//SORTGDG  JOB CLASS=A
//* Sorts the current generation into a temporary data set, then
//* copies it to a new generation: SORTIN and SYSUT1 are read, SORTOUT
//* and SYSUT2 written, whatever DISP says.
//SORT     EXEC PGM=SORT
//SORTIN   DD DSN=PAY.HISTORY(0),DISP=OLD
//SORTOUT  DD DSN=&&SORTED,DISP=(NEW,PASS)
//SYSIN    DD *
  SORT FIELDS=(1,8,CH,A)
/*
//COPY     EXEC PGM=IEBGENER
//SYSUT1   DD DSN=&&SORTED,DISP=(OLD,DELETE)
//SYSUT2   DD DSN=PAY.HISTORY(+1),DISP=(NEW,CATLG)
//SYSIN    DD DUMMY
//SYSPRINT DD SYSOUT=*
//STEPLIB  DD DSN=SYS1.LINKLIB,DISP=SHR
