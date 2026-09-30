*> ---------------------------------------------------------------
*> plbread: loading source files into a PLB-SOURCE-SET.
*>
*> PLB-SRC-LOAD reads a file in two passes:
*>   1. read every physical line, expand tabs, and append the text
*>      to the heap;
*>   2. decide the starting reference format (given, or detected)
*>      and classify each line, following >>SOURCE and $SET
*>      directives that switch format part-way through the file.
*>
*> Diagnostic codes raised here:
*>   RD001  error    file cannot be opened or read
*>   RD002  warning  line longer than SS-MAX-WIDTH, truncated
*>   RD003  error    invalid character in the indicator column
*>   RD004  warning  directive selects a format Plumbline cannot read
*>   RD005  error    too many files, lines, or characters
*> ---------------------------------------------------------------

*> PLB-SRC-INIT: empty the source set.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbsrc.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET.
    MOVE 0 TO SS-FILE-COUNT SS-LINE-COUNT SS-HEAP-USED
    GOBACK.
END PROGRAM PLB-SRC-INIT.

*> PLB-SRC-LOAD: read the file at PATH into the source set.
*> MODE is "X" (fixed), "F" (free), or "A" (detect).
*> FILE-ID receives the new file's id (0 if nothing was loaded).
*> STATUS receives 0 when the file was loaded, 1 otherwise; problems
*> are recorded in the diagnostics table either way.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-LOAD.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT SOURCE-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  SOURCE-FILE.
01  SOURCE-RECORD           PIC X(1024).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(512).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04".
    88  WS-READ-PARTIAL           VALUE "06".
    88  WS-AT-END                 VALUE "10".
01  WS-EXPANDED             PIC X(1024).
01  WS-RAW-LEN              PIC 9(9) COMP-5.
01  WS-LEN                  PIC 9(9) COMP-5.
01  WS-TAB-WIDTH            PIC 9(4) COMP-5 VALUE 8.
01  WS-OVERFLOW             PIC X.
01  WS-TRUNCATED            PIC X.
01  WS-LINE-NO              PIC 9(9) COMP-5.
01  WS-COLUMN               PIC 9(4) COMP-5.
01  WS-FULL                 PIC X.
01  WS-MESSAGE              PIC X(200).
01  WS-DONE                 PIC X.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-MODE                 PIC X.
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-PATH
        LK-MODE LK-FILE-ID LK-STATUS.
    MOVE 0 TO LK-FILE-ID
    MOVE 1 TO LK-STATUS
    MOVE LK-PATH TO WS-PATH
    MOVE 0 TO WS-LINE-NO WS-COLUMN

    IF SS-FILE-COUNT >= SS-MAX-FILES
        MOVE SPACES TO WS-MESSAGE
        STRING "too many source files (limit " SS-MAX-FILES ")"
            DELIMITED BY SIZE INTO WS-MESSAGE
        PERFORM ADD-LIMIT-ERROR
        GOBACK
    END-IF

    OPEN INPUT SOURCE-FILE
    IF WS-STATUS NOT = "00"
        MOVE SPACES TO WS-MESSAGE
        STRING "cannot open " FUNCTION TRIM(WS-PATH TRAILING)
            " (file status " WS-STATUS ")"
            DELIMITED BY SIZE INTO WS-MESSAGE
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "RD001"
            LK-FILE-ID WS-LINE-NO WS-COLUMN WS-MESSAGE
        GOBACK
    END-IF

    ADD 1 TO SS-FILE-COUNT
    MOVE SS-FILE-COUNT TO LK-FILE-ID
    MOVE LK-PATH TO SF-PATH(LK-FILE-ID)
    COMPUTE SF-FIRST-LINE(LK-FILE-ID) = SS-LINE-COUNT + 1
    MOVE 0 TO SF-LINE-COUNT(LK-FILE-ID)
    MOVE "N" TO WS-FULL WS-DONE

    PERFORM UNTIL WS-DONE = "Y"
        READ SOURCE-FILE
        EVALUATE TRUE
            WHEN WS-READ-OK
                MOVE "N" TO WS-TRUNCATED
                PERFORM STORE-LINE
            WHEN WS-READ-PARTIAL
                MOVE "Y" TO WS-TRUNCATED
                PERFORM STORE-LINE
                PERFORM SKIP-REST-OF-LINE
            WHEN WS-AT-END
                MOVE "Y" TO WS-DONE
            WHEN OTHER
                MOVE SPACES TO WS-MESSAGE
                STRING "error reading " FUNCTION TRIM(WS-PATH TRAILING)
                    " (file status " WS-STATUS ")"
                    DELIMITED BY SIZE INTO WS-MESSAGE
                MOVE 0 TO WS-COLUMN
                CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "RD001"
                    LK-FILE-ID WS-LINE-NO WS-COLUMN WS-MESSAGE
                MOVE "Y" TO WS-DONE
        END-EVALUATE
        IF WS-FULL = "Y"
            MOVE "Y" TO WS-DONE
        END-IF
    END-PERFORM
    CLOSE SOURCE-FILE

    CALL "PLB-SRC-SET-FORMAT" USING PLB-SOURCE-SET LK-FILE-ID LK-MODE
    CALL "PLB-SRC-CLASSIFY-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        LK-FILE-ID
    IF WS-FULL = "N"
        MOVE 0 TO LK-STATUS
    END-IF
    GOBACK.

