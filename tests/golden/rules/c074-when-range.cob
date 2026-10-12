*> PLB-C074 condition-range-reversed: a WHEN of an EVALUATE with a
*> THRU range whose start is above its end.
IDENTIFICATION DIVISION.
PROGRAM-ID. WHENTHRU.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AGE              PIC 999 VALUE 0.
01  WS-GRADE            PIC X VALUE SPACE.
01  WS-LIMIT            PIC 999 VALUE 10.
PROCEDURE DIVISION.
    EVALUATE WS-AGE
        *> Reported: matches no age.
        WHEN 65 THRU 18
            DISPLAY "WORKING AGE"
        *> Reported: matches every age.
        WHEN NOT 12 THRU 0
            DISPLAY "ANY"
    END-EVALUATE
    EVALUATE WS-AGE ALSO WS-GRADE
        *> Reported: the range after ALSO.
        WHEN 0 THRU 17 ALSO "F" THRU "A"
            DISPLAY "MINOR"
        *> Not reported: ranges in order, an end that is an expression,
        *> and ends that ASCII and EBCDIC order differently.
        WHEN 18 THRU 65 ALSO "A" THRU "F"
            DISPLAY "ADULT"
        WHEN WS-LIMIT + 5 THRU 1 ALSO ANY
            DISPLAY "EXPRESSION"
        WHEN ANY ALSO "a" THRU "Z"
            DISPLAY "MIXED CASE"
    END-EVALUATE
    STOP RUN.
