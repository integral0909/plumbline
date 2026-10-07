*> ---------------------------------------------------------------
*> plbrunreach: PLB-C072 unreachable-statement.
*>
*> A statement after one that never lets control reach it: GO TO (not
*> GO TO ... DEPENDING ON, which goes on when the value is out of
*> range), GOBACK, or STOP RUN, in the same list of statements, or in a
*> later sentence of the same paragraph:
*>
*>     IF WS-EOF = "Y"
*>         GO TO 900-FINISH
*>         CLOSE IN-FILE                      never runs
*>     END-IF
*>
*> Control cannot enter a paragraph between its sentences, so the
*> statement is dead. The first statement of each dead stretch is
*> reported. One that is itself GO TO, GOBACK, STOP RUN, EXIT, EXIT
*> PROGRAM, or CONTINUE is not: a second way out written for safety
*> does no harm. Nor is an ENTRY, where a caller comes in, or
*> GnuCOBOL's ENTRY FOR GO TO, where GO TO ENTRY jumps to (neither GO
*> TO of those is taken for a way out).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C072.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEAD                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-ENDS                 PIC X.
01  LS-WHAT                 PIC X(20).
01  LS-ENDED-BY             PIC X(20).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
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
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C072" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT"
            MOVE LS-NODE TO LS-STMT
            PERFORM TEST-ENDS
            IF LS-ENDS = "Y"
                MOVE LS-WHAT TO LS-ENDED-BY
                PERFORM FIND-DEAD
                IF LS-DEAD > 0
                    PERFORM REPORT-DEAD
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-ENDS = "Y" when statement LS-STMT never lets control go on to
*> the next one; LS-WHAT then says which it is.
TEST-ENDS.
    MOVE "N" TO LS-ENDS
    EVALUATE ND-DETAIL(LS-STMT)
        WHEN "GOBACK"
            MOVE "Y" TO LS-ENDS
            MOVE "GOBACK" TO LS-WHAT
        WHEN "STOP"
            COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
            IF LS-T <= ND-TOK-LAST(LS-STMT)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "RUN"
                    MOVE "Y" TO LS-ENDS
                    MOVE "STOP RUN" TO LS-WHAT
                END-IF
            END-IF
        WHEN "GO"
            MOVE "Y" TO LS-ENDS
            MOVE "GO TO" TO LS-WHAT
            PERFORM TEST-ENTRY-GO
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-STMT)
                IF TK-IS-WORD(LS-T)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    IF FUNCTION UPPER-CASE(LS-TEXT) = "DEPENDING"
                        MOVE "N" TO LS-ENDS
                        EXIT PERFORM
                    END-IF
                END-IF
            END-PERFORM
    END-EVALUATE.

*> LS-DEAD: the statement after LS-NODE, in its list or, when the list
*> is a sentence, in the next sentences of the paragraph; 0 when there
*> is none, or it is a way out itself.
FIND-DEAD.
    MOVE 0 TO LS-DEAD
    IF ND-NEXT(LS-NODE) > 0
        MOVE ND-NEXT(LS-NODE) TO LS-DEAD
    ELSE
        IF ND-PARENT(LS-NODE) = 0
            EXIT PARAGRAPH
        END-IF
        IF ND-KIND(ND-PARENT(LS-NODE)) NOT = "SENT"
            EXIT PARAGRAPH
        END-IF
        *> The first statement of a later sentence.
        MOVE ND-NEXT(ND-PARENT(LS-NODE)) TO LS-T
        PERFORM UNTIL LS-T = 0 OR LS-DEAD > 0
            IF ND-KIND(LS-T) NOT = "SENT"
                EXIT PERFORM
            END-IF
            MOVE ND-FIRST(LS-T) TO LS-DEAD
            MOVE ND-NEXT(LS-T) TO LS-T
        END-PERFORM
    END-IF
    IF LS-DEAD = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-DEAD) NOT = "STMT"
        MOVE 0 TO LS-DEAD
        EXIT PARAGRAPH
    END-IF
    MOVE LS-DEAD TO LS-STMT
    PERFORM TEST-ENDS
    IF LS-ENDS = "Y"
       OR ND-DETAIL(LS-DEAD) = "EXIT" OR ND-DETAIL(LS-DEAD) = "CONTINUE"
       OR ND-DETAIL(LS-DEAD) = "ENTRY"
        MOVE 0 TO LS-DEAD
    END-IF.

*> GO TO statement LS-STMT is ENTRY FOR GO TO (the word before it is
*> FOR), or GO TO ENTRY: LS-ENDS = "N".
TEST-ENTRY-GO.
    IF ND-TOK-FIRST(LS-STMT) > 1
        COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) - 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) = "FOR"
            MOVE "N" TO LS-ENDS
            EXIT PARAGRAPH
        END-IF
    END-IF
    *> GO [TO] ENTRY: the statement or the one after it.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-FIRST(LS-STMT) + 2 OR LS-T > TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) = "ENTRY"
            MOVE "N" TO LS-ENDS
            EXIT PARAGRAPH
        END-IF
    END-PERFORM.

REPORT-DEAD.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING ND-DETAIL(LS-DEAD) DELIMITED BY SPACE
           " never runs: it comes after the " DELIMITED BY SIZE
           LS-ENDED-BY DELIMITED BY "  "
           " on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-DEAD) LS-MESSAGE.
END PROGRAM PLB-RULE-C072.
