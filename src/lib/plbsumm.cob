*> ---------------------------------------------------------------
*> plbsumm: check --report summary, one row per program.
*>
*>   PLB-SUMMARY-ADD    the programs of the file just analyzed, from
*>                      its metrics (copy/plbmetr.cpy)
*>   PLB-SUMMARY-PRINT  count the findings of each program, and print
*>                      the rows as text, Markdown, CSV, or JSON
*>
*> A run over a whole code base then reads as a table of where the
*> work is: the size, McCabe complexity, and maintainability index of
*> each program, with its findings by severity. Each finding is
*> counted for the innermost program whose lines hold it; findings
*> in copybooks, and those that comments, a baseline, or a diff leave
*> out, are not counted.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SUMMARY-ADD.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbmetrc.cpy".
01  WS-P                    PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbmetr.cpy".
COPY "plbsumm.cpy".
PROCEDURE DIVISION USING PLB-METRICS PLB-SUMMARY.
    PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > MP-COUNT
        IF SM-COUNT >= SM-MAX
            ADD 1 TO SM-DROPPED
        ELSE
            ADD 1 TO SM-COUNT
            MOVE MP-NAME(WS-P) TO SM-NAME(SM-COUNT)
            MOVE MP-FILE-ID(WS-P) TO SM-FILE-ID(SM-COUNT)
            MOVE MP-LINE(WS-P) TO SM-FIRST-LINE(SM-COUNT)
            *> The program's own lines are together in its file.
            COMPUTE SM-LAST-LINE(SM-COUNT) =
                MP-LINE(WS-P) + MP-LINES(WS-P) - 1
            MOVE MP-LINES(WS-P) TO SM-LINES(SM-COUNT)
            MOVE MP-COMPLEXITY(WS-P) TO SM-COMPLEXITY(SM-COUNT)
            MOVE MP-MAINTAINABILITY(WS-P)
                TO SM-MAINTAINABILITY(SM-COUNT)
            MOVE 0 TO SM-ERRORS(SM-COUNT) SM-WARNINGS(SM-COUNT)
                SM-NOTES(SM-COUNT)
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-SUMMARY-ADD.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SUMMARY-PRINT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-S                    PIC 9(9) COMP-5.
01  WS-BEST                 PIC 9(9) COMP-5.
01  WS-OUT                  PIC X(2048).
01  WS-PTR                  PIC 9(9) COMP-5.
01  WS-PATH                 PIC X(512).
01  WS-PATH-LEN             PIC 9(9) COMP-5.
01  WS-NUM                  PIC S9(18) COMP-5.
01  WS-NUM-TEXT             PIC X(20).
01  WS-NUM-LEN              PIC 9(9) COMP-5.
01  WS-PAD                  PIC 9(9) COMP-5.
01  WS-FIRST                PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbfind.cpy".
COPY "plbsumm.cpy".
*> text, md, csv, or json.
01  LK-FORMAT               PIC X(11).
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-FINDINGS PLB-SUMMARY
        LK-FORMAT.
    PERFORM COUNT-FINDINGS
    EVALUATE LK-FORMAT
        WHEN "md"
            DISPLAY "| Program | File | Lines | Complexity | "
                    "Maintainability | Errors | Warnings | Notes |"
            DISPLAY "|---|---|---:|---:|---:|---:|---:|---:|"
        WHEN "csv"
            DISPLAY "program,file,line,lines,complexity,"
                    "maintainability,errors,warnings,notes"
        WHEN "json"
            DISPLAY "{"
            DISPLAY '  "programs": ['
        WHEN OTHER
            DISPLAY "program                         lines  complexity"
                    "  maintainability  errors  warnings  notes  file"
    END-EVALUATE
    MOVE "Y" TO WS-FIRST
    PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SM-COUNT
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET SM-FILE-ID(WS-S)
            WS-PATH
        CALL "PLB-STR-LENGTH" USING WS-PATH WS-PATH-LEN
        EVALUATE LK-FORMAT
            WHEN "md"    PERFORM MD-ROW
            WHEN "csv"   PERFORM CSV-ROW
            WHEN "json"  PERFORM JSON-ROW
            WHEN OTHER   PERFORM TEXT-ROW
        END-EVALUATE
    END-PERFORM
    IF LK-FORMAT = "json"
        IF WS-FIRST = "N"
            DISPLAY WS-OUT(1:WS-PTR - 1)
        END-IF
        DISPLAY "  ]"
        DISPLAY "}"
    END-IF
    GOBACK.

*> Each finding that is reported, for the innermost program of its
*> file whose lines hold it: the one that starts last.
COUNT-FINDINGS.
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N"
            MOVE 0 TO WS-BEST
            PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SM-COUNT
                IF SM-FILE-ID(WS-S) = FN-FILE-ID(WS-I)
                   AND SM-FIRST-LINE(WS-S) <= FN-LINE(WS-I)
                   AND SM-LAST-LINE(WS-S) >= FN-LINE(WS-I)
                    IF WS-BEST = 0
                        MOVE WS-S TO WS-BEST
                    ELSE
                        IF SM-FIRST-LINE(WS-S) > SM-FIRST-LINE(WS-BEST)
                            MOVE WS-S TO WS-BEST
                        END-IF
                    END-IF
                END-IF
            END-PERFORM
            IF WS-BEST > 0
                EVALUATE FN-SEVERITY(WS-I)
                    WHEN "E"   ADD 1 TO SM-ERRORS(WS-BEST)
                    WHEN "W"   ADD 1 TO SM-WARNINGS(WS-BEST)
                    WHEN OTHER ADD 1 TO SM-NOTES(WS-BEST)
                END-EVALUATE
            END-IF
        END-IF
    END-PERFORM.

