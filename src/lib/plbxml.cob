*> ---------------------------------------------------------------
*> plbxml: text for XML reports.
*>
*> PLB-XML-TEXT USING TEXT LENGTH OUT POINTER appends the first LENGTH
*> characters of TEXT to OUT at POINTER, with & < > and " written as
*> entities, so that the text can go in an element or an attribute.
*> Control characters other than tab, which XML 1.0 cannot hold at
*> all, become "?".
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-XML-TEXT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-CODE                 PIC 9(4) COMP-5.
LINKAGE SECTION.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LEN                  PIC 9(9) COMP-5.
01  LK-OUT                  PIC X ANY LENGTH.
01  LK-PTR                  PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-TEXT LK-LEN LK-OUT LK-PTR.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > LK-LEN
        EVALUATE LK-TEXT(LS-K:1)
            WHEN "&"
                STRING "&amp;" DELIMITED BY SIZE
                    INTO LK-OUT WITH POINTER LK-PTR
            WHEN "<"
                STRING "&lt;" DELIMITED BY SIZE
                    INTO LK-OUT WITH POINTER LK-PTR
            WHEN ">"
                STRING "&gt;" DELIMITED BY SIZE
                    INTO LK-OUT WITH POINTER LK-PTR
            WHEN '"'
                STRING "&quot;" DELIMITED BY SIZE
                    INTO LK-OUT WITH POINTER LK-PTR
            WHEN OTHER
                COMPUTE LS-CODE = FUNCTION ORD(LK-TEXT(LS-K:1)) - 1
                IF (LS-CODE < 32 AND LS-CODE NOT = 9) OR LS-CODE = 127
                    STRING "?" DELIMITED BY SIZE
                        INTO LK-OUT WITH POINTER LK-PTR
                ELSE
                    STRING LK-TEXT(LS-K:1) DELIMITED BY SIZE
                        INTO LK-OUT WITH POINTER LK-PTR
                END-IF
        END-EVALUATE
    END-PERFORM
    GOBACK.
END PROGRAM PLB-XML-TEXT.
