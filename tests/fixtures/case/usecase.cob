*> COPY of a word, which is tried in lower case first: the path must be
*> the file's own name, UPPERBK.cpy, on any file system.
IDENTIFICATION DIVISION.
PROGRAM-ID. USECASE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY UPPERBK.
PROCEDURE DIVISION.
    MOVE SPACES TO UPPER-RECORD
    DISPLAY UPPER-RECORD
    GOBACK.
