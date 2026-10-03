       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPT.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO INFILE.
       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC.
           05  IN-AMT              PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT               PIC 9(7)V99.
       01  WS-TAX                  PIC 9(7)V99.
       01  WS-TOTAL                PIC 9(9)V99 VALUE 0.
       01  WS-REPORT-LINE.
           05  RL-TOTAL            PIC Z(8)9.99.
       PROCEDURE DIVISION.
           OPEN INPUT IN-FILE
           READ IN-FILE
           MOVE IN-AMT TO WS-AMOUNT
           COMPUTE WS-TAX = WS-AMOUNT * 0.25
           ADD WS-AMOUNT WS-TAX TO WS-TOTAL
           MOVE WS-TOTAL TO RL-TOTAL
           DISPLAY WS-REPORT-LINE
           CLOSE IN-FILE
           STOP RUN.
