*> ---------------------------------------------------------------
*> plblex: split source files into tokens.
*>
*> PLB-LEX-FILE builds the logical stream of a file (plbstream) and
*> scans it into the PLB-TOKENS table (copy/plbtok.cpy).
*>
*> Token rules:
*>   - Spaces, newlines, commas, and semicolons separate tokens.
*>   - A word is a run of letters, digits, hyphens, and underscores
*>     that contains at least one non-digit. Bytes above X"7F" count
*>     as letters, so UTF-8 identifiers are accepted. A word may also
*>     contain colon-delimited tags, as in :PFX:-RECORD, which COPY
*>     REPLACING ==:PFX:== BY ==WS== turns into WS-RECORD.
*>   - A numeric literal is a run of digits with an optional sign,
*>     decimal point, and (after a decimal point) exponent:
*>     42  -7  +3.25  .5  1.5E+3
*>     A sign only belongs to the number when it directly follows a
*>     separator or "(", as in "MOVE -1 TO X"; "A - 1" is an operator.
*>   - Alphanumeric literals are quoted with " or ', may contain
*>     doubled quotes, and may carry a prefix: X Z N NX G B BX U.
*>   - After PIC or PICTURE (optionally followed by IS) the next token
*>     is a picture string: everything up to the next space, less a
*>     trailing period, comma, or semicolon.
*>   - "==" delimits pseudo-text; ( ) : . are tokens of their own.
*>   - Operators: + - * / ** = < > <= >= <> &
*>   - In the identification division, AUTHOR, INSTALLATION,
*>     DATE-WRITTEN, DATE-COMPILED, SECURITY, and REMARKS take a
*>     comment entry: free text, which may hold anything, up to the
*>     next line that starts another paragraph (a paragraph name and
*>     a period), a division (NAME DIVISION), or END PROGRAM. It
*>     yields no tokens.
*>
*> Diagnostic codes raised here:
*>   LX001  error    alphanumeric literal not terminated on its line
*>   LX002  error    character that cannot start a token
*>   LX004  warning  hexadecimal literal with invalid digits
*>   LX005  error    token table full
*>   LX009  warning  literal longer than 8192 characters, truncated
*> ---------------------------------------------------------------

*> PLB-LEX-INIT: empty the token table.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LEX-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
PROCEDURE DIVISION USING PLB-TOKENS.
    MOVE 0 TO TK-COUNT TK-TEXT-USED
    GOBACK.
END PROGRAM PLB-LEX-INIT.

*> PLB-LEX-FILE: tokenize FILE-ID and append its tokens, followed by
*> an end-of-file token. DEBUG is "Y" to include debugging lines.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LEX-FILE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbstrm.cpy".
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-DEBUG                PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        LK-FILE-ID LK-DEBUG.
    CALL "PLB-STREAM-BUILD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-STREAM LK-FILE-ID LK-DEBUG
    CALL "PLB-LEX-SCAN" USING PLB-STREAM PLB-SOURCE-SET
        PLB-DIAGNOSTICS PLB-TOKENS
    GOBACK.
END PROGRAM PLB-LEX-FILE.

*> PLB-LEX-SCAN: scan a built stream into tokens.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LEX-SCAN.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-CLASSES-READY        PIC X VALUE "N".
*> Character classes, indexed by FUNCTION ORD (byte value + 1):
*>   W letter or underscore   D digit   H hyphen
*>   S separator              Q quote   X anything else
01  WS-CLASS-TABLE.
    05  WS-CLASS            PIC X OCCURS 256 TIMES.
