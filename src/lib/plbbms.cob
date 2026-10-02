*> ---------------------------------------------------------------
*> plbbms: reading CICS BMS map definitions.
*>
*> A BMS source is assembler (read by plbasm): a statement has an
*> optional name in column 1, a macro (DFHMSD, DFHMDI, DFHMDF), and
*> operands separated by commas. END ends the source.
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
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbasms.cpy".
LOCAL-STORAGE SECTION.
*> Where the reading is.
01  LS-MAPSET               PIC 9(9) COMP-5 VALUE 0.
01  LS-MAP                  PIC 9(9) COMP-5 VALUE 0.
01  LS-ENDED                PIC X VALUE "N".
*> One operand: KEY=VALUE, or a positional VALUE.
01  OP-START                PIC 9(4) COMP-5.
01  OP-KEY                  PIC X(8).
01  OP-VALUE                PIC X(4000).
01  OP-ITEM-LEN             PIC 9(4) COMP-5.
01  OP-KEEP-CASE            PIC X VALUE "N".
*> Screen positions and lengths have at most 4 digits.
01  LS-NUM-1                PIC 9(4) COMP-5.
01  LS-NUM-2                PIC 9(4) COMP-5.
01  LS-NUMS                 PIC 9(4) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-Q                    PIC 9(4) COMP-5.
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
    CALL "PLB-ASM-READER" USING "O" LK-PATH PLB-ASM-STATEMENT
    PERFORM UNTIL AT-STATUS NOT = 0 OR LS-ENDED = "Y"
        PERFORM FINISH-STATEMENT
        CALL "PLB-ASM-READER" USING "N" LK-PATH PLB-ASM-STATEMENT
    END-PERFORM
    IF AT-STATUS = 2
        MOVE 1 TO LK-STATUS
    END-IF
    CALL "PLB-ASM-READER" USING "C" LK-PATH PLB-ASM-STATEMENT
    GOBACK.

FINISH-STATEMENT.
    EVALUATE AT-OP
        WHEN "DFHMSD"
            PERFORM ADD-MAPSET
        WHEN "DFHMDI"
            PERFORM ADD-MAP
        WHEN "DFHMDF"
            PERFORM ADD-FIELD
        WHEN "END"
            MOVE "Y" TO LS-ENDED
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
    MOVE AT-NAME TO BS-NAME(LS-MAPSET)
    MOVE LK-FILE-ID TO BS-FILE-ID(LS-MAPSET)
    MOVE AT-LINE TO BS-LINE(LS-MAPSET).

ADD-MAP.
    MOVE 0 TO LS-MAP
    IF BM-COUNT >= BM-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO BM-COUNT
    MOVE BM-COUNT TO LS-MAP
    MOVE AT-NAME TO BM-NAME(LS-MAP)
    MOVE LS-MAPSET TO BM-MAPSET(LS-MAP)
    MOVE LK-FILE-ID TO BM-FILE-ID(LS-MAP)
    MOVE AT-LINE TO BM-LINE(LS-MAP)
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
    MOVE AT-NAME TO BF-NAME(LS-F)
    MOVE LK-FILE-ID TO BF-FILE-ID(LS-F)
    MOVE AT-LINE TO BF-LINE(LS-F)
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

*> The next operand: OP-KEY, OP-VALUE, and OP-ITEM-LEN (0 at the end).
NEXT-OPERAND.
    CALL "PLB-ASM-OPERAND" USING PLB-ASM-STATEMENT OP-START OP-KEY
        OP-VALUE OP-ITEM-LEN OP-KEEP-CASE.
END PROGRAM PLB-BMS-READ.
