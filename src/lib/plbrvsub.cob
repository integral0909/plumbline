*> ---------------------------------------------------------------
*> plbrvsub: PLB-C062 varying-subscript-out-of-range.
*>
*> A PERFORM VARYING loop whose counter, used as a subscript in the
*> loop, takes a value outside the table:
*>
*>     01  LINES-TABLE.
*>         05  LINE-ENTRY  PIC X(10) OCCURS 20.
*>     PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 25
*>         DISPLAY LINE-ENTRY(IX)
*>     END-PERFORM
*>
*> IX reaches 25, and LINE-ENTRY has 20 entries; FROM 0 gives a
*> subscript of 0 on the first pass. The rule works out the values of
*> the counter from a VARYING (or AFTER) phrase of the form
*>
*>     counter FROM integer [BY positive integer] UNTIL counter op integer
*>
*> where op is >, >=, or = (= with BY 1 only), and nothing else is in
*> the condition. It then checks each subscript in the loop that is the
*> counter alone, or the counter plus or minus an integer, against the
*> OCCURS of that dimension. The counter is a data item or an index.
*>
*> The loop is the inline body, or, for PERFORM procedure VARYING, the
*> paragraphs from the procedure through its THRU; procedures they
*> perform in turn are not followed. The rule leaves a loop alone when
*> it may not run as written: WITH TEST AFTER; a statement in the loop
*> changes the counter (PLB-C044 reports that); or an IF, EVALUATE,
*> PERFORM, or SEARCH in the loop tests the counter, which may guard
*> the subscript.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C062.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  DIM-MAX                 VALUE 16.
78  RANGE-MAX               VALUE 64.
*> Reference starting at each token (0: none), and whether the token
*> is in the subscripts of a reference, for the tokens of the file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
01  WS-IN-SUBSCRIPT         PIC X OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-LOOP                 PIC 9(9) COMP-5.
01  LS-BODY                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-PHRASE-FROM          PIC 9(9) COMP-5.
01  LS-PHRASE-TO            PIC 9(9) COMP-5.
*> The counter: its symbol (0 for an index), and its name.
01  LS-COUNTER              PIC 9(9) COMP-5.
01  LS-COUNTER-NAME         PIC X(31).
*> The values the counter takes in the loop.
01  LS-FROM-VALUE           PIC S9(18) COMP-5.
01  LS-BY-VALUE             PIC S9(18) COMP-5.
01  LS-LIMIT-VALUE          PIC S9(18) COMP-5.
01  LS-OP                   PIC X.
01  LS-SMALLEST             PIC S9(18) COMP-5.
01  LS-LARGEST              PIC S9(18) COMP-5.
01  LS-VALUE                PIC S9(18) COMP-5.
01  LS-VALUE-OK             PIC X.
01  LS-USABLE               PIC X.
*> The token ranges of the loop.
01  LS-RANGE-COUNT          PIC 9(4) COMP-5.
01  LS-RANGE-FROM           PIC 9(9) COMP-5 OCCURS RANGE-MAX TIMES.
01  LS-RANGE-TO             PIC 9(9) COMP-5 OCCURS RANGE-MAX TIMES.
01  LS-RG                   PIC 9(4) COMP-5.
*> Dimensions of a table reference, outermost first.
01  LS-DIM-COUNT            PIC 9(4) COMP-5.
01  LS-DIM-OCCURS           PIC 9(9) COMP-5 OCCURS DIM-MAX TIMES.
01  LS-DIM-ITEM             PIC 9(9) COMP-5 OCCURS DIM-MAX TIMES.
*> Its subscripts: the first token of each, and the integer added to
*> the counter when the subscript is the counter (else "N").
01  LS-SUB-COUNT            PIC 9(4) COMP-5.
01  LS-SUB-TOKEN            PIC 9(9) COMP-5 OCCURS DIM-MAX TIMES.
01  LS-SUB-ON-COUNTER       PIC X OCCURS DIM-MAX TIMES.
01  LS-SUB-OFFSET           PIC S9(18) COMP-5 OCCURS DIM-MAX TIMES.
01  LS-SUB-TEXT             PIC X(40) OCCURS DIM-MAX TIMES.
01  LS-TOO-MANY             PIC X.
01  LS-SIGN                 PIC X.
01  LS-BOUND                PIC 9(9) COMP-5.
01  LS-OPEN                 PIC 9(9) COMP-5.
01  LS-CLOSE                PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-LINE-TEXT            PIC X(20).
01  LS-LINE-LEN             PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C062" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM MARK-TOKENS
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            PERFORM CHECK-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM UNMARK-TOKENS
    GOBACK.

