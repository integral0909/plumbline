#!/bin/sh
# End-to-end checks of the plumbline executable: output and exit codes.
# Usage: tests/cli/test-cli.sh path/to/plumbline
# Emits TAP and exits non-zero on any failure.
set -u

bin=${1:?usage: test-cli.sh path/to/plumbline}
n=0
failed=0

# check LABEL EXPECTED-RC EXPECTED-OUTPUT-PATTERN -- ARGS...
check() {
    label=$1 want_rc=$2 pattern=$3
    shift 4
    n=$((n + 1))
    out=$("$bin" "$@" 2>&1)
    rc=$?
    if [ "$rc" -eq "$want_rc" ] && printf '%s\n' "$out" | grep -q -- "$pattern"; then
        echo "ok $n - $label"
    else
        failed=$((failed + 1))
        echo "not ok $n - $label"
        echo "  ---"
        echo "  expected rc $want_rc, output matching: $pattern"
        echo "  actual rc $rc, output:"
        printf '%s\n' "$out" | sed 's/^/    /'
        echo "  ..."
    fi
}

echo "TAP version 13"
echo "# suite: cli"
check "--version prints name and version" 0 '^plumbline [0-9]' -- --version
check "-V is an alias for --version"      0 '^plumbline [0-9]' -- -V
check "--help prints usage"               0 '^Usage: plumbline' -- --help
check "-h is an alias for --help"         0 '^Usage: plumbline' -- -h
check "no arguments prints usage"         2 '^Usage: plumbline' --
check "unknown option is a usage error"   2 "unknown option '--frobnicate'" -- --frobnicate
check "first handled option wins"         0 '^plumbline [0-9]' -- --version --bogus
echo "1..$n"
echo "# cli: $n assertions, $failed failed"
[ "$failed" -eq 0 ]
