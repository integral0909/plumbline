*> ---------------------------------------------------------------
*> plbropen: OPEN statements on every pass of a loop.
*>
*>   PLB-C065  open-in-loop            a COBOL file
*>   PLB-Q011  cursor-opened-in-loop   an SQL cursor (EXEC SQL OPEN)
*>
*> An OPEN that runs on every pass of a loop, of a file the loop never
*> closes:
*>
*>     PERFORM UNTIL WS-EOF = "Y"
*>         OPEN INPUT IN-FILE
*>         READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
*>     END-PERFORM
*>
*> The second pass opens a file that is already open: the OPEN fails
*> with file status 41, and without a FILE STATUS check the program
*> goes on with the file as the first pass left it, or stops.
*>
*> A loop is a PERFORM with UNTIL, VARYING, or TIMES (other than 1
*> TIMES), or FOREVER. The OPEN is in its inline body, or in a
*> procedure of the range it performs, and nothing between the two may
*> let it run only once: no IF, EVALUATE, SEARCH, or conditional phrase
*> (AT END, INVALID KEY, ...) around it inside the loop. The loop
*> closes the file when a CLOSE of it is in the loop's statements or in
*> a procedure they perform, at any depth.
*>
*> PLB-Q011 checks EXEC SQL OPEN of a cursor the same way, against EXEC
*> SQL CLOSE of the same cursor: the second OPEN of a cursor that is
*> still open fails with SQLCODE -502.
*>
*> The search starts from each OPEN, which are few, and walks up the
*> syntax tree to the loop, or to the paragraph, then to the PERFORM
*> statements that loop over it.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C065.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  RANGE-MAX               VALUE 256.
*> Units a loop runs, marked while its CLOSE statements are looked for.
01  WS-UNIT-MARK            PIC X OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-CURSOR          PIC 9(4) COMP-5.
*> F a file (C065), C a cursor (Q011); the token to report at.
01  LS-MODE                 PIC X.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
*> The EXEC statement SQL-COMMAND reads, and the node and token kept
*> while CLOSE statements are looked for.
01  LS-CMD-NODE             PIC 9(9) COMP-5.
01  LS-SAVED-AT             PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-LOOP-STMT            PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-BODY                 PIC 9(9) COMP-5.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-PHRASE-FROM          PIC 9(9) COMP-5.
01  LS-PHRASE-TO            PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-PREVIOUS             PIC X(31).
01  LS-FILE                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LOOPS                PIC X.
01  LS-STATE                PIC X.
01  LS-CLOSED               PIC X.
*> The token ranges of the loop's statements and of what they perform,
*> and the units marked for them.
01  LS-RANGE-COUNT          PIC 9(4) COMP-5.
01  LS-RANGE-FROM           PIC 9(9) COMP-5 OCCURS RANGE-MAX TIMES.
01  LS-RANGE-TO             PIC 9(9) COMP-5 OCCURS RANGE-MAX TIMES.
01  LS-MARKED-COUNT         PIC 9(4) COMP-5.
01  LS-MARKED               PIC 9(9) COMP-5 OCCURS RANGE-MAX TIMES.
01  LS-RG                   PIC 9(4) COMP-5.
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
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C065" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q011" LS-RULE-CURSOR
    IF AS-COUNT = 0
        GOBACK
    END-IF
    IF RL-ENABLED(LS-RULE) = "Y"
        MOVE "F" TO LS-MODE
        PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
            IF RF-KIND(LS-R) = "O" AND RF-STMT(LS-R) > 0
                IF ND-DETAIL(RF-STMT(LS-R)) = "OPEN"
                    MOVE RF-STMT(LS-R) TO LS-STMT
                    MOVE RF-TOKEN(LS-R) TO LS-AT
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-AT LS-FILE
                        LS-LEN
                    MOVE FUNCTION UPPER-CASE(LS-FILE) TO LS-FILE
                    PERFORM CHECK-OPEN
                END-IF
            END-IF
        END-PERFORM
    END-IF
    IF RL-ENABLED(LS-RULE-CURSOR) = "Y"
        MOVE "C" TO LS-MODE
        PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
            IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "EXEC"
                MOVE LS-NODE TO LS-CMD-NODE
                PERFORM SQL-COMMAND
                IF LS-WORD = "OPEN"
                    MOVE LS-NODE TO LS-STMT
                    PERFORM CHECK-OPEN
                END-IF
            END-IF
        END-PERFORM
    END-IF
    GOBACK.

