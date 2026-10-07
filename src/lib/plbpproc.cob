*> ---------------------------------------------------------------
*> plbpproc: parser for the procedure division.
*>
*> Structure:  DIVN PROCEDURE
*>               USNG ...                   USING / RETURNING items
*>               SECT name                  sections (optional)
*>                 PARA name                paragraphs (optional)
*>                   SENT                   sentences, ended by periods
*>                     STMT verb            statements
*>
*> Statement nesting is tracked with a context stack instead of
*> recursion. Each open construct is one entry:
*>
*>   S  a statement still collecting its operands
*>   T  the THEN branch of an IF        E  the ELSE branch of an IF
*>   V  the head of an EVALUATE or SEARCH, before its first WHEN
*>   W  a WHEN branch                   R  the body of an inline PERFORM
*>   P  a conditional phrase such as AT END or ON SIZE ERROR
*>
*> A period closes every open construct. A scope terminator (END-IF,
*> END-READ, ...) closes the innermost matching construct and anything
*> still open inside it. ELSE pairs with the innermost open IF. A
*> phrase attaches to the innermost open statement whose verb accepts
*> it, so NOT AT END goes with the READ that has AT END. Without an
*> explicit terminator, statements after a phrase belong to the phrase
*> up to the period, as the standard says.
*>
*> Out-of-line PERFORM and GO TO targets become PROC nodes; IF,
*> EVALUATE, WHEN, SEARCH WHEN, and inline PERFORM headers get COND
*> nodes covering their conditions. Other operands are left as the
*> statement's token range.
*>
*> Diagnostic codes raised here:
*>   PS002  error    scope terminator with nothing to terminate
*>   PS003  error    ELSE without IF
*>   PS004  error    WHEN outside EVALUATE or SEARCH
*>   PS005  warning  sentence not ended by a period
*>   PS006  error    conditional phrase no open statement accepts
*>   PS007  error    text where a statement was expected
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-PROC.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  CX-MAX                      VALUE 256.
01  WS-CONTEXTS.
    05  WS-CX-DEPTH         PIC 9(4) COMP-5.
    05  WS-CX               OCCURS CX-MAX TIMES.
        10  CX-TYPE         PIC X.
        10  CX-NODE         PIC 9(9) COMP-5.
        10  CX-STMT         PIC 9(9) COMP-5.
        10  CX-VERB         PIC X(16).
LOCAL-STORAGE SECTION.
COPY "plbptok.cpy".
01  LS-HEADER               PIC X(16).
01  LS-DECLARATIVES         PIC 9(9) COMP-5.
01  LS-SECTION              PIC 9(9) COMP-5.
01  LS-PARAGRAPH            PIC 9(9) COMP-5.
01  LS-SENTENCE             PIC 9(9) COMP-5.
01  LS-PARENT               PIC 9(9) COMP-5.
01  LS-SORT-PROC            PIC X.
01  LS-WHENEVER-END         PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-BLOCK                PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-NEXT2                PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(4) COMP-5.
01  LS-VERB                 PIC X(16).
01  LS-DETAIL               PIC X(16).
01  LS-TEXT                 PIC X(31).
01  LS-NEXT-TEXT            PIC X(31).
01  LS-PAREN-DEPTH          PIC S9(9) COMP-5.
01  LS-NEXT-KIND            PIC X.
01  LS-SENTENCE-DONE        PIC X.
01  LS-DONE                 PIC X.
01  LS-FOUND                PIC X.
01  LS-STOP                 PIC X.
01  LS-PHRASE-CAT           PIC X.
01  LS-PHRASE-NAME          PIC X(16).
01  LS-PHRASE-LEN           PIC 9(4) COMP-5.
01  LS-ACCEPTS              PIC X.
01  LS-WANT                 PIC X(16).
01  LS-CX-TYPE              PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbpst.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-PARSE-STATE.
    MOVE 0 TO LS-DECLARATIVES LS-SECTION LS-PARAGRAPH WS-CX-DEPTH
    PERFORM DIVISION-HEADER
    MOVE "N" TO LS-DONE
    PERFORM UNTIL PS-POS >= PS-END OR PS-FULL = "Y" OR LS-DONE = "Y"
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        IF LS-HEADER NOT = SPACES
            EXIT PERFORM
        END-IF
        PERFORM SENTENCE-START
        PERFORM EXTEND-OPEN-NODES
    END-PERFORM
    GOBACK.

*> PROCEDURE DIVISION [USING [BY REFERENCE|VALUE|CONTENT] items...]
*>                    [CHAINING items...] [RETURNING item] .
DIVISION-HEADER.
    ADD 2 TO PS-POS
    MOVE SPACES TO LS-DETAIL
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-KIND = "."
            ADD 1 TO PS-POS
            EXIT PERFORM
        END-IF
        EVALUATE TRUE
            WHEN PX-TEXT = "USING" OR PX-TEXT = "RETURNING"
                 OR PX-TEXT = "CHAINING"
                MOVE PX-TEXT TO LS-DETAIL
            WHEN PX-KIND = "W" AND PX-KW = SPACE
                 AND LS-DETAIL NOT = SPACES
                CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "USNG"
                    LS-DETAIL PS-POS LS-NODE
                IF LS-NODE > 0
                    MOVE PS-POS TO ND-NAME(LS-NODE)
                END-IF
            WHEN PX-KW = "V"
                *> A verb here means the period is missing.
                EXIT PERFORM
        END-EVALUATE
        ADD 1 TO PS-POS
    END-PERFORM.

