*> ---------------------------------------------------------------
*> plbfmt: rewrite a source file in fixed or free reference format.
*>
*> PLB-FORMAT USING SOURCE FILE-ID TARGET CHECK CHANGED writes file
*> FILE-ID in TARGET format ("fixed" or "free") to standard output,
*> one line at a time, or, when CHECK is "Y", writes nothing and sets
*> CHANGED to "Y" when the output would differ from the file.
*>
*> To free format:
*>   - columns 1-6 and 73-80 are dropped and column 8 becomes column 1;
*>   - comment lines become *> comments, debugging lines >>D lines;
*>   - a line and its continuation lines become one line;
*>   - the file starts with >>SOURCE FORMAT IS FREE (if it was not
*>     free already), and other format directives are dropped.
*> To fixed format:
*>   - code goes in columns 8-72, keeping its indentation; division,
*>     section, and paragraph headers and 01, 77, FD, SD, RD, and CD
*>     entries start in column 8 (area A);
*>   - a line that does not fit is split at a space outside literals,
*>     the rest indented four more columns; a literal that does not fit
*>     continues on a line with - in column 7;
*>   - *> comment lines become comment lines (* in column 7), and an
*>     inline comment that does not fit after its code goes on a
*>     comment line before it;
*>   - format directives are dropped.
*> Lines already in the target format are kept as they are, less
*> trailing spaces. Either way the tokens do not change.
*>
*> The other reference formats are read for what they are: VARIABLE and
*> xCard as fixed with the text running to column 250 and 255, X/Open
*> free form, ACU terminal, and CRT format with their indicator in
*> column 1 and the text from column 1, COBOLX with the text from
*> column 2 to 255. Their continuation lines are joined, and a literal
*> continued across lines is padded to the margin of the line it starts
*> on, as the compiler reads it (column 250 in VARIABLE format, 255 in
*> xCard, not at all in terminal, COBOLX, and CRT format). A VARIABLE
*> or xCard line that fits in column 72 stays as it is in fixed format,
*> and page ejects stay page ejects.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FORMAT.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The output lines made from one input line (or a line and its
*> continuations), compared with the input in CHECK mode.
78  OUT-MAX                     VALUE 64.
01  WS-OUTPUT.
    05  WS-OUT-COUNT        PIC 9(4) COMP-5.
    05  WS-OUT-LINE         PIC X(1024) OCCURS OUT-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-L                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-GROUP-FIRST          PIC 9(9) COMP-5.
