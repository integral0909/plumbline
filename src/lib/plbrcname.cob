*> ---------------------------------------------------------------
*> plbrcname: PLB-K008 cics-name-too-long.
*>
*> An EXEC CICS command that names a resource with a literal longer
*> than CICS names of its kind are:
*>
*>     EXEC CICS RETURN TRANSID('ACCTU') END-EXEC     5 characters
*>
*> A transaction is 1 to 4 characters; a program, and a file (FILE or
*> DATASET), 1 to 8; a BMS map and mapset, 1 to 7. No resource has a
*> longer name, so the command finds none: CICS raises INVREQ, PGMIDERR,
*> FILENOTFOUND, or MAPFAIL, or abends the task. Usually a name was
*> typed with a character too many, or taken from another system. Read
*> are literals without a prefix; trailing spaces do not count.
*>
*> PLB-K016 abcode-invalid: an EXEC CICS ABEND ABCODE literal that CICS
*> does not take as an abend code: one that starts with A ("Do not
*> start the name with the letter A because this is reserved for CICS
*> itself"), or that is not the "name (1-4 characters)" of DUMPCODE,
*> whose rules it follows: longer, or with a leading or embedded blank,
*> for which CICS raises INVREQ.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-K008.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-ABCODE          PIC 9(4) COMP-5.
01  LS-CODE                 PIC X(31).
01  LS-I                    PIC 9(4) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-LIT                  PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-OPTION               PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-USED                 PIC 9(9) COMP-5.
01  LS-LIMIT                PIC 9(4) COMP-5.
01  LS-KIND                 PIC X(20).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-1                PIC X(20).
01  LS-NUM-1-LEN            PIC 9(9) COMP-5.
01  LS-NUM-2                PIC X(20).
01  LS-NUM-2-LEN            PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K008" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K016" LS-RULE-ABCODE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
       AND RL-ENABLED(LS-RULE-ABCODE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "EXEC"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "CICS"
                    PERFORM CHECK-COMMAND
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> The options of the command from LS-K to END-EXEC: name ( literal ).
CHECK-COMMAND.
    MOVE LS-K TO LS-END
    PERFORM UNTIL LS-END >= TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-END LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) = "END-EXEC"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-END
    END-PERFORM
    PERFORM VARYING LS-K FROM LS-K BY 1 UNTIL LS-K + 3 > LS-END
        IF TK-IS-WORD(LS-K) AND TK-IS-LPAREN(LS-K + 1)
           AND TK-IS-ALNUM(LS-K + 2) AND TK-IS-RPAREN(LS-K + 3)
            COMPUTE LS-LIT = LS-K + 2
            PERFORM CHECK-OPTION
        END-IF
    END-PERFORM.

*> Option LS-K with the literal LS-LIT.
CHECK-OPTION.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-OPTION LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-OPTION) TO LS-OPTION
    IF LS-OPTION = "ABCODE"
        IF RL-ENABLED(LS-RULE-ABCODE) = "Y"
           AND TK-PREFIX(LS-LIT) = SPACES
            PERFORM CHECK-ABCODE
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    EVALUATE LS-OPTION
        WHEN "TRANSID"
            MOVE 4 TO LS-LIMIT
            MOVE "transaction" TO LS-KIND
        WHEN "PROGRAM"
            MOVE 8 TO LS-LIMIT
            MOVE "program" TO LS-KIND
        WHEN "FILE" WHEN "DATASET"
            MOVE 8 TO LS-LIMIT
            MOVE "file" TO LS-KIND
        WHEN "MAP"
            MOVE 7 TO LS-LIMIT
            MOVE "map" TO LS-KIND
        WHEN "MAPSET"
            MOVE 7 TO LS-LIMIT
            MOVE "mapset" TO LS-KIND
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    IF TK-PREFIX(LS-LIT) NOT = SPACES
        EXIT PARAGRAPH
    END-IF
    *> Its length without trailing spaces.
    MOVE TK-TEXT-LEN(LS-LIT) TO LS-USED
    PERFORM UNTIL LS-USED = 0
        IF TK-TEXT(TK-TEXT-OFF(LS-LIT) + LS-USED - 1:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-USED
    END-PERFORM
    IF LS-USED <= LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    MOVE LS-USED TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE LS-LIMIT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING LS-OPTION DELIMITED BY SPACE
           " names a " DELIMITED BY SIZE
           LS-KIND DELIMITED BY SPACE
           " of " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           " characters; a CICS " DELIMITED BY SIZE
           LS-KIND DELIMITED BY SPACE
           " name has at most " DELIMITED BY SIZE
           LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           ", so the command finds none" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-LIT LS-MESSAGE.

*> The ABCODE literal LS-LIT: 1 to 4 characters, no blank before its
*> last, and not starting with A.
CHECK-ABCODE.
    MOVE TK-TEXT-LEN(LS-LIT) TO LS-USED
    PERFORM UNTIL LS-USED = 0
        IF TK-TEXT(TK-TEXT-OFF(LS-LIT) + LS-USED - 1:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-USED
    END-PERFORM
    IF LS-USED = 0 OR LS-USED > 31
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-CODE
    MOVE TK-TEXT(TK-TEXT-OFF(LS-LIT):LS-USED) TO LS-CODE
    MOVE SPACES TO LS-MESSAGE
    EVALUATE TRUE
        WHEN LS-USED > 4
            STRING "abend code '" DELIMITED BY SIZE
                   LS-CODE(1:LS-USED) DELIMITED BY SIZE
                   "' is longer than 4 characters" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN LS-CODE(1:1) = "A"
            STRING "abend code '" DELIMITED BY SIZE
                   LS-CODE(1:LS-USED) DELIMITED BY SIZE
                   "' starts with A, which CICS keeps for its own abend"
                   " codes" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN OTHER
            PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I >= LS-USED
                IF LS-CODE(LS-I:1) = SPACE
                    STRING "abend code '" DELIMITED BY SIZE
                           LS-CODE(1:LS-USED) DELIMITED BY SIZE
                           "' has a blank in it: CICS raises INVREQ"
                           DELIMITED BY SIZE
                        INTO LS-MESSAGE
                    EXIT PERFORM
                END-IF
            END-PERFORM
    END-EVALUATE
    IF LS-MESSAGE = SPACES
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-ABCODE LS-LIT LS-MESSAGE.
END PROGRAM PLB-RULE-K008.
