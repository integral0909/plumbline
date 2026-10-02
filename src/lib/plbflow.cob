*> ---------------------------------------------------------------
*> plbflow: the procedure graph.
*>
*> PLB-FLOW-BUILD collects the units (sections and paragraphs) of every
*> procedure division, the PERFORM and GO TO edges between them, and
*> which units can be reached. See copy/plbflow.cpy.
*>
*> Procedure names are resolved as the standard describes: a qualified
*> name (P IN S) must be a paragraph of that section; an unqualified
*> name is a paragraph of the current section, else a paragraph that
*> is unique in the program, else a section.
*>
*> Reachability starts at the first unit of each program and at every
*> declarative section. Control flows (FU-FLOWED) from an entry, from
*> a unit that flows and falls through, and to a GO TO target. A
*> PERFORM runs every unit of its range, but returns at the end of it:
*> a unit reached only by PERFORM does not carry control on into the
*> unit after the range.
*>
*> Diagnostic codes raised here:
*>   FL001  error    PERFORM or GO TO names no paragraph or section
*>   FL002  warning  paragraph name is ambiguous without qualification
*>   FL003  error    procedure graph full
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FLOW-BUILD.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Work queue of units to visit (a unit can be queued twice: once
*> when reached by PERFORM, again when found to flow).
01  WS-QUEUE                PIC 9(9) COMP-5 OCCURS 40000 TIMES.
*> Edges are made in unit order, so each unit's edges are one run.
01  WS-EDGE-FIRST           PIC 9(9) COMP-5 OCCURS 20000 TIMES.
01  WS-EDGE-LAST            PIC 9(9) COMP-5 OCCURS 20000 TIMES.
*> Last unit each edge's PERFORM range runs through.
01  WS-RANGE-END            PIC 9(9) COMP-5 OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-PROC-DIVISION        PIC 9(9) COMP-5.
01  LS-DECLARATIVES         PIC 9(9) COMP-5.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-SECTION-UNIT         PIC 9(9) COMP-5.
01  LS-PREV-UNIT            PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-KIND                 PIC X.
01  LS-NAME                 PIC X(31).
01  LS-QUALIFIER            PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
01  LS-MATCHES              PIC 9(9) COMP-5.
01  LS-QUAL-UNIT            PIC 9(9) COMP-5.
01  LS-FULL                 PIC X VALUE "N".
01  LS-HEAD                 PIC 9(9) COMP-5.
01  LS-TAIL                 PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbflow.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-FLOW.
    MOVE 0 TO FU-COUNT FE-COUNT LS-PROGRAM LS-PROC-DIVISION
        LS-DECLARATIVES LS-UNIT LS-SECTION-UNIT LS-PREV-UNIT LS-DEPTH
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    PERFORM UNTIL LS-NODE = 0 OR LS-FULL = "Y"
        PERFORM VISIT-NODE
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        PERFORM DECIDE-FALL-THROUGH
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        PERFORM RESOLVE-EDGE
    END-PERFORM
    PERFORM COMPUTE-REACHABILITY
    GOBACK.

*> Collect units and edges ------------------------------------------

