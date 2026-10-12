*> ---------------------------------------------------------------
*> plbrsorted: PLB-C100 table-keys-unsorted.
*>
*> A table that SEARCH ALL looks in, filled by VALUE clauses, whose
*> keys are not in the order its KEY phrase gives:
*>
*>     01  WS-VALUES.
*>         05  FILLER PIC X(7) VALUE "01ALPHA".
*>         05  FILLER PIC X(7) VALUE "05BETA ".
*>         05  FILLER PIC X(7) VALUE "03GAMMA".     before 05
*>     01  WS-TABLE REDEFINES WS-VALUES.
*>         05  WS-ENTRY OCCURS 3 ASCENDING KEY WS-CODE
*>                      INDEXED BY WS-IX.
*>             10  WS-CODE  PIC X(2).
*>             10  WS-NAME  PIC X(5).
*>
*> SEARCH ALL is a binary search: it trusts the order, and in a table
*> out of order it misses entries that are there (with GnuCOBOL 3.2,
*> the one above does not find 05). The start value of the table is
*> rebuilt from the VALUE clauses of the item it redefines: literals
*> of alphanumeric items, and unsigned numbers of DISPLAY items. Keys
*> are compared on their first KEY name as characters, and a pair is
*> reported only when it is out of order both in ASCII and in EBCDIC,
*> whose orders of letters, digits, and signs differ; a key with a
*> character neither order is known for here is not compared. Tables
*> with OCCURS DEPENDING ON, and keys some VALUE does not cover, are
*> not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C100.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  IMAGE-MAX               VALUE 32000.
*> The start bytes of the item the table redefines, and which of them
*> a VALUE gives.
01  WS-IMAGE                PIC X(32000).
01  WS-KNOWN                PIC X(32000).
*> The tables already checked.
01  WS-DONE-COUNT           PIC 9(4) COMP-5.
01  WS-DONE                 PIC 9(9) COMP-5 OCCURS 256 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-TABLE                PIC 9(9) COMP-5.
01  LS-KEY                  PIC 9(9) COMP-5.
01  LS-AREA                 PIC 9(9) COMP-5.
01  LS-BASE                 PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-PREV-AT              PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-KEY-NAME             PIC X(31).
01  LS-ORDER                PIC X.
01  LS-OK                   PIC X.
01  LS-CMP-ASCII            PIC S9 COMP-5.
01  LS-CMP-EBCDIC           PIC S9 COMP-5.
01  LS-W1                   PIC 9(4) COMP-5.
01  LS-W2                   PIC 9(4) COMP-5.
01  LS-CH                   PIC X.
01  LS-WEIGHT               PIC 9(4) COMP-5.
01  LS-VALUE                PIC X(256).
01  LS-VALUE-LEN            PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-1                PIC X(20).
01  LS-NUM-1-LEN            PIC 9(9) COMP-5.
01  LS-NUM-2                PIC X(20).
01  LS-NUM-2-LEN            PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C100" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 0 TO WS-DONE-COUNT
    *> Each SEARCH ALL: the table it names, once.
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "SEARCH"
            COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "ALL"
                ADD 1 TO LS-T
                PERFORM TABLE-AT
                IF LS-TABLE > 0
                    PERFORM VARYING LS-I FROM 1 BY 1
                            UNTIL LS-I > WS-DONE-COUNT
                        IF WS-DONE(LS-I) = LS-TABLE
                            MOVE 0 TO LS-TABLE
                            EXIT PERFORM
                        END-IF
                    END-PERFORM
                END-IF
                IF LS-TABLE > 0 AND WS-DONE-COUNT < 256
                    ADD 1 TO WS-DONE-COUNT
                    MOVE LS-TABLE TO WS-DONE(WS-DONE-COUNT)
                    PERFORM CHECK-TABLE
                END-IF
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-TABLE: the item named at token LS-T, or 0.
TABLE-AT.
    MOVE 0 TO LS-TABLE
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > RF-COUNT
        IF RF-TOKEN(LS-K) = LS-T
            IF RF-KIND(LS-K) = "D" AND RF-SYMBOL(LS-K) > 0
                MOVE RF-SYMBOL(LS-K) TO LS-TABLE
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Table LS-TABLE: its key, the area it redefines, and the keys of
*> the start value in order.
CHECK-TABLE.
    IF SY-OCCURS(LS-TABLE) < 2 OR SY-ODO-TOKEN(LS-TABLE) > 0
       OR SY-SIZE(LS-TABLE) = 0 OR SY-NODE(LS-TABLE) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-KEY
    IF LS-KEY = 0
        EXIT PARAGRAPH
    END-IF
    *> The nearest group around the table that redefines another item.
    MOVE LS-TABLE TO LS-UP
    MOVE 0 TO LS-AREA
    PERFORM UNTIL LS-UP = 0
        IF SY-REDEFINES(LS-UP) > 0
            MOVE SY-REDEFINES(LS-UP) TO LS-AREA
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF LS-AREA = 0
        EXIT PARAGRAPH
    END-IF
    IF SY-SIZE(LS-AREA) = 0 OR SY-SIZE(LS-AREA) > IMAGE-MAX
        EXIT PARAGRAPH
    END-IF
    *> The table must lie inside the area.
    IF SY-OFFSET(LS-TABLE) < SY-OFFSET(LS-AREA)
       OR SY-OFFSET(LS-TABLE) + SY-SIZE(LS-TABLE) * SY-OCCURS(LS-TABLE)
          > SY-OFFSET(LS-AREA) + SY-SIZE(LS-AREA)
        EXIT PARAGRAPH
    END-IF
    PERFORM BUILD-IMAGE
    *> Each key against the one before it.
    PERFORM VARYING LS-I FROM 2 BY 1 UNTIL LS-I > SY-OCCURS(LS-TABLE)
        COMPUTE LS-AT = SY-OFFSET(LS-KEY) - SY-OFFSET(LS-AREA)
            + (LS-I - 1) * SY-SIZE(LS-TABLE) + 1
        COMPUTE LS-PREV-AT = LS-AT - SY-SIZE(LS-TABLE)
        IF WS-KNOWN(LS-AT:SY-SIZE(LS-KEY)) NOT = ALL "Y"
           OR WS-KNOWN(LS-PREV-AT:SY-SIZE(LS-KEY)) NOT = ALL "Y"
            EXIT PARAGRAPH
        END-IF
        PERFORM COMPARE-KEYS
        IF LS-OK = "N"
            EXIT PARAGRAPH
        END-IF
        IF (LS-ORDER = "A" AND LS-CMP-ASCII < 0 AND LS-CMP-EBCDIC < 0)
           OR (LS-ORDER = "D" AND LS-CMP-ASCII > 0
               AND LS-CMP-EBCDIC > 0)
            PERFORM REPORT-UNSORTED
            EXIT PARAGRAPH
        END-IF
    END-PERFORM.

