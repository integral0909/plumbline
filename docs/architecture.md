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

A file can be added before it is read (`PLB-SRC-ADD`), which gives it
its id, and its lines can be released again (`PLB-SRC-RELEASE`). Lines
are only ever appended, so releasing is a rewind to a mark taken
earlier. A released file keeps its id, path, and line count, and
`PLB-SRC-ENSURE` reads it again when it is needed. The first read
reports the file's problems and a later read keeps quiet. Paths are
found through a hash index, so looking up a copybook does not depend on
how many files a run has.

### Checking many files

`plumbline check` adds every input first, so inputs have ids 1 to N in
command-line order, and then takes them one at a time:

1. read the input (copybooks are read as the preprocessor meets them);
2. analyze it and run the rules;
3. collect its programs and calls into the call graph;
4. settle which of its findings `plumbline: ignore` comments suppress;
5. release its lines and its copybooks' lines.

Only the lines of one input and its copybooks are in memory at a time.
Findings and the call graph refer to source by file id and line, which
stay valid. Some work needs a released file's lines again:

- the call rules, which run after the last input;
- baselines, whose entries hold the text of the reported line;
- the HTML report's excerpts.

For these, `PLB-SRC-LINE-INDEX` reads the file again, keeping one
such file at a time.

A run takes up to 10,000 inputs, which together with their copybooks
may be up to 20,000 files, and keeps up to 100,000 findings. Findings
beyond that are counted and reported as error FN001. The NIST suite's
459 programs (347,000 lines) check in one run in about 10 seconds, with
the same findings as one run per program (see [corpus](corpus.md)).

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

The call graph also gathers what a program needs from the rest of
the application, for the rules that check it against JCL, maps, and
resource definitions: its files (the DD name of each `SELECT ...
ASSIGN`, its open modes, `OPTIONAL`, sort files), the maps of its `EXEC
CICS SEND MAP` and `RECEIVE MAP`, the resources its other CICS commands
name, its SQL tables and how it uses them, its `EXEC DLI` calls, and
short literals that may name other programs. A name counts when it is
a literal, or a data item whose `VALUE` is a literal and that no
statement changes.

Once every file is collected, `PLB-CALL-RESOLVE` matches literal names
the way COBOL scopes program names. It looks first at programs the
caller contains, then at `COMMON` programs of the programs containing
the caller, and then at outermost programs and entry points of any file.
A name that matches several outermost programs is left unresolved.
Names are compared without regard to case.

`plumbline dump calls FILE...` prints the programs and calls.

### Beyond COBOL: JCL, maps, and definitions

An application is more than its programs: JCL runs the batch programs
and gives them their files, BMS maps are the screens of the online
programs, CICS resource definitions name the transactions, files, and
programs of a region, and IMS DBDs and PSBs describe the databases and
what each program may see of them. `check` reads them with the
programs, by the extension of each input, before the programs:

| Input | Reader | Model |
|---|---|---|
| `*.jcl`, `*.prc` | `src/lib/plbjcl.cob` | jobs, procedures, steps, DD statements (`copy/plbjcl.cpy`) |
| `*.bms` | `src/lib/plbbms.cob` | mapsets, maps, fields (`copy/plbbms.cpy`) |
| `*.csd` | `src/lib/plbcsd.cob` | CICS resources (`copy/plbcsd.cpy`) |
| `*.dbd`, `*.psb` | `src/lib/plbims.cob` | databases, segments, fields; PSBs, PCBs, sensitive segments (`copy/plbims.cpy`) |

BMS and IMS sources are assembler macros; `src/lib/plbasm.cob` reads
their statements (names, operations, operands continued by column 72)
for both. Each reader has a `dump` command of its own.

The rules that bring the models together run once per run, after the
call graph is resolved: J rules (`src/lib/plbrjcl.cob`) check job steps
against the files of the programs they run, B rules
(`src/lib/plbrbms.cob`) check maps and the programs' use of them, K
rules (`src/lib/plbrcics.cob`) the resources CICS commands name, I rules
(`src/lib/plbrims.cob`) PSBs and DL/I calls, and A rules
(`src/lib/plbrapp.cob`) the application as a whole. One check runs per
program while its tables are still there: the symbolic map a program
copies against the BMS map it was generated from.

### Inventory

`src/lib/plbinv.cob`.

`plumbline inventory` writes the models and the call graph out as a
description of the application: each program with what starts it and
what it uses, then the jobs, transactions, and maps, as text or JSON.

### Copybook fields

`src/lib/plbfield.cob`, with its table in `copy/plbfld.cpy`.

`plumbline fields` reads each program once. After a file is analyzed,
`PLB-FIELDS-COLLECT` marks the symbols its statements name (with the
groups they are in), and the keys, status items, and `DEPENDING ON`
objects its clauses name, then adds each item whose name is in a
copybook to a run-wide table, keyed by the copybook and the line of the
name, with a chain of entries per copybook. Each file counts once per
item, both as a program that copies it and as one that names it.