01  LS-GROUP-LAST           PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-RAW                  PIC X(1024).
01  LS-RAW-LEN              PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(4096).
01  LS-TEXT-LEN             PIC 9(9) COMP-5.
01  LS-CODE                 PIC X(4096).
01  LS-CODE-LEN             PIC 9(9) COMP-5.
01  LS-COMMENT              PIC X(1024).
01  LS-COMMENT-LEN          PIC 9(9) COMP-5.
01  LS-LINE                 PIC X(1024).
01  LS-INDENT               PIC 9(4) COMP-5.
01  LS-START                PIC 9(4) COMP-5.
01  LS-WIDTH                PIC 9(4) COMP-5.
01  LS-POS                  PIC 9(9) COMP-5.
01  LS-BREAK                PIC 9(9) COMP-5.
01  LS-QUOTE                PIC X.
01  LS-OPEN                 PIC X.
01  LS-INDICATOR            PIC X.
01  LS-UPPER                PIC X(80).
01  LS-WRAP-START           PIC 9(4) COMP-5.
01  LS-COMMENT-START        PIC 9(4) COMP-5.
01  LS-COMMENT-WIDTH        PIC 9(4) COMP-5.
01  LS-COMMENT-WORD         PIC X(31).
01  LS-KEYWORD-KIND         PIC X.
01  LS-CHANGED              PIC X.
01  LS-MIXED                PIC X.
*> Of line LS-L's format: the first column of its text, the last
*> (its margin; 0 when the text runs to the end of the line), and the
*> column its comment text starts after the indicator. COBOLX has a
*> margin but does not pad a continued literal to it.
01  LS-TEXT-FROM            PIC 9(4) COMP-5.
01  LS-TEXT-TO              PIC 9(4) COMP-5.
01  LS-COMMENT-FROM         PIC 9(4) COMP-5.
01  LS-TEXT-WIDTH           PIC 9(9) COMP-5.
*> The column a literal continued from line LS-L is padded to (0: it
*> is not padded).
01  LS-PAD-TO               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-TARGET               PIC X(5).
01  LK-CHECK                PIC X.
01  LK-CHANGED              PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID LK-TARGET LK-CHECK
        LK-CHANGED.
    MOVE "N" TO LK-CHANGED
    IF LK-FILE-ID < 1 OR LK-FILE-ID > SS-FILE-COUNT
        GOBACK
    END-IF
    MOVE SF-FIRST-LINE(LK-FILE-ID) TO LS-L
    COMPUTE LS-LAST = SF-FIRST-LINE(LK-FILE-ID)
        + SF-LINE-COUNT(LK-FILE-ID) - 1
    *> Whether any line is in the other format: if none is, the file
    *> is kept as it is, directives included.
    MOVE "N" TO LS-MIXED
    PERFORM VARYING LS-K FROM LS-L BY 1 UNTIL LS-K > LS-LAST
        IF LK-TARGET = "free" AND SL-FORMAT(LS-K) NOT = "F"
           OR LK-TARGET = "fixed" AND SL-FORMAT(LS-K) NOT = "X"
            MOVE "Y" TO LS-MIXED
            EXIT PERFORM
        END-IF
    END-PERFORM
    *> A free file made from fixed lines announces its format.
    IF LK-TARGET = "free" AND LS-MIXED = "Y"
        MOVE 0 TO WS-OUT-COUNT
        MOVE ">>SOURCE FORMAT IS FREE" TO LS-LINE
        PERFORM ADD-OUTPUT
        IF LK-CHECK NOT = "Y"
            MOVE 1 TO LS-I
            PERFORM WRITE-OUTPUT-LINE
        END-IF
        MOVE "Y" TO LK-CHANGED
    END-IF
    PERFORM UNTIL LS-L > LS-LAST
        MOVE 0 TO WS-OUT-COUNT
        MOVE LS-L TO LS-GROUP-FIRST LS-GROUP-LAST
        PERFORM FORMAT-LINE
        PERFORM FLUSH-GROUP
        COMPUTE LS-L = LS-GROUP-LAST + 1
    END-PERFORM
    GOBACK.

*> Output line LS-I on standard output. DISPLAY cannot write an empty
*> line (it writes a space), so the C library's putchar writes the line
*> feed of a blank one.
WRITE-OUTPUT-LINE.
    CALL "PLB-STR-LENGTH" USING WS-OUT-LINE(LS-I) LS-LEN
    IF LS-LEN = 0
        CALL STATIC "putchar" USING BY VALUE 10
    ELSE
        DISPLAY WS-OUT-LINE(LS-I)(1:LS-LEN)
    END-IF.

*> Write (or compare) the output of input lines LS-GROUP-FIRST to
*> LS-GROUP-LAST.
FLUSH-GROUP.
    MOVE "N" TO LS-CHANGED
    IF WS-OUT-COUNT NOT = LS-GROUP-LAST - LS-GROUP-FIRST + 1
        MOVE "Y" TO LS-CHANGED
    ELSE
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-OUT-COUNT
            COMPUTE LS-K = LS-GROUP-FIRST + LS-I - 1
            MOVE LS-K TO LS-NEXT
            PERFORM RAW-LINE
            MOVE SPACES TO LS-LINE
            IF LS-RAW-LEN > 0
                MOVE LS-RAW(1:LS-RAW-LEN) TO LS-LINE
            END-IF
            IF WS-OUT-LINE(LS-I) NOT = LS-LINE
                MOVE "Y" TO LS-CHANGED
            END-IF
        END-PERFORM
    END-IF
    IF LS-CHANGED = "Y"
        MOVE "Y" TO LK-CHANGED
    END-IF
    IF LK-CHECK = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-OUT-COUNT
        PERFORM WRITE-OUTPUT-LINE
    END-PERFORM.

*> LS-RAW(1:LS-RAW-LEN) = line LS-NEXT as read, without trailing
*> spaces.
RAW-LINE.
    MOVE SPACES TO LS-RAW
    MOVE SL-TEXT-LEN(LS-NEXT) TO LS-RAW-LEN
    IF LS-RAW-LEN > LENGTH OF LS-RAW
        MOVE LENGTH OF LS-RAW TO LS-RAW-LEN
    END-IF
    IF LS-RAW-LEN > 0
        MOVE SS-HEAP(SL-TEXT-OFF(LS-NEXT):LS-RAW-LEN) TO LS-RAW
    END-IF
    CALL "PLB-STR-LENGTH" USING LS-RAW LS-RAW-LEN.

