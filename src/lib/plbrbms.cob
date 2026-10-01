*> ---------------------------------------------------------------
*> plbrbms: rules about CICS BMS maps.
*>
*>   PLB-B001  map-fields-overlap   two fields of a map share screen
*>                                  positions
*>   PLB-B002  field-outside-map    a field ends past the end of its map
*>   PLB-B003  map-not-in-mapset    a program sends or receives a map
*>                                  that its mapset does not define
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
COPY "plbcallc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE-OVERLAP         PIC 9(4) COMP-5.
01  LS-RULE-OUTSIDE         PIC 9(4) COMP-5.
01  LS-RULE-UNDEFINED       PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-SET                  PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
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
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-BMS PLB-CALL-GRAPH.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-B001" LS-RULE-OVERLAP
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-B002" LS-RULE-OUTSIDE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-B003" LS-RULE-UNDEFINED
    PERFORM VARYING LS-M FROM 1 BY 1 UNTIL LS-M > BM-COUNT
        PERFORM CHECK-MAP
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > PM-COUNT
        PERFORM CHECK-MAP-USE
    END-PERFORM
    GOBACK.

*> PLB-B003: map use LS-U names a mapset of the run that has no map
*> of that name. Mapsets that are not among the BMS sources are not
*> judged.
CHECK-MAP-USE.
    MOVE 0 TO LS-SET
    PERFORM VARYING LS-M FROM 1 BY 1 UNTIL LS-M > BS-COUNT
        IF BS-NAME(LS-M) = PM-MAPSET(LS-U)
            MOVE LS-M TO LS-SET
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-SET = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-M FROM 1 BY 1 UNTIL LS-M > BM-COUNT
        IF BM-MAPSET(LS-M) = LS-SET AND BM-NAME(LS-M) = PM-MAP(LS-U)
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "map " DELIMITED BY SIZE
           PM-MAP(LS-U) DELIMITED BY SPACE
           " is not defined in mapset " DELIMITED BY SIZE
           PM-MAPSET(LS-U) DELIMITED BY SPACE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-UNDEFINED
        PM-FILE-ID(LS-U) PM-LINE(LS-U) PM-COLUMN(LS-U) LS-ZERO
        LS-MESSAGE.

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

*> PLB-B004 symbolic-map-stale: a program's symbolic map, the copybook
*> that BMS generates from a map, does not match the map. For map M,
*> the symbolic map is the record MI, and each named field F of the
*> map has the items FL (length), FF and FA (flag and attribute), and
*> FI (the data) in it. The rule checks, for each map of the run whose
*> MI record the program has:
*>
*>   - every named field of the map has its FI item, as long as the
*>     field's LENGTH;
*>   - every FI item that has an FL item beside it is a field of the
*>     map.
*>
*> A copybook generated from an older version of the map puts the
*> program's data at the wrong places on the screen.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SYMBOLIC-MAPS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbbmsc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-M                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-ITEM                 PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-NAME                 PIC X(31).
01  LS-FIELD                PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-SIZE-TEXT            PIC X(20).
01  LS-SIZE-LEN             PIC 9(9) COMP-5.
01  LS-LENGTH-TEXT          PIC X(20).
01  LS-LENGTH-LEN           PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbsym.cpy".
COPY "plbbms.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-SYMBOLS PLB-BMS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-B004" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR BM-COUNT = 0 OR SY-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-M FROM 1 BY 1 UNTIL LS-M > BM-COUNT
        IF BM-NAME(LS-M) NOT = SPACES
            MOVE SPACES TO LS-NAME
            STRING BM-NAME(LS-M) DELIMITED BY SPACE
                   "I" DELIMITED BY SIZE
                INTO LS-NAME
            PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > SY-COUNT
                IF SY-NAME(LS-G) = LS-NAME AND SY-LEVEL(LS-G) = 1
                    PERFORM CHECK-RECORD
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM
    GOBACK.

