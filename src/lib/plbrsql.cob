*> ---------------------------------------------------------------
*> plbrsql: rules about embedded SQL and CICS.
*>
*>   PLB-C018  sql-not-checked
*>   PLB-C019  cics-response-not-checked
*>   PLB-S001  dynamic-sql
*>
*> "Checked" means that a statement after the command, in the same
*> paragraph and before the next command of the same kind, names the
*> result (SQLCODE or SQLSTATE; the RESP item), either itself or in a
*> paragraph it PERFORMs. A check reached only by falling into the
*> next paragraph is not seen.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-EMBEDDED.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE-SQL             PIC 9(4) COMP-5.
01  LS-RULE-CICS            PIC 9(4) COMP-5.
01  LS-RULE-DYNAMIC         PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-STOP                 PIC 9(9) COMP-5.
01  LS-LANGUAGE             PIC X(31).
01  LS-COMMAND              PIC X(31).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> What a check looks for: up to two names.
01  LS-WANT-1               PIC X(31).
01  LS-WANT-2               PIC X(31).
01  LS-FOUND                PIC X.
*> "Y" while EXEC SQL WHENEVER SQLERROR (not CONTINUE) is in effect.
01  LS-WHENEVER             PIC X.
01  LS-RESP                 PIC 9(9) COMP-5.
01  LS-NOHANDLE             PIC X.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C018" LS-RULE-SQL
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C019" LS-RULE-CICS
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-S001" LS-RULE-DYNAMIC
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE "N" TO LS-WHENEVER
    MOVE 1 TO LS-NODE
    PERFORM UNTIL LS-NODE = 0
        EVALUATE ND-KIND(LS-NODE)
            WHEN "PROG"
                *> WHENEVER holds within one program.
                MOVE "N" TO LS-WHENEVER
            WHEN "STMT"
                IF ND-DETAIL(LS-NODE) = "EXEC"
                    MOVE LS-NODE TO LS-STMT
                    PERFORM EXEC-STATEMENT
                END-IF
        END-EVALUATE
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

EXEC-STATEMENT.
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-LANGUAGE LS-LEN
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-COMMAND LS-LEN
    EVALUATE LS-LANGUAGE
        WHEN "SQL"
            PERFORM SQL-STATEMENT
        WHEN "CICS"
            PERFORM CICS-STATEMENT
    END-EVALUATE.

*> SQL -------------------------------------------------------------

SQL-STATEMENT.
    EVALUATE LS-COMMAND
        WHEN "WHENEVER"
            PERFORM NOTE-WHENEVER
        WHEN "PREPARE"
            PERFORM CHECK-DYNAMIC
            PERFORM CHECK-SQL-RESULT
        WHEN "EXECUTE"
            PERFORM CHECK-DYNAMIC
            PERFORM CHECK-SQL-RESULT
        WHEN "SELECT" WHEN "INSERT" WHEN "UPDATE" WHEN "DELETE"
        WHEN "FETCH" WHEN "OPEN" WHEN "CALL" WHEN "MERGE"
        WHEN "CONNECT"
            PERFORM CHECK-SQL-RESULT
    END-EVALUATE.

*> WHENEVER SQLERROR {CONTINUE | GO TO x | PERFORM x | ...}, in force
*> for the statements after it in the source.
NOTE-WHENEVER.
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 3
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT NOT = "SQLERROR"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT = "CONTINUE"
        MOVE "N" TO LS-WHENEVER
    ELSE
        MOVE "Y" TO LS-WHENEVER
    END-IF.

*> PLB-C018.
CHECK-SQL-RESULT.
    IF RL-ENABLED(LS-RULE-SQL) NOT = "Y" OR LS-WHENEVER = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "SQLCODE" TO LS-WANT-1
    MOVE "SQLSTATE" TO LS-WANT-2
    PERFORM FOLLOWING-CHECK
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "the result of EXEC SQL " DELIMITED BY SIZE
           LS-COMMAND DELIMITED BY SPACE
           " is not checked: nothing tests SQLCODE or SQLSTATE before"
           DELIMITED BY SIZE
           " the next SQL statement" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-SQL ND-TOK-FIRST(LS-STMT) LS-MESSAGE.

*> PLB-S001: PREPARE s FROM :text, EXECUTE IMMEDIATE :text.
CHECK-DYNAMIC.
    IF RL-ENABLED(LS-RULE-DYNAMIC) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF (LS-TEXT = "FROM" AND LS-COMMAND = "PREPARE"
                OR LS-TEXT = "IMMEDIATE" AND LS-COMMAND = "EXECUTE")
               AND TK-IS-COLON(LS-T + 1)
                COMPUTE LS-K = LS-T + 2
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                MOVE SPACES TO LS-MESSAGE
                STRING "SQL text is built at run time from " DELIMITED BY SIZE
                       LS-TEXT DELIMITED BY SPACE
                       "; make sure no outside input reaches it unchecked"
                       DELIMITED BY SIZE
                    INTO LS-MESSAGE
                CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                    PLB-RULES PLB-FINDINGS LS-RULE-DYNAMIC LS-K LS-MESSAGE
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> CICS ------------------------------------------------------------

