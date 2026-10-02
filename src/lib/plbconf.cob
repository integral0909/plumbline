*> ---------------------------------------------------------------
*> plbconf: read a configuration file (copy/plbconf.cpy).
*>
*> PLB-CONF-READ USING PATH CONFIG STATUS reads the settings of the
*> file at PATH. STATUS is 0 when the file was read and 1 when it
*> could not be opened. What the settings mean is up to the caller;
*> plumbline applies them as if they were command-line options.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CONF-READ.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT CONFIG-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  CONFIG-FILE.
01  CONFIG-RECORD           PIC X(1024).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(512).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
01  WS-LINE                 PIC X(1024).
01  WS-LINE-NO              PIC 9(9) COMP-5.
01  WS-START                PIC 9(9) COMP-5.
01  WS-END                  PIC 9(9) COMP-5.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-TAB                  PIC X VALUE X"09".
LINKAGE SECTION.
COPY "plbconf.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH PLB-CONFIG LK-STATUS.
    MOVE 0 TO CF-COUNT LK-STATUS WS-LINE-NO
    MOVE "N" TO CF-OVERFLOW
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT CONFIG-FILE
    IF WS-STATUS NOT = "00"
        MOVE 1 TO LK-STATUS
        GOBACK
    END-IF
    PERFORM UNTIL EXIT
        MOVE SPACES TO CONFIG-RECORD
        READ CONFIG-FILE
            AT END
                EXIT PERFORM
        END-READ
        IF NOT WS-READ-OK
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-LINE-NO
        MOVE CONFIG-RECORD TO WS-LINE
        INSPECT WS-LINE REPLACING ALL WS-TAB BY SPACE
        PERFORM ADD-SETTING
    END-PERFORM
    CLOSE CONFIG-FILE
    GOBACK.

ADD-SETTING.
    MOVE 1 TO WS-START
    PERFORM UNTIL WS-START > LENGTH OF WS-LINE
        IF WS-LINE(WS-START:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-START
    END-PERFORM
    IF WS-START > LENGTH OF WS-LINE
        EXIT PARAGRAPH
    END-IF
    IF WS-LINE(WS-START:1) = "#"
        EXIT PARAGRAPH
    END-IF
    IF CF-COUNT >= CF-MAX
        MOVE "Y" TO CF-OVERFLOW
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CF-COUNT
    MOVE WS-LINE-NO TO CF-LINE-NO(CF-COUNT)
    MOVE SPACES TO CF-KEY(CF-COUNT) CF-VALUE(CF-COUNT)
    *> The key runs to the next space; the value is the rest of the
    *> line without its leading spaces.
    MOVE WS-START TO WS-END
    PERFORM UNTIL WS-END > LENGTH OF WS-LINE
        IF WS-LINE(WS-END:1) = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-END
    END-PERFORM
    COMPUTE WS-I = WS-END - WS-START
    MOVE WS-LINE(WS-START:WS-I) TO CF-KEY(CF-COUNT)
    PERFORM UNTIL WS-END > LENGTH OF WS-LINE
        IF WS-LINE(WS-END:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-END
    END-PERFORM
    IF WS-END <= LENGTH OF WS-LINE
        MOVE WS-LINE(WS-END:) TO CF-VALUE(CF-COUNT)
    END-IF.
END PROGRAM PLB-CONF-READ.
