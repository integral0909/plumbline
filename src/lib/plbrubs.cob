*> ---------------------------------------------------------------
*> plbrubs: PLB-C012 use-before-set.
*>
*> A data item that is read at a point no execution path can reach
*> with a value in it: every path from the program's start to the
*> read passes no statement that sets the item (or storage it shares).
*>
*> The analysis is a "may be set" data-flow analysis over the
*> procedure graph (plbflow), so it only reports reads that are
*> certainly before any setting on every path:
*>
*>   - The items considered are working- and local-storage items
*>     that are read and set somewhere, and have no VALUE (on
*>     themselves or on storage they share) and are not named in the
*>     environment division, where the runtime may set them. Items
*>     passed to a CALL BY REFERENCE may be set by the callee there.
*>   - Each unit (paragraph or section) is a list of events in source
*>     order: reads and sets from its references (plbrole), PERFORMs,
*>     and GO TOs. Within one statement, reads come before sets, so
*>     COMPUTE X = X + 1 reads X first. A PERFORM VARYING sets its
*>     variable before it tests UNTIL, so there it is a set.
*>   - A looping PERFORM (UNTIL, VARYING, TIMES, FOREVER) repeats
*>     its body, so everything the loop may set counts as possibly
*>     set when the loop starts. This misses reads before sets on the
*>     first iteration, but never reports one a later iteration makes
*>     good.
*>   - A PERFORM summary is everything its range may set, including
*>     through the ranges it performs in turn (computed to a fixed
*>     point).
*>   - What may be set on entry to a unit comes from the units that
*>     fall into it, GO TO it, or PERFORM it, also to a fixed point.
*>     A program starts with what its declarative procedures may set,
*>     since they can run at almost any point; declaratives themselves
*>     are assumed to start with everything set, and so does whatever follows a
*>     PERFORM whose target is unknown.
*>
*> Programs with more than 4096 units, or files with more than 512
*> such items, are not analyzed.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-USE-BEFORE-SET.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbspan.cpy".
COPY "plbacc.cpy".
78  UN-MAX                      VALUE 4096.
78  CD-MAX                      VALUE 512.
78  EV-MAX                      VALUE 300000.
*> Candidate items: the symbol of each, and each symbol's candidate.
01  WS-CANDIDATES.
    05  WS-CAND-COUNT       PIC 9(4) COMP-5.
    05  WS-CAND-SYMBOL      PIC 9(9) COMP-5 OCCURS CD-MAX TIMES.
01  WS-CAND-OF              PIC 9(4) COMP-5 OCCURS 100000 TIMES.
*> Per unit, one character per candidate ("1" set, "0" not):
*> what the unit itself may set, what performing it may set, and
*> what may be set on entry to it.
01  WS-SETS.
    05  WS-DEFS             PIC X(CD-MAX) OCCURS UN-MAX TIMES.
    05  WS-SUM              PIC X(CD-MAX) OCCURS UN-MAX TIMES.
    05  WS-IN               PIC X(CD-MAX) OCCURS UN-MAX TIMES.
*> Events, sorted by unit and position.
01  WS-EVENTS.
    05  WS-EVENT-COUNT      PIC 9(9) COMP-5.
    05  WS-EVENT            OCCURS 0 TO EV-MAX TIMES
                            DEPENDING ON WS-EVENT-COUNT.
        10  EV-UNIT         PIC 9(9) COMP-5.
        10  EV-KEY          PIC 9(9) COMP-5.
        *> Order among events at the same token: loops start before
        *> the references in them, and PERFORMs and GO TOs end them.
        10  EV-RANK         PIC 9.
        *>   L looping PERFORM statement (EV-INDEX: STMT node)
        *>   R reference (EV-INDEX: RF entry)
        *>   P PERFORM, G GO TO (EV-INDEX: FE entry)
        10  EV-TYPE         PIC X.
        10  EV-INDEX        PIC 9(9) COMP-5.
