# Plumbline

Plumbline is a static analyzer for COBOL, written in COBOL.

It reads COBOL source (fixed or free format, with COPY expansion), builds
control-flow and data-flow models of each program, and reports defects such
as unreachable paragraphs, PERFORM fall-through, truncating MOVEs, and
uninitialized fields. Findings can be emitted as text, JSON, SARIF, HTML,
Markdown, or GitLab's code quality format.

> **Status:** in development, before a first release. The front end
> (reader, preprocessor, lexer, parser), the symbol table, the procedure
> graph, data flow, and the rule engine work, with more than a hundred
> rules (`plumbline rules` lists them) for COBOL, embedded SQL, CICS,
> IMS, JCL, and BMS. Each rule is run over the NIST COBOL-85 test
> suite, GnuCOBOL's own tests, and AWS's CardDemo application, and what
> it reports there is read (see [docs/corpus.md](docs/corpus.md)). See
> [docs/architecture.md](docs/architecture.md) for the design.

## Building

Plumbline needs GnuCOBOL 3.2 and GNU make.

```sh
make                        # builds build/bin/plumbline
make test                   # runs all test suites
make coverage               # COBOL statement coverage (LCOV)
build/bin/plumbline --help
```

## Usage

```console
$ plumbline check -I copybooks src/*.cbl
src/payroll.cbl:118:8: warning: paragraph CALC-OVERTIME is never executed [PLB-C001]
```

Findings go to standard output as `file:line:column: severity: message
[rule]`, and problems reading the input go to standard error. The exit
code is 1 when there are findings at or above the `--fail-on` level
(`warning` by default), so `plumbline check` can gate a build.

A whole source tree can be checked in one run, which also checks the
calls between its programs. `check` holds one program's source at a
time and takes up to 10,000 files:

```console
$ find src -name '*.cbl' | plumbline check -I copybooks --files-from -
```

| Option | Meaning |
|--------|---------|
| `-I DIR` | search `DIR` for copybooks (repeatable) |
| `--files-from LIST` | also analyze the files listed in `LIST`, one per line (`-` for standard input) |
| `-D NAME`, `--define NAME` | `NAME` is defined for conditional compilation |
| `--tab-width N` | tab stops every `N` columns (default 8), as `cobc -ftab-width` |
| `--format fixed\|free\|auto` | reference format of the sources (default `auto`) |
| `--enable RULE`, `--disable RULE` | turn a rule on or off, by id or name |
| `--fail-on error\|warning\|note\|never` | the lowest severity that fails the run |
| `--report text\|json\|sarif\|html\|md\|codeclimate\|junit\|checkstyle` | output format (default `text`) |
| `--baseline FILE` | do not report the findings listed in `FILE` |
| `--write-baseline FILE` | write the findings to `FILE` instead of reporting them |
| `--config FILE`, `--no-config` | read settings from `FILE`, or from no file |

`--report sarif` writes SARIF 2.1.0, which code-scanning services and
many editors read directly; `--report json` writes a simpler document
with one finding per line; `--report html` writes one self-contained
page with each finding's source lines, to open in a browser or keep as
a build artifact; `--report md` writes Markdown, a summary with tables
of the findings by rule and of the findings themselves, for a CI job
summary or a pull request comment:

```console
$ plumbline check --report md --fail-on never src/*.cbl >> "$GITHUB_STEP_SUMMARY"
```

`--report codeclimate` writes the Code Climate issues that GitLab shows
in a merge request's code quality widget. Each issue has a fingerprint
from the rule, the file, the message, and the text of the reported
line, not its number, so GitLab sees a finding as the same one after
lines are added above it, and reports only the findings a change brings
in or removes:

```yaml
plumbline:
  script:
    - plumbline check --report codeclimate --fail-on never src/*.cbl > gl-code-quality.json
  artifacts:
    reports:
      codequality: gl-code-quality.json
```

`--report junit` writes a JUnit XML test report, which Jenkins, GitLab,
Azure DevOps, and most other CI servers show with their test results:
each finding is a failing test case named after its rule and place,
each error diagnostic a test case in error, and each file checked
without either a passing one.

```console
$ plumbline check --report junit --fail-on never src/*.cbl > plumbline-junit.xml
```

