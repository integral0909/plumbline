*> ---------------------------------------------------------------
*> plbpdata: parser for the data division.
*>
*> Sections (FILE, WORKING-STORAGE, LOCAL-STORAGE, LINKAGE, REPORT,
*> SCREEN, COMMUNICATION) become SECT nodes; FD, SD, CD, and RD
*> entries become FD nodes (detail FD, SD, CD, or RD); data description entries become DATA nodes nested by
*> level number:
*>
*>   01, 77       start a new record (under the section, or under
*>                the FD for 01 in the file section)
*>   78           goes under the section, without ending the record
*>                it may appear in
*>   02-49        go under the nearest preceding item with a lower
*>                level number
*>   66           goes under the current record (RENAMES)
*>   88           goes under the item just described
*>
*> Report Writer: the 01 entries of the report section go under their
*> RD, the CONTROL clause of an RD becomes a CLAU node of the RD, and
*> the report clauses of entries (TYPE, LINE, NEXT GROUP, COLUMN,
*> SOURCE, SUM, GROUP INDICATE, PRESENT WHEN) become CLAU nodes that
*> hold their operands. TYPE names the token of its type code.
*>
*> Clauses become CLAU nodes. PICTURE, REDEFINES, and RENAMES name
*> their operand token; OCCURS gets a DEPENDING child when it has one;
*> USAGE (written out or implied by a usage word) records the usage.
*>
*> Diagnostic codes raised here:
*>   PS008  error    malformed data description entry
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-DATA.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  LV-MAX                      VALUE 64.
01  WS-LEVELS.
    05  WS-LEVEL-DEPTH      PIC 9(4) COMP-5.
    05  WS-LEVEL            OCCURS LV-MAX TIMES.
        10  LV-NUMBER       PIC 9(4) COMP-5.
        10  LV-NODE         PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
COPY "plbptok.cpy".
01  LS-HEADER               PIC X(16).
01  LS-SECTION              PIC 9(9) COMP-5.
01  LS-FD                   PIC 9(9) COMP-5.
01  LS-RECORD               PIC 9(9) COMP-5.
01  LS-ENTRY                PIC 9(9) COMP-5.
01  LS-CLAUSE               PIC 9(9) COMP-5.
01  LS-NEXT-IS-GROUP        PIC X.
01  LS-PARENT               PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-LEVEL                PIC 9(4) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-DETAIL               PIC X(16).
01  LS-IN-FILE-SECTION      PIC X VALUE "N".
01  LS-ENTRY-DONE           PIC X.
01  LS-STOP                 PIC X.
01  LS-USAGE-WORD           PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbpst.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-PARSE-STATE.
    MOVE 0 TO LS-SECTION LS-FD LS-RECORD WS-LEVEL-DEPTH
    PERFORM UNTIL PS-POS >= PS-END OR PS-FULL = "Y"
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        IF LS-HEADER NOT = SPACES
            EXIT PERFORM
        END-IF
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        COMPUTE LS-NEXT = PS-POS + 1
        EVALUATE TRUE
            WHEN PX-KIND = "W" AND TK-IS-WORD(LS-NEXT)
                 AND TK-TEXT(TK-TEXT-OFF(LS-NEXT):TK-TEXT-LEN(LS-NEXT))
                     = "SECTION"
                PERFORM DATA-SECTION
            WHEN PX-TEXT = "FD" OR PX-TEXT = "SD" OR PX-TEXT = "CD"
                 OR PX-TEXT = "RD"
                PERFORM FILE-DESCRIPTION
            WHEN PX-KIND = "N"
                PERFORM DATA-ENTRY
            WHEN PX-TEXT = "EXEC"
                PERFORM EXEC-BLOCK
            WHEN OTHER
                PERFORM BAD-ENTRY
        END-EVALUATE
        PERFORM EXTEND-OPEN-NODES
    END-PERFORM
    GOBACK.

DATA-SECTION.
    MOVE PX-TEXT TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "SECT" LS-DETAIL
        PS-POS LS-SECTION
    PERFORM CHECK-SECTION-NODE
    *> Records of the file and report sections belong to their FD or
    *> RD.
    IF PX-TEXT = "FILE" OR PX-TEXT = "REPORT"
        MOVE "Y" TO LS-IN-FILE-SECTION
    ELSE
        MOVE "N" TO LS-IN-FILE-SECTION
    END-IF
    MOVE 0 TO LS-FD LS-RECORD WS-LEVEL-DEPTH
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE.

