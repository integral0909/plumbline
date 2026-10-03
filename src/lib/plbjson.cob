*> ---------------------------------------------------------------
*> plbjson: helpers for writing JSON and URIs.
*> ---------------------------------------------------------------

*> PLB-JSON-STRING: append VALUE (up to its last non-space character)
*> to OUT at POINTER as a JSON string literal, quotes included.
*> Quotation marks, backslashes, and control characters are escaped;
*> bytes above X"7F" are copied as they are (the input is UTF-8).
*> Output that does not fit is cut off, but the closing quote is
*> always written when there is room for it.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-JSON-STRING.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-CH                   PIC X.
01  LS-CODE                 PIC 9(4) COMP-5.
01  LS-HIGH                 PIC 9(4) COMP-5.
01  LS-LOW                  PIC 9(4) COMP-5.
01  LS-HEX                  PIC X(16) VALUE "0123456789abcdef".
01  LS-ESCAPE               PIC X(6).
01  LS-ESCAPE-LEN           PIC 9(4) COMP-5.
01  LS-LIMIT                PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-VALUE                PIC X ANY LENGTH.
01  LK-OUT                  PIC X ANY LENGTH.
01  LK-POINTER              PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-VALUE LK-OUT LK-POINTER.
    *> Keep one position for the closing quote.
    COMPUTE LS-LIMIT = FUNCTION LENGTH(LK-OUT) - 1
    MOVE '"' TO LS-ESCAPE
    MOVE 1 TO LS-ESCAPE-LEN
    PERFORM PUT-ESCAPE
    CALL "PLB-STR-LENGTH" USING LK-VALUE LS-LEN
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        MOVE LK-VALUE(LS-I:1) TO LS-CH
        COMPUTE LS-CODE = FUNCTION ORD(LS-CH) - 1
        EVALUATE TRUE
            WHEN LS-CH = '"'
                MOVE '\"' TO LS-ESCAPE
                MOVE 2 TO LS-ESCAPE-LEN
            WHEN LS-CH = "\"
                MOVE "\\" TO LS-ESCAPE
                MOVE 2 TO LS-ESCAPE-LEN
            WHEN LS-CODE = 10
                MOVE "\n" TO LS-ESCAPE
                MOVE 2 TO LS-ESCAPE-LEN
            WHEN LS-CODE = 13
                MOVE "\r" TO LS-ESCAPE
                MOVE 2 TO LS-ESCAPE-LEN
            WHEN LS-CODE = 9
                MOVE "\t" TO LS-ESCAPE
                MOVE 2 TO LS-ESCAPE-LEN
            WHEN LS-CODE < 32 OR LS-CODE = 127
                MOVE "\u00" TO LS-ESCAPE
                DIVIDE LS-CODE BY 16 GIVING LS-HIGH REMAINDER LS-LOW
                MOVE LS-HEX(LS-HIGH + 1:1) TO LS-ESCAPE(5:1)
                MOVE LS-HEX(LS-LOW + 1:1) TO LS-ESCAPE(6:1)
                MOVE 6 TO LS-ESCAPE-LEN
            WHEN OTHER
                MOVE LS-CH TO LS-ESCAPE
                MOVE 1 TO LS-ESCAPE-LEN
        END-EVALUATE
        PERFORM PUT-ESCAPE
    END-PERFORM
    ADD 1 TO LS-LIMIT
    MOVE '"' TO LS-ESCAPE
    MOVE 1 TO LS-ESCAPE-LEN
    PERFORM PUT-ESCAPE
    GOBACK.

PUT-ESCAPE.
    IF LK-POINTER + LS-ESCAPE-LEN - 1 <= LS-LIMIT
        STRING LS-ESCAPE(1:LS-ESCAPE-LEN) DELIMITED BY SIZE
            INTO LK-OUT WITH POINTER LK-POINTER
    END-IF.
END PROGRAM PLB-JSON-STRING.

*> PLB-URI-PATH: append file path PATH to OUT at POINTER as the path
*> of a relative URI: characters outside the unreserved set and "/"
*> are percent-encoded, so a path with spaces or "#" stays one URI.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-URI-PATH.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-CH                   PIC X.
01  LS-CODE                 PIC 9(4) COMP-5.
01  LS-HIGH                 PIC 9(4) COMP-5.
01  LS-LOW                  PIC 9(4) COMP-5.
01  LS-HEX                  PIC X(16) VALUE "0123456789ABCDEF".
LINKAGE SECTION.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-OUT                  PIC X ANY LENGTH.
01  LK-POINTER              PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-OUT LK-POINTER.
    CALL "PLB-STR-LENGTH" USING LK-PATH LS-LEN
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        MOVE LK-PATH(LS-I:1) TO LS-CH
        IF LK-POINTER + 2 > FUNCTION LENGTH(LK-OUT)
            EXIT PERFORM
        END-IF
        IF LS-CH >= "A" AND LS-CH <= "Z" OR LS-CH >= "a" AND LS-CH <= "z"
           OR LS-CH >= "0" AND LS-CH <= "9" OR LS-CH = "-" OR LS-CH = "."
           OR LS-CH = "_" OR LS-CH = "~" OR LS-CH = "/"
            MOVE LS-CH TO LK-OUT(LK-POINTER:1)
            ADD 1 TO LK-POINTER
        ELSE
            COMPUTE LS-CODE = FUNCTION ORD(LS-CH) - 1
            DIVIDE LS-CODE BY 16 GIVING LS-HIGH REMAINDER LS-LOW
            MOVE "%" TO LK-OUT(LK-POINTER:1)
            MOVE LS-HEX(LS-HIGH + 1:1) TO LK-OUT(LK-POINTER + 1:1)
            MOVE LS-HEX(LS-LOW + 1:1) TO LK-OUT(LK-POINTER + 2:1)
            ADD 3 TO LK-POINTER
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-URI-PATH.
