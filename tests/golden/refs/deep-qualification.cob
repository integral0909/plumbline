*> Two records that differ only in the outermost of ten qualifiers.
IDENTIFICATION DIVISION.
PROGRAM-ID. DEEPQUAL.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  REC-A.
    02  G02.
     03  G03.
      04  G04.
       05  G05.
        06  G06.
         07  G07.
          08  G08.
           09  G09.
            10  ITEM PIC X VALUE "A".
01  REC-B.
    02  G02.
     03  G03.
      04  G04.
       05  G05.
        06  G06.
         07  G07.
          08  G08.
           09  G09.
            10  ITEM PIC X VALUE "B".
PROCEDURE DIVISION.
    DISPLAY ITEM OF G09 OF G08 OF G07 OF G06 OF G05 OF G04 OF G03 OF G02
        OF REC-B
    DISPLAY ITEM OF G09 OF G08 OF G07 OF G06 OF G05 OF G04 OF G03 OF G02
        IN REC-A
    STOP RUN.
