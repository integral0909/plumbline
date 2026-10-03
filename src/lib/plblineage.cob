*> ---------------------------------------------------------------
*> plblineage: where a data item's value comes from, or where it
*> goes (plumbline lineage).
*>
*> Backward, from an item: each statement that gives it a value (or
*> gives one to a group it is in, or to an item in it), with the items
*> that statement reads, and for each of those, the statements that
*> give them their values, and so on, to the depth asked for. A record
*> of a file is also given its value by each READ (or RETURN) of the
*> file. Forward, the same the other way: the statements that read the
*> item, and the items they give values to.
*>
*>     WS-TOTAL  src/rpt.cob:12
*>       ADD WS-AMOUNT TO WS-TOTAL  (line 40)
*>         WS-AMOUNT  src/rpt.cob:10
*>           MOVE IN-AMT TO WS-AMOUNT  (line 33)
*>             IN-AMT  src/rpt.cob:5
*>               READ IN-FILE  (line 30)
*>
*> An item shown before is not expanded again ("see above"). The
*> statements of one program only are followed; where the trail leaves
*> it through a CALL, the run's call graph names the other side:
*>
*>     LK-AMOUNT  src/calc.cob:8
*>       <- argument 1 of CALL "CALC" in BILLING  src/billing.cob:42:
*>          WS-TOTAL
*>     ...
*>       CALL "CALC" USING WS-TOTAL  (line 42)
*>         -> parameter 1 of CALC: LK-AMOUNT
*>
*> An item of the LINKAGE SECTION gets its value from the arguments of
*> the calls to its program; an item passed in a CALL becomes the
*> parameter of the program called. Run lineage again on the other
*> program's item to follow it there.
*>
*> As JSON, the tree is a list of nodes, each with its id and its
*> parent's (0 for the item asked about):
*>     {"lineage": [
*>       {"id": 1, "parent": 0, "kind": "item", "name": "WS-TOTAL",
*>        "file": "src/rpt.cob", "line": 12, "seen": false},
*>       {"id": 2, "parent": 1, "kind": "statement",
*>        "text": "ADD WS-AMOUNT TO WS-TOTAL", "file": ..., "line": 40},
*>       ...]}
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LINEAGE-FILE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
*> A link to another program, as text.
01  WS-LINK                 PIC X(512).
01  WS-LINK-PTR             PIC 9(9) COMP-5.
*> "Y" for an item already expanded.
01  WS-SEEN                 PIC X OCCURS 100000 TIMES.
*> The work stack: an item (I) or a statement (S), its depth, and for
*> a statement the item it was reached from.
78  WS-STACK-MAX                VALUE 5000.
01  WS-STACK-COUNT          PIC 9(9) COMP-5.
01  WS-STACK                OCCURS WS-STACK-MAX TIMES.
    05  WS-ST-KIND          PIC X.
    05  WS-ST-ID            PIC 9(9) COMP-5.
    05  WS-ST-DEPTH         PIC 9(9) COMP-5.
    05  WS-ST-FROM          PIC 9(9) COMP-5.
    05  WS-ST-PARENT        PIC 9(9) COMP-5.
