*> ---------------------------------------------------------------
*> plbrflow: rules that read the procedure graph.
*>
*>   PLB-C002  perform-and-fall-through
*>   PLB-C003  fall-off-end
*>   PLB-C005  perform-thru-backwards
*>   PLB-C006  recursive-perform
*> ---------------------------------------------------------------

*> PLB-C002 perform-and-fall-through: a paragraph that is the target
*> of a PERFORM and is also entered by falling out of the paragraph
*> before it. When it is performed it returns at its end; when it is
*> fallen into, control runs on into whatever follows. Code written
*> for one of those uses is rarely right for the other.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C002.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-PREVIOUS             PIC 9(9) COMP-5 OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C002" LS-RULE
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE 0 TO WS-PREVIOUS(LS-U)
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-NEXT(LS-U) > 0
            MOVE LS-U TO WS-PREVIOUS(FU-NEXT(LS-U))
        END-IF
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE WS-PREVIOUS(LS-U) TO LS-P
        IF FU-PERFORMED(LS-U) = "Y" AND FU-KIND(LS-U) = "P"
           AND LS-P > 0
            IF FU-FLOWED(LS-P) = "Y" AND FU-FALLS(LS-P) = "Y"
               AND FU-KIND(LS-P) NOT = "S"
                PERFORM REPORT-UNIT
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

REPORT-UNIT.
    MOVE SPACES TO LS-MESSAGE
    STRING "paragraph " DELIMITED BY SIZE
           FU-NAME(LS-U) DELIMITED BY SPACE
           " is performed, but " DELIMITED BY SIZE
           FU-NAME(LS-P) DELIMITED BY SPACE
           " also falls into it" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE ND-NAME(FU-NODE(LS-U)) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C002.

*> PLB-C003 fall-off-end: control can reach the end of a program's
*> procedure division without a STOP RUN, GOBACK, or EXIT PROGRAM.
*> Compilers then end the program implicitly, which is easy to
*> misread and usually means a terminating statement is missing.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C003.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C003" LS-RULE
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-NEXT(LS-U) = 0 AND FU-DECLARATIVE(LS-U) = "N"
           AND FU-FLOWED(LS-U) = "Y" AND FU-FALLS(LS-U) = "Y"
            PERFORM REPORT-UNIT
        END-IF
    END-PERFORM
    GOBACK.

REPORT-UNIT.
    MOVE SPACES TO LS-MESSAGE
    IF FU-NAME(LS-U) = SPACES
        MOVE "control can run off the end of the procedure division"
            TO LS-MESSAGE
    ELSE
        STRING "control can run off the end of the procedure division"
               " after " DELIMITED BY SIZE
               FU-NAME(LS-U) DELIMITED BY SPACE
            INTO LS-MESSAGE
    END-IF
    IF FU-LAST-STMT(LS-U) > 0
        MOVE ND-TOK-FIRST(FU-LAST-STMT(LS-U)) TO LS-TOKEN
    ELSE
        MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO LS-TOKEN
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C003.

*> PLB-C005 perform-thru-backwards and PLB-C006 recursive-perform.
*> Both look at PERFORM ranges. Units are numbered in source order,
*> so a range runs from its target to its last unit by number.
*>
*> C005: PERFORM A THRU B where B comes before A. The range never
*>       reaches B, so the PERFORM runs on to wherever control goes.
*> C006: a PERFORM whose range contains the paragraph it is written
*>       in. COBOL PERFORM is not recursive; the behavior is undefined
*>       and in practice the return address is overwritten.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-PERFORM-RANGES.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE-BACKWARDS       PIC 9(4) COMP-5.
01  LS-RULE-RECURSIVE       PIC 9(4) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C005" LS-RULE-BACKWARDS
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C006" LS-RULE-RECURSIVE
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-TO(LS-E) > 0
           AND FE-THRU(LS-E) > 0
            PERFORM CHECK-EDGE
        END-IF
    END-PERFORM
    GOBACK.

CHECK-EDGE.
    MOVE FE-FROM(LS-E) TO LS-FROM
    MOVE FE-TO(LS-E) TO LS-FIRST
    MOVE ND-NAME(FE-PROC(LS-E)) TO LS-TOKEN
    IF FE-THRU(LS-E) < LS-FIRST
        MOVE SPACES TO LS-MESSAGE
        STRING "PERFORM range ends at " DELIMITED BY SIZE
               FU-NAME(FE-THRU(LS-E)) DELIMITED BY SPACE
               ", which comes before " DELIMITED BY SIZE
               FU-NAME(LS-FIRST) DELIMITED BY SPACE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-BACKWARDS LS-TOKEN
            LS-MESSAGE
        EXIT PARAGRAPH
    END-IF
    *> The range's last unit: a section includes its paragraphs.
    MOVE FE-THRU(LS-E) TO LS-LAST
    IF FU-KIND(LS-LAST) = "S"
        PERFORM UNTIL FU-NEXT(LS-LAST) = 0
            IF FU-SECTION(FU-NEXT(LS-LAST)) NOT = FE-THRU(LS-E)
                EXIT PERFORM
            END-IF
            MOVE FU-NEXT(LS-LAST) TO LS-LAST
        END-PERFORM
    END-IF
    IF LS-FROM >= LS-FIRST AND LS-FROM <= LS-LAST
        MOVE SPACES TO LS-MESSAGE
        STRING FU-NAME(LS-FROM) DELIMITED BY SPACE
               " performs a range that contains itself"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-RECURSIVE LS-TOKEN
            LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-PERFORM-RANGES.
