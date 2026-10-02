*> ---------------------------------------------------------------
*> plbcall: the call graph (copy/plbcall.cpy).
*>
*>   PLB-CALL-INIT     empty the graph at the start of a run
*>   PLB-CALL-COLLECT  add the programs, ENTRY points, and CALL
*>                     statements of the file just analyzed
*>   PLB-CALL-RESOLVE  match every CALL with a literal name to the
*>                     program it calls, once all files are collected
*>
*> A CALL "NAME" resolves the way COBOL scopes program names:
*>
*>   1. a program directly contained in the caller, or the caller
*>      itself;
*>   2. a COMMON program directly contained in a program that
*>      contains the caller;
*>   3. an outermost program, or an ENTRY point of one, in any file
*>      of the run.
*>
*> When step 3 finds more than one program, the call stays
*> unresolved (CC-MATCHES says how many matched). A CALL of a data
*> item is dynamic and is not resolved.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CALL-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-CALL-GRAPH.
    MOVE 0 TO CP-COUNT CA-COUNT CC-COUNT CG-COUNT CP-DROPPED PF-COUNT
        PM-COUNT PU-COUNT PL-COUNT PQ-COUNT PD-COUNT
    GOBACK.
END PROGRAM PLB-CALL-INIT.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CALL-COLLECT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtokc.cpy".
*> The outermost data reference starting at each token (0: none).
01  WS-REF-AT               PIC 9(9) COMP-5 OCCURS TK-MAX TIMES.
*> The PROG nodes of this file and their programs in the graph.
78  WS-PROG-MAX             VALUE 2000.
01  WS-PROGRAMS.
    05  WS-PROG-COUNT       PIC 9(4) COMP-5.
    05  WS-PROG             OCCURS WS-PROG-MAX TIMES.
        10  WS-PROG-NODE    PIC 9(9) COMP-5.
        10  WS-PROG-INDEX   PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
*> RECORD-SIZE.
01  LS-FD                   PIC 9(9) COMP-5.
01  LS-FD-UP                PIC 9(9) COMP-5.
01  LS-SEL-PROG             PIC 9(9) COMP-5.
01  LS-REC                  PIC 9(9) COMP-5.
01  LS-SYM                  PIC 9(9) COMP-5.
01  LS-FD-NAME              PIC X(31).
01  LS-LIMIT                PIC 9(9) COMP-5.
01  LS-DEPTH                PIC 9(9) COMP-5.
01  LS-SIZE                 PIC 9(9) COMP-5.
01  LS-MODE                 PIC X.
01  LS-KIND                 PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FILE-ID              PIC 9(4) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
01  LS-SRC-LINE             PIC 9(9) COMP-5.
01  LS-SPELLING             PIC X(31).
01  LS-K                    PIC 9(9) COMP-5.
01  LS-MAP-NAME             PIC X(31).
01  LS-MAPSET-NAME          PIC X(31).
01  LS-MAP-TOKEN            PIC 9(9) COMP-5.
01  LS-COMMAND              PIC X(31).
01  LS-IN-SQL               PIC X.
01  LS-SQL-VERB             PIC X.
01  LS-TABLE                PIC X(64).
01  LS-TABLE-FULL           PIC X(64).
01  LS-FOUND-COMMA          PIC X.
01  LS-NAMING               PIC X.
01  LS-START                PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-QUEUE-KIND           PIC X(31).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbcallc.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-CALL-GRAPH.
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > TK-COUNT
        MOVE 0 TO WS-REF-AT(LS-T)
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF WS-REF-AT(RF-TOKEN(LS-R)) = 0
            MOVE LS-R TO WS-REF-AT(RF-TOKEN(LS-R))
        END-IF
    END-PERFORM
    MOVE 0 TO WS-PROG-COUNT
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        EVALUATE ND-KIND(LS-N)
            WHEN "PROG"
                PERFORM ADD-PROGRAM
            WHEN "USNG"
                IF ND-DETAIL(LS-N) = "USING"
                    PERFORM ADD-USING-PARAMETER
                END-IF
            WHEN "SELE"
                PERFORM ADD-FILE
            WHEN "FD"
                IF ND-DETAIL(LS-N) = "SD"
                    PERFORM NOTE-SORT-FILE
                END-IF
            WHEN "STMT"
                EVALUATE ND-DETAIL(LS-N)
                    WHEN "CALL"
                        PERFORM ADD-CALL
                    WHEN "ENTRY"
                        PERFORM ADD-ENTRY
                    WHEN "STOP"
                        PERFORM NOTE-STOP-RUN
                    WHEN "OPEN"
                        PERFORM NOTE-OPEN
                    WHEN "EXEC"
                        PERFORM NOTE-MAP
                        PERFORM NOTE-RESOURCES
                        PERFORM NOTE-DLI
                END-EVALUATE
        END-EVALUATE
    END-PERFORM
    PERFORM NOTE-LITERALS
    PERFORM NOTE-SQL-TABLES
    GOBACK.

*> SQL tables ------------------------------------------------------

*> The tables of each EXEC SQL block, in any division: FROM and JOIN
*> lists, INSERT INTO, UPDATE, DELETE FROM, MERGE INTO, and DECLARE
*> name TABLE. A block belongs to the innermost program it is in.
NOTE-SQL-TABLES.
    MOVE "N" TO LS-IN-SQL
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE TRUE
                WHEN LS-WORD = "EXEC"
                    COMPUTE LS-C = LS-T + 1
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT
                        LS-LEN
                    IF LS-TEXT = "SQL"
                        MOVE "Y" TO LS-IN-SQL
                        PERFORM PROGRAM-OF-TOKEN
                        MOVE SPACE TO LS-SQL-VERB
                    END-IF
                WHEN LS-WORD = "END-EXEC"
                    MOVE "N" TO LS-IN-SQL
                WHEN LS-IN-SQL = "Y" AND LS-P > 0
                    PERFORM SQL-WORD
            END-EVALUATE
        END-IF
    END-PERFORM.

*> LS-P = the innermost program of the file whose tokens hold LS-T.
PROGRAM-OF-TOKEN.
    MOVE 0 TO LS-P
    MOVE 0 TO LS-C
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-PROG-COUNT
        MOVE WS-PROG-NODE(LS-I) TO LS-UP
        IF ND-TOK-FIRST(LS-UP) <= LS-T AND ND-TOK-LAST(LS-UP) >= LS-T
           AND ND-TOK-FIRST(LS-UP) >= LS-C
            MOVE ND-TOK-FIRST(LS-UP) TO LS-C
            MOVE WS-PROG-INDEX(LS-I) TO LS-P
        END-IF
    END-PERFORM.

