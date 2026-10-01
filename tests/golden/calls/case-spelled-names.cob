*> GnuCOBOL keeps the case of a program name, so PROG and prog are
*> two programs: a CALL of "prog" calls the one spelled that way. When
*> only the case differs and nothing matches exactly, the call still
*> resolves without regard to case.
IDENTIFICATION DIVISION.
PROGRAM-ID. PROG.
PROCEDURE DIVISION.
    CALL "prog"
    CALL "Helper"
    STOP RUN.
IDENTIFICATION DIVISION.
PROGRAM-ID. prog.
PROCEDURE DIVISION.
    GOBACK.
END PROGRAM prog.
END PROGRAM PROG.
IDENTIFICATION DIVISION.
PROGRAM-ID. HELPER.
PROCEDURE DIVISION.
    GOBACK.
END PROGRAM HELPER.
