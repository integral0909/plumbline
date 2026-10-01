*> Pseudo-text that ends right after a picture string: the closing ==
*> is not part of the picture.
IDENTIFICATION DIVISION.
PROGRAM-ID. REPLPIC.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  CUSTOMER.
    COPY TWOFIELDS REPLACING ==PIC 9(5).== BY ==PIC 9(8).==
                             ==NAME-FIELD      PIC X(20)== BY ==NAME-FIELD PIC X(40)==.
PROCEDURE DIVISION.
    DISPLAY CUSTOMER
    STOP RUN.
