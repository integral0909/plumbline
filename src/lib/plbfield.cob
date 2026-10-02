*> ---------------------------------------------------------------
*> plbfield: the fields of the copybooks of a run, and the programs
*> that name them (plumbline fields).
*>
*> A copybook shared by many programs collects fields that none of
*> them reads any more. PLB-FIELDS-COLLECT adds, after each file, the
*> data items it copies and the ones its statements name;
*> PLB-FIELDS-PRINT lists each copybook's items with the number of
*> programs that copy it and that name each item.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIELDS-INIT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbfldc.cpy".
LINKAGE SECTION.
COPY "plbfld.cpy".
PROCEDURE DIVISION USING PLB-FIELDS.
    MOVE 0 TO FI-COUNT FI-DROPPED
    PERFORM VARYING FI-COUNT FROM 1 BY 1 UNTIL FI-COUNT > FI-FILES-MAX
        MOVE 0 TO FI-HEAD(FI-COUNT)
    END-PERFORM
    MOVE 0 TO FI-COUNT
    GOBACK.
END PROGRAM PLB-FIELDS-INIT.

*> PLB-FIELDS-COLLECT: the copybook items of main file LK-FILE-ID, just
*> analyzed, and which of them its statements name.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIELDS-COLLECT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbfldc.cpy".
*> "Y" for each entry of the symbol table that a statement names.
01  WS-NAMED                PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-FILE                 PIC 9(4) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbfld.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-SYMBOLS PLB-REFS
        PLB-FIELDS LK-FILE-ID.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE "N" TO WS-NAMED(LS-S)
    END-PERFORM
    *> A name marks its item and the groups it is in; a condition name
    *> marks its item.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
            MOVE RF-SYMBOL(LS-R) TO LS-UP
            PERFORM UNTIL LS-UP = 0
                MOVE "Y" TO WS-NAMED(LS-UP)
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
        END-IF
    END-PERFORM
    PERFORM MARK-CLAUSE-NAMES
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME-TOKEN(LS-S) > 0
           AND ((SY-LEVEL(LS-S) >= 1 AND SY-LEVEL(LS-S) <= 49)
                OR SY-LEVEL(LS-S) = 77)
            PERFORM COPYBOOK-ITEM
        END-IF
    END-PERFORM
    GOBACK.

*> Items the run-time uses although no statement names them: the
*> keys and status items of files (RECORD KEY, ALTERNATE RECORD KEY,
*> RELATIVE KEY, FILE STATUS) and the objects of OCCURS DEPENDING ON.
*> They are marked by name.
MARK-CLAUSE-NAMES.
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T >= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "KEY" OR LS-WORD = "STATUS"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD
                    LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "IS"
                    ADD 1 TO LS-K
                END-IF
                IF LS-K < TK-COUNT AND TK-IS-WORD(LS-K)
                    PERFORM MARK-NAME-AT-K
                END-IF
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-ODO-TOKEN(LS-S) > 0
            MOVE SY-ODO-TOKEN(LS-S) TO LS-K
            PERFORM MARK-NAME-AT-K
        END-IF
    END-PERFORM.

*> Every item with the name at token LS-K, and its groups.
MARK-NAME-AT-K.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > SY-COUNT
        IF SY-NAME(LS-F) = LS-WORD
            MOVE LS-F TO LS-UP
            PERFORM UNTIL LS-UP = 0
                MOVE "Y" TO WS-NAMED(LS-UP)
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
        END-IF
    END-PERFORM.

