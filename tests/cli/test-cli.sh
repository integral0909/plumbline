#!/bin/sh
# End-to-end checks of the plumbline executable: output and exit codes.
# Usage: tests/cli/test-cli.sh path/to/plumbline
# Emits TAP and exits non-zero on any failure.
#
# Variables such as $sm hold several file names, and are split into
# arguments on purpose; expected Markdown output has backquotes, which
# are literal in the single-quoted patterns.
# shellcheck disable=SC2086,SC2016
set -u

bin=${1:?usage: test-cli.sh path/to/plumbline}
# Absolute, so that checks can run in another directory (run_dir).
bin_abs=$(cd "$(dirname "$bin")" && pwd)/$(basename "$bin")
run_dir=.
n=0
failed=0

# check LABEL EXPECTED-RC EXPECTED-OUTPUT-PATTERN -- ARGS...
check() {
    label=$1 want_rc=$2 pattern=$3
    shift 4
    n=$((n + 1))
    out=$(cd "$run_dir" && "$bin_abs" "$@" 2>&1)
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

# check_stdin LABEL EXPECTED-RC PATTERN INPUT -- ARGS...: like check,
# with INPUT (printf format) on standard input.
check_stdin() {
    label=$1 want_rc=$2 pattern=$3 input=$4
    shift 5
    n=$((n + 1))
    out=$(printf '%b' "$input" | "$bin_abs" "$@" 2>&1)
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

# check_absent LABEL PATTERN -- ARGS...: no line of the output matches
# PATTERN (the exit code is not checked).
check_absent() {
    label=$1 pattern=$2
    shift 3
    n=$((n + 1))
    out=$(cd "$run_dir" && "$bin_abs" "$@" 2>&1)
    if printf '%s\n' "$out" | grep -q -- "$pattern"; then
        failed=$((failed + 1))
        echo "not ok $n - $label"
        echo "  ---"
        echo "  expected no line matching: $pattern"
        echo "  actual output:"
        printf '%s\n' "$out" | sed 's/^/    /'
        echo "  ..."
    else
        echo "ok $n - $label"
    fi
}

# check_file LABEL PATTERN FILE: a line of FILE matches PATTERN.
check_file() {
    n=$((n + 1))
    if grep -q -- "$2" "$3"; then
        echo "ok $n - $1"
    else
        failed=$((failed + 1))
        echo "not ok $n - $1"
        echo "  ---"
        echo "  expected a line matching: $2"
        echo "  actual file:"
        sed 's/^/    /' "$3"
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
check "Markdown report lists input problems" 1 "^| error | \`tests/golden/pp/basic.cob:5:1\` | PP001 | copybook 'PAYREC' not found |\$" \
    -- check --no-config --report md $px/basic.cob
n=$((n + 1))
if "$bin" check --no-config --report json $px/basic.cob | python3 -c '
import json, sys
first = json.load(sys.stdin)["diagnostics"][0]
assert (first["code"], first["severity"], first["line"]) == ("PP001", "error", 5)
'; then
    echo "ok $n - json report lists input problems"
else
    echo "not ok $n - json report lists input problems"
fi
n=$((n + 1))
if "$bin" check --no-config --report sarif $px/basic.cob | python3 -c '
import json, sys
note = json.load(sys.stdin)["runs"][0]["invocations"][0]["toolExecutionNotifications"][0]
assert note["descriptor"]["id"] == "PP001" and note["level"] == "error"
assert note["locations"][0]["physicalLocation"]["region"]["startLine"] == 5
'; then
    echo "ok $n - sarif report lists input problems"
else
    echo "not ok $n - sarif report lists input problems"
fi
many_dir=$(mktemp -d)
python3 -c '
import sys
lines = ["IDENTIFICATION DIVISION.", "PROGRAM-ID. MANY.",
         "PROCEDURE DIVISION.", "MAIN-LINE.", "    STOP RUN."]
for i in range(1100):
    lines += ["UNUSED-%d." % i, "    DISPLAY \"UNUSED\"."]
open(sys.argv[1], "w").write("\n".join(lines) + "\n")
' "$many_dir/many.cob"
check "Markdown report stops after 1000 rows" 0 '^\.\.\. and 100 more\.$' \
    -- check --no-config --format free --fail-on never --report md "$many_dir/many.cob"
rm -rf "$many_dir"
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
check "alnum-narrowing is off by default"  0 '^$' -- check --disable move-truncation --disable read-never-set --disable set-never-read --disable value-never-used $rx/c008-move-truncation.cob
check "alnum-narrowing can be enabled"     0 'c008-move-truncation.cob:16:23: note: MOVE truncates LONG-TEXT (20 characters) to fit SHORT-TEXT (5 characters) \[PLB-M004\]' \
    -- check --enable alnum-narrowing --disable move-truncation --disable read-never-set --disable set-never-read --disable value-never-used $rx/c008-move-truncation.cob
check "overlong file names are refused"    2 'file name longer than 512 characters' \
    -- check "$(printf 'x%.0s' $(seq 1 600)).cob"
check "--debug includes debugging lines"  0 'continuation.cbl:5:20: alnum    "DEBUG ONLY"' \
    -- dump tokens --debug $gx/continuation.cbl
cx=tests/fixtures/calls
check "calls are checked across files"    1 'billing.cob:9:17: warning: argument 1 (CUST-ID, 6 bytes) is smaller than parameter LK-CUST-ID of CUSTLOOK (8 bytes) \[PLB-C014\]' \
    -- check $cx/billing.cob $cx/custlook.cob
check "calls to programs not in the run are not checked" 0 '^$' -- check $cx/billing.cob
# More inputs than the old limit of 256 files: tables indexed by file
# must hold them all.
many=$(mktemp -d)
i=1
while [ $i -le 300 ]; do
    printf '       IDENTIFICATION DIVISION.\n       PROGRAM-ID. P%s.\n       PROCEDURE DIVISION.\n           GOBACK.\n' $i \
        > "$many/p$i.cob"
    i=$((i + 1))
done
printf '       01  SHARED-REC PIC X(10).\n' > "$many/shared.cpy"
printf '       IDENTIFICATION DIVISION.\n       PROGRAM-ID. LAST.\n       DATA DIVISION.\n       WORKING-STORAGE SECTION.\n       COPY SHARED.\n       PROCEDURE DIVISION.\n           MOVE SPACES TO SHARED-REC\n           DISPLAY SHARED-REC\n           GOBACK.\n' \
    > "$many/z-last.cob"
check "impact over more than 256 files"   0 'included by .*z-last.cob directly' \
    -- impact SHARED --no-config -I "$many" "$many"/*.cob
check "check over more than 256 files"    0 '^$' -- check --no-config -I "$many" "$many"/*.cob
rm -rf "$many"
check "evaluate-without-other is off by default" 0 '^$' \
    -- check --no-config tests/fixtures/rules/evaluate.cob
check "evaluate-without-other finds the EVALUATE" 0 'evaluate.cob:12:12: note: EVALUATE has no WHEN OTHER.*\[PLB-M011\]$' \
    -- check --no-config --enable evaluate-without-other --fail-on error tests/fixtures/rules/evaluate.cob
check_absent "an EVALUATE with WHEN OTHER is fine" 'evaluate.cob:8:' \
    -- check --no-config --enable PLB-M011 tests/fixtures/rules/evaluate.cob
check "deep-nesting reports the outermost statement" 0 'nesting.cob:11:5: note: IF nests statements 4 levels deep (limit 3) \[PLB-M012\]' \
    -- check --config tests/fixtures/config/nesting.conf tests/fixtures/rules/nesting.cob
check_absent "deep-nesting reports it once" 'nesting.cob:2[0-9]:' \
    -- check --config tests/fixtures/config/nesting.conf tests/fixtures/rules/nesting.cob
check "deep-nesting allows 5 levels by default" 0 '^$' \
    -- check --no-config --enable deep-nesting tests/fixtures/rules/nesting.cob
check "dump jcl lists steps and DDs"       0 'statements.jcl:6:     dd INFILE dsn PROD.PAYROLL.MASTER disp OLD' \
    -- dump jcl tests/golden/jcl/statements.jcl
check "a cataloged procedure takes its member name" 0 'payrept.prc:3: proc PAYREPT' \
    -- dump jcl tests/fixtures/jcl/payrept.prc
check "dump jcl of a missing file"         2 'cannot read tests/golden/jcl/missing.jcl' \
    -- dump jcl tests/golden/jcl/missing.jcl
jx=tests/fixtures/jcl
check "a step without a DD the program opens" 1 'payroll.jcl:11:3: error: step RERUN has no DD PAYLOG for file LOG-FILE, which PAYLOG opens \[PLB-J001\]' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check "a DD no program of the step uses"  1 'payroll.jcl:14:3: note: DD OLDFILE is not a file of PAYUPD or the programs it calls \[PLB-J002\]' \
    -- check --no-config --fail-on error $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check_absent "a path DD, optional, sort, and override DDs are fine" 'payroll.jcl:[4-9]:\|payproc.prc' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check_absent "programs not in the run are not reported by default" 'PLB-J003' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check "programs not in the run on request" 1 'payroll.jcl:19:3: note: step CLEANUP runs IEFBR14, which is not among the programs checked \[PLB-J003\]' \
    -- check --no-config --fail-on error --enable program-not-in-run $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check "a read-only file on a new data set" 1 'payroll.jcl:23:3: error: DD RATES creates a new, empty data set, but PAYUPD only reads it as RATES \[PLB-J004\]' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check "a read-only file on SYSOUT"        1 'payroll.jcl:28:3: error: DD RATES is SYSOUT, but PAYUPD reads it as RATES \[PLB-J004\]' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check "a written file shared with DISP=SHR" 1 'shared.jcl:7:3: warning: DD PAYRPT is DISP=SHR, but PAYUPD writes it as REPORT-OUT.*\[PLB-J013\]' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/shared.jcl
check "a written data set deleted at the end" 1 'shared.jcl:15:3: warning: DD PAYRPT deletes PAY.REPORT.NEW when the step ends.*\[PLB-J014\]' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/shared.jcl
check "a step name used twice in a job" 1 'steps.jcl:5:3: warning: step name EXTRACT is already the name of the step on line 3: .*\[PLB-J015\]' \
    -- check --no-config $jx/steps.jcl
check "a step name used twice in a procedure" 1 'steps.jcl:10:3: warning: step name COPY is already the name of the step on line 9: .*\[PLB-J015\]' \
    -- check --no-config $jx/steps.jcl
check_absent "a procedure's step may have a job step's name" 'steps.jcl:8:' \
    -- check --no-config $jx/steps.jcl
check_absent "another job may use the same step names" 'steps.jcl:15:' \
    -- check --no-config $jx/steps.jcl
check "IEBGENER without SYSIN and SYSPRINT" 1 'utilities.jcl:3:3: error: step COPY runs IEBGENER but has no DD SYSIN, SYSPRINT, which it needs: the step fails \[PLB-J016\]' \
    -- check --no-config $jx/utilities.jcl
check "IKJEFT01 without SYSTSIN"            1 'utilities.jcl:13:3: error: step RUNDB2 runs IKJEFT01 but has no DD SYSTSIN.*\[PLB-J016\]' \
    -- check --no-config $jx/utilities.jcl
check_absent "IDCAMS with SYSIN is fine"     'utilities.jcl:7:' \
    -- check --no-config $jx/utilities.jcl
check_absent "a procedure's utility step is not read" 'utilities.jcl:17:' \
    -- check --no-config $jx/utilities.jcl
check "BLKSIZE not a multiple of LRECL for FB" 1 'blksize.jcl:6:3: error: DD SYSUT1 has BLKSIZE 27900 and LRECL 80, but RECFM=FB needs a BLKSIZE a multiple of LRECL.*\[PLB-J017\]' \
    -- check --no-config $jx/blksize.jcl
check "BLKSIZE too small for VB"            1 'blksize.jcl:9:3: error: DD SYSUT2 has BLKSIZE 100 and LRECL 100, but RECFM=VB needs a BLKSIZE at least LRECL + 4.*\[PLB-J017\]' \
    -- check --no-config $jx/blksize.jcl
check_absent "a BLKSIZE that fits is fine"   'blksize.jcl:1[5-9]:' \
    -- check --no-config $jx/blksize.jcl
check "a new generation read before it is made" 1 'gdg.jcl:4:3: error: PAY.HISTORY(+1) is a new generation, read with DISP=SHR, but no earlier step creates it.*\[PLB-J018\]' \
    -- check --no-config $jx/gdg.jcl
check_absent "a generation made, then read, is fine" 'gdg.jcl:9:' \
    -- check --no-config $jx/gdg.jcl
check_absent "(0) and names with symbols are fine" 'gdg.jcl:1[23]:' \
    -- check --no-config $jx/gdg.jcl
check "a PARM of 101 characters"         1 'parm.jcl:3:3: error: PARM passes 101 characters; z/OS takes at most 100.*\[PLB-J019\]' \
    -- check --no-config $jx/parm.jcl
check_absent "a PARM of 100 characters is fine" 'parm.jcl:8:' \
    -- check --no-config $jx/parm.jcl
check_absent "a doubled apostrophe passes one"  'parm.jcl:11:' \
    -- check --no-config $jx/parm.jcl
check_absent "a PARM with a symbol is not counted" 'parm.jcl:15:' \
    -- check --no-config $jx/parm.jcl
check "a step name of 11 characters"      1 'names.jcl:3:3: error: name EXTRACTSTEP is longer than 8 characters.*\[PLB-J020\]' \
    -- check --no-config $jx/names.jcl
check "a name that starts with a digit"   1 'names.jcl:6:3: error: name 1COPY does not start with a letter.*\[PLB-J020\]' \
    -- check --no-config $jx/names.jcl
check "a DD name with a hyphen"           1 'names.jcl:9:3: error: name PAY-IN has a character other than.*\[PLB-J020\]' \
    -- check --no-config $jx/names.jcl
check "an override's DD part too long"    1 'names.jcl:11:3: error: name STEP1.INPUTFILE1 (after the dot) is longer.*\[PLB-J020\]' \
    -- check --no-config $jx/names.jcl
check_absent "valid names are fine"       'names.jcl:1[4-9]:.*PLB-J020' \
    -- check --no-config $jx/names.jcl
check "a program name of 11 characters"   1 'names.jcl:22:3: error: program name PAYEXTRACT1 is longer than 8.*\[PLB-J020\]' \
    -- check --no-config $jx/names.jcl
check "a procedure name with a hyphen"    1 'names.jcl:23:3: error: procedure name PAY-PROC has a character.*\[PLB-J020\]' \
    -- check --no-config $jx/names.jcl
check_absent "PGM=*.STEP.DD is not a name" 'names.jcl:25:.*PLB-J020' \
    -- check --no-config $jx/names.jcl
check "COND=(0,LE) is always true"        1 'cond.jcl:4:3: warning: COND test (0,LE) is true for every return code.*\[PLB-J021\]' \
    -- check --no-config $jx/cond.jcl
check "(4095,GE) among other tests"       1 'cond.jcl:6:3: warning: COND test (4095,GE) is true.*\[PLB-J021\]' \
    -- check --no-config $jx/cond.jcl
check_absent "(0,LT) has codes it fails"  'cond.jcl:9:.*PLB-J021' \
    -- check --no-config $jx/cond.jcl
check_absent "(10,LE) is not (0,LE)"      'cond.jcl:10:.*PLB-J021' \
    -- check --no-config $jx/cond.jcl
check "COND=(0,GT) is never true"         1 'cond.jcl:14:3: warning: COND test (0,GT) is true for no return code.*\[PLB-J022\]' \
    -- check --no-config $jx/cond.jcl
check "(4095,LT) of a named step"         1 'cond.jcl:15:3: warning: COND test (4095,LT) is true for no return code.*\[PLB-J022\]' \
    -- check --no-config $jx/cond.jcl
check "IEBGENER copies a data set onto itself" 1 'copyself.jcl:7:3: error: SYSUT2 names PAY.MASTER, which SYSUT1 reads.*\[PLB-J023\]' \
    -- check --no-config $jx/copyself.jcl
check "SYSUT2 among SYSUT1's concatenation" 1 'copyself.jcl:14:3: error: SYSUT2 names PAY.ALL.*\[PLB-J023\]' \
    -- check --no-config $jx/copyself.jcl
check_absent "a copy to another data set"  'copyself.jcl:20:.*PLB-J023' \
    -- check --no-config $jx/copyself.jcl
check "DISP with SYSOUT"                  1 'sysout.jcl:4:3: warning: DD REPORT codes DISP with SYSOUT.*\[PLB-J024\]' \
    -- check --no-config $jx/sysout.jcl
check "VOL with SYSOUT"                   1 'sysout.jcl:6:3: warning: DD AUDIT codes VOL with SYSOUT.*\[PLB-J024\]' \
    -- check --no-config $jx/sysout.jcl
check "HOLD without SYSOUT"               1 'sysout.jcl:8:3: warning: DD LOG codes HOLD without SYSOUT.*\[PLB-J024\]' \
    -- check --no-config $jx/sysout.jcl
check_absent "DEST, HOLD, OUTLIM with SYSOUT" 'sysout.jcl:10:.*PLB-J024' \
    -- check --no-config $jx/sysout.jcl
check "OUTPUT without SYSOUT"             1 'sysout.jcl:14:3: warning: DD RPTCOPY codes OUTPUT without SYSOUT or SUBSYS.*\[PLB-J024\]' \
    -- check --no-config $jx/sysout.jcl
check "OUTPUT with the internal reader"   1 'sysout.jcl:15:3: warning: DD SUBMIT codes OUTPUT with SYSOUT=(...,INTRDR).*\[PLB-J024\]' \
    -- check --no-config $jx/sysout.jcl
check_absent "OUTPUT with SYSOUT"         'sysout.jcl:17:.*PLB-J024' \
    -- check --no-config $jx/sysout.jcl
check_absent "a procedure DD override"    'sysout.jcl:20:.*PLB-J024' \
    -- check --no-config $jx/sysout.jcl
check "DLM on a data set DD"              1 'dlm.jcl:4:3: error: DD CARDS codes DLM but is not DD \* or DD DATA.*\[PLB-J025\]' \
    -- check --no-config $jx/dlm.jcl
check_absent "DLM on DD DATA"            'dlm.jcl:6:.*PLB-J025' \
    -- check --no-config $jx/dlm.jcl
check_absent "DLM on DD *"                'dlm.jcl:9:.*PLB-J025' \
    -- check --no-config $jx/dlm.jcl
check "256 steps with a procedure's"     1 'manysteps.jcl:2:3: error: job PAYALL has at least 256 steps.*\[PLB-J026\]' \
    -- check --no-config $jx/manysteps.jcl $jx/payday.prc
check_absent "255 steps are allowed"      'job PAYMOST' \
    -- check --no-config $jx/manysteps.jcl $jx/payday.prc
check_absent "a procedure not in the run counts as one step" 'PLB-J026' \
    -- check --no-config $jx/manysteps.jcl
check "a generation past 255"             1 'gener.jcl:5:3: error: data set name PAY.HIST: relative generation -300 is more than 255.*\[PLB-J010\]' \
    -- check --no-config $jx/gener.jcl
check "a generation without a sign"       1 'gener.jcl:6:3: error: .*relative generation 1 is not a sign.*\[PLB-J010\]' \
    -- check --no-config $jx/gener.jcl
check "a generation of four digits"       1 'gener.jcl:7:3: error: .*relative generation +0001 is not.*\[PLB-J010\]' \
    -- check --no-config $jx/gener.jcl
check "a generation with a letter"        1 'gener.jcl:8:3: error: .*relative generation +1A is not.*\[PLB-J010\]' \
    -- check --no-config $jx/gener.jcl
check_absent "generation 0"               'gener.jcl:10:' \
    -- check --no-config $jx/gener.jcl
check_absent "generation -255"            'gener.jcl:11:' \
    -- check --no-config $jx/gener.jcl
check_absent "generation +1"              'gener.jcl:12:' \
    -- check --no-config $jx/gener.jcl
check_absent "a member name"              'gener.jcl:13:' \
    -- check --no-config $jx/gener.jcl
check "a procedure that calls itself"    1 'payloop.prc:3:3: error: procedure PAYLOOP calls itself.*\[PLB-J027\]' \
    -- check --no-config $jx/payloop.prc
check "two procedures that call each other" 1 'paya.prc:3:3: error: procedure PAYA calls PAYB, which calls PAYA again.*\[PLB-J027\]' \
    -- check --no-config $jx/paya.prc $jx/payb.prc $jx/payc.prc
check_absent "a call that does not lead back" 'paya.prc:5:.*PLB-J027' \
    -- check --no-config $jx/paya.prc $jx/payb.prc $jx/payc.prc
check "a sixteenth in-stream procedure"  1 'instream.jcl:49:3: error: procedure P16 is in-stream procedure 16 of job PAYALL.*\[PLB-J028\]' \
    -- check --no-config $jx/instream.jcl
check_absent "the fifteenth is allowed"   'procedure P15 is in-stream' \
    -- check --no-config $jx/instream.jcl
check "TIME=0 on a JOB statement"         1 'time.jcl:2:3: error: job PAYJOB codes TIME=0.*\[PLB-J029\]' \
    -- check --no-config $jx/time.jcl
check "90 seconds"                        1 'time.jcl:5:3: error: step EXTRACT codes TIME=(5,90), not minutes.*\[PLB-J029\]' \
    -- check --no-config $jx/time.jcl
check "400000 minutes"                    1 'time.jcl:6:3: error: step SORT codes TIME=400000.*\[PLB-J029\]' \
    -- check --no-config $jx/time.jcl
check "minutes that are not a number"     1 'time.jcl:7:3: error: step REPORT codes TIME=FIVE.*\[PLB-J029\]' \
    -- check --no-config $jx/time.jcl
check_absent "TIME in range, or no limit" 'time.jcl:1[0-5]:.*PLB-J029' \
    -- check --no-config $jx/time.jcl
check "REGION=3000M on a JOB statement"   1 'region.jcl:2:3: error: job PAYJOB codes REGION=3000M.*\[PLB-J030\]' \
    -- check --no-config $jx/region.jcl
check "more than 2096128K"                1 'region.jcl:5:3: error: step SORT codes REGION=4000000K.*\[PLB-J030\]' \
    -- check --no-config $jx/region.jcl
check "a REGION without K or M"           1 'region.jcl:6:3: error: step LOAD codes REGION=4096,.*\[PLB-J030\]' \
    -- check --no-config $jx/region.jcl
check_absent "REGION in range, 0K, 0M"    'region.jcl:1[0-3]:.*PLB-J030' \
    -- check --no-config $jx/region.jcl
check_absent "REGION=2096128K"            'region.jcl:9:.*PLB-J030' \
    -- check --no-config $jx/region.jcl
check "MSGLEVEL messages 2"               1 'msglevel.jcl:2:3: error: job PAYJOB1 codes MSGLEVEL=(1,2).*\[PLB-J031\]' \
    -- check --no-config $jx/msglevel.jcl
check "MSGLEVEL statements 3"             1 'msglevel.jcl:5:3: error: job PAYJOB2 codes MSGLEVEL=3:.*\[PLB-J031\]' \
    -- check --no-config $jx/msglevel.jcl
check_absent "MSGLEVEL forms the Reference shows" 'msglevel.jcl:1[02]:.*PLB-J031' \
    -- check --no-config $jx/msglevel.jcl
check_absent "MSGLEVEL=(2,1)"             'msglevel.jcl:8:.*PLB-J031' \
    -- check --no-config $jx/msglevel.jcl
check "MSGCLASS of two characters"       1 'class.jcl:2:3: error: job PAYJOB1 codes MSGCLASS=XY;.*\[PLB-J032\]' \
    -- check --no-config $jx/class.jcl
check "SYSOUT class of two characters"    1 'class.jcl:6:3: error: DD REPORT codes SYSOUT class AB;.*\[PLB-J032\]' \
    -- check --no-config $jx/class.jcl
check "SYSOUT class not a letter or digit" 1 'class.jcl:7:3: error: DD AUDIT codes SYSOUT class #;.*\[PLB-J032\]' \
    -- check --no-config $jx/class.jcl
check_absent "SYSOUT=*, (,), (A,,FM26), 'B'" 'class.jcl:1[0-2]:.*PLB-J032' \
    -- check --no-config $jx/class.jcl
check_absent "SYSOUT=*"                   'class.jcl:9:.*PLB-J032' \
    -- check --no-config $jx/class.jcl
check "a job class starting with a hyphen" 1 'class.jcl:14:3: error: job PAYJOB2 codes CLASS=-A;.*\[PLB-J032\]' \
    -- check --no-config $jx/class.jcl
check_absent "a job class of eight characters" 'class.jcl:17:.*PLB-J032' \
    -- check --no-config $jx/class.jcl
check "JOB COND=(0,LE)"                   1 'jobcond.jcl:3:3: warning: COND test (0,LE) is true for every return code: job PAYJOB1 ends after its first step.*\[PLB-J021\]' \
    -- check --no-config $jx/jobcond.jcl
check "JOB COND test (4095,LT)"           1 'jobcond.jcl:7:3: warning: COND test (4095,LT) is true for no return code: it never ends job PAYJOB2.*\[PLB-J022\]' \
    -- check --no-config $jx/jobcond.jcl
check_absent "JOB COND=(4,LT)"            'jobcond.jcl:10:' \
    -- check --no-config $jx/jobcond.jcl
check "a COND code above 4095"           1 'condbad.jcl:2:3: error: COND test (5000,LT) of PAYJOB has a code above 4095.*\[PLB-J033\]' \
    -- check --no-config $jx/condbad.jcl
check "a COND operator GTE"               1 'condbad.jcl:4:3: error: COND test (4,GTE) of EXTRACT has operator GTE,.*\[PLB-J033\]' \
    -- check --no-config $jx/condbad.jcl
check "nine COND tests"                   1 'condbad.jcl:7:3: error: COND of REPORT has 9 return code tests.*\[PLB-J033\]' \
    -- check --no-config $jx/condbad.jcl
check "eight COND tests and EVEN"         1 'condbad.jcl:10:3: error: COND of SUMMARY has 8 return code tests.*\[PLB-J033\]' \
    -- check --no-config $jx/condbad.jcl
check_absent "eight tests, or seven with ONLY" 'condbad.jcl:1[35]:.*PLB-J033' \
    -- check --no-config $jx/condbad.jcl
check "LRECL above 32760"                 1 'lreclbad.jcl:5:3: error: DD BIG codes LRECL=40000: above 32760.*\[PLB-J034\]' \
    -- check --no-config $jx/lreclbad.jcl
check "LRECL=0 for fixed records"         1 'lreclbad.jcl:6:3: error: DD EMPTY codes LRECL=0: only RECFM=U takes 0.*\[PLB-J034\]' \
    -- check --no-config $jx/lreclbad.jcl
check "a variable LRECL below 5"          1 'lreclbad.jcl:7:3: error: DD TINY codes LRECL=4: below 5.*\[PLB-J034\]' \
    -- check --no-config $jx/lreclbad.jcl
check_absent "LRECL allowed"              'lreclbad.jcl:1[0-3]:.*PLB-J034' \
    -- check --no-config $jx/lreclbad.jcl
check "EXPDT day past the year's end"    1 'retain.jcl:5:3: error: DD YEAREND codes EXPDT=2024/400,.*\[PLB-J035\]' \
    -- check --no-config $jx/retain.jcl
check "EXPDT day 366 of 2023"             1 'retain.jcl:6:3: error: DD NOLEAP codes EXPDT=2023/366,.*\[PLB-J035\]' \
    -- check --no-config $jx/retain.jcl
check "RETPD above 93000"                 1 'retain.jcl:7:3: error: DD LONG codes RETPD=99999,.*\[PLB-J035\]' \
    -- check --no-config $jx/retain.jcl
check "EXPDT and RETPD both"              1 'retain.jcl:8:3: error: DD BOTH codes both EXPDT and RETPD.*\[PLB-J035\]' \
    -- check --no-config $jx/retain.jcl
check "RETPD of a temporary data set"     1 'retain.jcl:9:3: error: DD WORK gives the temporary data set &&WORK.*\[PLB-J035\]' \
    -- check --no-config $jx/retain.jcl
check_absent "EXPDT and RETPD allowed"    'retain.jcl:1[2-5]:.*PLB-J035' \
    -- check --no-config $jx/retain.jcl
check "a SPACE unit that is not one"     1 'spacebad.jcl:5:3: error: DD TRACKS codes SPACE with TRACKS,.*\[PLB-J036\]' \
    -- check --no-config $jx/spacebad.jcl
check "a SPACE quantity above 16777215"   1 'spacebad.jcl:6:3: error: DD HUGE codes SPACE with (20000000,5),.*\[PLB-J036\]' \
    -- check --no-config $jx/spacebad.jcl
check "a SPACE option that is not one"    1 'spacebad.jcl:7:3: error: DD FREE codes SPACE with RELEASE,.*\[PLB-J036\]' \
    -- check --no-config $jx/spacebad.jcl
check_absent "SPACE forms the Reference shows" 'spacebad.jcl:1[0-2]:.*PLB-J036' \
    -- check --no-config $jx/spacebad.jcl
check_absent "SPACE=(TRK,(20,,2))"        'spacebad.jcl:9:.*PLB-J036' \
    -- check --no-config $jx/spacebad.jcl
check "a DISP status that is not one"    1 'dispbad.jcl:5:3: error: DD NEWER codes DISP with NEWW,.*\[PLB-J037\]' \
    -- check --no-config $jx/dispbad.jcl
check "a DISP disposition that is not one" 1 'dispbad.jcl:6:3: error: DD KEPT codes DISP with KEEPP,.*\[PLB-J037\]' \
    -- check --no-config $jx/dispbad.jcl
check "PASS after an abnormal end"        1 'dispbad.jcl:7:3: error: DD PASSED codes DISP with PASS, an abnormal-end.*\[PLB-J037\]' \
    -- check --no-config $jx/dispbad.jcl
check "a fourth DISP subparameter"        1 'dispbad.jcl:8:3: error: DD FOUR codes DISP with KEEP, a fourth.*\[PLB-J037\]' \
    -- check --no-config $jx/dispbad.jcl
check_absent "DISP forms the Reference shows" 'dispbad.jcl:1[0-3]:.*PLB-J037' \
    -- check --no-config $jx/dispbad.jcl
check "OUTPUT naming no OUTPUT statement" 1 'output.jcl:7:3: error: DD LIST codes OUTPUT=\*.REPROT, but no OUTPUT statement.*\[PLB-J038\]' \
    -- check --no-config $jx/output.jcl
check "OUTPUT naming a later statement"   1 'output.jcl:8:3: error: DD EARLY codes OUTPUT=\*.LATER,.*\[PLB-J038\]' \
    -- check --no-config $jx/output.jcl
check "OUTPUT of another step as *.name"  1 'output.jcl:18:3: error: DD NOTHERE codes OUTPUT=\*.LOCAL,.*\[PLB-J038\]' \
    -- check --no-config $jx/output.jcl
check "OUTPUT=*.step.name not in the step" 1 'output.jcl:20:3: error: DD BADSTEP codes OUTPUT=\*.PRINT.NONE, but step PRINT has no OUTPUT statement.*\[PLB-J038\]' \
    -- check --no-config $jx/output.jcl
check_absent "OUTPUT references that resolve" 'output.jcl:1[2-6]:.*PLB-J038' \
    -- check --no-config $jx/output.jcl
check "HOLD=YESS"                         1 'ddvalue.jcl:5:3: error: DD HELD codes HOLD=YESS, not YES, Y, NO, or N.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "FREE=EOJ"                          1 'ddvalue.jcl:6:3: error: DD FREED codes FREE=EOJ,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "SPIN=UNALLOCATE"                   1 'ddvalue.jcl:7:3: error: DD SPUN codes SPIN=UNALLOCATE,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "AVGREC=B"                          1 'ddvalue.jcl:8:3: error: DD AVG codes AVGREC=B,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "RECORG=KSDS"                       1 'ddvalue.jcl:9:3: error: DD KSDS codes RECORG=KSDS,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check_absent "values the Reference lists" 'ddvalue.jcl:1[1-4]:.*PLB-J039' \
    -- check --no-config $jx/ddvalue.jcl
check "DSNTYPE=PDSE"                      1 'ddvalue.jcl:16:3: error: DD PDSE codes DSNTYPE=PDSE,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "DSNTYPE=(LIBRARY,3)"               1 'ddvalue.jcl:17:3: error: DD VER3 codes DSNTYPE=(LIBRARY,3),.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check_absent "DSNTYPE=(LIBRARY,2)"        'ddvalue.jcl:19:.*PLB-J039' \
    -- check --no-config $jx/ddvalue.jcl
check_absent "DSNTYPE=LARGE"              'ddvalue.jcl:20:.*PLB-J039' \
    -- check --no-config $jx/ddvalue.jcl
check "DSORG=IS"                          1 'ddvalue.jcl:22:3: error: DD INDEXED codes DSORG=IS,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "DSORG=PDS"                         1 'ddvalue.jcl:23:3: error: DD LIBR codes DSORG=PDS,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check_absent "DSORG=PS and PO"            'ddvalue.jcl:2[56]:.*PLB-J039' \
    -- check --no-config $jx/ddvalue.jcl
check "a LABEL type that is not one"      1 'ddvalue.jcl:28:3: error: DD TAPE1 codes STD in LABEL,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check "INPUT in LABEL"                    1 'ddvalue.jcl:29:3: error: DD TAPE2 codes INPUT in LABEL,.*\[PLB-J039\]' \
    -- check --no-config $jx/ddvalue.jcl
check_absent "LABEL forms the Reference shows" 'ddvalue.jcl:3[1-3]:.*PLB-J039' \
    -- check --no-config $jx/ddvalue.jcl
check "RECFM letters out of order"       1 'recfm.jcl:4:3: error: DD OUTBF codes RECFM=BF,.*\[PLB-J040\]' \
    -- check --no-config $jx/recfm.jcl
check "RECFM in DCB with a doubled letter" 1 'recfm.jcl:5:3: error: DD OUTFBB codes RECFM=FBB,.*\[PLB-J040\]' \
    -- check --no-config $jx/recfm.jcl
check "RECFM with both A and M"           1 'recfm.jcl:6:3: error: DD OUTAM codes RECFM=FBAM,.*\[PLB-J040\]' \
    -- check --no-config $jx/recfm.jcl
check_absent "RECFM=FBA and VBS"          'recfm.jcl:[89]:.*PLB-J040' \
    -- check --no-config $jx/recfm.jcl
check_absent "RECFM=DBA, U, and VBSTM"    'recfm.jcl:1[0-2]:.*PLB-J040' \
    -- check --no-config $jx/recfm.jcl
check "RECORG with RECFM"                 1 'ddpair.jcl:5:3: warning: DD KSDS codes RECORG with RECFM,.*\[PLB-J041\]' \
    -- check --no-config $jx/ddpair.jcl
check "AVGREC with SPACE in tracks"       1 'ddpair.jcl:6:3: warning: DD RECS codes AVGREC with SPACE in TRK,.*\[PLB-J041\]' \
    -- check --no-config $jx/ddpair.jcl
check "LRECL and DCB=LRECL"               1 'ddpair.jcl:8:3: warning: DD TWICE codes LRECL with DCB=LRECL,.*\[PLB-J041\]' \
    -- check --no-config $jx/ddpair.jcl
check "RECORG with DCB=DSORG"             1 'ddpair.jcl:10:3: warning: DD ESDS codes RECORG with DCB=DSORG,.*\[PLB-J041\]' \
    -- check --no-config $jx/ddpair.jcl
check_absent "parameters that go together" 'ddpair.jcl:1[2-4]:.*PLB-J041' \
    -- check --no-config $jx/ddpair.jcl
check "RD=RESTART on a JOB statement"     1 'execval.jcl:2:3: error: job EXECJOB codes RD=RESTART,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check "ADDRSPC=VIRTUAL"                   1 'execval.jcl:4:3: error: step LOAD codes ADDRSPC=VIRTUAL,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check "MEMLIMIT=10GB"                     1 'execval.jcl:5:3: error: step SORT codes MEMLIMIT=10GB,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check "MEMLIMIT above 16384P"             1 'execval.jcl:6:3: error: step BIG codes MEMLIMIT=20000P,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check_absent "ADDRSPC=REAL, RD=RNC, 16384P" 'execval.jcl:[89]:.*PLB-J042' \
    -- check --no-config $jx/execval.jcl
check_absent "MEMLIMIT=NOLIMIT and 10G"   'execval.jcl:1[01]:.*PLB-J042' \
    -- check --no-config $jx/execval.jcl
check "TYPRUN=CHECK"                      1 'execval.jcl:13:3: error: job TYPJOB codes TYPRUN=CHECK,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check "PRTY=20"                           1 'execval.jcl:14:3: error: job PRTYJOB codes PRTY=20,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check "JESLOG=SPUN"                       1 'execval.jcl:15:3: error: job LOGJOB codes JESLOG=SPUN,.*\[PLB-J042\]' \
    -- check --no-config $jx/execval.jcl
check_absent "TYPRUN, PRTY, JESLOG listed" 'execval.jcl:17:.*PLB-J042' \
    -- check --no-config $jx/execval.jcl
check "a JOBLIB after another DD"        1 'joblib.jcl:10:3: error: JOBLIB DD after DD JOBCAT:.*\[PLB-J043\]' \
    -- check --no-config $jx/joblib.jcl
check "a JOBLIB after an EXEC"            1 'joblib.jcl:15:3: error: JOBLIB DD after EXEC STEP1:.*\[PLB-J043\]' \
    -- check --no-config $jx/joblib.jcl
check "a JOBLIB in a procedure"           1 'joblibp.prc:4:3: error: JOBLIB DD in a procedure.*\[PLB-J043\]' \
    -- check --no-config $jx/joblibp.prc
check_absent "a JOBLIB right after the JOB statement" 'joblib.jcl:4:.*PLB-J043' \
    -- check --no-config $jx/joblib.jcl
check "a JCLLIB after the first EXEC"     1 'jcllib.jcl:8:3: error: JCLLIB after the first EXEC.*\[PLB-J044\]' \
    -- check --no-config $jx/jcllib.jcl
check "a second JCLLIB"                   1 'jcllib.jcl:12:3: error: a second JCLLIB in the job.*\[PLB-J044\]' \
    -- check --no-config $jx/jcllib.jcl
check "a JCLLIB in a procedure"           1 'jcllibp.prc:3:3: error: JCLLIB in a procedure.*\[PLB-J044\]' \
    -- check --no-config $jx/jcllibp.prc
check_absent "one JCLLIB before the first EXEC" 'jcllib.jcl:3:.*PLB-J044' \
    -- check --no-config $jx/jcllib.jcl
check "UNIT=AFF to a later DD"            1 'unitaff.jcl:4:3: warning: DD TAPE1 codes UNIT=AFF=TAPE2, but no earlier DD.*\[PLB-J045\]' \
    -- check --no-config $jx/unitaff.jcl
check "UNIT=AFF to a DD with FREE=CLOSE"  1 'unitaff.jcl:11:3: warning: DD TAPE5 codes UNIT=AFF=TAPE4, a DD with FREE=CLOSE.*\[PLB-J045\]' \
    -- check --no-config $jx/unitaff.jcl
check "UNIT=AFF with STORCLAS"            1 'unitaff.jcl:12:3: warning: DD TAPE6 codes UNIT=AFF with STORCLAS.*\[PLB-J045\]' \
    -- check --no-config $jx/unitaff.jcl
check_absent "UNIT=AFF to an earlier DD"  'unitaff.jcl:7:.*PLB-J045' \
    -- check --no-config $jx/unitaff.jcl
check "a volume serial of 7 characters"  1 'volser.jcl:5:3: error: DD LONG codes volume serial PAYVOL1, longer.*\[PLB-J046\]' \
    -- check --no-config $jx/volser.jcl
check "volume serial SCRTCH"              1 'volser.jcl:6:3: error: DD SCRATCH codes volume serial SCRTCH, a name the system uses.*\[PLB-J046\]' \
    -- check --no-config $jx/volser.jcl
check "volume serial L00042"              1 'volser.jcl:7:3: error: DD NOLABEL codes volume serial L00042,.*\[PLB-J046\]' \
    -- check --no-config $jx/volser.jcl
check "a volume serial named twice"       1 'volser.jcl:8:3: error: DD TWICE codes volume serial T00001, named twice.*\[PLB-J046\]' \
    -- check --no-config $jx/volser.jcl
check_absent "volume serials allowed"     'volser.jcl:1[0-2]:.*PLB-J046' \
    -- check --no-config $jx/volser.jcl
check_absent "a temporary work file deleted is fine" 'shared.jcl:16:' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/shared.jcl
check_absent "an indexed file updated with DISP=SHR is fine" 'shared.jcl:4:' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/shared.jcl
check_absent "a file opened I-O on a new data set" 'payroll.jcl:27:' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payroll.jcl $jx/payproc.prc
check "a procedure step alone needs its DDs" 1 'payproc.prc:2:3: error: step UPD has no DD PAYLOG' \
    -- check --no-config $jx/payupd.cob $jx/paylog.cob $jx/payproc.prc
check "a JCL file that cannot be read"    1 'JL001' \
    -- check --no-config $jx/payupd.cob $jx/missing.jcl
check "packed-even-digits is off by default" 0 '^$' \
    -- check --no-config tests/fixtures/rules/packed.cob
check "packed-even-digits finds even counts" 0 'packed.cob:7:9: note: TOTAL is packed with 4 digits; 5 take the same bytes \[PLB-M015\]' \
    -- check --no-config --enable packed-even-digits tests/fixtures/rules/packed.cob
check "packed-even-digits counts decimals"  0 'packed.cob:8:9: note: RATE is packed with 6 digits; 7 take the same bytes' \
    -- check --no-config --enable packed-even-digits tests/fixtures/rules/packed.cob
check_absent "odd counts and other usages are fine" 'packed.cob:\(9\|10\|11\):' \
    -- check --no-config --enable packed-even-digits tests/fixtures/rules/packed.cob
check "dump bms lists maps and fields"     0 'orders.bms:8:     field ORDNUM at 3,10 length 8 input numeric' \
    -- dump bms tests/golden/bms/orders.bms
check "dump bms of a missing file"         2 'cannot read tests/golden/bms/missing.bms' \
    -- dump bms tests/golden/bms/missing.bms
bx=tests/fixtures/bms/screens.bms
check "BMS fields at the same position"   1 'screens.bms:8:1: error: field STOPPER overlaps field at 3,1 of map SCRMAP \[PLB-B001\]' \
    -- check --no-config $bx
check "a BMS field one byte too long"      1 'screens.bms:12:1: error: field FKEYS overlaps field ERRMSG of map SCRMAP' \
    -- check --no-config $bx
check "a BMS field with OCCURS"            1 'screens.bms:10:1: error: field NEXTTO overlaps field LINES of map SCRMAP' \
    -- check --no-config $bx
check_absent "adjacent BMS fields are fine" 'screens.bms:[456]:' \
    -- check --no-config $bx
check "a BMS field past the end of its map" 1 'screens.bms:14:1: error: field WIDE ends past the end of map SMALL (5 lines of 40) \[PLB-B002\]' \
    -- check --no-config $bx
check "a map its mapset does not define" 1 'screens.cob:20:24: error: map HELPMAP is not defined in mapset SCRSET \[PLB-B003\]' \
    -- check --no-config tests/fixtures/bms/screens.cob $bx
check "a map without MAPSET is in the mapset of its name" 1 'screens.cob:30:24: error: map SCRSET is not defined in mapset SCRSET' \
    -- check --no-config tests/fixtures/bms/screens.cob $bx
check_absent "maps named at run time and mapsets outside the run" 'screens.cob:\(1[58]\|2[58]\):[0-9]*: error' \
    -- check --no-config tests/fixtures/bms/screens.cob $bx
check "dump calls lists the maps a program uses" 0 '^map SCRMAP of mapset SCRSET tests/fixtures/bms/screens.cob:17:27 received by SCREENS$' \
    -- dump calls tests/fixtures/bms/screens.cob
sm="tests/fixtures/bms/custmnt.cob $bx"
check "a symbolic map without a field of the map" 1 'scrmap.cpy:3:5: error: symbolic map SCRMAPI has no item STOPPERI for field STOPPER of map SCRMAP \[PLB-B004\]' \
    -- check --no-config $sm
check "a symbolic map item of another length" 1 'scrmap.cpy:14:9: error: CUSTNMI has 25 characters, but field CUSTNM of map SCRMAP has LENGTH=30' \
    -- check --no-config $sm
check "a symbolic map item the map does not have" 1 'scrmap.cpy:19:9: error: symbolic map item OLDFLDI is for a field OLDFLD that map SCRMAP does not have' \
    -- check --no-config $sm
check_absent "matching symbolic map items" 'scrmap.cpy:\(9\|24\|28\|32\):' \
    -- check --no-config $sm
check "dump csd lists resources"          0 'orders.csd:4: transaction ORD1 group ORDERS program ORDMENU' \
    -- dump csd tests/golden/csd/orders.csd
check "dump csd of a missing file"         2 'cannot read tests/golden/csd/missing.csd' \
    -- dump csd tests/golden/csd/missing.csd
kx="tests/fixtures/cics/ordmenu.cob tests/golden/csd/orders.csd"
check "a CICS file the definitions do not have" 1 'ordmenu.cob:16:32: error: EXEC CICS READ names file ORDHIST, which the CICS definitions do not define \[PLB-K001\]' \
    -- check --no-config $kx
check "a CICS program the definitions do not have" 1 'ordmenu.cob:28:28: error: EXEC CICS LINK names program ORDPRICE' \
    -- check --no-config $kx
check "a transaction the definitions do not have" 1 'ordmenu.cob:32:30: error: EXEC CICS RETURN names transaction ORD9' \
    -- check --no-config $kx
check_absent "defined, supplied, and run programs' resources" 'ordmenu.cob:\(12\|20\|23\|29\|30\|31\):[0-9]*: error' \
    -- check --no-config $kx
check_absent "no definitions, no CICS resource checks" 'PLB-K001' \
    -- check --no-config tests/fixtures/cics/ordmenu.cob
check "dump calls lists CICS resources"    0 '^resource file ORDFILE tests/fixtures/cics/ordmenu.cob:12:25 READ by ORDMENU$' \
    -- dump calls tests/fixtures/cics/ordmenu.cob
ax="$jx/payupd.cob $jx/paylog.cob $jx/payold.cob $jx/paymenu.cob $jx/payrpt.cob $jx/payroll.jcl $jx/payproc.prc $jx/paymenu.csd"
check "a program nothing reaches"         0 'payold.cob:3:13: note: program PAYOLD is not called, run by a job step, or started by a transaction of the run \[PLB-A001\]' \
    -- check --no-config --fail-on never $ax
check_absent "programs run, called, started, or named" 'PLB-A001.*\(PAYUPD\|PAYLOG\|PAYMENU\|PAYRPT\)\|program \(PAYUPD\|PAYLOG\|PAYMENU\|PAYRPT\) is not' \
    -- check --no-config --fail-on never $ax
check_absent "no JCL or definitions, no unused programs" 'PLB-A001' \
    -- check --no-config --fail-on never $jx/payupd.cob $jx/payold.cob
check "dump jcl shows what IMS and TSO steps run" 0 'step DB2STEP pgm IKJEFT01 runs PAYDB2$' \
    -- dump jcl tests/golden/jcl/starters.jcl
check "inventory lists programs and how they start" 0 '^program PAYUPD batch tests/fixtures/jcl/payupd.cob:3$' \
    -- inventory $ax
check "inventory lists what starts a program" 0 '^  run by step UPD of procedure PAYPROC$' \
    -- inventory $ax
check "inventory lists a program's files"  0 '^  file MASTER dd PAYMAST i-o$' \
    -- inventory $ax
check "inventory counts menu names"         0 '^program PAYRPT online .*$' \
    -- inventory $ax
check "inventory lists jobs"                0 '^  step NIGHTLY runs procedure PAYPROC$' \
    -- inventory $ax
check "inventory lists transactions"        0 '^transaction PAYM runs PAYMENU$' \
    -- inventory $ax
vx="tests/fixtures/cics/ordmenu.cob tests/golden/csd/orders.csd tests/fixtures/bms/screens.cob tests/fixtures/bms/custmnt.cob tests/fixtures/bms/screens.bms tests/golden/rules/q001-sql-tables.cob tests/golden/jcl/starters.jcl tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob"
check "inventory lists CICS resources"    0 '^  uses file ORDHIST (READ)$' -- inventory $vx
check "inventory lists a program's maps"  0 '^  map HELPMAP of mapset SCRSET$' -- inventory $vx
check "inventory lists a program's tables" 0 '^  table PAY.LEAVERS select delete$' -- inventory $vx
check "inventory lists who uses a map"    0 '^  used by CUSTMNT$' -- inventory $vx
check "inventory lists IMS and DB2 steps" 0 '^  step DB2STEP runs PAYDB2 through IKJEFT01$' -- inventory $vx
n=$((n + 1))
if "$bin" inventory --report json $vx | python3 -c '
import json, sys
doc = json.load(sys.stdin)
programs = {p["name"]: p for p in doc["programs"]}
assert programs["TABLES"]["tables"][0] == {"name": "PAY.EMPLOYEE", "uses": "declare select update"}
assert {"map": "SCRMAP", "mapset": "SCRSET"} in programs["SCREENS"]["maps"]
assert {"kind": "file", "name": "ORDHIST"} in programs["ORDMENU"]["resources"]
assert programs["PAYLOG"]["calledBy"] == ["PAYUPD"]
assert doc["transactions"][0] == {"name": "ORD1", "program": "ORDMENU"}
assert doc["jobs"][0]["steps"][1]["runs"] == "PAYDB2"
' 2>/dev/null; then
    echo "ok $n - inventory json holds each part"
else
    failed=$((failed + 1))
    echo "not ok $n - inventory json holds each part"
fi
check "inventory refuses sarif"             2 "invalid --report format 'sarif' (expected text or json)" \
    -- inventory --report sarif $jx/payupd.cob
n=$((n + 1))
if "$bin" inventory --report json $ax tests/fixtures/bms/screens.bms tests/fixtures/bms/screens.cob \
        | python3 -m json.tool >/dev/null 2>&1; then
    echo "ok $n - inventory json is valid"
else
    failed=$((failed + 1))
    echo "not ok $n - inventory json is valid"
fi
check "dump ims lists segments and PCBs"   0 'orders.psb:8:   pcb type DB dbd ORDERDB procopt A' \
    -- dump ims tests/golden/ims/orders.psb
check "dump ims of a missing file"         2 'cannot read tests/golden/ims/missing.dbd' \
    -- dump ims tests/golden/ims/missing.dbd
ix="tests/fixtures/ims/ordupd.cob tests/golden/ims/orderdb.dbd tests/golden/ims/orders.psb tests/fixtures/ims/bad.psb"
check "a PCB for an unknown database"     1 'bad.psb:3:1: error: PCB names database NOSUCHDB, which no DBD of the run defines \[PLB-I001\]' \
    -- check --no-config $ix
check "a sensitive segment the database lacks" 1 'bad.psb:7:1: error: sensitive segment ORDITEM is not a segment of database ORDERDB \[PLB-I002\]' \
    -- check --no-config $ix
check "a sensitive segment under another parent" 1 'bad.psb:8:1: error: sensitive segment ORDNOTE has parent ORDLINE, but its parent in database ORDERDB is ORDER' \
    -- check --no-config $ix
check "a DL/I call on a segment the PSB lacks" 1 'ordupd.cob:16:39: error: EXEC DLI GNP names segment ORDNOTE, which PSB ORDREAD is not sensitive to \[PLB-I003\]' \
    -- check --no-config $ix
check "a DL/I call PROCOPT does not allow" 1 'ordupd.cob:15:40: error: EXEC DLI REPL on segment ORDER, but no PCB of PSB ORDREAD for it has PROCOPT R or A \[PLB-I004\]' \
    -- check --no-config $ix
check_absent "DL/I calls the PSB allows"  'ordupd.cob:1[34]:[0-9]*: error' \
    -- check --no-config $ix
check "dump calls lists DL/I calls"       0 '^dli SCHD psb ORDREAD tests/fixtures/ims/ordupd.cob:12:24 by ORDUPD$' \
    -- dump calls tests/fixtures/ims/ordupd.cob
lx=tests/fixtures/layout
check "layout of a copybook"              0 '^record ORDER-RECORD tests/fixtures/layout/order.cpy:3, 59 bytes$' \
    -- layout $lx/order.cpy
check "layout shows packed items"         0 '^  05    ORDER-AMOUNT  *S9(9)V99  *COMP-3  *12  *6$' \
    -- layout $lx/order.cpy
check "layout shows OCCURS"               0 '^  05    ORDER-LINE  *26  *8  *3$' \
    -- layout $lx/order.cpy
check "layout of a program's records"     0 '^ORDER-RECORD,10,ORDER-YEAR,"9(4)",,18,4,,$' \
    -- layout --report csv $lx/orders.cob
check "layout csv names what an item redefines" 0 '^ORDER-RECORD,5,ORDER-DATE-PARTS,,,18,8,,ORDER-DATE$' \
    -- layout --report csv $lx/order.cpy
check_absent "layout leaves out constants and condition names" 'MAX-ORDERS\|ORDER-OPEN' \
    -- layout $lx/orders.cob
check "layout as Markdown"                 0 '^| 05 | ORDER-AMOUNT | `S9(9)V99` | COMP-3 | 12 | 6 |  |$' \
    -- layout --report md $lx/order.cpy
check "layout refuses sarif"              2 "invalid --report format 'sarif' (expected text, json, csv, or md)" \
    -- layout --report sarif $lx/order.cpy
dx=tests/golden
check "doc heads each program"            0 '^# CUSTMNT$' \
    -- doc -I tests/fixtures/bms tests/fixtures/bms/custmnt.cob tests/fixtures/bms/screens.bms
check "doc lists what a program uses"     0 '^- uses mapset SCRSET (RECEIVE)$' \
    -- doc -I tests/fixtures/bms tests/fixtures/bms/custmnt.cob tests/fixtures/bms/screens.bms
check "doc lists paragraphs"              0 '^| DECIDE | 17 | 13 | 13 | FINISH | DECIDE, FINISH | yes |$' \
    -- doc $dx/metrics/complexity.cob
check "doc marks paragraphs that never run" 0 '^| FIRST-PARA | 2 | 1 | 1 |  |  | \*\*never\*\* |$' \
    -- doc $dx/rules/c001-sections.cob
check "doc lists records"                 0 '^### ORDER-RECORD (59 bytes)$' \
    -- doc $lx/orders.cob
check "doc says when there are no records" 0 '^The program has no records.$' \
    -- doc $dx/parser/nested.cob
check "doc places nested programs"        0 '^Nested in \*\*OUTER\*\* (common). Source: `tests/golden/calls/scopes.cob:23`.$' \
    -- doc $dx/calls/scopes.cob
check "doc lists callers of nested programs" 0 '^- called by OUTER$' \
    -- doc $dx/calls/scopes.cob
check "doc writes a line of one statement" 0 '^9 lines, 1 statement, complexity 1, maintainability index 70 of 100.$' \
    -- doc $dx/calls/scopes.cob
check "doc writes the size of a one-byte record" 0 '^### COUNTER (1 byte)$' \
    -- doc $dx/metrics/complexity.cob
check "doc lists the data sets of a batch program" 0 '^| PAYROLL.NIGHTLY | UPD.PAYLOG | `PAY.LOG` | written |$' \
    -- doc tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/payroll.jcl tests/fixtures/jcl/payproc.prc
check_absent "doc has no data sets without JCL" '^## Data sets$' \
    -- doc tests/fixtures/jcl/payupd.cob
check "doc indexes several programs"      0 '^| \[INNER-A\](#inner-a) | nested | `tests/golden/calls/scopes.cob:23` |$' \
    -- doc $dx/calls/scopes.cob
check_absent "doc has no index for one program" '^# Programs$' \
    -- doc $dx/metrics/complexity.cob
check "doc refuses --report"              2 'doc writes Markdown only' \
    -- doc --report json $dx/metrics/complexity.cob
fx="-I tests/fixtures/fields tests/fixtures/fields/custread.cob tests/fixtures/fields/custlist.cob"
check "fields counts the programs naming an item" 0 '^  05 CUST-NAME  *line 4, named by 1 of 2 programs$' \
    -- fields $fx
check "fields counts record keys"         0 '^  05 CUST-ID  *line 3, named by 1 of 2 programs$' \
    -- fields $fx
check "fields counts DEPENDING ON objects" 0 '^  10 CUST-ORDERS  *line 9, named by 2 of 2 programs$' \
    -- fields $fx
check "fields summarizes each copybook"   0 '^copybook tests/fixtures/fields/custrec.cpy: 9 items, 3 named by no program; copied by 2$' \
    -- fields $fx
check_absent "fields --unused leaves out named items" 'CUST-NAME' \
    -- fields --unused $fx
check "fields --unused keeps unnamed items" 0 '^  05 CUST-FAX  *line 7, named by no program$' \
    -- fields --unused $fx
check "fields refuses csv"                2 "invalid --report format 'csv' (expected text or json)" \
    -- fields --report csv $fx
n=$((n + 1))
if "$bin" fields --report json $fx | python3 -c '
import json, sys
book = json.load(sys.stdin)["copybooks"][0]
items = {i["name"]: i for i in book["items"]}
assert book["copiedBy"] == 2
assert items["CUST-FAX"]["namedBy"] == 0
assert items["CUST-ORDERS"]["namedBy"] == 2
'; then
    echo "ok $n - fields json"
else
    echo "not ok $n - fields json"
fi
rl="tests/fixtures/reclen"
check "programs disagree on a data set's record length" 1 'acctjob.jcl:7:3: warning: PROD.ACCT.EXTRACT has 350-byte records in ACCTRPT but 300-byte ones in ACCTEXT (DD on line 3) \[PLB-A002\]' \
    -- check $rl/acctext.cob $rl/acctrpt.cob $rl/acctsum.cob $rl/acctjob.jcl
check_absent "a use that agrees with the first is fine" 'acctjob.jcl:10:.*PLB-A002' \
    -- check $rl/acctext.cob $rl/acctrpt.cob $rl/acctsum.cob $rl/acctjob.jcl
check_absent "records of several lengths are not compared" 'HIST.*PLB-A002' \
    -- check $rl/acctext.cob $rl/acctrpt.cob $rl/acctsum.cob $rl/acctjob.jcl
ex="tests/fixtures/exitprog"
check "EXIT PROGRAM in a program a step runs" 1 'rptmain.cob:11:12: warning: EXIT PROGRAM does nothing in RPTMAIN, which step REPORT runs as the main program: execution goes on past it; GOBACK ends the program \[PLB-C053\]' \
    -- check $ex/rptmain.cob $ex/rptcalc.cob $ex/rptjob.jcl
check_absent "EXIT PROGRAM in a called program" 'rptcalc.cob:.*PLB-C053' \
    -- check $ex/rptmain.cob $ex/rptcalc.cob $ex/rptjob.jcl
check_absent "EXIT PROGRAM without JCL"       'PLB-C053' \
    -- check $ex/rptmain.cob $ex/rptcalc.cob
dx2="-I tests/fixtures/duplicates tests/fixtures/duplicates/billing.cob tests/fixtures/duplicates/invoice.cob"
check "duplicates groups paragraphs with the same code" 0 '^2 copies of 27 tokens, 5 statements:$' \
    -- duplicates --min-tokens 10 $dx2
check "duplicates ignores layout, case, and comments" 0 '^  tests/fixtures/duplicates/invoice.cob:14 COMPUTE-TAX in INVOICE$' \
    -- duplicates --min-tokens 10 $dx2
check_absent "duplicates tells another literal apart" 'COMPUTE-TAX-LOW' \
    -- duplicates --min-tokens 10 $dx2
check_absent "duplicates leaves out copybook paragraphs" 'SHOW-ERROR' \
    -- duplicates --min-tokens 10 $dx2
check "duplicates leaves out short paragraphs" 0 '^no paragraphs with the same code$' \
    -- duplicates $dx2
check "duplicates refuses a bad --min-tokens" 2 "invalid --min-tokens 'x' (expected a number)" \
    -- duplicates --min-tokens x $dx2
n=$((n + 1))
if "$bin" duplicates --min-tokens 10 --report json $dx2 | python3 -c '
import json, sys
[group] = json.load(sys.stdin)["groups"]
assert group["tokens"] == 27 and group["statements"] == 5
assert [p["name"] for p in group["paragraphs"]] == ["ADD-TAX", "COMPUTE-TAX"]
'; then
    echo "ok $n - duplicates json"
else
    failed=$((failed + 1)); echo "not ok $n - duplicates json"
fi
lin="tests/fixtures/lineage/rpt.cob"
check "lineage shows what gives an item its value" 0 '^  ADD WS-AMOUNT WS-TAX TO WS-TOTAL  (line 23)$' \
    -- lineage WS-TOTAL $lin
check "lineage follows a record to its READ" 0 '^          READ IN-FILE  (line 20)$' \
    -- lineage WS-TOTAL $lin
check "lineage shows an item once"         0 '^        WS-AMOUNT  tests/fixtures/lineage/rpt.cob:13  (see above)$' \
    -- lineage WS-TOTAL $lin
check_absent "lineage stops at --depth"    'MOVE IN-AMT' \
    -- lineage WS-TOTAL --depth 1 $lin
check "lineage --forward shows where a value goes" 0 '^          MOVE WS-TOTAL TO RL-TOTAL  (line 24)$' \
    -- lineage IN-AMT --forward $lin
n=$((n + 1))
if "$bin" lineage WS-TOTAL --report json $lin | python3 -c '
import json, sys
nodes = json.load(sys.stdin)["lineage"]
by_id = {node["id"]: node for node in nodes}
assert nodes[0]["parent"] == 0 and nodes[0]["name"] == "WS-TOTAL"
read = [node for node in nodes if node.get("text") == "READ IN-FILE"]
assert read and by_id[read[0]["parent"]]["name"] == "IN-AMT"
assert any(node.get("seen") for node in nodes)
'; then
    echo "ok $n - lineage json"
else
    failed=$((failed + 1)); echo "not ok $n - lineage json"
fi
calls_fx="tests/fixtures/calls/billing.cob tests/fixtures/calls/custlook.cob"
check "lineage names the caller's argument of a LINKAGE item" 0 \
    '^  <- argument 2 of CALL "CUSTLOOK" in BILLING  tests/fixtures/calls/billing.cob:9: CUST-NAME$' \
    -- lineage LK-CUST-NAME $calls_fx
check "lineage --forward names the parameter a CALL passes to" 0 \
    '^    -> parameter 1 of CUSTLOOK: LK-CUST-ID$' \
    -- lineage CUST-ID --forward $calls_fx
check "lineage --forward with the program called not in the run" 0 \
    '^    -> argument 1 of CUSTLOOK, which is not in the run$' \
    -- lineage CUST-ID --forward tests/fixtures/calls/billing.cob
n=$((n + 1))
if "$bin" lineage LK-CUST-NAME --report json $calls_fx | python3 -c '
import json, sys
nodes = json.load(sys.stdin)["lineage"]
by_id = {node["id"]: node for node in nodes}
calls = [node for node in nodes if node["kind"] == "call"]
assert len(calls) == 2
assert [by_id[c["parent"]]["name"] for c in calls] == ["LK-CUST-NAME", "LK-CUST-ID"]
assert calls[0]["side"] == "caller" and calls[0]["program"] == "BILLING"
assert calls[0]["position"] == 2 and calls[0]["name"] == "CUST-NAME"
assert calls[0]["file"].endswith("billing.cob") and calls[0]["line"] == 9
'; then
    echo "ok $n - lineage json call nodes"
else
    failed=$((failed + 1)); echo "not ok $n - lineage json call nodes"
fi
sql_lin="tests/fixtures/lineage/acctsql.cob"
check "lineage names the column a SELECT INTO reads" 0 '^        <- column BALANCE of ACCOUNT$' \
    -- lineage WS-NEW-BALANCE $sql_lin
check "lineage finds a FETCH's table in its cursor" 0 '^        <- column CREDIT_LIMIT of ACCOUNT$' \
    -- lineage WS-NEW-BALANCE $sql_lin
check "lineage --forward names the column UPDATE stores" 0 '^        -> column BALANCE of ACCOUNT$' \
    -- lineage WS-LIMIT --forward $sql_lin
check "lineage writes host variables with their colon" 0 'INTO :WS-ACCT-ID :WS-LIMIT END-EXEC  (line 22)$' \
    -- lineage WS-LIMIT $sql_lin
check "lineage json has column nodes"      0 '"kind": "column", "text": "<- column BALANCE of ACCOUNT", "table": "ACCOUNT", "column": "BALANCE"' \
    -- lineage WS-NEW-BALANCE --report json $sql_lin
crud_lin="tests/fixtures/crud/acctmnt.cob"
check "lineage names the file a CICS READ reads" 0 '^    <- CICS READ of file LIT-ACCTFILE ("ACCTDAT")$' \
    -- lineage WS-ACCOUNT-REC $crud_lin
check "lineage --forward names the file a CICS REWRITE writes" 0 '^    -> CICS REWRITE of file "ACCTDAT"$' \
    -- lineage WS-ACCOUNT-REC --forward $crud_lin
check "lineage writes literals with their quotes" 0 'EXEC CICS REWRITE FILE ("ACCTDAT") FROM (WS-ACCOUNT-REC) END-EXEC  (line 33)$' \
    -- lineage WS-ACCOUNT-REC --forward $crud_lin
check "lineage json has cics nodes"        0 '"kind": "cics", "text": "-> CICS REWRITE of file \\"ACCTDAT\\"", "command": "REWRITE", "resource": "file", "name": "\\"ACCTDAT\\""' \
    -- lineage WS-ACCOUNT-REC --forward --report json $crud_lin
check "lineage dot draws a statement once" 0 '^  n7 -> n9;$' \
    -- lineage WS-NEW-BALANCE --report dot $sql_lin
check "lineage dot points the way values go" 0 '^  n1 -> n2;$' \
    -- lineage WS-TOTAL --forward --report dot $lin
check "lineage dot labels a column"        0 '^  n5 \[label="column BALANCE of ACCOUNT", shape=ellipse, style=dashed\];$' \
    -- lineage WS-NEW-BALANCE --report dot $sql_lin
check "lineage refuses csv"                2 "invalid --report format 'csv' (expected text, json, or dot)" \
    -- lineage WS-TOTAL --report csv $lin
check "lineage of an unknown item"         1 'no data item named NOPE in the input' \
    -- lineage NOPE $lin
check "lineage needs a name"               2 'lineage needs a data item name' \
    -- lineage
crud_fx="tests/fixtures/crud/acctmnt.cob"
check "crud reads tables through cursors and updates them" 0 '^ACCTMNT   table      BANK.ACCOUNT  *- R U -$' \
    -- crud $crud_fx
check "crud counts inserts and deletes"   0 '^ACCTMNT   table      BANK.AUDIT  *C - - D$' \
    -- crud $crud_fx
check "crud finds a file by its record"  0 '^ACCTMNT   file       HIST-FILE  *C - - -$' \
    -- crud $crud_fx
check "crud takes a CICS file from a VALUE" 0 '^ACCTMNT   cics-file  ACCTDAT  *- R U -$' \
    -- crud $crud_fx
check "crud as CSV"                       0 '^ACCTMNT,table,BANK.AUDIT,Y,N,N,Y$' \
    -- crud --report csv $crud_fx
check "doc shows the tables and files a program uses" 0 '^| `BANK.AUDIT` | DB2 table | yes |  |  | yes |$' \
    -- doc $crud_fx
n=$((n + 1))
if "$bin" crud --report json $crud_fx | python3 -c '
import json, sys
rows = {(r["kind"], r["resource"]): r for r in json.load(sys.stdin)["crud"]}
assert rows[("cics-file", "ACCTDAT")]["update"] is True
assert rows[("table", "BANK.ACCOUNT")]["create"] is False
assert len(rows) == 4
'; then
    echo "ok $n - crud json"
else
    failed=$((failed + 1)); echo "not ok $n - crud json"
fi
xx="-I tests/fixtures/xref tests/fixtures/xref/acctupd.cob"
check "xref heads each program"           0 '^ACCTUPD (tests/fixtures/xref/acctupd.cob:2)$' \
    -- xref $xx
check "xref places copybook items"        0 '^    05 ACCT-BALANCE (acctrec.cpy:3)$' \
    -- xref $xx
check "xref marks the lines that change an item" 0 '^        18M 24$' \
    -- xref $xx
check "xref lists performs and THRU ends" 0 '^        13T$' \
    -- xref $xx
check "xref lists both paragraphs of an ALTER" 0 '^        14A 15G$' \
    -- xref $xx
check "xref lists nested programs"        0 '^ACCTLOG (tests/fixtures/xref/acctupd.cob:28)$' \
    -- xref $xx
check_absent "xref leaves out FILLER"     'FILLER' \
    -- xref $xx
check "xref wraps references at 79 columns" 0 '^        25M 26M .* 36M$' \
    -- xref tests/fixtures/xref/manyrefs.cob
check "xref refuses sarif"                2 "invalid --report format 'sarif' (expected text or json)" \
    -- xref --report sarif $xx
n=$((n + 1))
if "$bin" xref --report json $xx | python3 -c '
import json, sys
programs = {p["name"]: p for p in json.load(sys.stdin)["programs"]}
assert sorted(programs) == ["ACCTLOG", "ACCTUPD"]
data = {d["name"]: d for d in programs["ACCTUPD"]["data"]}
assert data["ACCT-ID"]["file"] == "tests/fixtures/xref/acctrec.cpy"
assert [(r["line"], r["use"]) for r in data["WS-COUNT"]["references"]] == [(18, "modify"), (24, "read")]
procs = {p["name"]: p for p in programs["ACCTUPD"]["procedures"]}
assert procs["MAIN"]["kind"] == "section"
assert [(r["line"], r["use"]) for r in procs["NEXT-STEP"]["references"]] == [(14, "alter"), (15, "go-to")]
assert procs["POST-EXIT"]["references"][0]["use"] == "thru"
'; then
    echo "ok $n - xref json"
else
    echo "not ok $n - xref json"
fi
n=$((n + 1))
if "$bin" layout --report json $lx/order.cpy $lx/orders.cob | python3 -c '
import json, sys
records = {r["name"]: r for r in json.load(sys.stdin)["records"]}
items = {i["name"]: i for i in records["ORDER-RECORD"]["items"]}
assert records["ORDER-RECORD"]["length"] == 59
assert items["ORDER-DATE-PARTS"]["redefines"] == "ORDER-DATE"
assert items["ORDER-LINE"]["occurs"] == 3
assert items["LINE-QTY"]["start"] == 32
' 2>/dev/null; then
    echo "ok $n - layout json is valid"
else
    failed=$((failed + 1))
    echo "not ok $n - layout json is valid"
fi
check "rules lists every rule"            0 '^PLB-C001  unreachable-code  *warning  on   ' -- rules --no-config
check "rules shows options applied"       0 '^PLB-M011  evaluate-without-other  *note     on ' \
    -- rules --no-config --enable evaluate-without-other
check "rules shows limits from the config" 0 'PLB-M009  complex-paragraph .* on .*(limit 10)$' \
    -- rules --config tests/fixtures/config/limits.conf
check "rules as JSON"                     0 '"id": "PLB-C023", "name": "subscript-out-of-range", "severity": "error", "enabled": true' \
    -- rules --no-config --report json
check "rules takes no files"              2 'rules takes no files' -- rules --no-config x.cob
check "rules has no sarif report"         2 "invalid --report format 'sarif' (expected text or json)" \
    -- rules --report sarif
sx=tests/golden/symbols
check "--define decides >>IF NAME SET"    0 '^1 PTR-NUM U size=8 .*usage=BINARY-DOUBLE' \
    -- dump symbols --no-config --define P64 $sx/conditional-compilation.cob
check "-D takes NAME=VALUE"               0 '^1 PTR-NUM U size=8 ' \
    -- dump symbols --no-config -D p64=1 $sx/conditional-compilation.cob
check "lines left out are shown as skipped" 0 'conditional-compilation.cob:12: skipped' \
    -- dump lines --no-config $sx/conditional-compilation.cob
check "--define needs a name"             2 '--define needs a name' -- check --define
check "--define rejects long names"       2 'name longer than 31 characters' \
    -- check --define ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFG x.cob
check "--tab-width reads narrow tabs"     0 '^$' \
    -- check --no-config --tab-width 4 tests/fixtures/tabs/narrow-tabs.cob
check "default tabs push text past column 72" 1 'unbalanced parenthesis' \
    -- check --no-config tests/fixtures/tabs/narrow-tabs.cob
check "--tab-width must be 1 to 12"       2 "invalid tab width '13' (expected 1 to 12)" \
    -- check --tab-width 13 x.cob
lx=tests/fixtures/lists
check "--files-from adds the files a list names" 1 'billing.cob:9:17: .*\[PLB-C014\]' \
    -- check --no-config --files-from $lx/calls.list
check "--files-from and file arguments add up" 1 'billing.cob:9:17: .*\[PLB-C014\]' \
    -- check --no-config --files-from $lx/calls.list $cx/archive.cob
check_stdin "--files-from - reads standard input" 1 'billing.cob:9:17: .*\[PLB-C014\]' \
    "$cx/billing.cob\n$cx/custlook.cob\n" -- check --no-config --files-from -
check_stdin "a last line without a newline counts" 1 'billing.cob:9:17: .*\[PLB-C014\]' \
    "$cx/billing.cob\n$cx/custlook.cob" -- check --no-config --files-from -
n=$((n + 1))
if printf '%s\n' "$cx/billing.cob" | "$bin_abs" check --no-config --files-from - 2>&1 \
        | grep -q libcob; then
    failed=$((failed + 1))
    echo "not ok $n - reading standard input draws no runtime warning"
else
    echo "ok $n - reading standard input draws no runtime warning"
fi
check "--files-from needs a file"         2 '--files-from needs a file' -- check --files-from
check "a missing list is an error"        2 'cannot read file list nope.list' \
    -- check --files-from nope.list
tmp_list=$(mktemp)
printf '%s.cob\n' "$(printf 'x%.0s' $(seq 1 600))" > "$tmp_list"
check "overlong names in a list are refused" 2 'file name longer than 512 characters in .* line 1' \
    -- check --files-from "$tmp_list"
rm -f "$tmp_list"
check "comments suppress call findings in earlier files" 0 '^$' \
    -- check $cx/archive.cob $cx/custlook.cob
check "html shows lines of files checked earlier" 1 '<mark>     9             CALL &quot;CUSTLOOK&quot;' \
    -- check --report html $cx/billing.cob $cx/custlook.cob
tmp_baseline=$(mktemp)
check "baselines key findings of earlier files by their line" 0 'wrote 1 findings' \
    -- check --write-baseline "$tmp_baseline" $cx/billing.cob $cx/custlook.cob
check_file "baseline line holds the source line" \
    '| CALL "CUSTLOOK" USING CUST-ID CUST-NAME$' "$tmp_baseline"
check "a baseline of several files hides their findings" 0 '^$' \
    -- check --baseline "$tmp_baseline" $cx/billing.cob $cx/custlook.cob
rm -f "$tmp_baseline"
check "dynamic-call is off by default"    0 '^$' -- check --disable call-argument-count --disable call-argument-mismatch --disable recursive-call $rx/c013-c015-calls.cob
check "dump calls lists parameters"       0 '^  parameter LK-CUST-ID reference 8$' -- dump calls $cx/custlook.cob
check "help lists dump calls"             0 'dump calls' -- --help
# A reader that stops early closes the pipe: plumbline ends without a
# word on standard error.
n=$((n + 1))
pipe_err=$( { "$bin_abs" rules | head -n 1 >/dev/null; } 2>&1 )
if [ -z "$pipe_err" ]; then
    echo "ok $n - a closed pipe ends plumbline quietly"
else
    failed=$((failed + 1))
    echo "not ok $n - a closed pipe ends plumbline quietly"
    printf '%s\n' "$pipe_err" | sed 's/^/    /'
fi
check "a directory is not taken for a file" 1 'tests/fixtures/impact is a directory: give its files' \
    -- check --no-config tests/fixtures/impact
check "dump lines needs files"            2 'no input files' -- dump lines
intr_fx=tests/fixtures/intrinsics
check "intrinsics without FUNCTION are undeclared" 1 'PI is not declared \[PLB-C009\]' \
    -- check --no-config $intr_fx/no-function.cob
check_absent "--intrinsics all allows them"  'PLB-C009' \
    -- check --no-config --intrinsics all $intr_fx/no-function.cob
check_absent "--intrinsics lists names"      'PLB-C009' \
    -- check --no-config --intrinsics pi,E $intr_fx/no-function.cob
check "--intrinsics allows only those listed" 1 'E is not declared \[PLB-C009\]' \
    -- check --no-config --intrinsics pi $intr_fx/no-function.cob
check "--intrinsics needs a value"          2 'needs all or a list of names' \
    -- check --intrinsics
check "invalid --format value"            2 "invalid format 'wide' (expected fixed, free, variable, xopen, terminal, cobolx, xcard, crt, or auto)" \
    -- dump lines --format wide $fx/fixed-basic.cbl
check "crt format from a directive"        0 'crt.cob:11: debug     crt   - DISPLAY "SHOWN WHEN DEBUGGING"$' \
    -- dump lines tests/fixtures/reader/crt.cob
check "crt format has page ejects"         0 'crt.cob:5: page      crt   -$' \
    -- dump lines tests/fixtures/reader/crt.cob
check "crt format does not pad a continued literal" 0 'alnum    "FIRST PART AND SECOND PART"$' \
    -- dump tokens tests/fixtures/reader/crt.cob
check "format joins a crt continuation"    0 '^    DISPLAY "FIRST PART AND SECOND PART"$' \
    -- format --to free tests/fixtures/reader/crt.cob
check "xcard format reads past column 72"  0 'xcard.cbl:6: code      xcard - DISPLAY "PAST COLUMN 72" *UPON CONSOLE$' \
    -- dump lines tests/fixtures/reader/xcard.cbl
check "xcard format pads a literal to column 255" 0 'alnum    "A LITERAL CONTINUED IN XCARD \{191\}FORMAT"$' \
    -- dump tokens tests/fixtures/reader/xcard.cbl
check "xcard format from --format"         0 'xcard.cbl:6: code      xcard' \
    -- dump lines --format xcard tests/fixtures/reader/xcard.cbl
check "cobolx format from a directive"     0 'cobolx.cob:4: debug     cblx  - DISPLAY "SHOWN WHEN DEBUGGING"$' \
    -- dump lines tests/fixtures/reader/cobolx.cob
check "cobolx format joins a continued literal" 0 'alnum    "FIRST PART AND SECOND PART"$' \
    -- dump tokens tests/fixtures/reader/cobolx.cob
check "variable format reads past column 72" 0 'variable.cbl:6: code      var   A PROCEDURE DIVISION.*TO WS-RESULT-OF-THE-COMPUTATION$' \
    -- dump lines --format variable tests/fixtures/reader/variable.cbl
check "variable format from a directive"   0 'variable-directive.cbl:7: code      var' \
    -- dump lines tests/fixtures/reader/variable-directive.cbl
check "xopen format reads its indicators"  0 'xopen.cob:10: debug     xopen - DISPLAY "COUNT " WS-COUNT$' \
    -- dump lines --format xopen tests/fixtures/reader/xopen.cob
check "xopen format has page ejects"       0 'xopen.cob:7: page      xopen -' \
    -- dump lines --format xopen tests/fixtures/reader/xopen.cob
check "terminal format joins a continued literal" 0 'alnum    "FIRST PART OF A LONG LITERAL AND ITS SECOND PART"$' \
    -- dump tokens --format terminal tests/fixtures/reader/terminal.cob
check "terminal format from a directive"   0 'TERMFMT' \
    -- dump ast tests/fixtures/reader/terminal.cob --format terminal
check "format keeps a page eject"          0 '^      / A page eject, then the procedure division.$' \
    -- format --to fixed --format xopen tests/fixtures/reader/xopen.cob
check "format joins a terminal continuation" 0 '^      DISPLAY "FIRST PART OF A LONG LITERAL AND ITS SECOND PART"$' \
    -- format --to free --format terminal tests/fixtures/reader/terminal.cob
check "format writes a COBOLX debugging line" 0 '^      DDISPLAY "SHOWN WHEN DEBUGGING"$' \
    -- format --to fixed tests/fixtures/reader/cobolx.cob
check_absent "variable format leaves no names cut" 'PLB-C009' \
    -- check --format variable tests/fixtures/reader/variable.cbl
check "unknown dump option"               2 "unknown option '--frob'" -- dump lines --frob $fx/fixed-basic.cbl
bx=tests/fixtures/baseline
check "--baseline hides the findings it lists" 0 '^$' -- check --baseline $bx/c001.baseline $rx/c001-unreachable.cob
check "findings not in the baseline are reported" 1 'NEVER-CALLED is never executed' \
    -- check --baseline $bx/c001-partial.baseline $rx/c001-unreachable.cob
check "a missing baseline is an error"    1 'cannot open baseline nope.baseline' \
    -- check --baseline nope.baseline $rx/c001-unreachable.cob
check "a file that is not a baseline"     1 'is not a Plumbline baseline' \
    -- check --baseline $rx/c001-unreachable.cob $rx/c001-unreachable.cob
check "--baseline needs a file"           2 '--baseline needs a file' -- check $rx/c001-unreachable.cob --baseline
check "each baseline line matches one finding" 0 'twice.cob:7:5: note: GO TO' \
    -- check --disable unreachable-code --baseline $bx/twice-once.baseline $bx/twice.cob
tmp_baseline=$(mktemp)
check "--write-baseline writes findings"  0 "wrote 3 findings to $tmp_baseline" \
    -- check --write-baseline "$tmp_baseline" $rx/c001-unreachable.cob
check "a written baseline hides its findings" 0 '^$' -- check --baseline "$tmp_baseline" $rx/c001-unreachable.cob
rm -f "$tmp_baseline"
check "--write-baseline to a bad path"    1 'cannot write baseline' \
    -- check --write-baseline no/such/dir/b.txt $rx/c001-unreachable.cob

cfx=tests/fixtures/config
check "--config applies settings"         1 'c001-unreachable.cob:11:9: error: GO TO makes' \
    -- check --config $cfx/strict.conf $rx/c001-unreachable.cob
check "options override the config"       1 'never executed' \
    -- check --config $cfx/strict.conf --enable unreachable-code $rx/c001-unreachable.cob
check "config can name a baseline"        0 '^$' -- check --config $cfx/baseline.conf $rx/c001-unreachable.cob
check "unknown settings are errors"       2 "in $cfx/unknown.conf line 1" -- check --config $cfx/unknown.conf $rx/c001-unreachable.cob
check "invalid severity"                  2 "invalid severity 'fatal'" -- check --config $cfx/bad-severity.conf $rx/c001-unreachable.cob
check "limit lowers a rule's threshold"   0 'paragraph DECIDE has complexity 13 (limit 10) \[PLB-M009\]' \
    -- check --config $cfx/limits.conf --fail-on never tests/golden/metrics/complexity.cob
check "limit applies to long paragraphs"  0 'paragraph DECIDE has 13 statements (limit 10) \[PLB-M010\]' \
    -- check --config $cfx/limits.conf --fail-on never tests/golden/metrics/complexity.cob
check "dynamic-call when enabled"         0 'named by data item ROUTINE-NAME, so the call cannot be checked \[PLB-M006\]' \
    -- check --no-config --enable dynamic-call --fail-on never $rx/c013-c015-calls.cob
check "vendor-routine when enabled"       0 'CBL_DELETE_FILE is a library routine of some compilers, not standard COBOL; keep such calls in one place \[PLB-P001\]' \
    -- check --no-config --enable vendor-routine --fail-on never $rx/p001-p002-portability.cob
check "signed-to-alphanumeric when enabled" 0 'MOVE of signed BALANCE to alphanumeric TEXT-OUT drops its sign: -5 and 5 give the same text \[PLB-M016\]' \
    -- check --no-config --enable signed-to-alphanumeric --fail-on never $rx/c039-decimal-to-alphanumeric.cob
check "signed-to-unsigned when enabled"   1 'signlost.cob:13:27: note: MOVE of signed WS-ADJUSTMENT to unsigned WS-REPORT-AMOUNT drops its sign: -5 is stored as 5 \[PLB-M018\]' \
    -- check --enable signed-to-unsigned --fail-on note tests/fixtures/signs/signlost.cob
co_fx=tests/fixtures/comments/oldcode.cbl
check "commented-out-code when enabled"    1 'oldcode.cbl:11:7: note: 3 lines of commented-out code \[PLB-M019\]' \
    -- check --enable commented-out-code --fail-on note $co_fx
check_absent "commented-out-code leaves prose alone" 'oldcode.cbl:1[67]:' \
    -- check --enable commented-out-code --fail-on note $co_fx
check_absent "commented-out-code is off by default" 'PLB-M019' \
    -- check $co_fx
nm_fx=tests/fixtures/numeric/nummove.cob
dv_fx=tests/fixtures/division/average.cob
check "divisor-not-checked when enabled"   1 'average.cob:26:24: warning: WS-COUNT may be zero here: nothing before this division tests it, and the statement has no ON SIZE ERROR \[PLB-C067\]' \
    -- check --enable divisor-not-checked $dv_fx
check "divisor-not-checked after /"        1 'average.cob:27:37: warning: WS-COUNT may be zero' \
    -- check --enable divisor-not-checked $dv_fx
check_absent "divisor-not-checked takes tests, constants, and SIZE ERROR" 'average.cob:\(3[0-9]\|4[0-9]\):.*PLB-C067' \
    -- check --enable divisor-not-checked $dv_fx
check_absent "divisor-not-checked is off by default" 'PLB-C067' \
    -- check $dv_fx
check "unchecked-numeric-move when enabled" 1 'nummove.cob:18:25: note: MOVE of alphanumeric IN-AMOUNT-X to numeric WS-AMOUNT, which nothing in the paragraph tests with NUMERIC \[PLB-C061\]' \
    -- check --enable unchecked-numeric-move --fail-on note $nm_fx
check_absent "unchecked-numeric-move takes a NUMERIC test" 'WS-COUNT, which' \
    -- check --enable unchecked-numeric-move --fail-on note $nm_fx
check_absent "unchecked-numeric-move is off by default" 'PLB-C061' \
    -- check $nm_fx
check_absent "signed-to-unsigned is off by default" 'PLB-M018' \
    -- check tests/fixtures/signs/signlost.cob
check_absent "signed receivers keep the sign" 'to unsigned WS-SIGNED-COPY\|to unsigned WS-EDITED' \
    -- check --enable signed-to-unsigned tests/fixtures/signs/signlost.cob
check "limit needs a measuring rule"      2 "rule 'go-to' has no limit" \
    -- check --config $cfx/no-limit.conf tests/golden/metrics/complexity.cob
check "limit needs a number"              2 "invalid limit 'many'" \
    -- check --config $cfx/bad-limit.conf tests/golden/metrics/complexity.cob
check "--config with a missing file"      2 'cannot read configuration file nope.conf' -- check --config nope.conf $rx/c001-unreachable.cob
run_dir=$cfx/project
check "plumbline.conf in the current directory is read" 0 '^$' -- check ../../../golden/rules/c001-unreachable.cob
check "--no-config skips plumbline.conf"  1 'GO TO makes' -- check --no-config ../../../golden/rules/c001-unreachable.cob
run_dir=.

mx=tests/golden/metrics
check "check as Markdown summarizes"     0 '^\*\*9 findings\*\* in 1 file: 0 errors, 8 warnings, 1 note.$' \
    -- check --no-config --report md --fail-on never tests/golden/rules/c036-arithmetic-overflow.cob
check "check as Markdown counts by rule"  0 '^| PLB-C036 | arithmetic-overflow | warning | 7 |$' \
    -- check --no-config --report md --fail-on never tests/golden/rules/c036-arithmetic-overflow.cob
check "check as Markdown escapes cells"   0 '| SELECT \\\* depends on every column of the table and their order; name the columns |$' \
    -- check --no-config --report md --fail-on never tests/golden/rules/q001-sql-tables.cob
check "check as Markdown with no findings" 0 '^No findings.$' \
    -- check --no-config --report md tests/fixtures/case/usecase.cob
check "metrics csv has a header"          0 '^file,program,kind,name,line,lines,statements,complexity,nesting,volume,maintainability$' \
    -- metrics --report csv $mx/complexity.cob
check "metrics csv quotes paths"          0 '^"tests/golden/metrics/complexity.cob",METRICS,paragraph,DECIDE,15,' \
    -- metrics --report csv $mx/complexity.cob
check "metrics start ends at the first paragraph" 0 '^"tests/fixtures/metrics/start.cob",START,start,,5,3,2,1,1,,$' \
    -- metrics --report csv tests/fixtures/metrics/start.cob
check "metrics has Halstead measures"     0 '^  Halstead volume 435, difficulty 32, effort 13852; maintainability 58$' \
    -- metrics $mx/complexity.cob
check "metrics refuses sarif"             2 "invalid --report format 'sarif' (expected text, json, or csv)" \
    -- metrics --report sarif $mx/complexity.cob
check "check refuses csv"                 2 "invalid --report format 'csv' (expected text, json, sarif, html, md, codeclimate, junit, or checkstyle)" \
    -- check --report csv $mx/complexity.cob
n=$((n + 1))
if "$bin" metrics --report json $mx/complexity.cob $rx/c001-unreachable.cob | python3 -m json.tool >/dev/null 2>&1; then
    echo "ok $n - metrics json is valid for several files"
else
    failed=$((failed + 1))
    echo "not ok $n - metrics json is valid for several files"
fi

ix=tests/fixtures/impact
check "impact of a copybook"              0 "included by $ix/custlook.cob through $ix/custio.cpy" \
    -- impact custrec -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of a program"               0 "called by MENU at $ix/menu.cob:5 through BILLING" \
    -- impact CUSTLOOK -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of a data item lists its declarations" 0 '^  declared at tests/fixtures/impact/custrec.cpy:3:16 in CUSTLOOK, level 5$' \
    -- impact CUST-ID -I $ix $ix/custlook.cob $ix/billing.cob
check "impact of a data item lists who sets it" 0 '^  set at tests/fixtures/impact/custlook.cob:10:26 in CUSTLOOK, MOVE$' \
    -- impact cust-id -I $ix $ix/custlook.cob $ix/billing.cob
check "impact of a data item lists calls with it" 0 '^  used at tests/fixtures/impact/billing.cob:8:34 in BILLING, CALL$' \
    -- impact CUST-ID -I $ix $ix/custlook.cob $ix/billing.cob
check "impact of an unknown name"         1 'no copybook, program, data item, or data set named NOPE in the input' \
    -- impact NOPE -I $ix $ix/menu.cob
check "impact of changed files: the copybook" 0 '^  tests/fixtures/impact/custio.cpy$' \
    -- impact --changed $ix/changed.txt -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of changed files: files not in the run" 0 '^changed files not in the run: 1$' \
    -- impact --changed $ix/changed.txt -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of changed files: programs that include it" 0 '^  CUSTLOOK tests/fixtures/impact/custlook.cob$' \
    -- impact --changed $ix/changed.txt -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of changed files: their callers" 0 '^  MENU tests/fixtures/impact/menu.cob$' \
    -- impact --changed $ix/changed.txt -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of changed files as JSON"     0 '{"name": "BILLING", "path": "tests/fixtures/impact/billing.cob"}' \
    -- impact --changed $ix/changed.txt --report json -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "impact of changed files needs a list" 2 'cannot read the list of changed files' \
    -- impact --changed $ix/no-such-list.txt $ix/menu.cob
check "copybook paths keep the file's own case" 0 '^copybook tests/fixtures/case/UPPERBK.cpy$' \
    -- impact UPPERBK tests/fixtures/case/usecase.cob
check "impact needs a name"               2 'impact needs a copybook or program name' -- impact -I $ix
check "graph of calls"                    0 '^  "MENU" -> "BILLING";$' \
    -- graph --kind calls -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "graph of copybooks"                0 "\"$ix/custio.cpy\" -> \"$ix/custrec.cpy\";" \
    -- graph --kind copybooks -I $ix $ix/custlook.cob $ix/billing.cob
check "graph refuses an unknown kind"     2 "invalid --kind 'data'" -- graph --kind data $ix/menu.cob
check "graph of jobs"                     0 '"PAYROLL (job)" -> "PAYPROC (proc)" \[label="NIGHTLY"\];' \
    -- graph --kind jobs tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/payroll.jcl tests/fixtures/jcl/payproc.prc
cx2="tests/fixtures/cics/ordmenu.cob tests/golden/csd/orders.csd"
check "graph of CICS starts programs from transactions" 0 '^  "ORD1 (transaction)" -> "ORDMENU" \[label="starts"\];$' \
    -- graph --kind cics $cx2
check "graph of CICS follows XCTL"        0 '^  "ORDMENU" -> "ORDENTRY" \[label="XCTL"\];$' \
    -- graph --kind cics $cx2
check "graph of CICS marks programs not in the run" 0 '^  "ORDENTRY" \[style=dashed\];$' \
    -- graph --kind cics $cx2
check "graph of jobs marks programs not in the run" 0 '"IEFBR14" \[style=dashed\];' \
    -- graph --kind jobs tests/fixtures/jcl/payroll.jcl
jds="tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/payroll.jcl tests/fixtures/jcl/payproc.prc"
check "graph of data sets follows the program's OPEN" 0 '^  "PAYROLL.UPDATE" -> "PAY.MASTER" \[label="PAYMAST", dir=both\];$' \
    -- graph --kind datasets $jds
check "graph of data sets falls back on DISP" 0 '^  "PAY.OLD" -> "PAYROLL.RERUN" \[label="OLDFILE"\];$' \
    -- graph --kind datasets $jds
check "graph of data sets gives overrides to the job step" 0 '^  "PAYROLL.NIGHTLY" -> "PAY.LOG" \[label="PAYLOG"\];$' \
    -- graph --kind datasets $jds
check "graph of data sets joins generations" 0 '^  "SORTGDG.COPY" -> "PAY.HISTORY" \[label="SYSUT2"\];$' \
    -- graph --kind datasets tests/fixtures/jcl/sortgdg.jcl
check "graph of data sets reads utility input" 0 '^  "PAY.HISTORY" -> "SORTGDG.SORT" \[label="SORTIN"\];$' \
    -- graph --kind datasets tests/fixtures/jcl/sortgdg.jcl
check "graph of data sets names temporaries with their job" 0 '^  "&&SORTED (SORTGDG)" -> "SORTGDG.COPY" \[label="SYSUT1"\];$' \
    -- graph --kind datasets tests/fixtures/jcl/sortgdg.jcl
check_absent "graph of data sets leaves out load libraries" 'LINKLIB' \
    -- graph --kind datasets tests/fixtures/jcl/sortgdg.jcl
lx2="tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/lrecl.jcl"
check "dump jcl shows LRECL and RECFM from DCB" 0 'dd PAYRPT dsn PAY.REPORT disp NEW recfm FBA lrecl 133$' \
    -- dump jcl tests/fixtures/jcl/lrecl.jcl
check "dump jcl shows LRECL and RECFM as keywords" 0 'dd PAYLOG dsn PAY.LOG disp MOD recfm VB lrecl 40$' \
    -- dump jcl tests/fixtures/jcl/lrecl.jcl
check "LRECL that is not the record length" 1 'DD RATES has LRECL=81 RECFM=FB, but the records of RATES in PAYUPD are 80 bytes \[PLB-J006\]' \
    -- check --no-config $lx2
check "LRECL of a variable format counts the descriptor" 1 'DD PAYLOG has LRECL=40 RECFM=VB, but the records of LOG-FILE in PAYLOG are 80 bytes (84 with the record descriptor) \[PLB-J006\]' \
    -- check --no-config $lx2
check_absent "LRECL with an ASA control character" 'DD PAYRPT has LRECL' \
    -- check --no-config $lx2
check "impact of a data set lists its writers" 0 '^  updated by PAYROLL.UPDATE through DD PAYMAST at tests/fixtures/jcl/payroll.jcl:5 (from OPEN; the step runs PAYUPD)$' \
    -- impact PAY.MASTER $jds
check "impact of a data set names procedure overrides" 0 '^  written by PAYROLL.NIGHTLY through DD UPD.PAYLOG at tests/fixtures/jcl/payroll.jcl:17 (from OPEN; the step runs PAYUPD)$' \
    -- impact pay.log $jds
check "impact of a data set falls back on DISP" 0 '^  read by PAYROLL.RERUN through DD OLDFILE at tests/fixtures/jcl/payroll.jcl:14 (from DISP=SHR)$' \
    -- impact PAY.OLD $jds
check "impact of a data set ignores the generation" 0 '^data set PAY.HISTORY$' \
    -- impact 'PAY.HISTORY(0)' tests/fixtures/jcl/sortgdg.jcl
check "impact of a data set reads utility DD names" 0 '^  written by SORTGDG.COPY through DD SYSUT2 at tests/fixtures/jcl/sortgdg.jcl:13 (from the DD name; the step runs IEBGENER)$' \
    -- impact PAY.HISTORY tests/fixtures/jcl/sortgdg.jcl
check "impact lists the steps that run a program" 0 'run by step UPDATE of job PAYROLL at tests/fixtures/jcl/payroll.jcl:4$' \
    -- impact PAYUPD tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/payroll.jcl
check "impact follows callers to their steps" 0 'run by step RERUN of job PAYROLL at tests/fixtures/jcl/payroll.jcl:11 through PAYUPD' \
    -- impact PAYLOG tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/payroll.jcl
check "graph of the CRUD matrix"          0 '^  "ACCTMNT" -> "BANK.AUDIT (table)" \[label="CD"\];$' \
    -- graph --kind crud tests/fixtures/crud/acctmnt.cob
check "graph refuses csv"                 2 "invalid --report format 'csv' (expected dot or json)" \
    -- graph --report csv $ix/menu.cob
for kind in performs calls copybooks jobs datasets cics crud; do
    n=$((n + 1))
    if "$bin" graph --kind $kind --report json -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob \
            tests/fixtures/jcl/payroll.jcl \
            | python3 -m json.tool >/dev/null 2>&1; then
        echo "ok $n - graph json is valid ($kind)"
    else
        failed=$((failed + 1))
        echo "not ok $n - graph json is valid ($kind)"
    fi
done

check "format to free"                    0 '^    MOVE LONG-NAME-PART-TWO TO X.$' -- format --to free $gx/continuation.cbl
check "format starts free output with its format" 0 '^>>SOURCE FORMAT IS FREE$' -- format --to free $gx/continuation.cbl
check "format --check on a file to change" 1 'is not in free format' -- format --to free --check $gx/continuation.cbl
check "format --check on a file in format" 0 '^$' -- format --to fixed --check $gx/continuation.cbl
check "format needs --to"                 2 'format needs --to fixed or --to free' -- format $gx/continuation.cbl
check "format refuses an unknown target"  2 "invalid --to 'variable'" -- format --to variable $gx/continuation.cbl
check "format writes one file"            2 'give one file, or use --check' -- format --to free $gx/continuation.cbl $gx/continuation.cbl
check "format splits long free lines"     0 '^      -    "ormat line has room for".$' -- format --to fixed tests/fixtures/format/long-lines.cob
check "format moves headers to area A"    0 '^       MAIN-LINE\.$' -- format --to fixed tests/fixtures/format/long-lines.cob
check "format keeps EXIT out of area A"   0 '^               EXIT\.$' -- format --to fixed tests/fixtures/format/long-lines.cob
check "format writes a blank line empty"  0 '^$' -- format --to free tests/fixtures/format/blank-line.cob

# fix: the findings with a fix, made in the file written to standard
# output, or listed with --check.
fx=tests/fixtures/fix
check "fix --check lists the fixes"         1 'fixable.cob:10:15: PLB-C071: Change AND to OR in this condition$' -- fix --check $fx/fixable.cob
check "fix --check: NEXT SENTENCE"          1 'fixable.cob:11:16: PLB-C004: Change NEXT SENTENCE to CONTINUE$' -- fix --check $fx/fixable.cob
check "fix --check: reversed range"         1 'fixable.cob:7:34: PLB-C074: Swap the ends of this range$' -- fix --check $fx/fixable.cob
check "fix --check: NEXT SENTENCE on two lines" 1 'fixable.cob:26:16: PLB-C004: Change NEXT SENTENCE to CONTINUE$' -- fix --check $fx/fixable.cob
check "fix makes NEXT SENTENCE on two lines" 0 '^               CONTINUE$' -- fix $fx/fixable.cob
check "fix keeps code before column 73"     0 'fixable.cob:21:15: PLB-C071: .*: not made, as the line would run past column 72$' -- fix $fx/fixable.cob
check "fix makes a fix"                     0 '^           IF WS-CODE = "A" or WS-CODE = "B"$' -- fix $fx/fixable.cob
check "fix keeps the case"                  0 '^               continue$' -- fix $fx/fixable.cob
check "fix swaps the ends of a range"       0 '^           88  MONTH-VALID VALUE 1 THRU 12\.$' -- fix $fx/fixable.cob
check "fix keeps the sequence area"         0 '^           IF WS-CODE NOT = "Q" AND "X" \{33\}FIX00160$' -- fix $fx/fixable.cob
check "fix writes a blank line empty"      0 '^$' -- fix $fx/fixable.cob
check "fix leaves other lines as they are"  0 '^           IF WS-CODE   NOT = "Q" OR "X" OR "Y"' -- fix $fx/fixable.cob
check "fix --check with nothing to fix"     0 '^$' -- fix --check $fx/clean.cob
check_absent "fix --disable leaves the rule's fixes" 'PLB-C074' -- fix --check --disable PLB-C074 $fx/fixable.cob
check "fix takes the quotes off a number"  0 '^           MOVE 1.50 TO WS-RATE WS-LAST$' -- fix $fx/quoted.cob
check "fix keeps a number's sign"           0 '^           MOVE -12 TO WS-COUNT$' -- fix $fx/quoted.cob
check "fix leaves a literal that is no number" 0 '^           MOVE "ABC" TO WS-COUNT$' -- fix $fx/quoted.cob
check_absent "fix --check: no fix for a literal that is no number" ':12:' -- fix --check $fx/quoted.cob
rgx=tests/golden/rules
check "fix sends literals whole"            0 '^           " WELCOME" DELIMITED BY SIZE$' -- fix $rgx/c078-string-literal-cut.cob
check "fix leaves a group with a data item" 0 '^    STRING "DEAR MR " WS-NAME DELIMITED BY SPACE$' -- fix $rgx/c078-string-literal-cut.cob
check "fix starts a pointer at 1"           0 '^    MOVE 1 TO WS-PTR$' -- fix $rgx/c082-pointer-below-one.cob
check_absent "fix: no fix for a COMPUTE of the pointer" ':18:' -- fix --check $rgx/c082-pointer-below-one.cob
check "fix --check: AND to OR for equalities" 1 'c071-contradictory-condition.cob:17:8: PLB-C071: Change AND to OR in this condition$' -- fix --check $rgx/c071-contradictory-condition.cob
check_absent "fix: no fix for a range \[PLB-C071\]" ':31:' -- fix --check $rgx/c071-contradictory-condition.cob
check "fix --patch: the file's name"        0 '^--- a/tests/fixtures/fix/fixable.cob$' -- fix --patch $fx/fixable.cob
check "fix --patch: a changed line"         0 '^+           88  MONTH-VALID VALUE 1 THRU 12\.$' -- fix --patch $fx/fixable.cob
check "fix --patch: its hunk"               0 '^@@ -4,17 +4,17 @@$' -- fix --patch $fx/fixable.cob
check "html report shows a fix"            1 '^<p>Fix: Swap the ends of this range</p>$' -- check --report html $fx/fixable.cob
check "html report shows the fixed line"    1 '^<ins>+            88  MONTH-VALID VALUE 1 THRU 12\.</ins>$' -- check --report html $fx/fixable.cob
check "fix writes one file"                 2 'give one file, or use --check' -- fix $fx/fixable.cob $fx/clean.cob

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
n=$((n + 1))
if err=$("$bin" check --report html $rx/c001-unreachable.cob | python3 tests/tools/check_html.py 3 2>&1); then
    echo "ok $n - html report is well formed"
else
    failed=$((failed + 1)); echo "not ok $n - html report is well formed"; echo "  # $err"
fi
check "html report escapes source text"   1 '    10      IF ERRORS &gt; 0' -- check --report html $rx/c001-unreachable.cob
check "html report marks the line"        1 '^<mark>    11          GO TO ABEND</mark>$' -- check --report html $rx/c001-unreachable.cob
n=$((n + 1))
if err=$("$bin" check --report html --baseline $bx/c001.baseline $rx/c001-unreachable.cob | python3 tests/tools/check_html.py 0 2>&1); then
    echo "ok $n - html report leaves out baselined findings"
else
    failed=$((failed + 1)); echo "not ok $n - html report leaves out baselined findings"; echo "  # $err"
fi
check_report "codeclimate report is valid" codeclimate 3 -- check --report codeclimate $rx/c001-unreachable.cob
check_report "empty codeclimate report is valid" codeclimate 0 -- check --report codeclimate --disable PLB-C001 --disable go-to $rx/c001-unreachable.cob
check_report "codeclimate tells alike findings apart" codeclimate 5 -- check --report codeclimate tests/fixtures/report/alike.cob
check "codeclimate maps severities"       1 '"check_name": "PLB-M001", .*"categories": \["Clarity"\], "severity": "minor"' \
    -- check --report codeclimate $rx/c001-unreachable.cob
check "codeclimate reports diagnostics"   1 '"check_name": "PP001", .*"severity": "critical"' \
    -- check --report codeclimate tests/fixtures/report/alike.cob
check_report "junit report is valid"       junit 3 -- check --report junit $rx/c001-unreachable.cob
check_report "junit report passes a clean file" junit 0 -- check --report junit --disable PLB-C001 --disable go-to $rx/c001-unreachable.cob
check "junit report names a clean file"    0 '<testcase classname="tests/golden/rules/c001-unreachable.cob" name="no findings"/>' \
    -- check --report junit --disable PLB-C001 --disable go-to $rx/c001-unreachable.cob
check "junit report fails on a finding"    1 '<testcase classname=".*c001-unreachable.cob" name="PLB-M001 go-to at 11:9">' \
    -- check --report junit $rx/c001-unreachable.cob
check "junit report errs on an error diagnostic" 1 '<error type="error" message="copybook .* not found">' \
    -- check --report junit tests/fixtures/report/alike.cob
check_report "checkstyle report is valid"  checkstyle 3 -- check --report checkstyle $rx/c001-unreachable.cob
check_report "checkstyle report has diagnostics" checkstyle 5 -- check --report checkstyle tests/fixtures/report/alike.cob
check "checkstyle report lists a clean file" 0 '<file name="tests/golden/rules/c001-unreachable.cob"/>' \
    -- check --report checkstyle --disable PLB-C001 --disable go-to $rx/c001-unreachable.cob
check "checkstyle report maps severities"  1 'severity="info" message="GO TO makes the flow of control hard to follow" source="plumbline.PLB-M001"' \
    -- check --report checkstyle $rx/c001-unreachable.cob
check "summary has a row per program"    0 '^METRICS  *28  *13  *58  *0  *3  *2  tests/golden/metrics/complexity.cob$' \
    -- summary $mx/complexity.cob
check "summary counts findings by program" 0 '^BILLING,"tests/fixtures/calls/billing.cob",1,11,1,67,0,1,0$' \
    -- summary --report csv tests/fixtures/calls/billing.cob tests/fixtures/calls/custlook.cob
check "summary in Markdown"                0 '^| METRICS | `tests/golden/metrics/complexity.cob` | 28 | 13 | 58 | 0 | 3 | 2 |$' \
    -- summary --report md $mx/complexity.cob
check "summary leaves out baselined findings" 0 '^ *27 *2 *[0-9]* *0 *0 *0  tests/golden/rules/c001-unreachable.cob$' \
    -- summary --baseline $bx/c001.baseline --disable go-to $rx/c001-unreachable.cob
check "summary refuses sarif"              2 "invalid --report format 'sarif' (expected text, md, csv, or json)" \
    -- summary --report sarif $mx/complexity.cob
n=$((n + 1))
if "$bin" summary --report json $mx/complexity.cob tests/fixtures/calls/billing.cob | python3 -c '
import json, sys
programs = json.load(sys.stdin)["programs"]
assert [p["program"] for p in programs] == ["METRICS", "BILLING"]
assert programs[0]["warnings"] == 3 and programs[1]["warnings"] == 0
'; then
    echo "ok $n - summary json"
else
    failed=$((failed + 1)); echo "not ok $n - summary json"
fi
diff_fx=tests/fixtures/diff/after-range.diff
check "diff keeps the findings on changed lines" 1 'c001-unreachable.cob:22:1: warning: paragraph AFTER-RANGE is never executed' \
    -- check --diff $diff_fx $rx/c001-unreachable.cob
check_absent "diff leaves out the other findings" 'NEVER-CALLED' \
    -- check --diff $diff_fx $rx/c001-unreachable.cob
check "diff passes when the changed lines are clean" 0 '' \
    -- check --diff $diff_fx --disable PLB-C001 $rx/c001-unreachable.cob
check "diff matches a path by its end"     1 'AFTER-RANGE is never executed' \
    -- check --diff $diff_fx ./$rx/c001-unreachable.cob
check "diff that cannot be read"           1 'cannot open diff no-such.diff' \
    -- check --diff no-such.diff $rx/c001-unreachable.cob
check "diff needs a file"                  2 '\-\-diff needs a file' \
    -- check --diff
# A line added above the findings moves them, but leaves their
# fingerprints as they were.
tmp=$(mktemp -d)
{ echo '*> a comment line added at the top'; cat $rx/c001-unreachable.cob; } > "$tmp/c001-unreachable.cob"
abs_bin=$(cd "$(dirname "$bin")" && pwd)/$(basename "$bin")
# Both runs have findings, so both exit 1.
(cd "$tmp" && "$abs_bin" check --report codeclimate c001-unreachable.cob) > "$tmp/after.json"
(cd $rx && "$abs_bin" check --report codeclimate c001-unreachable.cob) > "$tmp/before.json"
n=$((n + 1))
if python3 -c '
import json, sys
before = json.load(open(sys.argv[1]))
after = json.load(open(sys.argv[2]))
assert [i["fingerprint"] for i in before] == [i["fingerprint"] for i in after]
assert [i["location"]["lines"]["begin"] + 1 for i in before] == [i["location"]["lines"]["begin"] for i in after]
' "$tmp/before.json" "$tmp/after.json"; then
    echo "ok $n - codeclimate fingerprints survive moved lines"
else
    failed=$((failed + 1)); echo "not ok $n - codeclimate fingerprints survive moved lines"
fi
rm -rf "$tmp"
check "reports keep the exit code"        1 '"ruleId": "PLB-C001"' -- check --report sarif $rx/c001-unreachable.cob
check "invalid --report format"           2 "invalid --report format 'xml'" -- check --report xml $rx/c001-unreachable.cob

tmp=$(mktemp -d)
cp $rx/c001-unreachable.cob "$tmp/with space.cob"
check_report "sarif encodes spaces in uris" sarif 3 -- check --report sarif "$tmp/with space.cob"
rm -rf "$tmp"

echo "1..$n"
echo "# cli: $n assertions, $failed failed"
[ "$failed" -eq 0 ]
