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
