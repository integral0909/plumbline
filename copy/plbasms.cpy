*> plbasms.cpy: one assembler macro statement, as PLB-ASM-READER gives
*> it: the name in column 1 (spaces when there is none), the operation,
*> and the operands joined across continuation lines, up to the first
*> blank outside quotes.
01  PLB-ASM-STATEMENT.
    *> 0 a statement; 1 the end of the file; 2 the file cannot be read.
    05  AT-STATUS               PIC 9(4) COMP-5.
    05  AT-LINE                 PIC 9(9) COMP-5.
    05  AT-NAME                 PIC X(8).
    05  AT-OP                   PIC X(8).
    05  AT-LEN                  PIC 9(4) COMP-5.
    05  AT-OPERANDS             PIC X(4000).
