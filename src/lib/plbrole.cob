*> ---------------------------------------------------------------
*> plbrole: what each statement does with the data it names.
*>
*> PLB-REF-ROLES sets RF-ROLE for every data reference (see
*> copy/plbref.cpy). The role of an operand is decided by the verb of
*> its statement and the nearest keyword before it in the statement:
*>
*>   MOVE a TO b                 a U, b D
*>   ADD a TO b / GIVING c       a U, b B / c D
*>   SUBTRACT a FROM b           a U, b B          (GIVING: D)
*>   MULTIPLY a BY b             a U, b B          (GIVING: D)
*>   DIVIDE a INTO b             a U, b B          (BY: U; GIVING,
*>                                                  REMAINDER: D)
*>   COMPUTE a b = expr          a b D, expr U
*>   INITIALIZE a                D, operands after REPLACING etc. U
*>   SET a TO b                  a D (B with UP/DOWN BY), b U
*>   ACCEPT a                    D
*>   READ f INTO a, RETURN       a D, KEY U
*>   WRITE r FROM a              r a U
*>   STRING ... INTO a POINTER p       sources U, a D, p B
*>   UNSTRING s INTO a DELIMITER d COUNT c POINTER p TALLYING t
*>                               s U, a d c D, p t B
*>   INSPECT a TALLYING t FOR ...      a U (B with REPLACING or
*>                                     CONVERTING), t B, rest U
*>   CALL p USING a / BY CONTENT b / RETURNING r
*>                               a X, b U, r D
*>   PERFORM VARYING i FROM a BY b UNTIL c
*>                               i B, a b c U
*>   SEARCH t VARYING i          t U, i B
*>   IF, EVALUATE, DISPLAY, GO TO ... DEPENDING, conditions: U
*>   EXEC SQL ... INTO :a ... WHERE x = :b    a D, b U (CALL: X)
*>   EXEC CICS ... INTO(a) FROM(b) LENGTH(c)  a D, b U, c B
*>                 (ASSIGN, INQUIRE, FORMATTIME options: D)
*>
*> Identifiers inside subscripts and reference modifiers are always
*> read. LENGTH OF a uses only the size of a, not its value (-).
*> Names in report clauses (SOURCE, SUM, CONTROL, ...) are read when
*> the report is produced (U).
*> PROCEDURE DIVISION USING items are set by the caller (D).
*> Anything not covered is X: Plumbline does not know whether it is
*> read or set, and rules treat it as possibly both.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REF-ROLES.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-VERB                 PIC X(20).
01  LS-T                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-KEYWORD              PIC X(31).
01  LS-ROLE                 PIC X.
01  LS-OUTER-END            PIC 9(9) COMP-5 VALUE 0.
01  LS-HAS-UP-DOWN          PIC X.
01  LS-HAS-REPLACING        PIC X.
01  LS-COMMAND              PIC X(31).
01  LS-OPTION-LEVEL         PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbref.cpy".
PROCEDURE DIVISION USING PLB-TOKENS PLB-AST PLB-REFS.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        PERFORM DECIDE-ROLE
        MOVE LS-ROLE TO RF-ROLE(LS-R)
        *> Later references up to this one's last token are inside
        *> its subscripts or reference modifier.
        IF RF-LAST(LS-R) > LS-OUTER-END
            MOVE RF-LAST(LS-R) TO LS-OUTER-END
        END-IF
    END-PERFORM
    GOBACK.

DECIDE-ROLE.
    IF RF-KIND(LS-R) NOT = "D" AND RF-KIND(LS-R) NOT = "A"
        MOVE "-" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    IF RF-TOKEN(LS-R) <= LS-OUTER-END
        MOVE "U" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-LENGTH-OF
    IF LS-ROLE = "-"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-STMT(LS-R) TO LS-STMT
    IF LS-STMT = 0
        *> PROCEDURE DIVISION USING: the caller supplies the value.
        MOVE "D" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    *> A report clause (SOURCE, SUM, ...) reads what it names.
    IF ND-KIND(LS-STMT) = "CLAU"
        MOVE "U" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    MOVE ND-DETAIL(LS-STMT) TO LS-VERB
    IF LS-VERB = "EXEC"
        PERFORM EXEC-ROLE
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-KEYWORD
    PERFORM ROLE-FOR-VERB.

