*> ---------------------------------------------------------------
*> plbrsqlt: host variables against the types of the columns they
*> take values from or give values to.
*>
*>   PLB-Q006  host-variable-too-small   a FETCH or SELECT INTO puts a
*>                                       column into a host variable
*>                                       too small for its values
*>   PLB-Q007  host-variable-too-large   an INSERT or UPDATE gives a
*>                                       column a host variable that
*>                                       holds values it cannot take
*>   PLB-Q008  null-without-indicator    a FETCH or SELECT INTO puts a
*>                                       column that can be NULL into a
*>                                       host variable without an
*>                                       indicator variable
*>
*> The pairs of a column and a host variable come from the SQL model
*> (plbsqlu); the column's type from the DECLARE TABLE statements of the
*> file, usually DCLGEN copybooks. A column is looked for among the
*> tables the statement names, then among all the declared tables,
*> where its name must be unique. Compared are:
*>
*>   CHAR(n), VARCHAR(n)       an alphanumeric host variable's length,
*>                             or, for a VARCHAR structure (two items
*>                             of level 49, a length and the text), its
*>                             text's length
*>   DECIMAL(p,s)              a numeric host variable's integer digits
*>                             and decimal places
*>   SMALLINT, INTEGER,        a numeric host variable's digits: 4, 9,
*>   BIGINT                    and 18 when it is binary, 5, 10, and 19
*>                             when it is decimal
*>
*> Other types (dates, times, floats, graphics) and host variables of
*> another category (a CHAR column into a numeric item, which the
*> precompiler rejects) are not compared.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SQL-TYPES.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsqlm.cpy".
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE-SMALL           PIC 9(4) COMP-5.
01  LS-RULE-LARGE           PIC 9(4) COMP-5.
01  LS-RULE-NULL            PIC 9(4) COMP-5.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-HOST                 PIC 9(9) COMP-5.
01  LS-TEXT-ITEM            PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-CHILDREN             PIC 9(9) COMP-5.
01  LS-INTO                 PIC X.
*> The column's needs, and the host variable's room: characters, or
*> integer digits and decimal places.
01  LS-COL-CHARS            PIC 9(9) COMP-5.
01  LS-COL-INT              PIC S9(9) COMP-5.
01  LS-COL-DEC              PIC S9(9) COMP-5.
01  LS-HOST-CHARS           PIC 9(9) COMP-5.
01  LS-HOST-INT             PIC S9(9) COMP-5.
01  LS-HOST-DEC             PIC S9(9) COMP-5.
01  LS-BINARY               PIC X.
01  LS-KIND                 PIC X.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q006" LS-RULE-SMALL
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q007" LS-RULE-LARGE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q008" LS-RULE-NULL
    IF RL-ENABLED(LS-RULE-SMALL) NOT = "Y"
       AND RL-ENABLED(LS-RULE-LARGE) NOT = "Y"
       AND RL-ENABLED(LS-RULE-NULL) NOT = "Y"
        GOBACK
    END-IF
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    IF QT-COUNT = 0 OR QP-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > QS-COUNT
        EVALUATE QS-KIND(LS-S)
            WHEN "S"
            WHEN "F"
                MOVE "Y" TO LS-INTO
                MOVE LS-RULE-SMALL TO LS-RULE
                PERFORM CHECK-STATEMENT
            WHEN "I"
            WHEN "U"
                MOVE "N" TO LS-INTO
                MOVE LS-RULE-LARGE TO LS-RULE
                PERFORM CHECK-STATEMENT
        END-EVALUATE
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

CHECK-STATEMENT.
    IF RL-ENABLED(LS-RULE) NOT = "Y" AND (LS-INTO = "N"
       OR RL-ENABLED(LS-RULE-NULL) NOT = "Y")
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-P FROM QS-PAIR-FIRST(LS-S) BY 1
            UNTIL LS-P >= QS-PAIR-FIRST(LS-S) + QS-PAIR-COUNT(LS-S)
        IF QP-COLUMN(LS-P) NOT = SPACES AND QP-HOST-TOKEN(LS-P) > 0
            PERFORM CHECK-PAIR
        END-IF
    END-PERFORM.

