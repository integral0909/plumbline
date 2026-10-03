      * Called by RPTMAIN: EXIT PROGRAM returns to it.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTCALC.
       DATA DIVISION.
       LINKAGE SECTION.
       01  LK-TOTAL                PIC 9(7).
       PROCEDURE DIVISION USING LK-TOTAL.
           ADD 1 TO LK-TOTAL
           EXIT PROGRAM.
