*> ---------------------------------------------------------------
*> plbxref: the cross-reference of each program (plumbline xref).
*>
*> For each program, its data items and its paragraphs and sections,
*> each with where it is defined and every statement that names it,
*> as a compiler's cross-reference listing gives them. Data
*> references come from the reference table, marked when the statement
*> changes the item; procedure references from the PERFORM, GO TO,
*> and ALTER edges of the procedure graph.
*>
*> PLB-XREF-BEGIN starts the output, PLB-XREF-FILE adds the programs
*> of one analyzed file, and PLB-XREF-END finishes it (JSON needs the
*> closing brackets). The caller keeps ANY, "Y" once a program has
*> been written, so that the next one starts with a separator.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-XREF-BEGIN.
DATA DIVISION.
LINKAGE SECTION.
01  LK-FORMAT               PIC X(5).
01  LK-ANY                  PIC X.
PROCEDURE DIVISION USING LK-FORMAT LK-ANY.
    IF LK-FORMAT = "json"
        DISPLAY "{"
        DISPLAY '  "programs": ['
    END-IF
    MOVE "N" TO LK-ANY
    GOBACK.
END PROGRAM PLB-XREF-BEGIN.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-XREF-END.
DATA DIVISION.
LINKAGE SECTION.
01  LK-FORMAT               PIC X(5).
01  LK-ANY                  PIC X.
PROCEDURE DIVISION USING LK-FORMAT LK-ANY.
    IF LK-FORMAT = "json"
        IF LK-ANY = "Y"
            DISPLAY "    }"
        END-IF
        DISPLAY "  ]"
        DISPLAY "}"
    END-IF
    GOBACK.
END PROGRAM PLB-XREF-END.

*> PLB-XREF-FILE: the programs of the file just analyzed.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-XREF-FILE.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The references of each item, in source order: the first reference
*> of each symbol and the next of each reference.
01  WS-SYM-HEAD             PIC 9(9) COMP-5 OCCURS 100000 TIMES.
01  WS-REF-NEXT             PIC 9(9) COMP-5 OCCURS 200000 TIMES.
*> The edges that name each unit: as target, and in a second chain as
*> the end of a THRU range or as the paragraph an ALTER changes.
01  WS-UNIT-HEAD            PIC 9(9) COMP-5 OCCURS 20000 TIMES.
01  WS-UNIT-THRU-HEAD       PIC 9(9) COMP-5 OCCURS 20000 TIMES.
01  WS-EDGE-NEXT            PIC 9(9) COMP-5 OCCURS 100000 TIMES.
01  WS-EDGE-THRU-NEXT       PIC 9(9) COMP-5 OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-PROGRAM-FILE         PIC 9(4) COMP-5.
01  LS-FIRST                PIC X.
01  LS-WORD                 PIC X(64).
01  LS-WORD-LEN             PIC 9(9) COMP-5.
01  LS-FILE                 PIC 9(4) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-PATH-LEN             PIC 9(9) COMP-5.
01  LS-BASE                 PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
*> One line of output, and the piece being added to it.
01  LS-OUT                  PIC X(4096).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-PIECE                PIC X(400).
01  LS-PIECE-LEN            PIC 9(9) COMP-5.
01  LS-PIECE-PTR            PIC 9(9) COMP-5.
*> The mark of a reference (M, P, G, A, T, or space) and the last one
*> written, so that repeats on one line are listed once.
01  LS-MARK                 PIC X.
01  LS-HOW                  PIC X(8).
01  LS-PREV-FILE            PIC 9(4) COMP-5.
01  LS-PREV-LINE            PIC 9(9) COMP-5.
01  LS-PREV-MARK            PIC X.
01  LS-ANY-REF              PIC X.
01  LS-KIND                 PIC X(9).
01  LS-LEVEL                PIC 9(4).
*> Where references wrap in the text listing.
78  LS-WIDTH                VALUE 79.
78  LS-INDENT               VALUE 8.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbflow.cpy".
01  LK-FORMAT               PIC X(5).
01  LK-ANY                  PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-FLOW LK-FORMAT LK-ANY.
    PERFORM CHAIN-REFERENCES
    PERFORM CHAIN-EDGES
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-KIND(LS-N) = "PROG" AND ND-NAME(LS-N) > 0
            MOVE LS-N TO LS-PROGRAM
            PERFORM WRITE-PROGRAM
        END-IF
    END-PERFORM
    GOBACK.

