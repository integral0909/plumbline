# Plumbline

Plumbline is a static analyzer for COBOL, written in COBOL.

It reads COBOL source (fixed or free format, with COPY expansion), builds
control-flow and data-flow models of each program, and reports defects such
as unreachable paragraphs, PERFORM fall-through, truncating MOVEs, and
uninitialized fields. Findings can be emitted as text, JSON, or SARIF.

> **Status:** early development. The front end (reader, preprocessor,
> lexer, parser), the symbol table, the procedure graph, and the rule
> engine work; the rule set is still small. See
> [docs/architecture.md](docs/architecture.md) for the design.

## Building

Plumbline needs GnuCOBOL 3.2 and GNU make.

```sh
make                        # builds build/bin/plumbline
make test                   # runs all test suites
make coverage               # COBOL statement coverage (LCOV)
build/bin/plumbline --help
```

## Usage

```console
$ plumbline check -I copybooks src/*.cbl
src/payroll.cbl:118:8: warning: paragraph CALC-OVERTIME is never executed [PLB-C001]
```

Findings go to standard output as `file:line:column: severity: message
[rule]`, and problems reading the input go to standard error. The exit
code is 1 when there are findings at or above the `--fail-on` level
(`warning` by default), so `plumbline check` can gate a build.

| Option | Meaning |
|--------|---------|
| `-I DIR` | search `DIR` for copybooks (repeatable) |
| `--format fixed\|free\|auto` | reference format of the sources (default `auto`) |
| `--enable RULE`, `--disable RULE` | turn a rule on or off, by id or name |
| `--fail-on error\|warning\|note\|never` | the lowest severity that fails the run |
| `--report text\|json\|sarif\|html` | output format (default `text`) |
| `--baseline FILE` | do not report the findings listed in `FILE` |
| `--write-baseline FILE` | write the findings to `FILE` instead of reporting them |
| `--config FILE`, `--no-config` | read settings from `FILE`, or from no file |

`--report sarif` writes SARIF 2.1.0, which code-scanning services and
many editors read directly; `--report json` writes a simpler document
with one finding per line; `--report html` writes one self-contained
page with each finding's source lines, to open in a browser or keep as
a build artifact. In both, input diagnostics are part of the
report rather than printed to standard error.

See the [rule reference](docs/rules.md) for what each rule looks for.

The `dump` commands show Plumbline's view of a program at each stage,
which helps when a result is surprising: `dump lines`, `dump tokens`,
`dump expanded`, `dump ast`, `dump symbols`, `dump flow`, `dump refs`,
and `dump calls`.

Give `check` all the programs that call each other in one run. Calls
between them are then checked against the programs they call: the
number of arguments, how they are passed, and their sizes.

## Metrics

`plumbline metrics` reports the size and complexity of each program and
of its paragraphs and sections:

```console
$ plumbline metrics src/payroll.cbl
program PAYROLL src/payroll.cbl:2
  lines 412 (code 318, comment 81, blank 13)
  statements 245, sections 4, paragraphs 31, data items 120
  complexity 57, deepest nesting 4, GO TO 12, PERFORM 40, CALL 3
  paragraph MAIN-LINE line 61: 12 statements, complexity 3, nesting 2, 18 lines
  ...
```

Complexity is McCabe's: one plus each decision (IF, WHEN, a looping
PERFORM, a conditional phrase such as AT END, AND and OR in conditions,
and the targets of GO TO DEPENDING ON). `--report json` and
`--report csv` give the same figures for other tools and spreadsheets.

## Graphs and impact

`plumbline graph` draws how a program's paragraphs perform and jump to
each other, which programs call which, or which files include which
copybooks, as Graphviz DOT (or JSON with `--report json`):

```console
$ plumbline graph src/payroll.cbl | dot -Tsvg -o payroll.svg
$ plumbline graph --kind calls src/*.cbl | dot -Tsvg -o calls.svg
$ plumbline graph --kind copybooks -I copybooks src/*.cbl > copies.dot
```

`plumbline impact` answers the question before a change: what does it
reach?

```console
$ plumbline impact CUSTREC -I copybooks src/*.cbl
copybook copybooks/custrec.cpy
  included by copybooks/custio.cpy directly
  included by src/billing.cbl directly
  included by src/custlook.cbl through copybooks/custio.cpy
$ plumbline impact CUSTLOOK src/*.cbl
program CUSTLOOK src/custlook.cbl:2
  called by BILLING at src/billing.cbl:8 directly
  called by MENU at src/menu.cbl:5 through BILLING
```

## Configuration

Settings that a project always uses go in `plumbline.conf` in the
directory `plumbline` runs in, one per line:

```
# plumbline.conf
include copybooks
format fixed
enable alnum-narrowing
disable go-to
severity move-truncation error
fail-on error
baseline plumbline.baseline
```

`include`, `format`, `enable`, `disable`, `fail-on`, `report`, and
`baseline` work like the options of the same names. `severity RULE
LEVEL` reports a rule as `error`, `warning`, or `note`, and `limit RULE
N` sets the threshold of a rule that measures something, such as
`limit complex-paragraph 20`. Options given on
the command line are applied after the file, so they override it. Paths
in the file are relative to the directory `plumbline` runs in.

## Adopting Plumbline in existing code

An established code base has findings that nobody will fix this week. A
baseline records them, so that `check` fails only on new ones:

```console
$ plumbline check --write-baseline plumbline.baseline src/*.cbl
plumbline: wrote 214 findings to plumbline.baseline
$ plumbline check --baseline plumbline.baseline src/*.cbl
```

The baseline is a text file to commit along with the code. A finding
matches a baseline line when the rule, file, message, and the text of the
reported source line are the same. Line numbers are not part of it, so
editing other parts of a file does not bring old findings back. Fixing
a finding leaves a line that matches nothing. Write the baseline again
from time to time so that it shrinks, and give the files to `check`
with the same paths each time.

## Documentation

- [Rule reference](docs/rules.md)
- [Running Plumbline on the NIST COBOL-85 suite](docs/corpus.md)
- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Maintainers

- Fredrik Ahman ([@integral0909](https://github.com/integral0909))

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) and
[NOTICE](NOTICE).