01  WS-LETTERS              PIC X(53) VALUE
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_".
01  WS-I                    PIC 9(4) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-POS                  PIC 9(9) COMP-5.
01  LS-START                PIC 9(9) COMP-5.
01  LS-CH                   PIC X.
01  LS-CLS                  PIC X.
01  LS-NEXT-CLS             PIC X.
01  LS-QUOTE                PIC X.
01  LS-KIND                 PIC X.
01  LS-PREFIX               PIC XX.
01  LS-BUF                  PIC X(8192).
01  LS-BUF-LEN              PIC 9(9) COMP-5.
01  LS-RUN-LEN              PIC 9(9) COMP-5.
01  LS-ALL-DIGITS           PIC X.
01  LS-TRUNCATED            PIC X.
01  LS-FULL                 PIC X VALUE "N".
01  LS-PICTURE              PIC X.
01  LS-PREV-TEXT            PIC X(8).
01  LS-PREV2-TEXT           PIC X(8).
01  LS-SEG                  PIC 9(9) COMP-5 VALUE 1.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-DIAG-POS             PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
01  LS-J                    PIC 9(9) COMP-5.
01  LS-TAG-LEN              PIC 9(9) COMP-5.
01  LS-IN-IDENTIFICATION    PIC X VALUE "N".
01  LS-WORD                 PIC X(31).
01  LS-WORD-LEN             PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbstrm.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
PROCEDURE DIVISION USING PLB-STREAM PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-TOKENS.
    IF WS-CLASSES-READY = "N"
        PERFORM INIT-CLASSES
    END-IF

    MOVE 1 TO LS-POS
    PERFORM UNTIL LS-POS > ST-LEN OR LS-FULL = "Y"
        MOVE ST-TEXT(LS-POS:1) TO LS-CH
        MOVE WS-CLASS(FUNCTION ORD(LS-CH)) TO LS-CLS
        IF LS-CLS = "S"
            ADD 1 TO LS-POS
        ELSE
            PERFORM SCAN-TOKEN
            PERFORM CHECK-COMMENT-ENTRY
        END-IF
    END-PERFORM

    *> End-of-file token, located at the end of the stream.
    MOVE "E" TO LS-KIND
    MOVE SPACES TO LS-PREFIX
    MOVE 0 TO LS-BUF-LEN
    IF ST-LEN > 0
        MOVE ST-LEN TO LS-START
    ELSE
        MOVE 1 TO LS-START
    END-IF
    MOVE LS-START TO LS-POS
    PERFORM ADD-TOKEN
    GOBACK.

INIT-CLASSES.
    MOVE ALL "X" TO WS-CLASS-TABLE
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 53
        MOVE "W" TO WS-CLASS(FUNCTION ORD(WS-LETTERS(WS-I:1)))
    END-PERFORM
    PERFORM VARYING WS-I FROM 129 BY 1 UNTIL WS-I > 256
        MOVE "W" TO WS-CLASS(WS-I)
    END-PERFORM
    PERFORM VARYING WS-I FROM 49 BY 1 UNTIL WS-I > 58
        MOVE "D" TO WS-CLASS(WS-I)
    END-PERFORM
    MOVE "H" TO WS-CLASS(FUNCTION ORD("-"))
    MOVE "S" TO WS-CLASS(FUNCTION ORD(" "))
    MOVE "S" TO WS-CLASS(FUNCTION ORD(X"0A"))
    MOVE "S" TO WS-CLASS(FUNCTION ORD(X"0D"))
    MOVE "S" TO WS-CLASS(FUNCTION ORD(X"09"))
    MOVE "S" TO WS-CLASS(FUNCTION ORD(","))
    MOVE "S" TO WS-CLASS(FUNCTION ORD(";"))
    MOVE "Q" TO WS-CLASS(FUNCTION ORD('"'))
    MOVE "Q" TO WS-CLASS(FUNCTION ORD("'"))
    MOVE "Y" TO WS-CLASSES-READY.

