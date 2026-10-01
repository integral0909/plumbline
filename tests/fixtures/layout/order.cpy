*> An order record: a key, an amount in packed decimal, lines that
*> repeat, and a date seen two ways.
01  ORDER-RECORD.
    05  ORDER-KEY.
        10  ORDER-REGION   PIC X(2).
        10  ORDER-NUMBER   PIC 9(8).
    05  ORDER-STATUS       PIC X.
        88  ORDER-OPEN     VALUE "O".
    05  ORDER-AMOUNT       PIC S9(9)V99 COMP-3.
    05  ORDER-DATE         PIC 9(8).
    05  ORDER-DATE-PARTS REDEFINES ORDER-DATE.
        10  ORDER-YEAR     PIC 9(4).
        10  ORDER-MONTH    PIC 99.
        10  ORDER-DAY      PIC 99.
    05  ORDER-LINE OCCURS 3.
        10  LINE-ITEM      PIC X(6).
        10  LINE-QTY       PIC 9(3) COMP.
    05  FILLER             PIC X(10).
