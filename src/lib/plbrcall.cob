*> ---------------------------------------------------------------
*> plbrcall: rules about calls between programs.
*>
*>   PLB-C013  call-argument-count
*>   PLB-C014  call-argument-mismatch
*>   PLB-C015  recursive-call
*>   PLB-M006  dynamic-call
*>
*> These run once per run, after every file's programs and calls are
*> in the call graph (plbcall), so a CALL in one file is checked
*> against the program it calls in another. Calls that do not
*> resolve to a program of the run are not checked.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-CALLS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
*> Resolved calls as edges between programs, sorted by caller.
01  WS-EDGES.
    05  WS-EDGE-COUNT       PIC 9(9) COMP-5.
    05  WS-EDGE             OCCURS 0 TO CC-MAX TIMES
                            DEPENDING ON WS-EDGE-COUNT.
        10  WS-EDGE-FROM    PIC 9(9) COMP-5.
        10  WS-EDGE-TO      PIC 9(9) COMP-5.
        10  WS-EDGE-CALL    PIC 9(9) COMP-5.
01  WS-NODES.
    05  WS-NODE             OCCURS CP-MAX TIMES.
        10  WS-EDGES-FIRST  PIC 9(9) COMP-5.
        10  WS-EDGES-LAST   PIC 9(9) COMP-5.
        10  WS-CALLED       PIC X.
        *> Breadth-first search: visited, and the program it was
        *> reached from.
        10  WS-SEEN         PIC X.
        10  WS-CAME-FROM    PIC 9(9) COMP-5.
01  WS-QUEUE                PIC 9(9) COMP-5 OCCURS CP-MAX TIMES.
01  WS-PATH-NODE            PIC 9(9) COMP-5 OCCURS 64 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE-COUNT           PIC 9(4) COMP-5.
01  LS-RULE-MISMATCH        PIC 9(4) COMP-5.
01  LS-RULE-RECURSIVE       PIC 9(4) COMP-5.
01  LS-RULE-DYNAMIC         PIC 9(4) COMP-5.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-X                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-ARG                  PIC 9(9) COMP-5.
01  LS-PARAM                PIC 9(9) COMP-5.
01  LS-HEAD                 PIC 9(9) COMP-5.
01  LS-TAIL                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C013" LS-RULE-COUNT
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C014" LS-RULE-MISMATCH
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C015" LS-RULE-RECURSIVE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M006" LS-RULE-DYNAMIC
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        EVALUATE TRUE
            WHEN CC-DYNAMIC(LS-C) = "Y"
                PERFORM CHECK-DYNAMIC
            WHEN CC-TO(LS-C) > 0
                PERFORM CHECK-ARGUMENTS
        END-EVALUATE
    END-PERFORM
    IF RL-ENABLED(LS-RULE-RECURSIVE) = "Y"
        PERFORM CHECK-RECURSION
    END-IF
    GOBACK.

*> PLB-M006 ------------------------------------------------------

CHECK-DYNAMIC.
    MOVE SPACES TO LS-MESSAGE
    STRING "the program called is named by data item "
           DELIMITED BY SIZE
           CC-TARGET(LS-C) DELIMITED BY SPACE
           ", so the call cannot be checked" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE LS-RULE-DYNAMIC TO LS-RULE
    PERFORM REPORT-AT-CALL.

*> PLB-C013 and PLB-C014 -----------------------------------------

CHECK-ARGUMENTS.
    MOVE CC-TO(LS-C) TO LS-P
    IF CC-ARG-COUNT(LS-C) NOT = CP-PARAM-COUNT(LS-P)
        MOVE SPACES TO LS-MESSAGE
        MOVE 1 TO LS-PTR
        STRING CP-NAME(LS-P) DELIMITED BY SPACE " takes "
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE CP-PARAM-COUNT(LS-P) TO LS-NUM
        PERFORM APPEND-COUNT-OF-PARAMETERS
        STRING ", but this CALL passes " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE CC-ARG-COUNT(LS-C) TO LS-NUM
        PERFORM APPEND-NUM
        MOVE LS-RULE-COUNT TO LS-RULE
        PERFORM REPORT-AT-CALL
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1
            UNTIL LS-I > CC-ARG-COUNT(LS-C)
               OR LS-I > CP-PARAM-COUNT(LS-P)
        COMPUTE LS-ARG = CC-ARG-FIRST(LS-C) + LS-I - 1
        COMPUTE LS-PARAM = CP-PARAM-FIRST(LS-P) + LS-I - 1
        IF CG-KIND(LS-ARG) NOT = "O"
            PERFORM CHECK-ONE-ARGUMENT
        END-IF
    END-PERFORM.

