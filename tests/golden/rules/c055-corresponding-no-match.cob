*> PLB-C055 corresponding-no-match.
IDENTIFICATION DIVISION.
PROGRAM-ID. CORRMATCH.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  IN-REC.
    05  CUST-ID         PIC X(8) VALUE "C0000042".
    05  CUST-NAME       PIC X(30) VALUE "ACME".
    05  BALANCE         PIC S9(7)V99 VALUE 10.
    05  DETAIL.
        10  AMOUNT      PIC 9(5) VALUE 5.
    05  CODES           PIC X OCCURS 3 VALUE "A".
01  OUT-REC.
    05  CUSTOMER-ID     PIC X(8).
    05  NAME            PIC X(30).
    05  AMOUNT          PIC 9(5).
    05  CODES           PIC X OCCURS 3.
01  PRINT-REC.
    05  BALANCE         PIC -(7)9.99 VALUE SPACES.
01  COPY-REC.
    05  CUST-ID         PIC X(8).
    05  FILLER          PIC X(30).
01  TOTALS.
    05  BALANCE         PIC S9(9)V99 VALUE 0.
    05  DETAIL.
        10  AMOUNT      PIC 9(7) VALUE 0.
PROCEDURE DIVISION.
    *> Reported: no names in common but AMOUNT, which is in DETAIL on
    *> one side only, and CODES, which repeats.
    MOVE CORRESPONDING IN-REC TO OUT-REC
    *> Fine: CUST-ID corresponds.
    MOVE CORR IN-REC TO COPY-REC
    *> Reported: the BALANCE of PRINT-REC is numeric-edited.
    ADD CORRESPONDING PRINT-REC TO TOTALS
    *> Fine: BALANCE and DETAIL AMOUNT are numeric on both sides.
    ADD CORRESPONDING IN-REC TO TOTALS
    SUBTRACT CORR IN-REC FROM TOTALS
    DISPLAY OUT-REC COPY-REC PRINT-REC TOTALS
    GOBACK.
