#!/usr/bin/env python3
"""Time plumbline check on generated programs of growing size.

Usage: tools/bench.py path/to/plumbline [PARAGRAPHS...]

For each count (default 2500 5000 10000), a free-format program is
written to a temporary directory with that many data items and
paragraphs, each paragraph a few statements that use its item, and a
main paragraph that performs every tenth one. The time of
`plumbline check` on it is printed, with the time per thousand lines
and how much the time grew from the size before: a rule or pass whose
cost grows with the square of the program shows as a growth near 4
for each doubling.

Then runs of many programs: 1,000 and 2,000 programs of 13 lines,
each calling the three after it (around a ring), in one run of
`plumbline check`, which resolves every CALL across the run.
"""

import os
import subprocess
import sys
import tempfile
import time


def program(paragraphs):
    lines = ["IDENTIFICATION DIVISION.", "PROGRAM-ID. BENCH.",
             "DATA DIVISION.", "WORKING-STORAGE SECTION."]
    for i in range(paragraphs):
        lines.append(f"01  ITEM-{i}  PIC 9(5) VALUE 0.")
    lines += ["01  TOTAL PIC 9(9) VALUE 0.", "PROCEDURE DIVISION.",
              "MAIN-LINE."]
    for i in range(0, paragraphs, 10):
        lines.append(f"    PERFORM PARA-{i}")
    lines += ["    DISPLAY TOTAL", "    STOP RUN."]
    for i in range(paragraphs):
        lines += [f"PARA-{i}.",
                  f"    ADD 1 TO ITEM-{i}",
                  f"    IF ITEM-{i} > 10",
                  f"        ADD ITEM-{i} TO TOTAL ON SIZE ERROR",
                  "            DISPLAY TOTAL",
                  "        END-ADD",
                  "    END-IF",
                  f"    MOVE ITEM-{i} TO ITEM-{(i + 1) % paragraphs}",
                  f"    DISPLAY ITEM-{i}."]
    return "\n".join(lines) + "\n"


def caller(i, count):
    """Program P{i} of count, calling the three programs after it."""
    calls = [f"    CALL \"P{(i + k) % count}\"" for k in (1, 2, 3)]
    return "\n".join([
        "IDENTIFICATION DIVISION.", f"PROGRAM-ID. P{i}.",
        "DATA DIVISION.", "WORKING-STORAGE SECTION.",
        "01  WS-COUNT PIC 9(4) VALUE 0.", "PROCEDURE DIVISION.",
        "MAIN-LINE.", "    ADD 1 TO WS-COUNT"] + calls
        + ["    DISPLAY WS-COUNT", "    GOBACK."]) + "\n"


def time_check(plumbline, paths):
    start = time.monotonic()
    subprocess.run([plumbline, "check", "--no-config", "--format", "free",
                    "--fail-on", "never"] + paths,
                   stdout=subprocess.DEVNULL, check=True)
    return time.monotonic() - start


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    plumbline = sys.argv[1]
    sizes = [int(n) for n in sys.argv[2:]] or [2500, 5000, 10000]
    previous = None
    with tempfile.TemporaryDirectory() as directory:
        for paragraphs in sizes:
            path = os.path.join(directory, f"bench{paragraphs}.cob")
            text = program(paragraphs)
            with open(path, "w") as f:
                f.write(text)
            lines = text.count("\n")
            seconds = time_check(plumbline, [path])
            growth = f"{seconds / previous:5.2f}x" if previous else "     -"
            print(f"{lines:7d} lines {seconds:7.2f} s "
                  f"{1000000 * seconds / lines:6.1f} ms/1000 lines "
                  f"growth {growth}")
            previous = seconds
    previous = None
    for count in (1000, 2000):
        with tempfile.TemporaryDirectory() as directory:
            paths = []
            lines = 0
            for i in range(count):
                path = os.path.join(directory, f"p{i}.cob")
                text = caller(i, count)
                with open(path, "w") as f:
                    f.write(text)
                paths.append(path)
                lines += text.count("\n")
            seconds = time_check(plumbline, paths)
            growth = f"{seconds / previous:5.2f}x" if previous else "     -"
            print(f"{count:5d} programs {lines:6d} lines {seconds:7.2f} s "
                  f"growth {growth}")
            previous = seconds


if __name__ == "__main__":
    main()
