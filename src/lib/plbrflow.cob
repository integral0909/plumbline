*> ---------------------------------------------------------------
*> plbrflow: rules that read the procedure graph.
*>
*>   PLB-C002  perform-and-fall-through
*>   PLB-C003  fall-off-end
*>   PLB-C005  perform-thru-backwards
*>   PLB-C006  recursive-perform
*>   PLB-C029  go-to-leaves-perform
*>   PLB-C054  go-to-into-perform-range
*>   PLB-C035  duplicate-paragraph
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
        *> A method returns at its end; that is how methods end.
        IF FU-NEXT(LS-U) = 0 AND FU-DECLARATIVE(LS-U) = "N"
           AND FU-FLOWED(LS-U) = "Y" AND FU-FALLS(LS-U) = "Y"
           AND ND-DETAIL(FU-PROGRAM(LS-U)) NOT = "METHOD"
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

*> PLB-C029 go-to-leaves-perform: a GO TO in a performed range whose
*> target is outside the range. The PERFORM returns only when control
*> reaches the end of its range, so after such a GO TO it does not
*> return where it was written to, and control runs on from the
*> target instead. A target whose code ends the run (STOP RUN, GOBACK,
*> EXIT PROGRAM, or the end of the program, possibly after falling
*> through other paragraphs) is an abend exit and is not reported. Each
*> GO TO is reported once, for the first PERFORM whose range it
*> leaves.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C029.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-REPORTED             PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-STEPS                PIC 9(9) COMP-5.
01  LS-ENDS-RUN             PIC X.
01  LS-TOKEN                PIC 9(9) COMP-5.
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
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C029" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > FE-COUNT
        MOVE "N" TO WS-REPORTED(LS-G)
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-TO(LS-E) > 0
           AND FE-THRU(LS-E) >= FE-TO(LS-E)
            PERFORM CHECK-RANGE
        END-IF
    END-PERFORM
    GOBACK.

*> The GO TO statements in the range of PERFORM edge LS-E. Units are
*> numbered in source order, and a range that ends at a section runs
*> to the section's last paragraph.
CHECK-RANGE.
    MOVE FE-TO(LS-E) TO LS-FIRST
    MOVE FE-THRU(LS-E) TO LS-LAST
    IF FU-KIND(LS-LAST) = "S"
        PERFORM UNTIL FU-NEXT(LS-LAST) = 0
            IF FU-SECTION(FU-NEXT(LS-LAST)) NOT = FE-THRU(LS-E)
                EXIT PERFORM
            END-IF
            MOVE FU-NEXT(LS-LAST) TO LS-LAST
        END-PERFORM
    END-IF
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > FE-COUNT
        IF FE-KIND(LS-G) = "G" AND FE-TO(LS-G) > 0
           AND WS-REPORTED(LS-G) = "N"
           AND FE-FROM(LS-G) >= LS-FIRST AND FE-FROM(LS-G) <= LS-LAST
           AND (FE-TO(LS-G) < LS-FIRST OR FE-TO(LS-G) > LS-LAST)
            PERFORM CHECK-TARGET
            IF LS-ENDS-RUN = "N"
                MOVE "Y" TO WS-REPORTED(LS-G)
                PERFORM REPORT-GO-TO
            END-IF
        END-IF
    END-PERFORM.

*> LS-ENDS-RUN = "Y" when control that arrives at the target of LS-G
*> falls, unit by unit, into a statement that ends the run, or off
*> the end of the program.
CHECK-TARGET.
    MOVE "N" TO LS-ENDS-RUN
    MOVE FE-TO(LS-G) TO LS-U
    MOVE 0 TO LS-STEPS
    PERFORM UNTIL LS-STEPS > FU-COUNT
        ADD 1 TO LS-STEPS
        IF FU-FALLS(LS-U) = "N"
            IF FU-LAST-STMT(LS-U) > 0
                IF ND-DETAIL(FU-LAST-STMT(LS-U)) NOT = "GO"
                    MOVE "Y" TO LS-ENDS-RUN
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
        IF FU-NEXT(LS-U) = 0
            MOVE "Y" TO LS-ENDS-RUN
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-U) TO LS-U
    END-PERFORM.

