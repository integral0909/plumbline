*> ---------------------------------------------------------------
*> plbbms: reading CICS BMS map definitions.
*>
*> A BMS source is assembler: a statement has an optional name in
*> column 1, a macro (DFHMSD, DFHMDI, DFHMDF), and operands separated
*> by commas, up to the first blank outside quotes; the rest of the
*> line is a comment. A character in column 72 continues the statement
*> on the next line, from column 16, also inside a quoted string.
*> Lines starting with * or .* are comments, and END ends the source.
*>
*>     COSGN0A DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
*>     TRNNAME DFHMDF POS=(1,8),LENGTH=4,ATTRB=(ASKIP,FSET,NORM)
*>
*> DFHMSD starts a mapset (TYPE=FINAL ends it), DFHMDI a map, and
*> DFHMDF a field of the map. A field's POS is its attribute byte, as
*> (row,column) or as an offset from the start of the map.
*> ---------------------------------------------------------------

*> PLB-BMS-INIT: an empty model.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-BMS-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbbmsc.cpy".
COPY "plbbms.cpy".
PROCEDURE DIVISION USING PLB-BMS.
    MOVE 0 TO BS-COUNT BM-COUNT BF-COUNT
    GOBACK.
END PROGRAM PLB-BMS-INIT.

*> PLB-BMS-READ: add the maps of BMS source PATH, as file FILE-ID of
*> the run, to the model. STATUS receives 0, or 1 when the file cannot
*> be opened or read.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-BMS-READ.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT BMS-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  BMS-FILE.
01  BMS-RECORD              PIC X(256).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(1024).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
    88  WS-AT-END                 VALUE "10".
LOCAL-STORAGE SECTION.
01  LS-DONE                 PIC X VALUE "N".
01  LS-LINE-NO              PIC 9(9) COMP-5 VALUE 0.
01  LS-TEXT                 PIC X(80).
01  LS-P                    PIC 9(4) COMP-5.
01  LS-Q                    PIC 9(4) COMP-5.
*> Where the reading is.
01  LS-MAPSET               PIC 9(9) COMP-5 VALUE 0.
01  LS-MAP                  PIC 9(9) COMP-5 VALUE 0.
*> The statement being read.
01  ST-ACTIVE               PIC X VALUE "N".
01  ST-CONTINUES            PIC X VALUE "N".
01  ST-IN-QUOTE             PIC X VALUE "N".
01  ST-ENDED                PIC X VALUE "N".
01  ST-LINE                 PIC 9(9) COMP-5.
01  ST-NAME                 PIC X(8).
01  ST-OP                   PIC X(8).
01  ST-OPERANDS             PIC X(4000).
01  ST-LEN                  PIC 9(4) COMP-5.
*> One operand: KEY=VALUE, or a positional VALUE.
01  OP-START                PIC 9(4) COMP-5.
01  OP-I                    PIC 9(4) COMP-5.
01  OP-DEPTH                PIC 9(4) COMP-5.
01  OP-QUOTE                PIC X.
01  OP-KEY                  PIC X(8).
01  OP-VALUE                PIC X(4000).
01  OP-EQ                   PIC 9(4) COMP-5.
01  OP-ITEM-LEN             PIC 9(4) COMP-5.
*> Numbers in an operand value: N or (N,M).
*> Screen positions and lengths have at most 4 digits.
01  LS-NUM-1                PIC 9(4) COMP-5.
01  LS-NUM-2                PIC 9(4) COMP-5.
01  LS-NUMS                 PIC 9(4) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-POSITION             PIC 9(9) COMP-5.
01  LS-ATTRIBUTES           PIC X(200).
01  LS-F                    PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbbmsc.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-FILE-ID              PIC 9(4) COMP-5.
COPY "plbbms.cpy".
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-FILE-ID PLB-BMS LK-STATUS.
    MOVE 0 TO LK-STATUS
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT BMS-FILE
    IF WS-STATUS NOT = "00"
        MOVE 1 TO LK-STATUS
        GOBACK
    END-IF
    PERFORM UNTIL LS-DONE = "Y"
        MOVE SPACES TO BMS-RECORD
        READ BMS-FILE
        EVALUATE TRUE
            WHEN WS-READ-OK
                ADD 1 TO LS-LINE-NO
                MOVE BMS-RECORD(1:80) TO LS-TEXT
                PERFORM READ-LINE
                IF ST-ENDED = "Y"
                    MOVE "Y" TO LS-DONE
                END-IF
            WHEN WS-AT-END
                MOVE "Y" TO LS-DONE
            WHEN OTHER
                MOVE 1 TO LK-STATUS
                MOVE "Y" TO LS-DONE
        END-EVALUATE
    END-PERFORM
    CLOSE BMS-FILE
    IF ST-ACTIVE = "Y"
        PERFORM FINISH-STATEMENT
    END-IF
    GOBACK.

