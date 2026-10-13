*> plbjcl.cpy: the jobs, steps, and data definitions of JCL files.
*>
*> PLB-JCL-READ appends one JCL file at a time, so that a run can
*> hold the JCL of a whole application next to its programs. Names
*> (job, step, program, procedure, DD) are kept in upper case, as JCL
*> writes them.
*>
*> A step runs a program (EXEC PGM=) or a procedure (EXEC PROC= or
*> EXEC name). Procedures are defined in a JCL file of their own, or
*> in-stream between PROC and PEND; their steps have JS-PROC set. A DD
*> written as STEP.DDNAME in a job overrides or adds to step STEP of
*> the procedure the job step runs: JD-QUALIFIER holds STEP.
*>
*> The limits are in plbjclc.cpy, which a program copies once.
01  PLB-JCL.
    05  JJ-COUNT                PIC 9(9) COMP-5.
    05  JJ-ENTRY                OCCURS JJ-MAX TIMES.
        10  JJ-NAME             PIC X(8).
        10  JJ-FILE-ID          PIC 9(4) COMP-5.
        10  JJ-LINE             PIC 9(9) COMP-5.
        *> A TIME= value the z/OS MVS JCL Reference does not allow
        *> (minutes above 357912, seconds above 59, not a number, or 0
        *> on a JOB statement), as written; spaces when there is none.
        10  JJ-TIME-BAD         PIC X(20).
        *> A REGION= value it does not allow (not valueK from 0 through
        *> 2096128 or valueM from 0 through 2047), as written; spaces
        *> when there is none.
        10  JJ-REGION-BAD       PIC X(20).
        *> A MSGLEVEL= value it does not allow (statements other than
        *> 0, 1, or 2, or messages other than 0 or 1), as written.
        10  JJ-MSGLEVEL-BAD     PIC X(20).
        *> A CLASS= or MSGCLASS= value it does not allow, as written,
        *> with its keyword in JJ-CLASS-KEY.
        10  JJ-CLASS-BAD        PIC X(20).
        10  JJ-CLASS-KEY        PIC X(8).
        *> The COND operand of the JOB statement, in upper case, or
        *> spaces.
        10  JJ-COND             PIC X(80).
        *> The first of ADDRSPC=, RD=, and MEMLIMIT= whose value the JCL
        *> Reference does not list: the keyword and the value.
        10  JJ-VALUE-KEY        PIC X(8).
        10  JJ-VALUE-BAD        PIC X(20).
        *> A JOBLIB DD after another DD before the first EXEC: that DD's
        *> name, and the JOBLIB's line; spaces and 0 when there is none.
        10  JJ-JOBLIB-AFTER     PIC X(8).
        10  JJ-JOBLIB-LINE      PIC 9(9) COMP-5.
    *> Procedure definitions: PROC statements.
    05  JP-COUNT                PIC 9(9) COMP-5.
    05  JP-ENTRY                OCCURS JP-MAX TIMES.
        10  JP-NAME             PIC X(8).
        10  JP-FILE-ID          PIC 9(4) COMP-5.
        10  JP-LINE             PIC 9(9) COMP-5.
        *> "Y" between PROC and PEND in a job; JP-JOB is that job.
        10  JP-INSTREAM         PIC X.
        10  JP-JOB              PIC 9(9) COMP-5.
    05  JS-COUNT                PIC 9(9) COMP-5.
    05  JS-ENTRY                OCCURS JS-MAX TIMES.
        *> The job, or the procedure, the step is in (0: none).
        10  JS-JOB              PIC 9(9) COMP-5.
        10  JS-PROC             PIC 9(9) COMP-5.
        10  JS-NAME             PIC X(8).
        *>   P runs a program   R runs a procedure
        10  JS-KIND             PIC X.
        *> The program or procedure, as named.
        10  JS-TARGET           PIC X(8).
        *> For a step whose program starts another one: the program it
        *> runs. IMS's DFSRRC00 names it in PARM='BMP,name,...'; the
        *> TSO batch program IKJEFT01 runs DB2 programs named in RUN
        *> PROGRAM(name) in its SYSTSIN input.
        10  JS-INNER            PIC X(8).
        *> For DFSRRC00, the PSB it schedules (PARM='BMP,name,PSB').
        10  JS-PSB              PIC X(8).
        *> The COND operand, in upper case: (4,LT), ((8,LE,EXTRACT),
        *> EVEN), ...
        10  JS-COND             PIC X(80).
        *> The number of characters PARM= passes the program: without
        *> the apostrophes or parentheses that enclose it, a doubled
        *> apostrophe counted once. 0 when there is no PARM, or it has
        *> a symbol (&).
        10  JS-PARM-LEN         PIC 9(9) COMP-5.
        *> The same as JJ-TIME-BAD, for TIME= of the EXEC statement.
        10  JS-TIME-BAD         PIC X(20).
        10  JS-REGION-BAD       PIC X(20).
        10  JS-VALUE-KEY        PIC X(8).
        10  JS-VALUE-BAD        PIC X(20).
        10  JS-FILE-ID          PIC 9(4) COMP-5.
        10  JS-LINE             PIC 9(9) COMP-5.
        *> The step's DD statements: JS-DD-COUNT entries from
        *> JS-DD-FIRST.
        10  JS-DD-FIRST         PIC 9(9) COMP-5.
        10  JS-DD-COUNT         PIC 9(9) COMP-5.
    05  JD-COUNT                PIC 9(9) COMP-5.
    05  JD-ENTRY                OCCURS JD-MAX TIMES.
        10  JD-STEP             PIC 9(9) COMP-5.
        10  JD-NAME             PIC X(8).
        *> STEP of a STEP.DDNAME override, or spaces.
        10  JD-QUALIFIER        PIC X(8).
        *> What the DD gives the program:
        *>   D a data set (JD-DSN)   S SYSOUT   M DUMMY
        *>   I in-stream data (* or DATA)   O something else
        10  JD-KIND             PIC X.
        10  JD-DSN              PIC X(44).
        *> The first DISP subparameter (NEW, OLD, SHR, MOD), or spaces;
        *> the second, the normal disposition (CATLG, KEEP, DELETE,
        *> PASS, UNCATLG), or spaces.
        10  JD-DISP             PIC X(3).
        10  JD-NORMAL           PIC X(7).
        *> "Y" for a DD without a name, which concatenates its data
        *> set to the DD before it; it has that DD's name.
        10  JD-CONCAT           PIC X.
        *> LRECL, BLKSIZE, and RECFM, given as keywords or in DCB=( ):
        *> 0 and spaces when the DD gives none (or a symbol).
        10  JD-LRECL            PIC 9(9) COMP-5.
        10  JD-BLKSIZE          PIC 9(9) COMP-5.
        10  JD-RECFM            PIC X(4).
        *> What is wrong with the name in DSN=, as z/OS forms data set
        *> names: space when nothing is (or the name is a temporary
        *> data set, a backward reference, or holds a symbol); L longer
        *> than 44 characters (JD-DSN-AT: its length); E an empty
        *> qualifier; Q a qualifier longer than 8 characters; F one that
        *> does not start with a letter or national character; C one
        *> with another character (JD-DSN-AT: the qualifier's number,
        *> from 1, for E, Q, F, and C). For a relative generation in
        *> parentheses: G one above 255, H one that is not +, -, or 0
        *> and digits, 1 to 3 of them after a sign (JD-DSN-GEN: what is
        *> in the parentheses).
        10  JD-DSN-PROBLEM      PIC X.
        10  JD-DSN-AT           PIC 9(4) COMP-5.
        10  JD-DSN-GEN          PIC X(10).
        *> "Y" when the DD codes SYSOUT=. JD-SYSOUT-CLASH: the first
        *> keyword it codes that the JCL Reference says not to code with
        *> SYSOUT (DISP, VOLUME, LABEL, ...), when it codes SYSOUT, or
        *> the first that it says to code only with SYSOUT (DEST, HOLD,
        *> OUTLIM), when it does not; spaces when there is none.
        10  JD-SYSOUT           PIC X.
        10  JD-SYSOUT-CLASH     PIC X(8).
        *> "Y" when SYSOUT= names the internal reader, (class,INTRDR).
        10  JD-INTRDR           PIC X.
        *> OUTPUT= as written: *.name, or a list of them; spaces when
        *> the DD has none.
        10  JD-OUTPUT           PIC X(60).
        *> "Y" when the DD codes DLM=.
        10  JD-DLM              PIC X.
        *> "Y" when LRECL is coded as a number (JD-LRECL, 0 included),
        *> and when the DD codes RECORG= (a VSAM data set).
        10  JD-LRECL-CODED      PIC X.
        10  JD-RECORG           PIC X.
        *> KEYLEN, as a keyword or in DCB=( ), when coded as a number
        *> (JD-KEYLEN-CODED "Y"), and whether RECORG is KS.
        10  JD-KEYLEN           PIC 9(9) COMP-5.
        10  JD-KEYLEN-CODED     PIC X.
        10  JD-RECORG-KS        PIC X.
        *> What is wrong with EXPDT= or RETPD=: E an EXPDT that is not
        *> yyddd or yyyy/ddd of a real day, R a RETPD that is not 0
        *> through 93000, B both coded, T either on a temporary data set;
        *> space when nothing is. JD-RETAIN-VALUE: the value, as written.
        10  JD-RETAIN-PROBLEM   PIC X.
        10  JD-RETAIN-VALUE     PIC X(20).
        *> The first part of SPACE= that the JCL Reference does not
        *> allow, as written (a unit other than TRK, CYL, ABSTR, or a
        *> length of 0 to 65535; a quantity above 16777215 or not a
        *> number; an option other than RLSE, CONTIG, MXIG, ALX, ROUND),
        *> with JD-SPACE-PART: U unit, Q quantity, O option.
        10  JD-SPACE-BAD        PIC X(20).
        10  JD-SPACE-PART       PIC X.
        *> The first DISP= subparameter the JCL Reference does not
        *> allow, as written, and which it is: S status, N normal, A
        *> abnormal termination disposition, X a fourth.
        10  JD-DISP-BAD         PIC X(20).
        10  JD-DISP-PART        PIC X.
        *> The first of HOLD=, FREE=, SPIN=, AVGREC=, and RECORG= whose
        *> value is not one the JCL Reference lists: the keyword, and
        *> the value as written.
        10  JD-VALUE-KEY        PIC X(8).
        10  JD-VALUE-BAD        PIC X(20).
        *> A RECFM, as a keyword or in DCB=( ), that is none of the
        *> formats the JCL Reference lists, as written; spaces when
        *> there is none.
        10  JD-RECFM-BAD        PIC X(10).
        *> Two parameters of the DD that the JCL Reference says not to
        *> code together, the first pair found; spaces when there is
        *> none.
        *> UNIT=AFF=ddname: the ddname, or spaces. JD-AFF-WITH: S the DD
        *> codes STORCLAS, U SUBSYS, I it is in-stream data. JD-FREE-CLOSE:
        *> "Y" when the DD codes FREE=CLOSE.
        *> The first VOL=SER serial the JCL Reference does not allow,
        *> and why: L not 1 to 6 characters, R a name the system uses
        *> (SCRTCH, PRIVAT, MIGRAT, Lnnnnn), D named twice.
        10  JD-VOLSER-BAD       PIC X(20).
        10  JD-VOLSER-WHY       PIC X.
        10  JD-UNIT-AFF         PIC X(8).
        10  JD-AFF-WITH         PIC X.
        10  JD-FREE-CLOSE       PIC X.
        10  JD-CONFLICT-1       PIC X(24).
        10  JD-CONFLICT-2       PIC X(30).
        *> The class of SYSOUT= when the JCL Reference does not allow it
        *> (not one character, A through Z or 0 through 9, or *).
        10  JD-CLASS-BAD        PIC X(10).
        10  JD-FILE-ID          PIC 9(4) COMP-5.
        10  JD-LINE             PIC 9(9) COMP-5.
    *> The steps that IF statements test (IF STEP.RC > 4 THEN, ...):
    *> one entry for each name, with the job or procedure the IF is in
    *> and the number of steps read before it.
    *> Backward references of DD statements, *.DD, *.STEP.DD, or
    *> *.STEP.PROCSTEP.DD in DSN=, DCB=, VOL=REF=, and REFDD=: the DD,
    *> the keyword, the reference without its "*.", and what it
    *> resolved to: Y a DD before it (or, through a procedure step, a
    *> step), S no such step before it, D no such DD in the step.
    *> A DSN= that resolves takes the data set name of the DD it names.
    05  JR-COUNT                PIC 9(9) COMP-5.
    05  JR-ENTRY                OCCURS JR-MAX TIMES.
        10  JR-DD               PIC 9(9) COMP-5.
        10  JR-KEY              PIC X(5).
        10  JR-TEXT             PIC X(26).
        10  JR-STATE            PIC X.
    05  JI-COUNT                PIC 9(9) COMP-5.
    05  JI-ENTRY                OCCURS JI-MAX TIMES.
        10  JI-JOB              PIC 9(9) COMP-5.
        10  JI-PROC             PIC 9(9) COMP-5.
        10  JI-BEFORE           PIC 9(9) COMP-5.
        10  JI-STEP             PIC X(8).
        10  JI-FILE-ID          PIC 9(4) COMP-5.
        10  JI-LINE             PIC 9(9) COMP-5.
    *> Statements whose name z/OS does not accept: 1 to 8 letters,
    *> digits, or national characters ($ # @), the first not a digit,
    *> in each part of a STEP.DDNAME. JN-NAME is the name as written
    *> (its first 17 characters), JN-LEN its length, JN-PART the part
    *> that is wrong (1 or 2), and JN-PROBLEM what is wrong with it: L
    *> longer than 8 characters, F a first character that is not a
    *> letter or national character, C another character, E empty.
    *> Names with a symbol (&) are not checked. JN-KIND says which name
    *> it is: N the name field, P the program of EXEC PGM=, R the
    *> procedure of EXEC PROC= (or EXEC name); these two have no dot.
    05  JN-COUNT                PIC 9(9) COMP-5.
    05  JN-ENTRY                OCCURS JN-MAX TIMES.
        10  JN-KIND             PIC X.
        10  JN-NAME             PIC X(17).
        10  JN-LEN              PIC 9(9) COMP-5.
        10  JN-PART             PIC 9(4) COMP-5.
        10  JN-PROBLEM          PIC X.
        10  JN-FILE-ID          PIC 9(4) COMP-5.
        10  JN-LINE             PIC 9(9) COMP-5.
    *> OUTPUT JCL statements: the name, the job or procedure, and the
    *> step they follow (0: before the first EXEC).
    05  JO-COUNT                PIC 9(9) COMP-5.
    05  JO-ENTRY                OCCURS JO-MAX TIMES.
        10  JO-NAME             PIC X(8).
        10  JO-JOB              PIC 9(9) COMP-5.
        10  JO-PROC             PIC 9(9) COMP-5.
        10  JO-STEP             PIC 9(9) COMP-5.
        10  JO-FILE-ID          PIC 9(4) COMP-5.
        10  JO-LINE             PIC 9(9) COMP-5.
    *> JCLLIB statements out of their place: A after the job's first
    *> EXEC, T a second of the job, P in a procedure.
    05  JL-COUNT                PIC 9(9) COMP-5.
    05  JL-ENTRY                OCCURS JL-MAX TIMES.
        10  JL-PROBLEM          PIC X.
        10  JL-FILE-ID          PIC 9(4) COMP-5.
        10  JL-LINE             PIC 9(9) COMP-5.
