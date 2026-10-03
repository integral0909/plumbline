*> plbcrud.cpy: which programs create, read, update, and delete which
*> resources (plumbline crud, src/lib/plbcrud.cob): DB2 tables, COBOL
*> files, and CICS files. Entries beyond CX-MAX are counted in
*> CX-DROPPED.
78  CX-MAX                      VALUE 20000.
01  PLB-CRUD.
    05  CX-COUNT                PIC 9(9) COMP-5.
    05  CX-DROPPED              PIC 9(9) COMP-5.
    05  CX-ENTRY                OCCURS 0 TO CX-MAX TIMES
                                DEPENDING ON CX-COUNT.
        10  CX-PROGRAM          PIC X(31).
        *>   T a DB2 table   F a COBOL file   K a CICS file
        10  CX-KIND             PIC X.
        10  CX-NAME             PIC X(64).
        *> "Y" for each operation the program does on it.
        10  CX-CREATE           PIC X.
        10  CX-READ             PIC X.
        10  CX-UPDATE           PIC X.
        10  CX-DELETE           PIC X.
