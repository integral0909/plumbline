*> ---------------------------------------------------------------
*> plbgraph: graphs of a program and of a set of programs, and what a
*> change reaches.
*>
*>   PLB-GRAPH-INCLUDES-ADD  add the file just preprocessed to the
*>                           include graph (copy/plbigr.cpy)
*>   PLB-GRAPH-PERFORMS      the procedure graph of each program of
*>                           the file just analyzed
*>   PLB-GRAPH-CALLS         the call graph of the run
*>   PLB-GRAPH-INCLUDES      the include graph of the run
*>   PLB-IMPACT              what includes a copybook or calls a
*>                           program, directly or not
*>
*> Graphs are written as Graphviz DOT ("dot") or as JSON ("json"). A
*> graph of several files is one DOT digraph or one JSON object; the
*> caller writes its start and end (PLB-GRAPH-START, PLB-GRAPH-END).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-INCLUDES-ADD.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbigrc.cpy".
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
LINKAGE SECTION.
COPY "plbincl.cpy".
COPY "plbigr.cpy".
PROCEDURE DIVISION USING PLB-INCLUSIONS PLB-INCLUDE-GRAPH.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > IN-COUNT
        MOVE "N" TO LS-FOUND
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > GI-COUNT
            IF GI-FROM(LS-E) = IN-FROM-FILE-ID(LS-I)
               AND GI-TO(LS-E) = IN-FILE-ID(LS-I)
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-PERFORM
        IF LS-FOUND = "N" AND GI-COUNT < GI-MAX
            ADD 1 TO GI-COUNT
            MOVE IN-FROM-FILE-ID(LS-I) TO GI-FROM(GI-COUNT)
            MOVE IN-FILE-ID(LS-I) TO GI-TO(GI-COUNT)
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-GRAPH-INCLUDES-ADD.

*> PLB-GRAPH-START and PLB-GRAPH-END: the frame of a graph in FORMAT,
*> named NAME.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-START.
DATA DIVISION.
LINKAGE SECTION.
01  LK-FORMAT               PIC X(5).
01  LK-NAME                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-FORMAT LK-NAME.
    IF LK-FORMAT = "json"
        DISPLAY "{"
        DISPLAY '  "graph": "' FUNCTION TRIM(LK-NAME) '",'
        DISPLAY '  "items": ['
    ELSE
        DISPLAY "digraph " FUNCTION TRIM(LK-NAME) " {"
        DISPLAY "  node [shape=box];"
    END-IF
    GOBACK.
END PROGRAM PLB-GRAPH-START.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-END.
DATA DIVISION.
LINKAGE SECTION.
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING LK-FORMAT.
    IF LK-FORMAT = "json"
        DISPLAY "  ]"
        DISPLAY "}"
    ELSE
        DISPLAY "}"
    END-IF
    GOBACK.
END PROGRAM PLB-GRAPH-END.

*> PLB-GRAPH-QUOTED: append TEXT (without trailing spaces) to OUT at
*> PTR as a quoted DOT or JSON string.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-QUOTED.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-FORMAT               PIC X(5).
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-OUT                  PIC X ANY LENGTH.
01  LK-PTR                  PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-FORMAT LK-TEXT LK-OUT LK-PTR.
    IF LK-FORMAT = "json"
        CALL "PLB-JSON-STRING" USING LK-TEXT LK-OUT LK-PTR
        GOBACK
    END-IF
    CALL "PLB-STR-LENGTH" USING LK-TEXT LS-LEN
    STRING '"' DELIMITED BY SIZE INTO LK-OUT WITH POINTER LK-PTR
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        IF LK-TEXT(LS-I:1) = '"' OR LK-TEXT(LS-I:1) = "\"
            STRING "\" DELIMITED BY SIZE INTO LK-OUT WITH POINTER LK-PTR
        END-IF
        STRING LK-TEXT(LS-I:1) DELIMITED BY SIZE
            INTO LK-OUT WITH POINTER LK-PTR
    END-PERFORM
    STRING '"' DELIMITED BY SIZE INTO LK-OUT WITH POINTER LK-PTR
    GOBACK.
END PROGRAM PLB-GRAPH-QUOTED.

*> PLB-GRAPH-PERFORMS: for each program of the file, its paragraphs
*> and sections and how control moves between them:
*>     perform   PERFORM (THRU: the range's first unit, labelled)
*>     go        GO TO
*>     alter     the GO TO an ALTER redirects
*>     falls     falling from one unit into the next
*> Units never executed are drawn dashed (DOT) or have "reached":
*> false (JSON). FIRST is "Y" before the first JSON item of the graph.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-PERFORMS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-KIND                 PIC X(8).
01  LS-THRU                 PIC 9(9) COMP-5.
01  LS-PROGRAM-NAME         PIC X(31).
01  LS-ID                   PIC X(64).
01  LS-OUT                  PIC X(512).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-FIRST-ITEM           PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbflow.cpy".
01  LK-FORMAT               PIC X(5).
01  LK-FIRST                PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        LK-FORMAT LK-FIRST.
    MOVE 0 TO LS-PROGRAM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-PROGRAM(LS-U) NOT = LS-PROGRAM
            IF LS-PROGRAM > 0
                PERFORM END-PROGRAM
            END-IF
            MOVE FU-PROGRAM(LS-U) TO LS-PROGRAM
            PERFORM START-PROGRAM
        END-IF
        PERFORM WRITE-NODE
    END-PERFORM
    IF LS-PROGRAM > 0
        PERFORM END-PROGRAM
    END-IF
    GOBACK.

START-PROGRAM.
    MOVE SPACES TO LS-PROGRAM-NAME
    IF ND-NAME(LS-PROGRAM) > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-PROGRAM)
            LS-PROGRAM-NAME LS-LEN
    END-IF
    PERFORM START-OUT
    IF LK-FORMAT = "json"
        IF LK-FIRST = "N"
            DISPLAY "    ,"
        END-IF
        MOVE "N" TO LK-FIRST
        STRING '    {"program": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PROGRAM-NAME LS-OUT
            LS-PTR
        STRING ',' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        PERFORM PRINT-OUT
        DISPLAY '     "nodes": ['
    ELSE
        STRING '  subgraph "cluster_' DELIMITED BY SIZE
               LS-PROGRAM-NAME DELIMITED BY SPACE
               '" {' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        PERFORM PRINT-OUT
        PERFORM START-OUT
        STRING '    label=' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PROGRAM-NAME LS-OUT
            LS-PTR
        STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        PERFORM PRINT-OUT
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM.

