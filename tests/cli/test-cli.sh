#!/bin/sh
# End-to-end checks of the plumbline executable: output and exit codes.
# Usage: tests/cli/test-cli.sh path/to/plumbline
# Emits TAP and exits non-zero on any failure.
#
# Variables such as $sm hold several file names, and are split into
# arguments on purpose.
# shellcheck disable=SC2086
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
check "evaluate-without-other finds the EVALUATE" 0 'evaluate.cob:12:12: note: EVALUATE has no WHEN OTHER' \
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
check "dump lines needs files"            2 'no input files' -- dump lines
check "invalid --format value"            2 "invalid format 'variable'" \
    -- dump lines --format variable $fx/fixed-basic.cbl
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
check "metrics csv has a header"          0 '^file,program,kind,name,line,lines,statements,complexity,nesting$' \
    -- metrics --report csv $mx/complexity.cob
check "metrics csv quotes paths"          0 '^"tests/golden/metrics/complexity.cob",METRICS,paragraph,DECIDE,15,' \
    -- metrics --report csv $mx/complexity.cob
check "metrics refuses sarif"             2 "invalid --report format 'sarif' (expected text, json, or csv)" \
    -- metrics --report sarif $mx/complexity.cob
check "check refuses csv"                 2 "invalid --report format 'csv' (expected text, json, sarif, or html)" \
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
check "impact of an unknown name"         1 'no copybook or program named NOPE in the input' \
    -- impact NOPE -I $ix $ix/menu.cob
check "impact needs a name"               2 'impact needs a copybook or program name' -- impact -I $ix
check "graph of calls"                    0 '^  "MENU" -> "BILLING";$' \
    -- graph --kind calls -I $ix $ix/custlook.cob $ix/billing.cob $ix/menu.cob
check "graph of copybooks"                0 "\"$ix/custio.cpy\" -> \"$ix/custrec.cpy\";" \
    -- graph --kind copybooks -I $ix $ix/custlook.cob $ix/billing.cob
check "graph refuses an unknown kind"     2 "invalid --kind 'data'" -- graph --kind data $ix/menu.cob
check "graph of jobs"                     0 '"PAYROLL (job)" -> "PAYPROC (proc)" \[label="NIGHTLY"\];' \
    -- graph --kind jobs tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/payroll.jcl tests/fixtures/jcl/payproc.prc
check "graph of jobs marks programs not in the run" 0 '"IEFBR14" \[style=dashed\];' \
    -- graph --kind jobs tests/fixtures/jcl/payroll.jcl
check "impact lists the steps that run a program" 0 'run by step UPDATE of job PAYROLL at tests/fixtures/jcl/payroll.jcl:4$' \
    -- impact PAYUPD tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/payroll.jcl
check "impact follows callers to their steps" 0 'run by step RERUN of job PAYROLL at tests/fixtures/jcl/payroll.jcl:11 through PAYUPD' \
    -- impact PAYLOG tests/fixtures/jcl/payupd.cob tests/fixtures/jcl/paylog.cob tests/fixtures/jcl/payroll.jcl
check "graph refuses csv"                 2 "invalid --report format 'csv' (expected dot or json)" \
    -- graph --report csv $ix/menu.cob
for kind in performs calls copybooks jobs; do
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
check "reports keep the exit code"        1 '"ruleId": "PLB-C001"' -- check --report sarif $rx/c001-unreachable.cob
check "invalid --report format"           2 "invalid --report format 'xml'" -- check --report xml $rx/c001-unreachable.cob

tmp=$(mktemp -d)
cp $rx/c001-unreachable.cob "$tmp/with space.cob"
check_report "sarif encodes spaces in uris" sarif 3 -- check --report sarif "$tmp/with space.cob"
rm -rf "$tmp"

echo "1..$n"
echo "# cli: $n assertions, $failed failed"
[ "$failed" -eq 0 ]