*> Item LS-S, when its name is in a copybook.
COPYBOOK-ITEM.
    MOVE TK-SRC-LINE(SY-NAME-TOKEN(LS-S)) TO LS-LINE
    IF LS-LINE = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SL-FILE-ID(LS-LINE) TO LS-FILE
    IF LS-FILE = LK-FILE-ID OR LS-FILE = 0 OR LS-FILE > FI-FILES-MAX
        EXIT PARAGRAPH
    END-IF
    MOVE SL-LINE-NO(LS-LINE) TO LS-LINE
    PERFORM FIND-ENTRY
    IF LS-E = 0
        EXIT PARAGRAPH
    END-IF
    IF FI-LAST-COPY(LS-E) NOT = LK-FILE-ID
        MOVE LK-FILE-ID TO FI-LAST-COPY(LS-E)
        ADD 1 TO FI-COPIED(LS-E)
    END-IF
    IF WS-NAMED(LS-S) = "Y" AND FI-LAST-NAME(LS-E) NOT = LK-FILE-ID
        MOVE LK-FILE-ID TO FI-LAST-NAME(LS-E)
        ADD 1 TO FI-NAMED(LS-E)
    END-IF.

*> LS-E: the entry of the item at LS-LINE of copybook LS-FILE with the
*> name of LS-S, added when there is none (0 when the table is full).
FIND-ENTRY.
    MOVE 0 TO LS-LAST
    MOVE FI-HEAD(LS-FILE) TO LS-E
    PERFORM UNTIL LS-E = 0
        IF FI-LINE(LS-E) = LS-LINE AND FI-NAME(LS-E) = SY-NAME(LS-S)
            EXIT PARAGRAPH
        END-IF
        MOVE LS-E TO LS-LAST
        MOVE FI-NEXT(LS-E) TO LS-E
    END-PERFORM
    IF FI-COUNT >= FI-MAX
        ADD 1 TO FI-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO FI-COUNT
    MOVE FI-COUNT TO LS-E
    MOVE LS-FILE TO FI-FILE-ID(LS-E)
    MOVE LS-LINE TO FI-LINE(LS-E)
    MOVE SY-LEVEL(LS-S) TO FI-LEVEL(LS-E)
    MOVE SY-NAME(LS-S) TO FI-NAME(LS-E)
    MOVE 0 TO FI-COPIED(LS-E) FI-NAMED(LS-E) FI-LAST-COPY(LS-E)
        FI-LAST-NAME(LS-E) FI-NEXT(LS-E)
    IF LS-LAST = 0
        MOVE LS-E TO FI-HEAD(LS-FILE)
    ELSE
        MOVE LS-E TO FI-NEXT(LS-LAST)
    END-IF.
END PROGRAM PLB-FIELDS-COLLECT.

*> PLB-FIELDS-PRINT: each copybook with its items, as text or JSON.
*>
*>   copybook PATH: 12 items, 3 named by no program
*>     01 ACCOUNT-RECORD     line 4   named by 6 of 6 programs
*>     05 ACCT-ADDR-ZIP      line 12  named by no program of 6
*>
*> With LK-UNUSED = "Y", only the items no program names.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIELDS-PRINT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbfldc.cpy".
LOCAL-STORAGE SECTION.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-ITEMS                PIC 9(9) COMP-5.
01  LS-UNNAMED              PIC 9(9) COMP-5.
01  LS-COPIED               PIC 9(9) COMP-5.
01  LS-FIRST-BOOK           PIC X VALUE "Y".
01  LS-FIRST-ITEM           PIC X.
01  LS-PATH                 PIC X(1024).
01  LS-OUT                  PIC X(2048).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-LEVEL                PIC 99.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbfld.cpy".
01  LK-FORMAT               PIC X(5).
01  LK-UNUSED               PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-FIELDS LK-FORMAT LK-UNUSED.
    IF LK-FORMAT = "json"
        DISPLAY "{"
        DISPLAY '  "copybooks": ['
    END-IF
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > FI-FILES-MAX
        IF FI-HEAD(LS-F) > 0
            PERFORM COUNT-ITEMS
            IF LK-UNUSED NOT = "Y" OR LS-UNNAMED > 0
                IF LK-FORMAT = "json"
                    PERFORM JSON-COPYBOOK
                ELSE
                    PERFORM TEXT-COPYBOOK
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY "  ]"
        DISPLAY "}"
    END-IF
    GOBACK.

