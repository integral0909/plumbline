      * Numbers in quotes moved to numeric items.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. QUOTED.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RATE PIC 9V99.
       01  WS-LAST PIC 9V99.
       01  WS-COUNT PIC 9(3).
       PROCEDURE DIVISION.
           MOVE "1.50" TO WS-RATE WS-LAST
           MOVE "-12" TO WS-COUNT
           MOVE "ABC" TO WS-COUNT
           DISPLAY WS-RATE WS-LAST WS-COUNT
           STOP RUN.
