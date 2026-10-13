*> PLB-Q024 column-undeclared: a column that the DECLARE TABLE of the
*> statement's table does not have.
IDENTIFICATION DIVISION.
PROGRAM-ID. COLUNDEC.
DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL DECLARE ACCOUNT TABLE
        ( ACCT_ID      INTEGER NOT NULL,
          OWNER        CHAR(30),
          BALANCE      DECIMAL(9,2) )
    END-EXEC.
01  WS-ID               PIC S9(9) COMP.
01  WS-NAME             PIC X(30).
01  WS-BALANCE          PIC S9(7)V99 COMP-3.
PROCEDURE DIVISION.
    *> Reported: a misspelled column in a SELECT, an UPDATE, and an
    *> INSERT.
    EXEC SQL
        SELECT ACCT_ID, OWNR INTO :WS-ID, :WS-NAME
          FROM ACCOUNT WHERE ACCT_ID = 1
    END-EXEC
    EXEC SQL
        UPDATE ACCOUNT SET BALANSE = :WS-BALANCE WHERE ACCT_ID = :WS-ID
    END-EXEC
    EXEC SQL
        INSERT INTO ACCOUNT (ACCT_ID, OWNER_NAME)
               VALUES (:WS-ID, :WS-NAME)
    END-EXEC
    *> Not reported: declared columns, qualified by a correlation
    *> name, and a table with no DECLARE TABLE.
    EXEC SQL
        SELECT A.OWNER, A.BALANCE INTO :WS-NAME, :WS-BALANCE
          FROM ACCOUNT A WHERE A.ACCT_ID = :WS-ID
    END-EXEC
    EXEC SQL
        SELECT ANY_COLUMN INTO :WS-NAME FROM HISTORY
    END-EXEC
    STOP RUN.