*> PLB-C019: RESP(x) not tested before the next CICS command, or
*> NOHANDLE without RESP.
CICS-STATEMENT.
    IF RL-ENABLED(LS-RULE-CICS) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-RESP
    MOVE "N" TO LS-NOHANDLE
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "NOHANDLE"
                MOVE "Y" TO LS-NOHANDLE
            END-IF
            IF LS-TEXT = "RESP" AND TK-IS-LPAREN(LS-T + 1)
               AND TK-IS-WORD(LS-T + 2)
                COMPUTE LS-RESP = LS-T + 2
            END-IF
        END-IF
    END-PERFORM
    IF LS-RESP = 0
        IF LS-NOHANDLE = "Y"
            MOVE SPACES TO LS-MESSAGE
            STRING "EXEC CICS " DELIMITED BY SIZE
                   LS-COMMAND DELIMITED BY SPACE
                   " has NOHANDLE but no RESP, so its errors are ignored"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-CICS ND-TOK-FIRST(LS-STMT)
                LS-MESSAGE
        END-IF
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-RESP LS-WANT-1 LS-LEN
    MOVE "EIBRESP" TO LS-WANT-2
    PERFORM FOLLOWING-CHECK
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "the response of EXEC CICS " DELIMITED BY SIZE
           LS-COMMAND DELIMITED BY SPACE
           " in " DELIMITED BY SIZE
           LS-WANT-1 DELIMITED BY SPACE
           " is not tested before the next CICS command" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-CICS LS-RESP LS-MESSAGE.

*> Checks ----------------------------------------------------------

*> LS-FOUND = "Y" when LS-WANT-1 or LS-WANT-2 is named after statement
*> LS-STMT in its paragraph, before the next EXEC of the same language,
*> or in a paragraph performed from there.
FOLLOWING-CHECK.
    MOVE "N" TO LS-FOUND
    PERFORM UNIT-OF-STATEMENT
    IF LS-U = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO LS-END
    *> Where the next EXEC of the same language starts, if it does.
    MOVE LS-END TO LS-STOP
    COMPUTE LS-T = ND-TOK-LAST(LS-STMT) + 1
    PERFORM UNTIL LS-T > LS-END
        IF TK-IS-WORD(LS-T) AND LS-T < LS-END
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "EXEC"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                IF LS-TEXT = LS-LANGUAGE
                    MOVE LS-T TO LS-STOP
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM
    COMPUTE LS-T = ND-TOK-LAST(LS-STMT) + 1
    MOVE LS-STOP TO LS-LAST
    PERFORM SCAN-RANGE
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    *> PERFORMs between the statement and the stop.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-FROM(LS-E) = LS-U
           AND FE-TO(LS-E) > 0
            IF ND-TOK-FIRST(FE-STMT(LS-E)) > ND-TOK-LAST(LS-STMT)
               AND ND-TOK-FIRST(FE-STMT(LS-E)) < LS-STOP
                PERFORM SCAN-PERFORMED
                IF LS-FOUND = "Y"
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> The tokens of every unit in edge LS-E's range.
SCAN-PERFORMED.
    MOVE FE-TO(LS-E) TO LS-V
    PERFORM UNTIL LS-V = 0 OR LS-FOUND = "Y"
        MOVE ND-TOK-FIRST(FU-NODE(LS-V)) TO LS-T
        MOVE ND-TOK-LAST(FU-NODE(LS-V)) TO LS-LAST
        PERFORM SCAN-RANGE
        IF LS-V = FE-THRU(LS-E) OR FE-THRU(LS-E) = 0
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-V) TO LS-V
    END-PERFORM.

*> LS-FOUND = "Y" when a word from LS-T to LS-LAST is LS-WANT-1 or
*> LS-WANT-2.
SCAN-RANGE.
    PERFORM UNTIL LS-T > LS-LAST
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = LS-WANT-1 OR LS-TEXT = LS-WANT-2
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> LS-U = the innermost unit (paragraph, else section or division
*> start) whose tokens hold statement LS-STMT; 0 when none does.
UNIT-OF-STATEMENT.
    MOVE 0 TO LS-U
    PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > FU-COUNT
        IF ND-TOK-FIRST(FU-NODE(LS-V)) <= ND-TOK-FIRST(LS-STMT)
           AND ND-TOK-LAST(FU-NODE(LS-V)) >= ND-TOK-LAST(LS-STMT)
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
END PROGRAM PLB-RULE-EMBEDDED.
