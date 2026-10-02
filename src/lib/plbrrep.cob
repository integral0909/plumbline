*> ---------------------------------------------------------------
*> plbrrep: rules about Report Writer reports.
*>
*>   PLB-C016  report-not-initiated
*>   PLB-C017  report-not-terminated
*>   PLB-M007  detail-never-generated
*>
*> A report (RD) is produced by INITIATE report, then GENERATE (of a
*> detail group, or of the report for summary reporting), and ends
*> with TERMINATE report, which prints the final control footings.
*> These rules look at which reports and groups each statement names
*> in the program, in any order; they do not follow the flow of
*> control.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-REPORTS.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  RP-MAX                  VALUE 256.
78  DG-MAX                  VALUE 2048.
*> The reports of the program being checked.
01  WS-REPORTS.
    05  WS-REPORT-COUNT     PIC 9(4) COMP-5.
    05  WS-REPORT           OCCURS RP-MAX TIMES.
        10  RP-NAME         PIC X(31).
        10  RP-NAME-TOKEN   PIC 9(9) COMP-5.
        10  RP-INITIATED    PIC X.
        10  RP-TERMINATED   PIC X.
        10  RP-GENERATED    PIC X.
*> Their detail groups that have names.
01  WS-DETAILS.
    05  WS-DETAIL-COUNT     PIC 9(4) COMP-5.
    05  WS-DETAIL           OCCURS DG-MAX TIMES.
        10  DG-NAME         PIC X(31).
        10  DG-NAME-TOKEN   PIC 9(9) COMP-5.
        10  DG-REPORT       PIC 9(4) COMP-5.
        10  DG-GENERATED    PIC X.
LOCAL-STORAGE SECTION.
01  LS-RULE-INITIATED       PIC 9(4) COMP-5.
01  LS-RULE-TERMINATED      PIC 9(4) COMP-5.
01  LS-RULE-GENERATED       PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(4) COMP-5.
01  LS-G                    PIC 9(4) COMP-5.
01  LS-PASS                 PIC 9.
01  LS-VERB                 PIC X(20).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-KW                   PIC X.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C016" LS-RULE-INITIATED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C017" LS-RULE-TERMINATED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M007" LS-RULE-GENERATED
    IF AS-COUNT = 0
        GOBACK
    END-IF
    *> Each program on its own: its reports, then its statements.
    MOVE 1 TO LS-NODE
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "PROG"
            MOVE LS-NODE TO LS-PROGRAM
            PERFORM CHECK-PROGRAM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

CHECK-PROGRAM.
    MOVE 0 TO WS-REPORT-COUNT WS-DETAIL-COUNT
    *> Pass 1 finds the reports and groups, pass 2 the statements.
    PERFORM VARYING LS-PASS FROM 1 BY 1 UNTIL LS-PASS > 2
        PERFORM VARYING LS-CHILD FROM LS-PROGRAM BY 1
                UNTIL LS-CHILD > AS-COUNT
            IF ND-TOK-FIRST(LS-CHILD) > ND-TOK-LAST(LS-PROGRAM)
                EXIT PERFORM
            END-IF
            PERFORM CHECK-NODE
        END-PERFORM
    END-PERFORM
    IF WS-REPORT-COUNT > 0
        PERFORM REPORT-FINDINGS
    END-IF.

*> Node LS-CHILD of program LS-PROGRAM, in pass LS-PASS. Nodes of
*> programs nested in it belong to those programs.
CHECK-NODE.
    IF ND-KIND(LS-CHILD) = "PROG" AND LS-CHILD NOT = LS-PROGRAM
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN LS-PASS = 1 AND ND-KIND(LS-CHILD) = "FD"
             AND ND-DETAIL(LS-CHILD) = "RD"
            PERFORM ADD-REPORT
        WHEN LS-PASS = 1 AND ND-KIND(LS-CHILD) = "DATA"
             AND ND-NUM(LS-CHILD) = 1
            PERFORM CHECK-DETAIL-GROUP
        WHEN LS-PASS = 2 AND ND-KIND(LS-CHILD) = "STMT"
            MOVE ND-DETAIL(LS-CHILD) TO LS-VERB
            IF LS-VERB = "INITIATE" OR LS-VERB = "GENERATE"
               OR LS-VERB = "TERMINATE"
                PERFORM REPORT-STATEMENT
            END-IF
    END-EVALUATE.

ADD-REPORT.
    IF WS-REPORT-COUNT >= RP-MAX OR ND-NAME(LS-CHILD) = 0
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-REPORT-COUNT
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-CHILD)
        RP-NAME(WS-REPORT-COUNT) LS-LEN
    MOVE ND-NAME(LS-CHILD) TO RP-NAME-TOKEN(WS-REPORT-COUNT)
    MOVE "N" TO RP-INITIATED(WS-REPORT-COUNT)
        RP-TERMINATED(WS-REPORT-COUNT) RP-GENERATED(WS-REPORT-COUNT).