*> The id of the last node, and the JSON line of the last node, kept
*> until the next one tells whether a comma follows it.
01  WS-NODE-ID              PIC 9(9) COMP-5.
01  WS-ANY-NODE             PIC X VALUE "N".
01  WS-PENDING              PIC X(1024) VALUE SPACES.
01  WS-PENDING-LEN          PIC 9(9) COMP-5 VALUE 0.
*> The statements or items found for the node being expanded, in
*> source order, before they go on the stack (in reverse).
78  WS-FOUND-MAX                VALUE 2000.
01  WS-FOUND-COUNT          PIC 9(9) COMP-5.
01  WS-FOUND                PIC 9(9) COMP-5 OCCURS WS-FOUND-MAX TIMES.
01  WS-LINE                 PIC X(1024).
01  WS-PATH                 PIC X(512).
01  WS-TEXT-LINE            PIC X(1024).
LOCAL-STORAGE SECTION.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-ITEM                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC 9(9) COMP-5.
01  LS-RELATED              PIC X.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(64).
01  LS-FD                   PIC 9(9) COMP-5.
01  LS-FILE-NAME            PIC X(31).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-WANT                 PIC X(31).
01  LS-PARENT               PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-ARG                  PIC 9(9) COMP-5.
01  LS-ROOT-ITEM            PIC 9(9) COMP-5.
01  LS-PROGRAM-NAME         PIC X(31).
01  LS-PROGRAM-FILE         PIC 9(4) COMP-5.
01  LS-STMT-FILE            PIC 9(4) COMP-5.
01  LS-STMT-LINE            PIC 9(9) COMP-5.
*> The node of the item or statement shown: the parent of what is
*> below it.
01  LS-OWN-NODE             PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbcall.cpy".
*> The item's name, how deep to go, B (backward) or F (forward), and
*> FOUND, set to "Y" when the file has an item of that name.
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-DEPTH                PIC 9(9) COMP-5.
01  LK-DIRECTION            PIC X.
01  LK-FOUND                PIC X.
*> "json" for JSON nodes. ACTION is B to start the output (the JSON
*> brackets), F for the file just analyzed, and E to end it.
01  LK-FORMAT               PIC X(5).
01  LK-ACTION               PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-CALL-GRAPH LK-NAME LK-DEPTH LK-DIRECTION LK-FOUND
        LK-FORMAT LK-ACTION.
    EVALUATE LK-ACTION
        WHEN "B"
            MOVE 0 TO WS-NODE-ID
            MOVE "N" TO WS-ANY-NODE
            IF LK-FORMAT = "json"
                DISPLAY "{"
                DISPLAY '  "lineage": ['
            END-IF
            GOBACK
        WHEN "E"
            IF LK-FORMAT = "json"
                IF WS-ANY-NODE = "Y"
                    DISPLAY WS-PENDING(1:WS-PENDING-LEN)
                END-IF
                DISPLAY "  ]"
                DISPLAY "}"
            END-IF
            GOBACK
    END-EVALUATE
    MOVE FUNCTION UPPER-CASE(LK-NAME) TO LS-WANT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME(LS-S) = LS-WANT AND SY-NAME-TOKEN(LS-S) > 0
            IF LK-FOUND = "Y" AND LK-FORMAT NOT = "json"
                DISPLAY " "
            END-IF
            MOVE "Y" TO LK-FOUND
            PERFORM TRACE-ITEM
        END-IF
    END-PERFORM
    GOBACK.

*> The tree of item LS-S, from an empty stack.
TRACE-ITEM.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > SY-COUNT
        MOVE "N" TO WS-SEEN(LS-I)
    END-PERFORM
    MOVE 1 TO WS-STACK-COUNT
    MOVE "I" TO WS-ST-KIND(1)
    MOVE LS-S TO WS-ST-ID(1)
    MOVE 0 TO WS-ST-DEPTH(1) WS-ST-FROM(1) WS-ST-PARENT(1)
    PERFORM UNTIL WS-STACK-COUNT = 0
        MOVE WS-ST-DEPTH(WS-STACK-COUNT) TO LS-DEPTH
        MOVE WS-ST-PARENT(WS-STACK-COUNT) TO LS-PARENT
        IF WS-ST-KIND(WS-STACK-COUNT) = "I"
            MOVE WS-ST-ID(WS-STACK-COUNT) TO LS-ITEM
            SUBTRACT 1 FROM WS-STACK-COUNT
            PERFORM SHOW-ITEM
        ELSE
            MOVE WS-ST-ID(WS-STACK-COUNT) TO LS-STMT
            MOVE WS-ST-FROM(WS-STACK-COUNT) TO LS-ITEM
            SUBTRACT 1 FROM WS-STACK-COUNT
            PERFORM SHOW-STATEMENT
        END-IF
    END-PERFORM.