*> A word of an SQL statement: the keywords that a table name follows.
SQL-WORD.
    MOVE SPACE TO LS-KIND
    COMPUTE LS-C = LS-T + 1
    EVALUATE LS-WORD
        WHEN "FROM" WHEN "JOIN"
            EVALUATE LS-SQL-VERB
                WHEN "D"
                    MOVE "D" TO LS-KIND
                *> FETCH ... FROM cursor names no table.
                WHEN "F"
                    CONTINUE
                WHEN OTHER
                    MOVE "S" TO LS-KIND
            END-EVALUATE
        WHEN "FETCH"
            *> The statement FETCH, not FETCH FIRST n ROWS in a SELECT.
            COMPUTE LS-C = LS-T - 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
            IF LS-TEXT = "SQL"
                MOVE "F" TO LS-SQL-VERB
            END-IF
            COMPUTE LS-C = LS-T + 1
        WHEN "UPDATE"
            *> Not FOR UPDATE OF column.
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
            IF LS-TEXT NOT = "OF"
                MOVE "U" TO LS-KIND
            END-IF
        WHEN "DELETE"
            MOVE "D" TO LS-SQL-VERB
        WHEN "INSERT"
            MOVE "I" TO LS-SQL-VERB
        WHEN "MERGE"
            MOVE "M" TO LS-SQL-VERB
        WHEN "INTO"
            IF LS-SQL-VERB = "I" OR LS-SQL-VERB = "M"
                MOVE LS-SQL-VERB TO LS-KIND
            END-IF
        WHEN "DECLARE"
            PERFORM SQL-DECLARED-TABLE
    END-EVALUATE
    IF LS-KIND = SPACE
        EXIT PARAGRAPH
    END-IF
    PERFORM SQL-TABLE-AT-C
    *> FROM a x, b y: the lexer keeps no commas, so a comma between two
    *> tokens is looked for in the source.
    IF LS-KIND = "S" OR LS-KIND = "D"
        PERFORM UNTIL LS-C >= TK-COUNT
            IF NOT TK-IS-WORD(LS-C)
                EXIT PERFORM
            END-IF
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
            IF LS-TEXT = "WHERE" OR LS-TEXT = "GROUP"
               OR LS-TEXT = "ORDER" OR LS-TEXT = "JOIN"
               OR LS-TEXT = "END-EXEC" OR LS-TEXT = "ON"
               OR LS-TEXT = "FETCH" OR LS-TEXT = "FOR"
               OR LS-TEXT = "WITH" OR LS-TEXT = "UNION"
               OR LS-TEXT = "HAVING" OR LS-TEXT = "INNER"
               OR LS-TEXT = "LEFT" OR LS-TEXT = "RIGHT"
               OR LS-TEXT = "FULL" OR LS-TEXT = "CROSS"
               OR LS-TEXT = "EXCEPT" OR LS-TEXT = "INTERSECT"
                EXIT PERFORM
            END-IF
            PERFORM COMMA-BEFORE-C
            IF LS-FOUND-COMMA = "Y"
                PERFORM SQL-TABLE-AT-C
            ELSE
                ADD 1 TO LS-C
            END-IF
        END-PERFORM
    END-IF.

*> LS-FOUND-COMMA = "Y" when the source between token LS-C and the one
*> before it holds a comma.
COMMA-BEFORE-C.
    MOVE "N" TO LS-FOUND-COMMA
    COMPUTE LS-I = LS-C - 1
    IF LS-I < 1 OR TK-SRC-LINE(LS-C) = 0 OR TK-SRC-LINE(LS-I) = 0
        EXIT PARAGRAPH
    END-IF
    *> The rest of the earlier token's line, then the start of this
    *> token's line when it is another.
    MOVE TK-SRC-LINE(LS-I) TO LS-SRC-LINE
    COMPUTE LS-START = TK-COLUMN(LS-I) + TK-SPAN(LS-I)
    IF TK-SRC-LINE(LS-C) = LS-SRC-LINE
        COMPUTE LS-END = TK-COLUMN(LS-C) - 1
    ELSE
        MOVE SL-TEXT-LEN(LS-SRC-LINE) TO LS-END
    END-IF
    PERFORM COMMA-IN-RANGE
    IF LS-FOUND-COMMA = "Y" OR TK-SRC-LINE(LS-C) = LS-SRC-LINE
        EXIT PARAGRAPH
    END-IF
    MOVE TK-SRC-LINE(LS-C) TO LS-SRC-LINE
    MOVE 1 TO LS-START
    COMPUTE LS-END = TK-COLUMN(LS-C) - 1
    PERFORM COMMA-IN-RANGE.

COMMA-IN-RANGE.
    IF LS-SRC-LINE > SS-LINE-COUNT
        EXIT PARAGRAPH
    END-IF
    IF LS-END > SL-TEXT-LEN(LS-SRC-LINE)
        MOVE SL-TEXT-LEN(LS-SRC-LINE) TO LS-END
    END-IF
    PERFORM VARYING LS-K FROM LS-START BY 1 UNTIL LS-K > LS-END
        IF SS-HEAP(SL-TEXT-OFF(LS-SRC-LINE) + LS-K - 1:1) = ","
            MOVE "Y" TO LS-FOUND-COMMA
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> DECLARE name TABLE (...).
SQL-DECLARED-TABLE.
    PERFORM VARYING LS-K FROM LS-C BY 1 UNTIL LS-K > LS-C + 3
                                          OR LS-K >= TK-COUNT
        IF TK-IS-WORD(LS-K)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
            IF LS-TEXT = "TABLE"
                MOVE "T" TO LS-KIND
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> The table named from token LS-C: a word, or word.word; LS-C is left
*> after it. A parenthesis (a subquery) or a host variable is not one.
SQL-TABLE-AT-C.
    IF LS-C >= TK-COUNT OR NOT TK-IS-WORD(LS-C)
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-TABLE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
    MOVE LS-TEXT TO LS-TABLE
    MOVE LS-C TO LS-K
    ADD 1 TO LS-C
    IF LS-C < TK-COUNT AND TK-IS-OPERATOR(LS-C)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
        IF LS-TEXT = "." AND TK-IS-WORD(LS-C + 1)
            ADD 1 TO LS-C
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
            STRING LS-TABLE DELIMITED BY SPACE
                   "." DELIMITED BY SIZE
                   LS-TEXT DELIMITED BY SPACE
                INTO LS-TABLE-FULL
            MOVE LS-TABLE-FULL TO LS-TABLE
            MOVE SPACES TO LS-TABLE-FULL
            ADD 1 TO LS-C
        END-IF
    END-IF
    IF PQ-COUNT >= PQ-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PQ-COUNT
    MOVE LS-P TO PQ-PROGRAM(PQ-COUNT)
    MOVE FUNCTION UPPER-CASE(LS-TABLE) TO PQ-TABLE(PQ-COUNT)
    MOVE LS-KIND TO PQ-KIND(PQ-COUNT)
    MOVE LS-T TO LS-I
    MOVE LS-K TO LS-T
    PERFORM TOKEN-POSITION
    MOVE LS-I TO LS-T
    MOVE LS-FILE-ID TO PQ-FILE-ID(PQ-COUNT)
    MOVE LS-LINE TO PQ-LINE(PQ-COUNT)
    MOVE LS-COLUMN TO PQ-COLUMN(PQ-COUNT)
    MOVE LS-SRC-LINE TO PQ-SRC-LINE(PQ-COUNT).

*> Literals that could be program names, with the program they are in.
NOTE-LITERALS.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-PROG-COUNT
        MOVE WS-PROG-NODE(LS-I) TO LS-UP
        MOVE WS-PROG-INDEX(LS-I) TO LS-P
        PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-UP) BY 1
                UNTIL LS-T > ND-TOK-LAST(LS-UP)
            IF TK-IS-ALNUM(LS-T) AND TK-PREFIX(LS-T) = SPACES
               AND TK-TEXT-LEN(LS-T) > 0 AND TK-TEXT-LEN(LS-T) <= 8
                PERFORM NOTE-LITERAL
            END-IF
        END-PERFORM
    END-PERFORM.

