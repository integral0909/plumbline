//NAMEJOB  JOB (ACCT),'NAMES',CLASS=A
//* Reported: a step name of 11 characters.
//EXTRACTSTEP EXEC PGM=PAYEXT
//OUT      DD DSN=PAY.EXTRACT,DISP=SHR
//* Reported: a step name that starts with a digit.
//1COPY    EXEC PGM=IEFBR14
//* Reported: a DD name with a hyphen, and an override whose DD part
//* is too long.
//PAY-IN   DD DSN=PAY.INPUT,DISP=SHR
//RUN      EXEC PAYPROC
//STEP1.INPUTFILE1 DD DSN=PAY.INPUT,DISP=SHR
//* Not reported: names of 8 characters, national characters, a
//* digit after the first character, an override, and a symbol.
//EXTRACT8 EXEC PGM=PAYEXT
//$WORK#1  DD DSN=PAY.WORK,DISP=SHR
//@STEP2   EXEC PGM=IEFBR14
//RUN2     EXEC PAYPROC
//STEP1.INPUT DD DSN=PAY.INPUT,DISP=SHR
//&STEPX   EXEC PGM=IEFBR14
//* Reported: a program name of 11 characters, and a procedure name
//* with a hyphen.
//BIGPGM   EXEC PGM=PAYEXTRACT1
//BADPROC  EXEC PROC=PAY-PROC
//* Not reported: a program found by a backward reference.
//LINKED   EXEC PGM=*.LKED.SYSLMOD