*> Item LS-ITEM at depth LS-DEPTH: its line, then its statements on
*> the stack, unless it was shown before or the depth is reached.
SHOW-ITEM.
    IF LK-FORMAT = "json"
        PERFORM JSON-ITEM
    ELSE
        PERFORM TEXT-ITEM
    END-IF
    MOVE WS-NODE-ID TO LS-OWN-NODE
    IF WS-SEEN(LS-ITEM) = "Y" OR LS-DEPTH >= LK-DEPTH * 2
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO WS-SEEN(LS-ITEM)
    IF LK-DIRECTION = "B" AND SY-SECTION(LS-ITEM) = "K"
        PERFORM CALLER-LINKS
    END-IF
    PERFORM ITEM-STATEMENTS
    PERFORM VARYING LS-I FROM WS-FOUND-COUNT BY -1 UNTIL LS-I < 1
        IF WS-STACK-COUNT < WS-STACK-MAX
            ADD 1 TO WS-STACK-COUNT
            MOVE "S" TO WS-ST-KIND(WS-STACK-COUNT)
            MOVE WS-FOUND(LS-I) TO WS-ST-ID(WS-STACK-COUNT)
            COMPUTE WS-ST-DEPTH(WS-STACK-COUNT) = LS-DEPTH + 1
            MOVE LS-ITEM TO WS-ST-FROM(WS-STACK-COUNT)
            MOVE LS-OWN-NODE TO WS-ST-PARENT(WS-STACK-COUNT)
        END-IF
    END-PERFORM.

*> The item's line: NAME  PATH:LINE, and "(see above)" when shown
*> before. An item is seen only once expanded: one cut off by the
*> depth may be expanded where it comes again, higher up.
TEXT-ITEM.
    MOVE SPACES TO WS-LINE
    COMPUTE LS-PTR = LS-DEPTH * 2 + 1
    STRING SY-NAME(LS-ITEM) DELIMITED BY SPACE
           "  " DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE SY-NAME-TOKEN(LS-ITEM) TO LS-T
    PERFORM APPEND-POSITION
    IF WS-SEEN(LS-ITEM) = "Y"
        STRING "  (see above)" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    DISPLAY WS-LINE(1:LS-PTR - 1).

JSON-ITEM.
    PERFORM START-NODE
    STRING '"kind": "item", "name": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING SY-NAME(LS-ITEM) WS-LINE LS-PTR
    MOVE SY-NAME-TOKEN(LS-ITEM) TO LS-T
    PERFORM APPEND-JSON-POSITION
    IF WS-SEEN(LS-ITEM) = "Y"
        STRING ', "seen": true}' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING ', "seen": false}' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    PERFORM END-NODE.

*> A new node: the comma that ends the one before is written with it,
*> so the last has none (PLB-LINEAGE-END writes it).
START-NODE.
    IF WS-ANY-NODE = "Y"
        DISPLAY WS-PENDING(1:WS-PENDING-LEN) ","
    END-IF
    MOVE "Y" TO WS-ANY-NODE
    ADD 1 TO WS-NODE-ID
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '    {"id": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE WS-NODE-ID TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "parent": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE LS-PARENT TO LS-NUM
    PERFORM APPEND-NUM
    STRING ", " DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR.

END-NODE.
    MOVE WS-LINE TO WS-PENDING
    COMPUTE WS-PENDING-LEN = LS-PTR - 1.

*> , "file": PATH, "line": LINE of token LS-T.
APPEND-JSON-POSITION.
    STRING ', "file": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE SPACES TO WS-PATH
    MOVE 0 TO LS-NUM
    IF LS-T > 0
        IF TK-SRC-LINE(LS-T) > 0
            CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET
                SL-FILE-ID(TK-SRC-LINE(LS-T)) WS-PATH
            MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO LS-NUM
        END-IF
    END-IF
    CALL "PLB-JSON-STRING" USING WS-PATH WS-LINE LS-PTR
    STRING ', "line": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM APPEND-NUM.

