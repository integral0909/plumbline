*> ---------------------------------------------------------------
*> plbclass: classification of individual source lines.
*>
*> These routines look at one tab-expanded physical line at a time
*> and decide what it is (code, comment, directive, ...) and where
*> its significant text lies. They know nothing about files, so they
*> can be tested on literal text.
*>
*> Reference format summary:
*>
*>   fixed  cols 1-6 sequence area, col 7 indicator, cols 8-11
*>          area A, cols 12-72 area B, cols 73+ ignored.
*>          Indicators: space code, * comment, / page eject,
*>          - continuation, D/d debugging line, $ directive.
*>   free   no areas. "*>" starts a comment anywhere outside a
*>          literal; ">>" starts a compiler directive; ">>D " marks
*>          a debugging line.
*>
*> In both formats "*>" inside an alphanumeric literal is text, not a
*> comment, so the scanner tracks literals, including doubled quotes
*> ('It''s') and literals continued from the previous line.
*> ---------------------------------------------------------------

*> PLB-SRC-SCAN: scan LINE from column FROM to column TO.
*> QUOTE-IN is the quote character of a literal already open at FROM
*> (or space). Outputs the first and last non-space columns before
*> any inline comment (0 if none), the column where "*>" starts (0 if
*> none), and the quote of a literal still open at the end.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-SCAN.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-POS                  PIC 9(4) COMP-5.
01  LS-CH                   PIC X.
01  LS-QUOTE                PIC X.
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-FROM                 PIC 9(4) COMP-5.
01  LK-TO                   PIC 9(4) COMP-5.
01  LK-QUOTE-IN             PIC X.
01  LK-FIRST                PIC 9(4) COMP-5.
01  LK-LAST                 PIC 9(4) COMP-5.
01  LK-COMMENT-COL          PIC 9(4) COMP-5.
01  LK-QUOTE-OUT            PIC X.
PROCEDURE DIVISION USING LK-LINE LK-FROM LK-TO LK-QUOTE-IN
        LK-FIRST LK-LAST LK-COMMENT-COL LK-QUOTE-OUT.
    MOVE 0 TO LK-FIRST LK-LAST LK-COMMENT-COL
    MOVE LK-QUOTE-IN TO LS-QUOTE
    MOVE LK-FROM TO LS-POS
    PERFORM UNTIL LS-POS > LK-TO
               OR LS-POS > FUNCTION LENGTH(LK-LINE)
        MOVE LK-LINE(LS-POS:1) TO LS-CH
        IF LS-QUOTE = SPACE
            IF LS-CH = "*" AND LS-POS < LK-TO
               AND LK-LINE(LS-POS + 1:1) = ">"
                MOVE LS-POS TO LK-COMMENT-COL
                EXIT PERFORM
            END-IF
            IF LS-CH = '"' OR LS-CH = "'"
                MOVE LS-CH TO LS-QUOTE
            END-IF
        ELSE
            IF LS-CH = LS-QUOTE
                IF LS-POS < LK-TO AND LK-LINE(LS-POS + 1:1) = LS-QUOTE
                    *> A doubled quote stands for one quote character
                    *> and does not end the literal.
                    ADD 1 TO LS-POS
                ELSE
                    MOVE SPACE TO LS-QUOTE
                END-IF
            END-IF
        END-IF
        IF LS-CH NOT = SPACE
            IF LK-FIRST = 0
                MOVE LS-POS TO LK-FIRST
            END-IF
            MOVE LS-POS TO LK-LAST
        END-IF
        ADD 1 TO LS-POS
    END-PERFORM
    MOVE LS-QUOTE TO LK-QUOTE-OUT
    GOBACK.
END PROGRAM PLB-SRC-SCAN.