ADD-OUTPUT.
    IF WS-OUT-COUNT < OUT-MAX
        ADD 1 TO WS-OUT-COUNT
        MOVE LS-LINE TO WS-OUT-LINE(WS-OUT-COUNT)
    END-IF.

FORMAT-LINE.
    MOVE LS-L TO LS-NEXT
    PERFORM RAW-LINE
    IF SL-IS-DIRECTIVE(LS-L) AND LS-MIXED = "Y"
        PERFORM CHECK-FORMAT-DIRECTIVE
        IF LS-UPPER = "FORMAT"
            *> Dropped: the output has one format throughout.
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM TEXT-COLUMNS
    *> Lines already in the target format, and VARIABLE and xCard
    *> lines that are fixed lines too: no text past column 72, and not
    *> continued.
    IF LK-TARGET = "free" AND SL-FORMAT(LS-L) = "F"
       OR LK-TARGET = "fixed" AND SL-FORMAT(LS-L) = "X"
       OR LK-TARGET = "fixed"
          AND (SL-FORMAT(LS-L) = "V" OR SL-FORMAT(LS-L) = "K")
          AND LS-RAW-LEN <= 72 AND NOT SL-IS-CONTINUATION(LS-L)
          AND NOT (LS-L < LS-LAST AND SL-IS-CONTINUATION(LS-L + 1))
        MOVE SPACES TO LS-LINE
        IF LS-RAW-LEN > 0
            MOVE LS-RAW(1:LS-RAW-LEN) TO LS-LINE
        END-IF
        PERFORM ADD-OUTPUT
        EXIT PARAGRAPH
    END-IF
    IF LK-TARGET = "free"
        PERFORM FIXED-TO-FREE
    ELSE
        PERFORM FREE-TO-FIXED
    END-IF.

*> LS-TEXT-FROM, LS-TEXT-TO, and LS-COMMENT-FROM for line LS-L.
TEXT-COLUMNS.
    MOVE 0 TO LS-PAD-TO
    EVALUATE SL-FORMAT(LS-L)
        WHEN "X"
            MOVE 8 TO LS-TEXT-FROM LS-COMMENT-FROM
            MOVE 72 TO LS-TEXT-TO LS-PAD-TO
        WHEN "V"
            MOVE 8 TO LS-TEXT-FROM LS-COMMENT-FROM
            MOVE 250 TO LS-TEXT-TO LS-PAD-TO
        WHEN "K"
            MOVE 8 TO LS-TEXT-FROM LS-COMMENT-FROM
            MOVE 255 TO LS-TEXT-TO LS-PAD-TO
        WHEN "C"
            MOVE 2 TO LS-TEXT-FROM LS-COMMENT-FROM
            MOVE 255 TO LS-TEXT-TO
        WHEN "O" WHEN "T" WHEN "R"
            MOVE 1 TO LS-TEXT-FROM
            MOVE 2 TO LS-COMMENT-FROM
            MOVE 0 TO LS-TEXT-TO
        WHEN OTHER
            MOVE 1 TO LS-TEXT-FROM LS-COMMENT-FROM
            MOVE 0 TO LS-TEXT-TO
    END-EVALUATE.

*> LS-UPPER = "FORMAT" when directive line LS-L sets the reference
*> format (>>SOURCE [FORMAT] [IS] ..., $SET SOURCEFORMAT(...)).
CHECK-FORMAT-DIRECTIVE.
    MOVE SPACES TO LS-UPPER
    IF SL-CONTENT-LEN(LS-L) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION UPPER-CASE(LS-RAW(SL-CONTENT-COL(LS-L):
                                    SL-CONTENT-LEN(LS-L)))
        TO LS-TEXT
    MOVE 0 TO LS-K
    INSPECT LS-TEXT TALLYING LS-K FOR ALL ">>SOURCE"
    INSPECT LS-TEXT TALLYING LS-K FOR ALL "SOURCEFORMAT"
    IF LS-K > 0
        MOVE "FORMAT" TO LS-UPPER
    END-IF.

*> Fixed to free -----------------------------------------------------

