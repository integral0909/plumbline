*> ---------------------------------------------------------------
*> plbrcorr: PLB-C055 corresponding-no-match.
*>
*> A MOVE, ADD, or SUBTRACT CORRESPONDING whose two groups have no
*> pair of items that correspond: the statement does nothing.
*>
*>     01  IN-REC.
*>         05  CUST-ID     PIC X(8).
*>         05  CUST-NAME   PIC X(30).
*>     01  OUT-REC.
*>         05  CUSTOMER-ID PIC X(8).
*>         05  NAME        PIC X(30).
*>     ...
*>     MOVE CORRESPONDING IN-REC TO OUT-REC    *> moves nothing
*>
*> Two items correspond when they have the same name and the same
*> qualifiers up to the two groups, neither is FILLER, a condition
*> name, a RENAMES or USAGE INDEX item, and neither is, or is in, an
*> item with REDEFINES or OCCURS below the group. For MOVE one of the
*> two must be elementary; for ADD and SUBTRACT both must be
*> elementary numeric items. Renaming one side, or a change of a
*> picture, leaves the statement in place and doing nothing; the
*> compiler says nothing.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C055.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-FIRST-REF            PIC 9(9) COMP-5 VALUE 1.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-VERB                 PIC X(8).
*> The token after which the receiving group is named: TO, FROM.
01  LS-SOURCE-TOKEN         PIC 9(9) COMP-5.
01  LS-TARGET-TOKEN         PIC 9(9) COMP-5.
01  LS-SOURCE               PIC 9(9) COMP-5.
01  LS-TARGET               PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-UP-A                 PIC 9(9) COMP-5.
01  LS-UP-B                 PIC 9(9) COMP-5.
01  LS-ITEM                 PIC 9(9) COMP-5.
01  LS-GROUP                PIC 9(9) COMP-5.
01  LS-USABLE               PIC X.
01  LS-SAME-PATH            PIC X.
01  LS-NUMERIC              PIC X.
01  LS-NUMERIC-A            PIC X.
01  LS-PAIR                 PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C055" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR RF-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
           AND (ND-DETAIL(LS-NODE) = "MOVE" OR ND-DETAIL(LS-NODE) = "ADD"
                OR ND-DETAIL(LS-NODE) = "SUBTRACT")
            PERFORM CHECK-STATEMENT
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> VERB CORRESPONDING source TO (or FROM) target: the two groups, from
*> the references that start at those tokens.
CHECK-STATEMENT.
    MOVE ND-DETAIL(LS-NODE) TO LS-VERB
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    IF LS-T > ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    IF LS-TEXT NOT = "CORRESPONDING" AND LS-TEXT NOT = "CORR"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-SOURCE-TOKEN = LS-T + 1
    PERFORM UNTIL LS-FIRST-REF > RF-COUNT
            OR RF-TOKEN(LS-FIRST-REF) >= ND-TOK-FIRST(LS-NODE)
        ADD 1 TO LS-FIRST-REF
    END-PERFORM
    MOVE 0 TO LS-SOURCE LS-TARGET LS-TARGET-TOKEN
    PERFORM VARYING LS-R FROM LS-FIRST-REF BY 1
            UNTIL LS-R > RF-COUNT
               OR RF-TOKEN(LS-R) > ND-TOK-LAST(LS-NODE)
        IF RF-TOKEN(LS-R) = LS-SOURCE-TOKEN
            MOVE LS-R TO LS-SOURCE
            PERFORM FIND-TARGET-TOKEN
        END-IF
        IF LS-TARGET-TOKEN > 0 AND RF-TOKEN(LS-R) = LS-TARGET-TOKEN
            MOVE LS-R TO LS-TARGET
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-SOURCE = 0 OR LS-TARGET = 0
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-SOURCE) NOT = "D" OR RF-KIND(LS-TARGET) NOT = "D"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-SOURCE) TO LS-SOURCE
    MOVE RF-SYMBOL(LS-TARGET) TO LS-TARGET
    IF LS-SOURCE = 0 OR LS-TARGET = 0
        EXIT PARAGRAPH
    END-IF
    *> Both must be groups; other operands are the compiler's to
    *> reject.
    IF SY-CATEGORY(LS-SOURCE) NOT = "G"
       OR SY-CATEGORY(LS-TARGET) NOT = "G"
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-PAIR
    IF LS-PAIR = "N"
        PERFORM REPORT-NO-PAIR
    END-IF.

*> The word after the source's last token: TO for MOVE and ADD, FROM
*> for SUBTRACT; the target starts after it.
FIND-TARGET-TOKEN.
    COMPUTE LS-T = RF-LAST(LS-R) + 1
    IF LS-T >= ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    IF LS-TEXT = "TO" OR LS-TEXT = "FROM"
        COMPUTE LS-TARGET-TOKEN = LS-T + 1
    END-IF.

*> LS-PAIR = "Y" when an item in the source corresponds to one in the
*> target. The items of a group follow it in the symbol table.
FIND-PAIR.
    MOVE "N" TO LS-PAIR
    PERFORM VARYING LS-A FROM LS-SOURCE BY 1
            UNTIL LS-A > SY-COUNT OR LS-PAIR = "Y"
        IF LS-A > LS-SOURCE
            MOVE LS-A TO LS-ITEM
            MOVE LS-SOURCE TO LS-GROUP
            PERFORM TEST-USABLE
            IF LS-USABLE = "E"
                EXIT PERFORM
            END-IF
            IF LS-USABLE = "Y"
                MOVE LS-NUMERIC TO LS-NUMERIC-A
                PERFORM MATCH-IN-TARGET
            END-IF
        END-IF
    END-PERFORM.

