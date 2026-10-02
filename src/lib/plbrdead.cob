*> ---------------------------------------------------------------
*> plbrdead: values that are replaced before they are read.
*>
*>   PLB-C030  value-never-used
*>
*> MOVE 0 TO TOTAL followed, in the same paragraph, by MOVE AMOUNT TO
*> TOTAL with nothing reading TOTAL in between: the first value is
*> never used. Usually one of the two statements names the wrong item.
*>
*> The rule follows the statements of a paragraph in order, across
*> sentences, from a MOVE, COMPUTE, or INITIALIZE that gives an item
*> a value. It stops at the end of the paragraph and at any statement
*> that could read the item without saying so, or change the order of
*> execution: PERFORM, CALL, GO TO, I/O, conditional statements, and
*> statements with a phrase such as ON SIZE ERROR. A statement that
*> reads any part of the storage the item shares (its groups, its
*> members, or a REDEFINES of them) stops it too. The value is
*> reported when a MOVE or COMPUTE replaces the whole item.
*>
*> Clearing an item before filling it (MOVE SPACES, MOVE 0,
*> INITIALIZE) is a habit, not a mistake, and is not reported. MOVE
*> CORRESPONDING gives values to some members only, and is neither a
*> store the rule follows nor one that replaces a value. A program
*> with USE FOR DEBUGGING runs code on references that statements do
*> not show, and is not checked.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-DEAD-STORE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
*> The store: its statement, reference, and item.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-TARGET               PIC 9(9) COMP-5.
*> The statement being looked at after it, and its sentence.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-SENT                 PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-DONE                 PIC X.
01  LS-READS                PIC X.
01  LS-REPLACES             PIC X.
*> Storage overlap of two items.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-ROOT-A               PIC 9(9) COMP-5.
01  LS-ROOT-B               PIC 9(9) COMP-5.
01  LS-TABLE                PIC X.
01  LS-OVERLAP              PIC X.
01  LS-U                    PIC 9(9) COMP-5.
*> The reference that replaces the value.
01  LS-REPLACING            PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-CLEARS               PIC X.
01  LS-CORRESPONDING        PIC X.
01  LS-DEP-COUNT            PIC 9(4) COMP-5.
01  LS-DEBUGGING            PIC X.
01  LS-DEP-NAME             PIC X(31) OCCURS 1000 TIMES.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C030" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR RF-COUNT = 0
        GOBACK
    END-IF
    PERFORM COLLECT-DEPENDING
    IF LS-DEBUGGING = "Y"
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-KIND(ND-PARENT(LS-NODE)) = "SENT"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "MOVE"
                WHEN "COMPUTE"
                    MOVE LS-NODE TO LS-STMT
                    PERFORM TEST-CLEARS
                    IF LS-CLEARS = "N"
                        PERFORM CHECK-STORES
                    END-IF
            END-EVALUATE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> LS-CLEARS = "Y" when statement LS-STMT moves a value that clears
*> an item: a figurative constant, zero, or spaces (MOVE SPACES TO X,
*> COMPUTE X = 0).
TEST-CLEARS.
    MOVE "N" TO LS-CLEARS
    *> MOVE CORRESPONDING gives values to some members only.
    MOVE LS-STMT TO LS-C
    PERFORM TEST-CORRESPONDING
    IF LS-CORRESPONDING = "Y"
        MOVE "Y" TO LS-CLEARS
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-STMT) + 1
    IF ND-DETAIL(LS-STMT) = "COMPUTE"
        PERFORM UNTIL LS-TOKEN >= ND-TOK-LAST(LS-STMT)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-WORD LS-LEN
            IF LS-WORD = "=" OR LS-WORD = "EQUAL"
                EXIT PERFORM
            END-IF
            ADD 1 TO LS-TOKEN
        END-PERFORM
        ADD 1 TO LS-TOKEN
        *> The expression must be that one value.
        IF LS-TOKEN NOT = ND-TOK-LAST(LS-STMT)
            COMPUTE LS-C = LS-TOKEN + 1
            IF LS-C > ND-TOK-LAST(LS-STMT)
                EXIT PARAGRAPH
            END-IF
            IF NOT TK-IS-PERIOD(LS-C)
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-WORD LS-LEN
    EVALUATE TRUE
        WHEN TK-IS-WORD(LS-TOKEN)
            IF LS-WORD = "SPACE" OR "SPACES" OR "ZERO" OR "ZEROS"
               OR "ZEROES" OR "LOW-VALUE" OR "LOW-VALUES"
               OR "HIGH-VALUE" OR "HIGH-VALUES" OR "NULL" OR "NULLS"
                MOVE "Y" TO LS-CLEARS
            END-IF
        WHEN TK-IS-NUMBER(LS-TOKEN)
            IF LS-LEN <= 31
                MOVE "Y" TO LS-CLEARS
                PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > LS-LEN
                    IF LS-WORD(LS-C:1) NOT = "0" AND NOT = "."
                       AND NOT = "," AND NOT = "+" AND NOT = "-"
                        MOVE "N" TO LS-CLEARS
                    END-IF
                END-PERFORM
            END-IF
        WHEN TK-IS-ALNUM(LS-TOKEN)
            IF LS-WORD = SPACES AND LS-LEN <= 31
               AND TK-PREFIX(LS-TOKEN) = SPACES
                MOVE "Y" TO LS-CLEARS
            END-IF
    END-EVALUATE.

