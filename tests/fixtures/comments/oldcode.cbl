       IDENTIFICATION DIVISION.
       PROGRAM-ID. OLDCODE.
      * PLB-M019 commented-out-code, which is off by default.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RATE             PIC 9V99 VALUE 0.05.
       01  WS-OLD-RATE         PIC 9V99 VALUE 0.04.
       PROCEDURE DIVISION.
       MAIN-LINE.
      * Reported once, as 3 lines: code with a blank line in between.
      *    MOVE WS-OLD-RATE TO WS-RATE
      *    PERFORM 300-APPLY-DISCOUNT

      *    DISPLAY "RATE CHANGED".
      * Prose is left alone, in lower case or upper case.
      * Move the rate to the output when it changes.
      *    MOVE OLD VALUES TO NON-DISPLAY FIELDS
           DISPLAY WS-RATE WS-OLD-RATE
           GOBACK.