CHECK-PAIR.
    PERFORM FIND-COLUMN
    IF LS-C = 0
        EXIT PARAGRAPH
    END-IF
    MOVE WS-TOKEN-REF(QP-HOST-TOKEN(LS-P)) TO LS-R
    IF LS-R = 0
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-R) NOT = "D" OR RF-SYMBOL(LS-R) = 0
       OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-HOST
    IF LS-INTO = "Y" AND RL-ENABLED(LS-RULE-NULL) = "Y"
        PERFORM CHECK-NULL
    END-IF
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM COLUMN-NEEDS
    EVALUATE LS-KIND
        WHEN "C"
            PERFORM HOST-CHARACTERS
            IF LS-HOST-CHARS > 0
                PERFORM COMPARE-CHARACTERS
            END-IF
        WHEN "N"
            PERFORM HOST-DIGITS
            IF LS-HOST-INT >= 0
                PERFORM COMPARE-DIGITS
            END-IF
    END-EVALUATE.

*> LS-C: the column of pair LS-P of statement LS-S (see plbsqlu).
FIND-COLUMN.
    CALL "PLB-SQL-FIND-COLUMN" USING PLB-SQL-MODEL LS-S LS-P LS-C.

*> LS-KIND: C for a character column (LS-COL-CHARS characters), N for
*> a number (LS-COL-INT integer digits, LS-COL-DEC decimal places), or
*> space for a type not compared.
COLUMN-NEEDS.
    MOVE SPACE TO LS-KIND
    MOVE 0 TO LS-COL-CHARS LS-COL-INT LS-COL-DEC
    EVALUATE QL-TYPE(LS-C)
        WHEN "CHAR"
        WHEN "VARCHAR"
            MOVE "C" TO LS-KIND
            MOVE QL-LENGTH(LS-C) TO LS-COL-CHARS
            IF LS-COL-CHARS = 0
                MOVE 1 TO LS-COL-CHARS
            END-IF
        WHEN "DECIMAL"
            MOVE "N" TO LS-KIND
            IF QL-LENGTH(LS-C) = 0
                MOVE 5 TO LS-COL-INT
            ELSE
                COMPUTE LS-COL-INT = QL-LENGTH(LS-C) - QL-SCALE(LS-C)
                MOVE QL-SCALE(LS-C) TO LS-COL-DEC
            END-IF
        WHEN "SMALLINT"
        WHEN "INTEGER"
        WHEN "BIGINT"
            MOVE "N" TO LS-KIND
    END-EVALUATE.

*> LS-HOST-CHARS: the characters host variable LS-HOST holds, when it
*> is alphanumeric, or a VARCHAR structure; 0 otherwise.
HOST-CHARACTERS.
    MOVE 0 TO LS-HOST-CHARS
    IF SY-OCCURS(LS-HOST) > 0 OR SY-VARIABLE(LS-HOST) = "Y"
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-HOST) = "X" OR SY-CATEGORY(LS-HOST) = "A"
        MOVE SY-SIZE(LS-HOST) TO LS-HOST-CHARS
        MOVE LS-HOST TO LS-TEXT-ITEM
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-HOST) NOT = "G"
        EXIT PARAGRAPH
    END-IF
    *> 49 LEN PIC S9(4) COMP, 49 TEXT PIC X(n): the text's length.
    MOVE 0 TO LS-CHILDREN LS-TEXT-ITEM
    PERFORM VARYING LS-CHILD FROM LS-HOST BY 1
            UNTIL LS-CHILD >= SY-COUNT OR LS-CHILDREN > 2
        *> The group's items follow it, up to the next item of its
        *> level or above.
        IF SY-LEVEL(LS-CHILD + 1) <= SY-LEVEL(LS-HOST)
            EXIT PERFORM
        END-IF
        IF SY-PARENT(LS-CHILD + 1) = LS-HOST
            ADD 1 TO LS-CHILDREN
            IF SY-LEVEL(LS-CHILD + 1) NOT = 49
                MOVE 3 TO LS-CHILDREN
            END-IF
            COMPUTE LS-TEXT-ITEM = LS-CHILD + 1
        END-IF
    END-PERFORM
    IF LS-CHILDREN = 2
        IF SY-CATEGORY(LS-TEXT-ITEM) = "X"
           OR SY-CATEGORY(LS-TEXT-ITEM) = "A"
            MOVE SY-SIZE(LS-TEXT-ITEM) TO LS-HOST-CHARS
        END-IF
    END-IF.

