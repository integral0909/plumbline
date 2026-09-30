*> ---------------------------------------------------------------
*> plbrset: rules about where data items get and give their values.
*>
*>   PLB-C011  read-never-set
*>   PLB-M005  set-never-read
*>
*> Both are flow-insensitive: they look at every access in the
*> program, in any order. An access is a data reference with its role
*> (plbrole), or a VALUE clause, which gives an item its initial value.
*> Accesses count for every item whose storage they overlap
*> (plbspan): setting a group sets its members, reading a REDEFINES
*> view reads the storage it redefines, and so on.
*>
*> Items named in the environment division (FILE STATUS, RECORD KEY,
*> and so on) are set by the runtime, so a mention there counts as an
*> access that may set them.
*>
*> Only working-storage and local-storage items are checked. Items in
*> the linkage and file sections get their values from callers and
*> files, and EXTERNAL, GLOBAL, and BASED items from other programs or
*> addresses.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SET-AND-READ.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbspan.cpy".
78  AC-MAX                      VALUE 300000.
*> Every access, sorted by storage root.
01  WS-ACCESSES.
    05  WS-ACCESS-COUNT     PIC 9(9) COMP-5.
    05  WS-ACCESS           OCCURS 0 TO AC-MAX TIMES
                            DEPENDING ON WS-ACCESS-COUNT.
        10  AC-ROOT         PIC 9(9) COMP-5.
        10  AC-SYMBOL       PIC 9(9) COMP-5.
        *> A reference's role (U D B X), or V for a VALUE clause.
        10  AC-ROLE         PIC X.
*> First and last access of each root (0 when it has none).
01  WS-ROOT-FIRST           PIC 9(9) COMP-5 OCCURS 100000 TIMES.
01  WS-ROOT-LAST            PIC 9(9) COMP-5 OCCURS 100000 TIMES.
*> Per symbol: "Y" once reported, and whether it is checked at all.
01  WS-REPORTED             PIC X OCCURS 100000 TIMES.
01  WS-CHECKED              PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE-NEVER-SET       PIC 9(4) COMP-5.
01  LS-RULE-NEVER-READ      PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-OVERLAP              PIC X.
01  LS-WANTED               PIC X(5).
01  LS-MESSAGE              PIC X(200).
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-ROOT-NODE            PIC 9(9) COMP-5 VALUE 1.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C011" LS-RULE-NEVER-SET
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M005" LS-RULE-NEVER-READ
    IF RL-ENABLED(LS-RULE-NEVER-SET) NOT = "Y"
       AND RL-ENABLED(LS-RULE-NEVER-READ) NOT = "Y"
        GOBACK
    END-IF
    IF SY-COUNT = 0
        GOBACK
    END-IF
    CALL "PLB-SPAN-BUILD" USING PLB-SYMBOLS PLB-SPANS
    PERFORM COLLECT-ACCESSES
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE "N" TO WS-REPORTED(LS-S)
        PERFORM DECIDE-CHECKED
    END-PERFORM

    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D"
            MOVE RF-SYMBOL(LS-R) TO LS-S
            IF WS-CHECKED(LS-S) = "Y" AND WS-REPORTED(LS-S) = "N"
                EVALUATE RF-ROLE(LS-R)
                    WHEN "U"
                        PERFORM CHECK-NEVER-SET
                    WHEN "D"
                        PERFORM CHECK-NEVER-READ
                END-EVALUATE
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> All accesses, sorted by root, with the range of each root.
COLLECT-ACCESSES.
    MOVE 0 TO WS-ACCESS-COUNT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND WS-ACCESS-COUNT < AC-MAX
            ADD 1 TO WS-ACCESS-COUNT
            MOVE RF-SYMBOL(LS-R) TO AC-SYMBOL(WS-ACCESS-COUNT)
            MOVE SP-ROOT(RF-SYMBOL(LS-R)) TO AC-ROOT(WS-ACCESS-COUNT)
            MOVE RF-ROLE(LS-R) TO AC-ROLE(WS-ACCESS-COUNT)
        END-IF
    END-PERFORM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-HAS-VALUE(LS-S) = "Y" AND SY-LEVEL(LS-S) NOT = 88
           AND SY-LEVEL(LS-S) NOT = 78 AND WS-ACCESS-COUNT < AC-MAX
            ADD 1 TO WS-ACCESS-COUNT
            MOVE LS-S TO AC-SYMBOL(WS-ACCESS-COUNT)
            MOVE SP-ROOT(LS-S) TO AC-ROOT(WS-ACCESS-COUNT)
            MOVE "V" TO AC-ROLE(WS-ACCESS-COUNT)
        END-IF
    END-PERFORM
    PERFORM ENVIRONMENT-MENTIONS
    IF WS-ACCESS-COUNT > 1
        SORT WS-ACCESS ON ASCENDING KEY AC-ROOT
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE 0 TO WS-ROOT-FIRST(LS-S) WS-ROOT-LAST(LS-S)
    END-PERFORM
    PERFORM VARYING LS-A FROM 1 BY 1 UNTIL LS-A > WS-ACCESS-COUNT
        MOVE AC-ROOT(LS-A) TO LS-ROOT
        IF WS-ROOT-FIRST(LS-ROOT) = 0
            MOVE LS-A TO WS-ROOT-FIRST(LS-ROOT)
        END-IF
        MOVE LS-A TO WS-ROOT-LAST(LS-ROOT)
    END-PERFORM.

