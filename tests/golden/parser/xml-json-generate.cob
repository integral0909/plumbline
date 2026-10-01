*> XML GENERATE and JSON GENERATE with their phrases: GENERATE and
*> SUPPRESS are words of the statement here, not Report Writer verbs,
*> WHEN belongs to SUPPRESS, and NAME OF / TYPE OF name an item. A
*> DISPLAY in a phrase ends with END-DISPLAY: DISPLAY takes ON
*> EXCEPTION too, and a phrase goes to the innermost statement.
IDENTIFICATION DIVISION.
PROGRAM-ID. GENERATES.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  OUT-TEXT            PIC X(200).
01  REC.
    05  A               PIC X(4).
    05  B               PIC 9(3).
PROCEDURE DIVISION.
    XML GENERATE OUT-TEXT FROM REC
        WITH XML-DECLARATION WITH ATTRIBUTES
        NAME OF A IS "alpha"
        TYPE OF B IS ATTRIBUTE
        SUPPRESS WHEN SPACES
        ON EXCEPTION
            DISPLAY "XML failed: " XML-CODE END-DISPLAY
        NOT ON EXCEPTION
            DISPLAY OUT-TEXT
    END-XML
    JSON GENERATE OUT-TEXT FROM REC
        ON EXCEPTION
            DISPLAY "JSON failed: " JSON-CODE END-DISPLAY
        NOT ON EXCEPTION
            DISPLAY OUT-TEXT
    END-JSON
    STOP RUN.
