*> ---------------------------------------------------------------
*> plbrtable: rules about tables.
*>
*>   PLB-C037  search-index-not-set
*>   PLB-C047  foreign-index
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
            *> plumbline: ignore varying-control-changed -- steps past the tokens just read
            ADD 1 TO LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "BY"
                *> plumbline: ignore varying-control-changed -- steps past the tokens just read
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

*> PLB-C047 foreign-index: an index of one table (INDEXED BY) used as
*> the subscript of another table whose entries have another length.
*> IBM's compilers keep an index as the byte offset of its entry, so
*> such an index selects some other entry, or a position between two;
*> the standard allows it only for tables with entries of one length.
*> GnuCOBOL keeps the entry number, so the program works there and
*> fails after a move to the mainframe, or the other way round.
*>
*> Each subscript of a reference is matched with the table of its
*> dimension, outermost first. A subscript counts when it is an index
*> name alone or with a relative offset (IX + 1); expressions and data
*> items are not looked at.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C047.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The index names of the program: name, table, and program.
78  WS-IX-MAX               VALUE 5000.
01  WS-IX-COUNT             PIC 9(9) COMP-5.
01  WS-IX                   OCCURS WS-IX-MAX TIMES.
    05  WS-IX-NAME          PIC X(31).
    05  WS-IX-TABLE         PIC 9(9) COMP-5.
    05  WS-IX-PROGRAM       PIC 9(9) COMP-5.
*> The tables of the reference's dimensions, outermost first, and its
*> subscripts: first token and whether it is an index-name form.
78  WS-DIM-MAX              VALUE 16.
01  WS-DIM                  PIC 9(9) COMP-5 OCCURS WS-DIM-MAX TIMES.
01  WS-SUB-TOKEN            PIC 9(9) COMP-5 OCCURS WS-DIM-MAX TIMES.
01  WS-SUB-SIMPLE           PIC X OCCURS WS-DIM-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-X                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-DIMS                 PIC 9(9) COMP-5.
01  LS-SUBS                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC 9(9) COMP-5.
01  LS-OPERAND              PIC X.
01  LS-QUALIFIER            PIC X.
01  LS-GIVE-UP              PIC X.
01  LS-IN-INDEXED           PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-OTHER                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-SIZE-1               PIC X(12).
01  LS-SIZE-1-LEN           PIC 9(9) COMP-5.
01  LS-SIZE-2               PIC X(12).
01  LS-SIZE-2-LEN           PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C047" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM COLLECT-INDEXES
    IF WS-IX-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SUBSCRIPTED(LS-R) = "Y"
            PERFORM CHECK-REFERENCE
        END-IF
    END-PERFORM
    GOBACK.

*> The names after INDEXED BY in the entry of each table, up to the
*> next reserved word or the end of the entry.
COLLECT-INDEXES.
    MOVE 0 TO WS-IX-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-OCCURS(LS-S) > 0 AND SY-NODE(LS-S) > 0
            MOVE "N" TO LS-IN-INDEXED
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(SY-NODE(LS-S)) BY 1
                    UNTIL LS-T > ND-TOK-LAST(SY-NODE(LS-S))
                       OR TK-IS-PERIOD(LS-T)
                PERFORM INDEX-TOKEN
            END-PERFORM
        END-IF
    END-PERFORM.

INDEX-TOKEN.
    IF NOT TK-IS-WORD(LS-T)
        MOVE "N" TO LS-IN-INDEXED
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    EVALUATE TRUE
        WHEN LS-WORD = "INDEXED"
            MOVE "Y" TO LS-IN-INDEXED
        WHEN LS-IN-INDEXED = "Y" AND LS-WORD = "BY"
            CONTINUE
        WHEN LS-IN-INDEXED = "Y" AND TK-KEYWORD(LS-T) = SPACE
            IF WS-IX-COUNT < WS-IX-MAX
                ADD 1 TO WS-IX-COUNT
                MOVE LS-WORD TO WS-IX-NAME(WS-IX-COUNT)
                MOVE LS-S TO WS-IX-TABLE(WS-IX-COUNT)
                MOVE SY-PROGRAM(LS-S) TO WS-IX-PROGRAM(WS-IX-COUNT)
            END-IF
        WHEN OTHER
            MOVE "N" TO LS-IN-INDEXED
    END-EVALUATE.

