*> ---------------------------------------------------------------
*> plbfix: fixes for findings that have one obvious repair.
*>
*> PLB-FIX-FINDING USING SOURCE TOKENS AST RULES FINDINGS INDEX FIX
*> sets FIX (plbfix.cpy) to the fix for finding INDEX, or to none:
*>
*>   PLB-C004  CONTINUE in place of NEXT SENTENCE, in the case NEXT
*>             was written in
*>   PLB-C071  each AND of the contradictory condition made OR, or
*>             each OR made AND, in the case each was written in
*>   PLB-C074  the two ends of the reversed THRU range swapped, as
*>             written
*>
*> The finding's lines must still be loaded, and every token the fix
*> touches must be in the finding's file (not brought in by a COPY)
*> and on one line. The language server offers these fixes as quick
*> fixes; plumbline fix applies them.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIX-FINDING.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-LOW                  PIC 9(9) COMP-5.
01  LS-HIGH                 PIC 9(9) COMP-5.
01  LS-OTHER                PIC 9(9) COMP-5.
01  LS-OK                   PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-JOIN                 PIC X(3).
01  LS-JOIN-TO              PIC X(3).
01  LS-NEW                  PIC X(256).
01  LS-NEW-LEN              PIC 9(9) COMP-5.
01  LS-FIRST-CHAR           PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-FINDING              PIC 9(9) COMP-5.
COPY "plbfix.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS LK-FINDING PLB-FIX.
    MOVE SPACES TO FX-TITLE
    MOVE 0 TO FX-EDIT-COUNT
    IF LK-FINDING = 0 OR LK-FINDING > FN-COUNT
        GOBACK
    END-IF
    IF FN-SRC-LINE(LK-FINDING) = 0
        GOBACK
    END-IF
    *> The token the finding is reported at.
    MOVE 0 TO LS-TOKEN
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > TK-COUNT
        IF TK-SRC-LINE(LS-T) = FN-SRC-LINE(LK-FINDING)
           AND TK-COLUMN(LS-T) = FN-COLUMN(LK-FINDING)
            MOVE LS-T TO LS-TOKEN
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-TOKEN = 0
        GOBACK
    END-IF
    EVALUATE RL-ID(FN-RULE(LK-FINDING))
        WHEN "PLB-C004"
            PERFORM FIX-NEXT-SENTENCE
        WHEN "PLB-C071"
            PERFORM FIX-CONTRADICTION
        WHEN "PLB-C074"
            PERFORM FIX-REVERSED-RANGE
    END-EVALUATE
    IF FX-EDIT-COUNT = 0
        MOVE SPACES TO FX-TITLE
    END-IF
    GOBACK.

*> PLB-C004: NEXT at LS-TOKEN, SENTENCE after it.
FIX-NEXT-SENTENCE.
    IF LS-TOKEN >= TK-COUNT
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-HIGH = LS-TOKEN + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-HIGH LS-TEXT LS-LEN
    IF LS-TEXT NOT = "SENTENCE"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TOKEN TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-HIGH TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE "Change NEXT SENTENCE to CONTINUE" TO FX-TITLE
    MOVE LS-TOKEN TO LS-T
    PERFORM FIRST-CHARACTER
    IF LS-FIRST-CHAR IS ALPHABETIC-LOWER
        MOVE "continue" TO LS-NEW
    ELSE
        MOVE "CONTINUE" TO LS-NEW
    END-IF
    MOVE 8 TO LS-NEW-LEN
    MOVE LS-TOKEN TO LS-LOW
    PERFORM ADD-EDIT.