*> EXEC statement LS-CMD-NODE: LS-WORD the SQL command (OPEN, CLOSE, ...)
*> and, for OPEN and CLOSE, LS-FILE the cursor and LS-AT its token;
*> LS-WORD is spaces when it is not EXEC SQL.
SQL-COMMAND.
    MOVE SPACES TO LS-WORD LS-FILE
    COMPUTE LS-K = ND-TOK-FIRST(LS-CMD-NODE) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "SQL"
        MOVE SPACES TO LS-WORD
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-K
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    IF LS-WORD = "OPEN" OR LS-WORD = "CLOSE"
        ADD 1 TO LS-K
        MOVE LS-K TO LS-AT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-FILE LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-FILE) TO LS-FILE
    END-IF.

*> The file or cursor LS-FILE, opened by statement LS-STMT: the loop
*> that runs the OPEN on every pass, if one does.
CHECK-OPEN.
    PERFORM WALK-UP
    EVALUATE LS-STATE
        WHEN "L"
            *> In the inline body of loop LS-LOOP-STMT.
            PERFORM CHECK-LOOP
        WHEN "U"
            *> At the top of unit LS-UNIT: each PERFORM that loops over
            *> a range holding it.
            PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > FE-COUNT
                IF FE-KIND(LS-F) = "P" AND FE-TO(LS-F) > 0
                   AND FE-STMT(LS-F) > 0
                    MOVE FE-THRU(LS-F) TO LS-LAST
                    IF LS-LAST < FE-TO(LS-F)
                        MOVE FE-TO(LS-F) TO LS-LAST
                    END-IF
                    IF LS-UNIT >= FE-TO(LS-F) AND LS-UNIT <= LS-LAST
                        MOVE FE-STMT(LS-F) TO LS-LOOP-STMT
                        PERFORM STATEMENT-LOOPS
                        IF LS-LOOPS = "Y"
                            PERFORM CHECK-LOOP
                            *> One report for the OPEN is enough.
                            IF LS-CLOSED = "N"
                                EXIT PERFORM
                            END-IF
                        END-IF
                    END-IF
                END-IF
            END-PERFORM
    END-EVALUATE.

*> From statement LS-STMT up the tree. LS-STATE: G when a statement or
*> phrase that may skip the OPEN comes first, L when a looping PERFORM
*> with an inline body does (LS-LOOP-STMT), U when the paragraph or
*> section does (LS-UNIT, its unit), space otherwise.
WALK-UP.
    MOVE SPACE TO LS-STATE
    MOVE ND-PARENT(LS-STMT) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        EVALUATE TRUE
            WHEN ND-KIND(LS-UP) = "PARA" OR ND-KIND(LS-UP) = "SECT"
                PERFORM FIND-UNIT
                EXIT PERFORM
            WHEN ND-KIND(LS-UP) = "STMT" AND ND-DETAIL(LS-UP) = "PERFORM"
                MOVE LS-UP TO LS-LOOP-STMT
                PERFORM STATEMENT-LOOPS
                IF LS-LOOPS = "Y"
                    MOVE "L" TO LS-STATE
                    EXIT PERFORM
                END-IF
            WHEN ND-KIND(LS-UP) = "STMT"
                MOVE "G" TO LS-STATE
                EXIT PERFORM
            WHEN ND-KIND(LS-UP) = "BLCK" AND ND-DETAIL(LS-UP) NOT = "BODY"
                MOVE "G" TO LS-STATE
                EXIT PERFORM
        END-EVALUATE
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> LS-UNIT: the unit whose node is LS-UP; LS-STATE U when there is one.
FIND-UNIT.
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-NODE(LS-U) = LS-UP
            MOVE LS-U TO LS-UNIT
            MOVE "U" TO LS-STATE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-LOOPS = "Y" when PERFORM statement LS-LOOP-STMT loops: its phrase
