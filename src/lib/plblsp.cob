*> ---------------------------------------------------------------
*> plblsp: the pieces of a Language Server Protocol server.
*>
*>   PLB-LSP-RECEIVE     read one message from standard input
*>   PLB-LSP-SEND        write one message to standard output
*>   PLB-JSON-GET        the value of a key in a JSON message
*>   PLB-LSP-URI-PATH    the file path of a file: URI, and back
*>   PLB-LSP-WRITE-FILE  write a document's text to a file
*>
*> Messages are framed as the protocol says: header lines ending in
*> CR LF, among them Content-Length, an empty line, and then exactly
*> that many bytes of JSON.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LSP-RECEIVE.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    *> Standard input one byte at a time: a pipe cannot be read by
    *> position, but a file of one-byte records can be read in turn.
    SELECT INPUT-FILE ASSIGN TO WS-INPUT-PATH
        ORGANIZATION IS SEQUENTIAL
        FILE STATUS IS WS-INPUT-STATUS.
DATA DIVISION.
FILE SECTION.
FD  INPUT-FILE.
01  INPUT-BYTE              PIC X.
WORKING-STORAGE SECTION.
*> plumbline: ignore hard-coded-path -- Plumbline runs on POSIX hosts
01  WS-INPUT-PATH           PIC X(16) VALUE "/dev/stdin".
01  WS-INPUT-STATUS         PIC XX.
01  WS-OPEN                 PIC X VALUE "N".
LOCAL-STORAGE SECTION.
01  LS-HEADER               PIC X(256).
01  LS-HEADER-LEN           PIC 9(9) COMP-5.
01  LS-CONTENT-LENGTH       PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-EOF                  PIC X VALUE "N".
01  LS-DIGIT                PIC 9.
LINKAGE SECTION.
*>   STATUS: 0 a message, 1 end of input, 2 too large (skipped),
*>   3 no Content-Length
01  LK-BUFFER               PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-BUFFER LK-LENGTH LK-STATUS.
    MOVE 0 TO LK-LENGTH LK-STATUS LS-CONTENT-LENGTH
    IF WS-OPEN = "N"
        OPEN INPUT INPUT-FILE
        IF WS-INPUT-STATUS NOT = "00"
            MOVE 1 TO LK-STATUS
            GOBACK
        END-IF
        MOVE "Y" TO WS-OPEN
    END-IF
    *> Header lines up to the empty one.
    PERFORM UNTIL EXIT
        PERFORM READ-HEADER-LINE
        IF LS-EOF = "Y"
            MOVE 1 TO LK-STATUS
            PERFORM CLOSE-INPUT
            GOBACK
        END-IF
        IF LS-HEADER-LEN = 0
            EXIT PERFORM
        END-IF
        IF LS-HEADER-LEN > 16
            IF FUNCTION UPPER-CASE(LS-HEADER(1:15)) = "CONTENT-LENGTH:"
                MOVE 0 TO LS-CONTENT-LENGTH
                PERFORM VARYING LS-I FROM 16 BY 1
                        UNTIL LS-I > LS-HEADER-LEN
                    IF LS-HEADER(LS-I:1) >= "0"
                       AND LS-HEADER(LS-I:1) <= "9"
                        MOVE LS-HEADER(LS-I:1) TO LS-DIGIT
                        COMPUTE LS-CONTENT-LENGTH =
                            LS-CONTENT-LENGTH * 10 + LS-DIGIT
                    END-IF
                END-PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-CONTENT-LENGTH = 0
        MOVE 3 TO LK-STATUS
        GOBACK
    END-IF
    *> The content, kept if it fits.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-CONTENT-LENGTH
        READ INPUT-FILE
            AT END
                MOVE 1 TO LK-STATUS
                PERFORM CLOSE-INPUT
                GOBACK
        END-READ
        IF LS-I <= FUNCTION LENGTH(LK-BUFFER)
            MOVE INPUT-BYTE TO LK-BUFFER(LS-I:1)
        END-IF
    END-PERFORM
    IF LS-CONTENT-LENGTH > FUNCTION LENGTH(LK-BUFFER)
        MOVE 2 TO LK-STATUS
    ELSE
        MOVE LS-CONTENT-LENGTH TO LK-LENGTH
    END-IF
    GOBACK.

