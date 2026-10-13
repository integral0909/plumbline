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
*>
*> PLB-C115 inspect-no-change: an INSPECT that replaces a literal by
*> the same literal, or converts a string to itself:
*>
*>     INSPECT WS-TEXT REPLACING ALL "," BY ","
*>     INSPECT WS-TEXT CONVERTING ";," TO ";,"
*>
*> The replacement, or the conversion, changes nothing (GnuCOBOL 3.2
*> leaves the item as it was); usually one of the two was meant to be
*> another character, as in REPLACING ALL "," BY ".". Literals without
*> a prefix are read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C096.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-SAME            PIC 9(4) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C115" LS-RULE-SAME
    IF (RL-ENABLED(LS-RULE) NOT = "Y" AND RL-ENABLED(LS-RULE-SAME) NOT = "Y")
       OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "INSPECT"
            IF RL-ENABLED(LS-RULE-SAME) = "Y"
                PERFORM CHECK-NO-CHANGE
            END-IF
            IF RL-ENABLED(LS-RULE) = "Y"
                PERFORM CHECK-INSPECT
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> C115: literal BY the same literal, or literal TO the same literal
*> after CONVERTING.
CHECK-NO-CHANGE.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T) AND LS-T > ND-TOK-FIRST(LS-NODE)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "BY" OR LS-WORD = "TO"
                COMPUTE LS-A = LS-T - 1
                COMPUTE LS-B = LS-T + 1
                IF TK-IS-ALNUM(LS-A) AND TK-IS-ALNUM(LS-B)
                   AND TK-PREFIX(LS-A) = SPACES
                   AND TK-PREFIX(LS-B) = SPACES
                   AND TK-TEXT-LEN(LS-A) = TK-TEXT-LEN(LS-B)
                   AND TK-TEXT-LEN(LS-A) > 0
                    IF TK-TEXT(TK-TEXT-OFF(LS-A):TK-TEXT-LEN(LS-A))
                       = TK-TEXT(TK-TEXT-OFF(LS-B):TK-TEXT-LEN(LS-B))
                        PERFORM REPORT-SAME
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.

REPORT-SAME.
    MOVE SPACES TO LS-MESSAGE
    IF LS-WORD = "BY"
        STRING 'INSPECT replaces "' DELIMITED BY SIZE
               TK-TEXT(TK-TEXT-OFF(LS-A):TK-TEXT-LEN(LS-A))
               DELIMITED BY SIZE
               '" by itself: that replacement changes nothing'
               DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "INSPECT converts a string to the same string: the"
               " statement changes nothing" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-SAME LS-B LS-MESSAGE.

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