NOTE-LITERAL.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    IF LS-WORD(1:1) NOT ALPHABETIC-UPPER OR LS-WORD(1:1) = SPACE
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > LS-LEN
        IF LS-WORD(LS-C:1) NOT ALPHABETIC-UPPER
           AND LS-WORD(LS-C:1) NOT NUMERIC
           AND LS-WORD(LS-C:1) NOT = "#" AND NOT = "@" AND NOT = "$"
           AND LS-WORD(LS-C:1) NOT = "-"
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF PL-COUNT < PL-MAX
        ADD 1 TO PL-COUNT
        MOVE LS-P TO PL-PROGRAM(PL-COUNT)
        MOVE LS-WORD TO PL-NAME(PL-COUNT)
    END-IF.

*> Files -----------------------------------------------------------

*> SELECT [OPTIONAL] name ASSIGN [TO|USING] assignment.
ADD-FILE.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0 OR ND-NAME(LS-N) = 0
        EXIT PARAGRAPH
    END-IF
    IF PF-COUNT >= PF-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PF-COUNT
    MOVE LS-P TO PF-PROGRAM(PF-COUNT)
    MOVE ND-NAME(LS-N) TO LS-T
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO PF-NAME(PF-COUNT)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO PF-FILE-ID(PF-COUNT)
    MOVE LS-LINE TO PF-LINE(PF-COUNT)
    MOVE LS-COLUMN TO PF-COLUMN(PF-COUNT)
    MOVE LS-SRC-LINE TO PF-SRC-LINE(PF-COUNT)
    MOVE SPACES TO PF-DDNAME(PF-COUNT)
    MOVE 0 TO PF-ALTERNATES(PF-COUNT)
    MOVE "N" TO PF-OPTIONAL(PF-COUNT) PF-SORT(PF-COUNT)
        PF-INPUT(PF-COUNT) PF-OUTPUT(PF-COUNT) PF-I-O(PF-COUNT)
        PF-EXTEND(PF-COUNT)
    PERFORM RECORD-SIZE
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "OPTIONAL" AND LS-T < ND-NAME(LS-N)
                MOVE "Y" TO PF-OPTIONAL(PF-COUNT)
            END-IF
            IF LS-WORD = "ALTERNATE"
                ADD 1 TO PF-ALTERNATES(PF-COUNT)
            END-IF
            IF LS-WORD = "ASSIGN" AND PF-DDNAME(PF-COUNT) = SPACES
                MOVE LS-T TO LS-C
                ADD 1 TO LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                IF TK-IS-WORD(LS-T)
                   AND (LS-WORD = "TO" OR LS-WORD = "USING")
                    ADD 1 TO LS-T
                END-IF
                MOVE LS-T TO LS-R
                PERFORM ASSIGNED-DD-NAME
                MOVE LS-R TO LS-T
            END-IF
        END-IF
    END-PERFORM.

*> PF-RECORD-SIZE: the largest 01 record under the FD or SD of the
*> same name in the program of the SELECT (node LS-N).
RECORD-SIZE.
    MOVE 0 TO PF-RECORD-SIZE(PF-COUNT)
    MOVE LS-N TO LS-FD-UP
    PERFORM PROG-ABOVE
    MOVE LS-FD-UP TO LS-SEL-PROG
    PERFORM VARYING LS-FD FROM 1 BY 1 UNTIL LS-FD > AS-COUNT
        IF ND-KIND(LS-FD) = "FD" AND ND-NAME(LS-FD) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-FD)
                LS-FD-NAME LS-LEN
            IF FUNCTION UPPER-CASE(LS-FD-NAME) = PF-NAME(PF-COUNT)
                MOVE LS-FD TO LS-FD-UP
                PERFORM PROG-ABOVE
                IF LS-FD-UP = LS-SEL-PROG
                    PERFORM FD-RECORDS
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> The 01 records of FD node LS-FD, by their symbols.
FD-RECORDS.
    MOVE ND-FIRST(LS-FD) TO LS-REC
    PERFORM UNTIL LS-REC = 0
        IF ND-KIND(LS-REC) = "DATA"
            PERFORM VARYING LS-SYM FROM 1 BY 1 UNTIL LS-SYM > SY-COUNT
                IF SY-NODE(LS-SYM) = LS-REC
                    IF SY-SIZE(LS-SYM) > PF-RECORD-SIZE(PF-COUNT)
                        MOVE SY-SIZE(LS-SYM) TO PF-RECORD-SIZE(PF-COUNT)
                    END-IF
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-REC) TO LS-REC
    END-PERFORM.

*> LS-FD-UP: the PROG node above node LS-FD-UP.
PROG-ABOVE.
    PERFORM UNTIL LS-FD-UP = 0
        IF ND-KIND(LS-FD-UP) = "PROG"
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-FD-UP) TO LS-FD-UP
    END-PERFORM.

*> PF-DDNAME from the assignment at LS-T: a name, or a literal, that
*> is not a data item of the program.
ASSIGNED-DD-NAME.
    IF LS-T > ND-TOK-LAST(LS-N)
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(LS-T) AND NOT TK-IS-ALNUM(LS-T)
        EXIT PARAGRAPH
    END-IF
    IF WS-REF-AT(LS-T) > 0
        IF RF-KIND(WS-REF-AT(LS-T)) = "D"
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF TK-TEXT-LEN(LS-T) > 31
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    *> A data item holding the name (the environment division's names
    *> are not in the reference table).
    IF TK-IS-WORD(LS-T)
        PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
            IF SY-NAME(LS-S) = LS-WORD
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
    END-IF
    *> The DD name is the last part: UT-S-INFILE, S-INFILE, AS-INFILE.
    MOVE 0 TO LS-I
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > LS-LEN
        IF LS-WORD(LS-C:1) = "-"
            MOVE LS-C TO LS-I
        END-IF
    END-PERFORM
    IF LS-I > 0
        MOVE LS-WORD(LS-I + 1:) TO LS-TEXT
    ELSE
        MOVE LS-WORD TO LS-TEXT
    END-IF
    *> A DD name has 1 to 8 letters, digits, or national characters,
    *> and does not start with a digit.
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-LEN
    IF LS-LEN = 0 OR LS-LEN > 8
        EXIT PARAGRAPH
    END-IF
    IF LS-TEXT(1:1) IS NUMERIC
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > LS-LEN
        IF LS-TEXT(LS-C:1) NOT ALPHABETIC-UPPER
           AND LS-TEXT(LS-C:1) NOT NUMERIC
           AND LS-TEXT(LS-C:1) NOT = "#" AND NOT = "@" AND NOT = "$"
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    *> Device names of other compilers are not DD names.
    EVALUATE LS-TEXT
        WHEN "DISK" WHEN "PRINTER" WHEN "KEYBOARD" WHEN "DISPLAY"
        WHEN "CARD-READER" WHEN "RANDOM" WHEN "DYNAMIC" WHEN "EXTERNAL"
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE LS-TEXT TO PF-DDNAME(PF-COUNT).

