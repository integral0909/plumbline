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
| `--report text\|json\|sarif` | output format (default `text`) |

`--report sarif` writes SARIF 2.1.0, which code-scanning services and
many editors read directly; `--report json` writes a simpler document
with one finding per line. In both, input diagnostics are part of the
report rather than printed to standard error.

See the [rule reference](docs/rules.md) for what each rule looks for.

The `dump` commands show Plumbline's view of a program at each stage,
which helps when a result is surprising: `dump lines`, `dump tokens`,
`dump expanded`, `dump ast`, `dump symbols`, `dump flow`, `dump refs`,
and `dump calls`.

Give `check` all the programs that call each other in one run. Calls
between them are then checked against the programs they call: the
number of arguments, how they are passed, and their sizes.

## Documentation

- [Rule reference](docs/rules.md)
- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Maintainers

- Fredrik Ahman ([@integral0909](https://github.com/integral0909))

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) and
[NOTICE](NOTICE).
