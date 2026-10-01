*> plbdset.cpy: the data sets of the JCL of a run, and which job steps
*> read and write them (PLB-DATASETS-COLLECT).
*>
*> A data set is named by its DSN without a relative generation, and a
*> temporary data set (&&NAME) with its job: "&&NAME (JOB)".
*> The limits are in plbdsetc.cpy, which a program copies once.
01  PLB-DATASETS.
    05  DS-COUNT                PIC 9(9) COMP-5.
    05  DS-NAME                 PIC X(60) OCCURS DS-MAX TIMES.
    *> One for each step, data set, and DD name.
    05  DE-COUNT                PIC 9(9) COMP-5.
    05  DE-ENTRY                OCCURS DE-MAX TIMES.
        *> The job step, or the step of a procedure, the DD is in.
        10  DE-STEP             PIC 9(9) COMP-5.
        *> The step whose program opens the DD: DE-STEP, or for a DD
        *> a job step adds to its procedure (PSTEP.DDNAME), that step
        *> of the procedure.
        10  DE-RUNS             PIC 9(9) COMP-5.
        10  DE-DATASET          PIC 9(9) COMP-5.
        *> The DD statement (plbjcl.cpy).
        10  DE-DD               PIC 9(9) COMP-5.
        *>   R read   W write   U update   ? not known
        10  DE-ACCESS           PIC X.
        *> Where the access comes from: P the programs' OPEN
        *> statements, T a utility's DD name, D the DISP, or space.
        10  DE-SOURCE           PIC X.
