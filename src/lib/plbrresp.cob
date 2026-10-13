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
*>
*> PLB-K015 time-option-out-of-range: HOURS, MINUTES, SECONDS, or
*> MILLISECS of DELAY (FOR, UNTIL) or START (AFTER, AT) given a number
*> outside its range, for which CICS raises INVREQ (RESP2 4, 5, 6, or
*> 22): HOURS 0-99; MINUTES 0-59 with another of them, or 0-5999 alone;
*> SECONDS 0-59, or 0-359999 alone; MILLISECS (of DELAY) 0-999, or
*> 0-359999999 alone (CICS API reference, DELAY and START).
*>
*> PLB-K017 tsq-option-invalid: a WRITEQ TS with REWRITE and no ITEM
*> ("If the REWRITE option is specified, the ITEM option must also be
*> specified"), or with a LENGTH given as a number that is 0 or above
*> 32763, "the maximum length" (CICS API reference, WRITEQ TS).
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
01  LS-RULE-UNITS           PIC 9(4) COMP-5.
01  LS-RULE-TSQ             PIC 9(4) COMP-5.
*> K017: what the WRITEQ TS codes.
01  LS-TS                   PIC X.
01  LS-REWRITE              PIC 9(9) COMP-5.
01  LS-ITEM-CODED           PIC X.
01  LS-LENGTH-AT            PIC 9(9) COMP-5.
*> K015: how many of HOURS, MINUTES, SECONDS, MILLISECS the command
*> has, and the range of the one being read.
01  LS-UNITS                PIC 9(4) COMP-5.
01  LS-MOST                 PIC 9(9) COMP-5.
01  LS-RESP2                PIC X(2).
01  LS-VALUE                PIC 9(18).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K015" LS-RULE-UNITS
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K017" LS-RULE-TSQ
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-LENGTH) NOT = "Y"
        AND RL-ENABLED(LS-RULE-ABSTIME) NOT = "Y"
        AND RL-ENABLED(LS-RULE-INTERVAL) NOT = "Y"
        AND RL-ENABLED(LS-RULE-UNITS) NOT = "Y"
        AND RL-ENABLED(LS-RULE-TSQ) NOT = "Y") OR AS-COUNT = 0
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
    IF (LS-COMMAND = "DELAY" OR LS-COMMAND = "START")
       AND RL-ENABLED(LS-RULE-UNITS) = "Y"
        PERFORM CHECK-UNITS
    END-IF
    IF LS-COMMAND = "WRITEQ" AND RL-ENABLED(LS-RULE-TSQ) = "Y"
        PERFORM CHECK-WRITEQ-TS
    END-IF
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

*> K015: HOURS, MINUTES, SECONDS, and MILLISECS of the command, counted,
*> then each given as a number checked against its range.
CHECK-UNITS.
    MOVE 0 TO LS-UNITS
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-OPTION LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-OPTION) TO LS-OPTION
            IF LS-OPTION = "HOURS" OR LS-OPTION = "MINUTES"
               OR LS-OPTION = "SECONDS" OR LS-OPTION = "MILLISECS"
                ADD 1 TO LS-UNITS
            END-IF
        END-IF
    END-PERFORM
    IF LS-UNITS = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T + 2 > ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T) AND TK-IS-LPAREN(LS-T + 1)
           AND TK-IS-NUMBER(LS-T + 2)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-OPTION LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-OPTION) TO LS-OPTION
            MOVE 0 TO LS-MOST
            EVALUATE TRUE
                WHEN LS-OPTION = "HOURS"
                    MOVE 99 TO LS-MOST
                    MOVE "4" TO LS-RESP2
                WHEN LS-OPTION = "MINUTES"
                    MOVE 5999 TO LS-MOST
                    MOVE "5" TO LS-RESP2
                WHEN LS-OPTION = "SECONDS"
                    MOVE 359999 TO LS-MOST
                    MOVE "6" TO LS-RESP2
                WHEN LS-OPTION = "MILLISECS" AND LS-COMMAND = "DELAY"
                    MOVE 359999999 TO LS-MOST
                    MOVE "22" TO LS-RESP2
            END-EVALUATE
            IF LS-MOST > 0
                IF LS-UNITS > 1 AND LS-OPTION NOT = "HOURS"
                    IF LS-OPTION = "MILLISECS"
                        MOVE 999 TO LS-MOST
                    ELSE
                        MOVE 59 TO LS-MOST
                    END-IF
                END-IF
                COMPUTE LS-K = LS-T + 2
                PERFORM CHECK-UNIT-VALUE
            END-IF
        END-IF
    END-PERFORM.