*> PLB-SRC-CLASSIFY-FIXED: classify a fixed-format line, whose program
*> text ends at column 72 (see PLB-SRC-CLASSIFY-COLUMNS).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-FIXED.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-MARGIN               PIC 9(4) COMP-5 VALUE 72.
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN PLB-CLASSIFIED.
    CALL "PLB-SRC-CLASSIFY-COLUMNS" USING LK-LINE LK-LENGTH LK-QUOTE-IN
        WS-MARGIN PLB-CLASSIFIED
    GOBACK.
END PROGRAM PLB-SRC-CLASSIFY-FIXED.

*> PLB-SRC-CLASSIFY-VARIABLE: classify a line of Micro Focus's VARIABLE
*> format: as fixed format, but the program text runs to column 250,
*> with no identification area after column 72.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-VARIABLE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-MARGIN               PIC 9(4) COMP-5 VALUE 250.
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN PLB-CLASSIFIED.
    CALL "PLB-SRC-CLASSIFY-COLUMNS" USING LK-LINE LK-LENGTH LK-QUOTE-IN
        WS-MARGIN PLB-CLASSIFIED
    GOBACK.
END PROGRAM PLB-SRC-CLASSIFY-VARIABLE.

*> PLB-SRC-CLASSIFY-COLUMNS: classify a line in fixed columns: the
*> sequence area in 1 to 6, the indicator in 7, the program text from
*> 8 to MARGIN. LENGTH is the number of significant characters in
*> LINE. QUOTE-IN is the open-literal quote carried from the previous
*> code line; it only matters for continuation lines.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-COLUMNS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-FROM                 PIC 9(4) COMP-5.
01  LS-TO                   PIC 9(4) COMP-5.
01  LS-FIRST                PIC 9(4) COMP-5.
01  LS-LAST                 PIC 9(4) COMP-5.
01  LS-QUOTE                PIC X.
01  LS-LEAD                 PIC 9(4) COMP-5.
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
01  LK-MARGIN               PIC 9(4) COMP-5.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN LK-MARGIN
        PLB-CLASSIFIED.
    MOVE "B" TO CL-KIND
    MOVE SPACE TO CL-INDICATOR CL-OPEN-QUOTE CL-PROBLEM
    MOVE "N" TO CL-AREA-A
    MOVE 0 TO CL-CONTENT-COL CL-CONTENT-LEN CL-COMMENT-COL

    *> Nothing past the sequence area: a blank line.
    IF LK-LENGTH < 7
        GOBACK
    END-IF

    MOVE LK-LINE(7:1) TO CL-INDICATOR
    MOVE 8 TO LS-FROM
    MOVE LK-MARGIN TO LS-TO
    IF LK-LENGTH < LK-MARGIN
        *> plumbline: ignore move-truncation -- a line is at most 1024 columns
        MOVE LK-LENGTH TO LS-TO
    END-IF

    EVALUATE CL-INDICATOR
        WHEN "*"
            MOVE "*" TO CL-KIND
            MOVE 7 TO CL-COMMENT-COL
        WHEN "/"
            MOVE "/" TO CL-KIND
            MOVE 7 TO CL-COMMENT-COL
        WHEN "$"
            MOVE ">" TO CL-KIND
            MOVE 7 TO LS-FROM
            PERFORM SCAN-CONTENT
        *> A directive may start in the indicator column: ">> IF".
        WHEN ">"
            IF LK-LENGTH >= 8 AND LK-LINE(8:1) = ">"
                MOVE ">" TO CL-KIND
                MOVE 7 TO LS-FROM
                PERFORM SCAN-CONTENT
            ELSE
                MOVE "I" TO CL-PROBLEM
                MOVE "C" TO CL-KIND
                PERFORM SCAN-CONTENT
            END-IF
        WHEN "D"
        WHEN "d"
            MOVE "D" TO CL-KIND
            PERFORM SCAN-CONTENT
        WHEN "-"
            MOVE "-" TO CL-KIND
            PERFORM SCAN-CONTINUATION
        WHEN SPACE
            PERFORM SCAN-CONTENT
            EVALUATE TRUE
                WHEN CL-CONTENT-LEN = 0 AND CL-COMMENT-COL > 0
                    MOVE "*" TO CL-KIND
                WHEN CL-CONTENT-LEN = 0
                    MOVE "B" TO CL-KIND
                WHEN LK-LINE(CL-CONTENT-COL:2) = ">>"
                    MOVE ">" TO CL-KIND
                *> Micro Focus directives ($SET, $DISPLAY, $IF) may be
                *> indented; no COBOL text starts with $.
                WHEN LK-LINE(CL-CONTENT-COL:1) = "$"
                    MOVE ">" TO CL-KIND
                WHEN OTHER
                    MOVE "C" TO CL-KIND
            END-EVALUATE
        WHEN OTHER
            *> Treat the text as code so later stages still see it;
            *> the caller reports the bad indicator.
            MOVE "I" TO CL-PROBLEM
            MOVE "C" TO CL-KIND
            PERFORM SCAN-CONTENT
    END-EVALUATE
    GOBACK.

