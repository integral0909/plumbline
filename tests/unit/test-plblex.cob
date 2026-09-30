*> Unit tests for src/lib/plblex.cob. The token listings themselves are
*> covered by the golden suite in tests/golden/lexer; these tests check
*> the fields a listing does not show.
IDENTIFICATION DIVISION.
PROGRAM-ID. TEST-PLBLEX.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  WS-MODE                 PIC X.
01  WS-DEBUG                PIC X VALUE "N".
01  WS-FILE-ID              PIC 9(4) COMP-5.
01  WS-STATUS               PIC 9(4) COMP-5.
01  WS-INDEX                PIC 9(9) COMP-5.
01  WS-TEXT                 PIC X(200).
01  WS-SHORT                PIC X(4).
01  WS-LEN                  PIC 9(9) COMP-5.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-FOUND                PIC 9(9) COMP-5.
01  WS-EXPECT-NUM           PIC S9(18) COMP-5.
01  WS-ACTUAL-NUM           PIC S9(18) COMP-5.

PROCEDURE DIVISION.
    CALL "PLBT-BEGIN" USING "plblex"
    PERFORM TEST-LITERAL-FIELDS
    PERFORM TEST-CONTINUED-SPAN
    PERFORM TEST-EOF-PER-FILE
    PERFORM TEST-PICTURE-NOT-ACROSS-FILES
    PERFORM TEST-TOKEN-TEXT
    CALL "PLBT-END"
    STOP RUN.

RESET-ALL.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    CALL "PLB-LEX-INIT" USING PLB-TOKENS.

LEX-FILE.
    CALL "PLB-SRC-LOAD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        WS-TEXT WS-MODE WS-FILE-ID WS-STATUS
    CALL "PLB-LEX-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-TOKENS WS-FILE-ID WS-DEBUG.

*> Set WS-FOUND to the first token whose text is WS-SHORT, or 0.
FIND-TOKEN.
    MOVE 0 TO WS-FOUND
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-I WS-TEXT WS-LEN
        IF WS-TEXT = WS-SHORT
            MOVE WS-I TO WS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM.

TEST-LITERAL-FIELDS.
    CALL "PLBT-CASE" USING "literal prefixes and values"
    PERFORM RESET-ALL
    MOVE "F" TO WS-MODE
    MOVE "tests/golden/lexer/literals.cob" TO WS-TEXT
    PERFORM LEX-FILE
    MOVE "FF00" TO WS-SHORT
    PERFORM FIND-TOKEN
    CALL "PLBT-ASSERT-STR" USING "hex literal has prefix X" "X"
        TK-PREFIX(WS-FOUND)
    CALL "PLBT-ASSERT-FLAG" USING "hex literal is alphanumeric" "A"
        TK-KIND(WS-FOUND)
    MOVE 7 TO WS-EXPECT-NUM
    MOVE TK-SPAN(WS-FOUND) TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "span covers prefix and quotes"
        WS-EXPECT-NUM WS-ACTUAL-NUM

    MOVE "0041" TO WS-SHORT
    PERFORM FIND-TOKEN
    CALL "PLBT-ASSERT-STR" USING "two-letter prefix" "NX"
        TK-PREFIX(WS-FOUND)

    *> 'IT''S' holds four characters.
    MOVE 4 TO WS-INDEX
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-INDEX WS-TEXT WS-LEN
    CALL "PLBT-ASSERT-STR" USING "doubled quote collapsed" "IT'S"
        WS-TEXT
    MOVE 4 TO WS-EXPECT-NUM
    MOVE WS-LEN TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "collapsed length"
        WS-EXPECT-NUM WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-STR" USING "plain literal has no prefix" " "
        TK-PREFIX(WS-INDEX)

    *> DISPLAY "" is token 8: an empty value.
    MOVE 8 TO WS-INDEX
    MOVE 0 TO WS-EXPECT-NUM
    MOVE TK-TEXT-LEN(WS-INDEX) TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "empty literal has no text"
        WS-EXPECT-NUM WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-FLAG" USING "empty literal is alphanumeric" "A"
        TK-KIND(WS-INDEX).