*> NAME, padded to 31, then the numbers right-aligned under their
*> headings, then the file.
TEXT-ROW.
    MOVE SPACES TO WS-OUT
    MOVE SM-NAME(WS-S) TO WS-OUT(1:31)
    MOVE 32 TO WS-PTR
    MOVE SM-LINES(WS-S) TO WS-NUM
    MOVE 6 TO WS-PAD
    PERFORM APPEND-RIGHT
    MOVE SM-COMPLEXITY(WS-S) TO WS-NUM
    MOVE 12 TO WS-PAD
    PERFORM APPEND-RIGHT
    MOVE SM-MAINTAINABILITY(WS-S) TO WS-NUM
    MOVE 17 TO WS-PAD
    PERFORM APPEND-RIGHT
    MOVE SM-ERRORS(WS-S) TO WS-NUM
    MOVE 8 TO WS-PAD
    PERFORM APPEND-RIGHT
    MOVE SM-WARNINGS(WS-S) TO WS-NUM
    MOVE 10 TO WS-PAD
    PERFORM APPEND-RIGHT
    MOVE SM-NOTES(WS-S) TO WS-NUM
    MOVE 7 TO WS-PAD
    PERFORM APPEND-RIGHT
    STRING "  " WS-PATH(1:WS-PATH-LEN) DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    DISPLAY WS-OUT(1:WS-PTR - 1).

*> WS-NUM right-aligned in a field of WS-PAD characters.
APPEND-RIGHT.
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    IF WS-NUM-LEN < WS-PAD
        ADD WS-PAD TO WS-PTR
        SUBTRACT WS-NUM-LEN FROM WS-PTR
    END-IF
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR.

MD-ROW.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "| " DELIMITED BY SIZE
           SM-NAME(WS-S) DELIMITED BY SPACE
           " | `" WS-PATH(1:WS-PATH-LEN) "` |" DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    PERFORM APPEND-MD-NUMBERS
    DISPLAY WS-OUT(1:WS-PTR - 1).

APPEND-MD-NUMBERS.
    MOVE SM-LINES(WS-S) TO WS-NUM
    PERFORM APPEND-MD-NUM
    MOVE SM-COMPLEXITY(WS-S) TO WS-NUM
    PERFORM APPEND-MD-NUM
    MOVE SM-MAINTAINABILITY(WS-S) TO WS-NUM
    PERFORM APPEND-MD-NUM
    MOVE SM-ERRORS(WS-S) TO WS-NUM
    PERFORM APPEND-MD-NUM
    MOVE SM-WARNINGS(WS-S) TO WS-NUM
    PERFORM APPEND-MD-NUM
    MOVE SM-NOTES(WS-S) TO WS-NUM
    PERFORM APPEND-MD-NUM.

APPEND-MD-NUM.
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING " " WS-NUM-TEXT(1:WS-NUM-LEN) " |" DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR.

*> The path quoted, with doubled quotes, so that commas are safe.
CSV-ROW.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING SM-NAME(WS-S) DELIMITED BY SPACE
           ',"' DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-PATH-LEN
        IF WS-PATH(WS-I:1) = '"'
            STRING '""' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        ELSE
            STRING WS-PATH(WS-I:1) DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-PERFORM
    STRING '"' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-FIRST-LINE(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    MOVE SM-LINES(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    MOVE SM-COMPLEXITY(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    MOVE SM-MAINTAINABILITY(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    MOVE SM-ERRORS(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    MOVE SM-WARNINGS(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    MOVE SM-NOTES(WS-S) TO WS-NUM
    PERFORM APPEND-CSV-NUM
    DISPLAY WS-OUT(1:WS-PTR - 1).

APPEND-CSV-NUM.
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING "," WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR.

*> One object per line; the one before is written here, with its
*> comma, so that the last has none.
JSON-ROW.
    IF WS-FIRST = "N"
        DISPLAY WS-OUT(1:WS-PTR - 1) ","
    END-IF
    MOVE "N" TO WS-FIRST
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING '    {"program": ' DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    CALL "PLB-JSON-STRING" USING SM-NAME(WS-S) WS-OUT WS-PTR
    STRING ', "file": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    CALL "PLB-JSON-STRING" USING WS-PATH WS-OUT WS-PTR
    STRING ', "line": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-FIRST-LINE(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING ', "lines": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-LINES(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING ', "complexity": ' DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-COMPLEXITY(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING ', "maintainability": ' DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-MAINTAINABILITY(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING ', "errors": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-ERRORS(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING ', "warnings": ' DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-WARNINGS(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING ', "notes": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SM-NOTES(WS-S) TO WS-NUM
    PERFORM APPEND-JSON-NUM
    STRING "}" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR.

APPEND-JSON-NUM.
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR.
END PROGRAM PLB-SUMMARY-PRINT.
