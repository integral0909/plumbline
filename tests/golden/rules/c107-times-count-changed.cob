*> PLB-C107 times-count-changed: a statement of a PERFORM ... TIMES
*> loop that changes the loop's count.
IDENTIFICATION DIVISION.
PROGRAM-ID. TIMESCNT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-ROWS             PIC 99 VALUE 3.
01  WS-LEFT             PIC 99 VALUE 3.
01  WS-DONE             PIC 99 VALUE 0.
01  WS-TRIES.
    05  WS-TRY-COUNT    PIC 99 VALUE 3.
PROCEDURE DIVISION.
    *> Reported: the count changed in an inline loop, and its group.
    PERFORM WS-ROWS TIMES
        ADD 1 TO WS-DONE
        IF WS-DONE = 1
            MOVE 10 TO WS-ROWS
        END-IF
    END-PERFORM
    PERFORM WS-TRY-COUNT TIMES
        INITIALIZE WS-TRIES
    END-PERFORM
    *> Reported: the count changed in the performed paragraph.
    PERFORM TAKE-ONE WS-LEFT TIMES
    *> Not reported: a count the loop does not change, and a literal.
    PERFORM WS-ROWS TIMES
        ADD 1 TO WS-DONE
    END-PERFORM
    PERFORM 3 TIMES
        ADD 1 TO WS-DONE
    END-PERFORM
    STOP RUN.
TAKE-ONE.
    ADD 1 TO WS-DONE
    SUBTRACT 1 FROM WS-LEFT.