*> Follow which division the tokens are in, and after the period of a
*> paragraph that takes a comment entry, skip the entry.
CHECK-COMMENT-ENTRY.
    IF TK-COUNT < 2
        EXIT PARAGRAPH
    END-IF
    IF TK-FILE-ID(TK-COUNT - 1) NOT = ST-FILE-ID
       OR NOT TK-IS-WORD(TK-COUNT - 1)
       OR TK-TEXT-LEN(TK-COUNT - 1) > LENGTH OF LS-WORD
        EXIT PARAGRAPH
    END-IF
    MOVE TK-TEXT(TK-TEXT-OFF(TK-COUNT - 1):TK-TEXT-LEN(TK-COUNT - 1))
        TO LS-WORD
    IF TK-IS-WORD(TK-COUNT)
        IF TK-TEXT(TK-TEXT-OFF(TK-COUNT):TK-TEXT-LEN(TK-COUNT))
           = "DIVISION"
            IF LS-WORD = "IDENTIFICATION" OR LS-WORD = "ID"
                MOVE "Y" TO LS-IN-IDENTIFICATION
            ELSE
                MOVE "N" TO LS-IN-IDENTIFICATION
            END-IF
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF TK-IS-PERIOD(TK-COUNT) AND LS-IN-IDENTIFICATION = "Y"
        EVALUATE LS-WORD
            WHEN "AUTHOR" WHEN "INSTALLATION" WHEN "DATE-WRITTEN"
            WHEN "DATE-COMPILED" WHEN "SECURITY" WHEN "REMARKS"
                PERFORM SKIP-COMMENT-ENTRY
        END-EVALUATE
    END-IF.

*> Move LS-POS to the start of the next line that begins with a word
*> ending the comment entry, or a directive; or past the stream.
SKIP-COMMENT-ENTRY.
    PERFORM UNTIL LS-POS > ST-LEN
        IF ST-TEXT(LS-POS:1) = X"0A"
            ADD 1 TO LS-POS
            MOVE LS-POS TO LS-AT
            PERFORM UNTIL LS-AT > ST-LEN
                IF ST-TEXT(LS-AT:1) NOT = SPACE
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-AT
            END-PERFORM
            IF LS-AT <= ST-LEN
                IF ST-TEXT(LS-AT:1) = ">" OR ST-TEXT(LS-AT:1) = "$"
                    EXIT PERFORM
                END-IF
                PERFORM WORD-AT
                EVALUATE LS-WORD
                    WHEN "AUTHOR" WHEN "INSTALLATION" WHEN "DATE-WRITTEN"
                    WHEN "DATE-COMPILED" WHEN "SECURITY" WHEN "REMARKS"
                    WHEN "PROGRAM-ID"
                        PERFORM SKIP-SPACES-AT
                        IF LS-AT <= ST-LEN
                            IF ST-TEXT(LS-AT:1) = "."
                                EXIT PERFORM
                            END-IF
                        END-IF
                    WHEN "IDENTIFICATION" WHEN "ID" WHEN "ENVIRONMENT"
                    WHEN "DATA" WHEN "PROCEDURE"
                        PERFORM SKIP-SPACES-AT
                        PERFORM WORD-AT
                        IF LS-WORD = "DIVISION"
                            EXIT PERFORM
                        END-IF
                    WHEN "END"
                        PERFORM SKIP-SPACES-AT
                        PERFORM WORD-AT
                        IF LS-WORD = "PROGRAM"
                            EXIT PERFORM
                        END-IF
                END-EVALUATE
            END-IF
        ELSE
            ADD 1 TO LS-POS
        END-IF
    END-PERFORM.