*> PLB-C071: the innermost condition holding LS-TOKEN, from there to
*> its end; its join is its first AND or OR.
FIX-CONTRADICTION.
    MOVE 0 TO LS-COND
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "COND"
           AND ND-TOK-FIRST(LS-NODE) <= LS-TOKEN
           AND ND-TOK-LAST(LS-NODE) >= LS-TOKEN
            IF LS-COND = 0
                MOVE LS-NODE TO LS-COND
            ELSE
                IF ND-TOK-LAST(LS-NODE) - ND-TOK-FIRST(LS-NODE)
                   < ND-TOK-LAST(LS-COND) - ND-TOK-FIRST(LS-COND)
                    MOVE LS-NODE TO LS-COND
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF LS-COND = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-JOIN
    PERFORM VARYING LS-T FROM LS-TOKEN BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND) OR LS-JOIN NOT = SPACES
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "AND" OR LS-TEXT = "OR"
                MOVE LS-TEXT TO LS-JOIN
            END-IF
        END-IF
    END-PERFORM
    IF LS-JOIN = SPACES
        EXIT PARAGRAPH
    END-IF
    IF LS-JOIN = "AND"
        MOVE "OR" TO LS-JOIN-TO
    ELSE
        MOVE "AND" TO LS-JOIN-TO
    END-IF
    *> Every join must be one the fix can change.
    PERFORM VARYING LS-T FROM LS-TOKEN BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = LS-JOIN
                PERFORM TEST-TOKEN
                IF LS-OK = "N"
                    MOVE 0 TO FX-EDIT-COUNT
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    MOVE SPACES TO FX-TITLE
    STRING "Change " DELIMITED BY SIZE
           LS-JOIN DELIMITED BY SPACE
           " to " DELIMITED BY SIZE
           LS-JOIN-TO DELIMITED BY SPACE
           " in this condition" DELIMITED BY SIZE
        INTO FX-TITLE
    PERFORM VARYING LS-T FROM LS-TOKEN BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = LS-JOIN AND FX-EDIT-COUNT < FX-EDIT-MAX
                PERFORM FIRST-CHARACTER
                IF LS-FIRST-CHAR IS ALPHABETIC-LOWER
                    MOVE FUNCTION LOWER-CASE(LS-JOIN-TO) TO LS-NEW
                ELSE
                    MOVE LS-JOIN-TO TO LS-NEW
                END-IF
                MOVE 0 TO LS-NEW-LEN
                INSPECT LS-JOIN-TO TALLYING LS-NEW-LEN
                    FOR CHARACTERS BEFORE SPACE
                MOVE LS-T TO LS-LOW
                MOVE LS-T TO LS-HIGH
                PERFORM ADD-EDIT
            END-IF
        END-IF
    END-PERFORM.

*> PLB-C074: the range LS-TOKEN THRU (or THROUGH) the token after.
FIX-REVERSED-RANGE.
    IF LS-TOKEN + 2 > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = LS-TOKEN + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT NOT = "THRU" AND LS-TEXT NOT = "THROUGH"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TOKEN TO LS-LOW
    COMPUTE LS-HIGH = LS-TOKEN + 2
    MOVE LS-LOW TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-HIGH TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE "Swap the ends of this range" TO FX-TITLE
    *> The low end gets the high end's text, and the other way round.
    MOVE LS-HIGH TO LS-OTHER
    MOVE LS-HIGH TO LS-T
    PERFORM TOKEN-AS-WRITTEN
    MOVE LS-LOW TO LS-HIGH
    PERFORM ADD-EDIT
    MOVE LS-LOW TO LS-T
    PERFORM TOKEN-AS-WRITTEN
    MOVE LS-OTHER TO LS-LOW LS-HIGH
    PERFORM ADD-EDIT.

*> LS-OK = "Y" when token LS-T is in the finding's file, written
*> there (not brought in by a COPY), and on one line.
TEST-TOKEN.
    MOVE "N" TO LS-OK
    IF TK-FILE-ID(LS-T) NOT = FN-FILE-ID(LK-FINDING)
       OR TK-INCL(LS-T) NOT = 0 OR TK-SRC-LINE(LS-T) = 0
       OR TK-SPAN(LS-T) > 256
        EXIT PARAGRAPH
    END-IF
    IF TK-COLUMN(LS-T) - 1 + TK-SPAN(LS-T)
       > SL-TEXT-LEN(TK-SRC-LINE(LS-T))
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-OK.

*> LS-FIRST-CHAR: the first character of token LS-T as written.
FIRST-CHARACTER.
    MOVE SS-HEAP(SL-TEXT-OFF(TK-SRC-LINE(LS-T)) + TK-COLUMN(LS-T) - 1:1)
        TO LS-FIRST-CHAR.

*> LS-NEW: token LS-T as written.
TOKEN-AS-WRITTEN.
    MOVE SPACES TO LS-NEW
    MOVE SS-HEAP(SL-TEXT-OFF(TK-SRC-LINE(LS-T)) + TK-COLUMN(LS-T) - 1
                 :TK-SPAN(LS-T)) TO LS-NEW
    MOVE TK-SPAN(LS-T) TO LS-NEW-LEN.

*> An edit putting LS-NEW(1:LS-NEW-LEN) from the start of token LS-LOW
*> to the end of token LS-HIGH.
ADD-EDIT.
    IF FX-EDIT-COUNT >= FX-EDIT-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO FX-EDIT-COUNT
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-LOW)) TO FX-LINE(FX-EDIT-COUNT)
    MOVE TK-COLUMN(LS-LOW) TO FX-COLUMN(FX-EDIT-COUNT)
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-HIGH)) TO FX-END-LINE(FX-EDIT-COUNT)
    COMPUTE FX-END-COLUMN(FX-EDIT-COUNT)
        = TK-COLUMN(LS-HIGH) + TK-SPAN(LS-HIGH)
    MOVE LS-NEW TO FX-TEXT(FX-EDIT-COUNT)
    MOVE LS-NEW-LEN TO FX-TEXT-LEN(FX-EDIT-COUNT).
END PROGRAM PLB-FIX-FINDING.
