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

### Symbols

`src/lib/plbpic.cob` and `src/lib/plbsym.cob`, with tables in
`copy/plbpic.cpy` and `copy/plbsym.cpy`.

The picture analyzer expands repetitions (`X(10)`) and classifies a
PICTURE string. It reports the category (alphabetic, alphanumeric,
numeric, numeric-edited, alphanumeric-edited, national, national-edited,
or boolean), display size, digit positions, scale (including `P`
scaling), and sign. It understands floating insertion (`$$,$$9.99`),
zero suppression, `CR`/`DB`, and simple insertion, and it rejects
malformed pictures with a reason. A second routine gives the storage
size for each USAGE: display, national, packed decimal, binary by digit
count, COMP-X, floating point, index, and pointers.

The symbol table has one entry per data description entry. It records
the name, level, section, parent group, category, usage (inherited from
the group when not stated), digits, scale, sign, OCCURS maximum,
DEPENDING ON object, REDEFINES target, and whether a VALUE is given.
Sizes are computed bottom-up: a group is the sum of its members times
their OCCURS, and REDEFINES members add nothing. Offsets are computed
top-down, with a REDEFINES item starting where its target starts. These
give every item's exact place in its record, which the rules use to
reason about truncation and overlap.

`plumbline dump symbols FILE` prints the table.

### Procedure graph

`src/lib/plbflow.cob`, with tables in `copy/plbflow.cpy`.

The units are the sections and paragraphs of each procedure division, in
source order. Statements before the first section or paragraph form an
unnamed start unit. Each unit knows the next one and whether control can
fall into it. A unit whose last statement is `STOP RUN`, `GOBACK`,
`EXIT PROGRAM`, or a `GO TO` without `DEPENDING ON` does not fall. A
section always falls into its first paragraph. Control never falls out of
`DECLARATIVES`.

Every `PERFORM` and `GO TO` target becomes an edge. So do the
procedures of `SORT` and `MERGE` (`INPUT PROCEDURE` and `OUTPUT
PROCEDURE`), which run like a `PERFORM`. `ALTER X TO PROCEED TO Y`
becomes an edge from the `GO TO` in `X` to `Y`, kept with the edges of
the unit holding the `ALTER`. Procedure names
resolve as the standard says: `P IN S` is a paragraph of section `S`; an
unqualified name is a paragraph of the current section, then a paragraph
unique in the program, then a section. Unknown names and ambiguous
paragraph names are reported.

Reachability tells apart two ways of arriving at a unit:

- **flowed**: from the program entry, by falling through, or by `GO TO`.
  Only a flowed unit carries control on into the next unit.
- **performed**: as part of a `PERFORM` range, which returns at the end of
  its range. A range that ends at a section includes that section's
  paragraphs.

So a paragraph that sits after the end of a performed range, and is
neither fallen into nor jumped to, is correctly reported as unreachable.

`plumbline dump flow FILE` prints the units, their reachability, and their
edges.

Embedded languages: inside `EXEC SQL` the host variables (`:NAME`,
`:RECORD.FIELD`) and inside `EXEC CICS` the option arguments are
scanned for references, and every other token is skipped; their roles
come from the SQL clause or CICS option around them. `EXEC SQL INCLUDE`
is expanded by the preprocessor like `COPY`. `EXEC CICS RETURN`, `XCTL`,
and `ABEND` end a unit, and `EXEC SQL WHENEVER ... GO TO` or `PERFORM`
gets a PROC node like the statements it stands for.

Report Writer descriptions are part of the data division tree: an `RD`
node holds its `CONTROL` clause and the report groups (01 entries with a
`TYPE` clause), whose clauses (`LINE`, `COLUMN`, `SOURCE`, `SUM`, ...)
are clause nodes. The identifiers in `SOURCE`, `SUM`, `TYPE CONTROL ...`,
`CONTROL`, and `PRESENT WHEN` are scanned like the procedure division
and become references read by their clause.

### Data references

`src/lib/plbref.cob`, with its table in `copy/plbref.cpy`.

