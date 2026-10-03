*> ---------------------------------------------------------------
*> plbcrud: the CRUD matrix of a run (plumbline crud): which programs
*> create, read, update, and delete which DB2 tables, COBOL files, and
*> CICS files.
*>
*>   DB2 tables    INSERT creates, SELECT and cursors read, UPDATE
*>                 updates, DELETE deletes (from the SQL model)
*>   COBOL files   WRITE creates, READ and START read, REWRITE
*>                 updates, DELETE deletes; WRITE and REWRITE name a
*>                 record, whose FD gives the file
*>   CICS files    EXEC CICS WRITE, READ (READNEXT, READPREV,
*>                 STARTBR), REWRITE, and DELETE, by their FILE or
*>                 DATASET: a literal, or an item whose VALUE is one,
*>                 else the item's name
*>
*> Each use counts for the innermost program it is in.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CRUD-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbcrud.cpy".
PROCEDURE DIVISION USING PLB-CRUD.
    MOVE 0 TO CX-COUNT CX-DROPPED
    GOBACK.
END PROGRAM PLB-CRUD-INIT.

*> PLB-CRUD-COLLECT: the uses of the file just analyzed.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CRUD-COLLECT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsqlm.cpy".
*> The PROG nodes of the file, to find a statement's program.
01  WS-PROG-COUNT           PIC 9(9) COMP-5.
01  WS-PROG                 PIC 9(9) COMP-5 OCCURS 1000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-FD                   PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-PROGRAM-NODE         PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC X(31).
01  LS-KIND                 PIC X.
01  LS-NAME                 PIC X(64).
01  LS-OP                   PIC X.
01  LS-TEXT                 PIC X(64).
01  LS-WORD                 PIC X(64).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-COMMAND              PIC X(31).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbcrud.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-CRUD.
    MOVE 0 TO WS-PROG-COUNT
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-KIND(LS-N) = "PROG" AND WS-PROG-COUNT < 1000
            ADD 1 TO WS-PROG-COUNT
            MOVE LS-N TO WS-PROG(WS-PROG-COUNT)
        END-IF
    END-PERFORM
    IF WS-PROG-COUNT = 0
        GOBACK
    END-IF
    PERFORM SQL-USES
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-KIND(LS-N) = "STMT"
            EVALUATE ND-DETAIL(LS-N)
                WHEN "READ"
                WHEN "START"
                WHEN "DELETE"
                WHEN "WRITE"
                WHEN "REWRITE"
                    PERFORM FILE-STATEMENT
                WHEN "EXEC"
                    PERFORM CICS-STATEMENT
            END-EVALUATE
        END-IF
    END-PERFORM
    GOBACK.

*> The tables of each SQL statement.
SQL-USES.
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    MOVE "T" TO LS-KIND
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > QS-COUNT
        EVALUATE QS-KIND(LS-S)
            WHEN "S"
            WHEN "C"
            WHEN "F"
                MOVE "R" TO LS-OP
            WHEN "I"
                MOVE "C" TO LS-OP
            WHEN "U"
                MOVE "U" TO LS-OP
            WHEN "D"
                MOVE "D" TO LS-OP
        END-EVALUATE
        MOVE QS-TOKEN(LS-S) TO LS-TOKEN
        PERFORM PROGRAM-OF-TOKEN
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > QS-TABLE-COUNT(LS-S)
            MOVE QS-TABLE(LS-S, LS-I) TO LS-NAME
            PERFORM ADD-USE
        END-PERFORM
    END-PERFORM.

*> A COBOL file statement: READ, START, and DELETE name the file;
*> WRITE and REWRITE a record of it.
FILE-STATEMENT.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-T > ND-TOK-LAST(LS-N) OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-NAME
    EVALUATE ND-DETAIL(LS-N)
        WHEN "READ"
        WHEN "START"
            MOVE "R" TO LS-OP
        WHEN "DELETE"
            MOVE "D" TO LS-OP
        WHEN "WRITE"
            MOVE "C" TO LS-OP
            PERFORM FILE-OF-RECORD
        WHEN "REWRITE"
            MOVE "U" TO LS-OP
            PERFORM FILE-OF-RECORD
    END-EVALUATE
    IF LS-NAME = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE "F" TO LS-KIND
    MOVE ND-TOK-FIRST(LS-N) TO LS-TOKEN
    PERFORM PROGRAM-OF-TOKEN
    PERFORM ADD-USE.

