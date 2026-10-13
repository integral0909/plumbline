*> PLB-Q024 column-undeclared: a column in a WHERE that the DECLARE
*> TABLE of the statement's table does not have.
IDENTIFICATION DIVISION.
PROGRAM-ID. WHERECOL.
DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL DECLARE ACCOUNT TABLE
        ( ACCT_ID      INTEGER NOT NULL,
          OWNER        CHAR(30),
          OPENED       DATE )
    END-EXEC.
01  WS-ID               PIC S9(9) COMP.
01  WS-NAME             PIC X(30).
PROCEDURE DIVISION.
    *> Reported: ACCT_NO in a SELECT, a qualified OWNR in a DELETE.
    EXEC SQL
        SELECT OWNER INTO :WS-NAME FROM ACCOUNT
         WHERE ACCT_NO = :WS-ID
    END-EXEC
    EXEC SQL
        DELETE FROM ACCOUNT A WHERE A.OWNR = 'X'
    END-EXEC
    *> Not reported: declared columns, a host variable before the
    *> operator, a special register, and a subquery's columns.
    EXEC SQL
        UPDATE ACCOUNT SET OWNER = :WS-NAME
         WHERE ACCT_ID = :WS-ID AND :WS-ID > 0
           AND OPENED < CURRENT DATE
           AND ACCT_ID IN (SELECT HIST_ID FROM HISTORY WHERE KIND = 'A')
    END-EXEC
    STOP RUN.
