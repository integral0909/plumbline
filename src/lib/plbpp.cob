*> ---------------------------------------------------------------
*> plbpp: the COPY and REPLACE preprocessor.
*>
*> PLB-PP-EXPAND turns a source file into the token stream the
*> compiler would see:
*>
*>   1. COPY statements are replaced by the tokens of the copybook,
*>      with any REPLACING operands applied to that copybook's own
*>      text (not to text of copybooks it copies in turn). Expansion
*>      is iterative, using an explicit stack of copybook frames.
*>   2. If the result contains REPLACE statements, a second pass
*>      applies them to the text that follows each one, as the
*>      standard specifies (REPLACE acts after COPY).
*>
*> Copybooks are looked up in the directory of the file holding the
*> COPY statement, then in each search path of PLB-PP-OPTIONS. Names
*> must be relative and may not contain ".." segments, so a COPY in
*> untrusted source can never read files outside those directories.
*>
*> Diagnostic codes raised here:
*>   PP001  error    copybook not found
*>   PP002  error    copybook copies itself, directly or indirectly
*>   PP003  error    malformed COPY statement
*>   PP004  error    copybook name is absolute or contains ".."
*>   PP005  error    copybooks nested too deeply
*>   PP006  error    malformed REPLACE statement
*>   PP007  error    preprocessor table full
*> ---------------------------------------------------------------

*> PLB-PP-INIT-OPTIONS: no search paths, no debugging lines, and
*> copybook format detected.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-INIT-OPTIONS.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbppopt.cpy".
PROCEDURE DIVISION USING PLB-PP-OPTIONS.
    MOVE 0 TO PO-PATH-COUNT
    MOVE "N" TO PO-DEBUG
    MOVE "A" TO PO-FORMAT
    GOBACK.
END PROGRAM PLB-PP-INIT-OPTIONS.

*> PLB-PP-ADD-PATH: append a copybook search directory. STATUS is 0
*> on success, 1 when the list is full.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-ADD-PATH.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbppopt.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-PP-OPTIONS LK-PATH LK-STATUS.
    IF PO-PATH-COUNT >= PO-MAX-PATHS
        MOVE 1 TO LK-STATUS
    ELSE
        ADD 1 TO PO-PATH-COUNT
        MOVE LK-PATH TO PO-PATH(PO-PATH-COUNT)
        MOVE 0 TO LK-STATUS
    END-IF
    GOBACK.
END PROGRAM PLB-PP-ADD-PATH.

*> PLB-PP-SAFE-NAME: RESULT = "Y" when NAME is a relative path with
*> no ".." segment. Backslashes count as separators too.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-SAFE-NAME.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-NAME                 PIC X(514).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING LK-NAME LK-RESULT.
    MOVE "N" TO LK-RESULT
    CALL "PLB-STR-LENGTH" USING LK-NAME LS-LEN
    IF LS-LEN = 0 OR LS-LEN > 512
        GOBACK
    END-IF
    IF LK-NAME(1:1) = "/" OR LK-NAME(1:1) = "\"
        GOBACK
    END-IF
    *> Surround the name with separators so every segment, including
    *> the first and last, appears as /segment/.
    MOVE SPACES TO LS-NAME
    STRING "/" LK-NAME(1:LS-LEN) "/" DELIMITED BY SIZE INTO LS-NAME
    INSPECT LS-NAME REPLACING ALL "\" BY "/"
    MOVE 0 TO LS-COUNT
    INSPECT LS-NAME TALLYING LS-COUNT FOR ALL "/../"
    IF LS-COUNT = 0
        MOVE "Y" TO LK-RESULT
    END-IF
    GOBACK.
END PROGRAM PLB-PP-SAFE-NAME.

