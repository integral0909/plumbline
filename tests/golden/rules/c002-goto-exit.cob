*> GO TO xxx-EXIT inside a PERFORM ... THRU range stays within the
*> PERFORM: the exit paragraph returns, and does not fall into the
*> paragraph after it, which is only performed. A GO TO in code that
*> control flows into still carries the flow on.
IDENTIFICATION DIVISION.
PROGRAM-ID. GOTOEXIT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  CHOICE              PIC 9 VALUE 1.
PROCEDURE DIVISION.
MAIN-PARA.
    PERFORM EDIT-ONE THRU EDIT-ONE-EXIT
    PERFORM EDIT-TWO THRU EDIT-TWO-EXIT
    GO TO FINISH.
EDIT-ONE.
    IF CHOICE = 1
        GO TO EDIT-ONE-EXIT
    END-IF
    DISPLAY "ONE".
EDIT-ONE-EXIT.
    EXIT.
EDIT-TWO.
    DISPLAY "TWO".
EDIT-TWO-EXIT.
    EXIT.
FINISH.
    GO TO LAST-STEP.
SHARED-STEP.
    DISPLAY "SHARED".
LAST-STEP.
    PERFORM SHARED-STEP
    STOP RUN.
