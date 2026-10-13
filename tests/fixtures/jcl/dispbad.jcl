//DISPJOB  JOB (ACCT),'DISP',CLASS=A
//EXTRACT  EXEC PGM=PAYEXTR
//* Reported: a status that is not one, a normal disposition that is
//* not one, PASS after an abnormal end, and a fourth subparameter.
//NEWER    DD DSN=PAY.NEWER,DISP=(NEWW,CATLG)
//KEPT     DD DSN=PAY.KEPT,DISP=(OLD,KEEPP)
//PASSED   DD DSN=PAY.PASSED,DISP=(NEW,CATLG,PASS)
//FOUR     DD DSN=PAY.FOUR,DISP=(NEW,CATLG,DELETE,KEEP)
//* Not reported: the forms the Reference shows.
//SHARED   DD DSN=PAY.SHARED,DISP=SHR
//ADDED    DD DSN=PAY.ADDED,DISP=(MOD,KEEP,KEEP)
//GONE     DD DSN=PAY.GONE,DISP=(OLD,,DELETE)
//LATER    DD DSN=PAY.LATER,DISP=(,PASS)
