*> ---------------------------------------------------------------
*> plbrbms: rules about CICS BMS maps.
*>
*>   PLB-B001  map-fields-overlap   two fields of a map share screen
*>                                  positions
*>   PLB-B002  field-outside-map    a field ends past the end of its map
*>
*> On the screen a field takes its attribute byte, at POS, and LENGTH
*> bytes of data after it; a field with OCCURS=n takes that n times.
*> Positions count across the map's lines, so a field may run on into
*> the next line, but not past the map's last position. Maps without
*> SIZE take the terminal's size, which the source does not say, and
*> are checked for overlaps only.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-BMS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbbmsc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE-OVERLAP         PIC 9(4) COMP-5.
01  LS-RULE-OUTSIDE         PIC 9(4) COMP-5.
01  LS-M                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-LAST-F               PIC 9(9) COMP-5.
*> The first and last screen positions of fields F and G, counted
*> from 1 across the map's lines.
01  LS-F-START              PIC 9(9) COMP-5.
01  LS-F-END                PIC 9(9) COMP-5.
01  LS-G-START              PIC 9(9) COMP-5.
01  LS-G-END                PIC 9(9) COMP-5.
01  LS-COLUMNS              PIC 9(9) COMP-5.
01  LS-START                PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 1.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(20).
01  LS-NAME-PTR             PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
01  LS-PTR                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbbms.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-BMS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-B001" LS-RULE-OVERLAP
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-B002" LS-RULE-OUTSIDE
    PERFORM VARYING LS-M FROM 1 BY 1 UNTIL LS-M > BM-COUNT
        PERFORM CHECK-MAP
    END-PERFORM
    GOBACK.

*> Fields are checked against the fields before them in the source,
*> and each field is reported once.
CHECK-MAP.
    *> Without SIZE, positions count in an 80-column terminal line.
    MOVE BM-COLUMNS(LS-M) TO LS-COLUMNS
    IF LS-COLUMNS = 0
        MOVE 80 TO LS-COLUMNS
    END-IF
    COMPUTE LS-LAST-F = BM-FIELD-FIRST(LS-M) + BM-FIELD-COUNT(LS-M) - 1
    PERFORM VARYING LS-F FROM BM-FIELD-FIRST(LS-M) BY 1
            UNTIL LS-F > LS-LAST-F
        IF BF-ROW(LS-F) > 0 AND BF-COLUMN(LS-F) > 0
            MOVE LS-F TO LS-G
            PERFORM EXTENT-OF-G
            MOVE LS-START TO LS-F-START
            MOVE LS-END TO LS-F-END
            PERFORM CHECK-INSIDE
            PERFORM VARYING LS-G FROM BM-FIELD-FIRST(LS-M) BY 1
                    UNTIL LS-G >= LS-F
                IF BF-ROW(LS-G) > 0 AND BF-COLUMN(LS-G) > 0
                    PERFORM EXTENT-OF-G
                    IF LS-START <= LS-F-END AND LS-F-START <= LS-END
                        MOVE LS-START TO LS-G-START
                        MOVE LS-END TO LS-G-END
                        PERFORM REPORT-OVERLAP
                        EXIT PERFORM
                    END-IF
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.

*> LS-START and LS-END: the screen positions field LS-G takes.
EXTENT-OF-G.
    COMPUTE LS-START = (BF-ROW(LS-G) - 1) * LS-COLUMNS + BF-COLUMN(LS-G)
    COMPUTE LS-END = LS-START + BF-OCCURS(LS-G) * (BF-LENGTH(LS-G) + 1)
        - 1.

*> PLB-B002: past the map's last position, or starting outside it.
CHECK-INSIDE.
    IF BM-LINES(LS-M) = 0 OR BM-COLUMNS(LS-M) = 0
        EXIT PARAGRAPH
    END-IF
    IF LS-F-END <= BM-LINES(LS-M) * BM-COLUMNS(LS-M)
       AND BF-COLUMN(LS-F) <= BM-COLUMNS(LS-M)
        EXIT PARAGRAPH
    END-IF
    MOVE LS-F TO LS-G
    PERFORM FIELD-NAME
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "field " DELIMITED BY SIZE
           LS-NAME DELIMITED BY "  "
           " ends past the end of map " DELIMITED BY SIZE
           BM-NAME(LS-M) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE BM-LINES(LS-M) TO LS-NUM
    PERFORM APPEND-NUM
    STRING " lines of " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE BM-COLUMNS(LS-M) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ")" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-OUTSIDE
        BF-FILE-ID(LS-F) BF-LINE(LS-F) LS-COLUMN LS-ZERO LS-MESSAGE.

*> PLB-B001: field LS-F overlaps the earlier field LS-G.
REPORT-OVERLAP.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    MOVE LS-F TO LS-G
    PERFORM FIELD-NAME
    STRING "field " DELIMITED BY SIZE
           LS-NAME DELIMITED BY "  "
           " overlaps " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    *> LS-G was the earlier field: find it again from its extent.
    PERFORM VARYING LS-G FROM BM-FIELD-FIRST(LS-M) BY 1
            UNTIL LS-G >= LS-F
        IF BF-ROW(LS-G) > 0 AND BF-COLUMN(LS-G) > 0
            PERFORM EXTENT-OF-G
            IF LS-START = LS-G-START AND LS-END = LS-G-END
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    PERFORM FIELD-NAME
    STRING "field " DELIMITED BY SIZE
           LS-NAME DELIMITED BY "  "
           " of map " DELIMITED BY SIZE
           BM-NAME(LS-M) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-OVERLAP
        BF-FILE-ID(LS-F) BF-LINE(LS-F) LS-COLUMN LS-ZERO LS-MESSAGE.

*> LS-NAME: field LS-G's name, or "at row,column" for one without.
FIELD-NAME.
    MOVE SPACES TO LS-NAME
    IF BF-NAME(LS-G) NOT = SPACES
        MOVE BF-NAME(LS-G) TO LS-NAME
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-NAME-PTR
    MOVE BF-ROW(LS-G) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING "at " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           "," DELIMITED BY SIZE
        INTO LS-NAME WITH POINTER LS-NAME-PTR
    MOVE BF-COLUMN(LS-G) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-NAME WITH POINTER LS-NAME-PTR.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.
END PROGRAM PLB-RULE-BMS.