MARK-TOKENS.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
        IF RF-SUBSCRIPTED(LS-R) = "Y"
            PERFORM VARYING LS-T FROM RF-TOKEN(LS-R) BY 1
                    UNTIL LS-T >= RF-LAST(LS-R)
                MOVE "Y" TO WS-IN-SUBSCRIPT(LS-T + 1)
            END-PERFORM
        END-IF
    END-PERFORM.

UNMARK-TOKENS.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
        IF RF-SUBSCRIPTED(LS-R) = "Y"
            PERFORM VARYING LS-T FROM RF-TOKEN(LS-R) BY 1
                    UNTIL LS-T >= RF-LAST(LS-R)
                MOVE SPACE TO WS-IN-SUBSCRIPT(LS-T + 1)
            END-PERFORM
        END-IF
    END-PERFORM.

*> The loop phrase and the body of PERFORM statement LS-NODE.
CHECK-PERFORM.
    MOVE 0 TO LS-LOOP LS-BODY
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        EVALUATE TRUE
            WHEN ND-KIND(LS-CHILD) = "COND" AND ND-DETAIL(LS-CHILD) = "LOOP"
                MOVE LS-CHILD TO LS-LOOP
            WHEN ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "BODY"
                MOVE LS-CHILD TO LS-BODY
        END-EVALUATE
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    *> PERFORM procedure VARYING ... has no loop node: its VARYING
    *> phrase is in the statement's own tokens.
    IF LS-LOOP = 0
        IF LS-BODY > 0
            EXIT PARAGRAPH
        END-IF
        MOVE ND-TOK-FIRST(LS-NODE) TO LS-PHRASE-FROM
        MOVE ND-TOK-LAST(LS-NODE) TO LS-PHRASE-TO
    ELSE
        MOVE ND-TOK-FIRST(LS-LOOP) TO LS-PHRASE-FROM
        MOVE ND-TOK-LAST(LS-LOOP) TO LS-PHRASE-TO
    END-IF
    *> WITH TEST AFTER runs the body before the first test.
    PERFORM VARYING LS-T FROM LS-PHRASE-FROM BY 1
            UNTIL LS-T >= LS-PHRASE-TO
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "TEST"
                COMPUTE LS-Q = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "AFTER"
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    PERFORM COLLECT-RANGES
    IF LS-RANGE-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM LS-PHRASE-FROM BY 1
            UNTIL LS-T >= LS-PHRASE-TO
        IF TK-IS-WORD(LS-T) AND WS-TOKEN-REF(LS-T) = 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "VARYING"
               OR FUNCTION UPPER-CASE(LS-WORD) = "AFTER"
                PERFORM READ-PHRASE
                IF LS-USABLE = "Y"
                    PERFORM CHECK-LOOP
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> The token ranges the loop runs: the inline body, or the units of
*> the procedure range.
COLLECT-RANGES.
    MOVE 0 TO LS-RANGE-COUNT
    IF LS-BODY > 0
        MOVE 1 TO LS-RANGE-COUNT
        MOVE ND-TOK-FIRST(LS-BODY) TO LS-RANGE-FROM(1)
        MOVE ND-TOK-LAST(LS-BODY) TO LS-RANGE-TO(1)
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-STMT(LS-E) = LS-NODE AND FE-KIND(LS-E) = "P"
           AND FE-TO(LS-E) > 0
            MOVE FE-THRU(LS-E) TO LS-LAST
            IF LS-LAST < FE-TO(LS-E)
                MOVE FE-TO(LS-E) TO LS-LAST
            END-IF
            PERFORM VARYING LS-U FROM FE-TO(LS-E) BY 1
                    UNTIL LS-U > LS-LAST
                IF LS-RANGE-COUNT >= RANGE-MAX
                    *> Too long to follow: leave the loop alone.
                    MOVE 0 TO LS-RANGE-COUNT
                    EXIT PARAGRAPH
                END-IF
                ADD 1 TO LS-RANGE-COUNT
                MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO
                    LS-RANGE-FROM(LS-RANGE-COUNT)
                MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO
                    LS-RANGE-TO(LS-RANGE-COUNT)
            END-PERFORM
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-T is on VARYING or AFTER: the counter, FROM, BY, and UNTIL.
*> LS-USABLE = "Y" when the phrase has the form the rule works out.
READ-PHRASE.
    MOVE "N" TO LS-USABLE
    MOVE LS-PHRASE-TO TO LS-BOUND
    COMPUTE LS-Q = LS-T + 1
    IF WS-TOKEN-REF(LS-Q) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE WS-TOKEN-REF(LS-Q) TO LS-R
    IF RF-LAST(LS-R) NOT = LS-Q
        EXIT PARAGRAPH
    END-IF
    EVALUATE RF-KIND(LS-R)
        WHEN "D"
            MOVE RF-SYMBOL(LS-R) TO LS-COUNTER
        WHEN "O"
            MOVE 0 TO LS-COUNTER
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-COUNTER-NAME LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-COUNTER-NAME) TO LS-COUNTER-NAME
    ADD 1 TO LS-Q
    IF NOT TK-IS-WORD(LS-Q)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "FROM"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-Q
    PERFORM READ-INTEGER
    IF LS-VALUE-OK NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-VALUE TO LS-FROM-VALUE
    ADD 1 TO LS-Q
    MOVE 1 TO LS-BY-VALUE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
    IF TK-IS-WORD(LS-Q) AND FUNCTION UPPER-CASE(LS-WORD) = "BY"
        ADD 1 TO LS-Q
        PERFORM READ-INTEGER
        IF LS-VALUE-OK NOT = "Y" OR LS-VALUE < 1
            EXIT PARAGRAPH
        END-IF
        MOVE LS-VALUE TO LS-BY-VALUE
        ADD 1 TO LS-Q
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
    END-IF
    IF NOT TK-IS-WORD(LS-Q) OR FUNCTION UPPER-CASE(LS-WORD) NOT = "UNTIL"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-Q
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
    IF NOT TK-IS-WORD(LS-Q)
       OR FUNCTION UPPER-CASE(LS-WORD) NOT = LS-COUNTER-NAME
        EXIT PARAGRAPH
    END-IF
    IF WS-TOKEN-REF(LS-Q) > 0
        IF RF-LAST(WS-TOKEN-REF(LS-Q)) NOT = LS-Q
            EXIT PARAGRAPH
        END-IF
    END-IF
    ADD 1 TO LS-Q
    PERFORM READ-OPERATOR
    IF LS-OP = SPACE
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-INTEGER
    IF LS-VALUE-OK NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-VALUE TO LS-LIMIT-VALUE
    *> Nothing else in the condition: the phrase ends, or AFTER starts
    *> the next one.
    ADD 1 TO LS-Q
    IF LS-Q <= LS-PHRASE-TO
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
        IF NOT TK-IS-WORD(LS-Q)
           OR FUNCTION UPPER-CASE(LS-WORD) NOT = "AFTER"
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM WORK-OUT-VALUES.