CHECK-REFERENCE.
    *> The tables of the dimensions: the item and its groups that have
    *> OCCURS, found innermost first and stored outermost first.
    MOVE 0 TO LS-DIMS
    MOVE RF-SYMBOL(LS-R) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF SY-OCCURS(LS-UP) > 0
            IF LS-DIMS >= WS-DIM-MAX
                EXIT PARAGRAPH
            END-IF
            ADD 1 TO LS-DIMS
            MOVE LS-UP TO WS-DIM(LS-DIMS)
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF LS-DIMS = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-DIMS / 2
        COMPUTE LS-X = LS-DIMS + 1 - LS-K
        MOVE WS-DIM(LS-K) TO LS-I
        MOVE WS-DIM(LS-X) TO WS-DIM(LS-K)
        MOVE LS-I TO WS-DIM(LS-X)
    END-PERFORM
    PERFORM SPLIT-SUBSCRIPTS
    IF LS-GIVE-UP = "Y" OR LS-SUBS NOT = LS-DIMS
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-SUBS
        IF WS-SUB-SIMPLE(LS-K) = "Y"
            PERFORM CHECK-SUBSCRIPT
        END-IF
    END-PERFORM.

*> The subscripts between the first parenthesis after the name and
*> the one that closes it. Two operands side by side start a new
*> subscript; an operator joins them into one, as does a signed
*> number after an operand (IX +1). A colon means the parenthesis is
*> a reference modifier, not a subscript.
SPLIT-SUBSCRIPTS.
    MOVE 0 TO LS-SUBS
    MOVE "N" TO LS-GIVE-UP
    MOVE RF-TOKEN(LS-R) TO LS-T
    PERFORM UNTIL LS-T >= RF-LAST(LS-R) OR TK-IS-LPAREN(LS-T)
        ADD 1 TO LS-T
    END-PERFORM
    IF NOT TK-IS-LPAREN(LS-T)
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-DEPTH
    MOVE "N" TO LS-OPERAND LS-QUALIFIER
    ADD 1 TO LS-T
    PERFORM UNTIL LS-DEPTH = 0 OR LS-T > RF-LAST(LS-R)
           OR LS-GIVE-UP = "Y"
        PERFORM SUBSCRIPT-TOKEN
        ADD 1 TO LS-T
    END-PERFORM.

