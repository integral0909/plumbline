       >>SOURCE FORMAT XCARD
      * ICOBOL xCard format: fixed columns, the text to column 255.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. XCARDFMT.
       PROCEDURE DIVISION.
           DISPLAY "PAST COLUMN 72"                                                                 UPON CONSOLE
           DISPLAY FUNCTION LENGTH("A LITERAL CONTINUED IN XCARD
      -    "FORMAT")
           GOBACK.
