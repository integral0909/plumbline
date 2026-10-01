# Rule reference

`plumbline check` runs these rules. Each has an id (`PLB-C001`) and a
name (`unreachable-code`), and either can be given to `--enable` and
`--disable`.

| Id | Name | Default | Summary |
|----|------|---------|---------|
| [PLB-C001](#plb-c001-unreachable-code) | unreachable-code | warning | Paragraph or section can never be executed |
| [PLB-C002](#plb-c002-perform-and-fall-through) | perform-and-fall-through | warning | Paragraph is both performed and fallen into |
| [PLB-C003](#plb-c003-fall-off-end) | fall-off-end | warning | Control can run off the end of the procedure division |
| [PLB-C004](#plb-c004-next-sentence-in-scope) | next-sentence-in-scope | warning | NEXT SENTENCE inside a scope ended by an END- terminator |
| [PLB-C005](#plb-c005-perform-thru-backwards) | perform-thru-backwards | error | PERFORM THRU range ends before it starts |
| [PLB-C006](#plb-c006-recursive-perform) | recursive-perform | error | Paragraph performs a range that contains itself |
| [PLB-C007](#plb-c007-redefines-larger) | redefines-larger | error | REDEFINES item is larger than the item it redefines |
| [PLB-C008](#plb-c008-move-truncation) | move-truncation | warning | MOVE loses characters or high-order digits |
| [PLB-C009](#plb-c009-undefined-name) | undefined-name | error | Name is not declared |
| [PLB-C010](#plb-c010-ambiguous-name) | ambiguous-name | error | Name refers to more than one data item |
| [PLB-C011](#plb-c011-read-never-set) | read-never-set | warning | Data item is read but never given a value |
| [PLB-C012](#plb-c012-use-before-set) | use-before-set | warning | Data item is read before any path gives it a value |
| [PLB-C013](#plb-c013-call-argument-count) | call-argument-count | warning | CALL passes a different number of arguments than the program takes |
| [PLB-C014](#plb-c014-call-argument-mismatch) | call-argument-mismatch | warning | CALL argument is passed differently or is smaller than its parameter |
| [PLB-C015](#plb-c015-recursive-call) | recursive-call | error | Program that is not RECURSIVE can be called while it is running |
| [PLB-C016](#plb-c016-report-not-initiated) | report-not-initiated | warning | Report is generated or terminated but never initiated |
| [PLB-C017](#plb-c017-report-not-terminated) | report-not-terminated | warning | Report is initiated but never terminated |
| [PLB-C018](#plb-c018-sql-not-checked) | sql-not-checked | warning | Result of an SQL statement is not checked |
| [PLB-C019](#plb-c019-cics-response-not-checked) | cics-response-not-checked | warning | Response of a CICS command is not checked |
| [PLB-C020](#plb-c020-file-status-not-checked) | file-status-not-checked | warning | FILE STATUS is not tested after an I/O statement |
| [PLB-C021](#plb-c021-file-not-opened) | file-not-opened | warning | File is used but never opened |
| [PLB-C022](#plb-c022-open-mode-mismatch) | open-mode-mismatch | error | I/O statement needs an open mode the file is never opened in |
| [PLB-C023](#plb-c023-subscript-out-of-range) | subscript-out-of-range | error | Literal subscript is outside the table |
| [PLB-C024](#plb-c024-refmod-out-of-range) | refmod-out-of-range | error | Literal reference modification is outside the item |
| [PLB-C025](#plb-c025-stop-run-in-called-program) | stop-run-in-called-program | warning | STOP RUN in a program that is called |
| [PLB-C026](#plb-c026-varying-limit-unreachable) | varying-limit-unreachable | warning | PERFORM VARYING waits for a value its counter cannot hold |
| [PLB-C027](#plb-c027-divide-by-zero) | divide-by-zero | error | Divisor is a literal zero |
| [PLB-C028](#plb-c028-comparison-never-true) | comparison-never-true | warning | Data item is compared with a value it cannot hold |
| [PLB-C029](#plb-c029-go-to-leaves-perform) | go-to-leaves-perform | warning | GO TO leaves the range of a PERFORM, which then does not return |
| [PLB-C030](#plb-c030-value-never-used) | value-never-used | warning | Value is replaced before it is used |
| [PLB-C031](#plb-c031-string-overflow) | string-overflow | warning | STRING always sends more than its receiver holds |
| [PLB-J001](#plb-j001-dd-missing) | dd-missing | error | A file the step's programs open has no DD in the step |
| [PLB-J002](#plb-j002-dd-unused) | dd-unused | note | DD is not a file of the step's programs |
| [PLB-J003](#plb-j003-program-not-in-run) | program-not-in-run | note, off | Step runs a program that is not among those checked |
| [PLB-J004](#plb-j004-dd-cannot-be-read) | dd-cannot-be-read | error | A file the program only reads has a DD that gives it no data |
| [PLB-M001](#plb-m001-go-to) | go-to | note | GO TO statement |
| [PLB-M002](#plb-m002-alter) | alter | warning | ALTER statement (obsolete) |
| [PLB-M003](#plb-m003-unused-data-item) | unused-data-item | warning | Data item is never referenced |
| [PLB-M004](#plb-m004-alnum-narrowing) | alnum-narrowing | note, off | MOVE from a larger alphanumeric item to a smaller one |
| [PLB-M005](#plb-m005-set-never-read) | set-never-read | note | Data item is given values but never read |
| [PLB-M006](#plb-m006-dynamic-call) | dynamic-call | note, off | CALL of a program named by a data item |
| [PLB-M007](#plb-m007-detail-never-generated) | detail-never-generated | note | Report detail group is never generated |
| [PLB-M008](#plb-m008-file-not-closed) | file-not-closed | note | File is opened but never closed |
| [PLB-M009](#plb-m009-complex-paragraph) | complex-paragraph | note, off | Paragraph or section is more complex than the limit |
| [PLB-M010](#plb-m010-long-paragraph) | long-paragraph | note, off | Paragraph or section has more statements than the limit |
| [PLB-M011](#plb-m011-evaluate-without-other) | evaluate-without-other | note, off | EVALUATE has no WHEN OTHER |
| [PLB-M012](#plb-m012-deep-nesting) | deep-nesting | note, off | Statements are nested deeper than the limit |
| [PLB-M013](#plb-m013-unused-copybook) | unused-copybook | note | Copybook declares data the program never uses |
| [PLB-M014](#plb-m014-sql-select-star) | sql-select-star | note | Embedded SQL selects every column with SELECT * |
| [PLB-P001](#plb-p001-vendor-routine) | vendor-routine | note, off | CALL of a compiler library routine |
| [PLB-P002](#plb-p002-hard-coded-path) | hard-coded-path | warning | File is assigned to a path on one machine |
| [PLB-S001](#plb-s001-dynamic-sql) | dynamic-sql | note | SQL text is built at run time |
| [PLB-S002](#plb-s002-hard-coded-credential) | hard-coded-credential | warning | Credential is written into the program |
| [PLB-S003](#plb-s003-sensitive-data-displayed) | sensitive-data-displayed | warning | DISPLAY writes a credential or personal data |
| [PLB-S004](#plb-s004-shell-command) | shell-command | note | Shell command is taken from a data item |

Rules marked *off* run only when enabled with `--enable` (or `enable`
in `plumbline.conf`). Rules that measure something have a limit, which
`limit RULE N` in `plumbline.conf` changes.

Categories: **C** correctness, **M** maintainability, **P** portability,
**S** security.

## Suppressing findings

A comment containing `plumbline: ignore` suppresses findings on its own
line, or, when the comment is on a line by itself, on the line after it:

```cobol
    GO TO DONE.                   *> plumbline: ignore go-to
*> plumbline: ignore PLB-C001
OLD-ENTRY-POINT.
    DISPLAY "KEPT FOR REFERENCE".
```

After `ignore`, list rule ids or names separated by spaces or commas.
With none, every rule is suppressed for that line. A reason can follow
after `--`, and it is good practice to give one:

```cobol
*> plumbline: ignore move-truncation -- level numbers are at most 88
    MOVE ND-NUM TO SY-LEVEL
```

Case does not matter.
A suppression names the rules it silences, so the reason for it stays
reviewable.

## PLB-C001 unreachable-code

A paragraph or section that nothing can execute: it is not the program's
entry point, nothing falls into it, and no `PERFORM` or `GO TO` names it.

The analysis follows COBOL's execution model. A `PERFORM` runs its whole
range and then returns, so a paragraph placed after the end of a
performed range is unreachable unless something else falls into it or
jumps to it:

```cobol
MAIN-LINE.
    PERFORM STEP-1 THRU STEP-EXIT
    STOP RUN.
STEP-1.
    ADD 1 TO COUNTER.
STEP-EXIT.
    EXIT.
AFTER-RANGE.                      *> reported: nothing reaches it
    DISPLAY "NEVER".
```

When a whole section is unreachable, only the section is reported, not
each of its paragraphs.

**Why it matters.** Dead code misleads readers and reviewers, hides
logic that was meant to run, and is often left behind by an incomplete
change to a `PERFORM THRU` range or a `GO TO`.

**What to do.** Delete the code if it is obsolete. If it should run, add
the missing `PERFORM`, or check whether a `THRU` range ends too early.

## PLB-C002 perform-and-fall-through

A paragraph that is the target of a `PERFORM` and is also entered by
falling out of the paragraph before it.

```cobol
MAIN-LINE.
    PERFORM CALC
    DISPLAY "CALCULATED".         *> no STOP RUN: falls into CALC
CALC.                             *> reported
    ADD 1 TO TOTAL.
```

When `CALC` is performed it returns at its end. When it is fallen into,
control continues into whatever follows it. Code is rarely right for
both, and the second entry is usually a missing `STOP RUN`, `GOBACK`, or
`EXIT PROGRAM` in the paragraph before.

## PLB-C003 fall-off-end

Control can reach the end of a program's procedure division without
`STOP RUN`, `GOBACK`, or `EXIT PROGRAM`. The compiler then ends the
program implicitly, which readers easily miss. The finding points at the
last statement before the end.

End the main line explicitly.

## PLB-C004 next-sentence-in-scope

`NEXT SENTENCE` continues after the next *period*, not after the
`END-IF` (or other terminator) of the statement it is in:

```cobol
IF A = 1
    NEXT SENTENCE                 *> reported
ELSE
    MOVE 2 TO B
END-IF
DISPLAY "SKIPPED WHEN A = 1"      *> skipped too, up to the period
```

In code that uses scope terminators this is almost never intended. Use
`CONTINUE`, which does nothing and lets control reach the terminator.

## PLB-C005 perform-thru-backwards

`PERFORM A THRU B` where `B` comes before `A` in the source. The range
never reaches `B`, so control runs past the paragraphs the author meant
and returns only if some later `PERFORM` range happens to end where this
one's return point is. Swap the names, or fix the order of the
paragraphs.

## PLB-C006 recursive-perform

A `PERFORM` whose range includes the paragraph or section containing
the `PERFORM`, for example a paragraph that performs itself, or a
paragraph that performs its own section. COBOL `PERFORM` is not
recursive. The standard leaves the behavior undefined, and real
implementations overwrite the return point, so the program loops or
returns to the wrong place.

## PLB-C007 redefines-larger

An item below level 01 that is larger than the item it redefines:

```cobol
05  CODE-NUM        PIC 9(4).
05  CODE-TEXT REDEFINES CODE-NUM PIC X(6).     *> reported: 6 > 4
```

The extra bytes overlay whatever follows the redefined item, so writing
to `CODE-TEXT` silently changes the next field. The standard forbids it;
some compilers accept it with a warning. Sizes come from the symbol
table, so usages and `OCCURS` are taken into account. Level-01 records
may be redefined by larger records and are not reported.

## PLB-C008 move-truncation

A `MOVE` whose receiver cannot hold what is moved:

```cobol
01  SHORT-TEXT          PIC X(5).
01  SMALL-NUM           PIC 9(3).
01  BIG-NUM             PIC S9(7)V99.
    MOVE "TOO LONG FOR IT" TO SHORT-TEXT   *> 15 characters into 5
    MOVE 12345 TO SMALL-NUM                *> 5 integer digits into 3
    MOVE BIG-NUM TO SMALL-NUM              *> 7 integer digits into 3
```

A literal that is too long loses its rightmost characters. A number
with more integer digits than its receiver loses its high-order digits,
which silently changes the value: `MOVE 12345 TO SMALL-NUM` stores 345.
Leading zeros of a literal do not count.

Sizes come from the symbol table. Reference-modified operands, `MOVE
CORRESPONDING`, `ALL` literals, figurative constants, function results,
and `ANY LENGTH` parameters are not checked, because their sizes are not
known statically. Moving a larger alphanumeric item into a smaller one is
the separate, opt-in rule [PLB-M004](#plb-m004-alnum-narrowing).

When a narrowing is safe because of something the program guarantees,
suppress it and say why.

## PLB-C009 undefined-name

A name in the procedure division that is not a data item of the program
(or a `GLOBAL` item of a program containing it), a paragraph or section,
or another declared name: a file, a mnemonic name from `SPECIAL-NAMES`,
an alphabet or class, or an index from `INDEXED BY`. Device names such
as `CONSOLE` and `SYSOUT` are accepted without declaration, as compilers
do.

A qualified reference that matches no item is reported with its
qualifiers, as in `KEY-FIELD OF NO-SUCH-GROUP is not declared`.

Undefined names usually mean a typing mistake or a missing copybook. If
a `COPY` failed (see the `PP001` diagnostic), fix that first.

## PLB-C010 ambiguous-name

A name that matches more than one data item, where the reference does
not say which:

```cobol
01  A-REC.
    05  KEY-FIELD       PIC X(4).
01  B-REC.
    05  KEY-FIELD       PIC X(4).
    MOVE KEY-FIELD TO ...          *> reported
    MOVE KEY-FIELD OF B-REC TO ... *> fine
```

Compilers reject such references. Qualify the name with `IN` or `OF`.

## How data-flow rules see data

PLB-C011, PLB-C012, and PLB-M005 look at what each statement does with
the items it names. An operand is *read* (`MOVE A TO ...`, conditions,
`DISPLAY`), *set* (`MOVE ... TO B`, `ACCEPT`, `READ ... INTO`), or both
(`ADD 1 TO C`, `STRING ... POINTER P`). `plumbline dump refs` shows the
role of every reference. Plumbline does not claim to know what some
operands do, such as `CALL ... USING` items passed by reference, which
the called program may read or set. Such operands count as both. The
operand of `LENGTH OF` counts as neither, because only its size is used.

An access counts for every item whose storage it overlaps. Setting a
group sets its members, setting a member partly sets its group, and
reading a `REDEFINES` view reads the storage it redefines. A condition
name (level 88) stands for its conditional variable.

Only working-storage and local-storage items are checked. Items in the
linkage and file sections get their values from callers and files, and
`EXTERNAL`, `GLOBAL`, and `BASED` items get theirs from other programs
or addresses. A `VALUE` clause gives an initial value, and items named in
the environment division (such as `FILE STATUS` items) may be set by the
runtime.

## PLB-C011 read-never-set

An item that is read, while nothing in the program sets it or any
storage it shares, and it has no `VALUE`:

```cobol
01  TOTAL           PIC 9(5).
    DISPLAY TOTAL                  *> reported: nothing sets TOTAL
```

Its value is whatever the storage happens to hold, which depends on the
compiler and its options.

## PLB-C012 use-before-set

A read that no path through the program reaches with a value in the
item:

```cobol
01  TOTAL           PIC 9(5).
    ADD PRICE TO TOTAL             *> reported: TOTAL has no value yet
    ...
    MOVE 0 TO TOTAL
```

The analysis follows the procedure graph: fall-through, `PERFORM`
(including what the performed range may set), and `GO TO`. It reports a
read only when *every* path to it passes no statement that sets the item.
If any path sets the item first, the read is not reported. Within one
statement, reads come before sets, so `COMPUTE X = X + 1` reads `X`
first. The exception is `PERFORM VARYING`, which sets its variable before
it tests `UNTIL`.

A looping `PERFORM` (`UNTIL`, `VARYING`, `TIMES`, `FOREVER`) repeats its
body, so anything the loop sets counts as possibly set from its start.
This is what makes the usual "remember the previous record" loop
correct, but it also means a read before a set on a loop's first
iteration is not reported. Code after a `PERFORM` whose target
Plumbline cannot resolve, and declaratives, are assumed to have
everything set.

Items that PLB-C011 reports are not reported again here. Programs with
more than 4096 paragraphs and sections, and files with more than 512
items to check, are skipped.

Many compilers fill working storage with spaces or zeros by default, so
such code may happen to work. Give the item a `VALUE` or set it
explicitly, and the program no longer depends on compiler options.

## How call rules see programs

PLB-C013, PLB-C014, and PLB-C015 check each `CALL "NAME"` against the
program it calls. That program has to be in the same run: give
`plumbline check` the calling and the called programs together, in one
file or several. Calls of programs outside the run, such as runtime
library routines, are not checked. `plumbline dump calls` shows how
each call was resolved.

## PLB-C013 call-argument-count

A `CALL` that passes more or fewer arguments than the called program's
`PROCEDURE DIVISION USING` (or `ENTRY ... USING`) has parameters:

```cobol
    CALL "PRICING" USING ORDER-ID        *> reported
    ...
PROGRAM-ID. PRICING.
    PROCEDURE DIVISION USING ORDER-KEY ORDER-AMOUNT.
```

The parameters left without an argument have no storage behind them,
and using one is undefined. Pass `OMITTED` for an argument the program
is written to do without; it counts as an argument.

## PLB-C014 call-argument-mismatch

An argument that does not fit the parameter it is passed to:

- passed `BY VALUE` to a parameter the program takes by reference, or
  `BY REFERENCE` or `BY CONTENT` to one it takes `BY VALUE`;
- passed by reference or content while being smaller than its
  parameter.

```cobol
01  SHORT-ID        PIC X(4).
    CALL "PRICING" USING SHORT-ID ORDER-TOTAL   *> reported
    ...
PROGRAM-ID. PRICING.
    LINKAGE SECTION.
    01  ORDER-KEY       PIC X(8).
```

The called program reads and writes all 8 bytes of `ORDER-KEY`, and 4 of
them belong to whatever follows `SHORT-ID`. Literals count by their
length, so `CALL "PRICING" USING "A12" ...` is reported too. A larger
argument is not reported, because programs often pass a record to a
routine that uses only its start. Sizes Plumbline does not know, such
as `ANY LENGTH` parameters and reference-modified arguments, are not
compared.

## PLB-C015 recursive-call

A program that can be called while it is still running, through a chain
of calls that leads back to it, and that is not declared `RECURSIVE`:

```cobol
PROGRAM-ID. PRICING.
    CALL "DISCOUNT" USING ...
PROGRAM-ID. DISCOUNT.
    CALL "PRICING" USING ...    *> reported: PRICING -> DISCOUNT -> PRICING
```

COBOL programs are not reentrant unless they are declared `RECURSIVE`,
and calling an active program is undefined. Many runtimes stop with an
error at that point. The finding shows the chain and is reported at the
call that closes it. Declare the program `PROGRAM-ID. NAME IS RECURSIVE`
if the recursion is intended.

## How report rules see reports

A Report Writer report (an `RD` entry) is produced by `INITIATE`, then
`GENERATE` of its detail groups (or of the report itself, for summary
reporting), and ends with `TERMINATE`. PLB-C016, PLB-C017, and PLB-M007
look at which reports and groups these statements name anywhere in the
program. They do not follow the flow of control, so a report initiated
on one path and generated on another is not reported.

## PLB-C016 report-not-initiated

A `GENERATE` or `TERMINATE` of a report that no `INITIATE` in the
program starts:

```cobol
RD  MONTHLY-REPORT.
01  MONTH-LINE TYPE DETAIL ...
    GENERATE MONTH-LINE          *> reported: no INITIATE MONTHLY-REPORT
```

Generating or terminating a report that was not initiated is a run-time
error.

## PLB-C017 report-not-terminated

A report that is initiated but that no `TERMINATE` ends:

```cobol
RD  DAILY-REPORT.                *> reported
    INITIATE DAILY-REPORT
    GENERATE ITEM-LINE
    CLOSE PRINT-FILE
```

`TERMINATE` prints the final control footings and report footing, so
without it the last totals are missing from the report.

## How embedded SQL and CICS are read

Inside `EXEC SQL ... END-EXEC`, the host variables (`:NAME`, and
`:RECORD.FIELD` for a field of a record) are references to COBOL data.
`INTO` sets them, as in `SELECT ... INTO` and `FETCH ... INTO`, and so
does `SET :x = ...`. Everywhere else they are read. Inside `EXEC CICS`,
the arguments of options are references. Options that return data set
their argument (`INTO`, `SET`, `RESP`, `RESP2`), options that pass data
read it (`FROM`, `RIDFLD`), and `LENGTH` and `ITEM` do both. Every
option of `ASSIGN`, `INQUIRE`, and `FORMATTIME` returns a value.

`EXEC SQL INCLUDE member` includes the member like `COPY`. The SQLCA
fields (`SQLCODE`, `SQLSTATE`, ...) and the CICS EIB fields (`EIBCALEN`,
`EIBRESP`, ...) are known names. `EXEC CICS RETURN`, `XCTL`, and `ABEND`
end a paragraph like `GOBACK`. The procedures of `EXEC SQL WHENEVER ...
GO TO` and `PERFORM` count as jumped to or performed.

## PLB-C018 sql-not-checked

An SQL statement whose result nothing tests:

```cobol
    EXEC SQL SELECT NAME INTO :CUST-NAME FROM CUSTOMER
             WHERE ID = :CUST-ID END-EXEC          *> reported
    EXEC SQL UPDATE CUSTOMER SET SEEN = 'Y' ... END-EXEC
```

A statement counts as checked when a statement after it in the same
paragraph names `SQLCODE` or `SQLSTATE` before the next SQL statement,
or a paragraph performed from there does, or `WHENEVER SQLERROR` with an
action other than `CONTINUE` is in force. A check that is only reached
by falling into the next paragraph is not seen. `SELECT`, `INSERT`,
`UPDATE`, `DELETE`, `FETCH`, `OPEN`, `PREPARE`, `EXECUTE`, `CALL`,
`MERGE`, and `CONNECT` are checked. `CLOSE`, `COMMIT`, and `ROLLBACK`
are not.

An unchecked `FETCH` loops forever at the end of the data, and an
unchecked `UPDATE` fails silently.

## PLB-C019 cics-response-not-checked

A CICS command whose response is not tested:

```cobol
    EXEC CICS WRITE FILE('LOG') FROM(REC) RIDFLD(KEY)
         RESP(WS-RESP) END-EXEC                   *> reported if WS-RESP
    EXEC CICS RETURN END-EXEC                     *> is not tested first
    EXEC CICS DELETE FILE('TEMP') RIDFLD(KEY) NOHANDLE END-EXEC
                                                  *> reported
```

With `RESP(item)`, the item has to be tested (or `EIBRESP`, or a
paragraph performed in between has to test it) before the next CICS
command. `NOHANDLE` without `RESP` discards errors altogether. A command
with neither abends on an error, which is CICS's safe default, and is
not reported.

## How file rules see files

PLB-C020, PLB-C021, PLB-C022, and PLB-M008 look at each program's files
(`SELECT`), their records (`FD`), and the I/O statements that name them:
`OPEN` and `CLOSE`, `READ`, `START`, and `DELETE` of a file, and `WRITE`
and `REWRITE` of one of its records. A file's open modes are those of
every `OPEN` in the program that names it. The rules do not follow the
flow of control. An `EXTERNAL` file is shared with other programs, so
only PLB-C020 applies to it.

## PLB-C020 file-status-not-checked

An I/O statement on a file that has a `FILE STATUS` item, where nothing
tests the item afterwards:

```cobol
    OPEN OUTPUT REPORT-FILE                  *> reported
    WRITE REPORT-LINE FROM HEADING
```

A statement counts as checked when its own `AT END` or `INVALID KEY`
phrase handles errors, when a `USE AFTER ERROR PROCEDURE` declarative
covers the file (by name or by its open mode), or when the status item
or one of its condition names (level 88) is named after it. That can be
in the same paragraph before the next statement on the file, or in a
paragraph performed from there. `CLOSE` is not checked.

After a failed `OPEN`, every later statement on the file fails too, and
after a failed `WRITE` the record is simply not there.

## PLB-C021 file-not-opened

An I/O statement on a file that no `OPEN` in the program opens:

```cobol
    WRITE AUDIT-LINE FROM CUST-NAME          *> reported
```

The statement fails at run time with status 48 or 49 (or 47 for a
`READ`).

## PLB-C022 open-mode-mismatch

An I/O statement that none of the file's open modes allows:

```cobol
    OPEN INPUT CUST-FILE
    ...
    REWRITE CUST-REC                         *> reported: needs I-O
```

`READ` and `START` need `INPUT` or `I-O`, `WRITE` needs `OUTPUT`,
`EXTEND`, or `I-O`, and `REWRITE` and `DELETE` need `I-O`.

## PLB-C023 subscript-out-of-range

A subscript written as a number that is below 1 or past the table's
OCCURS:

```cobol
01  MONTH-TABLE.
    05  MONTH-NAME  PIC X(9) OCCURS 12 TIMES.
    ...
    MOVE "SMARCH" TO MONTH-NAME (13)                *> reported
    MOVE "NONE" TO MONTH-NAME (0)                   *> reported
    MOVE MONTH-NAME (I + 12) TO OUT-TEXT            *> not checked
```

At run time such a subscript reads or overwrites whatever follows the
table, unless the program was compiled with subscript checking. Each
dimension of a table inside a table is checked against its own OCCURS:
for `GRID-CELL (2, 5)` in a 3 by 4 grid, the 5 is reported. With
`OCCURS ... DEPENDING ON`, the subscript is checked against the maximum.
Only literal subscripts are checked, and only when there is one per
dimension.

## PLB-C024 refmod-out-of-range

A reference modification written with numbers that reaches outside the
item:

```cobol
01  CODE-TEXT  PIC X(8).
    ...
    MOVE CODE-TEXT (5:6) TO OUT-TEXT                *> ends at 10: reported
    MOVE CODE-TEXT (9:) TO OUT-TEXT                 *> starts past the end
    MOVE CODE-TEXT (0:2) TO OUT-TEXT                *> starts at 0
    MOVE CODE-TEXT (I:9) TO OUT-TEXT                *> 9 is too long anywhere
```

Positions count characters, from 1. Items whose characters are not
bytes (national, boolean), numeric items that are not `DISPLAY`, and
tables whose size depends on `OCCURS ... DEPENDING ON` are not checked.

## PLB-C025 stop-run-in-called-program

`STOP RUN` in a program that another program of the run calls, or in a
nested program:

```cobol
PROGRAM-ID. PAYSTEP.                    *> MAIN-RUN calls PAYSTEP
PROCEDURE DIVISION.
    ...
    STOP RUN.                           *> reported
```

`STOP RUN` ends the run unit: the program, its callers, and everything
else that is running. A called program usually means to return to its
caller, which `GOBACK` (or `EXIT PROGRAM`) does. A nested program only
runs when it is called, so it is always checked.

Whether a program is called is taken from the call graph, so the rule
needs the callers in the same run. That keeps it quiet on a main
program that has `PROCEDURE DIVISION USING` to receive a JCL `PARM`:
nothing calls it. Calls through a data item (`CALL WS-NAME`) do not
count.

## PLB-C026 varying-limit-unreachable

A `PERFORM VARYING` whose `UNTIL` condition waits for a value the
counter cannot hold:

```cobol
01  I  PIC 99.
    ...
    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 99      *> reported
        MOVE "A" TO CELL (I)
    END-PERFORM
```

`I` goes from 99 to 00 when it is increased, so it is never greater
than 99, and the loop goes on until something else ends it: a `GO TO`
out of it, `EXIT PERFORM`, or an abend when `CELL (0)` is stored. Give
the counter one more digit, or stop at the last value it holds
(`UNTIL I = 99` with `TEST AFTER`).

The rule checks `UNTIL counter op literal`, with op one of `>`, `>=`,
`=`, `<`, `<=` or their words, on the counter that `VARYING` names:
`UNTIL I < 0` is reported for an unsigned counter too. Only integer
counters stored as decimal digits (`DISPLAY` or `PACKED-DECIMAL`) are
checked. A binary counter can hold more than its picture says when the
compiler does not truncate binary data (IBM `TRUNC(BIN)`, GnuCOBOL
`-fnotrunc`). Conditions with `AND` or `OR` are not checked.

## PLB-C027 divide-by-zero

A division whose divisor is a literal zero:

```cobol
    DIVIDE ZERO INTO TOTAL                  *> reported
    COMPUTE RESULT = TOTAL / 0.00           *> reported
    DIVIDE 0 BY TOTAL GIVING RESULT         *> not reported: 0 is divided
```

Dividing by zero raises the size error condition. Without an `ON SIZE
ERROR` phrase the receiving item is left unchanged, or the program
stops, depending on the compiler and its options, and nothing says
which happened. Such a division is usually a placeholder that was
never filled in, or a constant that was meant to be a data item.

The rule checks the first operand of `DIVIDE ... INTO`, the operand
after `BY` in `DIVIDE ... BY`, and the operand after `/` in any
expression (`COMPUTE`, conditions, subscripts). A divisor is zero when
it is `ZERO`, `ZEROS`, `ZEROES`, or a numeric literal with only zero
digits. A statement with `ON SIZE ERROR` handles the failure and is not
reported; test programs divide by zero this way on purpose. Divisors
that are data items, or constants declared with level 78 or
`CONSTANT`, are not checked.

## PLB-C028 comparison-never-true

A condition that compares a data item with a literal the item cannot
hold, so the comparison is never true:

```cobol
01  AGE      PIC 99.
01  BALANCE  PIC 9(5).
    ...
    IF AGE > 99                             *> reported
    IF BALANCE < 0                          *> reported: BALANCE has no sign
```

The code under such a condition never runs. Often the item was made
smaller, or lost its sign, after the condition was written, and the
check it was meant to make no longer happens.

The rule checks `item op literal` in the conditions of `IF`, `PERFORM
... UNTIL`, and `WHEN` in `EVALUATE` and `SEARCH`, with op one of `>`,
`>=`, `=`, `<`, `<=` or their words. Like
[PLB-C026](#plb-c026-varying-limit-unreachable), it checks integer items
stored as decimal digits (`DISPLAY` or `PACKED-DECIMAL`), and integer
literals. Table elements are checked through their subscripts. It does
not report:

- comparisons with `NOT`, and comparisons that are always true
  (`IF BALANCE >= 0`), which are usually harmless checks;
- an item that is an operand of arithmetic (`IF AGE + 1 > 99`);
- the counter of `PERFORM VARYING`, which PLB-C026 checks;
- a literal on the left (`IF 99 < AGE`), or an abbreviated condition
  without a subject (`IF AGE > 10 AND < 100` checks the first part).

A numeric item that holds invalid data (spaces, after a `MOVE` to its
group) still never compares greater than its picture allows.

## PLB-C029 go-to-leaves-perform

A `GO TO` inside a performed range whose target is outside it:

```cobol
    PERFORM COUNT-RECORD
    ...
COUNT-RECORD.
    ADD 1 TO COUNTER
    IF COUNTER > 100
        GO TO SUMMARY                       *> reported
    END-IF.
```

A `PERFORM` returns when control reaches the end of its range. After
this `GO TO` it never does: control runs on from `SUMMARY`, and the
statement after the `PERFORM` is skipped. When the range is performed
again later, its return point may still be set from the first time,
so some compilers then return to the wrong place.

The range is the performed paragraph or section, or `A THRU B`, and
the procedures of `SORT` and `MERGE` count as ranges too. A `GO TO` to
a paragraph inside the range (`GO TO READ-EXIT`) is fine. So is a
`GO TO` to code that ends the run, directly or by falling through
other paragraphs into `STOP RUN`, `GOBACK`, `EXIT PROGRAM`, or the end
of the program: that is how many programs leave on an error. A target
that itself ends with a `GO TO` is reported, even when that `GO TO`
leads to the end of the run. Each `GO TO` is reported once, for the
first `PERFORM` whose range it leaves.

## PLB-C030 value-never-used

A value given to a data item that a later statement of the same
paragraph replaces before anything reads it:

```cobol
    MOVE FUNCTION CURRENT-DATE TO WS-CURDATE-DATA     *> reported
    MOVE CCDA-TITLE01 TO TITLE01O
    MOVE FUNCTION CURRENT-DATE TO WS-CURDATE-DATA
```

The first value is never used. Often the statements were copied and
one of them should name another item; sometimes one is simply left
over.

The rule starts at a `MOVE` or `COMPUTE` and follows the statements
after it, across sentences, to the end of the paragraph. It stops,
keeping the value, at:

- a statement that reads the item, or any storage it shares: the
  groups it is in, its members, and items that redefine them;
- a statement that could read it out of sight or change where control
  goes: `PERFORM`, `CALL`, `GO TO`, I/O, `IF`, `EVALUATE`, and any
  statement with a phrase such as `ON SIZE ERROR`.

The value is reported when a `MOVE` or `COMPUTE` gives the whole item a
new value. `STRING`, `MOVE CORRESPONDING`, and stores to part of the
item do not replace it. Not followed at all:

- clearing an item before filling it: `MOVE SPACES`, `MOVE ZERO`,
  `MOVE LOW-VALUES`, `COMPUTE X = 0`, `INITIALIZE`;
- table elements, condition names, and items named by `DEPENDING ON`,
  which the table or item that depends on them reads;
- programs with `USE FOR DEBUGGING`, whose declaratives run on
  references that the statements do not show.

## PLB-C031 string-overflow

A `STRING` whose operands delimited by size are longer, together,
than the item they go into:

```cobol
05  WS-RETURN-MSG  PIC X(75).
    ...
    STRING 'Account:' WS-CARD-RID-ACCT-ID-X ' not found in'
           ' Cross ref file.  Resp:' ERROR-RESP ' Reas:' ERROR-RESP2
           DELIMITED BY SIZE
        INTO WS-RETURN-MSG                  *> 81 characters: reported
```

An operand `DELIMITED BY SIZE` is sent whole, so this statement always
overflows. `STRING` stops at the end of the receiver, and without `ON
OVERFLOW` nothing tells that the end of the text was lost (here, most
of the reason code).

The rule adds up the operands delimited by size: data items by their
size, literals by their length, figurative constants as one
character. Operands delimited by anything else may send any part of
themselves and are not counted; neither are operands whose size the
source does not show (reference modification, functions, literals
with a prefix such as `X` or `N`). The sum is the least the statement
sends. A `STRING` with `ON OVERFLOW` handles the case and is not
reported, nor is a receiver with reference modification, of variable
size, or of national usage.

## PLB-J001 dd-missing

The J rules check programs against the JCL that runs them, when a run
has both: JCL files are those named `*.jcl` or `*.prc` (see
[JCL](jcl.md)).

A step that runs a program of the run, where the program, or a program
it calls by literal name, opens a file whose DD the step does not have:

```
//RERUN    EXEC PGM=PAYUPD
//PAYMAST  DD DSN=PAY.MASTER,DISP=SHR
//PAYRPT   DD SYSOUT=*
```

Here PAYUPD calls PAYLOG, which opens `LOG-FILE ASSIGN TO PAYLOG`, and
the step has no `PAYLOG` DD. The `OPEN` fails when the step runs (file status 35 for input, or an
abend). The DD name is that of the file's `ASSIGN TO`, or its last part
for an IBM assignment name such as `UT-S-PAYLOG`. Files that are
`OPTIONAL`, sort files (`SD`), files no `OPEN` names, and files assigned
to a data item or a path are not checked. A step in a procedure also
has the DDs that job steps running the procedure add as `STEP.DDNAME`;
with no such job step in the run, the procedure's own DDs must do.

## PLB-J002 dd-unused

A DD of a step that no file of the step's programs is assigned to:

```
//RERUN    EXEC PGM=PAYUPD
//OLDFILE  DD DSN=PAY.OLD,DISP=SHR
```

when neither PAYUPD nor the programs it calls assign a file to
`OLDFILE`.

Such a DD is often left over from an earlier version of the program,
and allocating it can hold a data set for nothing; or the program was
meant to read it under that name. DDs the system and the runtime read
count as used: `STEPLIB`, `JOBLIB`, names starting with `SYS`, `CEE`,
or `SORT`, and the path of an alternate index (the file's DD name with a
digit at its end, `PAYMAST1` for `PAYMAST`). A step whose programs
assign a file to a name known only at run time is not checked.

## PLB-J003 program-not-in-run

*Off by default.* A step that runs a program the run does not have.
Most jobs also run utilities (`IDCAMS`, `SORT`, `IEBGENER`), so the rule
is for runs meant to hold every program of the jobs, to find a step
whose program is missing or misspelled. Steps running programs that
start others (`IKJEFT01` for DB2, `DFSRRC00` for IMS) are not
followed, since the program they run is named in their input.

## PLB-J004 dd-cannot-be-read

A file that the step's programs only open for input, whose DD gives it
nothing to read:

```
//NEWRATE  EXEC PGM=PAYUPD
//RATES    DD DSN=PAY.RATES,DISP=(NEW,CATLG)
```

`DISP=NEW` creates the data set in the step, so it is empty when the
program reads it: the first `READ` is at end. A `SYSOUT` DD is output
for the spool and cannot be read at all. `DD DUMMY`, which reads as an
empty file, is left alone: it is how a job leaves out an input on
purpose. Files that a program also opens for output, `I-O`, or `EXTEND`
are not checked.

## PLB-M001 go-to

Every `GO TO` statement, reported as a note. `GO TO` makes the flow of
control hard to follow, and structured statements (`PERFORM`, `EVALUATE`,
inline `PERFORM ... END-PERFORM`) usually say the same thing more
clearly. Notes do not fail a run unless `--fail-on note` is given.
Disable the rule with `--disable go-to` in code bases that use `GO TO`
by convention (for example `GO TO xxx-EXIT`).

## PLB-M002 alter

`ALTER` changes the target of a `GO TO` while the program runs, so the
source no longer says where control goes. It was declared obsolete and
then removed from the standard in 2002. Replace the altered `GO TO` with
a flag and an `EVALUATE` or `IF`.

## PLB-M003 unused-data-item

A working-storage or local-storage item that the program never refers
to. Unused items are clutter at best. At worst they are a sign that code
meant to use them was lost.

An item counts as used when:

- its name, or the name of one of its condition names (level 88), appears
  in the procedure division;
- it is the object of an `OCCURS ... DEPENDING ON`;
- one of its members is used (for a group), or the group it belongs to is
  used by name (for a member);
- an item that `REDEFINES` it is used. This is the common idiom of a table
  of `VALUE` clauses read through a redefinition.

Only the outermost unused item is reported: an unused group is one
finding, not one per member. Items declared in copybooks are not
reported, because programs commonly use part of a shared layout. Neither
are `GLOBAL` or `EXTERNAL` items, which other programs may use, nor
linkage items, constants (level 78), and `RENAMES` (level 66).

References are matched by name within the program, so an item is treated
as used if any item of the same name is referenced.

## PLB-M004 alnum-narrowing

*Off by default; enable with `--enable alnum-narrowing`.*

A `MOVE` from an alphanumeric, edited, or group item into a smaller
alphanumeric or group item. The rightmost characters are lost. This is
often intended, for example when moving a field out of a large input
buffer, so the rule reports notes and does not run unless asked. Turn it
on when reviewing record layouts or when a truncation bug is suspected.

## PLB-M005 set-never-read

An item that the program gives values to but never reads, nor reads any
storage it shares:

```cobol
01  WORK-TOTAL      PIC 9(7).
    MOVE AMOUNT TO WORK-TOTAL      *> reported: nothing reads WORK-TOTAL
```

Usually the item is left over from earlier code, or the read that should
use it is reading something else. The rule is a note by default.

## PLB-M006 dynamic-call

A `CALL` of the program named in a data item:

```cobol
    CALL ROUTINE-NAME USING ORDER-ID       *> reported when enabled
```

Plumbline cannot tell which program such a call reaches, so the call
rules do not check it. Enable this rule to list the calls that are left
unchecked.

## PLB-M007 detail-never-generated

A detail group (`TYPE DETAIL`) with a name that no `GENERATE` names, in
a report that is never generated as a whole:

```cobol
01  ERROR-LINE TYPE DE LINE PLUS 1.   *> reported
```

The group is either left over or meant to be generated somewhere it is
not. Groups without names cannot be generated on their own and are not
reported.

## PLB-M008 file-not-closed

A file that the program opens but never closes:

```cobol
    SELECT LOG-FILE ASSIGN TO "LOG"          *> reported
    ...
    OPEN EXTEND LOG-FILE
```

Most runtimes close files when the run ends, but the last records of an
unclosed output file can be lost when a program is called rather than
run, and the file stays locked for others.

## PLB-M009 complex-paragraph

A paragraph or section whose complexity, as `plumbline metrics` reports
it, is above the limit (15 by default):

```
paragraph CHECK-CLAIM has complexity 23 (limit 15)
```

Complexity counts the paths through the code. The more there are, the
harder the paragraph is to test and change. Splitting it into
paragraphs that each make one decision usually helps. The rule is off
by default. A paragraph that dispatches through one long `EVALUATE` is
complex by this count but easy to read, so where the limit lies is a
choice each team makes.

## PLB-M010 long-paragraph

A paragraph or section with more statements than the limit (50 by
default):

```
paragraph PRINT-SUMMARY has 87 statements (limit 50)
```

Off by default, like PLB-M009.

## PLB-M011 evaluate-without-other

*Off by default.* An `EVALUATE` without `WHEN OTHER`:

```cobol
    EVALUATE STATUS-CODE                *> noted
        WHEN 1 DISPLAY "OPEN"
        WHEN 2 DISPLAY "CLOSED"
    END-EVALUATE
```

A value that no `WHEN` matches does nothing, silently. Often that is
what was meant, so the rule is for teams whose convention is that
every `EVALUATE` says what happens to the other values, if only
`WHEN OTHER CONTINUE`.

## PLB-M012 deep-nesting

*Off by default.* A statement whose body nests statements deeper than
the limit (5 by default):

```
IF nests statements 6 levels deep (limit 5)
```

A statement inside an `IF` inside another `IF` is at level 2. Every
statement with a body counts: `IF`, `EVALUATE`, `SEARCH`, inline
`PERFORM`, and the phrases of `READ ... AT END` or `ADD ... ON SIZE
ERROR`. The finding is at the outermost statement of the paragraph,
once, however many statements inside it go too deep. Moving the inner
levels into a paragraph of their own, or testing the exceptional cases
first and leaving, usually flattens the code. Like the size limits,
where the limit lies is a team's choice: `limit deep-nesting N` in
`plumbline.conf` changes it.

## PLB-M013 unused-copybook

A `COPY` in working-storage or local-storage whose copybook declares
data items, none of which the program uses:

```
none of the items copybook cvcus01y.cpy declares is used
```

The finding is at the `COPY` statement, so it can be suppressed there
for one program while the copybook stays in use elsewhere. Items count
as used as for [PLB-M003](#plb-m003-unused-data-item): by name in the
procedure division or the environment division, through a member, a
group, a condition name, or a `REDEFINES`. A constant (level 78) also
counts as used when the data division sizes an item with it (`OCCURS
ADDRESS-LINES`, `PIC X(NAME-LEN)`).

A copybook that only copies other copybooks is judged by them. One
that holds anything else is not reported: file or linkage entries,
`GLOBAL` or `EXTERNAL` items, or code.

## PLB-M014 sql-select-star

`SELECT *` in embedded SQL, in a statement, in a `DECLARE CURSOR` (also
one in working-storage), or in `INSERT ... SELECT`:

```cobol
    EXEC SQL DECLARE ALL-EMP CURSOR FOR
        SELECT * FROM EMPLOYEE              *> noted
    END-EXEC.
```

The host variables of `INTO` or `FETCH` must match the table's columns
one for one, in order. With `SELECT *` they do so only until a column
is added, and nothing in the program says which columns it reads.
Name the columns. `COUNT(*)` is not reported.

## PLB-P001 vendor-routine

*Off by default.* A CALL of a library routine that comes with some
compilers and not others:

```cobol
    CALL "CBL_DELETE_FILE" USING ITEM-PATH          *> noted
    CALL "C$SLEEP" USING 1                          *> noted
```

Routines named `CBL_...` come from Micro Focus COBOL, `C$...` from
ACUCOBOL; GnuCOBOL provides many of both, IBM Enterprise COBOL few.
`SYSTEM` is noted too. Programs built with one compiler call its library
on purpose, so the rule only runs on request, for code meant to move.
Where such calls are needed, keep them in a few small programs that a
port can replace.

## PLB-P002 hard-coded-path

A file assigned to a path, written into the SELECT or into the VALUE of
the item it is assigned to:

```cobol
    SELECT IN-FILE ASSIGN TO "/var/data/in.dat".    *> reported
    SELECT OUT-FILE ASSIGN TO "C:\DATA\OUT.DAT".      *> reported
    SELECT WORK-FILE ASSIGN TO DYNAMIC WORK-PATH.   *> reported when
01  WORK-PATH  PIC X(40) VALUE "../tmp/work.dat".   *> the VALUE is a path
    SELECT DD-FILE ASSIGN TO "INFILE".              *> fine
```

A path names a place on one machine, in its operating system's syntax.
A bare name is resolved when the program runs, by a DD statement on
z/OS or an environment variable (`DD_INFILE`, `dd_INFILE`, `INFILE`)
with GnuCOBOL, so the same program reads a different file in test and
in production. Text with a `/` or `\`, or that starts with a drive letter
(`C:`), is a path. A path the program builds at run time is not seen.

## PLB-S001 dynamic-sql

SQL text that the program builds at run time and hands to the database:

```cobol
    EXEC SQL PREPARE STMT FROM :SQL-TEXT END-EXEC       *> noted
    EXEC SQL EXECUTE IMMEDIATE :SQL-TEXT END-EXEC       *> noted
```

If outside input (a screen, a file, a message) reaches the text without
being checked, it can change what the statement does: SQL injection.
Static SQL with host variables keeps data and statement apart. Use it
where possible, and check the text where not.

## Names that mark sensitive data

PLB-S002 and PLB-S003 cannot see what an item holds, so they go by its
name. A name is split at its hyphens, and whole parts are compared:

- **credentials**: PASSWORD, PASSWD, PWD, PASSPHRASE, PASSCODE, SECRET,
  APIKEY, CREDENTIAL, CREDENTIALS;
- **personal data**: PIN, SSN, CVV, CVC, CVV2, TAXID.

`CUSTOMER-PIN` is personal data. `SPINDLE-ID` and `PINNED-FLAG` are
not: PIN is only part of a part. A name with a part that describes the
data rather than holding it (LEN, LENGTH, SIZE, COUNT, CNT, CTR, RETRY,
RETRIES, TRIES, ATTEMPTS, FLAG, SW, SWITCH, IND, STATUS, DATE, EXPIRY,
EXPIRES, MIN, MAX, RULES, POLICY, PROMPT, MSG, MESSAGE, LABEL, TEXT,
FIELD, COL, ROW, POS) is not sensitive, so `PASSWORD-LENGTH` and
`PIN-RETRY-COUNT` are left alone. Condition names (level 88) never are.

## PLB-S002 hard-coded-credential

A credential given its value by the program itself, in a VALUE clause
or a MOVE of a literal:

```cobol
01  DB-PASSWORD         PIC X(16) VALUE "tiger".   *> reported
    MOVE "s3cr3t" TO API-SECRET                    *> reported
    MOVE SPACES TO DB-PASSWORD                     *> fine: clears it
```

Anyone who can read the source, the load module, or a listing can read
the credential, and changing it means a new build. Read it at run time
from a protected file, a vault, or the job's environment. Blank values
(SPACES, `""`, `" "`) are not reported: they clear an item rather than
set a secret.

## PLB-S003 sensitive-data-displayed

DISPLAY of an item whose name marks it as a credential or as personal
data:

```cobol
    DISPLAY "LOGIN " USER-NAME " " DB-PASSWORD     *> reported
    DISPLAY CUSTOMER-PIN                           *> reported
```

DISPLAY output usually ends up in a job log or a console log, which is
kept, copied, and read by far more people than the data was meant for.
Leave the item out, or show a masked form.

## PLB-S004 shell-command

A command run through the operating system that comes from a data item
rather than a literal:

```cobol
    CALL "SYSTEM" USING "ls -l"                    *> fine: a literal
    CALL "SYSTEM" USING BY CONTENT SHELL-LINE      *> noted
```

The routines checked are SYSTEM, C$SYSTEM, C$RUN, CBL_OS_COMMAND, and
CBL_EXEC_RUN_UNIT. When outside input goes into the command text
unchecked, it can add commands of its own: command injection. Build the
command from known parts, and check or quote anything that comes from
outside. The rule cannot tell whether that happened, so it only notes
the call.