*> LS-CORRESPONDING = "Y" when statement LS-C is MOVE CORRESPONDING.
TEST-CORRESPONDING.
    MOVE "N" TO LS-CORRESPONDING
    IF ND-DETAIL(LS-C) = "MOVE"
        COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-C) + 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-WORD LS-LEN
        IF LS-WORD = "CORRESPONDING" OR LS-WORD = "CORR"
            MOVE "Y" TO LS-CORRESPONDING
        END-IF
    END-IF.

*> Each item statement LS-STMT gives a value to, as a whole.
CHECK-STORES.
    IF ND-FIRST(LS-STMT) > 0
        PERFORM HAS-BLOCK
        IF LS-DONE = "Y"
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM FIRST-REF
    PERFORM UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) > ND-TOK-LAST(LS-STMT)
            EXIT PERFORM
        END-IF
        IF RF-KIND(LS-R) = "D" AND RF-ROLE(LS-R) = "D"
           AND RF-SUBSCRIPTED(LS-R) = "N" AND RF-REFMOD(LS-R) = "N"
            MOVE RF-SYMBOL(LS-R) TO LS-TARGET
            PERFORM CHECK-TARGET-ITEM
            IF LS-TABLE = "N"
                PERFORM FOLLOW-STORE
            END-IF
        END-IF
        ADD 1 TO LS-R
    END-PERFORM.

*> LS-TABLE = "Y" when LS-TARGET is not an item the rule follows: in
*> a table, a condition name, renames, or constant, or a count that
*> DEPENDING ON names.
CHECK-TARGET-ITEM.
    MOVE "N" TO LS-TABLE
    IF SY-CATEGORY(LS-TARGET) = "C" OR SY-CATEGORY(LS-TARGET) = "R"
       OR SY-CATEGORY(LS-TARGET) = "K" OR SY-VARIABLE(LS-TARGET) = "Y"
        MOVE "Y" TO LS-TABLE
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TARGET TO LS-U
    PERFORM UNTIL LS-U = 0
        IF SY-OCCURS(LS-U) > 0
            MOVE "Y" TO LS-TABLE
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-U) TO LS-U
    END-PERFORM
    IF LS-TABLE = "Y"
        EXIT PARAGRAPH
    END-IF
    *> A count named by DEPENDING ON (of an OCCURS, or of an ACUCOBOL
    *> PICTURE L) is read by every statement that uses its item.
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > LS-DEP-COUNT
        IF LS-DEP-NAME(LS-U) = SY-NAME(LS-TARGET)
            MOVE "Y" TO LS-TABLE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-DEP-NAME = the names that follow DEPENDING [ON] anywhere;
