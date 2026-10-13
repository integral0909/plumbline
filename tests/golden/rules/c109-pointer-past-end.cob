*> PLB-C109 pointer-past-end: STRING or UNSTRING WITH POINTER an item
*> just given a value past the end of the item it counts in.
IDENTIFICATION DIVISION.
PROGRAM-ID. PTREND.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE             PIC X(20) VALUE SPACES.
01  WS-TEXT             PIC X(10) VALUE "A,B".
01  WS-PART             PIC X(5).
01  WS-PTR              PIC 99 VALUE 1.
PROCEDURE DIVISION.
    *> Reported: one past the end of the receiver, and of the item
    *> unstrung.
    MOVE 21 TO WS-PTR
    STRING "ABC" DELIMITED BY SIZE INTO WS-LINE WITH POINTER WS-PTR
    COMPUTE WS-PTR = 11
    UNSTRING WS-TEXT DELIMITED BY "," INTO WS-PART
        WITH POINTER WS-PTR
    *> Not reported: the last position, a pointer added to between,
    *> and a pointer set in another paragraph.
    MOVE 20 TO WS-PTR
    STRING "A" DELIMITED BY SIZE INTO WS-LINE WITH POINTER WS-PTR
    MOVE 30 TO WS-PTR
    SUBTRACT 20 FROM WS-PTR
    STRING "A" DELIMITED BY SIZE INTO WS-LINE WITH POINTER WS-PTR
    MOVE 40 TO WS-PTR.
APPEND-PARA.
    STRING "A" DELIMITED BY SIZE INTO WS-LINE WITH POINTER WS-PTR
    DISPLAY WS-LINE WS-PART
    STOP RUN.