*> At the start of a sentence: a section or paragraph header, the
*> DECLARATIVES brackets, or a sentence of statements.
SENTENCE-START.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    MOVE PX-TEXT TO LS-TEXT
    COMPUTE LS-NEXT = PS-POS + 1
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-NEXT PLB-PX-VIEW
    MOVE PX-TEXT TO LS-NEXT-TEXT
    MOVE PX-KIND TO LS-NEXT-KIND
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW

    EVALUATE TRUE
        WHEN LS-TEXT = "DECLARATIVES" AND LS-NEXT-KIND = "."
            CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "OTHR"
                "DECLARATIVES" PS-POS LS-DECLARATIVES
            MOVE 0 TO LS-SECTION LS-PARAGRAPH
            ADD 2 TO PS-POS
        WHEN LS-TEXT = "END" AND LS-NEXT-TEXT = "DECLARATIVES"
            CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
            IF LS-DECLARATIVES > 0
                COMPUTE ND-TOK-LAST(LS-DECLARATIVES) = PS-POS - 1
            END-IF
            MOVE 0 TO LS-DECLARATIVES LS-SECTION LS-PARAGRAPH
        WHEN (PX-KIND = "W" AND PX-KW = SPACE OR PX-KIND = "N")
             AND LS-NEXT-TEXT = "SECTION"
            MOVE PS-DIVISION TO LS-PARENT
            IF LS-DECLARATIVES > 0
                MOVE LS-DECLARATIVES TO LS-PARENT
            END-IF
            CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "SECT" " "
                PS-POS LS-SECTION
            IF LS-SECTION > 0
                MOVE PS-POS TO ND-NAME(LS-SECTION)
            END-IF
            MOVE 0 TO LS-PARAGRAPH
            CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
        WHEN (PX-KIND = "W" AND PX-KW = SPACE OR PX-KIND = "N")
             AND LS-NEXT-KIND = "."
            MOVE PS-DIVISION TO LS-PARENT
            IF LS-SECTION > 0
                MOVE LS-SECTION TO LS-PARENT
            ELSE
                IF LS-DECLARATIVES > 0
                    MOVE LS-DECLARATIVES TO LS-PARENT
                END-IF
            END-IF
            CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "PARA" " "
                PS-POS LS-PARAGRAPH
            IF LS-PARAGRAPH > 0
                MOVE PS-POS TO ND-NAME(LS-PARAGRAPH)
            END-IF
            ADD 2 TO PS-POS
        WHEN OTHER
            PERFORM PARSE-SENTENCE
    END-EVALUATE.

*> Statements up to and including the period.
PARSE-SENTENCE.
    PERFORM SENTENCE-PARENT
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "SENT" " " PS-POS
        LS-SENTENCE
    IF LS-SENTENCE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO WS-CX-DEPTH
    MOVE "N" TO LS-SENTENCE-DONE
    PERFORM UNTIL LS-SENTENCE-DONE = "Y" OR PS-FULL = "Y"
        IF PS-POS >= PS-END
            PERFORM MISSING-PERIOD
            EXIT PERFORM
        END-IF
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        IF LS-HEADER NOT = SPACES
            PERFORM MISSING-PERIOD
            EXIT PERFORM
        END-IF
        PERFORM SENTENCE-TOKEN
    END-PERFORM.

SENTENCE-PARENT.
    EVALUATE TRUE
        WHEN LS-PARAGRAPH > 0
            MOVE LS-PARAGRAPH TO LS-PARENT
        WHEN LS-SECTION > 0
            MOVE LS-SECTION TO LS-PARENT
        WHEN LS-DECLARATIVES > 0
            MOVE LS-DECLARATIVES TO LS-PARENT
        WHEN OTHER
            MOVE PS-DIVISION TO LS-PARENT
    END-EVALUATE.

MISSING-PERIOD.
    CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PS-POS "W" "PS005" "sentence is not ended by a period"
    PERFORM CLOSE-ALL
    COMPUTE ND-TOK-LAST(LS-SENTENCE) = PS-POS - 1
    MOVE "Y" TO LS-SENTENCE-DONE.

*> Dispatch on the token at PS-POS inside a sentence.
SENTENCE-TOKEN.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    MOVE PX-TEXT TO LS-TEXT
    COMPUTE LS-NEXT = PS-POS + 1
    PERFORM CHECK-PHRASE
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    EVALUATE TRUE
        WHEN PX-KIND = "."
            PERFORM CLOSE-ALL
            MOVE PS-POS TO ND-TOK-LAST(LS-SENTENCE)
            ADD 1 TO PS-POS
            MOVE "Y" TO LS-SENTENCE-DONE
        WHEN PX-KIND = "W" AND LS-TEXT = "ELSE"
            PERFORM HANDLE-ELSE
        *> XML GENERATE ... SUPPRESS ... WHEN SPACES: an operand.
        WHEN PX-KIND = "W" AND LS-TEXT = "WHEN" AND WS-CX-DEPTH > 0
             AND CX-TYPE(WS-CX-DEPTH) = "S"
             AND (CX-VERB(WS-CX-DEPTH) = "XML"
                  OR CX-VERB(WS-CX-DEPTH) = "JSON")
            ADD 1 TO PS-POS
        WHEN PX-KIND = "W" AND LS-TEXT = "WHEN"
            PERFORM HANDLE-WHEN
        WHEN PX-KW = "T"
            PERFORM HANDLE-TERMINATOR
        WHEN LS-PHRASE-CAT NOT = SPACE
            PERFORM HANDLE-PHRASE
        WHEN LS-TEXT = "NEXT" AND TK-IS-WORD(LS-NEXT)
             AND TK-TEXT(TK-TEXT-OFF(LS-NEXT):TK-TEXT-LEN(LS-NEXT))
                 = "SENTENCE"
            MOVE "NEXT SENTENCE" TO LS-VERB
            PERFORM BEGIN-STATEMENT
            ADD 2 TO PS-POS
            MOVE LS-NEXT TO ND-TOK-LAST(LS-STMT)
        *> XML GENERATE ... SUPPRESS: Report Writer's verbs are words
        *> of the XML and JSON statements.
        WHEN PX-KW = "V" AND WS-CX-DEPTH > 0
             AND CX-TYPE(WS-CX-DEPTH) = "S"
             AND (CX-VERB(WS-CX-DEPTH) = "XML"
                  OR CX-VERB(WS-CX-DEPTH) = "JSON")
             AND (LS-TEXT = "GENERATE" OR LS-TEXT = "SUPPRESS")
            ADD 1 TO PS-POS
        WHEN PX-KW = "V" OR (LS-TEXT = "USE" AND WS-CX-DEPTH = 0)
            MOVE LS-TEXT TO LS-VERB
            PERFORM HANDLE-VERB
        WHEN OTHER
            PERFORM OPERAND-TOKEN
    END-EVALUATE.

