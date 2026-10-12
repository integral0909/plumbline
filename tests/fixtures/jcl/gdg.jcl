//GENS     JOB (ACCT),'GENERATIONS'
//* Reported: (+1) read before any step creates it.
//REPORT   EXEC PGM=IEFBR14
//IN       DD DSN=PAY.HISTORY(+1),DISP=SHR
//* Fine: created, then read.
//MAKE     EXEC PGM=IEFBR14
//OUT      DD DSN=PAY.LEDGER(+1),DISP=(NEW,CATLG,DELETE)
//READ     EXEC PGM=IEFBR14
//IN       DD DSN=PAY.LEDGER(+1),DISP=SHR
//* Fine: the newest generation, and a name with a symbol.
//LAST     EXEC PGM=IEFBR14
//IN       DD DSN=PAY.HISTORY(0),DISP=SHR
//SYM      DD DSN=&HLQ..HISTORY(+1),DISP=SHR