MATCH-IN-TARGET.
    PERFORM VARYING LS-B FROM LS-TARGET BY 1
            UNTIL LS-B > SY-COUNT OR LS-PAIR = "Y"
        IF LS-B > LS-TARGET
            IF SY-NAME(LS-B) = SY-NAME(LS-A)
                MOVE LS-B TO LS-ITEM
                MOVE LS-TARGET TO LS-GROUP
                PERFORM TEST-USABLE
                IF LS-USABLE = "E"
                    EXIT PERFORM
                END-IF
                IF LS-USABLE = "Y"
                    PERFORM TEST-PATH
                    IF LS-SAME-PATH = "Y"
                        PERFORM TEST-KINDS
                    END-IF
                END-IF
            ELSE
                *> Past the end of the target group?
                MOVE LS-B TO LS-ITEM
                MOVE LS-TARGET TO LS-GROUP
                PERFORM TEST-INSIDE
                IF LS-USABLE = "E"
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> LS-USABLE for item LS-ITEM below LS-GROUP: "E" when it is not in the
*> group (the group has ended), "N" when it cannot correspond, "Y"
*> when it can; LS-NUMERIC = "Y" for an elementary numeric item.
TEST-USABLE.
    PERFORM TEST-INSIDE
    IF LS-USABLE = "E"
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-USABLE LS-NUMERIC
    IF SY-NAME(LS-ITEM) = SPACES OR SY-NAME(LS-ITEM) = "FILLER"
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-ITEM) = "C" OR SY-CATEGORY(LS-ITEM) = "R"
       OR SY-CATEGORY(LS-ITEM) = "K"
        EXIT PARAGRAPH
    END-IF
    IF SY-USAGE(LS-ITEM) = "INDEX"
        EXIT PARAGRAPH
    END-IF
    *> Neither it nor a group between it and LS-GROUP may redefine or
    *> repeat.
    MOVE LS-ITEM TO LS-UP-A
    PERFORM UNTIL LS-UP-A = LS-GROUP OR LS-UP-A = 0
        IF SY-REDEFINES(LS-UP-A) > 0 OR SY-OCCURS(LS-UP-A) > 0
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP-A) TO LS-UP-A
    END-PERFORM
    MOVE "Y" TO LS-USABLE
    EVALUATE SY-CATEGORY(LS-ITEM)
        WHEN "9"
            MOVE "Y" TO LS-NUMERIC
        WHEN "U"
            IF SY-USAGE(LS-ITEM) NOT = "POINTER"
               AND SY-USAGE(LS-ITEM) NOT = "PROCEDURE-POINTER"
               AND SY-USAGE(LS-ITEM) NOT = "PROGRAM-POINTER"
               AND SY-USAGE(LS-ITEM) NOT = "OBJECT-REFERENCE"
                MOVE "Y" TO LS-NUMERIC
            END-IF
    END-EVALUATE.

*> LS-USABLE = "E" when LS-ITEM is not below LS-GROUP.
TEST-INSIDE.
    MOVE "E" TO LS-USABLE
    MOVE SY-PARENT(LS-ITEM) TO LS-UP-A
    PERFORM UNTIL LS-UP-A = 0
        IF LS-UP-A = LS-GROUP
            MOVE "Y" TO LS-USABLE
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-UP-A) TO LS-UP-A
    END-PERFORM.

*> LS-SAME-PATH = "Y" when LS-A and LS-B have the same names from
*> themselves up to their groups.
TEST-PATH.
    MOVE "N" TO LS-SAME-PATH
    MOVE SY-PARENT(LS-A) TO LS-UP-A
    MOVE SY-PARENT(LS-B) TO LS-UP-B
    PERFORM UNTIL LS-UP-A = LS-SOURCE OR LS-UP-B = LS-TARGET
        IF SY-NAME(LS-UP-A) NOT = SY-NAME(LS-UP-B)
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP-A) TO LS-UP-A
        MOVE SY-PARENT(LS-UP-B) TO LS-UP-B
    END-PERFORM
    IF LS-UP-A = LS-SOURCE AND LS-UP-B = LS-TARGET
        MOVE "Y" TO LS-SAME-PATH
    END-IF.

*> A pair for MOVE when one of them is elementary; for ADD and
*> SUBTRACT when both are elementary and numeric.
TEST-KINDS.
    IF LS-VERB = "MOVE"
        IF SY-CATEGORY(LS-A) NOT = "G" OR SY-CATEGORY(LS-B) NOT = "G"
            MOVE "Y" TO LS-PAIR
        END-IF
    ELSE
        IF LS-NUMERIC-A = "Y" AND LS-NUMERIC = "Y"
            MOVE "Y" TO LS-PAIR
        END-IF
    END-IF.

REPORT-NO-PAIR.
    MOVE SPACES TO LS-MESSAGE
    IF LS-VERB = "MOVE"
        STRING "MOVE CORRESPONDING moves nothing: no item of "
               DELIMITED BY SIZE
               SY-NAME(LS-SOURCE) DELIMITED BY SPACE
               " corresponds to an item of " DELIMITED BY SIZE
               SY-NAME(LS-TARGET) DELIMITED BY SPACE
            INTO LS-MESSAGE
    ELSE
        STRING FUNCTION TRIM(LS-VERB) DELIMITED BY SIZE
               " CORRESPONDING does nothing: no numeric item of "
               DELIMITED BY SIZE
               SY-NAME(LS-SOURCE) DELIMITED BY SPACE
               " corresponds to a numeric item of "
               DELIMITED BY SIZE
               SY-NAME(LS-TARGET) DELIMITED BY SPACE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-NODE) LS-MESSAGE.
END PROGRAM PLB-RULE-C055.