*> Built backwards, so that each chain is in source order.
CHAIN-REFERENCES.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE 0 TO WS-SYM-HEAD(LS-S)
    END-PERFORM
    PERFORM VARYING LS-R FROM RF-COUNT BY -1 UNTIL LS-R < 1
        MOVE 0 TO WS-REF-NEXT(LS-R)
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
            MOVE WS-SYM-HEAD(RF-SYMBOL(LS-R)) TO WS-REF-NEXT(LS-R)
            MOVE LS-R TO WS-SYM-HEAD(RF-SYMBOL(LS-R))
        END-IF
    END-PERFORM.

CHAIN-EDGES.
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE 0 TO WS-UNIT-HEAD(LS-U) WS-UNIT-THRU-HEAD(LS-U)
    END-PERFORM
    PERFORM VARYING LS-E FROM FE-COUNT BY -1 UNTIL LS-E < 1
        MOVE 0 TO WS-EDGE-NEXT(LS-E) WS-EDGE-THRU-NEXT(LS-E)
        IF FE-TO(LS-E) > 0 AND FE-PROC(LS-E) > 0
            MOVE WS-UNIT-HEAD(FE-TO(LS-E)) TO WS-EDGE-NEXT(LS-E)
            MOVE LS-E TO WS-UNIT-HEAD(FE-TO(LS-E))
            MOVE 0 TO LS-U
            IF FE-KIND(LS-E) = "A"
                MOVE FE-ALTERED(LS-E) TO LS-U
            ELSE
                IF FE-THRU(LS-E) NOT = FE-TO(LS-E)
                    MOVE FE-THRU(LS-E) TO LS-U
                END-IF
            END-IF
            IF LS-U > 0
                MOVE WS-UNIT-THRU-HEAD(LS-U) TO WS-EDGE-THRU-NEXT(LS-E)
                MOVE LS-E TO WS-UNIT-THRU-HEAD(LS-U)
            END-IF
        END-IF
    END-PERFORM.

*> Program LS-PROGRAM: its heading, its data items, its procedures.
WRITE-PROGRAM.
    MOVE ND-NAME(LS-PROGRAM) TO LS-T
    PERFORM TOKEN-POSITION
    MOVE LS-FILE TO LS-PROGRAM-FILE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-WORD-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    IF LK-FORMAT = "json"
        PERFORM JSON-PROGRAM
    ELSE
        PERFORM TEXT-PROGRAM
    END-IF
    MOVE "Y" TO LK-ANY.

*> The text listing:
*>     XR (src/xr.cob:2)
*>       Data items
*>         05 A (6)
*>             11M 13 13M 16
*>         05 CUST-ID (CUSTREC.cpy:3)
*>       Procedures
*>         P1 paragraph (15)
*>             12P
*> A definition or reference in another file than the program's names
*> the file.
TEXT-PROGRAM.
    IF LK-ANY = "Y"
        DISPLAY " "
    END-IF
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING LS-WORD(1:LS-WORD-LEN) " (" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-POSITION
    STRING ")" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    DISPLAY LS-OUT(1:LS-PTR - 1)
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-NAME-TOKEN(LS-S) > 0
           AND SY-NAME(LS-S) NOT = "FILLER"
            IF LS-FIRST = "Y"
                DISPLAY "  Data items"
                MOVE "N" TO LS-FIRST
            END-IF
            PERFORM TEXT-ITEM
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-PROGRAM(LS-U) = LS-PROGRAM AND FU-KIND(LS-U) NOT = "D"
            IF LS-FIRST = "Y"
                DISPLAY "  Procedures"
                MOVE "N" TO LS-FIRST
            END-IF
            PERFORM TEXT-UNIT
        END-IF
    END-PERFORM.

TEXT-ITEM.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    *> Level numbers have two digits (01 to 49, 66, 77, 88).
    MOVE SY-LEVEL(LS-S) TO LS-LEVEL
    STRING "    " LS-LEVEL(3:2) " " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE SY-NAME-TOKEN(LS-S) TO LS-T
    PERFORM TOKEN-POSITION
    PERFORM APPEND-SHORT-POSITION
    STRING ")" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    DISPLAY LS-OUT(1:LS-PTR - 1)
    PERFORM START-REFERENCES
    MOVE WS-SYM-HEAD(LS-S) TO LS-R
    PERFORM UNTIL LS-R = 0
        MOVE RF-TOKEN(LS-R) TO LS-T
        PERFORM DATA-MARK
        PERFORM TEXT-REFERENCE
        MOVE WS-REF-NEXT(LS-R) TO LS-R
    END-PERFORM
    PERFORM END-REFERENCES.

