*> A section whose paragraphs are performed one by one is in use even
*> though control never enters at its header; a paragraph of it that
*> only unreachable code performs is reported. A section none of whose
*> code runs is reported once, for all its paragraphs.
IDENTIFICATION DIVISION.
PROGRAM-ID. SECTIONS.
PROCEDURE DIVISION.
MAIN SECTION.
START-HERE.
    PERFORM SAY-HELLO
    STOP RUN.
DEAD-CALLER.
    PERFORM SAY-GOODBYE.
UTILITIES SECTION.
SAY-HELLO.
    DISPLAY "HELLO".
SAY-GOODBYE.
    DISPLAY "GOODBYE".
UNUSED SECTION.
NEVER-ONE.
    DISPLAY "ONE".
NEVER-TWO.
    DISPLAY "TWO".
