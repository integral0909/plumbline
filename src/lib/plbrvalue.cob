*> ---------------------------------------------------------------
*> plbrvalue: PLB-C073 value-ignored.
*>
*> A VALUE clause on an item of the FILE or LINKAGE SECTION:
*>
*>     FD  OUT-FILE.
*>     01  OUT-REC.
*>         05  OUT-TYPE        PIC X VALUE "H".
*>
*> Storage there is not the program's own: a record holds what was last
*> read or moved into it, and a linkage item is the caller's storage, so
*> the VALUE gives the item nothing. Condition names (88) and constants
*> (78) are not reported; their values mean something. Each record is
*> reported once, at its first VALUE. VALUE clauses that a copybook
*> brings in are not reported: a copybook is often both a working-storage
*> record of one program and a linkage record of another. Nor is a
*> record that ALLOCATE ... INITIALIZED or INITIALIZE ... TO VALUE
*> names (or an item of it): those statements give it its VALUE
*> clauses at run time.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C073.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5.
01  LS-LAST-ROOT            PIC 9(9) COMP-5 VALUE 0.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-APPLIED              PIC X.
01  LS-TEXT                 PIC X(31).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C073" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-HAS-VALUE(LS-S) = "Y" AND SY-NODE(LS-S) > 0
           AND (SY-SECTION(LS-S) = "F" OR SY-SECTION(LS-S) = "K")
           AND SY-CATEGORY(LS-S) NOT = "C"
           AND SY-CATEGORY(LS-S) NOT = "K"
            PERFORM CHECK-ITEM
        END-IF
    END-PERFORM
    GOBACK.

*> Item LS-S has a VALUE: report it unless its record was reported or
*> the clause comes from a copybook.
CHECK-ITEM.
    MOVE LS-S TO LS-ROOT
    PERFORM UNTIL SY-PARENT(LS-ROOT) = 0
        MOVE SY-PARENT(LS-ROOT) TO LS-ROOT
    END-PERFORM
    IF LS-ROOT = LS-LAST-ROOT
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TOKEN
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "CLAU" AND ND-DETAIL(LS-C) = "VALUE"
            MOVE ND-TOK-FIRST(LS-C) TO LS-TOKEN
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM
    IF LS-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    IF TK-INCL(LS-TOKEN) > 0
        EXIT PARAGRAPH
    END-IF
    MOVE LS-ROOT TO LS-LAST-ROOT
    PERFORM TEST-APPLIED
    IF LS-APPLIED = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "VALUE gives " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF SY-SECTION(LS-S) = "F"
        STRING " nothing: in the FILE SECTION, the record holds what"
               " was last read or moved into it" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING " nothing: in the LINKAGE SECTION, the item is the"
               " caller's storage" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
*> LS-APPLIED = "Y" when a reference to record LS-ROOT, or to an item
*> of it, is in an ALLOCATE with INITIALIZED or an INITIALIZE with
*> VALUE.
TEST-APPLIED.
    MOVE "N" TO LS-APPLIED
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
           AND RF-STMT(LS-R) > 0
            MOVE RF-STMT(LS-R) TO LS-STMT
            IF ND-DETAIL(LS-STMT) = "ALLOCATE"
               OR ND-DETAIL(LS-STMT) = "INITIALIZE"
                MOVE RF-SYMBOL(LS-R) TO LS-UP
                PERFORM UNTIL SY-PARENT(LS-UP) = 0
                    MOVE SY-PARENT(LS-UP) TO LS-UP
                END-PERFORM
                IF LS-UP = LS-ROOT
                    PERFORM TEST-APPLYING-STATEMENT
                    IF LS-APPLIED = "Y"
                        EXIT PERFORM
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> Statement LS-STMT is ALLOCATE ... INITIALIZED or INITIALIZE ...
*> VALUE.
TEST-APPLYING-STATEMENT.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "INITIALIZED"
               OR FUNCTION UPPER-CASE(LS-TEXT) = "VALUE"
                MOVE "Y" TO LS-APPLIED
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

END PROGRAM PLB-RULE-C073.
