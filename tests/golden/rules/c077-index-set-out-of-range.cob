*> PLB-C077 index-set-out-of-range: SET of an index to a number outside
*> its table.
IDENTIFICATION DIVISION.
PROGRAM-ID. SETIDX.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-RATES.
    05  WS-RATE-ENTRY   OCCURS 10 TIMES
                        ASCENDING KEY IS WS-RATE-CODE
                        INDEXED BY RATE-IX RATE-IX2.
        10  WS-RATE-CODE    PIC X(2).
        10  WS-RATE-DAY     PIC 9 OCCURS 7 INDEXED DAY-IX.
PROCEDURE DIVISION.
    *> Reported: past the end.
    SET RATE-IX TO 11
    *> Reported: the second index named; the first is in range.
    SET RATE-IX2 DAY-IX TO 8
    *> Reported: negative.
    SET RATE-IX TO -1
    *> Not reported: in range, and zero.
    SET RATE-IX TO 10
    SET DAY-IX TO 0
    SET DAY-IX UP BY 1
    DISPLAY WS-RATE-CODE (RATE-IX) WS-RATE-DAY (RATE-IX2, DAY-IX)
    GOBACK.