SUBSCRIPT-TOKEN.
    EVALUATE TRUE
        WHEN TK-IS-LPAREN(LS-T)
            IF LS-DEPTH = 1
                PERFORM OPERAND-START
                MOVE "N" TO WS-SUB-SIMPLE(LS-SUBS)
            END-IF
            ADD 1 TO LS-DEPTH
        WHEN TK-IS-RPAREN(LS-T)
            SUBTRACT 1 FROM LS-DEPTH
            MOVE "Y" TO LS-OPERAND
        WHEN LS-DEPTH > 1
            CONTINUE
        WHEN TK-IS-COLON(LS-T)
            MOVE "Y" TO LS-GIVE-UP
        WHEN TK-IS-OPERATOR(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF (LS-WORD NOT = "+" AND LS-WORD NOT = "-") OR LS-SUBS = 0
                MOVE "Y" TO LS-GIVE-UP
            ELSE
                MOVE "N" TO LS-OPERAND
            END-IF
        WHEN TK-IS-NUMBER(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE TRUE
                WHEN LS-OPERAND = "Y"
                 AND (LS-WORD(1:1) = "+" OR LS-WORD(1:1) = "-")
                    CONTINUE
                *> The offset of IX + 1: still an index-name form.
                WHEN LS-OPERAND = "N" AND LS-SUBS > 0
                    MOVE "Y" TO LS-OPERAND
                WHEN OTHER
                    PERFORM OPERAND-START
                    MOVE "N" TO WS-SUB-SIMPLE(LS-SUBS)
            END-EVALUATE
        WHEN TK-IS-WORD(LS-T)
            PERFORM SUBSCRIPT-WORD
        WHEN OTHER
            MOVE "Y" TO LS-GIVE-UP
    END-EVALUATE.

SUBSCRIPT-WORD.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    EVALUATE TRUE
        WHEN LS-WORD = "IN" OR LS-WORD = "OF"
            MOVE "Y" TO LS-QUALIFIER
            IF LS-SUBS > 0
                MOVE "N" TO WS-SUB-SIMPLE(LS-SUBS)
            END-IF
        WHEN LS-QUALIFIER = "Y"
            MOVE "N" TO LS-QUALIFIER
        WHEN LS-WORD = "FUNCTION" OR LS-WORD = "ALL"
            MOVE "Y" TO LS-GIVE-UP
        WHEN LS-OPERAND = "N" AND LS-SUBS > 0
            *> The second operand of + or -: an expression.
            MOVE "N" TO WS-SUB-SIMPLE(LS-SUBS)
            MOVE "Y" TO LS-OPERAND
        WHEN OTHER
            PERFORM OPERAND-START
            MOVE "Y" TO WS-SUB-SIMPLE(LS-SUBS)
    END-EVALUATE.

*> An operand at depth 1 after another operand (or first) starts a
*> subscript; after an operator it continues the current one.
OPERAND-START.
    IF LS-OPERAND = "N" AND LS-SUBS > 0
        MOVE "N" TO WS-SUB-SIMPLE(LS-SUBS)
        MOVE "Y" TO LS-OPERAND
        EXIT PARAGRAPH
    END-IF
    IF LS-SUBS >= WS-DIM-MAX
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-SUBS
    MOVE LS-T TO WS-SUB-TOKEN(LS-SUBS)
    MOVE "Y" TO LS-OPERAND.

*> Subscript LS-K, an index name: is it an index of the dimension's
*> own table, or of another with entries of the same length?
CHECK-SUBSCRIPT.
    MOVE WS-SUB-TOKEN(LS-K) TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    MOVE WS-DIM(LS-K) TO LS-TABLE
    MOVE 0 TO LS-OTHER
    PERFORM VARYING LS-X FROM 1 BY 1 UNTIL LS-X > WS-IX-COUNT
        IF WS-IX-NAME(LS-X) = LS-WORD
           AND WS-IX-PROGRAM(LS-X) = SY-PROGRAM(LS-TABLE)
            IF WS-IX-TABLE(LS-X) = LS-TABLE
                EXIT PARAGRAPH
            END-IF
            MOVE WS-IX-TABLE(LS-X) TO LS-OTHER
        END-IF
    END-PERFORM
    IF LS-OTHER = 0 OR SY-SIZE(LS-OTHER) = SY-SIZE(LS-TABLE)
        EXIT PARAGRAPH
    END-IF
    MOVE SY-SIZE(LS-OTHER) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SIZE-1 LS-SIZE-1-LEN
    MOVE SY-SIZE(LS-TABLE) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SIZE-2 LS-SIZE-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "index " DELIMITED BY SIZE
           LS-WORD DELIMITED BY SPACE
           " of " DELIMITED BY SIZE
           SY-NAME(LS-OTHER) DELIMITED BY SPACE
           " (" LS-SIZE-1(1:LS-SIZE-1-LEN) "-byte entries) subscripts "
           DELIMITED BY SIZE
           SY-NAME(LS-TABLE) DELIMITED BY SPACE
           " (" LS-SIZE-2(1:LS-SIZE-2-LEN) "-byte entries)"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-T LS-MESSAGE.
END PROGRAM PLB-RULE-C047.