STORE-LINE.
    ADD 1 TO WS-LINE-NO
    CALL "PLB-STR-LENGTH" USING SOURCE-RECORD WS-RAW-LEN
    CALL "PLB-STR-EXPAND-TABS" USING SOURCE-RECORD WS-RAW-LEN
        WS-TAB-WIDTH WS-EXPANDED WS-LEN WS-OVERFLOW
    IF WS-OVERFLOW = "Y"
        MOVE "Y" TO WS-TRUNCATED
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-EXPANDED WS-LEN

    IF SS-LINE-COUNT >= SS-MAX-LINES
        MOVE SPACES TO WS-MESSAGE
        STRING "too many source lines (limit " SS-MAX-LINES ")"
            DELIMITED BY SIZE INTO WS-MESSAGE
        PERFORM ADD-LIMIT-ERROR
        MOVE "Y" TO WS-FULL
        EXIT PARAGRAPH
    END-IF
    IF SS-HEAP-USED + WS-LEN > SS-HEAP-SIZE
        MOVE SPACES TO WS-MESSAGE
        STRING "source text exceeds " SS-HEAP-SIZE " characters"
            DELIMITED BY SIZE INTO WS-MESSAGE
        PERFORM ADD-LIMIT-ERROR
        MOVE "Y" TO WS-FULL
        EXIT PARAGRAPH
    END-IF

    ADD 1 TO SS-LINE-COUNT
    ADD 1 TO SF-LINE-COUNT(LK-FILE-ID)
    MOVE LK-FILE-ID TO SL-FILE-ID(SS-LINE-COUNT)
    MOVE WS-LINE-NO TO SL-LINE-NO(SS-LINE-COUNT)
    COMPUTE SL-TEXT-OFF(SS-LINE-COUNT) = SS-HEAP-USED + 1
    *> plumbline: ignore move-truncation -- expanded lines are at most 1024 characters
    MOVE WS-LEN TO SL-TEXT-LEN(SS-LINE-COUNT)
    IF WS-LEN > 0
        MOVE WS-EXPANDED(1:WS-LEN)
            TO SS-HEAP(SS-HEAP-USED + 1:WS-LEN)
        ADD WS-LEN TO SS-HEAP-USED
    END-IF

    IF WS-TRUNCATED = "Y"
        MOVE SPACES TO WS-MESSAGE
        STRING "line longer than " SS-MAX-WIDTH
            " characters; the rest is ignored"
            DELIMITED BY SIZE INTO WS-MESSAGE
        MOVE SS-MAX-WIDTH TO WS-COLUMN
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" "RD002"
            LK-FILE-ID WS-LINE-NO WS-COLUMN WS-MESSAGE
        MOVE 0 TO WS-COLUMN
    END-IF.

*> After a partial read the runtime returns the rest of the line as
*> further records; the last piece comes back with status 00.
SKIP-REST-OF-LINE.
    PERFORM UNTIL NOT WS-READ-PARTIAL
        READ SOURCE-FILE
    END-PERFORM
    IF WS-AT-END
        MOVE "Y" TO WS-DONE
    END-IF.

ADD-LIMIT-ERROR.
    MOVE 0 TO WS-COLUMN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "RD005"
        LK-FILE-ID WS-LINE-NO WS-COLUMN WS-MESSAGE.
