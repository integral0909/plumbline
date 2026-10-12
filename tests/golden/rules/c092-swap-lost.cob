*> PLB-C092 swap-lost: a MOVE to an item and straight back.
IDENTIFICATION DIVISION.
PROGRAM-ID. SWAP.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-A                PIC X(5) VALUE "AAAAA".
01  WS-B                PIC X(5) VALUE "BBBBB".
01  WS-LONG             PIC X(8) VALUE "LLLLLLLL".
01  WS-SHORT            PIC X(3) VALUE "SSS".
01  WS-AMOUNT           PIC S9(5)V99 VALUE -123.45.
01  WS-OTHER            PIC S9(7)V99 VALUE 1.
01  WS-WHOLE            PIC S9(5) VALUE 0.
01  WS-TEMP             PIC X(5).
PROCEDURE DIVISION.
MAIN-LINE.
    *> Reported.
    MOVE WS-A TO WS-B
    MOVE WS-B TO WS-A
    MOVE WS-A TO WS-LONG.
    MOVE WS-LONG TO WS-A.
    MOVE WS-AMOUNT TO WS-OTHER
    MOVE WS-OTHER TO WS-AMOUNT
    *> Not reported: a swap through a third item, a move that cuts
    *> (to fewer characters, or to no decimal places), and a statement
    *> between.
    MOVE WS-A TO WS-TEMP
    MOVE WS-B TO WS-A
    MOVE WS-TEMP TO WS-B
    MOVE WS-A TO WS-SHORT
    MOVE WS-SHORT TO WS-A
    MOVE WS-AMOUNT TO WS-WHOLE
    MOVE WS-WHOLE TO WS-AMOUNT
    MOVE WS-A TO WS-B
    DISPLAY WS-B
    MOVE WS-B TO WS-A
    DISPLAY WS-A WS-B WS-LONG WS-SHORT WS-AMOUNT WS-OTHER WS-WHOLE
    STOP RUN.
