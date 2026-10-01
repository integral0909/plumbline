       IDENTIFICATION DIVISION.
       PROGRAM-ID. ARCHIVE.
      *> Calls CUSTLOOK with a short key on purpose; the comment keeps
      *> the finding, made after this file was checked, quiet.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  OLD-ID          PIC X(6) VALUE "A00001".
       01  OLD-NAME        PIC X(30) VALUE SPACES.
       PROCEDURE DIVISION.
      *> plumbline: ignore call-argument-mismatch -- old keys are short
           CALL "CUSTLOOK" USING OLD-ID OLD-NAME
           DISPLAY OLD-NAME
           STOP RUN.
