*> plbtstate.cpy: state shared by every PLBT-* routine in a test run.
01  PLBT-STATE EXTERNAL.
    05  PLBT-SUITE          PIC X(64).
    05  PLBT-CASE-NAME      PIC X(64).
    05  PLBT-TOTAL          PIC 9(9) COMP-5.
    05  PLBT-FAILED         PIC 9(9) COMP-5.
