# Running Plumbline on the NIST COBOL-85 suite

Plumbline's own source is its first test corpus (see
[testing](testing.md)). The second corpus is the NIST COBOL-85 test
suite (CCVS85, version 4.0): hundreds of programs written to exercise
every part of the 1985 standard, including the obsolete parts. It is a
US government work in the public domain. It is not included in this
repository. `make corpus` downloads it from the GnuCOBOL project's
mirror, checks it against a known SHA-256, and runs Plumbline over it:

```console
$ make corpus
programs:            459 (347213 lines with copybooks)
seconds:             22 (one run per program)
seconds, one run:    10
one run agrees:      yes
with input errors:   2
...
```

`tools/corpus/split_nist.py` splits the suite's single file into one
source file per program and one copybook per library member. Some
lines carry a letter in the indicator column. These mark optional
code, which the suite's driver program (EXEC85) switches on or off for
each compiler. The script switches all of it off, the way EXEC85 does
for a feature a compiler does not claim, by making those lines
comments.

## Results

The figures below are from 2026-10-01, on an Apple M1 laptop.
Each program is checked on its own with every rule at its default
setting. The script then checks all programs in one run and compares
the findings; they must be the same.

| | |
|---|---|
| Programs | 459 |
| Lines, with copybooks | 347,213 |
| Time, one `plumbline` run per program | 22 s |
| Time, all programs in one run | 10 s |
| Programs read without input errors | 458 |

The one program that still has input errors is **SM207A**: `COPY ALTLB
OF XXXXX047` names a library that EXEC85 would substitute. In the suite
as distributed, the library does not exist.

