*> ---------------------------------------------------------------
*> plbmd: the findings of plumbline check as Markdown.
*>
*> PLB-REPORT-MD USING SOURCE DIAGNOSTICS RULES FINDINGS writes a
*> summary, the findings by rule, and a table of the findings and of
*> the diagnostics, for a CI job summary or a pull request comment
*> (GitHub, GitLab). The tables stop after MD-SHOWN rows each, with a
*> line saying how many more there are. Suppressed and baselined
*> findings are left out, as in the other reports. Text taken from the
*> input is escaped for a table cell.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-MD.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
78  MD-SHOWN                    VALUE 1000.
*> Findings per rule, for the summary.
01  WS-RULE-COUNTS.
    *> One per rule of the catalog (RL-MAX in plbrules.cpy).
    05  WS-RULE-FINDINGS    PIC 9(9) COMP-5 OCCURS 200 TIMES.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(4) COMP-5.
01  LS-ERRORS               PIC 9(9) COMP-5.
01  LS-WARNINGS             PIC 9(9) COMP-5.
01  LS-NOTES                PIC 9(9) COMP-5.
01  LS-SHOWN                PIC 9(9) COMP-5.
01  LS-ROWS                 PIC 9(9) COMP-5.
01  LS-FILES                PIC 9(9) COMP-5.
01  LS-LAST-FILE            PIC 9(4) COMP-5.
01  LS-PATH                 PIC X(512).
01  LS-TEXT                 PIC X(200).
01  LS-OUT                  PIC X(2048).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-SEVERITY             PIC X.
01  LS-WORD                 PIC X(10).
01  LS-FILE-ID              PIC 9(4) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS.
    PERFORM COUNT-FINDINGS
    DISPLAY "## Plumbline " FUNCTION TRIM(PLB-VERSION)
    CALL STATIC "putchar" USING BY VALUE 10
    PERFORM WRITE-SUMMARY
    IF LS-SHOWN > 0
        PERFORM WRITE-RULES
        PERFORM WRITE-FINDINGS
    END-IF
    IF DG-COUNT > 0
        PERFORM WRITE-DIAGNOSTICS
    END-IF
    GOBACK.

COUNT-FINDINGS.
    MOVE 0 TO LS-ERRORS LS-WARNINGS LS-NOTES LS-SHOWN LS-FILES
    MOVE 0 TO LS-LAST-FILE
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RL-COUNT
        MOVE 0 TO WS-RULE-FINDINGS(LS-R)
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            ADD 1 TO LS-SHOWN
            ADD 1 TO WS-RULE-FINDINGS(FN-RULE(LS-I))
            EVALUATE FN-SEVERITY(LS-I)
                WHEN "E"   ADD 1 TO LS-ERRORS
                WHEN "W"   ADD 1 TO LS-WARNINGS
                WHEN OTHER ADD 1 TO LS-NOTES
            END-EVALUATE
            *> The findings are sorted by file.
            IF FN-FILE-ID(LS-I) NOT = LS-LAST-FILE
                ADD 1 TO LS-FILES
                MOVE FN-FILE-ID(LS-I) TO LS-LAST-FILE
            END-IF
        END-IF
    END-PERFORM.

*> **N findings** in F files: E errors, W warnings, N notes.
WRITE-SUMMARY.
    PERFORM START-OUT
    IF LS-SHOWN = 0
        STRING "No findings." DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "**" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-SHOWN TO LS-NUM
        MOVE "finding" TO LS-WORD
        PERFORM APPEND-COUNTED
        STRING "** in " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-FILES TO LS-NUM
        MOVE "file" TO LS-WORD
        PERFORM APPEND-COUNTED
        STRING ": " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-ERRORS TO LS-NUM
        MOVE "error" TO LS-WORD
        PERFORM APPEND-COUNTED
        STRING ", " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-WARNINGS TO LS-NUM
        MOVE "warning" TO LS-WORD
        PERFORM APPEND-COUNTED
        STRING ", " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-NOTES TO LS-NUM
        MOVE "note" TO LS-WORD
        PERFORM APPEND-COUNTED
        STRING "." DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT
    CALL STATIC "putchar" USING BY VALUE 10.

WRITE-RULES.
    DISPLAY "| Rule | Name | Severity | Findings |"
    DISPLAY "|---|---|---|---:|"
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RL-COUNT
        IF WS-RULE-FINDINGS(LS-R) > 0
            PERFORM START-OUT
            STRING "| " DELIMITED BY SIZE
                   RL-ID(LS-R) DELIMITED BY SPACE
                   " | " DELIMITED BY SIZE
                   RL-NAME(LS-R) DELIMITED BY SPACE
                   " | " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            MOVE RL-SEVERITY(LS-R) TO LS-SEVERITY
            PERFORM APPEND-SEVERITY
            STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
            MOVE WS-RULE-FINDINGS(LS-R) TO LS-NUM
            PERFORM APPEND-NUM
            STRING " |" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    CALL STATIC "putchar" USING BY VALUE 10.

