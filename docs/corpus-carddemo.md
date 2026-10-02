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
directory of copybooks and DB2 declarations on the copy path. None of
CardDemo is added to this repository.

## Results

The run on 2026-10-01 takes about a second:

| | |
|---|---|
| Programs | 44 (30,175 lines, without copybooks) |
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
| PLB-C002 perform-and-fall-through | 23 |
| PLB-C020 file-status-not-checked | 10 |
| PLB-M002 alter | 4 |
| PLB-M008 file-not-closed | 3 |
| PLB-C007 redefines-larger | 3 |
| PLB-C014 call-argument-mismatch | 2 |
| PLB-C011 read-never-set | 1 |
| PLB-C004 next-sentence-in-scope | 1 |
| PLB-C003 fall-off-end | 1 |

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