*> WS-FOUND: the statements that give LS-ITEM a value (backward) or
*> read it (forward), in source order, each once.
ITEM-STATEMENTS.
    MOVE 0 TO WS-FOUND-COUNT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
           AND RF-STMT(LS-R) > 0
            PERFORM TEST-RELATED
            IF LS-RELATED = "Y"
                PERFORM TEST-ROLE
                IF LS-RELATED = "Y"
                    MOVE RF-STMT(LS-R) TO LS-N
                    PERFORM ADD-FOUND
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF LK-DIRECTION = "B"
        PERFORM READS-OF-RECORD
    END-IF
    PERFORM SORT-FOUND.

*> LS-RELATED = "Y" when reference LS-R names LS-ITEM, a group it is
*> in, or an item in it.
TEST-RELATED.
    MOVE "N" TO LS-RELATED
    MOVE LS-ITEM TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF RF-SYMBOL(LS-R) = LS-UP
            MOVE "Y" TO LS-RELATED
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    MOVE RF-SYMBOL(LS-R) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF LS-UP = LS-ITEM
            MOVE "Y" TO LS-RELATED
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> Backward, the statement must give the item a value (ADD ... TO it
*> does); forward, read it.
TEST-ROLE.
    IF LK-DIRECTION = "B"
        IF RF-ROLE(LS-R) NOT = "D" AND RF-ROLE(LS-R) NOT = "B"
           AND RF-ROLE(LS-R) NOT = "X"
            MOVE "N" TO LS-RELATED
        END-IF
    ELSE
        *> Not ADD ... TO the item: that adds into it, and takes its
        *> value nowhere else.
        IF RF-ROLE(LS-R) NOT = "U" AND RF-ROLE(LS-R) NOT = "X"
            MOVE "N" TO LS-RELATED
        END-IF
    END-IF.

*> A record of a file's FD (or SD) also gets its value from each READ
*> or RETURN of the file.
READS-OF-RECORD.
    IF SY-SECTION(LS-ITEM) NOT = "F"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-ITEM TO LS-UP
    PERFORM UNTIL SY-PARENT(LS-UP) = 0
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF SY-NODE(LS-UP) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(SY-NODE(LS-UP)) TO LS-FD
    IF LS-FD = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-FD) NOT = "FD" OR ND-NAME(LS-FD) = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-FD) LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-FILE-NAME
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-KIND(LS-N) = "STMT"
           AND (ND-DETAIL(LS-N) = "READ" OR ND-DETAIL(LS-N) = "RETURN")
            COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = LS-FILE-NAME
                PERFORM ADD-FOUND
            END-IF
        END-IF
    END-PERFORM.

ADD-FOUND.
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > WS-FOUND-COUNT
        IF WS-FOUND(LS-Q) = LS-N
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-FOUND-COUNT < WS-FOUND-MAX
        ADD 1 TO WS-FOUND-COUNT
        MOVE LS-N TO WS-FOUND(WS-FOUND-COUNT)
    END-IF.

*> WS-FOUND by first token: source order (an insertion sort; the
*> lists are short).
SORT-FOUND.
    PERFORM VARYING LS-Q FROM 2 BY 1 UNTIL LS-Q > WS-FOUND-COUNT
        MOVE WS-FOUND(LS-Q) TO LS-N
        MOVE LS-Q TO LS-I
        PERFORM UNTIL LS-I < 2
            IF ND-TOK-FIRST(WS-FOUND(LS-I - 1)) <= ND-TOK-FIRST(LS-N)
                EXIT PERFORM
            END-IF
            MOVE WS-FOUND(LS-I - 1) TO WS-FOUND(LS-I)
            SUBTRACT 1 FROM LS-I
        END-PERFORM
        MOVE LS-N TO WS-FOUND(LS-I)
    END-PERFORM.

