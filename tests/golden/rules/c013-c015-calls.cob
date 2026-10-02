      *> Calls between programs in one file: argument counts, passing
      *> modes, sizes, and recursion.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ORDERS.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  ORDER-ID        PIC X(8) VALUE SPACES.
       01  ORDER-TOTAL     PIC 9(7)V99 VALUE 0.
       01  SHORT-ID        PIC X(4) VALUE SPACES.
       01  ROUTINE-NAME    PIC X(8) VALUE "PRICING".
       PROCEDURE DIVISION.
      *>   Fine: the arguments match PRICING's parameters.
           CALL "PRICING" USING ORDER-ID ORDER-TOTAL
      *>   One argument short.
           CALL "PRICING" USING ORDER-ID
      *>   SHORT-ID is 4 bytes; PRICING's ORDER-KEY is 8.
           CALL "PRICING" USING SHORT-ID ORDER-TOTAL
      *>   A 3-character literal for an 8-byte parameter.
           CALL "PRICING" USING BY CONTENT "A12" ORDER-TOTAL
      *>   PRICING takes ORDER-AMOUNT by reference.
           CALL "PRICING" USING ORDER-ID BY VALUE ORDER-TOTAL
      *>   Not checked: the name is in a data item, or the program is
      *>   not part of this run.
           CALL ROUTINE-NAME USING ORDER-ID
           CALL "AUDITLOG" USING ORDER-ID
           CALL "TAXES" USING ORDER-TOTAL
           STOP RUN.
       END PROGRAM ORDERS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. PRICING.
       DATA DIVISION.
       LINKAGE SECTION.
       01  ORDER-KEY       PIC X(8).
       01  ORDER-AMOUNT    PIC 9(7)V99.
       PROCEDURE DIVISION USING ORDER-KEY ORDER-AMOUNT.
           IF ORDER-KEY = SPACES
               CALL "DISCOUNT" USING ORDER-AMOUNT
           END-IF
           GOBACK.
       END PROGRAM PRICING.

      *> DISCOUNT calls back into PRICING, which is not RECURSIVE.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DISCOUNT.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  NO-KEY          PIC X(8) VALUE SPACES.
       LINKAGE SECTION.
       01  AMOUNT          PIC 9(7)V99.
       PROCEDURE DIVISION USING AMOUNT.
           IF AMOUNT > 100
               CALL "PRICING" USING NO-KEY AMOUNT
           END-IF
           GOBACK.
       END PROGRAM DISCOUNT.

      *> TAXES may call itself: it is RECURSIVE.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TAXES IS RECURSIVE.
       DATA DIVISION.
       LINKAGE SECTION.
       01  AMOUNT          PIC 9(7)V99.
       PROCEDURE DIVISION USING AMOUNT.
           IF AMOUNT > 1000
               CALL "TAXES" USING AMOUNT
           END-IF
           GOBACK.
       END PROGRAM TAXES.