*> (before the inline body, or the whole statement) has UNTIL, VARYING,
*> FOREVER, or TIMES after anything but the literal 1.
STATEMENT-LOOPS.
    MOVE "N" TO LS-LOOPS
    MOVE 0 TO LS-BODY
    MOVE ND-FIRST(LS-LOOP-STMT) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "BODY"
            MOVE LS-CHILD TO LS-BODY
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    MOVE ND-TOK-FIRST(LS-LOOP-STMT) TO LS-PHRASE-FROM
    IF LS-BODY > 0
        COMPUTE LS-PHRASE-TO = ND-TOK-FIRST(LS-BODY) - 1
    ELSE
        MOVE ND-TOK-LAST(LS-LOOP-STMT) TO LS-PHRASE-TO
    END-IF
    MOVE SPACES TO LS-PREVIOUS
    PERFORM VARYING LS-T FROM LS-PHRASE-FROM BY 1
            UNTIL LS-T > LS-PHRASE-TO
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF TK-IS-WORD(LS-T)
            EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                WHEN "UNTIL" WHEN "VARYING" WHEN "FOREVER"
                    MOVE "Y" TO LS-LOOPS
                    EXIT PERFORM
                WHEN "TIMES"
                    IF LS-PREVIOUS NOT = "1"
                        MOVE "Y" TO LS-LOOPS
                        EXIT PERFORM
                    END-IF
            END-EVALUATE
        END-IF
        MOVE LS-WORD TO LS-PREVIOUS
    END-PERFORM.

*> Loop LS-LOOP-STMT runs the OPEN of LS-FILE on every pass: report it
*> unless a CLOSE of the file is among what the loop runs.
CHECK-LOOP.
    PERFORM COLLECT-RANGES
    PERFORM FIND-CLOSE
    PERFORM CLEAR-MARKS
    IF LS-CLOSED = "N"
        PERFORM REPORT-OPEN
    END-IF.

*> The loop's statements (its inline body, or the units it performs),
*> then every unit a PERFORM among them performs, at any depth. Each
*> new range is searched in turn. LS-RANGE-COUNT is 0 when there are
*> too many to follow.
COLLECT-RANGES.
    MOVE 0 TO LS-RANGE-COUNT LS-MARKED-COUNT
    IF LS-BODY > 0
        MOVE 1 TO LS-RANGE-COUNT
        MOVE ND-TOK-FIRST(LS-BODY) TO LS-RANGE-FROM(1)
        MOVE ND-TOK-LAST(LS-BODY) TO LS-RANGE-TO(1)
    ELSE
        MOVE LS-LOOP-STMT TO LS-C
        PERFORM ADD-PERFORMED-UNITS
    END-IF
    MOVE 1 TO LS-RG
    PERFORM UNTIL LS-RG > LS-RANGE-COUNT
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
            IF FE-KIND(LS-E) = "P" AND FE-STMT(LS-E) > 0
                MOVE FE-STMT(LS-E) TO LS-C
                IF ND-TOK-FIRST(LS-C) >= LS-RANGE-FROM(LS-RG)
                   AND ND-TOK-FIRST(LS-C) <= LS-RANGE-TO(LS-RG)
                    PERFORM ADD-PERFORMED-UNITS
                    IF LS-RANGE-COUNT = 0
                        EXIT PARAGRAPH
                    END-IF
                END-IF
            END-IF
        END-PERFORM
        ADD 1 TO LS-RG
    END-PERFORM.

*> Each unit that statement LS-C performs, not marked yet, as a range.
ADD-PERFORMED-UNITS.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FE-COUNT
        IF FE-STMT(LS-I) = LS-C AND FE-KIND(LS-I) = "P"
           AND FE-TO(LS-I) > 0
            MOVE FE-THRU(LS-I) TO LS-LAST
            IF LS-LAST < FE-TO(LS-I)
                MOVE FE-TO(LS-I) TO LS-LAST
            END-IF
            PERFORM VARYING LS-U FROM FE-TO(LS-I) BY 1
                    UNTIL LS-U > LS-LAST
                IF WS-UNIT-MARK(LS-U) NOT = "Y"
                    IF LS-RANGE-COUNT >= RANGE-MAX
                        MOVE 0 TO LS-RANGE-COUNT
                        EXIT PARAGRAPH
                    END-IF
                    MOVE "Y" TO WS-UNIT-MARK(LS-U)
                    ADD 1 TO LS-MARKED-COUNT
                    MOVE LS-U TO LS-MARKED(LS-MARKED-COUNT)
                    ADD 1 TO LS-RANGE-COUNT
                    MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO
                        LS-RANGE-FROM(LS-RANGE-COUNT)
                    MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO
                        LS-RANGE-TO(LS-RANGE-COUNT)
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.

