*> A free-format copybook whose entries are mostly indented eight
*> columns, like those of a fixed-format program. Its few lines that
*> fixed format forbids, and no line with an indicator or a sequence
*> number, make it free.
    05  RECORD-COUNT        PIC 9(9) COMP-5.
        *> One entry per record.
        10  RECORD-NAME     PIC X(31).
        10  RECORD-SIZE     PIC 9(9) COMP-5.
        *> Where the record starts.
        10  RECORD-OFFSET   PIC 9(9) COMP-5.
        10  RECORD-FLAG     PIC X.
        10  RECORD-KIND     PIC X.
        10  RECORD-LEVEL    PIC 9(4) COMP-5.
        10  RECORD-PARENT   PIC 9(9) COMP-5.
        10  RECORD-CHILD    PIC 9(9) COMP-5.
        10  RECORD-NEXT     PIC 9(9) COMP-5.
        10  RECORD-LAST     PIC 9(9) COMP-5.
        10  RECORD-USAGE    PIC X(20).
        10  RECORD-DIGITS   PIC 9(4) COMP-5.
        10  RECORD-SCALE    PIC S9(4) COMP-5.
        10  RECORD-SIGNED   PIC X.
        10  RECORD-VALUE    PIC X.
        10  RECORD-SPARE-1  PIC X.
        10  RECORD-SPARE-2  PIC X.
        10  RECORD-SPARE-3  PIC X.