FIXED-TO-FREE.
    MOVE SPACES TO LS-LINE
    EVALUATE TRUE
        WHEN SL-IS-BLANK(LS-L)
            PERFORM ADD-OUTPUT
        WHEN SL-IS-COMMENT(LS-L) OR SL-IS-PAGE(LS-L)
            *> "*" in the indicator column: the comment text after it
            *> (a "*>" there is already one).
            MOVE "*>" TO LS-LINE
            IF LS-RAW-LEN >= LS-COMMENT-FROM
                MOVE LS-RAW(LS-COMMENT-FROM:
                    LS-RAW-LEN - LS-COMMENT-FROM + 1) TO LS-TEXT
                IF LS-TEXT(1:1) = ">"
                    MOVE LS-TEXT(2:) TO LS-LINE(3:)
                ELSE
                    MOVE LS-TEXT TO LS-LINE(3:)
                END-IF
            END-IF
            PERFORM CUT-AT-72
            PERFORM ADD-OUTPUT
        WHEN SL-IS-DEBUG(LS-L)
            MOVE ">>D " TO LS-LINE
            PERFORM AREA-TEXT
            PERFORM BLANK-DEBUG-MARKER
            MOVE FUNCTION TRIM(LS-TEXT LEADING) TO LS-LINE(5:)
            PERFORM ADD-OUTPUT
        WHEN OTHER
            PERFORM AREA-TEXT
            PERFORM JOIN-CONTINUATIONS
            MOVE SPACES TO LS-LINE
            IF LS-TEXT-LEN > 0
                IF LS-TEXT-LEN > LENGTH OF LS-LINE
                    MOVE LENGTH OF LS-LINE TO LS-TEXT-LEN
                END-IF
                MOVE LS-TEXT(1:LS-TEXT-LEN) TO LS-LINE
            END-IF
            PERFORM ADD-OUTPUT
    END-EVALUATE.

*> Keep a fixed comment's text within its old columns 8-72.
CUT-AT-72.
    IF LS-RAW-LEN > 72 AND SL-FORMAT(LS-L) = "X"
        MOVE SPACES TO LS-LINE(68:)
    END-IF.

*> LS-TEXT(1:LS-TEXT-LEN) = the text columns of line LS-L, less
*> trailing spaces, as free-format text starting in column 1.
AREA-TEXT.
    MOVE SPACES TO LS-TEXT
    MOVE 0 TO LS-TEXT-LEN
    IF LS-RAW-LEN < LS-TEXT-FROM
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-LEN = LS-RAW-LEN - LS-TEXT-FROM + 1
    PERFORM TEXT-WIDTH
    IF LS-LEN > LS-TEXT-WIDTH
        MOVE LS-TEXT-WIDTH TO LS-LEN
    END-IF
    MOVE LS-RAW(LS-TEXT-FROM:LS-LEN) TO LS-TEXT
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-TEXT-LEN.

*> LS-TEXT-WIDTH: how many columns of text the format has (to the end
*> of the line when it has no margin).
TEXT-WIDTH.
    IF LS-TEXT-TO > 0
        COMPUTE LS-TEXT-WIDTH = LS-TEXT-TO - LS-TEXT-FROM + 1
    ELSE
        COMPUTE LS-TEXT-WIDTH = LENGTH OF LS-RAW - LS-TEXT-FROM + 1
    END-IF.

*> The marker of a debugging line in X/Open, terminal, COBOLX, and CRT
*> format is in its text columns: blanked.
BLANK-DEBUG-MARKER.
    EVALUATE SL-FORMAT(LS-L)
        WHEN "O" WHEN "C" WHEN "R"
            IF LS-TEXT-FROM = 1
                MOVE SPACE TO LS-TEXT(1:1)
            END-IF
        WHEN "T"
            MOVE SPACES TO LS-TEXT(1:2)
    END-EVALUATE.

