*> PLB-C085 zeros-into-packed: MOVE ZEROS to a group, then a read of
*> one of its packed or binary items.
IDENTIFICATION DIVISION.
PROGRAM-ID. ZEROPK.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT IN-FILE ASSIGN TO "in.dat" FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  IN-FILE.
01  IN-REC              PIC X(80).
WORKING-STORAGE SECTION.
01  WS-TOTALS.
    05  WS-COUNT        PIC S9(7) COMP-3.
    05  WS-ITEMS        PIC S9(4) COMP.
    05  WS-PAGE         PIC 9(3).
01  WS-STATUS.
    05  WS-STATUS-CODE  PIC 9(4) COMP.
PROCEDURE DIVISION.
    *> Reported: the packed item read.
    MOVE ZEROS TO WS-TOTALS
    ADD 1 TO WS-COUNT
    *> Not reported: a DISPLAY item holds zeros well, and the items
    *> are given values before they are read.
    MOVE ZERO TO WS-TOTALS
    ADD 1 TO WS-PAGE
    MOVE "000" TO WS-TOTALS
    MOVE 0 TO WS-COUNT WS-ITEMS
    ADD 1 TO WS-COUNT WS-ITEMS
    *> Not reported: a FILE STATUS item, which the I/O sets.
    MOVE ZEROS TO WS-STATUS
    OPEN INPUT IN-FILE
    DISPLAY WS-STATUS-CODE
    CLOSE IN-FILE
    GOBACK.
