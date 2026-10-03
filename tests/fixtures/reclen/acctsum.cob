      * Reads the extract with its 300-byte layout, and writes the
      * history with records of two lengths.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTSUM.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-IN ASSIGN TO EXTIN.
           SELECT HIST-OUT ASSIGN TO HISTOUT.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-IN.
       01  ACCT-IN-REC             PIC X(300).
       FD  HIST-OUT.
       01  HIST-HEADER             PIC X(20).
       01  HIST-DETAIL             PIC X(120).
       PROCEDURE DIVISION.
           OPEN INPUT ACCT-IN OUTPUT HIST-OUT
           READ ACCT-IN
           WRITE HIST-DETAIL
           CLOSE ACCT-IN HIST-OUT
           GOBACK.