*> LS-VALUE from an unsigned integer literal at LS-Q, not past
*> LS-BOUND.
READ-INTEGER.
    MOVE "N" TO LS-VALUE-OK
    IF LS-Q > LS-BOUND OR NOT TK-IS-NUMBER(LS-Q)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
    IF LS-LEN > 9
        EXIT PARAGRAPH
    END-IF
    IF LS-WORD(1:LS-LEN) IS NOT NUMERIC
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-VALUE = FUNCTION NUMVAL(LS-WORD(1:LS-LEN))
    MOVE "Y" TO LS-VALUE-OK.

*> LS-OP from the operator at LS-Q: > G, >= H, = E (words too). LS-Q
*> is left on the token after it.
READ-OPERATOR.
    MOVE SPACE TO LS-OP
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    IF TK-IS-OPERATOR(LS-Q)
        EVALUATE LS-WORD
            WHEN ">"
                MOVE "G" TO LS-OP
            WHEN ">="
                MOVE "H" TO LS-OP
            WHEN "="
                MOVE "E" TO LS-OP
        END-EVALUATE
        ADD 1 TO LS-Q
        EXIT PARAGRAPH
    END-IF
    IF LS-WORD = "IS"
        ADD 1 TO LS-Q
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    END-IF
    EVALUATE LS-WORD
        WHEN "GREATER"
            MOVE "G" TO LS-OP
        WHEN "EQUAL"
            MOVE "E" TO LS-OP
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    ADD 1 TO LS-Q
    PERFORM SKIP-THAN-TO
    IF LS-OP = "G"
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) = "OR"
            ADD 1 TO LS-Q
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) NOT = "EQUAL"
                MOVE SPACE TO LS-OP
                EXIT PARAGRAPH
            END-IF
            MOVE "H" TO LS-OP
            ADD 1 TO LS-Q
            PERFORM SKIP-THAN-TO
        END-IF
    END-IF.

