*> ---------------------------------------------------------------
*> plbrsql: rules about embedded SQL and CICS.
*>
*>   PLB-C018  sql-not-checked
*>   PLB-C019  cics-response-not-checked
*>   PLB-S001  dynamic-sql
*>   PLB-M014  sql-select-star
*>   PLB-Q005  into-count-mismatch (PLB-RULE-Q005, below)
*>   PLB-K003  commarea-without-length (PLB-RULE-K003, below)
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
01  LS-RULE-STAR            PIC 9(4) COMP-5.
01  LS-RULE-NO-WHERE        PIC 9(4) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-IN-SQL               PIC X.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
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
COPY "plbnlist.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C018" LS-RULE-SQL
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C019" LS-RULE-CICS
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-S001" LS-RULE-DYNAMIC
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M014" LS-RULE-STAR
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q004" LS-RULE-NO-WHERE
    IF RL-ENABLED(LS-RULE-STAR) = "Y"
        PERFORM CHECK-SELECT-STAR
    END-IF
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

*> PLB-M014: SELECT * in embedded SQL, anywhere: in a statement, in
*> a DECLARE CURSOR in working-storage, in INSERT ... SELECT. The
*> program then depends on every column of the table and on their
*> order, and breaks when a column is added. COUNT(*) is fine.
CHECK-SELECT-STAR.
    MOVE "N" TO LS-IN-SQL
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE TRUE
                WHEN LS-TEXT = "EXEC" OR LS-TEXT = "EXECUTE"
                    COMPUTE LS-K = LS-T + 1
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                    IF LS-TEXT = "SQL"
                        MOVE "Y" TO LS-IN-SQL
                    END-IF
                WHEN LS-TEXT = "END-EXEC"
                    MOVE "N" TO LS-IN-SQL
                WHEN LS-TEXT = "SELECT" AND LS-IN-SQL = "Y"
                    PERFORM CHECK-STAR-AFTER-SELECT
            END-EVALUATE
        END-IF
    END-PERFORM.

CHECK-STAR-AFTER-SELECT.
    COMPUTE LS-K = LS-T + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
    IF TK-IS-WORD(LS-K) AND (LS-TEXT = "DISTINCT" OR LS-TEXT = "ALL")
        ADD 1 TO LS-K
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
    END-IF
    IF TK-IS-OPERATOR(LS-K) AND LS-TEXT = "*"
        MOVE "SELECT * depends on every column of the table and their"
            & " order; name the columns" TO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-STAR LS-T LS-MESSAGE
    END-IF.

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
    END-EVALUATE
    IF LS-COMMAND = "UPDATE" OR LS-COMMAND = "DELETE"
        PERFORM CHECK-WHERE
    END-IF.