**NC215A**, which splits a doubled quote across a continuation line
(the first quote of the pair in column 72, the second after the
continuation's own quote), had an unterminated literal until
Plumbline learned to join such a line.

| Rule | Findings |
|------|---------:|
| PLB-M001 go-to | 20,574 |
| PLB-C001 unreachable-code | 5,666 |
| PLB-M003 unused-data-item | 3,238 |
| PLB-C008 move-truncation | 476 |
| PLB-M005 set-never-read | 313 |
| PLB-C002 perform-and-fall-through | 257 |
| PLB-C020 file-status-not-checked | 105 |
| PLB-M002 alter | 97 |
| PLB-C009 undefined-name | 80 |
| PLB-C029 go-to-leaves-perform | 80 |
| PLB-M008 file-not-closed | 14 |
| PLB-C030 value-never-used | 12 |
| PLB-C003 fall-off-end | 11 |
| PLB-C031 string-overflow | 6 |
| PLB-C022 open-mode-mismatch | 6 |
| PLB-C011 read-never-set | 5 |
| PLB-C005 perform-thru-backwards | 3 |
| PLB-C021 file-not-opened | 1 |
| PLB-C006 recursive-perform | 1 |

Test programs written to exercise a compiler are not typical application
code. They use GO TO everywhere, declare many items that only some tests
use, and contain test paragraphs that are only reached when EXEC85
deletes a test. The numbers show what Plumbline reports on such code.
They are not a measure of how often these problems occur in practice.

## What the run found in Plumbline

The first run, with the optional-code markers still in place, read 52
of the 459 programs without input errors. With the markers switched
off, it read 409. Each remaining cause was either a gap in Plumbline
or an artifact of the suite. Every gap was fixed with a test of its
own:

- Numeric literals that start with a decimal point after a sign or an
  opening parenthesis (`-.5`, `MIN(.5, .1)`).
- Comment entries in the identification division (`SECURITY.` and its
  free text, which may contain an unmatched quote). These are now
  skipped up to the next paragraph or division header.
- `SORT` and `MERGE` with `INPUT PROCEDURE` and `OUTPUT PROCEDURE`, which
  run their procedures the way PERFORM does. Those procedures were
  reported as never executed.
- `ALTER`, which changes where a GO TO goes. The procedures reached only
  through an altered GO TO were reported as never executed.
- `CD` entries (the communication module) and the fields of
  `DEBUG-ITEM`, which caused about 480 false undefined-name errors.
- References qualified more than 8 levels deep, which were reported as
  ambiguous.
- Items set only in declarative procedures, which were reported as used
  before being set.
- The sign character of `SIGN ... SEPARATE` items, which was left out of
  their size.
- Trailing spaces of a literal, which were counted as characters that a
  MOVE loses.
- Picture strings in pseudo-text, which took the closing `==` with them.
- Qualified and subscripted identifiers as `COPY ... REPLACING`
  operands.
- `DECIMAL-POINT IS COMMA` and `CURRENCY SIGN`, which change how
  pictures and numeric literals read, and repetition counts with leading
  zeros.
- Report Writer: `RD` entries and report groups (6 programs), whose
  clauses' numbers read as level numbers and whose report names were
  undefined.

## Formatting the suite

`tests/tools/roundtrip_format.py` formats every program of the suite to
free format and back to fixed format. All 459 keep every token, and
formatting the results again changes nothing (2026-10-01, 3 minutes 40
seconds).

## Checking the findings

The findings were checked by rule:

- **PLB-C001 unreachable-code.** A script listed every paragraph
  reported as unreachable whose name appears anywhere else in the
  program, outside literals and outside code that is itself unreachable.
  Of 5,784 findings in an earlier run, 71 were left. These were read.
  Most were in programs using ALTER, and ALTER is now followed; the
  others were true, such as a paragraph performed only from another
  unreachable paragraph, which the script could not see. The findings
  the script cleared are true: most are the test-deletion paragraphs
  that only EXEC85 wires in.
- **PLB-C010 ambiguous-name, PLB-C011 read-never-set, and PLB-C012
  use-before-set.** Every finding was read. All C010 findings and all
  C012 findings were false and were fixed (deep qualification,
  declaratives). One C011 finding was false and was fixed (the separate
  sign). The 5 C011 findings that remain are true for the code as split. For example, `IF-D34`
  in NC250A has no VALUE and nothing sets it before it is tested.
- **PLB-C009 undefined-name.** Every finding left was read, and all 80
  have a cause outside Plumbline:
  - 66 name EXEC85 placeholders (`XXXXX031` and similar), which EXEC85
    replaces with names of each compiler's choosing.
  - 14 name switch conditions (`SW-1`, `ON-WRK-SWITCH-1`) declared only
    in optional code, which the split switches off.
- **PLB-C022 open-mode-mismatch.** Every finding was read. All 6 are in
  tests of the I-O status codes that read a file opened only for output
  on purpose, and then expect status 47. One false finding, a WRITE to
  an `EXTERNAL` file that another program opens, was fixed.
- **PLB-C029 go-to-leaves-perform.** A sample was read, and the findings
  are true. Most are error exits: a `RETURN ... AT END GO TO
  RETURN-ERROR` inside a performed section, where RETURN-ERROR reports
  the failure and jumps to the end of the sort's output procedure. The
  others are in the segmentation tests (SG102A), which leave performed
  sections on purpose.
- **PLB-C030 value-never-used.** Every finding was read. All 12 are
  true: a status copied twice in a row, a feature name replaced by the
  next test's before it is printed, a value moved and then computed
  over. Two false findings were fixed on the way: `MOVE CORRESPONDING`
  counted as replacing a whole group, and a store to an `OCCURS
  DEPENDING ON` count, which a later `MOVE` to the table's group
  reads.
- **PLB-C031 string-overflow.** All 6 are in NC217A, which tests
  `STRING` overflowing its receiver without `ON OVERFLOW` and checks
  the truncated result.
- **PLB-C008 move-truncation.** A sample was read. Literal truncations
  are true once trailing spaces are not counted (`"WRITE NOT INVALID
  END-"` into a 20-character FEATURE loses `D-`). Numeric findings
  report a MOVE whose receiver has fewer integer digits than the
  sender. The suite does this on purpose to display results.
- **PLB-C036 arithmetic-overflow.** 31 findings, a sample read. The
  operands are declared wider than the values they hold: `DNAME-10`
  is `PIC 9(18) VALUE 1` and is added into a `PIC 9(17)` total, and
  the indexed-file tests subtract a `PIC 9(6)` counter from a `PIC
  9(3)` count. With the values the tests give them, none of the
  sample can overflow; each is the case the rule documents, where the
  declarations allow what the values do not.

- **PLB-C037 search-index-not-set.** One finding: `NC401M`, a test of
  the compiler's flagging of non-standard code, searches `TEST-CODE`
  without ever setting `CODE-INDEX`. Of the suite's 107 serial
  searches, the first version of the rule, which read only the
  `SEARCH`'s own paragraph, reported 71; the suite sets the index in an
  `-INIT` paragraph that falls into or goes to the test paragraph, and
  the rule now follows that step.

- **PLB-C041 write-from-truncation.** 9 findings, all read. Each
  loses the end of its `FROM` area, and in each the suite means it.
  SQ117A ("the rightmost 7 characters should be truncated in the output
  record") and SQ116A, for `REWRITE`, test the truncation itself;
  SQ106A writes its short, 120-byte record type from the 151-byte
  buffer it also writes long records from (3); SQ212A and SQ224A write
  2117- and 2065-byte areas into a variable record of at most 2048. In
  IX207A (2) the record is 192 bytes, because the fields that would
  make the 240 of its `RECORD CONTAINS` clause are commented out. A
  first version also reported `READ ... INTO` a shorter item: 17 more
  in NIST, and in CardDemo the 80-byte date parameter card read into a
  21-byte area, which is meant.

- **PLB-C042 inspect-count-not-reset.** None. Reading only the
  `INSPECT`'s own paragraph reported 72: the suite sets each count to
  zero in an `-INIT` paragraph that falls into the test paragraph, and
  the rule follows that step, as PLB-C037 does.
- **PLB-C044 varying-control-changed.** Two, both in NC201A's test of
  a `PERFORM VARYING` whose body divides and subtracts its own control
  on purpose.
- **PP008, a REPLACING rule that replaces nothing.** Six, all in tests
  of `COPY ... REPLACING` whose expected results need the rule to
  replace nothing: replaced text is not scanned again (SM206A), a
  continued literal is one literal (SM206A), a debugging line is a
  comment (SM206A), the copybook lacks the name (SM201A), and a literal
  pattern only matches a whole literal (SM401M). A seventh,
  `==+00001==` in SM206A, was Plumbline reading the sign of a pseudo-text
  pattern as an operator, fixed before this diagnostic was added.
- **PLB-C049 loop-condition-unchanged.** One: NC401M, the flagging test
  again, performs `NC401M-NESTIF THRU NC401M-INIT WITH TEST AFTER UNTIL
  BOX-B IS EQUAL TO BOX-A`, and the two paragraphs set only `VARD` and
  `VARB`. The loop ends only because both boxes are zero when it starts.
  A first version also reported NC244A, whose condition subscripts with
  two indexes the performed paragraph moves with `SET ... DOWN BY`; a
  condition that names an index is now left alone.

- **PLB-C054 go-to-into-perform-range.** 19, in tests that jump into
  other ranges on purpose: the segmentation tests `SG102A`, `SG202A`,
  and `SG203A`, and the sort tests `ST119A` and `ST127A`, whose second
  output procedure goes to `RETURN-ERROR` in the first's range. A first
  version also reported the standard `FAIL-ROUTINE`, whose `GO TO
  FAIL-ROUTINE-EX` stays within `FAIL-ROUTINE THRU FAIL-ROUTINE-EX`
  while `FAIL-ROUTINE-WRITE THRU FAIL-ROUTINE-EX` shares the exit; jumps
  within another range are now left out, and GnuCOBOL's tests have none.

- **PLB-C055 corresponding-no-match.** Two, of 89 `CORRESPONDING`
  statements, and both meant: `MOVE CORR B-LEVEL OF A-LEVEL TO B-SET`
  in `NC209A`, whose comment says "no moves should take place", and
  GnuCOBOL's test `add-corresponding-no-match`, a `SUBTRACT
  CORRESPONDING` whose namesakes are not numeric on both sides.

- **PLB-C056 self-comparison.** None in NIST or GnuCOBOL's tests.

- **PLB-C057 misleading-indentation.** 8, all in NIST and all as
  described: in `NC109M`, `PERFORM PRINT-DETAIL` sits under `MOVE ... TO
  RE-MARK.` at the depth of the `IF` body, and in `NC176A`, `ADD 1 TO
  REC-CT` follows the period of an `ELSE` branch at its depth. A first
  version also reported 12 cases of `IF ... GO TO X.` followed by
  indented code, the "else" style; an `IF` without `ELSE` whose body
  leaves is now left alone. GnuCOBOL's tests have none.

- **PLB-C058 read-not-handled.** None in NIST, whose `READ` statements
  all have `AT END` or `INVALID KEY`. 45 in 14 of GnuCOBOL's tests
  (46 in 15 before the tests GnuCOBOL expects to fail were left out;
  one of those, `turn-ec-i-o`, reads a file once too often on
  purpose). Most read back exactly the records they have just
  written.

- **PLB-C028 comparison-never-true**, for alphanumeric items compared
  with longer literals: none in NIST or in GnuCOBOL's tests.

- **PLB-C062 varying-subscript-out-of-range.** None in NIST or in
  GnuCOBOL's tests.

- **PLB-C063 varying-refmod-out-of-range.** None in NIST or in
  GnuCOBOL's tests.

- **PLB-C064 duplicate-condition-value.** None in NIST or in
  GnuCOBOL's tests.

- **PLB-C065 open-in-loop.** None in NIST or in GnuCOBOL's tests.

- **PLB-C068 odo-count-out-of-range.** None in NIST. 2 in GnuCOBOL's
  test `Value of DEPENDING ON N out of bounds`, which checks the
  run-time error on purpose: `MOVE 3 TO N` for a table of 4 to 6
  entries, and `VALUE 7` in its second program.

- **PLB-C071 contradictory-condition.** None in NIST or in GnuCOBOL's
  tests.

- **PLB-C072 unreachable-statement.** 2 in NIST, both in `NC102A`,
  which tests `GO TO` on purpose: `GO TO GO--PASS-F1-1` followed by
  `PERFORM FAIL`, which runs only if the `GO TO` does not jump. None in
  GnuCOBOL's tests. A first version reported 7 in NIST programs that
  `RECEIVE ... NO DATA ... GO TO`: the parser did not know the `NO DATA`
  phrase, so its `GO TO` stood beside the `RECEIVE`; it now parses the
  phrase. It also reported 16 in GnuCOBOL's tests of `ENTRY` and of
  `ENTRY FOR GO TO`, where a caller or a `GO TO ENTRY` comes in after a
  `GOBACK`, `STOP RUN`, or `GO TO`; those are no longer reported.

- **PLB-C073 value-ignored.** None in NIST. 1 in GnuCOBOL's tests, in
  `dump feature with NULL address`: a linkage record `A-TABLE` with
  `VALUE` clauses that the program never allocates or initializes. A
  first version reported 3 more, in tests that give linkage and `BASED`
  items their values with `ALLOCATE ... INITIALIZED` and `INITIALIZE
  ... ALL TO VALUE`; those statements now exempt the record.

- **PLB-C069 search-index-used-unchecked.** None in NIST or in
  GnuCOBOL's tests: their `SEARCH` statements have `AT END`, or do not
  use the index after it.

- **PLB-C067 divisor-not-checked** (off by default). Enabled, 37 in 7
  NIST programs, which set their divisors to known values in ways the
  rule does not follow: a table filled by a performed paragraph, an
  item with a `VALUE` that other tests change. 5 in one of GnuCOBOL's
  tests, `sample-payroll-report`, which divides by Report Writer `SUM`
  totals in a declarative: with no detail lines, they are zero.

- **PLB-C066 identical-branches.** 2 in NIST, in `NC174A` and `NC254A`,
  which test `IF ... NEXT SENTENCE ELSE NEXT SENTENCE` on purpose: both
  branches do the same. None in GnuCOBOL's tests.

- **PLB-C061 unchecked-numeric-move** (off by default). Enabled, 6 in
  NIST, in tests of moves between categories (`NC104A` moves
  `MOVE50` to numeric items to see what they hold).

- **PLB-M020 constant-condition.** None in NIST. 8 in 4 of GnuCOBOL's
  tests, which compare constants on purpose: of the bit and hex
  functions, of abbreviated conditions, and of comparisons under the
  default collating sequence.

- **PLB-C060 spaces-into-numeric.** One, in GnuCOBOL's test
  `compare-numeric-display-space-with-zero`, which compares numeric
  items holding spaces on purpose. None in NIST, after two changes: a
  first version reported `MOVE SPACE TO TEST-RESULTS` followed by
  `DISPLAY TEST-RESULTS`, a print line whose numeric `DISPLAY` items
  only show blanks, and `NC252A`, which gives the item its value
  through a `RENAMES` item. A version that reported every `MOVE SPACES`
  to a group with packed items, without following the paragraph,
  reported 9 cases in GnuCOBOL's tests that clear a record and then read
  into it or fill it.

- **PLB-C059 key-error-not-handled.** None in NIST. 42 in 13 of
  GnuCOBOL's tests of indexed and relative files, which write and
  rewrite keys they know are free or present.

## Limits

- **Report Writer** is parsed and its `SOURCE`, `SUM`, and `CONTROL`
  operands count as reads, but the layout clauses (`LINE`, `COLUMN`,
  `NEXT GROUP`) are not checked against each other or the page limits.
- **Segmentation** (section priority numbers) is read but not modeled.
  It does not change which code can run.
- **EXEC85 substitutions** are not made, so names such as `XXXXX031` stay
  undefined. Plumbline analyzes the suite as distributed rather than as
  any one compiler's variant of it.
