       IDENTIFICATION DIVISION.
       PROGRAM-ID. BILLING.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT               PIC S9(7)V99 VALUE 0.
       01  WS-TAX                  PIC S9(7)V99 VALUE 0.
       01  WS-TOTAL                PIC S9(7)V99 VALUE 0.
       01  WS-STATUS               PIC X VALUE SPACE.
       PROCEDURE DIVISION.
       MAIN-LINE.
           PERFORM ADD-TAX
           STOP RUN.
      * Copied into INVOICE, with another layout and comments.
       ADD-TAX.
           COMPUTE WS-TAX = WS-AMOUNT * 0.25
           ADD WS-TAX TO WS-AMOUNT GIVING WS-TOTAL
           IF WS-TOTAL > 10000
               MOVE "H" TO WS-STATUS
           ELSE
               MOVE "N" TO WS-STATUS
           END-IF.
           COPY SHOWERR.