*> One header line, without its CR LF.
READ-HEADER-LINE.
    MOVE SPACES TO LS-HEADER
    MOVE 0 TO LS-HEADER-LEN
    PERFORM UNTIL EXIT
        READ INPUT-FILE
            AT END
                MOVE "Y" TO LS-EOF
                EXIT PERFORM
        END-READ
        IF INPUT-BYTE = X"0A"
            EXIT PERFORM
        END-IF
        IF INPUT-BYTE NOT = X"0D"
           AND LS-HEADER-LEN < LENGTH OF LS-HEADER
            ADD 1 TO LS-HEADER-LEN
            MOVE INPUT-BYTE TO LS-HEADER(LS-HEADER-LEN:1)
        END-IF
    END-PERFORM.

CLOSE-INPUT.
    IF WS-OPEN = "Y"
        CLOSE INPUT-FILE
        MOVE "N" TO WS-OPEN
    END-IF.
END PROGRAM PLB-LSP-RECEIVE.

*> PLB-LSP-SEND: BUFFER(1:LENGTH) as one message, then flush standard
*> output so that the client gets it now.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LSP-SEND.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-BUFFER               PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-BUFFER LK-LENGTH.
    MOVE LK-LENGTH TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    DISPLAY "Content-Length: " LS-NUM-TEXT(1:LS-NUM-LEN) X"0D0A0D0A"
        WITH NO ADVANCING
    IF LK-LENGTH > 0
        DISPLAY LK-BUFFER(1:LK-LENGTH) WITH NO ADVANCING
    END-IF
    *> The C library's fflush(NULL): standard output is buffered when
    *> it is a pipe, and the client waits for the whole message.
    CALL "fflush" USING BY VALUE 0
    GOBACK.
END PROGRAM PLB-LSP-SEND.

*> PLB-JSON-GET: the value of the first "KEY": in BUFFER(1:LENGTH).
*> KIND is "S" for a string (VALUE is the decoded text), "N" for any
*> other value (VALUE is its text as written, up to the next , } ] or
*> space), or "-" when the key is not there. VALUE-LEN is the length
*> of the value, which may be longer than VALUE can hold.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-JSON-GET.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-KEY                  PIC X(66).
01  LS-KEY-LEN              PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-CH                   PIC X.
01  LS-CODE                 PIC 9(9) COMP-5.
01  LS-LOW                  PIC 9(9) COMP-5.
01  LS-HEX-DIGIT            PIC 9(4) COMP-5.
01  LS-K                    PIC 9(4) COMP-5.
01  LS-BYTES.
    05  LS-BYTE             PIC X OCCURS 4 TIMES.
