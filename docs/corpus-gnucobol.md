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

The first run, on 2026-10-01:

| | |
|---|---|
| Programs | 1,035, of which 10 are in reference formats Plumbline does not read (COBOLX, VARIABLE, X/Open free form, ACU terminal) |
| Programs with input errors | 44 |
| Programs with names reported as undefined or ambiguous | 136 |

The causes, from the diagnostics and findings:

- level-78 constants inside a record, as in GnuCOBOL's own EXTFH
  copybook `xfhfcd3.cpy`, ended the record;
- `>> IF`, with a space after `>>`, in column 7 of fixed format;
- literal forms of other dialects: HP COBOL octal (`%47`) and ACUCOBOL
  `B#101`, `O#17`, `X#FF`, `H#FF`;
- a second program in a file that starts at `PROGRAM-ID.`, without the
  `IDENTIFICATION DIVISION` header that COBOL 2002 made optional;
- `PERFORM FOREVER`;
- `XML GENERATE` and `JSON GENERATE` with their exception phrases;
- ACUCOBOL's `PICTURE L`;
- GnuCOBOL's special registers (`COB-CRT-STATUS`, `XML-CODE`,
  `JSON-CODE`, `NUMBER-OF-CALL-PARAMETERS`);
- words that only have a meaning in one statement: `READ ... PREVIOUS`,
  `PROCEDURE DIVISION CHAINING`, `CALL STATIC`, `ACCEPT ... FROM DATE
  YYYYMMDD`, the `ROUNDED MODE` names, and screen attributes such as
  `AUTO-SKIP` and `REQUIRED` in `ACCEPT` and `DISPLAY`.