CHECK-SECTION-NODE.
    IF LS-SECTION = 0
        MOVE "Y" TO PS-FULL
    END-IF.

*> FD|SD file-name clauses... .  CD cd-name clauses... .
FILE-DESCRIPTION.
    PERFORM SECTION-PARENT
    MOVE PX-TEXT TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "FD  " LS-DETAIL PS-POS
        LS-FD
    IF LS-FD = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PS-POS
    IF TK-IS-WORD(PS-POS)
        MOVE PS-POS TO ND-NAME(LS-FD)
    END-IF
    MOVE 0 TO LS-RECORD WS-LEVEL-DEPTH
    IF ND-DETAIL(LS-FD) = "RD"
        PERFORM REPORT-CONTROLS
    END-IF
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE.

*> RD name [CODE lit] [CONTROL[S] [IS|ARE] [FINAL] name...] [PAGE ...]
*> The CONTROL clause becomes a CLAU node of the RD; it runs to PAGE,
*> CODE, or the period.
REPORT-CONTROLS.
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-KIND = "."
            EXIT PERFORM
        END-IF
        IF PX-TEXT = "CONTROL" OR PX-TEXT = "CONTROLS"
            CALL "PLB-AST-ADD" USING PLB-AST LS-FD "CLAU" "CONTROL"
                PS-POS LS-CLAUSE
            IF LS-CLAUSE = 0
                MOVE "Y" TO PS-FULL
                EXIT PERFORM
            END-IF
            ADD 1 TO PS-POS
            PERFORM UNTIL PS-POS >= PS-END
                CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
                IF PX-KIND = "." OR PX-TEXT = "PAGE" OR PX-TEXT = "CODE"
                    EXIT PERFORM
                END-IF
                ADD 1 TO PS-POS
            END-PERFORM
            COMPUTE ND-TOK-LAST(LS-CLAUSE) = PS-POS - 1
        ELSE
            ADD 1 TO PS-POS
        END-IF
    END-PERFORM.

SECTION-PARENT.
    MOVE PS-DIVISION TO LS-PARENT
    IF LS-SECTION > 0
        MOVE LS-SECTION TO LS-PARENT
    END-IF.

*> level-number [name | FILLER] clauses... .
DATA-ENTRY.
    MOVE FUNCTION NUMVAL(PX-TEXT) TO LS-LEVEL
    EVALUATE TRUE
        WHEN LS-LEVEL = 1 OR LS-LEVEL = 77
            PERFORM SECTION-PARENT
            IF LS-LEVEL = 1 AND LS-IN-FILE-SECTION = "Y" AND LS-FD > 0
                MOVE LS-FD TO LS-PARENT
            END-IF
            MOVE 0 TO WS-LEVEL-DEPTH
        *> A constant. Micro Focus and GnuCOBOL allow it among the
        *> entries of a record (GnuCOBOL's own EXTFH copybook lists the
        *> values of a field right after it), so it goes under the
        *> section and the record goes on after it.
        WHEN LS-LEVEL = 78
            PERFORM SECTION-PARENT
        WHEN LS-LEVEL = 66
            MOVE LS-RECORD TO LS-PARENT
        WHEN LS-LEVEL = 88
            IF WS-LEVEL-DEPTH > 0
                MOVE LV-NODE(WS-LEVEL-DEPTH) TO LS-PARENT
            ELSE
                MOVE 0 TO LS-PARENT
            END-IF
        WHEN LS-LEVEL >= 2 AND LS-LEVEL <= 49
            PERFORM UNTIL WS-LEVEL-DEPTH = 0
                IF LV-NUMBER(WS-LEVEL-DEPTH) < LS-LEVEL
                    EXIT PERFORM
                END-IF
                SUBTRACT 1 FROM WS-LEVEL-DEPTH
            END-PERFORM
            IF WS-LEVEL-DEPTH > 0
                MOVE LV-NODE(WS-LEVEL-DEPTH) TO LS-PARENT
            ELSE
                MOVE 0 TO LS-PARENT
            END-IF
        WHEN OTHER
            CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-TOKENS PS-POS "E" "PS008" "invalid level number"
            PERFORM BAD-ENTRY
            EXIT PARAGRAPH
    END-EVALUATE
    IF LS-PARENT = 0
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS008"
            "level number has no item to belong to"
        PERFORM SECTION-PARENT
    END-IF

    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "DATA" " " PS-POS
        LS-ENTRY
    IF LS-ENTRY = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    MOVE LS-LEVEL TO ND-NUM(LS-ENTRY)
    IF LS-LEVEL = 1 OR LS-LEVEL = 77
        MOVE LS-ENTRY TO LS-RECORD
    END-IF
    IF LS-LEVEL NOT = 66 AND LS-LEVEL NOT = 88 AND LS-LEVEL NOT = 78
       AND WS-LEVEL-DEPTH < LV-MAX
        ADD 1 TO WS-LEVEL-DEPTH
        MOVE LS-LEVEL TO LV-NUMBER(WS-LEVEL-DEPTH)
        MOVE LS-ENTRY TO LV-NODE(WS-LEVEL-DEPTH)
    END-IF

    ADD 1 TO PS-POS
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    EVALUATE TRUE
        WHEN PX-TEXT = "FILLER"
            MOVE "FILLER" TO ND-DETAIL(LS-ENTRY)
            ADD 1 TO PS-POS
        WHEN PX-KIND = "W" AND PX-KW = SPACE
            MOVE PS-POS TO ND-NAME(LS-ENTRY)
            ADD 1 TO PS-POS
    END-EVALUATE

    MOVE "N" TO LS-ENTRY-DONE
    PERFORM UNTIL LS-ENTRY-DONE = "Y" OR PS-POS >= PS-END
        PERFORM ENTRY-CLAUSE
    END-PERFORM
    COMPUTE ND-TOK-LAST(LS-ENTRY) = PS-POS - 1.

