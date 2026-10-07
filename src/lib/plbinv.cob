*> ---------------------------------------------------------------
*> plbinv: the inventory of an application.
*>
*> plumbline inventory lists what a run holds and how it fits
*> together: each program with what starts it (job steps, CICS
*> transactions, the programs that call it) and what it uses (the
*> programs it calls or transfers to, its files and their DD names,
*> its SQL tables, its maps, and the CICS resources its commands
*> name); then the jobs
*> with their steps, and the transactions with their programs.
*>
*> A program's kind says how it starts: batch when a job step runs it,
*> online when a transaction starts it or it uses CICS, called when
*> only other programs call it or name it (a menu's table of the
*> programs it starts), and unused when nothing in the run does any of
*> these.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-INVENTORY.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
COPY "plbcsdc.cpy".
COPY "plbbmsc.cpy".
LOCAL-STORAGE SECTION.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
01  LS-SEEN                 PIC X.
01  LS-KIND                 PIC X(10).
01  LS-ONLINE               PIC X.
01  LS-BATCH                PIC X.
01  LS-CALLED               PIC X.
01  LS-NAME                 PIC X(31).
01  LS-PATH                 PIC X(1024).
01  LS-OUT                  PIC X(32000).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
*> JSON: whether an item of the current list was written yet.
01  LS-FIRST                PIC X.
01  LS-FIRST-PROGRAM        PIC X.
*> The start of each line about a program ("  ", or "- " in Markdown),
*> and the lines written under a Markdown heading.
01  LS-INDENT               PIC XX.
01  LS-MD                   PIC X.
01  LS-LINES                PIC 9(9) COMP-5.
01  LS-USES                 PIC X(6).
01  LS-FIRST-USE            PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
COPY "plbcsd.cpy".
COPY "plbbms.cpy".
01  LK-FORMAT               PIC X(5).
*> 0 for the whole inventory; a program of the call graph for that
*> program only (plumbline doc), as Markdown when FORMAT is "md".
*> FORMAT "mdidx" writes the index of plumbline doc: a Markdown table
*> of the programs, each linked to its page.
01  LK-ONLY                 PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-CALL-GRAPH PLB-JCL PLB-CSD
        PLB-BMS LK-FORMAT LK-ONLY.
    MOVE "  " TO LS-INDENT
    MOVE "N" TO LS-MD
    EVALUATE TRUE
        WHEN LK-ONLY > 0
            MOVE LK-ONLY TO LS-P
            IF LK-FORMAT = "md"
                MOVE "- " TO LS-INDENT
                MOVE "Y" TO LS-MD
            END-IF
            IF CP-PARENT(LS-P) > 0
                PERFORM NESTED-PROGRAM
            ELSE
                PERFORM TEXT-PROGRAM
            END-IF
        WHEN LK-FORMAT = "mdidx"
            PERFORM MD-INDEX
        WHEN LK-FORMAT = "json"
            PERFORM JSON-INVENTORY
        WHEN OTHER
            PERFORM TEXT-INVENTORY
    END-EVALUATE
    GOBACK.

*> Markdown index ---------------------------------------------------