SKIP-THAN-TO.
    IF TK-IS-WORD(LS-Q)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) = "THAN"
           OR FUNCTION UPPER-CASE(LS-WORD) = "TO"
            ADD 1 TO LS-Q
        END-IF
    END-IF.

*> LS-SMALLEST and LS-LARGEST the body sees: FROM, then BY at a time,
*> while the condition is false. LS-USABLE = "N" when the body never
*> runs or the loop may not end.
WORK-OUT-VALUES.
    MOVE LS-FROM-VALUE TO LS-SMALLEST
    EVALUATE LS-OP
        WHEN "G"
            MOVE LS-LIMIT-VALUE TO LS-VALUE
        WHEN "H"
            COMPUTE LS-VALUE = LS-LIMIT-VALUE - 1
        WHEN "E"
            IF LS-BY-VALUE NOT = 1
                EXIT PARAGRAPH
            END-IF
            COMPUTE LS-VALUE = LS-LIMIT-VALUE - 1
    END-EVALUATE
    *> LS-VALUE: the largest value for which the condition is false.
    IF LS-FROM-VALUE > LS-VALUE
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-LARGEST = LS-FROM-VALUE
        + FUNCTION INTEGER((LS-VALUE - LS-FROM-VALUE) / LS-BY-VALUE)
          * LS-BY-VALUE
    MOVE "Y" TO LS-USABLE.

*> The loop's statements: give up when one changes the counter or
*> tests it; otherwise check the subscripts.
CHECK-LOOP.
    PERFORM VARYING LS-RG FROM 1 BY 1 UNTIL LS-RG > LS-RANGE-COUNT
        PERFORM VARYING LS-S FROM LS-RANGE-FROM(LS-RG) BY 1
                UNTIL LS-S > LS-RANGE-TO(LS-RG)
            IF WS-TOKEN-REF(LS-S) > 0
                MOVE WS-TOKEN-REF(LS-S) TO LS-R
                PERFORM IS-COUNTER
                IF LS-VALUE-OK = "Y"
                    PERFORM CHECK-COUNTER-USE
                    IF LS-USABLE NOT = "Y"
                        EXIT PARAGRAPH
                    END-IF
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM
    PERFORM VARYING LS-RG FROM 1 BY 1 UNTIL LS-RG > LS-RANGE-COUNT
        PERFORM VARYING LS-S FROM LS-RANGE-FROM(LS-RG) BY 1
                UNTIL LS-S > LS-RANGE-TO(LS-RG)
            IF WS-TOKEN-REF(LS-S) > 0
                MOVE WS-TOKEN-REF(LS-S) TO LS-R
                IF RF-SUBSCRIPTED(LS-R) = "Y" AND RF-KIND(LS-R) = "D"
                    PERFORM CHECK-TABLE-REFERENCE
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM.

*> LS-VALUE-OK = "Y" when reference LS-R names the counter.
IS-COUNTER.
    MOVE "N" TO LS-VALUE-OK
    IF LS-COUNTER > 0
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) = LS-COUNTER
            MOVE "Y" TO LS-VALUE-OK
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-R) = "O"
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS RF-TOKEN(LS-R) LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) = LS-COUNTER-NAME
            MOVE "Y" TO LS-VALUE-OK
        END-IF
    END-IF.

*> The counter at reference LS-R, in the loop: LS-USABLE = "N" when
*> its statement changes it, or tests it outside a subscript.
CHECK-COUNTER-USE.
    IF RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
       OR RF-ROLE(LS-R) = "X"
        MOVE "N" TO LS-USABLE
        EXIT PARAGRAPH
    END-IF
    IF RF-STMT(LS-R) = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE ND-DETAIL(RF-STMT(LS-R))
        WHEN "SET"
            *> An index is changed by SET; a data item's role says so.
            IF LS-COUNTER = 0
                MOVE "N" TO LS-USABLE
            END-IF
        WHEN "IF" WHEN "EVALUATE" WHEN "PERFORM" WHEN "SEARCH"
            IF WS-IN-SUBSCRIPT(LS-S) NOT = "Y"
                MOVE "N" TO LS-USABLE
            END-IF
    END-EVALUATE.

