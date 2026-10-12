*> ---------------------------------------------------------------
*> plbrnever: PLB-C089 loop-never-runs, for PERFORM ... UNTIL.
*>
*> A PERFORM ... UNTIL whose condition the statements just before it
*> make true:
*>
*>     MOVE "N" TO WS-EOF
*>     PERFORM READ-NEXT UNTIL WS-EOF = "N"       never performed
*>
*> PERFORM tests its UNTIL condition before each pass (unless WITH TEST
*> AFTER), so the loop runs no times; usually the value moved, or the
*> one tested, is the wrong one. Read are the MOVE statements of a
*> literal and the SET ... TO TRUE or FALSE statements before the
*> PERFORM, across statements whose references show all they change
*> (DISPLAY, arithmetic, MOVE of an item, STRING, INSPECT, ...; what
*> they store into is no longer known), back to the first other
*> statement (across the ends of sentences, within the paragraph), and
*> conditions of relations
*> item [IS] [NOT] op literal and condition names, joined all by AND or
*> all by OR, without parentheses. A condition is true when each of
*> the relations ANDed is, or one of those ORed. Items are named without
*> subscripts; a literal is compared by value, and only when the item
*> holds it as written: an alphanumeric literal no longer than the item
*> (compared with = only), or a number its numeric picture holds.
*>
*> PERFORM ... n TIMES runs no times when n is the literal 0, or an
*> item the statements before it set to 0 the same way.
*>
*> PERFORM VARYING with a FROM that makes the UNTIL true is read in
*> plbrloop.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C089.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbspan.cpy" REPLACING ==PLB-SPANS== BY ==WS-SPANS==.
78  KNOWN-MAX               VALUE 32.
78  PIECE-MAX               VALUE 16.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-PREV                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-UNTIL                PIC 9(9) COMP-5.
01  LS-TIMES                PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-GIVE-UP              PIC X.
01  LS-OVERLAP              PIC X.
*> What the statements before the PERFORM leave, nearest first: the
*> item or condition name, how (L a literal, T TRUE, F FALSE), the
*> literal's token, and the statement.
01  LS-KNOWN-COUNT          PIC 9(4) COMP-5.
01  LS-KNOWN-SYMBOL         PIC 9(9) COMP-5 OCCURS KNOWN-MAX TIMES.
01  LS-KNOWN-HOW            PIC X OCCURS KNOWN-MAX TIMES.
01  LS-KNOWN-TOKEN          PIC 9(9) COMP-5 OCCURS KNOWN-MAX TIMES.
01  LS-KNOWN-STMT           PIC 9(9) COMP-5 OCCURS KNOWN-MAX TIMES.
*> Every item those statements store into, for storage shared with an
*> item an earlier statement set.
01  LS-STORED-COUNT         PIC 9(4) COMP-5.
01  LS-STORED               PIC 9(9) COMP-5 OCCURS KNOWN-MAX TIMES.
01  LS-STORED-NOW           PIC 9(4) COMP-5.
01  LS-SOURCE               PIC 9(9) COMP-5.
01  LS-HOW                  PIC X.
*> The condition: the join (A AND, O OR), and for each relation its
*> truth when the loop starts (T true, F false, U not known) and the
*> entry of LS-KNOWN that decides it.
01  LS-JOIN                 PIC X.
01  LS-PIECE-COUNT          PIC 9(4) COMP-5.
01  LS-PIECE-TRUTH          PIC X OCCURS PIECE-MAX TIMES.
01  LS-PIECE-KNOWN          PIC 9(9) COMP-5 OCCURS PIECE-MAX TIMES.
01  LS-SUBJECT              PIC 9(9) COMP-5.
01  LS-NOT                  PIC X.
*> The operator: E =, G >, H >=, L <, M <=.
01  LS-OP                   PIC X.
01  LS-VALUE-TOKEN          PIC 9(9) COMP-5.
01  LS-TRUTH                PIC X.
01  LS-DECIDER              PIC 9(9) COMP-5.
01  LS-RESULT               PIC X.
*> Literal values: alphanumeric text without trailing spaces, or a
*> number; LS-A for the one moved, LS-B for the one tested.
01  LS-KIND                 PIC X.
01  LS-TEXT                 PIC X(160).
01  LS-NUMBER               PIC S9(18)V9(9) COMP-3.
01  LS-A-KIND               PIC X.
01  LS-A-TEXT               PIC X(160).
01  LS-A-NUMBER             PIC S9(18)V9(9) COMP-3.
01  LS-B-KIND               PIC X.
01  LS-B-TEXT               PIC X(160).
01  LS-B-NUMBER             PIC S9(18)V9(9) COMP-3.
01  LS-LIMIT                PIC S9(18)V9(9) COMP-3.
01  LS-SCALED               PIC S9(18)V9(9) COMP-3.
01  LS-FITS                 PIC X.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
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
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C089" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    CALL "PLB-SPAN-BUILD" USING PLB-SYMBOLS WS-SPANS
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            MOVE LS-NODE TO LS-STMT
            PERFORM CHECK-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

