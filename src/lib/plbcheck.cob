*> ---------------------------------------------------------------
*> plbcheck: running the analysis rules.
*>
*> PLB-CHECK-RUN runs every enabled rule over one analyzed file: its
*> expanded tokens, syntax tree, symbol table, and procedure graph.
*> Each rule is its own program, named after its rule id.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CHECK-RUN.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-SYMBOLS PLB-FLOW PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-C001" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-FLOW PLB-RULES PLB-FINDINGS
    CALL "PLB-RULE-C002" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-FLOW PLB-RULES PLB-FINDINGS
    CALL "PLB-RULE-C003" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-FLOW PLB-RULES PLB-FINDINGS
    CALL "PLB-RULE-PERFORM-RANGES" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-AST PLB-FLOW PLB-RULES PLB-FINDINGS
    CALL "PLB-RULE-STATEMENTS" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-RULES PLB-FINDINGS
    GOBACK.
END PROGRAM PLB-CHECK-RUN.

*> PLB-C001 unreachable-code: a paragraph or section that no entry
*> point, fall-through, PERFORM, or GO TO reaches. Paragraphs of an
*> unreachable section are covered by the finding for the section.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C001.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C001" LS-RULE
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-REACHED(LS-U) = "N" AND FU-KIND(LS-U) NOT = "D"
            IF FU-SECTION(LS-U) = 0
                PERFORM REPORT-UNIT
            ELSE
                IF FU-REACHED(FU-SECTION(LS-U)) = "Y"
                    PERFORM REPORT-UNIT
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

REPORT-UNIT.
    MOVE SPACES TO LS-MESSAGE
    IF FU-KIND(LS-U) = "S"
        STRING "section " DELIMITED BY SIZE
               FU-NAME(LS-U) DELIMITED BY SPACE
               " is never executed" DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "paragraph " DELIMITED BY SIZE
               FU-NAME(LS-U) DELIMITED BY SPACE
               " is never executed" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    MOVE ND-NAME(FU-NODE(LS-U)) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C001.