*> SD name: a sort or merge work file, which the sort program
*> allocates; it needs no DD of its own.
NOTE-SORT-FILE.
    IF ND-NAME(LS-N) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    MOVE ND-NAME(LS-N) TO LS-T
    PERFORM TOKEN-NAME
    PERFORM VARYING LS-I FROM PF-COUNT BY -1 UNTIL LS-I = 0
        IF PF-PROGRAM(LS-I) = LS-P AND PF-NAME(LS-I) = LS-TEXT
            MOVE "Y" TO PF-SORT(LS-I)
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> OPEN {INPUT|OUTPUT|I-O|EXTEND} names ...: each file named gets the
*> mode before it.
NOTE-OPEN.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACE TO LS-MODE
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE LS-WORD
                WHEN "INPUT"   MOVE "I" TO LS-MODE
                WHEN "OUTPUT"  MOVE "O" TO LS-MODE
                WHEN "I-O"     MOVE "U" TO LS-MODE
                WHEN "EXTEND"  MOVE "E" TO LS-MODE
                WHEN OTHER
                    IF LS-MODE NOT = SPACE
                        PERFORM NOTE-OPEN-FILE
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM.

NOTE-OPEN-FILE.
    PERFORM VARYING LS-I FROM PF-COUNT BY -1 UNTIL LS-I = 0
        IF PF-PROGRAM(LS-I) = LS-P AND PF-NAME(LS-I) = LS-WORD
            EVALUATE LS-MODE
                WHEN "I"  MOVE "Y" TO PF-INPUT(LS-I)
                WHEN "O"  MOVE "Y" TO PF-OUTPUT(LS-I)
                WHEN "U"  MOVE "Y" TO PF-I-O(LS-I)
                WHEN "E"  MOVE "Y" TO PF-EXTEND(LS-I)
            END-EVALUATE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Maps --------------------------------------------------------------

*> EXEC CICS SEND MAP(name) [MAPSET(name)] or RECEIVE MAP(...).
NOTE-MAP.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = "CICS"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD = "SEND"
        MOVE "S" TO LS-KIND
    ELSE
        IF LS-WORD = "RECEIVE"
            MOVE "R" TO LS-KIND
        ELSE
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE SPACES TO LS-MAP-NAME LS-MAPSET-NAME
    MOVE 0 TO LS-MAP-TOKEN
    PERFORM VARYING LS-T FROM LS-T BY 1 UNTIL LS-T >= ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            COMPUTE LS-C = LS-T + 1
            IF (LS-WORD = "MAP" OR LS-WORD = "MAPSET")
               AND TK-IS-LPAREN(LS-C)
                ADD 1 TO LS-C
                PERFORM CONSTANT-TEXT
                IF LS-WORD = "MAP"
                    MOVE LS-TEXT TO LS-MAP-NAME
                    MOVE LS-C TO LS-MAP-TOKEN
                ELSE
                    MOVE LS-TEXT TO LS-MAPSET-NAME
                END-IF
            END-IF
        END-IF
    END-PERFORM
    *> SEND TEXT, SEND CONTROL, or a map named at run time.
    IF LS-MAP-TOKEN = 0 OR LS-MAP-NAME = SPACES
        EXIT PARAGRAPH
    END-IF
    IF LS-MAPSET-NAME = SPACES
        MOVE LS-MAP-NAME TO LS-MAPSET-NAME
        *> A MAPSET operand that is not a constant: unknown.
        PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
                UNTIL LS-T >= ND-TOK-LAST(LS-N)
            IF TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                IF LS-WORD = "MAPSET"
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-PERFORM
    END-IF
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0 OR PM-COUNT >= PM-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PM-COUNT
    MOVE LS-P TO PM-PROGRAM(PM-COUNT)
    MOVE LS-KIND TO PM-COMMAND(PM-COUNT)
    MOVE LS-MAP-NAME TO PM-MAP(PM-COUNT)
    MOVE LS-MAPSET-NAME TO PM-MAPSET(PM-COUNT)
    MOVE LS-MAP-TOKEN TO LS-T
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO PM-FILE-ID(PM-COUNT)
    MOVE LS-LINE TO PM-LINE(PM-COUNT)
    MOVE LS-COLUMN TO PM-COLUMN(PM-COUNT)
    MOVE LS-SRC-LINE TO PM-SRC-LINE(PM-COUNT).

*> LS-NAMING = "Y" when reference LS-I is the operand of an EXEC
*> option that names a resource (PSB((X)), MAP(X), FILE(X), ...): the
*> command only reads it, though the reference table cannot say so.
TEST-NAMING-OPERAND.
    MOVE "N" TO LS-NAMING
    COMPUTE LS-K = RF-TOKEN(LS-I) - 1
    IF LS-K < 2 OR NOT TK-IS-LPAREN(LS-K)
        EXIT PARAGRAPH
    END-IF
    SUBTRACT 1 FROM LS-K
    IF TK-IS-LPAREN(LS-K)
        SUBTRACT 1 FROM LS-K
    END-IF
    IF LS-K < 1 OR NOT TK-IS-WORD(LS-K)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD LS-LEN
    EVALUATE LS-WORD
        WHEN "PSB" WHEN "MAP" WHEN "MAPSET" WHEN "FILE" WHEN "DATASET"
        WHEN "PROGRAM" WHEN "TRANSID" WHEN "QUEUE" WHEN "SEGMENT"
            MOVE "Y" TO LS-NAMING
    END-EVALUATE.

*> LS-TEXT = the constant at token LS-C, upper-cased: a literal, or a
*> data item whose VALUE is a literal and that no statement gives a
*> value; spaces when it is neither.
CONSTANT-TEXT.
    MOVE SPACES TO LS-TEXT
    IF LS-C > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    IF TK-IS-ALNUM(LS-C)
        IF TK-TEXT-LEN(LS-C) <= 8
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-TEXT LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
        END-IF
        EXIT PARAGRAPH
    END-IF
    *> The data item: from the reference table, or, for names that
    *> it does not hold (inside EXEC DLI), by name when only one item
    *> has it.
    MOVE 0 TO LS-S
    IF WS-REF-AT(LS-C) > 0
        MOVE WS-REF-AT(LS-C) TO LS-R
        IF RF-KIND(LS-R) NOT = "D"
            EXIT PARAGRAPH
        END-IF
        MOVE RF-SYMBOL(LS-R) TO LS-S
    ELSE
        IF NOT TK-IS-WORD(LS-C)
            EXIT PARAGRAPH
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-WORD LS-LEN
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > SY-COUNT
            IF SY-NAME(LS-I) = LS-WORD
                IF LS-S > 0
                    EXIT PARAGRAPH
                END-IF
                MOVE LS-I TO LS-S
            END-IF
        END-PERFORM
        IF LS-S = 0
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > RF-COUNT
        IF RF-SYMBOL(LS-I) = LS-S AND RF-KIND(LS-I) = "D"
           AND (RF-ROLE(LS-I) = "D" OR RF-ROLE(LS-I) = "B"
                OR RF-ROLE(LS-I) = "X")
            PERFORM TEST-NAMING-OPERAND
            IF LS-NAMING = "N"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    *> The literal of its VALUE clause.
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-I
    PERFORM UNTIL LS-I = 0
        IF ND-KIND(LS-I) = "CLAU" AND ND-DETAIL(LS-I) = "VALUE"
            PERFORM VARYING LS-K FROM ND-TOK-FIRST(LS-I) BY 1
                    UNTIL LS-K > ND-TOK-LAST(LS-I)
                IF TK-IS-ALNUM(LS-K) AND TK-TEXT-LEN(LS-K) <= 8
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
                    EXIT PARAGRAPH
                END-IF
            END-PERFORM
            EXIT PARAGRAPH
        END-IF
        MOVE ND-NEXT(LS-I) TO LS-I
    END-PERFORM.