CLEAR-MARKS.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-MARKED-COUNT
        MOVE SPACE TO WS-UNIT-MARK(LS-MARKED(LS-I))
    END-PERFORM.

*> LS-CLOSED = "Y" when a CLOSE in the ranges names LS-FILE, or when
*> the ranges were too many to follow.
FIND-CLOSE.
    MOVE "N" TO LS-CLOSED
    IF LS-RANGE-COUNT = 0
        MOVE "Y" TO LS-CLOSED
        EXIT PARAGRAPH
    END-IF
    IF LS-MODE = "C"
        PERFORM FIND-SQL-CLOSE
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > RF-COUNT
        IF RF-KIND(LS-C) = "O" AND RF-STMT(LS-C) > 0
            IF ND-DETAIL(RF-STMT(LS-C)) = "CLOSE"
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS RF-TOKEN(LS-C)
                    LS-WORD LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = LS-FILE
                    PERFORM VARYING LS-RG FROM 1 BY 1
                            UNTIL LS-RG > LS-RANGE-COUNT
                        IF RF-TOKEN(LS-C) >= LS-RANGE-FROM(LS-RG)
                           AND RF-TOKEN(LS-C) <= LS-RANGE-TO(LS-RG)
                            MOVE "Y" TO LS-CLOSED
                            EXIT PARAGRAPH
                        END-IF
                    END-PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> An EXEC SQL CLOSE of the cursor LS-FILE in the ranges. The cursor
*> name is kept aside, as SQL-COMMAND sets LS-FILE.
FIND-SQL-CLOSE.
    MOVE LS-FILE TO LS-PREVIOUS
    MOVE LS-AT TO LS-SAVED-AT
    PERFORM VARYING LS-CMD-NODE FROM 1 BY 1 UNTIL LS-CMD-NODE > AS-COUNT
        IF ND-KIND(LS-CMD-NODE) = "STMT"
           AND ND-DETAIL(LS-CMD-NODE) = "EXEC"
            PERFORM SQL-COMMAND
            IF LS-WORD = "CLOSE" AND LS-FILE = LS-PREVIOUS
                PERFORM VARYING LS-RG FROM 1 BY 1
                        UNTIL LS-RG > LS-RANGE-COUNT
                    IF ND-TOK-FIRST(LS-CMD-NODE) >= LS-RANGE-FROM(LS-RG)
                       AND ND-TOK-FIRST(LS-CMD-NODE) <= LS-RANGE-TO(LS-RG)
                        MOVE "Y" TO LS-CLOSED
                    END-IF
                END-PERFORM
            END-IF
        END-IF
        IF LS-CLOSED = "Y"
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE LS-PREVIOUS TO LS-FILE
    MOVE LS-SAVED-AT TO LS-AT.

REPORT-OPEN.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-LOOP-STMT))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    IF LS-MODE = "C"
        STRING "cursor " DELIMITED BY SIZE
               LS-FILE DELIMITED BY SPACE
               " is opened on every pass of the loop on line "
               LS-NUM-TEXT(1:LS-NUM-LEN)
               ", which never closes it: the second OPEN fails"
               " (SQLCODE -502)" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-CURSOR LS-AT LS-MESSAGE
        EXIT PARAGRAPH
    END-IF
    STRING LS-FILE DELIMITED BY SPACE
           " is opened on every pass of the loop on line "
           LS-NUM-TEXT(1:LS-NUM-LEN)
           ", which never closes it: the second OPEN fails"
           " (file status 41)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-AT LS-MESSAGE.
END PROGRAM PLB-RULE-C065.
