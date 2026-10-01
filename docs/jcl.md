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
