//GENJOB   JOB (ACCT),'GEN',CLASS=A
//ROLL     EXEC PGM=PAYROLL
//* Reported: a generation above 255, one without a sign, one of four
//* digits, and one with a letter.
//OLDEST   DD DSN=PAY.HIST(-300),DISP=SHR
//PLAIN    DD DSN=PAY.HIST(1),DISP=SHR
//LONG     DD DSN=PAY.HIST(+0001),DISP=SHR
//MIXED    DD DSN=PAY.HIST(+1A),DISP=SHR
//* Not reported: generations in range, and a member.
//NEWEST   DD DSN=PAY.HIST(0),DISP=SHR
//PRIOR    DD DSN=PAY.HIST(-255),DISP=SHR
//NEXT     DD DSN=PAY.HIST(+1),DISP=(NEW,CATLG)
//MEMBER   DD DSN=PAY.LOAD(PAYROLL),DISP=SHR
