*> ---------------------------------------------------------------
*> plbasm: reading assembler macro sources.
*>
*> CICS maps (BMS) and IMS definitions (DBD, PSB) are written as
*> assembler macros. A statement has an optional name starting in
*> column 1, an operation, and operands separated by commas, up to the
*> first blank outside quotes; the rest of the line is a comment. A
*> character in column 72 continues the statement on the next line,
*> from column 16, also inside a quoted string. Lines starting with *
*> or .* are comments.
*>
*> PLB-ASM-READER reads one file at a time, a statement per call;
*> PLB-ASM-OPERAND splits a statement's operands.
*> ---------------------------------------------------------------

*> PLB-ASM-READER: ACTION "O" opens file PATH and gives its first
*> statement, "N" gives the next, "C" closes the file. AT-STATUS says
*> whether a statement came (0), the file ended (1), or it cannot be
*> read (2).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-ASM-READER.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT ASM-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  ASM-FILE.
01  ASM-RECORD              PIC X(256).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(1024).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
    88  WS-AT-END                 VALUE "10".
01  WS-OPEN                 PIC X VALUE "N".
01  WS-LINE-NO              PIC 9(9) COMP-5 VALUE 0.
01  WS-TEXT                 PIC X(80).
01  WS-P                    PIC 9(4) COMP-5.
01  WS-Q                    PIC 9(4) COMP-5.
01  WS-IN-QUOTE             PIC X.
01  WS-CONTINUES            PIC X.
01  WS-DONE                 PIC X.
LINKAGE SECTION.
01  LK-ACTION               PIC X.
01  LK-PATH                 PIC X ANY LENGTH.
COPY "plbasms.cpy".
PROCEDURE DIVISION USING LK-ACTION LK-PATH PLB-ASM-STATEMENT.
    EVALUATE LK-ACTION
        WHEN "O"
            IF WS-OPEN = "Y"
                CLOSE ASM-FILE
            END-IF
            MOVE LK-PATH TO WS-PATH
            MOVE 0 TO WS-LINE-NO
            OPEN INPUT ASM-FILE
            IF WS-STATUS NOT = "00"
                MOVE "N" TO WS-OPEN
                MOVE 2 TO AT-STATUS
                GOBACK
            END-IF
            MOVE "Y" TO WS-OPEN
            PERFORM NEXT-STATEMENT
        WHEN "N"
            IF WS-OPEN = "N"
                MOVE 1 TO AT-STATUS
                GOBACK
            END-IF
            PERFORM NEXT-STATEMENT
        WHEN "C"
            IF WS-OPEN = "Y"
                CLOSE ASM-FILE
            END-IF
            MOVE "N" TO WS-OPEN
    END-EVALUATE
    GOBACK.

*> The next statement: its first line, and its continuation lines.
NEXT-STATEMENT.
    MOVE SPACES TO AT-NAME AT-OP AT-OPERANDS
    MOVE 0 TO AT-LEN AT-LINE
    MOVE "N" TO WS-DONE WS-IN-QUOTE WS-CONTINUES
    PERFORM UNTIL WS-DONE = "Y"
        PERFORM READ-RECORD
        IF AT-STATUS NOT = 0
            *> A statement cut off by the end of the file still counts.
            IF AT-LINE > 0 AND AT-STATUS = 1
                MOVE 0 TO AT-STATUS
            END-IF
            EXIT PERFORM
        END-IF
        IF AT-LINE = 0
            PERFORM FIRST-LINE
        ELSE
            MOVE 16 TO WS-P
            IF WS-IN-QUOTE = "N"
                PERFORM SKIP-BLANKS
            END-IF
            PERFORM READ-OPERANDS
        END-IF
        IF AT-LINE > 0 AND WS-CONTINUES = "N"
            MOVE "Y" TO WS-DONE
        END-IF
    END-PERFORM.

*> WS-TEXT = the next record; AT-STATUS 1 at the end, 2 on an error.
READ-RECORD.
    MOVE 0 TO AT-STATUS
    MOVE SPACES TO ASM-RECORD
    READ ASM-FILE
    EVALUATE TRUE
        WHEN WS-READ-OK
            ADD 1 TO WS-LINE-NO
            MOVE ASM-RECORD(1:80) TO WS-TEXT
        WHEN WS-AT-END
            MOVE 1 TO AT-STATUS
        WHEN OTHER
            MOVE 2 TO AT-STATUS
    END-EVALUATE.

*> The first line of a statement; comment and blank lines are passed.
FIRST-LINE.
    IF WS-TEXT(1:1) = "*" OR WS-TEXT(1:2) = ".*"
       OR WS-TEXT(1:71) = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE WS-LINE-NO TO AT-LINE
    MOVE 1 TO WS-P
    IF WS-TEXT(1:1) NOT = SPACE
        PERFORM READ-WORD
        MOVE FUNCTION UPPER-CASE(WS-TEXT(WS-Q:WS-P - WS-Q)) TO AT-NAME
    END-IF
    PERFORM SKIP-BLANKS
    IF WS-P <= 71
        PERFORM READ-WORD
        MOVE FUNCTION UPPER-CASE(WS-TEXT(WS-Q:WS-P - WS-Q)) TO AT-OP
        PERFORM SKIP-BLANKS
    END-IF
    IF WS-P <= 71
        PERFORM READ-OPERANDS
    ELSE
        PERFORM NOTE-CONTINUATION
    END-IF.