*> | severity | `path:line:col` | rule | message |
WRITE-FINDINGS.
    DISPLAY "| | Where | Rule | Finding |"
    DISPLAY "|---|---|---|---|"
    MOVE 0 TO LS-ROWS
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            ADD 1 TO LS-ROWS
            IF LS-ROWS <= MD-SHOWN
                PERFORM START-OUT
                STRING "| " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
                MOVE FN-SEVERITY(LS-I) TO LS-SEVERITY
                PERFORM APPEND-SEVERITY
                MOVE FN-FILE-ID(LS-I) TO LS-FILE-ID
                MOVE FN-LINE(LS-I) TO LS-LINE
                MOVE FN-COLUMN(LS-I) TO LS-COLUMN
                PERFORM APPEND-PLACE
                STRING " | " DELIMITED BY SIZE
                       RL-ID(FN-RULE(LS-I)) DELIMITED BY SPACE
                       " | " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
                MOVE FN-MESSAGE(LS-I) TO LS-TEXT
                PERFORM APPEND-CELL
                STRING " |" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
                PERFORM PRINT-OUT
            END-IF
        END-IF
    END-PERFORM
    PERFORM WRITE-MORE
    CALL STATIC "putchar" USING BY VALUE 10.

WRITE-DIAGNOSTICS.
    DISPLAY "Problems reading the input:"
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "| | Where | Code | Problem |"
    DISPLAY "|---|---|---|---|"
    MOVE 0 TO LS-ROWS
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        ADD 1 TO LS-ROWS
        IF LS-ROWS <= MD-SHOWN
            PERFORM START-OUT
            STRING "| " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
            MOVE DG-SEVERITY(LS-I) TO LS-SEVERITY
            PERFORM APPEND-SEVERITY
            MOVE DG-FILE-ID(LS-I) TO LS-FILE-ID
            MOVE DG-LINE(LS-I) TO LS-LINE
            MOVE DG-COLUMN(LS-I) TO LS-COLUMN
            PERFORM APPEND-PLACE
            STRING " | " DELIMITED BY SIZE
                   DG-CODE(LS-I) DELIMITED BY SPACE
                   " | " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            MOVE DG-MESSAGE(LS-I) TO LS-TEXT
            PERFORM APPEND-CELL
            STRING " |" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM WRITE-MORE
    CALL STATIC "putchar" USING BY VALUE 10.

*> After a table cut at MD-SHOWN rows.
WRITE-MORE.
    IF LS-ROWS > MD-SHOWN
        CALL STATIC "putchar" USING BY VALUE 10
        PERFORM START-OUT
        STRING "... and " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        COMPUTE LS-NUM = LS-ROWS - MD-SHOWN
        PERFORM APPEND-NUM
        STRING " more." DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        PERFORM PRINT-OUT
    END-IF.

APPEND-SEVERITY.
    EVALUATE LS-SEVERITY
        WHEN "E"
            STRING "error" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        WHEN "W"
            STRING "warning" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        WHEN OTHER
            STRING "note" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
    END-EVALUATE.

*> `path:line:col`, or `path` for a file as a whole.
APPEND-PLACE.
    STRING " | `" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    IF LS-FILE-ID > 0
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-FILE-ID LS-PATH
        CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
        IF LS-LEN > 0
            STRING LS-PATH(1:LS-LEN) DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-IF
    IF LS-LINE > 0
        STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-LINE TO LS-NUM
        PERFORM APPEND-NUM
        IF LS-COLUMN > 0
            STRING ":" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            MOVE LS-COLUMN TO LS-NUM
            PERFORM APPEND-NUM
        END-IF
    END-IF
    STRING "`" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR.

*> LS-TEXT in a table cell: | and \ escaped with a backslash, and the
*> characters Markdown would read as markup (` * _ < > [ ]) too.
APPEND-CELL.
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-LEN
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-LEN
        IF LS-TEXT(LS-K:1) = "|" OR "\" OR "`" OR "*" OR "_"
           OR "<" OR ">" OR "[" OR "]"
            STRING "\" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING LS-TEXT(LS-K:1) DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-PERFORM.

*> LS-NUM and LS-WORD, with an s unless LS-NUM is 1.
APPEND-COUNTED.
    PERFORM APPEND-NUM
    STRING " " DELIMITED BY SIZE
           LS-WORD DELIMITED BY SPACE
        INTO LS-OUT WITH POINTER LS-PTR
    IF LS-NUM NOT = 1
        STRING "s" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-REPORT-MD.
