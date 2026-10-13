//OUTJOB   JOB (ACCT),'OUTPUT',CLASS=A
//REPORT   OUTPUT CLASS=A,FORMS=STD
//PRINT    EXEC PGM=PAYRPT
//LOCAL    OUTPUT CLASS=B
//* Reported: a name no OUTPUT statement has, and one that comes after
//* the DD.
//LIST     DD SYSOUT=A,OUTPUT=*.REPROT
//EARLY    DD SYSOUT=A,OUTPUT=*.LATER
//LATER    OUTPUT CLASS=C
//* Not reported: a job-level statement, one of this step, a list of
//* both, and one of an earlier step by name.
//JOBLVL   DD SYSOUT=A,OUTPUT=*.REPORT
//STEPLVL  DD SYSOUT=A,OUTPUT=*.LOCAL
//BOTH     DD SYSOUT=A,OUTPUT=(*.REPORT,*.LOCAL)
//AGAIN    EXEC PGM=PAYRPT2
//BYSTEP   DD SYSOUT=A,OUTPUT=*.PRINT.LOCAL
//* Reported: LOCAL of step PRINT is not found from here as *.LOCAL.
//NOTHERE  DD SYSOUT=A,OUTPUT=*.LOCAL
//* Reported: step PRINT has no OUTPUT statement NONE.
//BADSTEP  DD SYSOUT=A,OUTPUT=*.PRINT.NONE
