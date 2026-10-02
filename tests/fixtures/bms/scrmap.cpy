*> The symbolic map of SCRMAP, from an older version of the map:
*> CUSTNM was 25 characters, STOPPER was not there, and OLDFLD was.
01  SCRMAPI.
    02  FILLER         PIC X(12).
    02  CUSTNOL        COMP PIC S9(4).
    02  CUSTNOF        PIC X.
    02  FILLER REDEFINES CUSTNOF.
        03  CUSTNOA    PIC X.
    02  CUSTNOI        PIC X(8).
    02  CUSTNML        COMP PIC S9(4).
    02  CUSTNMF        PIC X.
    02  FILLER REDEFINES CUSTNMF.
        03  CUSTNMA    PIC X.
    02  CUSTNMI        PIC X(25).
    02  OLDFLDL        COMP PIC S9(4).
    02  OLDFLDF        PIC X.
    02  FILLER REDEFINES OLDFLDF.
        03  OLDFLDA    PIC X.
    02  OLDFLDI        PIC X(10).
    02  LINESL         COMP PIC S9(4).
    02  LINESF         PIC X.
    02  LINESI         PIC X(39).
    02  NEXTTOL        COMP PIC S9(4).
    02  NEXTTOF        PIC X.
    02  NEXTTOI        PIC X(10).
    02  ERRMSGL        COMP PIC S9(4).
    02  ERRMSGF        PIC X.
    02  ERRMSGI        PIC X(80).
    02  FKEYSL         COMP PIC S9(4).
    02  FKEYSF         PIC X.
    02  FKEYSI         PIC X(79).
