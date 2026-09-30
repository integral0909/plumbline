# Plumbline

Plumbline is a static analyzer for COBOL, written in COBOL.

It reads COBOL source (fixed or free format, with COPY expansion), builds
control-flow and data-flow models of each program, and reports defects such
as unreachable paragraphs, PERFORM fall-through, truncating MOVEs, and
uninitialized fields. Findings can be emitted as text, JSON, or SARIF.

> **Status:** early development. The build, test, and coverage
> infrastructure is in place; the analyzer itself is being built. See
> [docs/architecture.md](docs/architecture.md) for the design and what
> exists so far.

## Building

Plumbline needs GnuCOBOL 3.2 and GNU make.

```sh
make                        # builds build/bin/plumbline
make test                   # runs all test suites
make coverage               # COBOL statement coverage (LCOV)
build/bin/plumbline --help
```

## Documentation

- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Maintainers

- Fredrik Ahman ([@integral0909](https://github.com/integral0909))

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) and
[NOTICE](NOTICE).