*> A host variable of EXEC SQL or an argument of EXEC CICS.
EXEC-ROLE.
    MOVE "X" TO LS-ROLE
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    EVALUATE LS-TEXT
        WHEN "SQL"
            PERFORM SQL-ROLE
        WHEN "CICS"
            PERFORM CICS-ROLE
    END-EVALUATE.

*> SQL: the nearest clause word before the host variable decides.
*> INTO (SELECT ... INTO, FETCH ... INTO) sets it, and so does SET
*> :x = ... at the start of the statement; a CALL may do either; in
*> every other place (VALUES, WHERE, SET col = :x, ...) it is read.
SQL-ROLE.
    MOVE "U" TO LS-ROLE
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT = "CALL"
        MOVE "X" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    IF LS-TEXT = "SET" AND RF-TOKEN(LS-R) = LS-T + 2
        MOVE "D" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = RF-TOKEN(LS-R) - 1
    PERFORM UNTIL LS-T <= ND-TOK-FIRST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "INTO"
                    MOVE "D" TO LS-ROLE
                    EXIT PERFORM
                WHEN "VALUES" WHEN "WHERE" WHEN "SET" WHEN "FROM"
                WHEN "USING" WHEN "HAVING" WHEN "ON" WHEN "BY"
                WHEN "AND" WHEN "OR" WHEN "SELECT"
                    EXIT PERFORM
            END-EVALUATE
        END-IF
        SUBTRACT 1 FROM LS-T
    END-PERFORM.

*> CICS: the option whose parentheses hold the argument decides.
*> Options that return data (INTO, SET, RESP, ...) set it, those that
*> pass data in (FROM, RIDFLD, ...) read it, and LENGTH and ITEM do
*> both. In ASSIGN, INQUIRE, and FORMATTIME every option returns a
*> value (except the ABSTIME that FORMATTIME formats).
CICS-ROLE.
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-COMMAND LS-LEN
    *> The option: the word before the "(" that encloses the argument.
    MOVE 0 TO LS-OPTION-LEVEL
    MOVE SPACES TO LS-KEYWORD
    COMPUTE LS-T = RF-TOKEN(LS-R) - 1
    PERFORM UNTIL LS-T <= ND-TOK-FIRST(LS-STMT)
        IF TK-IS-RPAREN(LS-T)
            ADD 1 TO LS-OPTION-LEVEL
        END-IF
        IF TK-IS-LPAREN(LS-T)
            IF LS-OPTION-LEVEL = 0
                SUBTRACT 1 FROM LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-KEYWORD
                    LS-LEN
                EXIT PERFORM
            END-IF
            SUBTRACT 1 FROM LS-OPTION-LEVEL
        END-IF
        SUBTRACT 1 FROM LS-T
    END-PERFORM
    EVALUATE TRUE
        WHEN LS-COMMAND = "FORMATTIME" AND LS-KEYWORD = "ABSTIME"
            MOVE "U" TO LS-ROLE
        WHEN LS-COMMAND = "ASSIGN" OR LS-COMMAND = "INQUIRE"
             OR LS-COMMAND = "FORMATTIME"
            MOVE "D" TO LS-ROLE
        WHEN LS-KEYWORD = "RIDFLD"
             AND (LS-COMMAND = "READNEXT" OR LS-COMMAND = "READPREV")
            MOVE "B" TO LS-ROLE
        WHEN OTHER
            EVALUATE LS-KEYWORD
                WHEN "INTO" WHEN "SET" WHEN "RESP" WHEN "RESP2"
                WHEN "ABSTIME" WHEN "NUMITEMS" WHEN "TOKEN"
                    MOVE "D" TO LS-ROLE
                WHEN "LENGTH" WHEN "FLENGTH" WHEN "ITEM"
                    MOVE "B" TO LS-ROLE
                WHEN "FROM" WHEN "RIDFLD" WHEN "KEYLENGTH" WHEN "QUEUE"
                WHEN "QNAME" WHEN "FILE" WHEN "DATASET" WHEN "MAP"
                WHEN "MAPSET" WHEN "PROGRAM" WHEN "TRANSID"
                WHEN "SYSID" WHEN "TERMID" WHEN "INTERVAL" WHEN "TIME"
                WHEN "CHANNEL" WHEN "CONTAINER" WHEN "CURSOR"
                WHEN "REQID" WHEN "ABCODE" WHEN "TEXT"
                    MOVE "U" TO LS-ROLE
                WHEN OTHER
                    *> COMMAREA, and options Plumbline does not know.
                    MOVE "X" TO LS-ROLE
            END-EVALUATE
    END-EVALUATE.

