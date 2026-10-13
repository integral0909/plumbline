*> ---------------------------------------------------------------
*> plbrresp: PLB-K010 resp-not-fullword.
*>
*> An EXEC CICS command whose RESP or RESP2 names an item that is not
*> a fullword binary item:
*>
*>     01  WS-RESP     PIC S9(4) COMP.
*>         EXEC CICS READ FILE('ACCTDAT') ... RESP(WS-RESP) END-EXEC
*>
*> CICS stores the response as a fullword binary value, four bytes,
*> into the area RESP and RESP2 name (CICS Application Programming
*> Reference, "How to use the RESP and RESP2 options"). Into a halfword
*> it overwrites the two bytes after the item; into a display or
*> packed item the program reads a number that is not the response.
*> A fullword is an integer of usage BINARY, COMP, COMP-4, or COMP-5
*> that is four bytes long (PIC S9(5) to S9(9)).
*>
*> PLB-K011 length-not-halfword: the same for LENGTH, whose item CICS
*> reads or sets as a halfword binary value (two bytes, PIC S9(4)
*> COMP), as it does ITEM and NUMITEMS of the temporary storage
*> commands, and FLENGTH, a fullword. A fullword in LENGTH is read by its
*> first two bytes, which hold 0 for any length below 65536.
*>
*> PLB-K012 abstime-not-packed: ABSTIME (of ASKTIME, FORMATTIME, and
*> others), the milliseconds since 1900, which CICS gives and takes as
*> eight bytes of packed decimal, PIC S9(15) COMP-3.
*>
*> PLB-K013 interval-invalid: INTERVAL or TIME (of DELAY, START, POST,
*> ROUTE; FORMATTIME's TIME gives six characters, and is not read)
*> naming an item that is not PIC S9(7) COMP-3, four bytes of packed
*> decimal, or a number that is not hhmmss: minutes or seconds above
*> 59, as in INTERVAL(90), which is not ninety seconds.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-K010.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-LENGTH          PIC 9(4) COMP-5.
01  LS-RULE-ABSTIME         PIC 9(4) COMP-5.
01  LS-RULE-INTERVAL        PIC 9(4) COMP-5.
*> K013: the number of an INTERVAL or TIME, as hhmmss.
01  LS-HHMMSS               PIC 9(6).
01  LS-DIGITS               PIC X(31).
*> The command: DELAY, START, ... (FORMATTIME's TIME is characters).
01  LS-COMMAND              PIC X(31).
*> The size the option needs: 4 for RESP, RESP2, FLENGTH; 2 for LENGTH.
01  LS-NEEDS                PIC 9(4) COMP-5.
01  LS-NEEDS-TEXT           PIC X(40).
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-OPTION               PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-BINARY               PIC X.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
01  LS-PTR                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K010" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K011" LS-RULE-LENGTH
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K012" LS-RULE-ABSTIME
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K013" LS-RULE-INTERVAL
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-LENGTH) NOT = "Y"
        AND RL-ENABLED(LS-RULE-ABSTIME) NOT = "Y"
        AND RL-ENABLED(LS-RULE-INTERVAL) NOT = "Y") OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "EXEC"
            COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "CICS"
                PERFORM CHECK-COMMAND
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> Each RESP( or RESP2( of the command, and the item in it.
CHECK-COMMAND.
    COMPUTE LS-K = ND-TOK-FIRST(LS-NODE) + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-COMMAND LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-COMMAND) TO LS-COMMAND
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-OPTION LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-OPTION) TO LS-OPTION
            MOVE 0 TO LS-NEEDS
            EVALUATE TRUE
                WHEN (LS-OPTION = "RESP" OR LS-OPTION = "RESP2")
                     AND RL-ENABLED(LS-RULE) = "Y"
                    MOVE 4 TO LS-NEEDS
                WHEN LS-OPTION = "FLENGTH"
                     AND RL-ENABLED(LS-RULE-LENGTH) = "Y"
                    MOVE 4 TO LS-NEEDS
                WHEN (LS-OPTION = "LENGTH" OR LS-OPTION = "ITEM"
                      OR LS-OPTION = "NUMITEMS")
                     AND RL-ENABLED(LS-RULE-LENGTH) = "Y"
                    MOVE 2 TO LS-NEEDS
                WHEN LS-OPTION = "ABSTIME"
                     AND RL-ENABLED(LS-RULE-ABSTIME) = "Y"
                    MOVE 8 TO LS-NEEDS
                WHEN (LS-OPTION = "INTERVAL" OR LS-OPTION = "TIME")
                     AND RL-ENABLED(LS-RULE-INTERVAL) = "Y"
                     AND (LS-COMMAND = "DELAY" OR LS-COMMAND = "START"
                          OR LS-COMMAND = "POST" OR LS-COMMAND = "ROUTE")
                    MOVE 7 TO LS-NEEDS
            END-EVALUATE
            IF LS-NEEDS > 0
                COMPUTE LS-K = LS-T + 1
                IF TK-IS-LPAREN(LS-K)
                    ADD 1 TO LS-K
                    IF LS-NEEDS = 7 AND TK-IS-NUMBER(LS-K)
                        PERFORM CHECK-HHMMSS
                    END-IF
                    IF WS-TOKEN-REF(LS-K) > 0
                        MOVE WS-TOKEN-REF(LS-K) TO LS-R
                        PERFORM CHECK-ITEM
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> The item of reference LS-R: four bytes of binary.
CHECK-ITEM.
    IF RF-KIND(LS-R) NOT = "D" OR RF-SYMBOL(LS-R) = 0
       OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF LS-NEEDS = 8
        PERFORM CHECK-ABSTIME
        EXIT PARAGRAPH
    END-IF
    IF LS-NEEDS = 7
        PERFORM CHECK-INTERVAL
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-BINARY
    IF SY-CATEGORY(LS-S) = "9" AND SY-SCALE(LS-S) = 0
        EVALUATE SY-USAGE(LS-S)
            WHEN "BINARY" WHEN "COMP" WHEN "COMPUTATIONAL"
            WHEN "COMP-4" WHEN "COMPUTATIONAL-4" WHEN "COMP-5"
            WHEN "COMPUTATIONAL-5"
                MOVE "Y" TO LS-BINARY
        END-EVALUATE
    END-IF
    IF LS-BINARY = "Y" AND SY-SIZE(LS-S) = LS-NEEDS
        EXIT PARAGRAPH
    END-IF
    IF LS-NEEDS = 4
        MOVE "fullword binary item (PIC S9(8) COMP)" TO LS-NEEDS-TEXT
    ELSE
        MOVE "halfword binary item (PIC S9(4) COMP)" TO LS-NEEDS-TEXT
    END-IF
    MOVE SY-SIZE(LS-S) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING LS-OPTION DELIMITED BY SPACE
           " needs a " DELIMITED BY SIZE
           LS-NEEDS-TEXT DELIMITED BY "  "
           ", but " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-BINARY = "Y"
        STRING " is binary of " LS-NUM-TEXT(1:LS-NUM-LEN) " bytes"
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING " is not binary" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    IF LS-OPTION = "RESP" OR LS-OPTION = "RESP2"
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE
    ELSE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-LENGTH RF-TOKEN(LS-R)
            LS-MESSAGE
    END-IF.
