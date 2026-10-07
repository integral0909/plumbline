*> ---------------------------------------------------------------
*> plbrsetidx: PLB-C077 index-set-out-of-range.
*>
*> SET of an index to a number past the end of its table:
*>
*>     05  RATE-ENTRY  OCCURS 10 TIMES INDEXED BY RATE-IX.
*>     ...
*>         SET RATE-IX TO 11
*>
*> A reference through the index then reads or writes past the table.
*> The index is a name after INDEXED BY in the table's OCCURS clause,
*> in the same program; the number is the literal after TO. Zero is not
*> reported: an index set to 0 and stepped with SET ... UP BY 1 before
*> it is used is common. Negative numbers are.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C077.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  IX-MAX                  VALUE 4096.
01  WS-INDEXES.
    05  WS-INDEX-COUNT      PIC 9(9) COMP-5.
    05  WS-INDEX            OCCURS IX-MAX TIMES.
        10  IX-NAME         PIC X(31).
        10  IX-PROGRAM      PIC 9(9) COMP-5.
        10  IX-TABLE        PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-X                    PIC 9(9) COMP-5.
01  LS-IN-NAMES             PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-VALUE                PIC S9(18) COMP-5.
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
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C077" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 0 TO WS-INDEX-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-OCCURS(LS-S) > 0 AND SY-NODE(LS-S) > 0
           AND SY-UNBOUNDED(LS-S) NOT = "Y"
            PERFORM COLLECT-INDEXES
        END-IF
    END-PERFORM
    IF WS-INDEX-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "SET"
            PERFORM CHECK-SET
        END-IF
    END-PERFORM
    GOBACK.

*> The names after INDEXED [BY] in the OCCURS clause of table LS-S.
COLLECT-INDEXES.
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "CLAU" AND ND-DETAIL(LS-C) = "OCCURS"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM
    IF LS-C = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-IN-NAMES
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-C) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-C)
        IF NOT TK-IS-WORD(LS-T)
            MOVE "N" TO LS-IN-NAMES
        ELSE
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE TRUE
                WHEN LS-TEXT = "INDEXED"
                    MOVE "Y" TO LS-IN-NAMES
                WHEN LS-IN-NAMES = "Y" AND LS-TEXT = "BY"
                    CONTINUE
                WHEN LS-IN-NAMES = "Y" AND TK-KEYWORD(LS-T) = SPACE
                    PERFORM ADD-INDEX
                WHEN OTHER
                    MOVE "N" TO LS-IN-NAMES
            END-EVALUATE
        END-IF
    END-PERFORM.

ADD-INDEX.
    IF WS-INDEX-COUNT >= IX-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-INDEX-COUNT
    MOVE LS-TEXT TO IX-NAME(WS-INDEX-COUNT)
    MOVE SY-PROGRAM(LS-S) TO IX-PROGRAM(WS-INDEX-COUNT)
    MOVE LS-S TO IX-TABLE(WS-INDEX-COUNT).

*> SET name ... TO number: each name that is an index of the program.
CHECK-SET.
    MOVE 0 TO LS-TO
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE) OR LS-TO > 0
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "TO"
                MOVE LS-T TO LS-TO
            END-IF
        END-IF
    END-PERFORM
    *> TO and a number, the last token of the statement.
    IF LS-TO = 0 OR LS-TO + 1 NOT = ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = LS-TO + 1
    IF NOT TK-IS-NUMBER(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-LEN > 18 OR FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) NOT = 0
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
       NOT = FUNCTION INTEGER-PART(FUNCTION NUMVAL(LS-TEXT(1:LS-LEN)))
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-VALUE = FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
    *> The program the statement is in.
    MOVE ND-PARENT(LS-NODE) TO LS-PROGRAM
    PERFORM UNTIL LS-PROGRAM = 0
        IF ND-KIND(LS-PROGRAM) = "PROG"
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-PROGRAM) TO LS-PROGRAM
    END-PERFORM
    PERFORM VARYING LS-R FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-R >= LS-TO
        IF TK-IS-WORD(LS-R) AND LS-R > ND-TOK-FIRST(LS-NODE)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R LS-TEXT LS-LEN
            PERFORM VARYING LS-X FROM 1 BY 1 UNTIL LS-X > WS-INDEX-COUNT
                IF IX-NAME(LS-X) = LS-TEXT
                   AND IX-PROGRAM(LS-X) = LS-PROGRAM
                    PERFORM TEST-VALUE
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.

*> Index LS-X set to LS-VALUE, reported at its name (token LS-R).
TEST-VALUE.
    IF LS-VALUE >= 0 AND LS-VALUE <= SY-OCCURS(IX-TABLE(LS-X))
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING IX-NAME(LS-X) DELIMITED BY SPACE
           " is an index of " DELIMITED BY SIZE
           SY-NAME(IX-TABLE(LS-X)) DELIMITED BY SPACE
           ", which has " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE SY-OCCURS(IX-TABLE(LS-X)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) " entries; set to " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-VALUE TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) ", it points outside the table"
           DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-R LS-MESSAGE.
END PROGRAM PLB-RULE-C077.
