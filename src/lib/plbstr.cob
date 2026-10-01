*> ---------------------------------------------------------------
*> plbstr: string helpers shared across Plumbline.
*>
*> All routines take PIC X ANY LENGTH arguments so callers can pass
*> fields of any size. Trailing spaces are treated as padding, never
*> as content, which matches how COBOL compares alphanumerics.
*> ---------------------------------------------------------------

*> PLB-STR-LENGTH: length of TEXT without trailing spaces (0 if blank).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STR-LENGTH.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-POS                  PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-TEXT LK-LENGTH.
    MOVE FUNCTION LENGTH(LK-TEXT) TO LS-POS
    *> Callers pass wide buffers that are mostly trailing spaces: skip
    *> blank blocks of 64 with one comparison each, then go by byte.
    PERFORM UNTIL LS-POS < 64
        IF LK-TEXT(LS-POS - 63:64) NOT = SPACES
            EXIT PERFORM
        END-IF
        SUBTRACT 64 FROM LS-POS
    END-PERFORM
    PERFORM UNTIL LS-POS = 0
        IF LK-TEXT(LS-POS:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-POS
    END-PERFORM
    MOVE LS-POS TO LK-LENGTH
    GOBACK.
END PROGRAM PLB-STR-LENGTH.

*> PLB-STR-UPPER: fold TEXT to upper case in place (ASCII letters only).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STR-UPPER.
DATA DIVISION.
LINKAGE SECTION.
01  LK-TEXT                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-TEXT.
    INSPECT LK-TEXT CONVERTING
        "abcdefghijklmnopqrstuvwxyz"
        TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    GOBACK.
END PROGRAM PLB-STR-UPPER.

*> PLB-STR-STARTS-WITH: RESULT = "Y" if TEXT begins with the
*> significant (non-trailing-space) part of PREFIX, else "N".
*> A blank PREFIX never matches.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STR-STARTS-WITH.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-PREFIX-LEN           PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-PREFIX               PIC X ANY LENGTH.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING LK-TEXT LK-PREFIX LK-RESULT.
    MOVE "N" TO LK-RESULT
    CALL "PLB-STR-LENGTH" USING LK-PREFIX LS-PREFIX-LEN
    IF LS-PREFIX-LEN > 0
       AND LS-PREFIX-LEN <= FUNCTION LENGTH(LK-TEXT)
        IF LK-TEXT(1:LS-PREFIX-LEN) = LK-PREFIX(1:LS-PREFIX-LEN)
            MOVE "Y" TO LK-RESULT
        END-IF
    END-IF
    GOBACK.
END PROGRAM PLB-STR-STARTS-WITH.

*> PLB-STR-FIRST-NONBLANK: position of the first non-space character
*> of TEXT, or 0 when TEXT is entirely blank.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STR-FIRST-NONBLANK.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-POS                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-POSITION             PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-TEXT LK-POSITION.
    MOVE 0 TO LK-POSITION
    MOVE FUNCTION LENGTH(LK-TEXT) TO LS-LEN
    PERFORM VARYING LS-POS FROM 1 BY 1 UNTIL LS-POS > LS-LEN
        IF LK-TEXT(LS-POS:1) NOT = SPACE
            MOVE LS-POS TO LK-POSITION
            EXIT PERFORM
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-STR-FIRST-NONBLANK.

*> PLB-STR-FROM-INT: render VALUE as decimal text, left-justified in
*> TEXT (space filled), with LENGTH set to the number of characters.
*> If TEXT is too short the result is filled with "*" and LENGTH is
*> the full field length, so an overflow is visible, never truncated
*> silently.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STR-FROM-INT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-EDIT                 PIC -(18)9.
01  LS-START                PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-VALUE                PIC S9(18) COMP-5.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-VALUE LK-TEXT LK-LENGTH.
    MOVE LK-VALUE TO LS-EDIT
    CALL "PLB-STR-FIRST-NONBLANK" USING LS-EDIT LS-START
    COMPUTE LK-LENGTH = FUNCTION LENGTH(LS-EDIT) - LS-START + 1
    MOVE SPACES TO LK-TEXT
    IF LK-LENGTH > FUNCTION LENGTH(LK-TEXT)
        MOVE ALL "*" TO LK-TEXT
        MOVE FUNCTION LENGTH(LK-TEXT) TO LK-LENGTH
    ELSE
        MOVE LS-EDIT(LS-START:LK-LENGTH) TO LK-TEXT(1:LK-LENGTH)
    END-IF
    GOBACK.
END PROGRAM PLB-STR-FROM-INT.

*> PLB-STR-EXPAND-TABS: copy the first IN-LENGTH characters of INPUT
*> to OUTPUT, replacing each tab with spaces up to the next tab stop.
*> Tab stops are every TAB-WIDTH columns (columns 1, 1+w, 1+2w, ...),
*> which matches cobc's -ftab-width. OUT-LENGTH receives the expanded
*> length. OVERFLOW is set to "Y" if OUTPUT was too small, in which
*> case the result is cut at the size of OUTPUT.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STR-EXPAND-TABS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-IN-POS               PIC 9(9) COMP-5.
01  LS-OUT-POS              PIC 9(9) COMP-5.
01  LS-OUT-MAX              PIC 9(9) COMP-5.
01  LS-WIDTH                PIC 9(9) COMP-5.
01  LS-STOPS                PIC 9(9) COMP-5.
01  LS-IN-LEN               PIC 9(9) COMP-5.
01  LS-TABS                 PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-INPUT                PIC X ANY LENGTH.
01  LK-IN-LENGTH            PIC 9(9) COMP-5.
01  LK-TAB-WIDTH            PIC 9(4) COMP-5.
01  LK-OUTPUT               PIC X ANY LENGTH.
01  LK-OUT-LENGTH           PIC 9(9) COMP-5.
01  LK-OVERFLOW             PIC X.
PROCEDURE DIVISION USING LK-INPUT LK-IN-LENGTH LK-TAB-WIDTH
        LK-OUTPUT LK-OUT-LENGTH LK-OVERFLOW.
    MOVE SPACES TO LK-OUTPUT
    MOVE "N" TO LK-OVERFLOW
    MOVE 0 TO LS-OUT-POS
    MOVE FUNCTION LENGTH(LK-OUTPUT) TO LS-OUT-MAX
    MOVE LK-IN-LENGTH TO LS-IN-LEN
    IF LS-IN-LEN > FUNCTION LENGTH(LK-INPUT)
        MOVE FUNCTION LENGTH(LK-INPUT) TO LS-IN-LEN
    END-IF
    IF LS-IN-LEN = 0
        MOVE 0 TO LK-OUT-LENGTH
        GOBACK
    END-IF
    *> Most lines have no tab: copy them whole.
    MOVE 0 TO LS-TABS
    INSPECT LK-INPUT(1:LS-IN-LEN) TALLYING LS-TABS FOR ALL X"09"
    IF LS-TABS = 0 AND LS-IN-LEN <= LS-OUT-MAX
        MOVE LK-INPUT(1:LS-IN-LEN) TO LK-OUTPUT(1:LS-IN-LEN)
        MOVE LS-IN-LEN TO LK-OUT-LENGTH
        GOBACK
    END-IF
    MOVE LK-TAB-WIDTH TO LS-WIDTH
    IF LS-WIDTH = 0
        MOVE 1 TO LS-WIDTH
    END-IF
    PERFORM VARYING LS-IN-POS FROM 1 BY 1
            UNTIL LS-IN-POS > LK-IN-LENGTH
               OR LS-IN-POS > FUNCTION LENGTH(LK-INPUT)
        IF LK-INPUT(LS-IN-POS:1) = X"09"
            *> Output is already spaces, so advancing is enough. A tab
            *> always advances, even when it sits on a stop.
            DIVIDE LS-OUT-POS BY LS-WIDTH GIVING LS-STOPS
            COMPUTE LS-OUT-POS = (LS-STOPS + 1) * LS-WIDTH
        ELSE
            ADD 1 TO LS-OUT-POS
            IF LS-OUT-POS <= LS-OUT-MAX
                MOVE LK-INPUT(LS-IN-POS:1) TO LK-OUTPUT(LS-OUT-POS:1)
            END-IF
        END-IF
        IF LS-OUT-POS > LS-OUT-MAX
            MOVE "Y" TO LK-OVERFLOW
            MOVE LS-OUT-MAX TO LS-OUT-POS
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE LS-OUT-POS TO LK-OUT-LENGTH
    GOBACK.
END PROGRAM PLB-STR-EXPAND-TABS.