*> Append the continuation lines after LS-L to LS-TEXT. A literal open
*> at the end of a line runs through column 72 and goes on after the
*> quote that starts the continuation's text; anything else goes on
*> with the continuation's first character.
JOIN-CONTINUATIONS.
    MOVE LS-L TO LS-J
    *> A literal open at the end of the first line runs through the
    *> margin: its trailing spaces count. Without a margin it ends
    *> where the line does.
    IF LS-L < LS-LAST AND LS-PAD-TO > 0
        IF SL-IS-CONTINUATION(LS-L + 1)
           AND SL-OPEN-QUOTE(LS-L) NOT = SPACE
            COMPUTE LS-TEXT-LEN = LS-PAD-TO - LS-TEXT-FROM + 1
        END-IF
    END-IF
    PERFORM UNTIL LS-J >= LS-LAST
        COMPUTE LS-NEXT = LS-J + 1
        IF NOT SL-IS-CONTINUATION(LS-NEXT)
            EXIT PERFORM
        END-IF
        PERFORM RAW-LINE
        MOVE SL-CONTENT-COL(LS-NEXT) TO LS-POS
        MOVE SL-CONTENT-LEN(LS-NEXT) TO LS-LEN
        *> This line's own open literal, if another continuation
        *> follows, also runs through the margin.
        IF LS-NEXT < LS-LAST AND LS-LEN > 0 AND LS-PAD-TO > 0
            IF SL-IS-CONTINUATION(LS-NEXT + 1)
               AND SL-OPEN-QUOTE(LS-NEXT) NOT = SPACE
               AND LS-POS <= LS-PAD-TO
                COMPUTE LS-LEN = LS-PAD-TO + 1 - LS-POS
            END-IF
        END-IF
        IF LS-LEN > 0
            IF SL-OPEN-QUOTE(LS-J) NOT = SPACE
               AND LS-RAW(LS-POS:1) = SL-OPEN-QUOTE(LS-J)
                ADD 1 TO LS-POS
                SUBTRACT 1 FROM LS-LEN
            END-IF
            *> A doubled quote split by the margin (see plbstream): the
            *> line before ends with a quote in column 72, and this one
            *> starts with two; the first only resumes the literal.
            IF SL-OPEN-QUOTE(LS-J) = SPACE AND LS-LEN > 1
               AND LS-TEXT-LEN > 0 AND LS-PAD-TO > 0
               AND SL-CONTENT-COL(LS-J) + SL-CONTENT-LEN(LS-J) - 1
                   = LS-PAD-TO
               AND (LS-TEXT(LS-TEXT-LEN:1) = '"'
                    OR LS-TEXT(LS-TEXT-LEN:1) = "'")
               AND LS-RAW(LS-POS:1) = LS-TEXT(LS-TEXT-LEN:1)
               AND LS-RAW(LS-POS + 1:1) = LS-TEXT(LS-TEXT-LEN:1)
                ADD 1 TO LS-POS
                SUBTRACT 1 FROM LS-LEN
            END-IF
            IF LS-LEN > 0
                MOVE LS-RAW(LS-POS:LS-LEN)
                    TO LS-TEXT(LS-TEXT-LEN + 1:LS-LEN)
                ADD LS-LEN TO LS-TEXT-LEN
            END-IF
            *> An inline comment of the continuation line follows.
            IF SL-COMMENT-COL(LS-NEXT) > 0
                COMPUTE LS-LEN = LS-RAW-LEN - SL-COMMENT-COL(LS-NEXT)
                    + 1
                MOVE " " TO LS-TEXT(LS-TEXT-LEN + 1:1)
                MOVE LS-RAW(SL-COMMENT-COL(LS-NEXT):LS-LEN)
                    TO LS-TEXT(LS-TEXT-LEN + 2:LS-LEN)
                COMPUTE LS-TEXT-LEN = LS-TEXT-LEN + 1 + LS-LEN
            END-IF
        END-IF
        MOVE LS-NEXT TO LS-J LS-GROUP-LAST
    END-PERFORM
    *> Trailing spaces end the text either way: after the last
    *> continuation, and when there was none after all (no padding
    *> either).
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-TEXT-LEN.

*> Free to fixed -----------------------------------------------------

