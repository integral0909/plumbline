//STEPS1   JOB (ACCT),'REPEATED STEP'
//* EXTRACT is the name of two steps of this job.
//EXTRACT  EXEC PGM=IEFBR14
//SORT     EXEC PGM=IEFBR14
//EXTRACT  EXEC PGM=IEFBR14
//* A procedure's steps are named apart from the job's.
//COPYPROC PROC
//EXTRACT  EXEC PGM=IEFBR14
//COPY     EXEC PGM=IEFBR14
//COPY     EXEC PGM=IEFBR14
//         PEND
//RUNPROC  EXEC COPYPROC
//STEPS2   JOB (ACCT),'ANOTHER JOB'
//* Another job may use the same names.
//EXTRACT  EXEC PGM=IEFBR14
//SORT     EXEC PGM=IEFBR14