*> Parse one clause at PS-POS, or end the entry.
ENTRY-CLAUSE.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PX-KIND = "."
        ADD 1 TO PS-POS
        MOVE "Y" TO LS-ENTRY-DONE
        EXIT PARAGRAPH
    END-IF
    *> A level number where a clause should be: the entry before it
    *> lacks its period. A level number starts its line; other numbers
    *> are operands of clauses Plumbline does not model, such as the
    *> colors of a screen entry.
    IF PX-KIND = "N" AND PS-POS > 1
        IF TK-SRC-LINE(PS-POS) = TK-SRC-LINE(PS-POS - 1)
           AND TK-FILE-ID(PS-POS) = TK-FILE-ID(PS-POS - 1)
            ADD 1 TO PS-POS
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF PX-KIND = "N"
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS008"
            "data description entry must end with a period"
        MOVE "Y" TO LS-ENTRY-DONE
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
    IF LS-HEADER NOT = SPACES
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS008"
            "data description entry must end with a period"
        MOVE "Y" TO LS-ENTRY-DONE
        EXIT PARAGRAPH
    END-IF

    PERFORM CHECK-USAGE-WORD
    PERFORM CHECK-NEXT-GROUP
    EVALUATE TRUE
        WHEN PX-TEXT = "PIC" OR PX-TEXT = "PICTURE"
            MOVE "PICTURE" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-IS
            IF TK-IS-PICTURE(PS-POS)
                MOVE PS-POS TO ND-NAME(LS-CLAUSE)
                ADD 1 TO PS-POS
            END-IF
        WHEN PX-TEXT = "VALUE" OR PX-TEXT = "VALUES"
            MOVE "VALUE" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        *> 01 name CONSTANT [IS GLOBAL] [AS] literal or expression
        *> (COBOL 2014, GnuCOBOL): the entry is a constant.
        WHEN PX-TEXT = "CONSTANT"
            MOVE "CONSTANT" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "REDEFINES" OR PX-TEXT = "RENAMES"
            MOVE PX-TEXT TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            IF TK-IS-WORD(PS-POS)
                MOVE PS-POS TO ND-NAME(LS-CLAUSE)
                ADD 1 TO PS-POS
            END-IF
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "OCCURS"
            MOVE "OCCURS" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM OCCURS-OPERANDS
        WHEN PX-TEXT = "USAGE"
            MOVE "USAGE" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-IS
            CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
            MOVE PX-TEXT TO ND-DETAIL(LS-CLAUSE)
            ADD 1 TO PS-POS
        WHEN LS-USAGE-WORD = "Y"
            MOVE PX-TEXT TO LS-DETAIL
            PERFORM OPEN-CLAUSE
        WHEN PX-TEXT = "SIGN" OR PX-TEXT = "LEADING"
                OR PX-TEXT = "TRAILING"
            MOVE "SIGN" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "JUST" OR PX-TEXT = "JUSTIFIED"
            MOVE "JUSTIFIED" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "SYNC" OR PX-TEXT = "SYNCHRONIZED"
            MOVE "SYNCHRONIZED" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "BLANK"
            MOVE "BLANK-WHEN-ZERO" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "EXTERNAL" OR PX-TEXT = "GLOBAL"
                OR PX-TEXT = "BASED"
            MOVE PX-TEXT TO LS-DETAIL
            PERFORM OPEN-CLAUSE
        *> Report Writer clauses.
        WHEN PX-TEXT = "TYPE"
            MOVE "TYPE" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-IS
            IF LS-CLAUSE > 0 AND TK-IS-WORD(PS-POS)
                MOVE PS-POS TO ND-NAME(LS-CLAUSE)
            END-IF
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "NEXT" AND LS-NEXT-IS-GROUP = "Y"
            MOVE "NEXT-GROUP" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            ADD 1 TO PS-POS
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "GROUP"
            MOVE "GROUP-INDICATE" TO LS-DETAIL
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN PX-TEXT = "LINE" OR PX-TEXT = "COLUMN" OR PX-TEXT = "COL"
                OR PX-TEXT = "SOURCE" OR PX-TEXT = "SUM"
                OR PX-TEXT = "PRESENT"
            MOVE PX-TEXT TO LS-DETAIL
            IF PX-TEXT = "COL"
                MOVE "COLUMN" TO LS-DETAIL
            END-IF
            PERFORM OPEN-CLAUSE
            PERFORM SKIP-OPERANDS
        WHEN OTHER
            *> A clause Plumbline does not model: keep it in the
            *> entry's token range.
            ADD 1 TO PS-POS
            MOVE 0 TO LS-CLAUSE
    END-EVALUATE
    IF LS-CLAUSE > 0
        COMPUTE ND-TOK-LAST(LS-CLAUSE) = PS-POS - 1
    END-IF.

