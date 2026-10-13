*> ---------------------------------------------------------------
*> plbrunsp: PLB-C106 unstring-space-not-all.
*>
*> An UNSTRING into more than one item DELIMITED BY SPACE without ALL:
*>
*>     UNSTRING WS-NAME DELIMITED BY SPACE INTO WS-FIRST WS-LAST
*>
*> Each space ends a field, so two spaces in a row give an empty field
*> between them, and the fields after it move along by one: with
*> GnuCOBOL 3.2, "JOHN  SMITH JR" gives JOHN, spaces, and SMITH.
*> DELIMITED BY ALL SPACE takes a run of spaces as one delimiter.
*> Delimiters of more than one character, and UNSTRING into one item,
*> are not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C106.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-SPACE-AT             PIC 9(9) COMP-5.
01  LS-RECEIVERS            PIC 9(4) COMP-5.
01  LS-ALL                  PIC X.
*> Where the walk is: D the delimiters, I the receivers, S a phrase
*> after a receiver (DELIMITER IN, COUNT IN), X past them.
01  LS-PART                 PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C106" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT"
           AND ND-DETAIL(LS-NODE) = "UNSTRING"
            PERFORM CHECK-UNSTRING
        END-IF
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> UNSTRING LS-NODE: a space delimiter without ALL, and how many items
*> it splits into.
CHECK-UNSTRING.
    MOVE 0 TO LS-SPACE-AT LS-RECEIVERS
    MOVE "N" TO LS-ALL
    MOVE SPACE TO LS-PART
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        IF WS-TOKEN-REF(LS-T) > 0
            MOVE WS-TOKEN-REF(LS-T) TO LS-R
            EVALUATE LS-PART
                WHEN "I"
                    ADD 1 TO LS-RECEIVERS
                WHEN "S"
                    MOVE "I" TO LS-PART
            END-EVALUATE
            MOVE "N" TO LS-ALL
            MOVE RF-LAST(LS-R) TO LS-T
        ELSE
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            EVALUATE TRUE
                WHEN TK-IS-WORD(LS-T) AND LS-WORD = "DELIMITED"
                    MOVE "D" TO LS-PART
                WHEN TK-IS-WORD(LS-T) AND LS-WORD = "INTO"
                    MOVE "I" TO LS-PART
                WHEN TK-IS-WORD(LS-T)
                     AND (LS-WORD = "DELIMITER" OR LS-WORD = "COUNT")
                     AND LS-PART = "I"
                    MOVE "S" TO LS-PART
                WHEN TK-IS-WORD(LS-T)
                     AND (LS-WORD = "WITH" OR LS-WORD = "POINTER"
                          OR LS-WORD = "TALLYING" OR LS-WORD = "ON"
                          OR LS-WORD = "NOT" OR LS-WORD = "OVERFLOW"
                          OR LS-WORD = "END-UNSTRING")
                     AND LS-PART NOT = "D"
                    MOVE "X" TO LS-PART
                WHEN LS-PART NOT = "D"
                    CONTINUE
                WHEN TK-IS-WORD(LS-T) AND LS-WORD = "ALL"
                    MOVE "Y" TO LS-ALL
                WHEN TK-IS-WORD(LS-T)
                     AND (LS-WORD = "SPACE" OR LS-WORD = "SPACES")
                    PERFORM NOTE-SPACE
                WHEN TK-IS-ALNUM(LS-T) AND TK-PREFIX(LS-T) = SPACES
                     AND TK-TEXT-LEN(LS-T) = 1 AND LS-WORD(1:1) = SPACE
                    PERFORM NOTE-SPACE
                WHEN TK-IS-WORD(LS-T) AND LS-WORD = "OR"
                    MOVE "N" TO LS-ALL
            END-EVALUATE
        END-IF
        ADD 1 TO LS-T
    END-PERFORM
    IF LS-SPACE-AT > 0 AND LS-RECEIVERS > 1
        MOVE "UNSTRING DELIMITED BY SPACE without ALL: two spaces in a"
          & " row give an empty field, and the words after go one field on"
          TO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE LS-SPACE-AT LS-MESSAGE
    END-IF.

NOTE-SPACE.
    IF LS-ALL = "N" AND LS-SPACE-AT = 0
        MOVE LS-T TO LS-SPACE-AT
    END-IF
    MOVE "N" TO LS-ALL.
END PROGRAM PLB-RULE-C106.
