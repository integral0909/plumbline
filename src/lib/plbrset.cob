*> ---------------------------------------------------------------
*> plbrset: rules about where data items get and give their values.
*>
*>   PLB-C011  read-never-set
*>   PLB-M005  set-never-read
*>
*> Both are flow-insensitive: they look at every access in the file
*> (plbacc), in any order. Accesses count for every item whose storage
*> they overlap (plbspan): setting a group sets its members, reading a
*> REDEFINES view reads the storage it redefines, and so on. VALUE
*> clauses give initial values, and items named in the environment
*> division (FILE STATUS and similar) may be set by the runtime.
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
COPY "plbacc.cpy".
*> "Y" once an item has been reported.
01  WS-REPORTED             PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE-NEVER-SET       PIC 9(4) COMP-5.
01  LS-RULE-NEVER-READ      PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C011" LS-RULE-NEVER-SET
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M005" LS-RULE-NEVER-READ
    IF RL-ENABLED(LS-RULE-NEVER-SET) NOT = "Y"
       AND RL-ENABLED(LS-RULE-NEVER-READ) NOT = "Y"
        GOBACK
    END-IF
    IF SY-COUNT = 0
        GOBACK
    END-IF
    CALL "PLB-ACCESS-BUILD" USING PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-SPANS PLB-ACCESSES PLB-ACCESS-INDEX
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE "N" TO WS-REPORTED(LS-S)
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D"
            MOVE RF-SYMBOL(LS-R) TO LS-S
            IF AX-CHECKED(LS-S) = "Y" AND WS-REPORTED(LS-S) = "N"
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

*> PLB-C011: read, yet nothing sets it or any storage it shares.
CHECK-NEVER-SET.
    IF RL-ENABLED(LS-RULE-NEVER-SET) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-ACCESS-FIND" USING PLB-SPANS PLB-ACCESSES
        PLB-ACCESS-INDEX LS-S "DBXV" LS-FOUND
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
    CALL "PLB-ACCESS-FIND" USING PLB-SPANS PLB-ACCESSES
        PLB-ACCESS-INDEX LS-S "UBX" LS-FOUND
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