`--report checkstyle` writes Checkstyle XML, the format that review
tools such as reviewdog and CI plugins such as Jenkins Warnings NG read
from many linters: a `file` element for each file checked, with an
`error` for each finding and diagnostic (severity `error`, `warning`,
or `info` for notes, and source `plumbline.PLB-C001`).

In all of them, input diagnostics are part of the report rather than
printed to standard error.

See the [rule reference](docs/rules.md) for what each rule looks for.
`plumbline rules` lists the rules with their severity and whether they
are on, after `plumbline.conf` and the options are applied
(`--report json` for tools).

The `dump` commands show Plumbline's view of a program at each stage,
which helps when a result is surprising: `dump lines`, `dump tokens`,
`dump expanded`, `dump ast`, `dump symbols`, `dump flow`, `dump refs`,
`dump calls`, `dump sql` (the tables, cursors, and host variables of
embedded SQL), and, for JCL, CICS maps, CICS resource definitions, and
IMS definitions, `dump jcl`, `dump bms`, `dump csd`, and `dump ims` (see
[JCL](docs/jcl.md), [BMS](docs/bms.md), [CICS](docs/cics.md), and
[IMS](docs/ims.md)).

Give `check` all the programs that call each other in one run. Calls
between them are then checked against the programs they call: the
number of arguments, how they are passed, and their sizes.

## Metrics

`plumbline metrics` reports the size and complexity of each program and
of its paragraphs and sections:

```console
$ plumbline metrics src/payroll.cbl
program PAYROLL src/payroll.cbl:2
  lines 412 (code 318, comment 81, blank 13)
  statements 245, sections 4, paragraphs 31, data items 120
  complexity 57, deepest nesting 4, GO TO 12, PERFORM 40, CALL 3
  paragraph MAIN-LINE line 61: 12 statements, complexity 3, nesting 2, 18 lines
  ...
```

Complexity is McCabe's: one plus each decision (IF, WHEN, a looping
PERFORM, a conditional phrase such as AT END, AND and OR in conditions,
and the targets of GO TO DEPENDING ON). `--report json` and
`--report csv` give the same figures for other tools and spreadsheets.

## Graphs and impact

`plumbline graph` draws how a program's paragraphs perform and jump to
each other, which programs call which, which files include which
copybooks, which JCL jobs run which programs, which job steps read
and write which data sets, how CICS transactions, programs, maps, and
files connect, or which programs create, read, update, and delete
which tables and files, as Graphviz DOT (or JSON with `--report
json`):

```console
$ plumbline graph src/payroll.cbl | dot -Tsvg -o payroll.svg
$ plumbline graph --kind calls src/*.cbl | dot -Tsvg -o calls.svg
$ plumbline graph --kind copybooks -I copybooks src/*.cbl > copies.dot
$ plumbline graph --kind jobs src/*.cbl jcl/*.jcl > jobs.dot
$ plumbline graph --kind datasets src/*.cbl jcl/*.jcl > datasets.dot
$ plumbline graph --kind cics src/*.cbl csd/*.csd > cics.dot
$ plumbline graph --kind crud -I copybooks src/*.cbl > crud.dot
```

`plumbline impact` answers the question before a change: what does it
reach?

```console
$ plumbline impact CUSTREC -I copybooks src/*.cbl
copybook copybooks/custrec.cpy
  included by copybooks/custio.cpy directly
  included by src/billing.cbl directly
  included by src/custlook.cbl through copybooks/custio.cpy
$ plumbline impact CUSTLOOK src/*.cbl
program CUSTLOOK src/custlook.cbl:2
  called by BILLING at src/billing.cbl:8 directly
  called by MENU at src/menu.cbl:5 through BILLING
$ plumbline impact CUST-ID -I copybooks src/*.cbl
data item CUST-ID
  declared at copybooks/custrec.cpy:3:16 in CUSTLOOK, level 5
  set at src/custlook.cbl:10:26 in CUSTLOOK, MOVE
  ...
```

For a program, the job steps that run it are listed too when the JCL is
among the inputs. For a data item, every declaration of that name and
every statement that reads it, sets it, or passes it on, in each
program of the run. For a data set, the job steps that write, update, and
read it, and what that is known from:

```console
$ plumbline impact AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS app/cbl/*.cbl app/jcl/*.jcl
data set AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS
  read by CBEXPORT.STEP02 through DD TRANSACT at app/jcl/CBEXPORT.jcl:55 (from OPEN; the step runs CBEXPORT)
  written by POSTTRAN.STEP15 through DD TRANFILE at app/jcl/POSTTRAN.jcl:28 (from OPEN; the step runs CBTRN02C)
  ...
```

