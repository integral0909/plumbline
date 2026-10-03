#!/usr/bin/env python3
"""Run plumbline check on damaged copies of real programs.

Usage: tools/fuzz.py path/to/plumbline [--seed N] [--count N]
                     [--timeout SECONDS] [--out DIR] SOURCE...

Each round takes one of the SOURCE files (programs, copybooks, or JCL)
and damages a copy of it in one of a few ways an editor's buffer or a
half-finished change can be damaged: a line dropped, doubled, or cut
short; two lines swapped; a period, parenthesis, or quote dropped or
added; the file cut off part way. `plumbline check` then runs on the
copy, with the copy's own directory and the original's on the copybook
path.

A damaged program may well have findings and diagnostics: exit status
1 is expected. A round fails when the check

  - ends with a status other than 0 or 1, or is killed by a signal;
  - writes a run-time error of the COBOL run-time (libcob: ...) to
    standard error, such as a subscript out of range in a build with
    subscript checking (make check-bounds builds one);
  - does not end within the time limit.

Each failing copy is kept in the output directory (build/fuzz by
default) with the command's standard error, and the exit status is 1
when any round failed. The same seed gives the same rounds.
"""

import argparse
import os
import random
import subprocess
import sys

MUTATIONS = []


def mutation(fn):
    MUTATIONS.append(fn)
    return fn


@mutation
def drop_line(rng, lines):
    if lines:
        del lines[rng.randrange(len(lines))]
    return "drop a line"


@mutation
def double_line(rng, lines):
    if lines:
        i = rng.randrange(len(lines))
        lines.insert(i, lines[i])
    return "double a line"


@mutation
def swap_lines(rng, lines):
    if len(lines) > 1:
        i = rng.randrange(len(lines) - 1)
        lines[i], lines[i + 1] = lines[i + 1], lines[i]
    return "swap two lines"


@mutation
def cut_line(rng, lines):
    if lines:
        i = rng.randrange(len(lines))
        if lines[i]:
            lines[i] = lines[i][:rng.randrange(len(lines[i]))]
    return "cut a line short"


@mutation
def truncate_file(rng, lines):
    if lines:
        del lines[rng.randrange(len(lines)):]
    return "cut the file off"


def edit_character(rng, lines, characters, add):
    """Drop one of CHARACTERS from a line that has it, or add one."""
    places = [(i, j) for i, line in enumerate(lines)
              for j, c in enumerate(line) if c in characters]
    if add:
        if not lines:
            return
        i = rng.randrange(len(lines))
        j = rng.randrange(len(lines[i]) + 1)
        c = rng.choice(characters)
        lines[i] = lines[i][:j] + c + lines[i][j:]
    elif places:
        i, j = rng.choice(places)
        lines[i] = lines[i][:j] + lines[i][j + 1:]


@mutation
def drop_period(rng, lines):
    edit_character(rng, lines, ".", False)
    return "drop a period"


@mutation
def drop_paren(rng, lines):
    edit_character(rng, lines, "()", False)
    return "drop a parenthesis"


@mutation
def add_paren(rng, lines):
    edit_character(rng, lines, "()", True)
    return "add a parenthesis"


@mutation
def drop_quote(rng, lines):
    edit_character(rng, lines, "\"'", False)
    return "drop a quote"


@mutation
def add_quote(rng, lines):
    edit_character(rng, lines, "\"'", True)
    return "add a quote"


def run(binary, path, original, timeout):
    """The check's status and standard error, or None on a time-out."""
    command = [binary, "check", "-I", os.path.dirname(path),
               "-I", os.path.dirname(original), path]
    try:
        done = subprocess.run(command, stdout=subprocess.DEVNULL,
                              stderr=subprocess.PIPE, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None, ""
    return done.returncode, done.stderr.decode("latin-1")


def failure(status, stderr):
    if status is None:
        return "no result within the time limit"
    if status < 0:
        return f"killed by signal {-status}"
    if status not in (0, 1):
        return f"exit status {status}"
    for line in stderr.splitlines():
        if line.startswith("libcob:"):
            return line
    return None


def main():
    parser = argparse.ArgumentParser(
        description="Run plumbline check on damaged copies of programs.")
    parser.add_argument("binary")
    parser.add_argument("sources", nargs="+")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--count", type=int, default=200)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--out", default="build/fuzz")
    args = parser.parse_args()

    rng = random.Random(args.seed)
    os.makedirs(args.out, exist_ok=True)
    work = os.path.join(args.out, "work")
    os.makedirs(work, exist_ok=True)
    sources = sorted(args.sources)
    failed = 0
    for round_number in range(1, args.count + 1):
        original = rng.choice(sources)
        with open(original, encoding="latin-1") as f:
            lines = f.read().split("\n")
        how = rng.choice(MUTATIONS)(rng, lines)
        name = os.path.basename(original)
        path = os.path.join(work, name)
        with open(path, "w", encoding="latin-1") as f:
            f.write("\n".join(lines))
        status, stderr = run(args.binary, path, original, args.timeout)
        problem = failure(status, stderr)
        if problem is None:
            continue
        failed += 1
        kept = os.path.join(args.out, f"{round_number:05d}-{name}")
        os.replace(path, kept)
        with open(kept + ".err", "w", encoding="latin-1") as f:
            f.write(f"{original}: {how}\n{problem}\n{stderr}")
        print(f"round {round_number}: {original}: {how}: {problem}"
              f" (kept as {kept})")
    print(f"{args.count} rounds, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