*> CICS resources --------------------------------------------------

*> EXEC CICS command ... KEYWORD(name): the files, transactions,
*> programs, mapsets, and transient data queues the command names, when
*> the name is a constant.
NOTE-RESOURCES.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = "CICS"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P > 0
        MOVE "Y" TO CP-CICS(LS-P)
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-COMMAND LS-LEN
    COMPUTE LS-C = LS-T + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C LS-WORD LS-LEN
    MOVE LS-WORD TO LS-QUEUE-KIND
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM LS-T BY 1 UNTIL LS-T >= ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE SPACE TO LS-KIND
            EVALUATE LS-WORD
                WHEN "FILE" WHEN "DATASET"
                    MOVE "F" TO LS-KIND
                WHEN "TRANSID"
                    MOVE "T" TO LS-KIND
                WHEN "PROGRAM"
                    IF LS-COMMAND = "XCTL" OR LS-COMMAND = "LINK"
                       OR LS-COMMAND = "LOAD"
                        MOVE "P" TO LS-KIND
                    END-IF
                WHEN "MAPSET"
                    MOVE "M" TO LS-KIND
                WHEN "QUEUE"
                    IF LS-QUEUE-KIND = "TD"
                        MOVE "Q" TO LS-KIND
                    END-IF
            END-EVALUATE
            COMPUTE LS-C = LS-T + 1
            IF LS-KIND NOT = SPACE AND TK-IS-LPAREN(LS-C)
                ADD 1 TO LS-C
                PERFORM CONSTANT-TEXT
                IF LS-TEXT NOT = SPACES
                    PERFORM ADD-RESOURCE-USE
                END-IF
            END-IF
        END-IF
    END-PERFORM.

ADD-RESOURCE-USE.
    IF PU-COUNT >= PU-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PU-COUNT
    MOVE LS-P TO PU-PROGRAM(PU-COUNT)
    MOVE LS-KIND TO PU-KIND(PU-COUNT)
    MOVE LS-TEXT TO PU-NAME(PU-COUNT)
    MOVE LS-COMMAND TO PU-COMMAND(PU-COUNT)
    MOVE LS-T TO LS-K
    MOVE LS-C TO LS-T
    PERFORM TOKEN-POSITION
    MOVE LS-K TO LS-T
    MOVE LS-FILE-ID TO PU-FILE-ID(PU-COUNT)
    MOVE LS-LINE TO PU-LINE(PU-COUNT)
    MOVE LS-COLUMN TO PU-COLUMN(PU-COUNT).

*> IMS DL/I --------------------------------------------------------

*> EXEC DLI function ... SEGMENT(name) ... or SCHD PSB(name). A name
*> in double parentheses is a data item holding it.
NOTE-DLI.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = "DLI"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-COMMAND LS-LEN
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM LS-T BY 1 UNTIL LS-T >= ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE SPACE TO LS-KIND
            IF LS-WORD = "SEGMENT"
                MOVE "S" TO LS-KIND
            END-IF
            IF LS-WORD = "PSB" AND LS-COMMAND = "SCHD"
                MOVE "P" TO LS-KIND
            END-IF
            COMPUTE LS-C = LS-T + 1
            IF LS-KIND NOT = SPACE AND TK-IS-LPAREN(LS-C)
                ADD 1 TO LS-C
                MOVE SPACES TO LS-TEXT
                IF TK-IS-LPAREN(LS-C)
                    ADD 1 TO LS-C
                    PERFORM CONSTANT-TEXT
                ELSE
                    IF TK-IS-WORD(LS-C)
                        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-C
                            LS-TEXT LS-LEN
                    END-IF
                END-IF
                IF LS-TEXT NOT = SPACES
                    PERFORM ADD-DLI-USE
                END-IF
            END-IF
        END-IF
    END-PERFORM.

ADD-DLI-USE.
    IF PD-COUNT >= PD-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PD-COUNT
    MOVE LS-P TO PD-PROGRAM(PD-COUNT)
    MOVE LS-COMMAND TO PD-FUNCTION(PD-COUNT)
    MOVE LS-KIND TO PD-KIND(PD-COUNT)
    MOVE LS-TEXT TO PD-NAME(PD-COUNT)
    MOVE LS-T TO LS-K
    MOVE LS-C TO LS-T
    PERFORM TOKEN-POSITION
    MOVE LS-K TO LS-T
    MOVE LS-FILE-ID TO PD-FILE-ID(PD-COUNT)
    MOVE LS-LINE TO PD-LINE(PD-COUNT)
    MOVE LS-COLUMN TO PD-COLUMN(PD-COUNT)
    MOVE LS-SRC-LINE TO PD-SRC-LINE(PD-COUNT).

*> Programs and parameters ----------------------------------------

ADD-PROGRAM.
    MOVE ND-PARENT(LS-N) TO LS-UP
    PERFORM PROGRAM-OF-NODE
    MOVE LS-P TO LS-OWNER
    IF CP-COUNT >= CP-MAX OR WS-PROG-COUNT >= WS-PROG-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CP-COUNT
    MOVE CP-COUNT TO LS-P
    ADD 1 TO WS-PROG-COUNT
    MOVE LS-N TO WS-PROG-NODE(WS-PROG-COUNT)
    MOVE LS-P TO WS-PROG-INDEX(WS-PROG-COUNT)
    MOVE "P" TO CP-KIND(LS-P)
    MOVE LS-P TO CP-OWNER(LS-P)
    MOVE LS-OWNER TO CP-PARENT(LS-P)
    MOVE "N" TO CP-COMMON(LS-P) CP-RECURSIVE(LS-P) CP-CICS(LS-P)
    MOVE CA-COUNT TO CP-PARAM-FIRST(LS-P)
    ADD 1 TO CP-PARAM-FIRST(LS-P)
    MOVE 0 TO CP-PARAM-COUNT(LS-P)
    MOVE 0 TO CP-STOP-FILE-ID(LS-P) CP-STOP-LINE(LS-P)
        CP-STOP-COLUMN(LS-P) CP-STOP-SRC-LINE(LS-P)
    MOVE ND-NAME(LS-N) TO LS-T
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CP-NAME(LS-P)
    PERFORM TOKEN-SPELLING
    MOVE LS-SPELLING TO CP-SPELLING(LS-P)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CP-FILE-ID(LS-P)
    MOVE LS-LINE TO CP-LINE(LS-P)
    MOVE LS-COLUMN TO CP-COLUMN(LS-P)
    MOVE LS-SRC-LINE TO CP-SRC-LINE(LS-P)
    *> PROGRAM-ID. NAME [IS] [COMMON] [INITIAL] [RECURSIVE] [PROGRAM].
    IF LS-T = 0
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    PERFORM UNTIL LS-T > TK-COUNT
        IF TK-IS-PERIOD(LS-T) OR TK-IS-EOF(LS-T)
            EXIT PERFORM
        END-IF
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE LS-WORD
                WHEN "COMMON"
                    MOVE "Y" TO CP-COMMON(LS-P)
                WHEN "RECURSIVE"
                    MOVE "Y" TO CP-RECURSIVE(LS-P)
            END-EVALUATE
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> STOP RUN: remember the first of each program.
NOTE-STOP-RUN.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-T > TK-COUNT OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = "RUN"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    IF CP-STOP-LINE(LS-P) > 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-FIRST(LS-N) TO LS-T
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CP-STOP-FILE-ID(LS-P)
    MOVE LS-LINE TO CP-STOP-LINE(LS-P)
    MOVE LS-COLUMN TO CP-STOP-COLUMN(LS-P)
    MOVE LS-SRC-LINE TO CP-STOP-SRC-LINE(LS-P).

