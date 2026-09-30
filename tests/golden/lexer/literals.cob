*> Alphanumeric literals, quoting, and prefixes.
    DISPLAY "HELLO, WORLD"
    DISPLAY 'IT''S'
    DISPLAY "SAY ""HI"""
    DISPLAY ""
    MOVE X"FF00" TO A
    MOVE x'0d0a' TO A
    MOVE N"NATIONAL" TO B
    MOVE NX"0041" TO B
    MOVE Z"C-STRING" TO C
    MOVE B"1010" TO D
    MOVE X"G1" TO A
    DISPLAY "UNTERMINATED
    DISPLAY "NEXT LINE STILL LEXES".