VISIT-NODE.
    EVALUATE ND-KIND(LS-NODE)
        WHEN "PROG"
            MOVE LS-NODE TO LS-PROGRAM
            MOVE 0 TO LS-PROC-DIVISION LS-UNIT LS-SECTION-UNIT
                LS-DECLARATIVES LS-PREV-UNIT
        WHEN "DIVN"
            IF ND-DETAIL(LS-NODE) = "PROCEDURE"
                MOVE LS-NODE TO LS-PROC-DIVISION
                MOVE 0 TO LS-UNIT LS-SECTION-UNIT LS-DECLARATIVES
                    LS-PREV-UNIT
            ELSE
                MOVE 0 TO LS-PROC-DIVISION
            END-IF
        WHEN "OTHR"
            IF ND-DETAIL(LS-NODE) = "DECLARATIVES"
               AND LS-PROC-DIVISION > 0
                MOVE LS-NODE TO LS-DECLARATIVES
            END-IF
        WHEN "SECT"
            IF LS-PROC-DIVISION > 0
                PERFORM LEAVE-DECLARATIVES
                MOVE "S" TO LS-KIND
                PERFORM ADD-UNIT
                MOVE LS-UNIT TO LS-SECTION-UNIT
            END-IF
        WHEN "PARA"
            IF LS-PROC-DIVISION > 0
                PERFORM LEAVE-DECLARATIVES
                MOVE "P" TO LS-KIND
                PERFORM ADD-UNIT
            END-IF
        WHEN "STMT"
            IF LS-PROC-DIVISION > 0
                PERFORM VISIT-STATEMENT
            END-IF
        WHEN "PROC"
            IF LS-PROC-DIVISION > 0
                PERFORM ADD-EDGE
            END-IF
    END-EVALUATE.

*> Units after END DECLARATIVES are ordinary units.
LEAVE-DECLARATIVES.
    IF LS-DECLARATIVES > 0
        IF ND-TOK-FIRST(LS-NODE) > ND-TOK-LAST(LS-DECLARATIVES)
            MOVE 0 TO LS-DECLARATIVES LS-SECTION-UNIT
        END-IF
    END-IF.

ADD-UNIT.
    IF FU-COUNT >= FU-MAX
        PERFORM GRAPH-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO FU-COUNT
    MOVE FU-COUNT TO LS-UNIT
    MOVE LS-NODE TO FU-NODE(LS-UNIT)
    MOVE LS-KIND TO FU-KIND(LS-UNIT)
    MOVE SPACES TO FU-NAME(LS-UNIT)
    IF ND-NAME(LS-NODE) > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE)
            FU-NAME(LS-UNIT) LS-LEN
    END-IF
    MOVE LS-PROGRAM TO FU-PROGRAM(LS-UNIT)
    IF LS-KIND = "P"
        MOVE LS-SECTION-UNIT TO FU-SECTION(LS-UNIT)
    ELSE
        MOVE 0 TO FU-SECTION(LS-UNIT)
    END-IF
    IF LS-DECLARATIVES > 0
        MOVE "Y" TO FU-DECLARATIVE(LS-UNIT)
    ELSE
        MOVE "N" TO FU-DECLARATIVE(LS-UNIT)
    END-IF
    MOVE 0 TO FU-NEXT(LS-UNIT) FU-LAST-STMT(LS-UNIT)
    MOVE "Y" TO FU-FALLS(LS-UNIT)
    MOVE "N" TO FU-REACHED(LS-UNIT) FU-FLOWED(LS-UNIT)
        FU-PERFORMED(LS-UNIT) FU-JUMPED-TO(LS-UNIT)
    *> Control never falls out of the declaratives into the rest of
    *> the procedure division.
    IF LS-PREV-UNIT > 0
        IF FU-DECLARATIVE(LS-PREV-UNIT) = FU-DECLARATIVE(LS-UNIT)
            MOVE LS-UNIT TO FU-NEXT(LS-PREV-UNIT)
        END-IF
    END-IF
    MOVE LS-UNIT TO LS-PREV-UNIT.

*> Statements before any section or paragraph belong to an unnamed
*> unit for the start of the division. A statement directly in a
*> sentence of the unit may be its last one.
VISIT-STATEMENT.
    IF LS-UNIT = 0
        MOVE LS-NODE TO LS-A
        MOVE LS-PROC-DIVISION TO LS-NODE
        MOVE "D" TO LS-KIND
        PERFORM ADD-UNIT
        MOVE LS-A TO LS-NODE
        IF LS-UNIT = 0
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF ND-KIND(ND-PARENT(LS-NODE)) = "SENT"
        MOVE LS-NODE TO FU-LAST-STMT(LS-UNIT)
    END-IF.

