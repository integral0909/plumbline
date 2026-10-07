*> PLB-C072 unreachable-statement: a statement after GO TO, GOBACK, or
*> STOP RUN in the same list, or in a later sentence of the paragraph.
IDENTIFICATION DIVISION.
PROGRAM-ID. DEADSTMT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-EOF              PIC X VALUE "N".
01  WS-KIND             PIC 9 VALUE 1.
01  WS-COUNT            PIC 9(4) VALUE 0.
PROCEDURE DIVISION.
MAIN-PARA.
    IF WS-EOF = "Y"
        GO TO FINISH
        *> Reported: in the same branch, after the GO TO.
        DISPLAY "CLOSING"
    END-IF
    PERFORM COUNT-PARA
    *> Not reported: the value may be out of range.
    GO TO COUNT-PARA FINISH DEPENDING ON WS-KIND
    DISPLAY "OUT OF RANGE"
    GO TO FINISH.
COUNT-PARA.
    ADD 1 TO WS-COUNT
    GOBACK.
    *> Reported: a later sentence of the same paragraph.
    DISPLAY WS-COUNT.
    DISPLAY "ALSO DEAD, NOT REPORTED AGAIN".
FINISH.
    STOP RUN
    *> Not reported: a second way out.
    GOBACK.
ALT-ENTRY.
    STOP RUN.
    *> Not reported: callers come in at an ENTRY.
    ENTRY "DEADALT"
    DISPLAY "ALTERNATE"
    GOBACK.
