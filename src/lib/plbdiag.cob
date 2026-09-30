*> ---------------------------------------------------------------
*> plbdiag: recording and formatting diagnostics.
*>
*> The PLB-DIAGNOSTICS table (copy/plbdiag.cpy) is owned by the
*> caller and passed to every routine, so separate runs and tests
*> never share state.
*>
*> Severities: "E" error, "W" warning, "N" note.
*> Codes name the check that raised the diagnostic, e.g. "RD001".
*> A file id, line, or column of 0 means "not applicable".
*> ---------------------------------------------------------------

*> PLB-DIAG-INIT: empty the table.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DIAG-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbdiag.cpy".
PROCEDURE DIVISION USING PLB-DIAGNOSTICS.
    MOVE 0 TO DG-COUNT DG-ERRORS DG-WARNINGS DG-DROPPED
    GOBACK.
END PROGRAM PLB-DIAG-INIT.

*> PLB-DIAG-ADD: record one diagnostic.
*> An unknown severity is recorded as an error: a caller bug should
*> fail loudly rather than disappear. A diagnostic identical to one
*> already recorded (same code, place, and message) is not recorded
*> again: a problem in a copybook is reported once, not once for
*> every program that copies it.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DIAG-ADD.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-SEVERITY             PIC X.
01  LS-I                    PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbdiag.cpy".
01  LK-SEVERITY             PIC X.
01  LK-CODE                 PIC X ANY LENGTH.
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-LINE                 PIC 9(9) COMP-5.
01  LK-COLUMN               PIC 9(4) COMP-5.
01  LK-MESSAGE              PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-DIAGNOSTICS LK-SEVERITY LK-CODE
        LK-FILE-ID LK-LINE LK-COLUMN LK-MESSAGE.
    PERFORM VARYING LS-I FROM DG-COUNT BY -1 UNTIL LS-I = 0
        IF DG-LINE(LS-I) = LK-LINE AND DG-COLUMN(LS-I) = LK-COLUMN
           AND DG-FILE-ID(LS-I) = LK-FILE-ID
           AND DG-CODE(LS-I) = LK-CODE
           AND DG-MESSAGE(LS-I) = LK-MESSAGE
            GOBACK
        END-IF
    END-PERFORM
    EVALUATE LK-SEVERITY
        WHEN "W"
            MOVE "W" TO LS-SEVERITY
            ADD 1 TO DG-WARNINGS
        WHEN "N"
            MOVE "N" TO LS-SEVERITY
        WHEN OTHER
            MOVE "E" TO LS-SEVERITY
            ADD 1 TO DG-ERRORS
    END-EVALUATE

    IF DG-COUNT >= DG-MAX
        ADD 1 TO DG-DROPPED
    ELSE
        ADD 1 TO DG-COUNT
        MOVE LS-SEVERITY TO DG-SEVERITY(DG-COUNT)
        MOVE LK-CODE     TO DG-CODE(DG-COUNT)
        MOVE LK-FILE-ID  TO DG-FILE-ID(DG-COUNT)
        MOVE LK-LINE     TO DG-LINE(DG-COUNT)
        MOVE LK-COLUMN   TO DG-COLUMN(DG-COUNT)
        MOVE LK-MESSAGE  TO DG-MESSAGE(DG-COUNT)
    END-IF
    GOBACK.
END PROGRAM PLB-DIAG-ADD.

*> PLB-DIAG-FORMAT: render entry INDEX as one line of text:
*>     path:line:column: severity: message [CODE]
*> PATH is the name of the entry's file (the caller resolves the file
*> id); a blank PATH is shown as "plumbline". Line and column are left
*> out when they are 0. The result is truncated to fit TEXT; LENGTH
*> receives the number of characters written.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DIAG-FORMAT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-SEVERITY-TEXT        PIC X(8).
LINKAGE SECTION.
COPY "plbdiag.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-DIAGNOSTICS LK-INDEX LK-PATH
        LK-TEXT LK-LENGTH.
    MOVE SPACES TO LK-TEXT
    MOVE 1 TO LS-PTR
    IF LK-INDEX < 1 OR LK-INDEX > DG-COUNT
        MOVE 0 TO LK-LENGTH
        GOBACK
    END-IF

    CALL "PLB-STR-LENGTH" USING LK-PATH LS-LEN
    IF LS-LEN = 0
        STRING "plumbline" DELIMITED BY SIZE
            INTO LK-TEXT WITH POINTER LS-PTR
        END-STRING
    ELSE
        STRING LK-PATH(1:LS-LEN) DELIMITED BY SIZE
            INTO LK-TEXT WITH POINTER LS-PTR
        END-STRING
    END-IF

    IF DG-LINE(LK-INDEX) > 0
        MOVE DG-LINE(LK-INDEX) TO LS-NUM
        PERFORM APPEND-NUMBER
        IF DG-COLUMN(LK-INDEX) > 0
            MOVE DG-COLUMN(LK-INDEX) TO LS-NUM
            PERFORM APPEND-NUMBER
        END-IF
    END-IF

    EVALUATE TRUE
        WHEN DG-IS-WARNING(LK-INDEX)
            MOVE "warning" TO LS-SEVERITY-TEXT
        WHEN DG-IS-NOTE(LK-INDEX)
            MOVE "note" TO LS-SEVERITY-TEXT
        WHEN OTHER
            MOVE "error" TO LS-SEVERITY-TEXT
    END-EVALUATE
    CALL "PLB-STR-LENGTH" USING LS-SEVERITY-TEXT LS-LEN
    STRING ": " LS-SEVERITY-TEXT(1:LS-LEN) ": " DELIMITED BY SIZE
        INTO LK-TEXT WITH POINTER LS-PTR
    END-STRING

    CALL "PLB-STR-LENGTH" USING DG-MESSAGE(LK-INDEX) LS-LEN
    IF LS-LEN > 0
        STRING DG-MESSAGE(LK-INDEX)(1:LS-LEN) DELIMITED BY SIZE
            INTO LK-TEXT WITH POINTER LS-PTR
        END-STRING
    END-IF

    CALL "PLB-STR-LENGTH" USING DG-CODE(LK-INDEX) LS-LEN
    IF LS-LEN > 0
        STRING " [" DG-CODE(LK-INDEX)(1:LS-LEN) "]" DELIMITED BY SIZE
            INTO LK-TEXT WITH POINTER LS-PTR
        END-STRING
    END-IF

    COMPUTE LK-LENGTH = LS-PTR - 1
    GOBACK.

APPEND-NUMBER.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING ":" LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LK-TEXT WITH POINTER LS-PTR
    END-STRING.
END PROGRAM PLB-DIAG-FORMAT.