*> LS-DEBUGGING = "Y" when a declarative is USE FOR DEBUGGING, which
*> runs on references the statements do not show.
COLLECT-DEPENDING.
    MOVE 0 TO LS-DEP-COUNT
    MOVE "N" TO LS-DEBUGGING
    PERFORM VARYING LS-TOKEN FROM 1 BY 1 UNTIL LS-TOKEN >= TK-COUNT
        IF TK-IS-WORD(LS-TOKEN) AND TK-KEYWORD(LS-TOKEN) NOT = SPACE
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-WORD LS-LEN
            IF LS-WORD = "DEBUGGING" AND LS-TOKEN > 1
                COMPUTE LS-C = LS-TOKEN - 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-WORD LS-LEN
                IF LS-WORD = "FOR"
                    MOVE "Y" TO LS-DEBUGGING
                END-IF
                MOVE "DEBUGGING" TO LS-WORD
            END-IF
            IF LS-WORD = "DEPENDING"
                COMPUTE LS-C = LS-TOKEN + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-WORD LS-LEN
                IF LS-WORD = "ON" AND LS-C < TK-COUNT
                    ADD 1 TO LS-C
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-WORD
                        LS-LEN
                END-IF
                IF TK-IS-WORD(LS-C) AND LS-DEP-COUNT < 1000
                    ADD 1 TO LS-DEP-COUNT
                    MOVE LS-WORD TO LS-DEP-NAME(LS-DEP-COUNT)
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> LS-R = the first reference at or after the first token of LS-STMT
*> (references are in token order).
FIRST-REF.
    MOVE 1 TO LS-R
    MOVE RF-COUNT TO LS-K
    PERFORM UNTIL LS-R >= LS-K
        COMPUTE LS-U = (LS-R + LS-K) / 2
        IF RF-TOKEN(LS-U) < ND-TOK-FIRST(LS-STMT)
            COMPUTE LS-R = LS-U + 1
        ELSE
            MOVE LS-U TO LS-K
        END-IF
    END-PERFORM.

*> LS-DONE = "Y" when statement LS-STMT has a phrase with statements
*> of its own (ON SIZE ERROR, AT END, ...).
HAS-BLOCK.
    MOVE "N" TO LS-DONE
    MOVE ND-FIRST(LS-STMT) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            MOVE "Y" TO LS-DONE
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

*> The statements after LS-STMT in its paragraph, until one reads the
*> target, replaces it, or ends the search.
FOLLOW-STORE.
    MOVE LS-STMT TO LS-NEXT
    MOVE ND-PARENT(LS-STMT) TO LS-SENT
    MOVE "N" TO LS-DONE
    PERFORM UNTIL LS-DONE = "Y"
        PERFORM NEXT-STATEMENT
        IF LS-NEXT = 0
            EXIT PERFORM
        END-IF
        EVALUATE ND-DETAIL(LS-NEXT)
            WHEN "MOVE" WHEN "COMPUTE" WHEN "INITIALIZE"
            WHEN "ADD" WHEN "SUBTRACT" WHEN "MULTIPLY" WHEN "DIVIDE"
            WHEN "SET" WHEN "STRING" WHEN "UNSTRING" WHEN "INSPECT"
            WHEN "DISPLAY" WHEN "CONTINUE" WHEN "ACCEPT"
                CONTINUE
            WHEN OTHER
                EXIT PERFORM
        END-EVALUATE
        MOVE LS-STMT TO LS-K
        MOVE LS-NEXT TO LS-STMT
        PERFORM HAS-BLOCK
        MOVE LS-K TO LS-STMT
        IF LS-DONE = "Y"
            EXIT PERFORM
        END-IF
        PERFORM SCAN-NEXT
        IF LS-READS = "Y"
            MOVE "Y" TO LS-DONE
        END-IF
        IF LS-REPLACES = "Y"
            PERFORM REPORT-STORE
            MOVE "Y" TO LS-DONE
        END-IF
    END-PERFORM.

*> LS-NEXT = the statement after LS-NEXT in its sentence, or the first
*> of the next sentence of the paragraph; 0 at the paragraph's end.
NEXT-STATEMENT.
    MOVE ND-NEXT(LS-NEXT) TO LS-K
    PERFORM UNTIL LS-K = 0
        IF ND-KIND(LS-K) = "STMT"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-K) TO LS-K
    END-PERFORM
    PERFORM UNTIL LS-K > 0
        MOVE ND-NEXT(LS-SENT) TO LS-SENT
        IF LS-SENT = 0
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-SENT) NOT = "SENT"
            MOVE 0 TO LS-SENT
            EXIT PERFORM
        END-IF
        MOVE ND-FIRST(LS-SENT) TO LS-K
        PERFORM UNTIL LS-K = 0
            IF ND-KIND(LS-K) = "STMT"
                EXIT PERFORM
            END-IF
            MOVE ND-NEXT(LS-K) TO LS-K
        END-PERFORM
    END-PERFORM
    MOVE LS-K TO LS-NEXT.