*> The edges of the program's units, then the end of its part.
END-PROGRAM.
    IF LK-FORMAT = "json"
        DISPLAY "     ],"
        DISPLAY '     "edges": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        MOVE FE-FROM(LS-E) TO LS-FROM
        IF FU-PROGRAM(LS-FROM) = LS-PROGRAM AND FE-TO(LS-E) > 0
            MOVE FE-TO(LS-E) TO LS-TO
            MOVE 0 TO LS-THRU
            EVALUATE FE-KIND(LS-E)
                WHEN "P"
                    MOVE "perform" TO LS-KIND
                    IF FE-THRU(LS-E) > 0 AND FE-THRU(LS-E) NOT = LS-TO
                        MOVE FE-THRU(LS-E) TO LS-THRU
                    END-IF
                WHEN "G"   MOVE "go" TO LS-KIND
                WHEN "A"
                    MOVE "alter" TO LS-KIND
                    MOVE FE-ALTERED(LS-E) TO LS-FROM
            END-EVALUATE
            IF LS-FROM > 0
                PERFORM WRITE-EDGE
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-PROGRAM(LS-U) = LS-PROGRAM AND FU-FALLS(LS-U) = "Y"
           AND FU-NEXT(LS-U) > 0
            MOVE LS-U TO LS-FROM
            MOVE FU-NEXT(LS-U) TO LS-TO
            MOVE 0 TO LS-THRU
            MOVE "falls" TO LS-KIND
            PERFORM WRITE-EDGE
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY "     ]}"
    ELSE
        DISPLAY "  }"
    END-IF.

WRITE-NODE.
    PERFORM START-OUT
    MOVE LS-U TO LS-TO
    PERFORM NODE-ID
    IF LK-FORMAT = "json"
        IF LS-FIRST-ITEM = "N"
            STRING '       ,' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        ELSE
            STRING '        ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING '{"id": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-ID LS-OUT LS-PTR
        STRING ', "name": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT FU-NAME(LS-U) LS-OUT
            LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        EVALUATE FU-KIND(LS-U)
            WHEN "S"
                STRING 'section"' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "P"
                STRING 'paragraph"' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN OTHER
                STRING 'start"' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
        END-EVALUATE
        STRING ', "line": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO LS-LEN
        MOVE 0 TO LS-NUM
        IF TK-SRC-LINE(LS-LEN) > 0
            MOVE SL-LINE-NO(TK-SRC-LINE(LS-LEN)) TO LS-NUM
        END-IF
        PERFORM APPEND-NUM
        IF FU-REACHED(LS-U) = "Y"
            STRING ', "reached": true}' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        ELSE
            STRING ', "reached": false}' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    ELSE
        STRING '    ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-ID LS-OUT LS-PTR
        STRING ' [label=' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        IF FU-KIND(LS-U) = "D"
            CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT "(start)" LS-OUT
                LS-PTR
        ELSE
            CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT FU-NAME(LS-U) LS-OUT
                LS-PTR
        END-IF
        IF FU-KIND(LS-U) = "S"
            STRING ', shape=box3d' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        IF FU-REACHED(LS-U) NOT = "Y"
            STRING ', style=dashed' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING '];' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM
    PERFORM PRINT-OUT.

*> An edge from LS-FROM to LS-TO of kind LS-KIND.
WRITE-EDGE.
    PERFORM START-OUT
    IF LK-FORMAT = "json"
        IF LS-FIRST-ITEM = "N"
            STRING '       ,' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        ELSE
            STRING '        ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING '{"from": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-TO TO LS-LEN
        MOVE LS-FROM TO LS-TO
        PERFORM NODE-ID
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-ID LS-OUT LS-PTR
        MOVE LS-LEN TO LS-TO
        STRING ', "to": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        PERFORM NODE-ID
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-ID LS-OUT LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        IF LS-THRU > 0
            STRING ', "thru": ' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT FU-NAME(LS-THRU)
                LS-OUT LS-PTR
        END-IF
        STRING '}' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '    ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE LS-TO TO LS-LEN
        MOVE LS-FROM TO LS-TO
        PERFORM NODE-ID
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-ID LS-OUT LS-PTR
        MOVE LS-LEN TO LS-TO
        STRING ' -> ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        PERFORM NODE-ID
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-ID LS-OUT LS-PTR
        EVALUATE LS-KIND
            WHEN "go"
                STRING ' [style=dashed]' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "alter"
                STRING ' [style=dotted, label="ALTER"]' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "falls"
                STRING ' [color=gray]' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
        END-EVALUATE
        IF LS-THRU > 0
            STRING ' [label="thru ' DELIMITED BY SIZE
                   FU-NAME(LS-THRU) DELIMITED BY SPACE
                   '"]' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM
    PERFORM PRINT-OUT.

*> LS-ID = PROGRAM.UNIT for unit LS-TO.
NODE-ID.
    MOVE SPACES TO LS-ID
    IF FU-KIND(LS-TO) = "D"
        STRING LS-PROGRAM-NAME DELIMITED BY SPACE
               ".(start)" DELIMITED BY SIZE
            INTO LS-ID
    ELSE
        STRING LS-PROGRAM-NAME DELIMITED BY SPACE
               "." DELIMITED BY SIZE
               FU-NAME(LS-TO) DELIMITED BY SPACE
            INTO LS-ID
    END-IF.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-GRAPH-PERFORMS.

*> PLB-GRAPH-CALLS: which program calls which, over the whole run. A
*> call that does not resolve to a program of the run goes to a node of
*> its own (dashed in DOT, "external" in JSON); a dynamic call goes to
*> a node named after the data item, in parentheses. Each pair of
*> programs gets one edge however many calls join them.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-CALLS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
LOCAL-STORAGE SECTION.
*> Holds an index taken from another table: GnuCOBOL 3.2 built with
*> -fec=EC-BOUND-SUBSCRIPT miscompiles a subscript nested two deep.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC X(40).
01  LS-TO                   PIC X(40).
01  LS-OTHER-FROM           PIC X(40).
01  LS-OTHER-TO             PIC X(40).
01  LS-KIND                 PIC X(8).
01  LS-OUT                  PIC X(512).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FIRST-ITEM           PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbcall.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-CALL-GRAPH LK-FORMAT.
    IF LK-FORMAT = "json"
        DISPLAY '    {"nodes": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P"
            PERFORM WRITE-PROGRAM-NODE
        END-IF
    END-PERFORM
    *> Targets outside the run.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        IF CC-TO(LS-C) = 0
            PERFORM CALL-ENDS
            PERFORM FIRST-WITH-TARGET
            IF LS-D = LS-C
                PERFORM WRITE-EXTERNAL-NODE
            END-IF
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ],'
        DISPLAY '     "edges": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        PERFORM CALL-ENDS
        PERFORM FIRST-WITH-ENDS
        IF LS-D = LS-C
            PERFORM WRITE-EDGE
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ]}'
    END-IF
    GOBACK.