CHECK-PERFORM.
    PERFORM FIND-CONDITION
    IF LS-TIMES > 0
        PERFORM CHECK-TIMES
        EXIT PARAGRAPH
    END-IF
    IF LS-UNTIL = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-BEFORE
    IF LS-KNOWN-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-CONDITION
    IF LS-GIVE-UP = "Y" OR LS-PIECE-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    *> AND: true when every relation is; OR: when one is.
    MOVE 0 TO LS-DECIDER
    IF LS-JOIN = "O"
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-PIECE-COUNT
            IF LS-PIECE-TRUTH(LS-I) = "T"
                MOVE LS-PIECE-KNOWN(LS-I) TO LS-DECIDER
                EXIT PERFORM
            END-IF
        END-PERFORM
    ELSE
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-PIECE-COUNT
            IF LS-PIECE-TRUTH(LS-I) NOT = "T"
                EXIT PARAGRAPH
            END-IF
            *> The statement furthest back that the condition needs.
            IF LS-PIECE-KNOWN(LS-I) > LS-DECIDER
                MOVE LS-PIECE-KNOWN(LS-I) TO LS-DECIDER
            END-IF
        END-PERFORM
    END-IF
    IF LS-DECIDER > 0
        PERFORM REPORT-LOOP
    END-IF.

*> LS-UNTIL: the UNTIL token of a PERFORM without VARYING, TIMES, or
*> WITH TEST AFTER (0 otherwise); LS-FIRST and LS-LAST: the condition.
*> LS-TIMES: the TIMES token of PERFORM ... n TIMES, or 0.
FIND-CONDITION.
    MOVE 0 TO LS-UNTIL LS-TIMES
    MOVE ND-TOK-LAST(LS-STMT) TO LS-LAST
    MOVE ND-FIRST(LS-STMT) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            COMPUTE LS-LAST = ND-TOK-FIRST(LS-CHILD) - 1
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > LS-LAST
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            EVALUATE LS-WORD
                WHEN "TIMES"
                    MOVE LS-T TO LS-TIMES
                    MOVE 0 TO LS-UNTIL
                    EXIT PARAGRAPH
                WHEN "VARYING"
                WHEN "AFTER"
                    MOVE 0 TO LS-UNTIL
                    EXIT PARAGRAPH
                WHEN "UNTIL"
                    IF LS-UNTIL = 0
                        MOVE LS-T TO LS-UNTIL
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM
    COMPUTE LS-FIRST = LS-UNTIL + 1.