*> LS-HOST-INT and LS-HOST-DEC: the integer digits and decimal places
*> of numeric host variable LS-HOST; LS-HOST-INT is -1 when it is not
*> a number. LS-BINARY = "Y" for a binary usage.
HOST-DIGITS.
    MOVE -1 TO LS-HOST-INT
    MOVE 0 TO LS-HOST-DEC
    MOVE "N" TO LS-BINARY
    IF SY-CATEGORY(LS-HOST) NOT = "9" OR SY-OCCURS(LS-HOST) > 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-HOST-INT = SY-DIGITS(LS-HOST) - SY-SCALE(LS-HOST)
    MOVE SY-SCALE(LS-HOST) TO LS-HOST-DEC
    IF LS-HOST-DEC < 0
        MOVE 0 TO LS-HOST-DEC
    END-IF
    EVALUATE SY-USAGE(LS-HOST)
        WHEN "BINARY"
        WHEN "COMP"
        WHEN "COMP-4"
        WHEN "COMP-5"
        WHEN "COMPUTATIONAL"
        WHEN "COMPUTATIONAL-4"
        WHEN "COMPUTATIONAL-5"
            MOVE "Y" TO LS-BINARY
    END-EVALUATE
    *> The integer types need these many digits.
    EVALUATE QL-TYPE(LS-C)
        WHEN "SMALLINT"
            IF LS-BINARY = "Y"
                MOVE 4 TO LS-COL-INT
            ELSE
                MOVE 5 TO LS-COL-INT
            END-IF
        WHEN "INTEGER"
            IF LS-BINARY = "Y"
                MOVE 9 TO LS-COL-INT
            ELSE
                MOVE 10 TO LS-COL-INT
            END-IF
        WHEN "BIGINT"
            IF LS-BINARY = "Y"
                MOVE 18 TO LS-COL-INT
            ELSE
                MOVE 19 TO LS-COL-INT
            END-IF
    END-EVALUATE.

COMPARE-CHARACTERS.
    IF LS-INTO = "Y" AND LS-HOST-CHARS < LS-COL-CHARS
        MOVE SPACES TO LS-MESSAGE
        MOVE 1 TO LS-PTR
        PERFORM START-MESSAGE
        STRING ", but " DELIMITED BY SIZE
               SY-NAME(LS-HOST) DELIMITED BY SPACE
               " holds " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-HOST-CHARS TO LS-NUM
        PERFORM APPEND-NUM
        STRING " characters: longer values are cut (SQLWARN1)"
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM REPORT-PAIR
    END-IF
    IF LS-INTO = "N" AND LS-HOST-CHARS > LS-COL-CHARS
        MOVE SPACES TO LS-MESSAGE
        MOVE 1 TO LS-PTR
        STRING SY-NAME(LS-HOST) DELIMITED BY SPACE
               " holds " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-HOST-CHARS TO LS-NUM
        PERFORM APPEND-NUM
        STRING " characters, but " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM START-MESSAGE
        STRING ": longer values are rejected (SQLCODE -404)"
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM REPORT-PAIR
    END-IF.

COMPARE-DIGITS.
    IF LS-INTO = "Y"
        IF LS-HOST-INT < LS-COL-INT
            MOVE SPACES TO LS-MESSAGE
            MOVE 1 TO LS-PTR
            PERFORM START-MESSAGE
            STRING ", but " DELIMITED BY SIZE
                   SY-NAME(LS-HOST) DELIMITED BY SPACE
                   " has " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE LS-HOST-INT TO LS-NUM
            PERFORM APPEND-NUM
            STRING " integer digits: larger values make the statement"
                   " fail (SQLCODE -304)" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            PERFORM REPORT-PAIR
        ELSE
            IF LS-HOST-DEC < LS-COL-DEC
                MOVE SPACES TO LS-MESSAGE
                MOVE 1 TO LS-PTR
                PERFORM START-MESSAGE
                STRING ", but " DELIMITED BY SIZE
                       SY-NAME(LS-HOST) DELIMITED BY SPACE
                       " has " DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
                MOVE LS-HOST-DEC TO LS-NUM
                PERFORM APPEND-NUM
                STRING " decimal places: the rest are cut"
                       DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
                PERFORM REPORT-PAIR
            END-IF
        END-IF
        EXIT PARAGRAPH
    END-IF
    *> INSERT and UPDATE: the column takes the host variable's values.
    IF QL-TYPE(LS-C) NOT = "DECIMAL"
        EXIT PARAGRAPH
    END-IF
    IF LS-HOST-INT > LS-COL-INT
        MOVE SPACES TO LS-MESSAGE
        MOVE 1 TO LS-PTR
        STRING SY-NAME(LS-HOST) DELIMITED BY SPACE
               " has " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-HOST-INT TO LS-NUM
        PERFORM APPEND-NUM
        STRING " integer digits, but " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM START-MESSAGE
        STRING ": larger values are rejected (SQLCODE -302)"
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        PERFORM REPORT-PAIR
    ELSE
        IF LS-HOST-DEC > LS-COL-DEC
            MOVE SPACES TO LS-MESSAGE
            MOVE 1 TO LS-PTR
            STRING SY-NAME(LS-HOST) DELIMITED BY SPACE
                   " has " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE LS-HOST-DEC TO LS-NUM
            PERFORM APPEND-NUM
            STRING " decimal places, but " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            PERFORM START-MESSAGE
            STRING ": the rest are cut" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            PERFORM REPORT-PAIR
        END-IF
    END-IF.