TEXT-UNIT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    MOVE FU-NAME(LS-U) TO LS-WORD
    IF FU-KIND(LS-U) = "S"
        MOVE "section" TO LS-KIND
    ELSE
        MOVE "paragraph" TO LS-KIND
    END-IF
    STRING "    " DELIMITED BY SIZE
           FU-NAME(LS-U) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
           LS-KIND DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE ND-NAME(FU-NODE(LS-U)) TO LS-T
    PERFORM TOKEN-POSITION
    PERFORM APPEND-SHORT-POSITION
    STRING ")" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    DISPLAY LS-OUT(1:LS-PTR - 1)
    PERFORM START-REFERENCES
    *> The two chains are each in source order; merge them.
    MOVE WS-UNIT-HEAD(LS-U) TO LS-E
    MOVE WS-UNIT-THRU-HEAD(LS-U) TO LS-K
    PERFORM UNTIL LS-E = 0 AND LS-K = 0
        IF LS-K = 0 OR (LS-E > 0 AND LS-E <= LS-K)
            MOVE ND-NAME(FE-PROC(LS-E)) TO LS-T
            IF LS-T = 0
                MOVE ND-TOK-FIRST(FE-PROC(LS-E)) TO LS-T
            END-IF
            PERFORM EDGE-MARK
            PERFORM TEXT-REFERENCE
            MOVE WS-EDGE-NEXT(LS-E) TO LS-E
        ELSE
            MOVE ND-TOK-FIRST(FE-STMT(LS-K)) TO LS-T
            IF FE-KIND(LS-K) = "A"
                MOVE "A" TO LS-MARK
            ELSE
                MOVE "T" TO LS-MARK
            END-IF
            PERFORM TEXT-REFERENCE
            MOVE WS-EDGE-THRU-NEXT(LS-K) TO LS-K
        END-IF
    END-PERFORM
    PERFORM END-REFERENCES.

START-REFERENCES.
    MOVE SPACES TO LS-OUT
    MOVE LS-INDENT TO LS-PTR
    ADD 1 TO LS-PTR
    MOVE 0 TO LS-PREV-FILE LS-PREV-LINE
    MOVE SPACE TO LS-PREV-MARK
    MOVE "N" TO LS-ANY-REF.

