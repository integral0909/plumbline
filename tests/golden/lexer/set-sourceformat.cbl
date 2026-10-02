      * >>SET SOURCEFORMAT switches the reference format, like >>SOURCE.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SWITCH.
       PROCEDURE DIVISION.
       >>SET SOURCEFORMAT "FREE"
DISPLAY "free here"
>>SET SOURCEFORMAT "FIXED"
           DISPLAY "fixed again"                                        IGNORED
           STOP RUN.
