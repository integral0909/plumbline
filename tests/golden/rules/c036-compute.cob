*> PLB-C036 arithmetic-overflow for COMPUTE: an expression of +, -,
*> and * alone into a receiver narrower than an operand.
IDENTIFICATION DIVISION.
PROGRAM-ID. COMPOVF.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  BIG-AMOUNT          PIC S9(9)V99 VALUE 0.
01  SMALL-TOTAL         PIC S9(5)V99 VALUE 0.
01  WIDE-TOTAL          PIC S9(11)V99 VALUE 0.
01  ROW-TABLE.
    05  ROW-TOTAL       PIC S9(7) OCCURS 10.
01  IX                  PIC 99 VALUE 1.
01  NATIVE              PIC 9(4) COMP-5.
PROCEDURE DIVISION.
    *> Reported: the widest operand has 9 integer digits; the subscript
    *> IX is no operand.
    COMPUTE SMALL-TOTAL = BIG-AMOUNT + (ROW-TOTAL(IX) * 2)
    *> Not reported: a wide receiver, /, a SIZE phrase, LENGTH OF, and
    *> a COMP-5 receiver, which holds what its bytes hold.
    COMPUTE WIDE-TOTAL = BIG-AMOUNT + ROW-TOTAL(IX)
    COMPUTE SMALL-TOTAL = BIG-AMOUNT / 1000
    COMPUTE SMALL-TOTAL = BIG-AMOUNT - 1
        ON SIZE ERROR DISPLAY "TOO BIG"
    END-COMPUTE
    COMPUTE SMALL-TOTAL = LENGTH OF BIG-AMOUNT
    COMPUTE NATIVE = BIG-AMOUNT + 1
    DISPLAY SMALL-TOTAL WIDE-TOTAL
    STOP RUN.
