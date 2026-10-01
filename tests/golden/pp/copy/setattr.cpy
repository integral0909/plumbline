*> Parts of words in parentheses, which COPY ... REPLACING
*> ==(TAG)== BY ==text== completes.
    IF FLG-(FIELD)-NOT-OK
        MOVE 1 TO (SCREEN)-ATTR
    END-IF