*> PLB-PP-RESOLVE: find the file for copybook NAME (optionally in
*> LIBRARY) included from FROM-FILE-ID.
*>
*> Each directory (the including file's own, then each search path)
*> is tried with each spelling of the name. A literal name is used as
*> written. A word (which the lexer has upper-cased) is tried in lower
*> case first, then upper case; on a file system that ignores case, the
*> file's own name is then taken from the system, so that the path is
*> the same as a case-sensitive system finds. Each spelling is tried bare if it has
*> an extension, then with .cpy .CPY .cbl .CBL .cob .COB .dcl .DCL
*> (DB2 declarations, DCLGEN members), then bare.
*> STATUS: 0 found (PATH set), 1 not found, 2 unsafe name.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-RESOLVE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-EXTENSIONS.
    05  FILLER              PIC X(4) VALUE ".cpy".
    05  FILLER              PIC X(4) VALUE ".CPY".
    05  FILLER              PIC X(4) VALUE ".cbl".
    05  FILLER              PIC X(4) VALUE ".CBL".
    05  FILLER              PIC X(4) VALUE ".cob".
    05  FILLER              PIC X(4) VALUE ".COB".
    05  FILLER              PIC X(4) VALUE ".dcl".
    05  FILLER              PIC X(4) VALUE ".DCL".
01  WS-EXTENSION-TABLE REDEFINES WS-EXTENSIONS.
    05  WS-EXT              PIC X(4) OCCURS 8 TIMES.
LOCAL-STORAGE SECTION.
01  LS-SAFE                 PIC X.
01  LS-DIR-COUNT            PIC 9(4) COMP-5.
01  LS-DIR-INDEX            PIC 9(4) COMP-5.
01  LS-DIR                  PIC X(512).
01  LS-DIR-LEN              PIC 9(9) COMP-5.
01  LS-SPELLING             PIC 9(4) COMP-5.
01  LS-NAME                 PIC X(512).
01  LS-NAME-LEN             PIC 9(9) COMP-5.
01  LS-LIB-LEN              PIC 9(9) COMP-5.
01  LS-BASE                 PIC X(1100).
01  LS-BASE-LEN             PIC 9(9) COMP-5.
01  LS-CANDIDATE            PIC X(1100).
01  LS-PROBE                PIC X(1100).
01  LS-INFO                 PIC X(16).
*> For the file name as stored (STORED-NAME).
01  LS-C-PATH               PIC X(1101).
01  LS-REAL                 PIC X(4096).
01  LS-REAL-RESULT          USAGE POINTER.
01  LS-SLASH                PIC 9(9) COMP-5.
01  LS-REAL-SLASH           PIC 9(9) COMP-5.
01  LS-REAL-END             PIC 9(9) COMP-5.
01  LS-CAND-LEN             PIC 9(9) COMP-5.
01  LS-EXT-INDEX            PIC 9(4) COMP-5.
01  LS-HAS-EXT              PIC X.
01  LS-FOUND                PIC X.
01  LS-I                    PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbppopt.cpy".
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-LIBRARY              PIC X ANY LENGTH.
01  LK-IS-WORD              PIC X.
01  LK-FROM-FILE-ID         PIC 9(4) COMP-5.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-PP-OPTIONS LK-NAME
        LK-LIBRARY LK-IS-WORD LK-FROM-FILE-ID LK-PATH LK-STATUS.
    MOVE SPACES TO LK-PATH
    MOVE 1 TO LK-STATUS
    CALL "PLB-PP-SAFE-NAME" USING LK-NAME LS-SAFE
    IF LS-SAFE = "Y"
        CALL "PLB-STR-LENGTH" USING LK-LIBRARY LS-LIB-LEN
        IF LS-LIB-LEN > 0
            CALL "PLB-PP-SAFE-NAME" USING LK-LIBRARY LS-SAFE
        END-IF
    END-IF
    IF LS-SAFE NOT = "Y"
        MOVE 2 TO LK-STATUS
        GOBACK
    END-IF

    MOVE "N" TO LS-FOUND
    COMPUTE LS-DIR-COUNT = PO-PATH-COUNT + 1
    PERFORM VARYING LS-DIR-INDEX FROM 1 BY 1
            UNTIL LS-DIR-INDEX > LS-DIR-COUNT OR LS-FOUND = "Y"
        PERFORM SELECT-DIRECTORY
        PERFORM VARYING LS-SPELLING FROM 1 BY 1
                UNTIL LS-SPELLING > 3 OR LS-FOUND = "Y"
            PERFORM TRY-SPELLING
        END-PERFORM
    END-PERFORM
    IF LS-FOUND = "Y"
        MOVE LS-CANDIDATE TO LK-PATH
        MOVE 0 TO LK-STATUS
    END-IF
    GOBACK.

*> Directory 1 is that of the including file; the rest are the
*> search paths in order.
SELECT-DIRECTORY.
    MOVE SPACES TO LS-DIR
    IF LS-DIR-INDEX = 1
        IF LK-FROM-FILE-ID >= 1 AND LK-FROM-FILE-ID <= SS-FILE-COUNT
            MOVE SF-PATH(LK-FROM-FILE-ID) TO LS-DIR
            CALL "PLB-STR-LENGTH" USING LS-DIR LS-DIR-LEN
            *> Cut after the last "/", or to nothing if there is none.
            PERFORM VARYING LS-I FROM LS-DIR-LEN BY -1 UNTIL LS-I = 0
                IF LS-DIR(LS-I:1) = "/"
                    EXIT PERFORM
                END-IF
            END-PERFORM
            IF LS-I = 0
                MOVE SPACES TO LS-DIR
            ELSE
                MOVE SPACES TO LS-DIR(LS-I:)
            END-IF
        END-IF
    ELSE
        MOVE PO-PATH(LS-DIR-INDEX - 1) TO LS-DIR
    END-IF
    CALL "PLB-STR-LENGTH" USING LS-DIR LS-DIR-LEN.

TRY-SPELLING.
    MOVE LK-NAME TO LS-NAME
    EVALUATE TRUE
        WHEN LK-IS-WORD NOT = "Y"
            IF LS-SPELLING > 1
                EXIT PARAGRAPH
            END-IF
        WHEN LS-SPELLING = 1
            MOVE FUNCTION LOWER-CASE(LK-NAME) TO LS-NAME
        WHEN LS-SPELLING = 2
            MOVE FUNCTION UPPER-CASE(LK-NAME) TO LS-NAME
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    CALL "PLB-STR-LENGTH" USING LS-NAME LS-NAME-LEN

    MOVE SPACES TO LS-BASE
    MOVE 1 TO LS-I
    IF LS-DIR-LEN > 0
        STRING LS-DIR(1:LS-DIR-LEN) "/" DELIMITED BY SIZE
            INTO LS-BASE WITH POINTER LS-I
    END-IF
    IF LS-LIB-LEN > 0
        STRING LK-LIBRARY(1:LS-LIB-LEN) "/" DELIMITED BY SIZE
            INTO LS-BASE WITH POINTER LS-I
    END-IF
    STRING LS-NAME(1:LS-NAME-LEN) DELIMITED BY SIZE
        INTO LS-BASE WITH POINTER LS-I
    COMPUTE LS-BASE-LEN = LS-I - 1

    *> Does the last path segment already have an extension?
    MOVE "N" TO LS-HAS-EXT
    PERFORM VARYING LS-I FROM LS-NAME-LEN BY -1 UNTIL LS-I = 0
        IF LS-NAME(LS-I:1) = "/"
            EXIT PERFORM
        END-IF
        IF LS-NAME(LS-I:1) = "."
            MOVE "Y" TO LS-HAS-EXT
            EXIT PERFORM
        END-IF
    END-PERFORM

    IF LS-HAS-EXT = "Y"
        MOVE LS-BASE TO LS-CANDIDATE
        PERFORM CHECK-CANDIDATE
    END-IF
    PERFORM VARYING LS-EXT-INDEX FROM 1 BY 1
            UNTIL LS-EXT-INDEX > 8 OR LS-FOUND = "Y"
        MOVE SPACES TO LS-CANDIDATE
        STRING LS-BASE(1:LS-BASE-LEN) WS-EXT(LS-EXT-INDEX)
            DELIMITED BY SIZE INTO LS-CANDIDATE
        PERFORM CHECK-CANDIDATE
    END-PERFORM
    IF LS-FOUND = "N" AND LS-HAS-EXT = "N"
        MOVE LS-BASE TO LS-CANDIDATE
        PERFORM CHECK-CANDIDATE
    END-IF.

*> A candidate counts only if it exists and is not a directory
*> (a directory also has "name/." while a file does not).
CHECK-CANDIDATE.
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    CALL "CBL_CHECK_FILE_EXIST" USING LS-CANDIDATE LS-INFO
    IF RETURN-CODE = 0
        MOVE SPACES TO LS-PROBE
        STRING FUNCTION TRIM(LS-CANDIDATE TRAILING) "/."
            DELIMITED BY SIZE INTO LS-PROBE
        CALL "CBL_CHECK_FILE_EXIST" USING LS-PROBE LS-INFO
        IF RETURN-CODE NOT = 0
            MOVE "Y" TO LS-FOUND
            PERFORM STORED-NAME
        END-IF
    END-IF
    MOVE 0 TO RETURN-CODE.

*> On a file system that ignores case, the spelling tried first is
*> found whatever the file is called. Take the file's own name from
*> realpath(3), so that the path is the one a case-sensitive system
*> finds; the directory stays as given.
STORED-NAME.
    CALL "PLB-STR-LENGTH" USING LS-CANDIDATE LS-CAND-LEN
    IF LS-CAND-LEN = 0 OR LS-CAND-LEN > 1099
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-C-PATH
    STRING LS-CANDIDATE(1:LS-CAND-LEN) X"00" DELIMITED BY SIZE
        INTO LS-C-PATH
    MOVE LOW-VALUES TO LS-REAL
    CALL "realpath" USING BY REFERENCE LS-C-PATH BY REFERENCE LS-REAL
        RETURNING LS-REAL-RESULT
    END-CALL
    MOVE 0 TO RETURN-CODE
    IF LS-REAL-RESULT = NULL
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-REAL-END LS-REAL-SLASH LS-SLASH
    INSPECT LS-REAL TALLYING LS-REAL-END FOR CHARACTERS BEFORE X"00"
    PERFORM VARYING LS-I FROM LS-REAL-END BY -1 UNTIL LS-I = 0
        IF LS-REAL(LS-I:1) = "/"
            MOVE LS-I TO LS-REAL-SLASH
            EXIT PERFORM
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM LS-CAND-LEN BY -1 UNTIL LS-I = 0
        IF LS-CANDIDATE(LS-I:1) = "/"
            MOVE LS-I TO LS-SLASH
            EXIT PERFORM
        END-IF
    END-PERFORM
    *> Only a name that differs in case: a link to another name stays.
    IF LS-REAL-END - LS-REAL-SLASH = LS-CAND-LEN - LS-SLASH
       AND LS-CAND-LEN > LS-SLASH
        IF FUNCTION UPPER-CASE(LS-REAL(LS-REAL-SLASH + 1:
                LS-REAL-END - LS-REAL-SLASH))
           = FUNCTION UPPER-CASE(LS-CANDIDATE(LS-SLASH + 1:
                LS-CAND-LEN - LS-SLASH))
            MOVE LS-REAL(LS-REAL-SLASH + 1:LS-REAL-END - LS-REAL-SLASH)
                TO LS-CANDIDATE(LS-SLASH + 1:
                    LS-CAND-LEN - LS-SLASH)
        END-IF
    END-IF.
END PROGRAM PLB-PP-RESOLVE.

*> PLB-PP-MATCH: does replacement rule (KIND, pattern PAT-FROM..PAT-TO,
*> replacement REP-FROM..REP-TO, all indexes into TOKENS) match at
*> token POS, looking no further than LIMIT?
*>   KIND "F": the pattern's tokens equal the tokens starting at POS.
*>             A pattern that is a single tag word such as :PFX: also
*>             matches inside a longer word: :PFX:-RECORD; so does
*>             a pattern of (PFX), in FLG-(PFX)-OK.
*>   KIND "L": the word at POS begins with the pattern word.
*>   KIND "T": the word at POS ends with the pattern word.
*> MATCHED receives:
*>   "Y"  the pattern's tokens match; emit the replacement tokens
*>   "W"  only the word at POS changes; TEXT holds its new text
*>   "N"  no match
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-MATCH.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-SAME                 PIC X.
01  LS-WORD-LEN             PIC 9(9) COMP-5.
01  LS-PAT-LEN              PIC 9(9) COMP-5.
01  LS-REP-LEN              PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-PAT-TEXT             PIC X(64).
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-KIND                 PIC X.
01  LK-PAT-FROM             PIC 9(9) COMP-5.
01  LK-PAT-TO               PIC 9(9) COMP-5.
01  LK-REP-FROM             PIC 9(9) COMP-5.
01  LK-REP-TO               PIC 9(9) COMP-5.
01  LK-POS                  PIC 9(9) COMP-5.
01  LK-LIMIT                PIC 9(9) COMP-5.
01  LK-MATCHED              PIC X.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-TEXT-LEN             PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-TOKENS LK-KIND LK-PAT-FROM LK-PAT-TO
        LK-REP-FROM LK-REP-TO LK-POS LK-LIMIT LK-MATCHED LK-TEXT
        LK-TEXT-LEN.
    MOVE "N" TO LK-MATCHED
    IF LK-PAT-TO < LK-PAT-FROM
        GOBACK
    END-IF
    EVALUATE TRUE
        WHEN LK-KIND NOT = "F"
            PERFORM MATCH-PARTIAL
        WHEN LK-PAT-FROM = LK-PAT-TO AND TK-IS-WORD(LK-PAT-FROM)
             AND TK-TEXT(TK-TEXT-OFF(LK-PAT-FROM):1) = ":"
             AND TK-TEXT-LEN(LK-PAT-FROM) > 2
            MOVE TK-TEXT-LEN(LK-PAT-FROM) TO LS-PAT-LEN
            MOVE TK-TEXT(TK-TEXT-OFF(LK-PAT-FROM):LS-PAT-LEN)
                TO LS-PAT-TEXT
            PERFORM MATCH-TAG
        *> ==(TAG)== (IBM Enterprise COBOL): the same as a :TAG:, for
        *> words that hold (TAG) as a part.
        WHEN LK-PAT-TO = LK-PAT-FROM + 2 AND TK-IS-LPAREN(LK-PAT-FROM)
             AND TK-IS-WORD(LK-PAT-FROM + 1) AND TK-IS-RPAREN(LK-PAT-TO)
            PERFORM MATCH-FULL
            IF LK-MATCHED = "N"
                MOVE SPACES TO LS-PAT-TEXT
                COMPUTE LS-PAT-LEN = TK-TEXT-LEN(LK-PAT-FROM + 1) + 2
                STRING "(" TK-TEXT(TK-TEXT-OFF(LK-PAT-FROM + 1)
                           :TK-TEXT-LEN(LK-PAT-FROM + 1)) ")"
                    DELIMITED BY SIZE INTO LS-PAT-TEXT
                PERFORM MATCH-TAG-IN-WORD
            END-IF
        WHEN OTHER
            PERFORM MATCH-FULL
    END-EVALUATE
    GOBACK.

*> The pattern is a tag. A word equal to it is replaced like any
*> other text-word; a word that merely contains it has each
*> occurrence replaced by the text of the (single-word or empty)
*> replacement.
MATCH-TAG.
    IF NOT TK-IS-WORD(LK-POS)
        EXIT PARAGRAPH
    END-IF
    IF TK-TEXT-LEN(LK-POS) = LS-PAT-LEN
        PERFORM MATCH-FULL
        EXIT PARAGRAPH
    END-IF
    PERFORM MATCH-TAG-IN-WORD.

*> Each occurrence of LS-PAT-TEXT(1:LS-PAT-LEN) in the word at LK-POS
*> is replaced by the text of the (single-word or empty) replacement.
MATCH-TAG-IN-WORD.
    IF NOT TK-IS-WORD(LK-POS)
        EXIT PARAGRAPH
    END-IF
    MOVE TK-TEXT-LEN(LK-POS) TO LS-WORD-LEN
    IF LS-WORD-LEN <= LS-PAT-LEN
        EXIT PARAGRAPH
    END-IF
    IF LK-REP-TO > LK-REP-FROM
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-REP-LEN
    IF LK-REP-TO = LK-REP-FROM
        MOVE TK-TEXT-LEN(LK-REP-FROM) TO LS-REP-LEN
    END-IF
    MOVE SPACES TO LK-TEXT
    MOVE 1 TO LS-PTR
    MOVE 1 TO LS-K
    PERFORM UNTIL LS-K > LS-WORD-LEN
        IF LS-K + LS-PAT-LEN - 1 <= LS-WORD-LEN
           AND TK-TEXT(TK-TEXT-OFF(LK-POS) + LS-K - 1:LS-PAT-LEN)
               = LS-PAT-TEXT(1:LS-PAT-LEN)
            MOVE "W" TO LK-MATCHED
            IF LS-REP-LEN > 0
                STRING TK-TEXT(TK-TEXT-OFF(LK-REP-FROM):LS-REP-LEN)
                    DELIMITED BY SIZE INTO LK-TEXT WITH POINTER LS-PTR
            END-IF
            ADD LS-PAT-LEN TO LS-K
        ELSE
            STRING TK-TEXT(TK-TEXT-OFF(LK-POS) + LS-K - 1:1)
                DELIMITED BY SIZE INTO LK-TEXT WITH POINTER LS-PTR
            ADD 1 TO LS-K
        END-IF
    END-PERFORM
    COMPUTE LK-TEXT-LEN = LS-PTR - 1.

MATCH-FULL.
    COMPUTE LS-N = LK-PAT-TO - LK-PAT-FROM + 1
    IF LK-POS + LS-N - 1 > LK-LIMIT
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-K FROM 0 BY 1 UNTIL LS-K >= LS-N
        COMPUTE LS-A = LK-POS + LS-K
        COMPUTE LS-B = LK-PAT-FROM + LS-K
        CALL "PLB-TOK-SAME" USING PLB-TOKENS LS-A LS-B LS-SAME
        IF LS-SAME = "N"
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE "Y" TO LK-MATCHED.

MATCH-PARTIAL.
    IF NOT TK-IS-WORD(LK-POS) OR NOT TK-IS-WORD(LK-PAT-FROM)
        EXIT PARAGRAPH
    END-IF
    MOVE TK-TEXT-LEN(LK-POS) TO LS-WORD-LEN
    MOVE TK-TEXT-LEN(LK-PAT-FROM) TO LS-PAT-LEN
    IF LS-PAT-LEN > LS-WORD-LEN
        EXIT PARAGRAPH
    END-IF
    IF LK-KIND = "L"
        IF TK-TEXT(TK-TEXT-OFF(LK-POS):LS-PAT-LEN)
           NOT = TK-TEXT(TK-TEXT-OFF(LK-PAT-FROM):LS-PAT-LEN)
            EXIT PARAGRAPH
        END-IF
    ELSE
        IF TK-TEXT(TK-TEXT-OFF(LK-POS) + LS-WORD-LEN - LS-PAT-LEN
                   :LS-PAT-LEN)
           NOT = TK-TEXT(TK-TEXT-OFF(LK-PAT-FROM):LS-PAT-LEN)
            EXIT PARAGRAPH
        END-IF
    END-IF

    MOVE 0 TO LS-REP-LEN
    IF LK-REP-TO >= LK-REP-FROM
        MOVE TK-TEXT-LEN(LK-REP-FROM) TO LS-REP-LEN
    END-IF
    MOVE SPACES TO LK-TEXT
    MOVE 1 TO LS-PTR
    IF LK-KIND = "T" AND LS-WORD-LEN > LS-PAT-LEN
        STRING TK-TEXT(TK-TEXT-OFF(LK-POS):LS-WORD-LEN - LS-PAT-LEN)
            DELIMITED BY SIZE INTO LK-TEXT WITH POINTER LS-PTR
    END-IF
    IF LS-REP-LEN > 0
        STRING TK-TEXT(TK-TEXT-OFF(LK-REP-FROM):LS-REP-LEN)
            DELIMITED BY SIZE INTO LK-TEXT WITH POINTER LS-PTR
    END-IF
    IF LK-KIND = "L" AND LS-WORD-LEN > LS-PAT-LEN
        STRING TK-TEXT(TK-TEXT-OFF(LK-POS) + LS-PAT-LEN
                       :LS-WORD-LEN - LS-PAT-LEN)
            DELIMITED BY SIZE INTO LK-TEXT WITH POINTER LS-PTR
    END-IF
    COMPUTE LK-TEXT-LEN = LS-PTR - 1
    MOVE "W" TO LK-MATCHED.
END PROGRAM PLB-PP-MATCH.

*> PLB-PP-RUN: preprocess FILE-ID into RESULT, using a scratch table
*> of its own. This is the entry point most callers want.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-RUN.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy" REPLACING ==PLB-TOKENS== BY ==WORK-TOKENS==.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbppopt.cpy".
COPY "plbtok.cpy".
COPY "plbincl.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-PP-OPTIONS PLB-TOKENS PLB-INCLUSIONS LK-FILE-ID.
    CALL "PLB-PP-EXPAND" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-PP-OPTIONS WORK-TOKENS PLB-TOKENS PLB-INCLUSIONS LK-FILE-ID
    GOBACK.
END PROGRAM PLB-PP-RUN.

*> PLB-PP-EXPAND: preprocess FILE-ID. WORK is scratch space for raw
*> tokens; the expanded tokens are written to RESULT, and the
*> copybook inclusions to PLB-INCLUSIONS.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-EXPAND.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  FR-MAX                      VALUE 33.
78  RU-MAX                      VALUE 2048.
78  CA-MAX                      VALUE 256.
*> Stack of token ranges being expanded; frame 1 is the main file.
01  WS-FRAMES.
    05  WS-FRAME-COUNT      PIC 9(4) COMP-5.
    05  WS-FRAME            OCCURS FR-MAX TIMES.
        10  FR-FILE-ID      PIC 9(4) COMP-5.
        10  FR-POS          PIC 9(9) COMP-5.
        10  FR-END          PIC 9(9) COMP-5.
        10  FR-RULE-FIRST   PIC 9(9) COMP-5.
        10  FR-RULE-COUNT   PIC 9(9) COMP-5.
        10  FR-INCL         PIC 9(4) COMP-5.
        *> The word COPY of the statement that opened the frame.
        10  FR-COPY-TOKEN   PIC 9(9) COMP-5.
*> REPLACING rules of the frames on the stack, innermost last.
01  WS-RULES.
    05  WS-RULE-COUNT       PIC 9(9) COMP-5.
    05  WS-RULE             OCCURS RU-MAX TIMES.
        10  RU-KIND         PIC X.
        10  RU-PAT-FROM     PIC 9(9) COMP-5.
        10  RU-PAT-TO       PIC 9(9) COMP-5.
        10  RU-REP-FROM     PIC 9(9) COMP-5.
        10  RU-REP-TO       PIC 9(9) COMP-5.
        *> "Y" once the rule has replaced something.
        10  RU-USED         PIC X.
*> Copybooks already read and tokenized in this run.
01  WS-CACHE.
    05  WS-CACHE-COUNT      PIC 9(4) COMP-5.
    05  WS-CACHED           OCCURS CA-MAX TIMES.
        10  CA-FILE-ID      PIC 9(4) COMP-5.
        10  CA-FIRST        PIC 9(9) COMP-5.
        10  CA-LAST         PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-MAIN-EOF             PIC 9(9) COMP-5.
01  LS-F                    PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-IS                   PIC X.
01  LS-MATCHED              PIC X.
01  LS-FULL                 PIC X.
01  LS-OK                   PIC X.
01  LS-REPLACE-SEEN         PIC X.
01  LS-INCL                 PIC 9(4) COMP-5.
01  LS-NAME                 PIC X(512).
01  LS-LIBRARY              PIC X(512).
01  LS-NAME-IS-WORD         PIC X.
01  LS-SQL-INCLUDE          PIC X.
01  LS-PATH                 PIC X(1100).
01  LS-RESOLVED             PIC 9(4) COMP-5.
01  LS-FILE-ID              PIC 9(4) COMP-5.
01  LS-LOAD-STATUS          PIC 9(4) COMP-5.
01  LS-RULE-START           PIC 9(9) COMP-5.
01  LS-RULE-KIND            PIC X.
01  LS-OPERAND-FROM         PIC 9(9) COMP-5.
01  LS-OPERAND-TO           PIC 9(9) COMP-5.
01  LS-PAT-FROM             PIC 9(9) COMP-5.
01  LS-PAT-TO               PIC 9(9) COMP-5.
01  LS-COPY-TOKEN           PIC 9(9) COMP-5.
01  LS-CACHE-INDEX          PIC 9(4) COMP-5.
01  LS-TEXT                 PIC X(8192).
01  LS-TEXT-LEN             PIC 9(9) COMP-5.
01  LS-MSG-PTR              PIC 9(9) COMP-5.
01  LS-USE-TEXT             PIC X.
01  LS-DIAG-TOKEN           PIC 9(9) COMP-5.
01  LS-DIAG-CODE            PIC X(5).
01  LS-MESSAGE              PIC X(200).
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
01  LS-DIAG-FILE            PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbppopt.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy" REPLACING ==PLB-TOKENS== BY ==WORK-TOKENS==.
COPY "plbtok.cpy" REPLACING ==PLB-TOKENS== BY ==RESULT-TOKENS==.
COPY "plbincl.cpy".
01  LK-FILE-ID              PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-PP-OPTIONS WORK-TOKENS RESULT-TOKENS PLB-INCLUSIONS
        LK-FILE-ID.
    MOVE 0 TO TK-COUNT OF RESULT-TOKENS TK-TEXT-USED OF RESULT-TOKENS
    MOVE 0 TO IN-COUNT IM-COUNT WS-FRAME-COUNT WS-RULE-COUNT
        WS-CACHE-COUNT
    MOVE "N" TO LS-FULL LS-REPLACE-SEEN

    CALL "PLB-LEX-INIT" USING WORK-TOKENS
    CALL "PLB-LEX-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        WORK-TOKENS LK-FILE-ID PO-DEBUG
    MOVE TK-COUNT OF WORK-TOKENS TO LS-MAIN-EOF

    ADD 1 TO WS-FRAME-COUNT
    MOVE LK-FILE-ID TO FR-FILE-ID(1)
    MOVE 1 TO FR-POS(1)
    COMPUTE FR-END(1) = LS-MAIN-EOF - 1
    MOVE 1 TO FR-RULE-FIRST(1)
    MOVE 0 TO FR-RULE-COUNT(1) FR-INCL(1)

    PERFORM UNTIL WS-FRAME-COUNT = 0 OR LS-FULL = "Y"
        MOVE WS-FRAME-COUNT TO LS-F
        IF FR-POS(LS-F) > FR-END(LS-F)
            PERFORM POP-FRAME
        ELSE
            PERFORM EXPAND-NEXT
        END-IF
    END-PERFORM

    MOVE LS-MAIN-EOF TO LS-I
    MOVE 0 TO LS-INCL
    MOVE "N" TO LS-USE-TEXT
    PERFORM EMIT-TOKEN

    IF LS-REPLACE-SEEN = "Y" AND LS-FULL = "N"
        CALL "PLB-PP-REPLACE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            WORK-TOKENS RESULT-TOKENS
    END-IF
    GOBACK.

POP-FRAME.
    PERFORM VARYING LS-R FROM FR-RULE-FIRST(LS-F) BY 1
            UNTIL LS-R >= FR-RULE-FIRST(LS-F) + FR-RULE-COUNT(LS-F)
        IF RU-USED(LS-R) = "N"
            PERFORM REPORT-UNUSED-RULE
        END-IF
    END-PERFORM
    MOVE FR-RULE-FIRST(LS-F) TO WS-RULE-COUNT
    SUBTRACT 1 FROM WS-RULE-COUNT
    SUBTRACT 1 FROM WS-FRAME-COUNT.

*> Handle the token at the current position of the top frame.
EXPAND-NEXT.
    MOVE FR-POS(LS-F) TO LS-I
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-I "COPY" LS-IS
    IF LS-IS = "Y"
        PERFORM HANDLE-COPY
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-I "EXEC" LS-IS
    IF LS-IS = "Y"
        PERFORM CHECK-SQL-INCLUDE
        IF LS-SQL-INCLUDE = "Y"
            PERFORM HANDLE-SQL-INCLUDE
            EXIT PARAGRAPH
        END-IF
    END-IF
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-I "REPLACE" LS-IS
    IF LS-IS = "Y"
        MOVE "Y" TO LS-REPLACE-SEEN
    END-IF

    MOVE "N" TO LS-MATCHED
    PERFORM VARYING LS-R FROM FR-RULE-FIRST(LS-F) BY 1
            UNTIL LS-R >= FR-RULE-FIRST(LS-F) + FR-RULE-COUNT(LS-F)
               OR LS-MATCHED NOT = "N"
        CALL "PLB-PP-MATCH" USING WORK-TOKENS RU-KIND(LS-R)
            RU-PAT-FROM(LS-R) RU-PAT-TO(LS-R)
            RU-REP-FROM(LS-R) RU-REP-TO(LS-R)
            LS-I FR-END(LS-F) LS-MATCHED LS-TEXT LS-TEXT-LEN
        IF LS-MATCHED NOT = "N"
            PERFORM APPLY-RULE
        END-IF
    END-PERFORM
    IF LS-MATCHED = "N"
        MOVE FR-INCL(LS-F) TO LS-INCL
        MOVE "N" TO LS-USE-TEXT
        PERFORM EMIT-TOKEN
        ADD 1 TO FR-POS(LS-F)
    END-IF.

*> Rule LS-R matched at LS-I: emit its replacement and move past the
*> text it replaced.
APPLY-RULE.
    MOVE "Y" TO RU-USED(LS-R)
    MOVE FR-INCL(LS-F) TO LS-INCL
    IF LS-MATCHED = "Y"
        MOVE "N" TO LS-USE-TEXT
        PERFORM VARYING LS-I FROM RU-REP-FROM(LS-R) BY 1
                UNTIL LS-I > RU-REP-TO(LS-R)
            PERFORM EMIT-TOKEN
        END-PERFORM
        COMPUTE FR-POS(LS-F) = FR-POS(LS-F)
            + RU-PAT-TO(LS-R) - RU-PAT-FROM(LS-R) + 1
    ELSE
        MOVE "Y" TO LS-USE-TEXT
        PERFORM EMIT-TOKEN
        ADD 1 TO FR-POS(LS-F)
    END-IF.

*> The top frame is at the word COPY (token LS-I). Parse the
*> statement, then push a frame for the copybook it names.
HANDLE-COPY.
    MOVE LS-I TO LS-COPY-TOKEN
    MOVE WS-RULE-COUNT TO LS-RULE-START
    ADD 1 TO LS-RULE-START
    MOVE "Y" TO LS-OK
    MOVE SPACES TO LS-NAME LS-LIBRARY
    MOVE LS-I TO LS-J
    ADD 1 TO LS-J

    IF LS-J > FR-END(LS-F)
        MOVE "N" TO LS-OK
    ELSE
        EVALUATE TRUE
            WHEN TK-IS-WORD OF WORK-TOKENS (LS-J)
                MOVE "Y" TO LS-NAME-IS-WORD
                PERFORM TAKE-NAME
            WHEN TK-IS-ALNUM OF WORK-TOKENS (LS-J)
                MOVE "N" TO LS-NAME-IS-WORD
                PERFORM TAKE-NAME
            WHEN OTHER
                MOVE "N" TO LS-OK
        END-EVALUATE
    END-IF
    IF LS-OK = "N"
        MOVE LS-COPY-TOKEN TO LS-DIAG-TOKEN
        MOVE "PP003" TO LS-DIAG-CODE
        MOVE "COPY must be followed by a copybook name" TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
        PERFORM SKIP-TO-PERIOD
        EXIT PARAGRAPH
    END-IF

    ADD 1 TO LS-J
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "OF" LS-IS
    IF LS-IS = "N"
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "IN" LS-IS
    END-IF
    IF LS-IS = "Y" AND LS-J < FR-END(LS-F)
        ADD 1 TO LS-J
        MOVE SPACES TO LS-LIBRARY
        MOVE TK-TEXT OF WORK-TOKENS
            (TK-TEXT-OFF OF WORK-TOKENS (LS-J)
             :TK-TEXT-LEN OF WORK-TOKENS (LS-J)) TO LS-LIBRARY
        IF TK-IS-WORD OF WORK-TOKENS (LS-J)
            MOVE FUNCTION LOWER-CASE(LS-LIBRARY) TO LS-LIBRARY
        END-IF
        ADD 1 TO LS-J
    END-IF

    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "SUPPRESS" LS-IS
    IF LS-IS = "Y"
        ADD 1 TO LS-J
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "PRINTING" LS-IS
        IF LS-IS = "Y"
            ADD 1 TO LS-J
        END-IF
    END-IF

    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "REPLACING" LS-IS
    IF LS-IS = "Y"
        ADD 1 TO LS-J
        PERFORM PARSE-REPLACING
    END-IF

    IF LS-OK = "Y"
        IF LS-J > FR-END(LS-F)
            MOVE "N" TO LS-OK
        ELSE
            IF NOT TK-IS-PERIOD OF WORK-TOKENS (LS-J)
                MOVE "N" TO LS-OK
            END-IF
        END-IF
        IF LS-OK = "N"
            MOVE LS-COPY-TOKEN TO LS-DIAG-TOKEN
            MOVE "PP003" TO LS-DIAG-CODE
            MOVE "COPY statement must end with a period" TO LS-MESSAGE
            PERFORM REPORT-AT-TOKEN
        END-IF
    END-IF
    IF LS-OK = "N"
        COMPUTE WS-RULE-COUNT = LS-RULE-START - 1
        PERFORM SKIP-TO-PERIOD
        EXIT PARAGRAPH
    END-IF

    COMPUTE FR-POS(LS-F) = LS-J + 1
    PERFORM OPEN-COPYBOOK
    IF LS-OK = "N"
        COMPUTE WS-RULE-COUNT = LS-RULE-START - 1
    END-IF.

*> EXEC SQL INCLUDE name END-EXEC at LS-I includes a member, such as a
*> DCLGEN layout, the way COPY name does. SQLCA and SQLDA are left to
*> the precompiler. LS-SQL-INCLUDE = "Y" when LS-I starts one, with
*> LS-J on the name.
CHECK-SQL-INCLUDE.
    MOVE "N" TO LS-SQL-INCLUDE
    IF LS-I + 4 > FR-END(LS-F)
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-J = LS-I + 1
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "SQL" LS-IS
    IF LS-IS = "N"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-J
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "INCLUDE" LS-IS
    IF LS-IS = "N"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-J
    COMPUTE LS-K = LS-J + 1
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-K "END-EXEC" LS-IS
    IF LS-IS = "N"
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-WORD OF WORK-TOKENS (LS-J)
            MOVE "Y" TO LS-NAME-IS-WORD
        WHEN TK-IS-ALNUM OF WORK-TOKENS (LS-J)
            MOVE "N" TO LS-NAME-IS-WORD
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    PERFORM TAKE-NAME
    IF FUNCTION UPPER-CASE(LS-NAME) = "SQLCA"
       OR FUNCTION UPPER-CASE(LS-NAME) = "SQLDA"
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-SQL-INCLUDE.

*> Replace EXEC SQL INCLUDE name END-EXEC, and a period after it, with
*> the member's tokens.
HANDLE-SQL-INCLUDE.
    MOVE LS-I TO LS-COPY-TOKEN
    MOVE WS-RULE-COUNT TO LS-RULE-START
    ADD 1 TO LS-RULE-START
    MOVE "Y" TO LS-OK
    MOVE SPACES TO LS-LIBRARY
    COMPUTE LS-J = LS-J + 2
    IF LS-J <= FR-END(LS-F)
        IF TK-IS-PERIOD OF WORK-TOKENS (LS-J)
            ADD 1 TO LS-J
        END-IF
    END-IF
    MOVE LS-J TO FR-POS(LS-F)
    PERFORM OPEN-COPYBOOK
    IF LS-OK = "N"
        COMPUTE WS-RULE-COUNT = LS-RULE-START - 1
    END-IF.

TAKE-NAME.
    MOVE TK-TEXT OF WORK-TOKENS
        (TK-TEXT-OFF OF WORK-TOKENS (LS-J)
         :TK-TEXT-LEN OF WORK-TOKENS (LS-J)) TO LS-NAME.

*> Parse "[LEADING|TRAILING] operand BY operand ..." up to the period,
*> adding one rule per pair. Leaves LS-J on the period.
PARSE-REPLACING.
    PERFORM UNTIL LS-OK = "N"
        IF LS-J > FR-END(LS-F)
            EXIT PERFORM
        END-IF
        IF TK-IS-PERIOD OF WORK-TOKENS (LS-J)
            EXIT PERFORM
        END-IF
        MOVE "F" TO LS-RULE-KIND
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "LEADING" LS-IS
        IF LS-IS = "Y"
            MOVE "L" TO LS-RULE-KIND
            ADD 1 TO LS-J
        ELSE
            CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "TRAILING"
                LS-IS
            IF LS-IS = "Y"
                MOVE "T" TO LS-RULE-KIND
                ADD 1 TO LS-J
            END-IF
        END-IF
        PERFORM PARSE-OPERAND
        MOVE LS-OPERAND-FROM TO LS-PAT-FROM
        MOVE LS-OPERAND-TO TO LS-PAT-TO
        IF LS-OK = "Y"
            CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "BY" LS-IS
            IF LS-IS = "N"
                MOVE "N" TO LS-OK
            ELSE
                ADD 1 TO LS-J
                PERFORM PARSE-OPERAND
            END-IF
        END-IF
        IF LS-OK = "Y"
            PERFORM ADD-RULE
        END-IF
    END-PERFORM
    IF LS-OK = "N"
        MOVE LS-COPY-TOKEN TO LS-DIAG-TOKEN
        MOVE "PP003" TO LS-DIAG-CODE
        MOVE "malformed REPLACING phrase in COPY statement"
            TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
    END-IF.

*> An operand is ==pseudo-text== or a single word or literal.
*> Sets LS-OPERAND-FROM/TO (TO < FROM for empty pseudo-text) and
*> moves LS-J past it.
PARSE-OPERAND.
    IF LS-J > FR-END(LS-F)
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    IF TK-IS-PSEUDO OF WORK-TOKENS (LS-J)
        COMPUTE LS-OPERAND-FROM = LS-J + 1
        MOVE LS-OPERAND-FROM TO LS-K
        PERFORM UNTIL LS-K > FR-END(LS-F)
            IF TK-IS-PSEUDO OF WORK-TOKENS (LS-K)
                EXIT PERFORM
            END-IF
            ADD 1 TO LS-K
        END-PERFORM
        IF LS-K > FR-END(LS-F)
            MOVE "N" TO LS-OK
        ELSE
            COMPUTE LS-OPERAND-TO = LS-K - 1
            COMPUTE LS-J = LS-K + 1
        END-IF
    ELSE
        IF TK-IS-WORD OF WORK-TOKENS (LS-J)
           OR TK-IS-ALNUM OF WORK-TOKENS (LS-J)
           OR TK-IS-NUMBER OF WORK-TOKENS (LS-J)
            MOVE LS-J TO LS-OPERAND-FROM LS-OPERAND-TO
            ADD 1 TO LS-J
            IF TK-IS-WORD OF WORK-TOKENS (LS-OPERAND-FROM)
                PERFORM EXTEND-IDENTIFIER
            END-IF
        ELSE
            MOVE "N" TO LS-OK
        END-IF
    END-IF.

*> An operand that is an identifier runs on over IN|OF qualifiers and
*> one parenthesized subscript: A OF B IN C (1, 2). LS-J is after the
*> word; on return it is after the identifier.
EXTEND-IDENTIFIER.
    PERFORM UNTIL LS-J + 1 > FR-END(LS-F)
        IF NOT TK-IS-WORD OF WORK-TOKENS (LS-J + 1)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "OF" LS-IS
        IF LS-IS = "N"
            CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "IN" LS-IS
        END-IF
        IF LS-IS = "N"
            EXIT PERFORM
        END-IF
        ADD 2 TO LS-J
        COMPUTE LS-OPERAND-TO = LS-J - 1
    END-PERFORM
    IF LS-J <= FR-END(LS-F)
        IF TK-IS-LPAREN OF WORK-TOKENS (LS-J)
            MOVE LS-J TO LS-K
            PERFORM UNTIL LS-K > FR-END(LS-F)
                IF TK-IS-RPAREN OF WORK-TOKENS (LS-K)
                    MOVE LS-K TO LS-OPERAND-TO
                    COMPUTE LS-J = LS-K + 1
                    EXIT PERFORM
                END-IF
                IF TK-IS-PERIOD OF WORK-TOKENS (LS-K)
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-K
            END-PERFORM
        END-IF
    END-IF.

ADD-RULE.
    *> An empty pattern can never match; a partial-word pattern must
    *> be a single word.
    IF LS-PAT-TO < LS-PAT-FROM
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    IF LS-RULE-KIND NOT = "F"
        IF LS-PAT-TO NOT = LS-PAT-FROM
           OR NOT TK-IS-WORD OF WORK-TOKENS (LS-PAT-FROM)
            MOVE "N" TO LS-OK
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF WS-RULE-COUNT >= RU-MAX
        MOVE LS-COPY-TOKEN TO LS-DIAG-TOKEN
        MOVE "PP007" TO LS-DIAG-CODE
        MOVE "too many REPLACING operands" TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-RULE-COUNT
    MOVE LS-RULE-KIND TO RU-KIND(WS-RULE-COUNT)
    MOVE LS-PAT-FROM TO RU-PAT-FROM(WS-RULE-COUNT)
    MOVE LS-PAT-TO TO RU-PAT-TO(WS-RULE-COUNT)
    MOVE LS-OPERAND-FROM TO RU-REP-FROM(WS-RULE-COUNT)
    MOVE LS-OPERAND-TO TO RU-REP-TO(WS-RULE-COUNT)
    MOVE "N" TO RU-USED(WS-RULE-COUNT).

*> Copybook LS-NAME was not found: kept once in IM-NAME.
NOTE-MISSING.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > IM-COUNT
        IF IM-NAME(LS-K) = LS-NAME(1:31)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF IM-COUNT < IM-MAX
        ADD 1 TO IM-COUNT
        MOVE LS-NAME(1:31) TO IM-NAME(IM-COUNT)
    END-IF.

*> After a malformed COPY, resume after the next period so that the
*> rest of the statement is not taken as program text.
SKIP-TO-PERIOD.
    MOVE LS-COPY-TOKEN TO LS-K
    PERFORM UNTIL LS-K > FR-END(LS-F)
        IF TK-IS-PERIOD OF WORK-TOKENS (LS-K)
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-K
    END-PERFORM
    COMPUTE FR-POS(LS-F) = LS-K + 1.

*> Resolve, load, and tokenize the copybook, then push its frame.
OPEN-COPYBOOK.
    MOVE LS-COPY-TOKEN TO LS-DIAG-TOKEN
    CALL "PLB-PP-RESOLVE" USING PLB-SOURCE-SET PLB-PP-OPTIONS LS-NAME
        LS-LIBRARY LS-NAME-IS-WORD FR-FILE-ID(LS-F) LS-PATH LS-RESOLVED
    EVALUATE LS-RESOLVED
        WHEN 1
            MOVE "PP001" TO LS-DIAG-CODE
            MOVE SPACES TO LS-MESSAGE
            STRING "copybook '" FUNCTION TRIM(LS-NAME TRAILING)
                "' not found" DELIMITED BY SIZE INTO LS-MESSAGE
            PERFORM REPORT-AT-TOKEN
            PERFORM NOTE-MISSING
            MOVE "N" TO LS-OK
            EXIT PARAGRAPH
        WHEN 2
            MOVE "PP004" TO LS-DIAG-CODE
            MOVE SPACES TO LS-MESSAGE
            STRING "copybook name '" FUNCTION TRIM(LS-NAME TRAILING)
                "' must be a relative path without '..'"
                DELIMITED BY SIZE INTO LS-MESSAGE
            PERFORM REPORT-AT-TOKEN
            MOVE "N" TO LS-OK
            EXIT PARAGRAPH
    END-EVALUATE

    PERFORM FIND-OR-LOAD
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF

    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > WS-FRAME-COUNT
        IF FR-FILE-ID(LS-K) = LS-FILE-ID
            MOVE "PP002" TO LS-DIAG-CODE
            MOVE SPACES TO LS-MESSAGE
            STRING "copybook '" FUNCTION TRIM(LS-NAME TRAILING)
                "' copies itself" DELIMITED BY SIZE INTO LS-MESSAGE
            PERFORM REPORT-AT-TOKEN
            MOVE "N" TO LS-OK
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-FRAME-COUNT >= FR-MAX
        MOVE "PP005" TO LS-DIAG-CODE
        MOVE "copybooks nested more than 32 deep" TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    IF IN-COUNT >= IN-MAX
        MOVE "PP007" TO LS-DIAG-CODE
        MOVE "too many copybook inclusions" TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF

    ADD 1 TO IN-COUNT
    MOVE LS-FILE-ID TO IN-FILE-ID(IN-COUNT)
    MOVE FR-INCL(LS-F) TO IN-PARENT(IN-COUNT)
    MOVE TK-FILE-ID OF WORK-TOKENS (LS-COPY-TOKEN)
        TO IN-FROM-FILE-ID(IN-COUNT)
    MOVE 0 TO IN-FROM-LINE(IN-COUNT)
    IF TK-SRC-LINE OF WORK-TOKENS (LS-COPY-TOKEN) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE OF WORK-TOKENS (LS-COPY-TOKEN))
            TO IN-FROM-LINE(IN-COUNT)
    END-IF
    MOVE TK-COLUMN OF WORK-TOKENS (LS-COPY-TOKEN)
        TO IN-FROM-COLUMN(IN-COUNT)

    ADD 1 TO WS-FRAME-COUNT
    MOVE LS-FILE-ID TO FR-FILE-ID(WS-FRAME-COUNT)
    MOVE CA-FIRST(LS-CACHE-INDEX) TO FR-POS(WS-FRAME-COUNT)
    MOVE CA-LAST(LS-CACHE-INDEX) TO FR-END(WS-FRAME-COUNT)
    MOVE LS-RULE-START TO FR-RULE-FIRST(WS-FRAME-COUNT)
    COMPUTE FR-RULE-COUNT(WS-FRAME-COUNT) =
        WS-RULE-COUNT - LS-RULE-START + 1
    MOVE IN-COUNT TO FR-INCL(WS-FRAME-COUNT)
    MOVE LS-COPY-TOKEN TO FR-COPY-TOKEN(WS-FRAME-COUNT).