*> Argument LS-ARG against parameter LS-PARAM (number LS-I).
CHECK-ONE-ARGUMENT.
    MOVE LS-RULE-MISMATCH TO LS-RULE
    *> Passing mode.
    IF CG-MODE(LS-ARG) = "V" AND CA-MODE(LS-PARAM) NOT = "V"
       OR CG-MODE(LS-ARG) NOT = "V" AND CA-MODE(LS-PARAM) = "V"
        MOVE SPACES TO LS-MESSAGE
        MOVE 1 TO LS-PTR
        PERFORM APPEND-ARGUMENT-NUMBER
        STRING " is passed BY " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        EVALUATE CG-MODE(LS-ARG)
            WHEN "V"
                STRING "VALUE" DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
            WHEN "C"
                STRING "CONTENT" DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
            WHEN OTHER
                STRING "REFERENCE" DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
        END-EVALUATE
        STRING ", but " DELIMITED BY SIZE
               CP-NAME(LS-P) DELIMITED BY SPACE
               " takes " DELIMITED BY SIZE
               CA-NAME(LS-PARAM) DELIMITED BY SPACE
               " BY " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        IF CA-MODE(LS-PARAM) = "V"
            STRING "VALUE" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        ELSE
            STRING "REFERENCE" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-IF
        PERFORM REPORT-AT-CALL
        EXIT PARAGRAPH
    END-IF
    *> Size: a smaller argument lets the called program read and
    *> write past its end.
    IF CA-MODE(LS-PARAM) = "R" AND CG-SIZE(LS-ARG) > 0
       AND CA-SIZE(LS-PARAM) > 0
       AND CG-SIZE(LS-ARG) < CA-SIZE(LS-PARAM)
        MOVE SPACES TO LS-MESSAGE
        MOVE 1 TO LS-PTR
        PERFORM APPEND-ARGUMENT-NUMBER
        STRING " (" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM APPEND-ARGUMENT-TEXT
        STRING ", " DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE CG-SIZE(LS-ARG) TO LS-NUM
        PERFORM APPEND-BYTES
        STRING ") is smaller than parameter " DELIMITED BY SIZE
               CA-NAME(LS-PARAM) DELIMITED BY SPACE
               " of " DELIMITED BY SIZE
               CP-NAME(LS-P) DELIMITED BY SPACE
               " (" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE CA-SIZE(LS-PARAM) TO LS-NUM
        PERFORM APPEND-BYTES
        STRING ")" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM REPORT-AT-CALL
    END-IF.

APPEND-ARGUMENT-NUMBER.
    STRING "argument " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-I TO LS-NUM
    PERFORM APPEND-NUM.

*> A data item by name, a literal in quotes.
APPEND-ARGUMENT-TEXT.
    IF CG-KIND(LS-ARG) = "L"
        STRING """" CG-TEXT(LS-ARG) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        *> The literal without its trailing spaces.
        PERFORM UNTIL LS-PTR <= 2
            IF LS-MESSAGE(LS-PTR - 1:1) NOT = SPACE
                EXIT PERFORM
            END-IF
            SUBTRACT 1 FROM LS-PTR
        END-PERFORM
        IF CG-SIZE(LS-ARG) > LENGTH OF CG-TEXT(LS-ARG)
            STRING "..." DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-IF
        STRING """" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING CG-TEXT(LS-ARG) DELIMITED BY SPACE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF.

APPEND-BYTES.
    PERFORM APPEND-NUM
    IF LS-NUM = 1
        STRING " byte" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING " bytes" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF.

APPEND-COUNT-OF-PARAMETERS.
    PERFORM APPEND-NUM
    IF LS-NUM = 1
        STRING " parameter" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING " parameters" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.

*> PLB-C015 ------------------------------------------------------

*> A program that is not RECURSIVE must not be called while it is
*> running. For each such program V that is called, search the
*> programs V calls, directly or not; a call U -> V where U is among
*> them (or is V) can re-enter V.
CHECK-RECURSION.
    PERFORM BUILD-EDGES
    PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > CP-COUNT
        IF WS-CALLED(LS-V) = "Y" AND CP-RECURSIVE(LS-V) NOT = "Y"
            PERFORM SEARCH-FROM-V
            PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > WS-EDGE-COUNT
                IF WS-EDGE-TO(LS-E) = LS-V
                    MOVE WS-EDGE-FROM(LS-E) TO LS-U
                    IF WS-SEEN(LS-U) = "Y"
                        MOVE WS-EDGE-CALL(LS-E) TO LS-C
                        PERFORM REPORT-RECURSION
                    END-IF
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.