*> PLB-Q008: a column without NOT NULL into a host variable without an
*> indicator. When the column is NULL, DB2 cannot say so, and the
*> statement fails (SQLCODE -305).
CHECK-NULL.
    IF QL-NULLS(LS-C) = "N" OR QP-INDICATOR-TOKEN(LS-P) > 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "column " DELIMITED BY SIZE
           QL-NAME(LS-C) DELIMITED BY SPACE
           " can be NULL, but " DELIMITED BY SIZE
           SY-NAME(LS-HOST) DELIMITED BY SPACE
           " has no indicator variable: a NULL makes the statement"
           " fail (SQLCODE -305)" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-NULL QP-HOST-TOKEN(LS-P) LS-MESSAGE.

*> "column NAME is TYPE(n[,s])", at LS-PTR.
START-MESSAGE.
    STRING "column " DELIMITED BY SIZE
           QL-NAME(LS-C) DELIMITED BY SPACE
           " is " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    PERFORM APPEND-TYPE.

APPEND-TYPE.
    STRING QL-TYPE(LS-C) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF QL-LENGTH(LS-C) > 0
        STRING "(" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE QL-LENGTH(LS-C) TO LS-NUM
        PERFORM APPEND-NUM
        IF QL-SCALE(LS-C) > 0
            STRING "," DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE QL-SCALE(LS-C) TO LS-NUM
            PERFORM APPEND-NUM
        END-IF
        STRING ")" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.

REPORT-PAIR.
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE QP-HOST-TOKEN(LS-P) LS-MESSAGE.
END PROGRAM PLB-RULE-SQL-TYPES.

*> ---------------------------------------------------------------
*> PLB-Q024 column-undeclared: a column that a SELECT, a cursor, an
*> INSERT, or an UPDATE pairs with a host variable, which none of the
*> tables it names has, when DECLARE TABLE statements describe all of
*> them:
*>
*>     EXEC SQL DECLARE ACCOUNT TABLE (ACCT_ID INTEGER, OWNER CHAR(30))
*>     EXEC SQL SELECT OWNR INTO :WS-NAME FROM ACCOUNT ...
*>
*> Db2 rejects the statement with SQLCODE -206 (the name is not a
*> column of a table the statement names), at bind or when it runs;
*> usually the name is misspelled, or the table's DCLGEN copybook is
*> older than the table. Statements that name a table without a DECLARE
*> TABLE, or more tables than the model keeps, are left alone, as are
*> columns in expressions. In the WHERE, at its top level, a word
*> just before a relational operator is read as a column too.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-Q024.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsqlm.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-ALL-DECLARED         PIC X.
01  LS-FOUND                PIC X.
01  LS-MESSAGE              PIC X(200).
01  LS-PTR                  PIC 9(9) COMP-5.
*> The column being looked for, and its token.
01  LS-COLUMN               PIC X(31).
01  LS-COLUMN-TOKEN         PIC 9(9) COMP-5.
*> CHECK-WHERE-COLUMNS: where the walk is, and the tokens around.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-PREV                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(4) COMP-5.
01  LS-IN-WHERE             PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-OP                   PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q024" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    IF QT-COUNT = 0 OR QP-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > QS-COUNT
        IF QS-KIND(LS-S) = "S" OR "C" OR "I" OR "U" OR "D"
            PERFORM CHECK-STATEMENT
        END-IF
    END-PERFORM
    GOBACK.

