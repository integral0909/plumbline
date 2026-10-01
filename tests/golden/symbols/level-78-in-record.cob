*> Level-78 constants among the entries of a record, as in GnuCOBOL's
*> EXTFH copybook: they do not end the record, and take no space in it.
IDENTIFICATION DIVISION.
PROGRAM-ID. CONSTS.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  FILE-CONTROL-BLOCK.
    05  FCB-STATUS          PIC XX.
    05  FCB-OPEN-MODE       PIC 9.
        78  FCB-INPUT       VALUE 0.
        78  FCB-OUTPUT      VALUE 1.
    05  FCB-RECORD-LENGTH   PIC 9(4).
    78  FCB-MAX-LENGTH      VALUE 9999.
    05  FCB-NAME            PIC X(8).
01  NEXT-RECORD             PIC X.
PROCEDURE DIVISION.
    MOVE FCB-OUTPUT TO FCB-OPEN-MODE
    MOVE FCB-MAX-LENGTH TO FCB-RECORD-LENGTH
    STOP RUN.
