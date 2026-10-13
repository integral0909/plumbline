//KEYJOB   JOB (ACCT),'KEY',CLASS=A
//DEFINE   EXEC PGM=PAYDEF
//* Reported: a key above 255, a key-sequenced data set without a key,
//* one whose key is as long as its records, and a key in DCB longer
//* than the record.
//BIGKEY   DD DSN=PAY.BIGKEY,DISP=(NEW,CATLG),KEYLEN=300,LRECL=400
//NOKEY    DD DSN=PAY.NOKEY,DISP=(NEW,CATLG),RECORG=KS,KEYLEN=0
//FULL     DD DSN=PAY.FULL,DISP=(NEW,CATLG),RECORG=KS,KEYLEN=80,
//            LRECL=80
//OVER     DD DSN=PAY.OVER,DISP=(NEW,CATLG),DCB=(KEYLEN=90,LRECL=80)
//* Not reported: keys the Reference allows.
//KSDS     DD DSN=PAY.KSDS,DISP=(NEW,CATLG),RECORG=KS,KEYLEN=10,
//            LRECL=80
//DIRECT   DD DSN=PAY.DIRECT,DISP=(NEW,CATLG),KEYLEN=80,LRECL=80
//PDSE     DD DSN=PAY.PDSE,DISP=(NEW,CATLG),KEYLEN=0