*> Reference LS-R to a table: each subscript that is the counter,
*> against the OCCURS of its dimension.
CHECK-TABLE-REFERENCE.
    PERFORM COLLECT-DIMENSIONS
    PERFORM COLLECT-SUBSCRIPTS
    IF LS-TOO-MANY = "Y" OR LS-SUB-COUNT NOT = LS-DIM-COUNT
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-SUB-COUNT
        IF LS-SUB-ON-COUNTER(LS-I) = "Y" AND LS-DIM-OCCURS(LS-I) > 0
            EVALUATE TRUE
                WHEN LS-LARGEST + LS-SUB-OFFSET(LS-I) > LS-DIM-OCCURS(LS-I)
                    COMPUTE LS-NUM = LS-LARGEST + LS-SUB-OFFSET(LS-I)
                    PERFORM REPORT-PAST-END
                WHEN LS-SMALLEST + LS-SUB-OFFSET(LS-I) < 1
                    COMPUTE LS-NUM = LS-SMALLEST + LS-SUB-OFFSET(LS-I)
                    PERFORM REPORT-BEFORE-START
            END-EVALUATE
        END-IF
    END-PERFORM.

*> The OCCURS of the item and the groups above it, outermost first,
*> with the item that has each.
COLLECT-DIMENSIONS.
    MOVE 0 TO LS-DIM-COUNT
    MOVE "N" TO LS-TOO-MANY
    MOVE RF-SYMBOL(LS-R) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF SY-OCCURS(LS-UP) > 0
            IF LS-DIM-COUNT >= DIM-MAX
                MOVE "Y" TO LS-TOO-MANY
                EXIT PERFORM
            END-IF
            PERFORM VARYING LS-Q FROM LS-DIM-COUNT BY -1 UNTIL LS-Q = 0
                MOVE LS-DIM-OCCURS(LS-Q) TO LS-DIM-OCCURS(LS-Q + 1)
                MOVE LS-DIM-ITEM(LS-Q) TO LS-DIM-ITEM(LS-Q + 1)
            END-PERFORM
            *> No largest count to check against: 0.
            IF SY-UNBOUNDED(LS-UP) = "Y"
                MOVE 0 TO LS-DIM-OCCURS(1)
            ELSE
                MOVE SY-OCCURS(LS-UP) TO LS-DIM-OCCURS(1)
            END-IF
            MOVE LS-UP TO LS-DIM-ITEM(1)
            ADD 1 TO LS-DIM-COUNT
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> The subscripts in the first parentheses after the name: each one
*> on the counter (the counter alone, or with + or - and an integer)
*> or not.
COLLECT-SUBSCRIPTS.
    MOVE 0 TO LS-SUB-COUNT
    MOVE 0 TO LS-OPEN LS-CLOSE
    PERFORM VARYING LS-Q FROM RF-TOKEN(LS-R) BY 1
            UNTIL LS-Q > RF-LAST(LS-R)
        IF TK-IS-LPAREN(LS-Q)
            MOVE LS-Q TO LS-OPEN
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-OPEN = 0
        MOVE "Y" TO LS-TOO-MANY
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-LEVEL
    PERFORM VARYING LS-Q FROM LS-OPEN BY 1 UNTIL LS-Q > RF-LAST(LS-R)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-Q)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-Q)
                SUBTRACT 1 FROM LS-LEVEL
                IF LS-LEVEL = 0
                    MOVE LS-Q TO LS-CLOSE
                    EXIT PERFORM
                END-IF
            WHEN TK-IS-COLON(LS-Q) AND LS-LEVEL = 1
                *> A reference modifier, not subscripts.
                MOVE "Y" TO LS-TOO-MANY
                EXIT PARAGRAPH
        END-EVALUATE
    END-PERFORM
    IF LS-CLOSE = 0
        MOVE "Y" TO LS-TOO-MANY
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-Q = LS-OPEN + 1
    PERFORM UNTIL LS-Q >= LS-CLOSE
        IF LS-SUB-COUNT >= DIM-MAX
            MOVE "Y" TO LS-TOO-MANY
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-SUB-COUNT
        MOVE LS-Q TO LS-SUB-TOKEN(LS-SUB-COUNT)
        MOVE "N" TO LS-SUB-ON-COUNTER(LS-SUB-COUNT)
        MOVE 0 TO LS-SUB-OFFSET(LS-SUB-COUNT)
        MOVE "N" TO LS-VALUE-OK
        IF WS-TOKEN-REF(LS-Q) > 0
            MOVE WS-TOKEN-REF(LS-Q) TO LS-E
            *> IS-COUNTER works on LS-R: lend it the subscript's.
            MOVE LS-R TO LS-U
            MOVE LS-E TO LS-R
            PERFORM IS-COUNTER
            MOVE LS-U TO LS-R
            IF LS-VALUE-OK = "Y" AND RF-LAST(LS-E) NOT = LS-Q
                MOVE "N" TO LS-VALUE-OK
            END-IF
        END-IF
        *> A parenthesized subscript of its own, as in A (B (1)).
        IF TK-IS-WORD(LS-Q) AND LS-Q + 1 < LS-CLOSE
            IF TK-IS-LPAREN(LS-Q + 1)
                MOVE "Y" TO LS-TOO-MANY
                EXIT PERFORM
            END-IF
        END-IF
        MOVE LS-VALUE-OK TO LS-SUB-ON-COUNTER(LS-SUB-COUNT)
        MOVE LS-COUNTER-NAME TO LS-SUB-TEXT(LS-SUB-COUNT)
        ADD 1 TO LS-Q
        *> A relative subscript: NAME + 1, NAME - 1.
        IF LS-Q < LS-CLOSE AND TK-IS-OPERATOR(LS-Q)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-WORD LS-LEN
            IF LS-WORD = "+" OR LS-WORD = "-"
                PERFORM READ-RELATIVE
                ADD 2 TO LS-Q
            END-IF
        END-IF
    END-PERFORM.

