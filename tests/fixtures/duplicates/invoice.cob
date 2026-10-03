       IDENTIFICATION DIVISION.
       PROGRAM-ID. INVOICE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT               PIC S9(7)V99 VALUE 0.
       01  WS-TAX                  PIC S9(7)V99 VALUE 0.
       01  WS-TOTAL                PIC S9(7)V99 VALUE 0.
       01  WS-STATUS               PIC X VALUE SPACE.
       PROCEDURE DIVISION.
       MAIN-LINE.
           PERFORM COMPUTE-TAX
           PERFORM COMPUTE-TAX-LOW
           STOP RUN.
       COMPUTE-TAX.
      *    the same code as ADD-TAX in BILLING
           compute ws-tax = ws-amount * 0.25
           add ws-tax to ws-amount giving ws-total
           if ws-total > 10000 move "H" to ws-status
           else move "N" to ws-status end-if.
       COMPUTE-TAX-LOW.
           COMPUTE WS-TAX = WS-AMOUNT * 0.20
           ADD WS-TAX TO WS-AMOUNT GIVING WS-TOTAL
           IF WS-TOTAL > 10000
               MOVE "H" TO WS-STATUS
           ELSE
               MOVE "N" TO WS-STATUS
           END-IF.
           COPY SHOWERR.