*> | [NAME](#name) | kind | `path:line` |, for each program, nested
*> ones too (kind "nested").
MD-INDEX.
    DISPLAY "| Program | Kind | Source |"
    DISPLAY "|---|---|---|"
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P"
            IF CP-PARENT(LS-P) = 0
                PERFORM PROGRAM-KIND
            ELSE
                MOVE "nested" TO LS-KIND
            END-IF
            PERFORM START-OUT
            MOVE FUNCTION LOWER-CASE(CP-NAME(LS-P)) TO LS-NAME
            STRING "| [" DELIMITED BY SIZE
                   CP-NAME(LS-P) DELIMITED BY SPACE
                   "](#" DELIMITED BY SIZE
                   LS-NAME DELIMITED BY SPACE
                   ") | " DELIMITED BY SIZE
                   LS-KIND DELIMITED BY SPACE
                   " | `" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-PROGRAM-PLACE
            STRING "` |" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM.

*> Text -------------------------------------------------------------

TEXT-INVENTORY.
    MOVE 0 TO LS-COUNT
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P" AND CP-PARENT(LS-P) = 0
            ADD 1 TO LS-COUNT
        END-IF
    END-PERFORM
    MOVE "programs" TO LS-NAME
    PERFORM TEXT-HEADING
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P" AND CP-PARENT(LS-P) = 0
            PERFORM TEXT-PROGRAM
        END-IF
    END-PERFORM
    MOVE JJ-COUNT TO LS-COUNT
    MOVE "jobs" TO LS-NAME
    PERFORM TEXT-HEADING
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        PERFORM TEXT-JOB
    END-PERFORM
    MOVE 0 TO LS-COUNT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION"
            ADD 1 TO LS-COUNT
        END-IF
    END-PERFORM
    MOVE "transactions" TO LS-NAME
    PERFORM TEXT-HEADING
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION"
            PERFORM START-OUT
            STRING "transaction " DELIMITED BY SIZE
                   CR-NAME(LS-I) DELIMITED BY SPACE
                   " runs " DELIMITED BY SIZE
                   CR-TARGET(LS-I) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    MOVE 0 TO LS-COUNT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > BM-COUNT
        ADD 1 TO LS-COUNT
    END-PERFORM
    MOVE "maps" TO LS-NAME
    PERFORM TEXT-HEADING
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > BM-COUNT
        PERFORM TEXT-MAP
    END-PERFORM.

*> "NAME: COUNT", after a blank line except at the start.
TEXT-HEADING.
    IF LS-NAME NOT = "programs"
        CALL STATIC "putchar" USING BY VALUE 10
    END-IF
    PERFORM START-OUT
    MOVE LS-COUNT TO LS-NUM
    STRING LS-NAME DELIMITED BY SPACE
           ": " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-NUM
    PERFORM PRINT-OUT.

TEXT-PROGRAM.
    PERFORM PROGRAM-KIND
    PERFORM START-OUT
    IF LS-MD = "Y"
        STRING "Kind: **" DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               "**. Source: `" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        PERFORM APPEND-PROGRAM-PLACE
        STRING "`." DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        PERFORM PRINT-OUT
        CALL STATIC "putchar" USING BY VALUE 10
        DISPLAY "## How it starts"
        CALL STATIC "putchar" USING BY VALUE 10
    ELSE
        STRING "program " DELIMITED BY SIZE
               CP-NAME(LS-P) DELIMITED BY SPACE
               " " DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               " " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        PERFORM APPEND-PROGRAM-PLACE
        PERFORM PRINT-OUT
    END-IF
    MOVE 0 TO LS-LINES
    *> What starts it.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        PERFORM TEST-STEP-RUNS-PROGRAM
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "run by step " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-STEP
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION"
           AND CR-TARGET(LS-I) = CP-NAME(LS-P)
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "started by transaction " DELIMITED BY SIZE
                   CR-NAME(LS-I) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        PERFORM TEST-CALLER
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "called by " DELIMITED BY SIZE
                   CP-NAME(LS-OWNER) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PL-COUNT
        PERFORM TEST-NAMER
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "named by " DELIMITED BY SIZE
                   CP-NAME(LS-OWNER) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    IF LS-MD = "Y"
        IF LS-LINES = 0
            DISPLAY "Nothing in the run starts it."
        END-IF
        CALL STATIC "putchar" USING BY VALUE 10
        DISPLAY "## What it uses"
        CALL STATIC "putchar" USING BY VALUE 10
        MOVE 0 TO LS-LINES
    END-IF
    *> What it uses.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        PERFORM TEST-CALL
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "calls " DELIMITED BY SIZE
                   CC-TARGET(LS-I) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PU-COUNT
        PERFORM TEST-RESOURCE
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "uses " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-RESOURCE
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PF-COUNT
        PERFORM TEST-FILE
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "file " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-FILE
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PQ-COUNT
        PERFORM TEST-TABLE
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "table " DELIMITED BY SIZE
                   PQ-TABLE(LS-I) DELIMITED BY SPACE
                   " " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-TABLE-USES
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PM-COUNT
        PERFORM TEST-MAP-USE
        IF LS-SEEN = "Y"
            PERFORM START-OUT
            STRING LS-INDENT DELIMITED BY SIZE
                   "map " DELIMITED BY SIZE
                   PM-MAP(LS-I) DELIMITED BY SPACE
                   " of mapset " DELIMITED BY SIZE
                   PM-MAPSET(LS-I) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    IF LS-MD = "Y" AND LS-LINES = 0
        DISPLAY "Nothing outside the program that the run shows."
    END-IF
    IF LS-MD = "Y"
        CALL STATIC "putchar" USING BY VALUE 10
    END-IF.

*> A nested program, which the run sees as part of its outermost
*> program: what contains it, and its own calls in and out.
NESTED-PROGRAM.
    PERFORM START-OUT
    STRING "Nested in **" DELIMITED BY SIZE
           CP-NAME(CP-PARENT(LS-P)) DELIMITED BY SPACE
           "**" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    IF CP-COMMON(LS-P) = "Y"
        STRING " (common)" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    STRING ". Source: `" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-PROGRAM-PLACE
    STRING "`." DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "## How it starts"
    CALL STATIC "putchar" USING BY VALUE 10
    MOVE 0 TO LS-LINES
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        IF CC-TO(LS-I) > 0 AND CP-OWNER(CC-TO(LS-I)) = LS-P
            MOVE CP-OWNER(CC-FROM(LS-I)) TO LS-K
            MOVE "called" TO LS-USES
            PERFORM NESTED-CALL-LINE
        END-IF
    END-PERFORM
    IF LS-LINES = 0
        DISPLAY "Nothing in the run calls it."
    END-IF
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "## What it uses"
    CALL STATIC "putchar" USING BY VALUE 10
    MOVE 0 TO LS-LINES
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        IF CP-OWNER(CC-FROM(LS-I)) = LS-P
            MOVE "calls" TO LS-USES
            PERFORM NESTED-CALL-LINE
        END-IF
    END-PERFORM
    IF LS-LINES = 0
        DISPLAY "It calls no programs."
    END-IF
    CALL STATIC "putchar" USING BY VALUE 10.

*> One line for call LS-I: "called by" program LS-K, or "calls" its
*> target, once for each.
NESTED-CALL-LINE.
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF LS-USES = "called"
            IF CC-TO(LS-J) > 0 AND CP-OWNER(CC-TO(LS-J)) = LS-P
               AND CP-OWNER(CC-FROM(LS-J)) = LS-K
                EXIT PARAGRAPH
            END-IF
        ELSE
            IF CP-OWNER(CC-FROM(LS-J)) = LS-P
               AND CC-TARGET(LS-J) = CC-TARGET(LS-I)
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    PERFORM START-OUT
    STRING LS-INDENT DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    IF LS-USES = "called"
        STRING "called by " DELIMITED BY SIZE
               CP-NAME(LS-K) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "calls " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        IF CC-DYNAMIC(LS-I) = "Y"
            STRING "the program named in " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING CC-TARGET(LS-I) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

TEXT-JOB.
    PERFORM START-OUT
    STRING "job " DELIMITED BY SIZE
           JJ-NAME(LS-I) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET JJ-FILE-ID(LS-I)
        LS-PATH
    PERFORM APPEND-PATH
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE JJ-LINE(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    PERFORM PRINT-OUT
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > JS-COUNT
        IF JS-JOB(LS-J) = LS-I
            PERFORM START-OUT
            STRING "  step " DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-STEP-NAME
            IF JS-KIND(LS-J) = "R"
                STRING " runs procedure " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            ELSE
                STRING " runs " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
            IF JS-INNER(LS-J) NOT = SPACES
                STRING JS-INNER(LS-J) DELIMITED BY SPACE
                       " through " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
            STRING JS-TARGET(LS-J) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM.

TEXT-MAP.
    PERFORM START-OUT
    STRING "map " DELIMITED BY SIZE
           BM-NAME(LS-I) DELIMITED BY SPACE
        INTO LS-OUT WITH POINTER LS-PTR
    IF BM-MAPSET(LS-I) > 0
        STRING " of mapset " DELIMITED BY SIZE
               BS-NAME(BM-MAPSET(LS-I)) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    STRING ", " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE BM-FIELD-COUNT(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING " fields" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > PM-COUNT
        IF PM-MAP(LS-J) = BM-NAME(LS-I)
           AND BM-MAPSET(LS-I) > 0
            IF PM-MAPSET(LS-J) = BS-NAME(BM-MAPSET(LS-I))
                PERFORM TEST-FIRST-MAP-USER
                IF LS-SEEN = "Y"
                    PERFORM START-OUT
                    STRING "  used by " DELIMITED BY SIZE
                           CP-NAME(PM-PROGRAM(LS-J)) DELIMITED BY SPACE
                        INTO LS-OUT WITH POINTER LS-PTR
                    PERFORM PRINT-OUT
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> JSON -------------------------------------------------------------

JSON-INVENTORY.
    DISPLAY "{"
    DISPLAY '  "programs": ['
    MOVE "Y" TO LS-FIRST-PROGRAM
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P" AND CP-PARENT(LS-P) = 0
            PERFORM JSON-PROGRAM
        END-IF
    END-PERFORM
    DISPLAY "  ],"
    DISPLAY '  "jobs": ['
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        PERFORM JSON-JOB
    END-PERFORM
    DISPLAY "  ],"
    DISPLAY '  "transactions": ['
    MOVE "Y" TO LS-FIRST-PROGRAM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION"
            PERFORM START-OUT
            IF LS-FIRST-PROGRAM = "N"
                STRING "    ," DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            ELSE
                STRING "     " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
            MOVE "N" TO LS-FIRST-PROGRAM
            STRING '{"name": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING CR-NAME(LS-I) LS-OUT LS-PTR
            STRING ', "program": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING CR-TARGET(LS-I) LS-OUT LS-PTR
            STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    DISPLAY "  ]"
    DISPLAY "}".

*> One program as a JSON object on one line.
JSON-PROGRAM.
    PERFORM PROGRAM-KIND
    PERFORM START-OUT
    IF LS-FIRST-PROGRAM = "N"
        STRING "    ," DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "     " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-PROGRAM
    STRING '{"name": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING CP-NAME(LS-P) LS-OUT LS-PTR
    STRING ', "kind": "' DELIMITED BY SIZE
           LS-KIND DELIMITED BY SPACE
           '", "file": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET CP-FILE-ID(LS-P)
        LS-PATH
    CALL "PLB-JSON-STRING" USING LS-PATH LS-OUT LS-PTR
    STRING ', "line": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE CP-LINE(LS-P) TO LS-NUM
    PERFORM APPEND-NUM
    *> Steps that run it.
    STRING ', "steps": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        PERFORM TEST-STEP-RUNS-PROGRAM
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            STRING '{"job": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            IF JS-JOB(LS-I) > 0
                CALL "PLB-JSON-STRING" USING JJ-NAME(JS-JOB(LS-I))
                    LS-OUT LS-PTR
            ELSE
                STRING "null" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
            STRING ', "step": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING JS-NAME(LS-I) LS-OUT LS-PTR
            STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    STRING '], "transactions": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION"
           AND CR-TARGET(LS-I) = CP-NAME(LS-P)
            PERFORM JSON-COMMA
            CALL "PLB-JSON-STRING" USING CR-NAME(LS-I) LS-OUT LS-PTR
        END-IF
    END-PERFORM
    STRING '], "calledBy": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        PERFORM TEST-CALLER
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            CALL "PLB-JSON-STRING" USING CP-NAME(LS-OWNER) LS-OUT
                LS-PTR
        END-IF
    END-PERFORM
    STRING '], "namedBy": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PL-COUNT
        PERFORM TEST-NAMER
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            CALL "PLB-JSON-STRING" USING CP-NAME(LS-OWNER) LS-OUT
                LS-PTR
        END-IF
    END-PERFORM
    STRING '], "calls": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        PERFORM TEST-CALL
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            CALL "PLB-JSON-STRING" USING CC-TARGET(LS-I) LS-OUT LS-PTR
        END-IF
    END-PERFORM
    STRING '], "resources": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PU-COUNT
        PERFORM TEST-RESOURCE
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            STRING '{"kind": "' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-RESOURCE-KIND
            STRING '", "name": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING PU-NAME(LS-I) LS-OUT LS-PTR
            STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    STRING '], "files": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PF-COUNT
        PERFORM TEST-FILE
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            STRING '{"name": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING PF-NAME(LS-I) LS-OUT LS-PTR
            STRING ', "dd": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            IF PF-DDNAME(LS-I) = SPACES
                STRING "null" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            ELSE
                CALL "PLB-JSON-STRING" USING PF-DDNAME(LS-I) LS-OUT
                    LS-PTR
            END-IF
            STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    STRING '], "tables": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PQ-COUNT
        PERFORM TEST-TABLE
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            STRING '{"name": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING PQ-TABLE(LS-I) LS-OUT LS-PTR
            STRING ', "uses": "' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM APPEND-TABLE-USES
            STRING '"}' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    STRING '], "maps": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PM-COUNT
        PERFORM TEST-MAP-USE
        IF LS-SEEN = "Y"
            PERFORM JSON-COMMA
            STRING '{"map": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING PM-MAP(LS-I) LS-OUT LS-PTR
            STRING ', "mapset": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING PM-MAPSET(LS-I) LS-OUT LS-PTR
            STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    STRING "]}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

JSON-JOB.
    PERFORM START-OUT
    IF LS-I > 1
        STRING "    ," DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "     " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    STRING '{"name": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING JJ-NAME(LS-I) LS-OUT LS-PTR
    STRING ', "file": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET JJ-FILE-ID(LS-I)
        LS-PATH
    CALL "PLB-JSON-STRING" USING LS-PATH LS-OUT LS-PTR
    STRING ', "line": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE JJ-LINE(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "steps": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > JS-COUNT
        IF JS-JOB(LS-J) = LS-I
            PERFORM JSON-COMMA
            STRING '{"name": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-JSON-STRING" USING JS-NAME(LS-J) LS-OUT LS-PTR
            IF JS-KIND(LS-J) = "R"
                STRING ', "procedure": ' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            ELSE
                STRING ', "program": ' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
            CALL "PLB-JSON-STRING" USING JS-TARGET(LS-J) LS-OUT LS-PTR
            IF JS-INNER(LS-J) NOT = SPACES
                STRING ', "runs": ' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
                CALL "PLB-JSON-STRING" USING JS-INNER(LS-J) LS-OUT
                    LS-PTR
            END-IF
            STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    STRING "]}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

JSON-COMMA.
    IF LS-FIRST = "N"
        STRING ", " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST.

*> What relates to program LS-P -------------------------------------

*> LS-KIND: batch, online, called, or unused.
PROGRAM-KIND.
    MOVE "N" TO LS-BATCH LS-ONLINE LS-CALLED
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        PERFORM TEST-STEP-RUNS-PROGRAM
        IF LS-SEEN = "Y"
            MOVE "Y" TO LS-BATCH
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION"
           AND CR-TARGET(LS-I) = CP-NAME(LS-P)
            MOVE "Y" TO LS-ONLINE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PM-COUNT
        MOVE PM-PROGRAM(LS-I) TO LS-Q
        PERFORM OUTERMOST
        IF LS-OWNER = LS-P
            MOVE "Y" TO LS-ONLINE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PU-COUNT
        MOVE PU-PROGRAM(LS-I) TO LS-Q
        PERFORM OUTERMOST
        IF LS-OWNER = LS-P
            MOVE "Y" TO LS-ONLINE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CP-COUNT
        MOVE LS-I TO LS-Q
        PERFORM OUTERMOST
        IF LS-OWNER = LS-P AND CP-CICS(LS-I) = "Y"
            MOVE "Y" TO LS-ONLINE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        PERFORM TEST-CALLER
        IF LS-SEEN = "Y"
            MOVE "Y" TO LS-CALLED
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PL-COUNT
        PERFORM TEST-NAMER
        IF LS-SEEN = "Y"
            MOVE "Y" TO LS-CALLED
        END-IF
    END-PERFORM
    EVALUATE TRUE
        WHEN LS-BATCH = "Y"   MOVE "batch" TO LS-KIND
        WHEN LS-ONLINE = "Y"  MOVE "online" TO LS-KIND
        WHEN LS-CALLED = "Y"  MOVE "called" TO LS-KIND
        WHEN OTHER            MOVE "unused" TO LS-KIND
    END-EVALUATE.

*> LS-OWNER = the outermost program program LS-Q is in.
OUTERMOST.
    MOVE CP-OWNER(LS-Q) TO LS-OWNER
    PERFORM UNTIL CP-PARENT(LS-OWNER) = 0
        MOVE CP-PARENT(LS-OWNER) TO LS-OWNER
    END-PERFORM.

*> LS-SEEN = "Y" when step LS-I runs program LS-P, directly or as the
*> program IMS or DB2 starts.
TEST-STEP-RUNS-PROGRAM.
    MOVE "N" TO LS-SEEN
    IF JS-KIND(LS-I) = "P"
        IF JS-TARGET(LS-I) = CP-NAME(LS-P)
           OR JS-INNER(LS-I) = CP-NAME(LS-P)
            MOVE "Y" TO LS-SEEN
        END-IF
    END-IF.

*> LS-SEEN = "Y" when call LS-I is the first call into LS-P from
*> another program; LS-OWNER is the caller.
TEST-CALLER.
    MOVE "N" TO LS-SEEN
    IF CC-TO(LS-I) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE CC-TO(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER NOT = LS-P
        EXIT PARAGRAPH
    END-IF
    MOVE CC-FROM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER = LS-P
        EXIT PARAGRAPH
    END-IF
    MOVE LS-OWNER TO LS-K
    *> The first call from that caller.
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF CC-TO(LS-J) > 0
            MOVE CC-TO(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                MOVE CC-FROM(LS-J) TO LS-Q
                PERFORM OUTERMOST
                IF LS-OWNER = LS-K
                    MOVE LS-K TO LS-OWNER
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    MOVE LS-K TO LS-OWNER
    MOVE "Y" TO LS-SEEN.

*> LS-SEEN = "Y" when literal LS-I of another program names LS-P, the
*> first literal of that program to; LS-OWNER is that program.
TEST-NAMER.
    MOVE "N" TO LS-SEEN
    IF PL-NAME(LS-I) NOT = CP-NAME(LS-P)
        EXIT PARAGRAPH
    END-IF
    MOVE PL-PROGRAM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER = LS-P
        EXIT PARAGRAPH
    END-IF
    MOVE LS-OWNER TO LS-K
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF PL-NAME(LS-J) = PL-NAME(LS-I)
            MOVE PL-PROGRAM(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-K
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    *> A literal of a CALL is the call itself.
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > CC-COUNT
        IF CC-TO(LS-J) > 0
            MOVE CC-FROM(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-K
                MOVE CC-TO(LS-J) TO LS-Q
                PERFORM OUTERMOST
                IF LS-OWNER = LS-P
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    MOVE LS-K TO LS-OWNER
    MOVE "Y" TO LS-SEEN.

*> LS-SEEN = "Y" when call LS-I is from LS-P, the first to its target.
TEST-CALL.
    MOVE "N" TO LS-SEEN
    MOVE CC-FROM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER NOT = LS-P
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF CC-TARGET(LS-J) = CC-TARGET(LS-I)
            MOVE CC-FROM(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-SEEN.

*> LS-SEEN = "Y" when resource use LS-I is of LS-P, the first of that
*> kind and name.
TEST-RESOURCE.
    MOVE "N" TO LS-SEEN
    MOVE PU-PROGRAM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER NOT = LS-P
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF PU-KIND(LS-J) = PU-KIND(LS-I) AND PU-NAME(LS-J) = PU-NAME(LS-I)
            MOVE PU-PROGRAM(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-SEEN.

*> LS-SEEN = "Y" when table use LS-I is of LS-P, the first of its
*> table there.
TEST-TABLE.
    MOVE "N" TO LS-SEEN
    MOVE PQ-PROGRAM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER NOT = LS-P
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF PQ-TABLE(LS-J) = PQ-TABLE(LS-I)
            MOVE PQ-PROGRAM(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-SEEN.

*> The uses of table PQ-TABLE(LS-I) by LS-P, in a fixed order:
*> declare select insert update delete merge.
APPEND-TABLE-USES.
    MOVE "Y" TO LS-FIRST-USE
    MOVE "TSIUDM" TO LS-USES
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > 6
        PERFORM VARYING LS-J FROM LS-I BY 1 UNTIL LS-J > PQ-COUNT
            IF PQ-TABLE(LS-J) = PQ-TABLE(LS-I)
               AND PQ-KIND(LS-J) = LS-USES(LS-K:1)
                MOVE PQ-PROGRAM(LS-J) TO LS-Q
                PERFORM OUTERMOST
                IF LS-OWNER = LS-P
                    IF LS-FIRST-USE = "N"
                        STRING " " DELIMITED BY SIZE
                            INTO LS-OUT WITH POINTER LS-PTR
                    END-IF
                    MOVE "N" TO LS-FIRST-USE
                    EVALUATE LS-USES(LS-K:1)
                        WHEN "T" STRING "declare" DELIMITED BY SIZE
                                     INTO LS-OUT WITH POINTER LS-PTR
                        WHEN "S" STRING "select" DELIMITED BY SIZE
                                     INTO LS-OUT WITH POINTER LS-PTR
                        WHEN "I" STRING "insert" DELIMITED BY SIZE
                                     INTO LS-OUT WITH POINTER LS-PTR
                        WHEN "U" STRING "update" DELIMITED BY SIZE
                                     INTO LS-OUT WITH POINTER LS-PTR
                        WHEN "D" STRING "delete" DELIMITED BY SIZE
                                     INTO LS-OUT WITH POINTER LS-PTR
                        WHEN "M" STRING "merge" DELIMITED BY SIZE
                                     INTO LS-OUT WITH POINTER LS-PTR
                    END-EVALUATE
                    EXIT PERFORM
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM.

*> LS-SEEN = "Y" when file LS-I is a file of LS-P.
TEST-FILE.
    MOVE "N" TO LS-SEEN
    MOVE PF-PROGRAM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER = LS-P
        MOVE "Y" TO LS-SEEN
    END-IF.

*> LS-SEEN = "Y" when map use LS-I is of LS-P, the first of that map.
TEST-MAP-USE.
    MOVE "N" TO LS-SEEN
    MOVE PM-PROGRAM(LS-I) TO LS-Q
    PERFORM OUTERMOST
    IF LS-OWNER NOT = LS-P
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J >= LS-I
        IF PM-MAP(LS-J) = PM-MAP(LS-I) AND PM-MAPSET(LS-J) = PM-MAPSET(LS-I)
            MOVE PM-PROGRAM(LS-J) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-SEEN.

*> LS-SEEN = "Y" when map use LS-J is the first by its program of the
*> map (for the list of a map's users).
TEST-FIRST-MAP-USER.
    MOVE "Y" TO LS-SEEN
    MOVE PM-PROGRAM(LS-J) TO LS-Q
    PERFORM OUTERMOST
    MOVE LS-OWNER TO LS-P
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K >= LS-J
        IF PM-MAP(LS-K) = PM-MAP(LS-J) AND PM-MAPSET(LS-K) = PM-MAPSET(LS-J)
            MOVE PM-PROGRAM(LS-K) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                MOVE "N" TO LS-SEEN
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> Text pieces ------------------------------------------------------

APPEND-PROGRAM-PLACE.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET CP-FILE-ID(LS-P)
        LS-PATH
    PERFORM APPEND-PATH
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE CP-LINE(LS-P) TO LS-NUM
    PERFORM APPEND-NUM.

*> STEP of job JOB (of proc PROC).
APPEND-STEP.
    MOVE LS-I TO LS-J
    PERFORM APPEND-STEP-NAME
    EVALUATE TRUE
        WHEN JS-PROC(LS-I) > 0
            STRING " of procedure " DELIMITED BY SIZE
                   JP-NAME(JS-PROC(LS-I)) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
        WHEN JS-JOB(LS-I) > 0
            STRING " of job " DELIMITED BY SIZE
                   JJ-NAME(JS-JOB(LS-I)) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
    END-EVALUATE.

APPEND-STEP-NAME.
    IF JS-NAME(LS-J) = SPACES
        STRING "-" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING JS-NAME(LS-J) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF.

*> KIND NAME (COMMAND).
APPEND-RESOURCE.
    PERFORM APPEND-RESOURCE-KIND
    STRING " " DELIMITED BY SIZE
           PU-NAME(LS-I) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
           PU-COMMAND(LS-I) DELIMITED BY SPACE
           ")" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

APPEND-RESOURCE-KIND.
    EVALUATE PU-KIND(LS-I)
        WHEN "F" STRING "file" DELIMITED BY SIZE
                     INTO LS-OUT WITH POINTER LS-PTR
        WHEN "T" STRING "transaction" DELIMITED BY SIZE
                     INTO LS-OUT WITH POINTER LS-PTR
        WHEN "P" STRING "program" DELIMITED BY SIZE
                     INTO LS-OUT WITH POINTER LS-PTR
        WHEN "M" STRING "mapset" DELIMITED BY SIZE
                     INTO LS-OUT WITH POINTER LS-PTR
        WHEN "Q" STRING "tdqueue" DELIMITED BY SIZE
                     INTO LS-OUT WITH POINTER LS-PTR
    END-EVALUATE.

*> NAME dd DDNAME [optional] [input output i-o extend].
APPEND-FILE.
    STRING PF-NAME(LS-I) DELIMITED BY SPACE
        INTO LS-OUT WITH POINTER LS-PTR
    IF PF-DDNAME(LS-I) NOT = SPACES
        STRING " dd " DELIMITED BY SIZE
               PF-DDNAME(LS-I) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    IF PF-INPUT(LS-I) = "Y"
        STRING " input" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    IF PF-OUTPUT(LS-I) = "Y"
        STRING " output" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    IF PF-I-O(LS-I) = "Y"
        STRING " i-o" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    IF PF-EXTEND(LS-I) = "Y"
        STRING " extend" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF.

APPEND-PATH.
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
    IF LS-LEN > 0
        STRING LS-PATH(1:LS-LEN) DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
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
        ADD 1 TO LS-LINES
    END-IF.
END PROGRAM PLB-INVENTORY.
