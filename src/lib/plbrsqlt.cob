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
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
01  LS-MATCHES              PIC 9(9) COMP-5.
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
    IF RL-ENABLED(LS-RULE-SMALL) NOT = "Y"
       AND RL-ENABLED(LS-RULE-LARGE) NOT = "Y"
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
    IF RL-ENABLED(LS-RULE) NOT = "Y"
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

*> LS-C: the column of pair LS-P, in a table of the statement, or else
*> the one column of that name among all declared tables; 0 when none
*> or more than one.
FIND-COLUMN.
    MOVE 0 TO LS-C LS-MATCHES
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > QS-TABLE-COUNT(LS-S)
        PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > QT-COUNT
            IF QT-NAME(LS-J) = QS-TABLE(LS-S, LS-I)
               OR QT-SHORT(LS-J) = QS-TABLE(LS-S, LS-I)
                PERFORM COLUMN-IN-TABLE
            END-IF
        END-PERFORM
    END-PERFORM
    IF LS-MATCHES = 1
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-C LS-MATCHES
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > QT-COUNT
        PERFORM COLUMN-IN-TABLE
    END-PERFORM
    IF LS-MATCHES NOT = 1
        MOVE 0 TO LS-C
    END-IF.

COLUMN-IN-TABLE.
    PERFORM VARYING LS-FOUND FROM QT-COL-FIRST(LS-J) BY 1
            UNTIL LS-FOUND >= QT-COL-FIRST(LS-J) + QT-COL-COUNT(LS-J)
        IF QL-NAME(LS-FOUND) = QP-COLUMN(LS-P)
            MOVE LS-FOUND TO LS-C
            ADD 1 TO LS-MATCHES
        END-IF
    END-PERFORM.

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