*> Use the cached tokens of LS-PATH, or read and tokenize it.
FIND-OR-LOAD.
    PERFORM VARYING LS-CACHE-INDEX FROM 1 BY 1
            UNTIL LS-CACHE-INDEX > WS-CACHE-COUNT
        IF SF-PATH(CA-FILE-ID(LS-CACHE-INDEX)) = LS-PATH
            MOVE CA-FILE-ID(LS-CACHE-INDEX) TO LS-FILE-ID
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-CACHE-COUNT >= CA-MAX
        MOVE "PP007" TO LS-DIAG-CODE
        MOVE "too many distinct copybooks" TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    *> A copybook an earlier file of the run included is already in
    *> the source set: tokenize it again, under the same id, reading it
    *> again only if its lines were released since.
    CALL "PLB-SRC-FIND-PATH" USING PLB-SOURCE-SET LS-PATH LS-FILE-ID
    IF LS-FILE-ID = 0
        CALL "PLB-SRC-LOAD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS LS-PATH
            PO-FORMAT LS-FILE-ID LS-LOAD-STATUS
    ELSE
        CALL "PLB-SRC-ENSURE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            LS-FILE-ID LS-LOAD-STATUS
        IF LS-LOAD-STATUS NOT = 0
            MOVE 0 TO LS-FILE-ID
        END-IF
    END-IF
    IF LS-FILE-ID = 0
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-FIRST = TK-COUNT OF WORK-TOKENS + 1
    CALL "PLB-LEX-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        WORK-TOKENS LS-FILE-ID PO-DEBUG
    ADD 1 TO WS-CACHE-COUNT
    MOVE WS-CACHE-COUNT TO LS-CACHE-INDEX
    MOVE LS-FILE-ID TO CA-FILE-ID(LS-CACHE-INDEX)
    MOVE LS-FIRST TO CA-FIRST(LS-CACHE-INDEX)
    *> Leave out the copybook's end-of-file token.
    COMPUTE CA-LAST(LS-CACHE-INDEX) = TK-COUNT OF WORK-TOKENS - 1.

