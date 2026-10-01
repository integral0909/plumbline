*> ---------------------------------------------------------------
*> plbrsec: security rules.
*>
*>   PLB-S002  hard-coded-credential
*>   PLB-S003  sensitive-data-displayed
*>   PLB-S004  shell-command
*>
*> What an item holds is guessed from its name: a name is split at its
*> hyphens, and a part such as PASSWORD or PIN marks it. Whole parts
*> only, so that PINNED or PASSWORDS-TABLE-COUNT do not count as they
*> would by substring; see SENSITIVE-PART for the lists.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-SECURITY.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Per symbol (SY-MAX entries): "C" a credential (password, secret, key), "S" other
*> sensitive data (PIN, SSN, card security code), space neither.
01  WS-SENSITIVE            PIC X OCCURS 100000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE-CREDENTIAL      PIC 9(4) COMP-5.
01  LS-RULE-DISPLAY         PIC 9(4) COMP-5.
01  LS-RULE-SHELL           PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-NAME                 PIC X(31).
01  LS-PART                 PIC X(31).
01  LS-CHAR                 PIC X.
01  LS-ABOUT                PIC X.
01  LS-POS                  PIC 9(4) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-KIND                 PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-S002" LS-RULE-CREDENTIAL
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-S003" LS-RULE-DISPLAY
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-S004" LS-RULE-SHELL
    PERFORM CLASSIFY-SYMBOLS
    PERFORM CHECK-VALUES
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-STMT(LS-R) > 0
            MOVE RF-STMT(LS-R) TO LS-STMT
            IF ND-KIND(LS-STMT) = "STMT"
                EVALUATE ND-DETAIL(LS-STMT)
                    WHEN "MOVE"
                        PERFORM CHECK-MOVED-CREDENTIAL
                    WHEN "DISPLAY"
                        PERFORM CHECK-DISPLAYED
                END-EVALUATE
            END-IF
        END-IF
    END-PERFORM
    PERFORM CHECK-SHELL-CALLS
    GOBACK.

*> Which items hold credentials or other sensitive data, by name.
CLASSIFY-SYMBOLS.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE SPACE TO WS-SENSITIVE(LS-S)
        MOVE SY-NAME(LS-S) TO LS-NAME
        IF SY-LEVEL(LS-S) NOT = 88 AND LS-NAME NOT = SPACES
            PERFORM CLASSIFY-NAME
            MOVE LS-KIND TO WS-SENSITIVE(LS-S)
        END-IF
    END-PERFORM.

*> LS-KIND = "C", "S", or space for name LS-NAME. A part that names
*> something about the data rather than the data itself (a length, a
*> count, a flag) clears it: PASSWORD-LENGTH and PIN-RETRY-COUNT hold
*> no secret.
CLASSIFY-NAME.
    MOVE SPACE TO LS-KIND
    MOVE "N" TO LS-ABOUT
    MOVE SPACES TO LS-PART
    MOVE 0 TO LS-I
    PERFORM VARYING LS-POS FROM 1 BY 1 UNTIL LS-POS > 32
        IF LS-POS = 32
            MOVE SPACE TO LS-CHAR
        ELSE
            MOVE LS-NAME(LS-POS:1) TO LS-CHAR
        END-IF
        IF LS-CHAR = "-" OR LS-CHAR = SPACE
            IF LS-I > 0
                PERFORM SENSITIVE-PART
            END-IF
            MOVE SPACES TO LS-PART
            MOVE 0 TO LS-I
            IF LS-CHAR = SPACE
                EXIT PERFORM
            END-IF
        ELSE
            ADD 1 TO LS-I
            MOVE LS-CHAR TO LS-PART(LS-I:1)
        END-IF
    END-PERFORM
    IF LS-ABOUT = "Y"
        MOVE SPACE TO LS-KIND
    END-IF.

*> The parts of names that mark them, or that say the item only
*> describes the data.
SENSITIVE-PART.
    EVALUATE LS-PART
        WHEN "PASSWORD" WHEN "PASSWD" WHEN "PWD" WHEN "PASSPHRASE"
        WHEN "PASSCODE" WHEN "SECRET" WHEN "APIKEY" WHEN "CREDENTIAL"
        WHEN "CREDENTIALS"
            MOVE "C" TO LS-KIND
        WHEN "PIN" WHEN "SSN" WHEN "CVV" WHEN "CVC" WHEN "CVV2"
        WHEN "TAXID"
            IF LS-KIND = SPACE
                MOVE "S" TO LS-KIND
            END-IF
        WHEN "LEN" WHEN "LENGTH" WHEN "SIZE" WHEN "COUNT" WHEN "CNT"
        WHEN "CTR" WHEN "RETRY" WHEN "RETRIES" WHEN "TRIES"
        WHEN "ATTEMPTS" WHEN "FLAG" WHEN "SW" WHEN "SWITCH" WHEN "IND"
        WHEN "STATUS" WHEN "DATE" WHEN "EXPIRY" WHEN "EXPIRES"
        WHEN "MIN" WHEN "MAX" WHEN "RULES" WHEN "POLICY" WHEN "PROMPT"
        WHEN "MSG" WHEN "MESSAGE" WHEN "LABEL" WHEN "TEXT" WHEN "FIELD"
        WHEN "COL" WHEN "ROW" WHEN "POS"
            MOVE "Y" TO LS-ABOUT
    END-EVALUATE.