*> LS-P = the program in the graph whose PROG node contains node
*> LS-UP (LS-UP itself included); 0 when there is none.
PROGRAM-OF-NODE.
    MOVE 0 TO LS-P
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "PROG"
            PERFORM VARYING LS-I FROM 1 BY 1
                    UNTIL LS-I > WS-PROG-COUNT
                IF WS-PROG-NODE(LS-I) = LS-UP
                    MOVE WS-PROG-INDEX(LS-I) TO LS-P
                    EXIT PERFORM
                END-IF
            END-PERFORM
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> A PROCEDURE DIVISION USING item: BY VALUE when the nearest of
*> USING, REFERENCE, and VALUE before it is VALUE.
ADD-USING-PARAMETER.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "R" TO LS-MODE
    MOVE ND-TOK-FIRST(LS-N) TO LS-T
    PERFORM UNTIL LS-T <= 1
        SUBTRACT 1 FROM LS-T
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "VALUE"
                MOVE "V" TO LS-MODE
            END-IF
            IF LS-WORD = "VALUE" OR LS-WORD = "REFERENCE"
               OR LS-WORD = "USING"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    MOVE ND-NAME(LS-N) TO LS-T
    PERFORM ADD-PARAMETER.

*> Add the item named at token LS-T, passed in mode LS-MODE, to the
*> parameters of program LS-P.
ADD-PARAMETER.
    IF CA-COUNT >= CA-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    IF CP-PARAM-COUNT(LS-P) = 0
        MOVE CA-COUNT TO CP-PARAM-FIRST(LS-P)
        ADD 1 TO CP-PARAM-FIRST(LS-P)
    END-IF
    ADD 1 TO CA-COUNT
    ADD 1 TO CP-PARAM-COUNT(LS-P)
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CA-NAME(CA-COUNT)
    MOVE LS-MODE TO CA-MODE(CA-COUNT)
    PERFORM SIZE-AT-TOKEN
    MOVE LS-SIZE TO CA-SIZE(CA-COUNT).

*> ENTRY "NAME" [USING [BY REFERENCE|VALUE] item...]: another way
*> into the program containing it, with parameters of its own.
ADD-ENTRY.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    MOVE LS-P TO LS-OWNER
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-OWNER = 0 OR LS-T > ND-TOK-LAST(LS-N)
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-ALNUM(LS-T)
        EXIT PARAGRAPH
    END-IF
    IF CP-COUNT >= CP-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CP-COUNT
    MOVE CP-COUNT TO LS-P
    MOVE "E" TO CP-KIND(LS-P)
    MOVE LS-OWNER TO CP-OWNER(LS-P)
    MOVE CP-PARENT(LS-OWNER) TO CP-PARENT(LS-P)
    MOVE "N" TO CP-COMMON(LS-P)
    MOVE CP-RECURSIVE(LS-OWNER) TO CP-RECURSIVE(LS-P)
    MOVE CA-COUNT TO CP-PARAM-FIRST(LS-P)
    ADD 1 TO CP-PARAM-FIRST(LS-P)
    MOVE 0 TO CP-PARAM-COUNT(LS-P)
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CP-NAME(LS-P)
    PERFORM TOKEN-SPELLING
    MOVE LS-SPELLING TO CP-SPELLING(LS-P)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CP-FILE-ID(LS-P)
    MOVE LS-LINE TO CP-LINE(LS-P)
    MOVE LS-COLUMN TO CP-COLUMN(LS-P)
    MOVE LS-SRC-LINE TO CP-SRC-LINE(LS-P)
    MOVE "R" TO LS-MODE
    ADD 1 TO LS-T
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE LS-WORD
                WHEN "REFERENCE"
                    MOVE "R" TO LS-MODE
                WHEN "VALUE"
                    MOVE "V" TO LS-MODE
            END-EVALUATE
            IF WS-REF-AT(LS-T) > 0
                MOVE WS-REF-AT(LS-T) TO LS-R
                PERFORM ADD-PARAMETER
                MOVE RF-LAST(LS-R) TO LS-T
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> Calls ----------------------------------------------------------

ADD-CALL.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    PERFORM CALL-LIMIT
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-P = 0 OR LS-T > LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    IF CC-COUNT >= CC-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CC-COUNT
    MOVE CC-COUNT TO LS-C
    MOVE LS-P TO CC-FROM(LS-C)
    MOVE 0 TO CC-TO(LS-C) CC-MATCHES(LS-C) CC-ARG-COUNT(LS-C)
    MOVE CG-COUNT TO CC-ARG-FIRST(LS-C)
    ADD 1 TO CC-ARG-FIRST(LS-C)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CC-FILE-ID(LS-C)
    MOVE LS-LINE TO CC-LINE(LS-C)
    MOVE LS-COLUMN TO CC-COLUMN(LS-C)
    MOVE LS-SRC-LINE TO CC-SRC-LINE(LS-C)
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CC-TARGET(LS-C)
    PERFORM TOKEN-SPELLING
    MOVE LS-SPELLING TO CC-SPELLING(LS-C)
    IF TK-IS-ALNUM(LS-T)
        MOVE "N" TO CC-DYNAMIC(LS-C)
        ADD 1 TO LS-T
    ELSE
        MOVE "Y" TO CC-DYNAMIC(LS-C)
        IF WS-REF-AT(LS-T) > 0
            MOVE RF-LAST(WS-REF-AT(LS-T)) TO LS-T
        END-IF
        ADD 1 TO LS-T
    END-IF
    PERFORM UNTIL LS-T > LS-LIMIT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "USING"
                ADD 1 TO LS-T
                PERFORM CALL-ARGUMENTS
                EXIT PERFORM
            END-IF
            IF LS-WORD = "RETURNING" OR LS-WORD = "GIVING"
                EXIT PERFORM
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> LS-LIMIT = the last token of CALL statement LS-N's own phrases,
*> before any conditional phrase (ON EXCEPTION ...) it contains.
CALL-LIMIT.
    MOVE ND-TOK-LAST(LS-N) TO LS-LIMIT
    MOVE ND-FIRST(LS-N) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "BLCK" OR ND-KIND(LS-UP) = "STMT"
            COMPUTE LS-LIMIT = ND-TOK-FIRST(LS-UP) - 1
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-UP) TO LS-UP
    END-PERFORM.