*> Append WORK token LS-I to RESULT with inclusion LS-INCL; when
*> LS-USE-TEXT is "Y", with text LS-TEXT(1:LS-TEXT-LEN) instead.
EMIT-TOKEN.
    IF LS-USE-TEXT = "N"
        MOVE TK-TEXT-LEN OF WORK-TOKENS (LS-I) TO LS-TEXT-LEN
        IF LS-TEXT-LEN > 0
            MOVE TK-TEXT OF WORK-TOKENS
                (TK-TEXT-OFF OF WORK-TOKENS (LS-I):LS-TEXT-LEN)
                TO LS-TEXT(1:LS-TEXT-LEN)
        END-IF
    END-IF
    IF TK-COUNT OF RESULT-TOKENS >= TK-MAX
       OR TK-TEXT-USED OF RESULT-TOKENS + LS-TEXT-LEN > TK-TEXT-SIZE
        MOVE "Y" TO LS-FULL
        MOVE LS-I TO LS-DIAG-TOKEN
        MOVE "PP007" TO LS-DIAG-CODE
        MOVE "expanded program has too many tokens" TO LS-MESSAGE
        PERFORM REPORT-AT-TOKEN
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO TK-COUNT OF RESULT-TOKENS
    MOVE TK-COUNT OF RESULT-TOKENS TO LS-K
    MOVE TK-KIND OF WORK-TOKENS (LS-I) TO TK-KIND OF RESULT-TOKENS (LS-K)
    MOVE TK-PREFIX OF WORK-TOKENS (LS-I)
        TO TK-PREFIX OF RESULT-TOKENS (LS-K)
    MOVE TK-KEYWORD OF WORK-TOKENS (LS-I)
        TO TK-KEYWORD OF RESULT-TOKENS (LS-K)
    IF LS-USE-TEXT = "Y"
        PERFORM LOOK-UP-KEYWORD
    END-IF
    MOVE TK-FILE-ID OF WORK-TOKENS (LS-I)
        TO TK-FILE-ID OF RESULT-TOKENS (LS-K)
    MOVE LS-INCL TO TK-INCL OF RESULT-TOKENS (LS-K)
    MOVE TK-SRC-LINE OF WORK-TOKENS (LS-I)
        TO TK-SRC-LINE OF RESULT-TOKENS (LS-K)
    MOVE TK-COLUMN OF WORK-TOKENS (LS-I)
        TO TK-COLUMN OF RESULT-TOKENS (LS-K)
    MOVE TK-SPAN OF WORK-TOKENS (LS-I) TO TK-SPAN OF RESULT-TOKENS (LS-K)
    COMPUTE TK-TEXT-OFF OF RESULT-TOKENS (LS-K) =
        TK-TEXT-USED OF RESULT-TOKENS + 1
    MOVE LS-TEXT-LEN TO TK-TEXT-LEN OF RESULT-TOKENS (LS-K)
    IF LS-TEXT-LEN > 0
        MOVE LS-TEXT(1:LS-TEXT-LEN) TO TK-TEXT OF RESULT-TOKENS
            (TK-TEXT-USED OF RESULT-TOKENS + 1:LS-TEXT-LEN)
        ADD LS-TEXT-LEN TO TK-TEXT-USED OF RESULT-TOKENS
    END-IF.

