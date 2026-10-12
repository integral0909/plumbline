*> PLB-C102 nested-if-decided: an IF first in the body of an inline
*> PERFORM ... UNTIL whose test the UNTIL test already decides.
IDENTIFICATION DIVISION.
PROGRAM-ID. UNTILIF.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-I                PIC S9(3) VALUE 0.
01  WS-J                PIC S9(3) VALUE 0.
PROCEDURE DIVISION.
    *> Reported: the body runs only while WS-I is 10 or less.
    PERFORM UNTIL WS-I > 10
        IF WS-I > 20
            DISPLAY "NEVER"
        END-IF
        ADD 1 TO WS-I
    END-PERFORM
    *> Reported: VARYING tests before each time round too.
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I >= 5
        IF WS-I < 5
            DISPLAY "ALWAYS"
        ELSE
            DISPLAY "NEVER"
        END-IF
    END-PERFORM
    *> Not reported: WITH TEST AFTER runs the body once first, VARYING
    *> ... AFTER, an UNTIL test with =, a test the UNTIL test leaves
    *> open, another item, and an IF after another statement.
    MOVE 30 TO WS-I
    PERFORM WITH TEST AFTER UNTIL WS-I > 10
        IF WS-I > 20
            DISPLAY "ONCE"
        END-IF
        MOVE 0 TO WS-I
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3
            AFTER WS-J FROM 1 BY 1 UNTIL WS-J > 3
        IF WS-I > 5
            DISPLAY "NOT READ"
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I = 5
        IF WS-I = 5
            DISPLAY "NOT READ"
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 10
        IF WS-I > 5
            DISPLAY "SIX TO TEN"
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 10
        IF WS-J > 20
            DISPLAY "OTHER"
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 10
        DISPLAY WS-I
        IF WS-I > 20
            DISPLAY "AFTER A STATEMENT"
        END-IF
    END-PERFORM
    STOP RUN.