*> Edges between programs (an ENTRY point counts as its program).
BUILD-EDGES.
    MOVE 0 TO WS-EDGE-COUNT
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        MOVE "N" TO WS-CALLED(LS-P)
        MOVE 1 TO WS-EDGES-FIRST(LS-P)
        MOVE 0 TO WS-EDGES-LAST(LS-P)
    END-PERFORM
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        IF CC-TO(LS-C) > 0 AND CC-FROM(LS-C) > 0
            ADD 1 TO WS-EDGE-COUNT
            MOVE CC-FROM(LS-C) TO WS-EDGE-FROM(WS-EDGE-COUNT)
            MOVE CP-OWNER(CC-TO(LS-C)) TO WS-EDGE-TO(WS-EDGE-COUNT)
            MOVE LS-C TO WS-EDGE-CALL(WS-EDGE-COUNT)
            MOVE "Y" TO WS-CALLED(CP-OWNER(CC-TO(LS-C)))
        END-IF
    END-PERFORM
    IF WS-EDGE-COUNT > 1
        SORT WS-EDGE ON ASCENDING KEY WS-EDGE-FROM WS-EDGE-CALL
    END-IF
    PERFORM VARYING LS-E FROM WS-EDGE-COUNT BY -1 UNTIL LS-E = 0
        MOVE WS-EDGE-FROM(LS-E) TO LS-P
        MOVE LS-E TO WS-EDGES-FIRST(LS-P)
        IF WS-EDGES-LAST(LS-P) = 0
            MOVE LS-E TO WS-EDGES-LAST(LS-P)
        END-IF
    END-PERFORM.

*> Mark every program reachable from LS-V by calls (WS-SEEN), and
*> remember for each how it was reached.
SEARCH-FROM-V.
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        MOVE "N" TO WS-SEEN(LS-P)
        MOVE 0 TO WS-CAME-FROM(LS-P)
    END-PERFORM
    MOVE 1 TO LS-HEAD
    MOVE 1 TO LS-TAIL
    MOVE LS-V TO WS-QUEUE(1)
    MOVE "Y" TO WS-SEEN(LS-V)
    PERFORM UNTIL LS-HEAD > LS-TAIL
        MOVE WS-QUEUE(LS-HEAD) TO LS-X
        ADD 1 TO LS-HEAD
        PERFORM VARYING LS-E FROM WS-EDGES-FIRST(LS-X) BY 1
                UNTIL LS-E > WS-EDGES-LAST(LS-X)
            MOVE WS-EDGE-TO(LS-E) TO LS-P
            IF WS-SEEN(LS-P) = "N"
                MOVE "Y" TO WS-SEEN(LS-P)
                MOVE LS-X TO WS-CAME-FROM(LS-P)
                ADD 1 TO LS-TAIL
                MOVE LS-P TO WS-QUEUE(LS-TAIL)
            END-IF
        END-PERFORM
    END-PERFORM.

*> Call LS-C from LS-U to LS-V closes a cycle: V -> ... -> U -> V.
REPORT-RECURSION.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    IF LS-U = LS-V
        STRING CP-NAME(LS-V) DELIMITED BY SPACE
               " calls itself, but it is not RECURSIVE"
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        *> The path from V to U, found backwards.
        MOVE 0 TO LS-DEPTH
        MOVE LS-U TO LS-X
        PERFORM UNTIL LS-X = 0 OR LS-DEPTH >= 64
            ADD 1 TO LS-DEPTH
            MOVE LS-X TO WS-PATH-NODE(LS-DEPTH)
            IF LS-X = LS-V
                EXIT PERFORM
            END-IF
            MOVE WS-CAME-FROM(LS-X) TO LS-X
        END-PERFORM
        STRING CP-NAME(LS-V) DELIMITED BY SPACE
               " can be called while it is running (" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM VARYING LS-I FROM LS-DEPTH BY -1 UNTIL LS-I = 0
            STRING CP-NAME(WS-PATH-NODE(LS-I)) DELIMITED BY SPACE
                   " -> " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-PERFORM
        STRING CP-NAME(LS-V) DELIMITED BY SPACE
               "), but it is not RECURSIVE" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    MOVE LS-RULE-RECURSIVE TO LS-RULE
    PERFORM REPORT-AT-CALL.

REPORT-AT-CALL.
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        CC-FILE-ID(LS-C) CC-LINE(LS-C) CC-COLUMN(LS-C)
        CC-SRC-LINE(LS-C) LS-MESSAGE.
END PROGRAM PLB-RULE-CALLS.