*> LS-FROM and LS-TO: the names of call LS-C's ends; LS-KIND how it
*> resolved: call, external, or dynamic.
CALL-ENDS.
    MOVE CP-NAME(CC-FROM(LS-C)) TO LS-FROM
    EVALUATE TRUE
        WHEN CC-DYNAMIC(LS-C) = "Y"
            MOVE SPACES TO LS-TO
            STRING "(" DELIMITED BY SIZE
                   CC-TARGET(LS-C) DELIMITED BY SPACE
                   ")" DELIMITED BY SIZE
                INTO LS-TO
            MOVE "dynamic" TO LS-KIND
        WHEN CC-TO(LS-C) > 0
            MOVE CP-OWNER(CC-TO(LS-C)) TO LS-OWNER
            MOVE CP-NAME(LS-OWNER) TO LS-TO
            MOVE "call" TO LS-KIND
        WHEN OTHER
            MOVE CC-TARGET(LS-C) TO LS-TO
            MOVE "external" TO LS-KIND
    END-EVALUATE.

*> LS-D = the first call with the same ends as call LS-C.
FIRST-WITH-ENDS.
    MOVE LS-FROM TO LS-OTHER-FROM
    MOVE LS-TO TO LS-OTHER-TO
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D >= LS-C
        PERFORM CALL-ENDS-OF-D
        IF LS-FROM = LS-OTHER-FROM AND LS-TO = LS-OTHER-TO
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE LS-OTHER-FROM TO LS-FROM
    MOVE LS-OTHER-TO TO LS-TO
    PERFORM CALL-ENDS.

*> LS-D = the first call with the same unresolved target as LS-C.
FIRST-WITH-TARGET.
    MOVE LS-TO TO LS-OTHER-TO
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D >= LS-C
        IF CC-TO(LS-D) = 0
            PERFORM CALL-ENDS-OF-D
            IF LS-TO = LS-OTHER-TO
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    PERFORM CALL-ENDS.

CALL-ENDS-OF-D.
    MOVE LS-C TO LS-P
    MOVE LS-D TO LS-C
    PERFORM CALL-ENDS
    MOVE LS-P TO LS-C.

WRITE-PROGRAM-NODE.
    PERFORM START-OUT
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"id": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT CP-NAME(LS-P) LS-OUT
            LS-PTR
        STRING ', "kind": "program"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT CP-NAME(LS-P) LS-OUT
            LS-PTR
        STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

WRITE-EXTERNAL-NODE.
    PERFORM START-OUT
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"id": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ' [style=dashed];' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

WRITE-EDGE.
    PERFORM START-OUT
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"from": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-FROM LS-OUT LS-PTR
        STRING ', "to": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-FROM LS-OUT LS-PTR
        STRING ' -> ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        IF LS-KIND NOT = "call"
            STRING ' [style=dashed]' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

JSON-SEPARATOR.
    IF LS-FIRST-ITEM = "Y"
        STRING '        ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '       ,' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-GRAPH-CALLS.

*> PLB-GRAPH-INCLUDES: which file includes which copybook, over the
*> whole run. Main files are drawn as boxes, copybooks as notes.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-INCLUDES.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbigrc.cpy".
LOCAL-STORAGE SECTION.
01  LS-F                    PIC 9(4) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-USED                 PIC X.
01  LS-PATH                 PIC X(512).
01  LS-OUT                  PIC X(1200).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FIRST-ITEM           PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbigr.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-INCLUDE-GRAPH LK-FORMAT.
    IF LK-FORMAT = "json"
        DISPLAY '    {"nodes": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > SS-FILE-COUNT
        PERFORM CHECK-USED
        IF LS-USED = "Y"
            PERFORM WRITE-NODE
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ],'
        DISPLAY '     "edges": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > GI-COUNT
        PERFORM WRITE-EDGE
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ]}'
    END-IF
    GOBACK.

*> Main files always appear; copybooks when an edge names them.
CHECK-USED.
    MOVE "N" TO LS-USED
    IF LS-F <= GI-MAIN-FILES
        MOVE "Y" TO LS-USED
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > GI-COUNT
        IF GI-TO(LS-E) = LS-F
            MOVE "Y" TO LS-USED
            EXIT PERFORM
        END-IF
    END-PERFORM.

WRITE-NODE.
    PERFORM START-OUT
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-F LS-PATH
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"id": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PATH LS-OUT LS-PTR
        IF LS-F <= GI-MAIN-FILES
            STRING ', "kind": "program"}' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        ELSE
            STRING ', "kind": "copybook"}' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PATH LS-OUT LS-PTR
        IF LS-F > GI-MAIN-FILES
            STRING ' [shape=note]' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

WRITE-EDGE.
    PERFORM START-OUT
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"from": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET GI-FROM(LS-E)
            LS-PATH
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PATH LS-OUT LS-PTR
        STRING ', "to": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET GI-TO(LS-E) LS-PATH
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PATH LS-OUT LS-PTR
        STRING ', "kind": "include"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET GI-FROM(LS-E)
            LS-PATH
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PATH LS-OUT LS-PTR
        STRING ' -> ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET GI-TO(LS-E) LS-PATH
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-PATH LS-OUT LS-PTR
        STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

JSON-SEPARATOR.
    IF LS-FIRST-ITEM = "Y"
        STRING '        ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '       ,' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-GRAPH-INCLUDES.

*> PLB-IMPACT: what a change to NAME reaches. NAME is a copybook (its
*> file name without directory and extension, or its path as loaded)
*> or a program or ENTRY name; case does not matter. For a copybook,
*> every file that includes it, directly or through other copybooks;
*> for a program, every program that calls it, directly or through
*> other programs, and the JCL steps that run any of them. FOUND is
*> "N" when NAME is neither.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-IMPACT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbigrc.cpy".
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
COPY "plbsrcc.cpy".
*> One entry per file of the source set.
01  WS-FILE-VIA             PIC 9(4) COMP-5 OCCURS SS-MAX-FILES TIMES.
01  WS-FILE-SEEN            PIC X OCCURS SS-MAX-FILES TIMES.
01  WS-FILE-QUEUE           PIC 9(4) COMP-5 OCCURS SS-MAX-FILES TIMES.
01  WS-PROG-VIA             PIC 9(9) COMP-5 OCCURS CP-MAX TIMES.
01  WS-PROG-SEEN            PIC X OCCURS CP-MAX TIMES.
01  WS-PROG-QUEUE           PIC 9(9) COMP-5 OCCURS CP-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-NAME                 PIC X(512).
01  LS-BASE                 PIC X(512).
01  LS-PATH                 PIC X(512).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-SLASH                PIC 9(9) COMP-5.
01  LS-DOT                  PIC 9(9) COMP-5.
01  LS-F                    PIC 9(4) COMP-5.
01  LS-G                    PIC 9(4) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-HEAD                 PIC 9(9) COMP-5.
01  LS-TAIL                 PIC 9(9) COMP-5.
01  LS-OUT                  PIC X(1200).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbcall.cpy".
COPY "plbigr.cpy".
COPY "plbjcl.cpy".
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-FOUND                PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-CALL-GRAPH
        PLB-INCLUDE-GRAPH PLB-JCL LK-NAME LK-FOUND.
    MOVE "N" TO LK-FOUND
    MOVE FUNCTION UPPER-CASE(LK-NAME) TO LS-NAME
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > SS-FILE-COUNT
        IF LS-F > GI-MAIN-FILES
            PERFORM COPYBOOK-NAME
            IF LS-BASE = LS-NAME
                MOVE "Y" TO LK-FOUND
                PERFORM COPYBOOK-IMPACT
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-NAME(LS-P) = LS-NAME
            MOVE "Y" TO LK-FOUND
            PERFORM PROGRAM-IMPACT
        END-IF
    END-PERFORM
    GOBACK.

