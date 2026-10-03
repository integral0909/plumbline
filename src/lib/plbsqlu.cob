*> ---------------------------------------------------------------
*> plbsqlu: helpers for the embedded SQL rules.
*> ---------------------------------------------------------------

*> PLB-SQL-COMMA-BETWEEN: COMMA = "Y" when the source text between
*> tokens FROM and TO holds a comma. Commas separate items of SQL lists
*> (select lists, INTO lists, column definitions), but to COBOL they
*> are separators and leave no token, so the text is read: after the
*> first token on its line, and, when the second is on another line,
*> before it on its own.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SQL-COMMA-BETWEEN.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE-TEXT            PIC X(4096).
LOCAL-STORAGE SECTION.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-LINE-LEN             PIC 9(9) COMP-5.
01  LS-SCAN-LINE            PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-FROM                 PIC 9(9) COMP-5.
01  LK-TO                   PIC 9(9) COMP-5.
01  LK-COMMA                PIC X.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS LK-FROM
        LK-TO LK-COMMA.
    PERFORM COMMA-BETWEEN
    GOBACK.

COMMA-BETWEEN.
    MOVE "N" TO LK-COMMA
    IF TK-SRC-LINE(LK-FROM) = 0 OR TK-SRC-LINE(LK-TO) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE TK-SRC-LINE(LK-FROM) TO LS-SCAN-LINE
    CALL "PLB-SRC-LINE-TEXT" USING PLB-SOURCE-SET LS-SCAN-LINE
        WS-LINE-TEXT LS-LINE-LEN
    COMPUTE LS-J = TK-COLUMN(LK-FROM) + TK-SPAN(LK-FROM)
    IF TK-SRC-LINE(LK-TO) = LS-SCAN-LINE
        PERFORM VARYING LS-J FROM LS-J BY 1
                UNTIL LS-J >= TK-COLUMN(LK-TO) OR LS-J > LS-LINE-LEN
            IF WS-LINE-TEXT(LS-J:1) = ","
                MOVE "Y" TO LK-COMMA
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-J FROM LS-J BY 1
            UNTIL LS-J > SL-CONTENT-COL(LS-SCAN-LINE)
                         + SL-CONTENT-LEN(LS-SCAN-LINE) - 1
               OR LS-J > LS-LINE-LEN
        IF WS-LINE-TEXT(LS-J:1) = ","
            MOVE "Y" TO LK-COMMA
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE TK-SRC-LINE(LK-TO) TO LS-SCAN-LINE
    CALL "PLB-SRC-LINE-TEXT" USING PLB-SOURCE-SET LS-SCAN-LINE
        WS-LINE-TEXT LS-LINE-LEN
    PERFORM VARYING LS-J FROM SL-CONTENT-COL(LS-SCAN-LINE) BY 1
            UNTIL LS-J >= TK-COLUMN(LK-TO) OR LS-J > LS-LINE-LEN
        IF WS-LINE-TEXT(LS-J:1) = ","
            MOVE "Y" TO LK-COMMA
            EXIT PARAGRAPH
        END-IF
    END-PERFORM.
END PROGRAM PLB-SQL-COMMA-BETWEEN.