END PROGRAM PLB-SRC-LOAD.

*> PLB-SRC-SET-FORMAT: set the starting format of FILE-ID from MODE,
*> detecting it when MODE is "A".
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-SET-FORMAT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-FORMAT               PIC X.
LINKAGE SECTION.
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-MODE                 PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID LK-MODE.
    MOVE "N" TO SF-DETECTED(LK-FILE-ID)
    EVALUATE LK-MODE
        WHEN "X"
        WHEN "F"
            MOVE LK-MODE TO SF-FORMAT(LK-FILE-ID)
        WHEN OTHER
            CALL "PLB-SRC-DETECT-FORMAT" USING PLB-SOURCE-SET
                LK-FILE-ID LS-FORMAT
            MOVE LS-FORMAT TO SF-FORMAT(LK-FILE-ID)
            MOVE "Y" TO SF-DETECTED(LK-FILE-ID)
    END-EVALUATE
    GOBACK.
END PROGRAM PLB-SRC-SET-FORMAT.

*> PLB-SRC-DETECT-FORMAT: guess the reference format of FILE-ID.
*>
*> Looks at up to 100 non-blank lines. A line counts against fixed
*> format when column 7 holds something that cannot be an indicator,
*> when the line starts with "*>" inside the sequence area, or when
*> the sequence area is only partly filled. Free
*> format source written from column 1 almost always trips this;
*> fixed format source almost never does. If more than a fifth of the
*> sample disagrees with fixed format, the file is free format.
*>
*> A format directive on the first line settles the question outright.
*> A later one ends the sample: the lines after it are in the format
*> it names, and say nothing about the format the file starts in.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-DETECT-FORMAT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-INDEX                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-SAMPLED              PIC 9(9) COMP-5.
01  LS-AGAINST              PIC 9(9) COMP-5.
01  LS-LINE                 PIC X(1024).
01  LS-LEAD                 PIC 9(4) COMP-5.
01  LS-FROM                 PIC 9(4) COMP-5 VALUE 1.
01  LS-TO                   PIC 9(4) COMP-5.
01  LS-DIRECTIVE            PIC X.
01  LS-AT                   PIC 9(4) COMP-5.
01  LS-SEQ-SPACES           PIC 9(4) COMP-5.
01  LS-FIXED-FROM           PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-FORMAT               PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID LK-FORMAT.
    MOVE "X" TO LK-FORMAT
    MOVE 0 TO LS-SAMPLED LS-AGAINST
    COMPUTE LS-LAST = SF-FIRST-LINE(LK-FILE-ID)
        + SF-LINE-COUNT(LK-FILE-ID) - 1
    PERFORM VARYING LS-INDEX FROM SF-FIRST-LINE(LK-FILE-ID) BY 1
            UNTIL LS-INDEX > LS-LAST OR LS-SAMPLED >= 100
        IF SL-TEXT-LEN(LS-INDEX) > 0
            MOVE SPACES TO LS-LINE
            MOVE SS-HEAP(SL-TEXT-OFF(LS-INDEX):SL-TEXT-LEN(LS-INDEX))
                TO LS-LINE
            MOVE SL-TEXT-LEN(LS-INDEX) TO LS-TO
            CALL "PLB-SRC-FIRST-FROM" USING LS-LINE LS-FROM LS-TO
                LS-LEAD
            IF LS-LEAD > 0
                PERFORM CHECK-DIRECTIVE
                IF LS-DIRECTIVE = "X" OR LS-DIRECTIVE = "F"
                    IF LS-SAMPLED = 0
                        MOVE LS-DIRECTIVE TO LK-FORMAT
                        GOBACK
                    END-IF
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-SAMPLED
                PERFORM CHECK-LINE
            END-IF
        END-IF
    END-PERFORM
    IF LS-AGAINST * 5 > LS-SAMPLED
        MOVE "F" TO LK-FORMAT
    END-IF
    GOBACK.