01  WS-UNIT-EVENTS.
    05  WS-EV-FIRST         PIC 9(9) COMP-5 OCCURS UN-MAX TIMES.
    05  WS-EV-LAST          PIC 9(9) COMP-5 OCCURS UN-MAX TIMES.
*> The unit each token belongs to.
01  WS-TOKEN-UNIT           PIC 9(9) COMP-5 OCCURS 500000 TIMES.
01  WS-REPORTED             PIC X OCCURS CD-MAX TIMES.
*> Candidates a statement sets, applied once its reads are done.
01  WS-PENDING              PIC X(CD-MAX).
01  WS-STATE                PIC X(CD-MAX).
01  WS-ALL-SET              PIC X(CD-MAX).
*> What the declarative procedures may set.
01  WS-DECLARED             PIC X(CD-MAX).
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-X                    PIC 9(9) COMP-5.
01  LS-Y                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-BODY                 PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LOOPS                PIC X.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-READ                 PIC X.
01  LS-SET                  PIC X.
01  LS-CHANGED              PIC X.
01  LS-ROUNDS               PIC 9(4) COMP-5.
01  LS-REPORTING            PIC X.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbflow.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-FLOW PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C012" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    IF SY-COUNT = 0 OR FU-COUNT = 0 OR FU-COUNT > UN-MAX
        GOBACK
    END-IF
    CALL "PLB-ACCESS-BUILD" USING PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-SPANS PLB-ACCESSES PLB-ACCESS-INDEX
    PERFORM CHOOSE-CANDIDATES
    IF WS-CAND-COUNT = 0 OR WS-CAND-COUNT > CD-MAX
        GOBACK
    END-IF
    PERFORM BUILD-EVENTS
    PERFORM UNIT-DEFINITIONS
    PERFORM PERFORM-SUMMARIES
    PERFORM ENTRY-SETS
    MOVE "Y" TO LS-REPORTING
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-REACHED(LS-U) = "Y"
            PERFORM WALK-UNIT
        END-IF
    END-PERFORM
    GOBACK.

*> Candidates ------------------------------------------------------

CHOOSE-CANDIDATES.
    MOVE 0 TO WS-CAND-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE 0 TO WS-CAND-OF(LS-S)
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D"
           AND (RF-ROLE(LS-R) = "U" OR RF-ROLE(LS-R) = "B")
            PERFORM SYMBOL-OF-REFERENCE
            IF WS-CAND-OF(LS-S) = 0 AND AX-CHECKED(LS-S) = "Y"
                PERFORM CONSIDER-CANDIDATE
            END-IF
        END-IF
    END-PERFORM
    MOVE ALL "1" TO WS-ALL-SET.

*> LS-S = the symbol reference LS-R is to; a condition name stands
*> for its conditional variable.
SYMBOL-OF-REFERENCE.
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF SY-LEVEL(LS-S) = 88 AND SY-PARENT(LS-S) > 0
        MOVE SY-PARENT(LS-S) TO LS-S
    END-IF.

CONSIDER-CANDIDATE.
    *> Something outside the program's statements may set it.
    CALL "PLB-ACCESS-FIND" USING PLB-SPANS PLB-ACCESSES
        PLB-ACCESS-INDEX LS-S "VX" LS-FOUND
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    *> Never set at all is PLB-C011's finding.
    CALL "PLB-ACCESS-FIND" USING PLB-SPANS PLB-ACCESSES
        PLB-ACCESS-INDEX LS-S "DB" LS-FOUND
    IF LS-FOUND = "N"
        EXIT PARAGRAPH
    END-IF
    IF WS-CAND-COUNT >= CD-MAX
        ADD 1 TO WS-CAND-COUNT
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-CAND-COUNT
    MOVE LS-S TO WS-CAND-SYMBOL(WS-CAND-COUNT)
    MOVE WS-CAND-COUNT TO WS-CAND-OF(LS-S)
    MOVE "N" TO WS-REPORTED(WS-CAND-COUNT).

*> Events ----------------------------------------------------------