*> Usage words may appear without USAGE IS.
CHECK-USAGE-WORD.
    MOVE "N" TO LS-USAGE-WORD
    IF PX-KIND NOT = "W"
        EXIT PARAGRAPH
    END-IF
    EVALUATE PX-TEXT
        WHEN "BINARY" WHEN "COMP" WHEN "COMPUTATIONAL"
        WHEN "COMP-1" WHEN "COMP-2" WHEN "COMP-3" WHEN "COMP-4"
        WHEN "COMP-5" WHEN "COMP-X" WHEN "COMPUTATIONAL-1"
        WHEN "COMPUTATIONAL-2" WHEN "COMPUTATIONAL-3"
        WHEN "COMPUTATIONAL-4" WHEN "COMPUTATIONAL-5"
        WHEN "COMPUTATIONAL-X" WHEN "DISPLAY" WHEN "NATIONAL"
        WHEN "INDEX" WHEN "POINTER" WHEN "PROCEDURE-POINTER"
        WHEN "PROGRAM-POINTER" WHEN "PACKED-DECIMAL"
        WHEN "BINARY-CHAR" WHEN "BINARY-SHORT" WHEN "BINARY-LONG"
        WHEN "BINARY-DOUBLE" WHEN "FLOAT-SHORT" WHEN "FLOAT-LONG"
        WHEN "OBJECT-REFERENCE"
            MOVE "Y" TO LS-USAGE-WORD
    END-EVALUATE.

*> Start a CLAU node LS-DETAIL at PS-POS and move past its keyword.
OPEN-CLAUSE.
    CALL "PLB-AST-ADD" USING PLB-AST LS-ENTRY "CLAU" LS-DETAIL PS-POS
        LS-CLAUSE
    IF LS-CLAUSE = 0
        MOVE "Y" TO PS-FULL
        MOVE "Y" TO LS-ENTRY-DONE
    END-IF
    ADD 1 TO PS-POS.

SKIP-IS.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PX-TEXT = "IS" OR PX-TEXT = "ARE"
        ADD 1 TO PS-POS
    END-IF.

*> Take tokens up to the period or the next clause keyword.
SKIP-OPERANDS.
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        PERFORM CHECK-CLAUSE-START
        IF LS-STOP = "Y"
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM.

