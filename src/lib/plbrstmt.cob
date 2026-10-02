*> ---------------------------------------------------------------
*> plbrstmt: rules that look at individual statements.
*>
*>   PLB-C004  next-sentence-in-scope
*>   PLB-M001  go-to
*>   PLB-M002  alter
*>   PLB-M011  evaluate-without-other
*>
*> One walk of the syntax tree dispatches each statement to the rules
*> that care about its verb.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-STATEMENTS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE-NEXT-SENTENCE   PIC 9(4) COMP-5.
01  LS-RULE-GO-TO           PIC 9(4) COMP-5.
01  LS-RULE-ALTER           PIC 9(4) COMP-5.
01  LS-RULE-NO-OTHER        PIC 9(4) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C004"
        LS-RULE-NEXT-SENTENCE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M001" LS-RULE-GO-TO
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M002" LS-RULE-ALTER
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M011" LS-RULE-NO-OTHER
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "NEXT SENTENCE"
                    PERFORM CHECK-NEXT-SENTENCE
                WHEN "GO"
                    PERFORM REPORT-GO-TO
                WHEN "ALTER"
                    PERFORM REPORT-ALTER
                WHEN "EVALUATE"
                    PERFORM CHECK-WHEN-OTHER
            END-EVALUATE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> PLB-C004: NEXT SENTENCE continues after the next period, not after
*> the END-IF (or other terminator) of the statement it is in. In code
*> that uses scope terminators that is almost never what was meant;
*> CONTINUE is.
CHECK-NEXT-SENTENCE.
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "SENT"
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-UP) = "STMT"
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-TOK-LAST(LS-UP)
                LS-TEXT LS-LEN
            IF LS-TEXT(1:4) = "END-" AND TK-IS-WORD(ND-TOK-LAST(LS-UP))
                MOVE SPACES TO LS-MESSAGE
                STRING "NEXT SENTENCE skips past " DELIMITED BY SIZE
                       LS-TEXT DELIMITED BY SPACE
                       " to the next period; use CONTINUE"
                       DELIMITED BY SIZE
                    INTO LS-MESSAGE
                MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
                CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET
                    PLB-TOKENS PLB-RULES PLB-FINDINGS
                    LS-RULE-NEXT-SENTENCE LS-TOKEN LS-MESSAGE
                EXIT PERFORM
            END-IF
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> PLB-M001: GO TO makes the flow of control hard to follow; PERFORM
*> and structured statements are usually clearer.
REPORT-GO-TO.
    MOVE "GO TO makes the flow of control hard to follow"
        TO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-GO-TO LS-TOKEN LS-MESSAGE.

*> PLB-M002: ALTER changes the target of a GO TO while the program
*> runs, so the code no longer says where control goes. It was
*> removed from the standard in 2002.
REPORT-ALTER.
    MOVE "ALTER changes GO TO targets at run time and is obsolete"
        TO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-ALTER LS-TOKEN LS-MESSAGE.
*> PLB-M011: an EVALUATE without WHEN OTHER does nothing for a value
*> that no WHEN matches, and says nothing about it either. Shops that
*> want every EVALUATE to say what happens then turn this rule on.
CHECK-WHEN-OTHER.
    IF RL-ENABLED(LS-RULE-NO-OTHER) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "WHEN-OTHER"
            EXIT PARAGRAPH
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    MOVE "EVALUATE has no WHEN OTHER for values no WHEN matches"
        TO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-NO-OTHER LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-STATEMENTS.
