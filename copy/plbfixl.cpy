*> plbfixl.cpy: the edits of the fixes accepted for one file.
*>
*> PLB-FIX-ACCEPT adds a fix's edits here when they can all be made;
*> PLB-FIX-WRITE writes the file with them. Each edit is on one line:
*> it replaces columns FXL-COLUMN up to but not including
*> FXL-END-COLUMN of line FXL-LINE with FXL-TEXT(1:FXL-TEXT-LEN).
78  FXL-MAX                     VALUE 4096.
01  PLB-FIX-LIST.
    05  FXL-COUNT               PIC 9(9) COMP-5.
    05  FXL-EDIT                OCCURS FXL-MAX TIMES.
        10  FXL-LINE            PIC 9(9) COMP-5.
        10  FXL-COLUMN          PIC 9(4) COMP-5.
        10  FXL-END-COLUMN      PIC 9(4) COMP-5.
        10  FXL-TEXT            PIC X(256).
        10  FXL-TEXT-LEN        PIC 9(9) COMP-5.