TEST-CONTINUED-SPAN.
    CALL "PLBT-CASE" USING "tokens across continuation lines"
    PERFORM RESET-ALL
    MOVE "X" TO WS-MODE
    MOVE "tests/golden/lexer/continuation.cbl" TO WS-TEXT
    PERFORM LEX-FILE
    *> The literal runs from its quote in column 32 to column 72 (41
    *> characters), then resumes after the quote on line 2 for 13 more.
    MOVE 6 TO WS-INDEX
    CALL "PLBT-ASSERT-FLAG" USING "continued literal" "A"
        TK-KIND(WS-INDEX)
    MOVE 1 TO WS-EXPECT-NUM
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-INDEX)) TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "located at its first line"
        WS-EXPECT-NUM WS-ACTUAL-NUM
    MOVE 54 TO WS-EXPECT-NUM
    MOVE TK-SPAN(WS-INDEX) TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "span includes both parts"
        WS-EXPECT-NUM WS-ACTUAL-NUM
    MOVE 9 TO WS-INDEX
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-INDEX WS-TEXT WS-LEN
    CALL "PLBT-ASSERT-STR" USING "continued word joined"
        "LONG-NAME-PART-TWO" WS-TEXT.

TEST-EOF-PER-FILE.
    CALL "PLBT-CASE" USING "end-of-file tokens"
    PERFORM RESET-ALL
    MOVE "F" TO WS-MODE
    MOVE "tests/golden/lexer/numbers.cob" TO WS-TEXT
    PERFORM LEX-FILE
    MOVE TK-COUNT TO WS-FOUND
    MOVE "tests/golden/lexer/operators.cob" TO WS-TEXT
    PERFORM LEX-FILE
    CALL "PLBT-ASSERT-FLAG" USING "first file ends with eof" "E"
        TK-KIND(WS-FOUND)
    CALL "PLBT-ASSERT-FLAG" USING "second file ends with eof" "E"
        TK-KIND(TK-COUNT)
    MOVE 2 TO WS-EXPECT-NUM
    MOVE TK-FILE-ID(WS-FOUND + 1) TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "next token is in file 2"
        WS-EXPECT-NUM WS-ACTUAL-NUM

    PERFORM RESET-ALL
    MOVE "tests/fixtures/reader/empty.cbl" TO WS-TEXT
    PERFORM LEX-FILE
    MOVE 1 TO WS-EXPECT-NUM
    MOVE TK-COUNT TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "empty file has only eof"
        WS-EXPECT-NUM WS-ACTUAL-NUM
    MOVE 0 TO WS-EXPECT-NUM
    MOVE TK-SRC-LINE(1) TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "eof of empty file has no line"
        WS-EXPECT-NUM WS-ACTUAL-NUM.

TEST-PICTURE-NOT-ACROSS-FILES.
    CALL "PLBT-CASE" USING "picture context stays in its file"
    PERFORM RESET-ALL
    MOVE "F" TO WS-MODE
    MOVE "tests/fixtures/lexer/ends-with-pic.cob" TO WS-TEXT
    PERFORM LEX-FILE
    MOVE "tests/golden/lexer/operators.cob" TO WS-TEXT
    PERFORM LEX-FILE
    MOVE "PIC" TO WS-SHORT
    PERFORM FIND-TOKEN
    *> PIC, then eof, then the first token of the next file.
    CALL "PLBT-ASSERT-FLAG" USING "eof follows trailing PIC" "E"
        TK-KIND(WS-FOUND + 1)
    CALL "PLBT-ASSERT-FLAG" USING "next file starts with a word" "W"
        TK-KIND(WS-FOUND + 2).

TEST-TOKEN-TEXT.
    CALL "PLBT-CASE" USING "PLB-TOK-TEXT"
    MOVE 0 TO WS-INDEX
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-INDEX WS-TEXT WS-LEN
    MOVE 0 TO WS-EXPECT-NUM
    MOVE WS-LEN TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "index 0 gives no text"
        WS-EXPECT-NUM WS-ACTUAL-NUM
    *> Token 2 is INITIAL-FIELD from ends-with-pic.cob.
    MOVE 2 TO WS-INDEX
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-INDEX WS-SHORT WS-LEN
    CALL "PLBT-ASSERT-STR" USING "text cut to fit" "INIT" WS-SHORT
    MOVE 4 TO WS-EXPECT-NUM
    MOVE WS-LEN TO WS-ACTUAL-NUM
    CALL "PLBT-ASSERT-NUM" USING "length cut to fit"
        WS-EXPECT-NUM WS-ACTUAL-NUM.
END PROGRAM TEST-PLBLEX.