*> Statement LS-S: its tables, all declared, then each column it
*> pairs.
CHECK-STATEMENT.
    IF QS-TABLE-COUNT(LS-S) = 0 OR QS-TABLE-COUNT(LS-S) > 4
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > QS-TABLE-COUNT(LS-S)
        MOVE "N" TO LS-ALL-DECLARED
        PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > QT-COUNT
            IF QT-NAME(LS-J) = QS-TABLE(LS-S, LS-I)
               OR QT-SHORT(LS-J) = QS-TABLE(LS-S, LS-I)
                MOVE "Y" TO LS-ALL-DECLARED
                EXIT PERFORM
            END-IF
        END-PERFORM
        IF LS-ALL-DECLARED = "N"
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    PERFORM VARYING LS-P FROM QS-PAIR-FIRST(LS-S) BY 1
            UNTIL LS-P >= QS-PAIR-FIRST(LS-S) + QS-PAIR-COUNT(LS-S)
        IF QP-COLUMN-TOKEN(LS-P) > 0 AND QP-COLUMN(LS-P) NOT = SPACES
            MOVE QP-COLUMN(LS-P) TO LS-COLUMN
            MOVE QP-COLUMN-TOKEN(LS-P) TO LS-COLUMN-TOKEN
            PERFORM CHECK-COLUMN
        END-IF
    END-PERFORM
    PERFORM CHECK-WHERE-COLUMNS.

*> The WHERE of statement LS-S, at its top level: each word just
*> before a relational operator (WHERE ACCT_ID = :WS-ID), not a host
*> variable (after a colon) or a special register (after CURRENT).
CHECK-WHERE-COLUMNS.
    MOVE 0 TO LS-DEPTH
    MOVE "N" TO LS-IN-WHERE
    PERFORM VARYING LS-T FROM QS-TOKEN(LS-S) BY 1
            UNTIL LS-T >= QS-END(LS-S)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-DEPTH
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-DEPTH
            WHEN LS-DEPTH NOT = 0
                CONTINUE
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
                EVALUATE TRUE
                    WHEN LS-TEXT = "WHERE"
                        MOVE "Y" TO LS-IN-WHERE
                    WHEN LS-TEXT = "ORDER" OR "GROUP" OR "HAVING"
                         OR "FETCH" OR "FOR" OR "UNION" OR "WITH"
                         OR "OPTIMIZE"
                        MOVE "N" TO LS-IN-WHERE
                    WHEN LS-IN-WHERE = "Y"
                        PERFORM WHERE-WORD
                END-EVALUATE
        END-EVALUATE
    END-PERFORM.

*> The word LS-TEXT at LS-T in a WHERE.
WHERE-WORD.
    COMPUTE LS-NEXT = LS-T + 1
    IF LS-NEXT >= QS-END(LS-S) OR NOT TK-IS-OPERATOR(LS-NEXT)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NEXT LS-OP LS-LEN
    IF LS-OP NOT = "=" AND NOT = "<>" AND NOT = "<" AND NOT = ">"
       AND NOT = "<=" AND NOT = ">="
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-PREV = LS-T - 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-PREV LS-OP LS-LEN
    IF LS-OP = ":" OR FUNCTION UPPER-CASE(LS-OP) = "CURRENT"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TEXT TO LS-COLUMN
    MOVE LS-T TO LS-COLUMN-TOKEN
    PERFORM CHECK-COLUMN.

*> Column of pair LS-P in one of the statement's tables.
CHECK-COLUMN.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > QS-TABLE-COUNT(LS-S)
        PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > QT-COUNT
            IF QT-NAME(LS-J) = QS-TABLE(LS-S, LS-I)
               OR QT-SHORT(LS-J) = QS-TABLE(LS-S, LS-I)
                PERFORM VARYING LS-C FROM QT-COL-FIRST(LS-J) BY 1
                        UNTIL LS-C >= QT-COL-FIRST(LS-J)
                                      + QT-COL-COUNT(LS-J)
                    IF QL-NAME(LS-C) = LS-COLUMN
                        MOVE "Y" TO LS-FOUND
                    END-IF
                END-PERFORM
            END-IF
        END-PERFORM
    END-PERFORM
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "column " DELIMITED BY SIZE
           LS-COLUMN DELIMITED BY SPACE
           " is not in the DECLARE TABLE of " DELIMITED BY SIZE
           QS-TABLE(LS-S, 1) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF QS-TABLE-COUNT(LS-S) > 1
        STRING " or the other tables it names" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING ": Db2 rejects it (SQLCODE -206)" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-COLUMN-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-Q024.