SCAN-CONTENT.
    CALL "PLB-SRC-SCAN" USING LK-LINE LS-FROM LS-TO SPACE
        LS-FIRST LS-LAST CL-COMMENT-COL CL-OPEN-QUOTE
    PERFORM SET-CONTENT.

*> On a continuation line that continues a literal, the literal
*> resumes after the first quote in area B. Otherwise the line is
*> scanned like any other.
SCAN-CONTINUATION.
    MOVE SPACE TO LS-QUOTE
    IF LK-QUOTE-IN NOT = SPACE
        CALL "PLB-SRC-FIRST-FROM" USING LK-LINE LS-FROM LS-TO LS-LEAD
        IF LS-LEAD > 0
            IF LK-LINE(LS-LEAD:1) = LK-QUOTE-IN
                MOVE LK-QUOTE-IN TO LS-QUOTE
                COMPUTE LS-FROM = LS-LEAD + 1
            END-IF
        END-IF
    END-IF
    CALL "PLB-SRC-SCAN" USING LK-LINE LS-FROM LS-TO LS-QUOTE
        LS-FIRST LS-LAST CL-COMMENT-COL CL-OPEN-QUOTE
    IF LS-QUOTE NOT = SPACE
        *> The opening quote belongs to the content.
        MOVE LS-LEAD TO LS-FIRST
        IF LS-LAST = 0
            MOVE LS-LEAD TO LS-LAST
        END-IF
    END-IF
    PERFORM SET-CONTENT.

SET-CONTENT.
    IF LS-FIRST > 0
        MOVE LS-FIRST TO CL-CONTENT-COL
        COMPUTE CL-CONTENT-LEN = LS-LAST - LS-FIRST + 1
        IF LS-FIRST >= 8 AND LS-FIRST <= 11
            MOVE "Y" TO CL-AREA-A
        END-IF
    END-IF.
END PROGRAM PLB-SRC-CLASSIFY-COLUMNS.

*> PLB-SRC-FIRST-FROM: first non-space column of LINE within
*> FROM..TO, or 0.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-FIRST-FROM.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-POS                  PIC 9(4) COMP-5.
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-FROM                 PIC 9(4) COMP-5.
01  LK-TO                   PIC 9(4) COMP-5.
01  LK-FIRST                PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-LINE LK-FROM LK-TO LK-FIRST.
    MOVE 0 TO LK-FIRST
    PERFORM VARYING LS-POS FROM LK-FROM BY 1
            UNTIL LS-POS > LK-TO OR LS-POS > FUNCTION LENGTH(LK-LINE)
        IF LK-LINE(LS-POS:1) NOT = SPACE
            MOVE LS-POS TO LK-FIRST
            EXIT PERFORM
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-SRC-FIRST-FROM.