REPORT-GO-TO.
    MOVE ND-NAME(FE-PROC(LS-E)) TO LS-TOKEN
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-TOKEN)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "GO TO " DELIMITED BY SIZE
           FU-NAME(FE-TO(LS-G)) DELIMITED BY SPACE
           " leaves the range of the PERFORM of " DELIMITED BY SIZE
           FU-NAME(LS-FIRST) DELIMITED BY SPACE
           " on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", which then does not return" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE ND-NAME(FE-PROC(LS-G)) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C029.

*> PLB-C035 duplicate-paragraph: a paragraph whose name an earlier
*> paragraph of the same section already has (or, outside sections,
*> of the same program), or a section whose name an earlier section of
*> the program has. A reference to the name cannot say which one it
*> means: compilers reject it, or take the first, and the second is
*> then code that never runs.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C035.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The units by name, upper-cased once: a hash of the name picks a
*> bucket, which chains the units added so far, the latest first.
78  UH-BUCKETS                  VALUE 4093.
01  WS-UNIT-HEAD            PIC 9(9) COMP-5 OCCURS UH-BUCKETS TIMES.
01  WS-UNIT-NEXT            PIC 9(9) COMP-5 OCCURS 20000 TIMES.
01  WS-UNIT-NAME            PIC X(31) OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-HASH                 PIC 9(9) COMP-5.
01  LS-HASH-SUM             PIC 9(9) COMP-5.
01  LS-HASH-I               PIC 9(4) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(31).
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
01  LS-PTR                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C035" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR FU-COUNT > 20000
        GOBACK
    END-IF
    PERFORM VARYING LS-HASH FROM 1 BY 1 UNTIL LS-HASH > UH-BUCKETS
        MOVE 0 TO WS-UNIT-HEAD(LS-HASH)
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-KIND(LS-U) = "P" OR FU-KIND(LS-U) = "S"
            MOVE FUNCTION UPPER-CASE(FU-NAME(LS-U)) TO LS-NAME
            MOVE LS-NAME TO WS-UNIT-NAME(LS-U)
            PERFORM NAME-HASH
            PERFORM FIND-EARLIER
            IF LS-V > 0
                PERFORM REPORT-UNIT
            END-IF
            MOVE WS-UNIT-HEAD(LS-HASH) TO WS-UNIT-NEXT(LS-U)
            MOVE LS-U TO WS-UNIT-HEAD(LS-HASH)
        END-IF
    END-PERFORM
    GOBACK.

*> LS-V: the first unit before LS-U of the same kind and name in the
*> same scope, or 0. The chain holds the earlier units, the latest
*> first, so the last match found is the first in the source.
FIND-EARLIER.
    MOVE 0 TO LS-FIRST
    MOVE WS-UNIT-HEAD(LS-HASH) TO LS-V
    PERFORM UNTIL LS-V = 0
        IF FU-PROGRAM(LS-V) = FU-PROGRAM(LS-U)
           AND FU-KIND(LS-V) = FU-KIND(LS-U)
           AND WS-UNIT-NAME(LS-V) = LS-NAME
            IF FU-KIND(LS-U) = "S"
               OR FU-SECTION(LS-V) = FU-SECTION(LS-U)
                MOVE LS-V TO LS-FIRST
            END-IF
        END-IF
        MOVE WS-UNIT-NEXT(LS-V) TO LS-V
    END-PERFORM
    MOVE LS-FIRST TO LS-V.

*> LS-HASH: the bucket of LS-NAME, 1 to UH-BUCKETS.
NAME-HASH.
    MOVE 0 TO LS-HASH-SUM
    PERFORM VARYING LS-HASH-I FROM 1 BY 1 UNTIL LS-HASH-I > 31
        IF LS-NAME(LS-HASH-I:1) = SPACE
            EXIT PERFORM
        END-IF
        COMPUTE LS-HASH-SUM = FUNCTION MOD(LS-HASH-SUM * 31
            + FUNCTION ORD(LS-NAME(LS-HASH-I:1)), UH-BUCKETS)
    END-PERFORM
    COMPUTE LS-HASH = LS-HASH-SUM + 1.

REPORT-UNIT.
    MOVE ND-NAME(FU-NODE(LS-V)) TO LS-TOKEN
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-TOKEN)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    IF FU-KIND(LS-U) = "S"
        STRING "section " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING "paragraph " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING FU-NAME(LS-U) DELIMITED BY SPACE
           " is already defined on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF FU-KIND(LS-U) = "P" AND FU-SECTION(LS-U) > 0
        STRING " of section " DELIMITED BY SIZE
               FU-NAME(FU-SECTION(LS-U)) DELIMITED BY SPACE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    MOVE ND-NAME(FU-NODE(LS-U)) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C035.