*> A token that is not a verb, terminator, or phrase: an operand of
*> the statement being collected, or text that cannot be here.
OPERAND-TOKEN.
    IF WS-CX-DEPTH > 0
        *> SORT ... INPUT PROCEDURE p, XML PARSE ... PROCESSING
        *> PROCEDURE p: the procedures run as a PERFORM's do.
        IF CX-TYPE(WS-CX-DEPTH) = "S"
           AND (CX-VERB(WS-CX-DEPTH) = "SORT"
                OR CX-VERB(WS-CX-DEPTH) = "MERGE"
                OR CX-VERB(WS-CX-DEPTH) = "XML"
                OR CX-VERB(WS-CX-DEPTH) = "JSON")
            PERFORM SORT-OPERAND
            EXIT PARAGRAPH
        END-IF
        IF CX-TYPE(WS-CX-DEPTH) = "S" OR CX-TYPE(WS-CX-DEPTH) = "V"
            ADD 1 TO PS-POS
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM CURRENT-CONTAINER
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "ERR " " " PS-POS LS-NODE
    CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PS-POS "E" "PS007" "expected a statement"
    *> Skip to something that can resume parsing.
    ADD 1 TO PS-POS
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-KIND = "." OR PX-KW = "V" OR PX-KW = "T"
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM
    IF LS-NODE > 0
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    ELSE
        MOVE "Y" TO PS-FULL
    END-IF.

*> The node that new statements attach to.
CURRENT-CONTAINER.
    MOVE LS-SENTENCE TO LS-PARENT
    IF WS-CX-DEPTH > 0
        MOVE CX-NODE(WS-CX-DEPTH) TO LS-PARENT
    END-IF.

*> Statements ----------------------------------------------------

HANDLE-VERB.
    *> A new verb ends the statement still collecting operands.
    IF WS-CX-DEPTH > 0
        IF CX-TYPE(WS-CX-DEPTH) = "S"
            PERFORM CLOSE-TOP
        END-IF
    END-IF
    PERFORM BEGIN-STATEMENT
    IF LS-STMT = 0
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PS-POS
    EVALUATE LS-VERB
        WHEN "IF"
            PERFORM IF-STATEMENT
        WHEN "EVALUATE"
            PERFORM EVALUATE-STATEMENT
        WHEN "SEARCH"
            PERFORM SEARCH-STATEMENT
        WHEN "PERFORM"
            PERFORM PERFORM-STATEMENT
        WHEN "GO"
            PERFORM GO-STATEMENT
        WHEN "ALTER"
            PERFORM ALTER-STATEMENT
        WHEN "EXIT"
            PERFORM EXIT-STATEMENT
        WHEN "EXEC"
            PERFORM EXEC-STATEMENT
        WHEN OTHER
            MOVE "S" TO LS-CX-TYPE
            MOVE LS-STMT TO LS-NODE
            PERFORM PUSH-CONTEXT
    END-EVALUATE.

*> Create STMT LS-VERB at PS-POS in the current container.
BEGIN-STATEMENT.
    PERFORM CURRENT-CONTAINER
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "STMT" LS-VERB PS-POS
        LS-STMT
    IF LS-STMT = 0
        MOVE "Y" TO PS-FULL
    END-IF.

*> IF condition [THEN] ... : a COND node, then a THEN block.
IF-STATEMENT.
    MOVE "IF" TO LS-DETAIL
    PERFORM COLLECT-CONDITION
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PX-TEXT = "THEN"
        ADD 1 TO PS-POS
    END-IF
    CALL "PLB-AST-ADD" USING PLB-AST LS-STMT "BLCK" "THEN" PS-POS
        LS-BLOCK
    MOVE "T" TO LS-CX-TYPE
    MOVE LS-BLOCK TO LS-NODE
    PERFORM PUSH-CONTEXT.

*> EVALUATE subjects: a COND node up to the first WHEN.
EVALUATE-STATEMENT.
    MOVE "SUBJECT" TO LS-DETAIL
    PERFORM COLLECT-CONDITION
    MOVE "V" TO LS-CX-TYPE
    MOVE LS-STMT TO LS-NODE
    PERFORM PUSH-CONTEXT.

*> SEARCH [ALL] table [VARYING index]: its operands are collected as
*> the head; AT END and WHEN phrases follow.
SEARCH-STATEMENT.
    MOVE "V" TO LS-CX-TYPE
    MOVE LS-STMT TO LS-NODE
    PERFORM PUSH-CONTEXT.

