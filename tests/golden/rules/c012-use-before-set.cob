       IDENTIFICATION DIVISION.
       PROGRAM-ID. C012-SAMPLE.
      *> Reads that no path gives a value first, and reads that are
      *> fine because a path does.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  TOTAL           PIC 9(5).
       01  PRICE           PIC 9(5).
       01  QTY             PIC 9(3).
       01  I               PIC 9(3).
       01  PREVIOUS        PIC X(10).
       01  CURRENT-KEY     PIC X(10).
       01  STATUS-FLAG     PIC X.
           88  DONE        VALUE "Y".
       01  RESULT          PIC 9(5).
       01  LOADED          PIC 9(5).
       01  SWAP-AREA       PIC X(10).
       01  SWAP-VIEW REDEFINES SWAP-AREA PIC 9(10).
       PROCEDURE DIVISION.
       MAIN-LINE.
      *>   PRICE and TOTAL are read before anything sets them.
           ADD PRICE TO TOTAL
           MOVE 5 TO PRICE
      *>   PRICE is set now; QTY is set by the performed paragraph.
           PERFORM LOAD-QTY
           COMPUTE RESULT = PRICE * QTY
      *>   A loop variable is set by VARYING before UNTIL reads it.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 3
               DISPLAY I
           END-PERFORM
      *>   PREVIOUS is set later in the loop body, so it has a value
      *>   from the second iteration on.
           MOVE "N" TO STATUS-FLAG
           PERFORM UNTIL DONE
               IF PREVIOUS = CURRENT-KEY
                   SET DONE TO TRUE
               END-IF
               MOVE CURRENT-KEY TO PREVIOUS
               MOVE "K" TO CURRENT-KEY
           END-PERFORM
      *>   Setting a REDEFINES view sets the storage it shares.
           MOVE 7 TO SWAP-VIEW
           DISPLAY SWAP-AREA
           PERFORM SHOW-LOADED
           GO TO FINISH.
       LOAD-QTY.
           MOVE 3 TO QTY.
       SHOW-LOADED.
      *>   Nothing sets LOADED before the only PERFORM of this.
           DISPLAY LOADED RESULT.
       FINISH.
           MOVE 1 TO LOADED
           DISPLAY TOTAL
           STOP RUN.
