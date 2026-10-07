*> PLB-C081 varying-wrong-direction: PERFORM VARYING whose steps never
*> make its UNTIL condition true.
IDENTIFICATION DIVISION.
PROGRAM-ID. VSTEP.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-I                PIC S9(4).
01  WS-J                PIC S9(4) COMP.
PROCEDURE DIVISION.
    *> Reported: away from the condition, up and down.
    PERFORM VARYING WS-I FROM 10 BY 1 UNTIL WS-I < 1
        DISPLAY WS-I
    END-PERFORM
    PERFORM VARYING WS-J FROM 1 BY -1 UNTIL WS-J IS GREATER THAN 10
        DISPLAY WS-J
    END-PERFORM
    *> Reported: past the limit without reaching it.
    PERFORM VARYING WS-I FROM 1 BY 2 UNTIL WS-I = 10
        DISPLAY WS-I
    END-PERFORM
    *> Not reported: toward the condition, reaching it with =, true
    *> at the start, and a limit that is not a literal.
    PERFORM VARYING WS-I FROM 10 BY -1 UNTIL WS-I < 1
        DISPLAY WS-I
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 3 UNTIL WS-I = 10
        DISPLAY WS-I
    END-PERFORM
    PERFORM VARYING WS-I FROM 20 BY 1 UNTIL WS-I > 10
        DISPLAY WS-I
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY -1 UNTIL WS-I > WS-J
        DISPLAY WS-I
    END-PERFORM
    GOBACK.