*> The references of statement LS-NEXT: LS-READS = "Y" when one may
*> read storage of the target; LS-REPLACES = "Y" when a MOVE or
*> COMPUTE gives the whole target a value and nothing there reads it.
SCAN-NEXT.
    MOVE "N" TO LS-READS LS-REPLACES
    MOVE LS-NEXT TO LS-C
    PERFORM TEST-CORRESPONDING
    MOVE LS-R TO LS-K
    PERFORM UNTIL LS-K > RF-COUNT
        IF RF-TOKEN(LS-K) >= ND-TOK-FIRST(LS-NEXT)
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-K
    END-PERFORM
    PERFORM UNTIL LS-K > RF-COUNT
        IF RF-TOKEN(LS-K) > ND-TOK-LAST(LS-NEXT)
            EXIT PERFORM
        END-IF
        *> An ambiguous name may be the target.
        IF RF-KIND(LS-K) = "A" AND RF-ROLE(LS-K) NOT = "D"
            MOVE "Y" TO LS-READS
        END-IF
        IF RF-KIND(LS-K) = "D"
            MOVE RF-SYMBOL(LS-K) TO LS-B
            PERFORM TEST-OVERLAP
            IF LS-OVERLAP = "Y"
                IF RF-ROLE(LS-K) = "D"
                    IF RF-SYMBOL(LS-K) = LS-TARGET
                       AND RF-SUBSCRIPTED(LS-K) = "N"
                       AND RF-REFMOD(LS-K) = "N"
                       AND (ND-DETAIL(LS-NEXT) = "MOVE"
                            OR ND-DETAIL(LS-NEXT) = "COMPUTE")
                       AND LS-CORRESPONDING = "N"
                        MOVE "Y" TO LS-REPLACES
                        MOVE LS-K TO LS-REPLACING
                    END-IF
                ELSE
                    MOVE "Y" TO LS-READS
                END-IF
            END-IF
        END-IF
        ADD 1 TO LS-K
    END-PERFORM
    IF LS-READS = "Y"
        MOVE "N" TO LS-REPLACES
    END-IF.

*> LS-OVERLAP = "Y" when item LS-B may share storage with the target:
*> the same record (or records that redefine each other), and byte
*> ranges that meet, or a table or renames whose place is not known.
TEST-OVERLAP.
    MOVE "N" TO LS-OVERLAP
    IF LS-B = LS-TARGET
        MOVE "Y" TO LS-OVERLAP
        EXIT PARAGRAPH
    END-IF
    *> A condition name tests its item.
    IF SY-CATEGORY(LS-B) = "C" AND SY-PARENT(LS-B) > 0
        MOVE SY-PARENT(LS-B) TO LS-B
    END-IF
    MOVE LS-TARGET TO LS-A
    PERFORM RECORD-OF-A
    MOVE LS-ROOT-A TO LS-ROOT-B
    MOVE LS-B TO LS-A
    PERFORM RECORD-OF-A
    IF LS-ROOT-A NOT = LS-ROOT-B
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-TABLE
    MOVE LS-B TO LS-U
    PERFORM UNTIL LS-U = 0
        IF SY-OCCURS(LS-U) > 0 OR SY-CATEGORY(LS-U) = "R"
            MOVE "Y" TO LS-TABLE
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-U) TO LS-U
    END-PERFORM
    IF LS-TABLE = "Y"
       OR (SY-OFFSET(LS-B) < SY-OFFSET(LS-TARGET) + SY-SIZE(LS-TARGET)
           AND SY-OFFSET(LS-TARGET) < SY-OFFSET(LS-B) + SY-SIZE(LS-B))
        MOVE "Y" TO LS-OVERLAP
    END-IF.

*> LS-ROOT-A = the record of item LS-A, or the record it redefines.
RECORD-OF-A.
    MOVE LS-A TO LS-ROOT-A
    PERFORM UNTIL SY-PARENT(LS-ROOT-A) = 0
        MOVE SY-PARENT(LS-ROOT-A) TO LS-ROOT-A
    END-PERFORM
    PERFORM UNTIL SY-REDEFINES(LS-ROOT-A) = 0
        MOVE SY-REDEFINES(LS-ROOT-A) TO LS-ROOT-A
    END-PERFORM.

REPORT-STORE.
    MOVE RF-TOKEN(LS-REPLACING) TO LS-TOKEN
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-TOKEN)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the value given to " DELIMITED BY SIZE
           SY-NAME(LS-TARGET) DELIMITED BY SPACE
           " here is replaced on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " before it is used" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE RF-TOKEN(LS-R) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-DEAD-STORE.