*> LS-KEY and LS-ORDER: the first key of the table's OCCURS clause, an
*> item in the table entry; 0 when there is none.
READ-KEY.
    MOVE 0 TO LS-KEY
    MOVE SPACES TO LS-KEY-NAME LS-ORDER
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(SY-NODE(LS-TABLE)) BY 1
            UNTIL LS-T >= ND-TOK-LAST(SY-NODE(LS-TABLE))
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "ASCENDING" OR LS-WORD = "DESCENDING"
                MOVE LS-WORD(1:1) TO LS-ORDER
                MOVE LS-T TO LS-K
                PERFORM UNTIL LS-K >= ND-TOK-LAST(SY-NODE(LS-TABLE))
                    ADD 1 TO LS-K
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD
                        LS-LEN
                    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
                    IF LS-WORD NOT = "KEY" AND LS-WORD NOT = "IS"
                        MOVE LS-WORD TO LS-KEY-NAME
                        EXIT PERFORM
                    END-IF
                END-PERFORM
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-KEY-NAME = SPACES
        EXIT PARAGRAPH
    END-IF
    *> The item of that name under the table.
    PERFORM VARYING LS-S FROM LS-TABLE BY 1 UNTIL LS-S > SY-COUNT
        IF LS-S > LS-TABLE
            MOVE SY-PARENT(LS-S) TO LS-UP
            PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-TABLE
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
            IF LS-UP = 0
                EXIT PERFORM
            END-IF
            IF FUNCTION UPPER-CASE(SY-NAME(LS-S)) = LS-KEY-NAME
                IF SY-OCCURS(LS-S) = 0 AND SY-SIZE(LS-S) > 0
                    MOVE LS-S TO LS-KEY
                END-IF
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> WS-IMAGE and WS-KNOWN: the start bytes of item LS-AREA that the
*> VALUE clauses of its items give.
BUILD-IMAGE.
    MOVE SPACES TO WS-IMAGE(1:SY-SIZE(LS-AREA))
    MOVE ALL "N" TO WS-KNOWN(1:SY-SIZE(LS-AREA))
    MOVE SY-OFFSET(LS-AREA) TO LS-BASE
    PERFORM VARYING LS-D FROM LS-AREA BY 1 UNTIL LS-D > SY-COUNT
        IF LS-D > LS-AREA
            MOVE SY-PARENT(LS-D) TO LS-UP
            PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-AREA
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
            IF LS-UP = 0
                EXIT PERFORM
            END-IF
        END-IF
        IF SY-HAS-VALUE(LS-D) = "Y" AND SY-OCCURS(LS-D) = 0
           AND SY-CATEGORY(LS-D) NOT = "C"
            PERFORM PLACE-VALUE
        END-IF
    END-PERFORM.

