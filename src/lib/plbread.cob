*> ---------------------------------------------------------------
*> plbread: loading source files into a PLB-SOURCE-SET.
*>
*> PLB-SRC-LOAD adds a file and reads it; PLB-SRC-ADD and PLB-SRC-READ
*> do the two steps apart, PLB-SRC-ENSURE reads a file that is not in
*> memory, and PLB-SRC-RELEASE drops the lines read since a mark.
*>
*> PLB-SRC-READ reads a file in two passes:
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
LOCAL-STORAGE SECTION.
01  LS-B                    PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET.
    MOVE 0 TO SS-FILE-COUNT SS-LINE-COUNT SS-HEAP-USED SS-DEFINE-COUNT
    PERFORM VARYING LS-B FROM 1 BY 1 UNTIL LS-B > SS-PATH-BUCKETS
        MOVE 0 TO SS-PATH-HEAD(LS-B)
    END-PERFORM
    GOBACK.
END PROGRAM PLB-SRC-INIT.

*> PLB-SRC-LOAD: add the file at PATH to the source set and read it.
*> MODE is "X" (fixed), "F" (free), or "A" (detect).
*> FILE-ID receives the new file's id (0 if nothing was loaded).
*> STATUS receives 0 when the file was loaded, 1 otherwise; problems
*> are recorded in the diagnostics table either way.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-LOAD.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-BUCKET               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-MODE                 PIC X.
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-PATH
        LK-MODE LK-FILE-ID LK-STATUS.
    CALL "PLB-SRC-ADD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-PATH
        LK-MODE LK-FILE-ID
    IF LK-FILE-ID = 0
        MOVE 1 TO LK-STATUS
        GOBACK
    END-IF
    CALL "PLB-SRC-READ" USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-FILE-ID
        LK-STATUS
    *> A file that cannot be opened gets no id.
    IF SF-READS(LK-FILE-ID) = 0 AND LK-FILE-ID = SS-FILE-COUNT
        CALL "PLB-SRC-PATH-BUCKET" USING SF-PATH(LK-FILE-ID) LS-BUCKET
        MOVE SF-PATH-NEXT(LK-FILE-ID) TO SS-PATH-HEAD(LS-BUCKET)
        SUBTRACT 1 FROM SS-FILE-COUNT
        MOVE 0 TO LK-FILE-ID
    END-IF
    GOBACK.
END PROGRAM PLB-SRC-LOAD.

*> PLB-SRC-ADD: give the file at PATH an id without reading it.
*> FILE-ID receives 0 when the source set has no room for it.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-ADD.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-MESSAGE              PIC X(200).
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-ZERO-COLUMN          PIC 9(4) COMP-5 VALUE 0.
01  LS-NO-FILE              PIC 9(4) COMP-5 VALUE 0.
01  LS-BUCKET               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-MODE                 PIC X.
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-PATH
        LK-MODE LK-FILE-ID.
    MOVE 0 TO LK-FILE-ID
    IF SS-FILE-COUNT >= SS-MAX-FILES
        MOVE SPACES TO LS-MESSAGE
        STRING "too many source files (limit " SS-MAX-FILES ")"
            DELIMITED BY SIZE INTO LS-MESSAGE
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "RD005"
            LS-NO-FILE LS-ZERO LS-ZERO-COLUMN LS-MESSAGE
        GOBACK
    END-IF
    ADD 1 TO SS-FILE-COUNT
    MOVE SS-FILE-COUNT TO LK-FILE-ID
    MOVE LK-PATH TO SF-PATH(LK-FILE-ID)
    CALL "PLB-SRC-PATH-BUCKET" USING SF-PATH(LK-FILE-ID) LS-BUCKET
    MOVE SS-PATH-HEAD(LS-BUCKET) TO SF-PATH-NEXT(LK-FILE-ID)
    MOVE LK-FILE-ID TO SS-PATH-HEAD(LS-BUCKET)
    MOVE LK-MODE TO SF-MODE(LK-FILE-ID)
    MOVE 0 TO SF-READS(LK-FILE-ID) SF-FIRST-LINE(LK-FILE-ID)
        SF-LINE-COUNT(LK-FILE-ID)
    MOVE "N" TO SF-LOADED(LK-FILE-ID) SF-DETECTED(LK-FILE-ID)
    MOVE SPACE TO SF-FORMAT(LK-FILE-ID)
    GOBACK.
