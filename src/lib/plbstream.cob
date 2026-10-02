*> ---------------------------------------------------------------
*> plbstream: build the logical character stream of a source file.
*>
*> See copy/plbstrm.cpy for what the stream contains and how its
*> positions map back to source lines and columns.
*>
*> Diagnostic codes raised here:
*>   LX006  warning  continuation line with no line to continue
*>   LX007  warning  continued literal does not resume with a quote
*>   LX008  error    stream or segment table full
*> ---------------------------------------------------------------

*> PLB-STREAM-BUILD: build the stream for FILE-ID. DEBUG is "Y" to
*> include debugging lines as code (WITH DEBUGGING MODE).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STREAM-BUILD.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-INDEX                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-PREV-SEG             PIC 9(9) COMP-5.
01  LS-PREV-QUOTE           PIC X.
01  LS-FROM-COL             PIC 9(4) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-PAD                  PIC S9(9) COMP-5.
01  LS-JOIN                 PIC X.
01  LS-FULL                 PIC X.
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbstrm.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-DEBUG                PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-STREAM
        LK-FILE-ID LK-DEBUG.
    MOVE LK-FILE-ID TO ST-FILE-ID
    MOVE 0 TO ST-LEN ST-SEG-COUNT LS-PREV-SEG
    MOVE SPACE TO LS-PREV-QUOTE
    MOVE "N" TO LS-FULL
    IF LK-FILE-ID < 1 OR LK-FILE-ID > SS-FILE-COUNT
        GOBACK
    END-IF
    COMPUTE LS-LAST = SF-FIRST-LINE(LK-FILE-ID)
        + SF-LINE-COUNT(LK-FILE-ID) - 1
    PERFORM VARYING LS-INDEX FROM SF-FIRST-LINE(LK-FILE-ID) BY 1
            UNTIL LS-INDEX > LS-LAST OR LS-FULL = "Y"
        EVALUATE TRUE
            *> Left out by conditional compilation (>>IF, $IF).
            WHEN SL-SKIPPED(LS-INDEX) = "Y"
                CONTINUE
            WHEN SL-IS-CODE(LS-INDEX)
                PERFORM ADD-LINE
            WHEN SL-IS-DEBUG(LS-INDEX) AND LK-DEBUG = "Y"
                PERFORM ADD-LINE
            WHEN SL-IS-CONTINUATION(LS-INDEX)
                PERFORM ADD-CONTINUATION
        END-EVALUATE
    END-PERFORM
    GOBACK.

*> An ordinary line starts a new segment after a newline.
ADD-LINE.
    MOVE "N" TO LS-JOIN
    MOVE SL-CONTENT-COL(LS-INDEX) TO LS-FROM-COL
    MOVE SL-CONTENT-LEN(LS-INDEX) TO LS-LEN
    PERFORM APPEND-SEGMENT.

*> A continuation line is joined to the last line added. If that line
*> left a literal open, the literal is padded to column 72 and the
*> continuation resumes after its opening quote.
ADD-CONTINUATION.
    MOVE SL-LINE-NO(LS-INDEX) TO LS-LINE-NO
    IF LS-PREV-SEG = 0
        MOVE 7 TO LS-COLUMN
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" "LX006"
            LK-FILE-ID LS-LINE-NO LS-COLUMN
            "continuation line has no line to continue"
        PERFORM ADD-LINE
        EXIT PARAGRAPH
    END-IF

    MOVE "Y" TO LS-JOIN
    MOVE SL-CONTENT-COL(LS-INDEX) TO LS-FROM-COL
    MOVE SL-CONTENT-LEN(LS-INDEX) TO LS-LEN
    IF LS-PREV-QUOTE NOT = SPACE
        COMPUTE LS-PAD = 72 - (SG-COL(LS-PREV-SEG)
            + SG-LEN(LS-PREV-SEG) - 1)
        IF LS-PAD > 0 AND ST-LEN + LS-PAD <= ST-SIZE
            MOVE SPACES TO ST-TEXT(ST-LEN + 1:LS-PAD)
            ADD LS-PAD TO ST-LEN
            ADD LS-PAD TO SG-LEN(LS-PREV-SEG)
        END-IF
        IF LS-LEN > 0 AND SS-HEAP(SL-TEXT-OFF(LS-INDEX)
                + LS-FROM-COL - 1:1) = LS-PREV-QUOTE
            ADD 1 TO LS-FROM-COL
            SUBTRACT 1 FROM LS-LEN
        ELSE
            MOVE LS-FROM-COL TO LS-COLUMN
            CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" "LX007"
                LK-FILE-ID LS-LINE-NO LS-COLUMN
                "continued literal should resume with a quote"
        END-IF
    END-IF
    PERFORM APPEND-SEGMENT.

