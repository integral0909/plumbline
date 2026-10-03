*> ---------------------------------------------------------------
*> plbkw: reserved-word lookup.
*> ---------------------------------------------------------------

*> PLB-KW-LOOKUP: KIND receives the kind of reserved word WORD (see
*> copy/plbkwtab.cpy), or space if WORD is not reserved. WORD must be
*> upper case, as the lexer stores words.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-KW-LOOKUP.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbkwtab.cpy".
01  LS-KEY                  PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-WORD                 PIC X ANY LENGTH.
01  LK-KIND                 PIC X.
PROCEDURE DIVISION USING LK-WORD LK-KIND.
    MOVE SPACE TO LK-KIND
    *> Callers pass wide text buffers. A word longer than 31 characters
    *> is not reserved, and that takes one comparison to see.
    MOVE FUNCTION LENGTH(LK-WORD) TO LS-LEN
    IF LS-LEN > 31
        IF LK-WORD(32:) NOT = SPACES
            GOBACK
        END-IF
        MOVE LK-WORD(1:31) TO LS-KEY
    ELSE
        MOVE LK-WORD TO LS-KEY
    END-IF
    IF LS-KEY = SPACES
        GOBACK
    END-IF
    SEARCH ALL WS-KEYWORD
        AT END
            CONTINUE
        WHEN KW-WORD(KW-INDEX) = LS-KEY
            MOVE KW-KIND(KW-INDEX) TO LK-KIND
    END-SEARCH
    GOBACK.
END PROGRAM PLB-KW-LOOKUP.

*> PLB-KW-SELF-CHECK: verify the table is strictly ascending, which
*> SEARCH ALL relies on. COUNT receives the number of entries and
*> BAD the index of the first entry not greater than the one before
*> it (0 when the table is in order).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-KW-SELF-CHECK.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbkwtab.cpy".
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-COUNT                PIC 9(9) COMP-5.
01  LK-BAD                  PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-COUNT LK-BAD.
    MOVE KW-COUNT TO LK-COUNT
    MOVE 0 TO LK-BAD
    PERFORM VARYING LS-I FROM 2 BY 1 UNTIL LS-I > KW-COUNT
        IF KW-WORD(LS-I) NOT > KW-WORD(LS-I - 1)
            MOVE LS-I TO LK-BAD
            EXIT PERFORM
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-KW-SELF-CHECK.
