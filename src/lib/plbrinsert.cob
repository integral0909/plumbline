*> ---------------------------------------------------------------
*> plbrinsert: PLB-Q015 insert-count-mismatch.
*>
*> An INSERT whose column list and VALUES list have different numbers
*> of items:
*>
*>     EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, BALANCE, STATUS)
*>         VALUES (:WS-ACCT-ID, :WS-BALANCE) END-EXEC
*>
*> DB2 rejects the statement (SQLCODE -117: the number of values is
*> not the number of columns), so the row is never written; usually a
*> column was added to one list and not the other. Read are INSERT
*> statements with a column list and a VALUES list. Commas are not
*> tokens, so items are counted from the source text: commas outside
*> inner parentheses. A host variable with an indicator (:HV :IND) is
*> one item, and so is a VARCHAR (a group of level-49 items); a VALUES
*> list with a host structure (another group item, which stands for its
*> fields) is not counted, nor INSERT ... SELECT.
*>
*> An INSERT without a column list gives a value for each column of the
*> table, in order: when a DECLARE TABLE in the file describes the
*> table, its VALUES list is counted against the table's columns.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-Q015.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsqlm.cpy".
LOCAL-STORAGE SECTION.
*> "Y" once the SQL model of the file is built.
01  LS-MODEL-BUILT          PIC X VALUE "N".
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-TABLE-NAME           PIC X(64).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-OPEN                 PIC 9(9) COMP-5.
01  LS-CLOSE                PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(4) COMP-5.
01  LS-COUNT                PIC 9(4) COMP-5.
01  LS-COLUMNS              PIC 9(4) COMP-5.
01  LS-VALUES               PIC 9(4) COMP-5.
01  LS-VALUES-AT            PIC 9(9) COMP-5.
01  LS-COMMA                PIC X.
01  LS-STRUCTURE            PIC X.
01  LS-SCAN-FROM            PIC 9(9) COMP-5.
01  LS-SCAN-TO              PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-1                PIC X(12).
01  LS-NUM-1-LEN            PIC 9(9) COMP-5.
01  LS-NUM-2                PIC X(12).
01  LS-NUM-2-LEN            PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q015" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "EXEC"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "SQL"
                    COMPUTE LS-K = LS-T + 2
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                    IF FUNCTION UPPER-CASE(LS-TEXT) = "INSERT"
                        PERFORM CHECK-INSERT
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> INSERT INTO table (columns) VALUES (values), from LS-K to END-EXEC.
CHECK-INSERT.
    MOVE LS-K TO LS-END
    PERFORM UNTIL LS-END >= TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-END LS-TEXT LS-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) = "END-EXEC"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-END
    END-PERFORM
    *> The column list: the first parenthesis after the table name.
    MOVE 0 TO LS-OPEN
    PERFORM VARYING LS-I FROM LS-K BY 1 UNTIL LS-I >= LS-END
        IF TK-IS-LPAREN(LS-I)
            MOVE LS-I TO LS-OPEN
            EXIT PERFORM
        END-IF
        IF TK-IS-WORD(LS-I)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-TEXT LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
            IF LS-TEXT = "VALUES"
                MOVE LS-I TO LS-VALUES-AT
                PERFORM CHECK-NO-LIST
                EXIT PARAGRAPH
            END-IF
            IF LS-TEXT = "SELECT" OR LS-TEXT = "WITH"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    IF LS-OPEN = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM COUNT-LIST
    IF LS-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    MOVE LS-COUNT TO LS-COLUMNS
    *> VALUES and its list, right after the column list.
    COMPUTE LS-I = LS-CLOSE + 1
    IF LS-I >= LS-END OR NOT TK-IS-WORD(LS-I)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "VALUES"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-I TO LS-VALUES-AT
    COMPUTE LS-OPEN = LS-I + 1
    IF LS-OPEN >= LS-END OR NOT TK-IS-LPAREN(LS-OPEN)
        EXIT PARAGRAPH
    END-IF
    PERFORM COUNT-LIST
    IF LS-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    *> One row only: VALUES (...), (...) is not read.
    COMPUTE LS-I = LS-CLOSE + 1
    IF LS-I < LS-END
        MOVE LS-CLOSE TO LS-SCAN-FROM
        MOVE LS-I TO LS-SCAN-TO
        PERFORM COMMA-BETWEEN
        IF LS-COMMA = "Y"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE LS-COUNT TO LS-VALUES
    IF LS-VALUES NOT = LS-COLUMNS
        PERFORM REPORT-MISMATCH
    END-IF.