*> PLB-Q004: UPDATE or DELETE without WHERE (outside parentheses, so a
*> subquery's WHERE does not count) changes every row of the table.
CHECK-WHERE.
    IF RL-ENABLED(LS-RULE-NO-WHERE) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-FOUND
    MOVE 0 TO LS-LEVEL
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL = 0 AND TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "WHERE"
                    MOVE "Y" TO LS-FOUND
                    EXIT PERFORM
                END-IF
        END-EVALUATE
    END-PERFORM
    IF LS-FOUND = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING "EXEC SQL " DELIMITED BY SIZE
               LS-COMMAND DELIMITED BY SPACE
               " has no WHERE: it changes every row of the table"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 2
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-NO-WHERE LS-T LS-MESSAGE
    END-IF.

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
    *> Where the next EXEC of the same language starts, if it does.
    MOVE 0 TO LS-STOP
    COMPUTE LS-T = ND-TOK-LAST(LS-STMT) + 1
    PERFORM UNTIL LS-T >= TK-COUNT
        IF TK-IS-WORD(LS-T)
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
    MOVE 2 TO NL-COUNT
    MOVE LS-WANT-1 TO NL-NAME(1)
    MOVE LS-WANT-2 TO NL-NAME(2)
    CALL "PLB-NAMED-AFTER" USING PLB-TOKENS PLB-AST PLB-FLOW LS-STMT
        LS-STOP PLB-NAME-LIST LS-FOUND.
END PROGRAM PLB-RULE-EMBEDDED.

*> PLB-Q001 sql-table-undeclared: a program that uses a table in
*> embedded SQL without declaring it (EXEC SQL DECLARE name TABLE,
*> usually through an INCLUDE of the table's DCLGEN member). With the
*> declaration the DB2 precompiler checks each statement's columns
*> against the table; without it, a misspelled column or a table
*> changed since is found only at bind time or when the statement
*> runs. Reported once per table and program, at its first use. The
*> catalog tables of DB2 (SYSIBM.*) are left out.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SQL-TABLES.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q001" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > PQ-COUNT
        IF PQ-KIND(LS-U) NOT = "T" AND PQ-TABLE(LS-U)(1:7) NOT = "SYSIBM."
            PERFORM CHECK-USE
        END-IF
    END-PERFORM
    GOBACK.

*> Use LS-U: the first of its table in its program, and no declaration
*> of the table there.
CHECK-USE.
    MOVE PQ-PROGRAM(LS-U) TO LS-Q
    PERFORM OUTERMOST
    MOVE LS-OWNER TO LS-PROGRAM
    PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > PQ-COUNT
        IF PQ-TABLE(LS-V) = PQ-TABLE(LS-U)
            MOVE PQ-PROGRAM(LS-V) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-PROGRAM
                IF PQ-KIND(LS-V) = "T"
                    EXIT PARAGRAPH
                END-IF
                IF LS-V < LS-U
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    MOVE SPACES TO LS-MESSAGE
    STRING "table " DELIMITED BY SIZE
           PQ-TABLE(LS-U) DELIMITED BY SPACE
           " is not declared in " DELIMITED BY SIZE
           CP-NAME(LS-PROGRAM) DELIMITED BY SPACE
           " (EXEC SQL DECLARE ... TABLE, or its DCLGEN INCLUDE)"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        PQ-FILE-ID(LS-U) PQ-LINE(LS-U) PQ-COLUMN(LS-U) PQ-SRC-LINE(LS-U)
        LS-MESSAGE.

OUTERMOST.
    MOVE CP-OWNER(LS-Q) TO LS-OWNER
    PERFORM UNTIL CP-PARENT(LS-OWNER) = 0
        MOVE CP-PARENT(LS-OWNER) TO LS-OWNER
    END-PERFORM.
END PROGRAM PLB-RULE-SQL-TABLES.

*> PLB-Q002 cursor-not-closed and PLB-Q003 cursor-not-opened: the
*> cursors a file declares (EXEC SQL DECLARE name ... CURSOR), and the
*> OPEN, FETCH, and CLOSE statements that name them.
*>
*>   Q002: a cursor that is opened but never closed holds its locks and
*>         its place until the unit of work ends, and a second OPEN of
*>         it fails (SQLCODE -502).
*>   Q003: a cursor that is fetched or closed but never opened: the
*>         statement fails (SQLCODE -501).
*>
*> The statements are read from the tokens of the file, so a cursor
*> declared in working-storage counts, and the names are compared
*> across the whole file.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SQL-CURSORS.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  QC-MAX                      VALUE 200.
01  WS-CURSORS.
    05  WS-QC-COUNT         PIC 9(4) COMP-5.
    05  WS-QC               OCCURS QC-MAX TIMES.
        10  WS-QC-NAME      PIC X(31).
        10  WS-QC-DECLARED  PIC 9(9) COMP-5.
        10  WS-QC-OPENED    PIC 9(9) COMP-5.
        10  WS-QC-FETCHED   PIC 9(9) COMP-5.
        10  WS-QC-CLOSED    PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-RULE-NOT-CLOSED      PIC 9(4) COMP-5.
01  LS-RULE-NOT-OPENED      PIC 9(4) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-NAME                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-PASS                 PIC 9.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q002" LS-RULE-NOT-CLOSED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q003" LS-RULE-NOT-OPENED
    IF RL-ENABLED(LS-RULE-NOT-CLOSED) NOT = "Y"
       AND RL-ENABLED(LS-RULE-NOT-OPENED) NOT = "Y"
        GOBACK
    END-IF
    MOVE 0 TO WS-QC-COUNT
    *> First the declarations, wherever they are, then the uses.
    PERFORM VARYING LS-PASS FROM 1 BY 1 UNTIL LS-PASS > 2
        PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
            IF TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "EXEC"
                    COMPUTE LS-K = LS-T + 1
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                    IF FUNCTION UPPER-CASE(LS-TEXT) = "SQL"
                        PERFORM SQL-BLOCK
                    END-IF
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-QC-COUNT
        PERFORM CHECK-CURSOR
    END-PERFORM
    GOBACK.

*> The statement from LS-T + 2 to END-EXEC.
SQL-BLOCK.
    COMPUTE LS-END = LS-T + 2
    PERFORM UNTIL LS-END >= TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-END LS-TEXT LS-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) = "END-EXEC"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-END
    END-PERFORM
    COMPUTE LS-K = LS-T + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    EVALUATE TRUE
        WHEN LS-PASS = 1 AND LS-TEXT = "DECLARE"
            PERFORM DECLARATION
        WHEN LS-PASS = 2 AND (LS-TEXT = "OPEN" OR LS-TEXT = "CLOSE")
            ADD 1 TO LS-K
            PERFORM FIND-CURSOR
            IF LS-C > 0
                IF LS-TEXT = "OPEN"
                    IF WS-QC-OPENED(LS-C) = 0
                        MOVE LS-K TO WS-QC-OPENED(LS-C)
                    END-IF
                ELSE
                    IF WS-QC-CLOSED(LS-C) = 0
                        MOVE LS-K TO WS-QC-CLOSED(LS-C)
                    END-IF
                END-IF
            END-IF
        WHEN LS-PASS = 2 AND LS-TEXT = "FETCH"
            *> FETCH [orientation] [FROM] cursor: the first word that
            *> names a cursor.
            PERFORM VARYING LS-K FROM LS-K BY 1 UNTIL LS-K >= LS-END
                PERFORM FIND-CURSOR
                IF LS-C > 0
                    IF WS-QC-FETCHED(LS-C) = 0
                        MOVE LS-K TO WS-QC-FETCHED(LS-C)
                    END-IF
                    EXIT PERFORM
                END-IF
            END-PERFORM
    END-EVALUATE.

*> DECLARE name [options] CURSOR: a cursor when CURSOR comes before
*> FOR (DECLARE name TABLE and DECLARE name STATEMENT are not).
DECLARATION.
    ADD 1 TO LS-K
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-NAME LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    PERFORM VARYING LS-C FROM LS-K BY 1 UNTIL LS-C >= LS-END
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
        IF LS-TEXT = "FOR" OR LS-TEXT = "TABLE"
            EXIT PARAGRAPH
        END-IF
        IF LS-TEXT = "CURSOR"
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-C >= LS-END OR WS-QC-COUNT >= QC-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-QC-COUNT
    MOVE LS-NAME TO WS-QC-NAME(WS-QC-COUNT)
    MOVE LS-K TO WS-QC-DECLARED(WS-QC-COUNT)
    MOVE 0 TO WS-QC-OPENED(WS-QC-COUNT) WS-QC-FETCHED(WS-QC-COUNT)
        WS-QC-CLOSED(WS-QC-COUNT).

*> LS-C: the declared cursor named by token LS-K, or 0.
FIND-CURSOR.
    MOVE 0 TO LS-C
    IF NOT TK-IS-WORD(LS-K)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-NAME LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-QC-COUNT
        IF WS-QC-NAME(LS-C) = LS-NAME
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE 0 TO LS-C.

CHECK-CURSOR.
    IF WS-QC-OPENED(LS-C) > 0 AND WS-QC-CLOSED(LS-C) = 0
        MOVE SPACES TO LS-MESSAGE
        STRING "cursor " DELIMITED BY SIZE
               WS-QC-NAME(LS-C) DELIMITED BY SPACE
               " is opened but never closed" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-NOT-CLOSED
            WS-QC-OPENED(LS-C) LS-MESSAGE
    END-IF
    IF WS-QC-OPENED(LS-C) = 0
        IF WS-QC-FETCHED(LS-C) > 0
            MOVE WS-QC-FETCHED(LS-C) TO LS-K
            MOVE "fetched" TO LS-TEXT
        ELSE
            MOVE WS-QC-CLOSED(LS-C) TO LS-K
            MOVE "closed" TO LS-TEXT
        END-IF
        IF LS-K > 0
            MOVE SPACES TO LS-MESSAGE
            STRING "cursor " DELIMITED BY SIZE
                   WS-QC-NAME(LS-C) DELIMITED BY SPACE
                   " is " DELIMITED BY SIZE
                   LS-TEXT DELIMITED BY SPACE
                   " but never opened" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-NOT-OPENED LS-K
                LS-MESSAGE
        END-IF
    END-IF.
END PROGRAM PLB-RULE-SQL-CURSORS.

*> PLB-K002 read-update-not-released: EXEC CICS READ ... UPDATE of a
*> file that the program never rewrites, deletes, or unlocks. The
*> record stays locked for the rest of the task (or until a SYNCPOINT),
*> and other tasks that want it wait. A read only to look at the record
*> needs no UPDATE.
*>
*> The file is the operand of FILE( ) or DATASET( ), compared as
*> written: READ FILE(WS-FILE) is released by REWRITE FILE(WS-FILE).
*> Statements are paired within a program, in any order.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-CICS-UPDATES.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  CU-MAX                      VALUE 500.
01  WS-USES.
    05  WS-CU-COUNT         PIC 9(4) COMP-5.
    05  WS-CU               OCCURS CU-MAX TIMES.
        10  WS-CU-PROGRAM   PIC 9(9) COMP-5.
        *>   U  READ ... UPDATE   R  REWRITE, DELETE, or UNLOCK
        10  WS-CU-KIND      PIC X.
        10  WS-CU-FILE      PIC X(60).
        10  WS-CU-TOKEN     PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-COMMAND              PIC X(31).
01  LS-TEXT                 PIC X(60).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FILE                 PIC X(60).
01  LS-FILE-TOKEN           PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-UPDATE               PIC X.
01  LS-FOUND                PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K002" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 0 TO WS-CU-COUNT
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "EXEC"
            PERFORM CICS-STATEMENT
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-CU-COUNT
        IF WS-CU-KIND(LS-I) = "U"
            PERFORM CHECK-RELEASED
        END-IF
    END-PERFORM
    GOBACK.

CICS-STATEMENT.
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "CICS"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-COMMAND LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-COMMAND) TO LS-COMMAND
    IF LS-COMMAND NOT = "READ" AND NOT = "REWRITE" AND NOT = "DELETE"
       AND NOT = "UNLOCK"
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-OPERANDS
    IF LS-FILE = SPACES
        EXIT PARAGRAPH
    END-IF
    IF LS-COMMAND = "READ" AND LS-UPDATE = "N"
        EXIT PARAGRAPH
    END-IF
    IF WS-CU-COUNT >= CU-MAX
        EXIT PARAGRAPH
    END-IF
    PERFORM PROGRAM-OF-NODE
    ADD 1 TO WS-CU-COUNT
    MOVE LS-PROGRAM TO WS-CU-PROGRAM(WS-CU-COUNT)
    MOVE LS-FILE TO WS-CU-FILE(WS-CU-COUNT)
    MOVE LS-FILE-TOKEN TO WS-CU-TOKEN(WS-CU-COUNT)
    IF LS-COMMAND = "READ"
        MOVE "U" TO WS-CU-KIND(WS-CU-COUNT)
    ELSE
        MOVE "R" TO WS-CU-KIND(WS-CU-COUNT)
    END-IF.