*> A PROC node under PERFORM or GO TO. THRU completes the edge made
*> for the PROC node before it.
ADD-EDGE.
    IF LS-UNIT = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-DETAIL(LS-NODE) = "THRU"
        IF FE-COUNT > 0
            MOVE LS-NODE TO FE-THRU(FE-COUNT)
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF FE-COUNT >= FE-MAX
        PERFORM GRAPH-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO FE-COUNT
    IF ND-DETAIL(LS-NODE) = "GO"
        MOVE "G" TO FE-KIND(FE-COUNT)
    ELSE
        MOVE "P" TO FE-KIND(FE-COUNT)
    END-IF
    MOVE LS-UNIT TO FE-FROM(FE-COUNT)
    MOVE 0 TO FE-TO(FE-COUNT)
    *> FE-THRU holds the THRU PROC node until resolution.
    MOVE 0 TO FE-THRU(FE-COUNT)
    MOVE ND-PARENT(LS-NODE) TO FE-STMT(FE-COUNT)
    MOVE LS-NODE TO FE-PROC(FE-COUNT).

GRAPH-FULL.
    MOVE "Y" TO LS-FULL
    CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        ND-TOK-FIRST(LS-NODE) "E" "FL003"
        "procedure graph full; the rest is not analyzed".

*> Fall-through ---------------------------------------------------

*> Control cannot pass STOP RUN, GOBACK, EXIT PROGRAM, EXIT FUNCTION,
*> or a GO TO without DEPENDING ON. A section falls into its first
*> paragraph whatever it contains.
DECIDE-FALL-THROUGH.
    MOVE FU-LAST-STMT(LS-U) TO LS-STMT
    IF LS-STMT = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE ND-DETAIL(LS-STMT)
        WHEN "GOBACK"
        WHEN "EXIT PROGRAM"
        WHEN "EXIT FUNCTION"
            MOVE "N" TO FU-FALLS(LS-U)
        WHEN "STOP"
            COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-STMT) + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
            IF LS-TEXT = "RUN"
                MOVE "N" TO FU-FALLS(LS-U)
            END-IF
        WHEN "GO"
            MOVE "N" TO FU-FALLS(LS-U)
            PERFORM VARYING LS-TOKEN FROM ND-TOK-FIRST(LS-STMT) BY 1
                    UNTIL LS-TOKEN > ND-TOK-LAST(LS-STMT)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT
                    LS-LEN
                IF LS-TEXT = "DEPENDING" AND TK-IS-WORD(LS-TOKEN)
                    MOVE "Y" TO FU-FALLS(LS-U)
                    EXIT PERFORM
                END-IF
            END-PERFORM
    END-EVALUATE
    IF FU-KIND(LS-U) = "S" AND FU-NEXT(LS-U) > 0
        IF FU-SECTION(FU-NEXT(LS-U)) = LS-U
            MOVE "Y" TO FU-FALLS(LS-U)
        END-IF
    END-IF.

*> Name resolution -------------------------------------------------

RESOLVE-EDGE.
    MOVE FE-PROC(LS-E) TO LS-NODE
    PERFORM RESOLVE-PROC-NODE
    MOVE LS-FOUND TO FE-TO(LS-E)
    MOVE LS-FOUND TO LS-A
    IF FE-THRU(LS-E) > 0
        MOVE FE-THRU(LS-E) TO LS-NODE
        PERFORM RESOLVE-PROC-NODE
        MOVE LS-FOUND TO FE-THRU(LS-E)
    ELSE
        MOVE LS-A TO FE-THRU(LS-E)
    END-IF
    *> A range that ends at a section runs to the section's last
    *> paragraph.
    IF FE-THRU(LS-E) > 0
        IF FU-KIND(FE-THRU(LS-E)) = "S"
            MOVE FE-THRU(LS-E) TO LS-K
            PERFORM UNTIL FU-NEXT(LS-K) = 0
                IF FU-SECTION(FU-NEXT(LS-K)) NOT = FE-THRU(LS-E)
                    EXIT PERFORM
                END-IF
                MOVE FU-NEXT(LS-K) TO LS-K
            END-PERFORM
            MOVE LS-K TO WS-RANGE-END(LS-E)
        ELSE
            MOVE FE-THRU(LS-E) TO WS-RANGE-END(LS-E)
        END-IF
    ELSE
        MOVE 0 TO WS-RANGE-END(LS-E)
    END-IF
    IF FE-TO(LS-E) > 0
        IF FE-KIND(LS-E) = "P"
            MOVE "Y" TO FU-PERFORMED(FE-TO(LS-E))
        ELSE
            MOVE "Y" TO FU-JUMPED-TO(FE-TO(LS-E))
        END-IF
    END-IF.