*> PERFORM ... n TIMES: n the literal 0, or an item a MOVE before the
*> PERFORM sets to 0.
CHECK-TIMES.
    COMPUTE LS-T = LS-TIMES - 1
    MOVE LS-T TO LS-VALUE-TOKEN
    IF TK-IS-NUMBER(LS-T)
        PERFORM READ-LITERAL
        IF LS-KIND = "N" AND LS-NUMBER = 0
            MOVE SPACES TO LS-MESSAGE
            STRING "PERFORM 0 TIMES runs no times" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE LS-VALUE-TOKEN LS-MESSAGE
        END-IF
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-GIVE-UP
    PERFORM SUBJECT-AT
    IF LS-GIVE-UP = "Y" OR LS-T NOT = LS-TIMES
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-SUBJECT) NOT = "9"
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-BEFORE
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-KNOWN-COUNT
        IF LS-KNOWN-SYMBOL(LS-K) = LS-SUBJECT
            IF LS-KNOWN-HOW(LS-K) = "L"
                MOVE LS-KNOWN-TOKEN(LS-K) TO LS-T
                PERFORM READ-LITERAL
                IF LS-KIND = "Z"
                    MOVE "N" TO LS-KIND
                    MOVE 0 TO LS-NUMBER
                END-IF
                MOVE LS-NUMBER TO LS-A-NUMBER
                IF LS-KIND = "N" AND LS-NUMBER = 0
                    PERFORM NUMBER-FITS
                    IF LS-FITS = "Y"
                        MOVE LS-K TO LS-DECIDER
                        PERFORM REPORT-TIMES
                    END-IF
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-TIMES.
    MOVE LS-KNOWN-STMT(LS-DECIDER) TO LS-K
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-K))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-SUBJECT) DELIMITED BY SPACE
           " is 0 after the MOVE on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", so the loop runs no times" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-VALUE-TOKEN LS-MESSAGE.

*> The MOVE and SET statements right before the PERFORM, nearest
*> first, into LS-KNOWN.
READ-BEFORE.
    MOVE 0 TO LS-KNOWN-COUNT LS-STORED-COUNT
    MOVE LS-STMT TO LS-NODE
    PERFORM UNTIL LS-NODE = 0
        PERFORM PREVIOUS-STATEMENT
        IF LS-PREV = 0
            EXIT PERFORM
        END-IF
        MOVE LS-PREV TO LS-NODE
        MOVE "N" TO LS-GIVE-UP
        EVALUATE ND-DETAIL(LS-NODE)
            WHEN "MOVE"
                PERFORM READ-MOVE
            WHEN "SET"
                PERFORM READ-SET
            *> Statements whose references show all they change.
            WHEN "ADD" WHEN "SUBTRACT" WHEN "MULTIPLY" WHEN "DIVIDE"
            WHEN "COMPUTE" WHEN "INITIALIZE" WHEN "STRING"
            WHEN "UNSTRING" WHEN "INSPECT" WHEN "DISPLAY"
            WHEN "CONTINUE"
                PERFORM READ-STORES
            WHEN OTHER
                MOVE "Y" TO LS-GIVE-UP
        END-EVALUATE
        IF LS-GIVE-UP = "Y"
            EXIT PERFORM
        END-IF
    END-PERFORM
    *> LS-NODE served as the walk; the tree walk goes on from the
    *> PERFORM.
    MOVE LS-STMT TO LS-NODE.

*> LS-PREV: the statement before LS-NODE in its list, or the last one
*> of the sentence before, in the same paragraph; 0 when there is none.
PREVIOUS-STATEMENT.
    MOVE 0 TO LS-PREV
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-UP) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0 OR LS-CHILD = LS-NODE
        MOVE LS-CHILD TO LS-PREV
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-PREV > 0
        IF ND-KIND(LS-PREV) NOT = "STMT"
            MOVE 0 TO LS-PREV
        END-IF
        EXIT PARAGRAPH
    END-IF
    *> First in its sentence: the sentence before it.
    IF ND-KIND(LS-UP) NOT = "SENT"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(LS-UP) TO LS-K
    IF LS-K = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-K) TO LS-CHILD
    MOVE 0 TO LS-I
    PERFORM UNTIL LS-CHILD = 0 OR LS-CHILD = LS-UP
        MOVE LS-CHILD TO LS-I
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-I > 0
        IF ND-KIND(LS-I) = "SENT" AND ND-LAST(LS-I) > 0
            IF ND-KIND(ND-LAST(LS-I)) = "STMT"
                MOVE ND-LAST(LS-I) TO LS-PREV
            END-IF
        END-IF
    END-IF.