SKIP-SPACES-AT.
    PERFORM UNTIL LS-AT > ST-LEN
        IF ST-TEXT(LS-AT:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-AT
    END-PERFORM.

*> LS-WORD = the upper-cased word at stream position LS-AT.
WORD-AT.
    MOVE SPACES TO LS-WORD
    MOVE 0 TO LS-WORD-LEN
    PERFORM UNTIL LS-AT > ST-LEN OR LS-WORD-LEN >= LENGTH OF LS-WORD
        IF WS-CLASS(FUNCTION ORD(ST-TEXT(LS-AT:1))) NOT = "W"
           AND WS-CLASS(FUNCTION ORD(ST-TEXT(LS-AT:1))) NOT = "D"
           AND WS-CLASS(FUNCTION ORD(ST-TEXT(LS-AT:1))) NOT = "H"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-WORD-LEN
        MOVE FUNCTION UPPER-CASE(ST-TEXT(LS-AT:1))
            TO LS-WORD(LS-WORD-LEN:1)
        ADD 1 TO LS-AT
    END-PERFORM.

*> Scan one token starting at LS-POS (not a separator).
SCAN-TOKEN.
    MOVE LS-POS TO LS-START
    MOVE SPACES TO LS-PREFIX
    PERFORM CHECK-PICTURE-CONTEXT
    PERFORM PEEK-NEXT-CLASS
    EVALUATE TRUE
        WHEN LS-PICTURE = "Y"
            PERFORM SCAN-PICTURE
        WHEN LS-CLS = "Q"
            PERFORM SCAN-LITERAL
        WHEN LS-CLS = "W" OR LS-CLS = "D"
            PERFORM SCAN-WORD-OR-NUMBER
        WHEN LS-CH = ":"
            PERFORM MEASURE-TAG
            IF LS-TAG-LEN > 0
                PERFORM SCAN-WORD-OR-NUMBER
            ELSE
                PERFORM SCAN-SPECIAL
            END-IF
        *> A sign starts a number when digits, or a decimal point and
        *> digits, follow it: +1, -.5.
        WHEN (LS-CH = "+" OR LS-CH = "-")
             AND (LS-NEXT-CLS = "D"
                  OR LS-POS + 2 <= ST-LEN
                     AND ST-TEXT(LS-POS + 1:1) = "."
                     AND WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS + 2:1)))
                         = "D")
             AND (LS-POS = 1 OR ST-TEXT(LS-POS - 1:1) = SPACE
                  OR ST-TEXT(LS-POS - 1:1) = X"0A"
                  OR ST-TEXT(LS-POS - 1:1) = "(")
            ADD 1 TO LS-POS
            PERFORM SCAN-NUMBER-DIGITS
        *> A decimal point followed by digits is a number (.5) unless it
        *> ends something: a period separator is followed by a space.
        WHEN LS-CH = "." AND LS-NEXT-CLS = "D"
             AND (LS-POS = 1 OR ST-TEXT(LS-POS - 1:1) = SPACE
                  OR ST-TEXT(LS-POS - 1:1) = X"0A"
                  OR ST-TEXT(LS-POS - 1:1) = "(")
            PERFORM SCAN-NUMBER-DIGITS
        WHEN OTHER
            PERFORM SCAN-SPECIAL
    END-EVALUATE.

PEEK-NEXT-CLASS.
    IF LS-POS < ST-LEN
        MOVE WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS + 1:1)))
            TO LS-NEXT-CLS
    ELSE
        MOVE "S" TO LS-NEXT-CLS
    END-IF.

