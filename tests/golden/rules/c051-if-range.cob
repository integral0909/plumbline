*> PLB-C051 duplicate-if-condition: an ELSE IF whose relation an
*> earlier IF of the chain already holds every value of.
IDENTIFICATION DIVISION.
PROGRAM-ID. IFRANGE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AMOUNT           PIC S9(5)V99.
01  WS-COUNT            PIC 9(3).
01  WS-RATE             PIC 9(3) OCCURS 5 TIMES.
01  WS-I                PIC 9.
01  WS-CODE             PIC X.
PROCEDURE DIVISION.
    *> Reported: above 20 is above 10.
    IF WS-AMOUNT > 10
        DISPLAY "OVER 10"
    ELSE IF WS-AMOUNT > 20
        DISPLAY "NEVER"
    END-IF
    END-IF
    *> Reported: the words, NOT, and an earlier IF that is not the one
    *> just before.
    IF WS-COUNT NOT LESS THAN 100
        DISPLAY "LARGE"
    ELSE IF WS-COUNT < 5
        DISPLAY "SMALL"
    ELSE IF WS-COUNT IS EQUAL TO 150
        DISPLAY "NEVER"
    END-IF
    END-IF
    END-IF
    *> Reported: the same element of a table.
    IF WS-RATE(WS-I) <= 50
        DISPLAY "LOW"
    ELSE IF WS-RATE(WS-I) = 7
        DISPLAY "NEVER"
    END-IF
    END-IF
    *> Not reported: a range that reaches past the earlier one, values
    *> only the earlier ones together hold, another element, another
    *> item, an open end against a closed one, and a test of a
    *> character item.
    IF WS-AMOUNT > 10
        DISPLAY "OVER 10"
    ELSE IF WS-AMOUNT > 5
        DISPLAY "OVER 5"
    END-IF
    END-IF
    IF WS-COUNT > 10
        DISPLAY "OVER 10"
    ELSE IF WS-COUNT < 5
        DISPLAY "UNDER 5"
    ELSE IF WS-COUNT = 7
        DISPLAY "SEVEN"
    END-IF
    END-IF
    END-IF
    IF WS-RATE(1) > 10
        DISPLAY "HIGH"
    ELSE IF WS-RATE(2) > 20
        DISPLAY "OTHER"
    END-IF
    END-IF
    IF WS-COUNT > 10
        DISPLAY "HIGH"
    ELSE IF WS-AMOUNT > 20
        DISPLAY "OTHER"
    END-IF
    END-IF
    IF WS-COUNT > 10
        DISPLAY "OVER 10"
    ELSE IF WS-COUNT >= 10
        DISPLAY "TEN"
    END-IF
    END-IF
    IF WS-CODE > "A"
        DISPLAY "AFTER A"
    ELSE IF WS-CODE > "B"
        DISPLAY "AFTER B"
    END-IF
    END-IF
    STOP RUN.