*> MOVE literal TO item...: each item, unsubscripted, takes the literal.
READ-MOVE.
    COMPUTE LS-SOURCE = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM READ-LITERAL-AT-SOURCE
    IF LS-KIND = SPACE
        PERFORM READ-STORES
        EXIT PARAGRAPH
    END-IF
    MOVE "L" TO LS-HOW
    PERFORM READ-RECEIVERS.

*> SET condition-name... TO TRUE or FALSE.
READ-SET.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    EVALUATE FUNCTION UPPER-CASE(LS-WORD)
        WHEN "TRUE"
            MOVE "T" TO LS-HOW
        WHEN "FALSE"
            MOVE "F" TO LS-HOW
        WHEN OTHER
            PERFORM READ-STORES
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE 0 TO LS-SOURCE
    PERFORM READ-RECEIVERS.

*> Statement LS-NODE, which sets no value the rule knows: what it
*> stores into is stored, so earlier values there are not known. One
*> with statements under it (ON SIZE ERROR), or that stores into
*> something not a data item, ends the walk.
READ-STORES.
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            MOVE "Y" TO LS-GIVE-UP
            EXIT PARAGRAPH
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-STMT(LS-R) = LS-NODE
           AND (RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
                OR RF-ROLE(LS-R) = "X")
            IF RF-KIND(LS-R) NOT = "D" OR RF-SYMBOL(LS-R) = 0
               OR LS-STORED-COUNT >= KNOWN-MAX
                MOVE "Y" TO LS-GIVE-UP
                EXIT PARAGRAPH
            END-IF
            MOVE RF-SYMBOL(LS-R) TO LS-K
            IF SY-CATEGORY(LS-K) = "C" AND SY-PARENT(LS-K) > 0
                MOVE SY-PARENT(LS-K) TO LS-K
            END-IF
            ADD 1 TO LS-STORED-COUNT
            MOVE LS-K TO LS-STORED(LS-STORED-COUNT)
        END-IF
    END-PERFORM.

*> The references of statement LS-NODE that it stores into: each must
*> be a data item without subscripts or reference modification (for
*> SET, a condition name); each is known unless a nearer statement
*> stored into storage it shares.
READ-RECEIVERS.
    MOVE LS-STORED-COUNT TO LS-STORED-NOW
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-STMT(LS-R) = LS-NODE AND RF-ROLE(LS-R) NOT = "U"
            IF RF-KIND(LS-R) NOT = "D" OR RF-SYMBOL(LS-R) = 0
               OR RF-SUBSCRIPTED(LS-R) = "Y" OR RF-REFMOD(LS-R) = "Y"
                MOVE "Y" TO LS-GIVE-UP
                EXIT PARAGRAPH
            END-IF
            MOVE RF-SYMBOL(LS-R) TO LS-S
            IF LS-HOW = "L"
                IF SY-CATEGORY(LS-S) = "C"
                    MOVE "Y" TO LS-GIVE-UP
                    EXIT PARAGRAPH
                END-IF
            ELSE
                IF SY-CATEGORY(LS-S) NOT = "C" OR SY-PARENT(LS-S) = 0
                    MOVE "Y" TO LS-GIVE-UP
                    EXIT PARAGRAPH
                END-IF
            END-IF
            PERFORM ADD-KNOWN
            IF LS-GIVE-UP = "Y"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM.