*> Copybooks -------------------------------------------------------

*> LS-BASE = file LS-F's name without directory or extension,
*> upper-cased; or its whole path when NAME names the whole path.
COPYBOOK-NAME.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-F LS-PATH
    IF FUNCTION UPPER-CASE(LS-PATH) = LS-NAME
        MOVE LS-NAME TO LS-BASE
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
    MOVE 0 TO LS-SLASH LS-DOT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        IF LS-PATH(LS-I:1) = "/"
            MOVE LS-I TO LS-SLASH
            MOVE 0 TO LS-DOT
        END-IF
        IF LS-PATH(LS-I:1) = "."
            MOVE LS-I TO LS-DOT
        END-IF
    END-PERFORM
    IF LS-DOT = 0
        COMPUTE LS-DOT = LS-LEN + 1
    END-IF
    MOVE SPACES TO LS-BASE
    IF LS-DOT > LS-SLASH + 1
        MOVE FUNCTION UPPER-CASE(LS-PATH(LS-SLASH + 1:
                                         LS-DOT - LS-SLASH - 1))
            TO LS-BASE
    END-IF.

COPYBOOK-IMPACT.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-F LS-PATH
    PERFORM START-OUT
    STRING "copybook " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-PATH
    PERFORM PRINT-OUT
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > SS-FILE-COUNT
        MOVE "N" TO WS-FILE-SEEN(LS-G)
        MOVE 0 TO WS-FILE-VIA(LS-G)
    END-PERFORM
    MOVE "Y" TO WS-FILE-SEEN(LS-F)
    MOVE 1 TO LS-HEAD LS-TAIL
    MOVE LS-F TO WS-FILE-QUEUE(1)
    PERFORM UNTIL LS-HEAD > LS-TAIL
        MOVE WS-FILE-QUEUE(LS-HEAD) TO LS-G
        ADD 1 TO LS-HEAD
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > GI-COUNT
            IF GI-TO(LS-E) = LS-G AND WS-FILE-SEEN(GI-FROM(LS-E)) = "N"
                MOVE "Y" TO WS-FILE-SEEN(GI-FROM(LS-E))
                IF LS-G NOT = LS-F
                    MOVE LS-G TO WS-FILE-VIA(GI-FROM(LS-E))
                END-IF
                ADD 1 TO LS-TAIL
                MOVE GI-FROM(LS-E) TO WS-FILE-QUEUE(LS-TAIL)
                MOVE GI-FROM(LS-E) TO LS-T
                PERFORM PRINT-INCLUDER
            END-IF
        END-PERFORM
    END-PERFORM
    IF LS-TAIL = 1
        DISPLAY "  included by no file of the run"
    END-IF.

*>   included by PATH directly | through VIA-PATH
PRINT-INCLUDER.
    PERFORM START-OUT
    STRING "  included by " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-T LS-PATH
    PERFORM APPEND-PATH
    IF WS-FILE-VIA(LS-T) = 0
        STRING " directly" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING " through " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET WS-FILE-VIA(LS-T)
            LS-PATH
        PERFORM APPEND-PATH
    END-IF
    PERFORM PRINT-OUT.

*> Programs --------------------------------------------------------

*> Program or entry LS-P: the programs whose calls can reach it.
PROGRAM-IMPACT.
    PERFORM START-OUT
    IF CP-KIND(LS-P) = "E"
        STRING "entry " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "program " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    STRING CP-NAME(LS-P) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET CP-FILE-ID(LS-P)
        LS-PATH
    PERFORM APPEND-PATH
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE CP-LINE(LS-P) TO LS-NUM
    PERFORM APPEND-NUM
    PERFORM PRINT-OUT
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > CP-COUNT
        MOVE "N" TO WS-PROG-SEEN(LS-Q)
        MOVE 0 TO WS-PROG-VIA(LS-Q)
    END-PERFORM
    MOVE CP-OWNER(LS-P) TO LS-Q
    MOVE "Y" TO WS-PROG-SEEN(LS-Q)
    MOVE 1 TO LS-HEAD LS-TAIL
    MOVE LS-Q TO WS-PROG-QUEUE(1)
    PERFORM UNTIL LS-HEAD > LS-TAIL
        MOVE WS-PROG-QUEUE(LS-HEAD) TO LS-Q
        ADD 1 TO LS-HEAD
        PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
            IF CC-TO(LS-C) > 0
                *> At the start, only calls of LS-P itself (an entry
                *> point has callers of its own); later, of any entry
                *> of the program reached.
                IF LS-HEAD = 2 AND CC-TO(LS-C) = LS-P
                   OR LS-HEAD > 2 AND CP-OWNER(CC-TO(LS-C)) = LS-Q
                    MOVE CC-FROM(LS-C) TO LS-T
                    IF WS-PROG-SEEN(LS-T) = "N"
                        MOVE "Y" TO WS-PROG-SEEN(LS-T)
                        IF LS-HEAD > 2
                            MOVE LS-Q TO WS-PROG-VIA(LS-T)
                        END-IF
                        ADD 1 TO LS-TAIL
                        MOVE LS-T TO WS-PROG-QUEUE(LS-TAIL)
                        PERFORM PRINT-CALLER
                    END-IF
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM
    IF LS-TAIL = 1
        DISPLAY "  called by no program of the run"
    END-IF
    *> The steps that run the program, or a program that calls it.
    PERFORM VARYING LS-HEAD FROM 1 BY 1 UNTIL LS-HEAD > LS-TAIL
        MOVE WS-PROG-QUEUE(LS-HEAD) TO LS-Q
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > JS-COUNT
            IF JS-KIND(LS-E) = "P"
               AND JS-TARGET(LS-E) = CP-NAME(CP-OWNER(LS-Q))
                PERFORM PRINT-STEP
            END-IF
        END-PERFORM
    END-PERFORM.

