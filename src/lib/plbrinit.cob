*> ---------------------------------------------------------------
*> plbrinit: PLB-C080 initialize-loses-value.
*>
*> INITIALIZE of a group with items whose VALUE clause it replaces:
*>
*>     01  HEADING-LINE.
*>         05  HL-TITLE    PIC X(12) VALUE "SALES REPORT".
*>         05  HL-PAGE     PIC ZZ9.
*>     ...
*>         INITIALIZE HEADING-LINE
*>
*> INITIALIZE gives alphanumeric items spaces and numeric items zero,
*> whatever their VALUE clause says, so HL-TITLE is blank afterwards.
*> Reported are named elementary items under the item initialized
*> whose VALUE is something INITIALIZE does not give back: not SPACE
*> for an alphanumeric item, not zero for a numeric or numeric-edited
*> one, that something reads (the item or a group it is in), and that
*> nothing else gives a value: no statement other than an INITIALIZE
*> writes the item, a group it is in, an item that redefines one of
*> those, or (by SET) one of its condition names. An item that the
*> program sets again after the INITIALIZE uses its VALUE clause as a
*> first value only, and one never read loses nothing. FILLER items
*> and items under a REDEFINES are left alone, as INITIALIZE leaves
*> them, and a statement with a VALUE phrase (... TO VALUE), which
*> gives the items their VALUE clauses, is not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C080.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> "Y" for an item that a statement other than INITIALIZE writes, and
*> for an item that a statement reads.
01  WS-WRITTEN              PIC X OCCURS 100000 TIMES.
01  WS-READ                 PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-TARGET               PIC 9(9) COMP-5.
01  LS-UNDER                PIC X.
01  LS-LOST                 PIC X.
01  LS-FIRST-LOST           PIC 9(9) COMP-5.
01  LS-LOST-COUNT           PIC 9(9) COMP-5.
01  LS-HAS-VALUE-PHRASE     PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C080" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM NOTE-WRITTEN
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-STMT(LS-R) > 0
           AND RF-SYMBOL(LS-R) > 0
            MOVE RF-STMT(LS-R) TO LS-NODE
            IF ND-DETAIL(LS-NODE) = "INITIALIZE"
                PERFORM CHECK-REFERENCE
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> WS-WRITTEN: the items written by statements other than INITIALIZE;
*> a condition name set marks its item.
NOTE-WRITTEN.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE "N" TO WS-WRITTEN(LS-S) WS-READ(LS-S)
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-STMT(LS-R) > 0
           AND RF-SYMBOL(LS-R) > 0
            IF ND-DETAIL(RF-STMT(LS-R)) NOT = "INITIALIZE"
               AND (RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
                    OR RF-ROLE(LS-R) = "X"
                    OR ND-DETAIL(RF-STMT(LS-R)) = "SET")
                MOVE RF-SYMBOL(LS-R) TO LS-S
                IF SY-CATEGORY(LS-S) = "C" AND SY-PARENT(LS-S) > 0
                    MOVE SY-PARENT(LS-S) TO LS-S
                END-IF
                MOVE "Y" TO WS-WRITTEN(LS-S)
                *> Storage that a REDEFINES shares is written too.
                MOVE LS-S TO LS-UP
                PERFORM UNTIL LS-UP = 0
                    IF SY-REDEFINES(LS-UP) > 0
                        MOVE "Y" TO WS-WRITTEN(SY-REDEFINES(LS-UP))
                    END-IF
                    MOVE SY-PARENT(LS-UP) TO LS-UP
                END-PERFORM
            END-IF
            IF RF-ROLE(LS-R) = "U" OR RF-ROLE(LS-R) = "B"
               OR RF-ROLE(LS-R) = "X"
                MOVE RF-SYMBOL(LS-R) TO LS-S
                IF SY-CATEGORY(LS-S) = "C" AND SY-PARENT(LS-S) > 0
                    MOVE SY-PARENT(LS-S) TO LS-S
                END-IF
                MOVE "Y" TO WS-READ(LS-S)
            END-IF
        END-IF
    END-PERFORM.

*> Reference LS-R in INITIALIZE statement LS-NODE: a receiver (before
*> any phrase), when the statement has no VALUE phrase.
CHECK-REFERENCE.
    MOVE "N" TO LS-HAS-VALUE-PHRASE
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "VALUE"
                    MOVE "Y" TO LS-HAS-VALUE-PHRASE
                    EXIT PERFORM
                *> The receivers end at the first phrase.
                WHEN "REPLACING" WHEN "WITH" WHEN "ALL" WHEN "THEN"
                WHEN "DEFAULT" WHEN "FILLER"
                    IF LS-T < RF-TOKEN(LS-R)
                        EXIT PARAGRAPH
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM
    IF LS-HAS-VALUE-PHRASE = "Y"
        EXIT PARAGRAPH
    END-IF
    *> A subscript or qualifier inside another receiver is no receiver.
    IF RF-ROLE(LS-R) NOT = "D"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-TARGET
    MOVE 0 TO LS-FIRST-LOST LS-LOST-COUNT
    PERFORM VARYING LS-S FROM LS-TARGET BY 1 UNTIL LS-S > SY-COUNT
        IF LS-S > LS-TARGET AND SY-LEVEL(LS-S) <= SY-LEVEL(LS-TARGET)
           AND SY-LEVEL(LS-S) NOT = 88
            EXIT PERFORM
        END-IF
        PERFORM CHECK-ITEM
    END-PERFORM
    IF LS-LOST-COUNT > 0
        PERFORM REPORT-LOSS
    END-IF.

