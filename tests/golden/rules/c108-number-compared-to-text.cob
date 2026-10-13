*> PLB-C108 number-compared-to-text: an unsigned integer item compared
*> for equality with digits in quotes, of another length.
IDENTIFICATION DIVISION.
PROGRAM-ID. NUMTEXT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-COUNT            PIC 99 VALUE 5.
01  WS-YEAR             PIC 9(4) VALUE 2026.
01  WS-SIGNED           PIC S99 VALUE 5.
01  WS-PACKED           PIC 99 COMP-3 VALUE 5.
01  WS-CODE             PIC XX VALUE "05".
PROCEDURE DIVISION.
    *> Reported: fewer digits, more digits, and a WHEN.
    IF WS-COUNT = "5"
        DISPLAY "FIVE"
    END-IF
    IF WS-YEAR = "026" OR WS-COUNT = "0005"
        DISPLAY "YEAR"
    END-IF
    EVALUATE WS-COUNT
        WHEN "7"
            DISPLAY "SEVEN"
    END-EVALUATE
    *> Not reported: as many digits as the item, trailing spaces, a
    *> number, a signed or packed item, text that is no number, and an
    *> alphanumeric item.
    IF WS-COUNT = "05" OR WS-COUNT = "05  " OR WS-COUNT = 5
        DISPLAY "FIVE"
    END-IF
    IF WS-SIGNED = "5" OR WS-PACKED = "5" OR WS-COUNT = "AB"
        DISPLAY "OTHER"
    END-IF
    IF WS-CODE = "5"
        DISPLAY "CODE"
    END-IF
    STOP RUN.
