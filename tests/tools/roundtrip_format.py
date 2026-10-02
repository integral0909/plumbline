#!/usr/bin/env python3
"""Check that plumbline format keeps every token of a file.

Usage: roundtrip_format.py PLUMBLINE FILE...

For each FILE: format it to free format, then that to fixed format, and
compare the tokens of each (as plumbline dump tokens lists them, without
their positions) with those of FILE. Formatting a result again must
change nothing (format --check). Prints one line per problem and exits
non-zero if there is one.
"""

import os
import subprocess
import sys
import tempfile


def tokens(plumbline, path):
    """The (kind, text) of each token of PATH."""
    out = subprocess.run([plumbline, "dump", "tokens", path],
                         capture_output=True, text=True).stdout
    result = []
    for line in out.splitlines():
        # path:line:col: kind     text
        rest = line.split(": ", 1)[1] if ": " in line else line
        kind, _, text = rest.partition(" ")
        result.append((kind, text.strip()))
    return result


def formatted(plumbline, path, target, out_path):
    with open(out_path, "w") as out:
        subprocess.run([plumbline, "format", "--to", target, path],
                       stdout=out, check=True)


def main(argv):
    if len(argv) < 3:
        sys.stderr.write(__doc__)
        return 2
    plumbline, files = argv[1], argv[2:]
    problems = 0
    with tempfile.TemporaryDirectory() as tmp:
        for path in files:
            free = os.path.join(tmp, "free.cob")
            fixed = os.path.join(tmp, "fixed.cob")
            expected = tokens(plumbline, path)
            formatted(plumbline, path, "free", free)
            formatted(plumbline, free, "fixed", fixed)
            for name, result in (("free", free), ("fixed", fixed)):
                got = tokens(plumbline, result)
                if got != expected:
                    problems += 1
                    first = next((i for i, (a, b) in
                                  enumerate(zip(expected, got)) if a != b),
                                 min(len(expected), len(got)))
                    print(f"{path}: tokens differ in {name} format at "
                          f"token {first + 1}: "
                          f"{expected[first:first + 1]} != "
                          f"{got[first:first + 1]}")
                target = name
                check = subprocess.run(
                    [plumbline, "format", "--to", target, "--check", result],
                    capture_output=True, text=True)
                if check.returncode != 0:
                    problems += 1
                    print(f"{path}: formatting the {name} result again "
                          f"changes it")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