*> A picture string follows PIC, PICTURE, PIC IS, or PICTURE IS
*> within the current file.
CHECK-PICTURE-CONTEXT.
    MOVE "N" TO LS-PICTURE
    MOVE SPACES TO LS-PREV-TEXT LS-PREV2-TEXT
    IF TK-COUNT > 0
        IF TK-IS-WORD(TK-COUNT) AND TK-FILE-ID(TK-COUNT) = ST-FILE-ID
                AND TK-TEXT-LEN(TK-COUNT) <= 8
            MOVE TK-TEXT(TK-TEXT-OFF(TK-COUNT):TK-TEXT-LEN(TK-COUNT))
                TO LS-PREV-TEXT
        END-IF
    END-IF
    IF TK-COUNT > 1
        IF TK-IS-WORD(TK-COUNT - 1)
                AND TK-FILE-ID(TK-COUNT - 1) = ST-FILE-ID
                AND TK-TEXT-LEN(TK-COUNT - 1) <= 8
            MOVE TK-TEXT(TK-TEXT-OFF(TK-COUNT - 1)
                         :TK-TEXT-LEN(TK-COUNT - 1))
                TO LS-PREV2-TEXT
        END-IF
    END-IF
    IF LS-PREV-TEXT = "PIC" OR LS-PREV-TEXT = "PICTURE"
        MOVE "Y" TO LS-PICTURE
    END-IF
    IF LS-PREV-TEXT = "IS"
            AND (LS-PREV2-TEXT = "PIC" OR LS-PREV2-TEXT = "PICTURE")
        MOVE "Y" TO LS-PICTURE
    END-IF
    *> "PIC IS X": the IS is a keyword, not the picture.
    IF LS-PICTURE = "Y" AND (LS-CH = "I" OR LS-CH = "i")
            AND LS-POS + 2 <= ST-LEN
        IF FUNCTION UPPER-CASE(ST-TEXT(LS-POS:2)) = "IS"
                AND WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS + 2:1))) = "S"
            MOVE "N" TO LS-PICTURE
        END-IF
    END-IF.

SCAN-PICTURE.
    PERFORM UNTIL LS-POS > ST-LEN
        IF ST-TEXT(LS-POS:1) = SPACE OR ST-TEXT(LS-POS:1) = X"0A"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-POS
    END-PERFORM
    *> A trailing period, comma, or semicolon is a separator.
    IF LS-POS - LS-START > 1
        IF ST-TEXT(LS-POS - 1:1) = "." OR ST-TEXT(LS-POS - 1:1) = ","
                OR ST-TEXT(LS-POS - 1:1) = ";"
            SUBTRACT 1 FROM LS-POS
        END-IF
    END-IF
    MOVE "P" TO LS-KIND
    PERFORM TAKE-UPPER-TEXT
    PERFORM ADD-TOKEN.

SCAN-WORD-OR-NUMBER.
    MOVE "Y" TO LS-ALL-DIGITS
    PERFORM UNTIL LS-POS > ST-LEN
        MOVE WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS:1))) TO LS-CLS
        EVALUATE LS-CLS
            WHEN "D"
                ADD 1 TO LS-POS
            WHEN "W"
            WHEN "H"
                MOVE "N" TO LS-ALL-DIGITS
                ADD 1 TO LS-POS
            WHEN OTHER
                IF ST-TEXT(LS-POS:1) NOT = ":"
                    EXIT PERFORM
                END-IF
                PERFORM MEASURE-TAG
                IF LS-TAG-LEN = 0
                    EXIT PERFORM
                END-IF
                MOVE "N" TO LS-ALL-DIGITS
                ADD LS-TAG-LEN TO LS-POS
        END-EVALUATE
    END-PERFORM
    COMPUTE LS-RUN-LEN = LS-POS - LS-START

    IF LS-ALL-DIGITS = "Y"
        PERFORM SCAN-NUMBER-TAIL
        EXIT PARAGRAPH
    END-IF

    *> A short prefix directly followed by a quote starts a literal.
    IF LS-POS <= ST-LEN AND LS-RUN-LEN <= 2
        IF WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS:1))) = "Q"
            MOVE FUNCTION UPPER-CASE(ST-TEXT(LS-START:LS-RUN-LEN))
                TO LS-PREFIX
            IF LS-PREFIX = "X " OR "Z " OR "N " OR "NX" OR "G "
                       OR "B " OR "BX" OR "U "
                PERFORM SCAN-LITERAL
                EXIT PARAGRAPH
            END-IF
            MOVE SPACES TO LS-PREFIX
        END-IF
    END-IF

    MOVE "W" TO LS-KIND
    PERFORM TAKE-UPPER-TEXT
    PERFORM ADD-TOKEN.

