*> REPLACING with pseudo-text, single words, and partial words.
COPY TEMPLATE REPLACING ==:PFX:== BY ==WS==
                        X-FIELD BY Y-FIELD
                        LEADING ==OLD== BY ==NEW==
                        TRAILING ==OLD== BY ==NEW==.
*> The rules apply only to the copybook, not to the text after it.
01  X-FIELD PIC X.