## Formatting

`plumbline format` rewrites a file in fixed or free reference format,
without changing a single token:

```console
$ plumbline format --to free src/payroll.cbl > payroll-free.cob
$ plumbline format --to fixed --check src/*.cbl     # exit 1 if any would change
```

To free format, it drops the sequence and identification areas, turns
comment lines into `*>` comments, and joins continued lines. To fixed
format, it fits code into columns 8-72. Headers and record entries go
in area A, long lines are split at spaces, long literals are continued
with `-` in column 7, and inline comments that do not fit move to a
line of their own.

## Record layouts

`plumbline layout` lists the records of programs and copybooks with
each item's level, picture, usage, start position, length, and OCCURS
count, as text, JSON, CSV, or a Markdown table: the layout a file
transfer or a program in another language needs.

```console
$ plumbline layout copybooks/order.cpy
record ORDER-RECORD copybooks/order.cpy:3, 59 bytes
  level name                            picture         usage           start  length  occurs
  01    ORDER-RECORD                                                        1      59
  05    ORDER-KEY                                                           1      10
  10    ORDER-REGION                    X(2)                                1       2
...
  05    ORDER-AMOUNT                    S9(9)V99        COMP-3             12       6
```

## Copybook fields

`plumbline fields` lists the data items of each copybook of the run and
how many of the programs that copy it name each one: in a statement,
through a condition name or a subordinate item, as a file's key or
status, or as an `OCCURS DEPENDING ON` object. Items that no program
names, which only travel with their record, are the ones to look at
before a copybook is changed or a file converted. `--unused` lists only
those, and `--report json` gives the counts as JSON.

```console
$ plumbline fields --unused -I app/cpy app/cbl/*.cbl
copybook app/cpy/CVTRA06Y.cpy: 14 items, 1 named by no program; copied by 2
  05 DALYTRAN-PROC-TS                line 17, named by no program
...
```

## Cross-reference

`plumbline xref` lists, for each program, its data items and its
paragraphs and sections, each with the line that defines it and every
line that names it, as a compiler's cross-reference listing does. An
`M` marks a statement that changes the item; procedure references are
marked `P` (PERFORM), `T` (the end of a PERFORM THRU range), `G` (GO
TO), or `A` (ALTER). Definitions and references in a copybook name the
copybook. `--report json` gives each reference with its file, line,
column, and use.

```console
$ plumbline xref -I app/cpy app/cbl/CBACT02C.cbl
CBACT02C (app/cbl/CBACT02C.cbl:23)
  Data items
...
    01 IO-STATUS (50)
        111M 130M 148M 162 171
    05 IO-STAT1 (51)
        163 164
...
```

The references are those of the procedure division: an item named only
in a data division clause, such as `FILE STATUS`, shows none.

## CRUD matrix

`plumbline crud` lists which programs create, read, update, and delete
which DB2 tables, COBOL files, and CICS files:

```console
$ plumbline crud -I app/cpy app/cbl/*.cbl
COACTUPC  cics-file  ACCTDAT                                     - R U -
COTRTUPC  table      CARDDEMO.TRANSACTION_TYPE                   C R U D
CBTRN02C  file       TCATBAL-FILE                                C R U -
...
```

Tables count `INSERT`, `SELECT` and cursors, `UPDATE`, and `DELETE`;
COBOL files `WRITE`, `READ` and `START`, `REWRITE`, and `DELETE`, a
`WRITE` or `REWRITE` through the FD of its record; CICS files the
`WRITE`, `READ` (and browsing), `REWRITE`, and `DELETE` commands, by
their `FILE` or `DATASET`, which may be an item whose `VALUE` names the
file. `--report csv` and `--report json` give the same rows for a
spreadsheet or a tool.

## Data lineage

`plumbline lineage NAME` shows where a data item's value comes from:
each statement that gives it a value (or gives one to a group it is in,
or to an item in it), the items that statement reads, the statements
that give those their values, and so on, three statements deep by
default (`--depth N`). A record of a file goes back to the `READ` of
the file. `--forward` shows where the value goes instead: the
statements that read the item and the items they give values to.

