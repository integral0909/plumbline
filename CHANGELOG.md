# Changelog

All notable changes to Plumbline are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Build system (`make`, `make test`, `make coverage`).
- `plumbline` command with `--help` and `--version`.
- `plumbline dump lines [--format fixed|free|auto] FILE...` shows how
  each source line was classified; diagnostics go to standard error.
- `plbstr` string helpers.
- `PLBT-*` unit test library with TAP output.
- COBOL statement coverage from runtime traces (`tools/cobcov.py`).
- CI on Linux and macOS.
- `plbdiag` diagnostics table with `path:line:col: severity: message` formatting.
- Source reader: fixed and free reference formats, format detection,
  `>>SOURCE`/`$SET` format switching, tab expansion, literal-aware
  inline comments, and continuation lines.
- Lexer: words, numeric and alphanumeric literals (with prefixes),
  picture strings, operators, and pseudo-text delimiters, over a logical
  stream that joins continuation lines.
- `plumbline dump tokens [--debug] FILE...` prints the token stream.
- Golden-file test suites (`tests/golden`, `make golden-update`).
- Preprocessor: COPY with OF/IN, SUPPRESS, and REPLACING (pseudo-text,
  words, literals, LEADING/TRAILING, and :TAG: substitution), REPLACE
  with ALSO / LAST OFF / OFF, recursion and depth checks, and safe
  copybook resolution against `-I` search paths.
- `plumbline dump expanded [-I DIR]... FILE...` prints the expanded
  tokens and where each copybook was included from.
