#!/bin/sh
# Stand-in for the plumbline executable during make coverage: runs the
# traced build through cov-run.sh.
exec "$(dirname "$0")/cov-run.sh" "${PLB_COV_BIN:?PLB_COV_BIN must name the traced plumbline}" "$@"