*> A format directive may start the line (free format) or follow a
*> sequence area (fixed format: "$" in column 7, or ">>" in area A or
*> B), so both positions are checked.
CHECK-DIRECTIVE.
    MOVE SPACE TO LS-DIRECTIVE
    MOVE LS-LEAD TO LS-AT
    PERFORM CHECK-DIRECTIVE-AT
    IF LS-DIRECTIVE = SPACE AND SL-TEXT-LEN(LS-INDEX) >= 7
        IF LS-LINE(7:1) = "$"
            MOVE 7 TO LS-AT
        ELSE
            MOVE 8 TO LS-FIXED-FROM
            CALL "PLB-SRC-FIRST-FROM" USING LS-LINE LS-FIXED-FROM LS-TO
                LS-AT
        END-IF
        IF LS-AT > 0
            PERFORM CHECK-DIRECTIVE-AT
        END-IF
    END-IF.

CHECK-DIRECTIVE-AT.
    IF LS-LINE(LS-AT:2) = ">>" OR LS-LINE(LS-AT:1) = "$"
        CALL "PLB-SRC-DIRECTIVE-FORMAT" USING LS-LINE(LS-AT:)
            LS-DIRECTIVE
    END-IF.

*> In fixed format the sequence area is blank or fully used (a
*> number or tag). Text that starts inside it and leaves part of it
*> blank, such as "    05" or "01  :P", is free-format indentation.
CHECK-LINE.
    MOVE 0 TO LS-SEQ-SPACES
    IF SL-TEXT-LEN(LS-INDEX) >= 6
        INSPECT LS-LINE(1:6) TALLYING LS-SEQ-SPACES FOR ALL SPACE
    END-IF
    EVALUATE TRUE
        WHEN LS-LEAD < 7 AND LS-LINE(LS-LEAD:2) = "*>"
            ADD 1 TO LS-AGAINST
        WHEN SL-TEXT-LEN(LS-INDEX) > 7 AND LS-SEQ-SPACES > 0
                AND LS-SEQ-SPACES < 6
            ADD 1 TO LS-AGAINST
        WHEN SL-TEXT-LEN(LS-INDEX) < 7
            CONTINUE
        WHEN LS-LINE(7:1) = SPACE OR "*" OR "/" OR "-" OR "D" OR "d"
                           OR "$"
            CONTINUE
        WHEN OTHER
            ADD 1 TO LS-AGAINST
    END-EVALUATE.
END PROGRAM PLB-SRC-DETECT-FORMAT.

*> PLB-SRC-CLASSIFY-FILE: classify every line of FILE-ID in order,
*> tracking the current format and any literal left open by a code
*> line so that continuation lines can be read correctly.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CLASSIFY-FILE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
COPY "plbcls.cpy".
01  LS-INDEX                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-FORMAT               PIC X.
01  LS-NEW-FORMAT           PIC X.
01  LS-QUOTE                PIC X.
01  LS-LINE                 PIC X(1024).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-FILE-ID.
    MOVE SF-FORMAT(LK-FILE-ID) TO LS-FORMAT
    MOVE SPACE TO LS-QUOTE
    COMPUTE LS-LAST = SF-FIRST-LINE(LK-FILE-ID)
        + SF-LINE-COUNT(LK-FILE-ID) - 1
    PERFORM VARYING LS-INDEX FROM SF-FIRST-LINE(LK-FILE-ID) BY 1
            UNTIL LS-INDEX > LS-LAST
        PERFORM CLASSIFY-ONE
    END-PERFORM
    GOBACK.