*> The items of copybook LS-F, those no program names, and the number
*> of programs that copy it (the most that copy any of its items).
COUNT-ITEMS.
    MOVE 0 TO LS-ITEMS LS-UNNAMED LS-COPIED
    MOVE FI-HEAD(LS-F) TO LS-E
    PERFORM UNTIL LS-E = 0
        ADD 1 TO LS-ITEMS
        IF FI-NAMED(LS-E) = 0
            ADD 1 TO LS-UNNAMED
        END-IF
        IF FI-COPIED(LS-E) > LS-COPIED
            MOVE FI-COPIED(LS-E) TO LS-COPIED
        END-IF
        MOVE FI-NEXT(LS-E) TO LS-E
    END-PERFORM.

TEXT-COPYBOOK.
    PERFORM START-OUT
    STRING "copybook " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-PATH
    STRING ": " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-ITEMS TO LS-NUM
    PERFORM APPEND-NUM
    STRING " items, " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-UNNAMED TO LS-NUM
    PERFORM APPEND-NUM
    STRING " named by no program; copied by " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-COPIED TO LS-NUM
    PERFORM APPEND-NUM
    PERFORM PRINT-OUT
    MOVE FI-HEAD(LS-F) TO LS-E
    PERFORM UNTIL LS-E = 0
        IF LK-UNUSED NOT = "Y" OR FI-NAMED(LS-E) = 0
            PERFORM TEXT-ITEM
        END-IF
        MOVE FI-NEXT(LS-E) TO LS-E
    END-PERFORM.

*>     05 NAME  line N  named by K of C programs | named by no program
TEXT-ITEM.
    PERFORM START-OUT
    *> plumbline: ignore move-truncation -- levels 1 to 49 and 77
    MOVE FI-LEVEL(LS-E) TO LS-LEVEL
    STRING "  " LS-LEVEL " " DELIMITED BY SIZE
           FI-NAME(LS-E) DELIMITED BY SIZE
           " line " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE FI-LINE(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    IF FI-NAMED(LS-E) = 0
        STRING ", named by no program" DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING ", named by " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        MOVE FI-NAMED(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING " of " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        MOVE FI-COPIED(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        IF FI-COPIED(LS-E) = 1
            STRING " program" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        ELSE
            STRING " programs" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
    END-IF
    PERFORM PRINT-OUT.

JSON-COPYBOOK.
    PERFORM START-OUT
    IF LS-FIRST-BOOK = "Y"
        STRING '    {"path": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '   ,{"path": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-BOOK
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-F LS-PATH
    CALL "PLB-JSON-STRING" USING LS-PATH LS-OUT LS-PTR
    STRING ', "copiedBy": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-COPIED TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "items": [' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    MOVE "Y" TO LS-FIRST-ITEM
    MOVE FI-HEAD(LS-F) TO LS-E
    PERFORM UNTIL LS-E = 0
        IF LK-UNUSED NOT = "Y" OR FI-NAMED(LS-E) = 0
            PERFORM JSON-ITEM
        END-IF
        MOVE FI-NEXT(LS-E) TO LS-E
    END-PERFORM
    DISPLAY "      ]}".

JSON-ITEM.
    PERFORM START-OUT
    IF LS-FIRST-ITEM = "Y"
        STRING '        {"name": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING '       ,{"name": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    MOVE "N" TO LS-FIRST-ITEM
    CALL "PLB-JSON-STRING" USING FI-NAME(LS-E) LS-OUT LS-PTR
    STRING ', "level": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE FI-LEVEL(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "line": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE FI-LINE(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "copiedBy": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE FI-COPIED(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "namedBy": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE FI-NAMED(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING '}' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

APPEND-PATH.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-F LS-PATH
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
END PROGRAM PLB-FIELDS-PRINT.
