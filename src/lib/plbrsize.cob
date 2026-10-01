*> ---------------------------------------------------------------
*> plbrsize: rules about the size of paragraphs and sections.
*>
*>   PLB-M009  complex-paragraph  complexity above RL-LIMIT (15)
*>   PLB-M010  long-paragraph     more statements than RL-LIMIT (50)
*>   PLB-M012  deep-nesting       statements nested deeper than
*>                                RL-LIMIT (5)
*>
*> M009 and M010 use the metrics of plumbline metrics (plbmetr). A
*> section's figures count only the statements before its first
*> paragraph.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SIZE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbmetrc.cpy".
COPY "plbmetr.cpy".
LOCAL-STORAGE SECTION.
*> Holds an index taken from another table: GnuCOBOL 3.2 built with
*> -fec=EC-BOUND-SUBSCRIPT miscompiles a subscript nested two deep.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-RULE-COMPLEX         PIC 9(4) COMP-5.
01  LS-RULE-LONG            PIC 9(4) COMP-5.
01  LS-RULE-NESTING         PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-LEVEL                PIC 9(9) COMP-5.
01  LS-TOP                  PIC 9(9) COMP-5.
01  LS-DEEPEST              PIC 9(9) COMP-5.
01  LS-M                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-KIND                 PIC X(10).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-VALUE-TEXT           PIC X(20).
01  LS-VALUE-LEN            PIC 9(9) COMP-5.
01  LS-LIMIT-TEXT           PIC X(20).
01  LS-LIMIT-LEN            PIC 9(9) COMP-5.
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
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-FLOW PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M009" LS-RULE-COMPLEX
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M010" LS-RULE-LONG
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M012" LS-RULE-NESTING
    IF RL-ENABLED(LS-RULE-NESTING) = "Y" AND RL-LIMIT(LS-RULE-NESTING) > 0
       AND AS-COUNT > 0
        PERFORM CHECK-NESTING
    END-IF
    IF RL-ENABLED(LS-RULE-COMPLEX) NOT = "Y"
       AND RL-ENABLED(LS-RULE-LONG) NOT = "Y"
        GOBACK
    END-IF
    CALL "PLB-METRICS-COMPUTE" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-SYMBOLS PLB-FLOW PLB-METRICS
    PERFORM VARYING LS-M FROM 1 BY 1 UNTIL LS-M > MU-COUNT
        IF MU-COMPLEXITY(LS-M) > RL-LIMIT(LS-RULE-COMPLEX)
           AND RL-LIMIT(LS-RULE-COMPLEX) > 0
            MOVE MU-COMPLEXITY(LS-M) TO LS-NUM
            MOVE RL-LIMIT(LS-RULE-COMPLEX) TO LS-LIMIT-LEN
            PERFORM DESCRIBE
            STRING LS-KIND DELIMITED BY SPACE
                   " " DELIMITED BY SIZE
                   MU-NAME(LS-M) DELIMITED BY SPACE
                   " has complexity " DELIMITED BY SIZE
                   LS-VALUE-TEXT(1:LS-VALUE-LEN) DELIMITED BY SIZE
                   " (limit " DELIMITED BY SIZE
                   LS-LIMIT-TEXT(1:LS-LIMIT-LEN) DELIMITED BY SIZE
                   ")" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-COMPLEX LS-TOKEN LS-MESSAGE
        END-IF
        IF MU-STATEMENTS(LS-M) > RL-LIMIT(LS-RULE-LONG)
           AND RL-LIMIT(LS-RULE-LONG) > 0
            MOVE MU-STATEMENTS(LS-M) TO LS-NUM
            MOVE RL-LIMIT(LS-RULE-LONG) TO LS-LIMIT-LEN
            PERFORM DESCRIBE
            STRING LS-KIND DELIMITED BY SPACE
                   " " DELIMITED BY SIZE
                   MU-NAME(LS-M) DELIMITED BY SPACE
                   " has " DELIMITED BY SIZE
                   LS-VALUE-TEXT(1:LS-VALUE-LEN) DELIMITED BY SIZE
                   " statements (limit " DELIMITED BY SIZE
                   LS-LIMIT-TEXT(1:LS-LIMIT-LEN) DELIMITED BY SIZE
                   ")" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-LONG LS-TOKEN LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.

*> PLB-M012: for each statement that no other statement contains, the
*> deepest level of statements inside it; a statement inside an IF
*> inside an IF is at level 2. The tree is walked in order, so all of
*> a statement's descendants come before the next outermost statement.
CHECK-NESTING.
    MOVE 0 TO LS-TOP LS-DEEPEST
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
            MOVE 0 TO LS-LEVEL
            MOVE ND-PARENT(LS-NODE) TO LS-UP
            PERFORM UNTIL LS-UP = 0
                IF ND-KIND(LS-UP) = "STMT"
                    ADD 1 TO LS-LEVEL
                END-IF
                IF ND-KIND(LS-UP) = "PARA" OR ND-KIND(LS-UP) = "SECT"
                   OR ND-KIND(LS-UP) = "DIVN"
                    EXIT PERFORM
                END-IF
                MOVE ND-PARENT(LS-UP) TO LS-UP
            END-PERFORM
            IF LS-LEVEL = 0
                PERFORM REPORT-NESTING
                MOVE LS-NODE TO LS-TOP
                MOVE 0 TO LS-DEEPEST
            ELSE
                IF LS-LEVEL > LS-DEEPEST
                    MOVE LS-LEVEL TO LS-DEEPEST
                END-IF
            END-IF
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM REPORT-NESTING.

*> The finding for outermost statement LS-TOP, when the statements in
*> it go deeper than the limit.
REPORT-NESTING.
    IF LS-TOP = 0 OR LS-DEEPEST <= RL-LIMIT(LS-RULE-NESTING)
        EXIT PARAGRAPH
    END-IF
    MOVE LS-DEEPEST TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-VALUE-TEXT LS-VALUE-LEN
    MOVE RL-LIMIT(LS-RULE-NESTING) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-LIMIT-TEXT LS-LIMIT-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING ND-DETAIL(LS-TOP) DELIMITED BY SPACE
           " nests statements " DELIMITED BY SIZE
           LS-VALUE-TEXT(1:LS-VALUE-LEN) DELIMITED BY SIZE
           " levels deep (limit " DELIMITED BY SIZE
           LS-LIMIT-TEXT(1:LS-LIMIT-LEN) DELIMITED BY SIZE
           ")" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-TOP) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-NESTING LS-TOKEN LS-MESSAGE.

*> Text of the value (LS-NUM) and limit (in LS-LIMIT-LEN on entry),
*> what the unit is, and the token to report at.
DESCRIBE.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-VALUE-TEXT LS-VALUE-LEN
    MOVE LS-LIMIT-LEN TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-LIMIT-TEXT LS-LIMIT-LEN
    EVALUATE MU-KIND(LS-M)
        WHEN "S"     MOVE "section" TO LS-KIND
        WHEN "P"     MOVE "paragraph" TO LS-KIND
        WHEN OTHER   MOVE "code" TO LS-KIND
    END-EVALUATE
    MOVE MU-NAME-TOKEN(LS-M) TO LS-TOKEN
    IF LS-TOKEN = 0
        MOVE MU-UNIT(LS-M) TO LS-UNIT
        MOVE ND-TOK-FIRST(FU-NODE(LS-UNIT)) TO LS-TOKEN
    END-IF
    MOVE SPACES TO LS-MESSAGE.
END PROGRAM PLB-RULE-SIZE.