*> Append LS-LEN characters of line LS-INDEX from column LS-FROM-COL
*> as a new segment, preceded by a newline unless LS-JOIN is "Y".
APPEND-SEGMENT.
    IF LS-JOIN = "N" AND ST-LEN > 0
        IF ST-LEN + 1 > ST-SIZE
            PERFORM REPORT-FULL
            EXIT PARAGRAPH
        END-IF
        ADD 1 TO ST-LEN
        MOVE X"0A" TO ST-TEXT(ST-LEN:1)
    END-IF
    IF ST-SEG-COUNT >= ST-MAX-SEGMENTS OR ST-LEN + LS-LEN > ST-SIZE
        PERFORM REPORT-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO ST-SEG-COUNT
    COMPUTE SG-START(ST-SEG-COUNT) = ST-LEN + 1
    MOVE LS-INDEX TO SG-LINE(ST-SEG-COUNT)
    MOVE LS-FROM-COL TO SG-COL(ST-SEG-COUNT)
    *> plumbline: ignore move-truncation -- a segment is at most one 1024-column line
    MOVE LS-LEN TO SG-LEN(ST-SEG-COUNT)
    IF LS-LEN > 0
        MOVE SS-HEAP(SL-TEXT-OFF(LS-INDEX) + LS-FROM-COL - 1:LS-LEN)
            TO ST-TEXT(ST-LEN + 1:LS-LEN)
        ADD LS-LEN TO ST-LEN
    END-IF
    MOVE ST-SEG-COUNT TO LS-PREV-SEG
    MOVE SL-OPEN-QUOTE(LS-INDEX) TO LS-PREV-QUOTE.

REPORT-FULL.
    MOVE "Y" TO LS-FULL
    MOVE SL-LINE-NO(LS-INDEX) TO LS-LINE-NO
    MOVE 0 TO LS-COLUMN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "LX008"
        LK-FILE-ID LS-LINE-NO LS-COLUMN
        "file too large to tokenize; the rest is ignored".
END PROGRAM PLB-STREAM-BUILD.

*> PLB-STREAM-LOCATE: map stream position POS to a source location.
*> SEGMENT is a search hint in and the containing segment out: pass
*> the previous result when positions only move forward, or 1.
*> A position between segments (a newline) maps to the end of the
*> segment before it. LINE receives the SS-LINE index, COLUMN the
*> column; both are 0 for an empty stream.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STREAM-LOCATE.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbstrm.cpy".
01  LK-POS                  PIC 9(9) COMP-5.
01  LK-SEGMENT              PIC 9(9) COMP-5.
01  LK-LINE                 PIC 9(9) COMP-5.
01  LK-COLUMN               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-STREAM LK-POS LK-SEGMENT LK-LINE
        LK-COLUMN.
    MOVE 0 TO LK-LINE LK-COLUMN
    IF ST-SEG-COUNT = 0
        MOVE 0 TO LK-SEGMENT
        GOBACK
    END-IF
    IF LK-SEGMENT < 1 OR LK-SEGMENT > ST-SEG-COUNT
        MOVE 1 TO LK-SEGMENT
    END-IF
    IF SG-START(LK-SEGMENT) > LK-POS
        MOVE 1 TO LK-SEGMENT
    END-IF
    PERFORM UNTIL LK-SEGMENT >= ST-SEG-COUNT
        IF SG-START(LK-SEGMENT + 1) > LK-POS
            EXIT PERFORM
        END-IF
        ADD 1 TO LK-SEGMENT
    END-PERFORM
    MOVE SG-LINE(LK-SEGMENT) TO LK-LINE
    IF LK-POS >= SG-START(LK-SEGMENT) + SG-LEN(LK-SEGMENT)
            AND SG-LEN(LK-SEGMENT) > 0
        COMPUTE LK-COLUMN = SG-COL(LK-SEGMENT) + SG-LEN(LK-SEGMENT) - 1
    ELSE
        COMPUTE LK-COLUMN = SG-COL(LK-SEGMENT)
            + LK-POS - SG-START(LK-SEGMENT)
    END-IF
    GOBACK.
END PROGRAM PLB-STREAM-LOCATE.