*> Symbol LS-S as set by statement LS-NODE: known when no nearer
*> statement stored into it or storage it shares. Its storage (the
*> item of a condition name) is then stored too.
ADD-KNOWN.
    MOVE LS-S TO LS-K
    IF SY-CATEGORY(LS-K) = "C"
        MOVE SY-PARENT(LS-K) TO LS-K
    END-IF
    MOVE "N" TO LS-OVERLAP
    PERFORM VARYING LS-I FROM 1 BY 1
            UNTIL LS-I > LS-STORED-NOW OR LS-OVERLAP = "Y"
        IF LS-STORED(LS-I) = LS-K
            MOVE "Y" TO LS-OVERLAP
        ELSE
            CALL "PLB-SPAN-OVERLAP" USING WS-SPANS LS-STORED(LS-I) LS-K
                LS-OVERLAP
        END-IF
    END-PERFORM
    IF LS-OVERLAP = "N" AND LS-KNOWN-COUNT < KNOWN-MAX
        ADD 1 TO LS-KNOWN-COUNT
        MOVE LS-S TO LS-KNOWN-SYMBOL(LS-KNOWN-COUNT)
        MOVE LS-HOW TO LS-KNOWN-HOW(LS-KNOWN-COUNT)
        MOVE LS-SOURCE TO LS-KNOWN-TOKEN(LS-KNOWN-COUNT)
        MOVE LS-NODE TO LS-KNOWN-STMT(LS-KNOWN-COUNT)
    END-IF
    IF LS-STORED-COUNT < KNOWN-MAX
        ADD 1 TO LS-STORED-COUNT
        MOVE LS-K TO LS-STORED(LS-STORED-COUNT)
    ELSE
        MOVE "Y" TO LS-GIVE-UP
    END-IF.

*> The literal of the MOVE at LS-SOURCE, which TO must follow: LS-KIND
*> A (LS-TEXT) or N (LS-NUMBER), or space for anything else.
READ-LITERAL-AT-SOURCE.
    MOVE LS-SOURCE TO LS-T
    PERFORM READ-LITERAL
    IF LS-KIND = SPACE
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = LS-SOURCE + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "TO"
        MOVE SPACE TO LS-KIND
    END-IF.

*> The literal at LS-T: an alphanumeric literal without a prefix, a
*> number, SPACE or ZERO (and their plurals). LS-KIND as above, with
*> Z for ZERO, which is a number or characters 0 by its item.
READ-LITERAL.
    MOVE SPACE TO LS-KIND
    MOVE SPACES TO LS-TEXT
    MOVE 0 TO LS-NUMBER
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
            IF TK-PREFIX(LS-T) = SPACES AND TK-TEXT-LEN(LS-T) <= 160
                MOVE "A" TO LS-KIND
                IF TK-TEXT-LEN(LS-T) > 0
                    MOVE TK-TEXT(TK-TEXT-OFF(LS-T):TK-TEXT-LEN(LS-T))
                        TO LS-TEXT
                END-IF
            END-IF
        WHEN TK-IS-NUMBER(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-LEN <= 27
                MOVE 0 TO LS-I
                INSPECT LS-WORD(1:LS-LEN) TALLYING LS-I
                    FOR ALL "," "E" "e"
                IF LS-I = 0
                    IF FUNCTION TEST-NUMVAL(LS-WORD(1:LS-LEN)) = 0
                        COMPUTE LS-NUMBER =
                            FUNCTION NUMVAL(LS-WORD(1:LS-LEN))
                        MOVE "N" TO LS-KIND
                    END-IF
                END-IF
            END-IF
        WHEN TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                WHEN "SPACE" WHEN "SPACES"
                    MOVE "A" TO LS-KIND
                WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
                    MOVE "Z" TO LS-KIND
            END-EVALUATE
    END-EVALUATE.

*> The condition from LS-FIRST to LS-LAST, relation by relation.
READ-CONDITION.
    MOVE "N" TO LS-GIVE-UP
    MOVE SPACE TO LS-JOIN
    MOVE 0 TO LS-PIECE-COUNT
    MOVE LS-FIRST TO LS-T
    PERFORM UNTIL LS-T > LS-LAST OR LS-GIVE-UP = "Y"
        IF LS-PIECE-COUNT >= PIECE-MAX
            MOVE "Y" TO LS-GIVE-UP
            EXIT PARAGRAPH
        END-IF
        PERFORM READ-PIECE
        IF LS-GIVE-UP = "Y"
            EXIT PARAGRAPH
        END-IF
        ADD 1 TO LS-PIECE-COUNT
        MOVE LS-TRUTH TO LS-PIECE-TRUTH(LS-PIECE-COUNT)
        MOVE LS-DECIDER TO LS-PIECE-KNOWN(LS-PIECE-COUNT)
        IF LS-T <= LS-LAST
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            EVALUATE TRUE
                WHEN NOT TK-IS-WORD(LS-T)
                    MOVE "Y" TO LS-GIVE-UP
                WHEN LS-WORD = "AND" AND LS-JOIN NOT = "O"
                    MOVE "A" TO LS-JOIN
                WHEN LS-WORD = "OR" AND LS-JOIN NOT = "A"
                    MOVE "O" TO LS-JOIN
                WHEN OTHER
                    MOVE "Y" TO LS-GIVE-UP
            END-EVALUATE
            ADD 1 TO LS-T
            IF LS-T > LS-LAST
                MOVE "Y" TO LS-GIVE-UP
            END-IF
        END-IF
    END-PERFORM
    IF LS-JOIN = SPACE
        MOVE "A" TO LS-JOIN
    END-IF.

*> One relation at LS-T: [NOT] condition-name, or item [IS] [NOT] op
*> literal. LS-TRUTH and LS-DECIDER; LS-T is left after it.
READ-PIECE.
    MOVE "U" TO LS-TRUTH
    MOVE 0 TO LS-DECIDER
    MOVE "N" TO LS-NOT
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF TK-IS-WORD(LS-T) AND FUNCTION UPPER-CASE(LS-WORD) = "NOT"
        MOVE "Y" TO LS-NOT
        ADD 1 TO LS-T
    END-IF
    PERFORM SUBJECT-AT
    IF LS-GIVE-UP = "Y"
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-SUBJECT) = "C"
        PERFORM DECIDE-CONDITION-NAME
        EXIT PARAGRAPH
    END-IF
    IF LS-NOT = "Y"
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-OPERATOR
    IF LS-GIVE-UP = "Y" OR LS-T > LS-LAST
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-LITERAL
    IF LS-KIND = SPACE
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    MOVE LS-T TO LS-VALUE-TOKEN
    ADD 1 TO LS-T
    PERFORM DECIDE-RELATION.

