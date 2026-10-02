*> ---------------------------------------------------------------
*> plbacc: the access table shared by the data-flow rules.
*> ---------------------------------------------------------------

*> PLB-ACCESS-BUILD: spans, accesses sorted by root, and which items
*> are checked (copy/plbacc.cpy).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-ACCESS-BUILD.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-ROOT-NODE            PIC 9(9) COMP-5 VALUE 1.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbspan.cpy".
COPY "plbacc.cpy".
PROCEDURE DIVISION USING PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-REFS
        PLB-SPANS PLB-ACCESSES PLB-ACCESS-INDEX.
    CALL "PLB-SPAN-BUILD" USING PLB-SYMBOLS PLB-SPANS
    MOVE 0 TO AX-COUNT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D"
            MOVE RF-SYMBOL(LS-R) TO LS-S
            MOVE RF-ROLE(LS-R) TO LS-TEXT
            PERFORM ADD-ACCESS
        END-IF
    END-PERFORM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-HAS-VALUE(LS-S) = "Y" AND SY-LEVEL(LS-S) NOT = 88
           AND SY-LEVEL(LS-S) NOT = 78
            MOVE "V" TO LS-TEXT
            PERFORM ADD-ACCESS
        END-IF
    END-PERFORM
    PERFORM ENVIRONMENT-MENTIONS
    IF AX-COUNT > 1
        SORT AX-ENTRY ON ASCENDING KEY AX-ROOT
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE 0 TO AX-ROOT-FIRST(LS-S) AX-ROOT-LAST(LS-S)
        PERFORM DECIDE-CHECKED
    END-PERFORM
    PERFORM VARYING LS-A FROM 1 BY 1 UNTIL LS-A > AX-COUNT
        MOVE AX-ROOT(LS-A) TO LS-ROOT
        IF AX-ROOT-FIRST(LS-ROOT) = 0
            MOVE LS-A TO AX-ROOT-FIRST(LS-ROOT)
        END-IF
        MOVE LS-A TO AX-ROOT-LAST(LS-ROOT)
    END-PERFORM
    GOBACK.

*> An access by symbol LS-S with role LS-TEXT(1:1).
ADD-ACCESS.
    IF AX-COUNT < AX-MAX
        ADD 1 TO AX-COUNT
        MOVE LS-S TO AX-SYMBOL(AX-COUNT)
        MOVE SP-ROOT(LS-S) TO AX-ROOT(AX-COUNT)
        MOVE LS-TEXT(1:1) TO AX-ROLE(AX-COUNT)
    END-IF.

*> Each data item named in an environment division may be set by the
*> runtime (FILE STATUS, RECORD KEY, ...), and each named in the
*> procedure division header is given a value on entry: an X access.
ENVIRONMENT-MENTIONS.
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "PROG"
            MOVE LS-NODE TO LS-PROGRAM
        END-IF
        *> PROCEDURE DIVISION CHAINING items get their values from the
        *> command line, as USING items do from the caller.
        IF ND-KIND(LS-NODE) = "USNG" AND ND-NAME(LS-NODE) > 0
            IF TK-TEXT-LEN(ND-NAME(LS-NODE)) <= 31
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE)
                    LS-TEXT LS-LEN
                PERFORM MENTION-NAME
            END-IF
        END-IF
        IF ND-KIND(LS-NODE) = "DIVN"
           AND ND-DETAIL(LS-NODE) = "ENVIRONMENT"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-NODE)
                IF TK-IS-WORD(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    PERFORM MENTION-NAME
                END-IF
            END-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT-NODE LS-NODE LS-DEPTH
    END-PERFORM.

MENTION-NAME.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME(LS-S) = LS-TEXT AND SY-PROGRAM(LS-S) = LS-PROGRAM
            MOVE "X" TO LS-TEXT
            PERFORM ADD-ACCESS
            MOVE SY-NAME(LS-S) TO LS-TEXT
        END-IF
    END-PERFORM.

DECIDE-CHECKED.
    MOVE "N" TO AX-CHECKED(LS-S)
    IF SY-SECTION(LS-S) NOT = "W" AND SY-SECTION(LS-S) NOT = "L"
        EXIT PARAGRAPH
    END-IF
    IF SY-LEVEL(LS-S) = 78 OR SY-LEVEL(LS-S) = 66
        EXIT PARAGRAPH
    END-IF
    MOVE LS-S TO LS-A
    PERFORM UNTIL LS-A = 0
        MOVE ND-FIRST(SY-NODE(LS-A)) TO LS-C
        PERFORM UNTIL LS-C = 0
            IF ND-KIND(LS-C) = "CLAU"
               AND (ND-DETAIL(LS-C) = "EXTERNAL"
                    OR ND-DETAIL(LS-C) = "GLOBAL"
                    OR ND-DETAIL(LS-C) = "BASED")
                EXIT PARAGRAPH
            END-IF
            MOVE ND-NEXT(LS-C) TO LS-C
        END-PERFORM
        MOVE SY-PARENT(LS-A) TO LS-A
    END-PERFORM
    MOVE "Y" TO AX-CHECKED(LS-S).
END PROGRAM PLB-ACCESS-BUILD.

*> PLB-ACCESS-FIND: FOUND = "Y" when an access whose role is one of
*> the characters of ROLES shares storage with symbol SYMBOL.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-ACCESS-FIND.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5.
01  LS-COUNT                PIC 9(4) COMP-5.
01  LS-OVERLAP              PIC X.
LINKAGE SECTION.
COPY "plbspan.cpy".
COPY "plbacc.cpy".
01  LK-SYMBOL               PIC 9(9) COMP-5.
01  LK-ROLES                PIC X ANY LENGTH.
01  LK-FOUND                PIC X.
PROCEDURE DIVISION USING PLB-SPANS PLB-ACCESSES PLB-ACCESS-INDEX
        LK-SYMBOL LK-ROLES LK-FOUND.
    MOVE "N" TO LK-FOUND
    MOVE SP-ROOT(LK-SYMBOL) TO LS-ROOT
    IF AX-ROOT-FIRST(LS-ROOT) = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-A FROM AX-ROOT-FIRST(LS-ROOT) BY 1
            UNTIL LS-A > AX-ROOT-LAST(LS-ROOT)
        MOVE 0 TO LS-COUNT
        INSPECT LK-ROLES TALLYING LS-COUNT FOR ALL AX-ROLE(LS-A)
        IF LS-COUNT > 0
            CALL "PLB-SPAN-OVERLAP" USING PLB-SPANS LK-SYMBOL
                AX-SYMBOL(LS-A) LS-OVERLAP
            IF LS-OVERLAP = "Y"
                MOVE "Y" TO LK-FOUND
                GOBACK
            END-IF
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-ACCESS-FIND.
