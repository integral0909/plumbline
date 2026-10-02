*> ---------------------------------------------------------------
*> plbsupp: suppressing findings with comments.
*>
*> A comment containing "plumbline: ignore" suppresses findings:
*>
*>     MOVE X TO Y    *> plumbline: ignore PLB-C001
*>     *> plumbline: ignore unreachable-code, go-to
*>     *> plumbline: ignore
*>
*> The comment applies to findings on its own line, or, when the
*> comment is a line of its own, to findings on the line after it.
*> After "ignore" come rule ids or names, separated by spaces or
*> commas; with none, every rule is suppressed. Case does not matter.
*> ---------------------------------------------------------------

*> PLB-FIND-SUPPRESS: mark suppressed findings.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-SUPPRESS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-SUPPRESSED           PIC X.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-RULES PLB-FINDINGS.
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > FN-COUNT
        MOVE FN-SRC-LINE(LS-F) TO LS-LINE
        IF LS-LINE > 0
            CALL "PLB-SUPPRESSED-BY-LINE" USING PLB-SOURCE-SET
                PLB-RULES FN-RULE(LS-F) LS-LINE LS-SUPPRESSED
            IF LS-SUPPRESSED = "N" AND LS-LINE > 1
                SUBTRACT 1 FROM LS-LINE
                IF SL-FILE-ID(LS-LINE) = FN-FILE-ID(LS-F)
                   AND SL-IS-COMMENT(LS-LINE)
                    CALL "PLB-SUPPRESSED-BY-LINE" USING PLB-SOURCE-SET
                        PLB-RULES FN-RULE(LS-F) LS-LINE LS-SUPPRESSED
                END-IF
            END-IF
            MOVE LS-SUPPRESSED TO FN-SUPPRESSED(LS-F)
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-FIND-SUPPRESS.

*> PLB-SUPPRESSED-BY-LINE: RESULT = "Y" when source line LINE (an
*> SS-LINE index) has a comment that suppresses rule RULE.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SUPPRESSED-BY-LINE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-COMMENT              PIC X(1024).
01  LS-START                PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
01  LS-REST                 PIC X(1024).
01  LS-WORD                 PIC X(40).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ANY                  PIC X.
01  LS-MARKER               PIC X(17) VALUE "PLUMBLINE: IGNORE".
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbrules.cpy".
01  LK-RULE                 PIC 9(4) COMP-5.
01  LK-LINE                 PIC 9(9) COMP-5.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-RULES LK-RULE LK-LINE
        LK-RESULT.
    MOVE "N" TO LK-RESULT
    IF SL-COMMENT-COL(LK-LINE) = 0
        GOBACK
    END-IF
    *> The comment runs from its start to the end of the line.
    MOVE SL-COMMENT-COL(LK-LINE) TO LS-START
    COMPUTE LS-LEN = SL-TEXT-LEN(LK-LINE) - LS-START + 1
    IF LS-LEN < 1
        GOBACK
    END-IF
    MOVE SPACES TO LS-COMMENT
    MOVE SS-HEAP(SL-TEXT-OFF(LK-LINE) + LS-START - 1:LS-LEN)
        TO LS-COMMENT
    MOVE FUNCTION UPPER-CASE(LS-COMMENT) TO LS-COMMENT
    MOVE 0 TO LS-COUNT
    INSPECT LS-COMMENT TALLYING LS-COUNT
        FOR CHARACTERS BEFORE INITIAL "PLUMBLINE: IGNORE"
    IF LS-COUNT >= LS-LEN
        GOBACK
    END-IF
    COMPUTE LS-AT = LS-COUNT + 1 + LENGTH OF LS-MARKER
    MOVE SPACES TO LS-REST
    IF LS-AT <= LENGTH OF LS-COMMENT
        MOVE LS-COMMENT(LS-AT:) TO LS-REST
    END-IF
    INSPECT LS-REST REPLACING ALL "," BY SPACE

    *> No rule named: every rule is suppressed.
    MOVE "N" TO LS-ANY
    MOVE 1 TO LS-PTR
    PERFORM UNTIL LS-PTR > LENGTH OF LS-REST OR LK-RESULT = "Y"
        MOVE SPACES TO LS-WORD
        UNSTRING LS-REST DELIMITED BY ALL SPACE
            INTO LS-WORD WITH POINTER LS-PTR
        END-UNSTRING
        IF LS-WORD NOT = SPACES
            MOVE "Y" TO LS-ANY
            CALL "PLB-RULE-FIND" USING PLB-RULES LS-WORD LS-RULE
            IF LS-RULE = LK-RULE
                MOVE "Y" TO LK-RESULT
            END-IF
        END-IF
    END-PERFORM
    IF LS-ANY = "N"
        MOVE "Y" TO LK-RESULT
    END-IF
    GOBACK.
END PROGRAM PLB-SUPPRESSED-BY-LINE.