*> Statement LS-STMT, reached from item LS-ITEM: its text and line,
*> then the items it reads (backward) or gives values to (forward).
SHOW-STATEMENT.
    IF LK-FORMAT = "json"
        PERFORM JSON-STATEMENT
    ELSE
        PERFORM TEXT-STATEMENT
    END-IF
    MOVE WS-NODE-ID TO LS-OWN-NODE
    IF LK-DIRECTION = "F" AND ND-DETAIL(LS-STMT) = "CALL"
        PERFORM CALLEE-LINK
    END-IF
    *> The other items of the statement: what it reads, backward, and
    *> what it gives values to, forward.
    MOVE 0 TO WS-FOUND-COUNT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-STMT(LS-R) = LS-STMT AND RF-KIND(LS-R) = "D"
           AND RF-SYMBOL(LS-R) > 0 AND RF-SYMBOL(LS-R) NOT = LS-ITEM
            PERFORM OTHER-ROLE
            IF LS-RELATED = "Y"
                MOVE RF-SYMBOL(LS-R) TO LS-N
                PERFORM ADD-FOUND
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM WS-FOUND-COUNT BY -1 UNTIL LS-I < 1
        IF WS-STACK-COUNT < WS-STACK-MAX
            ADD 1 TO WS-STACK-COUNT
            MOVE "I" TO WS-ST-KIND(WS-STACK-COUNT)
            MOVE WS-FOUND(LS-I) TO WS-ST-ID(WS-STACK-COUNT)
            COMPUTE WS-ST-DEPTH(WS-STACK-COUNT) = LS-DEPTH + 1
            MOVE 0 TO WS-ST-FROM(WS-STACK-COUNT)
            MOVE LS-OWN-NODE TO WS-ST-PARENT(WS-STACK-COUNT)
        END-IF
    END-PERFORM.

TEXT-STATEMENT.
    MOVE SPACES TO WS-LINE
    COMPUTE LS-PTR = LS-DEPTH * 2 + 1
    PERFORM APPEND-STATEMENT-TEXT
    STRING "  (line " DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE ND-TOK-FIRST(LS-STMT) TO LS-T
    MOVE 0 TO LS-NUM
    IF TK-SRC-LINE(LS-T) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO LS-NUM
    END-IF
    PERFORM APPEND-NUM
    STRING ")" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    DISPLAY WS-LINE(1:LS-PTR - 1).

JSON-STATEMENT.
    *> The text first, in a line of its own, to escape it.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    PERFORM APPEND-STATEMENT-TEXT
    MOVE WS-LINE TO WS-TEXT-LINE
    PERFORM START-NODE
    STRING '"kind": "statement", "text": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING WS-TEXT-LINE WS-LINE LS-PTR
    MOVE ND-TOK-FIRST(LS-STMT) TO LS-T
    PERFORM APPEND-JSON-POSITION
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    PERFORM END-NODE.

*> Backward, the statement's other items it reads; forward, those it
*> gives values to.
OTHER-ROLE.
    MOVE "N" TO LS-RELATED
    IF LK-DIRECTION = "B"
        IF RF-ROLE(LS-R) = "U" OR RF-ROLE(LS-R) = "B"
            MOVE "Y" TO LS-RELATED
        END-IF
    ELSE
        IF RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
           OR RF-ROLE(LS-R) = "X"
            MOVE "Y" TO LS-RELATED
        END-IF
    END-IF.

