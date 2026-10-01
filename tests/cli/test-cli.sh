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
check "dump rejects unknown targets"      2 "unknown target 'frobs'" -- dump frobs x.cbl
check "help lists dump tokens"            0 'dump tokens' -- --help

gx=tests/golden/lexer
check "dump tokens shows tokens"          0 'numbers.cob:3:10: number   42$' \
    -- dump tokens $gx/numbers.cob
check "dump tokens reports lexer errors"  1 'bad-chars.cob:2:17: error: unexpected character .@. \[LX002\]' \
    -- dump tokens $gx/bad-chars.cob
check "debugging lines skipped by default" 0 'continuation.cbl:6:12: word     STOP' \
    -- dump tokens $gx/continuation.cbl
px=tests/golden/pp
check "help lists dump expanded"          0 'dump expanded' -- --help
check "dump expanded with -I DIR"         0 'copy/payrec.cpy:2:5: word     PAY-RECORD$' \
    -- dump expanded -I $px/copy $px/basic.cob
check "dump expanded with -IDIR"          0 'inclusion 1: tests/golden/pp/copy/payrec.cpy from tests/golden/pp/basic.cob:5:1$' \
    -- dump expanded -I$px/copy $px/basic.cob
check "missing copybook is an error"      1 "copybook 'PAYREC' not found \[PP001\]" \
    -- dump expanded $px/basic.cob
check "-I needs a directory"              2 '-I needs a directory' -- dump expanded $px/basic.cob -I
ax=tests/golden/parser
check "help lists dump ast"               0 'dump ast' -- --help
check "dump ast shows the tree"           0 '^    DIVN PROCEDURE @30:1$' -- dump ast $ax/structure.cob
check "dump ast reports syntax errors"    1 'errors.cob:14:5: error: ELSE without a matching IF \[PS003\]' \
    -- dump ast $ax/errors.cob
check "dump ast expands copybooks"        0 'DATA 1 PAY-RECORD @2:1 in tests/golden/pp/copy/payrec.cpy' \
    -- dump ast -I tests/golden/pp/copy tests/golden/pp/basic.cob
check "dump symbols shows sizes"          1 '^1 CUSTOMER G size=136 offset=0 section=W @4:1$' \
    -- dump symbols tests/golden/symbols/layout.cob
check "dump symbols reports bad pictures" 1 "layout.cob:28:33: warning: invalid character 'Q' in picture \[SY001\]" \
    -- dump symbols tests/golden/symbols/layout.cob
fw=tests/golden/flow
check "dump flow shows reachability"      0 '^paragraph AFTER-RANGE unreachable @18$' -- dump flow $fw/paths.cob
check "dump flow shows edges"             0 '^  perform STEP-1 thru STEP-EXIT$' -- dump flow $fw/paths.cob
check "dump flow reports bad targets"     1 'NO-SUCH-PARAGRAPH is not a paragraph or section of this program \[FL001\]' \
    -- dump flow $fw/sections.cob
rx=tests/golden/rules
check "help lists check"                  0 'check            analyze programs' -- --help
check "check reports findings"            1 'c001-unreachable.cob:27:1: warning: paragraph NEVER-CALLED is never executed \[PLB-C001\]' \
    -- check $rx/c001-unreachable.cob
check "--fail-on error ignores warnings"  0 'NEVER-CALLED' -- check --fail-on error $rx/c001-unreachable.cob
check "--disable by rule name"            0 '^$' -- check --disable unreachable-code --disable go-to $rx/c001-unreachable.cob
check "--disable by rule id"              0 '^$' -- check --disable PLB-C001 --disable PLB-M001 $rx/c001-unreachable.cob
check "notes do not fail by default"      0 'GO TO makes' -- check --disable PLB-C001 $rx/c001-unreachable.cob
check "--fail-on note fails on notes"     1 'GO TO makes' -- check --disable PLB-C001 --fail-on note $rx/c001-unreachable.cob
check "unknown rule is a usage error"     2 "unknown rule 'PLB-X999'" -- check --disable PLB-X999 $rx/c001-unreachable.cob
check "invalid --fail-on level"           2 "invalid --fail-on level 'sometimes'" -- check --fail-on sometimes $rx/c001-unreachable.cob
check "dump refs resolves qualified names" 0 '^25:10 CUST-ID OF CUSTOMER (MOVE) -> 5 CUST-ID @16 role=U$' \
    -- dump refs tests/golden/refs/resolution.cob
