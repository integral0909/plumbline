       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTLOOK.
      *> Looks a customer up; includes the record through CUSTIO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           COPY CUSTIO.
       LINKAGE SECTION.
       01  LK-ID               PIC X(8).
       PROCEDURE DIVISION USING LK-ID.
           MOVE LK-ID TO CUST-ID
           GOBACK.