*> The statement's tokens, one space apart, cut at 72 characters; a
*> statement with a body (IF, EVALUATE, ...) up to the body.
APPEND-STATEMENT-TEXT.
    MOVE ND-TOK-LAST(LS-STMT) TO LS-N
    IF ND-FIRST(LS-STMT) > 0
        IF ND-KIND(ND-FIRST(LS-STMT)) = "BLCK"
            COMPUTE LS-N = ND-TOK-FIRST(ND-FIRST(LS-STMT)) - 1
        END-IF
    END-IF
    MOVE LS-PTR TO LS-Q
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > LS-N
        IF TK-IS-PERIOD(LS-T)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        IF LS-PTR - LS-Q + LS-LEN > 72
            STRING " ..." DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
            EXIT PERFORM
        END-IF
        IF LS-T > ND-TOK-FIRST(LS-STMT) AND NOT TK-IS-RPAREN(LS-T)
           AND NOT TK-IS-COLON(LS-T)
            IF LS-T > 1
                IF NOT TK-IS-LPAREN(LS-T - 1) AND NOT TK-IS-COLON(LS-T - 1)
                    STRING " " DELIMITED BY SIZE
                        INTO WS-LINE WITH POINTER LS-PTR
                END-IF
            END-IF
        END-IF
        IF LS-LEN > 0
            STRING LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        END-IF
    END-PERFORM.

*> PATH:LINE of token LS-T.
APPEND-POSITION.
    IF LS-T = 0 OR TK-SRC-LINE(LS-T) = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET
        SL-FILE-ID(TK-SRC-LINE(LS-T)) WS-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH LS-LEN
    IF LS-LEN > 0
        STRING WS-PATH(1:LS-LEN) ":" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO LS-NUM
    PERFORM APPEND-NUM.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR.

*> The calls that pass the value of LINKAGE item LS-ITEM: for the
*> parameter its record is, each call to its program and the argument
*> in that place.
CALLER-LINKS.
    MOVE LS-ITEM TO LS-ROOT-ITEM
    PERFORM UNTIL SY-PARENT(LS-ROOT-ITEM) = 0
        MOVE SY-PARENT(LS-ROOT-ITEM) TO LS-ROOT-ITEM
    END-PERFORM
    PERFORM PROGRAM-OF-ITEM
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-ARG
    PERFORM VARYING LS-A FROM 1 BY 1 UNTIL LS-A > CP-PARAM-COUNT(LS-P)
        IF CA-NAME(CP-PARAM-FIRST(LS-P) + LS-A - 1)
           = SY-NAME(LS-ROOT-ITEM)
            MOVE LS-A TO LS-ARG
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-ARG = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        IF CC-TO(LS-C) > 0 AND CC-ARG-COUNT(LS-C) >= LS-ARG
            IF CP-OWNER(CC-TO(LS-C)) = LS-P
                PERFORM CALLER-LINK
            END-IF
        END-IF
    END-PERFORM.

*> LS-P: the program of the call graph that LS-ITEM's program is, by
*> name and file; 0 when it is not there.
PROGRAM-OF-ITEM.
    MOVE 0 TO LS-P
    IF SY-PROGRAM(LS-ITEM) = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-NAME(SY-PROGRAM(LS-ITEM)) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-NAME(SY-PROGRAM(LS-ITEM)) TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-PROGRAM-NAME
    MOVE 0 TO LS-PROGRAM-FILE
    IF TK-SRC-LINE(LS-T) > 0
        MOVE SL-FILE-ID(TK-SRC-LINE(LS-T)) TO LS-PROGRAM-FILE
    END-IF
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > CP-COUNT
        IF CP-KIND(LS-Q) = "P" AND CP-NAME(LS-Q) = LS-PROGRAM-NAME
           AND CP-FILE-ID(LS-Q) = LS-PROGRAM-FILE
            MOVE LS-Q TO LS-P
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> <- argument N of CALL "TARGET" in CALLER  PATH:LINE: ARGUMENT
CALLER-LINK.
    MOVE SPACES TO WS-LINK
    MOVE 1 TO WS-LINK-PTR
    MOVE LS-ARG TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET CC-FILE-ID(LS-C)
        WS-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH LS-LEN
    STRING "<- argument " LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ' of CALL "' DELIMITED BY SIZE
           CC-SPELLING(LS-C) DELIMITED BY SPACE
           '" in ' DELIMITED BY SIZE
           CP-NAME(CC-FROM(LS-C)) DELIMITED BY SPACE
           "  " DELIMITED BY SIZE
        INTO WS-LINK WITH POINTER WS-LINK-PTR
    IF LS-LEN > 0
        STRING WS-PATH(1:LS-LEN) ":" DELIMITED BY SIZE
            INTO WS-LINK WITH POINTER WS-LINK-PTR
    END-IF
    MOVE CC-LINE(LS-C) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) ": " DELIMITED BY SIZE
           CG-TEXT(CC-ARG-FIRST(LS-C) + LS-ARG - 1) DELIMITED BY SPACE
        INTO WS-LINK WITH POINTER WS-LINK-PTR
    PERFORM SHOW-LINK.

