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
check "help lists the dump command"       0 'dump lines' -- --help
check "unknown command is a usage error"  2 "unknown command 'frobnicate'" -- frobnicate

fx=tests/fixtures/reader
check "dump lines shows each line"        0 "fixed-basic.cbl:1: code      fixed A IDENTIFICATION DIVISION.$" \
    -- dump lines $fx/fixed-basic.cbl
check "dump lines shows continuations"    0 'fixed-basic.cbl:8: cont      fixed - "THE CURRENT PERIOD".$' \
    -- dump lines $fx/fixed-basic.cbl
check "dump lines shows blank lines"      0 'fixed-basic.cbl:9: blank     fixed -$' \
    -- dump lines $fx/fixed-basic.cbl
check "detected free format"              0 'free-basic.cob:10: debug     free  - DISPLAY "DEBUG"$' \
    -- dump lines $fx/free-basic.cob
check "warnings go to stderr, exit 0"     0 'switch-format.cbl:8:8: warning: .*\[RD004\]' \
    -- dump lines $fx/switch-format.cbl
check "--format overrides detection"      1 'free-basic.cob:1:7: error: invalid character .*\[RD003\]' \
    -- dump lines --format fixed $fx/free-basic.cob
check "--format=VALUE form"               0 'fixed-basic.cbl:3: comment' \
    -- dump lines --format=fixed $fx/fixed-basic.cbl
check "missing file is an input error"    1 'cannot open no-such-file.cbl (file status 35) \[RD001\]' \
    -- dump lines no-such-file.cbl
check "other files still dumped"          1 'free-basic.cob:1: code' \
    -- dump lines no-such-file.cbl $fx/free-basic.cob
check "dump needs a target"               2 'missing what to dump' -- dump
check "dump rejects unknown targets"      2 "unknown target 'tokens'" -- dump tokens x.cbl
check "dump lines needs files"            2 'no input files' -- dump lines
check "invalid --format value"            2 "invalid format 'variable'" \
    -- dump lines --format variable $fx/fixed-basic.cbl
check "unknown dump option"               2 "unknown option '--frob'" -- dump lines --frob $fx/fixed-basic.cbl
echo "1..$n"
echo "# cli: $n assertions, $failed failed"
[ "$failed" -eq 0 ]
