*> PLB-Q025 insert-not-null-missing: an INSERT that leaves out a NOT
*> NULL column without a default.
IDENTIFICATION DIVISION.
PROGRAM-ID. NOTNULL.
DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL DECLARE ACCOUNT TABLE
        ( ACCT_ID      INTEGER NOT NULL,
          OWNER        CHAR(30) NOT NULL,
          NOTE         CHAR(40),
          OPENED       DATE NOT NULL WITH DEFAULT,
          STATUS       CHAR(1) NOT NULL DEFAULT 'A' )
    END-EXEC.
01  WS-ID               PIC S9(9) COMP.
01  WS-NAME             PIC X(30).
01  WS-NOTE             PIC X(40).
PROCEDURE DIVISION.
    *> Reported: OWNER left out.
    EXEC SQL
        INSERT INTO ACCOUNT (ACCT_ID, NOTE) VALUES (:WS-ID, :WS-NOTE)
    END-EXEC
    *> Not reported: every NOT NULL column without a default given,
    *> and an INSERT without a column list.
    EXEC SQL
        INSERT INTO ACCOUNT (ACCT_ID, OWNER) VALUES (:WS-ID, 'X')
    END-EXEC
    EXEC SQL
        INSERT INTO ACCOUNT VALUES (:WS-ID, :WS-NAME, :WS-NOTE,
               CURRENT DATE, 'A')
    END-EXEC
    *> Reported: an INSERT whose VALUES give OWNER NULL; not reported,
    *> NULL for NOTE.
    EXEC SQL
        INSERT INTO ACCOUNT (ACCT_ID, OWNER, NOTE)
               VALUES (:WS-ID, NULL, NULL)
    END-EXEC
    *> Reported: an UPDATE that sets OWNER to NULL; not reported, one
    *> that sets NOTE, which can be NULL.
    EXEC SQL
        UPDATE ACCOUNT SET NOTE = NULL, OWNER = NULL
         WHERE ACCT_ID = :WS-ID
    END-EXEC
    STOP RUN.
