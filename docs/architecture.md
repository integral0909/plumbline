# Architecture

This document describes the analyzer's design. Plumbline is under active
development: sections marked *(planned)* describe intended structure that
does not exist in code yet.

## Pipeline

```
source files ──► reader ──► preprocessor ──► lexer ──► parser ──► AST store
                                                                     │
       reports ◄── reporters ◄── rule engine ◄── analyses ◄──────────┘
```

Each stage is a separate module in `src/lib/` with its own unit suite. The
stages communicate through tables defined in copybooks, not through global
state, so each stage can be tested on hand-built input.

### Reader

`src/lib/plbread.cob` and `src/lib/plbclass.cob`, with tables in
`copy/plbsrc.cpy`.

A file is loaded in two passes. The first pass reads each physical line,
expands tabs (8-column stops, as cobc does), and appends the text to a
shared heap. The second pass picks the starting format and classifies
every line:

- **fixed format**: sequence area (1–6), indicator (7), area A (8–11),
  area B (12–72), identification area (73–80, ignored). Indicator `*`
  and `/` mark comments, `-` a continuation, `D`/`d` a debugging line,
  and `$` a directive.
- **free format**: `*>` starts a comment anywhere, `>>` a directive, and
  `>>D` a debugging line.

In both formats the scanner tracks alphanumeric literals, including
doubled quotes and literals continued from the previous line, so `*>`
inside a literal is not taken as a comment.

The starting format is given by the caller, or detected. Detection
samples up to 100 lines and checks whether column 7 holds a valid
indicator. `>>SOURCE FORMAT` and `$SET SOURCEFORMAT` directives switch
the format for the lines that follow.

Each line records its file, physical line number, kind, content columns,
area-A flag, and any literal left open at its end. Findings can therefore
point at the exact source the user wrote.

Hard limits (files, lines, heap size, 1024-column lines) are enforced
with diagnostics, never with silent truncation.

### Preprocessor *(planned)*

Expands `COPY ... [REPLACING ...]` and `REPLACE` statements. Copybooks are
resolved against user-provided search paths only. Resolution never follows
a path outside those roots (see [SECURITY.md](../SECURITY.md)). Nested
copies are tracked on a stack to detect recursion and to build the source
map for findings inside copybooks.

### Lexer and parser *(planned)*

The lexer produces tokens: words, literals (alphanumeric, national,
hexadecimal, numeric), picture strings, and separators. The parser is
hand-written recursive descent over the four divisions. It recovers at
sentence and paragraph boundaries, so one syntax error does not hide the
rest of the program.

The AST is stored in flat, indexed tables (node kind, parent, first child,
next sibling, token span) rather than pointer structures. That fits COBOL's
data model and keeps traversal cheap.

### Analyses *(planned)*

- **Symbols**: data description entries, level numbers, `REDEFINES`,
  `OCCURS [DEPENDING ON]`, `88` condition names, and picture analysis
  (category, size, scale, sign).
- **Control flow**: paragraphs and sections as nodes; `PERFORM`,
  `PERFORM THRU`, `GO TO`, `GO TO DEPENDING`, fall-through, and
  `STOP RUN`/`GOBACK` as edges. Yields reachability and PERFORM ranges.
- **Data flow**: reaching definitions over the control-flow graph, used for
  uninitialized-use and dead-store checks.
- **Call graph**: static `CALL` literals across programs in one run.

### Rules and reporting *(planned)*

Rules are identified as `PLB-<category><number>`, for example `PLB-C001`.
The categories are correctness (C), maintainability (M), portability (P),
and security (S). Each rule reads the analysis tables and emits findings
with a severity, location, and message. Findings can be suppressed inline
(`*> plumbline: ignore PLB-C001`) or through a baseline file.

Reporters write findings as plain text, JSON, or SARIF 2.1.0.

## Design principles

- **Written in COBOL.** The analyzer is built in the language it analyzes,
  and its own sources are the first test corpus.
- **Never execute the input.** Analysis is purely static.
- **Precise locations.** Every finding maps back to a file, line, and
  column in the original source, including inside copybooks.
- **Tables over pointers.** Data lives in `OCCURS` tables with explicit
  limits. Exceeding a limit is a reported error, never silent truncation.