*> LS-FILE: the words inside FILE( ) or DATASET( ), upper-cased and
*> joined by spaces; LS-UPDATE = "Y" when UPDATE is an option.
READ-OPERANDS.
    MOVE SPACES TO LS-FILE
    MOVE 0 TO LS-FILE-TOKEN LS-LEVEL
    MOVE "N" TO LS-UPDATE
    PERFORM VARYING LS-T FROM LS-T BY 1 UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL = 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
                EVALUATE LS-TEXT
                    WHEN "UPDATE"
                        MOVE "Y" TO LS-UPDATE
                    WHEN "FILE" WHEN "DATASET"
                        MOVE LS-T TO LS-FILE-TOKEN
                        PERFORM FILE-OPERAND
                END-EVALUATE
        END-EVALUATE
    END-PERFORM.

*> The tokens from the "(" after LS-FILE-TOKEN to its ")".
FILE-OPERAND.
    COMPUTE LS-I = LS-FILE-TOKEN + 1
    IF NOT TK-IS-LPAREN(LS-I)
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-PTR LS-J
    ADD 1 TO LS-I
    PERFORM VARYING LS-I FROM LS-I BY 1
            UNTIL LS-I > ND-TOK-LAST(LS-NODE)
        IF TK-IS-LPAREN(LS-I)
            ADD 1 TO LS-J
        END-IF
        IF TK-IS-RPAREN(LS-I)
            SUBTRACT 1 FROM LS-J
        END-IF
        IF LS-J = 0
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-TEXT LS-LEN
        IF LS-PTR > 1 AND LS-PTR < 55
            STRING " " DELIMITED BY SIZE INTO LS-FILE WITH POINTER LS-PTR
        END-IF
        IF LS-PTR < 55
            STRING FUNCTION UPPER-CASE(LS-TEXT(1:LS-LEN))
                DELIMITED BY SIZE INTO LS-FILE WITH POINTER LS-PTR
        END-IF
    END-PERFORM.

