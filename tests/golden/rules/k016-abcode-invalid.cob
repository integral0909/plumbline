*> PLB-K016 abcode-invalid: an EXEC CICS ABEND ABCODE that CICS does not
*> take as an abend code.
IDENTIFICATION DIVISION.
PROGRAM-ID. ABCODES.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-CODE             PIC X(4) VALUE 'PAY1'.
01  WS-STATE            PIC 9 VALUE 0.
PROCEDURE DIVISION.
    EVALUATE WS-STATE
        *> Reported: a code that starts with A, one of five characters,
        *> and one with a blank in it.
        WHEN 1
            EXEC CICS ABEND ABCODE('ACCT') END-EXEC
        WHEN 2
            EXEC CICS ABEND ABCODE('PAYER') END-EXEC
        WHEN 3
            EXEC CICS ABEND ABCODE('P Y1') END-EXEC
        *> Not reported: a code of four, one of two with trailing
        *> blanks, and a data item.
        WHEN 4
            EXEC CICS ABEND ABCODE('PAY1') END-EXEC
        WHEN 5
            EXEC CICS ABEND ABCODE('E1  ') NODUMP END-EXEC
        WHEN OTHER
            EXEC CICS ABEND ABCODE(WS-CODE) END-EXEC
    END-EVALUATE
    EXEC CICS RETURN END-EXEC.