CHECK-CLAUSE-START.
    MOVE "N" TO LS-STOP
    IF PX-KIND = "."
        MOVE "Y" TO LS-STOP
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-USAGE-WORD
    IF LS-USAGE-WORD = "Y"
        MOVE "Y" TO LS-STOP
        EXIT PARAGRAPH
    END-IF
    EVALUATE PX-TEXT
        WHEN "PIC" WHEN "PICTURE" WHEN "VALUE" WHEN "VALUES"
        WHEN "CONSTANT"
        WHEN "REDEFINES" WHEN "OCCURS" WHEN "USAGE" WHEN "SIGN"
        WHEN "JUST" WHEN "JUSTIFIED" WHEN "SYNC" WHEN "SYNCHRONIZED"
        WHEN "BLANK" WHEN "EXTERNAL" WHEN "GLOBAL" WHEN "BASED"
        WHEN "TYPE" WHEN "LINE" WHEN "COLUMN" WHEN "COL" WHEN "SOURCE"
        WHEN "SUM" WHEN "GROUP" WHEN "PRESENT"
            MOVE "Y" TO LS-STOP
        WHEN "NEXT"
            *> NEXT GROUP starts a clause; LINE NEXT PAGE does not.
            PERFORM CHECK-NEXT-GROUP
            MOVE LS-NEXT-IS-GROUP TO LS-STOP
    END-EVALUATE.

*> LS-NEXT-IS-GROUP = "Y" when the token after PS-POS is GROUP.
CHECK-NEXT-GROUP.
    MOVE "N" TO LS-NEXT-IS-GROUP
    IF PS-POS + 1 < PS-END AND TK-IS-WORD(PS-POS + 1)
        IF TK-TEXT(TK-TEXT-OFF(PS-POS + 1):TK-TEXT-LEN(PS-POS + 1))
           = "GROUP"
            MOVE "Y" TO LS-NEXT-IS-GROUP
        END-IF
    END-IF.

*> OCCURS n [TO m] [TIMES] [DEPENDING [ON] name] [ASCENDING|DESCENDING
*> [KEY] [IS] names] [INDEXED [BY] names]. DEPENDING gets a child.
OCCURS-OPERANDS.
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-TEXT = "DEPENDING"
            MOVE "DEPENDING" TO LS-DETAIL
            CALL "PLB-AST-ADD" USING PLB-AST LS-CLAUSE "CLAU" LS-DETAIL
                PS-POS LS-NODE
            ADD 1 TO PS-POS
            CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
            IF PX-TEXT = "ON"
                ADD 1 TO PS-POS
            END-IF
            IF LS-NODE > 0 AND TK-IS-WORD(PS-POS)
                MOVE PS-POS TO ND-NAME(LS-NODE) ND-TOK-LAST(LS-NODE)
            END-IF
        ELSE
            PERFORM CHECK-CLAUSE-START
            IF LS-STOP = "Y"
                EXIT PERFORM
            END-IF
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM.

*> EXEC SQL ... END-EXEC [.] (for example DECLARE SECTION or
*> INCLUDE) is kept as one node.
EXEC-BLOCK.
    PERFORM SECTION-PARENT
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "OTHR" "EXEC" PS-POS
        LS-NODE
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        ADD 1 TO PS-POS
        IF PX-TEXT = "END-EXEC"
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF PS-POS < PS-END
        IF TK-IS-PERIOD(PS-POS)
            ADD 1 TO PS-POS
        END-IF
    END-IF
    IF LS-NODE > 0
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    END-IF.

BAD-ENTRY.
    PERFORM SECTION-PARENT
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "ERR " " " PS-POS LS-NODE
    IF PX-KIND NOT = "N"
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS008"
            "expected a level number or section header"
    END-IF
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
    IF LS-NODE > 0
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    ELSE
        MOVE "Y" TO PS-FULL
    END-IF.

*> The open section, file description, and record extend to the
*> current position.
EXTEND-OPEN-NODES.
    IF LS-SECTION > 0
        COMPUTE ND-TOK-LAST(LS-SECTION) = PS-POS - 1
    END-IF
    IF LS-FD > 0
        COMPUTE ND-TOK-LAST(LS-FD) = PS-POS - 1
    END-IF
    PERFORM VARYING LS-NEXT FROM 1 BY 1
            UNTIL LS-NEXT > WS-LEVEL-DEPTH
        COMPUTE ND-TOK-LAST(LV-NODE(LS-NEXT)) = PS-POS - 1
    END-PERFORM.
END PROGRAM PLB-PX-DATA.
