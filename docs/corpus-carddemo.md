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
sources, and its 4 files of CICS resource definitions. None of
CardDemo is added to this repository.

## Results

The run on 2026-10-01 takes about a second:

| | |
|---|---|
| Programs | 44 (30,175 lines, without copybooks) |
| JCL members and procedures | 48 |
| BMS map sources | 21 |
| CICS resource definition files | 4 |
| Programs with input errors | 24, all for copybooks of CICS and MQ |

The copybooks it cannot find are those that come with the products, not
with the application: `DFHAID` and `DFHBMSCA` (CICS), and `CMQV`,
`CMQODV`, and the other MQ definitions. Every undefined name left
(PLB-C009) is one of the MQ names; the CICS names, which all start with
`DFH`, are known in a program that uses `EXEC CICS`.

| Rule | Findings |
|------|---------:|
| PLB-M003 unused-data-item | 201 |
| PLB-M001 go-to | 200 |
| PLB-C009 undefined-name | 167 |
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
| PLB-J001 dd-missing | 1 |

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
