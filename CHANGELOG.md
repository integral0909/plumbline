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
- `plumbline dump ims` reads IMS DBD and PSB sources: databases with
  their segments and fields, PSBs with their PCBs and sensitive
  segments (see docs/ims.md). `check` reads `*.dbd` and `*.psb`
  inputs and checks PSBs against databases and DL/I calls against
  PSBs: rules PLB-I001 to PLB-I004.
- `plumbline dump csd` reads CICS resource definitions, the DFHCSDUP
  input that defines transactions, programs, mapsets, and files (see
  docs/cics.md). `check` reads `*.csd` inputs and checks the resources
  that EXEC CICS commands name: rule PLB-K001 cics-resource-undefined.
- `plumbline dump bms` reads CICS BMS maps: mapsets, maps, and their
  fields (see docs/bms.md). `check` reads `*.bms` inputs and checks
  their maps: rules PLB-B001 map-fields-overlap, PLB-B002
  field-outside-map, PLB-B003 map-not-in-mapset, against the SEND and
  RECEIVE MAP commands of the programs, and PLB-B004
  symbolic-map-stale, against the symbolic maps they copy.
- `plumbline dump jcl` reads JCL: jobs, procedures, steps, and DD
  statements (see docs/jcl.md).
- `check` reads `*.jcl` and `*.prc` inputs as JCL and checks each step
  against the programs it runs: rules PLB-J001 dd-missing, PLB-J002
  dd-unused, PLB-J003 program-not-in-run (off by default), and
  PLB-J004 dd-cannot-be-read.
- The JCL reader records the program that IMS (`DFSRRC00`) and DB2
  (`IKJEFT01`, `RUN PROGRAM`) steps run, and the J rules check it.
- `plumbline impact NAME` also takes a data item name and lists every
  declaration and use of it in the run, with what each use does.
- `plumbline layout [--report text|json|csv|md]` lists the records of
  programs and copybooks with each item's start and length.
- `plumbline inventory [--report text|json]` describes an application:
  its programs with what starts them and what they use, its jobs,
  transactions, and maps.
- `plumbline graph --kind datasets` draws which job steps read and
  write which data sets, from the programs' `OPEN` statements, utility
  DD names, and `DISP`.
- `plumbline graph --kind cics` draws how transactions, programs,
  mapsets, and files connect through the CICS commands.
- `plumbline impact DSN` lists the job steps that read and write a data
  set.
