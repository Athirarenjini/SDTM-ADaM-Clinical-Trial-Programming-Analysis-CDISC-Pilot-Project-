/*
Table 2 : Subjects with >=1 Treatment-Emergent Adverse Event
Analysis Dataset : ADAE (counts SUBJECTS) */


%let HOME=/home/&sysuserid;
libname ADAM "&HOME/sas_adam_project_1";

options dlcreatedir;
libname OUT "&HOME/sas_output_project_1";
%let OUTPATH=%sysfunc(pathname(OUT));

proc sort data=ADAM.ADAE out=TEAE_SUBJECTS nodupkey;
    where TRTEMFL='Y';
    by USUBJID TRT01P;
run;

proc freq data=TEAE_SUBJECTS noprint;
    tables TRT01P / out=TEAE_SUMMARY;
run;

proc freq data=ADAM.ADSL noprint;
    where SAFFL='Y';
    tables TRT01P / out=SAFETY_N(rename=(COUNT=N_SAFETY));
run;

proc sort data=TEAE_SUMMARY;  by TRT01P; run;
proc sort data=SAFETY_N;      by TRT01P; run;

data TEAE_SUMMARY;
    merge TEAE_SUMMARY(in=a) SAFETY_N(keep=TRT01P N_SAFETY);
    by TRT01P;
    if a;
    if N_SAFETY > 0 then PERCENT = 100 * COUNT / N_SAFETY;
run;

ods pdf file="&OUTPATH/Table2_TEAE_Summary.pdf" style=journal;

title1 "Table 2";
title2 "Subjects with >=1 Treatment-Emergent Adverse Event";

proc report data=TEAE_SUMMARY nowd;
    columns TRT01P COUNT N_SAFETY PERCENT;
    define TRT01P  / display "Treatment";
    define COUNT   / display "Subjects with >=1 TEAE";
    define N_SAFETY/ display "Safety Population N";
    define PERCENT / display format=6.1 "Percent";
run;

footnote1 "Source: ADAE, ADSL";
footnote2 "Population: Safety Population (SAFFL='Y'); TEAE = TRTEMFL='Y'";

ods pdf close;
title;
footnote;

proc print data=TEAE_SUMMARY noobs; run;

