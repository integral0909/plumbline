*> PLB-C098 group-value-into-packed and PLB-C099 value-overridden: a
*> group's VALUE in packed or binary items, and over their own VALUE.
IDENTIFICATION DIVISION.
PROGRAM-ID. GROUPVAL.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> C098: spaces in a packed item, the character 0 in another, spaces
*> in a binary item.
01  WS-TOTALS VALUE SPACES.
    05  WS-COUNT        PIC S9(7) COMP-3.
    05  WS-NAME         PIC X(10).
01  WS-SUMS VALUE ZERO.
    05  WS-AMOUNT       PIC S9(5)V99 PACKED-DECIMAL.
01  WS-KEYS VALUE SPACES.
    05  WS-KEY-NUM      PIC 9(4) COMP.
    05  WS-KEY-NUM2     PIC 9(4) COMP-3.
*> Not C098: LOW-VALUES in a binary item is 0; zoned items.
01  WS-FLAGS VALUE LOW-VALUES.
    05  WS-FLAG-NUM     PIC 9(4) COMP.
01  WS-LINE VALUE SPACES.
    05  WS-LINE-NUM     PIC 9(5).
    05  WS-LINE-TEXT    PIC X(20).
*> C099: the item's VALUE under the group's.
01  WS-LIMITS VALUE SPACES.
    05  WS-LIMIT        PIC X(3) VALUE "MAX".
PROCEDURE DIVISION.
    ADD 1 TO WS-COUNT WS-AMOUNT WS-KEY-NUM WS-KEY-NUM2 WS-FLAG-NUM
    DISPLAY WS-TOTALS WS-SUMS WS-KEYS WS-FLAGS WS-LINE WS-LIMITS
    STOP RUN.