*> PLB-C054 go-to-into-perform-range: a GO TO from outside a PERFORM
*> ... THRU range to a paragraph inside it, after its first:
*>
*>     PERFORM 2000-EDIT THRU 2000-EXIT
*>     ...
*>     GO TO 2100-EDIT-AMOUNT        *> inside 2000-EDIT ... 2000-EXIT
*>
*> Control that arrives that way reaches the end of the range with no
*> PERFORM to return to, and runs on into the paragraphs after it; if a
*> PERFORM of the range is active at the time, it returns to that
*> PERFORM's caller instead. Either way the jump starts code that was
*> written to run only as part of the range. Each GO TO is reported
*> once, for the first range it enters.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C054.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-REPORTED             PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-O                    PIC 9(9) COMP-5.
01  LS-WITHIN               PIC X.
01  LS-TOKEN                PIC 9(9) COMP-5.
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
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C054" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > FE-COUNT
        MOVE "N" TO WS-REPORTED(LS-G)
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-TO(LS-E) > 0
           AND FE-THRU(LS-E) > FE-TO(LS-E)
            PERFORM CHECK-RANGE
        END-IF
    END-PERFORM
    GOBACK.

*> The GO TO statements from outside the range of PERFORM edge LS-E to
*> a unit inside it after the first. As in PLB-C029, a range that ends
*> at a section runs to the section's last paragraph.
CHECK-RANGE.
    MOVE FE-TO(LS-E) TO LS-FIRST
    MOVE FE-THRU(LS-E) TO LS-LAST
    IF FU-KIND(LS-LAST) = "S"
        PERFORM UNTIL FU-NEXT(LS-LAST) = 0
            IF FU-SECTION(FU-NEXT(LS-LAST)) NOT = FE-THRU(LS-E)
                EXIT PERFORM
            END-IF
            MOVE FU-NEXT(LS-LAST) TO LS-LAST
        END-PERFORM
    END-IF
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > FE-COUNT
        IF FE-KIND(LS-G) = "G" AND FE-TO(LS-G) > 0
           AND WS-REPORTED(LS-G) = "N"
           AND FE-TO(LS-G) > LS-FIRST AND FE-TO(LS-G) <= LS-LAST
           AND (FE-FROM(LS-G) < LS-FIRST OR FE-FROM(LS-G) > LS-LAST)
           AND FU-PROGRAM(FE-FROM(LS-G)) = FU-PROGRAM(LS-FIRST)
            PERFORM WITHIN-OTHER-RANGE
            IF LS-WITHIN = "N"
                MOVE "Y" TO WS-REPORTED(LS-G)
                PERFORM REPORT-GO-TO
            END-IF
        END-IF
    END-PERFORM.

*> LS-WITHIN = "Y" when some PERFORM range holds both the GO TO and
*> its target: a jump within that range, as when two ranges share an
*> exit paragraph (PERFORM A THRU A-EXIT and PERFORM A2 THRU A-EXIT,
*> with A going to A-EXIT).
WITHIN-OTHER-RANGE.
    MOVE "N" TO LS-WITHIN
    PERFORM VARYING LS-O FROM 1 BY 1 UNTIL LS-O > FE-COUNT
        IF FE-KIND(LS-O) = "P" AND FE-TO(LS-O) > 0
           AND FE-THRU(LS-O) >= FE-TO(LS-O)
           AND FE-FROM(LS-G) >= FE-TO(LS-O)
           AND FE-FROM(LS-G) <= FE-THRU(LS-O)
           AND FE-TO(LS-G) >= FE-TO(LS-O)
           AND FE-TO(LS-G) <= FE-THRU(LS-O)
            MOVE "Y" TO LS-WITHIN
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-GO-TO.
    MOVE ND-NAME(FE-PROC(LS-E)) TO LS-TOKEN
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-TOKEN)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "GO TO " DELIMITED BY SIZE
           FU-NAME(FE-TO(LS-G)) DELIMITED BY SPACE
           " enters the middle of the range " DELIMITED BY SIZE
           FU-NAME(LS-FIRST) DELIMITED BY SPACE
           " THRU " DELIMITED BY SIZE
           FU-NAME(FE-THRU(LS-E)) DELIMITED BY SPACE
           " performed on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE ND-NAME(FE-PROC(LS-G)) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C054.
