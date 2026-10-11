*> PLB-C087 when-covered: a WHEN whose values an earlier WHEN's range
*> takes.
IDENTIFICATION DIVISION.
PROGRAM-ID. WHENCOV.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-CODE             PIC S9(3).
PROCEDURE DIVISION.
    EVALUATE WS-CODE
        WHEN 1 THRU 10
            DISPLAY "LOW"
        *> Reported: a value, and a range, inside 1 THRU 10.
        WHEN 5
            DISPLAY "FIVE"
        WHEN 8 THROUGH 9
            DISPLAY "EIGHT"
        *> Not reported: partly outside, outside, and the same WHEN
        *> again (PLB-C032's).
        WHEN 9 THRU 12
            DISPLAY "NINE ON"
        WHEN -5 THRU 0
            DISPLAY "NOT POSITIVE"
        WHEN 1 THRU 10
            DISPLAY "AGAIN"
        WHEN OTHER
            DISPLAY "OTHER"
    END-EVALUATE
    *> Not reported: EVALUATE TRUE.
    EVALUATE TRUE
        WHEN WS-CODE > 0
            DISPLAY "POSITIVE"
    END-EVALUATE
    GOBACK.
