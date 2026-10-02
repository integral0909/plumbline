#!/usr/bin/env python3
"""Run one program with statement tracing, folding its trace as it runs.

Usage: PLB_COV_DIR=dir tools/cov_run.py PROGRAM [ARG]...

The program writes its trace (COB_TRACE_FILE) into a named pipe, which a
thread reads and folds into PLB_COV_DIR/counts while the program runs,
so the trace never lands on disk: a long run, such as the language
server tests, writes gigabytes of it, more than a CI runner has room
for. The exit status is the program's, or 99 when folding failed.
"""

import os
import subprocess
import sys
import tempfile
import threading

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cobcov  # noqa: E402


def main(argv):
    if not argv:
        sys.exit(__doc__)
    directory = os.environ.get("PLB_COV_DIR")
    if not directory:
        sys.exit("PLB_COV_DIR must name the coverage directory")
    counts = os.path.join(directory, "counts")
    work = tempfile.mkdtemp(prefix="run.", dir=directory)
    pipe = os.path.join(work, "trace")
    os.mkfifo(pipe)
    failed = []
    done = threading.Event()

    def reader():
        try:
            cobcov.fold(pipe, counts)
        except Exception as error:  # reported after the program ends
            failed.append(error)
        finally:
            done.set()

    thread = threading.Thread(target=reader)
    thread.start()
    env = dict(os.environ, COB_SET_TRACE="Y", COB_TRACE_FORMAT="%F|%L",
               COB_TRACE_FILE=pipe)
    status = subprocess.call(argv, env=env)
    # A program that traced nothing never opened the pipe, and the
    # reader still waits for a writer: open and close it to end it.
    if not done.wait(0.5):
        os.close(os.open(pipe, os.O_WRONLY))
    thread.join()
    os.unlink(pipe)
    os.rmdir(work)
    if failed:
        print(f"cov_run: folding the trace failed: {failed[0]}",
              file=sys.stderr)
        return 99
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