END PROGRAM PLB-SRC-ADD.

*> PLB-SRC-READ: read file FILE-ID, which was added and whose lines
*> are not in memory, appending its lines to the source set.
*> STATUS receives 0 when the whole file was read, 1 otherwise.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-READ.
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
01  WS-NO-FILE              PIC 9(4) COMP-5 VALUE 0.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-FILE-ID
        LK-STATUS.
    MOVE 1 TO LK-STATUS
    MOVE SF-PATH(LK-FILE-ID) TO WS-PATH
    MOVE 0 TO WS-LINE-NO WS-COLUMN

    OPEN INPUT SOURCE-FILE
    IF WS-STATUS NOT = "00"
        MOVE SPACES TO WS-MESSAGE
        STRING "cannot open " FUNCTION TRIM(WS-PATH TRAILING)
            " (file status " WS-STATUS ")"
            DELIMITED BY SIZE INTO WS-MESSAGE
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "RD001"
            WS-NO-FILE WS-LINE-NO WS-COLUMN WS-MESSAGE
        GOBACK
    END-IF

    ADD 1 TO SF-READS(LK-FILE-ID)
    MOVE "Y" TO SF-LOADED(LK-FILE-ID)
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

    CALL "PLB-SRC-SET-FORMAT" USING PLB-SOURCE-SET LK-FILE-ID
        SF-MODE(LK-FILE-ID)
    CALL "PLB-SRC-CLASSIFY-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        LK-FILE-ID
    CALL "PLB-SRC-CONDITIONALS" USING PLB-SOURCE-SET LK-FILE-ID
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
END PROGRAM PLB-SRC-READ.

*> PLB-SRC-ENSURE: make sure the lines of file FILE-ID are in memory,
*> reading the file if they are not. The first read reports problems
*> in the diagnostics table; a later one found them already and keeps
*> quiet. STATUS receives 0 when the lines are there, 1 otherwise.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-ENSURE.
DATA DIVISION.
WORKING-STORAGE SECTION.
LOCAL-STORAGE SECTION.
01  LS-SAVED-COUNT          PIC 9(9) COMP-5.
01  LS-SAVED-ERRORS         PIC 9(9) COMP-5.
01  LS-SAVED-WARNINGS       PIC 9(9) COMP-5.
01  LS-SAVED-DROPPED        PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS LK-FILE-ID
        LK-STATUS.
    MOVE 0 TO LK-STATUS
    IF LK-FILE-ID < 1 OR LK-FILE-ID > SS-FILE-COUNT
        MOVE 1 TO LK-STATUS
        GOBACK
    END-IF
    IF SF-LOADED(LK-FILE-ID) = "Y"
        GOBACK
    END-IF
    IF SF-READS(LK-FILE-ID) = 0
        CALL "PLB-SRC-READ" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            LK-FILE-ID LK-STATUS
    ELSE
        *> Diagnostics are only ever appended: forget the ones this
        *> read repeats.
        MOVE DG-COUNT TO LS-SAVED-COUNT
        MOVE DG-ERRORS TO LS-SAVED-ERRORS
        MOVE DG-WARNINGS TO LS-SAVED-WARNINGS
        MOVE DG-DROPPED TO LS-SAVED-DROPPED
        CALL "PLB-SRC-READ" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            LK-FILE-ID LK-STATUS
        MOVE LS-SAVED-COUNT TO DG-COUNT
        MOVE LS-SAVED-ERRORS TO DG-ERRORS
        MOVE LS-SAVED-WARNINGS TO DG-WARNINGS
        MOVE LS-SAVED-DROPPED TO DG-DROPPED
    END-IF
    IF SF-LOADED(LK-FILE-ID) NOT = "Y"
        MOVE 1 TO LK-STATUS
    END-IF
    GOBACK.