*>   run by step STEP of job JOB (of proc PROC) at PATH:LINE
*>   [through NAME]
PRINT-STEP.
    PERFORM START-OUT
    STRING "  run by step " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    IF JS-NAME(LS-E) = SPACES
        STRING "-" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING JS-NAME(LS-E) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    EVALUATE TRUE
        WHEN JS-PROC(LS-E) > 0
            STRING " of proc " DELIMITED BY SIZE
                   JP-NAME(JS-PROC(LS-E)) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
        WHEN JS-JOB(LS-E) > 0
            STRING " of job " DELIMITED BY SIZE
                   JJ-NAME(JS-JOB(LS-E)) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
    END-EVALUATE
    STRING " at " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET JS-FILE-ID(LS-E)
        LS-PATH
    PERFORM APPEND-PATH
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE JS-LINE(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    IF LS-HEAD > 1
        STRING " through " DELIMITED BY SIZE
               CP-NAME(CP-OWNER(LS-Q)) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

*>   called by NAME at PATH:LINE directly | through VIA
PRINT-CALLER.
    PERFORM START-OUT
    STRING "  called by " DELIMITED BY SIZE
           CP-NAME(LS-T) DELIMITED BY SPACE
           " at " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET CC-FILE-ID(LS-C)
        LS-PATH
    PERFORM APPEND-PATH
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE CC-LINE(LS-C) TO LS-NUM
    PERFORM APPEND-NUM
    IF WS-PROG-VIA(LS-T) = 0
        STRING " directly" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING " through " DELIMITED BY SIZE
               CP-NAME(WS-PROG-VIA(LS-T)) DELIMITED BY SPACE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

APPEND-PATH.
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
    IF LS-LEN > 0
        STRING LS-PATH(1:LS-LEN) DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-IMPACT.

*> PLB-GRAPH-JOBS: which jobs and procedures run which programs. A
*> job's or procedure's steps are edges labelled with the step name:
*> to the program it runs (EXEC PGM=), or to the procedure (EXEC
*> PROC=). Jobs and procedures are named "NAME (job)" and "NAME
*> (proc)", since a job often has its program's name; programs that
*> are not in the run are drawn dashed (DOT) or have kind "external"
*> (JSON).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-JOBS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(40).
01  LS-FROM                 PIC X(40).
01  LS-TO                   PIC X(40).
01  LS-KIND                 PIC X(8).
01  LS-OUT                  PIC X(512).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FIRST-ITEM           PIC X.
LINKAGE SECTION.
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-CALL-GRAPH PLB-JCL LK-FORMAT.
    IF LK-FORMAT = "json"
        DISPLAY '    {"nodes": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        MOVE SPACES TO LS-NAME
        STRING JJ-NAME(LS-I) DELIMITED BY SPACE
               " (job)" DELIMITED BY SIZE
            INTO LS-NAME
        MOVE "job" TO LS-KIND
        PERFORM WRITE-NODE
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JP-COUNT
        MOVE SPACES TO LS-NAME
        STRING JP-NAME(LS-I) DELIMITED BY SPACE
               " (proc)" DELIMITED BY SIZE
            INTO LS-NAME
        MOVE "proc" TO LS-KIND
        PERFORM WRITE-NODE
    END-PERFORM
    *> Each program a step runs, once.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P"
            PERFORM FIRST-STEP-OF-PROGRAM
            IF LS-K = LS-S
                MOVE JS-TARGET(LS-S) TO LS-NAME
                PERFORM PROGRAM-KIND
                PERFORM WRITE-NODE
            END-IF
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ],'
        DISPLAY '     "edges": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) NOT = SPACE
            PERFORM WRITE-STEP-EDGE
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ]}'
    END-IF
    GOBACK.

*> LS-K = the first step that runs the program step LS-S runs.
FIRST-STEP-OF-PROGRAM.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K >= LS-S
        IF JS-KIND(LS-K) = "P" AND JS-TARGET(LS-K) = JS-TARGET(LS-S)
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-KIND = "program" for a program of the run, else "external".
PROGRAM-KIND.
    MOVE "external" TO LS-KIND
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CP-COUNT
        IF CP-KIND(LS-I) = "P" AND CP-NAME(LS-I) = LS-NAME
            MOVE "program" TO LS-KIND
            EXIT PERFORM
        END-IF
    END-PERFORM.

WRITE-NODE.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"id": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME LS-OUT LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME LS-OUT LS-PTR
        EVALUATE LS-KIND
            WHEN "job"
                STRING ' [shape=folder];' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "proc"
                STRING ' [shape=component];' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "external"
                STRING ' [style=dashed];' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN OTHER
                STRING ';' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
        END-EVALUATE
    END-IF
    PERFORM PRINT-OUT.

*> From the step's job or procedure to its program or procedure.
WRITE-STEP-EDGE.
    MOVE SPACES TO LS-FROM LS-TO
    EVALUATE TRUE
        WHEN JS-PROC(LS-S) > 0
            STRING JP-NAME(JS-PROC(LS-S)) DELIMITED BY SPACE
                   " (proc)" DELIMITED BY SIZE
                INTO LS-FROM
        WHEN JS-JOB(LS-S) > 0
            STRING JJ-NAME(JS-JOB(LS-S)) DELIMITED BY SPACE
                   " (job)" DELIMITED BY SIZE
                INTO LS-FROM
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    IF JS-KIND(LS-S) = "R"
        STRING JS-TARGET(LS-S) DELIMITED BY SPACE
               " (proc)" DELIMITED BY SIZE
            INTO LS-TO
    ELSE
        MOVE JS-TARGET(LS-S) TO LS-TO
    END-IF
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"from": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-FROM LS-OUT LS-PTR
        STRING ', "to": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ', "step": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT JS-NAME(LS-S) LS-OUT
            LS-PTR
        STRING '}' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-FROM LS-OUT LS-PTR
        STRING ' -> ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ' [label=' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT JS-NAME(LS-S) LS-OUT
            LS-PTR
        STRING '];' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

JSON-SEPARATOR.
    IF LS-FIRST-ITEM = "Y"
        STRING '        ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '       ,' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-GRAPH-JOBS.

*> PLB-GRAPH-DATASETS: which job steps read and write which data sets,
*> across the jobs of the run: the data a job leaves for the next.
*>
*> A step is named "JOB.STEP", or "PROC.STEP" for a step of a
*> procedure; a DD that a job step adds to its procedure's step
*> (PSTEP.DDNAME) belongs to the job step. Data sets are named by DSN,
*> without a relative generation, so that DALYREJS(+1) written by one
*> job is DALYREJS read as DALYREJS(0) by the next; a temporary data
*> set (&&NAME) is named with its job, since it ends with the job.
*> Load libraries (STEPLIB, JOBLIB) are not data and are left out.
*>
*> Whether a step reads or writes a data set comes, in this order,
*> from:
*>   1. the OPEN statements of the files that the step's programs (the
*>      program it runs and those it calls) assign to the DD: INPUT
*>      reads, OUTPUT and EXTEND write, I-O updates;
*>   2. the DD names of system utilities: SYSUT1, SORTIN, and SORTINnn
*>      are read, SYSUT2, SORTOUT, and SORTOFxx are written;
*>   3. DISP: SHR reads, NEW and MOD write.
*> What none of these settles (DISP=OLD, or no DISP) is "uses".
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-GRAPH-DATASETS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
78  GD-MAX                      VALUE 5000.
01  WS-DATASETS.
    05  WS-DS-COUNT         PIC 9(9) COMP-5.
    05  WS-DS-NAME          PIC X(60) OCCURS GD-MAX TIMES.
