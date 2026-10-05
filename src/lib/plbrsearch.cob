*> ---------------------------------------------------------------
*> plbrsearch: PLB-C069 search-index-used-unchecked.
*>
*> A SEARCH without AT END, after which the paragraph uses the table's
*> index as if the search had found an entry:
*>
*>     SEARCH RATE-ENTRY
*>         WHEN RATE-CODE (RATE-IX) = WS-CODE
*>             CONTINUE
*>     END-SEARCH
*>     MOVE RATE-VALUE (RATE-IX) TO WS-RATE
*>
*> When no entry matches, the index is left past the last entry (or
*> where SEARCH ALL stopped), and the MOVE reads storage after the
*> table, or a wrong entry. The index is the first INDEXED BY name of
*> the table searched, or the item after VARYING. Its uses are looked
*> for after the SEARCH, to the end of the paragraph, as subscripts in
*> statements directly in the paragraph: a SET of the index or another
*> SEARCH ends the search for them, and a use under an IF or EVALUATE
*> (which may test whether the search found anything) is not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C069.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none).
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-UNIT-NODE            PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-INDEX                PIC X(31).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-AT-END               PIC X.
01  LS-DONE                 PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C069" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "SEARCH"
            PERFORM CHECK-SEARCH
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> SEARCH statement LS-NODE: without AT END, the index, and its uses.
CHECK-SEARCH.
    MOVE "N" TO LS-AT-END
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "AT-END"
            MOVE "Y" TO LS-AT-END
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-AT-END = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-INDEX
    IF LS-INDEX = SPACES
        EXIT PARAGRAPH
    END-IF
    *> The statement must be directly in a sentence of a paragraph, a
    *> section, or the procedure division: its uses are then the
    *> statements after it there.
    IF ND-PARENT(LS-NODE) = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(ND-PARENT(LS-NODE)) NOT = "SENT"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(ND-PARENT(LS-NODE)) TO LS-UNIT-NODE
    IF LS-UNIT-NODE = 0
        EXIT PARAGRAPH
    END-IF
    *> A paragraph, a section, or a procedure division without them.
    IF ND-KIND(LS-UNIT-NODE) NOT = "PARA"
       AND ND-KIND(LS-UNIT-NODE) NOT = "SECT"
       AND ND-KIND(LS-UNIT-NODE) NOT = "DIVN"
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-USES.

*> LS-INDEX: the item after VARYING, or the first INDEXED BY name of
*> the table searched (the reference after SEARCH [ALL]).
FIND-INDEX.
    MOVE SPACES TO LS-INDEX
    MOVE 0 TO LS-TABLE
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        IF WS-TOKEN-REF(LS-T) > 0 AND LS-TABLE = 0
            MOVE WS-TOKEN-REF(LS-T) TO LS-R
            IF RF-KIND(LS-R) = "D"
                MOVE RF-SYMBOL(LS-R) TO LS-TABLE
            END-IF
        END-IF
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "VARYING"
                COMPUTE LS-Q = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-INDEX LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-INDEX) TO LS-INDEX
                EXIT PARAGRAPH
            END-IF
            IF FUNCTION UPPER-CASE(LS-TEXT) = "WHEN"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-TABLE = 0 OR SY-NODE(LS-TABLE) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(SY-NODE(LS-TABLE)) BY 1
            UNTIL LS-T >= ND-TOK-LAST(SY-NODE(LS-TABLE))
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "INDEXED"
                COMPUTE LS-Q = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "BY"
                    ADD 1 TO LS-Q
                END-IF
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-Q LS-INDEX LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-INDEX) TO LS-INDEX
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> The tokens after the SEARCH to the end of the paragraph: the first
*> use of the index as a subscript, unless a SET of it comes first.
FIND-USES.
    MOVE "N" TO LS-DONE
    PERFORM VARYING LS-T FROM ND-TOK-LAST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-UNIT-NODE) OR LS-DONE = "Y"
        IF LS-T > ND-TOK-LAST(LS-NODE) AND WS-TOKEN-REF(LS-T) > 0
            MOVE WS-TOKEN-REF(LS-T) TO LS-R
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = LS-INDEX
               AND RF-STMT(LS-R) > 0
                PERFORM CHECK-USE
            END-IF
        END-IF
    END-PERFORM.

*> Reference LS-R names the index: a SET ends the search; a use as a
*> subscript of a statement directly in the paragraph is reported.
CHECK-USE.
    *> A SET of the index, or another SEARCH, starts afresh.
    IF ND-DETAIL(RF-STMT(LS-R)) = "SET"
       OR ND-DETAIL(RF-STMT(LS-R)) = "SEARCH"
        MOVE "Y" TO LS-DONE
        EXIT PARAGRAPH
    END-IF
    *> Directly in the paragraph: no statement around it.
    MOVE ND-PARENT(RF-STMT(LS-R)) TO LS-UP
    PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-UNIT-NODE
        *> Under a statement or phrase, or in a later paragraph.
        IF ND-KIND(LS-UP) = "STMT" OR ND-KIND(LS-UP) = "BLCK"
           OR ND-KIND(LS-UP) = "PARA" OR ND-KIND(LS-UP) = "SECT"
            EXIT PARAGRAPH
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    *> As a subscript: inside the parentheses of another reference.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > RF-COUNT
        IF RF-SUBSCRIPTED(LS-C) = "Y"
           AND RF-TOKEN(LS-C) < RF-TOKEN(LS-R)
           AND RF-LAST(LS-C) > RF-TOKEN(LS-R)
            PERFORM REPORT-USE
            MOVE "Y" TO LS-DONE
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-USE.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING LS-INDEX DELIMITED BY SPACE
           " is used after the SEARCH on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", which has no AT END: when nothing matched, it is past"
           " the entry looked for" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C069.
