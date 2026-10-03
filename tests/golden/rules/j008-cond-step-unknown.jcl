//* PLB-J008 cond-step-unknown: a COND test of a step that does not
//* run before the one tested.
//ACCTJOB  JOB (ACCT),'NIGHTLY',CLASS=A
//EXTRACT  EXEC PGM=IEFBR14
//* Fine: the extract step runs first.
//SORTX    EXEC PGM=IEFBR14,COND=(4,LT,EXTRACT)
//* Reported: no step is named EXTRCT.
//LOAD     EXEC PGM=IEFBR14,COND=(4,LT,EXTRCT)
//* Reported: REPORT runs after this step; the first test is fine.
//BACKUP   EXEC PGM=IEFBR14,COND=((8,LE,SORTX),(0,NE,REPORT),EVEN)
//* Fine: tests without a step, a step of a procedure, and ONLY.
//REPORT   EXEC PGM=IEFBR14,COND=(0,NE)
//NOTIFY   EXEC PGM=IEFBR14,COND=((4,LT,SORTX.STEP1),ONLY)
//* Reported in the in-stream procedure: its steps are its own.
//CLEANUP  PROC
//DELWORK  EXEC PGM=IEFBR14,COND=(0,NE,EXTRACT)
//         PEND
//* IF statements: fine, then a misspelled step, then a later one.
//CHECKS   JOB (ACCT),'CHECKS',CLASS=A
//EXTRACT  EXEC PGM=IEFBR14
//IFOK     IF (EXTRACT.RC = 0 AND RC < 8) THEN
//SORTX    EXEC PGM=IEFBR14
//         ENDIF
//IFBAD    IF (EXTRCT.RC > 4 OR
//            EXTRACT.ABEND OR SORTX.STEP1.RC = 8 OR
//            LATER.RUN) THEN
//NOTIFY   EXEC PGM=IEFBR14
//         ENDIF
//LATER    EXEC PGM=IEFBR14
