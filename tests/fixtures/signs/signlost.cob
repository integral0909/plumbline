*> PLB-M018 signed-to-unsigned, off by default and enabled by the
*> test: a MOVE of a signed number to an unsigned one.
IDENTIFICATION DIVISION.
PROGRAM-ID. SIGNLOST.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-ADJUSTMENT           PIC S9(5)V99 VALUE -12.50.
01  WS-REPORT-AMOUNT        PIC 9(5)V99.
01  WS-SIGNED-COPY          PIC S9(5)V99.
01  WS-EDITED               PIC -ZZZZ9.99.
PROCEDURE DIVISION.
    *> Reported: -12.50 is stored as 12.50.
    MOVE WS-ADJUSTMENT TO WS-REPORT-AMOUNT
    *> Fine: the receiver has a sign, or is edited with one.
    MOVE WS-ADJUSTMENT TO WS-SIGNED-COPY
    MOVE WS-ADJUSTMENT TO WS-EDITED
    STOP RUN.
