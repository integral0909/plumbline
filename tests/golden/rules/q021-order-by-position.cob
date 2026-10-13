*> PLB-Q021 order-by-position: an SQL ORDER BY column number beyond
*> the select list.
IDENTIFICATION DIVISION.
PROGRAM-ID. ORDERPOS.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-ID               PIC S9(9) COMP.
01  WS-NAME             PIC X(30).
    *> Reported: a cursor ordered by its third column, of two.
    EXEC SQL
        DECLARE ACCT-CUR CURSOR FOR
            SELECT ACCT_ID, OWNER FROM ACCOUNT
             ORDER BY 3
    END-EXEC.
    *> Not reported: positions within the list, a name, an expression,
    *> and the number of FETCH FIRST.
    EXEC SQL
        DECLARE OWNER-CUR CURSOR FOR
            SELECT ACCT_ID, OWNER, BALANCE FROM ACCOUNT
             ORDER BY 2 DESC, 1, BALANCE + 1
             FETCH FIRST 10 ROWS ONLY
    END-EXEC.
PROCEDURE DIVISION.
    *> Reported: the second number of the list.
    EXEC SQL
        SELECT ACCT_ID, OWNER INTO :WS-ID, :WS-NAME FROM ACCOUNT
         WHERE ACCT_ID = 1 ORDER BY 1, 5
    END-EXEC
    STOP RUN.
