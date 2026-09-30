*> Numeric literals and words that contain digits.
01 WS-COUNT PIC 9.
    MOVE 42 TO WS-COUNT
    MOVE -7 TO X
    MOVE +3.25 TO Y
    MOVE .5 TO Z
    COMPUTE F = 1.5E+3 * 2.0E-1
    COMPUTE A = B - 1
    COMPUTE A = B -1
    MOVE ARR(-1) TO C
    PERFORM 100-INIT THRU 100-INIT-EXIT
    MOVE 1ST-VALUE TO X.
