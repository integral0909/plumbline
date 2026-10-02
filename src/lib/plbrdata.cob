*> ---------------------------------------------------------------
*> plbrdata: rules that read the symbol table.
*>
*>   PLB-C007  redefines-larger
*>   PLB-M003  unused-data-item
*>   PLB-M013  unused-copybook
*>   PLB-M015  packed-even-digits
*> ---------------------------------------------------------------

*> PLB-C007 redefines-larger: an item below level 01 that is larger
*> than the item it redefines. The standard does not allow it: the
*> extra bytes overlay whatever follows the redefined item.
*>
*> PLB-M015 packed-even-digits walks the same table: a packed-decimal
*> item with an even number of digits. Packed decimal stores two
*> digits a byte and the sign in the last half byte, so an even count
*> leaves the first half byte unused: PIC S9(4) COMP-3 takes the 3
*> bytes of S9(5). IBM compilers then generate extra code to clear it,
*> and a digit can hide there that the picture does not show.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C007.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-PACKED          PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-DIGITS-TEXT          PIC X(20).
01  LS-DIGITS-LEN           PIC 9(9) COMP-5.
01  LS-SIZE-TEXT            PIC X(20).
01  LS-SIZE-LEN             PIC 9(9) COMP-5.
01  LS-RSIZE-TEXT           PIC X(20).
01  LS-RSIZE-LEN            PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbsym.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-SYMBOLS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C007" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M015" LS-RULE-PACKED
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE SY-REDEFINES(LS-S) TO LS-R
        IF LS-R > 0 AND SY-LEVEL(LS-S) > 1
            IF SY-SIZE(LS-S) > SY-SIZE(LS-R) AND SY-SIZE(LS-R) > 0
                PERFORM REPORT-ITEM
            END-IF
        END-IF
        IF RL-ENABLED(LS-RULE-PACKED) = "Y"
            PERFORM CHECK-PACKED
        END-IF
    END-PERFORM
    GOBACK.

