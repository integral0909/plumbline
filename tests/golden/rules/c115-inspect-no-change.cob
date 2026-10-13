*> PLB-C115 inspect-no-change: an INSPECT that replaces a literal by
*> itself, or converts a string to itself.
IDENTIFICATION DIVISION.
PROGRAM-ID. INSPSAME.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TEXT             PIC X(20) VALUE "A,B;C,D".
01  WS-COUNT            PIC 9(4) VALUE 0.
PROCEDURE DIVISION.
    *> Reported: a replacement by the same character, one clause of
    *> two, and a conversion to the same string.
    INSPECT WS-TEXT REPLACING ALL "," BY ","
    INSPECT WS-TEXT REPLACING ALL ";" BY ","
                              ALL "D" BY "D"
    INSPECT WS-TEXT CONVERTING ";," TO ";,"
    *> Not reported: replacements and conversions that change, and
    *> TALLYING.
    INSPECT WS-TEXT REPLACING ALL "," BY "."
    INSPECT WS-TEXT CONVERTING "abc" TO "ABC"
    INSPECT WS-TEXT TALLYING WS-COUNT FOR ALL ","
    DISPLAY WS-TEXT WS-COUNT
    STOP RUN.
