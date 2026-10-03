//* PLB-J007 dataset-created-twice: a data set created and cataloged
//* again with nothing deleting it in between.
//ACCTJOB  JOB (ACCT),'EXTRACT',CLASS=A
//EXTRACT  EXEC PGM=IEBGENER
//SYSUT2   DD DSN=PROD.ACCT.EXTRACT,DISP=(NEW,CATLG,DELETE)
//* Reported: the extract step already created it.
//RESORT   EXEC PGM=SORT
//SORTOUT  DD DSN=PROD.ACCT.EXTRACT,
//            DISP=(NEW,CATLG,DELETE)
//* Fine: deleted first, then created again.
//CLEAN    EXEC PGM=IEFBR14
//DEL      DD DSN=PROD.ACCT.EXTRACT,DISP=(OLD,DELETE)
//REMAKE   EXEC PGM=IEBGENER
//SYSUT2   DD DSN=PROD.ACCT.EXTRACT,DISP=(,CATLG)
//* Fine: new generations, temporary data sets, and kept data sets.
//GENS     EXEC PGM=IEBGENER
//SYSUT2   DD DSN=PROD.ACCT.HIST(+1),DISP=(NEW,CATLG)
//WORK     DD DSN=&&WORK,DISP=(NEW,PASS)
//MORE     EXEC PGM=IEBGENER
//SYSUT2   DD DSN=PROD.ACCT.HIST(+1),DISP=(NEW,CATLG)
//WORK     DD DSN=&&WORK,DISP=(NEW,PASS)