END PROGRAM PLB-SRC-ENSURE.

*> PLB-SRC-RELEASE: drop every line read since the mark LINES, HEAP
*> (the values of SS-LINE-COUNT and SS-HEAP-USED then). Files whose
*> lines go keep their ids, paths, and line counts, and can be read
*> again with PLB-SRC-ENSURE.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-RELEASE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-F                    PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-LINES                PIC 9(9) COMP-5.
01  LK-HEAP                 PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-LINES LK-HEAP.
    IF LK-LINES >= SS-LINE-COUNT
        GOBACK
    END-IF
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > SS-FILE-COUNT
        IF SF-LOADED(LS-F) = "Y" AND SF-FIRST-LINE(LS-F) > LK-LINES
            MOVE "N" TO SF-LOADED(LS-F)
            MOVE 0 TO SF-FIRST-LINE(LS-F)
        END-IF
    END-PERFORM
    MOVE LK-LINES TO SS-LINE-COUNT
    MOVE LK-HEAP TO SS-HEAP-USED
    GOBACK.
END PROGRAM PLB-SRC-RELEASE.

*> PLB-SRC-SET-FORMAT: set the starting format of FILE-ID from MODE,
*> detecting it when MODE is "A".
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-SET-FORMAT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-FORMAT               PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
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
01  LS-FIXED-SIGNS          PIC 9(9) COMP-5.
01  LS-LINE                 PIC X(1024).
01  LS-LEAD                 PIC 9(4) COMP-5.
01  LS-FROM                 PIC 9(4) COMP-5 VALUE 1.
01  LS-TO                   PIC 9(4) COMP-5.
01  LS-DIRECTIVE            PIC X.
01  LS-AT                   PIC 9(4) COMP-5.
01  LS-SEQ-SPACES           PIC 9(4) COMP-5.
01  LS-FIXED-FROM           PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-FORMAT               PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID LK-FORMAT.
    MOVE "X" TO LK-FORMAT
    MOVE 0 TO LS-SAMPLED LS-AGAINST LS-FIXED-SIGNS
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
    *> Free when lines against fixed format are more than a fifth of
    *> those sampled, or when there are any and not one line has a
    *> sign of fixed format: an indicator in column 7 or a sequence
    *> area filled in.
    IF LS-AGAINST * 5 > LS-SAMPLED
       OR (LS-AGAINST > 0 AND LS-FIXED-SIGNS = 0)
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
        WHEN LS-LINE(7:1) = "*" OR "/" OR "-" OR "D" OR "d" OR "$"
            ADD 1 TO LS-FIXED-SIGNS
        *> A sequence number or tag: columns 1 to 6 used, 7 blank.
        WHEN LS-SEQ-SPACES = 0 AND LS-LINE(7:1) = SPACE
             AND SL-TEXT-LEN(LS-INDEX) > 7
            ADD 1 TO LS-FIXED-SIGNS
        WHEN LS-LINE(7:1) = SPACE
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
COPY "plbsrcc.cpy".
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
    MOVE "N" TO SL-SKIPPED(LS-INDEX)
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
COPY "plbsrcc.cpy".
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
COPY "plbsrcc.cpy".
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
COPY "plbsrcc.cpy".
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

