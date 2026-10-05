*> ---------------------------------------------------------------
*> plbrdiv: PLB-C067 divisor-not-checked.
*>
*> A division by a data item that may be zero, with nothing to catch
*> it:
*>
*>     DIVIDE WS-TOTAL BY WS-COUNT GIVING WS-AVERAGE
*>
*> When the file was empty, WS-COUNT is 0: the statement raises a size
*> error, which without ON SIZE ERROR leaves WS-AVERAGE as it was (or,
*> on z/OS with some options, ends the program with a decimal-divide
*> exception, S0CB).
*>
*> The divisor is the item after INTO or BY of a DIVIDE, or after / in
*> a COMPUTE. The division is left alone when:
*>
*>   - the statement has ON SIZE ERROR;
*>   - the divisor is never given a value by a statement (a constant
*>     with a VALUE);
*>   - the paragraph, or one that falls into it, tests the divisor
*>     before the division, in an IF, EVALUATE, PERFORM UNTIL, or
*>     SEARCH (IF WS-COUNT > 0 ...), or gives it a value from a nonzero
*>     literal (MOVE 12 TO WS-MONTHS);
*>   - the paragraph is performed from a statement that such a test
*>     encloses, as IF WS-COUNT > 0 PERFORM WRITE-AVERAGE.
*>
*> It is off by default: a divisor is often known not to be zero for
*> reasons the program does not show (a record count of a file that is
*> never empty).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C067.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), and whether a statement
*> gives each data item a value ("Y"), worked out once.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
01  WS-CHANGED              PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
*> The token of the scans inside a paragraph or a condition.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-FIRST-UNIT           PIC 9(9) COMP-5.
01  LS-DIVISOR              PIC 9(9) COMP-5.
01  LS-DIVISOR-TOKEN        PIC 9(9) COMP-5.
01  LS-SAFE                 PIC X.
01  LS-CHANGED              PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C067" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
           AND (RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
                OR RF-ROLE(LS-R) = "X")
            MOVE "Y" TO WS-CHANGED(RF-SYMBOL(LS-R))
        END-IF
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
           AND (ND-DETAIL(LS-NODE) = "DIVIDE"
                OR ND-DETAIL(LS-NODE) = "COMPUTE")
            PERFORM CHECK-DIVISION
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
            MOVE SPACE TO WS-CHANGED(RF-SYMBOL(LS-R))
        END-IF
    END-PERFORM
    GOBACK.

*> Statement LS-NODE: each divisor in its own tokens, unless it has ON
*> SIZE ERROR.
CHECK-DIVISION.
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
           AND ND-DETAIL(LS-CHILD) = "SIZE-ERROR"
            EXIT PARAGRAPH
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        EVALUATE TRUE
            WHEN TK-IS-OPERATOR(LS-T) AND LS-TEXT = "/"
               AND ND-DETAIL(LS-NODE) = "COMPUTE"
                COMPUTE LS-DIVISOR-TOKEN = LS-T + 1
                PERFORM CHECK-DIVISOR
            WHEN ND-DETAIL(LS-NODE) = "DIVIDE" AND TK-IS-WORD(LS-T)
                 AND LS-TEXT = "BY"
                COMPUTE LS-DIVISOR-TOKEN = LS-T + 1
                PERFORM CHECK-DIVISOR
            WHEN ND-DETAIL(LS-NODE) = "DIVIDE" AND TK-IS-WORD(LS-T)
                 AND LS-TEXT = "INTO"
                *> DIVIDE x INTO y: the divisor is x, before INTO.
                COMPUTE LS-DIVISOR-TOKEN = ND-TOK-FIRST(LS-NODE) + 1
                PERFORM CHECK-DIVISOR
        END-EVALUATE
    END-PERFORM.

*> The operand at LS-DIVISOR-TOKEN: a data item, then the reasons it
*> may be known not to be zero.
CHECK-DIVISOR.
    MOVE WS-TOKEN-REF(LS-DIVISOR-TOKEN) TO LS-R
    IF LS-R = 0
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-DIVISOR
    PERFORM CHECK-CHANGED
    IF LS-CHANGED = "N"
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-UNIT
    IF LS-UNIT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-PARAGRAPH
    IF LS-SAFE = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-CALLERS
    IF LS-SAFE = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-DIVISOR) DELIMITED BY SPACE
           " may be zero here: nothing before this division tests it"
           ", and the statement has no ON SIZE ERROR"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-DIVISOR-TOKEN LS-MESSAGE.

