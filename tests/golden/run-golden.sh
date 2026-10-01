#!/bin/sh
# Golden-file tests: run a plumbline command on each input and compare
# its standard output and standard error with the files next to it.
#
# Usage: tests/golden/run-golden.sh PLUMBLINE SUITE-DIR COMMAND...
#   e.g. tests/golden/run-golden.sh build/bin/plumbline \
#            tests/golden/lexer dump tokens
#
# For an input NAME.cob (or NAME.cbl) the expected output is in
# NAME.out and the expected diagnostics in NAME.err (absent when the
# command writes nothing to standard error).
#
# Set GOLDEN_UPDATE=1 to rewrite the expected files from the current
# output instead of comparing. Review the resulting diff before
# committing it.
set -u

bin=${1:?usage: run-golden.sh PLUMBLINE SUITE-DIR COMMAND...}
dir=${2:?usage: run-golden.sh PLUMBLINE SUITE-DIR COMMAND...}
shift 2

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

n=0
failed=0
echo "TAP version 13"
echo "# suite: golden $(basename "$dir")"
for input in "$dir"/*.cob "$dir"/*.cbl "$dir"/*.jcl "$dir"/*.prc "$dir"/*.bms "$dir"/*.csd "$dir"/*.dbd "$dir"/*.psb; do
    [ -e "$input" ] || continue
    n=$((n + 1))
    base=${input%.*}
    "$bin" "$@" "$input" > "$tmp/out" 2> "$tmp/err"

    if [ "${GOLDEN_UPDATE:-0}" = 1 ]; then
        cp "$tmp/out" "$base.out"
        if [ -s "$tmp/err" ]; then cp "$tmp/err" "$base.err"; else rm -f "$base.err"; fi
        echo "ok $n - $(basename "$input") # updated"
        continue
    fi

    [ -e "$base.err" ] && expected_err="$base.err" || expected_err=/dev/null
    if diff -u "$base.out" "$tmp/out" > "$tmp/diff" 2>&1 &&
       diff -u "$expected_err" "$tmp/err" >> "$tmp/diff" 2>&1; then
        echo "ok $n - $(basename "$input")"
    else
        failed=$((failed + 1))
        echo "not ok $n - $(basename "$input")"
        sed 's/^/  # /' "$tmp/diff"
    fi
done
echo "1..$n"
echo "# golden $(basename "$dir"): $n cases, $failed failed"
[ "$failed" -eq 0 ]
