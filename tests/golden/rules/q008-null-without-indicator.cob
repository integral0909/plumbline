*> PLB-Q008 null-without-indicator: a column that can be NULL fetched
*> into a host variable without an indicator variable.
IDENTIFICATION DIVISION.
PROGRAM-ID. NULLIND.
DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL DECLARE BANK.CUSTOMER TABLE
    ( CUST_ID                        INTEGER NOT NULL,
      PHONE                          CHAR(15),
      CLOSED_ON                      DATE
    ) END-EXEC.
01  WS-ID                   PIC S9(9) COMP.
01  WS-PHONE                PIC X(15).
01  WS-PHONE-IND            PIC S9(4) COMP.
01  WS-CLOSED-ON            PIC X(10).
    EXEC SQL DECLARE CUST-CUR CURSOR FOR
        SELECT CUST_ID, PHONE, CLOSED_ON FROM BANK.CUSTOMER
    END-EXEC.
PROCEDURE DIVISION.
    *> Reported: PHONE can be NULL.
    EXEC SQL SELECT CUST_ID, PHONE
        INTO :WS-ID, :WS-PHONE
        FROM BANK.CUSTOMER WHERE CUST_ID = 1
    END-EXEC
    *> Fine: indicators, either way of writing them; CUST_ID is NOT
    *> NULL. Reported: CLOSED_ON, without one.
    EXEC SQL OPEN CUST-CUR END-EXEC
    EXEC SQL FETCH CUST-CUR
        INTO :WS-ID, :WS-PHONE :WS-PHONE-IND, :WS-CLOSED-ON
    END-EXEC
    EXEC SQL FETCH CUST-CUR
        INTO :WS-ID, :WS-PHONE INDICATOR :WS-PHONE-IND, :WS-CLOSED-ON
    END-EXEC
    EXEC SQL CLOSE CUST-CUR END-EXEC
    STOP RUN.
