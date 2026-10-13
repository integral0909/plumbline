*> PLB-Q020 column-repeated: an SQL INSERT or UPDATE that names a
*> column twice.
IDENTIFICATION DIVISION.
PROGRAM-ID. COLREP.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-ID               PIC S9(9) COMP.
01  WS-NAME             PIC X(30).
01  WS-LIMIT            PIC S9(7)V99 COMP-3.
PROCEDURE DIVISION.
    *> Reported: the INSERT's column list, and the UPDATE's SET.
    EXEC SQL
        INSERT INTO ACCOUNT (ACCT_ID, OWNER, ACCT_ID)
               VALUES (:WS-ID, :WS-NAME, :WS-ID)
    END-EXEC
    EXEC SQL
        UPDATE ACCOUNT
           SET CREDIT_LIMIT = :WS-LIMIT, OWNER = :WS-NAME,
               CREDIT_LIMIT = 0
         WHERE ACCT_ID = :WS-ID
    END-EXEC
    *> Not reported: each column once, a column in an expression and
    *> in the WHERE, and the same name in a subquery.
    EXEC SQL
        INSERT INTO ACCOUNT (ACCT_ID, OWNER) VALUES (:WS-ID, :WS-NAME)
    END-EXEC
    EXEC SQL
        UPDATE ACCOUNT
           SET CREDIT_LIMIT = CREDIT_LIMIT + 100,
               OWNER = (SELECT OWNER FROM OWNERS WHERE OWNER_ID = 1)
         WHERE CREDIT_LIMIT = 0
    END-EXEC
    STOP RUN.
