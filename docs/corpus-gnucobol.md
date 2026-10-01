# Running Plumbline on GnuCOBOL's test suite

The [NIST suite](corpus.md) is COBOL-85. GnuCOBOL's own test suite is
the second corpus: about a thousand small programs that use the
COBOL 2002 and 2014 additions and the extensions of the dialects
GnuCOBOL accepts (IBM, Micro Focus, ACUCOBOL, RM/COBOL, HP COBOL).

The run-time tests (`tests/testsuite.src/run_*.at`) only hold programs
that GnuCOBOL compiles and runs. So on this corpus:

- every input error Plumbline reports is something it does not
  understand yet, or an extension it does not know;
- every undefined or ambiguous name it reports (PLB-C009, PLB-C010)
  is a false finding, for the same reasons.

`make corpus-gnucobol` downloads GnuCOBOL 3.2 from ftp.gnu.org, checks
it against the SHA-256 that CI builds the compiler from, extracts the
test programs and the copybooks GnuCOBOL installs (the EXTFH and screen
I/O definitions), and checks each program with the reference format
its test compiles it with. The suite is GPL-licensed; none of it is
added to this repository.

`tools/corpus/split_gnucobol.py` reads the Autotest files: each test
case runs from `AT_SETUP` to `AT_CLEANUP`, writes its files with
`AT_DATA`, and compiles them with `AT_CHECK([$COMPILE ...])`. A test
case whose compile is expected to succeed is written to a directory of
its own, with its copybooks and data files, and listed in a manifest
with the format (`-free`, `-fformat=...`) and dialect (`-std=...`) it
compiles with.

## Results

| | First run | Now |
|---|---:|---:|
| Programs (in formats Plumbline reads) | 1,025 | 1,025 |
| Programs with input errors | 44 | 1 |
| Programs with names reported as undefined or ambiguous | 136 | 3 |

Ten more programs are in reference formats Plumbline does not read
(COBOLX, VARIABLE, X/Open free form, ACU terminal) and are not counted.

What the first run found, each fixed with a test of its own:

- level-78 constants inside a record, as in GnuCOBOL's own EXTFH
  copybook `xfhfcd3.cpy`, ended the record: 700 errors from one
  copybook;
- `>> IF`, with a space after `>>`, starting in column 7 of fixed
  format;
- literal forms of other dialects: HP COBOL octal (`%47`), ACUCOBOL
  `B#101`, `O#17`, `X#FF`, `H#FF`, and Micro Focus `H"80"`;
- a second program in a file that starts at `PROGRAM-ID.`, without the
  `IDENTIFICATION DIVISION` header that COBOL 2002 made optional;
- `PERFORM FOREVER`;
- `XML GENERATE` and `JSON GENERATE`, whose `GENERATE` and `SUPPRESS`
  are also Report Writer verbs;
- `01 ... CONSTANT` entries, the `OPTIONS` paragraph, ACUCOBOL's
  `PICTURE L`, and `END PROGRAM` naming a program whose `PROGRAM-ID` is
  a literal;
- `$SET`, `$DISPLAY`, and `>>SET` directives, the constants they
  define, and `>>SET SOURCEFORMAT`;
- conditional compilation: both branches of `>>IF P64 SET` declared
  the same item, which led to [conditional compilation](../README.md#conditional-compilation)
  support;
- `CURRENCY SIGN ... WITH PICTURE SYMBOL "U"`: the lexer read `SYMBOL`
  as a picture, and only one currency symbol was kept;
- numbers in a screen entry (`BACKGROUND-COLOR 0`) taken for the level
  number of the next entry;
- the records of `FD ... GLOBAL` in nested programs;
- GnuCOBOL's special registers (`COB-CRT-STATUS`, `XML-CODE`,
  `JSON-CODE`, `NUMBER-OF-CALL-PARAMETERS`), intrinsic functions named
  without `FUNCTION` under `REPOSITORY. FUNCTION ALL INTRINSIC`, the
  counter of a report group's `OCCURS ... VARYING`, and words that are
  keywords only in their statements: `READ ... PREVIOUS`, `ROUNDED MODE
  NEAREST-EVEN`, `ACCEPT ... FROM DATE YYYYMMDD`, screen attributes such
  as `AUTO-SKIP`, `STOP RUN WITH NORMAL STATUS`, and the bit operators.

What is left:

- **COBOLX format**: one program switches to it with `>>SOURCE FORMAT
  COBOLX`, which Plumbline does not read (RD004).
- **`-fintrinsics=all`**: two programs name `PI` and `E` without
  `FUNCTION`, which a compiler option allows; Plumbline sees only the
  source.
- **`INVOICE-AMOUNT`**: one program uses a name that no entry declares.
  GnuCOBOL 3.2 compiles and runs it; the report is correct as far as
  the program's text goes.
