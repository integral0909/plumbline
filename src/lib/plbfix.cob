*> ---------------------------------------------------------------
*> plbfix: fixes for findings that have one obvious repair.
*>
*> PLB-FIX-FINDING USING SOURCE TOKENS AST RULES FINDINGS INDEX FIX
*> sets FIX (plbfix.cpy) to the fix for finding INDEX, or to none:
*>
*>   PLB-C004  CONTINUE in place of NEXT SENTENCE, in the case NEXT
*>             was written in (when SENTENCE is on a line of its own
*>             after NEXT, CONTINUE in place of NEXT, and SENTENCE
*>             taken out)
*>   PLB-C071  each AND of the contradictory condition made OR, or
*>             each OR made AND, in the case each was written in
*>   PLB-C074  the two ends of the reversed THRU range swapped, as
*>             written
*>   PLB-C079  the quotes taken off a literal that is a number written
*>             in quotes ("1.50" becomes 1.50); a literal that is no
*>             number ("ABC") has no fix
*>
*> The finding's lines must still be loaded, and every token the fix
*> touches must be in the finding's file (not brought in by a COPY)
*> and on one line. The language server offers these fixes as quick
*> fixes; plumbline fix applies them.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIX-FINDING.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-LOW                  PIC 9(9) COMP-5.
01  LS-HIGH                 PIC 9(9) COMP-5.
01  LS-OTHER                PIC 9(9) COMP-5.
01  LS-OK                   PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-JOIN                 PIC X(3).
01  LS-JOIN-TO              PIC X(3).
01  LS-NEW                  PIC X(256).
01  LS-NEW-LEN              PIC 9(9) COMP-5.
01  LS-FIRST-CHAR           PIC X.
01  LS-POINT                PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-FINDING              PIC 9(9) COMP-5.
COPY "plbfix.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS LK-FINDING PLB-FIX.
    MOVE SPACES TO FX-TITLE
    MOVE 0 TO FX-EDIT-COUNT
    IF LK-FINDING = 0 OR LK-FINDING > FN-COUNT
        GOBACK
    END-IF
    IF FN-SRC-LINE(LK-FINDING) = 0
        GOBACK
    END-IF
    *> Most findings have no fix: no search for their token.
    IF RL-ID(FN-RULE(LK-FINDING)) NOT = "PLB-C004"
       AND RL-ID(FN-RULE(LK-FINDING)) NOT = "PLB-C071"
       AND RL-ID(FN-RULE(LK-FINDING)) NOT = "PLB-C074"
       AND RL-ID(FN-RULE(LK-FINDING)) NOT = "PLB-C079"
        GOBACK
    END-IF
    *> The token the finding is reported at.
    MOVE 0 TO LS-TOKEN
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > TK-COUNT
        IF TK-SRC-LINE(LS-T) = FN-SRC-LINE(LK-FINDING)
           AND TK-COLUMN(LS-T) = FN-COLUMN(LK-FINDING)
            MOVE LS-T TO LS-TOKEN
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-TOKEN = 0
        GOBACK
    END-IF
    EVALUATE RL-ID(FN-RULE(LK-FINDING))
        WHEN "PLB-C004"
            PERFORM FIX-NEXT-SENTENCE
        WHEN "PLB-C071"
            PERFORM FIX-CONTRADICTION
        WHEN "PLB-C074"
            PERFORM FIX-REVERSED-RANGE
        WHEN "PLB-C079"
            PERFORM FIX-QUOTED-NUMBER
    END-EVALUATE
    IF FX-EDIT-COUNT = 0
        MOVE SPACES TO FX-TITLE
    END-IF
    GOBACK.