*> PLB-SRC-CLASSIFY-FREE: classify a free-format line.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-FREE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-FROM                 PIC 9(4) COMP-5.
01  LS-TO                   PIC 9(4) COMP-5.
01  LS-FIRST                PIC 9(4) COMP-5.
01  LS-LAST                 PIC 9(4) COMP-5.
01  LS-LEAD                 PIC 9(4) COMP-5.
01  LS-WORD                 PIC X(5).
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN PLB-CLASSIFIED.
    MOVE "B" TO CL-KIND
    MOVE SPACE TO CL-INDICATOR CL-OPEN-QUOTE CL-PROBLEM
    MOVE "N" TO CL-AREA-A
    MOVE 0 TO CL-CONTENT-COL CL-CONTENT-LEN CL-COMMENT-COL

    MOVE 1 TO LS-FROM
    *> plumbline: ignore move-truncation -- a line is at most 1024 columns
    MOVE LK-LENGTH TO LS-TO
    CALL "PLB-SRC-FIRST-FROM" USING LK-LINE LS-FROM LS-TO LS-LEAD
    IF LS-LEAD = 0
        GOBACK
    END-IF

    MOVE SPACES TO LS-WORD
    MOVE LK-LINE(LS-LEAD:) TO LS-WORD
    CALL "PLB-STR-UPPER" USING LS-WORD
    EVALUATE TRUE
        WHEN LS-WORD(1:2) = "*>"
            MOVE "*" TO CL-KIND
            MOVE LS-LEAD TO CL-COMMENT-COL
        WHEN LS-WORD(1:4) = ">>D "
            *> Debugging line: the content follows the marker.
            MOVE "D" TO CL-KIND
            COMPUTE LS-FROM = LS-LEAD + 4
            PERFORM SCAN-CONTENT
        WHEN LS-WORD(1:2) = ">>"
        *> Micro Focus directives: $SET, $IF, $ELSE, $END, $DISPLAY.
        WHEN LS-WORD(1:1) = "$"
            MOVE ">" TO CL-KIND
            MOVE LS-LEAD TO LS-FROM
            PERFORM SCAN-CONTENT
        WHEN OTHER
            *> The first character is not the start of "*>", so the
            *> line always has content.
            MOVE "C" TO CL-KIND
            MOVE LS-LEAD TO LS-FROM
            PERFORM SCAN-CONTENT
    END-EVALUATE
    GOBACK.

SCAN-CONTENT.
    CALL "PLB-SRC-SCAN" USING LK-LINE LS-FROM LS-TO SPACE
        LS-FIRST LS-LAST CL-COMMENT-COL CL-OPEN-QUOTE
    IF LS-FIRST > 0
        MOVE LS-FIRST TO CL-CONTENT-COL
        COMPUTE CL-CONTENT-LEN = LS-LAST - LS-FIRST + 1
    END-IF.
END PROGRAM PLB-SRC-CLASSIFY-FREE.

*> PLB-SRC-CLASSIFY-XOPEN and PLB-SRC-CLASSIFY-TERMINAL: free format
*> with an indicator in column 1, as X/Open's free-form format and
*> ACUCOBOL's terminal format have it:
*>
*>   X/Open    * comment   / page eject   D and a space: debugging line
*>   terminal  * comment   \D: debugging line   - continuation line
*>
*> Any other line is free format from column 1.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-XOPEN.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-STYLE                PIC X VALUE "O".
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN PLB-CLASSIFIED.
    CALL "PLB-SRC-CLASSIFY-INDICATED" USING LK-LINE LK-LENGTH
        LK-QUOTE-IN WS-STYLE PLB-CLASSIFIED
    GOBACK.
END PROGRAM PLB-SRC-CLASSIFY-XOPEN.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-TERMINAL.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-STYLE                PIC X VALUE "T".
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN PLB-CLASSIFIED.
    CALL "PLB-SRC-CLASSIFY-INDICATED" USING LK-LINE LK-LENGTH
        LK-QUOTE-IN WS-STYLE PLB-CLASSIFIED
    GOBACK.
END PROGRAM PLB-SRC-CLASSIFY-TERMINAL.

