*> PLB-C071 contradictory-condition: equalities of one item joined by
*> AND, or inequalities joined by OR; ranges of a numeric item that
*> never meet under AND, or cover every number under OR.
IDENTIFICATION DIVISION.
PROGRAM-ID. CONTRA.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-STATUS           PIC XX VALUE "00".
01  WS-CODE             PIC 9(3) VALUE 0.
01  WS-AMOUNT           PIC S9(5)V99 VALUE 0.
01  WS-TEXT             PIC XX VALUE "5".
01  WS-TABLE.
    05  WS-FLAG         PIC X OCCURS 3.
PROCEDURE DIVISION.
    *> Reported: never true.
    IF WS-STATUS = "00" AND WS-STATUS = "23"
        DISPLAY "1"
    END-IF
    IF WS-STATUS = "00" AND "23"
        DISPLAY "2"
    END-IF
    IF WS-FLAG(1) IS EQUAL TO "Y" AND WS-FLAG(1) = "N"
        DISPLAY "3"
    END-IF
    *> Reported: always true.
    IF WS-CODE NOT = 100 OR 200
        DISPLAY "4"
    END-IF
    *> Reported: ranges.
    IF WS-AMOUNT > 5 AND WS-AMOUNT < 3
        DISPLAY "R1"
    END-IF
    IF WS-AMOUNT IS GREATER THAN OR EQUAL TO 5 AND LESS THAN 5
        DISPLAY "R2"
    END-IF
    IF WS-AMOUNT > 5 AND NOT > 4.5
        DISPLAY "R3"
    END-IF
    IF WS-AMOUNT < 5 OR WS-AMOUNT >= 5
        DISPLAY "R4"
    END-IF
    IF WS-AMOUNT NOT GREATER 0 OR > -1
        DISPLAY "R5"
    END-IF
    *> Not reported: OR of equalities, the same value, different items
    *> or subscripts, AND of inequalities, ranges that meet or leave a
    *> gap, and an alphanumeric item, compared character by character.
    IF WS-STATUS = "00" OR "23"
        DISPLAY "5"
    END-IF
    IF WS-CODE = 7 AND WS-CODE = 007
        DISPLAY "6"
    END-IF
    IF WS-FLAG(1) = "Y" AND WS-FLAG(2) = "N"
        DISPLAY "7"
    END-IF
    IF WS-STATUS NOT = "00" AND NOT = "23"
        DISPLAY "8"
    END-IF
    IF WS-CODE > 100 AND WS-CODE = 50
        DISPLAY "9"
    END-IF
    IF WS-AMOUNT >= 5 AND <= 5
        DISPLAY "10"
    END-IF
    IF WS-AMOUNT < 5 OR WS-AMOUNT > 5
        DISPLAY "11"
    END-IF
    IF WS-AMOUNT > 3 AND WS-AMOUNT < 5
        DISPLAY "12"
    END-IF
    IF WS-TEXT > 10 AND WS-TEXT < 9
        DISPLAY "13"
    END-IF
    IF WS-AMOUNT NOT = 5 AND WS-AMOUNT > 4
        DISPLAY "14"
    END-IF
    STOP RUN.