*> LS-PROGRAM: the PROG node around statement LS-NODE.
PROGRAM-OF-NODE.
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "PROG"
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    MOVE LS-UP TO LS-PROGRAM.

CHECK-RELEASED.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > WS-CU-COUNT
        IF WS-CU-KIND(LS-J) = "R"
           AND WS-CU-PROGRAM(LS-J) = WS-CU-PROGRAM(LS-I)
           AND WS-CU-FILE(LS-J) = WS-CU-FILE(LS-I)
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING "READ UPDATE of " DELIMITED BY SIZE
               WS-CU-FILE(LS-I) DELIMITED BY "  "
               " locks the record, but the program never rewrites,"
               " deletes, or unlocks it" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE WS-CU-TOKEN(LS-I) LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-CICS-UPDATES.

*> PLB-Q005 into-count-mismatch: a FETCH, or a SELECT ... INTO, whose
*> INTO list has another number of host variables than the select list
*> has columns:
*>
*>     EXEC SQL DECLARE C1 CURSOR FOR SELECT ACCT_ID, BALANCE, STATUS
*>         FROM ACCOUNT END-EXEC
*>     EXEC SQL FETCH C1 INTO :WS-ACCT-ID, :WS-BALANCE END-EXEC
*>
*> With fewer host variables than columns, DB2 sets SQLWARN3 and the
*> statement otherwise succeeds, so a program that tests only SQLCODE
*> carries on without the columns it dropped; with more, the statement
*> is in error.
*>
*> Commas are separators to COBOL and are not tokens, so the lists are
*> counted from the source text between their tokens: commas outside
*> parentheses. A host variable with an indicator (:HV :IND, :HV
*> INDICATOR :IND) is one. Lists with * at their top level, a cursor
*> for a prepared statement, and host structures (a group item, which
*> stands for its fields) are not counted.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-Q005.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  QK-MAX                      VALUE 200.
01  WS-CURSORS.
    05  WS-QK-COUNT         PIC 9(4) COMP-5.
    05  WS-QK               OCCURS QK-MAX TIMES.
        10  WS-QK-NAME      PIC X(31).
        *> Columns of its SELECT list; 0 when not known.
        10  WS-QK-COLUMNS   PIC 9(4) COMP-5.
