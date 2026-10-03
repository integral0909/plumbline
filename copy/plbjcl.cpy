*> plbjcl.cpy: the jobs, steps, and data definitions of JCL files.
*>
*> PLB-JCL-READ appends one JCL file at a time, so that a run can
*> hold the JCL of a whole application next to its programs. Names
*> (job, step, program, procedure, DD) are kept in upper case, as JCL
*> writes them.
*>
*> A step runs a program (EXEC PGM=) or a procedure (EXEC PROC= or
*> EXEC name). Procedures are defined in a JCL file of their own, or
*> in-stream between PROC and PEND; their steps have JS-PROC set. A DD
*> written as STEP.DDNAME in a job overrides or adds to step STEP of
*> the procedure the job step runs: JD-QUALIFIER holds STEP.
*>
*> The limits are in plbjclc.cpy, which a program copies once.
01  PLB-JCL.
    05  JJ-COUNT                PIC 9(9) COMP-5.
    05  JJ-ENTRY                OCCURS JJ-MAX TIMES.
        10  JJ-NAME             PIC X(8).
        10  JJ-FILE-ID          PIC 9(4) COMP-5.
        10  JJ-LINE             PIC 9(9) COMP-5.
    *> Procedure definitions: PROC statements.
    05  JP-COUNT                PIC 9(9) COMP-5.
    05  JP-ENTRY                OCCURS JP-MAX TIMES.
        10  JP-NAME             PIC X(8).
        10  JP-FILE-ID          PIC 9(4) COMP-5.
        10  JP-LINE             PIC 9(9) COMP-5.
        *> "Y" between PROC and PEND in a job.
        10  JP-INSTREAM         PIC X.
    05  JS-COUNT                PIC 9(9) COMP-5.
    05  JS-ENTRY                OCCURS JS-MAX TIMES.
        *> The job, or the procedure, the step is in (0: none).
        10  JS-JOB              PIC 9(9) COMP-5.
        10  JS-PROC             PIC 9(9) COMP-5.
        10  JS-NAME             PIC X(8).
        *>   P runs a program   R runs a procedure
        10  JS-KIND             PIC X.
        *> The program or procedure, as named.
        10  JS-TARGET           PIC X(8).
        *> For a step whose program starts another one: the program it
        *> runs. IMS's DFSRRC00 names it in PARM='BMP,name,...'; the
        *> TSO batch program IKJEFT01 runs DB2 programs named in RUN
        *> PROGRAM(name) in its SYSTSIN input.
        10  JS-INNER            PIC X(8).
        *> For DFSRRC00, the PSB it schedules (PARM='BMP,name,PSB').
        10  JS-PSB              PIC X(8).
        10  JS-FILE-ID          PIC 9(4) COMP-5.
        10  JS-LINE             PIC 9(9) COMP-5.
        *> The step's DD statements: JS-DD-COUNT entries from
        *> JS-DD-FIRST.
        10  JS-DD-FIRST         PIC 9(9) COMP-5.
        10  JS-DD-COUNT         PIC 9(9) COMP-5.
    05  JD-COUNT                PIC 9(9) COMP-5.
    05  JD-ENTRY                OCCURS JD-MAX TIMES.
        10  JD-STEP             PIC 9(9) COMP-5.
        10  JD-NAME             PIC X(8).
        *> STEP of a STEP.DDNAME override, or spaces.
        10  JD-QUALIFIER        PIC X(8).
        *> What the DD gives the program:
        *>   D a data set (JD-DSN)   S SYSOUT   M DUMMY
        *>   I in-stream data (* or DATA)   O something else
        10  JD-KIND             PIC X.
        10  JD-DSN              PIC X(44).
        *> The first DISP subparameter (NEW, OLD, SHR, MOD), or spaces;
        *> the second, the normal disposition (CATLG, KEEP, DELETE,
        *> PASS, UNCATLG), or spaces.
        10  JD-DISP             PIC X(3).
        10  JD-NORMAL           PIC X(7).
        *> "Y" for a DD without a name, which concatenates its data
        *> set to the DD before it; it has that DD's name.
        10  JD-CONCAT           PIC X.
        *> LRECL and RECFM, given as keywords or in DCB=( ): 0 and
        *> spaces when the DD gives none (or a symbol).
        10  JD-LRECL            PIC 9(9) COMP-5.
        10  JD-RECFM            PIC X(4).
        10  JD-FILE-ID          PIC 9(4) COMP-5.
        10  JD-LINE             PIC 9(9) COMP-5.
