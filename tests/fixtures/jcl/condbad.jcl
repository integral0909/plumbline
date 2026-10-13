//* Reported: a code above 4095 on the JOB statement.
//PAYJOB   JOB (ACCT),'PAY',CLASS=A,COND=(5000,LT)
//* Reported, on the first step too: an operator that is not one.
//EXTRACT  EXEC PGM=PAYEXTR,COND=(4,GTE)
//EXTRACT2 EXEC PGM=PAYEXTR,COND=(4,LS)
//* Reported: nine tests.
//REPORT   EXEC PGM=PAYRPT,COND=((1,EQ),(2,EQ),(3,EQ),(4,EQ),(5,EQ),
//             (6,EQ),(7,EQ),(8,EQ),(9,EQ))
//* Reported: eight tests and EVEN.
//SUMMARY  EXEC PGM=PAYSUM,COND=((1,EQ),(2,EQ),(3,EQ),(4,EQ),(5,EQ),
//             (6,EQ),(7,EQ),(8,EQ),EVEN)
//* Not reported: eight tests, and seven with ONLY.
//CLEANUP  EXEC PGM=PAYCLEAN,COND=((1,EQ),(2,EQ),(3,EQ),(4,EQ),
//             (5,EQ),(6,EQ),(7,EQ),(8,EQ))
//RECOVER  EXEC PGM=PAYRECOV,COND=(ONLY,(1,EQ),(2,EQ),(3,EQ),(4,EQ),
//             (5,EQ),(6,EQ),(7,EQ))