- The Visual Studio Code extension's `Plumbline: Document this
  program` shows the `plumbline doc` page of the open file.
- The language server shows, above each section and paragraph, how many
  `PERFORM` and `GO TO` statements name it (code lens).
- Go to definition on a `COPY` statement opens the copybook.
- Completion of data, paragraph, and section names in the language
  server.
- Inlay hints show the size and offset of each data item where it is
  declared.
- The copybook name of each `COPY` statement is a link to the copybook
  (document links).
- Hover over a paragraph or section name shows its size, complexity,
  callers, and whether it ever runs.
- `plumbline check --report md` writes the findings as Markdown, for a
  CI job summary or a pull request comment.
- `plumbline fields [--unused]` lists the items of each copybook and
  how many programs name them.
- `plumbline doc` writes a Markdown page for each program: what starts
  it, what it uses, the data sets its job steps give it, its
  paragraphs, and its records.
- The SQL tables each program uses, in `dump calls` and `inventory`,
  and rule PLB-Q001 sql-table-undeclared.
- Rule PLB-A001 unused-program, for runs with JCL or CICS definitions.
- `plumbline graph --kind jobs` draws which jobs and procedures run
  which programs, and `impact` lists the job steps that run a program
  or its callers.
- Rule PLB-C027 divide-by-zero.
- Rule PLB-C028 comparison-never-true.
- Rule PLB-C029 go-to-leaves-perform.
- Rule PLB-C030 value-never-used.
- Rule PLB-C031 string-overflow.
- Rules PLB-C032 duplicate-when and PLB-C033 self-move.
- Rule PLB-C034 linkage-not-addressed.
- Rule PLB-C035 duplicate-paragraph.
- Rule PLB-C036 arithmetic-overflow.
- Rule PLB-C037 search-index-not-set.
- Rule PLB-C038 condition-value-unfit.
- Rules PLB-Q002 cursor-not-closed and PLB-Q003 cursor-not-opened.
- Rule PLB-C040 odo-object-too-small.
- Rule PLB-C041 write-from-truncation.
- Rule PLB-C042 inspect-count-not-reset.
- Rule PLB-C043 pointer-not-reset.
- Rule PLB-C044 varying-control-changed.
- Rule PLB-M017 two-digit-year.
- Rule PLB-C045 alnum-compared-to-number.
- Diagnostic PP008: a `COPY ... REPLACING` rule that replaces nothing.
- Rule PLB-J006 lrecl-mismatch. `dump jcl` shows `LRECL` and `RECFM`,
  and `dump calls` the record length of each file.
- Rule PLB-K002 read-update-not-released.
- Rule PLB-Q004 sql-no-where.
- Rule PLB-C046 overlapping-move.
- Rule PLB-C047 foreign-index.
- Rule PLB-C048 sort-procedure-no-record.
- Rule PLB-C049 loop-condition-unchanged.
- Rule PLB-C050 record-read-at-end.
- Rule PLB-C051 duplicate-if-condition.
- Rule PLB-C052 string-overlap.
- Rule PLB-Q005 into-count-mismatch.
- Rule PLB-K003 commarea-without-length.
- Rule PLB-K004 commarea-length-too-long.
- Rule PLB-K005 batch-io-in-cics.
- Rule PLB-A002 record-length-conflict.
- Rule PLB-C054 go-to-into-perform-range.
- Rule PLB-C055 corresponding-no-match.
- Rule PLB-C056 self-comparison.
- Rule PLB-C057 misleading-indentation.
- Rule PLB-C058 read-not-handled.
- Rule PLB-C059 key-error-not-handled.
- Rule PLB-C060 spaces-into-numeric.
- Rule PLB-C061 unchecked-numeric-move (off by default).
- Rule PLB-C062 varying-subscript-out-of-range.
- Rule PLB-C063 varying-refmod-out-of-range.
- Rule PLB-C064 duplicate-condition-value.
- Rule PLB-C065 open-in-loop.
- Rule PLB-J010 dsn-invalid.
- Rule PLB-J011 dd-name-repeated.
- Rule PLB-J012 read-after-delete.
- Rule PLB-C066 identical-branches.
- Rule PLB-K006 return-transid-without-commarea.
- Rule PLB-K007 commarea-too-short.
- Rule PLB-I005 dli-status-not-checked.
- Rule PLB-C070 mq-completion-not-checked.
- Rule PLB-C067 divisor-not-checked (off by default).
- Rule PLB-C068 odo-count-out-of-range.
- Rule PLB-C069 search-index-used-unchecked.
- Rule PLB-C071 contradictory-condition.
- Rule PLB-C072 unreachable-statement.
- Rule PLB-Q011 cursor-opened-in-loop.
- Rule PLB-Q012 fetch-after-commit.
- ICOBOL's xCard and CRT reference formats (`--format xcard`, `--format
  crt`, or a directive), read as GnuCOBOL reads them: xCard as fixed
  with the text to column 255 and continued literals padded to it, CRT
  with the indicator in column 1 and the text to column 320. A
  `COBOL85` format directive is read as fixed. Plumbline now reads
  every reference format GnuCOBOL 3.2 accepts.
- Rule PLB-M019 commented-out-code (off by default).
- Rule PLB-M020 constant-condition.
- Rule PLB-M018 signed-to-unsigned, off by default.
- Rule PLB-C053 exit-program-in-main. `dump calls` is unchanged; the
  call graph also keeps each program's first `EXIT PROGRAM`.
- Rule PLB-J007 dataset-created-twice. `dump jcl` is unchanged; the
  JCL reader now keeps the normal disposition of each DD as well.
- Language server: hover on a condition name (level 88) shows its
  `VALUE` clause and the item it tests.
- Language server: signature help inside the `USING` phrase of a
  `CALL "NAME"` lists the called program's parameters and marks the
  one at the cursor.
- Language server: hover on the program name of a `CALL "NAME"` shows
  where the program is and its `PROCEDURE DIVISION USING` parameters.
- Language server: hover on a table name in embedded SQL lists its
  columns from the `DECLARE TABLE`.
- Language server: a code lens above each record counts the
  references that read it, write it, and pass it to a `CALL`.
- Language server: go to definition from `CALL "NAME"` to the program
  called, in the same file, another open file, or `NAME.cbl` or
  `NAME.cob` in the file's directory.
- Language server: a finding's code links to its rule's section of the
  reference (`codeDescription`), and unreachable code, unused data
  items, and unused copybooks are tagged unnecessary, `ALTER` deprecated.
- A `Dockerfile` for a container image with Plumbline and the GnuCOBOL
  run-time library, built and run by CI when it changes.
- docs/ci.md: running Plumbline in CI.
- The COBOLX reference format (`--format cobolx`, `>>SOURCE FORMAT
  COBOLX`).
- `format --to fixed|free` converts sources in VARIABLE, X/Open,
  terminal, and COBOLX format: each format's text columns, comments,
  page ejects, debugging lines, and continued literals are read as the
  compiler reads them.
- X/Open free form and ACU terminal reference formats (`--format xopen`,
  `--format terminal`, or `>>SOURCE FORMAT XOPEN|TERMINAL`), and the
  padding of continued literals to each format's margin.
- Micro Focus's VARIABLE reference format, fixed with the text running
  to column 250: `--format variable`, `format variable` in
  `plumbline.conf`, or `>>SOURCE FORMAT VARIABLE`. `dump lines` names
  such lines `var`.
- `plumbline summary`: one row per program with its size, complexity,
  maintainability index, and findings by severity, as text, Markdown,
  CSV, or JSON.
- `metrics`: Halstead's measures and the maintainability index of each
  program, in text, JSON, and CSV.
- `doc` gives each program's maintainability index with its size.
- `check --diff FILE`: report only the findings on the lines a unified
  diff adds or changes.
- `check --report checkstyle`: Checkstyle XML, for review tools and CI
  plugins that read it.
- `check --report junit`: a JUnit XML test report, one failing test
  case per finding and one passing case per clean file.
- `make fuzz` (`tools/fuzz.py`): `plumbline check` on damaged copies of
  the corpora's sources, with the bounds-checked build.
- Rule PLB-J009 referback-unresolved. The JCL reader resolves
  backward references (`DSN=*.STEP.DD`), and a `DSN=` reference takes
  the data set name of the DD it names.
- Rule PLB-J008 cond-step-unknown, for `COND` tests and `IF`
  statements. The JCL reader keeps each step's `COND` operand and the
  steps each `IF` tests.
- Language server: selection ranges (expand selection) from a name out
  to its statement, paragraph, section, division, and program.
- `check --report codeclimate`: Code Climate issues for GitLab's code
  quality reports, with fingerprints that survive moved lines.
- Language server: hover on a host variable of embedded SQL shows the
  column it is paired with, its type, and whether it is fetched or
  stored.
- Rules PLB-Q006 host-variable-too-small and PLB-Q007
  host-variable-too-large, against the DECLARE TABLE of the file.
- Rule PLB-Q008 null-without-indicator.
- Rule PLB-Q009 update-of-read-only-cursor.
- Rule PLB-Q010 cursor-undeclared.
- `plumbline crud`: which programs create, read, update, and delete
  which DB2 tables, COBOL files, and CICS files, as text, CSV, or JSON;
  `plumbline doc` shows each program's rows, and `graph --kind crud`
  draws them.
- `dump sql`: the tables a file declares, its cursors, and the pairs of
  a column and a host variable of its SELECT, FETCH, INSERT, and UPDATE
  statements.
- `plumbline lineage NAME`: the statements and items a data item's
  value comes from, or with `--forward` goes to, as text or JSON.
- `lineage` crosses calls between the programs of the run: a LINKAGE
  item shows the argument each caller passes in its place, and a
  `CALL` the parameter it passes the item to.
- `lineage --report dot`: the trails as a Graphviz graph.
- `lineage` names the table column of embedded SQL that gives an item
  its value (`SELECT INTO`, `FETCH`) or that it is stored in (`INSERT`,
  `UPDATE`), and the CICS file, map, queue, or container that an
  `EXEC CICS` command reads it from or writes it to.
- `plumbline duplicates`: paragraphs with the same code, across the
  programs of the run, as text or JSON.
- `plumbline xref`: the cross-reference of each program, its data
  items and procedures with the lines that define and name them, as
  text or JSON.
- SARIF reports link each rule to its section of the rule reference
  (`helpUri`), and the tool to the project (`informationUri`).
- Rules PLB-C039 decimal-to-alphanumeric and PLB-M016
  signed-to-alphanumeric (off by default).
- Rule PLB-J005 temp-not-created.
- Rule PLB-M011 evaluate-without-other (off by default).
- Rule PLB-M012 deep-nesting (off by default, limit 5).
- Rule PLB-M013 unused-copybook.
- Rules PLB-M014 sql-select-star and PLB-M015 packed-even-digits (off
  by default).
- `plumbline rules [--report text|json]` lists the rules as configured.
- Conditional compilation: `>>IF`/`>>ELIF`/`>>ELSE`/`>>END-IF` and
  `$IF`/`$ELSE`/`$END` with `DEFINED` and `SET` conditions, and
  `--define NAME` (`-D`).
- `--tab-width N` (`tab-width` in `plumbline.conf`), as `cobc -ftab-width`.
- A Visual Studio Code extension (`editors/vscode`) that runs the
  language server.
- `plumbline lsp` finds references and highlights them, telling reads
  from writes, renames data items and procedures, gives folding
  ranges, offers quick fixes that suppress a finding, finds symbols
  across the open files, gives the call hierarchy of paragraphs, and
  semantic tokens for highlighting.
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
- `--intrinsics all|NAME,...` (and `intrinsics` in `plumbline.conf`):
  intrinsic functions that may be named without `FUNCTION` in every
  program, as GnuCOBOL's `-fintrinsics` allows.
- `impact --changed LIST`: the programs and job steps that a set of
  changed files reaches, as text or JSON, for choosing what to rebuild
  and test.
- Visual Studio Code: `Plumbline: Show what the name under the cursor
  reaches` runs `plumbline impact` over the workspace's COBOL and JCL
  files.
- Language server: for a contradictory condition (PLB-C071), a quick
  fix that changes its `AND`s to `OR` or its `OR`s to `AND`.
- Language server: for `NEXT SENTENCE` in a scope ended by a terminator
  (PLB-C004), a quick fix that puts `CONTINUE` in its place.

### Changed

- In a file with a copybook that was not found, PLB-C009 reports each
  undeclared name once, naming the missing copybook; on CardDemo's MQ
  programs that is 100 findings instead of 167.
- Checking is faster: the NIST suite in one run went from 17.2 to 9.8
  seconds.
- The rules of embedded SQL and CICS commands run only for files with
  `EXEC SQL` or `EXEC CICS` statements: the NIST suite, with more rules
  than before, takes 12.7 seconds instead of 14.9.
- `make corpus-gnucobol` leaves out the test cases GnuCOBOL expects to
  fail (`AT_XFAIL_IF([true])`), 36 programs, and checks each program
  with its test's `-fintrinsics`: no names are reported as undefined
  on the corpus now.
- PLB-C028 comparison-never-true also reports an alphanumeric item
  compared for equality with a literal longer than the item, also as
  the subject of an `EVALUATE` with that literal in a `WHEN`.

### Fixed

- A pipe closed early (`plumbline rules | head`) ends plumbline quietly,
  as it does other tools; the run-time library reported it as a crash,
  with a stack of COBOL statements on standard error.
- A directory given as an input is reported (RD001) instead of read as
  an empty file, which let `plumbline check src` pass without a word.
- In ACU terminal format, a `/` in column 1 is a page eject, as in the
  other formats, and text past column 320 is not part of the program.
- `lineage` writes alphanumeric literals in statement text with their
  quotes and prefix, as `MOVE "Y" TO WS-FLAG`, not `MOVE Y TO WS-FLAG`.
- `USAGE SQL TYPE IS type` (DB2 locators, LOBs, ROWID) is one usage
  clause: its type is no longer read as a TYPEDEF name and reported as
  undeclared (PLB-C009).
- A doubled quote split by the right margin of fixed format (the first
  quote in column 72, the second after the continuation line's quote)
  no longer ends the literal; NIST's NC215A now reads without errors.
- A signed literal at the start of pseudo-text (`==+1==`) was read as
  an operator and a number, so `COPY ... REPLACING ==+1== BY ...` never
  matched the literal `+1` of the copybook.
- In `ADD a TO b GIVING c` (and `SUBTRACT ... FROM`, `MULTIPLY ... BY`,
  `DIVIDE ... INTO` with `GIVING`), `b` was taken as both read and set;
  it is only read.
- PLB-M005 reported the object of OCCURS DEPENDING ON as never read,
  though every use of the table reads it.
- On a file system that ignores case (macOS), a copybook named in
  upper case was reported under its lower-case spelling.
- PLB-Q001 took the cursor of `FETCH ... FROM cursor` for a table.
- The JCL reader kept only the first data set of a concatenation; the
  `DD` statements without a name that follow it are now read too.
- `metrics` counted the statements before a program's first paragraph
  as running to the end of the procedure division.
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
- The NO DATA and WITH DATA phrases of RECEIVE hold their statements,
  as AT END does, instead of leaving them beside the RECEIVE.