*> PLB-SRC-CLASSIFY-INDICATED: the line in STYLE O (X/Open) or T
*> (terminal). A debugging line is classified as free format with its
*> marker blanked, so that its content keeps its columns.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-INDICATED.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-COPY                 PIC X(1024).
01  WS-LENGTH               PIC 9(9) COMP-5.
01  WS-MARGIN               PIC 9(4) COMP-5.
LINKAGE SECTION.
01  LK-LINE                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-QUOTE-IN             PIC X.
01  LK-STYLE                PIC X.
COPY "plbcls.cpy".
PROCEDURE DIVISION USING LK-LINE LK-LENGTH LK-QUOTE-IN LK-STYLE
        PLB-CLASSIFIED.
    IF LK-LENGTH = 0
        CALL "PLB-SRC-CLASSIFY-FREE" USING LK-LINE LK-LENGTH
            LK-QUOTE-IN PLB-CLASSIFIED
        GOBACK
    END-IF
    EVALUATE TRUE
        WHEN LK-LINE(1:1) = "*"
            PERFORM COMMENT-LINE
            MOVE "*" TO CL-KIND CL-INDICATOR
        WHEN LK-LINE(1:1) = "/" AND LK-STYLE = "O"
            PERFORM COMMENT-LINE
            MOVE "/" TO CL-KIND CL-INDICATOR
        WHEN LK-STYLE = "O" AND (LK-LINE(1:1) = "D" OR "d")
             AND (LK-LENGTH = 1 OR LK-LINE(2:1) = SPACE)
            MOVE LK-LINE TO WS-COPY
            MOVE SPACE TO WS-COPY(1:1)
            PERFORM DEBUGGING-LINE
        WHEN LK-STYLE = "T" AND LK-LENGTH >= 2
             AND LK-LINE(1:1) = "\" AND (LK-LINE(2:1) = "D" OR "d")
            MOVE LK-LINE TO WS-COPY
            MOVE SPACES TO WS-COPY(1:2)
            PERFORM DEBUGGING-LINE
        WHEN LK-STYLE = "T" AND LK-LINE(1:1) = "-"
            PERFORM CONTINUATION-LINE
        WHEN OTHER
            CALL "PLB-SRC-CLASSIFY-FREE" USING LK-LINE LK-LENGTH
                LK-QUOTE-IN PLB-CLASSIFIED
    END-EVALUATE
    GOBACK.

COMMENT-LINE.
    MOVE SPACE TO CL-OPEN-QUOTE CL-PROBLEM
    MOVE "N" TO CL-AREA-A
    MOVE 0 TO CL-CONTENT-COL CL-CONTENT-LEN
    MOVE 1 TO CL-COMMENT-COL.

*> A continuation line, as fixed format reads one: the line is put
*> after six blanks, so that its - is in column 7, and the columns
*> found are moved back.
CONTINUATION-LINE.
    MOVE SPACES TO WS-COPY
    IF LK-LENGTH > 1000
        MOVE 1000 TO WS-LENGTH
    ELSE
        MOVE LK-LENGTH TO WS-LENGTH
    END-IF
    MOVE LK-LINE(1:WS-LENGTH) TO WS-COPY(7:WS-LENGTH)
    COMPUTE WS-MARGIN = WS-LENGTH + 6
    COMPUTE WS-LENGTH = WS-LENGTH + 6
    CALL "PLB-SRC-CLASSIFY-COLUMNS" USING WS-COPY WS-LENGTH LK-QUOTE-IN
        WS-MARGIN PLB-CLASSIFIED
    IF CL-CONTENT-COL > 6
        SUBTRACT 6 FROM CL-CONTENT-COL
    END-IF
    IF CL-COMMENT-COL > 6
        SUBTRACT 6 FROM CL-COMMENT-COL
    END-IF.

DEBUGGING-LINE.
    CALL "PLB-SRC-CLASSIFY-FREE" USING WS-COPY LK-LENGTH LK-QUOTE-IN
        PLB-CLASSIFIED
    IF CL-KIND = "C"
        MOVE "D" TO CL-KIND
    END-IF
    MOVE "D" TO CL-INDICATOR.
