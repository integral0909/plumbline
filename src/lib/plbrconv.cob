*> ---------------------------------------------------------------
*> plbrconv: PLB-C096 converting-repeated.
*>
*> An INSPECT ... CONVERTING whose first string has a character twice,
*> with different characters for it in the second:
*>
*>     INSPECT WS-TEXT CONVERTING "ABA" TO "XYZ"
*>
*> Only the first occurrence counts: with GnuCOBOL 3.2 each A becomes
*> X, and the Z is never used. Usually one character of a table was
*> typed twice and another left out. Read are both strings written as
*> literals without a prefix; a character repeated with the same
*> character for it changes nothing, and is not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C096.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-J                    PIC 9(4) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-FROM-TEXT            PIC X(256).
01  LS-TO-TEXT              PIC X(256).
01  LS-FROM-LEN             PIC 9(9) COMP-5.
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
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C096" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "INSPECT"
            PERFORM CHECK-INSPECT
        END-IF
    END-PERFORM
    GOBACK.

*> CONVERTING literal TO literal.
CHECK-INSPECT.
    MOVE 0 TO LS-FROM
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "CONVERTING"
                COMPUTE LS-FROM = LS-T + 1
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-FROM = 0 OR LS-FROM + 2 > ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = LS-FROM + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "TO"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-TO = LS-FROM + 2
    IF NOT TK-IS-ALNUM(LS-FROM) OR NOT TK-IS-ALNUM(LS-TO)
        EXIT PARAGRAPH
    END-IF
    IF TK-PREFIX(LS-FROM) NOT = SPACES OR TK-PREFIX(LS-TO) NOT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE TK-TEXT-LEN(LS-FROM) TO LS-FROM-LEN
    IF LS-FROM-LEN < 2 OR LS-FROM-LEN > 256
       OR TK-TEXT-LEN(LS-TO) NOT = LS-FROM-LEN
        EXIT PARAGRAPH
    END-IF
    MOVE TK-TEXT(TK-TEXT-OFF(LS-FROM):LS-FROM-LEN) TO LS-FROM-TEXT
    MOVE TK-TEXT(TK-TEXT-OFF(LS-TO):LS-FROM-LEN) TO LS-TO-TEXT
    *> The first character repeated with another one for it.
    PERFORM VARYING LS-J FROM 2 BY 1 UNTIL LS-J > LS-FROM-LEN
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I >= LS-J
            IF LS-FROM-TEXT(LS-I:1) = LS-FROM-TEXT(LS-J:1)
                IF LS-TO-TEXT(LS-I:1) NOT = LS-TO-TEXT(LS-J:1)
                    PERFORM REPORT-REPEATED
                    EXIT PARAGRAPH
                END-IF
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-PERFORM.

REPORT-REPEATED.
    MOVE LS-I TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE LS-J TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING '"' LS-FROM-TEXT(LS-I:1) '" is at positions '
           LS-NUM-1(1:LS-NUM-1-LEN) " and " LS-NUM-2(1:LS-NUM-2-LEN)
           ' of the CONVERTING string: only the first counts, so it '
           'becomes "' LS-TO-TEXT(LS-I:1) '", and the "'
           LS-TO-TEXT(LS-J:1) '" for it is never used'
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-FROM LS-MESSAGE.
END PROGRAM PLB-RULE-C096.