01  LS-BYTE-COUNT           PIC 9(4) COMP-5.
01  LS-MATCH                PIC X.
LINKAGE SECTION.
01  LK-BUFFER               PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-KIND                 PIC X.
01  LK-VALUE                PIC X ANY LENGTH.
01  LK-VALUE-LEN            PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-BUFFER LK-LENGTH LK-NAME LK-KIND LK-VALUE
        LK-VALUE-LEN.
    MOVE "-" TO LK-KIND
    MOVE SPACES TO LK-VALUE
    MOVE 0 TO LK-VALUE-LEN
    MOVE SPACES TO LS-KEY
    STRING '"' DELIMITED BY SIZE
           LK-NAME DELIMITED BY SPACE
           '"' DELIMITED BY SIZE
        INTO LS-KEY
    CALL "PLB-STR-LENGTH" USING LS-KEY LS-KEY-LEN
    *> The key, outside strings: a quote inside a string is escaped,
    *> so "key" with its quotes only appears as a key or a value.
    MOVE 0 TO LS-J
    PERFORM VARYING LS-I FROM 1 BY 1
            UNTIL LS-I + LS-KEY-LEN - 1 > LK-LENGTH
        PERFORM MATCH-KEY
        IF LS-MATCH = "Y"
            COMPUTE LS-J = LS-I + LS-KEY-LEN
            PERFORM SKIP-SPACES
            IF LS-J <= LK-LENGTH
                IF LK-BUFFER(LS-J:1) = ":"
                    ADD 1 TO LS-J
                    EXIT PERFORM
                END-IF
            END-IF
            MOVE 0 TO LS-J
        END-IF
    END-PERFORM
    IF LS-J = 0
        GOBACK
    END-IF
    PERFORM SKIP-SPACES
    IF LS-J > LK-LENGTH
        GOBACK
    END-IF
    IF LK-BUFFER(LS-J:1) = '"'
        MOVE "S" TO LK-KIND
        ADD 1 TO LS-J
        PERFORM READ-STRING
    ELSE
        MOVE "N" TO LK-KIND
        PERFORM UNTIL LS-J > LK-LENGTH
            MOVE LK-BUFFER(LS-J:1) TO LS-CH
            IF LS-CH = "," OR LS-CH = "}" OR LS-CH = "]" OR LS-CH = SPACE
               OR LS-CH = X"0A" OR LS-CH = X"0D"
                EXIT PERFORM
            END-IF
            MOVE LS-CH TO LS-BYTE(1)
            MOVE 1 TO LS-BYTE-COUNT
            PERFORM PUT-BYTES
            ADD 1 TO LS-J
        END-PERFORM
    END-IF
    GOBACK.

*> LS-MATCH = "Y" when the key starts at LS-I.
MATCH-KEY.
    MOVE "Y" TO LS-MATCH
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-KEY-LEN
        IF LK-BUFFER(LS-I + LS-K - 1:1) NOT = LS-KEY(LS-K:1)
            MOVE "N" TO LS-MATCH
            EXIT PERFORM
        END-IF
    END-PERFORM.

SKIP-SPACES.
    PERFORM UNTIL LS-J > LK-LENGTH
        IF LK-BUFFER(LS-J:1) NOT = SPACE AND LK-BUFFER(LS-J:1) NOT = X"0A"
           AND LK-BUFFER(LS-J:1) NOT = X"0D"
           AND LK-BUFFER(LS-J:1) NOT = X"09"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-J
    END-PERFORM.

*> A string from LS-J to its closing quote, decoding escapes.
READ-STRING.
    PERFORM UNTIL LS-J > LK-LENGTH
        MOVE LK-BUFFER(LS-J:1) TO LS-CH
        IF LS-CH = '"'
            EXIT PERFORM
        END-IF
        MOVE 1 TO LS-BYTE-COUNT
        MOVE LS-CH TO LS-BYTE(1)
        IF LS-CH = "\" AND LS-J < LK-LENGTH
            ADD 1 TO LS-J
            MOVE LK-BUFFER(LS-J:1) TO LS-CH
            EVALUATE LS-CH
                WHEN "n"   MOVE X"0A" TO LS-BYTE(1)
                WHEN "r"   MOVE X"0D" TO LS-BYTE(1)
                WHEN "t"   MOVE X"09" TO LS-BYTE(1)
                WHEN "b"   MOVE X"08" TO LS-BYTE(1)
                WHEN "f"   MOVE X"0C" TO LS-BYTE(1)
                WHEN "u"   PERFORM UNICODE-ESCAPE
                WHEN OTHER MOVE LS-CH TO LS-BYTE(1)
            END-EVALUATE
        END-IF
        PERFORM PUT-BYTES
        ADD 1 TO LS-J
    END-PERFORM.

