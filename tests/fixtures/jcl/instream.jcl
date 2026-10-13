//PAYALL   JOB (ACCT),'ALL',CLASS=A
//* Reported: P16, the sixteenth in-stream procedure; P01 to P15 are
//* not.
//P01      PROC
//RUN      EXEC PGM=PAY01
//         PEND
//P02      PROC
//RUN      EXEC PGM=PAY02
//         PEND
//P03      PROC
//RUN      EXEC PGM=PAY03
//         PEND
//P04      PROC
//RUN      EXEC PGM=PAY04
//         PEND
//P05      PROC
//RUN      EXEC PGM=PAY05
//         PEND
//P06      PROC
//RUN      EXEC PGM=PAY06
//         PEND
//P07      PROC
//RUN      EXEC PGM=PAY07
//         PEND
//P08      PROC
//RUN      EXEC PGM=PAY08
//         PEND
//P09      PROC
//RUN      EXEC PGM=PAY09
//         PEND
//P10      PROC
//RUN      EXEC PGM=PAY10
//         PEND
//P11      PROC
//RUN      EXEC PGM=PAY11
//         PEND
//P12      PROC
//RUN      EXEC PGM=PAY12
//         PEND
//P13      PROC
//RUN      EXEC PGM=PAY13
//         PEND
//P14      PROC
//RUN      EXEC PGM=PAY14
//         PEND
//P15      PROC
//RUN      EXEC PGM=PAY15
//         PEND
//P16      PROC
//RUN      EXEC PGM=PAY16
//         PEND
//STEP1    EXEC P16