END PROGRAM PLB-SRC-CLASSIFY-INDICATED.

*> PLB-SRC-DIRECTIVE-FORMAT: decide whether directive TEXT switches
*> the reference format. FORMAT receives:
*>   "X" fixed, "F" free, "V" variable, "O" X/Open free form, "T"
*>   ACU terminal, space if TEXT is not a format directive,
*>   "?" a format directive naming a format Plumbline does not read.
*> Recognized forms (case-insensitive):
*>   >>SOURCE [FORMAT] [IS] FIXED|FREE|VARIABLE|XOPEN|TERMINAL
*>   $SET SOURCEFORMAT"FIXED"   $SET SOURCEFORMAT(FREE)   and similar
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-DIRECTIVE-FORMAT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-TEXT                 PIC X(256).
01  LS-TOKENS.
    05  LS-TOKEN            PIC X(32) OCCURS 12 TIMES.
01  LS-COUNT                PIC 9(4) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-PTR                  PIC 9(4) COMP-5.
LINKAGE SECTION.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-FORMAT               PIC X.
PROCEDURE DIVISION USING LK-TEXT LK-FORMAT.
    MOVE SPACE TO LK-FORMAT
    MOVE FUNCTION TRIM(LK-TEXT LEADING) TO LS-TEXT
    CALL "PLB-STR-UPPER" USING LS-TEXT
    INSPECT LS-TEXT REPLACING ALL '"' BY SPACE
                              ALL "'" BY SPACE
                              ALL "(" BY SPACE
                              ALL ")" BY SPACE
                              ALL "=" BY SPACE
    PERFORM SPLIT-TOKENS

    EVALUATE LS-TOKEN(1)
        WHEN ">>SOURCE"
            MOVE 2 TO LS-I
            IF LS-TOKEN(LS-I) = "FORMAT"
                ADD 1 TO LS-I
            END-IF
            IF LS-TOKEN(LS-I) = "IS"
                ADD 1 TO LS-I
            END-IF
            PERFORM DECODE-FORMAT
        WHEN "$SET"
        WHEN ">>SET"
            PERFORM VARYING LS-I FROM 2 BY 1 UNTIL LS-I >= LS-COUNT
                IF LS-TOKEN(LS-I) = "SOURCEFORMAT"
                    *> plumbline: ignore varying-control-changed -- steps past the tokens just read
                    ADD 1 TO LS-I
                    PERFORM DECODE-FORMAT
                    EXIT PERFORM
                END-IF
            END-PERFORM
    END-EVALUATE
    GOBACK.

DECODE-FORMAT.
    EVALUATE LS-TOKEN(LS-I)
        WHEN "FIXED"
            MOVE "X" TO LK-FORMAT
        WHEN "FREE"
            MOVE "F" TO LK-FORMAT
        WHEN "VARIABLE"
            MOVE "V" TO LK-FORMAT
        WHEN "XOPEN"
            MOVE "O" TO LK-FORMAT
        WHEN "TERMINAL"
            MOVE "T" TO LK-FORMAT
        WHEN OTHER
            MOVE "?" TO LK-FORMAT
    END-EVALUATE.

*> LS-TEXT has no leading spaces, and UNSTRING moves the pointer past
*> every space after a token, so each pass starts on a token.
SPLIT-TOKENS.
    MOVE SPACES TO LS-TOKENS
    MOVE 0 TO LS-COUNT
    MOVE 1 TO LS-PTR
    PERFORM UNTIL LS-PTR > FUNCTION LENGTH(LS-TEXT) OR LS-COUNT = 12
        ADD 1 TO LS-COUNT
        UNSTRING LS-TEXT DELIMITED BY ALL SPACE
            INTO LS-TOKEN(LS-COUNT)
            WITH POINTER LS-PTR
        END-UNSTRING
    END-PERFORM.
END PROGRAM PLB-SRC-DIRECTIVE-FORMAT.