*> \uXXXX (and a following \uXXXX for a surrogate pair) as UTF-8.
UNICODE-ESCAPE.
    PERFORM READ-HEX
    IF LS-CODE >= 55296 AND LS-CODE <= 56319 AND LS-J + 6 <= LK-LENGTH
        IF LK-BUFFER(LS-J + 1:2) = "\u"
            MOVE LS-CODE TO LS-LOW
            ADD 2 TO LS-J
            PERFORM READ-HEX
            COMPUTE LS-CODE = 65536 + (LS-LOW - 55296) * 1024
                + (LS-CODE - 56320)
        END-IF
    END-IF
    EVALUATE TRUE
        WHEN LS-CODE < 128
            MOVE FUNCTION CHAR(LS-CODE + 1) TO LS-BYTE(1)
            MOVE 1 TO LS-BYTE-COUNT
        WHEN LS-CODE < 2048
            MOVE FUNCTION CHAR(192 + LS-CODE / 64 + 1) TO LS-BYTE(1)
            MOVE FUNCTION CHAR(128 + FUNCTION MOD(LS-CODE, 64) + 1)
                TO LS-BYTE(2)
            MOVE 2 TO LS-BYTE-COUNT
        WHEN LS-CODE < 65536
            MOVE FUNCTION CHAR(224 + LS-CODE / 4096 + 1) TO LS-BYTE(1)
            MOVE FUNCTION CHAR(128 + FUNCTION MOD(LS-CODE / 64, 64) + 1)
                TO LS-BYTE(2)
            MOVE FUNCTION CHAR(128 + FUNCTION MOD(LS-CODE, 64) + 1)
                TO LS-BYTE(3)
            MOVE 3 TO LS-BYTE-COUNT
        WHEN OTHER
            MOVE FUNCTION CHAR(240 + LS-CODE / 262144 + 1) TO LS-BYTE(1)
            MOVE FUNCTION CHAR(128 + FUNCTION MOD(LS-CODE / 4096, 64)
                + 1) TO LS-BYTE(2)
            MOVE FUNCTION CHAR(128 + FUNCTION MOD(LS-CODE / 64, 64) + 1)
                TO LS-BYTE(3)
            MOVE FUNCTION CHAR(128 + FUNCTION MOD(LS-CODE, 64) + 1)
                TO LS-BYTE(4)
            MOVE 4 TO LS-BYTE-COUNT
    END-EVALUATE.

*> LS-CODE = the four hex digits after LS-J (the "u"); LS-J is left
*> on the last of them.
READ-HEX.
    MOVE 0 TO LS-CODE
    PERFORM 4 TIMES
        ADD 1 TO LS-J
        IF LS-J <= LK-LENGTH
            MOVE LK-BUFFER(LS-J:1) TO LS-CH
            EVALUATE TRUE
                WHEN LS-CH >= "0" AND LS-CH <= "9"
                    COMPUTE LS-HEX-DIGIT = FUNCTION ORD(LS-CH)
                        - FUNCTION ORD("0")
                WHEN LS-CH >= "a" AND LS-CH <= "f"
                    COMPUTE LS-HEX-DIGIT = FUNCTION ORD(LS-CH)
                        - FUNCTION ORD("a") + 10
                WHEN LS-CH >= "A" AND LS-CH <= "F"
                    COMPUTE LS-HEX-DIGIT = FUNCTION ORD(LS-CH)
                        - FUNCTION ORD("A") + 10
                WHEN OTHER
                    MOVE 0 TO LS-HEX-DIGIT
            END-EVALUATE
            COMPUTE LS-CODE = LS-CODE * 16 + LS-HEX-DIGIT
        END-IF
    END-PERFORM.

PUT-BYTES.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LS-BYTE-COUNT
        ADD 1 TO LK-VALUE-LEN
        IF LK-VALUE-LEN <= FUNCTION LENGTH(LK-VALUE)
            MOVE LS-BYTE(LS-K) TO LK-VALUE(LK-VALUE-LEN:1)
        END-IF
    END-PERFORM.
END PROGRAM PLB-JSON-GET.