### Cross-reference

`src/lib/plbxref.cob`.

`plumbline xref` reads each program once and lists it right after it
is analyzed. `PLB-XREF-FILE` threads two sets of chains through
existing tables, built backwards so each comes out in source order: one
per symbol through the reference table, and two per procedure unit
through the edge table of the procedure graph, one for the edges that
target the unit and one for the edges that end a THRU range at it or
ALTER its GO TO. The two unit chains are merged by edge number when
they are written. Nothing is kept from one file to the next except
whether a program has been written, which the caller holds so that
programs are separated in text and in JSON.

### Embedded SQL

`src/lib/plbsqlu.cob`, with its model in `copy/plbsqlm.cpy`.

`PLB-SQL-MODEL-BUILD` reads the EXEC SQL blocks of a file's tokens
twice: first the declarations, of tables (`DECLARE name TABLE`, from
DCLGEN copybooks) and of cursors, then the statements that move values
between columns and host variables. Each statement keeps its pairs of
a column and a host variable: a `SELECT ... INTO` pairs its select
list with its `INTO` list, a `FETCH` its cursor's select list with its
`INTO` list, an `INSERT` its column list with its `VALUES`, and an
`UPDATE` each `SET column = :host`. COBOL drops commas, so lists are
split at the commas of the source text between their tokens
(`PLB-SQL-COMMA-BETWEEN`), outside parentheses. `dump sql` prints the
model.

### CRUD matrix

`src/lib/plbcrud.cob`, with its table in `copy/plbcrud.cpy`.

`plumbline crud` reads each program once. `PLB-CRUD-COLLECT` takes the
tables of each SQL statement from the SQL model, the COBOL file
statements from the syntax tree (a record's FD is the `FD` node above
its symbol's), and the CICS file commands with their `FILE` or
`DATASET` operand, whose item is replaced by the literal of its
`VALUE` clause when it has one. Each use is entered for the innermost
program around it, one row per program, kind, and resource, with a
flag for each operation; `PLB-CRUD-PRINT` sorts the rows.

### Data lineage

`src/lib/plblineage.cob`.

`plumbline lineage` reads each program once and traces each item of
the name in it. The tree is walked with an explicit stack of items and
statements, since COBOL paragraphs do not recurse: an item's frame
pushes the statements that give it a value (the references with a
storing role to it, a group it is in, or an item in it, and the READs
of its file for a record), in reverse source order so that they come
off in order; a statement's frame pushes the items it reads. Forward,
the roles swap. An item is marked seen when it is expanded, and later
frames of it print "see above".

The command analyzes the run once first, as `doc` does, for the call
graph (`PLB-CALL-RESOLVE` has matched each call to its program). A
LINKAGE item's frame, backward, finds its program in the graph by name
and file, the place of its record among the program's parameters, and
each resolved call to the program; the argument in that place is a
leaf below the item. A CALL statement's frame, forward, finds its call
entry by file and line and the first argument that names the item, a
group it is in, or an item in it, and shows the parameter there. The
other program's statements are not followed: they belong to another
file's analysis.

An `EXEC SQL` statement's frame builds the file's SQL model
(`PLB-SQL-MODEL-BUILD`) the first time it is needed, finds the
statement by its `EXEC` token, and, for each pair whose host variable
is the item or related to it, shows the column as a leaf: backward for
`SELECT INTO` and `FETCH` (whose table is that of its cursor's
declaration), forward for `INSERT` and `UPDATE`. An `EXEC CICS`
statement's frame reads the command and its options from the tokens:
the resource (`FILE` or `DATASET`, `MAP`, `QUEUE` or `QNAME`,
`CONTAINER`) and the references inside `INTO( )` (backward) or
`FROM( )` (forward).

With `--report dot` the frames write Graphviz nodes and edges instead
of lines. Each item and statement is drawn once, at its first frame
(`WS-ITEM-NODE`, `WS-STMT-NODE`), and later frames only add an edge to
it, so trails that meet are one graph; `strict digraph` merges the
edges drawn twice. Edges point from what gives a value to what is
given it: from child to parent backward, from parent to child
forward.

### Duplicate code

`src/lib/plbdup.cob`, with its table in `copy/plbdupt.cpy`.

`plumbline duplicates` reads each program once. After a file is
analyzed, `PLB-DUP-COLLECT` hashes the body of each paragraph of at
least the minimum length: each token's kind and characters, words in
upper case, with a separator after each. Two polynomial hashes modulo
different primes below 2^31 are kept, with the body's token and
statement counts, and where the paragraph is. `PLB-DUP-PRINT` sorts
the run's entries by token count (down) and hashes, so that a group is
a run of equal entries, and writes each group of two or more.

### Program documentation

`src/lib/plbdoc.cob`.

`plumbline doc` reads the run twice. The first pass is the one the
inventory makes, for the call graph and the models; the second reads
each program again, because its tokens, symbols, and procedure graph
are released after each file. For each program of the metrics it
writes the inventory's description of that one program, the paragraph
table (from the metrics and the PERFORM and GO TO edges of the
procedure graph), and the program's records from the layout. A nested
program is described from the call graph directly, because the
inventory counts its calls as its outermost program's.

### Metrics

`src/lib/plbmetr.cob`, with its table in `copy/plbmetr.cpy`.

`PLB-METRICS-COMPUTE` measures each program of a file and each of its
units, using the tree, the symbol table, and the procedure graph.
Statements are counted in the innermost unit whose tokens hold them.
Decisions come from the tree: IF statements, WHEN blocks other than
WHEN OTHER, PERFORM statements that loop, conditional phrase blocks,
AND and OR in condition nodes, and the targets of GO TO DEPENDING ON.
Nesting is the number of statements a statement is inside, plus one.
The text, JSON, and CSV writers are in the same file. The size rules
PLB-M009 and PLB-M010 (`src/lib/plbrsize.cob`) use the same figures.

### Graphs and impact

`src/lib/plbgraph.cob`, with the include graph in `copy/plbigr.cpy`.

The PERFORM graph comes from the procedure graph of each file. The call
graph is the one the call rules use. The include graph collects, per
run, an edge for each file that includes a copybook, from the
preprocessor's inclusion table of each file. The writers produce DOT or
JSON. `PLB-IMPACT` searches the include or call graph backwards from a
copybook or program. For each file or program it reaches, it notes the
one it was reached through.

### Formatter

`src/lib/plbfmt.cob`.

The formatter works from the reader's line table (kind, indicator,
content columns, inline comment, and the quote of a literal left open),
not from tokens. Comments and layout are kept, and only the reference
format changes. A line, or a line and its continuations, becomes one or
more output lines. In `--check` mode those lines are compared with the
input instead of written. The test of the formatter is that it changes
no token: `tests/tools/roundtrip_format.py` compares the tokens of a
file with those of its free and fixed versions.