CHECK-PACKED.
    IF SY-CATEGORY(LS-S) NOT = "9" OR SY-NAME-TOKEN(LS-S) = 0
       OR SY-DIGITS(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION MOD(SY-DIGITS(LS-S), 2) NOT = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-USAGE(LS-S)
        WHEN "COMP-3" WHEN "COMPUTATIONAL-3" WHEN "PACKED-DECIMAL"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE SY-DIGITS(LS-S) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-DIGITS-TEXT LS-DIGITS-LEN
    ADD 1 TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SIZE-TEXT LS-SIZE-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " is packed with " DELIMITED BY SIZE
           LS-DIGITS-TEXT(1:LS-DIGITS-LEN) DELIMITED BY SIZE
           " digits; " DELIMITED BY SIZE
           LS-SIZE-TEXT(1:LS-SIZE-LEN) DELIMITED BY SIZE
           " take the same bytes" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE SY-NAME-TOKEN(LS-S) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-PACKED LS-TOKEN LS-MESSAGE.

REPORT-ITEM.
    MOVE SY-SIZE(LS-S) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SIZE-TEXT LS-SIZE-LEN
    MOVE SY-SIZE(LS-R) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-RSIZE-TEXT LS-RSIZE-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
           LS-SIZE-TEXT(1:LS-SIZE-LEN) DELIMITED BY SIZE
           " bytes) is larger than " DELIMITED BY SIZE
           SY-NAME(LS-R) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
           LS-RSIZE-TEXT(1:LS-RSIZE-LEN) DELIMITED BY SIZE
           " bytes), which it redefines" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE SY-NAME-TOKEN(LS-S) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C007.

*> PLB-M003 unused-data-item: a working-storage or local-storage item
*> of the program's own source that nothing refers to.
*>
*> An item counts as used when its name, or the name of one of its
*> condition names (88), appears in the program's procedure division
*> or as the object of an OCCURS DEPENDING ON. A group is used when
*> any member is, and members of a group that is used by name are
*> used through it. An item is also used when an item that redefines
*> it is used: that is the common idiom of a VALUE-filled table read
*> through a REDEFINES. Only the outermost unused item is reported.
*>
*> Items from copybooks are not reported (a program commonly uses
*> part of a shared layout), nor are GLOBAL or EXTERNAL items, which
*> other programs may use, nor constants (level 78 or CONSTANT).
*>
*> PLB-M013 unused-copybook comes from the same reckoning: a COPY in
*> working-storage or local-storage that declares items, none of them
*> used. It is reported at the COPY statement. A copybook with
*> anything else (file or linkage entries, GLOBAL or EXTERNAL items,
*> code) is not, nor is one that only copies other copybooks: each of
*> those is judged on its own.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-M003.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  NM-MAX                      VALUE 200000.
01  WS-NAMES.
    05  WS-NAME-COUNT       PIC 9(9) COMP-5.
    05  WS-NAME             OCCURS 0 TO NM-MAX TIMES
                            DEPENDING ON WS-NAME-COUNT
                            ASCENDING KEY IS NM-TEXT
                            INDEXED BY NM-IX.
        10  NM-TEXT         PIC X(31).
*> Per symbol, "Y" or "N": referenced by name; used (itself, a
*> member, or through a redefining item); used through a group.
01  WS-STATE.
    05  WS-DIRECT           PIC X OCCURS 100000 TIMES.
    05  WS-USED             PIC X OCCURS 100000 TIMES.
    05  WS-VIA-GROUP        PIC X OCCURS 100000 TIMES.
*> Per inclusion: items it declares, whether one is used, and whether
*> it holds anything the rule does not judge.
01  WS-COPYBOOKS.
    05  WS-INCL-ITEMS       PIC 9(9) COMP-5 OCCURS 4096 TIMES.
    05  WS-INCL-USED        PIC X OCCURS 4096 TIMES.
    05  WS-INCL-OTHER       PIC X OCCURS 4096 TIMES.
*> Constants of the program, and whether the data division names them
*> (OCCURS TK-MAX TIMES, PIC X(LEN)).
01  WS-CONSTANTS.
    05  WS-CONST-COUNT      PIC 9(4) COMP-5.
    05  WS-CONST            OCCURS 2000 TIMES.
        10  WS-CONST-SYM    PIC 9(9) COMP-5.
        10  WS-CONST-USED   PIC X.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-COPYBOOK        PIC 9(4) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-SRC-LINE             PIC 9(9) COMP-5.
01  LS-PATH                 PIC X(1024).
01  LS-BASE                 PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-CLAUSE               PIC 9(9) COMP-5.
01  LS-DIVISION             PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-KW                   PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-SKIP                 PIC X.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbincl.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-INCLUSIONS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M003" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M013" LS-RULE-COPYBOOK
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-COPYBOOK) NOT = "Y")
       OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "PROG"
            MOVE LS-NODE TO LS-PROGRAM
            PERFORM CHECK-PROGRAM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

CHECK-PROGRAM.
    PERFORM COLLECT-NAMES
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE "N" TO WS-DIRECT(LS-S) WS-USED(LS-S) WS-VIA-GROUP(LS-S)
    END-PERFORM
    *> Direct references, credited to the item (an 88 credits its
    *> conditional variable).
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-NAME(LS-S) NOT = SPACES
            MOVE SY-NAME(LS-S) TO LS-TEXT
            PERFORM LOOK-UP-NAME
            IF LS-FOUND = "Y"
                IF SY-LEVEL(LS-S) = 88 AND SY-PARENT(LS-S) > 0
                    MOVE "Y" TO WS-DIRECT(SY-PARENT(LS-S))
                ELSE
                    MOVE "Y" TO WS-DIRECT(LS-S)
                END-IF
            END-IF
        END-IF
    END-PERFORM
    *> Members come after their groups: pass upward in reverse order,
    *> then downward in order.
    PERFORM VARYING LS-S FROM SY-COUNT BY -1 UNTIL LS-S = 0
        IF WS-DIRECT(LS-S) = "Y"
            MOVE "Y" TO WS-USED(LS-S)
        END-IF
        IF WS-USED(LS-S) = "Y" AND SY-PARENT(LS-S) > 0
            MOVE "Y" TO WS-USED(SY-PARENT(LS-S))
        END-IF
        *> The redefined item always comes before the item redefining
        *> it, so it has not been passed yet.
        IF WS-USED(LS-S) = "Y" AND SY-REDEFINES(LS-S) > 0
            MOVE "Y" TO WS-USED(SY-REDEFINES(LS-S))
            MOVE "Y" TO WS-DIRECT(SY-REDEFINES(LS-S))
        END-IF
    END-PERFORM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE SY-PARENT(LS-S) TO LS-P
        IF LS-P > 0
            IF WS-DIRECT(LS-P) = "Y" OR WS-VIA-GROUP(LS-P) = "Y"
                MOVE "Y" TO WS-VIA-GROUP(LS-S)
            END-IF
        END-IF
    END-PERFORM
    IF RL-ENABLED(LS-RULE) = "Y"
        PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
            IF SY-PROGRAM(LS-S) = LS-PROGRAM
                PERFORM CONSIDER-ITEM
            END-IF
        END-PERFORM
    END-IF
    IF RL-ENABLED(LS-RULE-COPYBOOK) = "Y" AND IN-COUNT > 0
        PERFORM CHECK-COPYBOOKS
    END-IF.

