*> PLB-C045 alnum-compared-to-number: an alphanumeric item compared
*> with a numeric literal shorter than the item.
IDENTIFICATION DIVISION.
PROGRAM-ID. ALNUMNUM.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  TYPE-CODE           PIC X(2) VALUE "00".
01  TYPE-CODE-N REDEFINES TYPE-CODE PIC 9(2).
01  FLAG                PIC X VALUE "1".
01  COUNTER             PIC 9(2) VALUE 0.
PROCEDURE DIVISION.
    IF TYPE-CODE = 0
        DISPLAY "NEVER FOR 00"
    END-IF
    IF TYPE-CODE-N = 0
        DISPLAY "ZERO"
    END-IF
    IF TYPE-CODE = ZERO
        DISPLAY "ZEROS"
    END-IF
    IF TYPE-CODE = 12
        DISPLAY "TWELVE"
    END-IF
    IF FLAG = 1
        DISPLAY "ONE"
    END-IF
    EVALUATE TRUE
        WHEN TYPE-CODE = 5
            DISPLAY "FIVE"
    END-EVALUATE
    STOP RUN.
