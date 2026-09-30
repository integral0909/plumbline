*> REPLACING operands: literals, numbers, multi-token pseudo-text,
*> and empty replacements that delete text.
PROCEDURE DIVISION.
    COPY STMTS SUPPRESS PRINTING
        REPLACING 'DEFAULT' BY 'CUSTOM'
                  100 BY 250
                  ==UPON CONSOLE== BY ====
                  ==CHECK-IT THRU CHECK-IT-EXIT== BY ==VALIDATE==.
    COPY "stmts.cpy" OF "copy".
    REPLACE ==MOVE 1 TO X== BY ==INITIALIZE X==.
    MOVE 1 TO X
    MOVE 1 TO Y
    REPLACE LAST.
    STOP RUN.