01  WS-LINE-TEXT            PIC X(4096).
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(4) COMP-5.
01  LS-COUNT                PIC 9(4) COMP-5.
01  LS-COLUMNS              PIC 9(4) COMP-5.
01  LS-HOSTS                PIC 9(4) COMP-5.
01  LS-UNKNOWN              PIC X.
01  LS-COMMA                PIC X.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
*> COMMA-BETWEEN's own position, apart from its callers' loops.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-LINE-LEN             PIC 9(9) COMP-5.
01  LS-SCAN-FROM            PIC 9(9) COMP-5.
01  LS-SCAN-TO              PIC 9(9) COMP-5.
01  LS-SCAN-LINE            PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-NAME                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-PASS                 PIC 9.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-1                PIC X(12).
01  LS-NUM-1-LEN            PIC 9(9) COMP-5.
01  LS-NUM-2                PIC X(12).
01  LS-NUM-2-LEN            PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(4) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-SYMBOLS PLB-REFS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q005" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    MOVE 0 TO WS-QK-COUNT
    *> First the cursors, wherever they are declared, then the uses.
    PERFORM VARYING LS-PASS FROM 1 BY 1 UNTIL LS-PASS > 2
        PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
            IF TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "EXEC"
                    COMPUTE LS-K = LS-T + 1
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                    IF FUNCTION UPPER-CASE(LS-TEXT) = "SQL"
                        PERFORM SQL-BLOCK
                    END-IF
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM
    GOBACK.

*> The statement from LS-T + 2 to END-EXEC (LS-END).
SQL-BLOCK.
    COMPUTE LS-END = LS-T + 2
    PERFORM UNTIL LS-END >= TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-END LS-TEXT LS-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) = "END-EXEC"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-END
    END-PERFORM
    COMPUTE LS-K = LS-T + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    EVALUATE TRUE
        WHEN LS-PASS = 1 AND LS-TEXT = "DECLARE"
            PERFORM DECLARATION
        WHEN LS-PASS = 2 AND LS-TEXT = "FETCH"
            PERFORM CHECK-FETCH
        WHEN LS-PASS = 2 AND LS-TEXT = "SELECT"
            PERFORM CHECK-SELECT-INTO
    END-EVALUATE.

