*> PLB-Q023 select-not-grouped: a column of a HAVING, outside an
*> aggregate, that the GROUP BY does not name.
IDENTIFICATION DIVISION.
PROGRAM-ID. HAVINGNG.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-OWNER            PIC X(30).
01  WS-TOTAL            PIC S9(9)V99 COMP-3.
01  WS-LIMIT            PIC S9(9)V99 COMP-3.
    *> Reported: PAY_TYPE, which the GROUP BY leaves out.
    EXEC SQL
        DECLARE BIG-CUR CURSOR FOR
            SELECT OWNER, SUM(AMOUNT) FROM PAYMENT
             GROUP BY OWNER
            HAVING SUM(AMOUNT) > 100 AND PAY_TYPE = 'CR'
    END-EXEC.
PROCEDURE DIVISION.
    *> Not reported: grouped columns, aggregates, host variables, and
    *> words of SQL.
    EXEC SQL
        SELECT OWNER, SUM(AMOUNT) INTO :WS-OWNER, :WS-TOTAL
          FROM PAYMENT
         GROUP BY OWNER
        HAVING OWNER IS NOT NULL AND MAX(AMOUNT) > :WS-LIMIT
           AND OWNER NOT LIKE 'Z%'
    END-EXEC
    STOP RUN.