*> LS-NAME: the file whose FD has record LS-NAME; spaces when it is
*> not a record of a file (WRITE of a report line, say).
FILE-OF-RECORD.
    MOVE LS-NAME TO LS-WORD
    MOVE SPACES TO LS-NAME
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > SY-COUNT
        IF SY-NAME(LS-U) = LS-WORD AND SY-SECTION(LS-U) = "F"
           AND SY-PARENT(LS-U) = 0 AND SY-NODE(LS-U) > 0
            MOVE ND-PARENT(SY-NODE(LS-U)) TO LS-FD
            IF LS-FD > 0
                IF ND-KIND(LS-FD) = "FD" AND ND-NAME(LS-FD) > 0
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-FD)
                        LS-TEXT LS-LEN
                    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-NAME
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> EXEC CICS READ, READNEXT, READPREV, STARTBR, WRITE, REWRITE, or
*> DELETE with FILE( ) or DATASET( ).
CICS-STATEMENT.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "CICS"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-COMMAND
    EVALUATE LS-COMMAND
        WHEN "READ"
        WHEN "READNEXT"
        WHEN "READPREV"
        WHEN "STARTBR"
            MOVE "R" TO LS-OP
        WHEN "WRITE"
            MOVE "C" TO LS-OP
        WHEN "REWRITE"
            MOVE "U" TO LS-OP
        WHEN "DELETE"
            MOVE "D" TO LS-OP
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE SPACES TO LS-NAME
    PERFORM VARYING LS-T FROM LS-T BY 1
            UNTIL LS-T + 2 > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T) AND TK-IS-LPAREN(LS-T + 1)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-WORD
            IF LS-WORD = "FILE" OR LS-WORD = "DATASET"
                COMPUTE LS-E = LS-T + 2
                PERFORM FILE-OPERAND
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-NAME = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE "K" TO LS-KIND
    MOVE ND-TOK-FIRST(LS-N) TO LS-TOKEN
    PERFORM PROGRAM-OF-TOKEN
    PERFORM ADD-USE.

*> LS-NAME: the file named by token LS-E: a literal's text, or the
*> literal VALUE of the item it names, or else the item's name.
FILE-OPERAND.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-E LS-TEXT LS-LEN
    *> A literal's token text has no quotes.
    IF TK-IS-ALNUM(LS-E)
        MOVE LS-TEXT TO LS-NAME
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(LS-E)
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-WORD
    MOVE LS-WORD TO LS-NAME
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > SY-COUNT
        IF SY-NAME(LS-U) = LS-WORD AND SY-NODE(LS-U) > 0
            PERFORM ITEM-VALUE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> The literal of the VALUE clause of item LS-U, when it has one.
ITEM-VALUE.
    MOVE ND-FIRST(SY-NODE(LS-U)) TO LS-I
    PERFORM UNTIL LS-I = 0
        IF ND-KIND(LS-I) = "CLAU" AND ND-DETAIL(LS-I) = "VALUE"
            PERFORM VARYING LS-E FROM ND-TOK-FIRST(LS-I) BY 1
                    UNTIL LS-E > ND-TOK-LAST(LS-I)
                IF TK-IS-ALNUM(LS-E)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-E LS-TEXT
                        LS-LEN
                    MOVE LS-TEXT TO LS-NAME
                    EXIT PARAGRAPH
                END-IF
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-I) TO LS-I
    END-PERFORM.

*> LS-PROGRAM: the name of the innermost program around token LS-TOKEN.
PROGRAM-OF-TOKEN.
    MOVE 0 TO LS-PROGRAM-NODE
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-PROG-COUNT
        IF ND-TOK-FIRST(WS-PROG(LS-I)) <= LS-TOKEN
           AND ND-TOK-LAST(WS-PROG(LS-I)) >= LS-TOKEN
            MOVE WS-PROG(LS-I) TO LS-PROGRAM-NODE
        END-IF
    END-PERFORM
    MOVE SPACES TO LS-PROGRAM
    IF LS-PROGRAM-NODE > 0
        IF ND-NAME(LS-PROGRAM-NODE) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS
                ND-NAME(LS-PROGRAM-NODE) LS-TEXT LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-PROGRAM
        END-IF
    END-IF.