```console
$ plumbline lineage WS-TOTAL src/rpt.cob
WS-TOTAL  src/rpt.cob:15
  ADD WS-AMOUNT WS-TAX TO WS-TOTAL  (line 23)
    WS-AMOUNT  src/rpt.cob:13
      MOVE IN-AMT TO WS-AMOUNT  (line 21)
        IN-AMT  src/rpt.cob:11
          READ IN-FILE  (line 20)
    WS-TAX  src/rpt.cob:14
      COMPUTE WS-TAX = WS-AMOUNT * 0.25  (line 22)
        WS-AMOUNT  src/rpt.cob:13  (see above)
```

An item already shown is not expanded again. The statements followed
are those of one program; where the trail crosses a `CALL` to another
program of the run, the line below names the other side. Backward, an
item of the `LINKAGE SECTION` lists the argument each call to its
program passes in its place; forward, a `CALL` lists the parameter of
the program called that the item becomes:

```console
$ plumbline lineage LK-CUST-NAME src/billing.cob src/custlook.cob
LK-CUST-NAME  src/custlook.cob:6
  <- argument 2 of CALL "CUSTLOOK" in BILLING  src/billing.cob:9: CUST-NAME
  MOVE LK-CUST-ID TO LK-CUST-NAME  (line 8)
    LK-CUST-ID  src/custlook.cob:5
      <- argument 1 of CALL "CUSTLOOK" in BILLING  src/billing.cob:9: CUST-ID
```

Run `lineage` on the named item to follow it into the other program.
Embedded SQL is where a trail meets the database: an item that a
`SELECT ... INTO` or `FETCH` gives its value names the column it comes
from (`<- column BALANCE of ACCOUNT`, the table of a `FETCH` taken from
its cursor), and, forward, an item that `INSERT` or `UPDATE` stores
names its column (`-> column BALANCE of ACCOUNT`). `EXEC CICS` commands
are shown the same way: `READ`, `RECEIVE`, `READQ`, and `GET` with
`INTO` an item name the file, map, queue, or container the value comes
from (`<- CICS READ of file "ACCTDAT"`, or `of file LIT-ACCTFILE
("ACCTDAT")` for an item with that `VALUE`), and `WRITE`, `REWRITE`,
`SEND`, `WRITEQ`, and `PUT` with `FROM` it, forward, where it goes. A
file is where the trail leaves for good. `--report json` gives the tree
as a list of nodes (items, statements, calls, columns, and CICS
resources), each with its id and its parent's; a call node gives the
side (`caller` or `callee`), the other program, the position, and the
item there, a column node the table and the column, and a CICS node
the command, the kind of resource, and its name. `--report dot` draws
the trails as one Graphviz graph, each item and statement once, with
the arrows the way the values go:

```console
$ plumbline lineage WS-NEW-BALANCE --report dot src/acct.cob | dot -Tsvg > lineage.svg
```

## Duplicate code

`plumbline duplicates` finds paragraphs with the same code, in one
program or across all the programs of the run: a fix made in one copy
is easily missed in the others. Two paragraphs are the same when their
bodies have the same tokens, words compared without regard to case;
layout and comments do not count, literals and names do. Groups are
listed from the largest paragraph down; `--min-tokens N` sets the
smallest body counted (50 by default, which leaves out the short
paragraphs every program has), and `--report json` gives the groups as
JSON.

```console
$ plumbline duplicates src/*.cbl
2 copies of 230 tokens, 58 statements:
  src/RL115A.cob:644 REL-TEST-010-3 in RL115A
  src/RL204A.cob:569 REL-TEST-010-3 in RL204A
...
```

## Inventory

`plumbline inventory` describes an application: each program with what
starts it (job steps, CICS transactions, callers, menus that name it)
and what it uses (calls, files and their DD names, maps, CICS
resources), then the jobs, transactions, and maps. Give it the
programs with their JCL, BMS maps, and CICS definitions; `--report
json` gives the same as JSON.

```console
$ plumbline inventory app/cbl/*.cbl app/jcl/*.jcl app/bms/*.bms app/csd/*.csd
programs: 44
program CBTRN02C batch app/cbl/CBTRN02C.cbl:23
  run by step STEP15 of job POSTTRAN
  file DALYTRAN-FILE dd DALYTRAN input
...
```

## Program documentation

