*> ---------------------------------------------------------------
*> plbspan: storage spans of data items (copy/plbspan.cpy).
*> ---------------------------------------------------------------

*> PLB-SPAN-BUILD: the root and byte range of every symbol.
*> A condition name (88) spans its conditional variable. An item of
*> unknown size (ANY LENGTH, invalid picture) or a RENAMES item (66)
*> spans its whole record.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SPAN-BUILD.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5.
01  LS-GUARD                PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsym.cpy".
COPY "plbspan.cpy".
PROCEDURE DIVISION USING PLB-SYMBOLS PLB-SPANS.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        PERFORM SPAN-OF-ITEM
    END-PERFORM
    GOBACK.

SPAN-OF-ITEM.
    *> The record, and the outermost table on the way to it.
    MOVE LS-S TO LS-A
    IF SY-LEVEL(LS-A) = 88 AND SY-PARENT(LS-A) > 0
        MOVE SY-PARENT(LS-A) TO LS-A
    END-IF
    MOVE 0 TO LS-TABLE
    MOVE LS-A TO LS-ROOT
    PERFORM UNTIL LS-ROOT = 0
        IF SY-OCCURS(LS-ROOT) > 0
            MOVE LS-ROOT TO LS-TABLE
        END-IF
        IF SY-PARENT(LS-ROOT) = 0
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-ROOT) TO LS-ROOT
    END-PERFORM
    *> A record that redefines another shares that record's storage.
    MOVE 0 TO LS-GUARD
    PERFORM UNTIL SY-REDEFINES(LS-ROOT) = 0 OR LS-GUARD > 100
        IF SY-PARENT(SY-REDEFINES(LS-ROOT)) NOT = 0
            EXIT PERFORM
        END-IF
        MOVE SY-REDEFINES(LS-ROOT) TO LS-ROOT
        ADD 1 TO LS-GUARD
    END-PERFORM
    MOVE LS-ROOT TO SP-ROOT(LS-S)

    EVALUATE TRUE
        WHEN SY-SIZE(LS-A) = 0 OR SY-LEVEL(LS-A) = 66
            MOVE 0 TO SP-LOW(LS-S)
            MOVE 999999999 TO SP-HIGH(LS-S)
        WHEN LS-TABLE > 0
            MOVE SY-OFFSET(LS-TABLE) TO SP-LOW(LS-S)
            COMPUTE SP-HIGH(LS-S) = SY-OFFSET(LS-TABLE)
                + SY-SIZE(LS-TABLE) * SY-OCCURS(LS-TABLE)
        WHEN OTHER
            MOVE SY-OFFSET(LS-A) TO SP-LOW(LS-S)
            COMPUTE SP-HIGH(LS-S) = SY-OFFSET(LS-A) + SY-SIZE(LS-A)
    END-EVALUATE.
END PROGRAM PLB-SPAN-BUILD.

*> PLB-SPAN-OVERLAP: RESULT = "Y" when symbols A and B share storage.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SPAN-OVERLAP.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbspan.cpy".
01  LK-A                    PIC 9(9) COMP-5.
01  LK-B                    PIC 9(9) COMP-5.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING PLB-SPANS LK-A LK-B LK-RESULT.
    IF SP-ROOT(LK-A) = SP-ROOT(LK-B)
       AND SP-LOW(LK-A) < SP-HIGH(LK-B)
       AND SP-LOW(LK-B) < SP-HIGH(LK-A)
        MOVE "Y" TO LK-RESULT
    ELSE
        MOVE "N" TO LK-RESULT
    END-IF
    GOBACK.
END PROGRAM PLB-SPAN-OVERLAP.
