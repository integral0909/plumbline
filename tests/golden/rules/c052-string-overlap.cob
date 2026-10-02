*> PLB-C052 string-overlap: a STRING or UNSTRING that sends from
*> storage it receives into.
IDENTIFICATION DIVISION.
PROGRAM-ID. STROVER.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE                 PIC X(40) VALUE "TOTAL".
01  WS-LINE-HEAD REDEFINES WS-LINE PIC X(10).
01  WS-WORK                 PIC X(40).
01  WS-PARTS.
    05  WS-PART             PIC X(10) OCCURS 4.
01  WS-I                    PIC 9 VALUE 1.
01  WS-PTR                  PIC 99 VALUE 1.
PROCEDURE DIVISION.
    *> Reported: appending to the item being sent.
    STRING WS-LINE DELIMITED BY SPACE ", DONE" DELIMITED BY SIZE
        INTO WS-LINE
    *> Reported: the sender redefines the receiver.
    STRING WS-LINE-HEAD DELIMITED BY SIZE INTO WS-LINE
    *> Reported: an UNSTRING receiver inside the item being split.
    UNSTRING WS-PARTS DELIMITED BY "," INTO WS-PART(1) WS-PART(2)
    *> Fine: built in another item, with a pointer.
    STRING WS-LINE DELIMITED BY SPACE ", DONE" DELIMITED BY SIZE
        INTO WS-WORK WITH POINTER WS-PTR
    *> Fine: the subscript is not a sender.
    UNSTRING WS-LINE DELIMITED BY "," INTO WS-PART(WS-I)
    STOP RUN.
