*> ---------------------------------------------------------------
*> plbafter: does the code after a statement look at a result?
*>
*> PLB-NAMED-AFTER USING TOKENS AST FLOW STMT STOP NAMES FOUND sets
*> FOUND to "Y" when one of NAMES (plbnlist.cpy) is named
*>
*>   - after statement STMT in the paragraph that holds it, before
*>     token STOP (0: to the end of the paragraph), or
*>   - in a paragraph that a PERFORM in that stretch performs (its
*>     whole range, but not the paragraphs that one performs in turn).
*>
*> Rules use it to tell whether a status (FILE STATUS, SQLCODE, a CICS
*> RESP item) is tested after the statement that sets it. A test that
*> is only reached by falling into the next paragraph is not seen.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-NAMED-AFTER.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-STOP                 PIC 9(9) COMP-5.
01  LS-N                    PIC 9(4) COMP-5.
*> SKIP-CALL: the length of the prefix, and the token after CALL.
01  LS-PREFIX-LEN           PIC 9(4) COMP-5.
01  LS-AFTER-CALL           PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbflow.cpy".
COPY "plbnlist.cpy".
01  LK-STMT                 PIC 9(9) COMP-5.
01  LK-STOP                 PIC 9(9) COMP-5.
01  LK-FOUND                PIC X.
PROCEDURE DIVISION USING PLB-TOKENS PLB-AST PLB-FLOW LK-STMT LK-STOP
        PLB-NAME-LIST LK-FOUND.
    MOVE "N" TO LK-FOUND
    PERFORM UNIT-OF-STATEMENT
    IF LS-U = 0 OR NL-COUNT = 0
        GOBACK
    END-IF
    MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO LS-STOP
    IF LK-STOP > 0 AND LK-STOP <= LS-STOP
        COMPUTE LS-STOP = LK-STOP - 1
    END-IF
    COMPUTE LS-T = ND-TOK-LAST(LK-STMT) + 1
    MOVE LS-STOP TO LS-LAST
    PERFORM SCAN-RANGE
    IF LK-FOUND = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-FROM(LS-E) = LS-U
           AND FE-TO(LS-E) > 0
            IF ND-TOK-FIRST(FE-STMT(LS-E)) > ND-TOK-LAST(LK-STMT)
               AND ND-TOK-FIRST(FE-STMT(LS-E)) <= LS-STOP
                PERFORM SCAN-PERFORMED
                IF LK-FOUND = "Y"
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> The tokens of every unit in edge LS-E's range.
SCAN-PERFORMED.
    MOVE FE-TO(LS-E) TO LS-V
    PERFORM UNTIL LS-V = 0 OR LK-FOUND = "Y"
        MOVE ND-TOK-FIRST(FU-NODE(LS-V)) TO LS-T
        MOVE ND-TOK-LAST(FU-NODE(LS-V)) TO LS-LAST
        PERFORM SCAN-RANGE
        IF LS-V = FE-THRU(LS-E) OR FE-THRU(LS-E) = 0
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-V) TO LS-V
    END-PERFORM.

*> LK-FOUND = "Y" when a word from LS-T to LS-LAST is in the list.
SCAN-RANGE.
    PERFORM UNTIL LS-T > LS-LAST OR LK-FOUND = "Y"
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "CALL" AND NL-SKIP-PREFIX NOT = SPACES
                PERFORM SKIP-CALL
            END-IF
            PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > NL-COUNT
                IF LS-TEXT = NL-NAME(LS-N)
                    MOVE "Y" TO LK-FOUND
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> At CALL (token LS-T): when it calls a program whose name starts
*> with NL-SKIP-PREFIX, the range ends here (LS-T moves past LS-LAST),
*> and LS-TEXT is cleared so the word CALL itself matches nothing.
SKIP-CALL.
    COMPUTE LS-PREFIX-LEN = FUNCTION LENGTH(FUNCTION TRIM(NL-SKIP-PREFIX))
    COMPUTE LS-AFTER-CALL = LS-T + 1
    IF NOT TK-IS-ALNUM(LS-AFTER-CALL)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-AFTER-CALL LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT(1:LS-PREFIX-LEN))
       NOT = NL-SKIP-PREFIX(1:LS-PREFIX-LEN)
        MOVE "CALL" TO LS-TEXT
        EXIT PARAGRAPH
    END-IF
    MOVE LS-LAST TO LS-T
    MOVE SPACES TO LS-TEXT.

*> LS-U = the innermost unit (paragraph, else section or division
*> start) whose tokens hold the statement; 0 when none does.
UNIT-OF-STATEMENT.
    MOVE 0 TO LS-U
    PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > FU-COUNT
        IF ND-TOK-FIRST(FU-NODE(LS-V)) <= ND-TOK-FIRST(LK-STMT)
           AND ND-TOK-LAST(FU-NODE(LS-V)) >= ND-TOK-LAST(LK-STMT)
            IF LS-U = 0
                MOVE LS-V TO LS-U
            ELSE
                IF ND-TOK-FIRST(FU-NODE(LS-V))
                   >= ND-TOK-FIRST(FU-NODE(LS-U))
                    MOVE LS-V TO LS-U
                END-IF
            END-IF
        END-IF
    END-PERFORM.
END PROGRAM PLB-NAMED-AFTER.
