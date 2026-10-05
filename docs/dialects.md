# COBOL dialects

Plumbline reads COBOL 85 and the parts of COBOL 2002 and 2014 that
programs use, with the extensions of IBM Enterprise COBOL, Micro Focus,
ACUCOBOL, and GnuCOBOL that are common in practice. What it reads has
been measured against three corpora: the [NIST COBOL-85
suite](corpus.md), [GnuCOBOL's own tests](corpus-gnucobol.md), and AWS's
[CardDemo application](corpus-carddemo.md). This page lists what is
supported, and what is not.

Plumbline does not compile: it does not need to know which compiler a
program is for, and it accepts the union of what these dialects allow.
A word that is reserved in one dialect and a name in another is read
as a name where a name can stand.

## Reference formats

| | |
|---|---|
| Fixed (columns 1–6 sequence, 7 indicator, 8–72 text) | yes |
| Free | yes |
| Detecting which of the two a file uses | yes |
| Variable (as fixed, with the text running to column 250) | yes, with `--format variable` or a directive |
| Switching with `>>SOURCE [FORMAT] [IS] FIXED`/`FREE`/`VARIABLE`/`XOPEN`/`TERMINAL`/`COBOLX`/`XCARD`/`CRT` (and `COBOL85`, read as fixed), `$SET SOURCEFORMAT"..."`, `>>SET SOURCEFORMAT` | yes |
| X/Open free form (free, with `*`, `/`, and `D` in column 1) | yes, with `--format xopen` or a directive |
| ACU terminal (free, with `*`, `/`, `\D`, and `-` continuations in column 1, text to column 320) | yes, with `--format terminal` or a directive |
| COBOLX (indicator in column 1, text to column 255) | yes, with `--format cobolx` or a directive |
| ICOBOL xCard (as fixed, with the text running to column 255) | yes, with `--format xcard` or a directive |
| ICOBOL CRT (free, with `*`, `/`, `D`, and `-` continuations in column 1, text to column 320) | yes, with `--format crt` or a directive |
| Other formats | no (diagnostic RD004) |
| Tabs | expanded to stops every 8 columns, or `--tab-width N` |

## Compiler directives

| | |
|---|---|
| `>>IF`, `>>ELIF`, `>>ELSE`, `>>END-IF`; `$IF`, `$ELSE`, `$END` | conditions `NAME [IS] [NOT] DEFINED` and `NAME [IS] [NOT] SET` are decided; for other conditions every branch is analyzed |
| `>>DEFINE [CONSTANT] NAME [AS ...]`, `$SET CONSTANT`, `>>SET CONSTANT` | the names are known, and count for `DEFINED` |
| `--define NAME` | defines `NAME` for the whole run |
| `>> IF` (with a space), `>>` starting in column 7, `$` directives indented into area A or B | yes |
| Other directives (`>>TURN`, `$SET` options) | read and ignored |

## Copybooks

| | |
|---|---|
| `COPY name [OF|IN library]`, nested copybooks, `SUPPRESS` | yes |
| `REPLACING` pseudo-text, words, literals, `LEADING`, `TRAILING` | yes |
| Partial words: `:TAG:` (COBOL 2002, Micro Focus, GnuCOBOL) and `(TAG)` (IBM) | yes |
| `REPLACE`, `REPLACE ALSO`, `REPLACE OFF` | yes |
| `EXEC SQL INCLUDE` | yes |
| Copybook files | the name in lower and upper case, bare or with `.cpy`, `.cbl`, `.cob`, `.dcl` in either case, in the including file's directory and the `-I` directories |

## Literals

| | |
|---|---|
| Alphanumeric, national (`N"..."`, `NX"..."`), hexadecimal (`X"..."`, Micro Focus `H"..."`), boolean (`B"..."`, `BX"..."`), Unicode (`U"..."`), DBCS (`G"..."`) | yes |
| ACUCOBOL radix literals `B#101`, `O#17`, `X#FF`, `H#FF`; HP COBOL octal `%47` | yes, read as the numbers they are |
| Figurative constants, `ALL` literals | yes |
| `DECIMAL-POINT IS COMMA` | yes |

## Data division

| | |
|---|---|
| Level 66, 77, 88; `REDEFINES`, `RENAMES` | yes |
| Level 78 constants, also inside a record (Micro Focus) | yes |
| `01 name CONSTANT [IS GLOBAL] [AS] value` | yes; an integer constant can size a picture |
| `OCCURS ... DEPENDING ON`, `OCCURS ... TO UNBOUNDED` | yes; sizes that change at run time are not checked against fixed lengths |
| `USAGE` `COMP-1` to `COMP-6`, `COMP-X`, `BINARY-CHAR` to `BINARY-DOUBLE`, `FLOAT-*`, `POINTER`, `INDEX`, `NATIONAL` | yes, with storage sizes |
| `CURRENCY SIGN ... WITH PICTURE SYMBOL`, several currency signs | yes |
| ACUCOBOL `PICTURE L` | yes |
| Report section (Report Writer) | yes |
| Screen section | entries and their structure; attributes are kept, not checked |
| `BASED`, `EXTERNAL`, `GLOBAL` (also on an FD) | yes |

## Procedure division

| | |
|---|---|
| Sections, paragraphs, `DECLARATIVES`, segmentation numbers | yes |
| Scope terminators and conditional phrases (`ON SIZE ERROR`, `AT END`, `INVALID KEY`, `ON EXCEPTION`, ...) | yes |
| `PERFORM` in all forms, including `UNTIL EXIT`, `FOREVER`, and counts that are qualified or subscripted | yes |
| `ALTER`, `GO TO DEPENDING` | yes |
| `ENTRY`, nested programs, `COMMON`, `RECURSIVE` | yes |
| `PROCEDURE DIVISION USING`, `CHAINING`, `RETURNING` | yes |
| `EXEC SQL`, `EXEC CICS`, `EXEC DLI` | the data they name, and the roles it plays; the rest is skipped |
| `XML GENERATE`, `XML PARSE`, `JSON GENERATE`, `JSON PARSE` | yes |
| `ALLOCATE`, `FREE`, `EXHIBIT`, GnuCOBOL bit operators | yes |
| Intrinsic functions, also without `FUNCTION` under `REPOSITORY. FUNCTION ALL INTRINSIC` | yes |
| Object-oriented COBOL: `CLASS-ID`, `FACTORY`, `OBJECT`, `METHOD-ID`, `INTERFACE-ID`, `INVOKE` | the definitions are parsed as nested units and their code analyzed; classes and objects are not modeled (an `INVOKE` is not a call the call rules check) |

## Names

Plumbline knows the special registers of the standard and of IBM,
Micro Focus, and GnuCOBOL (`RETURN-CODE`, `TALLY`, `XML-CODE`,
`JSON-CODE`, `COB-CRT-STATUS`, `NUMBER-OF-CALL-PARAMETERS`, ...), the
fields of the SQL communication area, the CICS EXEC interface block, and
the DL/I interface block. In a program with `EXEC CICS`, a name starting
with `DFH` that the program does not declare comes from a CICS copybook
(`DFHAID`, `DFHBMSCA`). Words that are keywords only in some statements,
such as `PREVIOUS`, `NEAREST-EVEN`, or `AUTO-SKIP`, are names when a
program declares them and keywords otherwise.

Program names are compared without regard to case, but when two
programs differ only in case, as GnuCOBOL allows, a `CALL` goes to the
one spelled the same way.

## Not supported

- Compiler options that change the language, such as GnuCOBOL's
  `-fintrinsics=all` or IBM's `TRUNC(BIN)`: Plumbline sees only the
  source. Rules whose result would depend on them say so.
- Conditional compilation on conditions other than `DEFINED` and `SET`.
- Object-oriented COBOL beyond the structure of its definitions.