*> LS-SUBJECT: the symbol of the reference at LS-T, a data item or
*> condition name without subscripts; LS-T is left after it.
SUBJECT-AT.
    MOVE 0 TO LS-SUBJECT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-T
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND RF-SUBSCRIPTED(LS-R) = "N" AND RF-REFMOD(LS-R) = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-SUBJECT
                COMPUTE LS-T = RF-LAST(LS-R) + 1
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-SUBJECT = 0
        MOVE "Y" TO LS-GIVE-UP
    END-IF.

*> [IS] [NOT] operator at LS-T into LS-OP, NOT folded in for all but
*> = (LS-NOT stays Y for NOT =).
READ-OPERATOR.
    MOVE SPACE TO LS-OP
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    IF TK-IS-WORD(LS-T) AND LS-WORD = "IS"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    END-IF
    IF TK-IS-WORD(LS-T) AND LS-WORD = "NOT"
        MOVE "Y" TO LS-NOT
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "="
            MOVE "E" TO LS-OP
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = ">"
            MOVE "G" TO LS-OP
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = ">="
            MOVE "H" TO LS-OP
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "<"
            MOVE "L" TO LS-OP
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "<="
            MOVE "M" TO LS-OP
        WHEN TK-IS-WORD(LS-T) AND LS-WORD = "EQUAL"
            MOVE "E" TO LS-OP
            PERFORM SKIP-THAN-TO
            SUBTRACT 1 FROM LS-T
        WHEN TK-IS-WORD(LS-T)
             AND (LS-WORD = "GREATER" OR LS-WORD = "LESS")
            IF LS-WORD = "GREATER"
                MOVE "G" TO LS-OP
            ELSE
                MOVE "L" TO LS-OP
            END-IF
            PERFORM SKIP-THAN-TO
            *> OR EQUAL [TO]; an OR followed by anything else joins the
            *> next relation.
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "OR" AND LS-T < LS-LAST
                COMPUTE LS-I = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-WORD LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "EQUAL"
                    ADD 1 TO LS-T
                    IF LS-OP = "G"
                        MOVE "H" TO LS-OP
                    ELSE
                        MOVE "M" TO LS-OP
                    END-IF
                    PERFORM SKIP-THAN-TO
                END-IF
            END-IF
            SUBTRACT 1 FROM LS-T
        WHEN OTHER
            MOVE "Y" TO LS-GIVE-UP
            EXIT PARAGRAPH
    END-EVALUATE
    ADD 1 TO LS-T
    IF LS-NOT = "Y" AND LS-OP NOT = "E"
        EVALUATE LS-OP
            WHEN "G" MOVE "M" TO LS-OP
            WHEN "H" MOVE "L" TO LS-OP
            WHEN "L" MOVE "H" TO LS-OP
            WHEN "M" MOVE "G" TO LS-OP
        END-EVALUATE
        MOVE "N" TO LS-NOT
    END-IF.

