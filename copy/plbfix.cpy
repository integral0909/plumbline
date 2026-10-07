*> plbfix.cpy: the fix for one finding, as edits of its file.
*>
*> FX-TITLE says what the fix does ("Change NEXT SENTENCE to
*> CONTINUE"); spaces, with no edits, when the finding has none. Each
*> edit replaces the text from line FX-LINE, column FX-COLUMN, up to
*> but not including line FX-END-LINE, column FX-END-COLUMN, with
*> FX-TEXT(1:FX-TEXT-LEN). Lines are line numbers in the file, columns
*> count from 1 in the line as read (tabs expanded). Edits are in the
*> order of the text and do not overlap.
78  FX-EDIT-MAX                 VALUE 64.
01  PLB-FIX.
    05  FX-TITLE                PIC X(80).
    05  FX-EDIT-COUNT           PIC 9(4) COMP-5.
    05  FX-EDIT                 OCCURS FX-EDIT-MAX TIMES.
        10  FX-LINE             PIC 9(9) COMP-5.
        10  FX-COLUMN           PIC 9(4) COMP-5.
        10  FX-END-LINE         PIC 9(9) COMP-5.
        10  FX-END-COLUMN       PIC 9(4) COMP-5.
        10  FX-TEXT             PIC X(256).
        10  FX-TEXT-LEN         PIC 9(9) COMP-5.
