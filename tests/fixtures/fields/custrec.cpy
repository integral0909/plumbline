*> The customer record, shared by the programs of the fixture.
01  CUST-RECORD.
    05  CUST-ID             PIC X(8).
    05  CUST-NAME           PIC X(30).
    05  CUST-STATUS         PIC X.
        88  CUST-ACTIVE     VALUE "A".
    05  CUST-FAX            PIC X(15).
    05  CUST-COUNTS.
        10  CUST-ORDERS     PIC 9(5).
        10  CUST-RETURNS    PIC 9(5).
    05  CUST-HISTORY        PIC X(10) OCCURS 1 TO 12
                            DEPENDING ON CUST-ORDERS.
