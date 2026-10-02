*> PLB-C035 duplicate-paragraph: a paragraph name repeated in the same
*> section, or outside sections in the same program, and a section
*> name repeated in a program. The same paragraph name in another
*> section is fine.
IDENTIFICATION DIVISION.
PROGRAM-ID. DUPS.
PROCEDURE DIVISION.
MAIN SECTION.
BEGIN.
    PERFORM CHECK-IT
    PERFORM OTHER-WORK
    STOP RUN.
CHECK-IT.
    DISPLAY "FIRST".
CHECK-IT.
    DISPLAY "SECOND".
OTHER-WORK SECTION.
CHECK-IT.
    DISPLAY "THIRD".
OTHER-WORK SECTION.
LAST-ONE.
    DISPLAY "FOURTH".
END PROGRAM DUPS.

IDENTIFICATION DIVISION.
PROGRAM-ID. NO-SECTIONS.
PROCEDURE DIVISION.
MAIN-LINE.
    PERFORM Finish-Up
    GOBACK.
FINISH-UP.
    DISPLAY "DONE".
finish-up.
    EXIT.
END PROGRAM NO-SECTIONS.