*> An 01 entry under an RD with TYPE DETAIL (or DE) and a name.
CHECK-DETAIL-GROUP.
    IF ND-KIND(ND-PARENT(LS-CHILD)) NOT = "FD"
       OR ND-DETAIL(ND-PARENT(LS-CHILD)) NOT = "RD"
       OR ND-NAME(LS-CHILD) = 0 OR WS-DETAIL-COUNT >= DG-MAX
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-CHILD) TO LS-NODE
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "CLAU" AND ND-DETAIL(LS-NODE) = "TYPE"
           AND ND-NAME(LS-NODE) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE)
                LS-TEXT LS-LEN
            IF LS-TEXT = "DETAIL" OR LS-TEXT = "DE"
                ADD 1 TO WS-DETAIL-COUNT
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-CHILD)
                    DG-NAME(WS-DETAIL-COUNT) LS-LEN
                MOVE ND-NAME(LS-CHILD) TO DG-NAME-TOKEN(WS-DETAIL-COUNT)
                MOVE WS-REPORT-COUNT TO DG-REPORT(WS-DETAIL-COUNT)
                MOVE "N" TO DG-GENERATED(WS-DETAIL-COUNT)
            END-IF
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-NODE) TO LS-NODE
    END-PERFORM
    *> Leave LS-NODE as the walk in the main line expects it.
    MOVE LS-PROGRAM TO LS-NODE.

*> INITIATE report..., GENERATE group-or-report, TERMINATE report...
*> The words after the verb (other than reserved words, and the
*> qualifier after IN or OF) name reports or groups.
REPORT-STATEMENT.
    COMPUTE LS-T = ND-TOK-FIRST(LS-CHILD) + 1
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "IN" OR LS-TEXT = "OF"
                ADD 1 TO LS-T
            ELSE
                CALL "PLB-KW-LOOKUP" USING LS-TEXT LS-KW
                IF LS-KW = SPACE
                    PERFORM STATEMENT-OPERAND
                END-IF
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> Name LS-TEXT at token LS-T, operand of LS-VERB.
STATEMENT-OPERAND.
    MOVE 0 TO LS-R
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > WS-REPORT-COUNT
        IF RP-NAME(LS-G) = LS-TEXT
            MOVE LS-G TO LS-R
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-R = 0 AND LS-VERB = "GENERATE"
        PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > WS-DETAIL-COUNT
            IF DG-NAME(LS-G) = LS-TEXT
                MOVE "Y" TO DG-GENERATED(LS-G)
                MOVE DG-REPORT(LS-G) TO LS-R
                EXIT PERFORM
            END-IF
        END-PERFORM
        IF LS-R = 0
            EXIT PARAGRAPH
        END-IF
        PERFORM GENERATED-BEFORE-INITIATE
        EXIT PARAGRAPH
    END-IF
    IF LS-R = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE LS-VERB
        WHEN "INITIATE"
            MOVE "Y" TO RP-INITIATED(LS-R)
        WHEN "TERMINATE"
            MOVE "Y" TO RP-TERMINATED(LS-R)
            PERFORM GENERATED-BEFORE-INITIATE
        WHEN "GENERATE"
            MOVE "Y" TO RP-GENERATED(LS-R)
            PERFORM GENERATED-BEFORE-INITIATE
    END-EVALUATE.

*> PLB-C016: report LS-R is used at token LS-T but no INITIATE in the
*> program names it. An INITIATE may come later in the source, so all
*> of them are looked at.
GENERATED-BEFORE-INITIATE.
    IF RL-ENABLED(LS-RULE-INITIATED) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-INITIATE
    IF RP-INITIATED(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "report " DELIMITED BY SIZE
           RP-NAME(LS-R) DELIMITED BY SPACE
           " is used by " DELIMITED BY SIZE
           LS-VERB DELIMITED BY SPACE
           ", but no INITIATE starts it" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-INITIATED LS-T LS-MESSAGE.

*> Set RP-INITIATED(LS-R) when any INITIATE in the program names the
*> report, wherever it is.
FIND-INITIATE.
    IF RP-INITIATED(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-NODE FROM LS-PROGRAM BY 1
            UNTIL LS-NODE > AS-COUNT
        IF ND-TOK-FIRST(LS-NODE) > ND-TOK-LAST(LS-PROGRAM)
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "INITIATE"
            PERFORM INITIATE-NAMES-REPORT
            IF RP-INITIATED(LS-R) = "Y"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    MOVE LS-PROGRAM TO LS-NODE.

INITIATE-NAMES-REPORT.
    PERFORM VARYING LS-K FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-K > ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-K)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
            IF LS-TEXT = RP-NAME(LS-R)
                MOVE "Y" TO RP-INITIATED(LS-R)
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> PLB-C017 and PLB-M007, once every statement has been seen.
REPORT-FINDINGS.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > WS-REPORT-COUNT
        IF RP-INITIATED(LS-R) = "Y" AND RP-TERMINATED(LS-R) = "N"
            MOVE SPACES TO LS-MESSAGE
            STRING "report " DELIMITED BY SIZE
                   RP-NAME(LS-R) DELIMITED BY SPACE
                   " is initiated but never terminated, so its final"
                   DELIMITED BY SIZE
                   " footings are not printed" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-TERMINATED
                RP-NAME-TOKEN(LS-R) LS-MESSAGE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > WS-DETAIL-COUNT
        MOVE DG-REPORT(LS-G) TO LS-R
        IF DG-GENERATED(LS-G) = "N" AND LS-R > 0
            IF RP-GENERATED(LS-R) = "N"
                MOVE SPACES TO LS-MESSAGE
                STRING "detail group " DELIMITED BY SIZE
                       DG-NAME(LS-G) DELIMITED BY SPACE
                       " is never generated" DELIMITED BY SIZE
                    INTO LS-MESSAGE
                CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                    PLB-RULES PLB-FINDINGS LS-RULE-GENERATED
                    DG-NAME-TOKEN(LS-G) LS-MESSAGE
            END-IF
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-REPORTS.
