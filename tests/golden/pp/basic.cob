*> A copybook found on the search path, one found relative to this
*> file, and one found in a library.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY PAYREC.
COPY "copy/dates.cpy".
COPY SHARED OF LIB.
01  AFTER-COPIES PIC X.
