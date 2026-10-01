*> Statements nested deeper than the limit: one finding for the
*> outermost statement, however many statements inside it go too deep.
IDENTIFICATION DIVISION.
PROGRAM-ID. NESTING.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  A                  PIC 9 VALUE 1.
01  B                  PIC 9 VALUE 2.
PROCEDURE DIVISION.
MAIN-LINE.
    IF A = 1
        IF B = 2
            EVALUATE A
                WHEN 1
                    IF B = 3
                        DISPLAY "FOUR LEVELS"
                        DISPLAY "STILL FOUR"
                    END-IF
                WHEN OTHER
                    CONTINUE
            END-EVALUATE
        END-IF
    END-IF
    PERFORM UNTIL A = 9
        ADD 1 TO A
        IF A = 5
            IF B = 2
                DISPLAY "THREE LEVELS"
            END-IF
        END-IF
    END-PERFORM
    GOBACK.
