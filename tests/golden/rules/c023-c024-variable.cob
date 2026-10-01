*> Tables whose size changes at run time: OCCURS ... TO UNBOUNDED has
*> no largest count, and a group with OCCURS DEPENDING ON in it has no
*> fixed length, so literal subscripts and reference modifications are
*> only checked where they can be. A subscript below 1 still is.
IDENTIFICATION DIVISION.
PROGRAM-ID. VARIABLE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  ROW-COUNT           PIC 9(4) VALUE 20.
LINKAGE SECTION.
01  OPEN-TABLE.
    05  OPEN-ROW        PIC X(4) OCCURS 1 TO UNBOUNDED
                        DEPENDING ON ROW-COUNT.
01  SIZED-TABLE.
    05  SIZED-HEADER    PIC X(2).
    05  SIZED-ROW       PIC X(4) OCCURS 1 TO 10
                        DEPENDING ON ROW-COUNT.
PROCEDURE DIVISION USING OPEN-TABLE SIZED-TABLE.
    MOVE "ABCD" TO OPEN-ROW (17)
    MOVE "ABCD" TO OPEN-ROW (0)
    MOVE "ABCD" TO SIZED-ROW (11)
    MOVE "X" TO SIZED-TABLE (20:1)
    MOVE "X" TO SIZED-HEADER (3:1)
    GOBACK.