*> The keyword kind of RESULT token LS-K, whose text is replaced.
LOOK-UP-KEYWORD.
    MOVE SPACE TO TK-KEYWORD OF RESULT-TOKENS (LS-K)
    IF TK-KIND OF RESULT-TOKENS (LS-K) = "W" AND LS-TEXT-LEN > 0
       AND LS-TEXT-LEN <= 31
        CALL "PLB-KW-LOOKUP" USING LS-TEXT(1:LS-TEXT-LEN)
            TK-KEYWORD OF RESULT-TOKENS (LS-K)
    END-IF.

*> Report LS-DIAG-CODE / LS-MESSAGE at WORK token LS-DIAG-TOKEN.
*> PP008: REPLACING rule LS-R of the frame being closed replaced
*> nothing in its copybook: the pattern is misspelled, or the copybook
*> no longer has what it names.
REPORT-UNUSED-RULE.
    MOVE "PP008" TO LS-DIAG-CODE
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-MSG-PTR
    STRING "REPLACING ==" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-MSG-PTR
    PERFORM VARYING LS-I FROM RU-PAT-FROM(LS-R) BY 1
            UNTIL LS-I > RU-PAT-TO(LS-R) OR LS-MSG-PTR > 120
        CALL "PLB-TOK-TEXT" USING WORK-TOKENS LS-I LS-TEXT LS-TEXT-LEN
        IF LS-I > RU-PAT-FROM(LS-R)
            STRING " " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-MSG-PTR
        END-IF
        IF LS-TEXT-LEN > 0 AND LS-TEXT-LEN < 60
            STRING LS-TEXT(1:LS-TEXT-LEN) DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-MSG-PTR
        END-IF
    END-PERFORM
    STRING "== replaces nothing in the copybook" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-MSG-PTR
    MOVE FR-COPY-TOKEN(LS-F) TO LS-DIAG-TOKEN
    MOVE TK-FILE-ID OF WORK-TOKENS (LS-DIAG-TOKEN) TO LS-DIAG-FILE
    MOVE 0 TO LS-LINE-NO
    IF TK-SRC-LINE OF WORK-TOKENS (LS-DIAG-TOKEN) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE OF WORK-TOKENS (LS-DIAG-TOKEN))
            TO LS-LINE-NO
    END-IF
    MOVE TK-COLUMN OF WORK-TOKENS (LS-DIAG-TOKEN) TO LS-COLUMN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "W" LS-DIAG-CODE
        LS-DIAG-FILE LS-LINE-NO LS-COLUMN LS-MESSAGE.

