# Architecture

This document describes the analyzer's design. Plumbline is under active
development: sections marked *(planned)* describe intended structure that
does not exist in code yet.

## Pipeline

```
source files ──► reader ──► lexer ──► preprocessor ──► parser ──► AST store
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

### Preprocessor

`src/lib/plbpp.cob`, with tables in `copy/plbppopt.cpy` and
`copy/plbincl.cpy`.

The preprocessor works on tokens, not text. `PLB-PP-RUN` lexes the main
file and walks its tokens with an explicit stack of frames, one per file
being expanded:

- **COPY** *name* [`OF`|`IN` *library*] [`SUPPRESS`] [`REPLACING` ...] `.`
  pushes a frame for the copybook. The copybook is read and tokenized
  once per run and cached. The `REPLACING` operands of a COPY statement
  apply only to that copybook's own text. An operand is pseudo-text
  (`==...==`), a word, or a literal. `LEADING` and `TRAILING` replace
  part of a word. A tag such as `:PFX:` is replaced wherever it appears
  inside a word, so `:PFX:-RECORD` becomes `WS-RECORD`.
- **REPLACE** statements are applied in a second pass over the expanded
  text, as the standard requires. `REPLACE ... .`, `REPLACE ALSO ... .`,
  `REPLACE LAST OFF.`, and `REPLACE OFF.` manage a stack of rule sets.

Copybooks are looked up in the directory of the file that contains the
COPY statement, then in each `-I` search path. A word name is tried in
lower case, then upper case, with the extensions `.cpy`, `.cbl`, and
`.cob` (in both cases), then bare. A library name is a subdirectory.
Names and libraries must be relative paths without `..` segments, so COPY
statements in untrusted source cannot reach files outside the search
directories.

A copybook that copies itself, directly or through others, is reported
and not expanded. Nesting is limited to 32 levels.

Every expansion adds an entry to the inclusion table: the copybook, the
inclusion it is nested in, and the location of the COPY statement. Each
output token records the inclusion it came through. A finding inside a
copybook can therefore name the copybook line and the chain of COPY
statements that led there.

`plumbline dump expanded -I DIR FILE` prints the expanded tokens and the
inclusion table.

### Lexer

`src/lib/plbstream.cob` and `src/lib/plblex.cob`, with tables in
`copy/plbstrm.cpy` and `copy/plbtok.cpy`.

The lexer does not scan physical lines. For each file it first builds a
*logical stream*: the significant text of every code line, separated by
newlines. Comment, blank, and directive lines are left out, and so are
debugging lines unless debugging mode is on. Fixed-format continuation
lines are joined directly to the line they continue. A continued literal
is padded to column 72 and resumes after the continuation's opening quote,
exactly as the standard describes. A segment table maps every stream
position back to its source line and column. As a result, continuation
handling lives in one place, and the scanner never has to know about it.

The scanner then produces tokens: words, numeric literals (signed,
decimal, and floating-point), alphanumeric literals with their prefixes
(`X`, `N`, `NX`, `Z`, `G`, `B`, `BX`, `U`), picture strings (recognized
from context after `PIC`/`PICTURE`), separators, operators, and `==`
pseudo-text delimiters. A newline inside an open literal means it was
never terminated. That is reported, and scanning continues on the next
line. Each file's tokens end with an end-of-file token.

Columns are byte positions, so a line containing multi-byte UTF-8
characters reports columns in bytes.

`plumbline dump tokens FILE` prints the token stream.

### Parser

`src/lib/plbparse.cob` (driver, identification and environment
divisions), `src/lib/plbpdata.cob` (data division), and
`src/lib/plbpproc.cob` (procedure division). The tree lives in
`copy/plbast.cpy`, and reserved words are in `copy/plbkwtab.cpy`.

The syntax tree is a flat table of nodes linked by index: parent, first
and last child, and next sibling. Appending a child takes constant time,
and `PLB-AST-NEXT` walks any subtree in pre-order without recursion or a
stack. Every node records the range of expanded tokens it covers, so any
node maps back to source lines, including lines inside copybooks.

The parser is hand-written and non-recursive:

- **Programs** are tracked on a stack. A program that starts before the
  current one has ended is nested in it. `END PROGRAM` must name the
  program it ends.
- **Data entries** are placed by a level-number stack. 01, 77, and 78
  start records; 02–49 go under the nearest item with a lower level; 88
  goes under the item just described; 66 goes under the current record.
  PICTURE, VALUE, REDEFINES, RENAMES, OCCURS (with DEPENDING ON), USAGE,
  SIGN, JUSTIFIED, SYNCHRONIZED, BLANK WHEN ZERO, EXTERNAL, GLOBAL, and
  BASED become clause nodes.
- **Statements** are nested using a context stack of open constructs:
  THEN and ELSE branches, EVALUATE and SEARCH heads and their WHEN
  branches, inline PERFORM bodies, conditional phrases, and statements
  still collecting operands. The COBOL scoping rules follow from how the
  stack is popped. A period closes everything. `ELSE` pairs with the
  innermost open IF. A scope terminator closes the innermost matching
  construct. A phrase such as `NOT AT END` attaches to the innermost open
  statement whose verb accepts it. Without an explicit terminator, every
  statement up to the period belongs to the open phrase, a classic source
  of COBOL bugs that the tree makes visible.

Out-of-line `PERFORM` and `GO TO` targets become `PROC` nodes. Conditions
of IF, EVALUATE, WHEN, and inline PERFORM become `COND` nodes. Other
operands stay as the statement's token range for the analyses to read.
`EXEC ... END-EXEC` is kept opaque.

The parser is lenient. Clauses it does not model are kept in their
entry's token range. Text it cannot parse becomes an `ERR` node with a
diagnostic, and parsing resumes at the next period or statement.

`plumbline dump ast FILE` prints the tree.

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