78  GE-MAX                      VALUE 10000.
01  WS-EDGES.
    05  WS-GE-COUNT         PIC 9(9) COMP-5.
    05  WS-GE               OCCURS GE-MAX TIMES.
        10  WS-GE-STEP      PIC 9(9) COMP-5.
        10  WS-GE-DATASET   PIC 9(9) COMP-5.
        10  WS-GE-DD        PIC X(8).
        *>   R read   W write   U update   ? uses
        10  WS-GE-ACCESS    PIC X.
*> The programs a step runs: its program and those it calls.
78  RN-MAX                      VALUE 500.
01  WS-RUNS.
    05  WS-RUN-COUNT        PIC 9(4) COMP-5.
    05  WS-RUN              PIC 9(9) COMP-5 OCCURS RN-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-DS                   PIC 9(9) COMP-5.
01  LS-DSN                  PIC X(60).
01  LS-PAREN                PIC 9(9) COMP-5.
01  LS-READ                 PIC X.
01  LS-WRITE                PIC X.
01  LS-ACCESS               PIC X.
01  LS-FOUND                PIC X.
01  LS-PROGRAM-NAME         PIC X(8).
01  LS-NAME                 PIC X(60).
01  LS-FROM                 PIC X(60).
01  LS-TO                   PIC X(60).
01  LS-KIND                 PIC X(8).
01  LS-OUT                  PIC X(512).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FIRST-ITEM           PIC X.
LINKAGE SECTION.
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-CALL-GRAPH PLB-JCL LK-FORMAT.
    MOVE 0 TO WS-DS-COUNT WS-GE-COUNT
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-KIND(LS-D) = "D" AND JD-NAME(LS-D) NOT = "STEPLIB"
           AND JD-NAME(LS-D) NOT = "JOBLIB" AND JD-STEP(LS-D) > 0
            PERFORM ADD-DD
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '    {"nodes": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-DS FROM 1 BY 1 UNTIL LS-DS > WS-DS-COUNT
        MOVE WS-DS-NAME(LS-DS) TO LS-NAME
        MOVE "dataset" TO LS-KIND
        PERFORM WRITE-NODE
    END-PERFORM
    *> Each step with a data set, once.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > WS-GE-COUNT
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I >= LS-E
            IF WS-GE-STEP(LS-I) = WS-GE-STEP(LS-E)
                EXIT PERFORM
            END-IF
        END-PERFORM
        IF LS-I = LS-E
            MOVE WS-GE-STEP(LS-E) TO LS-S
            PERFORM STEP-NAME
            MOVE "step" TO LS-KIND
            PERFORM WRITE-NODE
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ],'
        DISPLAY '     "edges": ['
    END-IF
    MOVE "Y" TO LS-FIRST-ITEM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > WS-GE-COUNT
        PERFORM WRITE-EDGE
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY '     ]}'
    END-IF
    GOBACK.

*> The edge of DD LS-D: its data set, its step, and the access.
ADD-DD.
    PERFORM DATASET-NAME
    IF LS-DSN = SPACES
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-DATASET
    MOVE JD-STEP(LS-D) TO LS-S
    *> The step whose program opens the DD: for PSTEP.DDNAME on a job
    *> step running a procedure, step PSTEP of the procedure.
    MOVE LS-S TO LS-A
    IF JD-QUALIFIER(LS-D) NOT = SPACES AND JS-KIND(LS-S) = "R"
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
            IF JS-PROC(LS-I) > 0
                IF JP-NAME(JS-PROC(LS-I)) = JS-TARGET(LS-S)
                   AND JS-NAME(LS-I) = JD-QUALIFIER(LS-D)
                    MOVE LS-I TO LS-A
                    EXIT PERFORM
                END-IF
            END-IF
        END-PERFORM
    END-IF
    PERFORM FIND-ACCESS
    *> Once per step, data set, and DD.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > WS-GE-COUNT
        IF WS-GE-STEP(LS-E) = LS-S AND WS-GE-DATASET(LS-E) = LS-DS
           AND WS-GE-DD(LS-E) = JD-NAME(LS-D)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-GE-COUNT < GE-MAX
        ADD 1 TO WS-GE-COUNT
        MOVE LS-S TO WS-GE-STEP(WS-GE-COUNT)
        MOVE LS-DS TO WS-GE-DATASET(WS-GE-COUNT)
        MOVE JD-NAME(LS-D) TO WS-GE-DD(WS-GE-COUNT)
        MOVE LS-ACCESS TO WS-GE-ACCESS(WS-GE-COUNT)
    END-IF.

*> LS-DSN: the DSN of DD LS-D without a relative generation ((+1),
*> (0), (-1)); a member name stays. A temporary data set gets its
*> job's name: "&&TEMP (JOB)".
DATASET-NAME.
    MOVE SPACES TO LS-DSN
    MOVE JD-DSN(LS-D) TO LS-DSN
    MOVE 0 TO LS-PAREN
    INSPECT LS-DSN TALLYING LS-PAREN FOR CHARACTERS BEFORE "("
    IF LS-PAREN < 44
        IF LS-DSN(LS-PAREN + 2:1) = "+" OR "-" OR "0"
            MOVE SPACES TO LS-DSN(LS-PAREN + 1:)
        END-IF
    END-IF
    IF LS-DSN(1:2) = "&&"
        MOVE JD-STEP(LS-D) TO LS-S
        IF JS-JOB(LS-S) > 0
            CALL "PLB-STR-LENGTH" USING LS-DSN LS-LEN
            ADD 1 TO LS-LEN
            STRING " (" DELIMITED BY SIZE
                   JJ-NAME(JS-JOB(LS-S)) DELIMITED BY SPACE
                   ")" DELIMITED BY SIZE
                INTO LS-DSN WITH POINTER LS-LEN
        END-IF
    END-IF.

