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
- Call graph across all files of a run, with parameters and arguments;
  `plumbline dump calls` prints it.
- Rules PLB-C013 call-argument-count, PLB-C014 call-argument-mismatch,
  PLB-C015 recursive-call, and PLB-M006 dynamic-call (off by default).
- Baselines: `--write-baseline FILE` records the current findings and
  `--baseline FILE` reports only findings that are not in it.
- Settings in `plumbline.conf` or `--config FILE`, including rule
  severities; `--no-config` skips the file.

- `make corpus` runs Plumbline over the NIST COBOL-85 test suite
  (`tools/corpus/`); see `docs/corpus.md`.
- `plumbline lsp`: a language server with diagnostics, outline, go to
  definition, and hover.
- Security rules PLB-S002 hard-coded-credential, PLB-S003
  sensitive-data-displayed, and PLB-S004 shell-command.
- Portability rules PLB-P001 vendor-routine (off by default) and
  PLB-P002 hard-coded-path.
- `plumbline check` holds the lines of one input at a time and takes up
  to 10,000 inputs (was 256); the NIST suite checks in one run.
- Error FN001 when a run has more findings than it can keep.
- `--files-from LIST` reads the files to analyze from a list, or from
  standard input with `-`.
- Rules PLB-C023 subscript-out-of-range and PLB-C024
  refmod-out-of-range, for literal subscripts and reference modifiers.
- Rule PLB-C025 stop-run-in-called-program.
- Rule PLB-C026 varying-limit-unreachable.
- Rule PLB-M011 evaluate-without-other (off by default).
- `plumbline rules [--report text|json]` lists the rules as configured.
- Conditional compilation: `>>IF`/`>>ELIF`/`>>ELSE`/`>>END-IF` and
  `$IF`/`$ELSE`/`$END` with `DEFINED` and `SET` conditions, and
  `--define NAME` (`-D`).
- `--tab-width N` (`tab-width` in `plumbline.conf`), as `cobc -ftab-width`.
- `plumbline lsp` finds references and highlights them, telling reads
  from writes.
- Object-oriented COBOL definitions (`CLASS-ID`, `FACTORY`, `OBJECT`,
  `METHOD-ID`, `INTERFACE-ID`) are read as nested units, with instance
  data visible to methods.
- `XML PARSE` processing procedures, `COMP-6`.
- [COBOL dialects](docs/dialects.md): what Plumbline reads.
- Partial-word replacement with `==(TAG)==` (IBM Enterprise COBOL), CICS
  `DFH` names from `DFHAID` and `DFHBMSCA`, `EXEC DLI`, and DCLGEN
  members (`.dcl`) as copybooks, found by checking AWS's CardDemo.
- `make corpus-gnucobol`: GnuCOBOL's run-time test programs as a second
  corpus; the dialect support it led to: radix literals (`B#101`,
  `%47`, `H"80"`), `PERFORM FOREVER`, `XML GENERATE`/`JSON GENERATE`
  phrases, `CONSTANT` entries, level 78 inside records, the `OPTIONS`
  paragraph, programs without an `IDENTIFICATION DIVISION` header,
  literal program names in `END PROGRAM`, indented `$SET`, `>>`
  in column 7, special registers, and context-sensitive words.
- `make check-bounds` runs the tests on a build that checks subscripts.
- [Diagnostics reference](docs/diagnostics.md).
- `plumbline format --to fixed|free [--check]`: rewrite a file in the
  other reference format without changing its tokens.
- HTML report (`--report html`): one self-contained page with source
  excerpts.
- `plumbline graph` (PERFORM, CALL, and copybook graphs as DOT or
  JSON) and `plumbline impact` (what includes a copybook or calls a
  program, directly or not).
- `plumbline metrics`: size and complexity of programs, paragraphs, and
  sections, as text, JSON, or CSV.
- Measuring rules have limits (`limit RULE N`); PLB-M009
  complex-paragraph and PLB-M010 long-paragraph (both off by default).
- File rules PLB-C020 file-status-not-checked, PLB-C021
  file-not-opened, PLB-C022 open-mode-mismatch, and PLB-M008
  file-not-closed.
- Embedded SQL and CICS: host variables and command arguments are
  references with roles, EXEC SQL INCLUDE is expanded, the SQLCA and EIB
  fields are known, CICS RETURN/XCTL/ABEND end a paragraph, and WHENEVER
  targets are reachable; rules PLB-C018 sql-not-checked, PLB-C019
  cics-response-not-checked, and PLB-S001 dynamic-sql.
- Report Writer: RD entries, report groups, and the data their SOURCE,
  SUM, and CONTROL clauses read; rules PLB-C016 report-not-initiated,
  PLB-C017 report-not-terminated, and PLB-M007 detail-never-generated.
- SORT and MERGE INPUT and OUTPUT PROCEDUREs, ALTER, CD entries, the
  fields of DEBUG-ITEM, DECIMAL-POINT IS COMMA, and CURRENCY SIGN.

### Changed

- Checking is faster: the NIST suite in one run went from 17.2 to 9.8
  seconds.

### Fixed

- Copybooks shared by many files of one run are read once, rather than
  once per file, which ran into the 256-file limit.
- Numeric literals starting with a decimal point after a sign or "(".
- Comment entries in the identification division are skipped.
- References qualified more than 8 levels deep.
- Items set in declaratives are not reported as used before set.
- The sign character of SIGN ... SEPARATE items counts in their size.
- Trailing spaces of a literal are not counted as truncated characters.
- Picture strings no longer take the == that ends pseudo-text.
- Qualified and subscripted identifiers as COPY REPLACING operands.
- file-status-not-checked no longer stops at a statement in another
  branch of the same IF or EVALUATE.
- PERFORM UNTIL EXIT is a loop, and paragraphs holding an ENTRY
  statement are entry points.