*> PLB-S002: VALUE "literal" on a credential item.
CHECK-VALUES.
    IF RL-ENABLED(LS-RULE-CREDENTIAL) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF WS-SENSITIVE(LS-S) = "C" AND SY-HAS-VALUE(LS-S) = "Y"
            MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-CHILD
            PERFORM UNTIL LS-CHILD = 0
                IF ND-KIND(LS-CHILD) = "CLAU"
                   AND ND-DETAIL(LS-CHILD) = "VALUE"
                    PERFORM CHECK-VALUE-LITERAL
                END-IF
                MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
            END-PERFORM
        END-IF
    END-PERFORM.

*> A non-blank alphanumeric literal in VALUE clause LS-CHILD.
CHECK-VALUE-LITERAL.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-ALNUM(LS-T) AND TK-TEXT-LEN(LS-T) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT NOT = SPACES
                MOVE SPACES TO LS-MESSAGE
                STRING SY-NAME(LS-S) DELIMITED BY SPACE
                       " is given a credential written into the program"
                       DELIMITED BY SIZE
                       " (VALUE); read it from a protected source"
                       DELIMITED BY SIZE
                    INTO LS-MESSAGE
                CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                    PLB-RULES PLB-FINDINGS LS-RULE-CREDENTIAL LS-T
                    LS-MESSAGE
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> PLB-S002: MOVE "literal" TO credential item (reference LS-R, the
*> receiver).
CHECK-MOVED-CREDENTIAL.
    IF RL-ENABLED(LS-RULE-CREDENTIAL) NOT = "Y"
       OR RF-ROLE(LS-R) NOT = "D"
        EXIT PARAGRAPH
    END-IF
    IF WS-SENSITIVE(RF-SYMBOL(LS-R)) NOT = "C"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    IF NOT TK-IS-ALNUM(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(RF-SYMBOL(LS-R)) DELIMITED BY SPACE
           " is given a credential written into the program (MOVE);"
           DELIMITED BY SIZE
           " read it from a protected source" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-CREDENTIAL LS-T LS-MESSAGE.

*> PLB-S003: DISPLAY of a credential or other sensitive item.
CHECK-DISPLAYED.
    IF RL-ENABLED(LS-RULE-DISPLAY) NOT = "Y"
       OR RF-ROLE(LS-R) NOT = "U"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF WS-SENSITIVE(LS-S) = SPACE
        EXIT PARAGRAPH
    END-IF
    IF WS-SENSITIVE(LS-S) = "C"
        MOVE "a credential" TO LS-TEXT
    ELSE
        MOVE "personal data" TO LS-TEXT
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "DISPLAY writes " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           ", which looks like " DELIMITED BY SIZE
           LS-TEXT DELIMITED BY "  "
           ", where logs keep it" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-DISPLAY RF-TOKEN(LS-R) LS-MESSAGE.

*> PLB-S004: CALL "SYSTEM" (or another routine that runs a command)
*> USING a data item rather than a literal.
CHECK-SHELL-CALLS.
    IF RL-ENABLED(LS-RULE-SHELL) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-N
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-N = 0
        IF ND-KIND(LS-N) = "STMT" AND ND-DETAIL(LS-N) = "CALL"
            PERFORM CHECK-SHELL-CALL
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-N LS-DEPTH
    END-PERFORM.

CHECK-SHELL-CALL.
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF NOT TK-IS-ALNUM(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    EVALUATE LS-TEXT
        WHEN "SYSTEM" WHEN "C$SYSTEM" WHEN "CBL_EXEC_RUN_UNIT"
        WHEN "C$RUN" WHEN "CBL_OS_COMMAND"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    *> The first argument after USING (and BY CONTENT/REFERENCE).
    PERFORM VARYING LS-T FROM LS-T BY 1 UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-NAME LS-LEN
            IF LS-NAME = "USING"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    ADD 1 TO LS-T
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF NOT TK-IS-WORD(LS-T)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-NAME LS-LEN
        IF LS-NAME NOT = "BY" AND LS-NAME NOT = "CONTENT"
           AND LS-NAME NOT = "REFERENCE"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-T
    END-PERFORM
    IF LS-T > ND-TOK-LAST(LS-N) OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "the command that " DELIMITED BY SIZE
           LS-TEXT DELIMITED BY SPACE
           " runs comes from " DELIMITED BY SIZE
           LS-NAME DELIMITED BY SPACE
           "; make sure no outside input reaches it unchecked"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-SHELL LS-T LS-MESSAGE.
END PROGRAM PLB-RULE-SECURITY.
