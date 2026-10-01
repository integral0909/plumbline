       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVALS.
      *> One EVALUATE says what happens to any other value, one does not.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  STATUS-CODE     PIC 9 VALUE 1.
       PROCEDURE DIVISION.
           EVALUATE STATUS-CODE
               WHEN 1 DISPLAY "OPEN"
               WHEN OTHER DISPLAY "UNKNOWN"
           END-EVALUATE
           EVALUATE STATUS-CODE
               WHEN 1 DISPLAY "OPEN"
               WHEN 2 DISPLAY "CLOSED"
           END-EVALUATE
           STOP RUN.