*> Record LS-G is the symbolic map of map LS-M.
CHECK-RECORD.
    PERFORM VARYING LS-F FROM BM-FIELD-FIRST(LS-M) BY 1
            UNTIL LS-F >= BM-FIELD-FIRST(LS-M) + BM-FIELD-COUNT(LS-M)
        IF BF-NAME(LS-F) NOT = SPACES
            MOVE SPACES TO LS-FIELD
            STRING BF-NAME(LS-F) DELIMITED BY SPACE
                   "I" DELIMITED BY SIZE
                INTO LS-FIELD
            PERFORM FIND-ITEM
            IF LS-ITEM = 0
                PERFORM REPORT-MISSING
            ELSE
                IF SY-SIZE(LS-ITEM) NOT = BF-LENGTH(LS-F)
                   AND BF-LENGTH(LS-F) > 0
                    PERFORM REPORT-LENGTH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    *> Items of fields the map no longer has: FI with FL beside it.
    PERFORM VARYING LS-S FROM LS-G BY 1 UNTIL LS-S > SY-COUNT
        IF LS-S > LS-G AND SY-LEVEL(LS-S) = 1
            EXIT PERFORM
        END-IF
        PERFORM CHECK-EXTRA-ITEM
    END-PERFORM.

*> LS-ITEM = the item named LS-FIELD in record LS-G, or 0.
FIND-ITEM.
    MOVE 0 TO LS-ITEM
    PERFORM VARYING LS-S FROM LS-G BY 1 UNTIL LS-S > SY-COUNT
        IF LS-S > LS-G AND SY-LEVEL(LS-S) = 1
            EXIT PERFORM
        END-IF
        IF SY-NAME(LS-S) = LS-FIELD
            MOVE LS-S TO LS-ITEM
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Item LS-S: when its name ends in I and the record has the name
*> with L instead, the map must have a field of the name without I.
CHECK-EXTRA-ITEM.
    MOVE SY-NAME(LS-S) TO LS-NAME
    CALL "PLB-STR-LENGTH" USING LS-NAME LS-LEN
    IF LS-LEN < 2 OR LS-LEN > 8
        EXIT PARAGRAPH
    END-IF
    IF LS-NAME(LS-LEN:1) NOT = "I"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-NAME TO LS-FIELD
    MOVE "L" TO LS-FIELD(LS-LEN:1)
    MOVE LS-S TO LS-TOKEN
    PERFORM FIND-ITEM
    MOVE LS-TOKEN TO LS-S
    IF LS-ITEM = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-F FROM BM-FIELD-FIRST(LS-M) BY 1
            UNTIL LS-F >= BM-FIELD-FIRST(LS-M) + BM-FIELD-COUNT(LS-M)
        IF BF-NAME(LS-F) = LS-NAME(1:LS-LEN - 1)
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "symbolic map item " DELIMITED BY SIZE
           LS-NAME(1:LS-LEN) DELIMITED BY SIZE
           " is for a field " DELIMITED BY SIZE
           LS-NAME(1:LS-LEN - 1) DELIMITED BY SIZE
           " that map " DELIMITED BY SIZE
           BM-NAME(LS-M) DELIMITED BY SPACE
           " does not have" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE SY-NAME-TOKEN(LS-S) TO LS-TOKEN
    PERFORM REPORT-AT-TOKEN.

REPORT-MISSING.
    MOVE SPACES TO LS-MESSAGE
    STRING "symbolic map " DELIMITED BY SIZE
           SY-NAME(LS-G) DELIMITED BY SPACE
           " has no item " DELIMITED BY SIZE
           LS-FIELD DELIMITED BY SPACE
           " for field " DELIMITED BY SIZE
           BF-NAME(LS-F) DELIMITED BY SPACE
           " of map " DELIMITED BY SIZE
           BM-NAME(LS-M) DELIMITED BY SPACE
        INTO LS-MESSAGE
    MOVE SY-NAME-TOKEN(LS-G) TO LS-TOKEN
    PERFORM REPORT-AT-TOKEN.

REPORT-LENGTH.
    MOVE SY-SIZE(LS-ITEM) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SIZE-TEXT LS-SIZE-LEN
    MOVE BF-LENGTH(LS-F) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-LENGTH-TEXT LS-LENGTH-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING LS-FIELD DELIMITED BY SPACE
           " has " DELIMITED BY SIZE
           LS-SIZE-TEXT(1:LS-SIZE-LEN) DELIMITED BY SIZE
           " characters, but field " DELIMITED BY SIZE
           BF-NAME(LS-F) DELIMITED BY SPACE
           " of map " DELIMITED BY SIZE
           BM-NAME(LS-M) DELIMITED BY SPACE
           " has LENGTH=" DELIMITED BY SIZE
           LS-LENGTH-TEXT(1:LS-LENGTH-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE SY-NAME-TOKEN(LS-ITEM) TO LS-TOKEN
    PERFORM REPORT-AT-TOKEN.

REPORT-AT-TOKEN.
    IF LS-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-SYMBOLIC-MAPS.
