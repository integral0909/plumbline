#!/bin/sh
# Run one program with statement tracing and fold its trace into the
# coverage counts file, then delete the trace. Used by make coverage
# so that trace files never pile up.
#
# Usage: PLB_COV_DIR=dir tools/cov-run.sh PROGRAM [ARG]...
set -u
dir=${PLB_COV_DIR:?PLB_COV_DIR must name the coverage directory}
trace=$(mktemp "$dir/run.XXXXXX")
COB_SET_TRACE=Y COB_TRACE_FORMAT='%F|%L' COB_TRACE_FILE="$trace" "$@"
rc=$?
python3 "$(dirname "$0")/cobcov.py" --fold "$trace" --counts "$dir/counts" || rc=99
rm -f "$trace"
exit $rc
