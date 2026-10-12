*> ---------------------------------------------------------------
*> plbrqopen: PLB-Q016 cursor-open-twice, PLB-Q017 fetch-after-close.
*>
*> An OPEN of an SQL cursor, then, later in the same list of
*> statements, another OPEN of it with no CLOSE between:
*>
*>     EXEC SQL OPEN ACCT-CUR END-EXEC
*>     ...
*>     EXEC SQL OPEN ACCT-CUR END-EXEC          already open
*>
*> DB2 rejects the second OPEN (SQLCODE -502, the cursor is already
*> open); a program that tests only for 100 reads on from the old
*> position. The statements after the OPEN are read in their list (for
*> a statement directly in a sentence, on through the paragraph's later
*> sentences): a CLOSE of the cursor ends the search, as do a PERFORM
*> of a procedure, GO TO, CALL, GOBACK, STOP, EXIT, and a statement
*> holding other SQL statements; a test of SQLCODE or SQLSTATE between
*> them, which may find that the first OPEN failed, ends it too.
*>
*> PLB-Q017 reads the statements after a CLOSE of a cursor the same
*> way: a FETCH or CLOSE of it before an OPEN finds it closed, and DB2
*> rejects it (SQLCODE -501, the cursor is not open).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-Q016.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-CLOSED          PIC 9(4) COMP-5.
*> The statement the search starts from: OPEN or CLOSE.
01  LS-FROM-VERB            PIC X(31).
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-VERB                 PIC X(31).
01  LS-CURSOR               PIC X(31).
01  LS-NAME                 PIC X(31).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-STOP                 PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q016" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q017" LS-RULE-CLOSED
    IF RL-ENABLED(LS-RULE) NOT = "Y"
       AND RL-ENABLED(LS-RULE-CLOSED) NOT = "Y"
        GOBACK
    END-IF
    IF AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "EXEC"
            MOVE LS-NODE TO LS-STMT
            PERFORM SQL-COMMAND
            IF LS-NAME NOT = SPACES
               AND ((LS-VERB = "OPEN" AND RL-ENABLED(LS-RULE) = "Y")
                    OR (LS-VERB = "CLOSE"
                        AND RL-ENABLED(LS-RULE-CLOSED) = "Y"))
                MOVE LS-NAME TO LS-CURSOR
                MOVE LS-VERB TO LS-FROM-VERB
                PERFORM CHECK-OPEN
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> EXEC SQL verb name ... in statement LS-STMT: LS-VERB and LS-NAME,
*> upper-cased; spaces for anything else.
SQL-COMMAND.
    MOVE SPACES TO LS-VERB LS-NAME
    IF ND-TOK-FIRST(LS-STMT) + 3 > ND-TOK-LAST(LS-STMT)
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "SQL"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-VERB LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-VERB) TO LS-VERB
    ADD 1 TO LS-T
    IF TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-NAME LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    END-IF.

*> The statements after OPEN or CLOSE LS-NODE of LS-CURSOR.
CHECK-OPEN.
    MOVE LS-NODE TO LS-STMT
    MOVE "N" TO LS-STOP
    PERFORM UNTIL LS-STOP = "Y"
        PERFORM NEXT-STATEMENT
        IF LS-NEXT = 0
            EXIT PERFORM
        END-IF
        MOVE LS-NEXT TO LS-STMT
        EVALUATE ND-DETAIL(LS-STMT)
            WHEN "EXEC"
                PERFORM SQL-COMMAND
                IF LS-NAME = LS-CURSOR
                    EVALUATE TRUE
                        WHEN LS-FROM-VERB = "OPEN" AND LS-VERB = "OPEN"
                            PERFORM REPORT-TWICE
                        WHEN LS-FROM-VERB = "CLOSE"
                             AND (LS-VERB = "FETCH" OR LS-VERB = "CLOSE")
                            PERFORM REPORT-CLOSED
                    END-EVALUATE
                    MOVE "Y" TO LS-STOP
                END-IF
            WHEN "GO" WHEN "CALL" WHEN "GOBACK" WHEN "STOP" WHEN "EXIT"
                MOVE "Y" TO LS-STOP
            WHEN OTHER
                PERFORM CHECK-OTHER
        END-EVALUATE
    END-PERFORM.

*> Any other statement: a PERFORM of a procedure, SQL inside it, or a
*> mention of SQLCODE or SQLSTATE ends the search.
CHECK-OTHER.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "SQLCODE" OR LS-WORD = "SQLSTATE"
               OR LS-WORD = "EXEC"
                MOVE "Y" TO LS-STOP
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    IF ND-DETAIL(LS-STMT) = "PERFORM"
        MOVE ND-FIRST(LS-STMT) TO LS-UP
        PERFORM UNTIL LS-UP = 0
            IF ND-KIND(LS-UP) = "PROC"
                MOVE "Y" TO LS-STOP
                EXIT PARAGRAPH
            END-IF
            MOVE ND-NEXT(LS-UP) TO LS-UP
        END-PERFORM
    END-IF.

*> LS-NEXT: the statement after LS-STMT in its list, or the first of
*> the next sentence of the paragraph; 0 when there is none.
NEXT-STATEMENT.
    MOVE ND-NEXT(LS-STMT) TO LS-NEXT
    IF LS-NEXT > 0
        IF ND-KIND(LS-NEXT) NOT = "STMT"
            MOVE 0 TO LS-NEXT
        END-IF
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(LS-STMT) TO LS-UP
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-UP) NOT = "SENT"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-NEXT(LS-UP) TO LS-UP
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-UP) = "SENT"
        MOVE ND-FIRST(LS-UP) TO LS-NEXT
        IF LS-NEXT > 0
            IF ND-KIND(LS-NEXT) NOT = "STMT"
                MOVE 0 TO LS-NEXT
            END-IF
        END-IF
    END-IF.

REPORT-TWICE.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "cursor " DELIMITED BY SIZE
           LS-CURSOR DELIMITED BY SPACE
           " is already open, from the OPEN on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", with no CLOSE between: DB2 rejects this OPEN (SQLCODE "
           "-502)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-STMT) LS-MESSAGE.

REPORT-CLOSED.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "cursor " DELIMITED BY SIZE
           LS-CURSOR DELIMITED BY SPACE
           " was closed on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", with no OPEN between: DB2 rejects this " DELIMITED BY SIZE
           LS-VERB DELIMITED BY SPACE
           " (SQLCODE -501)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-CLOSED ND-TOK-FIRST(LS-STMT) LS-MESSAGE.
END PROGRAM PLB-RULE-Q016.
