*> PLB-M020 constant-condition.
IDENTIFICATION DIVISION.
PROGRAM-ID. CONSTCOND.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-COUNT            PIC 9(3) VALUE 0.
PROCEDURE DIVISION.
    *> Reported: always true, always false, and with figurative
    *> constants.
    IF 1 = 1
        DISPLAY "ALWAYS"
    END-IF
    IF "ABC" GREATER THAN "ABD"
        DISPLAY "NEVER"
    END-IF
    IF ZEROS NOT = ZERO
        DISPLAY "NEVER"
    END-IF
    *> Reported, without telling which way: a number and a literal.
    IF 0 = "0"
        DISPLAY "DEPENDS ON THE COMPARISON RULES"
    END-IF
    *> Fine: a data item, and an expression.
    IF WS-COUNT = 0 OR 1 + WS-COUNT > 2
        DISPLAY WS-COUNT
    END-IF
    PERFORM UNTIL WS-COUNT > 2
        ADD 1 TO WS-COUNT
    END-PERFORM
    GOBACK.