BUILD-EVENTS.
    *> Units in source order: later (inner) units overwrite the
    *> tokens of the division or section they are in.
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > TK-COUNT
        MOVE 0 TO WS-TOKEN-UNIT(LS-T)
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        PERFORM VARYING LS-T FROM ND-TOK-FIRST(FU-NODE(LS-U)) BY 1
                UNTIL LS-T > ND-TOK-LAST(FU-NODE(LS-U))
            MOVE LS-U TO WS-TOKEN-UNIT(LS-T)
        END-PERFORM
    END-PERFORM
    MOVE 0 TO WS-EVENT-COUNT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-STMT(LS-R) > 0
           AND WS-EVENT-COUNT < EV-MAX
            ADD 1 TO WS-EVENT-COUNT
            MOVE WS-TOKEN-UNIT(RF-TOKEN(LS-R)) TO EV-UNIT(WS-EVENT-COUNT)
            MOVE RF-TOKEN(LS-R) TO EV-KEY(WS-EVENT-COUNT)
            MOVE 1 TO EV-RANK(WS-EVENT-COUNT)
            MOVE "R" TO EV-TYPE(WS-EVENT-COUNT)
            MOVE LS-R TO EV-INDEX(WS-EVENT-COUNT)
        END-IF
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF WS-EVENT-COUNT < EV-MAX
            ADD 1 TO WS-EVENT-COUNT
            MOVE FE-FROM(LS-E) TO EV-UNIT(WS-EVENT-COUNT)
            MOVE LS-E TO EV-INDEX(WS-EVENT-COUNT)
            *> After the statement's own operands.
            MOVE ND-TOK-LAST(FE-STMT(LS-E)) TO EV-KEY(WS-EVENT-COUNT)
            MOVE 2 TO EV-RANK(WS-EVENT-COUNT)
            *> An ALTER makes the GO TO of the altered unit, at its end,
            *> go to the edge's target.
            IF FE-KIND(LS-E) = "A"
                MOVE FE-ALTERED(LS-E) TO EV-UNIT(WS-EVENT-COUNT)
                IF FE-ALTERED(LS-E) > 0
                    MOVE ND-TOK-LAST(FU-NODE(FE-ALTERED(LS-E)))
                        TO EV-KEY(WS-EVENT-COUNT)
                END-IF
            END-IF
            IF FE-KIND(LS-E) = "P"
                MOVE "P" TO EV-TYPE(WS-EVENT-COUNT)
            ELSE
                MOVE "G" TO EV-TYPE(WS-EVENT-COUNT)
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-KIND(LS-N) = "STMT" AND ND-DETAIL(LS-N) = "PERFORM"
           AND WS-EVENT-COUNT < EV-MAX
            PERFORM CHECK-LOOPS
            IF LS-LOOPS = "Y"
                ADD 1 TO WS-EVENT-COUNT
                MOVE WS-TOKEN-UNIT(ND-TOK-FIRST(LS-N))
                    TO EV-UNIT(WS-EVENT-COUNT)
                MOVE ND-TOK-FIRST(LS-N) TO EV-KEY(WS-EVENT-COUNT)
                MOVE 0 TO EV-RANK(WS-EVENT-COUNT)
                MOVE "L" TO EV-TYPE(WS-EVENT-COUNT)
                MOVE LS-N TO EV-INDEX(WS-EVENT-COUNT)
            END-IF
        END-IF
    END-PERFORM
    IF WS-EVENT-COUNT > 1
        SORT WS-EVENT ON ASCENDING KEY EV-UNIT EV-KEY EV-RANK
    END-IF
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE 1 TO WS-EV-FIRST(LS-U)
        MOVE 0 TO WS-EV-LAST(LS-U)
    END-PERFORM
    PERFORM VARYING LS-X FROM WS-EVENT-COUNT BY -1 UNTIL LS-X = 0
        MOVE EV-UNIT(LS-X) TO LS-U
        IF LS-U > 0
            MOVE LS-X TO WS-EV-FIRST(LS-U)
            IF WS-EV-LAST(LS-U) = 0
                MOVE LS-X TO WS-EV-LAST(LS-U)
            END-IF
        END-IF
    END-PERFORM.

