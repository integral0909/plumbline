#!/bin/sh
# Run each test executable given on the command line and summarize.
#
# Each test prints TAP to stdout and exits non-zero if any assertion
# failed. Output is shown only for failing suites unless VERBOSE=1.
set -u

passed=0
failed=0
failed_names=""

for test in "$@"; do
    name=$(basename "$test")
    if out=$("$test" 2>&1); then
        passed=$((passed + 1))
        summary=$(printf '%s\n' "$out" | grep '^# .*assertions' | tail -n 1)
        printf 'PASS  %-32s %s\n' "$name" "${summary#\# }"
        if [ "${VERBOSE:-0}" = 1 ]; then
            printf '%s\n' "$out"
        fi
    else
        failed=$((failed + 1))
        failed_names="$failed_names $name"
        printf 'FAIL  %s\n' "$name"
        printf '%s\n' "$out" | sed 's/^/      /'
    fi
done

printf '\n%d suite(s) passed, %d failed\n' "$passed" "$failed"
if [ "$failed" -gt 0 ]; then
    printf 'failed:%s\n' "$failed_names"
    exit 1
fi
