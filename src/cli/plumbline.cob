*> ---------------------------------------------------------------
*> plumbline: command-line entry point.
*>
*> Exit codes:
*>   0  success
*>   2  usage error (unknown option, missing argument)
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLUMBLINE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
01  WS-ARG-COUNT            PIC 9(4).
01  WS-ARG-INDEX            PIC 9(4).
01  WS-ARG                  PIC X(1024).
01  WS-ARG-LEN              PIC 9(9) COMP-5.
01  WS-EXIT-CODE            PIC 9(4) VALUE 0.
01  WS-DONE                 PIC X VALUE "N".
    88  WS-IS-DONE                VALUE "Y".

PROCEDURE DIVISION.
MAIN-LOGIC.
    ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
    IF WS-ARG-COUNT = 0
        PERFORM SHOW-USAGE
        MOVE 2 TO WS-EXIT-CODE
    ELSE
        PERFORM VARYING WS-ARG-INDEX FROM 1 BY 1
                UNTIL WS-ARG-INDEX > WS-ARG-COUNT OR WS-IS-DONE
            DISPLAY WS-ARG-INDEX UPON ARGUMENT-NUMBER
            ACCEPT WS-ARG FROM ARGUMENT-VALUE
            PERFORM HANDLE-ARG
        END-PERFORM
    END-IF
    MOVE WS-EXIT-CODE TO RETURN-CODE
    STOP RUN.

HANDLE-ARG.
    EVALUATE WS-ARG
        WHEN "--version"
        WHEN "-V"
            DISPLAY PLB-NAME " " PLB-VERSION
            SET WS-IS-DONE TO TRUE
        WHEN "--help"
        WHEN "-h"
            PERFORM SHOW-USAGE
            SET WS-IS-DONE TO TRUE
        WHEN OTHER
            CALL "PLB-STR-LENGTH" USING WS-ARG WS-ARG-LEN
            DISPLAY PLB-NAME ": unknown option '" WS-ARG(1:WS-ARG-LEN)
                "'" UPON SYSERR
            DISPLAY "Try 'plumbline --help' for more information."
                UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
            SET WS-IS-DONE TO TRUE
    END-EVALUATE.

SHOW-USAGE.
    DISPLAY "Usage: plumbline [OPTION]..."
    DISPLAY "Static analysis for COBOL programs."
    DISPLAY " "
    DISPLAY "Options:"
    DISPLAY "  -h, --help       show this help and exit"
    DISPLAY "  -V, --version    show version information and exit".
END PROGRAM PLUMBLINE.
