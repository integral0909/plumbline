//* Not reported: a JOBLIB right after the JOB statement, with a
//* library concatenated to it.
//GOODJOB  JOB (ACCT),'GOOD',CLASS=A
//JOBLIB   DD DSN=PAY.LOADLIB,DISP=SHR
//         DD DSN=PAY.COMMON.LOADLIB,DISP=SHR
//STEP1    EXEC PGM=PAYRUN
//* Reported: a JOBLIB after another DD of the job.
//LATEJOB  JOB (ACCT),'LATE',CLASS=A
//JOBCAT   DD DSN=PAY.CATALOG,DISP=SHR
//JOBLIB   DD DSN=PAY.LOADLIB,DISP=SHR
//STEP1    EXEC PGM=PAYRUN
//* Reported: a JOBLIB after an EXEC, a DD of that step.
//STEPJOB  JOB (ACCT),'STEP',CLASS=A
//STEP1    EXEC PGM=PAYRUN
//JOBLIB   DD DSN=PAY.LOADLIB,DISP=SHR