*> DECLARE name ... CURSOR ... FOR SELECT list FROM: the cursor and
*> the columns of its list (0 for FOR a statement name).
DECLARATION.
    ADD 1 TO LS-K
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-NAME LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    MOVE 0 TO LS-FROM
    PERFORM VARYING LS-C FROM LS-K BY 1 UNTIL LS-C >= LS-END
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
        IF LS-TEXT = "TABLE" OR LS-TEXT = "STATEMENT"
            EXIT PARAGRAPH
        END-IF
        IF LS-TEXT = "SELECT"
            MOVE LS-C TO LS-FROM
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF WS-QK-COUNT >= QK-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-QK-COUNT
    MOVE LS-NAME TO WS-QK-NAME(WS-QK-COUNT)
    MOVE 0 TO WS-QK-COLUMNS(WS-QK-COUNT)
    IF LS-FROM > 0
        PERFORM SELECT-LIST
        MOVE LS-COLUMNS TO WS-QK-COLUMNS(WS-QK-COUNT)
    END-IF.

*> LS-COLUMNS: the columns of the select list after SELECT at LS-FROM,
*> up to FROM or INTO at the top level; 0 when not counted. LS-TO is
*> the token that ends it.
SELECT-LIST.
    MOVE 0 TO LS-COLUMNS LS-DEPTH
    MOVE 1 TO LS-COUNT
    MOVE "N" TO LS-UNKNOWN
    COMPUTE LS-A = LS-FROM + 1
    MOVE 0 TO LS-TO
    PERFORM VARYING LS-B FROM LS-A BY 1 UNTIL LS-B >= LS-END
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-B)
                ADD 1 TO LS-DEPTH
            WHEN TK-IS-RPAREN(LS-B)
                SUBTRACT 1 FROM LS-DEPTH
            WHEN LS-DEPTH = 0 AND TK-IS-WORD(LS-B)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-B LS-TEXT LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
                IF LS-TEXT = "FROM" OR LS-TEXT = "INTO"
                    MOVE LS-B TO LS-TO
                    EXIT PERFORM
                END-IF
            WHEN LS-DEPTH = 0 AND TK-IS-OPERATOR(LS-B)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-B LS-TEXT LS-LEN
                IF LS-TEXT = "*"
                    MOVE "Y" TO LS-UNKNOWN
                END-IF
        END-EVALUATE
        IF LS-DEPTH = 0 AND LS-B > LS-A
            COMPUTE LS-I = LS-B - 1
            MOVE LS-I TO LS-SCAN-FROM
            MOVE LS-B TO LS-SCAN-TO
            PERFORM COMMA-BETWEEN
            IF LS-COMMA = "Y"
                ADD 1 TO LS-COUNT
            END-IF
        END-IF
    END-PERFORM
    IF LS-TO > 0 AND LS-UNKNOWN = "N"
        MOVE LS-COUNT TO LS-COLUMNS
    END-IF.

*> LS-HOSTS: the host variables of an INTO list from LS-A up to the
*> token before LS-B: one more than its top-level commas; 0 when one of
*> them is a group (a host structure) or the list is empty.
INTO-LIST.
    MOVE 0 TO LS-HOSTS
    IF LS-A >= LS-B
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-COUNT
    PERFORM VARYING LS-I FROM LS-A BY 1 UNTIL LS-I >= LS-B
        IF TK-IS-WORD(LS-I)
            PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
                IF RF-TOKEN(LS-R) = LS-I
                    IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
                        IF SY-CATEGORY(RF-SYMBOL(LS-R)) = "G"
                            EXIT PARAGRAPH
                        END-IF
                    END-IF
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
        IF LS-I > LS-A
            COMPUTE LS-SCAN-FROM = LS-I - 1
            MOVE LS-I TO LS-SCAN-TO
            PERFORM COMMA-BETWEEN
            IF LS-COMMA = "Y"
                ADD 1 TO LS-COUNT
            END-IF
        END-IF
    END-PERFORM
    MOVE LS-COUNT TO LS-HOSTS.