*> PLB-SRC-LINE-INDEX: INDEX receives the SS-LINE index of line
*> LINE-NO of file FILE-ID, or 0 when there is no such line. A file
*> whose lines were released is read again; this program holds one
*> such file at a time, and releases it when asked for another, as long
*> as nothing was read after it. Problems were reported when the file
*> was first read, so a read here reports nothing.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-LINE-INDEX.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbdiag.cpy".
*> The file this program read, the source set before it read it, and
*> SS-LINE-COUNT after.
01  WS-HELD-FILE            PIC 9(4) COMP-5 VALUE 0.
01  WS-HELD-MARK-LINES      PIC 9(9) COMP-5 VALUE 0.
01  WS-HELD-MARK-HEAP       PIC 9(9) COMP-5 VALUE 0.
01  WS-HELD-END             PIC 9(9) COMP-5 VALUE 0.
LOCAL-STORAGE SECTION.
01  LS-STATUS               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-LINE-NO              PIC 9(9) COMP-5.
01  LK-INDEX                PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID LK-LINE-NO LK-INDEX.
    MOVE 0 TO LK-INDEX
    IF LK-FILE-ID < 1 OR LK-FILE-ID > SS-FILE-COUNT OR LK-LINE-NO = 0
        GOBACK
    END-IF
    *> Only a file that was read once can be read again.
    IF SF-LOADED(LK-FILE-ID) NOT = "Y" AND SF-READS(LK-FILE-ID) > 0
        PERFORM RELEASE-HELD-FILE
        MOVE SS-LINE-COUNT TO WS-HELD-MARK-LINES
        MOVE SS-HEAP-USED TO WS-HELD-MARK-HEAP
        CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
        CALL "PLB-SRC-ENSURE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            LK-FILE-ID LS-STATUS
        MOVE LK-FILE-ID TO WS-HELD-FILE
        MOVE SS-LINE-COUNT TO WS-HELD-END
    END-IF
    IF SF-LOADED(LK-FILE-ID) = "Y"
       AND LK-LINE-NO <= SF-LINE-COUNT(LK-FILE-ID)
        COMPUTE LK-INDEX = SF-FIRST-LINE(LK-FILE-ID) + LK-LINE-NO - 1
    END-IF
    GOBACK.

RELEASE-HELD-FILE.
    IF WS-HELD-FILE > 0 AND WS-HELD-FILE <= SS-FILE-COUNT
        IF SF-LOADED(WS-HELD-FILE) = "Y" AND SS-LINE-COUNT = WS-HELD-END
            CALL "PLB-SRC-RELEASE" USING PLB-SOURCE-SET
                WS-HELD-MARK-LINES WS-HELD-MARK-HEAP
        END-IF
    END-IF
    MOVE 0 TO WS-HELD-FILE.
END PROGRAM PLB-SRC-LINE-INDEX.

*> PLB-SRC-FIND-PATH: FILE-ID receives the id of the file added with
*> path PATH, the first if there are several, or 0.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-FIND-PATH.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-PATH                 PIC X(512).
01  LS-BUCKET               PIC 9(4) COMP-5.
01  LS-F                    PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-PATH LK-FILE-ID.
    MOVE 0 TO LK-FILE-ID
    MOVE LK-PATH TO LS-PATH
    CALL "PLB-SRC-PATH-BUCKET" USING LS-PATH LS-BUCKET
    MOVE SS-PATH-HEAD(LS-BUCKET) TO LS-F
    PERFORM UNTIL LS-F = 0
        *> The chain runs from the newest file to the oldest.
        IF SF-PATH(LS-F) = LS-PATH
            MOVE LS-F TO LK-FILE-ID
        END-IF
        MOVE SF-PATH-NEXT(LS-F) TO LS-F
    END-PERFORM
    GOBACK.
END PROGRAM PLB-SRC-FIND-PATH.