*> Resolve PROC node LS-NODE (name, optionally IN/OF section) to a
*> unit of the program of edge LS-E. LS-FOUND receives it, or 0 after
*> reporting FL001.
RESOLVE-PROC-NODE.
    MOVE 0 TO LS-FOUND LS-QUAL-UNIT
    MOVE SPACES TO LS-NAME LS-QUALIFIER
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE) LS-NAME
        LS-LEN
    IF ND-TOK-LAST(LS-NODE) >= ND-NAME(LS-NODE) + 2
        COMPUTE LS-TOKEN = ND-NAME(LS-NODE) + 2
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-QUALIFIER
            LS-LEN
    END-IF
    MOVE FE-FROM(LS-E) TO LS-U

    IF LS-QUALIFIER NOT = SPACES
        PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FU-COUNT
            IF FU-PROGRAM(LS-K) = FU-PROGRAM(LS-U)
               AND FU-KIND(LS-K) = "S" AND FU-NAME(LS-K) = LS-QUALIFIER
                MOVE LS-K TO LS-QUAL-UNIT
                EXIT PERFORM
            END-IF
        END-PERFORM
        PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FU-COUNT
            IF FU-PROGRAM(LS-K) = FU-PROGRAM(LS-U)
               AND FU-KIND(LS-K) = "P" AND FU-NAME(LS-K) = LS-NAME
               AND FU-SECTION(LS-K) = LS-QUAL-UNIT
               AND LS-QUAL-UNIT > 0
                MOVE LS-K TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-PERFORM
    ELSE
        *> A paragraph in the referencing unit's own section.
        MOVE FU-SECTION(LS-U) TO LS-QUAL-UNIT
        IF FU-KIND(LS-U) = "S"
            MOVE LS-U TO LS-QUAL-UNIT
        END-IF
        IF LS-QUAL-UNIT > 0
            PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FU-COUNT
                IF FU-PROGRAM(LS-K) = FU-PROGRAM(LS-U)
                   AND FU-KIND(LS-K) = "P" AND FU-NAME(LS-K) = LS-NAME
                   AND FU-SECTION(LS-K) = LS-QUAL-UNIT
                    MOVE LS-K TO LS-FOUND
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
        *> Else a paragraph anywhere in the program; it should be
        *> unique there.
        IF LS-FOUND = 0
            MOVE 0 TO LS-MATCHES
            PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FU-COUNT
                IF FU-PROGRAM(LS-K) = FU-PROGRAM(LS-U)
                   AND FU-KIND(LS-K) = "P" AND FU-NAME(LS-K) = LS-NAME
                    ADD 1 TO LS-MATCHES
                    IF LS-FOUND = 0
                        MOVE LS-K TO LS-FOUND
                    END-IF
                END-IF
            END-PERFORM
            IF LS-MATCHES > 1
                MOVE SPACES TO LS-MESSAGE
                STRING "paragraph " FUNCTION TRIM(LS-NAME)
                    " is defined in more than one section; qualify it"
                    DELIMITED BY SIZE INTO LS-MESSAGE
                CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                    PLB-TOKENS ND-NAME(LS-NODE) "W" "FL002" LS-MESSAGE
            END-IF
        END-IF
        *> Else a section.
        IF LS-FOUND = 0
            PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FU-COUNT
                IF FU-PROGRAM(LS-K) = FU-PROGRAM(LS-U)
                   AND FU-KIND(LS-K) = "S" AND FU-NAME(LS-K) = LS-NAME
                    MOVE LS-K TO LS-FOUND
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
    END-IF
    IF LS-FOUND = 0
        MOVE SPACES TO LS-MESSAGE
        STRING FUNCTION TRIM(LS-NAME)
            " is not a paragraph or section of this program"
            DELIMITED BY SIZE INTO LS-MESSAGE
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS ND-NAME(LS-NODE) "E" "FL001" LS-MESSAGE
    END-IF.