*> The arguments after USING, up to RETURNING, a conditional phrase,
*> or the end of the statement. BY REFERENCE, CONTENT, and VALUE
*> apply to the arguments after them until the next one.
CALL-ARGUMENTS.
    MOVE "R" TO LS-MODE
    PERFORM UNTIL LS-T > LS-LIMIT
        EVALUATE TRUE
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                EVALUATE LS-WORD
                    WHEN "RETURNING" WHEN "GIVING" WHEN "ON"
                    WHEN "EXCEPTION" WHEN "OVERFLOW" WHEN "NOT"
                    WHEN "END-CALL"
                        EXIT PERFORM
                    WHEN "BY"
                        ADD 1 TO LS-T
                    WHEN "REFERENCE"
                        MOVE "R" TO LS-MODE
                        ADD 1 TO LS-T
                    WHEN "CONTENT"
                        MOVE "C" TO LS-MODE
                        ADD 1 TO LS-T
                    WHEN "VALUE"
                        MOVE "V" TO LS-MODE
                        ADD 1 TO LS-T
                    WHEN "SIZE"
                        *> BY VALUE ... SIZE [IS] n|AUTO|DEFAULT
                        PERFORM SKIP-SIZE-PHRASE
                    WHEN "OMITTED"
                        MOVE "O" TO LS-KIND
                        MOVE 0 TO LS-SIZE
                        MOVE LS-WORD TO LS-TEXT
                        PERFORM ADD-ARGUMENT
                        ADD 1 TO LS-T
                    WHEN "ADDRESS" WHEN "LENGTH" WHEN "BYTE-LENGTH"
                        PERFORM SPECIAL-REGISTER-ARGUMENT
                    WHEN "FUNCTION"
                        PERFORM FUNCTION-ARGUMENT
                    WHEN OTHER
                        PERFORM WORD-ARGUMENT
                END-EVALUATE
            WHEN TK-IS-ALNUM(LS-T)
                MOVE "L" TO LS-KIND
                MOVE 0 TO LS-SIZE
                IF TK-PREFIX(LS-T) = SPACES
                    MOVE TK-TEXT-LEN(LS-T) TO LS-SIZE
                END-IF
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                PERFORM JOIN-CONCATENATED
                PERFORM ADD-ARGUMENT
                ADD 1 TO LS-T
            WHEN TK-IS-NUMBER(LS-T)
                *> The size of a numeric literal depends on the
                *> compiler.
                MOVE "L" TO LS-KIND
                MOVE 0 TO LS-SIZE
                PERFORM TOKEN-NAME
                PERFORM ADD-ARGUMENT
                ADD 1 TO LS-T
            WHEN OTHER
                ADD 1 TO LS-T
        END-EVALUATE
    END-PERFORM.

*> "abc" & "def" is one literal: add the size of each further part
*> to LS-SIZE, and leave LS-T at the last part.
JOIN-CONCATENATED.
    PERFORM UNTIL LS-T + 2 > LS-LIMIT
        IF NOT TK-IS-OPERATOR(LS-T + 1)
           OR NOT TK-IS-ALNUM(LS-T + 2)
            EXIT PERFORM
        END-IF
        COMPUTE LS-I = LS-T + 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-WORD LS-LEN
        IF LS-WORD NOT = "&"
            EXIT PERFORM
        END-IF
        ADD 2 TO LS-T
        IF LS-SIZE > 0 AND TK-PREFIX(LS-T) = SPACES
            ADD TK-TEXT-LEN(LS-T) TO LS-SIZE
        ELSE
            MOVE 0 TO LS-SIZE
        END-IF
    END-PERFORM.

SKIP-SIZE-PHRASE.
    ADD 1 TO LS-T
    IF LS-T <= LS-LIMIT AND TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF LS-WORD = "IS"
            ADD 1 TO LS-T
        END-IF
    END-IF
    ADD 1 TO LS-T.

*> A data item argument, or a word Plumbline does not resolve (a
*> figurative constant such as ZERO or NULL).
WORD-ARGUMENT.
    PERFORM TOKEN-NAME
    MOVE WS-REF-AT(LS-T) TO LS-R
    IF LS-R > 0
        MOVE "D" TO LS-KIND
        PERFORM SIZE-AT-TOKEN
        PERFORM ADD-ARGUMENT
        MOVE RF-LAST(LS-R) TO LS-T
    ELSE
        MOVE "X" TO LS-KIND
        MOVE 0 TO LS-SIZE
        PERFORM ADD-ARGUMENT
    END-IF
    ADD 1 TO LS-T.

*> ADDRESS OF x, LENGTH OF x, BYTE-LENGTH OF x.
SPECIAL-REGISTER-ARGUMENT.
    MOVE "X" TO LS-KIND
    MOVE 0 TO LS-SIZE
    MOVE LS-WORD TO LS-TEXT
    PERFORM ADD-ARGUMENT
    ADD 1 TO LS-T
    IF LS-T > LS-LIMIT OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = "OF"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    IF LS-T <= LS-LIMIT AND WS-REF-AT(LS-T) > 0
        MOVE RF-LAST(WS-REF-AT(LS-T)) TO LS-T
    END-IF
    ADD 1 TO LS-T.

*> FUNCTION name [(arguments)].
FUNCTION-ARGUMENT.
    MOVE "X" TO LS-KIND
    MOVE 0 TO LS-SIZE
    ADD 1 TO LS-T
    PERFORM TOKEN-NAME
    PERFORM ADD-ARGUMENT
    ADD 1 TO LS-T
    IF LS-T > LS-LIMIT OR NOT TK-IS-LPAREN(LS-T)
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-T > LS-LIMIT
        IF TK-IS-LPAREN(LS-T)
            ADD 1 TO LS-DEPTH
        END-IF
        IF TK-IS-RPAREN(LS-T)
            SUBTRACT 1 FROM LS-DEPTH
        END-IF
        ADD 1 TO LS-T
        IF LS-DEPTH = 0
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Add argument LS-TEXT (kind LS-KIND, size LS-SIZE, mode LS-MODE)
*> to call LS-C.
ADD-ARGUMENT.
    IF CG-COUNT >= CG-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CG-COUNT
    ADD 1 TO CC-ARG-COUNT(LS-C)
    MOVE LS-TEXT TO CG-TEXT(CG-COUNT)
    MOVE LS-KIND TO CG-KIND(CG-COUNT)
    MOVE LS-MODE TO CG-MODE(CG-COUNT)
    MOVE LS-SIZE TO CG-SIZE(CG-COUNT).

*> Helpers --------------------------------------------------------

*> LS-SIZE = bytes of the data item referenced at token LS-T, or 0
*> when not known: unresolved, reference-modified, a whole table, or
*> an item without a fixed size (ANY LENGTH).
SIZE-AT-TOKEN.
    MOVE 0 TO LS-SIZE
    MOVE WS-REF-AT(LS-T) TO LS-R
    IF LS-R = 0
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF SY-LEVEL(LS-S) = 88 OR SY-LEVEL(LS-S) = 66
       OR SY-LEVEL(LS-S) = 78
        EXIT PARAGRAPH
    END-IF
    IF SY-OCCURS(LS-S) > 0 AND RF-SUBSCRIPTED(LS-R) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SY-SIZE(LS-S) TO LS-SIZE.

*> LS-TEXT = the upper-cased text of token LS-T (spaces for 0).
TOKEN-NAME.
    MOVE SPACES TO LS-TEXT
    IF LS-T > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    END-IF.