*> Reference at token LS-T with mark LS-MARK: LINE or FILE:LINE, then
*> the mark; a repeat of the last one is left out.
TEXT-REFERENCE.
    PERFORM TOKEN-POSITION
    IF LS-FILE = LS-PREV-FILE AND LS-LINE = LS-PREV-LINE
       AND LS-MARK = LS-PREV-MARK
        EXIT PARAGRAPH
    END-IF
    MOVE LS-FILE TO LS-PREV-FILE
    MOVE LS-LINE TO LS-PREV-LINE
    MOVE LS-MARK TO LS-PREV-MARK
    MOVE SPACES TO LS-PIECE
    MOVE 1 TO LS-PIECE-PTR
    PERFORM SHORT-POSITION
    IF LS-MARK NOT = SPACE
        STRING LS-MARK DELIMITED BY SIZE
            INTO LS-PIECE WITH POINTER LS-PIECE-PTR
    END-IF
    COMPUTE LS-PIECE-LEN = LS-PIECE-PTR - 1
    IF LS-ANY-REF = "Y"
       AND LS-PTR + 1 + LS-PIECE-LEN > LS-WIDTH + 1
        DISPLAY LS-OUT(1:LS-PTR - 1)
        PERFORM START-REFERENCES
    END-IF
    IF LS-ANY-REF = "Y"
        STRING " " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    STRING LS-PIECE(1:LS-PIECE-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "Y" TO LS-ANY-REF.

END-REFERENCES.
    IF LS-ANY-REF = "Y"
        DISPLAY LS-OUT(1:LS-PTR - 1)
    END-IF.

*> M when the statement gives the item a value (or may: a CALL BY
*> REFERENCE argument is not marked, since it may only be read).
DATA-MARK.
    IF RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
        MOVE "M" TO LS-MARK
        MOVE "modify" TO LS-HOW
    ELSE
        MOVE SPACE TO LS-MARK
        MOVE "read" TO LS-HOW
    END-IF.

EDGE-MARK.
    EVALUATE FE-KIND(LS-E)
        WHEN "P"
            MOVE "P" TO LS-MARK
            MOVE "perform" TO LS-HOW
        WHEN "G"
            MOVE "G" TO LS-MARK
            MOVE "go-to" TO LS-HOW
        WHEN OTHER
            MOVE "A" TO LS-MARK
            MOVE "alter" TO LS-HOW
    END-EVALUATE.

*> The JSON listing: one object per program, one line per reference.
JSON-PROGRAM.
    IF LK-ANY = "Y"
        DISPLAY "    },"
    END-IF
    DISPLAY "    {"
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING '      "name": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING LS-WORD(1:LS-WORD-LEN) LS-OUT LS-PTR
    STRING ", " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-JSON-POSITION
    STRING "," DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    DISPLAY LS-OUT(1:LS-PTR - 1)
    DISPLAY '      "data": ['
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-NAME-TOKEN(LS-S) > 0
           AND SY-NAME(LS-S) NOT = "FILLER"
            PERFORM JSON-ITEM
        END-IF
    END-PERFORM
    IF LS-FIRST = "N"
        DISPLAY "        }"
    END-IF
    DISPLAY "      ],"
    DISPLAY '      "procedures": ['
    MOVE "Y" TO LS-FIRST
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-PROGRAM(LS-U) = LS-PROGRAM AND FU-KIND(LS-U) NOT = "D"
            PERFORM JSON-UNIT
        END-IF
    END-PERFORM
    IF LS-FIRST = "N"
        DISPLAY "        }"
    END-IF
    DISPLAY "      ]".

JSON-ITEM.
    IF LS-FIRST = "N"
        DISPLAY "        },"
    END-IF
    MOVE "N" TO LS-FIRST
    DISPLAY "        {"
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING '          "name": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING SY-NAME(LS-S) LS-OUT LS-PTR
    STRING ', "level": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE SY-LEVEL(LS-S) TO LS-NUM
    PERFORM APPEND-NUMBER
    STRING ", " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE SY-NAME-TOKEN(LS-S) TO LS-T
    PERFORM TOKEN-POSITION
    PERFORM APPEND-JSON-POSITION
    STRING "," DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    DISPLAY LS-OUT(1:LS-PTR - 1)
    MOVE "N" TO LS-ANY-REF
    MOVE WS-SYM-HEAD(LS-S) TO LS-R
    IF LS-R = 0
        DISPLAY '          "references": []'
    ELSE
        DISPLAY '          "references": ['
    END-IF
    PERFORM UNTIL LS-R = 0
        MOVE RF-TOKEN(LS-R) TO LS-T
        PERFORM DATA-MARK
        MOVE WS-REF-NEXT(LS-R) TO LS-K
        PERFORM JSON-REFERENCE
        MOVE LS-K TO LS-R
    END-PERFORM
    IF WS-SYM-HEAD(LS-S) > 0
        DISPLAY "          ]"
    END-IF.

JSON-UNIT.
    IF LS-FIRST = "N"
        DISPLAY "        },"
    END-IF
    MOVE "N" TO LS-FIRST
    DISPLAY "        {"
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING '          "name": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING FU-NAME(LS-U) LS-OUT LS-PTR
    IF FU-KIND(LS-U) = "S"
        STRING ', "kind": "section", ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING ', "kind": "paragraph", ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE ND-NAME(FU-NODE(LS-U)) TO LS-T
    PERFORM TOKEN-POSITION
    PERFORM APPEND-JSON-POSITION
    STRING "," DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    DISPLAY LS-OUT(1:LS-PTR - 1)
    IF WS-UNIT-HEAD(LS-U) = 0 AND WS-UNIT-THRU-HEAD(LS-U) = 0
        DISPLAY '          "references": []'
        EXIT PARAGRAPH
    END-IF
    DISPLAY '          "references": ['
    MOVE "N" TO LS-ANY-REF
    MOVE WS-UNIT-HEAD(LS-U) TO LS-E
    MOVE WS-UNIT-THRU-HEAD(LS-U) TO LS-R
    PERFORM UNTIL LS-E = 0 AND LS-R = 0
        IF LS-R = 0 OR (LS-E > 0 AND LS-E <= LS-R)
            MOVE ND-NAME(FE-PROC(LS-E)) TO LS-T
            IF LS-T = 0
                MOVE ND-TOK-FIRST(FE-PROC(LS-E)) TO LS-T
            END-IF
            PERFORM EDGE-MARK
            MOVE WS-EDGE-NEXT(LS-E) TO LS-E
        ELSE
            MOVE ND-TOK-FIRST(FE-STMT(LS-R)) TO LS-T
            IF FE-KIND(LS-R) = "A"
                MOVE "alter" TO LS-HOW
            ELSE
                MOVE "thru" TO LS-HOW
            END-IF
            MOVE WS-EDGE-THRU-NEXT(LS-R) TO LS-R
        END-IF
        IF LS-E = 0 AND LS-R = 0
            MOVE 0 TO LS-K
        ELSE
            MOVE 1 TO LS-K
        END-IF
        PERFORM JSON-REFERENCE
    END-PERFORM
    DISPLAY "          ]".

*> {"file": ..., "line": ..., "column": ..., "use": LS-HOW}, with a
*> comma unless LS-K = 0 (the last).
JSON-REFERENCE.
    PERFORM TOKEN-POSITION
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING "            {" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-JSON-POSITION
    STRING ', "column": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-COLUMN TO LS-NUM
    PERFORM APPEND-NUMBER
    STRING ', "use": "' DELIMITED BY SIZE
           LS-HOW DELIMITED BY SPACE
           '"}' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    IF LS-K NOT = 0
        STRING "," DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    DISPLAY LS-OUT(1:LS-PTR - 1).

*> File, line, and column of token LS-T (0 when it has no source
*> line).
TOKEN-POSITION.
    MOVE 0 TO LS-FILE LS-LINE LS-COLUMN
    IF LS-T = 0 OR LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    MOVE TK-SRC-LINE(LS-T) TO LS-LINE
    IF LS-LINE = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SL-FILE-ID(LS-LINE) TO LS-FILE
    MOVE SL-LINE-NO(LS-LINE) TO LS-LINE
    MOVE TK-COLUMN(LS-T) TO LS-COLUMN.

*> PATH:LINE of the last TOKEN-POSITION.
APPEND-POSITION.
    IF LS-FILE = 0
        STRING "?" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-STR-LENGTH" USING SF-PATH(LS-FILE) LS-PATH-LEN
    STRING SF-PATH(LS-FILE)(1:LS-PATH-LEN) ":" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-LINE TO LS-NUM
    PERFORM APPEND-NUMBER.

*> LINE, or FILE:LINE when the last TOKEN-POSITION is in another file
*> than the program's, added to LS-OUT.
APPEND-SHORT-POSITION.
    MOVE SPACES TO LS-PIECE
    MOVE 1 TO LS-PIECE-PTR
    PERFORM SHORT-POSITION
    STRING LS-PIECE(1:LS-PIECE-PTR - 1) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

*> The same, added to LS-PIECE.
SHORT-POSITION.
    IF LS-FILE NOT = LS-PROGRAM-FILE AND LS-FILE > 0
        PERFORM BASE-NAME
        STRING SF-PATH(LS-FILE)(LS-BASE:LS-PATH-LEN - LS-BASE + 1)
               ":" DELIMITED BY SIZE
            INTO LS-PIECE WITH POINTER LS-PIECE-PTR
    END-IF
    MOVE LS-LINE TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-PIECE WITH POINTER LS-PIECE-PTR.

*> "file": PATH, "line": LINE of the last TOKEN-POSITION.
APPEND-JSON-POSITION.
    STRING '"file": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    IF LS-FILE = 0
        STRING "null" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        CALL "PLB-JSON-STRING" USING SF-PATH(LS-FILE) LS-OUT LS-PTR
    END-IF
    STRING ', "line": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-LINE TO LS-NUM
    PERFORM APPEND-NUMBER.

APPEND-NUMBER.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

*> LS-BASE: where the last component of the path of LS-FILE starts;
*> LS-PATH-LEN: its length.
BASE-NAME.
    CALL "PLB-STR-LENGTH" USING SF-PATH(LS-FILE) LS-PATH-LEN
    MOVE 1 TO LS-BASE
    PERFORM VARYING LS-B FROM LS-PATH-LEN BY -1 UNTIL LS-B < 1
        IF SF-PATH(LS-FILE)(LS-B:1) = "/"
            COMPUTE LS-BASE = LS-B + 1
            EXIT PERFORM
        END-IF
    END-PERFORM.

END PROGRAM PLB-XREF-FILE.
