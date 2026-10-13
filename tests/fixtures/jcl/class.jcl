//* Reported: a MSGCLASS of two characters.
//PAYJOB1  JOB (ACCT),'PAY',CLASS=A,MSGCLASS=XY
//STEP1    EXEC PGM=PAYRUN
//* Reported: a SYSOUT class of two characters, and one that is not a
//* letter or digit.
//REPORT   DD SYSOUT=AB
//AUDIT    DD SYSOUT=(#,INTRDR)
//* Not reported: classes the Reference allows.
//LIST     DD SYSOUT=*
//LOG      DD SYSOUT=(,)
//PRINT    DD SYSOUT=(A,,FM26)
//COPY     DD SYSOUT='B'
//* Reported: a job class that starts with a hyphen.
//PAYJOB2  JOB (ACCT),'PAY',CLASS=-A,MSGCLASS=X
//STEP1    EXEC PGM=PAYRUN
//* Not reported: a job class of eight characters.
//PAYJOB3  JOB (ACCT),'PAY',CLASS=BATCH#01,MSGCLASS=0
//STEP1    EXEC PGM=PAYRUN
