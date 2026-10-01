*> ---------------------------------------------------------------
*> plbrtable: rules about tables.
*>
*>   PLB-C037  search-index-not-set
*> ---------------------------------------------------------------

*> PLB-C037 search-index-not-set: a serial SEARCH (not SEARCH ALL)
*> starts at the current value of the table's first index, not at the
*> first entry. Unless the paragraph sets that index (SET, or a PERFORM
*> that names it, as in PERFORM VARYING) before the SEARCH, the search
*> starts wherever the last one stopped, and misses the entries before.
*>
*> The index counts as set when the paragraph sets it before the
*> SEARCH, or when a paragraph that leads into this one sets it
*> anywhere: one that falls into it, goes to it, or performs it. Paths
*> longer than that are not followed.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C037.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-SEARCH               PIC 9(9) COMP-5.
01  LS-SCAN                 PIC 9(9) COMP-5.
01  LS-SCAN-DEPTH           PIC S9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-TABLE-TOKEN          PIC 9(9) COMP-5.
01  LS-START                PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-INDEX                PIC X(31).
01  LS-WORD                 PIC X(31).
01  LS-VARYING              PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C037" LS-RULE
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
            MOVE LS-NODE TO LS-SEARCH
            PERFORM CHECK-SEARCH
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

CHECK-SEARCH.
    COMPUTE LS-TABLE-TOKEN = ND-TOK-FIRST(LS-SEARCH) + 1
    IF LS-TABLE-TOKEN > ND-TOK-LAST(LS-SEARCH)
        EXIT PARAGRAPH
    END-IF
    *> SEARCH ALL starts from the middle of the table on its own.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TABLE-TOKEN LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) = "ALL"
        EXIT PARAGRAPH
    END-IF
    IF WS-TOKEN-REF(LS-TABLE-TOKEN) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE WS-TOKEN-REF(LS-TABLE-TOKEN) TO LS-R
    IF RF-KIND(LS-R) NOT = "D"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-TABLE
    PERFORM FIRST-INDEX
    IF LS-INDEX = SPACES
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING-INDEX
    PERFORM PARAGRAPH-START
    MOVE ND-TOK-FIRST(LS-SEARCH) TO LS-END
    PERFORM FIND-SET
    IF LS-FOUND = "N" AND LS-UNIT > 0
        PERFORM FIND-SET-BEFORE
    END-IF
    IF LS-FOUND = "N"
        PERFORM REPORT-SEARCH
    END-IF.

*> LS-FOUND = "Y" when a unit leading into LS-UNIT sets the index.
FIND-SET-BEFORE.
    PERFORM VARYING LS-V FROM 1 BY 1
            UNTIL LS-V > FU-COUNT OR LS-FOUND = "Y"
        IF FU-NEXT(LS-V) = LS-UNIT AND FU-FALLS(LS-V) = "Y"
           AND FU-FLOWED(LS-V) = "Y"
            PERFORM FIND-SET-IN-UNIT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1
            UNTIL LS-E > FE-COUNT OR LS-FOUND = "Y"
        IF FE-TO(LS-E) = LS-UNIT
           AND (FE-KIND(LS-E) = "P" OR FE-KIND(LS-E) = "G")
            MOVE FE-FROM(LS-E) TO LS-V
            PERFORM FIND-SET-IN-UNIT
        END-IF
    END-PERFORM.

FIND-SET-IN-UNIT.
    MOVE ND-TOK-FIRST(FU-NODE(LS-V)) TO LS-START
    COMPUTE LS-END = ND-TOK-LAST(FU-NODE(LS-V)) + 1
    PERFORM FIND-SET.

*> LS-INDEX: the first name after INDEXED BY in the table's entry, or
*> spaces.
FIRST-INDEX.
    MOVE SPACES TO LS-INDEX
    IF SY-NODE(LS-TABLE) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(SY-NODE(LS-TABLE)) BY 1
            UNTIL LS-T >= ND-TOK-LAST(SY-NODE(LS-TABLE))
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) = "INDEXED"
            ADD 1 TO LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "BY"
                ADD 1 TO LS-T
            END-IF
            IF LS-T <= ND-TOK-LAST(SY-NODE(LS-TABLE))
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-INDEX
                    LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-INDEX) TO LS-INDEX
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> SEARCH ... VARYING one of the table's own indexes searches with
*> that index instead of the first.
VARYING-INDEX.
    COMPUTE LS-T = LS-TABLE-TOKEN + 1
    IF LS-T >= ND-TOK-LAST(LS-SEARCH)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "VARYING"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-VARYING LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-VARYING) TO LS-VARYING
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(SY-NODE(LS-TABLE)) BY 1
            UNTIL LS-T > ND-TOK-LAST(SY-NODE(LS-TABLE))
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        EVALUATE TRUE
            WHEN FUNCTION UPPER-CASE(LS-WORD) = "INDEXED"
                MOVE "Y" TO LS-FOUND
            WHEN LS-FOUND = "Y"
             AND FUNCTION UPPER-CASE(LS-WORD) = LS-VARYING
                MOVE LS-VARYING TO LS-INDEX
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM.

*> LS-START: the first token of the paragraph, section, or division
*> start the SEARCH is in, LS-UNIT: that unit (the last to start
*> before it; a paragraph rather than the section it opens).
PARAGRAPH-START.
    MOVE 1 TO LS-START
    MOVE 0 TO LS-UNIT
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF ND-TOK-FIRST(FU-NODE(LS-U)) <= ND-TOK-FIRST(LS-SEARCH)
           AND ND-TOK-FIRST(FU-NODE(LS-U)) >= LS-START
            MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO LS-START
            MOVE LS-U TO LS-UNIT
        END-IF
    END-PERFORM.

*> LS-FOUND = "Y" when a SET or PERFORM statement from LS-START up to
*> LS-END names the index.
FIND-SET.
    MOVE "N" TO LS-FOUND
    MOVE 1 TO LS-SCAN
    MOVE 0 TO LS-SCAN-DEPTH
    PERFORM UNTIL LS-SCAN = 0 OR LS-FOUND = "Y"
        IF ND-KIND(LS-SCAN) = "STMT"
           AND (ND-DETAIL(LS-SCAN) = "SET" OR "PERFORM")
           AND ND-TOK-FIRST(LS-SCAN) >= LS-START
           AND ND-TOK-FIRST(LS-SCAN) < LS-END
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-SCAN) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-SCAN)
                       OR LS-T >= LS-END
                IF TK-IS-WORD(LS-T)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD
                        LS-LEN
                    IF FUNCTION UPPER-CASE(LS-WORD) = LS-INDEX
                        MOVE "Y" TO LS-FOUND
                        EXIT PERFORM
                    END-IF
                END-IF
            END-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-SCAN LS-SCAN-DEPTH
    END-PERFORM.

REPORT-SEARCH.
    MOVE SPACES TO LS-MESSAGE
    STRING "SEARCH " DELIMITED BY SIZE
           SY-NAME(LS-TABLE) DELIMITED BY SPACE
           " starts at the current value of " DELIMITED BY SIZE
           LS-INDEX DELIMITED BY SPACE
           ", which this paragraph does not set before it"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TABLE-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C037.
