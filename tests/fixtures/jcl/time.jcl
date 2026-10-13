//* Reported: TIME=0 on a JOB statement.
//PAYJOB   JOB (ACCT),'PAY',CLASS=A,TIME=0
//* Reported: 90 seconds, 400000 minutes, and minutes that are not a
//* number.
//EXTRACT  EXEC PGM=PAYEXTR,TIME=(5,90)
//SORT     EXEC PGM=SORT,TIME=400000
//REPORT   EXEC PGM=PAYRPT,TIME=FIVE
//* Not reported: minutes and seconds in range, seconds alone, the
//* words for no limit, 0 on a step, and a symbol.
//LOAD     EXEC PGM=PAYLOAD,TIME=(357912,59)
//CHECK    EXEC PGM=PAYCHK,TIME=(,30)
//ARCHIVE  EXEC PGM=PAYARCH,TIME=1440
//PURGE    EXEC PGM=PAYPURGE,TIME=NOLIMIT
//NEXT     EXEC PGM=PAYNEXT,TIME=0
//LAST     EXEC PGM=PAYLAST,TIME=&LIMIT