READ-LINE.
    IF ST-ACTIVE = "Y" AND ST-CONTINUES = "Y"
        MOVE 16 TO LS-P
        IF ST-IN-QUOTE = "N"
            PERFORM SKIP-BLANKS
        END-IF
        PERFORM READ-OPERANDS
        IF ST-CONTINUES = "N"
            PERFORM FINISH-STATEMENT
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF LS-TEXT(1:1) = "*" OR LS-TEXT(1:2) = ".*"
       OR LS-TEXT(1:71) = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO ST-ACTIVE
    MOVE "N" TO ST-CONTINUES ST-IN-QUOTE
    MOVE LS-LINE-NO TO ST-LINE
    MOVE SPACES TO ST-NAME ST-OP ST-OPERANDS
    MOVE 0 TO ST-LEN
    MOVE 1 TO LS-P
    IF LS-TEXT(1:1) NOT = SPACE
        PERFORM READ-WORD
        MOVE FUNCTION UPPER-CASE(LS-TEXT(LS-Q:LS-P - LS-Q)) TO ST-NAME
    END-IF
    PERFORM SKIP-BLANKS
    IF LS-P <= 71
        PERFORM READ-WORD
        MOVE FUNCTION UPPER-CASE(LS-TEXT(LS-Q:LS-P - LS-Q)) TO ST-OP
        PERFORM SKIP-BLANKS
    END-IF
    IF LS-P <= 71
        PERFORM READ-OPERANDS
    ELSE
        PERFORM NOTE-CONTINUATION
    END-IF
    IF ST-CONTINUES = "N"
        PERFORM FINISH-STATEMENT
    END-IF.

