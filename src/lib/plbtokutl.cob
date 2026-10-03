*> ---------------------------------------------------------------
*> plbtokutl: small operations on token tables.
*> ---------------------------------------------------------------

*> PLB-TOK-SAME: RESULT = "Y" when tokens I and J of TOKENS are the
*> same text-word: same kind, same literal prefix, and same text.
*> Words are stored upper-cased, so the comparison ignores case as
*> COBOL does; literal values are compared exactly.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-TOK-SAME.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-I                    PIC 9(9) COMP-5.
01  LK-J                    PIC 9(9) COMP-5.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING PLB-TOKENS LK-I LK-J LK-RESULT.
    MOVE "N" TO LK-RESULT
    IF TK-KIND(LK-I) NOT = TK-KIND(LK-J)
       OR TK-PREFIX(LK-I) NOT = TK-PREFIX(LK-J)
       OR TK-TEXT-LEN(LK-I) NOT = TK-TEXT-LEN(LK-J)
        GOBACK
    END-IF
    IF TK-TEXT-LEN(LK-I) = 0
        MOVE "Y" TO LK-RESULT
        GOBACK
    END-IF
    IF TK-TEXT(TK-TEXT-OFF(LK-I):TK-TEXT-LEN(LK-I))
       = TK-TEXT(TK-TEXT-OFF(LK-J):TK-TEXT-LEN(LK-J))
        MOVE "Y" TO LK-RESULT
    END-IF
    GOBACK.
END PROGRAM PLB-TOK-SAME.

*> PLB-TOK-IS-WORD: RESULT = "Y" when token I is the word WORD.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-TOK-IS-WORD.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-I                    PIC 9(9) COMP-5.
01  LK-WORD                 PIC X ANY LENGTH.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING PLB-TOKENS LK-I LK-WORD LK-RESULT.
    MOVE "N" TO LK-RESULT
    IF LK-I < 1 OR LK-I > TK-COUNT
        GOBACK
    END-IF
    IF NOT TK-IS-WORD(LK-I)
        GOBACK
    END-IF
    *> WORD matches when it holds the token's text followed only by
    *> spaces: compare the lengths before any text.
    MOVE TK-TEXT-LEN(LK-I) TO LS-LEN
    IF LS-LEN = 0 OR LS-LEN > FUNCTION LENGTH(LK-WORD)
        GOBACK
    END-IF
    IF TK-TEXT(TK-TEXT-OFF(LK-I):LS-LEN) NOT = LK-WORD(1:LS-LEN)
        GOBACK
    END-IF
    IF LS-LEN < FUNCTION LENGTH(LK-WORD)
        IF LK-WORD(LS-LEN + 1:) NOT = SPACES
            GOBACK
        END-IF
    END-IF
    MOVE "Y" TO LK-RESULT
    GOBACK.
END PROGRAM PLB-TOK-IS-WORD.