*> CALL statement LS-STMT passes item LS-ITEM, or a group it is in, or
*> an item in it: the parameter it becomes in the program called.
CALLEE-LINK.
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    IF LS-T > ND-TOK-LAST(LS-STMT) OR TK-SRC-LINE(LS-T) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SL-FILE-ID(TK-SRC-LINE(LS-T)) TO LS-STMT-FILE
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO LS-STMT-LINE
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        IF CC-FILE-ID(LS-C) = LS-STMT-FILE
           AND CC-LINE(LS-C) = LS-STMT-LINE
            PERFORM CALLEE-ARGUMENT
            EXIT PERFORM
        END-IF
    END-PERFORM.

CALLEE-ARGUMENT.
    MOVE 0 TO LS-ARG
    PERFORM VARYING LS-A FROM 1 BY 1 UNTIL LS-A > CC-ARG-COUNT(LS-C)
                                        OR LS-ARG > 0
        MOVE LS-ITEM TO LS-UP
        PERFORM UNTIL LS-UP = 0 OR LS-ARG > 0
            IF CG-TEXT(CC-ARG-FIRST(LS-C) + LS-A - 1) = SY-NAME(LS-UP)
                MOVE LS-A TO LS-ARG
            END-IF
            MOVE SY-PARENT(LS-UP) TO LS-UP
        END-PERFORM
    END-PERFORM
    IF LS-ARG = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO WS-LINK
    MOVE 1 TO WS-LINK-PTR
    MOVE LS-ARG TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    IF CC-TO(LS-C) = 0
        STRING "-> argument " LS-NUM-TEXT(1:LS-NUM-LEN) " of "
               DELIMITED BY SIZE
               CC-SPELLING(LS-C) DELIMITED BY SPACE
               ", which is not in the run" DELIMITED BY SIZE
            INTO WS-LINK WITH POINTER WS-LINK-PTR
    ELSE
        MOVE CP-OWNER(CC-TO(LS-C)) TO LS-P
        STRING "-> parameter " LS-NUM-TEXT(1:LS-NUM-LEN) " of "
               DELIMITED BY SIZE
               CP-NAME(LS-P) DELIMITED BY SPACE
            INTO WS-LINK WITH POINTER WS-LINK-PTR
        IF CP-PARAM-COUNT(CC-TO(LS-C)) >= LS-ARG
            STRING ": " DELIMITED BY SIZE
                   CA-NAME(CP-PARAM-FIRST(CC-TO(LS-C)) + LS-ARG - 1)
                   DELIMITED BY SPACE
                INTO WS-LINK WITH POINTER WS-LINK-PTR
        END-IF
    END-IF
    PERFORM SHOW-LINK.

*> WS-LINK one level below the current node, as a line or a JSON node
*> of kind "call".
SHOW-LINK.
    IF LK-FORMAT = "json"
        MOVE LS-OWN-NODE TO LS-PARENT
        PERFORM START-NODE
        STRING '"kind": "call", "text": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        CALL "PLB-JSON-STRING" USING WS-LINK WS-LINE LS-PTR
        STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
        PERFORM END-NODE
    ELSE
        MOVE SPACES TO WS-LINE
        COMPUTE LS-PTR = (LS-DEPTH + 1) * 2 + 1
        STRING WS-LINK(1:WS-LINK-PTR - 1) DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        DISPLAY WS-LINE(1:LS-PTR - 1)
    END-IF.
END PROGRAM PLB-LINEAGE-FILE.
