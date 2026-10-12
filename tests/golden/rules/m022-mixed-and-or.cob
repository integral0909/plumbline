*> PLB-M022 mixed-and-or: AND and OR at one level of parentheses.
IDENTIFICATION DIVISION.
PROGRAM-ID. MIXED.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TYPE             PIC X VALUE "A".
01  WS-AMOUNT           PIC 9(3) VALUE 0.
01  WS-I                PIC 9(3) VALUE 0.
PROCEDURE DIVISION.
MAIN-LINE.
    *> Reported: at the top level, and inside parentheses.
    IF WS-TYPE = "A" OR WS-TYPE = "B" AND WS-AMOUNT > 0
        DISPLAY "1"
    END-IF
    IF (WS-AMOUNT > 1 AND WS-AMOUNT < 9 OR WS-AMOUNT = 0)
        DISPLAY "2"
    END-IF
    PERFORM VARYING WS-I FROM 1 BY 1
            UNTIL WS-I > 9 AND WS-AMOUNT = 0 OR WS-TYPE = "Z"
        DISPLAY WS-I
    END-PERFORM
    *> Not reported: parentheses around the AND, one join, GREATER OR
    *> EQUAL, and joins split by ALSO.
    IF WS-TYPE = "A" OR (WS-TYPE = "B" AND WS-AMOUNT > 0)
        DISPLAY "3"
    END-IF
    IF WS-AMOUNT IS GREATER THAN OR EQUAL TO 1 AND WS-TYPE = "A"
        DISPLAY "4"
    END-IF
    EVALUATE WS-TYPE = "A" OR WS-TYPE = "B" ALSO WS-AMOUNT > 0 AND
             WS-I = 0
        WHEN TRUE ALSO TRUE
            DISPLAY "5"
    END-EVALUATE
    STOP RUN.