*> FETCH ... cursor ... INTO list.
CHECK-FETCH.
    MOVE 0 TO LS-COLUMNS LS-A
    PERFORM VARYING LS-K FROM LS-K BY 1 UNTIL LS-K >= LS-END
        IF TK-IS-WORD(LS-K)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
            IF LS-TEXT = "INTO"
                COMPUTE LS-A = LS-K + 1
                EXIT PERFORM
            END-IF
            IF LS-COLUMNS = 0
                PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-QK-COUNT
                    IF WS-QK-NAME(LS-C) = LS-TEXT
                        MOVE WS-QK-COLUMNS(LS-C) TO LS-COLUMNS
                        MOVE LS-K TO LS-R
                    END-IF
                END-PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-A = 0 OR LS-COLUMNS = 0
        EXIT PARAGRAPH
    END-IF
    MOVE LS-END TO LS-B
    PERFORM INTO-LIST
    IF LS-HOSTS > 0 AND LS-HOSTS NOT = LS-COLUMNS
        PERFORM REPORT-MISMATCH
    END-IF.

*> SELECT list INTO hosts FROM ...
CHECK-SELECT-INTO.
    MOVE LS-K TO LS-FROM
    PERFORM SELECT-LIST
    IF LS-COLUMNS = 0 OR LS-TO = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TO LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "INTO"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-A = LS-TO + 1
    MOVE LS-END TO LS-B
    PERFORM VARYING LS-K FROM LS-A BY 1 UNTIL LS-K >= LS-END
        IF TK-IS-WORD(LS-K)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "FROM"
                MOVE LS-K TO LS-B
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    PERFORM INTO-LIST
    IF LS-HOSTS > 0 AND LS-HOSTS NOT = LS-COLUMNS
        MOVE LS-FROM TO LS-R
        PERFORM REPORT-MISMATCH
    END-IF.

REPORT-MISMATCH.
    MOVE LS-COLUMNS TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE LS-HOSTS TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "the select list has " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           " column" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-COLUMNS > 1
        STRING "s" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING " and the INTO list " DELIMITED BY SIZE
           LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           " host variable" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-HOSTS > 1
        STRING "s" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-A LS-MESSAGE.

*> LS-COMMA = "Y" when the source text between tokens LS-SCAN-FROM and
*> LS-SCAN-TO holds a comma: after the first on its line, and before
*> the second on its line when they are on different lines.
COMMA-BETWEEN.
    MOVE "N" TO LS-COMMA
    IF TK-SRC-LINE(LS-SCAN-FROM) = 0 OR TK-SRC-LINE(LS-SCAN-TO) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE TK-SRC-LINE(LS-SCAN-FROM) TO LS-SCAN-LINE
    CALL "PLB-SRC-LINE-TEXT" USING PLB-SOURCE-SET LS-SCAN-LINE
        WS-LINE-TEXT LS-LINE-LEN
    COMPUTE LS-J = TK-COLUMN(LS-SCAN-FROM) + TK-SPAN(LS-SCAN-FROM)
    IF TK-SRC-LINE(LS-SCAN-TO) = LS-SCAN-LINE
        PERFORM VARYING LS-J FROM LS-J BY 1
                UNTIL LS-J >= TK-COLUMN(LS-SCAN-TO) OR LS-J > LS-LINE-LEN
            IF WS-LINE-TEXT(LS-J:1) = ","
                MOVE "Y" TO LS-COMMA
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-J FROM LS-J BY 1
            UNTIL LS-J > SL-CONTENT-COL(LS-SCAN-LINE)
                         + SL-CONTENT-LEN(LS-SCAN-LINE) - 1
               OR LS-J > LS-LINE-LEN
        IF WS-LINE-TEXT(LS-J:1) = ","
            MOVE "Y" TO LS-COMMA
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE TK-SRC-LINE(LS-SCAN-TO) TO LS-SCAN-LINE
    CALL "PLB-SRC-LINE-TEXT" USING PLB-SOURCE-SET LS-SCAN-LINE
        WS-LINE-TEXT LS-LINE-LEN
    PERFORM VARYING LS-J FROM SL-CONTENT-COL(LS-SCAN-LINE) BY 1
            UNTIL LS-J >= TK-COLUMN(LS-SCAN-TO) OR LS-J > LS-LINE-LEN
        IF WS-LINE-TEXT(LS-J:1) = ","
            MOVE "Y" TO LS-COMMA
            EXIT PARAGRAPH
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-Q005.