SKIP-BLANKS.
    PERFORM UNTIL LS-P > 71
        IF LS-TEXT(LS-P:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-P
    END-PERFORM.

READ-WORD.
    MOVE LS-P TO LS-Q
    PERFORM UNTIL LS-P > 71
        IF LS-TEXT(LS-P:1) = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-P
    END-PERFORM
    IF LS-P - LS-Q > 8
        COMPUTE LS-P = LS-Q + 8
    END-IF.

*> The operand text from LS-P to the first blank outside quotes, or
*> column 71, appended to ST-OPERANDS.
READ-OPERANDS.
    PERFORM UNTIL LS-P > 71
        IF LS-TEXT(LS-P:1) = SPACE AND ST-IN-QUOTE = "N"
            EXIT PERFORM
        END-IF
        IF LS-TEXT(LS-P:1) = "'"
            IF ST-IN-QUOTE = "Y"
                MOVE "N" TO ST-IN-QUOTE
            ELSE
                MOVE "Y" TO ST-IN-QUOTE
            END-IF
        END-IF
        IF ST-LEN < 4000
            ADD 1 TO ST-LEN
            MOVE LS-TEXT(LS-P:1) TO ST-OPERANDS(ST-LEN:1)
        END-IF
        ADD 1 TO LS-P
    END-PERFORM
    PERFORM NOTE-CONTINUATION.

*> A character in column 72 continues the statement.
NOTE-CONTINUATION.
    IF LS-TEXT(72:1) NOT = SPACE
        MOVE "Y" TO ST-CONTINUES
    ELSE
        MOVE "N" TO ST-CONTINUES
    END-IF.

FINISH-STATEMENT.
    MOVE "N" TO ST-ACTIVE ST-CONTINUES
    EVALUATE ST-OP
        WHEN "DFHMSD"
            PERFORM ADD-MAPSET
        WHEN "DFHMDI"
            PERFORM ADD-MAP
        WHEN "DFHMDF"
            PERFORM ADD-FIELD
        WHEN "END"
            MOVE "Y" TO ST-ENDED
    END-EVALUATE.

*> DFHMSD TYPE=FINAL ends the mapset; any other DFHMSD starts one.
ADD-MAPSET.
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        IF OP-KEY = "TYPE" AND OP-VALUE = "FINAL"
            MOVE 0 TO LS-MAPSET LS-MAP
            EXIT PARAGRAPH
        END-IF
        PERFORM NEXT-OPERAND
    END-PERFORM
    MOVE 0 TO LS-MAP
    IF BS-COUNT >= BS-MAX
        MOVE 0 TO LS-MAPSET
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO BS-COUNT
    MOVE BS-COUNT TO LS-MAPSET
    MOVE ST-NAME TO BS-NAME(LS-MAPSET)
    MOVE LK-FILE-ID TO BS-FILE-ID(LS-MAPSET)
    MOVE ST-LINE TO BS-LINE(LS-MAPSET).

ADD-MAP.
    MOVE 0 TO LS-MAP
    IF BM-COUNT >= BM-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO BM-COUNT
    MOVE BM-COUNT TO LS-MAP
    MOVE ST-NAME TO BM-NAME(LS-MAP)
    MOVE LS-MAPSET TO BM-MAPSET(LS-MAP)
    MOVE LK-FILE-ID TO BM-FILE-ID(LS-MAP)
    MOVE ST-LINE TO BM-LINE(LS-MAP)
    MOVE 0 TO BM-LINES(LS-MAP) BM-COLUMNS(LS-MAP)
        BM-FIELD-FIRST(LS-MAP) BM-FIELD-COUNT(LS-MAP)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        IF OP-KEY = "SIZE"
            PERFORM READ-NUMBERS
            IF LS-NUMS = 2
                MOVE LS-NUM-1 TO BM-LINES(LS-MAP)
                MOVE LS-NUM-2 TO BM-COLUMNS(LS-MAP)
            END-IF
        END-IF
        PERFORM NEXT-OPERAND
    END-PERFORM.

ADD-FIELD.
    IF LS-MAP = 0 OR BF-COUNT >= BF-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO BF-COUNT
    MOVE BF-COUNT TO LS-F
    IF BM-FIELD-COUNT(LS-MAP) = 0
        MOVE LS-F TO BM-FIELD-FIRST(LS-MAP)
    END-IF
    ADD 1 TO BM-FIELD-COUNT(LS-MAP)
    MOVE LS-MAP TO BF-MAP(LS-F)
    MOVE ST-NAME TO BF-NAME(LS-F)
    MOVE LK-FILE-ID TO BF-FILE-ID(LS-F)
    MOVE ST-LINE TO BF-LINE(LS-F)
    MOVE 0 TO BF-ROW(LS-F) BF-COLUMN(LS-F) BF-LENGTH(LS-F)
    MOVE 1 TO BF-OCCURS(LS-F)
    MOVE "N" TO BF-NUMERIC(LS-F) BF-HAS-INITIAL(LS-F)
    *> Without ATTRB a field is ASKIP; with an ATTRB that names
    *> neither ASKIP nor PROT, it is UNPROT.
    MOVE "Y" TO BF-PROTECTED(LS-F)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE OP-KEY
            WHEN "POS"
                PERFORM READ-NUMBERS
                PERFORM SET-POSITION
            WHEN "LENGTH"
                PERFORM READ-NUMBERS
                IF LS-NUMS = 1
                    MOVE LS-NUM-1 TO BF-LENGTH(LS-F)
                END-IF
            WHEN "OCCURS"
                PERFORM READ-NUMBERS
                IF LS-NUMS = 1 AND LS-NUM-1 > 0
                    MOVE LS-NUM-1 TO BF-OCCURS(LS-F)
                END-IF
            WHEN "ATTRB"
                PERFORM READ-ATTRIBUTES
            WHEN "INITIAL"
                MOVE "Y" TO BF-HAS-INITIAL(LS-F)
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM.

*> POS=(row,column), or POS=offset from the start of the map, counted
*> from 0 in the map's columns.
SET-POSITION.
    EVALUATE TRUE
        WHEN LS-NUMS = 2
            MOVE LS-NUM-1 TO BF-ROW(LS-F)
            MOVE LS-NUM-2 TO BF-COLUMN(LS-F)
        WHEN LS-NUMS = 1 AND BM-COLUMNS(LS-MAP) > 0
            MOVE LS-NUM-1 TO LS-POSITION
            COMPUTE BF-ROW(LS-F) =
                LS-POSITION / BM-COLUMNS(LS-MAP) + 1
            COMPUTE BF-COLUMN(LS-F) =
                FUNCTION MOD(LS-POSITION, BM-COLUMNS(LS-MAP)) + 1
    END-EVALUATE.

*> ATTRB=(ASKIP,NORM,...) or ATTRB=PROT.
READ-ATTRIBUTES.
    MOVE "N" TO BF-PROTECTED(LS-F)
    *> The words, each between spaces, so that PROT is not found in
    *> UNPROT.
    MOVE SPACES TO LS-ATTRIBUTES
    STRING " " DELIMITED BY SIZE
           OP-VALUE DELIMITED BY SPACE
        INTO LS-ATTRIBUTES
    INSPECT LS-ATTRIBUTES REPLACING ALL "," BY SPACE ALL ")" BY SPACE
        ALL "(" BY SPACE
    MOVE 0 TO LS-Q
    INSPECT LS-ATTRIBUTES TALLYING LS-Q FOR ALL " ASKIP " ALL " PROT "
    IF LS-Q > 0
        MOVE "Y" TO BF-PROTECTED(LS-F)
    END-IF
    MOVE 0 TO LS-Q
    INSPECT LS-ATTRIBUTES TALLYING LS-Q FOR ALL " NUM "
    IF LS-Q > 0
        MOVE "Y" TO BF-NUMERIC(LS-F)
    END-IF.

*> LS-NUM-1 and LS-NUM-2 from OP-VALUE: N or (N,M); LS-NUMS is how
*> many numbers there are (0 when the value is not that, or a number
*> has more than 4 digits).
READ-NUMBERS.
    MOVE 0 TO LS-NUMS LS-NUM-1 LS-NUM-2
    IF OP-VALUE(1:1) = "("
        MOVE SPACES TO LS-NUM-TEXT
        UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
            INTO LS-NUM-TEXT
        IF FUNCTION TRIM(LS-NUM-TEXT) IS NUMERIC
           AND LS-NUM-TEXT(5:) = SPACES
            MOVE FUNCTION NUMVAL(LS-NUM-TEXT) TO LS-NUM-1
            MOVE 1 TO LS-NUMS
        ELSE
            EXIT PARAGRAPH
        END-IF
        MOVE 0 TO LS-Q
        INSPECT OP-VALUE TALLYING LS-Q FOR CHARACTERS BEFORE ","
        IF LS-Q < 30
            MOVE SPACES TO LS-NUM-TEXT
            UNSTRING OP-VALUE(LS-Q + 2:) DELIMITED BY ")" OR ","
                INTO LS-NUM-TEXT
            IF LS-NUM-TEXT NOT = SPACES AND LS-NUM-TEXT(5:) = SPACES
               AND FUNCTION TRIM(LS-NUM-TEXT) IS NUMERIC
                MOVE FUNCTION NUMVAL(LS-NUM-TEXT) TO LS-NUM-2
                MOVE 2 TO LS-NUMS
            END-IF
        END-IF
    ELSE
        MOVE SPACES TO LS-NUM-TEXT
        UNSTRING OP-VALUE DELIMITED BY SPACE INTO LS-NUM-TEXT
        IF LS-NUM-TEXT NOT = SPACES AND LS-NUM-TEXT(5:) = SPACES
           AND FUNCTION TRIM(LS-NUM-TEXT) IS NUMERIC
            MOVE FUNCTION NUMVAL(LS-NUM-TEXT) TO LS-NUM-1
            MOVE 1 TO LS-NUMS
        END-IF
    END-IF.

*> The next operand of ST-OPERANDS from OP-START, split into OP-KEY
*> and OP-VALUE at its first = outside parentheses and quotes;
*> OP-ITEM-LEN is 0 at the end.
NEXT-OPERAND.
    MOVE 0 TO OP-ITEM-LEN OP-DEPTH OP-EQ
    MOVE "N" TO OP-QUOTE
    MOVE SPACES TO OP-KEY OP-VALUE
    IF OP-START > ST-LEN
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING OP-I FROM OP-START BY 1 UNTIL OP-I > ST-LEN
        EVALUATE TRUE
            WHEN ST-OPERANDS(OP-I:1) = "'"
                IF OP-QUOTE = "Y"
                    MOVE "N" TO OP-QUOTE
                ELSE
                    MOVE "Y" TO OP-QUOTE
                END-IF
            WHEN OP-QUOTE = "Y"
                CONTINUE
            WHEN ST-OPERANDS(OP-I:1) = "("
                ADD 1 TO OP-DEPTH
            WHEN ST-OPERANDS(OP-I:1) = ")" AND OP-DEPTH > 0
                SUBTRACT 1 FROM OP-DEPTH
            WHEN ST-OPERANDS(OP-I:1) = "," AND OP-DEPTH = 0
                EXIT PERFORM
            WHEN ST-OPERANDS(OP-I:1) = "=" AND OP-DEPTH = 0
                 AND OP-EQ = 0
                COMPUTE OP-EQ = OP-I - OP-START + 1
        END-EVALUATE
    END-PERFORM
    COMPUTE OP-ITEM-LEN = OP-I - OP-START
    IF OP-ITEM-LEN = 0
        *> An empty operand (two commas): skip it.
        COMPUTE OP-START = OP-I + 1
        MOVE 1 TO OP-ITEM-LEN
        EXIT PARAGRAPH
    END-IF
    IF OP-EQ > 1 AND OP-EQ <= 9
        MOVE FUNCTION UPPER-CASE(ST-OPERANDS(OP-START:OP-EQ - 1))
            TO OP-KEY
        IF OP-EQ < OP-ITEM-LEN
            MOVE ST-OPERANDS(OP-START + OP-EQ:OP-ITEM-LEN - OP-EQ)
                TO OP-VALUE
        END-IF
    ELSE
        MOVE ST-OPERANDS(OP-START:OP-ITEM-LEN) TO OP-VALUE
    END-IF
    IF OP-KEY NOT = "INITIAL"
        MOVE FUNCTION UPPER-CASE(OP-VALUE) TO OP-VALUE
    END-IF
    COMPUTE OP-START = OP-I + 1.
END PROGRAM PLB-BMS-READ.