*> K017: a WRITEQ TS, its REWRITE without ITEM, and a LENGTH number of
*> 0 or above 32763.
CHECK-WRITEQ-TS.
    MOVE "N" TO LS-TS LS-ITEM-CODED
    MOVE 0 TO LS-REWRITE LS-LENGTH-AT
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-OPTION LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-OPTION) TO LS-OPTION
            EVALUATE LS-OPTION
                WHEN "TS"
                    MOVE "Y" TO LS-TS
                WHEN "REWRITE"
                    MOVE LS-T TO LS-REWRITE
                WHEN "ITEM"
                    MOVE "Y" TO LS-ITEM-CODED
                WHEN "LENGTH"
                    COMPUTE LS-K = LS-T + 2
                    IF TK-IS-LPAREN(LS-T + 1) AND TK-IS-NUMBER(LS-K)
                        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K
                            LS-DIGITS LS-LEN
                        IF LS-LEN > 0 AND LS-LEN <= 9
                           AND LS-DIGITS(1:LS-LEN) IS NUMERIC
                            MOVE FUNCTION NUMVAL(LS-DIGITS(1:LS-LEN))
                                TO LS-VALUE
                            IF LS-VALUE = 0 OR LS-VALUE > 32763
                                MOVE LS-K TO LS-LENGTH-AT
                            END-IF
                        END-IF
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM
    IF LS-TS NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    IF LS-REWRITE > 0 AND LS-ITEM-CODED = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING "WRITEQ TS with REWRITE names no ITEM: the item to"
               " overwrite must be given" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-TSQ LS-REWRITE LS-MESSAGE
    END-IF
    IF LS-LENGTH-AT > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-LENGTH-AT LS-DIGITS LS-LEN
        MOVE SPACES TO LS-MESSAGE
        STRING "WRITEQ TS writes LENGTH(" DELIMITED BY SIZE
               LS-DIGITS(1:LS-LEN) DELIMITED BY SIZE
               "), but an item is 1 to 32763 bytes: CICS raises LENGERR"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-TSQ LS-LENGTH-AT LS-MESSAGE
    END-IF.

*> The number at LS-K, for option LS-OPTION, against LS-MOST.
CHECK-UNIT-VALUE.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-DIGITS LS-LEN
    IF LS-LEN = 0 OR LS-LEN > 18
        EXIT PARAGRAPH
    END-IF
    IF LS-DIGITS(1:LS-LEN) IS NOT NUMERIC
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION NUMVAL(LS-DIGITS(1:LS-LEN)) TO LS-VALUE
    IF LS-VALUE <= LS-MOST
        EXIT PARAGRAPH
    END-IF
    MOVE LS-MOST TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING LS-OPTION DELIMITED BY SPACE
           "(" LS-DIGITS(1:LS-LEN) ") of " DELIMITED BY SIZE
           LS-COMMAND DELIMITED BY SPACE
           " is above " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-UNITS > 1 AND LS-OPTION NOT = "HOURS"
        STRING ", its most with another time option" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING ": CICS raises INVREQ (RESP2 " DELIMITED BY SIZE
           LS-RESP2 DELIMITED BY SPACE
           ")" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-UNITS LS-K LS-MESSAGE.

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
