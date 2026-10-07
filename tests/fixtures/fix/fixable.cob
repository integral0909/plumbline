      * Findings with a fix, for plumbline fix.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXABLE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MONTH PIC 99 VALUE 1.
           88  MONTH-VALID VALUE 12 THRU 1.
       01  WS-CODE PIC X VALUE "A".
       PROCEDURE DIVISION.
           IF WS-CODE = "A" and WS-CODE = "B"
               next sentence
           ELSE
               DISPLAY "NOT A"
           END-IF

      * The sequence area stays in column 73.
           IF WS-CODE NOT = "Q" OR "X"                                  FIX00160
               DISPLAY "NOT Q"
           END-IF
      * No room for one more character before column 73.
           IF WS-CODE   NOT = "Q" OR "X" OR "Y" OR "Z" OR "W" OR "V"
               DISPLAY "NOT Q"
           END-IF
      * NEXT SENTENCE over two lines.
           IF WS-CODE = "1"
               NEXT
               SENTENCE
           END-IF
           IF MONTH-VALID DISPLAY WS-MONTH END-IF
           STOP RUN.