*> Out-of-line:  PERFORM proc [THRU proc] [n TIMES | UNTIL ... |
*>               VARYING ...]
*> Inline:       PERFORM [n TIMES | UNTIL ... | VARYING ...]
*>                   statements END-PERFORM
*> It is out of line when a user word follows that is not the count
*> of a TIMES loop. The count can be qualified and subscripted, as in
*> PERFORM CNT OF TOTALS (I) TIMES.
PERFORM-STATEMENT.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    PERFORM TIMES-AFTER-COUNT
    *> PERFORM FOREVER ... END-PERFORM (GnuCOBOL, Micro Focus) is an
    *> inline loop, not a PERFORM of a paragraph named FOREVER.
    IF (PX-KIND = "W" AND PX-KW = SPACE OR PX-KIND = "N")
       AND LS-NEXT-TEXT NOT = "TIMES" AND PX-TEXT NOT = "FOREVER"
        MOVE "PERFORM" TO LS-DETAIL
        PERFORM PROCEDURE-NAME
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-TEXT = "THRU" OR PX-TEXT = "THROUGH"
            ADD 1 TO PS-POS
            MOVE "THRU" TO LS-DETAIL
            PERFORM PROCEDURE-NAME
        END-IF
        MOVE "S" TO LS-CX-TYPE
        MOVE LS-STMT TO LS-NODE
        PERFORM PUSH-CONTEXT
    ELSE
        MOVE "LOOP" TO LS-DETAIL
        PERFORM COLLECT-CONDITION
        CALL "PLB-AST-ADD" USING PLB-AST LS-STMT "BLCK" "BODY" PS-POS
            LS-BLOCK
        MOVE "R" TO LS-CX-TYPE
        MOVE LS-BLOCK TO LS-NODE
        PERFORM PUSH-CONTEXT
    END-IF.

*> LS-NEXT-TEXT = the word after the operand at PS-POS, past its
*> qualifiers (IN or OF a name) and one parenthesized subscript list.
TIMES-AFTER-COUNT.
    COMPUTE LS-NEXT = PS-POS + 1
    PERFORM NEXT-WORD-TEXT
    PERFORM UNTIL LS-NEXT-TEXT NOT = "IN" AND LS-NEXT-TEXT NOT = "OF"
        ADD 2 TO LS-NEXT
        PERFORM NEXT-WORD-TEXT
    END-PERFORM
    IF LS-NEXT <= TK-COUNT
        IF TK-IS-LPAREN(LS-NEXT)
            MOVE 0 TO LS-PAREN-DEPTH
            PERFORM UNTIL LS-NEXT > TK-COUNT
                IF TK-IS-LPAREN(LS-NEXT)
                    ADD 1 TO LS-PAREN-DEPTH
                END-IF
                IF TK-IS-RPAREN(LS-NEXT)
                    SUBTRACT 1 FROM LS-PAREN-DEPTH
                    IF LS-PAREN-DEPTH = 0
                        EXIT PERFORM
                    END-IF
                END-IF
                IF TK-IS-PERIOD(LS-NEXT)
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-NEXT
            END-PERFORM
            ADD 1 TO LS-NEXT
            PERFORM NEXT-WORD-TEXT
        END-IF
    END-IF.

*> LS-NEXT-TEXT = the word at LS-NEXT, or spaces.
NEXT-WORD-TEXT.
    MOVE SPACES TO LS-NEXT-TEXT
    IF LS-NEXT <= TK-COUNT
        IF TK-IS-WORD(LS-NEXT) AND TK-TEXT-LEN(LS-NEXT) <= 31
            MOVE TK-TEXT(TK-TEXT-OFF(LS-NEXT):TK-TEXT-LEN(LS-NEXT))
                TO LS-NEXT-TEXT
        END-IF
    END-IF.

*> A PROC node (detail LS-DETAIL) for the procedure name at PS-POS,
*> with an optional qualifier: name [IN|OF section].
PROCEDURE-NAME.
    CALL "PLB-AST-ADD" USING PLB-AST LS-STMT "PROC" LS-DETAIL PS-POS
        LS-NODE
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    MOVE PS-POS TO ND-NAME(LS-NODE)
    ADD 1 TO PS-POS
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF (PX-TEXT = "IN" OR PX-TEXT = "OF")
        ADD 2 TO PS-POS
    END-IF
    COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1.

*> An operand of SORT or MERGE. INPUT PROCEDURE [IS] proc [THRU proc]
*> and OUTPUT PROCEDURE ... run their procedures as PERFORM does, so
*> they get PROC nodes like a PERFORM's.
SORT-OPERAND.
    MOVE "N" TO LS-SORT-PROC
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PS-POS > 2 AND PX-KIND = "W" AND PX-KW = SPACE
        COMPUTE LS-NEXT = PS-POS - 1
        PERFORM PREVIOUS-WORD
        IF LS-NEXT-TEXT = "IS"
            COMPUTE LS-NEXT = PS-POS - 2
            PERFORM PREVIOUS-WORD
        END-IF
        IF LS-NEXT-TEXT = "PROCEDURE"
            MOVE "Y" TO LS-SORT-PROC
        END-IF
    END-IF
    IF LS-SORT-PROC = "N"
        ADD 1 TO PS-POS
        EXIT PARAGRAPH
    END-IF
    MOVE CX-STMT(WS-CX-DEPTH) TO LS-STMT
    MOVE "PERFORM" TO LS-DETAIL
    PERFORM PROCEDURE-NAME
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PX-TEXT = "THRU" OR PX-TEXT = "THROUGH"
        ADD 1 TO PS-POS
        MOVE "THRU" TO LS-DETAIL
        PERFORM PROCEDURE-NAME
    END-IF.

