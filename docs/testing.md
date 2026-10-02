# Testing Plumbline

`make test` runs four kinds of tests:

| Kind | Location | Runner |
|------|----------|--------|
| Unit | `tests/unit/test-*.cob` | `tools/run-tests.sh` |
| CLI end-to-end | `tests/cli/test-cli.sh` | shell |
| Golden files | `tests/golden/<suite>/` | `tests/golden/run-golden.sh` |
| Tooling | `tests/tools/test_*.py` | `python3 -m unittest` |

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

To add a case, write the input and run `make golden-update`, which
rewrites every expected file from the current output. **Read the diff
before committing it.** A golden file only protects behavior that someone
has checked to be right.

## Coverage

GnuCOBOL has no built-in coverage report, so `make coverage` builds its own
from the runtime's statement trace:

1. Everything is rebuilt under `build/cov/` with `cobc -ftraceall`.
2. Each product source is also compiled to C (`cobc -C`). cobc marks every
   statement in the generated C with a `/* Line: N : VERB : file */`
   comment, which gives the executable lines of each file.
3. Tests run with `COB_SET_TRACE=Y` and `COB_TRACE_FORMAT='%F|%L'`. Each
   process writes its own trace file (`$$` in `COB_TRACE_FILE` expands to
   the process ID).
4. `tools/cobcov.py` maps traced lines onto the executable lines and writes
   `build/coverage/lcov.info` plus a summary table.

Only files under `src/` and `copy/` are reported. `COV_MIN=<percent>`
makes the target fail below a threshold; CI sets it.

If `cobcov.py` warns about traced lines missing from the line map, the
generated-C annotations have changed (usually after a GnuCOBOL upgrade) and
the `NON_STATEMENTS` set in the tool needs revisiting.