*> From the word at LS-T, past THAN or TO after it.
SKIP-THAN-TO.
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) = "THAN"
       OR FUNCTION UPPER-CASE(LS-WORD) = "TO"
        ADD 1 TO LS-T
    END-IF.

*> [NOT] condition-name LS-SUBJECT: true when a SET before made it
*> TRUE (without NOT) or FALSE (with NOT).
DECIDE-CONDITION-NAME.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-KNOWN-COUNT
        IF LS-KNOWN-SYMBOL(LS-K) = LS-SUBJECT
            IF (LS-KNOWN-HOW(LS-K) = "T" AND LS-NOT = "N")
               OR (LS-KNOWN-HOW(LS-K) = "F" AND LS-NOT = "Y")
                MOVE "T" TO LS-TRUTH
                MOVE LS-K TO LS-DECIDER
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Item LS-SUBJECT op the literal just read: true when a MOVE before
*> left a literal the item holds as written that makes it so.
DECIDE-RELATION.
    MOVE LS-KIND TO LS-B-KIND
    MOVE LS-TEXT TO LS-B-TEXT
    MOVE LS-NUMBER TO LS-B-NUMBER
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-KNOWN-COUNT
        IF LS-KNOWN-SYMBOL(LS-K) = LS-SUBJECT
            IF LS-KNOWN-HOW(LS-K) = "L"
                MOVE LS-KNOWN-TOKEN(LS-K) TO LS-T
                PERFORM READ-LITERAL
                MOVE LS-KIND TO LS-A-KIND
                MOVE LS-TEXT TO LS-A-TEXT
                MOVE LS-NUMBER TO LS-A-NUMBER
                COMPUTE LS-T = LS-VALUE-TOKEN + 1
                PERFORM COMPARE-VALUES
                IF LS-RESULT = "T"
                    MOVE "T" TO LS-TRUTH
                    MOVE LS-K TO LS-DECIDER
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-RESULT = "T" when the item LS-SUBJECT, holding literal A, meets
*> op literal B; "U" when that is not known.
COMPARE-VALUES.
    MOVE "U" TO LS-RESULT
    EVALUATE SY-CATEGORY(LS-SUBJECT)
        WHEN "X" WHEN "A"
            IF LS-OP NOT = "E"
                EXIT PARAGRAPH
            END-IF
            *> ZERO is characters 0 here: the item all zeros.
            IF LS-A-KIND = "Z" OR LS-B-KIND = "Z"
                IF LS-A-KIND = "Z" AND LS-B-KIND = "Z"
                    MOVE "T" TO LS-RESULT
                END-IF
                PERFORM APPLY-NOT
                EXIT PARAGRAPH
            END-IF
            IF LS-A-KIND NOT = "A" OR LS-B-KIND NOT = "A"
                EXIT PARAGRAPH
            END-IF
            IF FUNCTION LENGTH(FUNCTION TRIM(LS-A-TEXT TRAILING))
                    > SY-SIZE(LS-SUBJECT)
               AND LS-A-TEXT NOT = SPACES
                EXIT PARAGRAPH
            END-IF
            IF FUNCTION LENGTH(FUNCTION TRIM(LS-B-TEXT TRAILING))
                    > SY-SIZE(LS-SUBJECT)
               AND LS-B-TEXT NOT = SPACES
                EXIT PARAGRAPH
            END-IF
            IF LS-A-TEXT = LS-B-TEXT
                MOVE "T" TO LS-RESULT
            ELSE
                MOVE "F" TO LS-RESULT
            END-IF
            PERFORM APPLY-NOT
        WHEN "9"
            EVALUATE SY-USAGE(LS-SUBJECT)
                WHEN SPACES WHEN "DISPLAY" WHEN "PACKED-DECIMAL"
                WHEN "COMP-3" WHEN "COMPUTATIONAL-3"
                    CONTINUE
                WHEN OTHER
                    EXIT PARAGRAPH
            END-EVALUATE
            IF LS-A-KIND = "Z"
                MOVE "N" TO LS-A-KIND
                MOVE 0 TO LS-A-NUMBER
            END-IF
            IF LS-B-KIND = "Z"
                MOVE "N" TO LS-B-KIND
                MOVE 0 TO LS-B-NUMBER
            END-IF
            IF LS-A-KIND NOT = "N" OR LS-B-KIND NOT = "N"
                EXIT PARAGRAPH
            END-IF
            PERFORM NUMBER-FITS
            IF LS-FITS = "N"
                EXIT PARAGRAPH
            END-IF
            MOVE "F" TO LS-RESULT
            EVALUATE LS-OP
                WHEN "E"
                    IF LS-A-NUMBER = LS-B-NUMBER
                        MOVE "T" TO LS-RESULT
                    END-IF
                WHEN "G"
                    IF LS-A-NUMBER > LS-B-NUMBER
                        MOVE "T" TO LS-RESULT
                    END-IF
                WHEN "H"
                    IF LS-A-NUMBER >= LS-B-NUMBER
                        MOVE "T" TO LS-RESULT
                    END-IF
                WHEN "L"
                    IF LS-A-NUMBER < LS-B-NUMBER
                        MOVE "T" TO LS-RESULT
                    END-IF
                WHEN "M"
                    IF LS-A-NUMBER <= LS-B-NUMBER
                        MOVE "T" TO LS-RESULT
                    END-IF
            END-EVALUATE
            PERFORM APPLY-NOT
    END-EVALUATE.