*> ---------------------------------------------------------------
*> PLB-Q025 insert-not-null-missing: an INSERT whose column list
*> leaves out a column the DECLARE TABLE of its table declares NOT
*> NULL without a default:
*>
*>     EXEC SQL DECLARE ACCOUNT TABLE
*>         (ACCT_ID INTEGER NOT NULL, OWNER CHAR(30) NOT NULL)
*>     EXEC SQL INSERT INTO ACCOUNT (ACCT_ID) VALUES (:WS-ID)
*>
*> The INSERT gives the column the null value, which it cannot hold:
*> Db2 rejects it with SQLCODE -407, and SQLite 3 with "NOT NULL
*> constraint failed". A column WITH DEFAULT, with DEFAULT value, or
*> GENERATED gets a value of its own. An INSERT without a column list
*> gives every column, and is not read. An UPDATE that sets a NOT NULL
*> column = NULL, and an INSERT whose VALUES give one NULL, are
*> reported too, for the same SQLCODE.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-Q025.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsqlm.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-DEPTH                PIC S9(4) COMP-5.
01  LS-LIST                 PIC X.
01  LS-NAME-COUNT           PIC 9(4) COMP-5.
01  LS-NAME                 PIC X(31) OCCURS 200 TIMES.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
*> CHECK-VALUES-NULL: the value being read, its first token and its
*> length, the token before, and whether a comma is between.
01  LS-ITEM-AT              PIC 9(9) COMP-5.
01  LS-ITEM-TOKENS          PIC 9(4) COMP-5.
01  LS-PREV                 PIC 9(9) COMP-5.
01  LS-COMMA                PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q025" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    IF QT-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > QS-COUNT
        IF QS-KIND(LS-S) = "I" AND QS-TABLE-COUNT(LS-S) = 1
            PERFORM CHECK-INSERT
        END-IF
        IF QS-KIND(LS-S) = "U" AND QS-TABLE-COUNT(LS-S) = 1
            PERFORM CHECK-UPDATE
        END-IF
    END-PERFORM
    GOBACK.

*> INSERT LS-S: its declared table, and its column list.
CHECK-INSERT.
    PERFORM FIND-TABLE
    IF LS-TABLE = 0
        EXIT PARAGRAPH
    END-IF
    *> The column list: the first parentheses, before VALUES or SELECT.
    MOVE 0 TO LS-NAME-COUNT LS-DEPTH LS-AT
    MOVE "N" TO LS-LIST
    PERFORM VARYING LS-T FROM QS-TOKEN(LS-S) BY 1
            UNTIL LS-T >= QS-END(LS-S)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-DEPTH
                IF LS-DEPTH = 1
                    MOVE "Y" TO LS-LIST
                END-IF
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-DEPTH
                IF LS-DEPTH = 0 AND LS-LIST = "Y"
                    EXIT PERFORM
                END-IF
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
                IF LS-TEXT = "INSERT"
                    MOVE LS-T TO LS-AT
                END-IF
                IF LS-DEPTH = 0
                   AND (LS-TEXT = "VALUES" OR LS-TEXT = "SELECT")
                    EXIT PARAGRAPH
                END-IF
                IF LS-LIST = "Y" AND LS-DEPTH = 1
                   AND LS-NAME-COUNT < 200
                    ADD 1 TO LS-NAME-COUNT
                    MOVE LS-TEXT TO LS-NAME(LS-NAME-COUNT)
                END-IF
        END-EVALUATE
    END-PERFORM
    IF LS-NAME-COUNT = 0 OR LS-AT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM QT-COL-FIRST(LS-TABLE) BY 1
            UNTIL LS-C >= QT-COL-FIRST(LS-TABLE) + QT-COL-COUNT(LS-TABLE)
        IF QL-NULLS(LS-C) = "N" AND QL-DEFAULT(LS-C) = "N"
            PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-NAME-COUNT
                IF LS-NAME(LS-I) = QL-NAME(LS-C)
                    EXIT PERFORM
                END-IF
            END-PERFORM
            IF LS-I > LS-NAME-COUNT
                PERFORM REPORT-MISSING
            END-IF
        END-IF
    END-PERFORM
    PERFORM CHECK-VALUES-NULL.