check "alnum-narrowing is off by default"  0 '^$' -- check --disable move-truncation --disable read-never-set --disable set-never-read $rx/c008-move-truncation.cob
check "alnum-narrowing can be enabled"     0 'c008-move-truncation.cob:16:23: note: MOVE truncates LONG-TEXT (20 characters) to fit SHORT-TEXT (5 characters) \[PLB-M004\]' \
    -- check --enable alnum-narrowing --disable move-truncation --disable read-never-set --disable set-never-read $rx/c008-move-truncation.cob
check "overlong file names are refused"    2 'file name longer than 512 characters' \
    -- check "$(printf 'x%.0s' $(seq 1 600)).cob"
check "--debug includes debugging lines"  0 'continuation.cbl:5:20: alnum    "DEBUG ONLY"' \
    -- dump tokens --debug $gx/continuation.cbl
cx=tests/fixtures/calls
check "calls are checked across files"    1 'billing.cob:9:17: warning: argument 1 (CUST-ID, 6 bytes) is smaller than parameter LK-CUST-ID of CUSTLOOK (8 bytes) \[PLB-C014\]' \
    -- check $cx/billing.cob $cx/custlook.cob
check "calls to programs not in the run are not checked" 0 '^$' -- check $cx/billing.cob
check "dynamic-call is off by default"    0 '^$' -- check --disable call-argument-count --disable call-argument-mismatch --disable recursive-call $rx/c013-c015-calls.cob
check "dump calls lists parameters"       0 '^  parameter LK-CUST-ID reference 8$' -- dump calls $cx/custlook.cob
check "help lists dump calls"             0 'dump calls' -- --help
check "dump lines needs files"            2 'no input files' -- dump lines
check "invalid --format value"            2 "invalid format 'variable'" \
    -- dump lines --format variable $fx/fixed-basic.cbl
check "unknown dump option"               2 "unknown option '--frob'" -- dump lines --frob $fx/fixed-basic.cbl
# check_report LABEL FORMAT EXPECTED-COUNT -- ARGS...
# Run plumbline and validate its report with tests/tools/check_report.py.
check_report() {
    label=$1 format=$2 count=$3
    shift 4
    n=$((n + 1))
    if err=$("$bin" "$@" 2>/dev/null | python3 tests/tools/check_report.py "$format" "$count" 2>&1); then
        echo "ok $n - $label"
    else
        failed=$((failed + 1))
        echo "not ok $n - $label"
        echo "  # $err"
    fi
}

check_report "json report is valid"        json 3 -- check --report json $rx/c001-unreachable.cob
check_report "sarif report is valid"       sarif 3 -- check --report sarif $rx/c001-unreachable.cob
check_report "empty sarif report is valid" sarif 0 -- check --report sarif --disable PLB-C001 --disable go-to $rx/c001-unreachable.cob
check "reports keep the exit code"        1 '"ruleId": "PLB-C001"' -- check --report sarif $rx/c001-unreachable.cob
check "invalid --report format"           2 "invalid --report format 'xml'" -- check --report xml $rx/c001-unreachable.cob

tmp=$(mktemp -d)
cp $rx/c001-unreachable.cob "$tmp/with space.cob"
check_report "sarif encodes spaces in uris" sarif 3 -- check --report sarif "$tmp/with space.cob"
rm -rf "$tmp"

echo "1..$n"
echo "# cli: $n assertions, $failed failed"
[ "$failed" -eq 0 ]