*> PLB-C004: NEXT at LS-TOKEN, SENTENCE after it.
FIX-NEXT-SENTENCE.
    IF LS-TOKEN >= TK-COUNT
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-HIGH = LS-TOKEN + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-HIGH LS-TEXT LS-LEN
    IF LS-TEXT NOT = "SENTENCE"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TOKEN TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-HIGH TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE "Change NEXT SENTENCE to CONTINUE" TO FX-TITLE
    MOVE LS-TOKEN TO LS-T
    PERFORM FIRST-CHARACTER
    IF LS-FIRST-CHAR IS ALPHABETIC-LOWER
        MOVE "continue" TO LS-NEW
    ELSE
        MOVE "CONTINUE" TO LS-NEW
    END-IF
    MOVE 8 TO LS-NEW-LEN
    MOVE LS-TOKEN TO LS-LOW
    IF TK-SRC-LINE(LS-HIGH) = TK-SRC-LINE(LS-TOKEN)
        PERFORM ADD-EDIT
        EXIT PARAGRAPH
    END-IF
    *> Two lines: one edit each, so that neither spans lines.
    MOVE LS-HIGH TO LS-OTHER
    MOVE LS-TOKEN TO LS-HIGH
    PERFORM ADD-EDIT
    MOVE LS-OTHER TO LS-LOW LS-HIGH
    MOVE SPACES TO LS-NEW
    MOVE 0 TO LS-NEW-LEN
    PERFORM ADD-EDIT.

*> PLB-C071: the innermost condition holding LS-TOKEN, from there to
*> its end; its join is its first AND or OR.
FIX-CONTRADICTION.
    MOVE 0 TO LS-COND
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "COND"
           AND ND-TOK-FIRST(LS-NODE) <= LS-TOKEN
           AND ND-TOK-LAST(LS-NODE) >= LS-TOKEN
            IF LS-COND = 0
                MOVE LS-NODE TO LS-COND
            ELSE
                IF ND-TOK-LAST(LS-NODE) - ND-TOK-FIRST(LS-NODE)
                   < ND-TOK-LAST(LS-COND) - ND-TOK-FIRST(LS-COND)
                    MOVE LS-NODE TO LS-COND
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF LS-COND = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-JOIN
    PERFORM VARYING LS-T FROM LS-TOKEN BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND) OR LS-JOIN NOT = SPACES
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "AND" OR LS-TEXT = "OR"
                MOVE LS-TEXT TO LS-JOIN
            END-IF
        END-IF
    END-PERFORM
    IF LS-JOIN = SPACES
        EXIT PARAGRAPH
    END-IF
    IF LS-JOIN = "AND"
        MOVE "OR" TO LS-JOIN-TO
    ELSE
        MOVE "AND" TO LS-JOIN-TO
    END-IF
    *> Every join must be one the fix can change.
    PERFORM VARYING LS-T FROM LS-TOKEN BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = LS-JOIN
                PERFORM TEST-TOKEN
                IF LS-OK = "N"
                    MOVE 0 TO FX-EDIT-COUNT
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-PERFORM
    MOVE SPACES TO FX-TITLE
    STRING "Change " DELIMITED BY SIZE
           LS-JOIN DELIMITED BY SPACE
           " to " DELIMITED BY SIZE
           LS-JOIN-TO DELIMITED BY SPACE
           " in this condition" DELIMITED BY SIZE
        INTO FX-TITLE
    PERFORM VARYING LS-T FROM LS-TOKEN BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = LS-JOIN AND FX-EDIT-COUNT < FX-EDIT-MAX
                PERFORM FIRST-CHARACTER
                IF LS-FIRST-CHAR IS ALPHABETIC-LOWER
                    MOVE FUNCTION LOWER-CASE(LS-JOIN-TO) TO LS-NEW
                ELSE
                    MOVE LS-JOIN-TO TO LS-NEW
                END-IF
                MOVE 0 TO LS-NEW-LEN
                INSPECT LS-JOIN-TO TALLYING LS-NEW-LEN
                    FOR CHARACTERS BEFORE SPACE
                MOVE LS-T TO LS-LOW
                MOVE LS-T TO LS-HIGH
                PERFORM ADD-EDIT
            END-IF
        END-IF
    END-PERFORM.