*> The VALUE of item LS-D into the image, when it is a literal the
*> item holds as written: alphanumeric text for an alphanumeric item
*> (cut or padded with spaces), or an unsigned integer for a DISPLAY
*> numeric item without decimal places (with leading zeros).
PLACE-VALUE.
    MOVE ND-FIRST(SY-NODE(LS-D)) TO LS-N
    PERFORM UNTIL LS-N = 0
        IF ND-KIND(LS-N) = "CLAU" AND ND-DETAIL(LS-N) = "VALUE"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-N) TO LS-N
    END-PERFORM
    IF LS-N = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-LAST(LS-N) TO LS-T
    COMPUTE LS-AT = SY-OFFSET(LS-D) - LS-BASE + 1
    IF LS-AT < 1 OR LS-AT + SY-SIZE(LS-D) - 1 > SY-SIZE(LS-AREA)
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
             AND (SY-CATEGORY(LS-D) = "X" OR SY-CATEGORY(LS-D) = "A")
             AND TK-PREFIX(LS-T) = SPACES
            MOVE SPACES TO LS-VALUE
            MOVE TK-TEXT-LEN(LS-T) TO LS-VALUE-LEN
            IF LS-VALUE-LEN > 256
                EXIT PARAGRAPH
            END-IF
            IF LS-VALUE-LEN > 0
                MOVE TK-TEXT(TK-TEXT-OFF(LS-T):LS-VALUE-LEN) TO LS-VALUE
            END-IF
            IF SY-SIZE(LS-D) > 256
                EXIT PARAGRAPH
            END-IF
            MOVE LS-VALUE(1:SY-SIZE(LS-D))
                TO WS-IMAGE(LS-AT:SY-SIZE(LS-D))
            MOVE ALL "Y" TO WS-KNOWN(LS-AT:SY-SIZE(LS-D))
        WHEN TK-IS-NUMBER(LS-T) AND SY-CATEGORY(LS-D) = "9"
             AND SY-SCALE(LS-D) = 0 AND SY-SIGNED(LS-D) NOT = "Y"
             AND (SY-USAGE(LS-D) = SPACES
                  OR SY-USAGE(LS-D) = "DISPLAY")
             AND SY-SIZE(LS-D) = SY-DIGITS(LS-D)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-LEN = 0 OR LS-LEN > SY-SIZE(LS-D)
                EXIT PARAGRAPH
            END-IF
            IF LS-WORD(1:LS-LEN) IS NOT NUMERIC
                EXIT PARAGRAPH
            END-IF
            MOVE ALL "0" TO WS-IMAGE(LS-AT:SY-SIZE(LS-D))
            COMPUTE LS-J = LS-AT + SY-SIZE(LS-D) - LS-LEN
            MOVE LS-WORD(1:LS-LEN) TO WS-IMAGE(LS-J:LS-LEN)
            MOVE ALL "Y" TO WS-KNOWN(LS-AT:SY-SIZE(LS-D))
    END-EVALUATE.

