//* PLB-J010 dsn-invalid: DSN= names that z/OS does not accept as data
//* set names.
//MONTHLY  JOB (ACCT),'MONTHLY',CLASS=A
//STEP1    EXEC PGM=IEFBR14
//* Reported: a qualifier that starts with a digit, one longer than 8
//* characters, an empty one, a character a name cannot hold, and a
//* name longer than 44 characters.
//MASTER   DD DSN=PROD.CUSTOMER.2024JAN,DISP=SHR
//HISTORY  DD DSN=PROD.CUSTOMERS.HISTORY,DISP=SHR
//EMPTY    DD DSN=PROD..MASTER,DISP=SHR
//UNDER    DD DSN=PROD.CUST_MAST,DISP=SHR
//LONG     DD DSN=PROD.CUSTOMER.MASTER.FILE.BACKUP.COPY.MONTHLY.A,
//            DISP=SHR
//* Not reported: national characters, hyphens, a member and a
//* generation, a temporary data set, symbols, a backward reference,
//* and NULLFILE.
//NATIONAL DD DSN=$SYS.#WORK.@TEMP-1,DISP=SHR
//MEMBER   DD DSN=PROD.SOURCE.LIB(PAYROLL),DISP=SHR
//GDG      DD DSN=PROD.DAILY.TOTALS(+1),DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(TRK,(5,5))
//TEMP     DD DSN=&&WORK,DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(TRK,1)
//SYMBOL   DD DSN=&HLQ..CUSTOMER.MASTER,DISP=SHR
//SCHED    DD DSN=PROD.D%%ODATE,DISP=SHR
//BACK     DD DSN=*.MASTER,DISP=SHR
//NOTHING  DD DSN=NULLFILE