*> Operation LS-OP of LS-PROGRAM on LS-KIND resource LS-NAME.
ADD-USE.
    MOVE FUNCTION TRIM(LS-NAME) TO LS-NAME
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > CX-COUNT
        IF CX-PROGRAM(LS-E) = LS-PROGRAM AND CX-KIND(LS-E) = LS-KIND
           AND CX-NAME(LS-E) = LS-NAME
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-E > CX-COUNT
        IF CX-COUNT >= CX-MAX
            ADD 1 TO CX-DROPPED
            EXIT PARAGRAPH
        END-IF
        ADD 1 TO CX-COUNT
        MOVE CX-COUNT TO LS-E
        MOVE LS-PROGRAM TO CX-PROGRAM(LS-E)
        MOVE LS-KIND TO CX-KIND(LS-E)
        MOVE LS-NAME TO CX-NAME(LS-E)
        MOVE "N" TO CX-CREATE(LS-E) CX-READ(LS-E) CX-UPDATE(LS-E)
            CX-DELETE(LS-E)
    END-IF
    EVALUATE LS-OP
        WHEN "C" MOVE "Y" TO CX-CREATE(LS-E)
        WHEN "R" MOVE "Y" TO CX-READ(LS-E)
        WHEN "U" MOVE "Y" TO CX-UPDATE(LS-E)
        WHEN "D" MOVE "Y" TO CX-DELETE(LS-E)
    END-EVALUATE.
END PROGRAM PLB-CRUD-COLLECT.

*> PLB-CRUD-PRINT: the matrix, by program, kind, and name; as text,
*> CSV, or JSON.
*>   text   PROGRAM   KIND   RESOURCE   C R U D, with - for none
*>   csv    program,kind,resource,create,read,update,delete (Y or N)
*>   json   {"crud": [{"program": ..., "kind": ..., "resource": ...,
*>          "create": true, ...}, ...]}
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CRUD-PRINT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE                 PIC X(1024).
LOCAL-STORAGE SECTION.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-KIND-TEXT            PIC X(10).
LINKAGE SECTION.
COPY "plbcrud.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-CRUD LK-FORMAT.
    IF CX-COUNT > 1
        SORT CX-ENTRY ON ASCENDING KEY CX-PROGRAM CX-KIND CX-NAME
    END-IF
    EVALUATE LK-FORMAT
        WHEN "json"
            DISPLAY "{"
            DISPLAY '  "crud": ['
        WHEN "csv"
            DISPLAY "program,kind,resource,create,read,update,delete"
        WHEN OTHER
            IF CX-COUNT = 0
                DISPLAY "no tables or files used"
            END-IF
    END-EVALUATE
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > CX-COUNT
        EVALUATE CX-KIND(LS-E)
            WHEN "T" MOVE "table" TO LS-KIND-TEXT
            WHEN "F" MOVE "file" TO LS-KIND-TEXT
            WHEN OTHER MOVE "cics-file" TO LS-KIND-TEXT
        END-EVALUATE
        EVALUATE LK-FORMAT
            WHEN "json" PERFORM JSON-ENTRY
            WHEN "csv" PERFORM CSV-ENTRY
            WHEN OTHER PERFORM TEXT-ENTRY
        END-EVALUATE
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY "  ]"
        DISPLAY "}"
    END-IF
    GOBACK.

TEXT-ENTRY.
    MOVE SPACES TO WS-LINE
    MOVE CX-PROGRAM(LS-E) TO WS-LINE(1:)
    MOVE LS-KIND-TEXT TO WS-LINE(11:)
    MOVE CX-NAME(LS-E) TO WS-LINE(22:)
    MOVE 66 TO LS-PTR
    CALL "PLB-STR-LENGTH" USING CX-NAME(LS-E) LS-PTR
    IF LS-PTR < 44
        MOVE 66 TO LS-PTR
    ELSE
        COMPUTE LS-PTR = 22 + LS-PTR + 1
    END-IF
    IF CX-CREATE(LS-E) = "Y"
        MOVE "C" TO WS-LINE(LS-PTR:1)
    ELSE
        MOVE "-" TO WS-LINE(LS-PTR:1)
    END-IF
    IF CX-READ(LS-E) = "Y"
        MOVE "R" TO WS-LINE(LS-PTR + 2:1)
    ELSE
        MOVE "-" TO WS-LINE(LS-PTR + 2:1)
    END-IF
    IF CX-UPDATE(LS-E) = "Y"
        MOVE "U" TO WS-LINE(LS-PTR + 4:1)
    ELSE
        MOVE "-" TO WS-LINE(LS-PTR + 4:1)
    END-IF
    IF CX-DELETE(LS-E) = "Y"
        MOVE "D" TO WS-LINE(LS-PTR + 6:1)
    ELSE
        MOVE "-" TO WS-LINE(LS-PTR + 6:1)
    END-IF
    DISPLAY WS-LINE(1:LS-PTR + 6).