*> PLB-SRC-PATH-BUCKET: BUCKET receives the hash bucket of PATH, from 1
*> to SS-PATH-BUCKETS. Trailing spaces do not count.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-PATH-BUCKET.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsrcc.cpy".
LOCAL-STORAGE SECTION.
01  LS-HASH                 PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-BUCKETS              PIC 9(9) COMP-5 VALUE SS-PATH-BUCKETS.
LINKAGE SECTION.
01  LK-PATH                 PIC X(SS-PATH-SIZE).
01  LK-BUCKET               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-BUCKET.
    MOVE 0 TO LS-HASH
    CALL "PLB-STR-LENGTH" USING LK-PATH LS-LEN
    *> 31 * hash + character, kept below 2**32 / 31 by the modulus.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        COMPUTE LS-HASH = FUNCTION MOD(LS-HASH * 31
            + FUNCTION ORD(LK-PATH(LS-I:1)), 16777213)
    END-PERFORM
    COMPUTE LK-BUCKET = FUNCTION MOD(LS-HASH, LS-BUCKETS) + 1
    GOBACK.
END PROGRAM PLB-SRC-PATH-BUCKET.

*> PLB-SRC-CONDITIONALS: conditional compilation in file FILE-ID.
*>
*>     >>IF condition ... [>>ELIF condition ...] [>>ELSE ...] >>END-IF
*>     $IF condition ... [$ELSE ...] $END            (Micro Focus)
*>
*> Lines in a branch that is not compiled get SL-SKIPPED "Y". The
*> conditions Plumbline decides are NAME [IS] [NOT] DEFINED and
*> NAME [IS] [NOT] SET, where a name is defined by >>DEFINE or
*> $SET CONSTANT earlier in the file, or for the run (--define). For
*> any other condition every branch is kept, as if each were compiled:
*> the analysis then sees all of the code.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SRC-CONDITIONALS.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  CD-MAX-DEPTH            VALUE 32.
78  CD-MAX-NAMES            VALUE 256.
LOCAL-STORAGE SECTION.
01  LS-L                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(1024).
01  LS-REST                 PIC X(1024).
01  LS-WORDS.
    05  LS-WORD             PIC X(31) OCCURS 6 TIMES.
01  LS-W                    PIC 9(4) COMP-5.
01  LS-ACTIVE               PIC X.
01  LS-KNOWN                PIC X.
01  LS-TRUE                 PIC X.
01  LS-NAME                 PIC X(31).
01  LS-FOUND                PIC X.
01  LS-I                    PIC 9(4) COMP-5.
*> One entry per open >>IF: whether the branch being read is compiled,
*> whether the condition could be decided, whether a branch was
*> already taken, and whether the >>IF itself is in compiled code.
01  LS-DEPTH                PIC 9(4) COMP-5 VALUE 0.
01  LS-LEVELS.
    05  LS-LEVEL            OCCURS CD-MAX-DEPTH TIMES.
        10  LV-ACTIVE       PIC X.
        10  LV-KNOWN        PIC X.
        10  LV-TAKEN        PIC X.
        10  LV-OUTER        PIC X.
*> Names defined: those of the run, then those of the file.
01  LS-NAME-COUNT           PIC 9(4) COMP-5 VALUE 0.
01  LS-NAMES.
    05  LS-DEFINED          PIC X(31) OCCURS CD-MAX-NAMES TIMES.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID.
    IF SF-LOADED(LK-FILE-ID) NOT = "Y" OR SF-LINE-COUNT(LK-FILE-ID) = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > SS-DEFINE-COUNT
        MOVE SS-DEFINE(LS-I) TO LS-NAME
        PERFORM ADD-NAME
    END-PERFORM
    COMPUTE LS-LAST = SF-FIRST-LINE(LK-FILE-ID)
        + SF-LINE-COUNT(LK-FILE-ID) - 1
    PERFORM VARYING LS-L FROM SF-FIRST-LINE(LK-FILE-ID) BY 1
            UNTIL LS-L > LS-LAST
        PERFORM CURRENT-ACTIVE
        IF SL-IS-DIRECTIVE(LS-L)
            PERFORM DIRECTIVE
        ELSE
            IF LS-ACTIVE = "N"
                MOVE "Y" TO SL-SKIPPED(LS-L)
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

