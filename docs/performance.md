# Performance

Plumbline reads and analyzes each program in one pass per stage
(preprocessing, parsing, symbols, procedure graph, references), then
runs the rules on the tables those stages build. The aim is that time
grows with the size of the input, not faster.

## Measured

On an Apple M1, with GnuCOBOL 3.2 and the default `make` build, which
passes `-O2` to cobc for the C compiler:

| Input | Lines | `plumbline check` |
|---|---:|---:|
| NIST COBOL-85 suite, 459 programs in one run | 345,140 | 8.8 s, 281 MB |
| CardDemo's 29 base programs (without copybooks) with their JCL, maps, and CICS definitions | 19,496 | 0.9 s |
| Generated program, 2,500 paragraphs (`make bench`) | 25,259 | 0.6 s |
| Generated program, 5,000 paragraphs | 50,509 | 1.1 s |
| Generated program, 10,000 paragraphs | 101,009 | 2.1 s |
| 1,000 generated programs, each calling the next three (`make bench`) | 13,000 | 1.6 s |
| 2,000 generated programs, each calling the next three | 26,000 | 3.5 s |

## `make bench`

`tools/bench.py` writes programs of 2,500, 5,000, and 10,000
paragraphs, each with a data item of its own, and times `check` on
them. Then it writes 1,000 and 2,000 programs of 13 lines, each calling
the three after it, and times `check` on each set in one run. It prints the time per thousand lines and how much the time grew
from the size before. Doubling the program should about double the
time; a growth near 4 means some pass or rule compares everything with
everything.

Two such passes were found this way and replaced by hashed lookups:
resolving a name to its data items read the whole symbol table for
every reference, and PLB-C035 duplicate-paragraph compared every
paragraph with all those before it. A program of 80,000 lines took
13.5 s before and 2.5 s after. Across programs, resolving each `CALL`
compared it with every program of the run; it now reads only the
programs of its name, through a hash.

The rules grow in number, and each costs a little on every file.
Those of embedded SQL and of CICS commands read every token of a file
for its `EXEC` blocks, so they run only for a file whose procedure
division has an `EXEC SQL` or `EXEC CICS` statement; on the NIST suite,
which has none, that took the run from 14.9 to 12.7 seconds, with the
same findings on all three corpora.

Small programs that every rule calls for each node or token
(`PLB-AST-NEXT`, `PLB-TOK-IS-WORD`, `PLB-RULE-FIND`, `PLB-STR-LENGTH`,
...) keep their few items in `WORKING-STORAGE`: GnuCOBOL allocates and
frees a program's `LOCAL-STORAGE` on every call, which a profile showed
as a cost of its own. None of them is called while it runs, and none
needs an item's `VALUE` set again on entry. That took another 7% off
the NIST run.

The scan of each source line for literals and inline comments
(`PLB-SRC-SCAN`, once for every line read) compared its position with
`FUNCTION LENGTH` of the line on every character; GnuCOBOL works out
an intrinsic function and compares with it in its general numeric
code. The end column is now worked out once. With the rules added
since, the NIST run had grown to 12.4 to 12.9 seconds (12.1 s of user
time); the change brought it to 11.9 seconds (11.5 s), with the same
findings on all three corpora.

Thirteen rules later (PLB-C072 to PLB-C083 and PLB-Q013), three runs
took 12.1 to 12.4 seconds (11.8 s of user time), with the same 280 MB
at most. A profile with macOS `sample` put none of the new rules among
the costly ones: the rules that cost most are still use-before-set,
value-never-used, and unused-data-item, and preprocessing and reading
the sources take about as long as all the rules together.

## Build

Until October 2026 the build passed no optimization flag to cobc, and
the C that cobc writes was compiled without optimization. With `-O2`
the build takes about twice as long (20 s against 9 s for the program
on an M1), and every run is faster, with the same output: on the NIST
suite 8.7 to 8.8 seconds against 12.1 to 12.4, the same findings on all
three corpora, and in `make bench` 2.1 against 2.9 seconds for the
largest program and 1.6 against 1.9 for 1,000 programs.

## Limits

The tables have fixed sizes (`copy/*c.cpy`): for instance 500,000
tokens and 100,000 data items in one file with its copybooks, and 20,000
paragraphs and sections. Past a limit, the input is still read, and a
diagnostic says what was left out ([diagnostics](diagnostics.md)).
