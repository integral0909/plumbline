*> EXEC DLI names COBOL data in its options, like EXEC CICS, but the
*> name in SEGMENT(...) is a segment, and a name before a relational
*> operator in WHERE(...) is a field of it. The translator declares
*> the DL/I interface block (DIBSTAT).
IDENTIFICATION DIVISION.
PROGRAM-ID. DLIREAD.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  PCB-NUM             PIC S9(4) COMP VALUE 1.
01  ACCOUNT-ID          PIC 9(11) VALUE 0.
01  SUMMARY-SEGMENT     PIC X(100).
PROCEDURE DIVISION.
    EXEC DLI GU USING PCB(PCB-NUM)
        SEGMENT (PAUTSUM0)
        INTO (SUMMARY-SEGMENT)
        WHERE (ACCNTID = ACCOUNT-ID)
    END-EXEC
    IF DIBSTAT NOT = SPACES
        DISPLAY "not found"
    END-IF
    GOBACK.