*> LS-CHANGED = "Y" when a statement gives the divisor, or a group
*> around it, a value.
CHECK-CHANGED.
    MOVE "N" TO LS-CHANGED
    MOVE LS-DIVISOR TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF WS-CHANGED(LS-UP) = "Y"
            MOVE "Y" TO LS-CHANGED
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> LS-UNIT: the paragraph or section the division is in.
FIND-UNIT.
    MOVE 0 TO LS-UNIT
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "PARA" OR ND-KIND(LS-UP) = "SECT"
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-NODE(LS-U) = LS-UP
            MOVE LS-U TO LS-UNIT
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-SAFE = "Y" when, before the division, in its unit or the units
*> that fall into it (up to 20), the divisor is tested by a condition
*> or given a nonzero literal.
CHECK-PARAGRAPH.
    MOVE "N" TO LS-SAFE
    MOVE LS-UNIT TO LS-FIRST-UNIT
    PERFORM 20 TIMES
        IF LS-FIRST-UNIT <= 1
            EXIT PERFORM
        END-IF
        IF FU-FALLS(LS-FIRST-UNIT - 1) NOT = "Y"
           OR FU-NEXT(LS-FIRST-UNIT - 1) NOT = LS-FIRST-UNIT
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-FIRST-UNIT
    END-PERFORM
    PERFORM VARYING LS-S FROM ND-TOK-FIRST(FU-NODE(LS-FIRST-UNIT)) BY 1
            UNTIL LS-S >= ND-TOK-FIRST(LS-NODE)
        IF WS-TOKEN-REF(LS-S) > 0
            MOVE WS-TOKEN-REF(LS-S) TO LS-Q
            IF RF-KIND(LS-Q) = "D" AND RF-SYMBOL(LS-Q) = LS-DIVISOR
               AND RF-STMT(LS-Q) > 0
                PERFORM CHECK-USE
                IF LS-SAFE = "Y"
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> Reference LS-Q to the divisor: in a condition, or the receiver of a
*> MOVE of a nonzero literal.
CHECK-USE.
    EVALUATE ND-DETAIL(RF-STMT(LS-Q))
        WHEN "IF" WHEN "EVALUATE" WHEN "PERFORM" WHEN "SEARCH"
            MOVE "Y" TO LS-SAFE
        WHEN "MOVE"
            IF RF-ROLE(LS-Q) = "D"
                MOVE ND-TOK-FIRST(RF-STMT(LS-Q)) TO LS-E
                ADD 1 TO LS-E
                IF TK-IS-NUMBER(LS-E)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-E LS-TEXT
                        LS-LEN
                    IF FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) = 0
                        IF FUNCTION NUMVAL(LS-TEXT(1:LS-LEN)) NOT = 0
                            MOVE "Y" TO LS-SAFE
                        END-IF
                    END-IF
                END-IF
            END-IF
    END-EVALUATE.

*> LS-SAFE = "Y" when the unit is performed from a statement inside an
*> IF, EVALUATE, or PERFORM UNTIL whose condition names the divisor.
CHECK-CALLERS.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-STMT(LS-E) > 0
           AND LS-UNIT >= FE-TO(LS-E)
           AND (LS-UNIT <= FE-THRU(LS-E) OR LS-UNIT = FE-TO(LS-E))
            MOVE ND-PARENT(FE-STMT(LS-E)) TO LS-UP
            PERFORM UNTIL LS-UP = 0
                IF ND-KIND(LS-UP) = "PARA" OR ND-KIND(LS-UP) = "SECT"
                    EXIT PERFORM
                END-IF
                IF ND-KIND(LS-UP) = "STMT"
                    PERFORM CONDITION-NAMES-DIVISOR
                    IF LS-SAFE = "Y"
                        EXIT PARAGRAPH
                    END-IF
                END-IF
                MOVE ND-PARENT(LS-UP) TO LS-UP
            END-PERFORM
        END-IF
    END-PERFORM.

*> LS-SAFE = "Y" when statement LS-UP's own condition (its COND
*> children) names the divisor.
CONDITION-NAMES-DIVISOR.
    MOVE ND-FIRST(LS-UP) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "COND"
            PERFORM VARYING LS-S FROM ND-TOK-FIRST(LS-CHILD) BY 1
                    UNTIL LS-S > ND-TOK-LAST(LS-CHILD)
                IF WS-TOKEN-REF(LS-S) > 0
                    MOVE WS-TOKEN-REF(LS-S) TO LS-Q
                    IF RF-KIND(LS-Q) = "D"
                       AND RF-SYMBOL(LS-Q) = LS-DIVISOR
                        MOVE "Y" TO LS-SAFE
                        EXIT PARAGRAPH
                    END-IF
                END-IF
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.
END PROGRAM PLB-RULE-C067.
