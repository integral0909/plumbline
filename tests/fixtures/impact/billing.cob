       IDENTIFICATION DIVISION.
       PROGRAM-ID. BILLING.
      *> Bills a customer: includes the record and calls CUSTLOOK.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           COPY CUSTREC.
       PROCEDURE DIVISION.
           CALL "CUSTLOOK" USING CUST-ID
           GOBACK.
