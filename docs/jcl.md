# JCL

Batch COBOL programs run as steps of JCL jobs, and a job step gives a
program its files: each `SELECT ... ASSIGN TO name` finds its data set
through the step's `DD` statement of that name. Plumbline reads JCL so
that programs can be checked against the jobs that run them.

## Reading JCL

`plumbline dump jcl FILE...` shows what Plumbline reads from JCL files:
jobs, procedure definitions, their steps and what each step runs, and
each step's `DD` statements.

```console
$ plumbline dump jcl app/jcl/POSTTRAN.jcl
app/jcl/POSTTRAN.jcl:1: job POSTTRAN
app/jcl/POSTTRAN.jcl:23:   step STEP15 pgm CBTRN02C
app/jcl/POSTTRAN.jcl:24:     dd STEPLIB dsn AWS.M2.CARDDEMO.LOADLIB disp SHR
app/jcl/POSTTRAN.jcl:26:     dd SYSPRINT sysout
app/jcl/POSTTRAN.jcl:28:     dd TRANFILE dsn AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS disp SHR
...
```

The reader follows the rules of z/OS JCL:

- A statement starts with `//` in columns 1 and 2. A name starts in
  column 3; the operation and the operands follow, and the operands end
  at the first blank outside quotes. The rest of the line, and columns
  72 to 80, are comments.
- A statement continues on the next `//` line when its operands end with
  a comma, or when a quoted string runs to column 71; it then goes on in
  column 16.
- `//*` lines are comments, and `//` alone ends a job.
- `DD *` and `DD DATA` are followed by in-stream data, which ends at
  `/*`, at the delimiter that `DLM=` names, or, for `DD *`, at the next
  `//` line.
- `PROC` starts a procedure, which `PEND` ends when it is in-stream. A
  step runs a program (`EXEC PGM=name`) or a procedure (`EXEC
  PROC=name`, or `EXEC name`). A `DD` named `STEP.DDNAME` in a job
  overrides or adds to step `STEP` of the procedure the job step runs.
- A `DD` without a name concatenates its data set to the one before it,
  and is shown as part of it. `DD` statements before a job's first step
  (`JOBLIB`, `JOBCAT`) belong to no step.

A step whose program starts another one records the program it runs:
IMS's `DFSRRC00` names it in `PARM='BMP,name,...'`, and the TSO batch
program `IKJEFT01` runs a DB2 program named in `RUN PROGRAM(name)` in
its `SYSTSIN` input. `dump jcl` shows it as `runs name`, and the steps
are checked against that program.

Symbolic parameters (`&HLQ`) are not substituted, and `INCLUDE`,
`JCLLIB`, `SET`, `IF`, and `OUTPUT` statements are read and passed over.

## Checking programs against their JCL

Give `check` the JCL with the programs, and the steps are checked
against the programs they run (see the [J rules](rules.md#plb-j001-dd-missing)):

```console
$ plumbline check app/cbl/*.cbl app/jcl/*.jcl
app/jcl/CBIMPORT.jcl:22:3: error: step STEP01 has no DD CARDOUT for file CARD-OUTPUT, which CBIMPORT opens [PLB-J001]
```

Files named `*.jcl` or `*.prc`, in either case, are read as JCL; every
other input is COBOL. A step's program is matched to a program of the
run by name, and the programs it calls are followed through the call
graph, so a file opened by a called subprogram also needs its DD in
the step.

## Drawing the jobs

`plumbline graph --kind jobs` draws which jobs and procedures run which
programs, with each step as an edge labelled with the step's name.
Jobs are named `NAME (job)` and procedures `NAME (proc)`, since a job
is often named after its program; programs that are not among the
inputs, such as utilities, are drawn dashed.

```console
$ plumbline graph --kind jobs app/cbl/*.cbl app/jcl/*.jcl | dot -Tsvg -o jobs.svg
```

## Drawing the data

`plumbline graph --kind datasets` draws which job steps read and write
which data sets: the data each job leaves for the next. A step is
named `JOB.STEP`, or `PROC.STEP` for a step of a procedure; a DD a job
adds to its procedure's step (`PSTEP.DDNAME`) belongs to the job step.
Reads point from the data set to the step, writes from the step to the
data set; an update is drawn both ways.

```console
$ plumbline graph --kind datasets app/cbl/*.cbl app/jcl/*.jcl app/proc/*.prc
  ...
  "AWS.M2.CARDDEMO.DALYTRAN.PS" -> "POSTTRAN.STEP15" [label="DALYTRAN"];
  "POSTTRAN.STEP15" -> "AWS.M2.CARDDEMO.DALYREJS" [label="DALYREJS"];
  "POSTTRAN.STEP15" -> "AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS" [label="TRANFILE"];
```

Whether a step reads or writes comes first from its programs: the
`OPEN` statements of the files they assign to the DD (`INPUT` reads,
`OUTPUT` and `EXTEND` write, `I-O` updates). `POSTTRAN` above has
`DISP=SHR` on `TRANFILE`, but `CBTRN02C` opens it `OUTPUT`, so the step
writes it. For a program outside the run, the DD names of system
utilities decide (`SYSUT1`, `SORTIN` read; `SYSUT2`, `SORTOUT` write),
and then `DISP` (`SHR` reads, `NEW` and `MOD` write). What none of
these settles, such as an `IDCAMS` step with `DISP=OLD`, is drawn as a
dashed line without a direction.

A relative generation is dropped from the name, so that the
generation one job writes (`DALYREJS(+1)`) and the one the next reads
(`DALYREJS(0)`) are the same data set. A temporary data set (`&&NAME`)
is named with its job, as it ends with the job. Load libraries
(`STEPLIB`, `JOBLIB`) are left out.

## Impact

`plumbline impact PROGRAM` lists the job steps that run the program,
or run a program that calls it, when the JCL is among the inputs:

```console
$ plumbline impact PAYLOG src/*.cbl jcl/*.jcl
program PAYLOG src/paylog.cbl:3
  called by PAYUPD at src/payupd.cbl:35 directly
  run by step UPDATE of job PAYROLL at jcl/payroll.jcl:4 through PAYUPD
```

`plumbline impact DSN` lists the job steps that write, update, read, or
use a data set, in the order of the JCL, with the DD that names it and
what the access is known from, as in the data set graph. A relative
generation in DSN is ignored:

```console
$ plumbline impact 'PAY.HISTORY(0)' jcl/sortgdg.jcl
data set PAY.HISTORY
  read by SORTGDG.SORT through DD SORTIN at jcl/sortgdg.jcl:6 (from the DD name; the step runs SORT)
  written by SORTGDG.COPY through DD SYSUT2 at jcl/sortgdg.jcl:13 (from the DD name; the step runs IEBGENER)
```
