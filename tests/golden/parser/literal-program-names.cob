*> A program name may be a literal in PROGRAM-ID and a word in END
*> PROGRAM, or the other way round; case and the spaces around a
*> literal name do not matter. A name that differs is still reported.
PROGRAM-ID. "Caller".
PROCEDURE DIVISION.
    CALL "callee"
    STOP RUN.
PROGRAM-ID. "callee ".
PROCEDURE DIVISION.
    EXIT PROGRAM.
END PROGRAM CALLEE.
END PROGRAM " caller".
PROGRAM-ID. THIRD AS "the third".
PROCEDURE DIVISION.
    GOBACK.
END PROGRAM FOURTH.
