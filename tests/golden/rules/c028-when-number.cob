*> PLB-C028 comparison-never-true: a WHEN number, or a THRU range of
*> numbers, that the numeric subject of the EVALUATE cannot hold.
IDENTIFICATION DIVISION.
PROGRAM-ID. WHENNUM.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AGE              PIC 99 VALUE 0.
01  WS-BALANCE          PIC S9(3) COMP-3 VALUE 0.
01  WS-RATE             PIC 9V99 VALUE 0.
01  WS-COUNT            PIC 9(4) COMP VALUE 0.
PROCEDURE DIVISION.
    EVALUATE WS-AGE
        *> Reported: above 99, below 0, and a range wholly above 99.
        WHEN 100
            DISPLAY "CENTURY"
        WHEN -1
            DISPLAY "UNKNOWN"
        WHEN 120 THRU 150
            DISPLAY "RECORD"
        *> Not reported: a range with values the item holds.
        WHEN 90 THRU 150
            DISPLAY "OLD"
    END-EVALUATE
    EVALUATE WS-AGE ALSO WS-BALANCE
        *> Reported: a range wholly below what the signed item holds.
        WHEN ANY ALSO -2000 THRU -1000
            DISPLAY "DEEP"
        *> Not reported: values the signed item holds.
        WHEN ANY ALSO -999 THRU -1
            DISPLAY "NEGATIVE"
    END-EVALUATE
    *> Not reported: an item with decimal places, and a binary item.
    EVALUATE WS-RATE
        WHEN 10
            DISPLAY "TEN"
    END-EVALUATE
    EVALUATE WS-COUNT
        WHEN 10000
            DISPLAY "MANY"
    END-EVALUATE
    STOP RUN.