*> PLB-C074: the range LS-TOKEN THRU (or THROUGH) the token after.
FIX-REVERSED-RANGE.
    IF LS-TOKEN + 2 > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = LS-TOKEN + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT NOT = "THRU" AND LS-TEXT NOT = "THROUGH"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TOKEN TO LS-LOW
    COMPUTE LS-HIGH = LS-TOKEN + 2
    MOVE LS-LOW TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-HIGH TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE "Swap the ends of this range" TO FX-TITLE
    *> The low end gets the high end's text, and the other way round.
    MOVE LS-HIGH TO LS-OTHER
    MOVE LS-HIGH TO LS-T
    PERFORM TOKEN-AS-WRITTEN
    MOVE LS-LOW TO LS-HIGH
    PERFORM ADD-EDIT
    MOVE LS-LOW TO LS-T
    PERFORM TOKEN-AS-WRITTEN
    MOVE LS-OTHER TO LS-LOW LS-HIGH
    PERFORM ADD-EDIT.

*> PLB-C079, reported at a receiver of a MOVE: the literal sent, when
*> it is a number in quotes: [sign] digits [. digits], or with a
*> comma for the point.
FIX-QUOTED-NUMBER.
    MOVE 0 TO LS-NODE
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > AS-COUNT
        IF ND-KIND(LS-T) = "STMT" AND ND-DETAIL(LS-T) = "MOVE"
           AND ND-TOK-FIRST(LS-T) < LS-TOKEN
           AND ND-TOK-LAST(LS-T) >= LS-TOKEN
            MOVE LS-T TO LS-NODE
        END-IF
    END-PERFORM
    IF LS-NODE = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-LOW = ND-TOK-FIRST(LS-NODE) + 1
    IF NOT TK-IS-ALNUM(LS-LOW) OR TK-PREFIX(LS-LOW) NOT = SPACES
       OR TK-TEXT-LEN(LS-LOW) = 0 OR TK-TEXT-LEN(LS-LOW) > 31
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-NEW
    MOVE TK-TEXT(TK-TEXT-OFF(LS-LOW):TK-TEXT-LEN(LS-LOW)) TO LS-NEW
    MOVE TK-TEXT-LEN(LS-LOW) TO LS-NEW-LEN
    PERFORM TEST-NUMBER
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-LOW TO LS-T
    PERFORM TEST-TOKEN
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE "Take the quotes off this number" TO FX-TITLE
    MOVE LS-LOW TO LS-HIGH
    PERFORM ADD-EDIT.

*> LS-OK = "Y" when LS-NEW(1:LS-NEW-LEN) is [+|-] digits [. or ,
*> digits], with at least one digit.
TEST-NUMBER.
    MOVE "N" TO LS-OK
    MOVE 0 TO LS-LEN
    MOVE "N" TO LS-POINT
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > LS-NEW-LEN
        EVALUATE TRUE
            WHEN LS-NEW(LS-T:1) >= "0" AND LS-NEW(LS-T:1) <= "9"
                ADD 1 TO LS-LEN
            WHEN (LS-NEW(LS-T:1) = "+" OR LS-NEW(LS-T:1) = "-")
                 AND LS-T = 1
                CONTINUE
            WHEN (LS-NEW(LS-T:1) = "." OR LS-NEW(LS-T:1) = ",")
                 AND LS-POINT = "N" AND LS-T < LS-NEW-LEN
                MOVE "Y" TO LS-POINT
            WHEN OTHER
                EXIT PARAGRAPH
        END-EVALUATE
    END-PERFORM
    IF LS-LEN > 0
        MOVE "Y" TO LS-OK
    END-IF.

*> LS-OK = "Y" when token LS-T is in the finding's file, written
*> there (not brought in by a COPY), and on one line.
TEST-TOKEN.
    MOVE "N" TO LS-OK
    IF TK-FILE-ID(LS-T) NOT = FN-FILE-ID(LK-FINDING)
       OR TK-INCL(LS-T) NOT = 0 OR TK-SRC-LINE(LS-T) = 0
       OR TK-SPAN(LS-T) > 256
        EXIT PARAGRAPH
    END-IF
    IF TK-COLUMN(LS-T) - 1 + TK-SPAN(LS-T)
       > SL-TEXT-LEN(TK-SRC-LINE(LS-T))
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-OK.