*> Item LS-S: under the target (not through a REDEFINES), elementary,
*> named, and with a VALUE that INITIALIZE replaces.
CHECK-ITEM.
    IF SY-HAS-VALUE(LS-S) NOT = "Y" OR SY-NODE(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-S) = "G" OR SY-CATEGORY(LS-S) = "C"
       OR SY-CATEGORY(LS-S) = "K" OR SY-CATEGORY(LS-S) = "R"
       OR SY-CATEGORY(LS-S) = "U" OR SY-CATEGORY(LS-S) = "?"
        EXIT PARAGRAPH
    END-IF
    IF SY-NAME(LS-S) = SPACES OR SY-NAME(LS-S) = "FILLER"
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-UNDER
    MOVE LS-S TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF LS-UP = LS-TARGET
            MOVE "Y" TO LS-UNDER
            EXIT PERFORM
        END-IF
        IF SY-REDEFINES(LS-UP) > 0
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF LS-UNDER = "N"
        EXIT PARAGRAPH
    END-IF
    *> Given a value again: by itself, or through a group it is in;
    *> read: by itself, or through a group it is in.
    MOVE "N" TO LS-LOST
    MOVE LS-S TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF WS-WRITTEN(LS-UP) = "Y"
            EXIT PARAGRAPH
        END-IF
        IF WS-READ(LS-UP) = "Y"
            MOVE "Y" TO LS-LOST
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF LS-LOST = "N"
        EXIT PARAGRAPH
    END-IF
    PERFORM TEST-VALUE
    IF LS-LOST = "Y"
        ADD 1 TO LS-LOST-COUNT
        IF LS-FIRST-LOST = 0
            MOVE LS-S TO LS-FIRST-LOST
        END-IF
    END-IF.

*> LS-LOST = "Y" when the VALUE of item LS-S is not what INITIALIZE
*> gives it: spaces for an alphanumeric item, zero for a numeric one.
TEST-VALUE.
    MOVE "Y" TO LS-LOST
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "CLAU" AND ND-DETAIL(LS-C) = "VALUE"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM
    IF LS-C = 0
        MOVE "N" TO LS-LOST
        EXIT PARAGRAPH
    END-IF
    *> The first token after VALUE [IS], VALUES [ARE].
    MOVE ND-TOK-FIRST(LS-C) TO LS-T
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-C)
        IF NOT TK-IS-WORD(LS-T)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        IF LS-TEXT NOT = "VALUE" AND LS-TEXT NOT = "VALUES"
           AND LS-TEXT NOT = "IS" AND LS-TEXT NOT = "ARE"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-T
    END-PERFORM
    IF LS-T > ND-TOK-LAST(LS-C)
        MOVE "N" TO LS-LOST
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "SPACE" WHEN "SPACES"
                    IF SY-CATEGORY(LS-S) NOT = "9"
                       AND SY-CATEGORY(LS-S) NOT = "E"
                        MOVE "N" TO LS-LOST
                    END-IF
                WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
                    IF SY-CATEGORY(LS-S) = "9" OR SY-CATEGORY(LS-S) = "E"
                        MOVE "N" TO LS-LOST
                    END-IF
            END-EVALUATE
        WHEN TK-IS-NUMBER(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-LEN <= 18
                IF FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) = 0
                    IF FUNCTION NUMVAL(LS-TEXT(1:LS-LEN)) = 0
                        MOVE "N" TO LS-LOST
                    END-IF
                END-IF
            END-IF
        WHEN TK-IS-ALNUM(LS-T)
            IF TK-PREFIX(LS-T) = SPACES AND SY-CATEGORY(LS-S) NOT = "9"
               AND SY-CATEGORY(LS-S) NOT = "E"
                IF TK-TEXT-LEN(LS-T) = 0
                    MOVE "N" TO LS-LOST
                ELSE
                    IF TK-TEXT(TK-TEXT-OFF(LS-T):TK-TEXT-LEN(LS-T))
                       = SPACES
                        MOVE "N" TO LS-LOST
                    END-IF
                END-IF
            END-IF
    END-EVALUATE.

REPORT-LOSS.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "INITIALIZE replaces the VALUE of " DELIMITED BY SIZE
           SY-NAME(LS-FIRST-LOST) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-LOST-COUNT > 1
        COMPUTE LS-NUM = LS-LOST-COUNT - 1
        CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
        STRING " and of " LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        IF LS-NUM = 1
            STRING " other item" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        ELSE
            STRING " other items" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-IF
    END-IF
    STRING " with spaces or zeros" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C080.