*> Reachability ----------------------------------------------------

COMPUTE-REACHABILITY.
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE 1 TO WS-EDGE-FIRST(LS-U)
        MOVE 0 TO WS-EDGE-LAST(LS-U)
    END-PERFORM
    PERFORM VARYING LS-E FROM FE-COUNT BY -1 UNTIL LS-E = 0
        MOVE LS-E TO WS-EDGE-FIRST(FE-FROM(LS-E))
        IF WS-EDGE-LAST(FE-FROM(LS-E)) = 0
            MOVE LS-E TO WS-EDGE-LAST(FE-FROM(LS-E))
        END-IF
    END-PERFORM

    MOVE 0 TO LS-HEAD LS-TAIL LS-PROGRAM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-DECLARATIVE(LS-U) = "Y" AND FU-KIND(LS-U) = "S"
            PERFORM ENQUEUE-FLOW
        END-IF
        IF FU-DECLARATIVE(LS-U) = "N"
           AND FU-PROGRAM(LS-U) NOT = LS-PROGRAM
            MOVE FU-PROGRAM(LS-U) TO LS-PROGRAM
            PERFORM ENQUEUE-FLOW
        END-IF
    END-PERFORM
    PERFORM UNTIL LS-HEAD >= LS-TAIL
        ADD 1 TO LS-HEAD
        MOVE WS-QUEUE(LS-HEAD) TO LS-A
        IF FU-FLOWED(LS-A) = "Y" AND FU-FALLS(LS-A) = "Y"
           AND FU-NEXT(LS-A) > 0
            MOVE FU-NEXT(LS-A) TO LS-U
            PERFORM ENQUEUE-FLOW
        END-IF
        PERFORM VARYING LS-E FROM WS-EDGE-FIRST(LS-A) BY 1
                UNTIL LS-E > WS-EDGE-LAST(LS-A)
            IF FE-TO(LS-E) > 0
                IF FE-KIND(LS-E) = "G"
                    MOVE FE-TO(LS-E) TO LS-U
                    PERFORM ENQUEUE-FLOW
                ELSE
                    PERFORM ENQUEUE-RANGE
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM.

*> Every unit from the edge's target to the end of its THRU range
*> runs; none of them carries control past the range.
ENQUEUE-RANGE.
    MOVE FE-TO(LS-E) TO LS-U
    PERFORM UNTIL LS-U = 0
        IF FU-REACHED(LS-U) = "N"
            MOVE "Y" TO FU-REACHED(LS-U)
            PERFORM PUSH
        END-IF
        IF LS-U = WS-RANGE-END(LS-E) OR WS-RANGE-END(LS-E) = 0
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-U) TO LS-U
    END-PERFORM.

ENQUEUE-FLOW.
    IF FU-FLOWED(LS-U) = "N"
        MOVE "Y" TO FU-FLOWED(LS-U) FU-REACHED(LS-U)
        PERFORM PUSH
    END-IF.

PUSH.
    IF LS-TAIL < 40000
        ADD 1 TO LS-TAIL
        MOVE LS-U TO WS-QUEUE(LS-TAIL)
    END-IF.
END PROGRAM PLB-FLOW-BUILD.