*> LS-FIRST-CHAR: the first character of token LS-T as written.
FIRST-CHARACTER.
    MOVE SS-HEAP(SL-TEXT-OFF(TK-SRC-LINE(LS-T)) + TK-COLUMN(LS-T) - 1:1)
        TO LS-FIRST-CHAR.

*> LS-NEW: token LS-T as written.
TOKEN-AS-WRITTEN.
    MOVE SPACES TO LS-NEW
    MOVE SS-HEAP(SL-TEXT-OFF(TK-SRC-LINE(LS-T)) + TK-COLUMN(LS-T) - 1
                 :TK-SPAN(LS-T)) TO LS-NEW
    MOVE TK-SPAN(LS-T) TO LS-NEW-LEN.

*> An edit putting LS-NEW(1:LS-NEW-LEN) from the start of token LS-LOW
*> to the end of token LS-HIGH.
ADD-EDIT.
    IF FX-EDIT-COUNT >= FX-EDIT-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO FX-EDIT-COUNT
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-LOW)) TO FX-LINE(FX-EDIT-COUNT)
    MOVE TK-COLUMN(LS-LOW) TO FX-COLUMN(FX-EDIT-COUNT)
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-HIGH)) TO FX-END-LINE(FX-EDIT-COUNT)
    COMPUTE FX-END-COLUMN(FX-EDIT-COUNT)
        = TK-COLUMN(LS-HIGH) + TK-SPAN(LS-HIGH)
    MOVE LS-NEW TO FX-TEXT(FX-EDIT-COUNT)
    MOVE LS-NEW-LEN TO FX-TEXT-LEN(FX-EDIT-COUNT).
END PROGRAM PLB-FIX-FINDING.

*> ---------------------------------------------------------------
*> PLB-FIX-ACCEPT USING SOURCE FILE-ID FIX LIST RESULT adds the edits
*> of FIX to LIST, all or none, and sets RESULT:
*>   Y  added
*>   S  an edit spans lines (an editor can make it; this cannot)
*>   O  an edit overlaps one already in LIST (an edit the same as one
*>      in LIST, from another finding of the same statement, is
*>      taken as made)
*>   M  in fixed format, a line would grow past column 72: the blanks
*>      before column 73 are what a line may grow into, so that the
*>      sequence area stays where it is
*>   F  LIST is full
*> The lines of FILE-ID must be loaded.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIX-ACCEPT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-L                    PIC 9(9) COMP-5.
01  LS-GROWTH               PIC S9(9) COMP-5.
01  LS-SPARE                PIC S9(9) COMP-5.
*> "Y" for an edit of FIX that LIST already has.
01  LS-SAME                 PIC X OCCURS 64 TIMES.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
COPY "plbfix.cpy".
COPY "plbfixl.cpy".
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID PLB-FIX PLB-FIX-LIST
        LK-RESULT.
    IF FXL-COUNT + FX-EDIT-COUNT > FXL-MAX
        MOVE "F" TO LK-RESULT
        GOBACK
    END-IF
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FX-EDIT-COUNT
        IF FX-END-LINE(LS-E) NOT = FX-LINE(LS-E)
            MOVE "S" TO LK-RESULT
            GOBACK
        END-IF
        MOVE "N" TO LS-SAME(LS-E)
        PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FXL-COUNT
            IF FXL-LINE(LS-K) = FX-LINE(LS-E)
               AND FXL-COLUMN(LS-K) = FX-COLUMN(LS-E)
               AND FXL-END-COLUMN(LS-K) = FX-END-COLUMN(LS-E)
               AND FXL-TEXT-LEN(LS-K) = FX-TEXT-LEN(LS-E)
               AND FXL-TEXT(LS-K) = FX-TEXT(LS-E)
                MOVE "Y" TO LS-SAME(LS-E)
                EXIT PERFORM
            END-IF
            IF FXL-LINE(LS-K) = FX-LINE(LS-E)
               AND FXL-COLUMN(LS-K) < FX-END-COLUMN(LS-E)
               AND FX-COLUMN(LS-E) < FXL-END-COLUMN(LS-K)
                MOVE "O" TO LK-RESULT
                GOBACK
            END-IF
        END-PERFORM
    END-PERFORM
    *> Each line an edit is on: how much the line grows, with the edits
    *> already accepted, against the blanks it has before column 73.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FX-EDIT-COUNT
        COMPUTE LS-L = SF-FIRST-LINE(LK-FILE-ID) + FX-LINE(LS-E) - 1
        IF SL-FORMAT(LS-L) = "X"
            MOVE 0 TO LS-GROWTH
            PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FX-EDIT-COUNT
                IF FX-LINE(LS-K) = FX-LINE(LS-E) AND LS-SAME(LS-K) = "N"
                    COMPUTE LS-GROWTH = LS-GROWTH + FX-TEXT-LEN(LS-K)
                        - FX-END-COLUMN(LS-K) + FX-COLUMN(LS-K)
                END-IF
            END-PERFORM
            PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FXL-COUNT
                IF FXL-LINE(LS-K) = FX-LINE(LS-E)
                    COMPUTE LS-GROWTH = LS-GROWTH + FXL-TEXT-LEN(LS-K)
                        - FXL-END-COLUMN(LS-K) + FXL-COLUMN(LS-K)
                END-IF
            END-PERFORM
            IF LS-GROWTH > 0
                PERFORM FIND-SPARE
                IF LS-GROWTH > LS-SPARE
                    MOVE "M" TO LK-RESULT
                    GOBACK
                END-IF
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FX-EDIT-COUNT
        IF LS-SAME(LS-E) = "N"
            ADD 1 TO FXL-COUNT
            MOVE FX-LINE(LS-E) TO FXL-LINE(FXL-COUNT)
            MOVE FX-COLUMN(LS-E) TO FXL-COLUMN(FXL-COUNT)
            MOVE FX-END-COLUMN(LS-E) TO FXL-END-COLUMN(FXL-COUNT)
            MOVE FX-TEXT(LS-E) TO FXL-TEXT(FXL-COUNT)
            MOVE FX-TEXT-LEN(LS-E) TO FXL-TEXT-LEN(FXL-COUNT)
        END-IF
    END-PERFORM
    MOVE "Y" TO LK-RESULT
    GOBACK.