REPORT-AT-TOKEN.
    MOVE TK-FILE-ID OF WORK-TOKENS (LS-DIAG-TOKEN) TO LS-DIAG-FILE
    MOVE 0 TO LS-LINE-NO
    IF TK-SRC-LINE OF WORK-TOKENS (LS-DIAG-TOKEN) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE OF WORK-TOKENS (LS-DIAG-TOKEN))
            TO LS-LINE-NO
    END-IF
    MOVE TK-COLUMN OF WORK-TOKENS (LS-DIAG-TOKEN) TO LS-COLUMN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" LS-DIAG-CODE
        LS-DIAG-FILE LS-LINE-NO LS-COLUMN LS-MESSAGE.
END PROGRAM PLB-PP-EXPAND.

*> PLB-PP-REPLACE: apply REPLACE statements to RESULT (the output of
*> COPY expansion), using WORK as scratch space.
*>
*>   REPLACE ==a== BY ==b== ... .        replaces the active set
*>   REPLACE ALSO ==a== BY ==b== ... .   adds a set on top of it
*>   REPLACE LAST OFF.                   drops the most recent set
*>   REPLACE OFF.                        drops every set
*>
*> LEADING and TRAILING operands replace part of a word. More recent
*> sets are tried first; within a set, operands are tried in order.
*> REPLACE statements themselves are removed from the output.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PP-REPLACE.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  RG-MAX                      VALUE 64.
78  RR-MAX                      VALUE 2048.
01  WS-GROUPS.
    05  WS-GROUP-COUNT      PIC 9(4) COMP-5.
    05  WS-GROUP            OCCURS RG-MAX TIMES.
        10  GR-FIRST        PIC 9(9) COMP-5.
        10  GR-COUNT        PIC 9(9) COMP-5.
