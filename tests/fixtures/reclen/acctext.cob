      * Writes the extract with 300-byte records.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTEXT.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-OUT ASSIGN TO EXTOUT.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-OUT.
       01  ACCT-OUT-REC            PIC X(300).
       PROCEDURE DIVISION.
           OPEN OUTPUT ACCT-OUT
           WRITE ACCT-OUT-REC
           CLOSE ACCT-OUT
           GOBACK.
