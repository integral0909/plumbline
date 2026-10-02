# Contributing to Plumbline

Thanks for your interest in Plumbline. This guide covers how to build the
project, how the code is organized, and what we look for in a pull request.

## Prerequisites

- GnuCOBOL 3.2 (`cobc` on your `PATH`)
  - macOS: `brew install gnucobol`
  - Linux: build from the [GNU release](https://ftp.gnu.org/gnu/gnucobol/),
    as CI does (see `.github/workflows/ci.yml`)
- GNU make, a POSIX shell, and Python 3.9 or later (for tooling only)

## Building and testing

```sh
make            # build build/bin/plumbline
make test       # unit suites, CLI tests, tooling tests
make coverage   # statement coverage report, LCOV in build/coverage/
make clean
```

`VERBOSE=1 make test` prints the full TAP output of passing suites.

## Layout

| Path | Contents |
|------|----------|
| `src/cli/` | the `plumbline` executable |
| `src/lib/` | analyzer modules, one subsystem per file |
| `copy/` | copybooks shared by `src/` |
| `tests/harness/` | the `PLBT-*` assertion library |
| `tests/unit/` | one `test-<module>.cob` per module in `src/lib/` |
| `tests/cli/` | end-to-end tests of the executable |
| `tests/tools/` | tests for the Python tooling |
| `tools/` | test runner and coverage tooling |
| `docs/` | design notes and user documentation |

## Coding conventions

Plumbline's own sources are GnuCOBOL free format (`cobc -free`).

- Indent with four spaces. No tabs.
- Program names are `PLB-<AREA>-<ACTION>`, e.g. `PLB-STR-LENGTH`.
- Data names carry a prefix for their section: `WS-` working storage,
  `LS-` local storage, `LK-` linkage.
- Subprograms take `PIC X ANY LENGTH` for text arguments where practical,
  and use `LOCAL-STORAGE` so they are safe to call repeatedly.
- Every source file opens with a comment block that says what it is for.
  Comment the why, not the what.
- The build uses `-Wall`. New code must compile without warnings.

## Tests

Every change to `src/` needs tests. Unit tests are COBOL programs in
`tests/unit/` that call the module under test and use the `PLBT-*`
assertions:

```cobol
CALL "PLBT-BEGIN" USING "plbstr"
CALL "PLBT-CASE" USING "PLB-STR-LENGTH"
CALL "PLB-STR-LENGTH" USING WS-TEXT WS-LEN
CALL "PLBT-ASSERT-NUM" USING "trailing spaces are not counted"
    WS-EXPECT-NUM WS-ACTUAL-NUM
CALL "PLBT-END"
```

New files named `tests/unit/test-*.cob` are picked up by the Makefile
automatically. See [docs/testing.md](docs/testing.md) for details.

## Commits and pull requests

- Keep commits focused: one logical change per commit, with a message in
  the imperative mood ("Add ...", "Fix ...").
- Open a pull request against `main`. CI must pass before merge.
- Describe what changed and why, and how you tested it.
- Add a line to `CHANGELOG.md` under "Unreleased" for user-visible changes.

## Reporting bugs

Open an issue with the smallest COBOL program that reproduces the problem,
the command you ran, and what you expected. For security issues, see
[SECURITY.md](SECURITY.md) instead.

## License

By contributing, you agree that your contributions are licensed under the
Apache License 2.0, as described in [LICENSE](LICENSE).