01  WS-RULES.
    05  WS-RULE-COUNT       PIC 9(9) COMP-5.
    05  WS-RULE             OCCURS RR-MAX TIMES.
        10  RU-KIND         PIC X.
        10  RU-PAT-FROM     PIC 9(9) COMP-5.
        10  RU-PAT-TO       PIC 9(9) COMP-5.
        10  RU-REP-FROM     PIC 9(9) COMP-5.
        10  RU-REP-TO       PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-POS                  PIC 9(9) COMP-5.
01  LS-LIMIT                PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-IS                   PIC X.
01  LS-OK                   PIC X.
01  LS-MATCHED              PIC X.
01  LS-FULL                 PIC X VALUE "N".
01  LS-ALSO                 PIC X.
01  LS-RULE-KIND            PIC X.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-OPERAND-FROM         PIC 9(9) COMP-5.
01  LS-OPERAND-TO           PIC 9(9) COMP-5.
01  LS-PAT-FROM             PIC 9(9) COMP-5.
01  LS-PAT-TO               PIC 9(9) COMP-5.
01  LS-GROUP-START          PIC 9(9) COMP-5.
01  LS-INCL                 PIC 9(4) COMP-5.
01  LS-TEXT                 PIC X(8192).
01  LS-TEXT-LEN             PIC 9(9) COMP-5.
01  LS-USE-TEXT             PIC X.
01  LS-DIAG-FILE            PIC 9(4) COMP-5.
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy" REPLACING ==PLB-TOKENS== BY ==WORK-TOKENS==.
COPY "plbtok.cpy" REPLACING ==PLB-TOKENS== BY ==RESULT-TOKENS==.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS WORK-TOKENS
        RESULT-TOKENS.
    *> Move the expanded tokens to WORK; RESULT receives the output.
    MOVE TK-COUNT OF RESULT-TOKENS TO TK-COUNT OF WORK-TOKENS
    MOVE TK-TEXT-USED OF RESULT-TOKENS TO TK-TEXT-USED OF WORK-TOKENS
    PERFORM VARYING LS-I FROM 1 BY 1
            UNTIL LS-I > TK-COUNT OF RESULT-TOKENS
        MOVE TK-ENTRY OF RESULT-TOKENS (LS-I)
            TO TK-ENTRY OF WORK-TOKENS (LS-I)
    END-PERFORM
    IF TK-TEXT-USED OF RESULT-TOKENS > 0
        MOVE TK-TEXT OF RESULT-TOKENS (1:TK-TEXT-USED OF RESULT-TOKENS)
            TO TK-TEXT OF WORK-TOKENS (1:TK-TEXT-USED OF RESULT-TOKENS)
    END-IF
    MOVE 0 TO TK-COUNT OF RESULT-TOKENS TK-TEXT-USED OF RESULT-TOKENS
    MOVE 0 TO WS-GROUP-COUNT WS-RULE-COUNT

    *> The last token is the end-of-file token; no pattern reaches it.
    COMPUTE LS-LIMIT = TK-COUNT OF WORK-TOKENS - 1
    MOVE 1 TO LS-POS
    PERFORM UNTIL LS-POS > TK-COUNT OF WORK-TOKENS OR LS-FULL = "Y"
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-POS "REPLACE" LS-IS
        IF LS-IS = "Y"
            PERFORM HANDLE-REPLACE
        ELSE
            PERFORM REPLACE-OR-EMIT
        END-IF
    END-PERFORM
    GOBACK.

REPLACE-OR-EMIT.
    MOVE "N" TO LS-MATCHED
    MOVE TK-INCL OF WORK-TOKENS (LS-POS) TO LS-INCL
    IF LS-POS <= LS-LIMIT
        PERFORM VARYING LS-G FROM WS-GROUP-COUNT BY -1
                UNTIL LS-G = 0 OR LS-MATCHED NOT = "N"
            PERFORM VARYING LS-R FROM GR-FIRST(LS-G) BY 1
                    UNTIL LS-R >= GR-FIRST(LS-G) + GR-COUNT(LS-G)
                       OR LS-MATCHED NOT = "N"
                CALL "PLB-PP-MATCH" USING WORK-TOKENS RU-KIND(LS-R)
                    RU-PAT-FROM(LS-R) RU-PAT-TO(LS-R)
                    RU-REP-FROM(LS-R) RU-REP-TO(LS-R)
                    LS-POS LS-LIMIT LS-MATCHED LS-TEXT LS-TEXT-LEN
            END-PERFORM
        END-PERFORM
    END-IF
    IF LS-MATCHED = "N"
        MOVE LS-POS TO LS-I
        MOVE "N" TO LS-USE-TEXT
        PERFORM EMIT-TOKEN
        ADD 1 TO LS-POS
        EXIT PARAGRAPH
    END-IF
    *> The PERFORM loops leave LS-R one past the rule that matched.
    SUBTRACT 1 FROM LS-R
    IF LS-MATCHED = "Y"
        MOVE "N" TO LS-USE-TEXT
        PERFORM VARYING LS-I FROM RU-REP-FROM(LS-R) BY 1
                UNTIL LS-I > RU-REP-TO(LS-R)
            PERFORM EMIT-TOKEN
        END-PERFORM
        COMPUTE LS-POS = LS-POS + RU-PAT-TO(LS-R) - RU-PAT-FROM(LS-R) + 1
    ELSE
        MOVE LS-POS TO LS-I
        MOVE "Y" TO LS-USE-TEXT
        PERFORM EMIT-TOKEN
        ADD 1 TO LS-POS
    END-IF.