*> LS-LOOPS = "Y" when PERFORM statement LS-N repeats: UNTIL,
*> VARYING, TIMES, or FOREVER before the statements of its body.
CHECK-LOOPS.
    MOVE "N" TO LS-LOOPS
    MOVE ND-TOK-LAST(LS-N) TO LS-BODY
    PERFORM VARYING LS-Y FROM LS-N BY 1 UNTIL LS-Y >= AS-COUNT
        IF ND-TOK-FIRST(LS-Y + 1) > ND-TOK-LAST(LS-N)
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-Y + 1) = "STMT"
            MOVE ND-TOK-FIRST(LS-Y + 1) TO LS-BODY
            EXIT PERFORM
        END-IF
    END-PERFORM
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
            UNTIL LS-T > LS-BODY
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "UNTIL" OR LS-TEXT = "VARYING"
               OR LS-TEXT = "TIMES" OR LS-TEXT = "FOREVER"
                MOVE "Y" TO LS-LOOPS
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> What each unit itself may set: every set, wherever it is.
UNIT-DEFINITIONS.
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE ALL "0" TO WS-DEFS(LS-U)
        PERFORM VARYING LS-X FROM WS-EV-FIRST(LS-U) BY 1
                UNTIL LS-X > WS-EV-LAST(LS-U)
            IF EV-TYPE(LS-X) = "R"
                MOVE EV-INDEX(LS-X) TO LS-R
                IF RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
                   OR RF-ROLE(LS-R) = "X"
                    PERFORM SYMBOL-OF-REFERENCE
                    MOVE WS-DEFS(LS-U) TO WS-PENDING
                    PERFORM MARK-SET
                    MOVE WS-PENDING TO WS-DEFS(LS-U)
                END-IF
            END-IF
            IF EV-TYPE(LS-X) = "P" AND FE-TO(EV-INDEX(LS-X)) = 0
                MOVE WS-ALL-SET TO WS-DEFS(LS-U)
            END-IF
        END-PERFORM
        MOVE WS-DEFS(LS-U) TO WS-SUM(LS-U)
    END-PERFORM.

*> Set in WS-PENDING every candidate sharing storage with LS-S.
MARK-SET.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-CAND-COUNT
        MOVE WS-CAND-SYMBOL(LS-C) TO LS-V
        IF SP-ROOT(LS-V) = SP-ROOT(LS-S)
           AND SP-LOW(LS-V) < SP-HIGH(LS-S)
           AND SP-LOW(LS-S) < SP-HIGH(LS-V)
            MOVE "1" TO WS-PENDING(LS-C:1)
        END-IF
    END-PERFORM.

*> SUM(u) = DEFS(u) plus the SUM of every unit u performs, until
*> nothing changes.
PERFORM-SUMMARIES.
    MOVE 0 TO LS-ROUNDS
    MOVE "Y" TO LS-CHANGED
    PERFORM UNTIL LS-CHANGED = "N" OR LS-ROUNDS > 200
        MOVE "N" TO LS-CHANGED
        ADD 1 TO LS-ROUNDS
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
            IF FE-KIND(LS-E) = "P" AND FE-TO(LS-E) > 0
                MOVE FE-FROM(LS-E) TO LS-U
                PERFORM RANGE-END
                MOVE FE-TO(LS-E) TO LS-V
                PERFORM UNTIL LS-V = 0
                    PERFORM VARYING LS-C FROM 1 BY 1
                            UNTIL LS-C > WS-CAND-COUNT
                        IF WS-SUM(LS-V)(LS-C:1) = "1"
                           AND WS-SUM(LS-U)(LS-C:1) = "0"
                            MOVE "1" TO WS-SUM(LS-U)(LS-C:1)
                            MOVE "Y" TO LS-CHANGED
                        END-IF
                    END-PERFORM
                    IF LS-V = LS-LAST
                        EXIT PERFORM
                    END-IF
                    MOVE FU-NEXT(LS-V) TO LS-V
                END-PERFORM
            END-IF
        END-PERFORM
    END-PERFORM.