CSV-ENTRY.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING CX-PROGRAM(LS-E) DELIMITED BY SPACE
           "," DELIMITED BY SIZE
           LS-KIND-TEXT DELIMITED BY SPACE
           "," DELIMITED BY SIZE
           CX-NAME(LS-E) DELIMITED BY SPACE
           "," CX-CREATE(LS-E) "," CX-READ(LS-E) "," CX-UPDATE(LS-E)
           "," CX-DELETE(LS-E) DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    DISPLAY WS-LINE(1:LS-PTR - 1).

JSON-ENTRY.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '    {"program": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING CX-PROGRAM(LS-E) WS-LINE LS-PTR
    STRING ', "kind": "' DELIMITED BY SIZE
           LS-KIND-TEXT DELIMITED BY SPACE
           '", "resource": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING CX-NAME(LS-E) WS-LINE LS-PTR
    STRING ', "create": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM APPEND-BOOL-C
    STRING ', "read": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM APPEND-BOOL-R
    STRING ', "update": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM APPEND-BOOL-U
    STRING ', "delete": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM APPEND-BOOL-D
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-E < CX-COUNT
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    DISPLAY WS-LINE(1:LS-PTR - 1).

APPEND-BOOL-C.
    IF CX-CREATE(LS-E) = "Y"
        STRING "true" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "false" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF.

APPEND-BOOL-R.
    IF CX-READ(LS-E) = "Y"
        STRING "true" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "false" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF.

APPEND-BOOL-U.
    IF CX-UPDATE(LS-E) = "Y"
        STRING "true" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "false" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF.

APPEND-BOOL-D.
    IF CX-DELETE(LS-E) = "Y"
        STRING "true" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "false" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF.
END PROGRAM PLB-CRUD-PRINT.

*> PLB-CRUD-DOC: the rows of program PROGRAM, for its page of
*> plumbline doc:
*>     ## Tables and files
*>
*>     | Resource | Kind | Create | Read | Update | Delete |
*>     |---|---|:-:|:-:|:-:|:-:|
*>     | `ACCTDAT` | CICS file |  | yes | yes |  |
*> Nothing when the program uses none.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CRUD-DOC.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE                 PIC X(1024).
LOCAL-STORAGE SECTION.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-ROWS                 PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC X(31).
LINKAGE SECTION.
COPY "plbcrud.cpy".
01  LK-PROGRAM              PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-CRUD LK-PROGRAM.
    MOVE FUNCTION UPPER-CASE(LK-PROGRAM) TO LS-PROGRAM
    MOVE 0 TO LS-ROWS
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > CX-COUNT
        IF CX-PROGRAM(LS-E) = LS-PROGRAM
            IF LS-ROWS = 0
                DISPLAY "## Tables and files"
                DISPLAY " "
                DISPLAY "| Resource | Kind | Create | Read | Update |"
                    " Delete |"
                DISPLAY "|---|---|:-:|:-:|:-:|:-:|"
            END-IF
            ADD 1 TO LS-ROWS
            PERFORM WRITE-ROW
        END-IF
    END-PERFORM
    IF LS-ROWS > 0
        DISPLAY " "
    END-IF
    GOBACK.

WRITE-ROW.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING "| `" DELIMITED BY SIZE
           CX-NAME(LS-E) DELIMITED BY SPACE
           "` | " DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    EVALUATE CX-KIND(LS-E)
        WHEN "T"
            STRING "DB2 table" DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN "F"
            STRING "file" DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN OTHER
            STRING "CICS file" DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
    END-EVALUATE
    STRING " |" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF CX-CREATE(LS-E) = "Y"
        STRING " yes |" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "  |" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    IF CX-READ(LS-E) = "Y"
        STRING " yes |" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "  |" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    IF CX-UPDATE(LS-E) = "Y"
        STRING " yes |" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "  |" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    IF CX-DELETE(LS-E) = "Y"
        STRING " yes |" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "  |" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    DISPLAY WS-LINE(1:LS-PTR - 1).
END PROGRAM PLB-CRUD-DOC.

