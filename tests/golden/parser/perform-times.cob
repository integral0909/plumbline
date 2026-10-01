*> The count of a TIMES loop can be qualified and subscripted; a
*> procedure name can be qualified and followed by its own count.
IDENTIFICATION DIVISION.
PROGRAM-ID. TIMESES.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  TOTALS.
    05  CNT             PIC 9 OCCURS 3 TIMES.
01  N                   PIC 9 VALUE 2.
PROCEDURE DIVISION.
MAIN SECTION.
START-HERE.
    PERFORM N TIMES
        DISPLAY "A"
    END-PERFORM
    PERFORM CNT (2) TIMES
        DISPLAY "B"
    END-PERFORM
    PERFORM CNT OF TOTALS (N) TIMES
        DISPLAY "C"
    END-PERFORM
    PERFORM SAY-D OF MAIN 3 TIMES
    PERFORM SAY-D OF MAIN
    STOP RUN.
SAY-D.
    DISPLAY "D".