*> LS-LAST = the last unit of edge LS-E's range: its THRU unit, or a
*> section's last paragraph.
RANGE-END.
    MOVE FE-THRU(LS-E) TO LS-LAST
    IF LS-LAST = 0
        MOVE FE-TO(LS-E) TO LS-LAST
    END-IF
    IF FU-KIND(LS-LAST) = "S"
        MOVE LS-LAST TO LS-V
        PERFORM UNTIL FU-NEXT(LS-V) = 0
            IF FU-SECTION(FU-NEXT(LS-V)) NOT = LS-LAST
                EXIT PERFORM
            END-IF
            MOVE FU-NEXT(LS-V) TO LS-V
        END-PERFORM
        MOVE LS-V TO LS-LAST
    END-IF.

*> What may be set on entry to each unit, until nothing changes.
ENTRY-SETS.
    *> Declarative procedures run whenever their event happens (an I/O
    *> error, a procedure being debugged), so what they may set may be
    *> set anywhere.
    MOVE ALL "0" TO WS-DECLARED
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-DECLARATIVE(LS-U) = "Y"
            PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-CAND-COUNT
                IF WS-SUM(LS-U)(LS-C:1) = "1"
                    MOVE "1" TO WS-DECLARED(LS-C:1)
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE WS-DECLARED TO WS-IN(LS-U)
        IF FU-DECLARATIVE(LS-U) = "Y"
            MOVE WS-ALL-SET TO WS-IN(LS-U)
        END-IF
    END-PERFORM
    MOVE "N" TO LS-REPORTING
    MOVE 0 TO LS-ROUNDS
    MOVE "Y" TO LS-CHANGED
    PERFORM UNTIL LS-CHANGED = "N" OR LS-ROUNDS > 200
        MOVE "N" TO LS-CHANGED
        ADD 1 TO LS-ROUNDS
        PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
            IF FU-REACHED(LS-U) = "Y"
                PERFORM WALK-UNIT
            END-IF
        END-PERFORM
    END-PERFORM.

*> Walk unit LS-U's events from its entry set. Propagates what may
*> be set to the units it performs, jumps to, and falls into; when
*> LS-REPORTING is "Y", reports reads of candidates not yet set.
WALK-UNIT.
    MOVE WS-IN(LS-U) TO WS-STATE
    MOVE ALL "0" TO WS-PENDING
    MOVE 0 TO LS-STMT
    PERFORM VARYING LS-X FROM WS-EV-FIRST(LS-U) BY 1
            UNTIL LS-X > WS-EV-LAST(LS-U)
        EVALUATE EV-TYPE(LS-X)
            WHEN "R"
                MOVE EV-INDEX(LS-X) TO LS-R
                IF RF-STMT(LS-R) NOT = LS-STMT
                    PERFORM APPLY-PENDING
                    MOVE RF-STMT(LS-R) TO LS-STMT
                END-IF
                PERFORM REFERENCE-EVENT
            WHEN "L"
                PERFORM APPLY-PENDING
                PERFORM LOOP-EVENT
            WHEN "P"
                PERFORM APPLY-PENDING
                MOVE EV-INDEX(LS-X) TO LS-E
                IF FE-TO(LS-E) > 0
                    PERFORM PERFORM-EVENT
                ELSE
                    MOVE WS-ALL-SET TO WS-STATE
                END-IF
            WHEN "G"
                PERFORM APPLY-PENDING
                MOVE EV-INDEX(LS-X) TO LS-E
                IF FE-TO(LS-E) > 0
                    MOVE FE-TO(LS-E) TO LS-V
                    PERFORM FLOW-INTO
                END-IF
        END-EVALUATE
    END-PERFORM
    PERFORM APPLY-PENDING
    IF FU-FALLS(LS-U) = "Y" AND FU-NEXT(LS-U) > 0
        MOVE FU-NEXT(LS-U) TO LS-V
        PERFORM FLOW-INTO
    END-IF.