*> LS-POS is on a colon. If a tag such as :PFX: starts here, set
*> LS-TAG-LEN to its length (both colons included), else to 0.
MEASURE-TAG.
    MOVE 0 TO LS-TAG-LEN
    MOVE LS-POS TO LS-J
    ADD 1 TO LS-J
    PERFORM UNTIL LS-J > ST-LEN
        MOVE WS-CLASS(FUNCTION ORD(ST-TEXT(LS-J:1))) TO LS-NEXT-CLS
        IF LS-NEXT-CLS NOT = "W" AND LS-NEXT-CLS NOT = "D"
                AND LS-NEXT-CLS NOT = "H"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-J
    END-PERFORM
    IF LS-J <= ST-LEN AND LS-J > LS-POS + 1
        IF ST-TEXT(LS-J:1) = ":"
            COMPUTE LS-TAG-LEN = LS-J - LS-POS + 1
        END-IF
    END-IF.

*> Digits after an optional sign or leading decimal point.
SCAN-NUMBER-DIGITS.
    IF ST-TEXT(LS-POS:1) NOT = "."
        PERFORM SKIP-DIGITS
    END-IF
    PERFORM SCAN-NUMBER-TAIL.

*> Optional fraction and exponent after the integer digits.
SCAN-NUMBER-TAIL.
    IF LS-POS < ST-LEN AND ST-TEXT(LS-POS:1) = "."
        IF WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS + 1:1))) = "D"
            ADD 1 TO LS-POS
            PERFORM SKIP-DIGITS
            PERFORM SCAN-EXPONENT
        END-IF
    END-IF
    MOVE "N" TO LS-KIND
    MOVE ST-TEXT(LS-START:LS-POS - LS-START) TO LS-BUF
    COMPUTE LS-BUF-LEN = LS-POS - LS-START
    PERFORM ADD-TOKEN.

SCAN-EXPONENT.
    IF LS-POS < ST-LEN
            AND (ST-TEXT(LS-POS:1) = "E" OR ST-TEXT(LS-POS:1) = "e")
        MOVE LS-POS TO LS-J
        ADD 1 TO LS-J
        IF LS-J < ST-LEN
                AND (ST-TEXT(LS-J:1) = "+" OR ST-TEXT(LS-J:1) = "-")
            ADD 1 TO LS-J
        END-IF
        IF WS-CLASS(FUNCTION ORD(ST-TEXT(LS-J:1))) = "D"
            MOVE LS-J TO LS-POS
            PERFORM SKIP-DIGITS
        END-IF
    END-IF.

SKIP-DIGITS.
    PERFORM UNTIL LS-POS > ST-LEN
        IF WS-CLASS(FUNCTION ORD(ST-TEXT(LS-POS:1))) NOT = "D"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-POS
    END-PERFORM.

*> LS-POS is on the opening quote. The literal ends at the matching
*> quote that is not doubled; a newline or the end of the stream
*> before that means it was never terminated.
SCAN-LITERAL.
    MOVE ST-TEXT(LS-POS:1) TO LS-QUOTE
    ADD 1 TO LS-POS
    MOVE 0 TO LS-BUF-LEN
    MOVE "N" TO LS-TRUNCATED
    PERFORM UNTIL LS-POS > ST-LEN
        MOVE ST-TEXT(LS-POS:1) TO LS-CH
        IF LS-CH = X"0A"
            EXIT PERFORM
        END-IF
        IF LS-CH = LS-QUOTE
            IF LS-POS < ST-LEN AND ST-TEXT(LS-POS + 1:1) = LS-QUOTE
                ADD 1 TO LS-POS
            ELSE
                EXIT PERFORM
            END-IF
        END-IF
        IF LS-BUF-LEN < LENGTH OF LS-BUF
            ADD 1 TO LS-BUF-LEN
            MOVE LS-CH TO LS-BUF(LS-BUF-LEN:1)
        ELSE
            MOVE "Y" TO LS-TRUNCATED
        END-IF
        ADD 1 TO LS-POS
    END-PERFORM

    IF LS-POS <= ST-LEN AND ST-TEXT(LS-POS:1) = LS-QUOTE
        ADD 1 TO LS-POS
    ELSE
        MOVE LS-START TO LS-DIAG-POS
        MOVE "alphanumeric literal is not terminated" TO LS-MESSAGE
        PERFORM REPORT-ERROR
    END-IF
    IF LS-TRUNCATED = "Y"
        MOVE LS-START TO LS-DIAG-POS
        MOVE "literal longer than 8192 characters; the rest is ignored"
            TO LS-MESSAGE
        PERFORM LOCATE-DIAG
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" "LX009"
            ST-FILE-ID LS-LINE-NO LS-COLUMN LS-MESSAGE
    END-IF
    IF LS-PREFIX = "X " OR LS-PREFIX = "BX"
        PERFORM CHECK-HEX-DIGITS
    END-IF
    MOVE "A" TO LS-KIND
    PERFORM ADD-TOKEN.

