*> PLB-C096 converting-repeated: a character twice in the first string
*> of INSPECT CONVERTING, with different characters for it.
IDENTIFICATION DIVISION.
PROGRAM-ID. CONVREP.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TEXT             PIC X(20) VALUE "ABCABC".
01  WS-FROM             PIC X(3) VALUE "ABA".
PROCEDURE DIVISION.
MAIN-LINE.
    *> Reported.
    INSPECT WS-TEXT CONVERTING "ABA" TO "XYZ"
    INSPECT WS-TEXT CONVERTING "aeiouAEIOe" TO "1234512345"
    *> Not reported: a repeat with the same character for it, no
    *> repeat, a data item, and a literal with a prefix.
    INSPECT WS-TEXT CONVERTING "ABA" TO "XYX"
    INSPECT WS-TEXT CONVERTING "abc" TO "ABC"
    INSPECT WS-TEXT CONVERTING WS-FROM TO "XYZ"
    INSPECT WS-TEXT CONVERTING X"C1C2C1" TO "XYZ"
    DISPLAY WS-TEXT
    STOP RUN.