*> INSERT at LS-T without a column list, VALUES at LS-VALUES-AT: its
*> values against the columns of its table's DECLARE TABLE.
CHECK-NO-LIST.
    IF LS-MODEL-BUILT = "N"
        CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-SQL-MODEL
        MOVE "Y" TO LS-MODEL-BUILT
    END-IF
    *> The table: the tokens after INTO, up to VALUES, joined.
    MOVE SPACES TO LS-TABLE-NAME
    MOVE 1 TO LS-PTR
    MOVE 0 TO LS-Q
    PERFORM VARYING LS-I FROM LS-K BY 1 UNTIL LS-I >= LS-VALUES-AT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-TEXT LS-LEN
        IF LS-Q > 0 AND LS-LEN > 0 AND LS-PTR + LS-LEN < 64
            STRING FUNCTION UPPER-CASE(LS-TEXT(1:LS-LEN))
                DELIMITED BY SIZE INTO LS-TABLE-NAME WITH POINTER LS-PTR
        END-IF
        IF FUNCTION UPPER-CASE(LS-TEXT) = "INTO"
            MOVE LS-I TO LS-Q
        END-IF
    END-PERFORM
    MOVE 0 TO LS-TABLE
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > QT-COUNT
        IF QT-NAME(LS-S) = LS-TABLE-NAME
           OR QT-SHORT(LS-S) = LS-TABLE-NAME
            MOVE LS-S TO LS-TABLE
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-TABLE = 0
        EXIT PARAGRAPH
    END-IF
    IF QT-COL-COUNT(LS-TABLE) = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-OPEN = LS-VALUES-AT + 1
    IF LS-OPEN >= LS-END OR NOT TK-IS-LPAREN(LS-OPEN)
        EXIT PARAGRAPH
    END-IF
    PERFORM COUNT-LIST
    IF LS-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    *> One row only.
    COMPUTE LS-I = LS-CLOSE + 1
    IF LS-I < LS-END
        MOVE LS-CLOSE TO LS-SCAN-FROM
        MOVE LS-I TO LS-SCAN-TO
        PERFORM COMMA-BETWEEN
        IF LS-COMMA = "Y"
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF LS-COUNT = QT-COL-COUNT(LS-TABLE)
        EXIT PARAGRAPH
    END-IF
    MOVE LS-COUNT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE QT-COL-COUNT(LS-TABLE) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the INSERT gives " DELIMITED BY SIZE
           LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           " values and no column list, but the DECLARE TABLE of "
           DELIMITED BY SIZE
           QT-NAME(LS-TABLE) DELIMITED BY SPACE
           " has " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           " columns: DB2 rejects it (SQLCODE -117)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-VALUES-AT LS-MESSAGE.

*> LS-COUNT: the items in the parentheses opening at LS-OPEN, one more
*> than the commas at their top level; LS-CLOSE: the closing one. 0
*> when it does not close before END-EXEC, is empty, or holds a host
*> structure.
COUNT-LIST.
    MOVE 0 TO LS-COUNT LS-CLOSE LS-DEPTH
    COMPUTE LS-I = LS-OPEN + 1
    IF LS-I >= LS-END OR TK-IS-RPAREN(LS-I)
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-COUNT
    PERFORM VARYING LS-I FROM LS-I BY 1 UNTIL LS-I >= LS-END
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-I)
                ADD 1 TO LS-DEPTH
            WHEN TK-IS-RPAREN(LS-I) AND LS-DEPTH = 0
                MOVE LS-I TO LS-CLOSE
                EXIT PERFORM
            WHEN TK-IS-RPAREN(LS-I)
                SUBTRACT 1 FROM LS-DEPTH
            WHEN TK-IS-WORD(LS-I)
                PERFORM CHECK-STRUCTURE
                IF LS-STRUCTURE = "Y"
                    MOVE 0 TO LS-COUNT
                    EXIT PARAGRAPH
                END-IF
        END-EVALUATE
        IF LS-DEPTH = 0
            COMPUTE LS-SCAN-FROM = LS-I - 1
            MOVE LS-I TO LS-SCAN-TO
            PERFORM COMMA-BETWEEN
            IF LS-COMMA = "Y"
                ADD 1 TO LS-COUNT
            END-IF
        END-IF
    END-PERFORM
    IF LS-CLOSE = 0
        MOVE 0 TO LS-COUNT
    END-IF.

*> LS-STRUCTURE = "Y" when the word at LS-I names a group item, a host
*> structure; a group of level-49 items is one VARCHAR host variable.
CHECK-STRUCTURE.
    MOVE "N" TO LS-STRUCTURE
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-I
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
                MOVE RF-SYMBOL(LS-R) TO LS-G
                IF SY-CATEGORY(LS-G) = "G"
                    MOVE "Y" TO LS-STRUCTURE
                    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
                        IF SY-PARENT(LS-S) = LS-G AND SY-LEVEL(LS-S) = 49
                            MOVE "N" TO LS-STRUCTURE
                            EXIT PERFORM
                        END-IF
                    END-PERFORM
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-MISMATCH.
    MOVE LS-COLUMNS TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE LS-VALUES TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the INSERT names " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           " columns and gives " DELIMITED BY SIZE
           LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           " values: DB2 rejects it (SQLCODE -117)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-VALUES-AT LS-MESSAGE.

*> LS-COMMA = "Y" when the source text between tokens LS-SCAN-FROM and
*> LS-SCAN-TO holds a comma (see plbsqlu).
COMMA-BETWEEN.
    CALL "PLB-SQL-COMMA-BETWEEN" USING PLB-SOURCE-SET PLB-TOKENS
        LS-SCAN-FROM LS-SCAN-TO LS-COMMA.
END PROGRAM PLB-RULE-Q015.
