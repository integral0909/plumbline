*> ---------------------------------------------------------------
*> plbrclass: PLB-C113 class-test-invalid, PLB-C114
*> sign-test-not-numeric.
*>
*> A class condition that IBM Enterprise COBOL does not accept for the
*> item it tests (Language Reference, "Class condition"):
*>
*>     01  WS-QTY          PIC 9(4).
*>         IF WS-QTY IS ALPHABETIC          ALPHABETIC of a numeric item
*>     01  WS-NAME         PIC A(20).
*>         IF WS-NAME IS NUMERIC            NUMERIC of an alphabetic item
*>     01  WS-AMOUNTS.
*>         05  WS-AMT      PIC S9(3).
*>         IF WS-AMOUNTS IS NUMERIC         NUMERIC of a group with a
*>                                          signed item
*>
*> GnuCOBOL 3.2 compiles all three. The last is wrong there too: the
*> group is tested as characters, and the sign of a negative WS-AMT,
*> kept in its last digit, is not one, so the group holding -12 is not
*> NUMERIC while holding +12 it is. ALPHABETIC-LOWER and -UPPER count
*> as ALPHABETIC. Reference-modified items are left out: a reference
*> modification is alphanumeric, and may be tested either way.
*>
*> PLB-C114 is the same for a sign condition, IS [NOT] POSITIVE,
*> NEGATIVE, or ZERO, whose item is not numeric: alphanumeric,
*> alphabetic, edited, or a group. IBM Enterprise COBOL takes only a
*> numeric item or an arithmetic expression there; GnuCOBOL 3.2
*> compiles it. Usually the item was meant to be compared: IF WS-X =
*> ZERO is a relation, and allowed.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C113.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference ending at each token (0: none), for the tokens of the
*> current file.
01  WS-LAST-REF             PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-SIGN            PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-SIGNED               PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-NEXT-WORD            PIC X(31).
01  LS-CLASS                PIC X(31).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C113" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C114" LS-RULE-SIGN
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-SIGN) NOT = "Y") OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-LAST-REF(RF-LAST(LS-R))
    END-PERFORM
    PERFORM VARYING LS-T FROM 2 BY 1 UNTIL LS-T > TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-CLASS
            IF LS-CLASS = "NUMERIC" OR "ALPHABETIC" OR "ALPHABETIC-LOWER"
               OR "ALPHABETIC-UPPER" OR "POSITIVE" OR "NEGATIVE" OR "ZERO"
                PERFORM CHECK-CLASS
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-LAST-REF(RF-LAST(LS-R))
    END-PERFORM
    GOBACK.

*> Class or sign word at LS-T: the item before it, past NOT and IS.
CHECK-CLASS.
    *> Not INITIALIZE ... NUMERIC TO VALUE, or REPLACING NUMERIC DATA.
    IF LS-T < TK-COUNT
        COMPUTE LS-K = LS-T + 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-NEXT-WORD LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-NEXT-WORD) TO LS-NEXT-WORD
        IF LS-NEXT-WORD = "TO" OR LS-NEXT-WORD = "DATA"
            EXIT PARAGRAPH
        END-IF
    END-IF
    COMPUTE LS-K = LS-T - 1
    PERFORM 2 TIMES
        IF LS-K > 1 AND WS-LAST-REF(LS-K) = 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "NOT" OR LS-WORD = "IS"
                SUBTRACT 1 FROM LS-K
            END-IF
        END-IF
    END-PERFORM
    IF WS-LAST-REF(LS-K) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE WS-LAST-REF(LS-K) TO LS-R
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) NOT = "N"
        EXIT PARAGRAPH
    END-IF
    IF RF-STMT(LS-R) > 0
        IF ND-DETAIL(RF-STMT(LS-R)) = "INITIALIZE"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    MOVE SPACES TO LS-MESSAGE
    IF LS-CLASS = "POSITIVE" OR "NEGATIVE" OR "ZERO"
        PERFORM CHECK-SIGN
        EXIT PARAGRAPH
    END-IF
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN LS-CLASS = "NUMERIC" AND SY-CATEGORY(LS-S) = "A"
            STRING "NUMERIC test of " DELIMITED BY SIZE
                   SY-NAME(LS-S) DELIMITED BY SPACE
                   ", an alphabetic item: IBM Enterprise COBOL does not"
                   " accept it" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN LS-CLASS NOT = "NUMERIC" AND SY-CATEGORY(LS-S) = "9"
            STRING LS-CLASS DELIMITED BY SPACE
                   " test of " DELIMITED BY SIZE
                   SY-NAME(LS-S) DELIMITED BY SPACE
                   ", a numeric item: IBM Enterprise COBOL does not"
                   " accept it" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN LS-CLASS = "NUMERIC" AND SY-CATEGORY(LS-S) = "G"
            PERFORM FIND-SIGNED
            IF LS-SIGNED = 0
                EXIT PARAGRAPH
            END-IF
            STRING "NUMERIC test of the group " DELIMITED BY SIZE
                   SY-NAME(LS-S) DELIMITED BY SPACE
                   ", which has the signed item " DELIMITED BY SIZE
                   SY-NAME(LS-SIGNED) DELIMITED BY SPACE
                   ": a negative sign is not a digit, and IBM Enterprise"
                   " COBOL does not accept it" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-T LS-MESSAGE.

*> Sign condition at LS-T on item LS-S.
CHECK-SIGN.
    IF RL-ENABLED(LS-RULE-SIGN) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-CATEGORY(LS-S)
        WHEN "X"
            MOVE "an alphanumeric item" TO LS-WORD
        WHEN "A"
            MOVE "an alphabetic item" TO LS-WORD
        WHEN "E" WHEN "D"
            MOVE "an edited item" TO LS-WORD
        WHEN "G"
            MOVE "a group" TO LS-WORD
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    STRING LS-CLASS DELIMITED BY SPACE
           " test of " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           ", " DELIMITED BY SIZE
           LS-WORD DELIMITED BY "  "
           ": a sign condition needs a number, and IBM Enterprise"
           " COBOL does not accept it" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-SIGN LS-T LS-MESSAGE.

*> LS-SIGNED: the first signed numeric item in group LS-S (0: none).
*> The items of a group follow it, each with the group above it.
FIND-SIGNED.
    MOVE 0 TO LS-SIGNED
    PERFORM VARYING LS-E FROM LS-S BY 1 UNTIL LS-E >= SY-COUNT
        COMPUTE LS-K = LS-E + 1
        MOVE SY-PARENT(LS-K) TO LS-UP
        PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-S
            MOVE SY-PARENT(LS-UP) TO LS-UP
        END-PERFORM
        IF LS-UP = 0
            EXIT PERFORM
        END-IF
        IF SY-CATEGORY(LS-K) = "9" AND SY-SIGNED(LS-K) = "Y"
           AND SY-REDEFINES(LS-K) = 0
            MOVE LS-K TO LS-SIGNED
            EXIT PERFORM
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-C113.