*> The VALUES after the column list, which ends at LS-T: a NULL alone
*> as the value of a NOT NULL column of the list.
CHECK-VALUES-NULL.
    ADD 1 TO LS-T
    IF LS-T >= QS-END(LS-S)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "VALUES"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    IF LS-T >= QS-END(LS-S) OR NOT TK-IS-LPAREN(LS-T)
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-I
    MOVE 0 TO LS-DEPTH LS-ITEM-TOKENS
    MOVE 0 TO LS-ITEM-AT
    PERFORM VARYING LS-T FROM LS-T BY 1 UNTIL LS-T >= QS-END(LS-S)
        IF LS-DEPTH = 1 AND LS-ITEM-TOKENS > 0
            COMPUTE LS-PREV = LS-T - 1
            CALL "PLB-SQL-COMMA-BETWEEN" USING PLB-SOURCE-SET PLB-TOKENS
                LS-PREV LS-T LS-COMMA
            IF LS-COMMA = "Y"
                PERFORM END-VALUE
                ADD 1 TO LS-I
                MOVE 0 TO LS-ITEM-TOKENS LS-ITEM-AT
            END-IF
        END-IF
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-DEPTH
                IF LS-DEPTH > 1
                    ADD 1 TO LS-ITEM-TOKENS
                END-IF
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-DEPTH
                IF LS-DEPTH = 0
                    PERFORM END-VALUE
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-ITEM-TOKENS
            WHEN OTHER
                IF LS-ITEM-TOKENS = 0
                    MOVE LS-T TO LS-ITEM-AT
                END-IF
                ADD 1 TO LS-ITEM-TOKENS
        END-EVALUATE
    END-PERFORM.

*> Value LS-I of the VALUES list, LS-ITEM-TOKENS long from LS-ITEM-AT:
*> NULL alone, for a NOT NULL column.
END-VALUE.
    IF LS-ITEM-TOKENS NOT = 1 OR LS-I > LS-NAME-COUNT
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-ITEM-AT LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "NULL"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM QT-COL-FIRST(LS-TABLE) BY 1
            UNTIL LS-C >= QT-COL-FIRST(LS-TABLE) + QT-COL-COUNT(LS-TABLE)
        IF QL-NAME(LS-C) = LS-NAME(LS-I) AND QL-NULLS(LS-C) = "N"
            MOVE SPACES TO LS-MESSAGE
            STRING "INSERT gives NULL to " DELIMITED BY SIZE
                   QL-NAME(LS-C) DELIMITED BY SPACE
                   " of " DELIMITED BY SIZE
                   QT-NAME(LS-TABLE) DELIMITED BY SPACE
                   ", which is NOT NULL: Db2 rejects it (SQLCODE -407)"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE LS-ITEM-AT LS-MESSAGE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> UPDATE LS-S: each SET column = NULL, at the top level before
*> WHERE, for a NOT NULL column of its declared table.
CHECK-UPDATE.
    PERFORM FIND-TABLE
    IF LS-TABLE = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-DEPTH
    MOVE "N" TO LS-LIST
    PERFORM VARYING LS-T FROM QS-TOKEN(LS-S) BY 1
            UNTIL LS-T >= QS-END(LS-S)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-DEPTH
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-DEPTH
            WHEN LS-DEPTH > 0
                CONTINUE
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
                EVALUATE TRUE
                    WHEN LS-TEXT = "SET"
                        MOVE "Y" TO LS-LIST
                    WHEN LS-TEXT = "WHERE"
                        EXIT PERFORM
                    WHEN LS-LIST = "Y"
                        PERFORM CHECK-SET-NULL
                END-EVALUATE
        END-EVALUATE
    END-PERFORM.

*> The word LS-TEXT at LS-T in a SET: a column, = and NULL after it.
CHECK-SET-NULL.
    COMPUTE LS-AT = LS-T + 2
    IF LS-AT >= QS-END(LS-S)
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-I = LS-T + 1
    IF NOT TK-IS-OPERATOR(LS-I)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-AT LS-NAME(1) LS-LEN
    IF FUNCTION UPPER-CASE(LS-NAME(1)) NOT = "NULL"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM QT-COL-FIRST(LS-TABLE) BY 1
            UNTIL LS-C >= QT-COL-FIRST(LS-TABLE) + QT-COL-COUNT(LS-TABLE)
        IF QL-NAME(LS-C) = LS-TEXT AND QL-NULLS(LS-C) = "N"
            MOVE SPACES TO LS-MESSAGE
            STRING "UPDATE sets " DELIMITED BY SIZE
                   QL-NAME(LS-C) DELIMITED BY SPACE
                   " of " DELIMITED BY SIZE
                   QT-NAME(LS-TABLE) DELIMITED BY SPACE
                   " to NULL, but it is NOT NULL: Db2 rejects it"
                   " (SQLCODE -407)" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE LS-AT LS-MESSAGE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-TABLE: the declared table that statement LS-S names; 0: none.