FREE-TO-FIXED.
    MOVE SPACES TO LS-LINE
    EVALUATE TRUE
        WHEN SL-IS-BLANK(LS-L)
            PERFORM ADD-OUTPUT
        WHEN SL-IS-PAGE(LS-L) AND SL-FORMAT(LS-L) NOT = "F"
            *> A page eject stays one: "/" in column 7.
            MOVE "/" TO LS-LINE(7:1)
            IF LS-RAW-LEN >= LS-COMMENT-FROM
                MOVE LS-RAW(LS-COMMENT-FROM:
                    LS-RAW-LEN - LS-COMMENT-FROM + 1) TO LS-LINE(8:)
            END-IF
            PERFORM ADD-OUTPUT
        WHEN SL-IS-COMMENT(LS-L) OR SL-IS-PAGE(LS-L)
            *> The text after "*>", or after the indicator.
            MOVE SPACES TO LS-COMMENT
            MOVE 0 TO LS-COMMENT-LEN
            IF SL-FORMAT(LS-L) = "F"
                COMPUTE LS-POS = SL-COMMENT-COL(LS-L) + 2
            ELSE
                MOVE LS-COMMENT-FROM TO LS-POS
            END-IF
            IF SL-COMMENT-COL(LS-L) > 0 AND LS-POS <= LS-RAW-LEN
                COMPUTE LS-COMMENT-LEN = LS-RAW-LEN - LS-POS + 1
                MOVE LS-RAW(LS-POS:LS-COMMENT-LEN) TO LS-COMMENT
            END-IF
            PERFORM WRITE-COMMENT-LINES
        WHEN SL-IS-DIRECTIVE(LS-L)
            MOVE LS-RAW(SL-CONTENT-COL(LS-L):) TO LS-LINE(8:)
            PERFORM ADD-OUTPUT
        WHEN OTHER
            PERFORM SPLIT-FREE-LINE
            *> A line continued in a format other than fixed:
            *> the whole statement text, joined, to be split again.
            IF LS-L < LS-LAST
                IF SL-IS-CONTINUATION(LS-L + 1)
                    PERFORM JOIN-FOR-FIXED
                END-IF
            END-IF
            IF SL-IS-DEBUG(LS-L)
                MOVE "D" TO LS-INDICATOR
            ELSE
                MOVE SPACE TO LS-INDICATOR
            END-IF
            *> An inline comment that will not fit goes first.
            IF LS-COMMENT-LEN > 0
               AND LS-START + LS-CODE-LEN + 1 + LS-COMMENT-LEN > 73
                *> Its text, without the "*>", on lines of its own.
                MOVE SPACES TO LS-TEXT
                IF LS-COMMENT-LEN > 2
                    MOVE LS-COMMENT(3:LS-COMMENT-LEN - 2) TO LS-TEXT
                END-IF
                MOVE LS-TEXT(1:LENGTH OF LS-COMMENT) TO LS-COMMENT
                SUBTRACT 2 FROM LS-COMMENT-LEN
                PERFORM WRITE-COMMENT-LINES
                MOVE 0 TO LS-COMMENT-LEN
            END-IF
            PERFORM WRITE-CODE-LINES
    END-EVALUATE.