*> ABSTIME item LS-S: packed decimal of 8 bytes, without decimals.
CHECK-ABSTIME.
    IF SY-CATEGORY(LS-S) = "9" AND SY-SCALE(LS-S) = 0
       AND SY-SIZE(LS-S) = 8
       AND (SY-USAGE(LS-S) = "COMP-3" OR "COMPUTATIONAL-3"
            OR "PACKED-DECIMAL")
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "ABSTIME needs a packed decimal item of 8 bytes (PIC S9(15)"
           " COMP-3), but " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           " is not one" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-ABSTIME RF-TOKEN(LS-R) LS-MESSAGE.
*> INTERVAL or TIME item LS-S: PIC S9(7) COMP-3, four bytes packed.
CHECK-INTERVAL.
    IF SY-CATEGORY(LS-S) = "9" AND SY-SCALE(LS-S) = 0
       AND SY-SIZE(LS-S) = 4
       AND (SY-USAGE(LS-S) = "COMP-3" OR "COMPUTATIONAL-3"
            OR "PACKED-DECIMAL")
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING LS-OPTION DELIMITED BY SPACE
           " needs a packed decimal item of 4 bytes (PIC S9(7) COMP-3)"
           ", but " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           " is not one" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-INTERVAL RF-TOKEN(LS-R) LS-MESSAGE.

*> The number of INTERVAL or TIME at LS-K, as hhmmss: minutes and
*> seconds from 00 to 59.
CHECK-HHMMSS.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-DIGITS LS-LEN
    IF LS-LEN = 0 OR LS-LEN > 6
        EXIT PARAGRAPH
    END-IF
    IF LS-DIGITS(1:LS-LEN) IS NOT NUMERIC
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-HHMMSS = FUNCTION NUMVAL(LS-DIGITS(1:LS-LEN))
    IF LS-HHMMSS(3:2) <= "59" AND LS-HHMMSS(5:2) <= "59"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING LS-OPTION DELIMITED BY SPACE
           "(" LS-DIGITS(1:LS-LEN) ") is read as hhmmss, "
           DELIMITED BY SIZE
           LS-HHMMSS(1:2) ":" LS-HHMMSS(3:2) ":" LS-HHMMSS(5:2)
           DELIMITED BY SIZE
           ", whose minutes or seconds are above 59" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-INTERVAL LS-K LS-MESSAGE.
END PROGRAM PLB-RULE-K010.