*> PLB-M013: tally each inclusion's items in this program, then
*> report those with items and none used.
CHECK-COPYBOOKS.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > IN-COUNT
        MOVE 0 TO WS-INCL-ITEMS(LS-I)
        MOVE "N" TO WS-INCL-USED(LS-I) WS-INCL-OTHER(LS-I)
    END-PERFORM
    *> Copybook text outside the data division's storage sections:
    *> code, environment entries, the program header.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-PROGRAM) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-PROGRAM)
        IF TK-INCL(LS-T) > 0
            MOVE TK-INCL(LS-T) TO LS-I
            IF WS-INCL-OTHER(LS-I) = "N"
                PERFORM CHECK-COPYBOOK-TOKEN
            END-IF
        END-IF
    END-PERFORM
    PERFORM COLLECT-CONSTANT-USES
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-NAME-TOKEN(LS-S) > 0
            MOVE SY-NAME-TOKEN(LS-S) TO LS-TOKEN
            IF TK-INCL(LS-TOKEN) > 0
                MOVE TK-INCL(LS-TOKEN) TO LS-I
                ADD 1 TO WS-INCL-ITEMS(LS-I)
                IF WS-USED(LS-S) = "Y" OR WS-VIA-GROUP(LS-S) = "Y"
                    MOVE "Y" TO WS-INCL-USED(LS-I)
                END-IF
                IF SY-CATEGORY(LS-S) = "K"
                    PERFORM VARYING LS-P FROM 1 BY 1
                            UNTIL LS-P > WS-CONST-COUNT
                        IF WS-CONST-SYM(LS-P) = LS-S
                           AND WS-CONST-USED(LS-P) = "Y"
                            MOVE "Y" TO WS-INCL-USED(LS-I)
                        END-IF
                    END-PERFORM
                END-IF
                IF SY-SECTION(LS-S) NOT = "W" AND NOT = "L"
                    MOVE "Y" TO WS-INCL-OTHER(LS-I)
                END-IF
                PERFORM CHECK-SHARED
                IF LS-SKIP = "Y"
                    MOVE "Y" TO WS-INCL-OTHER(LS-I)
                END-IF
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > IN-COUNT
        IF WS-INCL-ITEMS(LS-I) > 0 AND WS-INCL-USED(LS-I) = "N"
           AND WS-INCL-OTHER(LS-I) = "N" AND IN-FROM-LINE(LS-I) > 0
            PERFORM REPORT-COPYBOOK
        END-IF
    END-PERFORM.

