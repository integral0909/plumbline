      * Reads the extract with an old, 350-byte layout.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTRPT.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-IN ASSIGN TO EXTIN.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-IN.
       01  ACCT-IN-REC.
           05  ACCT-IN-KEY         PIC X(50).
           05  ACCT-IN-DATA        PIC X(300).
       PROCEDURE DIVISION.
           OPEN INPUT ACCT-IN
           READ ACCT-IN
           CLOSE ACCT-IN
           GOBACK.
