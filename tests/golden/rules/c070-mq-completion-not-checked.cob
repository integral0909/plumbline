*> PLB-C070 mq-completion-not-checked: an MQ call whose completion code
*> and reason nothing tests before the next MQ call.
IDENTIFICATION DIVISION.
PROGRAM-ID. MQREAD.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  HCONN               PIC S9(9) BINARY VALUE 0.
01  HOBJ                PIC S9(9) BINARY VALUE 0.
01  MQ-CC               PIC S9(9) BINARY VALUE 0.
01  MQ-RC               PIC S9(9) BINARY VALUE 0.
01  BUFFER              PIC X(100).
01  DATA-LEN            PIC S9(9) BINARY VALUE 0.
PROCEDURE DIVISION.
GET-REQUEST.
    *> Reported: the MQGET's codes are only passed on to the MQCLOSE
    *> that CLOSE-QUEUE performs, which sets them anew.
    CALL 'MQGET' USING HCONN HOBJ BUFFER DATA-LEN MQ-CC MQ-RC
    DISPLAY BUFFER
    PERFORM CLOSE-QUEUE.
PUT-REPLY.
    *> Not reported: tested right after the call.
    CALL 'MQPUT' USING HCONN HOBJ BUFFER MQ-CC MQ-RC
    IF MQ-CC NOT = 0
        DISPLAY "MQPUT FAILED " MQ-RC
    END-IF
    STOP RUN.
CLOSE-QUEUE.
    CALL 'MQCLOSE' USING HCONN HOBJ MQ-CC MQ-RC
    IF MQ-CC NOT = 0
        DISPLAY "MQCLOSE FAILED " MQ-RC
    END-IF.
