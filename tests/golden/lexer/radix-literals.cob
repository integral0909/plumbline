*> Radix literals of other dialects become numbers with their decimal
*> value: ACUCOBOL B#, O#, X#, and H#; HP COBOL % (octal). H"..." is
*> a Micro Focus hexadecimal literal. A # that starts no literal is
*> still an error.
IDENTIFICATION DIVISION.
PROGRAM-ID. R.
DATA DIVISION.
WORKING-STORAGE SECTION.
01 A PIC 9(10) VALUE %47.
01 B PIC X COMP-X VALUE H"80".
PROCEDURE DIVISION.
    DISPLAY B#101 O#17 X#ff h#FF %0 A B.
    DISPLAY Q#12 B#2
    STOP RUN.