### Language server

`src/lib/plblsp.cob` and the `lsp` part of `src/cli/plumbline.cob`.

Messages are read a byte at a time from standard input, opened as a
file of one-byte records, because a pipe cannot be read by position.
Replies are written with `DISPLAY` and flushed with the C library's
`fflush`. `PLB-JSON-GET` finds the first `"key":` in a message and
decodes its value. That is enough for the few fields the server reads,
because a quote inside a JSON string is always escaped. On each change,
the editor's text is written to a copy, and the copy goes through the
same steps as `plumbline check`. Position requests look up the token at
the position, then its reference or procedure name: definitions,
references, highlights, rename, and the call hierarchy all start there.
Semantic tokens classify the document's tokens from the reference
table, the symbol table, and the tree.

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
[rule]`), as JSON, or as SARIF 2.1.0 (`src/lib/plbreport.cob`), or as
an HTML page (`src/lib/plbhtml.cob`) that shows each finding with the
source lines around it, or as a JUnit XML test report
(`src/lib/plbjunit.cob`) with a test case per finding, per diagnostic,
and per clean file, or as Checkstyle XML (`src/lib/plbckst.cob`); the
two XML reports escape their text with `PLB-XML-TEXT`
(`src/lib/plbxml.cob`). The SARIF
log lists every rule with its default level, one result per finding with
a `ruleIndex` into that list, and diagnostics as tool execution
notifications. Paths are percent-encoded as URIs.

Before reporting, comments of the form `plumbline: ignore` mark the
findings they suppress (`src/lib/plbsupp.cob`). Then a baseline, if one
is given, marks the findings it lists (`src/lib/plbbase.cob`), and a
diff, if one is given, marks those not on the lines it adds
(`src/lib/plbdiff.cob`, which follows each hunk by its line counts).
All three are left out of every report and of the exit code.

Settings in `plumbline.conf` are read by `src/lib/plbconf.cob` and
applied by the command line program through the same code as its
options.

Rule ids are `PLB-<category><number>`, where the categories are
correctness (C), maintainability (M), portability (P), security (S),
SQL (Q), the application as a whole (A), BMS maps (B), JCL (J), CICS
resources (K), and IMS (I).
See the [rule reference](rules.md).

## Design principles

- **Written in COBOL.** The analyzer is built in the language it analyzes,
  and its own sources are the first test corpus.
- **Never execute the input.** Analysis is purely static.
- **Precise locations.** Every finding maps back to a file, line, and
  column in the original source, including inside copybooks.
- **Tables over pointers.** Data lives in `OCCURS` tables with explicit
  limits. Exceeding a limit is a reported error, never silent truncation.