*> LS-NEXT-TEXT = the word at token LS-NEXT, or spaces.
PREVIOUS-WORD.
    MOVE SPACES TO LS-NEXT-TEXT
    IF TK-IS-WORD(LS-NEXT) AND TK-TEXT-LEN(LS-NEXT) <= 31
        MOVE TK-TEXT(TK-TEXT-OFF(LS-NEXT):TK-TEXT-LEN(LS-NEXT))
            TO LS-NEXT-TEXT
    END-IF.

*> ALTER proc TO [PROCEED TO] proc [proc TO [PROCEED TO] proc]...
*> The paragraph altered gets a PROC node "ALTERED", the new target
*> one "ALTER".
ALTER-STATEMENT.
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF NOT (PX-KIND = "W" AND PX-KW = SPACE OR PX-KIND = "N")
            EXIT PERFORM
        END-IF
        MOVE "ALTERED" TO LS-DETAIL
        PERFORM PROCEDURE-NAME
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-TEXT NOT = "TO"
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-TEXT = "PROCEED"
            ADD 2 TO PS-POS
        END-IF
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF NOT (PX-KIND = "W" AND PX-KW = SPACE OR PX-KIND = "N")
            EXIT PERFORM
        END-IF
        MOVE "ALTER" TO LS-DETAIL
        PERFORM PROCEDURE-NAME
    END-PERFORM
    MOVE "S" TO LS-CX-TYPE
    MOVE LS-STMT TO LS-NODE
    PERFORM PUSH-CONTEXT.

*> GO [TO] proc... [DEPENDING [ON] identifier]
GO-STATEMENT.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PX-TEXT = "TO"
        ADD 1 TO PS-POS
    END-IF
    MOVE "GO" TO LS-DETAIL
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF NOT (PX-KIND = "W" AND PX-KW = SPACE OR PX-KIND = "N")
            EXIT PERFORM
        END-IF
        PERFORM PROCEDURE-NAME
    END-PERFORM
    MOVE "S" TO LS-CX-TYPE
    MOVE LS-STMT TO LS-NODE
    PERFORM PUSH-CONTEXT.

*> EXIT [PROGRAM | PARAGRAPH | SECTION | PERFORM [CYCLE] | FUNCTION
*> | METHOD]: the word after EXIT is part of the statement even when
*> it is a verb (PERFORM).
EXIT-STATEMENT.
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    EVALUATE PX-TEXT
        WHEN "PROGRAM" WHEN "PARAGRAPH" WHEN "SECTION"
        WHEN "FUNCTION" WHEN "METHOD"
            MOVE PX-TEXT TO ND-DETAIL(LS-STMT)(6:)
            ADD 1 TO PS-POS
        WHEN "PERFORM"
            MOVE "PERFORM" TO ND-DETAIL(LS-STMT)(6:)
            ADD 1 TO PS-POS
            CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
            IF PX-TEXT = "CYCLE"
                MOVE "EXIT PERFORM CYCLE" TO ND-DETAIL(LS-STMT)
                ADD 1 TO PS-POS
            END-IF
    END-EVALUATE
    MOVE "S" TO LS-CX-TYPE
    MOVE LS-STMT TO LS-NODE
    PERFORM PUSH-CONTEXT.

*> EXEC ... END-EXEC is opaque: embedded SQL or CICS may contain
*> COBOL verbs (DELETE, START) that must not start statements.
EXEC-STATEMENT.
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-TEXT = "END-EXEC" OR PX-KIND = "."
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM
    IF PX-TEXT = "END-EXEC"
        MOVE PS-POS TO ND-TOK-LAST(LS-STMT)
        ADD 1 TO PS-POS
    ELSE
        COMPUTE ND-TOK-LAST(LS-STMT) = PS-POS - 1
    END-IF
    PERFORM WHENEVER-TARGET.

*> EXEC SQL WHENEVER condition {GO TO | GOTO | PERFORM} proc: the
*> precompiler makes later SQL statements jump to, or perform, proc,
*> so it gets a PROC node like a GO TO or PERFORM target.
WHENEVER-TARGET.
    MOVE ND-TOK-FIRST(LS-STMT) TO LS-NEXT
    ADD 1 TO LS-NEXT
    PERFORM PREVIOUS-WORD
    IF LS-NEXT-TEXT NOT = "SQL"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-NEXT
    PERFORM PREVIOUS-WORD
    IF LS-NEXT-TEXT NOT = "WHENEVER"
        EXIT PARAGRAPH
    END-IF
    MOVE PS-POS TO LS-WHENEVER-END
    PERFORM VARYING LS-NEXT FROM LS-NEXT BY 1
            UNTIL LS-NEXT >= ND-TOK-LAST(LS-STMT)
        PERFORM PREVIOUS-WORD
        EVALUATE LS-NEXT-TEXT
            WHEN "GO" WHEN "GOTO" WHEN "PERFORM"
                IF LS-NEXT-TEXT = "PERFORM"
                    MOVE "PERFORM" TO LS-DETAIL
                ELSE
                    MOVE "GO" TO LS-DETAIL
                END-IF
                *> plumbline: ignore varying-control-changed -- steps past the tokens just read
                ADD 1 TO LS-NEXT
                IF LS-NEXT-TEXT = "GO"
                    PERFORM PREVIOUS-WORD
                    IF LS-NEXT-TEXT = "TO"
                        *> plumbline: ignore varying-control-changed -- steps past the tokens just read
                        ADD 1 TO LS-NEXT
                    END-IF
                END-IF
                IF LS-NEXT < ND-TOK-LAST(LS-STMT)
                   AND TK-IS-WORD(LS-NEXT)
                    MOVE LS-NEXT TO PS-POS
                    PERFORM PROCEDURE-NAME
                END-IF
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM
    MOVE LS-WHENEVER-END TO PS-POS.