*> Each data item named in an environment division may be set by the
*> runtime: an X access.
ENVIRONMENT-MENTIONS.
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "PROG"
            MOVE LS-NODE TO LS-PROGRAM
        END-IF
        IF ND-KIND(LS-NODE) = "DIVN"
           AND ND-DETAIL(LS-NODE) = "ENVIRONMENT"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-NODE)
                IF TK-IS-WORD(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    PERFORM MENTION-NAME
                END-IF
            END-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT-NODE LS-NODE LS-DEPTH
    END-PERFORM.

MENTION-NAME.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME(LS-S) = LS-TEXT AND SY-PROGRAM(LS-S) = LS-PROGRAM
           AND WS-ACCESS-COUNT < AC-MAX
            ADD 1 TO WS-ACCESS-COUNT
            MOVE LS-S TO AC-SYMBOL(WS-ACCESS-COUNT)
            MOVE SP-ROOT(LS-S) TO AC-ROOT(WS-ACCESS-COUNT)
            MOVE "X" TO AC-ROLE(WS-ACCESS-COUNT)
        END-IF
    END-PERFORM.

*> Working-storage and local-storage items that are not shared with
*> other programs and are not constants.
DECIDE-CHECKED.
    MOVE "N" TO WS-CHECKED(LS-S)
    IF SY-SECTION(LS-S) NOT = "W" AND SY-SECTION(LS-S) NOT = "L"
        EXIT PARAGRAPH
    END-IF
    IF SY-LEVEL(LS-S) = 78 OR SY-LEVEL(LS-S) = 66
        EXIT PARAGRAPH
    END-IF
    MOVE LS-S TO LS-A
    PERFORM UNTIL LS-A = 0
        MOVE ND-FIRST(SY-NODE(LS-A)) TO LS-C
        PERFORM UNTIL LS-C = 0
            IF ND-KIND(LS-C) = "CLAU"
               AND (ND-DETAIL(LS-C) = "EXTERNAL"
                    OR ND-DETAIL(LS-C) = "GLOBAL"
                    OR ND-DETAIL(LS-C) = "BASED")
                EXIT PARAGRAPH
            END-IF
            MOVE ND-NEXT(LS-C) TO LS-C
        END-PERFORM
        MOVE SY-PARENT(LS-A) TO LS-A
    END-PERFORM
    MOVE "Y" TO WS-CHECKED(LS-S).

*> LS-FOUND = "Y" when an access with a role in LS-WANTED overlaps
*> symbol LS-S.
FIND-ACCESS.
    MOVE "N" TO LS-FOUND
    MOVE SP-ROOT(LS-S) TO LS-ROOT
    IF WS-ROOT-FIRST(LS-ROOT) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-A FROM WS-ROOT-FIRST(LS-ROOT) BY 1
            UNTIL LS-A > WS-ROOT-LAST(LS-ROOT)
        IF LS-WANTED(1:1) = AC-ROLE(LS-A) OR LS-WANTED(2:1) = AC-ROLE(LS-A)
           OR LS-WANTED(3:1) = AC-ROLE(LS-A)
           OR LS-WANTED(4:1) = AC-ROLE(LS-A)
            CALL "PLB-SPAN-OVERLAP" USING PLB-SPANS LS-S AC-SYMBOL(LS-A)
                LS-OVERLAP
            IF LS-OVERLAP = "Y"
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> PLB-C011: read, yet nothing sets it or any storage it shares.
CHECK-NEVER-SET.
    IF RL-ENABLED(LS-RULE-NEVER-SET) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "DBXV " TO LS-WANTED
    PERFORM FIND-ACCESS
    IF LS-FOUND = "N"
        MOVE "Y" TO WS-REPORTED(LS-S)
        MOVE SPACES TO LS-MESSAGE
        STRING SY-NAME(LS-S) DELIMITED BY SPACE
               " is read but never given a value" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-NEVER-SET RF-TOKEN(LS-R)
            LS-MESSAGE
    END-IF.

*> PLB-M005: given a value, yet nothing reads it or any storage it
*> shares.
CHECK-NEVER-READ.
    IF RL-ENABLED(LS-RULE-NEVER-READ) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "UBX  " TO LS-WANTED
    PERFORM FIND-ACCESS
    IF LS-FOUND = "N"
        MOVE "Y" TO WS-REPORTED(LS-S)
        MOVE SPACES TO LS-MESSAGE
        STRING SY-NAME(LS-S) DELIMITED BY SPACE
               " is given a value but never read" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-NEVER-READ RF-TOKEN(LS-R)
            LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-SET-AND-READ.