Every identifier in a procedure division is found and resolved. An
identifier is a user-defined word that is not a procedure name (those are
the parser's `PROC` nodes and paragraph headers), not an intrinsic
function name, and not inside `EXEC ... END-EXEC`. Its `IN`/`OF`
qualifiers, subscripts, and reference modifier come with it, and
identifiers inside subscripts are references of their own.

Resolution looks for data items of the program, and then `GLOBAL` items of
the programs containing it, whose name matches and whose ancestors
include each qualifier in order. A file-section record may also be
qualified by its file name. The outcome is one item, several (an
ambiguous reference), or none. In the last case, the name may still be a
paragraph (`SORT ... INPUT PROCEDURE P`), a name declared in the
environment division, an FD, or an `INDEXED BY` phrase, or a device name
such as `CONSOLE`.

`plumbline dump refs FILE` prints every reference and what it resolved
to.

### Data flow

`src/lib/plbrole.cob`, `src/lib/plbspan.cob`, and `src/lib/plbacc.cob`,
with tables in `copy/plbspan.cpy` and `copy/plbacc.cpy`.

`plbrole` gives each reference a role from its statement's verb and the
nearest keyword before it: read (U), set (D), both (B), unknown (X), or
none (-). `plbspan` gives each data item the record it belongs to and
the byte range it covers there. A table element covers its whole table,
and an item whose size is unknown covers its whole record. Two items
share storage when their ranges in the same record overlap.

`plbacc` builds the access table the data-flow rules share. It holds
every access (references with their roles, `VALUE` clauses, and names
mentioned in the environment division), sorted by record, and whether
each item is checked at all. `PLB-ACCESS-FIND` answers "does any access
with one of these roles touch storage this item shares?"

PLB-C011 and PLB-M005 ask that question for each item. PLB-C012 is a
may-be-set analysis over the procedure graph, with one bit per checked
item:

1. Each paragraph or section becomes a list of events in source order:
   references, `PERFORM`s and `GO TO`s, and the start of looping
   `PERFORM`s.
2. The summary of a unit is everything it may set, plus the summaries
   of every range it performs. It is computed to a fixed point.
3. The entry set of each unit is the union of what may be set where
   control falls, jumps, or is performed into it. It is also computed to
   a fixed point.
4. A final walk of each reachable unit, starting from its entry set,
   reports reads of items that are not set yet.

### Call graph

`src/lib/plbcall.cob`, with its table in `copy/plbcall.cpy`.

The other tables describe one file at a time. The call graph collects
the programs of every file in the run instead, so that a call in one
file can be checked against the program it calls in another:

- **Programs**: their nesting, `COMMON` and `RECURSIVE`, and their
  `PROCEDURE DIVISION USING` parameters, including `BY VALUE` and
  sizes from the symbol table. `ENTRY` points are programs with their
  own parameters.
- **Calls**: the caller, the literal name called (or, for a dynamic
  call, the data item holding the name), and each argument with its
  passing mode and size. An argument's size is known for literals and
  for data items that are not reference-modified, and not known for
  `ANY LENGTH` items, whole tables, numeric literals, `ADDRESS OF`,
  `LENGTH OF`, and functions.

Once every file is collected, `PLB-CALL-RESOLVE` matches literal names
the way COBOL scopes program names. It looks first at programs the
caller contains, then at `COMMON` programs of the programs containing
the caller, and then at outermost programs and entry points of any file.
A name that matches several outermost programs is left unresolved.
Names are compared without regard to case.

`plumbline dump calls FILE...` prints the programs and calls.

### Rules and reporting

`src/lib/plbrule.cob` (catalog and findings) and `src/lib/plbcheck.cob`
(the rules), with tables in `copy/plbrules.cpy` and `copy/plbfind.cpy`.

Each rule is one program that reads the analysis tables and reports
findings through `PLB-FIND-AT-TOKEN`, which takes the rule's configured
severity and does nothing for disabled rules. Rules that run on the
call graph, after all files, report through `PLB-FIND-AT` with a
recorded position instead. Findings are kept separate
from diagnostics. Diagnostics describe problems with Plumbline's input,
while findings describe problems in the analyzed program. Findings are
sorted by file, line, column, and rule with a COBOL table `SORT` before
they are printed.

Reports are written as text (`file:line:column: severity: message
[rule]`), as JSON, or as SARIF 2.1.0 (`src/lib/plbreport.cob`). The SARIF
log lists every rule with its default level, one result per finding with
a `ruleIndex` into that list, and diagnostics as tool execution
notifications. Paths are percent-encoded as URIs.

Before reporting, comments of the form `plumbline: ignore` mark the
findings they suppress (`src/lib/plbsupp.cob`). Then a baseline, if one
is given, marks the findings it lists (`src/lib/plbbase.cob`). Both are
left out of every report and of the exit code.

Settings in `plumbline.conf` are read by `src/lib/plbconf.cob` and
applied by the command line program through the same code as its
options.

Rule ids are `PLB-<category><number>`, where the categories are
correctness (C), maintainability (M), portability (P), and security (S).
See the [rule reference](rules.md).

## Design principles

- **Written in COBOL.** The analyzer is built in the language it analyzes,
  and its own sources are the first test corpus.
- **Never execute the input.** Analysis is purely static.
- **Precise locations.** Every finding maps back to a file, line, and
  column in the original source, including inside copybooks.
- **Tables over pointers.** Data lives in `OCCURS` tables with explicit
  limits. Exceeding a limit is a reported error, never silent truncation.
