# Performance

Plumbline reads and analyzes each program in one pass per stage
(preprocessing, parsing, symbols, procedure graph, references), then
runs the rules on the tables those stages build. The aim is that time
grows with the size of the input, not faster.

## Measured

On an Apple M1, with GnuCOBOL 3.2 and the default `make` build
(no optimization flags):

| Input | Lines | `plumbline check` |
|---|---:|---:|
| NIST COBOL-85 suite, 459 programs in one run | 345,140 | 12.4 s, 250 MB |
| CardDemo's 29 base programs (without copybooks) with their JCL, maps, and CICS definitions | 19,496 | 1.2 s |
| Generated program, 2,500 paragraphs (`make bench`) | 25,259 | 0.8 s |
| Generated program, 5,000 paragraphs | 50,509 | 1.6 s |
| Generated program, 10,000 paragraphs | 101,009 | 3.2 s |

## `make bench`

`tools/bench.py` writes programs of 2,500, 5,000, and 10,000
paragraphs, each with a data item of its own, and times `check` on
them. It prints the time per thousand lines and how much the time grew
from the size before. Doubling the program should about double the
time; a growth near 4 means some pass or rule compares everything with
everything.

Two such passes were found this way and replaced by hashed lookups:
resolving a name to its data items read the whole symbol table for
every reference, and PLB-C035 duplicate-paragraph compared every
paragraph with all those before it. A program of 80,000 lines took
13.5 s before and 2.5 s after.

## Limits

The tables have fixed sizes (`copy/*c.cpy`): for instance 500,000
tokens and 100,000 data items in one file with its copybooks, and 20,000
paragraphs and sections. Past a limit, the input is still read, and a
diagnostic says what was left out ([diagnostics](diagnostics.md)).
