*> ---------------------------------------------------------------
*> plbrsize: rules about the size of paragraphs and sections.
*>
*>   PLB-M009  complex-paragraph  complexity above RL-LIMIT (15)
*>   PLB-M010  long-paragraph     more statements than RL-LIMIT (50)
*>
*> Both use the metrics of plumbline metrics (plbmetr). A section's
*> figures count only the statements before its first paragraph.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SIZE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbmetrc.cpy".
COPY "plbmetr.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE-COMPLEX         PIC 9(4) COMP-5.
01  LS-RULE-LONG            PIC 9(4) COMP-5.
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
        MOVE ND-TOK-FIRST(FU-NODE(MU-UNIT(LS-M))) TO LS-TOKEN
    END-IF
    MOVE SPACES TO LS-MESSAGE.
END PROGRAM PLB-RULE-SIZE.