*> LS-SPELLING = token LS-T as written: the lexer upper-cases words,
*> so a word is taken from its source line; a literal's value keeps
*> its case.
TOKEN-SPELLING.
    MOVE SPACES TO LS-SPELLING
    IF LS-T < 1 OR LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-SPELLING LS-LEN
        EXIT PARAGRAPH
    END-IF
    MOVE TK-SRC-LINE(LS-T) TO LS-SRC-LINE
    IF LS-SRC-LINE = 0 OR LS-SRC-LINE > SS-LINE-COUNT
       OR TK-SPAN(LS-T) > 31 OR TK-SPAN(LS-T) = 0
       OR TK-COLUMN(LS-T) + TK-SPAN(LS-T) - 1 > SL-TEXT-LEN(LS-SRC-LINE)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-SPELLING LS-LEN
        EXIT PARAGRAPH
    END-IF
    MOVE SS-HEAP(SL-TEXT-OFF(LS-SRC-LINE) + TK-COLUMN(LS-T) - 1
        :TK-SPAN(LS-T)) TO LS-SPELLING.

*> Where token LS-T is.
TOKEN-POSITION.
    MOVE 0 TO LS-FILE-ID LS-LINE LS-COLUMN LS-SRC-LINE
    IF LS-T < 1 OR LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    MOVE TK-FILE-ID(LS-T) TO LS-FILE-ID
    MOVE TK-SRC-LINE(LS-T) TO LS-SRC-LINE
    MOVE TK-COLUMN(LS-T) TO LS-COLUMN
    IF LS-SRC-LINE > 0
        MOVE SL-LINE-NO(LS-SRC-LINE) TO LS-LINE
    END-IF.
END PROGRAM PLB-CALL-COLLECT.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CALL-RESOLVE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
*> The programs by name: a hash of the name picks a bucket, which
*> chains the programs of that name (and others of the same hash) in
*> program order, so that a call is not compared with every program.
78  CH-BUCKETS                  VALUE 4093.
01  WS-CP-HEAD              PIC 9(9) COMP-5 OCCURS CH-BUCKETS TIMES.
01  WS-CP-NEXT              PIC 9(9) COMP-5 OCCURS CP-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-HASH                 PIC 9(9) COMP-5.
01  LS-HASH-SUM             PIC 9(9) COMP-5.
01  LS-HASH-I               PIC 9(4) COMP-5.
01  LS-HASH-NAME            PIC X(31).
01  LS-C                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
01  LS-EXACT                PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-CALL-GRAPH.
    PERFORM VARYING LS-HASH FROM 1 BY 1 UNTIL LS-HASH > CH-BUCKETS
        MOVE 0 TO WS-CP-HEAD(LS-HASH)
    END-PERFORM
    PERFORM VARYING LS-P FROM CP-COUNT BY -1 UNTIL LS-P = 0
        MOVE CP-NAME(LS-P) TO LS-HASH-NAME
        PERFORM NAME-HASH
        MOVE WS-CP-HEAD(LS-HASH) TO WS-CP-NEXT(LS-P)
        MOVE LS-P TO WS-CP-HEAD(LS-HASH)
    END-PERFORM
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        MOVE 0 TO CC-TO(LS-C) CC-MATCHES(LS-C)
        IF CC-DYNAMIC(LS-C) = "N" AND CC-FROM(LS-C) > 0
            PERFORM RESOLVE-CALL
        END-IF
    END-PERFORM
    GOBACK.

RESOLVE-CALL.
    MOVE CC-FROM(LS-C) TO LS-FROM
    MOVE CC-TARGET(LS-C) TO LS-HASH-NAME
    PERFORM NAME-HASH
    *> 1. Contained in the caller, or the caller itself; a name spelled
    *> the same way, case included, before one that only matches
    *> without regard to case.
    MOVE WS-CP-HEAD(LS-HASH) TO LS-P
    PERFORM UNTIL LS-P = 0
        IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-KIND(LS-P) = "P"
           AND (CP-PARENT(LS-P) = LS-FROM OR LS-P = LS-FROM)
           AND CP-SPELLING(LS-P) = CC-SPELLING(LS-C)
            MOVE LS-P TO CC-TO(LS-C)
            MOVE 1 TO CC-MATCHES(LS-C)
            EXIT PARAGRAPH
        END-IF
        MOVE WS-CP-NEXT(LS-P) TO LS-P
    END-PERFORM
    MOVE WS-CP-HEAD(LS-HASH) TO LS-P
    PERFORM UNTIL LS-P = 0
        IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-KIND(LS-P) = "P"
           AND (CP-PARENT(LS-P) = LS-FROM OR LS-P = LS-FROM)
            MOVE LS-P TO CC-TO(LS-C)
            MOVE 1 TO CC-MATCHES(LS-C)
            EXIT PARAGRAPH
        END-IF
        MOVE WS-CP-NEXT(LS-P) TO LS-P
    END-PERFORM
    *> 2. COMMON programs of the programs containing the caller.
    MOVE CP-PARENT(LS-FROM) TO LS-A
    PERFORM UNTIL LS-A = 0
        MOVE WS-CP-HEAD(LS-HASH) TO LS-P
        PERFORM UNTIL LS-P = 0
            IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-KIND(LS-P) = "P"
               AND CP-COMMON(LS-P) = "Y" AND CP-PARENT(LS-P) = LS-A
                MOVE LS-P TO CC-TO(LS-C)
                MOVE 1 TO CC-MATCHES(LS-C)
                EXIT PARAGRAPH
            END-IF
            MOVE WS-CP-NEXT(LS-P) TO LS-P
        END-PERFORM
        MOVE CP-PARENT(LS-A) TO LS-A
    END-PERFORM
    *> 3. Outermost programs and their entry points.
    MOVE 0 TO LS-FOUND
    MOVE WS-CP-HEAD(LS-HASH) TO LS-P
    PERFORM UNTIL LS-P = 0
        IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-PARENT(LS-P) = 0
            ADD 1 TO CC-MATCHES(LS-C)
            MOVE LS-P TO LS-FOUND
        END-IF
        MOVE WS-CP-NEXT(LS-P) TO LS-P
    END-PERFORM
    IF CC-MATCHES(LS-C) = 1
        MOVE LS-FOUND TO CC-TO(LS-C)
    END-IF
    *> Several, told apart by case: the one spelled the same way.
    IF CC-MATCHES(LS-C) > 1
        MOVE 0 TO LS-EXACT LS-FOUND
        MOVE WS-CP-HEAD(LS-HASH) TO LS-P
        PERFORM UNTIL LS-P = 0
            IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-PARENT(LS-P) = 0
               AND CP-SPELLING(LS-P) = CC-SPELLING(LS-C)
                ADD 1 TO LS-EXACT
                MOVE LS-P TO LS-FOUND
            END-IF
            MOVE WS-CP-NEXT(LS-P) TO LS-P
        END-PERFORM
        IF LS-EXACT = 1
            MOVE LS-FOUND TO CC-TO(LS-C)
            MOVE 1 TO CC-MATCHES(LS-C)
        END-IF
    END-IF.

*> LS-HASH: the bucket of LS-HASH-NAME, 1 to CH-BUCKETS.
NAME-HASH.
    MOVE 0 TO LS-HASH-SUM
    PERFORM VARYING LS-HASH-I FROM 1 BY 1 UNTIL LS-HASH-I > 31
        IF LS-HASH-NAME(LS-HASH-I:1) = SPACE
            EXIT PERFORM
        END-IF
        COMPUTE LS-HASH-SUM = FUNCTION MOD(LS-HASH-SUM * 31
            + FUNCTION ORD(LS-HASH-NAME(LS-HASH-I:1)), CH-BUCKETS)
    END-PERFORM
    COMPUTE LS-HASH = LS-HASH-SUM + 1.
END PROGRAM PLB-CALL-RESOLVE.
