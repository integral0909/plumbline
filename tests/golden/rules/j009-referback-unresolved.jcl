//* PLB-J009 referback-unresolved: backward references to a step or
//* DD that is not before them.
//NIGHTLY  JOB (ACCT),'NIGHTLY',CLASS=A
//EXTRACT  EXEC PGM=IEFBR14
//OUT      DD DSN=&&EXTRACT,DISP=(NEW,PASS),UNIT=SYSDA,
//            SPACE=(TRK,(5,5))
//COPY     DD DSN=PROD.COPY,DISP=(NEW,CATLG),DCB=*.OUT,UNIT=SYSDA,
//            SPACE=(TRK,(5,5))
//* Fine: the step and its DD come first.
//SORTA    EXEC PGM=IEFBR14
//SORTIN   DD DSN=*.EXTRACT.OUT,DISP=(OLD,PASS)
//SORTOUT  DD DSN=PROD.SORTED,DISP=(NEW,CATLG),DCB=*.EXTRACT.OUT,
//            UNIT=SYSDA,SPACE=(TRK,(5,5))
//* Reported: a misspelled step, a DD the step does not have, a DD of
//* this step that comes later, and a step that runs later.
//SORTB    EXEC PGM=IEFBR14
//SORTIN   DD DSN=*.EXTRCT.OUT,DISP=(OLD,PASS)
//SORTIN2  DD DSN=*.EXTRACT.OUTPUT,DISP=(OLD,PASS)
//SORTIN3  DD DSN=*.LATER,DISP=(OLD,PASS)
//BACKUP   DD DSN=PROD.BACKUP,DISP=(NEW,CATLG),UNIT=SYSDA,
//            VOL=REF=*.REPORT.OUT,SPACE=(TRK,(5,5))
//LATER    DD DSN=PROD.LATER,DISP=SHR
//REPORT   EXEC PGM=IEFBR14
//OUT      DD SYSOUT=*