*> WS-CONST-USED = "Y" for each constant of the program whose name
*> appears in its data division other than where it is declared.
COLLECT-CONSTANT-USES.
    MOVE 0 TO WS-CONST-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-CATEGORY(LS-S) = "K"
           AND SY-NAME-TOKEN(LS-S) > 0 AND WS-CONST-COUNT < 2000
            ADD 1 TO WS-CONST-COUNT
            MOVE LS-S TO WS-CONST-SYM(WS-CONST-COUNT)
            MOVE "N" TO WS-CONST-USED(WS-CONST-COUNT)
        END-IF
    END-PERFORM
    IF WS-CONST-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-PROGRAM) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "DIVN" AND ND-DETAIL(LS-CHILD) = "DATA"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
                IF TK-IS-WORD(LS-T) AND TK-KEYWORD(LS-T) = SPACE
                   AND TK-TEXT-LEN(LS-T) <= 31
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    PERFORM VARYING LS-P FROM 1 BY 1
                            UNTIL LS-P > WS-CONST-COUNT
                        MOVE WS-CONST-SYM(LS-P) TO LS-S
                        IF SY-NAME(LS-S) = LS-TEXT
                           AND SY-NAME-TOKEN(LS-S) NOT = LS-T
                            MOVE "Y" TO WS-CONST-USED(LS-P)
                        END-IF
                    END-PERFORM
                END-IF
                *> A picture sized by a constant: X(LEN).
                IF TK-IS-PICTURE(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    PERFORM VARYING LS-P FROM 1 BY 1
                            UNTIL LS-P > WS-CONST-COUNT
                        MOVE WS-CONST-SYM(LS-P) TO LS-S
                        MOVE 0 TO LS-LEN
                        INSPECT LS-TEXT TALLYING LS-LEN FOR ALL
                            FUNCTION CONCATENATE("(" FUNCTION TRIM(
                                SY-NAME(LS-S)) ")")
                        IF LS-LEN > 0
                            MOVE "Y" TO WS-CONST-USED(LS-P)
                        END-IF
                    END-PERFORM
                END-IF
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

*> Inclusion LS-I holds something other than storage entries when
*> token LS-T is outside the program's working-storage and
*> local-storage sections.
CHECK-COPYBOOK-TOKEN.
    MOVE "Y" TO LS-SKIP
    MOVE ND-FIRST(LS-PROGRAM) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "DIVN" AND ND-DETAIL(LS-CHILD) = "DATA"
            MOVE ND-FIRST(LS-CHILD) TO LS-CLAUSE
            PERFORM UNTIL LS-CLAUSE = 0
                IF ND-KIND(LS-CLAUSE) = "SECT"
                   AND (ND-DETAIL(LS-CLAUSE) = "WORKING-STORAGE"
                        OR ND-DETAIL(LS-CLAUSE) = "LOCAL-STORAGE")
                   AND LS-T >= ND-TOK-FIRST(LS-CLAUSE)
                   AND LS-T <= ND-TOK-LAST(LS-CLAUSE)
                    MOVE "N" TO LS-SKIP
                END-IF
                MOVE ND-NEXT(LS-CLAUSE) TO LS-CLAUSE
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-SKIP = "Y"
        MOVE "Y" TO WS-INCL-OTHER(LS-I)
    END-IF.

REPORT-COPYBOOK.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET IN-FILE-ID(LS-I)
        LS-PATH
    *> The copybook's file name, without its directory.
    MOVE 0 TO LS-BASE
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > 1024
        IF LS-PATH(LS-T:1) = "/"
            MOVE LS-T TO LS-BASE
        END-IF
        IF LS-PATH(LS-T:) = SPACES
            EXIT PERFORM
        END-IF
    END-PERFORM
    ADD 1 TO LS-BASE
    MOVE SPACES TO LS-MESSAGE
    STRING "none of the items copybook " DELIMITED BY SIZE
           LS-PATH(LS-BASE:) DELIMITED BY SPACE
           " declares is used" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-SRC-LINE-INDEX" USING PLB-SOURCE-SET IN-FROM-FILE-ID(LS-I)
        IN-FROM-LINE(LS-I) LS-SRC-LINE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-COPYBOOK
        IN-FROM-FILE-ID(LS-I) IN-FROM-LINE(LS-I) IN-FROM-COLUMN(LS-I)
        LS-SRC-LINE LS-MESSAGE.

*> The sorted, searchable list of words in the program's environment
*> and procedure divisions, its report clauses, and the objects of
*> OCCURS DEPENDING ON.
COLLECT-NAMES.
    MOVE 0 TO WS-NAME-COUNT LS-DIVISION
    MOVE ND-FIRST(LS-PROGRAM) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "DIVN"
           AND ND-DETAIL(LS-CHILD) = "PROCEDURE"
            MOVE LS-CHILD TO LS-DIVISION
        END-IF
        *> Items the environment division names (FILE STATUS, RECORD
        *> KEY, ...) are in use even if no statement names them.
        IF ND-KIND(LS-CHILD) = "DIVN"
           AND ND-DETAIL(LS-CHILD) = "ENVIRONMENT"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
                IF TK-IS-WORD(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    PERFORM ADD-NAME
                END-IF
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-DIVISION > 0
        PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-DIVISION) BY 1
                UNTIL LS-T > ND-TOK-LAST(LS-DIVISION)
            IF TK-IS-WORD(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                CALL "PLB-KW-LOOKUP" USING LS-TEXT LS-KW
                IF LS-KW = SPACE OR LS-KW = "S"
                    PERFORM ADD-NAME
                END-IF
            END-IF
        END-PERFORM
    END-IF
    *> Report clauses that name data: SOURCE, SUM, TYPE CONTROL ...,
    *> CONTROL, PRESENT WHEN.
    PERFORM VARYING LS-CLAUSE FROM LS-PROGRAM BY 1
            UNTIL LS-CLAUSE > AS-COUNT
        IF ND-TOK-FIRST(LS-CLAUSE) > ND-TOK-LAST(LS-PROGRAM)
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-CLAUSE) = "CLAU"
            EVALUATE ND-DETAIL(LS-CLAUSE)
                WHEN "SOURCE" WHEN "SUM" WHEN "TYPE" WHEN "CONTROL"
                WHEN "PRESENT"
                    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CLAUSE)
                            BY 1 UNTIL LS-T > ND-TOK-LAST(LS-CLAUSE)
                        IF TK-IS-WORD(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
                            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T
                                LS-TEXT LS-LEN
                            PERFORM ADD-NAME
                        END-IF
                    END-PERFORM
            END-EVALUATE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-ODO-TOKEN(LS-S) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS SY-ODO-TOKEN(LS-S)
                LS-TEXT LS-LEN
            PERFORM ADD-NAME
        END-IF
    END-PERFORM
    IF WS-NAME-COUNT > 1
        SORT WS-NAME ON ASCENDING KEY NM-TEXT
    END-IF.

ADD-NAME.
    IF WS-NAME-COUNT < NM-MAX
        ADD 1 TO WS-NAME-COUNT
        MOVE LS-TEXT TO NM-TEXT(WS-NAME-COUNT)
    END-IF.

LOOK-UP-NAME.
    MOVE "N" TO LS-FOUND
    IF WS-NAME-COUNT > 0
        SEARCH ALL WS-NAME
            AT END
                CONTINUE
            WHEN NM-TEXT(NM-IX) = LS-TEXT
                MOVE "Y" TO LS-FOUND
        END-SEARCH
    END-IF.

*> Report LS-S if it is unused, used by no group it belongs to, and
*> its group (if any) is used: the outermost unused item.
CONSIDER-ITEM.
    IF SY-NAME(LS-S) = SPACES OR WS-USED(LS-S) = "Y"
       OR WS-VIA-GROUP(LS-S) = "Y"
        EXIT PARAGRAPH
    END-IF
    IF SY-SECTION(LS-S) NOT = "W" AND SY-SECTION(LS-S) NOT = "L"
        EXIT PARAGRAPH
    END-IF
    *> Constants are left out: a program commonly declares a whole
    *> set of codes (OP-OPEN-INPUT, OP-OPEN-OUTPUT, ...) and uses some.
    IF SY-LEVEL(LS-S) = 88 OR SY-LEVEL(LS-S) = 66
       OR SY-CATEGORY(LS-S) = "K"
        EXIT PARAGRAPH
    END-IF
    MOVE SY-PARENT(LS-S) TO LS-P
    IF LS-P > 0
        IF WS-USED(LS-P) = "N"
            EXIT PARAGRAPH
        END-IF
    END-IF
    *> Declared in a copybook?
    MOVE SY-NAME-TOKEN(LS-S) TO LS-TOKEN
    IF TK-INCL(LS-TOKEN) > 0
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-SHARED
    IF LS-SKIP = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " is never referenced" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.

*> LS-SKIP = "Y" when the item or its record is GLOBAL or EXTERNAL.
CHECK-SHARED.
    MOVE "N" TO LS-SKIP
    *> Object and factory data: the methods use it.
    IF ND-DETAIL(SY-PROGRAM(LS-S)) = "OBJECT"
       OR ND-DETAIL(SY-PROGRAM(LS-S)) = "FACTORY"
        MOVE "Y" TO LS-SKIP
        EXIT PARAGRAPH
    END-IF
    MOVE LS-S TO LS-P
    PERFORM UNTIL LS-P = 0
        MOVE ND-FIRST(SY-NODE(LS-P)) TO LS-CHILD
        PERFORM UNTIL LS-CHILD = 0
            IF ND-KIND(LS-CHILD) = "CLAU"
               AND (ND-DETAIL(LS-CHILD) = "GLOBAL"
                    OR ND-DETAIL(LS-CHILD) = "EXTERNAL")
                MOVE "Y" TO LS-SKIP
                EXIT PERFORM
            END-IF
            MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
        END-PERFORM
        MOVE SY-PARENT(LS-P) TO LS-P
    END-PERFORM.
END PROGRAM PLB-RULE-M003.