CURRENT-ACTIVE.
    IF LS-DEPTH = 0
        MOVE "Y" TO LS-ACTIVE
    ELSE
        MOVE LV-ACTIVE(LS-DEPTH) TO LS-ACTIVE
    END-IF.

*> The words of directive line LS-L, upper case, with ">> IF" read
*> as ">>IF".
DIRECTIVE.
    CALL "PLB-SRC-LINE-CONTENT" USING PLB-SOURCE-SET LS-L LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    IF LS-TEXT(1:3) = ">> "
        MOVE LS-TEXT(4:) TO LS-REST
        MOVE LS-REST TO LS-TEXT(3:)
    END-IF
    MOVE SPACES TO LS-WORDS
    UNSTRING LS-TEXT DELIMITED BY ALL SPACE
        INTO LS-WORD(1) LS-WORD(2) LS-WORD(3) LS-WORD(4) LS-WORD(5)
            LS-WORD(6)
    EVALUATE LS-WORD(1)
        WHEN ">>IF" WHEN "$IF"
            PERFORM OPEN-IF
        WHEN ">>ELIF"
            PERFORM ELSE-IF
        WHEN ">>ELSE" WHEN "$ELSE"
            PERFORM ELSE-BRANCH
        WHEN ">>END-IF" WHEN "$END" WHEN "$END-IF"
            IF LS-DEPTH > 0
                SUBTRACT 1 FROM LS-DEPTH
            END-IF
        WHEN ">>DEFINE"
            IF LS-ACTIVE = "Y"
                PERFORM DEFINE-DIRECTIVE
            END-IF
        WHEN "$SET" WHEN ">>SET"
            IF LS-ACTIVE = "Y" AND LS-WORD(2) = "CONSTANT"
                MOVE LS-WORD(3) TO LS-NAME
                PERFORM ADD-NAME
            END-IF
    END-EVALUATE.

OPEN-IF.
    IF LS-DEPTH >= CD-MAX-DEPTH
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-DEPTH
    MOVE LS-ACTIVE TO LV-OUTER(LS-DEPTH)
    PERFORM DECIDE-CONDITION
    MOVE LS-KNOWN TO LV-KNOWN(LS-DEPTH)
    IF LS-KNOWN = "Y"
        MOVE LS-TRUE TO LV-TAKEN(LS-DEPTH)
        IF LS-ACTIVE = "Y" AND LS-TRUE = "Y"
            MOVE "Y" TO LV-ACTIVE(LS-DEPTH)
        ELSE
            MOVE "N" TO LV-ACTIVE(LS-DEPTH)
        END-IF
    ELSE
        MOVE "N" TO LV-TAKEN(LS-DEPTH)
        MOVE LS-ACTIVE TO LV-ACTIVE(LS-DEPTH)
    END-IF.

*> >>ELIF: compiled when no branch was taken and its condition holds.
ELSE-IF.
    IF LS-DEPTH = 0
        EXIT PARAGRAPH
    END-IF
    IF LV-KNOWN(LS-DEPTH) = "N"
        MOVE LV-OUTER(LS-DEPTH) TO LV-ACTIVE(LS-DEPTH)
        EXIT PARAGRAPH
    END-IF
    IF LV-TAKEN(LS-DEPTH) = "Y"
        MOVE "N" TO LV-ACTIVE(LS-DEPTH)
        EXIT PARAGRAPH
    END-IF
    PERFORM DECIDE-CONDITION
    IF LS-KNOWN = "N"
        *> From here on the branches cannot be told apart.
        MOVE "N" TO LV-KNOWN(LS-DEPTH)
        MOVE LV-OUTER(LS-DEPTH) TO LV-ACTIVE(LS-DEPTH)
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TRUE TO LV-TAKEN(LS-DEPTH)
    IF LV-OUTER(LS-DEPTH) = "Y" AND LS-TRUE = "Y"
        MOVE "Y" TO LV-ACTIVE(LS-DEPTH)
    ELSE
        MOVE "N" TO LV-ACTIVE(LS-DEPTH)
    END-IF.