SKIP-BLANKS.
    PERFORM UNTIL WS-P > 71
        IF WS-TEXT(WS-P:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-P
    END-PERFORM.

READ-WORD.
    MOVE WS-P TO WS-Q
    PERFORM UNTIL WS-P > 71
        IF WS-TEXT(WS-P:1) = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-P
    END-PERFORM
    IF WS-P - WS-Q > 8
        COMPUTE WS-P = WS-Q + 8
    END-IF.

*> Operand text from WS-P to the first blank outside quotes, or column
*> 71, appended to AT-OPERANDS.
READ-OPERANDS.
    PERFORM UNTIL WS-P > 71
        IF WS-TEXT(WS-P:1) = SPACE AND WS-IN-QUOTE = "N"
            EXIT PERFORM
        END-IF
        IF WS-TEXT(WS-P:1) = "'"
            IF WS-IN-QUOTE = "Y"
                MOVE "N" TO WS-IN-QUOTE
            ELSE
                MOVE "Y" TO WS-IN-QUOTE
            END-IF
        END-IF
        IF AT-LEN < 4000
            ADD 1 TO AT-LEN
            MOVE WS-TEXT(WS-P:1) TO AT-OPERANDS(AT-LEN:1)
        END-IF
        ADD 1 TO WS-P
    END-PERFORM
    PERFORM NOTE-CONTINUATION.

*> A character in column 72 continues the statement.
NOTE-CONTINUATION.
    IF WS-TEXT(72:1) NOT = SPACE
        MOVE "Y" TO WS-CONTINUES
    ELSE
        MOVE "N" TO WS-CONTINUES
    END-IF.
END PROGRAM PLB-ASM-READER.

*> PLB-ASM-OPERAND: the operand of the statement that starts at START,
*> which is left at the operand after it. KEY and VALUE are its parts
*> around its first = outside parentheses and quotes (KEY spaces for a
*> positional operand), upper-cased unless KEEP-CASE is "Y"; LENGTH is
*> its length, 0 when there are no more operands.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-ASM-OPERAND.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-DEPTH                PIC 9(4) COMP-5.
01  LS-QUOTE                PIC X.
01  LS-EQ                   PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbasms.cpy".
01  LK-START                PIC 9(4) COMP-5.
01  LK-KEY                  PIC X(8).
01  LK-VALUE                PIC X(4000).
01  LK-LENGTH               PIC 9(4) COMP-5.
01  LK-KEEP-CASE            PIC X.
PROCEDURE DIVISION USING PLB-ASM-STATEMENT LK-START LK-KEY LK-VALUE
        LK-LENGTH LK-KEEP-CASE.
    MOVE 0 TO LK-LENGTH LS-DEPTH LS-EQ
    MOVE "N" TO LS-QUOTE
    MOVE SPACES TO LK-KEY LK-VALUE
    IF LK-START > AT-LEN
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM LK-START BY 1 UNTIL LS-I > AT-LEN
        EVALUATE TRUE
            WHEN AT-OPERANDS(LS-I:1) = "'"
                IF LS-QUOTE = "Y"
                    MOVE "N" TO LS-QUOTE
                ELSE
                    MOVE "Y" TO LS-QUOTE
                END-IF
            WHEN LS-QUOTE = "Y"
                CONTINUE
            WHEN AT-OPERANDS(LS-I:1) = "("
                ADD 1 TO LS-DEPTH
            WHEN AT-OPERANDS(LS-I:1) = ")" AND LS-DEPTH > 0
                SUBTRACT 1 FROM LS-DEPTH
            WHEN AT-OPERANDS(LS-I:1) = "," AND LS-DEPTH = 0
                EXIT PERFORM
            WHEN AT-OPERANDS(LS-I:1) = "=" AND LS-DEPTH = 0
                 AND LS-EQ = 0
                COMPUTE LS-EQ = LS-I - LK-START + 1
        END-EVALUATE
    END-PERFORM
    COMPUTE LK-LENGTH = LS-I - LK-START
    IF LK-LENGTH = 0
        *> An empty operand, between two commas.
        COMPUTE LK-START = LS-I + 1
        MOVE 1 TO LK-LENGTH
        GOBACK
    END-IF
    IF LS-EQ > 1 AND LS-EQ <= 9
        MOVE FUNCTION UPPER-CASE(AT-OPERANDS(LK-START:LS-EQ - 1))
            TO LK-KEY
        IF LS-EQ < LK-LENGTH
            MOVE AT-OPERANDS(LK-START + LS-EQ:LK-LENGTH - LS-EQ)
                TO LK-VALUE
        END-IF
    ELSE
        MOVE AT-OPERANDS(LK-START:LK-LENGTH) TO LK-VALUE
    END-IF
    IF LK-KEEP-CASE NOT = "Y"
        MOVE FUNCTION UPPER-CASE(LK-VALUE) TO LK-VALUE
    END-IF
    COMPUTE LK-START = LS-I + 1
    GOBACK.
END PROGRAM PLB-ASM-OPERAND.
