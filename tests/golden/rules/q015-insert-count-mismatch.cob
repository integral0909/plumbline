*> PLB-Q015 insert-count-mismatch: an INSERT with another number of
*> values than columns.
IDENTIFICATION DIVISION.
PROGRAM-ID. INSCNT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-ID                   PIC S9(9) COMP.
01  WS-NAME                 PIC X(30).
01  WS-BALANCE              PIC S9(9)V99 COMP-3.
01  WS-NAME-IND             PIC S9(4) COMP.
01  WS-NOTE.
    49  WS-NOTE-LEN         PIC S9(4) COMP.
    49  WS-NOTE-TEXT        PIC X(100).
01  WS-ACCOUNT.
    05  WS-ACC-ID           PIC S9(9) COMP.
    05  WS-ACC-NAME         PIC X(30).
PROCEDURE DIVISION.
    *> Reported: three columns, two values; two columns, three values.
    EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, ACCT_NAME, BALANCE)
        VALUES (:WS-ID, :WS-NAME)
    END-EXEC
    EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, ACCT_NAME)
        VALUES (:WS-ID, :WS-NAME, :WS-BALANCE)
    END-EXEC
    *> A VARCHAR (level-49 items) is one value.
    EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, NOTE, BALANCE)
        VALUES (:WS-ID, :WS-NOTE)
    END-EXEC
    *> Fine: as many of each, with an indicator, a function, and a
    *> constant; a host structure; no column list; INSERT ... SELECT.
    EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, ACCT_NAME, BALANCE, OPENED)
        VALUES (:WS-ID, :WS-NAME :WS-NAME-IND,
                COALESCE(:WS-BALANCE, 0), CURRENT DATE)
    END-EXEC
    EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, ACCT_NAME, BALANCE)
        VALUES (:WS-ACCOUNT)
    END-EXEC
    EXEC SQL INSERT INTO ACCOUNT
        VALUES (:WS-ID, :WS-NAME)
    END-EXEC
    EXEC SQL INSERT INTO ACCOUNT_COPY (ACCT_ID, ACCT_NAME)
        SELECT ACCT_ID, ACCT_NAME, BALANCE FROM ACCOUNT
    END-EXEC
    STOP RUN.