*> LS-CMP-ASCII and LS-CMP-EBCDIC: -1, 0, or 1 as the key at LS-AT is
*> below, equal to, or above the one at LS-PREV-AT; LS-OK = "N" when
*> a character has no EBCDIC place here.
COMPARE-KEYS.
    MOVE "Y" TO LS-OK
    MOVE 0 TO LS-CMP-ASCII LS-CMP-EBCDIC
    PERFORM VARYING LS-J FROM 0 BY 1 UNTIL LS-J >= SY-SIZE(LS-KEY)
        IF WS-IMAGE(LS-AT + LS-J:1) NOT = WS-IMAGE(LS-PREV-AT + LS-J:1)
            IF LS-CMP-ASCII = 0
                IF WS-IMAGE(LS-AT + LS-J:1)
                   < WS-IMAGE(LS-PREV-AT + LS-J:1)
                    MOVE -1 TO LS-CMP-ASCII
                ELSE
                    MOVE 1 TO LS-CMP-ASCII
                END-IF
            END-IF
            IF LS-CMP-EBCDIC = 0
                MOVE WS-IMAGE(LS-AT + LS-J:1) TO LS-CH
                PERFORM EBCDIC-WEIGHT
                MOVE LS-WEIGHT TO LS-W1
                MOVE WS-IMAGE(LS-PREV-AT + LS-J:1) TO LS-CH
                PERFORM EBCDIC-WEIGHT
                MOVE LS-WEIGHT TO LS-W2
                IF LS-W1 = 0 OR LS-W2 = 0
                    MOVE "N" TO LS-OK
                    EXIT PARAGRAPH
                END-IF
                IF LS-W1 < LS-W2
                    MOVE -1 TO LS-CMP-EBCDIC
                ELSE
                    MOVE 1 TO LS-CMP-EBCDIC
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> LS-WEIGHT: the EBCDIC code of LS-CH (code page 037), for space,
*> letters, digits, and common signs; 0 for any other.
EBCDIC-WEIGHT.
    MOVE 0 TO LS-WEIGHT
    EVALUATE TRUE
        WHEN LS-CH = SPACE        MOVE 64 TO LS-WEIGHT
        WHEN LS-CH = "."          MOVE 75 TO LS-WEIGHT
        WHEN LS-CH = "("          MOVE 77 TO LS-WEIGHT
        WHEN LS-CH = "+"          MOVE 78 TO LS-WEIGHT
        WHEN LS-CH = "&"          MOVE 80 TO LS-WEIGHT
        WHEN LS-CH = "$"          MOVE 91 TO LS-WEIGHT
        WHEN LS-CH = "*"          MOVE 92 TO LS-WEIGHT
        WHEN LS-CH = ")"          MOVE 93 TO LS-WEIGHT
        WHEN LS-CH = "-"          MOVE 96 TO LS-WEIGHT
        WHEN LS-CH = "/"          MOVE 97 TO LS-WEIGHT
        WHEN LS-CH = ","          MOVE 107 TO LS-WEIGHT
        WHEN LS-CH = "_"          MOVE 109 TO LS-WEIGHT
        WHEN LS-CH = ":"          MOVE 122 TO LS-WEIGHT
        WHEN LS-CH = "#"          MOVE 123 TO LS-WEIGHT
        WHEN LS-CH = "@"          MOVE 124 TO LS-WEIGHT
        WHEN LS-CH >= "a" AND LS-CH <= "i"
            COMPUTE LS-WEIGHT = 129 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("a")
        WHEN LS-CH >= "j" AND LS-CH <= "r"
            COMPUTE LS-WEIGHT = 145 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("j")
        WHEN LS-CH >= "s" AND LS-CH <= "z"
            COMPUTE LS-WEIGHT = 162 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("s")
        WHEN LS-CH >= "A" AND LS-CH <= "I"
            COMPUTE LS-WEIGHT = 193 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("A")
        WHEN LS-CH >= "J" AND LS-CH <= "R"
            COMPUTE LS-WEIGHT = 209 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("J")
        WHEN LS-CH >= "S" AND LS-CH <= "Z"
            COMPUTE LS-WEIGHT = 226 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("S")
        WHEN LS-CH >= "0" AND LS-CH <= "9"
            COMPUTE LS-WEIGHT = 240 + FUNCTION ORD(LS-CH)
                - FUNCTION ORD("0")
    END-EVALUATE.

REPORT-UNSORTED.
    MOVE LS-I TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    COMPUTE LS-NUM = LS-I - 1
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the start value of " DELIMITED BY SIZE
           SY-NAME(LS-TABLE) DELIMITED BY SPACE
           " is out of its KEY order: entry " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           ' ("' WS-IMAGE(LS-AT:SY-SIZE(LS-KEY)) '") comes after '
           DELIMITED BY SIZE
           "entry " LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           ' ("' WS-IMAGE(LS-PREV-AT:SY-SIZE(LS-KEY)) '"), and SEARCH '
           "ALL may miss entries" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(SY-NODE(LS-TABLE)) LS-MESSAGE.
END PROGRAM PLB-RULE-C100.
