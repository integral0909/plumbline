*> PLB-C113 class-test-invalid: a class test IBM Enterprise COBOL does
*> not accept for the item's category.
IDENTIFICATION DIVISION.
PROGRAM-ID. CLASSTST.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-QTY              PIC 9(4) VALUE 12.
01  WS-NAME             PIC A(8) VALUE "SMITH".
01  WS-AMOUNTS.
    05  WS-AMT          PIC S9(3) VALUE -12.
    05  WS-CNT          PIC 9(2) VALUE 5.
01  WS-CODES.
    05  WS-CODE-1       PIC 9(2) VALUE 1.
    05  WS-CODE-2       PIC X(2) VALUE "AB".
01  WS-TEXT             PIC X(8) VALUE "ABC".
PROCEDURE DIVISION.
    *> Reported.
    IF WS-QTY IS ALPHABETIC
        DISPLAY "quantity"
    END-IF
    IF WS-QTY IS NOT ALPHABETIC-UPPER
        DISPLAY "quantity"
    END-IF
    IF WS-NAME NUMERIC
        DISPLAY "name"
    END-IF
    IF WS-AMOUNTS IS NUMERIC
        DISPLAY "amounts"
    END-IF
    *> Not reported: NUMERIC of a number, of a group with no signed
    *> item, of text, a reference modification, and INITIALIZE.
    IF WS-QTY IS NUMERIC AND WS-CODES IS NUMERIC
        DISPLAY "codes"
    END-IF
    IF WS-TEXT IS ALPHABETIC OR WS-TEXT IS NUMERIC
        DISPLAY "text"
    END-IF
    IF WS-QTY(1:2) IS ALPHABETIC
        DISPLAY "start"
    END-IF
    INITIALIZE WS-AMOUNTS REPLACING NUMERIC DATA BY 0
    DISPLAY WS-AMOUNTS
    STOP RUN.