*> PLB-K003 commarea-without-length: a CICS program that uses
*> DFHCOMMAREA but never looks at EIBCALEN.
*>
*>     LINKAGE SECTION.
*>     01  DFHCOMMAREA.
*>         05  CA-ACCOUNT-ID       PIC X(11).
*>     PROCEDURE DIVISION.
*>         MOVE CA-ACCOUNT-ID TO WS-ACCOUNT-ID
*>
*> When a transaction starts without a COMMAREA (its first time, from a
*> terminal), EIBCALEN is 0 and DFHCOMMAREA has no storage: the
*> reference abends the task (ASRA), or reads whatever is at that
*> address. Programs test EIBCALEN = 0 first, and set their state up
*> instead. A mention of EIBCALEN anywhere in the program counts as the
*> test; each program's first use of DFHCOMMAREA or an item in it is
*> reported.
*>
*> Only transaction programs are checked: those that end with EXEC
*> CICS RETURN TRANSID, the pseudo-conversational return that has the
*> terminal start them again. A program that is only LINKed or XCTLed
*> to with a COMMAREA always has one.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-K003.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-NEST-COUNT           PIC 9(4) COMP-5.
01  WS-NEST                 PIC 9(9) COMP-5 OCCURS 100 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-IN-RETURN            PIC X.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-MOVED                PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K003" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME(LS-S) = "DFHCOMMAREA" AND SY-SECTION(LS-S) = "K"
           AND SY-PARENT(LS-S) = 0 AND SY-PROGRAM(LS-S) > 0
            MOVE SY-PROGRAM(LS-S) TO LS-PROGRAM
            PERFORM CHECK-PROGRAM
        END-IF
    END-PERFORM
    GOBACK.

CHECK-PROGRAM.
    *> Any EIBCALEN in the program's text counts as the test; a RETURN
    *> with TRANSID makes it a transaction program.
    MOVE "N" TO LS-FOUND LS-IN-RETURN
    PERFORM NESTED-PROGRAMS
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-PROGRAM) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-PROGRAM)
        PERFORM SKIP-NESTED
        IF LS-T <= ND-TOK-LAST(LS-PROGRAM) AND TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            EVALUATE LS-WORD
                WHEN "EIBCALEN"
                    EXIT PARAGRAPH
                WHEN "RETURN"
                    MOVE "Y" TO LS-IN-RETURN
                WHEN "END-EXEC"
                    MOVE "N" TO LS-IN-RETURN
                WHEN "TRANSID"
                    IF LS-IN-RETURN = "Y"
                        MOVE "Y" TO LS-FOUND
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM
    IF LS-FOUND = "N"
        EXIT PARAGRAPH
    END-IF
    *> The first reference to the COMMAREA or an item in it.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
            MOVE RF-SYMBOL(LS-R) TO LS-UP
            PERFORM UNTIL SY-PARENT(LS-UP) = 0
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
            IF LS-UP = LS-S
                PERFORM REPORT-USE
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM.

*> The programs nested in this one (direct children of its node), whose
*> text is their own.
NESTED-PROGRAMS.
    MOVE 0 TO WS-NEST-COUNT
    MOVE ND-FIRST(LS-PROGRAM) TO LS-N
    PERFORM UNTIL LS-N = 0
        IF ND-KIND(LS-N) = "PROG" AND WS-NEST-COUNT < 100
            ADD 1 TO WS-NEST-COUNT
            MOVE LS-N TO WS-NEST(WS-NEST-COUNT)
        END-IF
        MOVE ND-NEXT(LS-N) TO LS-N
    END-PERFORM.

*> At the first token of a nested program, LS-T moves past its last.
SKIP-NESTED.
    MOVE "Y" TO LS-MOVED
    PERFORM UNTIL LS-MOVED = "N"
        MOVE "N" TO LS-MOVED
        PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > WS-NEST-COUNT
            IF ND-TOK-FIRST(WS-NEST(LS-N)) = LS-T
                COMPUTE LS-T = ND-TOK-LAST(WS-NEST(LS-N)) + 1
                MOVE "Y" TO LS-MOVED
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-PERFORM.

REPORT-USE.
    MOVE SPACES TO LS-MESSAGE
    IF RF-SYMBOL(LS-R) = LS-S
        STRING "the program uses DFHCOMMAREA but never tests EIBCALEN;"
               " started without a COMMAREA, it abends here"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "the program uses " DELIMITED BY SIZE
               SY-NAME(RF-SYMBOL(LS-R)) DELIMITED BY SPACE
               " of DFHCOMMAREA but never tests EIBCALEN; started"
               " without a COMMAREA, it abends here" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-K003.
