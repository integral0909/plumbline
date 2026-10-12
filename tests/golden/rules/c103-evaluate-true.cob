*> PLB-C103 chain-exhausted: a WHEN, or the WHEN OTHER, of an
*> EVALUATE TRUE that the WHEN phrases before it leave no value for.
IDENTIFICATION DIVISION.
PROGRAM-ID. EVALEXH.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AMOUNT           PIC S9(5)V99 VALUE 0.
01  WS-CODE             PIC X VALUE SPACE.
PROCEDURE DIVISION.
    *> Reported: the third WHEN.
    EVALUATE TRUE
        WHEN WS-AMOUNT > 5
            DISPLAY "OVER 5"
        WHEN WS-AMOUNT < 8
            DISPLAY "UNDER 8"
        WHEN WS-AMOUNT >= 3
            DISPLAY "NEVER"
    END-EVALUATE
    *> Reported: the WHEN OTHER, past a WHEN of another item.
    EVALUATE TRUE
        WHEN WS-AMOUNT >= 0
            DISPLAY "NOT NEGATIVE"
        WHEN WS-CODE = "X"
            DISPLAY "CODE X"
        WHEN WS-AMOUNT < 0
            DISPLAY "NEGATIVE"
        WHEN OTHER
            DISPLAY "NEVER"
    END-EVALUATE
    *> Not reported: values left for WHEN OTHER, an EVALUATE of an
    *> item, and a WHEN one earlier WHEN holds (PLB-C087).
    EVALUATE TRUE
        WHEN WS-AMOUNT > 8
            DISPLAY "OVER 8"
        WHEN WS-AMOUNT < 5
            DISPLAY "UNDER 5"
        WHEN OTHER
            DISPLAY "5 TO 8"
    END-EVALUATE
    EVALUATE WS-CODE
        WHEN "A"
            DISPLAY "A"
        WHEN OTHER
            DISPLAY "OTHER"
    END-EVALUATE
    EVALUATE TRUE
        WHEN WS-AMOUNT >= 0
            DISPLAY "NOT NEGATIVE"
        WHEN WS-AMOUNT = 7
            DISPLAY "PLB-C087 REPORTS THIS"
    END-EVALUATE
    STOP RUN.
