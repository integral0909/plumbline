# Testing Plumbline

`make test` runs four kinds of tests:

| Kind | Location | Runner |
|------|----------|--------|
| Unit | `tests/unit/test-*.cob` | `tools/run-tests.sh` |
| CLI end-to-end | `tests/cli/test-cli.sh` | shell |
| Golden files | `tests/golden/<suite>/` | `tests/golden/run-golden.sh` |
| Tooling and language server | `tests/tools/test_*.py` | `python3 -m unittest` |

## Unit tests

A unit test is a standalone COBOL program linked against every object in
`src/lib/` and the assertion library in `tests/harness/`. It prints
[TAP](https://testanything.org/) and exits non-zero if any assertion fails.

| Routine | Arguments | Checks |
|---------|-----------|--------|
| `PLBT-BEGIN` | suite name | starts a suite, resets counters |
| `PLBT-CASE` | case name | labels the following assertions |
| `PLBT-ASSERT-STR` | label, expected, actual | alphanumeric equality |
| `PLBT-ASSERT-NUM` | label, expected, actual (`S9(18) COMP-5`) | numeric equality |
| `PLBT-ASSERT-FLAG` | label, expected, actual (`PIC X`) | a Y/N flag |
| `PLBT-END` | none | prints the plan and sets `RETURN-CODE` |

String comparison follows COBOL rules, so trailing spaces are not
significant: `"ABC"` equals `"ABC   "`.

Numeric assertions take `S9(18) COMP-5` arguments. Move the values into
fields of that type before the call, because passing a field with a
different picture passes the wrong bytes.

## Golden-file tests

A golden suite is a directory of inputs (`NAME.cob` or `NAME.cbl`), each
with the expected standard output (`NAME.out`) and, if the command
reports anything, the expected standard error (`NAME.err`). The runner
passes each input to a `plumbline` command and diffs the results. The
suites and their commands are listed in `GOLDEN_SUITES` in the Makefile:

| Suite | Command |
|-------|---------|
| `tests/golden/lexer` | `plumbline dump tokens` |
| `tests/golden/pp` | `plumbline dump expanded -I tests/golden/pp/copy` |
| `tests/golden/parser` | `plumbline dump ast` |
| `tests/golden/symbols` | `plumbline dump symbols` |
| `tests/golden/flow` | `plumbline dump flow` |
| `tests/golden/rules` | `plumbline check --fail-on never` |
| `tests/golden/refs` | `plumbline dump refs` |
| `tests/golden/calls` | `plumbline dump calls` |
| `tests/golden/metrics` | `plumbline metrics` |
| `tests/golden/graph` | `plumbline graph` |

Copybooks for the `pp` suite live in `tests/golden/pp/copy/`, with a
`.cpy` extension, so the runner does not mistake them for test inputs.

To add a case, write the input and run `make golden-update`, which
rewrites every expected file from the current output. **Read the diff
before committing it.** A golden file only protects behavior that someone
has checked to be right.

## Self-check

`make test` also runs `tools/selfcheck.sh`, which runs `plumbline check`
on every COBOL source file of Plumbline itself and fails on any finding or
diagnostic. It then checks all of them in one run, so that every `CALL`
between Plumbline's programs is checked against the program it calls. Plumbline is held to its own rules.
The analyzer's own source is several thousand lines of real COBOL, and
this check has already caught parser bugs that the targeted tests missed.

## Bounds-checked build

COBOL does not check subscripts: an index past the end of a table
reads or overwrites whatever follows it, and the program goes on.
`make check-bounds` builds Plumbline with
`-fec=EC-BOUND-SUBSCRIPT` in `build/bounds/` and runs the whole test
suite on that build, so such an index stops the program with a
message naming the table instead. CI runs it on Linux.

It caught a real bug when the file limit was raised from 256 to 20,000:
the tables that `plumbline impact` keeps per file still had 256 entries.

Reference modifiers are not checked. GnuCOBOL 3.2 has three bugs in
code built with checks, and the code avoids the two that affect
subscripts:

- with `EC-BOUND-SUBSCRIPT`, a subscript nested two deep, as in
  `A(B(C(I)))`, takes only as many bytes as the innermost index field
  has. The code takes such an index into a variable first;
- with `EC-BOUND-SUBSCRIPT`, `FUNCTION ORD` as a subscript does not
  compile. The lexer reads character codes through a `BINARY-CHAR
  UNSIGNED` redefinition instead, which is also faster;
- with `EC-BOUND-REF-MOD`, comparing two reference modifications whose
  offsets are subscripted compares the wrong text. That is why
  reference modifiers are left unchecked.

## Rule reference

`tests/tools/test_rules_doc.py` runs `plumbline rules --report json`
and checks that `docs/rules.md` has a row and a section for every rule,
with the name, default severity, default state, and title of the
catalog. A rule cannot be added, renamed, or retuned without its
documentation.

## Formatter round trip

`make test` also runs `tests/tools/roundtrip_format.py` on every golden
sample. It formats each one to free format and the result to fixed
format, and checks that the tokens of both match the original's. It
then checks that formatting either result again changes nothing.

## Coverage

GnuCOBOL has no built-in coverage report, so `make coverage` builds its own
from the runtime's statement trace:

1. Everything is rebuilt under `build/cov/` with `cobc -ftraceall`.
2. Each product source is also compiled to C (`cobc -C`). cobc marks every
   statement in the generated C with a `/* Line: N : VERB : file */`
   comment, which gives the executable lines of each file.
3. Every test program, and every `plumbline` run the CLI, golden, and
   self-check suites make, goes through `tools/cov-run.sh`. It runs the
   program with `COB_SET_TRACE=Y` and `COB_TRACE_FORMAT='%F|%L'` into a
   private trace file, then folds that trace into `build/coverage/counts`
   (`file|line|hits`) and deletes it. Raw traces grow by one line per
   executed statement and would otherwise reach gigabytes.
4. `tools/cobcov.py` maps the counted lines onto the executable lines and
   writes `build/coverage/lcov.info` plus a summary table.

Tracing slows programs down considerably, so `make coverage` takes
minutes where `make test` takes seconds.

Only files under `src/` and `copy/` are reported. `COV_MIN=<percent>`
makes the target fail below a threshold; CI sets it.

If `cobcov.py` warns about traced lines missing from the line map, the
generated-C annotations have changed (usually after a GnuCOBOL upgrade) and
the `NON_STATEMENTS` set in the tool needs revisiting.