*> A COND node (detail LS-DETAIL) under LS-STMT for the tokens from
*> PS-POS up to a verb, WHEN, THEN, NEXT SENTENCE, a terminator, a
*> phrase, or the period.
COLLECT-CONDITION.
    CALL "PLB-AST-ADD" USING PLB-AST LS-STMT "COND" LS-DETAIL PS-POS
        LS-NODE
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        MOVE "N" TO LS-STOP
        COMPUTE LS-NEXT = PS-POS - 1
        PERFORM PREVIOUS-WORD
        EVALUATE TRUE
            *> PERFORM UNTIL EXIT loops until something leaves it: the
            *> EXIT is the condition, not a statement.
            WHEN PX-TEXT = "EXIT" AND LS-NEXT-TEXT = "UNTIL"
                CONTINUE
            WHEN PX-KIND = "."
            WHEN PX-KW = "V"
            WHEN PX-KW = "T"
            WHEN PX-TEXT = "WHEN"
            WHEN PX-TEXT = "THEN"
            WHEN PX-TEXT = "ELSE"
                MOVE "Y" TO LS-STOP
            WHEN PX-TEXT = "NEXT"
                COMPUTE LS-NEXT = PS-POS + 1
                IF TK-IS-WORD(LS-NEXT)
                    IF TK-TEXT(TK-TEXT-OFF(LS-NEXT):TK-TEXT-LEN(LS-NEXT))
                       = "SENTENCE"
                        MOVE "Y" TO LS-STOP
                    END-IF
                END-IF
            WHEN OTHER
                PERFORM CHECK-PHRASE
                IF LS-PHRASE-CAT NOT = SPACE
                    MOVE "Y" TO LS-STOP
                END-IF
        END-EVALUATE
        IF LS-STOP = "Y"
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM
    IF PS-POS > ND-TOK-FIRST(LS-NODE)
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    ELSE
        *> An empty condition covers no tokens.
        MOVE 0 TO ND-TOK-LAST(LS-NODE)
    END-IF.

*> IF branches, WHEN branches, terminators -------------------------

*> ELSE: close everything inside the innermost THEN branch and open
*> the ELSE branch of that IF. An open ELSE branch on the way means
*> that inner IF is complete.
HANDLE-ELSE.
    MOVE "N" TO LS-FOUND
    PERFORM UNTIL WS-CX-DEPTH = 0
        IF CX-TYPE(WS-CX-DEPTH) = "T"
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
        PERFORM CLOSE-TOP
    END-PERFORM
    IF LS-FOUND = "N"
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS003" "ELSE without a matching IF"
        ADD 1 TO PS-POS
        EXIT PARAGRAPH
    END-IF
    COMPUTE ND-TOK-LAST(CX-NODE(WS-CX-DEPTH)) = PS-POS - 1
    CALL "PLB-AST-ADD" USING PLB-AST CX-STMT(WS-CX-DEPTH) "BLCK" "ELSE"
        PS-POS LS-BLOCK
    MOVE "E" TO CX-TYPE(WS-CX-DEPTH)
    MOVE LS-BLOCK TO CX-NODE(WS-CX-DEPTH)
    ADD 1 TO PS-POS.

*> WHEN [OTHER] objects: a new branch of the innermost EVALUATE or
*> SEARCH.
HANDLE-WHEN.
    MOVE "N" TO LS-FOUND
    PERFORM UNTIL WS-CX-DEPTH = 0
        IF CX-TYPE(WS-CX-DEPTH) = "V"
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
        PERFORM CLOSE-TOP
    END-PERFORM
    IF LS-FOUND = "N"
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS004"
            "WHEN outside EVALUATE or SEARCH"
        ADD 1 TO PS-POS
        EXIT PARAGRAPH
    END-IF
    MOVE CX-NODE(WS-CX-DEPTH) TO LS-STMT
    MOVE "WHEN" TO LS-DETAIL
    COMPUTE LS-NEXT = PS-POS + 1
    IF TK-IS-WORD(LS-NEXT)
        IF TK-TEXT(TK-TEXT-OFF(LS-NEXT):TK-TEXT-LEN(LS-NEXT)) = "OTHER"
            MOVE "WHEN-OTHER" TO LS-DETAIL
        END-IF
    END-IF
    CALL "PLB-AST-ADD" USING PLB-AST LS-STMT "BLCK" LS-DETAIL PS-POS
        LS-BLOCK
    IF LS-BLOCK = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PS-POS
    IF LS-DETAIL = "WHEN-OTHER"
        ADD 1 TO PS-POS
    ELSE
        MOVE LS-BLOCK TO LS-STMT
        MOVE "WHEN" TO LS-DETAIL
        PERFORM COLLECT-CONDITION
        MOVE CX-NODE(WS-CX-DEPTH) TO LS-STMT
    END-IF
    MOVE "W" TO LS-CX-TYPE
    MOVE LS-BLOCK TO LS-NODE
    PERFORM PUSH-CONTEXT
    MOVE CX-NODE(WS-CX-DEPTH - 1) TO CX-STMT(WS-CX-DEPTH).

