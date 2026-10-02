#!/usr/bin/env python3
"""Statement coverage for GnuCOBOL programs.

GnuCOBOL has no native coverage report, but it can trace every statement
it executes (cobc -ftraceall, COB_SET_TRACE=Y). This tool combines:

  * line maps: the C that cobc generates (cobc -C -ftraceall) marks each
    COBOL statement with a comment of the form
        /* Line: 21        : IF                 : src/lib/plbstr.cob */
    which gives the set of executable lines per source file;
  * trace files: written by the runtime when COB_TRACE_FORMAT='%F|%L',
    one line per executed statement, e.g.
        Source: src/lib/plbstr.cob            |    21

and writes an LCOV tracefile plus a per-file summary.

Usage:
  cobcov.py --map GEN.c|DIR [--map ...] [--trace FILE|DIR ...]
            [--counts FILE] [--include PREFIX ...] [--lcov OUT]
            [--fail-under PCT]
  cobcov.py --fold TRACE --counts FILE

A directory given to --map contributes every *.c file in it; one given to
--trace contributes every *.trace file.

Traces grow by one line per executed statement, which quickly reaches
gigabytes for a parser run over real programs. --fold adds the hit counts
of one trace to a compact counts file (one "file|line|count" line per
executed line), so each trace can be deleted as soon as its program ends.
A report can then read the counts file instead of the raw traces.
"""

import argparse
import os
import re
import sys
from collections import defaultdict

MAP_RE = re.compile(r"/\* Line: (\d+)\s*: (\S+).*:\s*(\S+) \*/")
TRACE_RE = re.compile(r"^Source:\s+(\S+)\s*\|\s*(\d+)\s*$")

# Markers cobc emits that do not correspond to a traced statement:
# program entry points and the end-of-source sentinel. Paragraph, WHEN,
# UNTIL and VARYING markers are traced and so count as executable.
# Markers on line 0 (such as the generated default error handler) are
# also skipped: they have no source line to report.
NON_STATEMENTS = {"Entry", "last"}


def expand(paths, suffix):
    """Replace each directory in PATHS by the files in it ending in SUFFIX."""
    files = []
    for path in paths:
        if os.path.isdir(path):
            files.extend(sorted(os.path.join(path, name)
                                for name in os.listdir(path)
                                if name.endswith(suffix)))
        else:
            files.append(path)
    return files


def read_maps(paths):
    """Return {source file: set of executable line numbers}."""
    lines = defaultdict(set)
    for path in paths:
        with open(path, encoding="latin-1") as f:
            for text in f:
                m = MAP_RE.search(text)
                if (m and m.group(2) not in NON_STATEMENTS
                        and int(m.group(1)) > 0):
                    lines[m.group(3)].add(int(m.group(1)))
    return lines


def read_traces(paths):
    """Return {source file: {line: hit count}}."""
    hits = defaultdict(lambda: defaultdict(int))
    for path in paths:
        with open(path, encoding="latin-1") as f:
            for text in f:
                m = TRACE_RE.match(text)
                if m:
                    hits[m.group(1)][int(m.group(2))] += 1
    return hits


def unmapped_hits(executable, hits, prefixes):
    """Return {file: sorted lines} traced but absent from the line maps.

    Line 0 is ignored: the runtime uses it for program-level events.
    Anything else here means the map and the trace disagree, usually
    because cobc changed how it annotates generated C.
    """
    result = {}
    for name in sorted(hits):
        if not included(name, prefixes):
            continue
        extra = sorted(line for line in hits[name]
                       if line and line not in executable.get(name, ()))
        if extra:
            result[name] = extra
    return result


def read_counts(path, hits):
    """Add the counts in counts file PATH to HITS."""
    if not os.path.exists(path):
        return hits
    with open(path, encoding="latin-1") as f:
        for text in f:
            name, line, count = text.rstrip("\n").rsplit("|", 2)
            hits[name][int(line)] += int(count)
    return hits


def write_counts(path, hits):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="latin-1") as f:
        for name in sorted(hits):
            for line in sorted(hits[name]):
                f.write(f"{name}|{line}|{hits[name][line]}\n")
    os.replace(tmp, path)


def fold(trace, counts):
    """Add the hits in TRACE to the counts file COUNTS."""
    hits = read_traces([trace])
    read_counts(counts, hits)
    write_counts(counts, hits)


def included(name, prefixes):
    return not prefixes or any(name.startswith(p) for p in prefixes)


def build_report(executable, hits, prefixes):
    """Return a sorted list of (file, {line: count}) for included files."""
    report = []
    for name in sorted(executable):
        if not included(name, prefixes):
            continue
        counts = {line: hits.get(name, {}).get(line, 0)
                  for line in sorted(executable[name])}
        report.append((name, counts))
    return report


def write_lcov(report, out):
    for name, counts in report:
        out.write("TN:\n")
        out.write(f"SF:{name}\n")
        for line, count in counts.items():
            out.write(f"DA:{line},{count}\n")
        out.write(f"LF:{len(counts)}\n")
        out.write(f"LH:{sum(1 for c in counts.values() if c)}\n")
        out.write("end_of_record\n")


def percent(hit, total):
    return 100.0 * hit / total if total else 100.0


def write_summary(report, out):
    width = max([len(name) for name, _ in report] + [len("TOTAL")])
    total_lines = total_hit = 0
    out.write(f"{'File':<{width}}  {'Lines':>6}  {'Hit':>6}  {'Cover':>7}\n")
    for name, counts in report:
        n = len(counts)
        h = sum(1 for c in counts.values() if c)
        total_lines += n
        total_hit += h
        out.write(f"{name:<{width}}  {n:>6}  {h:>6}  {percent(h, n):>6.1f}%\n")
    out.write(f"{'TOTAL':<{width}}  {total_lines:>6}  {total_hit:>6}  "
              f"{percent(total_hit, total_lines):>6.1f}%\n")
    return percent(total_hit, total_lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--map", action="append", default=[],
                    help="C file generated by cobc -C -ftraceall")
    ap.add_argument("--trace", action="append", default=[],
                    help="runtime trace file (COB_TRACE_FORMAT='%%F|%%L')")
    ap.add_argument("--counts",
                    help="counts file written by --fold (read, or folded into)")
    ap.add_argument("--fold", metavar="TRACE",
                    help="add TRACE to --counts and exit")
    ap.add_argument("--include", action="append", default=[],
                    help="only report files starting with this prefix")
    ap.add_argument("--lcov", help="write an LCOV tracefile here")
    ap.add_argument("--fail-under", type=float, default=0.0,
                    help="exit 1 if total coverage is below this percent")
    args = ap.parse_args(argv)

    if args.fold:
        if not args.counts:
            ap.error("--fold needs --counts")
        fold(args.fold, args.counts)
        return 0
    if not args.map:
        ap.error("--map is required")

    executable = read_maps(expand(args.map, ".c"))
    hits = read_traces(expand(args.trace, ".trace"))
    if args.counts:
        read_counts(args.counts, hits)
    for name, lines in unmapped_hits(executable, hits, args.include).items():
        print(f"warning: {name}: traced lines missing from line map: "
              f"{', '.join(map(str, lines))}", file=sys.stderr)
    report = build_report(executable, hits, args.include)
    if args.lcov:
        with open(args.lcov, "w") as f:
            write_lcov(report, f)
    total = write_summary(report, sys.stdout)
    if total < args.fail_under:
        print(f"coverage {total:.1f}% is below the required "
              f"{args.fail_under:.1f}%", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
