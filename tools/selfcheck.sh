#!/bin/sh
# Analyze Plumbline's own COBOL sources with Plumbline and fail on any
# diagnostic. The analyzer's source is its first real-world corpus.
# Usage: tools/selfcheck.sh path/to/plumbline
set -u
bin=${1:?usage: selfcheck.sh path/to/plumbline}
failed=0
checked=0
for f in src/lib/*.cob src/cli/*.cob tests/harness/*.cob tests/unit/*.cob; do
    checked=$((checked + 1))
    if ! err=$("$bin" dump flow -I copy -I tests/harness "$f" 2>&1 >/dev/null) || [ -n "$err" ]; then
        failed=$((failed + 1))
        printf 'selfcheck: %s\n%s\n' "$f" "$err"
    fi
done
printf 'selfcheck: %d files parsed, %d with diagnostics\n' "$checked" "$failed"
[ "$failed" -eq 0 ]