*> LS-ROLE = "-" when the reference is the operand of LENGTH OF or
*> BYTE-LENGTH OF, or the whole argument of FUNCTION LENGTH or
*> FUNCTION BYTE-LENGTH, otherwise spaces.
CHECK-LENGTH-OF.
    MOVE SPACE TO LS-ROLE
    IF RF-TOKEN(LS-R) <= 2
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = RF-TOKEN(LS-R) - 1
    *> FUNCTION LENGTH (item), FUNCTION BYTE-LENGTH (item): the item
    *> is measured, not read, when it is the whole argument.
    IF TK-IS-LPAREN(LS-T) AND LS-T > 2
       AND RF-LAST(LS-R) < TK-COUNT
        IF TK-IS-RPAREN(RF-LAST(LS-R) + 1)
            SUBTRACT 1 FROM LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF (LS-TEXT = "LENGTH" OR LS-TEXT = "BYTE-LENGTH")
               AND TK-IS-WORD(LS-T)
                SUBTRACT 1 FROM LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                    LS-LEN
                IF LS-TEXT = "FUNCTION"
                    MOVE "-" TO LS-ROLE
                END-IF
            END-IF
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT NOT = "OF"
        EXIT PARAGRAPH
    END-IF
    SUBTRACT 1 FROM LS-T
    IF NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT = "LENGTH" OR LS-TEXT = "BYTE-LENGTH"
        MOVE "-" TO LS-ROLE
    END-IF.