*> LS-Q is on + or - after a subscript on the counter: the integer
*> after it is the offset; anything else is not on the counter.
READ-RELATIVE.
    MOVE LS-WORD(1:1) TO LS-SIGN
    COMPUTE LS-E = LS-Q + 1
    MOVE LS-Q TO LS-U
    MOVE LS-E TO LS-Q
    MOVE LS-CLOSE TO LS-BOUND
    PERFORM READ-INTEGER
    MOVE LS-U TO LS-Q
    IF LS-VALUE-OK NOT = "Y"
        MOVE "N" TO LS-SUB-ON-COUNTER(LS-SUB-COUNT)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-E LS-WORD LS-LEN
    MOVE SPACES TO LS-SUB-TEXT(LS-SUB-COUNT)
    STRING LS-COUNTER-NAME DELIMITED BY SPACE
           " " LS-SIGN " " LS-WORD(1:LS-LEN) DELIMITED BY SIZE
        INTO LS-SUB-TEXT(LS-SUB-COUNT)
    IF LS-SIGN = "-"
        COMPUTE LS-SUB-OFFSET(LS-SUB-COUNT) = 0 - LS-VALUE
    ELSE
        MOVE LS-VALUE TO LS-SUB-OFFSET(LS-SUB-COUNT)
    END-IF.

REPORT-PAST-END.
    PERFORM LOOP-LINE
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SY-OCCURS(LS-DIM-ITEM(LS-I)) TO LS-NUM
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "Subscript " FUNCTION TRIM(LS-SUB-TEXT(LS-I)) " reaches "
           LS-NUM-TEXT(1:LS-NUM-LEN)
           " in the PERFORM VARYING on line " LS-LINE-TEXT(1:LS-LINE-LEN)
           ", but " DELIMITED BY SIZE
           SY-NAME(LS-DIM-ITEM(LS-I)) DELIMITED BY SPACE
           " occurs " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) " times" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-SUB-TOKEN(LS-I) LS-MESSAGE.

REPORT-BEFORE-START.
    PERFORM LOOP-LINE
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    IF LS-NUM < 0
        STRING "Subscript " FUNCTION TRIM(LS-SUB-TEXT(LS-I)) " is -"
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING "Subscript " FUNCTION TRIM(LS-SUB-TEXT(LS-I)) " is "
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING LS-NUM-TEXT(1:LS-NUM-LEN)
           " on the first pass of the PERFORM VARYING on line "
           LS-LINE-TEXT(1:LS-LINE-LEN)
           ", but the entries of " DELIMITED BY SIZE
           SY-NAME(LS-DIM-ITEM(LS-I)) DELIMITED BY SPACE
           " start at 1" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-SUB-TOKEN(LS-I) LS-MESSAGE.

LOOP-LINE.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-VALUE
    CALL "PLB-STR-FROM-INT" USING LS-VALUE LS-LINE-TEXT LS-LINE-LEN.
END PROGRAM PLB-RULE-C062.