FIND-DATASET.
    PERFORM VARYING LS-DS FROM 1 BY 1 UNTIL LS-DS > WS-DS-COUNT
        IF WS-DS-NAME(LS-DS) = LS-DSN
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-DS-COUNT < GD-MAX
        ADD 1 TO WS-DS-COUNT
        MOVE LS-DSN TO WS-DS-NAME(WS-DS-COUNT)
        MOVE WS-DS-COUNT TO LS-DS
    ELSE
        MOVE GD-MAX TO LS-DS
    END-IF.

*> LS-ACCESS for DD LS-D opened by the programs of step LS-A.
FIND-ACCESS.
    MOVE "N" TO LS-READ LS-WRITE
    PERFORM PROGRAM-FILES
    IF LS-READ = "N" AND LS-WRITE = "N"
        EVALUATE TRUE
            WHEN JD-NAME(LS-D) = "SYSUT1" OR JD-NAME(LS-D) = "SORTIN"
              OR JD-NAME(LS-D)(1:6) = "SORTIN"
                MOVE "Y" TO LS-READ
            WHEN JD-NAME(LS-D) = "SYSUT2" OR JD-NAME(LS-D) = "SORTOUT"
              OR JD-NAME(LS-D)(1:6) = "SORTOF"
                MOVE "Y" TO LS-WRITE
            WHEN JD-DISP(LS-D) = "SHR"
                MOVE "Y" TO LS-READ
            WHEN JD-DISP(LS-D) = "NEW" OR JD-DISP(LS-D) = "MOD"
                MOVE "Y" TO LS-WRITE
        END-EVALUATE
    END-IF
    EVALUATE TRUE
        WHEN LS-READ = "Y" AND LS-WRITE = "Y"
            MOVE "U" TO LS-ACCESS
        WHEN LS-READ = "Y"
            MOVE "R" TO LS-ACCESS
        WHEN LS-WRITE = "Y"
            MOVE "W" TO LS-ACCESS
        WHEN OTHER
            MOVE "?" TO LS-ACCESS
    END-EVALUATE.

*> LS-READ and LS-WRITE from the open modes of the files that the
*> programs of step LS-A assign to the DD.
PROGRAM-FILES.
    IF JS-KIND(LS-A) NOT = "P"
        EXIT PARAGRAPH
    END-IF
    MOVE JS-TARGET(LS-A) TO LS-PROGRAM-NAME
    IF JS-INNER(LS-A) NOT = SPACES
        MOVE JS-INNER(LS-A) TO LS-PROGRAM-NAME
    END-IF
    MOVE 0 TO LS-P
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CP-COUNT
        IF CP-KIND(LS-I) = "P" AND CP-PARENT(LS-I) = 0
           AND CP-NAME(LS-I) = LS-PROGRAM-NAME
            MOVE LS-I TO LS-P
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM COLLECT-RUNS
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > PF-COUNT
        IF PF-DDNAME(LS-F) = JD-NAME(LS-D) AND PF-SORT(LS-F) = "N"
            PERFORM IS-RUN-PROGRAM
            IF LS-FOUND = "Y"
                IF PF-INPUT(LS-F) = "Y"
                    MOVE "Y" TO LS-READ
                END-IF
                IF PF-OUTPUT(LS-F) = "Y" OR PF-EXTEND(LS-F) = "Y"
                    MOVE "Y" TO LS-WRITE
                END-IF
                IF PF-I-O(LS-F) = "Y"
                    MOVE "Y" TO LS-READ LS-WRITE
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> WS-RUN = LS-P and every program it calls, directly or not, through
*> calls the graph resolved.
COLLECT-RUNS.
    MOVE 1 TO WS-RUN-COUNT
    MOVE LS-P TO WS-RUN(1)
    MOVE 1 TO LS-K
    PERFORM UNTIL LS-K > WS-RUN-COUNT
        PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
            IF CC-TO(LS-C) > 0
                IF CP-OWNER(CC-FROM(LS-C)) = WS-RUN(LS-K)
                    MOVE CP-OWNER(CC-TO(LS-C)) TO LS-J
                    PERFORM ADD-RUN
                END-IF
            END-IF
        END-PERFORM
        ADD 1 TO LS-K
    END-PERFORM.

ADD-RUN.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-RUN-COUNT
        IF WS-RUN(LS-I) = LS-J
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-RUN-COUNT < RN-MAX
        ADD 1 TO WS-RUN-COUNT
        MOVE LS-J TO WS-RUN(WS-RUN-COUNT)
    END-IF.

*> LS-FOUND = "Y" when file LS-F belongs to a program of WS-RUN, or a
*> program nested in one.
IS-RUN-PROGRAM.
    MOVE "N" TO LS-FOUND
    MOVE PF-PROGRAM(LS-F) TO LS-J
    PERFORM UNTIL LS-J = 0
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-RUN-COUNT
            IF WS-RUN(LS-I) = LS-J
                MOVE "Y" TO LS-FOUND
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
        MOVE CP-PARENT(LS-J) TO LS-J
    END-PERFORM.

*> LS-NAME: "JOB.STEP" or "PROC.STEP" for step LS-S.
STEP-NAME.
    MOVE SPACES TO LS-NAME
    EVALUATE TRUE
        WHEN JS-JOB(LS-S) > 0
            STRING JJ-NAME(JS-JOB(LS-S)) DELIMITED BY SPACE
                   "." DELIMITED BY SIZE
                   JS-NAME(LS-S) DELIMITED BY SPACE
                INTO LS-NAME
        WHEN JS-PROC(LS-S) > 0
            STRING JP-NAME(JS-PROC(LS-S)) DELIMITED BY SPACE
                   "." DELIMITED BY SIZE
                   JS-NAME(LS-S) DELIMITED BY SPACE
                INTO LS-NAME
        WHEN OTHER
            MOVE JS-NAME(LS-S) TO LS-NAME
    END-EVALUATE.

WRITE-NODE.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"id": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME LS-OUT LS-PTR
        STRING ', "kind": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-NAME LS-OUT LS-PTR
        IF LS-KIND = "dataset"
            STRING ' [shape=cylinder];' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        ELSE
            STRING ';' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-IF
    PERFORM PRINT-OUT.

