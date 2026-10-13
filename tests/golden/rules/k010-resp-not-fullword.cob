*> PLB-K010 resp-not-fullword: RESP or RESP2 of an item that is not a
*> fullword binary item.
IDENTIFICATION DIVISION.
PROGRAM-ID. RESPSIZE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-RESP-HALF        PIC S9(4) COMP.
01  WS-RESP-TEXT        PIC X(8).
01  WS-RESP-NUM         PIC S9(8).
01  WS-RESP             PIC S9(8) COMP.
01  WS-RESP2            PIC S9(8) BINARY.
01  WS-RESP5            PIC S9(9) COMP-5.
01  WS-RECORD           PIC X(80).
01  WS-KEY              PIC X(11).
PROCEDURE DIVISION.
    *> Reported: a halfword, a character item, and a display number.
    EXEC CICS READ FILE('ACCTDAT') INTO(WS-RECORD) RIDFLD(WS-KEY)
         RESP(WS-RESP-HALF) RESP2(WS-RESP-TEXT)
    END-EXEC
    EXEC CICS RETURN RESP(WS-RESP-NUM) END-EXEC
    *> Not reported: fullword binary items.
    EXEC CICS READ FILE('ACCTDAT') INTO(WS-RECORD) RIDFLD(WS-KEY)
         RESP(WS-RESP) RESP2(WS-RESP2)
    END-EXEC
    EXEC CICS RETURN RESP(WS-RESP5) END-EXEC
    GOBACK.
