#!/usr/bin/env python3
"""Split the NIST COBOL-85 test suite (newcob.val) into source files.

newcob.val is one file holding every program and copybook of the suite,
each between a header line and an end line:

    *HEADER,COBOL,NC101A
    ...
    *END-OF,NC101A

A program that belongs to another test (a subprogram it calls, or a
program run after it) has a header naming both, such as
*HEADER,COBOL,IC101A,SUBRTN,IC102A or *HEADER,COBOL,IX101A,SUBPRG,IX102A,
and is written under its own name (IC102A, IX102A). Two members with
the same file name are an error rather than one overwriting the other.

Some lines carry a letter in column 7 (the indicator area), such as S,
X, or Y. These mark optional code that the suite's driver program,
EXEC85, switches on or off for each compiler before it compiles
anything; as distributed, such lines are not valid COBOL. This script
switches all of it off, the way EXEC85 does for features a compiler
does not claim, by turning the letter into * so the line is a comment.
Debugging lines (D) are kept as they are.

COBOL members become NAME.cob in the output directory and CLBRY
(copy library) members become copy/NAME.cpy, so that `-I copy` finds
them. Other members (data files for the test runs) are skipped.

Usage: split_nist.py newcob.val OUTPUT-DIR
"""

import os
import sys

EXTENSIONS = {"COBOL": ".cob", "CLBRY": ".cpy"}
# Indicators that are COBOL rather than EXEC85 markers.
INDICATORS = set(" *-/Dd")


def without_optional_code(line):
    """LINE with an EXEC85 optional-code marker turned into a comment."""
    if len(line) > 6 and line[6] not in INDICATORS:
        return line[:6] + "*" + line[7:]
    return line


def split(lines):
    """Yield (kind, name, lines) for each member of the suite."""
    kind = name = None
    body = []
    for line in lines:
        if line.startswith("*HEADER,"):
            parts = [p.split()[0] if p.split() else "" for p in line.rstrip().split(",")]
            kind, name, body = parts[1], parts[2], []
            if len(parts) >= 5 and parts[3] in ("SUBRTN", "SUBPRG"):
                name = parts[4]
        elif line.startswith("*END-OF,") and kind is not None:
            yield kind, name, body
            kind = name = None
        elif kind is not None:
            body.append(line)


def main(argv):
    if len(argv) != 3:
        sys.stderr.write(__doc__)
        return 2
    source, out = argv[1], argv[2]
    os.makedirs(os.path.join(out, "copy"), exist_ok=True)
    counts = {}
    written = set()
    # The suite is ASCII; latin-1 never fails on a stray byte.
    with open(source, encoding="latin-1") as f:
        for kind, name, body in split(f):
            ext = EXTENSIONS.get(kind)
            if ext is None:
                continue
            folder = out if kind == "COBOL" else os.path.join(out, "copy")
            path = os.path.join(folder, name + ext)
            if path in written:
                sys.stderr.write(f"split_nist.py: {name} appears twice\n")
                return 1
            written.add(path)
            with open(path, "w",
                      encoding="latin-1") as member:
                member.writelines(
                    without_optional_code(line.rstrip("\r\n")) + "\n"
                    for line in body)
            counts[kind] = counts.get(kind, 0) + 1
    for kind in sorted(counts):
        print(f"{kind}: {counts[kind]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