*> LS-KEYWORD = the nearest word before the reference, within its
*> statement, that decides roles ("=" counts for COMPUTE); spaces
*> when the reference comes straight after the verb's operands start.
FIND-KEYWORD.
    MOVE SPACES TO LS-KEYWORD
    COMPUTE LS-T = RF-TOKEN(LS-R) - 1
    PERFORM UNTIL LS-T <= ND-TOK-FIRST(LS-STMT)
        IF TK-IS-WORD(LS-T) OR TK-IS-OPERATOR(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "TO" WHEN "GIVING" WHEN "FROM" WHEN "BY"
                WHEN "INTO" WHEN "REMAINDER" WHEN "=" WHEN "EQUAL"
                WHEN "REPLACING" WHEN "WITH" WHEN "VALUE" WHEN "UPON"
                WHEN "KEY" WHEN "POINTER" WHEN "DELIMITED"
                WHEN "DELIMITER" WHEN "COUNT" WHEN "TALLYING"
                WHEN "FOR" WHEN "CONVERTING" WHEN "BEFORE" WHEN "AFTER"
                WHEN "INITIAL" WHEN "USING" WHEN "REFERENCE"
                WHEN "CONTENT" WHEN "RETURNING" WHEN "VARYING"
                WHEN "UNTIL" WHEN "WHEN" WHEN "DEPENDING" WHEN "TIMES"
                    MOVE LS-TEXT TO LS-KEYWORD
                    EXIT PERFORM
            END-EVALUATE
        END-IF
        SUBTRACT 1 FROM LS-T
    END-PERFORM.

ROLE-FOR-VERB.
    MOVE "X" TO LS-ROLE
    EVALUATE LS-VERB
        WHEN "MOVE"
            EVALUATE LS-KEYWORD
                WHEN "TO"       MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "ADD"
            EVALUATE LS-KEYWORD
                WHEN "TO"       MOVE "B" TO LS-ROLE
                WHEN "GIVING"   MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "SUBTRACT"
            EVALUATE LS-KEYWORD
                WHEN "FROM"     MOVE "B" TO LS-ROLE
                WHEN "GIVING"   MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "MULTIPLY"
            EVALUATE LS-KEYWORD
                WHEN "BY"       MOVE "B" TO LS-ROLE
                WHEN "GIVING"   MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "DIVIDE"
            EVALUATE LS-KEYWORD
                WHEN "INTO"     MOVE "B" TO LS-ROLE
                WHEN "GIVING"   MOVE "D" TO LS-ROLE
                WHEN "REMAINDER" MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "COMPUTE"
            EVALUATE LS-KEYWORD
                WHEN SPACES     MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "INITIALIZE"
            EVALUATE LS-KEYWORD
                WHEN SPACES     MOVE "D" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "SET"
            PERFORM CHECK-UP-DOWN
            EVALUATE TRUE
                WHEN LS-KEYWORD NOT = SPACES
                    MOVE "U" TO LS-ROLE
                WHEN LS-HAS-UP-DOWN = "Y"
                    MOVE "B" TO LS-ROLE
                WHEN OTHER
                    MOVE "D" TO LS-ROLE
            END-EVALUATE
        WHEN "ACCEPT"
            EVALUATE LS-KEYWORD
                WHEN SPACES     MOVE "D" TO LS-ROLE
            END-EVALUATE
        WHEN "DISPLAY"
            EVALUATE LS-KEYWORD
                WHEN SPACES     MOVE "U" TO LS-ROLE
            END-EVALUATE
        *> XML GENERATE out FROM data [COUNT IN n], JSON GENERATE the
        *> same; XML PARSE document reads it.
        WHEN "XML"
        WHEN "JSON"
            EVALUATE LS-KEYWORD
                WHEN SPACES
                    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    IF LS-TEXT = "GENERATE"
                        MOVE "D" TO LS-ROLE
                    ELSE
                        MOVE "U" TO LS-ROLE
                    END-IF
                WHEN "FROM"     MOVE "U" TO LS-ROLE
                WHEN "COUNT"    MOVE "D" TO LS-ROLE
            END-EVALUATE
        WHEN "READ"
        WHEN "RETURN"
            EVALUATE LS-KEYWORD
                WHEN "INTO"     MOVE "D" TO LS-ROLE
                WHEN "KEY"      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "WRITE"
        WHEN "REWRITE"
        WHEN "RELEASE"
            MOVE "U" TO LS-ROLE
        WHEN "START"
        WHEN "DELETE"
            EVALUATE LS-KEYWORD
                WHEN "KEY"      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "STRING"
            EVALUATE LS-KEYWORD
                WHEN "INTO"     MOVE "D" TO LS-ROLE
                WHEN "POINTER"  MOVE "B" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "UNSTRING"
            EVALUATE LS-KEYWORD
                WHEN "INTO"     MOVE "D" TO LS-ROLE
                WHEN "DELIMITER" MOVE "D" TO LS-ROLE
                WHEN "COUNT"    MOVE "D" TO LS-ROLE
                WHEN "POINTER"  MOVE "B" TO LS-ROLE
                WHEN "TALLYING" MOVE "B" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "INSPECT"
            EVALUATE LS-KEYWORD
                WHEN SPACES
                    PERFORM CHECK-REPLACING
                    IF LS-HAS-REPLACING = "Y"
                        MOVE "B" TO LS-ROLE
                    ELSE
                        MOVE "U" TO LS-ROLE
                    END-IF
                WHEN "TALLYING" MOVE "B" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "CALL"
            EVALUATE LS-KEYWORD
                WHEN SPACES     MOVE "U" TO LS-ROLE
                WHEN "CONTENT"  MOVE "U" TO LS-ROLE
                WHEN "VALUE"    MOVE "U" TO LS-ROLE
                WHEN "RETURNING" MOVE "D" TO LS-ROLE
                WHEN "GIVING"   MOVE "D" TO LS-ROLE
            END-EVALUATE
        WHEN "PERFORM"
            EVALUATE LS-KEYWORD
                WHEN "VARYING"  MOVE "B" TO LS-ROLE
                WHEN "AFTER"    MOVE "B" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "SEARCH"
            EVALUATE LS-KEYWORD
                WHEN "VARYING"  MOVE "B" TO LS-ROLE
                WHEN OTHER      MOVE "U" TO LS-ROLE
            END-EVALUATE
        WHEN "IF"
        WHEN "EVALUATE"
        WHEN "GO"
        WHEN "CANCEL"
            MOVE "U" TO LS-ROLE
    END-EVALUATE.

CHECK-UP-DOWN.
    MOVE "N" TO LS-HAS-UP-DOWN
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "UP" OR LS-TEXT = "DOWN"
                MOVE "Y" TO LS-HAS-UP-DOWN
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

CHECK-REPLACING.
    MOVE "N" TO LS-HAS-REPLACING
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "REPLACING" OR LS-TEXT = "CONVERTING"
                MOVE "Y" TO LS-HAS-REPLACING
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.
END PROGRAM PLB-REF-ROLES.