*> END-IF, END-EVALUATE, END-SEARCH, END-PERFORM, or END-<verb>:
*> close the innermost construct it belongs to, and everything open
*> inside that construct.
HANDLE-TERMINATOR.
    MOVE LS-TEXT(5:) TO LS-WANT
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-C FROM WS-CX-DEPTH BY -1 UNTIL LS-C = 0
        EVALUATE TRUE
            WHEN LS-WANT = "IF"
                IF CX-TYPE(LS-C) = "T" OR CX-TYPE(LS-C) = "E"
                    MOVE "Y" TO LS-FOUND
                END-IF
            WHEN LS-WANT = "PERFORM"
                IF CX-TYPE(LS-C) = "R"
                    MOVE "Y" TO LS-FOUND
                END-IF
            WHEN OTHER
                IF (CX-TYPE(LS-C) = "S" OR CX-TYPE(LS-C) = "V")
                   AND CX-VERB(LS-C) = LS-WANT
                    MOVE "Y" TO LS-FOUND
                END-IF
        END-EVALUATE
        IF LS-FOUND = "Y"
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "N"
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS002"
            "scope terminator has no statement to end"
        ADD 1 TO PS-POS
        EXIT PARAGRAPH
    END-IF
    *> Close everything above the construct, then the construct,
    *> which extends to and includes the terminator.
    PERFORM UNTIL WS-CX-DEPTH = LS-C
        PERFORM CLOSE-TOP
    END-PERFORM
    ADD 1 TO PS-POS
    PERFORM CLOSE-TOP.

*> Conditional phrases ---------------------------------------------

*> Is a conditional phrase at PS-POS? Sets LS-PHRASE-CAT (space if
*> not), LS-PHRASE-NAME, and LS-PHRASE-LEN (its number of tokens).
*>   A  [NOT] [AT] END             K  [NOT] INVALID [KEY]
*>   G  [NOT] [AT] END-OF-PAGE|EOP Z  [NOT] [ON] SIZE ERROR
*>   O  [NOT] [ON] OVERFLOW        X  [NOT] [ON] EXCEPTION
*>   D  NO DATA, WITH DATA (RECEIVE of the communication module)
CHECK-PHRASE.
    MOVE SPACE TO LS-PHRASE-CAT
    MOVE SPACES TO LS-PHRASE-NAME
    MOVE 0 TO LS-PHRASE-LEN
    MOVE PS-POS TO LS-I
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-I PLB-PX-VIEW
    IF PX-KIND NOT = "W"
        EXIT PARAGRAPH
    END-IF
    IF PX-TEXT = "NO" OR PX-TEXT = "WITH"
        MOVE PX-TEXT TO LS-PHRASE-NAME
        COMPUTE LS-NEXT2 = LS-I + 1
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-NEXT2 PLB-PX-VIEW
        IF PX-TEXT = "DATA"
            MOVE "D" TO LS-PHRASE-CAT
            MOVE SPACES TO LS-DETAIL
            STRING LS-PHRASE-NAME DELIMITED BY SPACE "-DATA"
                DELIMITED BY SIZE INTO LS-DETAIL
            MOVE LS-DETAIL TO LS-PHRASE-NAME
            MOVE 2 TO LS-PHRASE-LEN
        ELSE
            MOVE SPACES TO LS-PHRASE-NAME
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF PX-TEXT = "NOT"
        MOVE "NOT-" TO LS-PHRASE-NAME
        ADD 1 TO LS-I
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-I PLB-PX-VIEW
    END-IF
    IF PX-TEXT = "AT" OR PX-TEXT = "ON"
        ADD 1 TO LS-I
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-I PLB-PX-VIEW
    END-IF
    EVALUATE PX-TEXT
        WHEN "END"
            MOVE "A" TO LS-PHRASE-CAT
            MOVE "AT-END" TO LS-DETAIL
        WHEN "END-OF-PAGE"
        WHEN "EOP"
            MOVE "G" TO LS-PHRASE-CAT
            MOVE "AT-EOP" TO LS-DETAIL
        WHEN "INVALID"
            MOVE "K" TO LS-PHRASE-CAT
            MOVE "INVALID-KEY" TO LS-DETAIL
            COMPUTE LS-NEXT2 = LS-I + 1
            CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-NEXT2 PLB-PX-VIEW
            IF PX-TEXT = "KEY"
                MOVE LS-NEXT2 TO LS-I
            END-IF
        WHEN "SIZE"
            COMPUTE LS-NEXT2 = LS-I + 1
            CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-NEXT2 PLB-PX-VIEW
            IF PX-TEXT = "ERROR"
                MOVE "Z" TO LS-PHRASE-CAT
                MOVE "SIZE-ERROR" TO LS-DETAIL
                MOVE LS-NEXT2 TO LS-I
            END-IF
        WHEN "OVERFLOW"
            MOVE "O" TO LS-PHRASE-CAT
            MOVE "OVERFLOW" TO LS-DETAIL
        WHEN "EXCEPTION"
            MOVE "X" TO LS-PHRASE-CAT
            MOVE "EXCEPTION" TO LS-DETAIL
    END-EVALUATE
    IF LS-PHRASE-CAT NOT = SPACE
        MOVE LS-DETAIL TO LS-PHRASE-NAME(5:)
        IF LS-PHRASE-NAME(1:4) NOT = "NOT-"
            MOVE LS-DETAIL TO LS-PHRASE-NAME
        END-IF
        COMPUTE LS-PHRASE-LEN = LS-I - PS-POS + 1
    END-IF.

