# Running Plumbline on AWS CardDemo

The [NIST suite](corpus.md) and [GnuCOBOL's tests](corpus-gnucobol.md)
are programs written to exercise compilers. CardDemo is written like an
application: a credit card system that Amazon Web Services publishes,
under the Apache License 2.0, to demonstrate mainframe migration. It
has online programs (CICS, BMS maps, VSAM files), batch programs, and
extensions that use DB2, IMS DL/I, and IBM MQ: 44 programs and 30,000
lines of IBM Enterprise COBOL, with their copybooks.

`make corpus-carddemo` downloads a fixed commit
(`59cc6c2fd7ebd7ef7925cad552a01a4b8b6e4d5e`) from GitHub, checks it
against a known SHA-256, and checks all programs in one run, with every
directory of copybooks and DB2 declarations on the copy path, together
with the application's 48 JCL members and procedures, its 21 BMS map
sources, its 4 files of CICS resource definitions, and the 8 DBDs and
PSBs of its IMS extension. None of
CardDemo is added to this repository.

## Results

The run on 2026-10-01 takes about a second:

| | |
|---|---|
| Programs | 44 (30,175 lines, without copybooks) |
| JCL members and procedures | 48 |
| BMS map sources | 21 |
| CICS resource definition files | 4 |
| IMS DBDs and PSBs | 8 |
| Programs with input errors | 24, all for copybooks of CICS and MQ |

The copybooks it cannot find are those that come with the products, not
with the application: `DFHAID` and `DFHBMSCA` (CICS), and `CMQV`,
`CMQODV`, and the other MQ definitions. Every undefined name left
(PLB-C009) is one of the MQ names, each reported once in each of the
three MQ programs; the CICS names, which all start with `DFH`, are
known in a program that uses `EXEC CICS`.

| Rule | Findings |
|------|---------:|
| PLB-M003 unused-data-item | 201 |
| PLB-M001 go-to | 200 |
| PLB-C009 undefined-name | 100 |
| PLB-C008 move-truncation | 119 |
| PLB-M005 set-never-read | 72 |
| PLB-C019 cics-response-not-checked | 42 |
| PLB-C001 unreachable-code | 33 |
| PLB-B001 map-fields-overlap | 16 |
| PLB-M013 unused-copybook | 30 |
| PLB-C002 perform-and-fall-through | 23 |
| PLB-C020 file-status-not-checked | 10 |
| PLB-C031 string-overflow | 9 |
| PLB-C030 value-never-used | 7 |
| PLB-M002 alter | 4 |
| PLB-M008 file-not-closed | 3 |
| PLB-C007 redefines-larger | 3 |
| PLB-C014 call-argument-mismatch | 2 |
| PLB-C011 read-never-set | 1 |
| PLB-C004 next-sentence-in-scope | 1 |
| PLB-C003 fall-off-end | 1 |
| PLB-C033 self-move | 2 |
| PLB-C032 duplicate-when | 2 |
| PLB-J001 dd-missing | 1 |
| PLB-A001 unused-program | 1 |

Some findings that were read and are true:

- **PLB-C007**: `CDEMO-ADMIN-OPTIONS` redefines six options of 45 bytes
  as a table of nine, and `JOB-DATA-2` redefines 17 lines of JCL as a
  table of 1,000; a subscript past the data reads whatever follows.
- **PLB-C014**: the date routine `CSUTLDTC` takes 10-byte parameters,
  and the copybook that calls it passes 8-byte items.
- **PLB-C001**: `1230-EDIT-ALPHANUM-REQD` in COACTUPC is performed by
  nothing, and several `9999-EXIT` paragraphs follow a paragraph that
  ends in `GOBACK` and is performed without `THRU`.

## What the run found in Plumbline

- **Partial-word replacement.** CardDemo's copybook `CSSETATY` is
  written for `COPY CSSETATY REPLACING ==(TESTVAR1)== BY
  ==ACCT-STATUS==`, which IBM Enterprise COBOL applies inside words
  such as `FLG-(TESTVAR1)-NOT-OK`. Plumbline supported only `:TAG:`.
- **`EXEC DLI`.** Its options name COBOL data like those of `EXEC
  CICS`, except the segment of `SEGMENT(...)` and the segment fields
  compared in `WHERE(...)`; the DL/I interface block (`DIBSTAT`) is
  declared by the IMS translator.
- **DB2 declarations** are kept as `.dcl` files, which `EXEC SQL
  INCLUDE` now finds.
- **Tabs.** Three files use tabs with stops every 4 columns; at the
  usual 8, a copybook's entries ran past column 72. The run uses
  `--tab-width 4`, which this led to.
- **`GO TO xxx-EXIT`.** CardDemo performs most paragraphs with `THRU`
  their exit paragraph and leaves them with `GO TO xxx-EXIT`. The flow
  analysis took such a GO TO's target as entered by falling, so the exit
  paragraph fell into the next paragraph, and perform-and-fall-through
  reported 147 paragraphs. A GO TO in a paragraph reached only by
  `PERFORM` now stays within that PERFORM; 23 findings are left.

## Findings worth a look

- **PLB-C030 value-never-used.** Seven online programs move
  `FUNCTION CURRENT-DATE` to `WS-CURDATE-DATA` twice in the routine that
  fills the screen header, a few lines apart, with no use in between.
  The first move is left over; the routine was copied from program to
  program with it.
- **PLB-M013 unused-copybook.** 30 `COPY` statements bring in record
  layouts that their program never uses: message and user layouts in
  the online programs (`CSMSG01Y`, `CSUSR01Y`), and file records in
  batch programs that do not read those files (`CVCUS01Y` in
  `CBTRN01C`).
- **PLB-C031 string-overflow.** Nine error messages are built with
  `STRING ... DELIMITED BY SIZE` from more text than their receiver
  holds: in `COACTUPC` and `COACTVWC`, 81 characters go into the
  75-character `WS-RETURN-MSG`, and the end of the CICS reason code is
  cut off.
- **PLB-J001 dd-missing.** The job `CBIMPORT` runs the program of that
  name, which opens seven files for its import; the step has DDs for
  six. `CARD-OUTPUT ASSIGN TO CARDOUT` has none, so the step fails when
  `CBIMPORT` opens it. Every other batch step has a DD for each file its
  program opens, and no DD that its program does not use, once the
  paths of alternate indexes (`XREFFIL1` for `XREFFILE`) are counted.
- **PLB-B001 map-fields-overlap.** Sixteen fields overlap another field
  of their map. Some are one byte too long: `ERRMSG` with `LENGTH=80` at
  column 1 runs into the attribute byte of the function key line below
  it (`COCRDSL`, `COCRDUP`), and the label before `USRTYPE` runs into
  `USRTYPE` (`COUSR01` to `COUSR03`); in the authorization screen
  `COPAU01`, an 18-character label runs over the field `TRNID`. Others put two fields at one
  position: a stopper field and a label in the sign-on screen, and
  after each card's selection field in the card list. In `COACTUP` and
  `COACTVW`, the last field of the map is placed at row 1, column 1,
  on top of the first.
- **PLB-B004 symbolic-map-stale.** None: the symbolic map copybooks in
  `cpy-bms` match the 21 maps field for field.
- **PLB-K001 cics-resource-undefined.** None: every file, transaction,
  program, mapset, and queue that the programs' CICS commands name by a
  constant is defined, once the definitions of the extensions are read
  with the application's. Without them, the 13 commands of the
  extensions' programs that name their own transactions and mapsets
  are reported.
- **PLB-A001 unused-program.** `CBTRN01C` is the only program that no
  job runs, no program calls or names, and no transaction starts.
  `CBTRN02C`, which the job `POSTTRAN` runs, posts the daily
  transactions; `CBTRN01C` also reads the daily transaction file, but
  no job runs it. The
  IMS programs are started by `DFSRRC00` and the DB2 program by
  `IKJEFT01`, which the JCL reader follows into `PARM` and `SYSTSIN`.
- **PLB-Q001 sql-table-undeclared.** None: the DB2 programs include the
  DCLGEN member of every table they use.
- **PLB-C032 duplicate-when.** In the card list (`COCRDLIC`) and the
  transaction type list (`COTRTLIC`), two `WHEN`s test `CCARD-AID-PFK07
  AND CA-FIRST-PAGE`: PF7 on the first page. The second, under a comment
  that says what it is for, never runs.
- **PLB-C033 self-move.** `COACCT01` and `CODATE01` move
  `WS-CICS-RESP2-CD` to itself, and then build an error message from
  `WS-CICS-RESP2-CD-D`, which the MOVE was meant to fill.
- **PLB-C035 duplicate-paragraph.** `COACTVWC` defines
  `0000-MAIN-EXIT` on lines 408 and 411. Nothing performs either, so
  the program compiles; a `PERFORM 0000-MAIN-EXIT` added later would
  not. The NIST and GnuCOBOL suites have no repeats.
- **PLB-C036 arithmetic-overflow.** The authorization programs
  `COPAUA0C` and `CBPAUP0C` add and subtract `S9(10)V99` amounts into
  the `S9(09)V99` totals of the pending-authorization summary
  (`CIPAUSMY`), so a large enough amount wraps a total (5 findings).
  Since `COMPUTE` is read, 3 more: `COPAUA0C` and `CBTRN02C` compute
  `S9(10)V99` amounts into `S9(09)V99` items, and `CBPAUP0C` a
  difference of `YYDDD` dates into a 4-digit item. A first version took
  `LENGTH OF XREF-CUST-ID`, in `CBSTM03A`, for the item's value.
- **PLB-K002 read-update-not-released.** `COTRN01C`, the screen that
  shows one transaction, reads the transaction file with `UPDATE` and
  never rewrites the record, so it holds the record's lock until the
  task returns. The six other reads for update (in bill payment, in the
  account update for the account and the customer, and in the card
  update, user update, and user delete) are each paired with a
  `REWRITE` or `DELETE`.
- **PLB-J006 lrecl-mismatch.** None: every DD that gives a record
  length for a file of a CardDemo program matches the program's
  records, `CBIMPORT`'s five outputs and the variable-length `VBRCFILE`
  of `READACCT` (80-byte records, `LRECL=84`) among them.
- **PLB-C042 inspect-count-not-reset.** `COCRDLIC` counts the selected
  rows with `INSPECT ... TALLYING I`, where `I` is a loop index that
  nothing sets to zero first. The transaction type list, `COTRTLIC`,
  sets its counts to zero at the top of the same kind of paragraph.
- **PLB-C043 pointer-not-reset.** The authorization program `COPAUA0C`
  builds each reply with `STRING ... WITH POINTER WS-RESP-LENGTH`, a
  pointer that starts at `VALUE 1` and is never set again, in a
  paragraph that runs once for each message of its `PERFORM UNTIL
  NO-MORE-MSG-AVAILABLE` loop. From the second message on, the reply is
  written after the previous one and its length (`W02-BUFFLEN`) is
  wrong.
- **PLB-M017 two-digit-year.** Four programs of the authorization
  extension accept the date and the day in two-digit years (8 notes).
  The purge job `CBPAUP0C` goes further: it ages each authorization as
  `CURRENT-YYDDD - WS-AUTH-DATE`, a difference of two Julian dates that
  is wrong across every new year (an authorization of December 31 is
  636 days old on January 1), so it purges authorizations early in the
  first days of a year.
- **PLB-C045 alnum-compared-to-number.** The transaction type list
  (`COTRTLIC`) tests `WHEN WS-IN-TYPE-CD = 0`, with `WS-IN-TYPE-CD`
  `PIC X(02)`: true for "0 " but not for a type code of "00". The
  program declares the numeric view `WS-IN-TYPE-CD-N` next to it.
- **PLB-C046 overlapping-move.** None, here or in the NIST and
  GnuCOBOL corpora: no program moves between items that share storage.
- **PLB-C047 foreign-index.** None, here or in the NIST and GnuCOBOL
  corpora. NIST declares 163 indexes in 50 programs and uses each with
  its own table; swapping one in a copy of `NC123A` (an index of 2-byte
  entries on a table of 3-byte entries) is reported.
- **PLB-C048 sort-procedure-no-record.** None, here or in the NIST and
  GnuCOBOL corpora. The 29 NIST programs with SORT or MERGE procedures
  all release and return their records; with the `RELEASE` of `DB104A`
  taken out, its input procedure `SORT-IN` is reported.
- **PLB-C049 loop-condition-unchanged.** None, and none in the
  GnuCOBOL corpus. Of CardDemo's 33 lines with `UNTIL`, four belong to
  `VARYING` loops; the others are loops that read a file, call a program
  (MQ), or run EXEC SQL or CICS commands, which the rule leaves alone.
- **PLB-C050 record-read-at-end.** None, here or in the NIST and
  GnuCOBOL corpora: the `AT END` phrases set end-of-file flags. A
  `DISPLAY` of the record added to the `END` phrase of a `READ` in a
  copy of NIST's `SQ103A` is reported.
- **PLB-C051 duplicate-if-condition.** None, here or in the NIST and
  GnuCOBOL corpora. In a copy of NIST's `CM202M` whose third test is
  made the same as its second, the third is reported. In a copy of
  `COCRDSLC` whose `IF CDEMO-ACCT-ID = 0` is made `< 100` with
  `IF CDEMO-ACCT-ID < 10` as the first statement of its `ELSE`, the
  second test is reported.
- **PLB-C052 string-overlap.** None, here or in the NIST and GnuCOBOL
  corpora. A copy of NIST's `NC217A` whose first `STRING` sends its
  receiver is reported.
- **PLB-Q005 into-count-mismatch.** None: the `FETCH` statements of
  `COTRTLIC` and the singleton `SELECT`s of the DB2 extension match their
  select lists, commas at the start of continuation lines included. With
  one host variable taken out of a `FETCH` in a copy of `COTRTLIC`, it
  is reported.
- **PLB-K003 commarea-without-length.** None. The 21 programs that have
  a `DFHCOMMAREA` and return with `TRANSID` all test `EIBCALEN`. A first
  version, which checked every program with a COMMAREA, reported
  `COPAUS2C`, which `COPAUS1C` only `LINK`s to with a COMMAREA; the rule
  now checks transaction programs only. With `EIBCALEN` renamed away in
  a copy of `COMEN01C`, its use of the COMMAREA is reported.
- **PLB-J007 dataset-created-twice.** None: the jobs that rebuild a data
  set delete it first in an `IEFBR14` step. With that step of `DUSRSECJ`
  made to create the data set instead, the step that rebuilds it is
  reported.
- **PLB-J011 dd-name-repeated.** None. In a copy of `READACCT` with
  its `DD03` renamed `DD02`, it reports the second `DD02`.
- **PLB-J012 read-after-delete.** None: the jobs that delete their
  data sets first (`PREDEL` steps, `DISP=(MOD,DELETE,DELETE)`) create
  them again before reading them. In a copy of `READACCT` whose
  `OUTFILE` is made `DISP=SHR` instead of `(NEW,CATLG,DELETE)`, it
  reports that DD.
- **PLB-J010 dsn-invalid.** None, among the 90 distinct names without
  symbols in the jobs' `DSN=` parameters. In a copy of `ACCTFILE` with
  `ACCTDATA` made `ACCTDATA1`, it reports the nine-character qualifier.
  Its 25 relative generations are `(+1)` and `(0)`; in a copy of
  `PRTCATBL` with a `(+1)` made `(+256)`, it reports that one.
- **PLB-J009 referback-unresolved.** None: CardDemo's jobs have no
  backward references. In a copy of `TRANEXTR` with two `DSN=` changed
  to `*.STEP10.SYSUT1` and `*.STEP10.SYSUT9`, the first takes the data
  set of `STEP10`'s `SYSUT1` and the second is reported.
- **PLB-J008 cond-step-unknown.** None: the 17 `COND` tests of the jobs
  name no step (`COND=(0,NE)`, `COND=(4,LT)`), nor does the one `IF`
  (`IF RC = 0 THEN` in `BLDCIDB2`). In a copy of `TRANEXTR`
  with step names added, a test of `STEP30` from `STEP20` and one of a
  missing `STEP35` are reported, and one of `STEP40` from `STEP50` is
  not.
- **PLB-C053 exit-program-in-main.** None. CardDemo's one `EXIT PROGRAM`
  is in `CSUTLDTC`, a date check other programs call. With the `GOBACK`
  of `CBACT01C`, which job `READACCT` runs, changed to `EXIT PROGRAM`,
  it is reported. NIST and GnuCOBOL's tests come without JCL.
- **PLB-A002 record-length-conflict.** None: the programs that share
  data sets through CardDemo's jobs use them with the same record
  lengths. With the account record of `CBACT01C` made a
  byte longer, its use through `READACCT` is reported against `INTCALC`'s.
- **PLB-K004 commarea-length-too-long.** None: most commands leave
  `LENGTH` out, and the rest give `LENGTH OF` their own COMMAREA item.
  With that length changed to 20000 in a copy of `COCRDUPC`, whose
  `WS-COMMAREA` has 2000 bytes, it is reported.
- **PLB-K006 return-transid-without-commarea.** None: each of the 21
  programs with a `DFHCOMMAREA` and a `RETURN TRANSID` passes its
  `COMMAREA` back. In a copy of `COADM01C` with the `COMMAREA` line of
  its first `RETURN` taken out, it reports that `RETURN`.
- **PLB-K005 batch-io-in-cics.** None: no program with CICS commands
  has COBOL file statements or an `ACCEPT` of input.
  An `ACCEPT` added to a copy of `COMEN01C` is reported.
- **PLB-Q006 and PLB-Q007.** None: the DB2 programs use the host
  variables of their DCLGEN copybooks, which match the tables. With the
  text of the VARCHAR structure for `TR_DESCRIPTION` made 40 characters
  in a copy of `DCLTRTYP`, the `SELECT` of `COTRTUPC` is reported.
- **PLB-C054 go-to-into-perform-range.** Three, all the same mistake.
  `COACTUPC` performs `9700-CHECK-CHANGE-IN-REC THRU
  9700-CHECK-CHANGE-IN-REC-EXIT` from within `9600-WRITE-PROCESSING`,
  and the check, when it finds a change, goes to
  `9600-WRITE-PROCESSING-EXIT` (twice) instead of its own exit:
  the inner `PERFORM` is left unfinished and the outer range returns.
  `COCRDUPC` does the same from `9300-CHECK-CHANGE-IN-REC` to
  `9200-WRITE-PROCESSING-EXIT`.
- **PLB-C055 corresponding-no-match.** None: CardDemo has no
  `CORRESPONDING` statement.
- **PLB-C056 self-comparison.** None. With the credit limit test of
  `CBTRN02C` (`IF ACCT-CREDIT-LIMIT >= WS-TEMP-BAL`) changed to compare
  the limit with itself in a copy, the copy's condition is reported as
  always true.
- **PLB-C057 misleading-indentation.** None: CardDemo ends its `IF`
  statements with `END-IF`.
- **PLB-C058 read-not-handled.** None: each `READ` has an `AT END` or
  `INVALID KEY` phrase, or its file a `FILE STATUS`.
- **PLB-C059 key-error-not-handled.** None, for the same reason.
- **PLB-C060 spaces-into-numeric.** None.
- **PLB-C028 comparison-never-true**, for alphanumeric items compared
  with longer literals: none. In a copy of `CBACT01C` with `IF
  END-OF-FILE = 'N'` changed to `'NO'` (the item is `PIC X(01)`), it
  reports that comparison; in a copy of `COTRN02C` with `WHEN 'Y'`
  changed to `'YES'`, under `EVALUATE CONFIRMI OF COTRN2AI`, that
  `WHEN`. For a numeric `EVALUATE` subject and its `WHEN` numbers:
  none. In a copy of `COADM01C` whose `WS-IDX` is made `PIC S9(01)`,
  its `EVALUATE WS-IDX` is reported at `WHEN 10`.
- **PLB-C062 varying-subscript-out-of-range.** None. In a copy of
  `COCRDLIC` with the limit of its loop over the 7 rows of the screen
  raised from `I > 7` to `I > 8`, it reports the 4 subscripts of that
  loop; with `FROM 0`, the same 4 for the first pass.
- **PLB-C063 varying-refmod-out-of-range.** None. The two loops with
  the counter in a reference modifier, in `COMEN01C` and `COADM01C`,
  count down from `LENGTH OF`, which the rule does not work out.
- **PLB-C064 duplicate-condition-value.** 2, both in `COTRTLIC`:
  `CA-DELETE-SUCCEEDED` and `CA-UPDATE-SUCCEEDED` have the value
  `LOW-VALUES` of `CA-DELETE-NOT-REQUESTED` and
  `CA-UPDATE-NOT-REQUESTED`. The program tests `IF CA-DELETE-SUCCEEDED`
  after `9300-DELETE-RECORD`, whose `WHEN OTHER` branch (a failed
  delete) leaves the flag as it was: a flag that was never set to
  requested would read as a delete that succeeded. A first version also
  reported 4 pairs of messages with the same text (`SEARCHED-ACCT-ZEROES`
  and `SEARCHED-ACCT-NOT-NUMERIC`, in `COACTUPC`, `COACTVWC`, `COCRDSLC`,
  and `COCRDUPC`) that no statement names; pairs the program does not
  name are no longer reported.
- **PLB-C068 odo-count-out-of-range.** None.
- **PLB-C071 contradictory-condition.** None. In a copy of `CBACT04C`
  whose `IF DISCGRP-STATUS = '00' OR '23'` is made `AND`, it reports
  that condition. With ranges read, still none; it reports
  `IF WS-CURDATE-MONTH > 12 AND < 1` put in a copy of `CORPT00C`, and
  `IF WS-CURDATE-MONTH > 11 AND < 12`, as the month holds whole
  numbers, and
  `IF WS-REJECT-COUNT > 0 OR WS-REJECT-COUNT <= 0` in a copy of
  `CBTRN02C`.
- **PLB-C072 unreachable-statement.** None. In copies of `CBACT01C`
  with its `GOBACK` moved before the `DISPLAY` above it, with a `GO TO
  9999-ABEND-PROGRAM` put first in the success branch of
  `1000-ACCTFILE-GET-NEXT`, or with a `GOBACK` before one of its
  `PERFORM 9999-ABEND-PROGRAM` statements, it reports the statement
  after each. Its 37 `EXEC CICS RETURN` and `XCTL` commands end their
  lists of statements; in a copy of `COSGN00C` with a `MOVE` after its
  first `RETURN`, it reports the `MOVE`.
- **PLB-C073 value-ignored.** 1, in `COBTUPDT`: the record of its
  `FD TR-RECORD` is `WS-INPUT-VARS`, whose three fields each have
  `VALUE SPACES`, a working-storage layout under an `FD`. In a copy of
  `COSGN00C` with `VALUE SPACE` on `LK-COMMAREA` of its `DFHCOMMAREA`,
  and a copy of `CBACT01C` with `VALUE ZERO` on `OUT-ACCT-ID` of its
  output record, it reports each.
- **PLB-C087 when-covered.** None. In a copy of `COADM01C` whose `WHEN 1`
  of `EVALUATE WS-IDX` is made `WHEN 1 THRU 3`, it reports its `WHEN 2`
  and `WHEN 3`. With `EVALUATE TRUE` read, still none; in a copy of
  `COACTUPC` with `WHEN CC-ACCT-ID-N < 10` and a later `WHEN
  CC-ACCT-ID-N = 5`, it reports the second.
- **PLB-C088 accept-truncation.** None: its `PIC 9(06)` and `PIC 9(05)`
  items take `DATE` and `DAY`. In a copy of `CBPAUP0C` whose `ACCEPT
  CURRENT-DATE FROM DATE` is made `FROM DATE YYYYMMDD`, it reports that
  `YY` is lost; in a copy of `PAUDBLOD` made `FROM TIME`, that `HH` is.
- **PLB-C101 string-numeric-sender.** None: its `STRING` statements
  send unsigned whole numbers (`ACCT-ID`, `WS-TRANID-SUFFIX`). In a copy
  of `CBACT04C` with `WS-TRANID-SUFFIX` made `PIC S9(06)`, it reports
  that item.
- **PLB-C107 times-count-changed.** None: CardDemo has no `PERFORM
  ... TIMES`.
- **PLB-C106 unstring-space-not-all.** None: CardDemo has no
  `UNSTRING`.
- **PLB-C105 string-edited-leading-space.** None: its `STRING`
  statements send alphanumeric items `DELIMITED BY SPACE`. In a copy
  of `COBIL00C` that sends a `PIC Z(15)9` copy of the transaction ID
  in place of `TRAN-ID`, it reports that item.
- **PLB-M023 file-unused.** None. In a copy of `CBACT01C` with a
  `SELECT HIST-FILE` and its `FD` added, it reports `HIST-FILE`.
- **PLB-C114 sign-test-not-numeric.** None: CardDemo has no sign
  conditions. In a copy of `COMEN01C` whose `WS-OPTION = ZEROS` is made
  `WS-OPTION IS ZERO`, it reports nothing while `WS-OPTION` is `PIC
  9(02)`, and reports it once `WS-OPTION` is made `PIC X(02)`.
- **PLB-C113 class-test-invalid.** None. In a copy of `CBACT04C` whose
  `IO-STAT2` is made `PIC S9`, it reports `IF IO-STATUS NOT NUMERIC`.
- **PLB-C112 varying-step-zero.** None: its loops step by 1. In a copy
  of `COUSR00C` with a `WS-IDX-STEP` of `VALUE 0` added, and its first
  `PERFORM VARYING WS-IDX FROM 1 BY 1` made `BY WS-IDX-STEP`, it reports
  that loop.
- **PLB-C111 sort-statement-wrong-phase.** None: CardDemo's programs
  have no `SORT` procedures.
- **PLB-C110 file-dd-shared.** None. In a copy of `CBSTM03A` whose
  `HTML-FILE` is assigned to `STMTFILE`, the DD of `STMT-FILE`, it
  reports `HTML-FILE`: one `OPEN OUTPUT` opens both.
- **PLB-C109 pointer-past-end.** None: CardDemo has no `WITH POINTER`.
- **PLB-C108 number-compared-to-text.** None. In a copy of `COACTUPC`
  whose `IF CC-ACCT-ID-N = 0` is made `= "0"`, it reports that
  comparison.
- **PLB-C104 count-too-small.** None: its one `INSPECT ... TALLYING`,
  in `COCRDLIC`, counts 7 flags into `I`, a `PIC S9(4) COMP`. In a
  copy with the flags made `PIC X(10)` and `I` `PIC S9 COMP`, it
  reports that count.
- **PLB-C103 chain-exhausted.** None. In a copy of `COCRDSLC` whose
  `IF CDEMO-ACCT-ID = 0` is made `NOT > 0`, with `IF CDEMO-ACCT-ID > 0
  ... ELSE ...` in its `ELSE`, that last `ELSE` is reported. In a copy
  of `COCRDLIC` whose `WHEN CDEMO-ACCT-ID = 0` is made `<= 0`, with a
  `WHEN CDEMO-ACCT-ID > 0` after it, its `WHEN OTHER` is.
- **PLB-C102 nested-if-decided.** None. In a copy of `COCRDSLC` whose
  `IF CDEMO-ACCT-ID = 0` branch is made to start with `IF
  CDEMO-ACCT-ID > 0`, the inner test is reported as never true. In a
  copy of `COTRN00C` whose `PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL
  WS-IDX > 10` body is made to start with `IF WS-IDX > 11`, that test
  is reported.
- **PLB-C100 table-keys-unsorted.** None: `COPAUS1C`'s
  `WS-DECLINE-REASON-TAB`, the one table `SEARCH ALL` looks in, has its
  ten codes in order (0000 to 9000). In a copy with the rows for 4100
  and 4200 swapped, it reports entry 4 after entry 3.
- **PLB-C098 group-value-into-packed** and **PLB-C099
  value-overridden.** None.
- **PLB-Q029 cursor-unused.** None: its cursors are all opened.
- **PLB-Q030 for-update-read-only.** None: no cursor of CardDemo is
  declared `FOR UPDATE`. In a copy of `COTRTLIC` whose
  `C-TR-TYPE-FORWARD` cursor selects `DISTINCT TR_TYPE`, with its `ORDER
  BY` made `FOR UPDATE`, it reports that cursor.
- **PLB-Q028 order-by-for-update.** None: its two ordered cursors, in
  `COTRTLIC`, are not `FOR UPDATE`. In a copy whose first gets `FOR
  UPDATE OF TR_DESCRIPTION` after its `ORDER BY TR_TYPE`, it reports
  it.
- **PLB-Q027 update-not-for-update.** None: CardDemo has no `WHERE
  CURRENT OF`. In a copy of `COTRTLIC` whose cursor is made `FOR UPDATE
  OF TR_TYPE`, with an `UPDATE ... SET TR_DESCRIPTION = ... WHERE
  CURRENT OF` it after a fetch, it reports `TR_DESCRIPTION`.
- **PLB-Q026 cursor-table-mismatch.** None: CardDemo has no `WHERE
  CURRENT OF`. In a copy of `COTRTLIC` with a `DELETE FROM
  CARDDEMO.AUTHFRDS WHERE CURRENT OF C-TR-TYPE-FORWARD` after a fetch of
  that cursor, on `TRANSACTION_TYPE`, it reports it.
- **PLB-Q025 insert-not-null-missing.** None: its `INSERT` statements
  give every `NOT NULL` column. In a copy of `COBTUPDT` whose `INSERT`
  into `TRANSACTION_TYPE` gives only `TR_TYPE`, it reports
  `TR_DESCRIPTION`, and in one whose `UPDATE` sets `TR_DESCRIPTION =
  NULL`, or whose `INSERT` gives it `NULL`, that `NULL`.
- **PLB-Q024 column-undeclared.** None: the 12 statements and cursors
  of its DB2 programs name the columns of their DCLGEN declarations. In
  a copy of `COTRTLIC` whose cursor selects `TR_DESC` for
  `TR_DESCRIPTION`, it reports `TR_DESC`, and in one whose cursor's
  `WHERE` tests `TR_TYP`, that.
- **PLB-Q023 select-not-grouped.** None: its one aggregate, `SELECT
  COUNT(1)` in `COTRTLIC`, is alone in its list. In a copy that selects
  `COUNT(1), TR_TYPE`, it reports `TR_TYPE`, and in one with `HAVING
  TR_TYPE > '00'` added to that query, the `TR_TYPE` of the `HAVING`.
- **PLB-Q022 aggregate-in-where.** None. In a copy of `COTRTLIC` whose
  cursor's `WHERE TR_TYPE >= :WS-START-KEY` is made `WHERE
  MAX(TR_TYPE) >= ...`, it reports the `MAX`.
- **PLB-Q021 order-by-position.** None: its two `ORDER BY` clauses, in
  `COTRTLIC`, name `TR_TYPE`. In a copy whose first is made `ORDER BY
  3`, after a select list of two, it reports it.
- **PLB-Q020 column-repeated.** None. In a copy of `COBTUPDT` whose
  `UPDATE` sets `TR_DESCRIPTION` a second time, to `SPACE`, it reports
  the second.
- **PLB-Q019 between-reversed.** None: CardDemo's SQL has no
  `BETWEEN`. In a copy of `COBTUPDT` whose `DELETE` has `WHERE TR_TYPE
  BETWEEN 90 AND 10`, it reports that range.
- **PLB-Q018 null-compared.** None. In a copy of `COBTUPDT` whose
  `DELETE` has `WHERE TR_TYPE = NULL`, it reports that comparison.
- **PLB-Q017 fetch-after-close.** None. In a copy of `COTRTLIC` with
  a `FETCH C-TR-TYPE-FORWARD` put after its `CLOSE`, it reports it.
- **PLB-Q016 cursor-open-twice.** None. In a copy of `COTRTLIC` with
  its `OPEN C-TR-TYPE-FORWARD` written twice, it reports the second.
- **PLB-C097 sort-file-open.** None.
- **PLB-C096 converting-repeated.** None.
- **PLB-C095 rewrite-without-read.** None.
- **PLB-M022 mixed-and-or.** 2, in `COTRTLIC`: `IF WS-IN-TYPE-CD EQUAL
  WS-CA-TYPE-CD OR FLG-TYPEFILTER-BLANK AND (WS-CA-TYPE-CD EQUAL ZEROES
  OR ...)`, and the same for the description. The indentation puts the
  `AND` under the `OR`'s right side, which is how COBOL reads it.
- **PLB-C094 open-after-lock.** None: it has no `CLOSE ... WITH LOCK`.
- **PLB-C093 pointer-too-small.** None.
- **PLB-Q015 insert-count-mismatch.** None: its three `INSERT`
  statements have as many values as columns, `COPAUS2C`'s 26 among them
  with `VARCHAR` host variables, a function, and `CURRENT DATE`. A first
  version took a `VARCHAR` for a host structure and did not count that
  list. In a copy of `COPAUS2C` with one column taken out of the list,
  it reports 25 columns and 26 values, and in a copy of `COBTUPDT`
  whose `INSERT` into `TRANSACTION_TYPE` has no column list and one
  value, it reports the table's two columns.
- **PLB-M021 empty-branch-statement.** None.
- **PLB-C092 swap-lost.** None. In a copy of `COSGN00C` with `MOVE
  WS-MESSAGE TO CCDA-MSG-THANK-YOU` put after its `MOVE
  CCDA-MSG-THANK-YOU TO WS-MESSAGE`, it reports the second `MOVE`.
- **PLB-C091 varying-counter-repeated.** None: no `PERFORM` of
  CardDemo has an `AFTER` phrase.
- **PLB-C090 condition-never-true.** 4, in `COPAUA0C`: its
  `WS-DECLINE-REASON-FLG` is only set by `SET INSUFFICIENT-FUND TO
  TRUE`, so the `WHEN CARD-NOT-ACTIVE`, `ACCOUNT-CLOSED`, `CARD-FRAUD`,
  and `MERCHANT-FRAUD` of its `EVALUATE` never match: reasons the
  program does not decide yet. `CBPAUP0C` loops `UNTIL ERR-FLG-ON OR
  END-OF-AUTHDB` and never sets `WS-ERR-FLG`, which keeps its `VALUE
  'N'`; as no statement stores into it, it is not reported. In a copy
  whose `SET END-OF-AUTHDB TO TRUE` is made `MOVE 'E' TO
  WS-END-OF-AUTHDB-FLAG`, it reports `END-OF-AUTHDB`.
- **PLB-C089 loop-never-runs.** None. In a copy of `CBACT01C` with
  `MOVE 'Y' TO END-OF-FILE.` put before its `PERFORM UNTIL END-OF-FILE
  = 'Y'`, it reports that loop.
- **PLB-K016 abcode-invalid.** None: its four literal codes are
  `'9999'`. In a copy of `COCRDUPC` whose `ABCODE('9999')` is made
  `ABCODE('ACCT')`, it reports it.
- **PLB-K015 time-option-out-of-range.** None: CardDemo has no `DELAY`
  or `START`. In a copy of `COSGN00C` with `EXEC CICS DELAY FOR
  MINUTES(1) SECONDS(90)` added, it reports the 90.
- **PLB-K014 return-not-top-level.** None: its one `LINK`, in
  `COPAUS1C`, names `COPAUS2C`, whose `RETURN` has no options. In a
  copy of `COPAUS2C` whose `RETURN` is given `COMMAREA(DFHCOMMAREA)`,
  it reports that `RETURN`.
- **PLB-K013 interval-invalid.** None: CardDemo has no `DELAY`,
  `START`, `POST`, or `ROUTE`. In a copy of `COSGN00C` with an `EXEC
  CICS DELAY INTERVAL(90)` added, it reports the 90.
- **PLB-K012 abstime-not-packed.** None: its `WS-ABS-TIME` items are
  `PIC S9(15) COMP-3`. In a copy of `COBIL00C` whose `WS-ABS-TIME` is
  made `PIC S9(15) COMP`, it reports its `ASKTIME` and `FORMATTIME`.
- **PLB-K011 length-not-halfword.** None: its `LENGTH` options are
  `LENGTH OF` an item or a `FUNCTION`, never an item. In a copy of
  `COSGN00C` whose `RETURN` has `LENGTH(WS-RESP-CD)`, a `PIC S9(09)
  COMP`, it reports it.
- **PLB-K010 resp-not-fullword.** None: its `RESP` items, such as
  `WS-RESP-CD`, are `PIC S9(09) COMP`. In a copy of `COBIL00C` whose
  `WS-RESP-CD` is made `PIC S9(04) COMP`, it reports each of its 7
  commands with `RESP(WS-RESP-CD)`.
- **PLB-K009 browse-not-active.** None: each browse command is in a
  paragraph of its own. In a copy of `COTRN00C` with a `READPREV` put
  after its `ENDBR`, it reports it.
- **PLB-K008 cics-name-too-long.** None among its 68 resource names
  written as literals; its maps and mapsets have 7 characters
  (`COSGN0A`, `COSGN00`). In a copy of `COUSR00C` whose
  `MAPSET('COUSR00')` is made `MAPSET('COUSR00X')`, it reports it.
- **PLB-J038 output-unresolved.** None: CardDemo has no `OUTPUT`
  statements or references. In a copy of `DUSRSECJ` whose `SYSPRINT`
  DD of `STEP01` is given `OUTPUT=*.LASER`, it reports that DD, and not
  once `//LASER OUTPUT CLASS=A` is put before the first step.
- **PLB-J037 disp-invalid.** None among its 348 `DISP` values. In a
  copy of `DUSRSECJ` whose `DISP=(NEW,CATLG,DELETE)` is made
  `(NEW,CATLG,PASS)`, it reports that DD.
- **PLB-J036 space-invalid.** None among its 139 `SPACE` values, in
  tracks, cylinders, and block lengths with `ROUND`. In a copy of
  `DUSRSECJ` whose `RLSE` is made `RELEASE`, it reports that DD.
- **PLB-J035 retention-invalid.** None: no DD of CardDemo codes `EXPDT`
  or `RETPD`. In a copy of `DUSRSECJ` whose `SYSUT2` DD is given
  `RETPD=99999`, it reports that DD.
- **PLB-J034 lrecl-invalid.** None among its 44 `LRECL` values, the
  longest 27990 (`DBPAUTP0`). In a copy of `DBPAUTP0` with
  `LRECL=37990`, it reports that DD.
- **PLB-J033 cond-invalid.** None: its `COND` tests are `(0,NE)`,
  `(4,LT)`, and `(8,LT)`, some naming a step. In a copy of `TRANBKP`
  whose `COND=(4,LT)` is made `(4,LTE)`, it reports that step.
- **PLB-J032 class-invalid.** None: its jobs code `CLASS=A`, and
  `MSGCLASS` 0, A, H, X, or Y, and its DDs `SYSOUT=*` or `SYSOUT=(A,...)`.
  In a copy of `DUSRSECJ` with `MSGCLASS=HX`, it reports the job.
- **PLB-J031 msglevel-invalid.** None: its 17 `MSGLEVEL` values are
  `(1,1)`. In a copy of `FTPJCL` with `MSGLEVEL=(1,2)`, it reports the
  job.
- **PLB-J030 region-invalid.** None among its 58 `REGION=` values,
  from `1024K` to `8M`, and `0K` and `0M`. In a copy of `DUSRSECJ` with
  `REGION=8M` made `REGION=8192`, it reports the job.
- **PLB-J029 time-invalid.** None: its jobs code `TIME=1440` 15 times
  and `TIME=30` once (`DBPAUTP0`). In a copy of `DBPAUTP0` with
  `TIME=(30,60)`, it reports the job.
- **PLB-J028 instream-procs-too-many.** None: no job file of CardDemo
  has more than one in-stream procedure.
- **PLB-J027 proc-calls-itself.** None. `TRANREPT.prc` begins
  `//REPROC PROC` and calls `PROC=REPROC`, but z/OS calls it by its
  member name, `TRANREPT` (as `CORPT00C` does), so `REPROC` is the
  other procedure. In a copy of `REPROC.prc` with a step `EXEC
  PROC=TRANREPT` added, it reports both procedures' calls.
- **PLB-J026 job-too-many-steps.** None: the jobs with the most steps,
  `CARDFILE` and `TRANFILE`, have 8, each running a program.
- **PLB-J025 dlm-not-instream.** None: no DD of CardDemo codes `DLM`.
  In a copy of `INTRDRJ1` whose `SYSUT1` DD, a data set, is given
  `DLM=@@`, it reports it.
- **PLB-J024 sysout-parameter-conflict.** None among its 210 `SYSOUT`
  DDs. In a copy of `INTRDRJ1` whose `SYSPRINT` DDs are given
  `DISP=SHR`, it reports both; in one whose `SYSOUT=(A,INTRDR)` DD is
  given `OUTPUT=*.LASER`, that DD.
- **PLB-J023 copy-onto-itself.** None among its 17 `IEBGENER` steps
  in 10 files. In a copy of `INTRDRJ1` whose `SYSUT2` is made the
  member its `SYSUT1` reads, `AWS.M2.CARDDEMO.JCL(INTRDRJ2)`, it
  reports it.
- **PLB-J022 cond-never-true.** None, for the same tests. In a copy of
  `DEFGDGD` whose `COND=(0,NE)` is made `(0,GT)`, it reports that step.
- **PLB-J021 cond-always-bypasses.** None: the `COND` tests of its steps are
  `(0,NE)` and `(4,LT)`. In a copy of `DEFGDGD` whose `COND=(0,NE)` is
  made `(0,LE)`, it reports that step. No `JOB` statement codes `COND`;
  in a copy of `DUSRSECJ` with `COND=(0,LE)` added to its `JOB`
  statement, it reports the job.
- **PLB-J020 jcl-name-invalid.** None in its 48 JCL and procedure
  files. In a copy of `INTCALC` whose `STEP15` is renamed
  `STEP15CALC`, it reports that name, and in one whose `PGM=CBACT04C`
  is made `PGM=CBACT04CALC`, the program name.
- **PLB-J019 parm-too-long.** None: its longest `PARM` passes 36
  characters (`DFHCSDUP` in `CBADMCDJ`). In a copy of `INTCALC` whose
  `PARM='2022071800'` is made 101 characters, continued over three
  lines, it reports that step.
- **PLB-J018 gdg-generation-not-created.** None: its jobs read `(0)` and
  create `(+1)`. In a copy of `DEFGDGD` whose `TRANTYPE.BKUP(+1)` DD is
  made `DISP=SHR`, it reports that DD.
- **PLB-J017 blksize-invalid.** None: its 11 DD statements with a
  `BLKSIZE` other than 0 are `RECFM=FB` with a multiple of `LRECL` (or
  `SYSOUT`). In a copy of the job whose `SORTOUT` has `LRECL=350`, with
  `BLKSIZE=3400` for its 3500, it reports that DD.
- **PLB-J016 utility-dd-missing.** None: its 62 `IDCAMS`, 8
  `IEBGENER`, and 8 `IKJEFT01`/`IKJEFT1B` steps have their DD
  statements. In a copy of `DEFCUST` with the first `SYSIN` renamed, it
  reports that `IDCAMS` step.
- **PLB-J015 step-name-repeated.** 2: `DEFCUST` names two `IDCAMS`
  steps `STEP05`, and `TRANREPT` names both the `REPROC` step and the
  `SORT` after it `STEP05R`.
- **PLB-J014 output-deleted.** None. In a copy of `READACCT` whose
  `OUTFILE` DD is made `DISP=(NEW,DELETE,DELETE)`, it reports that DD.
- **PLB-J013 shr-for-output.** None: its jobs write their sequential
  outputs as new data sets. In a copy of `READACCT` whose `OUTFILE` DD
  is made `DISP=SHR`, it reports that DD; the `ACCTFILE` DD, `DISP=SHR`
  for a VSAM file the program reads, is left alone.
- **PLB-C086 read-loop-end-only** and **PLB-Q014 fetch-loop-end-only.**
  None: its read loops end on a flag that a paragraph sets from the
  status, with an abend for errors, and its `FETCH` statements are
  followed by tests of `SQLCODE`. In a copy of `CBACT01C` whose read
  loop is made `PERFORM UNTIL ACCTFILE-STATUS = '10'` around a bare
  `READ`, and a copy of `COTRTLIC` with a `PERFORM UNTIL SQLCODE = 100`
  around one of its `FETCH` statements, each is reported.
- **PLB-C085 zeros-into-packed.** None. In a copy of `CBTRN03C` with a
  `MOVE ZEROS TO WS-REPORT-VARS` before its `ADD 1 TO WS-LINE-COUNTER`,
  it reports that the `COMP-3` counter is read with zeros in it.
- **PLB-C084 file-status-unknown.** None. In a copy of `CBACT01C` whose
  `IF ACCTFILE-STATUS = '10'` is made `'01'`, it reports the `'01'`.
- **PLB-C083 close-in-loop.** None. In copies of `CBACT01C` with a
  `CLOSE ACCTFILE-FILE`, or a `PERFORM 9000-ACCTFILE-CLOSE`, put at the
  end of its read loop, it reports the `CLOSE`.
- **PLB-C082 pointer-below-one.** None. CardDemo's one `WITH POINTER`,
  in `COPAUA0C`, starts from the item's `VALUE 1`.
- **PLB-Q013 select-into-no-where.** None. In a copy of `COTRTUPC`
  whose `SELECT TR_TYPE, TR_DESCRIPTION INTO ...` loses its `WHERE`, it
  reports that `SELECT`.
- **PLB-C081 varying-wrong-direction.** None.
- **PLB-C080 initialize-loses-value.** None. A first version reported
  23: its programs `INITIALIZE` their working storage at the start,
  and the flags in it (`ACUP-CHANGE-ACTION VALUE LOW-VALUES`,
  `WS-EDIT-YES-NO VALUE 'N'`) are set again afterwards, through their
  condition names, a `MOVE`, or (`WS-EDIT-SELECT-FLAGS`) the table that
  redefines them; one (`WS-DATE-FORMAT` in `COTRTUPC`) is never read.
  The rule now leaves such items alone. In a copy of `CBTRN03C` with
  `INITIALIZE REPORT-NAME-HEADER` before the header is written, it
  reports the three titles of the report's first line.
- **PLB-C079 nonnumeric-literal-move.** None. In a copy of `CBACT04C`
  with `MOVE 0 TO WS-TOTAL-INT` made `MOVE '0.00' TO WS-TOTAL-INT`, it
  reports that `MOVE`.
- **PLB-C078 string-literal-cut.** None. In a copy of `COUSR03C` whose
  `' has been deleted ...'` is made `DELIMITED BY SPACE`, it reports
  that the literal sends nothing.
- **PLB-C077 index-set-out-of-range.** None: CardDemo has no `SET`
  of an index to a number. In a copy of `COPAUS1C` with `SET
  WS-DECL-RSN-IDX TO 11` before its `SEARCH ALL` of a 10-entry table,
  it reports that `SET`.
- **PLB-C076 open-while-open.** None. In a copy of `CBACT01C` with its
  `OPEN INPUT ACCTFILE-FILE` written twice, it reports the second.
- **PLB-C075 io-after-close.** None. In a copy of `CBACT01C` with a
  `READ ACCTFILE-FILE` after the `CLOSE` in `9000-ACCTFILE-CLOSE`, and
  one with a `CLOSE OUT-FILE` before the `WRITE OUT-ACCT-REC`, it
  reports the `READ` (status 47) and the `WRITE` (status 48).
- **PLB-C074 condition-range-reversed.** None, in 4 lines with a
  `VALUE ... THRU` range. In a copy of `COCRDUPC` whose `VALID-MONTH`
  is made `VALUES 12 THRU 1`, it reports that range. CardDemo has no
  `WHEN ... THRU`.
- **PLB-C069 search-index-used-unchecked.** None: CardDemo has no
  `SEARCH`.
- **PLB-Q012 fetch-after-commit.** None: the `SYNCPOINT` statements of
  `COTRTLIC` and `COTRTUPC` are in their update and delete paragraphs,
  not in the loops that fetch. In a copy of `COTRTLIC` with an `EXEC
  SQL COMMIT` added before the `FETCH` of its forward read loop, it
  reports that `FETCH`.
- **PLB-K007 commarea-too-short.** None: every `DFHCOMMAREA` of
  CardDemo is declared `OCCURS 1 TO 32767 TIMES DEPENDING ON EIBCALEN`,
  which the rule does not check, and most `XCTL` statements name their
  program in a data item set at run time. With the `DFHCOMMAREA` of
  `COMEN01C` made `PIC X(5000)` in a copy of the programs, it reports
  the two `XCTL` statements that name `COMEN01C` by a constant, in
  `COCRDLIC` and `COSGN00C`, each passing the 160 bytes of
  `CARDDEMO-COMMAREA`.
- **PLB-Q011 cursor-opened-in-loop.** None. In a copy of `COTRTLIC`
  that performs `9400-OPEN-FORWARD-CURSOR` `2 TIMES`, it reports the
  `OPEN` of `C-TR-TYPE-FORWARD` there.
- **PLB-C067 divisor-not-checked** (off by default). None when
  enabled: CardDemo divides only by literals.
- **PLB-C066 identical-branches.** None. In a copy of `CBACT01C` whose
  `ELSE MOVE 12 TO APPL-RESULT` is made `MOVE 0`, as its `THEN` has,
  it reports that `ELSE`.
- **PLB-C065 open-in-loop.** None. In a copy of `CBACT01C` whose
  `PERFORM 0000-ACCTFILE-OPEN` is made `2 TIMES`, it reports the `OPEN`
  of `ACCTFILE-FILE` in that paragraph.
- **PLB-M020 constant-condition.** None.
- **PLB-Q008 null-without-indicator.** None: the tables that are fetched
  from declare their columns `NOT NULL`, and the one with nullable
  columns, `AUTHFRDS`, is only inserted into, by `COPAUS2C`.
- **PLB-Q009 update-of-read-only-cursor.** None, and none of the three
  corpora has a positioned `UPDATE` or `DELETE` (`WHERE CURRENT OF`): the
  rule is only tested by its own test.
- **PLB-Q010 cursor-undeclared.** None: the seven `OPEN`, `FETCH`, and
  `CLOSE` statements of `COTRTLIC` name its two declared cursors. With
  one `FETCH` of `C-TR-TYPE-BACKWARD` misspelled in a copy, the rule
  reports it there.
- **PLB-C070 mq-completion-not-checked.** None: the MQ programs test
  `MQ-CONDITION-CODE` after each call. In a copy of `COACCT01` with the
  tests after its `MQGET` made to name another item, it reports that
  call; a first version took the `MQCLOSE` of the paragraph performed
  at the end, and the test of its own codes after it, for the
  `MQGET`'s test.
- **PLB-I005 dli-status-not-checked.** None: each DL/I call of the IMS
  programs is followed by a test of its PCB status or of `DIBSTAT`. A
  first version reported 4 `EXEC DLI TERM` statements, now left alone,
  and a `REPL` whose test came after the `ISRT` of the `ELSE` branch.
  In copies of `PAUDBLOD` and `COPAUA0C` with the tests after a call
  taken out, it reports those calls.
- **PLB-I001 to PLB-I004.** None: the IMS extension's PSBs match its
  databases, and every DL/I call of its programs names a segment their
  PSB (`PSBPAUTB`, scheduled with `SCHD` or by the job's `DFSRRC00` step)
  is sensitive to, with `PROCOPT=AP`.

## CRUD matrix

`plumbline crud` over the 44 programs gives 86 rows: the batch
programs' files, the online programs' CICS files (`ACCTDAT`,
`CARDDAT`, `CARDAIX`, `CCXREF`, `CUSTDAT`, `CXACAIX`, `TRANSACT`, and
`USRSEC`, the names the CICS definitions give, found through items such
as `LIT-ACCTFILENAME`), and the DB2 extension's tables. `COTRTUPC` is
the one program that creates, reads, updates, and deletes
`CARDDEMO.TRANSACTION_TYPE`; `COUSR01C` to `COUSR03C` split the user
file `USRSEC` between them (create, read and update, read and delete).

## Duplicate code

`plumbline duplicates` over the 44 programs lists 17 groups of
paragraphs with the same code. The largest group is a paragraph that
shows a file status, pasted into eight batch programs (`CBACT01C`,
`CBACT02C`, `CBACT03C`, `CBACT04C`, `CBTRN02C`, and `CBTRN03C` call it
`9910-DISPLAY-IO-STATUS`; `CBCUS01C` and `CBTRN01C`,
`Z-DISPLAY-IO-STATUS`). The others are pairs, such as
`1230-EDIT-ALPHANUM-REQD` in `COACTUPC` and `COTRTUPC`, and
`3000-GET-REQUEST` in the two MQ programs. A first version also listed
`YYYY-STORE-PFKEY` seven times: it comes from one copybook, `CSSTRPFY`,
and paragraphs a COPY brings in are now left out.

## Program documentation

`plumbline doc` over the base application's 29 programs, with its JCL,
maps, and CICS definitions, writes 29 pages (about 12,600 lines of
Markdown) in about 1.3 seconds. The 23 paragraphs its tables mark as
never run are the 23 that PLB-C001 reports. Most are `-EXIT`
paragraphs after an `EXEC CICS RETURN`, and copies of `SEND-LONG-TEXT`,
a debugging aid the programs share. `COACTVWC` defines `0000-MAIN-EXIT`
twice, and both copies show.

## Data sets

`plumbline graph --kind datasets` over the programs, JCL, and
procedures draws 49 data sets and 103 reads and writes between them
and the job steps. Three are updates, all from programs that open the
file `I-O` (the account file in `INTCALC` and `POSTTRAN`, the category
balances in `POSTTRAN`). Four are left without a direction: `IDCAMS`
steps loading a VSAM file with `DISP=OLD`, whose `REPRO` is in the
control statements rather than in a program.

## Copybook fields

`plumbline fields` over the base programs lists 41 copybooks. The
record layouts of the data files are named nearly in full: every item
of the account, card cross-reference, customer, and transaction
records is named by some program. What no program names is mostly in
the symbolic maps, whose input and attribute fields a program leaves to
CICS, and in a few layouts: the date conversion area `CODATECN`, filled
by the date routine the program calls with the whole record, and the
timestamp `DALYTRAN-PROC-TS` of the daily transaction record.
