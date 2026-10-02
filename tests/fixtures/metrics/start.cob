*> Two statements before the first paragraph: the start of the
*> procedure division is lines 5 to 7, not the whole division.
IDENTIFICATION DIVISION.
PROGRAM-ID. START.
PROCEDURE DIVISION.
    PERFORM GREET
    STOP RUN.
GREET.
    DISPLAY "HELLO"
    DISPLAY "THERE".