*> Does verb LS-VERB accept phrase category LS-PHRASE-CAT?
CHECK-ACCEPTS.
    MOVE "N" TO LS-ACCEPTS
    EVALUATE LS-PHRASE-CAT ALSO LS-VERB
        WHEN "A" ALSO "READ"      WHEN "A" ALSO "RETURN"
        WHEN "A" ALSO "SEARCH"
        WHEN "D" ALSO "RECEIVE"
        WHEN "K" ALSO "READ"      WHEN "K" ALSO "WRITE"
        WHEN "K" ALSO "REWRITE"   WHEN "K" ALSO "DELETE"
        WHEN "K" ALSO "START"
        WHEN "G" ALSO "WRITE"
        WHEN "Z" ALSO "ADD"       WHEN "Z" ALSO "SUBTRACT"
        WHEN "Z" ALSO "MULTIPLY"  WHEN "Z" ALSO "DIVIDE"
        WHEN "Z" ALSO "COMPUTE"
        WHEN "O" ALSO "STRING"    WHEN "O" ALSO "UNSTRING"
        WHEN "O" ALSO "CALL"
        WHEN "X" ALSO "CALL"      WHEN "X" ALSO "ACCEPT"
        WHEN "X" ALSO "DISPLAY"   WHEN "X" ALSO "INVOKE"
        WHEN "X" ALSO "JSON"      WHEN "X" ALSO "XML"
            MOVE "Y" TO LS-ACCEPTS
    END-EVALUATE.

*> Attach the phrase to the innermost open statement that accepts it.
*> A phrase of the same statement that is already open is closed.
HANDLE-PHRASE.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-C FROM WS-CX-DEPTH BY -1 UNTIL LS-C = 0
        EVALUATE CX-TYPE(LS-C)
            WHEN "S"
            WHEN "V"
            WHEN "P"
                MOVE CX-VERB(LS-C) TO LS-VERB
                PERFORM CHECK-ACCEPTS
                IF LS-ACCEPTS = "Y"
                    MOVE "Y" TO LS-FOUND
                    EXIT PERFORM
                END-IF
            WHEN "T"
            WHEN "E"
            WHEN "W"
            WHEN "R"
                *> Statements inside a branch cannot take a phrase
                *> that belongs to a statement outside it.
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM
    IF LS-FOUND = "N"
        *> Inside a statement's operands the words are just operands
        *> (USE AFTER STANDARD EXCEPTION PROCEDURE). Elsewhere the
        *> phrase has nothing to attach to.
        IF WS-CX-DEPTH > 0
            IF CX-TYPE(WS-CX-DEPTH) = "S"
                ADD LS-PHRASE-LEN TO PS-POS
                EXIT PARAGRAPH
            END-IF
        END-IF
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS006"
            "conditional phrase does not belong to any open statement"
        ADD LS-PHRASE-LEN TO PS-POS
        EXIT PARAGRAPH
    END-IF
    PERFORM UNTIL WS-CX-DEPTH = LS-C
        PERFORM CLOSE-TOP
    END-PERFORM
    IF CX-TYPE(WS-CX-DEPTH) = "P"
        PERFORM CLOSE-TOP
    END-IF
    MOVE CX-NODE(WS-CX-DEPTH) TO LS-STMT
    MOVE LS-PHRASE-NAME TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST LS-STMT "BLCK" LS-DETAIL PS-POS
        LS-BLOCK
    ADD LS-PHRASE-LEN TO PS-POS
    MOVE "P" TO LS-CX-TYPE
    MOVE LS-BLOCK TO LS-NODE
    PERFORM PUSH-CONTEXT
    MOVE LS-STMT TO CX-STMT(WS-CX-DEPTH).

*> Context stack ---------------------------------------------------

*> Push LS-CX-TYPE for node LS-NODE, owned by statement LS-STMT with
*> verb LS-VERB (for W and P entries CX-STMT is fixed by the caller).
PUSH-CONTEXT.
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    IF WS-CX-DEPTH >= CX-MAX
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-CX-DEPTH
    MOVE LS-CX-TYPE TO CX-TYPE(WS-CX-DEPTH)
    MOVE LS-NODE TO CX-NODE(WS-CX-DEPTH)
    MOVE LS-STMT TO CX-STMT(WS-CX-DEPTH)
    IF WS-CX-DEPTH > 1 AND (LS-CX-TYPE = "P" OR LS-CX-TYPE = "W")
        MOVE CX-VERB(WS-CX-DEPTH - 1) TO CX-VERB(WS-CX-DEPTH)
    ELSE
        MOVE ND-DETAIL(LS-STMT) TO CX-VERB(WS-CX-DEPTH)
    END-IF.

*> Close the innermost context: its node, and the statement it
*> belongs to, extend to the token before PS-POS.
CLOSE-TOP.
    IF WS-CX-DEPTH = 0
        EXIT PARAGRAPH
    END-IF
    MOVE CX-NODE(WS-CX-DEPTH) TO LS-NODE
    IF PS-POS - 1 >= ND-TOK-FIRST(LS-NODE)
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    END-IF
    MOVE CX-STMT(WS-CX-DEPTH) TO LS-NODE
    IF LS-NODE > 0
        IF PS-POS - 1 >= ND-TOK-FIRST(LS-NODE)
            COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
        END-IF
    END-IF
    SUBTRACT 1 FROM WS-CX-DEPTH.

CLOSE-ALL.
    PERFORM UNTIL WS-CX-DEPTH = 0
        PERFORM CLOSE-TOP
    END-PERFORM.

*> The open section, paragraph, and declaratives extend to the
*> current position.
EXTEND-OPEN-NODES.
    IF LS-SECTION > 0
        COMPUTE ND-TOK-LAST(LS-SECTION) = PS-POS - 1
    END-IF
    IF LS-PARAGRAPH > 0
        COMPUTE ND-TOK-LAST(LS-PARAGRAPH) = PS-POS - 1
    END-IF
    IF LS-DECLARATIVES > 0
        COMPUTE ND-TOK-LAST(LS-DECLARATIVES) = PS-POS - 1
    END-IF.
END PROGRAM PLB-PX-PROC.