*> PLB-LSP-URI-PATH: the path of a file: URI, with %XX decoded; PATH
*> is spaces for any other URI.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LSP-URI-PATH.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-OUT                  PIC 9(9) COMP-5.
01  LS-HIGH                 PIC 9(4) COMP-5.
01  LS-LOW                  PIC 9(4) COMP-5.
01  LS-HEX                  PIC X(16) VALUE "0123456789ABCDEF".
LINKAGE SECTION.
01  LK-URI                  PIC X ANY LENGTH.
01  LK-PATH                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-URI LK-PATH.
    MOVE SPACES TO LK-PATH
    CALL "PLB-STR-LENGTH" USING LK-URI LS-LEN
    IF LS-LEN < 8
        GOBACK
    END-IF
    IF LK-URI(1:7) NOT = "file://"
        GOBACK
    END-IF
    MOVE 0 TO LS-OUT
    MOVE 8 TO LS-I
    PERFORM UNTIL LS-I > LS-LEN OR LS-OUT >= FUNCTION LENGTH(LK-PATH)
        ADD 1 TO LS-OUT
        IF LK-URI(LS-I:1) = "%" AND LS-I + 2 <= LS-LEN
            MOVE 0 TO LS-HIGH LS-LOW
            INSPECT LS-HEX TALLYING LS-HIGH FOR CHARACTERS
                BEFORE FUNCTION UPPER-CASE(LK-URI(LS-I + 1:1))
            INSPECT LS-HEX TALLYING LS-LOW FOR CHARACTERS
                BEFORE FUNCTION UPPER-CASE(LK-URI(LS-I + 2:1))
            MOVE FUNCTION CHAR(LS-HIGH * 16 + LS-LOW + 1)
                TO LK-PATH(LS-OUT:1)
            ADD 3 TO LS-I
        ELSE
            MOVE LK-URI(LS-I:1) TO LK-PATH(LS-OUT:1)
            ADD 1 TO LS-I
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-LSP-URI-PATH.

*> PLB-LSP-WRITE-FILE: TEXT(1:LENGTH) as the whole content of the file
*> at PATH, byte for byte. STATUS is 0 when it was written.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-LSP-WRITE-FILE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-PATH                 PIC X(512).
01  LS-HANDLE               PIC X(4).
01  LS-OFFSET               PIC X(8) COMP-X.
01  LS-COUNT                PIC X(4) COMP-X.
01  LS-FLAGS                PIC X COMP-X VALUE 0.
*> Write only, no sharing restriction, a disk file.
01  LS-ACCESS               PIC X COMP-X VALUE 2.
01  LS-DENY                 PIC X COMP-X VALUE 0.
01  LS-DEVICE               PIC X COMP-X VALUE 0.
01  LS-CHUNK                PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-RESULT               PIC S9(9) COMP-5.
LINKAGE SECTION.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-TEXT LK-LENGTH LK-STATUS.
    MOVE 1 TO LK-STATUS
    MOVE LK-PATH TO LS-PATH
    CALL "CBL_DELETE_FILE" USING LS-PATH
    CALL "CBL_CREATE_FILE" USING LS-PATH LS-ACCESS LS-DENY LS-DEVICE
        LS-HANDLE RETURNING LS-RESULT
    IF LS-RESULT NOT = 0
        GOBACK
    END-IF
    MOVE 0 TO LS-OFFSET
    PERFORM UNTIL LS-OFFSET >= LK-LENGTH
        COMPUTE LS-CHUNK = LK-LENGTH - LS-OFFSET
        IF LS-CHUNK > 65536
            MOVE 65536 TO LS-CHUNK
        END-IF
        MOVE LS-CHUNK TO LS-COUNT
        COMPUTE LS-FROM = LS-OFFSET + 1
        *> The text from that position on: CBL_WRITE_FILE takes
        *> LS-COUNT bytes of it.
        CALL "CBL_WRITE_FILE" USING LS-HANDLE LS-OFFSET LS-COUNT
            LS-FLAGS LK-TEXT(LS-FROM:)
            RETURNING LS-RESULT
        IF LS-RESULT NOT = 0
            CALL "CBL_CLOSE_FILE" USING LS-HANDLE
            GOBACK
        END-IF
        ADD LS-CHUNK TO LS-OFFSET
    END-PERFORM
    CALL "CBL_CLOSE_FILE" USING LS-HANDLE
    MOVE 0 TO LK-STATUS
    GOBACK.
END PROGRAM PLB-LSP-WRITE-FILE.
