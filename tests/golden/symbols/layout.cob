*> Sizes and offsets of groups, tables, REDEFINES, and usages.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  CUSTOMER.
    05  CUST-ID             PIC 9(8).
    05  CUST-NAME.
        10  FIRST-NAME      PIC X(15).
        10  LAST-NAME       PIC X(20).
    05  CUST-BALANCE        PIC S9(9)V99 COMP-3.
    05  CUST-FLAGS          PIC X.
        88  CUST-ACTIVE     VALUE "A".
        88  CUST-CLOSED     VALUE "C" "X".
    05  CUST-ORDERS         OCCURS 10 TIMES.
        10  ORDER-NO        PIC 9(6) COMP.
        10  ORDER-AMT       PIC S9(5)V99 COMP-3.
    05  CUST-ID-X REDEFINES CUST-ID PIC X(8).
    05  CUST-COUNTERS       COMP.
        10  VISITS          PIC 9(4).
        10  PURCHASES       PIC 9(9).
01  WS-POINTERS.
    05  WS-PTR              USAGE POINTER.
    05  WS-IX               INDEX.
    05  WS-FLOAT            COMP-2.
01  WS-EDITED.
    05  WS-AMOUNT-OUT       PIC $$$,$$9.99-.
    05  WS-DATE-OUT         PIC 99/99/9999.
    05  WS-NATIONAL         PIC N(4).
01  WS-BAD                  PIC 9(3)Q.
01  WS-BAD-REDEF REDEFINES NO-SUCH-ITEM PIC X.