*> Reads go from the data set to the step, writes and updates from
*> the step to the data set.
WRITE-EDGE.
    MOVE WS-GE-STEP(LS-E) TO LS-S
    PERFORM STEP-NAME
    MOVE LS-NAME TO LS-FROM
    MOVE WS-DS-NAME(WS-GE-DATASET(LS-E)) TO LS-TO
    IF WS-GE-ACCESS(LS-E) = "R" OR WS-GE-ACCESS(LS-E) = "?"
        MOVE LS-TO TO LS-FROM
        MOVE LS-NAME TO LS-TO
    END-IF
    EVALUATE WS-GE-ACCESS(LS-E)
        WHEN "R" MOVE "read" TO LS-KIND
        WHEN "W" MOVE "write" TO LS-KIND
        WHEN "U" MOVE "update" TO LS-KIND
        WHEN OTHER MOVE "uses" TO LS-KIND
    END-EVALUATE
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    IF LK-FORMAT = "json"
        PERFORM JSON-SEPARATOR
        STRING '{"from": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-FROM LS-OUT LS-PTR
        STRING ', "to": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ', "dd": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT WS-GE-DD(LS-E) LS-OUT
            LS-PTR
        STRING ', "access": "' DELIMITED BY SIZE
               LS-KIND DELIMITED BY SPACE
               '"}' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '  ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-FROM LS-OUT LS-PTR
        STRING ' -> ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT LS-TO LS-OUT LS-PTR
        STRING ' [label=' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-GRAPH-QUOTED" USING LK-FORMAT WS-GE-DD(LS-E) LS-OUT
            LS-PTR
        EVALUATE LS-KIND
            WHEN "update"
                STRING ', dir=both' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "uses"
                STRING ', style=dashed, arrowhead=none' DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
        END-EVALUATE
        STRING '];' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    PERFORM PRINT-OUT.

JSON-SEPARATOR.
    IF LS-FIRST-ITEM = "Y"
        STRING '        ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '       ,' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-GRAPH-DATASETS.

*> PLB-DATA-IMPACT-COLLECT: add the declarations of data items named
*> NAME in the file just analyzed, and every reference to them, to
*> PLB-DATA-USES.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DATA-IMPACT-COLLECT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-NAME                 PIC X(31).
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LEVEL-TEXT           PIC X(20).
01  LS-NUM                  PIC S9(18) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbduse.cpy".
01  LK-NAME                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-DATA-USES LK-NAME.
    MOVE FUNCTION UPPER-CASE(LK-NAME) TO LS-NAME
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME(LS-S) = LS-NAME AND SY-NAME-TOKEN(LS-S) > 0
            MOVE SY-NAME-TOKEN(LS-S) TO LS-T
            MOVE SY-NODE(LS-S) TO LS-NODE
            MOVE SY-LEVEL(LS-S) TO LS-NUM
            CALL "PLB-STR-FROM-INT" USING LS-NUM LS-LEVEL-TEXT LS-LEN
            MOVE SPACES TO LS-LEVEL-TEXT(LS-LEN + 1:)
            PERFORM ADD-USE
            IF DU-COUNT > 0 AND DU-COUNT <= DU-MAX
                MOVE "T" TO DU-ROLE(DU-COUNT)
                MOVE LS-LEVEL-TEXT TO DU-VERB(DU-COUNT)
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" OR RF-KIND(LS-R) = "A"
            IF SY-NAME(RF-SYMBOL(LS-R)) = LS-NAME
                MOVE RF-TOKEN(LS-R) TO LS-T
                MOVE RF-STMT(LS-R) TO LS-NODE
                PERFORM ADD-USE
                IF DU-COUNT > 0 AND DU-COUNT <= DU-MAX
                    MOVE RF-ROLE(LS-R) TO DU-ROLE(DU-COUNT)
                    IF RF-STMT(LS-R) > 0
                        MOVE ND-DETAIL(RF-STMT(LS-R))
                            TO DU-VERB(DU-COUNT)
                    ELSE
                        MOVE SPACES TO DU-VERB(DU-COUNT)
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> An entry for token LS-T in the program that holds node LS-NODE.
ADD-USE.
    IF DU-COUNT >= DU-MAX
        ADD 1 TO DU-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO DU-COUNT
    MOVE SPACES TO DU-PROGRAM(DU-COUNT)
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "PROG"
            IF ND-NAME(LS-NODE) > 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE)
                    DU-PROGRAM(DU-COUNT) LS-LEN
            END-IF
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-NODE) TO LS-NODE
    END-PERFORM
    MOVE TK-FILE-ID(LS-T) TO DU-FILE-ID(DU-COUNT)
    MOVE TK-COLUMN(LS-T) TO DU-COLUMN(DU-COUNT)
    MOVE 0 TO DU-LINE(DU-COUNT)
    IF TK-SRC-LINE(LS-T) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO DU-LINE(DU-COUNT)
    END-IF.
END PROGRAM PLB-DATA-IMPACT-COLLECT.

*> PLB-DATA-IMPACT-PRINT: the declarations and uses that
*> PLB-DATA-IMPACT-COLLECT gathered, under "data item NAME".
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DATA-IMPACT-PRINT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-OUT                  PIC X(1200).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-PATH                 PIC X(1024).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbduse.cpy".
01  LK-NAME                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DATA-USES LK-NAME.
    IF DU-COUNT = 0
        GOBACK
    END-IF
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING "data item " DELIMITED BY SIZE
           FUNCTION UPPER-CASE(LK-NAME) DELIMITED BY SPACE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DU-COUNT
        MOVE SPACES TO LS-OUT
        MOVE 1 TO LS-PTR
        EVALUATE DU-ROLE(LS-I)
            WHEN "T" MOVE "  declared at " TO LS-OUT
            WHEN "U" MOVE "  read at " TO LS-OUT
            WHEN "D" MOVE "  set at " TO LS-OUT
            WHEN "B" MOVE "  read and set at " TO LS-OUT
            WHEN OTHER MOVE "  used at " TO LS-OUT
        END-EVALUATE
        CALL "PLB-STR-LENGTH" USING LS-OUT LS-PTR
        ADD 2 TO LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DU-FILE-ID(LS-I)
            LS-PATH
        CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
        IF LS-LEN > 0
            STRING LS-PATH(1:LS-LEN) DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE DU-LINE(LS-I) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE DU-COLUMN(LS-I) TO LS-NUM
        PERFORM APPEND-NUM
        IF DU-PROGRAM(LS-I) NOT = SPACES
            STRING " in " DELIMITED BY SIZE
                   DU-PROGRAM(LS-I) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        IF DU-VERB(LS-I) NOT = SPACES
            IF DU-ROLE(LS-I) = "T"
                STRING ", level " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            ELSE
                STRING ", " DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            END-IF
            STRING DU-VERB(LS-I) DELIMITED BY SPACE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        PERFORM PRINT-OUT
    END-PERFORM
    IF DU-DROPPED > 0
        DISPLAY "  (more uses than " DU-MAX " were left out)"
    END-IF
    GOBACK.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

PRINT-OUT.
    CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-DATA-IMPACT-PRINT.
