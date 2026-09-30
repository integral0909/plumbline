*> Operators, parentheses, reference modification, pseudo-text.
    COMPUTE R = (A + B) * C / D ** 2 - E
    IF A = B AND C <> D OR E >= F OR G <= H OR I < J OR K > L
       DISPLAY A(1:2) B (I, J)
    END-IF
    DISPLAY "A" & "B"
    COPY PAYREC REPLACING ==:PFX:== BY ==WS==.
