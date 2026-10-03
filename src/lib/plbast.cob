*> ---------------------------------------------------------------
*> plbast: building and walking the syntax tree (copy/plbast.cpy).
*> ---------------------------------------------------------------

*> PLB-AST-INIT: empty the tree.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-AST-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbastc.cpy".
COPY "plbast.cpy".
PROCEDURE DIVISION USING PLB-AST.
    MOVE 0 TO AS-COUNT
    GOBACK.
END PROGRAM PLB-AST-INIT.

*> PLB-AST-ADD: append a node of KIND and DETAIL as the last child
*> of PARENT (0 for a root), covering tokens from TOKEN onwards.
*> NODE receives the new node's index, or 0 when the table is full.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-AST-ADD.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbastc.cpy".
COPY "plbast.cpy".
01  LK-PARENT               PIC 9(9) COMP-5.
01  LK-KIND                 PIC X(4).
01  LK-DETAIL               PIC X ANY LENGTH.
01  LK-TOKEN                PIC 9(9) COMP-5.
01  LK-NODE                 PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-AST LK-PARENT LK-KIND LK-DETAIL LK-TOKEN
        LK-NODE.
    IF AS-COUNT >= AS-MAX
        MOVE 0 TO LK-NODE
        GOBACK
    END-IF
    ADD 1 TO AS-COUNT
    MOVE AS-COUNT TO LK-NODE
    MOVE LK-KIND TO ND-KIND(LK-NODE)
    MOVE LK-DETAIL TO ND-DETAIL(LK-NODE)
    MOVE LK-PARENT TO ND-PARENT(LK-NODE)
    MOVE 0 TO ND-FIRST(LK-NODE) ND-LAST(LK-NODE) ND-NEXT(LK-NODE)
    MOVE 0 TO ND-NAME(LK-NODE) ND-NUM(LK-NODE)
    MOVE LK-TOKEN TO ND-TOK-FIRST(LK-NODE) ND-TOK-LAST(LK-NODE)
    IF LK-PARENT > 0
        IF ND-LAST(LK-PARENT) = 0
            MOVE LK-NODE TO ND-FIRST(LK-PARENT)
        ELSE
            MOVE LK-NODE TO ND-NEXT(ND-LAST(LK-PARENT))
        END-IF
        MOVE LK-NODE TO ND-LAST(LK-PARENT)
    END-IF
    GOBACK.
END PROGRAM PLB-AST-ADD.

*> PLB-AST-NEXT: the node after NODE in a pre-order walk of the
*> subtree rooted at ROOT, or 0 when the walk is over. Start a walk
*> with NODE = ROOT. No recursion or stack is needed: the walk goes
*> down to a first child, else across to a sibling, else up until an
*> ancestor below ROOT has one.
*> DEPTH is adjusted by the move (+1 down, -n up) so callers can
*> indent output.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-AST-NEXT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  LS-NODE                 PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbastc.cpy".
COPY "plbast.cpy".
01  LK-ROOT                 PIC 9(9) COMP-5.
01  LK-NODE                 PIC 9(9) COMP-5.
01  LK-DEPTH                PIC S9(9) COMP-5.
PROCEDURE DIVISION USING PLB-AST LK-ROOT LK-NODE LK-DEPTH.
    IF LK-NODE = 0 OR LK-NODE > AS-COUNT
        MOVE 0 TO LK-NODE
        GOBACK
    END-IF
    IF ND-FIRST(LK-NODE) > 0
        MOVE ND-FIRST(LK-NODE) TO LK-NODE
        ADD 1 TO LK-DEPTH
        GOBACK
    END-IF
    MOVE LK-NODE TO LS-NODE
    PERFORM UNTIL LS-NODE = LK-ROOT OR LS-NODE = 0
        IF ND-NEXT(LS-NODE) > 0
            MOVE ND-NEXT(LS-NODE) TO LK-NODE
            GOBACK
        END-IF
        MOVE ND-PARENT(LS-NODE) TO LS-NODE
        SUBTRACT 1 FROM LK-DEPTH
    END-PERFORM
    MOVE 0 TO LK-NODE
    GOBACK.
END PROGRAM PLB-AST-NEXT.

*> PLB-AST-CHILD-COUNT: number of children of NODE.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-AST-CHILD-COUNT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-CHILD                PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbastc.cpy".
COPY "plbast.cpy".
01  LK-NODE                 PIC 9(9) COMP-5.
01  LK-COUNT                PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-AST LK-NODE LK-COUNT.
    MOVE 0 TO LK-COUNT
    IF LK-NODE < 1 OR LK-NODE > AS-COUNT
        GOBACK
    END-IF
    MOVE ND-FIRST(LK-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        ADD 1 TO LK-COUNT
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    GOBACK.
END PROGRAM PLB-AST-CHILD-COUNT.