APPLY-NOT.
    IF LS-NOT = "Y"
        EVALUATE LS-RESULT
            WHEN "T" MOVE "F" TO LS-RESULT
            WHEN "F" MOVE "T" TO LS-RESULT
        END-EVALUATE
    END-IF.

*> LS-FITS = "Y" when the item's picture holds LS-A-NUMBER as it is:
*> the sign, the digits before the point, and those after it.
NUMBER-FITS.
    MOVE "N" TO LS-FITS
    IF SY-DIGITS(LS-SUBJECT) = 0 OR SY-DIGITS(LS-SUBJECT) > 17
       OR SY-SCALE(LS-SUBJECT) < 0 OR SY-SCALE(LS-SUBJECT) > 9
       OR SY-SCALE(LS-SUBJECT) > SY-DIGITS(LS-SUBJECT)
        EXIT PARAGRAPH
    END-IF
    IF LS-A-NUMBER < 0 AND SY-SIGNED(LS-SUBJECT) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-LIMIT = 10 ** (SY-DIGITS(LS-SUBJECT)
                              - SY-SCALE(LS-SUBJECT))
    IF FUNCTION ABS(LS-A-NUMBER) >= LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-SCALED = LS-A-NUMBER * 10 ** SY-SCALE(LS-SUBJECT)
    IF LS-SCALED NOT = FUNCTION INTEGER-PART(LS-SCALED)
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-FITS.

*> At the UNTIL: the statement (LS-DECIDER) that makes it true.
REPORT-LOOP.
    MOVE LS-KNOWN-STMT(LS-DECIDER) TO LS-K
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-K))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "the UNTIL condition is already true after the "
           DELIMITED BY SIZE
           ND-DETAIL(LS-K) DELIMITED BY SPACE
           " on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", and is tested first: the loop runs no times"
           DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-UNTIL LS-MESSAGE.
END PROGRAM PLB-RULE-C089.