*> The text of line LS-L and its continuations, from its first
*> character, as the code to write; the inline comment of the last is
*> kept with it by JOIN-CONTINUATIONS.
JOIN-FOR-FIXED.
    PERFORM AREA-TEXT
    PERFORM JOIN-CONTINUATIONS
    MOVE SPACES TO LS-CODE LS-COMMENT
    MOVE 0 TO LS-COMMENT-LEN
    MOVE 1 TO LS-POS
    PERFORM UNTIL LS-POS > LS-TEXT-LEN
        IF LS-TEXT(LS-POS:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-POS
    END-PERFORM
    COMPUTE LS-CODE-LEN = LS-TEXT-LEN - LS-POS + 1
    IF LS-CODE-LEN > 0
        MOVE LS-TEXT(LS-POS:LS-CODE-LEN) TO LS-CODE
    ELSE
        MOVE 0 TO LS-CODE-LEN
    END-IF.

*> LS-CODE and LS-COMMENT (with its "*>") of free line LS-L, and the
*> column the code starts in.
SPLIT-FREE-LINE.
    MOVE SPACES TO LS-CODE LS-COMMENT
    MOVE 0 TO LS-CODE-LEN LS-COMMENT-LEN
    MOVE SL-CONTENT-COL(LS-L) TO LS-POS
    MOVE SL-CONTENT-LEN(LS-L) TO LS-CODE-LEN
    *> A debugging line's ">>D" is not code.
    IF SL-IS-DEBUG(LS-L) AND LS-CODE-LEN > 3
        IF FUNCTION UPPER-CASE(LS-RAW(LS-POS:3)) = ">>D"
            ADD 3 TO LS-POS
            SUBTRACT 3 FROM LS-CODE-LEN
            PERFORM UNTIL LS-CODE-LEN = 0
                IF LS-RAW(LS-POS:1) NOT = SPACE
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-POS
                SUBTRACT 1 FROM LS-CODE-LEN
            END-PERFORM
        END-IF
    END-IF
    IF LS-CODE-LEN > 0
        MOVE LS-RAW(LS-POS:LS-CODE-LEN) TO LS-CODE
    END-IF
    IF SL-COMMENT-COL(LS-L) > 0
        COMPUTE LS-COMMENT-LEN = LS-RAW-LEN - SL-COMMENT-COL(LS-L) + 1
        MOVE LS-RAW(SL-COMMENT-COL(LS-L):LS-COMMENT-LEN) TO LS-COMMENT
    END-IF
    *> Column 8 plus the indentation, in area B unless it is a header
    *> or a record entry, which belong in area A. The indentation is
    *> counted from the first column of the format's text.
    IF SL-CONTENT-COL(LS-L) > LS-TEXT-FROM
        COMPUTE LS-INDENT = SL-CONTENT-COL(LS-L) - LS-TEXT-FROM
    ELSE
        MOVE 0 TO LS-INDENT
    END-IF
    IF LS-INDENT > 24
        MOVE 24 TO LS-INDENT
    END-IF
    COMPUTE LS-START = 8 + LS-INDENT
    PERFORM CHECK-AREA-A
    IF LS-UPPER = "A"
        MOVE 8 TO LS-START
    END-IF.

*> LS-UPPER = "A" when LS-CODE starts a division, section, paragraph,
*> or record (01, 77, FD, SD, RD, CD).
CHECK-AREA-A.
    MOVE SPACES TO LS-UPPER
    MOVE FUNCTION UPPER-CASE(LS-CODE(1:80)) TO LS-TEXT
    EVALUATE TRUE
        WHEN LS-TEXT(1:3) = "01 " OR LS-TEXT(1:3) = "77 "
        WHEN LS-TEXT(1:2) = "1 " AND LS-CODE-LEN > 2
        WHEN LS-TEXT(1:3) = "FD " OR LS-TEXT(1:3) = "SD "
        WHEN LS-TEXT(1:3) = "RD " OR LS-TEXT(1:3) = "CD "
            MOVE "A" TO LS-UPPER
        WHEN LS-CODE-LEN = 0
            CONTINUE
        WHEN OTHER
            MOVE 0 TO LS-K
            INSPECT LS-TEXT(1:LS-CODE-LEN)
                TALLYING LS-K FOR ALL " DIVISION" ALL " SECTION"
            *> NAME. alone on the line is a paragraph header, unless
            *> NAME is a reserved word (EXIT., CONTINUE.).
            IF LS-CODE-LEN > 1
                IF LS-CODE(LS-CODE-LEN:1) = "."
                    MOVE 0 TO LS-J
                    INSPECT LS-CODE(1:LS-CODE-LEN) TALLYING LS-J
                        FOR ALL SPACE
                    IF LS-J = 0 AND LS-CODE-LEN <= 32
                        MOVE SPACES TO LS-COMMENT-WORD
                        MOVE LS-TEXT(1:LS-CODE-LEN - 1)
                            TO LS-COMMENT-WORD
                        CALL "PLB-KW-LOOKUP" USING LS-COMMENT-WORD
                            LS-KEYWORD-KIND
                        IF LS-KEYWORD-KIND = SPACE
                            ADD 1 TO LS-K
                        END-IF
                    END-IF
                END-IF
            END-IF
            IF LS-K > 0
                MOVE "A" TO LS-UPPER
            END-IF
    END-EVALUATE.

*> LS-COMMENT(1:LS-COMMENT-LEN) as comment lines, 65 characters each,
*> split at spaces where possible.
WRITE-COMMENT-LINES.
    MOVE 1 TO LS-POS
    IF LS-COMMENT-LEN = 0
        MOVE SPACES TO LS-LINE
        MOVE "*" TO LS-LINE(7:1)
        PERFORM ADD-OUTPUT
    END-IF
    *> Lines after the first start one column in, after a space.
    MOVE 8 TO LS-COMMENT-START
    MOVE 65 TO LS-COMMENT-WIDTH
    PERFORM UNTIL LS-POS > LS-COMMENT-LEN
        COMPUTE LS-LEN = LS-COMMENT-LEN - LS-POS + 1
        IF LS-LEN > LS-COMMENT-WIDTH
            MOVE LS-COMMENT-WIDTH TO LS-LEN
            PERFORM VARYING LS-K FROM LS-COMMENT-WIDTH BY -1 UNTIL LS-K < 20
                IF LS-COMMENT(LS-POS + LS-K - 1:1) = SPACE
                    MOVE LS-K TO LS-LEN
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
        MOVE SPACES TO LS-LINE
        MOVE "*" TO LS-LINE(7:1)
        MOVE LS-COMMENT(LS-POS:LS-LEN) TO LS-LINE(LS-COMMENT-START:LS-LEN)
        PERFORM ADD-OUTPUT
        ADD LS-LEN TO LS-POS
        MOVE 9 TO LS-COMMENT-START
        MOVE 64 TO LS-COMMENT-WIDTH
    END-PERFORM.

*> LS-CODE(1:LS-CODE-LEN) from column LS-START, as many lines as it
*> takes; LS-COMMENT after the last one when it fits there.
WRITE-CODE-LINES.
    MOVE 1 TO LS-POS
    MOVE SPACE TO LS-OPEN
    COMPUTE LS-WRAP-START = LS-START + 4
    IF LS-WRAP-START > 40
        MOVE 40 TO LS-WRAP-START
    END-IF
    PERFORM UNTIL LS-POS > LS-CODE-LEN
        COMPUTE LS-WIDTH = 73 - LS-START
        MOVE SPACES TO LS-LINE
        MOVE LS-INDICATOR TO LS-LINE(7:1)
        IF LS-OPEN NOT = SPACE
            *> Continuing a literal: "-" in column 7, then its quote.
            MOVE "-" TO LS-LINE(7:1)
            MOVE LS-OPEN TO LS-LINE(LS-START:1)
            ADD 1 TO LS-START
            SUBTRACT 1 FROM LS-WIDTH
        END-IF
        COMPUTE LS-LEN = LS-CODE-LEN - LS-POS + 1
        IF LS-LEN > LS-WIDTH
            PERFORM FIND-BREAK
        END-IF
        MOVE LS-CODE(LS-POS:LS-LEN) TO LS-LINE(LS-START:LS-LEN)
        PERFORM TRACK-QUOTES
        ADD LS-LEN TO LS-POS
        *> The rest: four columns further in, after spaces.
        PERFORM UNTIL LS-POS > LS-CODE-LEN OR LS-OPEN NOT = SPACE
            IF LS-CODE(LS-POS:1) NOT = SPACE
                EXIT PERFORM
            END-IF
            ADD 1 TO LS-POS
        END-PERFORM
        IF LS-POS > LS-CODE-LEN AND LS-COMMENT-LEN > 0
            CALL "PLB-STR-LENGTH" USING LS-LINE LS-K
            IF LS-K + 1 + LS-COMMENT-LEN <= 72
                MOVE LS-COMMENT(1:LS-COMMENT-LEN)
                    TO LS-LINE(LS-K + 2:LS-COMMENT-LEN)
            END-IF
        END-IF
        PERFORM ADD-OUTPUT
        IF LS-OPEN = SPACE
            MOVE LS-WRAP-START TO LS-START
        ELSE
            *> A continued literal goes on in area B.
            MOVE 12 TO LS-START
        END-IF
    END-PERFORM.

*> LS-LEN = how much of the code from LS-POS fits in LS-WIDTH: up to
*> the last space outside a literal, or, inside a literal that will
*> not fit, the whole width (the literal continues).
FIND-BREAK.
    MOVE 0 TO LS-BREAK
    MOVE LS-OPEN TO LS-QUOTE
    PERFORM VARYING LS-K FROM 0 BY 1 UNTIL LS-K >= LS-WIDTH
        MOVE LS-POS TO LS-I
        ADD LS-K TO LS-I
        EVALUATE TRUE
            WHEN LS-QUOTE = SPACE
                 AND (LS-CODE(LS-I:1) = '"' OR LS-CODE(LS-I:1) = "'")
                MOVE LS-CODE(LS-I:1) TO LS-QUOTE
            WHEN LS-QUOTE NOT = SPACE AND LS-CODE(LS-I:1) = LS-QUOTE
                MOVE SPACE TO LS-QUOTE
            WHEN LS-QUOTE = SPACE AND LS-CODE(LS-I:1) = SPACE
                MOVE LS-K TO LS-BREAK
        END-EVALUATE
    END-PERFORM
    IF LS-BREAK > 0
        MOVE LS-BREAK TO LS-LEN
    ELSE
        MOVE LS-WIDTH TO LS-LEN
    END-IF.

*> LS-OPEN = the quote of a literal still open at the end of the part
*> just written (LS-CODE from LS-POS, LS-LEN characters).
TRACK-QUOTES.
    PERFORM VARYING LS-K FROM LS-POS BY 1
            UNTIL LS-K >= LS-POS + LS-LEN
        EVALUATE TRUE
            WHEN LS-OPEN = SPACE
                 AND (LS-CODE(LS-K:1) = '"' OR LS-CODE(LS-K:1) = "'")
                MOVE LS-CODE(LS-K:1) TO LS-OPEN
            WHEN LS-OPEN NOT = SPACE AND LS-CODE(LS-K:1) = LS-OPEN
                MOVE SPACE TO LS-OPEN
        END-EVALUATE
    END-PERFORM.
END PROGRAM PLB-FORMAT.
