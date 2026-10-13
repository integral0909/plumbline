//* Reported: (0,LE) on the JOB statement ends the job after its first
//* step.
//PAYJOB1  JOB (ACCT),'PAY',CLASS=A,COND=(0,LE)
//EXTRACT  EXEC PGM=PAYEXTR
//REPORT   EXEC PGM=PAYRPT
//* Reported: (4095,LT) never ends the job.
//PAYJOB2  JOB (ACCT),'PAY',CLASS=A,COND=((8,LE),(4095,LT))
//EXTRACT  EXEC PGM=PAYEXTR
//* Not reported: (4,LT) ends the job after a return code above 4.
//PAYJOB3  JOB (ACCT),'PAY',CLASS=A,COND=(4,LT)
//EXTRACT  EXEC PGM=PAYEXTR
