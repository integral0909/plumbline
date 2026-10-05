*> PLB-C066 identical-branches: an IF whose ELSE does what its THEN
*> does.
IDENTIFICATION DIVISION.
PROGRAM-ID. SAMEBRANCH.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TYPE             PIC X VALUE "S".
01  WS-RATE             PIC 9V999 VALUE 0.
01  SAVINGS-RATE        PIC 9V999 VALUE 0.025.
01  CHECKING-RATE       PIC 9V999 VALUE 0.001.
01  WS-COUNT            PIC 99 VALUE 0.
PROCEDURE DIVISION.
    *> Reported: the same statement, written differently.
    IF WS-TYPE = "S"
        MOVE SAVINGS-RATE TO WS-RATE
    ELSE
        move   savings-rate
               TO WS-RATE
    END-IF
    *> Reported: several statements, nested in another IF.
    IF WS-COUNT > 0
        IF WS-TYPE = "C"
            ADD 1 TO WS-COUNT
            DISPLAY "COUNTED"
        ELSE
            ADD 1 TO WS-COUNT
            DISPLAY "COUNTED"
        END-IF
    END-IF
    *> Not reported: different statements, a different literal, and an
    *> IF without ELSE.
    IF WS-TYPE = "S"
        MOVE SAVINGS-RATE TO WS-RATE
    ELSE
        MOVE CHECKING-RATE TO WS-RATE
    END-IF
    IF WS-TYPE = "S"
        DISPLAY "SAVINGS"
    ELSE
        DISPLAY "SAVING"
    END-IF
    IF WS-TYPE = "S"
        DISPLAY WS-RATE
    END-IF
    STOP RUN.