*> PLB-GRAPH-CRUD: the CRUD matrix as a graph, DOT or JSON (within the
*> frame PLB-GRAPH-BEGIN and PLB-GRAPH-END write): a node for each
*> program and for each resource, named "NAME (table)", "NAME (file)",
*> or "NAME (cics-file)", and an edge from a program to each resource it
*> uses, labelled with its operations (CRUD, RU, R, ...).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-CRUD.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-OUT                  PIC X(1024).
*> The nodes drawn so far, each once.
01  WS-NODE-COUNT           PIC 9(9) COMP-5.
01  WS-NODE                 PIC X(80) OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FIRST-ITEM           PIC X.
01  LS-NAME                 PIC X(80).
01  LS-KIND                 PIC X(10).
01  LS-LABEL                PIC X(4).
01  LS-LABEL-PTR            PIC 9(4) COMP-5.
01  LS-FOUND                PIC X.
LINKAGE SECTION.
COPY "plbcrud.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-CRUD LK-FORMAT.
    MOVE 0 TO WS-NODE-COUNT
    IF LK-FORMAT = "json"
        DISPLAY '    {"nodes": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > CX-COUNT
        MOVE CX-PROGRAM(LS-E) TO LS-NAME
        MOVE "program" TO LS-KIND
        PERFORM WRITE-NODE
        PERFORM RESOURCE-NAME
        PERFORM WRITE-NODE
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ],'
        DISPLAY '     "edges": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > CX-COUNT
        PERFORM WRITE-EDGE
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ]}'
    END-IF
    GOBACK.

*> LS-NAME and LS-KIND of the resource of row LS-E.
RESOURCE-NAME.
    EVALUATE CX-KIND(LS-E)
        WHEN "T" MOVE "table" TO LS-KIND
        WHEN "F" MOVE "file" TO LS-KIND
        WHEN OTHER MOVE "cics-file" TO LS-KIND
    END-EVALUATE
    MOVE SPACES TO LS-NAME
    STRING CX-NAME(LS-E) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
           LS-KIND DELIMITED BY SPACE
           ")" DELIMITED BY SIZE
        INTO LS-NAME.

*> Node LS-NAME of kind LS-KIND, when not drawn yet.
WRITE-NODE.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-NODE-COUNT
        IF WS-NODE(LS-I) = LS-NAME
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "Y" OR WS-NODE-COUNT >= 20000
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-NODE-COUNT
    MOVE LS-NAME TO WS-NODE(WS-NODE-COUNT)
    MOVE SPACES TO WS-OUT
    MOVE 1 TO LS-PTR
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"id": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME WS-OUT LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME WS-OUT LS-PTR
        IF LS-KIND = "program"
            STRING ';' DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER LS-PTR
        ELSE
            STRING ' [shape=cylinder];' DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER LS-PTR
        END-IF
    END-IF
    PERFORM PRINT-OUT.

*> Program of row LS-E -> its resource, labelled with the operations.
WRITE-EDGE.
    MOVE SPACES TO LS-LABEL
    MOVE 1 TO LS-LABEL-PTR
    IF CX-CREATE(LS-E) = "Y"
        STRING "C" DELIMITED BY SIZE INTO LS-LABEL WITH POINTER LS-LABEL-PTR
    END-IF
    IF CX-READ(LS-E) = "Y"
        STRING "R" DELIMITED BY SIZE INTO LS-LABEL WITH POINTER LS-LABEL-PTR
    END-IF
    IF CX-UPDATE(LS-E) = "Y"
        STRING "U" DELIMITED BY SIZE INTO LS-LABEL WITH POINTER LS-LABEL-PTR
    END-IF
    IF CX-DELETE(LS-E) = "Y"
        STRING "D" DELIMITED BY SIZE INTO LS-LABEL WITH POINTER LS-LABEL-PTR
    END-IF
    MOVE SPACES TO WS-OUT
    MOVE 1 TO LS-PTR
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"from": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE CX-PROGRAM(LS-E) TO LS-NAME
    CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME WS-OUT LS-PTR
    IF LK-FORMAT = "json"
        STRING ', "to": ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    ELSE
        STRING ' -> ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM RESOURCE-NAME
    CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME WS-OUT LS-PTR
    IF LK-FORMAT = "json"
        STRING ', "operations": "' DELIMITED BY SIZE
               LS-LABEL DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER LS-PTR
    ELSE
        STRING ' [label="' DELIMITED BY SIZE
               LS-LABEL DELIMITED BY SPACE
               '"];' DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

JSON-SEPARATOR.
    IF LS-FIRST-ITEM = "Y"
        STRING '        ' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '       ,' DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING WS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY WS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-GRAPH-CRUD.
