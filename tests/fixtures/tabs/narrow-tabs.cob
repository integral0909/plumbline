      * Written with tab stops every 4 columns: at the default 8,
      * the second record ends past column 72.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TABBED.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  CUSTOMER.
		     05  CUST-ID                                 PIC 9(09).
		     05  CUST-NAME                               PIC X(25).
       PROCEDURE DIVISION.
           MOVE SPACES TO CUSTOMER
           DISPLAY CUSTOMER
           STOP RUN.
