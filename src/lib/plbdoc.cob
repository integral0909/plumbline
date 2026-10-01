*> ---------------------------------------------------------------
*> plbdoc: documentation of programs.
*>
*> plumbline doc writes a Markdown page for each program of the run:
*> how it starts and what it uses (from the inventory, plbinv), its
*> paragraphs and sections with their size, complexity, and the
*> paragraphs they perform and jump to (from the procedure graph and
*> the metrics), and its records (from the layout, plblayout).
*> PLB-DOC-PARAGRAPHS writes the paragraph table of one program, from
*> the metrics computed for its file.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DOC-PARAGRAPHS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-SEEN                 PIC X.
01  LS-FIRST                PIC X.
01  LS-KIND                 PIC X.
01  LS-OUT                  PIC X(4000).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbflow.cpy".
COPY "plbmetrc.cpy".
COPY "plbmetr.cpy".
*> The program's entry in the metrics (PLB-METRICS-COMPUTE).
01  LS-M                    PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-FLOW PLB-METRICS LS-M.
    DISPLAY "## Paragraphs"
    DISPLAY " "
    PERFORM PROGRAM-TABLE
    GOBACK.

PROGRAM-TABLE.
    PERFORM START-OUT
    MOVE MP-LINES(LS-M) TO LS-NUM
    PERFORM APPEND-NUM
    IF LS-NUM = 1
        STRING " line, " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING " lines, " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE MP-STATEMENTS(LS-M) TO LS-NUM
    PERFORM APPEND-NUM
    IF LS-NUM = 1
        STRING " statement, complexity " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING " statements, complexity " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE MP-COMPLEXITY(LS-M) TO LS-NUM
    PERFORM APPEND-NUM
    STRING "." DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    DISPLAY " "
    IF MP-UNIT-COUNT(LS-M) = 0
        DISPLAY "The program has no paragraphs."
        DISPLAY " "
        EXIT PARAGRAPH
    END-IF
    DISPLAY "| Paragraph | Lines | Statements | Complexity | Performs |"
        " Goes to | Runs |"
    DISPLAY "|---|---:|---:|---:|---|---|---|"
    PERFORM VARYING LS-U FROM MP-UNIT-FIRST(LS-M) BY 1
            UNTIL LS-U >= MP-UNIT-FIRST(LS-M) + MP-UNIT-COUNT(LS-M)
        PERFORM UNIT-ROW
    END-PERFORM
    DISPLAY " ".

*> | NAME | lines | statements | complexity | performs | goes to | runs |
UNIT-ROW.
    MOVE MU-UNIT(LS-U) TO LS-UNIT
    PERFORM START-OUT
    STRING "| " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    EVALUATE MU-KIND(LS-U)
        WHEN "S"
            STRING "**" DELIMITED BY SIZE
                   MU-NAME(LS-U) DELIMITED BY SPACE
                   "** (section)" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        WHEN "P"
            STRING MU-NAME(LS-U) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
        WHEN OTHER
            STRING "(start)" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
    END-EVALUATE
    STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE MU-LINES(LS-U) TO LS-NUM
    PERFORM APPEND-NUM
    STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE MU-STATEMENTS(LS-U) TO LS-NUM
    PERFORM APPEND-NUM
    STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE MU-COMPLEXITY(LS-U) TO LS-NUM
    PERFORM APPEND-NUM
    STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE "P" TO LS-KIND
    PERFORM APPEND-TARGETS
    STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE "G" TO LS-KIND
    PERFORM APPEND-TARGETS
    STRING " | " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    IF FU-REACHED(LS-UNIT) = "Y"
        STRING "yes" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "**never**" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    STRING " |" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

*> The units the edges of kind LS-KIND from LS-UNIT lead to, each once.
APPEND-TARGETS.
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-FROM(LS-E) = LS-UNIT AND FE-KIND(LS-E) = LS-KIND
           AND FE-TO(LS-E) > 0
            MOVE "N" TO LS-SEEN
            PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F >= LS-E
                IF FE-FROM(LS-F) = LS-UNIT AND FE-KIND(LS-F) = LS-KIND
                   AND FE-TO(LS-F) = FE-TO(LS-E)
                    MOVE "Y" TO LS-SEEN
                    EXIT PERFORM
                END-IF
            END-PERFORM
            IF LS-SEEN = "N" AND LS-PTR < 3900
                IF LS-FIRST = "N"
                    STRING ", " DELIMITED BY SIZE
                        INTO LS-OUT WITH POINTER LS-PTR
                END-IF
                MOVE "N" TO LS-FIRST
                STRING FU-NAME(FE-TO(LS-E)) DELIMITED BY SPACE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
        END-IF
    END-PERFORM.

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
END PROGRAM PLB-DOC-PARAGRAPHS.
