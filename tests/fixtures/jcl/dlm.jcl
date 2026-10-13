//DLMJOB   JOB (ACCT),'DLM',CLASS=A
//LOAD     EXEC PGM=PAYLOAD
//* Reported: DLM on a data set.
//CARDS    DD DSN=PAY.CARDS,DISP=SHR,DLM=@@
//* Not reported: DLM on DD DATA and on DD *.
//SYSIN    DD DATA,DLM=$$
// CONTROL CARD
$$
//PARMS    DD *,DLM='##'
RUN=FULL
##
//SYSOUT   DD SYSOUT=*