*> LS-SPARE: the blanks at the end of columns 1 to 72 of line LS-L.
FIND-SPARE.
    MOVE 72 TO LS-SPARE
    IF SL-TEXT-LEN(LS-L) < 72
        MOVE SL-TEXT-LEN(LS-L) TO LS-K
    ELSE
        MOVE 72 TO LS-K
    END-IF
    PERFORM UNTIL LS-K = 0
        IF SS-HEAP(SL-TEXT-OFF(LS-L) + LS-K - 1:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-K
    END-PERFORM
    COMPUTE LS-SPARE = 72 - LS-K.
END PROGRAM PLB-FIX-ACCEPT.

*> ---------------------------------------------------------------
*> PLB-FIX-WRITE USING SOURCE FILE-ID LIST writes file FILE-ID to
*> standard output with the edits of LIST made, one line at a time, as
*> it was read: tabs expanded, trailing spaces dropped, a blank line
*> empty (DISPLAY cannot write an empty line, so the C library's
*> putchar writes its line feed). In fixed format
*> a line that grows or shrinks keeps its columns 73 on where they
*> were: it grows into the blanks before column 73, and a line that
*> shrinks gets blanks there.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIX-WRITE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TEXT                 PIC X(1024).
01  WS-OUT                  PIC X(1024).
LOCAL-STORAGE SECTION.
01  LS-L                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-GROWTH               PIC S9(9) COMP-5.
01  LS-EDITS                PIC 9(9) COMP-5.
01  LS-KEEP                 PIC S9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
COPY "plbfixl.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET LK-FILE-ID PLB-FIX-LIST.
    IF LK-FILE-ID < 1 OR LK-FILE-ID > SS-FILE-COUNT
        GOBACK
    END-IF
    MOVE SF-FIRST-LINE(LK-FILE-ID) TO LS-L
    COMPUTE LS-LAST = SF-FIRST-LINE(LK-FILE-ID)
        + SF-LINE-COUNT(LK-FILE-ID) - 1
    PERFORM VARYING LS-L FROM LS-L BY 1 UNTIL LS-L > LS-LAST
        PERFORM EDIT-LINE
        PERFORM WRITE-LINE
    END-PERFORM
    GOBACK.

*> WS-OUT(1:LS-PTR - 1): line LS-L with its edits made, in column
*> order.
EDIT-LINE.
    MOVE SPACES TO WS-TEXT WS-OUT
    MOVE SL-TEXT-LEN(LS-L) TO LS-LEN
    IF LS-LEN > 1024
        MOVE 1024 TO LS-LEN
    END-IF
    IF LS-LEN > 0
        MOVE SS-HEAP(SL-TEXT-OFF(LS-L):LS-LEN) TO WS-TEXT
    END-IF
    MOVE SL-LINE-NO(LS-L) TO LS-LINE-NO
    MOVE 1 TO LS-FROM LS-PTR
    MOVE 0 TO LS-GROWTH LS-EDITS
    PERFORM FIND-NEXT-EDIT
    PERFORM UNTIL LS-NEXT = 0
        ADD 1 TO LS-EDITS
        IF FXL-COLUMN(LS-NEXT) > LS-FROM
            STRING WS-TEXT(LS-FROM:FXL-COLUMN(LS-NEXT) - LS-FROM)
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
        END-IF
        IF FXL-TEXT-LEN(LS-NEXT) > 0
            STRING FXL-TEXT(LS-NEXT)(1:FXL-TEXT-LEN(LS-NEXT))
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
        END-IF
        COMPUTE LS-GROWTH = LS-GROWTH + FXL-TEXT-LEN(LS-NEXT)
            - FXL-END-COLUMN(LS-NEXT) + FXL-COLUMN(LS-NEXT)
        MOVE FXL-END-COLUMN(LS-NEXT) TO LS-FROM
        PERFORM FIND-NEXT-EDIT
    END-PERFORM
    IF LS-EDITS = 0
        MOVE WS-TEXT TO WS-OUT
        COMPUTE LS-PTR = LS-LEN + 1
        EXIT PARAGRAPH
    END-IF
    *> The rest of the line. In fixed format, columns 73 on stay put.
    IF SL-FORMAT(LS-L) = "X" AND LS-LEN > 72 AND LS-FROM <= 72
        *> A line that grew drops as many blanks before column 73; one
        *> that shrank keeps all, and blanks fill the columns left.
        COMPUTE LS-KEEP = 72 - LS-FROM + 1
        IF LS-GROWTH > 0
            SUBTRACT LS-GROWTH FROM LS-KEEP
        END-IF
        IF LS-KEEP > 0
            STRING WS-TEXT(LS-FROM:LS-KEEP)
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
        END-IF
        MOVE 73 TO LS-PTR
        STRING WS-TEXT(73:LS-LEN - 72)
            DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
    ELSE
        IF LS-FROM <= LS-LEN
            STRING WS-TEXT(LS-FROM:LS-LEN - LS-FROM + 1)
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER LS-PTR
        END-IF
    END-IF.

*> LS-NEXT: the edit of line LS-LINE-NO with the lowest column at or
*> after LS-FROM, or 0.
FIND-NEXT-EDIT.
    MOVE 0 TO LS-NEXT
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FXL-COUNT
        IF FXL-LINE(LS-K) = LS-LINE-NO AND FXL-COLUMN(LS-K) >= LS-FROM
            IF LS-NEXT = 0
                MOVE LS-K TO LS-NEXT
            ELSE
                IF FXL-COLUMN(LS-K) < FXL-COLUMN(LS-NEXT)
                    MOVE LS-K TO LS-NEXT
                END-IF
            END-IF
        END-IF
    END-PERFORM.

WRITE-LINE.
    CALL "PLB-STR-LENGTH" USING WS-OUT LS-LEN
    IF LS-LEN = 0
        CALL STATIC "putchar" USING BY VALUE 10
    ELSE
        DISPLAY WS-OUT(1:LS-LEN)
    END-IF.
END PROGRAM PLB-FIX-WRITE.

*> ---------------------------------------------------------------
*> PLB-FIX-KEEP USING FINDINGS INDEX FIX STORE keeps FIX, the fix of
*> finding INDEX, in STORE (plbfixs.cpy), when there is room for it
*> whole. A fix too large to write on one report line, its edits'
*> text taken twice for escaping, is not kept.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIX-KEEP.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-SIZE                 PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbfind.cpy".
01  LK-FINDING              PIC 9(9) COMP-5.
COPY "plbfix.cpy".
COPY "plbfixs.cpy".
PROCEDURE DIVISION USING PLB-FINDINGS LK-FINDING PLB-FIX PLB-FIX-STORE.
    IF FX-EDIT-COUNT = 0 OR FK-FIX-COUNT >= FK-FIX-MAX
       OR FK-EDIT-COUNT + FX-EDIT-COUNT > FK-EDIT-MAX
        GOBACK
    END-IF
    MOVE 200 TO LS-SIZE
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FX-EDIT-COUNT
        COMPUTE LS-SIZE = LS-SIZE + 160 + 2 * FX-TEXT-LEN(LS-E)
    END-PERFORM
    IF LS-SIZE > 2400
        GOBACK
    END-IF
    ADD 1 TO FK-FIX-COUNT
    MOVE FN-FILE-ID(LK-FINDING) TO FK-FILE-ID(FK-FIX-COUNT)
    MOVE FN-LINE(LK-FINDING) TO FK-LINE(FK-FIX-COUNT)
    MOVE FN-COLUMN(LK-FINDING) TO FK-COLUMN(FK-FIX-COUNT)
    MOVE FN-RULE(LK-FINDING) TO FK-RULE(FK-FIX-COUNT)
    MOVE FX-TITLE TO FK-TITLE(FK-FIX-COUNT)
    COMPUTE FK-FIRST-EDIT(FK-FIX-COUNT) = FK-EDIT-COUNT + 1
    MOVE FX-EDIT-COUNT TO FK-EDITS(FK-FIX-COUNT)
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FX-EDIT-COUNT
        ADD 1 TO FK-EDIT-COUNT
        MOVE FX-LINE(LS-E) TO FK-EDIT-LINE(FK-EDIT-COUNT)
        MOVE FX-COLUMN(LS-E) TO FK-EDIT-COLUMN(FK-EDIT-COUNT)
        MOVE FX-END-LINE(LS-E) TO FK-EDIT-END-LINE(FK-EDIT-COUNT)
        MOVE FX-END-COLUMN(LS-E) TO FK-EDIT-END-COLUMN(FK-EDIT-COUNT)
        MOVE FX-TEXT(LS-E) TO FK-EDIT-TEXT(FK-EDIT-COUNT)
        MOVE FX-TEXT-LEN(LS-E) TO FK-EDIT-TEXT-LEN(FK-EDIT-COUNT)
    END-PERFORM
    GOBACK.
END PROGRAM PLB-FIX-KEEP.

*> ---------------------------------------------------------------
*> PLB-FIX-FOR USING FINDINGS INDEX STORE FIX-INDEX sets FIX-INDEX to
*> the fix kept for finding INDEX, or 0.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIX-FOR.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-K                    PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbfind.cpy".
01  LK-FINDING              PIC 9(9) COMP-5.
COPY "plbfixs.cpy".
01  LK-FIX                  PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-FINDINGS LK-FINDING PLB-FIX-STORE LK-FIX.
    MOVE 0 TO LK-FIX
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > FK-FIX-COUNT
        IF FK-FILE-ID(LS-K) = FN-FILE-ID(LK-FINDING)
           AND FK-LINE(LS-K) = FN-LINE(LK-FINDING)
           AND FK-COLUMN(LS-K) = FN-COLUMN(LK-FINDING)
           AND FK-RULE(LS-K) = FN-RULE(LK-FINDING)
            MOVE LS-K TO LK-FIX
            GOBACK
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-FIX-FOR.