FIND-TABLE.
    MOVE 0 TO LS-TABLE
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > QT-COUNT
        IF QT-NAME(LS-J) = QS-TABLE(LS-S, 1)
           OR QT-SHORT(LS-J) = QS-TABLE(LS-S, 1)
            MOVE LS-J TO LS-TABLE
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-MISSING.
    MOVE SPACES TO LS-MESSAGE
    STRING "INSERT into " DELIMITED BY SIZE
           QT-NAME(LS-TABLE) DELIMITED BY SPACE
           " leaves out column " DELIMITED BY SIZE
           QL-NAME(LS-C) DELIMITED BY SPACE
           ", NOT NULL without a default: Db2 rejects it (SQLCODE -407)"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-AT LS-MESSAGE.
END PROGRAM PLB-RULE-Q025.

*> ---------------------------------------------------------------
*> PLB-Q026 cursor-table-mismatch: an UPDATE or DELETE ... WHERE
*> CURRENT OF a cursor declared on another table:
*>
*>     EXEC SQL DECLARE ACCT-CUR CURSOR FOR
*>         SELECT ACCT_ID FROM ACCOUNT FOR UPDATE END-EXEC
*>     EXEC SQL DELETE FROM HISTORY WHERE CURRENT OF ACCT-CUR END-EXEC
*>
*> The statement changes the row the cursor is on, which is a row of
*> the cursor's table: Db2 rejects one that names another table with
*> SQLCODE -509. Usually the statement was copied from another cursor's
*> loop. Tables are compared without their qualifiers; a cursor on
*> more than one table is not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-Q026.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsqlm.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-CURSOR               PIC X(31).
01  LS-NAME                 PIC X(64).
01  LS-SHORT-1              PIC X(64).
01  LS-SHORT-2              PIC X(64).
01  LS-SHORT-TMP            PIC X(64).
01  LS-I                    PIC 9(4) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-Q026" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > QS-COUNT
        IF (QS-KIND(LS-S) = "U" OR QS-KIND(LS-S) = "D")
           AND QS-TABLE-COUNT(LS-S) = 1
            PERFORM CHECK-POSITIONED
        END-IF
    END-PERFORM
    GOBACK.

*> UPDATE or DELETE LS-S: CURRENT OF a cursor, and that cursor's table.
CHECK-POSITIONED.
    MOVE SPACES TO LS-CURSOR
    PERFORM VARYING LS-T FROM QS-TOKEN(LS-S) BY 1
            UNTIL LS-T >= QS-END(LS-S)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "CURRENT"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "OF"
                    ADD 1 TO LS-K
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-CURSOR
                    MOVE LS-K TO LS-AT
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF LS-CURSOR = SPACES
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > QS-COUNT
        IF QS-KIND(LS-C) = "C" AND QS-CURSOR(LS-C) = LS-CURSOR
            IF QS-TABLE-COUNT(LS-C) = 1
                MOVE QS-TABLE(LS-C, 1) TO LS-NAME
                PERFORM SHORT-NAME
                MOVE LS-NAME TO LS-SHORT-1
                MOVE QS-TABLE(LS-S, 1) TO LS-NAME
                PERFORM SHORT-NAME
                MOVE LS-NAME TO LS-SHORT-2
                IF LS-SHORT-1 NOT = LS-SHORT-2
                    PERFORM REPORT-MISMATCH
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-NAME without its qualifier: the part after its last dot.
SHORT-NAME.
    PERFORM VARYING LS-I FROM 64 BY -1 UNTIL LS-I = 0
        IF LS-NAME(LS-I:1) = "."
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-I > 0 AND LS-I < 64
        MOVE LS-NAME(LS-I + 1:) TO LS-SHORT-TMP
        MOVE LS-SHORT-TMP TO LS-NAME
    END-IF.

REPORT-MISMATCH.
    MOVE SPACES TO LS-MESSAGE
    STRING "cursor " DELIMITED BY SIZE
           LS-CURSOR DELIMITED BY SPACE
           " is declared on " DELIMITED BY SIZE
           QS-TABLE(LS-C, 1) DELIMITED BY SPACE
           ", not on " DELIMITED BY SIZE
           QS-TABLE(LS-S, 1) DELIMITED BY SPACE
           ": Db2 rejects this statement (SQLCODE -509)"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-AT LS-MESSAGE.
END PROGRAM PLB-RULE-Q026.
