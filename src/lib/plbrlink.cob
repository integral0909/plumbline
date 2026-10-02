*> ---------------------------------------------------------------
*> plbrlink: LINKAGE SECTION items.
*>
*>   PLB-C034  linkage-not-addressed
*>
*> A LINKAGE SECTION record has no storage of its own: the caller
*> passes it (PROCEDURE DIVISION USING, ENTRY ... USING), or the
*> program gives it an address (SET ADDRESS OF item TO pointer, EXEC
*> CICS ... SET(ADDRESS OF item), ALLOCATE). A record that a statement
*> uses without either has no address, and the program reads or writes
*> wherever that happens to point, or ends abnormally. In a program
*> with EXEC CICS, DFHEIBLK and DFHCOMMAREA are passed by CICS.
*> Constants (level 78) take no storage and need no address. A BASED
*> record is in the same case: it has no storage until ALLOCATE or SET
*> ADDRESS OF gives it some.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-LINKAGE.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Per symbol: "Y" when its record has an address.
01  WS-ADDRESSED            PIC X OCCURS 100000 TIMES.
*> Per symbol: "Y" once its record was reported.
01  WS-REPORTED             PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-RECORD               PIC 9(9) COMP-5.
01  LS-CICS                 PIC X VALUE "N".
01  LS-BASED                PIC X.
01  LS-AFTER-USING          PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C034" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR SY-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE "N" TO WS-ADDRESSED(LS-S) WS-REPORTED(LS-S)
    END-PERFORM
    *> What gives records their address.
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        EVALUATE ND-KIND(LS-NODE)
            WHEN "USNG"
                PERFORM MARK-PARAMETER
            WHEN "STMT"
                EVALUATE ND-DETAIL(LS-NODE)
                    WHEN "ENTRY"
                        PERFORM MARK-ENTRY-PARAMETERS
                    WHEN "ALLOCATE"
                        PERFORM MARK-ALLOCATED
                END-EVALUATE
                PERFORM MARK-ADDRESS-OF
                IF ND-DETAIL(LS-NODE) = "EXEC"
                    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD
                        LS-LEN
                    IF LS-WORD = "CICS"
                        MOVE "Y" TO LS-CICS
                    END-IF
                END-IF
        END-EVALUATE
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    IF LS-CICS = "Y"
        PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
            IF SY-NAME(LS-S) = "DFHCOMMAREA" OR SY-NAME(LS-S) = "DFHEIBLK"
                MOVE LS-S TO LS-RECORD
                PERFORM MARK-RECORD
            END-IF
        END-PERFORM
    END-IF
    *> Statements that use a record without an address.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-STMT(LS-R) > 0
            MOVE RF-SYMBOL(LS-R) TO LS-S
            PERFORM RECORD-OF-S
            PERFORM TEST-BASED
            IF (SY-SECTION(LS-RECORD) = "K" OR LS-BASED = "Y")
               AND WS-ADDRESSED(LS-RECORD) = "N"
               AND WS-REPORTED(LS-RECORD) = "N"
               AND SY-LEVEL(LS-RECORD) NOT = 66
               AND SY-LEVEL(LS-RECORD) NOT = 78
               AND SY-CATEGORY(LS-RECORD) NOT = "K"
                MOVE "Y" TO WS-REPORTED(LS-RECORD)
                PERFORM REPORT-RECORD
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-RECORD = the record of item LS-S, and the record that one
*> redefines, if it does.
RECORD-OF-S.
    MOVE LS-S TO LS-RECORD
    PERFORM UNTIL SY-PARENT(LS-RECORD) = 0
        MOVE SY-PARENT(LS-RECORD) TO LS-RECORD
    END-PERFORM
    PERFORM UNTIL SY-REDEFINES(LS-RECORD) = 0
        MOVE SY-REDEFINES(LS-RECORD) TO LS-RECORD
    END-PERFORM.

*> LS-BASED = "Y" when record LS-RECORD has a BASED clause.
TEST-BASED.
    MOVE "N" TO LS-BASED
    MOVE ND-FIRST(SY-NODE(LS-RECORD)) TO LS-T
    PERFORM UNTIL LS-T = 0
        IF ND-KIND(LS-T) = "CLAU" AND ND-DETAIL(LS-T) = "BASED"
            MOVE "Y" TO LS-BASED
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-T) TO LS-T
    END-PERFORM.

MARK-RECORD.
    MOVE LS-RECORD TO LS-S
    PERFORM RECORD-OF-S
    MOVE "Y" TO WS-ADDRESSED(LS-RECORD).

*> The item of reference LS-K, when there is one, gets its address.
MARK-REFERENCE.
    IF LS-K > 0
        IF RF-KIND(LS-K) = "D"
            MOVE RF-SYMBOL(LS-K) TO LS-RECORD
            PERFORM MARK-RECORD
        END-IF
    END-IF.

*> PROCEDURE DIVISION USING (or CHAINING) item.
MARK-PARAMETER.
    MOVE ND-NAME(LS-NODE) TO LS-T
    PERFORM REFERENCE-AT-T
    PERFORM MARK-REFERENCE.

*> ENTRY "name" USING items.
MARK-ENTRY-PARAMETERS.
    MOVE "N" TO LS-AFTER-USING
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "USING"
                MOVE "Y" TO LS-AFTER-USING
            ELSE
                IF LS-AFTER-USING = "Y"
                    PERFORM REFERENCE-AT-T
                    PERFORM MARK-REFERENCE
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> ADDRESS OF item, in any statement: SET ADDRESS OF and EXEC ...
*> SET(ADDRESS OF) give the address; a CALL passing ADDRESS OF lets
*> another program give it, and a test of ADDRESS OF against NULL
*> shows the program knows it may have none.
MARK-ADDRESS-OF.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T + 2 > ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "ADDRESS"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-WORD
                    LS-LEN
                IF LS-WORD = "OF"
                    *> plumbline: ignore varying-control-changed -- steps past the tokens just read
                    ADD 2 TO LS-T
                    PERFORM REFERENCE-AT-T
                    PERFORM MARK-REFERENCE
                    *> plumbline: ignore varying-control-changed -- steps past the tokens just read
                    SUBTRACT 2 FROM LS-T
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> ALLOCATE item: GnuCOBOL and IBM give it storage.
MARK-ALLOCATED.
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM REFERENCE-AT-T
    PERFORM MARK-REFERENCE.

*> LS-K = the reference that starts at token LS-T, or 0.
REFERENCE-AT-T.
    MOVE 0 TO LS-K
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-T
            MOVE LS-R TO LS-K
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-RECORD.
    MOVE SPACES TO LS-MESSAGE
    IF LS-BASED = "Y"
        STRING "BASED record " DELIMITED BY SIZE
               SY-NAME(LS-RECORD) DELIMITED BY SPACE
               " has no storage here: nothing ALLOCATEs it or sets"
               DELIMITED BY SIZE
               " ADDRESS OF it" DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "LINKAGE record " DELIMITED BY SIZE
               SY-NAME(LS-RECORD) DELIMITED BY SPACE
               " has no address here: it is not a USING parameter, and"
               DELIMITED BY SIZE
               " nothing sets ADDRESS OF it" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    MOVE RF-TOKEN(LS-R) TO LS-T
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-T LS-MESSAGE.
END PROGRAM PLB-RULE-LINKAGE.
