#!/bin/sh
# Run one program with statement tracing and fold its trace into the
# coverage counts file as it is written (tools/cov_run.py). Used by
# make coverage.
#
# Usage: PLB_COV_DIR=dir tools/cov-run.sh PROGRAM [ARG]...
exec python3 "$(dirname "$0")/cov_run.py" "$@"