*> LS-POS is at the word REPLACE. Update the rule sets and move past
*> the statement's period.
HANDLE-REPLACE.
    MOVE LS-POS TO LS-STMT
    MOVE "Y" TO LS-OK
    COMPUTE LS-J = LS-POS + 1
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "OFF" LS-IS
    IF LS-IS = "Y"
        MOVE 0 TO WS-GROUP-COUNT WS-RULE-COUNT
        ADD 1 TO LS-J
        PERFORM EXPECT-PERIOD
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "LAST" LS-IS
    IF LS-IS = "Y"
        ADD 1 TO LS-J
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "OFF" LS-IS
        IF LS-IS = "N"
            MOVE "N" TO LS-OK
        ELSE
            IF WS-GROUP-COUNT > 0
                MOVE GR-FIRST(WS-GROUP-COUNT) TO WS-RULE-COUNT
                SUBTRACT 1 FROM WS-RULE-COUNT
                SUBTRACT 1 FROM WS-GROUP-COUNT
            END-IF
            ADD 1 TO LS-J
        END-IF
        PERFORM EXPECT-PERIOD
        EXIT PARAGRAPH
    END-IF

    MOVE "N" TO LS-ALSO
    CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "ALSO" LS-IS
    IF LS-IS = "Y"
        MOVE "Y" TO LS-ALSO
        ADD 1 TO LS-J
    END-IF
    IF LS-ALSO = "N"
        MOVE 0 TO WS-GROUP-COUNT WS-RULE-COUNT
    END-IF
    IF WS-GROUP-COUNT >= RG-MAX
        MOVE "N" TO LS-OK
        PERFORM EXPECT-PERIOD
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-GROUP-START = WS-RULE-COUNT + 1

    PERFORM PARSE-PAIRS
    IF LS-OK = "Y" AND WS-RULE-COUNT >= LS-GROUP-START
        ADD 1 TO WS-GROUP-COUNT
        MOVE LS-GROUP-START TO GR-FIRST(WS-GROUP-COUNT)
        COMPUTE GR-COUNT(WS-GROUP-COUNT) =
            WS-RULE-COUNT - LS-GROUP-START + 1
    ELSE
        COMPUTE WS-RULE-COUNT = LS-GROUP-START - 1
        MOVE "N" TO LS-OK
    END-IF
    PERFORM EXPECT-PERIOD.

PARSE-PAIRS.
    PERFORM UNTIL LS-OK = "N"
        IF LS-J > LS-LIMIT
            EXIT PERFORM
        END-IF
        IF TK-IS-PERIOD OF WORK-TOKENS (LS-J)
            EXIT PERFORM
        END-IF
        MOVE "F" TO LS-RULE-KIND
        CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "LEADING" LS-IS
        IF LS-IS = "Y"
            MOVE "L" TO LS-RULE-KIND
            ADD 1 TO LS-J
        ELSE
            CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "TRAILING"
                LS-IS
            IF LS-IS = "Y"
                MOVE "T" TO LS-RULE-KIND
                ADD 1 TO LS-J
            END-IF
        END-IF
        PERFORM PARSE-OPERAND
        MOVE LS-OPERAND-FROM TO LS-PAT-FROM
        MOVE LS-OPERAND-TO TO LS-PAT-TO
        IF LS-OK = "Y"
            CALL "PLB-TOK-IS-WORD" USING WORK-TOKENS LS-J "BY" LS-IS
            IF LS-IS = "N"
                MOVE "N" TO LS-OK
            ELSE
                ADD 1 TO LS-J
                PERFORM PARSE-OPERAND
            END-IF
        END-IF
        IF LS-OK = "Y"
            PERFORM ADD-RULE
        END-IF
    END-PERFORM.

PARSE-OPERAND.
    IF LS-J > LS-LIMIT
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    IF TK-IS-PSEUDO OF WORK-TOKENS (LS-J)
        COMPUTE LS-OPERAND-FROM = LS-J + 1
        MOVE LS-OPERAND-FROM TO LS-K
        PERFORM UNTIL LS-K > LS-LIMIT
            IF TK-IS-PSEUDO OF WORK-TOKENS (LS-K)
                EXIT PERFORM
            END-IF
            ADD 1 TO LS-K
        END-PERFORM
        IF LS-K > LS-LIMIT
            MOVE "N" TO LS-OK
        ELSE
            COMPUTE LS-OPERAND-TO = LS-K - 1
            COMPUTE LS-J = LS-K + 1
        END-IF
    ELSE
        IF TK-IS-WORD OF WORK-TOKENS (LS-J)
           OR TK-IS-ALNUM OF WORK-TOKENS (LS-J)
           OR TK-IS-NUMBER OF WORK-TOKENS (LS-J)
            MOVE LS-J TO LS-OPERAND-FROM LS-OPERAND-TO
            ADD 1 TO LS-J
        ELSE
            MOVE "N" TO LS-OK
        END-IF
    END-IF.

ADD-RULE.
    IF LS-PAT-TO < LS-PAT-FROM
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    IF LS-RULE-KIND NOT = "F"
        IF LS-PAT-TO NOT = LS-PAT-FROM
           OR NOT TK-IS-WORD OF WORK-TOKENS (LS-PAT-FROM)
            MOVE "N" TO LS-OK
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF WS-RULE-COUNT >= RR-MAX
        MOVE "N" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-RULE-COUNT
    MOVE LS-RULE-KIND TO RU-KIND(WS-RULE-COUNT)
    MOVE LS-PAT-FROM TO RU-PAT-FROM(WS-RULE-COUNT)
    MOVE LS-PAT-TO TO RU-PAT-TO(WS-RULE-COUNT)
    MOVE LS-OPERAND-FROM TO RU-REP-FROM(WS-RULE-COUNT)
    MOVE LS-OPERAND-TO TO RU-REP-TO(WS-RULE-COUNT).

*> The statement must end at LS-J with a period. On any problem,
*> report it and resume after the next period.
EXPECT-PERIOD.
    IF LS-OK = "Y"
        IF LS-J > LS-LIMIT
            MOVE "N" TO LS-OK
        ELSE
            IF NOT TK-IS-PERIOD OF WORK-TOKENS (LS-J)
                MOVE "N" TO LS-OK
            END-IF
        END-IF
    END-IF
    IF LS-OK = "N"
        PERFORM REPORT-MALFORMED
        MOVE LS-STMT TO LS-J
        PERFORM UNTIL LS-J > LS-LIMIT
            IF TK-IS-PERIOD OF WORK-TOKENS (LS-J)
                EXIT PERFORM
            END-IF
            ADD 1 TO LS-J
        END-PERFORM
    END-IF
    COMPUTE LS-POS = LS-J + 1.

REPORT-MALFORMED.
    MOVE TK-FILE-ID OF WORK-TOKENS (LS-STMT) TO LS-DIAG-FILE
    MOVE 0 TO LS-LINE-NO
    IF TK-SRC-LINE OF WORK-TOKENS (LS-STMT) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE OF WORK-TOKENS (LS-STMT))
            TO LS-LINE-NO
    END-IF
    MOVE TK-COLUMN OF WORK-TOKENS (LS-STMT) TO LS-COLUMN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "PP006"
        LS-DIAG-FILE LS-LINE-NO LS-COLUMN
        "malformed REPLACE statement".

*> Append WORK token LS-I to RESULT with inclusion LS-INCL; when
*> LS-USE-TEXT is "Y", with text LS-TEXT(1:LS-TEXT-LEN) instead.
EMIT-TOKEN.
    IF LS-USE-TEXT = "N"
        MOVE TK-TEXT-LEN OF WORK-TOKENS (LS-I) TO LS-TEXT-LEN
        IF LS-TEXT-LEN > 0
            MOVE TK-TEXT OF WORK-TOKENS
                (TK-TEXT-OFF OF WORK-TOKENS (LS-I):LS-TEXT-LEN)
                TO LS-TEXT(1:LS-TEXT-LEN)
        END-IF
    END-IF
    IF TK-COUNT OF RESULT-TOKENS >= TK-MAX
       OR TK-TEXT-USED OF RESULT-TOKENS + LS-TEXT-LEN > TK-TEXT-SIZE
        MOVE "Y" TO LS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO TK-COUNT OF RESULT-TOKENS
    MOVE TK-COUNT OF RESULT-TOKENS TO LS-K
    MOVE TK-ENTRY OF WORK-TOKENS (LS-I) TO TK-ENTRY OF RESULT-TOKENS (LS-K)
    MOVE LS-INCL TO TK-INCL OF RESULT-TOKENS (LS-K)
    IF LS-USE-TEXT = "Y"
        PERFORM LOOK-UP-KEYWORD
    END-IF
    COMPUTE TK-TEXT-OFF OF RESULT-TOKENS (LS-K) =
        TK-TEXT-USED OF RESULT-TOKENS + 1
    MOVE LS-TEXT-LEN TO TK-TEXT-LEN OF RESULT-TOKENS (LS-K)
    IF LS-TEXT-LEN > 0
        MOVE LS-TEXT(1:LS-TEXT-LEN) TO TK-TEXT OF RESULT-TOKENS
            (TK-TEXT-USED OF RESULT-TOKENS + 1:LS-TEXT-LEN)
        ADD LS-TEXT-LEN TO TK-TEXT-USED OF RESULT-TOKENS
    END-IF.

*> The keyword kind of RESULT token LS-K, whose text is replaced.
LOOK-UP-KEYWORD.
    MOVE SPACE TO TK-KEYWORD OF RESULT-TOKENS (LS-K)
    IF TK-KIND OF RESULT-TOKENS (LS-K) = "W" AND LS-TEXT-LEN > 0
       AND LS-TEXT-LEN <= 31
        CALL "PLB-KW-LOOKUP" USING LS-TEXT(1:LS-TEXT-LEN)
            TK-KEYWORD OF RESULT-TOKENS (LS-K)
    END-IF.
END PROGRAM PLB-PP-REPLACE.