ELSE-BRANCH.
    IF LS-DEPTH = 0
        EXIT PARAGRAPH
    END-IF
    IF LV-KNOWN(LS-DEPTH) = "N"
        MOVE LV-OUTER(LS-DEPTH) TO LV-ACTIVE(LS-DEPTH)
        EXIT PARAGRAPH
    END-IF
    IF LV-OUTER(LS-DEPTH) = "Y" AND LV-TAKEN(LS-DEPTH) = "N"
        MOVE "Y" TO LV-ACTIVE(LS-DEPTH)
    ELSE
        MOVE "N" TO LV-ACTIVE(LS-DEPTH)
    END-IF
    MOVE "Y" TO LV-TAKEN(LS-DEPTH).

*> The condition in words 2 onward: NAME [IS] [NOT] DEFINED|SET.
*> LS-KNOWN = "Y" when it is of that form; LS-TRUE its value.
DECIDE-CONDITION.
    MOVE "N" TO LS-KNOWN LS-TRUE
    MOVE LS-WORD(2) TO LS-NAME
    MOVE 3 TO LS-W
    IF LS-WORD(LS-W) = "IS"
        ADD 1 TO LS-W
    END-IF
    IF LS-WORD(LS-W) = "NOT"
        ADD 1 TO LS-W
        IF LS-WORD(LS-W) = "DEFINED" OR LS-WORD(LS-W) = "SET"
            IF LS-WORD(LS-W + 1) = SPACES
                MOVE "Y" TO LS-KNOWN
                PERFORM FIND-NAME
                IF LS-FOUND = "N"
                    MOVE "Y" TO LS-TRUE
                END-IF
            END-IF
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF LS-WORD(LS-W) = "DEFINED" OR LS-WORD(LS-W) = "SET"
        IF LS-WORD(LS-W + 1) = SPACES
            MOVE "Y" TO LS-KNOWN
            PERFORM FIND-NAME
            MOVE LS-FOUND TO LS-TRUE
        END-IF
    END-IF.

*> >>DEFINE [CONSTANT] NAME [AS value | AS PARAMETER | OFF]. A name
*> AS PARAMETER is defined only when the run defines it.
DEFINE-DIRECTIVE.
    MOVE 2 TO LS-W
    IF LS-WORD(LS-W) = "CONSTANT"
        ADD 1 TO LS-W
    END-IF
    MOVE LS-WORD(LS-W) TO LS-NAME
    IF LS-NAME = SPACES
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN LS-WORD(LS-W + 1) = "OFF"
            PERFORM REMOVE-NAME
        WHEN LS-WORD(LS-W + 1) = "AS" AND LS-WORD(LS-W + 2) = "PARAMETER"
            CONTINUE
        WHEN OTHER
            PERFORM ADD-NAME
    END-EVALUATE.

FIND-NAME.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-NAME-COUNT
        IF LS-DEFINED(LS-I) = LS-NAME
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM.

ADD-NAME.
    PERFORM FIND-NAME
    IF LS-FOUND = "N" AND LS-NAME-COUNT < CD-MAX-NAMES
        ADD 1 TO LS-NAME-COUNT
        MOVE LS-NAME TO LS-DEFINED(LS-NAME-COUNT)
    END-IF.

REMOVE-NAME.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-NAME-COUNT
        IF LS-DEFINED(LS-I) = LS-NAME
            MOVE SPACES TO LS-DEFINED(LS-I)
        END-IF
    END-PERFORM.
END PROGRAM PLB-SRC-CONDITIONALS.