CLASSIFY-ONE.
    MOVE SPACES TO LS-LINE
    MOVE SL-TEXT-LEN(LS-INDEX) TO LS-LEN
    IF LS-LEN > 0
        MOVE SS-HEAP(SL-TEXT-OFF(LS-INDEX):LS-LEN) TO LS-LINE
    END-IF
    IF LS-FORMAT = "F"
        CALL "PLB-SRC-CLASSIFY-FREE" USING LS-LINE LS-LEN LS-QUOTE
            PLB-CLASSIFIED
    ELSE
        CALL "PLB-SRC-CLASSIFY-FIXED" USING LS-LINE LS-LEN LS-QUOTE
            PLB-CLASSIFIED
    END-IF

    MOVE LS-FORMAT      TO SL-FORMAT(LS-INDEX)
    MOVE CL-KIND        TO SL-KIND(LS-INDEX)
    MOVE CL-INDICATOR   TO SL-INDICATOR(LS-INDEX)
    MOVE CL-CONTENT-COL TO SL-CONTENT-COL(LS-INDEX)
    MOVE CL-CONTENT-LEN TO SL-CONTENT-LEN(LS-INDEX)
    MOVE CL-COMMENT-COL TO SL-COMMENT-COL(LS-INDEX)
    MOVE CL-AREA-A      TO SL-AREA-A(LS-INDEX)
    MOVE CL-OPEN-QUOTE  TO SL-OPEN-QUOTE(LS-INDEX)
    MOVE SL-LINE-NO(LS-INDEX) TO LS-LINE-NO

    IF CL-PROBLEM = "I"
        MOVE 7 TO LS-COLUMN
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "RD003"
            LK-FILE-ID LS-LINE-NO LS-COLUMN
            "invalid character in indicator column"
    END-IF

    *> Comment, blank and directive lines do not end a literal that a
    *> later continuation line may resume.
    IF CL-IS-CODE OR CL-IS-DEBUG OR CL-IS-CONTINUATION
        MOVE CL-OPEN-QUOTE TO LS-QUOTE
    END-IF

    IF CL-IS-DIRECTIVE
        CALL "PLB-SRC-DIRECTIVE-FORMAT" USING
            LS-LINE(CL-CONTENT-COL:CL-CONTENT-LEN) LS-NEW-FORMAT
        EVALUATE LS-NEW-FORMAT
            WHEN "X"
            WHEN "F"
                MOVE LS-NEW-FORMAT TO LS-FORMAT
            WHEN "?"
                MOVE CL-CONTENT-COL TO LS-COLUMN
                CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" "RD004"
                    LK-FILE-ID LS-LINE-NO LS-COLUMN
                    "unsupported source format; keeping current format"
        END-EVALUATE
    END-IF.
END PROGRAM PLB-SRC-CLASSIFY-FILE.

*> PLB-SRC-LINE-CONTENT: the significant text of line INDEX.
*> TEXT is space filled; LENGTH is 0 for lines without content.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-LINE-CONTENT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbsrc.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-INDEX LK-TEXT LK-LENGTH.
    MOVE SPACES TO LK-TEXT
    MOVE 0 TO LK-LENGTH
    IF LK-INDEX < 1 OR LK-INDEX > SS-LINE-COUNT
        GOBACK
    END-IF
    IF SL-CONTENT-LEN(LK-INDEX) > 0
        MOVE SL-CONTENT-LEN(LK-INDEX) TO LK-LENGTH
        IF LK-LENGTH > FUNCTION LENGTH(LK-TEXT)
            MOVE FUNCTION LENGTH(LK-TEXT) TO LK-LENGTH
        END-IF
        MOVE SS-HEAP(SL-TEXT-OFF(LK-INDEX)
                     + SL-CONTENT-COL(LK-INDEX) - 1:LK-LENGTH)
            TO LK-TEXT(1:LK-LENGTH)
    END-IF
    GOBACK.
END PROGRAM PLB-SRC-LINE-CONTENT.

*> PLB-SRC-LINE-TEXT: the full tab-expanded text of line INDEX.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-LINE-TEXT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbsrc.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-INDEX LK-TEXT LK-LENGTH.
    MOVE SPACES TO LK-TEXT
    MOVE 0 TO LK-LENGTH
    IF LK-INDEX < 1 OR LK-INDEX > SS-LINE-COUNT
        GOBACK
    END-IF
    MOVE SL-TEXT-LEN(LK-INDEX) TO LK-LENGTH
    IF LK-LENGTH > FUNCTION LENGTH(LK-TEXT)
        MOVE FUNCTION LENGTH(LK-TEXT) TO LK-LENGTH
    END-IF
    IF LK-LENGTH > 0
        MOVE SS-HEAP(SL-TEXT-OFF(LK-INDEX):LK-LENGTH)
            TO LK-TEXT(1:LK-LENGTH)
    END-IF
    GOBACK.
END PROGRAM PLB-SRC-LINE-TEXT.

*> PLB-SRC-FILE-PATH: the path of FILE-ID, or spaces if unknown.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-FILE-PATH.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-PATH                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID LK-PATH.
    MOVE SPACES TO LK-PATH
    IF LK-FILE-ID >= 1 AND LK-FILE-ID <= SS-FILE-COUNT
        MOVE SF-PATH(LK-FILE-ID) TO LK-PATH
    END-IF
    GOBACK.
END PROGRAM PLB-SRC-FILE-PATH.