`plumbline doc` writes a Markdown page for each program: what starts
it and what it uses (as in the inventory), the data sets the job steps
running it give it, the tables and files it creates, reads, updates,
and deletes (as in `plumbline crud`), its paragraphs and sections
with their size, complexity, what they perform and go to, and whether
they can run at all, and its records with the layout of each item.
Give it the same inputs as the inventory.

```console
$ plumbline doc -I app/cpy app/cbl/CBACT01C.cbl app/jcl/*.jcl
# CBACT01C

Kind: **batch**. Source: `app/cbl/CBACT01C.cbl:23`.

## How it starts

- run by step STEP05 of job READACCT

## What it uses

- calls COBDATFT
- file ACCTFILE-FILE dd ACCTFILE input
...
## Paragraphs

405 lines, 190 statements, complexity 29.

| Paragraph | Lines | Statements | Complexity | Performs | Goes to | Runs |
|---|---:|---:|---:|---|---|---|
| 1350-WRITE-ACCT-RECORD | 10 | 7 | 3 | 9910-DISPLAY-IO-STATUS, 9999-ABEND-PROGRAM |  | yes |
...
```

A nested program gets a page of its own, which names the program
containing it and the calls into and out of it. With more than one
program, the output starts with an index of them, linked to their
pages.

## Editors

`plumbline lsp` is a language server, so editors that speak the Language
Server Protocol can show findings as you type, with an outline, go to
definition, hover, find references, highlights, folding, expand
selection, rename, call hierarchy, semantic highlighting, and quick
fixes that suppress a finding. See [Using Plumbline in an editor](docs/editors.md).

## Configuration

Settings that a project always uses go in `plumbline.conf` in the
directory `plumbline` runs in, one per line:

```
# plumbline.conf
include copybooks
format fixed
enable alnum-narrowing
disable go-to
severity move-truncation error
fail-on error
baseline plumbline.baseline
```

`include`, `format`, `enable`, `disable`, `fail-on`, `report`,
`define`, `tab-width`, and `baseline` work like the options of the
same names. `severity RULE
LEVEL` reports a rule as `error`, `warning`, or `note`, and `limit RULE
N` sets the threshold of a rule that measures something, such as
`limit complex-paragraph 20`. Options given on
the command line are applied after the file, so they override it. Paths
in the file are relative to the directory `plumbline` runs in.

## Conditional compilation

Plumbline follows `>>IF`, `>>ELIF`, `>>ELSE`, and `>>END-IF`, and Micro
Focus `$IF`, `$ELSE`, and `$END`, when the condition is one it can
decide: `NAME [IS] [NOT] DEFINED` or `NAME [IS] [NOT] SET`. A name is
defined by `>>DEFINE` or `$SET CONSTANT` earlier in the file, or by
`--define NAME` (`define NAME` in `plumbline.conf`) for the whole run.
The lines of a branch that is not compiled are left out of the
analysis; `plumbline dump lines` shows them as `skipped`. When a
condition is anything else, such as a comparison of values, every
branch is analyzed, as if each were compiled.

## Adopting Plumbline in existing code

An established code base has findings that nobody will fix this week. A
baseline records them, so that `check` fails only on new ones:

```console
$ plumbline check --write-baseline plumbline.baseline src/*.cbl
plumbline: wrote 214 findings to plumbline.baseline
$ plumbline check --baseline plumbline.baseline src/*.cbl
```

The baseline is a text file to commit along with the code. A finding
matches a baseline line when the rule, file, message, and the text of the
reported source line are the same. Line numbers are not part of it, so
editing other parts of a file does not bring old findings back. Fixing
a finding leaves a line that matches nothing. Write the baseline again
from time to time so that it shrinks, and give the files to `check`
with the same paths each time.

## Documentation

- [Rule reference](docs/rules.md)
- [Diagnostics](docs/diagnostics.md): problems reading the input, and limits
- [COBOL dialects](docs/dialects.md): what Plumbline reads, and what not
- [Using Plumbline in an editor](docs/editors.md)
- [Running Plumbline on the NIST COBOL-85 suite](docs/corpus.md)
- [Running Plumbline on GnuCOBOL's test suite](docs/corpus-gnucobol.md)
- [Running Plumbline on AWS CardDemo](docs/corpus-carddemo.md)
- [Architecture](docs/architecture.md)
- [Performance](docs/performance.md)
- [Testing](docs/testing.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Maintainers

- Fredrik Ahman ([@integral0909](https://github.com/integral0909))

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) and
[NOTICE](NOTICE).
