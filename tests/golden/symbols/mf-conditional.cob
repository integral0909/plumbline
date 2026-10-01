      * Micro Focus conditional compilation: $IF NAME DEFINED, with
      * names from $SET CONSTANT, and $ELSE and $END.
       $SET CONSTANT TRACE-ON "Y"
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MFCOND.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       $IF TRACE-ON DEFINED
       01  TRACE-LINE        PIC X(132).
       $ELSE
       01  TRACE-LINE        PIC X(1).
       $END
       $IF NO-SUCH-NAME DEFINED
       01  NEVER-HERE        PIC X.
       $END
       PROCEDURE DIVISION.
           DISPLAY TRACE-LINE
           STOP RUN.
