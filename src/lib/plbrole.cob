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
*>
*> Identifiers inside subscripts and reference modifiers are always
*> read. PROCEDURE DIVISION USING items are set by the caller (D).
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
    MOVE RF-STMT(LS-R) TO LS-STMT
    IF LS-STMT = 0
        *> PROCEDURE DIVISION USING: the caller supplies the value.
        MOVE "D" TO LS-ROLE
        EXIT PARAGRAPH
    END-IF
    MOVE ND-DETAIL(LS-STMT) TO LS-VERB
    PERFORM FIND-KEYWORD
    PERFORM ROLE-FOR-VERB.

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