CHECK-HEX-DIGITS.
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > LS-BUF-LEN
        IF NOT (LS-BUF(LS-J:1) >= "0" AND LS-BUF(LS-J:1) <= "9"
             OR LS-BUF(LS-J:1) >= "A" AND LS-BUF(LS-J:1) <= "F"
             OR LS-BUF(LS-J:1) >= "a" AND LS-BUF(LS-J:1) <= "f")
            MOVE LS-START TO LS-DIAG-POS
            MOVE "hexadecimal literal contains a non-hexadecimal digit"
                TO LS-MESSAGE
            PERFORM LOCATE-DIAG
            CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" "LX004"
                ST-FILE-ID LS-LINE-NO LS-COLUMN LS-MESSAGE
            EXIT PERFORM
        END-IF
    END-PERFORM.

SCAN-SPECIAL.
    MOVE "O" TO LS-KIND
    ADD 1 TO LS-POS
    EVALUATE LS-CH
        WHEN "("
            MOVE "(" TO LS-KIND
        WHEN ")"
            MOVE ")" TO LS-KIND
        WHEN ":"
            MOVE ":" TO LS-KIND
        WHEN "."
            MOVE "." TO LS-KIND
        WHEN "*"
            PERFORM TAKE-IF-NEXT-IS-STAR
        WHEN "="
            IF LS-POS <= ST-LEN AND ST-TEXT(LS-POS:1) = "="
                ADD 1 TO LS-POS
                MOVE "=" TO LS-KIND
            END-IF
        WHEN "<"
            IF LS-POS <= ST-LEN
                    AND (ST-TEXT(LS-POS:1) = "=" OR ST-TEXT(LS-POS:1) = ">")
                ADD 1 TO LS-POS
            END-IF
        WHEN ">"
            IF LS-POS <= ST-LEN AND ST-TEXT(LS-POS:1) = "="
                ADD 1 TO LS-POS
            END-IF
        WHEN "+"
        WHEN "-"
        WHEN "/"
        WHEN "&"
            CONTINUE
        WHEN OTHER
            MOVE LS-START TO LS-DIAG-POS
            MOVE SPACES TO LS-MESSAGE
            STRING "unexpected character '" LS-CH "'"
                DELIMITED BY SIZE INTO LS-MESSAGE
            PERFORM REPORT-ERROR-LX002
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE ST-TEXT(LS-START:LS-POS - LS-START) TO LS-BUF
    COMPUTE LS-BUF-LEN = LS-POS - LS-START
    PERFORM ADD-TOKEN.

TAKE-IF-NEXT-IS-STAR.
    IF LS-POS <= ST-LEN AND ST-TEXT(LS-POS:1) = "*"
        ADD 1 TO LS-POS
    END-IF.

TAKE-UPPER-TEXT.
    COMPUTE LS-BUF-LEN = LS-POS - LS-START
    IF LS-BUF-LEN > LENGTH OF LS-BUF
        MOVE LENGTH OF LS-BUF TO LS-BUF-LEN
    END-IF
    MOVE ST-TEXT(LS-START:LS-BUF-LEN) TO LS-BUF
    INSPECT LS-BUF(1:LS-BUF-LEN) CONVERTING
        "abcdefghijklmnopqrstuvwxyz" TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ".

