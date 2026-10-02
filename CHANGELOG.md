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
- Parser: programs (nested and sibling), identification, environment,
  data, and procedure divisions; data entries with clauses; sections,
  paragraphs, sentences, and statements with COBOL scoping of IF/ELSE,
  EVALUATE, SEARCH, inline PERFORM, conditional phrases, and scope
  terminators; error recovery at periods.
- `plumbline dump ast [-I DIR]... FILE...` prints the syntax tree.
- Reserved-word table with binary search.
- PICTURE analysis (category, size, digits, scale, sign, validation)
  and storage size by USAGE.
- Symbol table with group sizes, OCCURS, REDEFINES, and byte offsets;
  `plumbline dump symbols` prints it.
- Procedure graph: sections and paragraphs, fall-through, PERFORM and
  GO TO edges with qualified name resolution, and reachability that
  respects PERFORM return semantics; `plumbline dump flow` prints it.
- `plumbline check` with a rule engine, `--enable`/`--disable`, and
  `--fail-on`; first rule PLB-C001 unreachable-code.
- Rules PLB-C002 perform-and-fall-through, PLB-C003 fall-off-end,
  PLB-C004 next-sentence-in-scope, PLB-C005 perform-thru-backwards,
  PLB-C006 recursive-perform, PLB-M001 go-to, and PLB-M002 alter.
- Rules PLB-C007 redefines-larger and PLB-M003 unused-data-item.
- `--report json` and `--report sarif` (SARIF 2.1.0) for `plumbline check`.
- `*> plumbline: ignore [RULE...] [-- reason]` comments suppress findings.
- Data references: identifiers in procedures resolved with qualifiers,
  subscripts, and reference modification; `plumbline dump refs`.
- Rules PLB-C008 move-truncation, PLB-C009 undefined-name,
  PLB-C010 ambiguous-name, and PLB-M004 alnum-narrowing (off by default).
- Level-78 constants resolved in PICTURE and OCCURS; identical
  diagnostics reported once.
- Reference roles (read, set, both) in `plumbline dump refs`, storage
  spans, and a shared access table for data-flow rules.
- Rules PLB-C011 read-never-set, PLB-C012 use-before-set, and
  PLB-M005 set-never-read.
