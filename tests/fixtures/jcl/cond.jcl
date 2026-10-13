//CONDJOB  JOB (ACCT),'COND',CLASS=A
//EXTRACT  EXEC PGM=IEFBR14
//* Reported: (0,LE) is true for every return code.
//REPORT   EXEC PGM=IEFBR14,COND=(0,LE)
//* Reported: (4095,GE), among other tests.
//ARCHIVE  EXEC PGM=IEFBR14,COND=((8,LT),(4095,GE,EXTRACT))
//* Not reported: tests that some return codes pass, and a number
//* that ends in 0 before LE.
//SUMMARY  EXEC PGM=IEFBR14,COND=(0,LT)
//CLEANUP  EXEC PGM=IEFBR14,COND=((10,LE),(4,LT,EXTRACT)),
//             REGION=0M
//NOTIFY   EXEC PGM=IEFBR14,COND=EVEN