REFERENCE-EVENT.
    PERFORM SYMBOL-OF-REFERENCE
    MOVE "N" TO LS-READ LS-SET
    EVALUATE RF-ROLE(LS-R)
        WHEN "U"
            MOVE "Y" TO LS-READ
        WHEN "B"
            MOVE "Y" TO LS-SET
            *> PERFORM VARYING sets its variable before reading it.
            IF ND-DETAIL(RF-STMT(LS-R)) NOT = "PERFORM"
                MOVE "Y" TO LS-READ
            END-IF
        WHEN "D"
        WHEN "X"
            MOVE "Y" TO LS-SET
    END-EVALUATE
    IF LS-READ = "Y" AND LS-REPORTING = "Y"
        MOVE WS-CAND-OF(LS-S) TO LS-C
        IF LS-C > 0
            IF WS-STATE(LS-C:1) = "0" AND WS-REPORTED(LS-C) = "N"
                MOVE "Y" TO WS-REPORTED(LS-C)
                PERFORM REPORT-USE
            END-IF
        END-IF
    END-IF
    IF LS-SET = "Y"
        PERFORM MARK-SET
    END-IF.

*> The sets of a statement take effect after its reads.
APPLY-PENDING.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-CAND-COUNT
        IF WS-PENDING(LS-C:1) = "1"
            MOVE "1" TO WS-STATE(LS-C:1)
        END-IF
    END-PERFORM
    MOVE ALL "0" TO WS-PENDING.

*> A looping PERFORM statement (node EV-INDEX(LS-X)): everything set
*> in it, or by the ranges it performs, may be set when it starts.
LOOP-EVENT.
    MOVE EV-INDEX(LS-X) TO LS-N
    PERFORM VARYING LS-Y FROM LS-X BY 1 UNTIL LS-Y > WS-EV-LAST(LS-U)
        IF EV-KEY(LS-Y) > ND-TOK-LAST(LS-N)
            EXIT PERFORM
        END-IF
        EVALUATE EV-TYPE(LS-Y)
            WHEN "R"
                MOVE EV-INDEX(LS-Y) TO LS-R
                IF RF-ROLE(LS-R) NOT = "U"
                    PERFORM SYMBOL-OF-REFERENCE
                    PERFORM MARK-SET
                END-IF
            WHEN "P"
                MOVE EV-INDEX(LS-Y) TO LS-E
                IF FE-TO(LS-E) > 0
                    PERFORM ADD-RANGE-SUM
                ELSE
                    MOVE WS-ALL-SET TO WS-PENDING
                END-IF
        END-EVALUATE
    END-PERFORM
    PERFORM APPLY-PENDING.

*> A PERFORM: the range starts with the current state, and afterwards
*> whatever the range may set may be set.
PERFORM-EVENT.
    MOVE FE-TO(LS-E) TO LS-V
    PERFORM FLOW-INTO
    PERFORM ADD-RANGE-SUM
    PERFORM APPLY-PENDING.

*> Mark in WS-PENDING everything performing edge LS-E's range may set.
ADD-RANGE-SUM.
    PERFORM RANGE-END
    MOVE FE-TO(LS-E) TO LS-V
    PERFORM UNTIL LS-V = 0
        PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-CAND-COUNT
            IF WS-SUM(LS-V)(LS-C:1) = "1"
                MOVE "1" TO WS-PENDING(LS-C:1)
            END-IF
        END-PERFORM
        IF LS-V = LS-LAST
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-V) TO LS-V
    END-PERFORM.

*> IN(LS-V) gains everything in the current state.
FLOW-INTO.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-CAND-COUNT
        IF WS-STATE(LS-C:1) = "1" AND WS-IN(LS-V)(LS-C:1) = "0"
            MOVE "1" TO WS-IN(LS-V)(LS-C:1)
            MOVE "Y" TO LS-CHANGED
        END-IF
    END-PERFORM.

REPORT-USE.
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " is used before it is given a value" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-USE-BEFORE-SET.