*> Append a token of kind LS-KIND spanning LS-START up to LS-POS,
*> with text LS-BUF(1:LS-BUF-LEN).
ADD-TOKEN.
    IF TK-COUNT >= TK-MAX OR TK-TEXT-USED + LS-BUF-LEN > TK-TEXT-SIZE
        MOVE "Y" TO LS-FULL
        MOVE LS-START TO LS-DIAG-POS
        PERFORM LOCATE-DIAG
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "LX005"
            ST-FILE-ID LS-LINE-NO LS-COLUMN
            "too many tokens; the rest of the input is ignored"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO TK-COUNT
    MOVE LS-KIND TO TK-KIND(TK-COUNT)
    MOVE LS-PREFIX TO TK-PREFIX(TK-COUNT)
    MOVE ST-FILE-ID TO TK-FILE-ID(TK-COUNT)
    MOVE 0 TO TK-INCL(TK-COUNT)
    CALL "PLB-STREAM-LOCATE" USING PLB-STREAM LS-START LS-SEG
        LS-LINE LS-COLUMN
    MOVE LS-LINE TO TK-SRC-LINE(TK-COUNT)
    MOVE LS-COLUMN TO TK-COLUMN(TK-COUNT)
    COMPUTE TK-SPAN(TK-COUNT) = LS-POS - LS-START
    COMPUTE TK-TEXT-OFF(TK-COUNT) = TK-TEXT-USED + 1
    MOVE LS-BUF-LEN TO TK-TEXT-LEN(TK-COUNT)
    IF LS-BUF-LEN > 0
        MOVE LS-BUF(1:LS-BUF-LEN)
            TO TK-TEXT(TK-TEXT-USED + 1:LS-BUF-LEN)
        ADD LS-BUF-LEN TO TK-TEXT-USED
    END-IF.

*> Set LS-LINE-NO and LS-COLUMN for stream position LS-DIAG-POS.
LOCATE-DIAG.
    MOVE 0 TO LS-LINE-NO
    CALL "PLB-STREAM-LOCATE" USING PLB-STREAM LS-DIAG-POS LS-SEG
        LS-LINE LS-COLUMN
    IF LS-LINE > 0
        MOVE SL-LINE-NO(LS-LINE) TO LS-LINE-NO
    END-IF.

REPORT-ERROR.
    PERFORM LOCATE-DIAG
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "LX001"
        ST-FILE-ID LS-LINE-NO LS-COLUMN LS-MESSAGE.

REPORT-ERROR-LX002.
    PERFORM LOCATE-DIAG
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "LX002"
        ST-FILE-ID LS-LINE-NO LS-COLUMN LS-MESSAGE.
END PROGRAM PLB-LEX-SCAN.

*> PLB-TOK-TEXT: the text of token INDEX, space filled; LENGTH is 0
*> for an index out of range or an empty token.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-TOK-TEXT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-TOKENS LK-INDEX LK-TEXT LK-LENGTH.
    MOVE SPACES TO LK-TEXT
    MOVE 0 TO LK-LENGTH
    IF LK-INDEX < 1 OR LK-INDEX > TK-COUNT
        GOBACK
    END-IF
    MOVE TK-TEXT-LEN(LK-INDEX) TO LK-LENGTH
    IF LK-LENGTH > FUNCTION LENGTH(LK-TEXT)
        MOVE FUNCTION LENGTH(LK-TEXT) TO LK-LENGTH
    END-IF
    IF LK-LENGTH > 0
        MOVE TK-TEXT(TK-TEXT-OFF(LK-INDEX):LK-LENGTH)
            TO LK-TEXT(1:LK-LENGTH)
    END-IF
    GOBACK.
END PROGRAM PLB-TOK-TEXT.
