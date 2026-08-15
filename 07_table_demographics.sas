/*
Table 1 : Demographic Summary by Planned Treatment
Analysis Dataset : ADSL
Population : Safety Population (SAFFL='Y')
*/


%let HOME=/home/&sysuserid;
libname ADAM "&HOME/sas_adam_project_1";

  
options dlcreatedir;
libname OUT "&HOME/sas_output_project_1";
%let OUTPATH=%sysfunc(pathname(OUT));

proc means data=ADAM.ADSL noprint;
    where SAFFL='Y';
    class TRT01P;
    var AGE;
    output out=AGE_SUMMARY(drop=_TYPE_ _FREQ_)
        n=Subjects mean=Mean std=StdDev median=Median min=Minimum max=Maximum;
run;

proc freq data=ADAM.ADSL noprint;
    where SAFFL='Y';
    tables TRT01P*SEX / out=SEX_SUMMARY outpct;
run;

proc freq data=ADAM.ADSL noprint;
    where SAFFL='Y';
    tables TRT01P*RACE / out=RACE_SUMMARY outpct;
run;

ods pdf file="&OUTPATH/Table1_Demographics.pdf" style=journal;

title1 "Table 1";
title2 "Demographic Summary by Planned Treatment";

title3 "Age Summary";
proc report data=AGE_SUMMARY nowd;
    where TRT01P ne "";
    columns TRT01P Subjects Mean StdDev Median Minimum Maximum;
    define TRT01P   / display "Treatment";
    define Subjects / display "N";
    define Mean     / display format=6.1;
    define StdDev   / display format=6.1;
    define Median   / display format=6.1;
    define Minimum  / display format=6.1;
    define Maximum  / display format=6.1;
run;

title3 "Sex Distribution";
proc report data=SEX_SUMMARY nowd;
    columns TRT01P SEX COUNT PCT_ROW;
    define TRT01P / group "Treatment";
    define SEX    / group "Sex";
    define COUNT  / display "Count";
    define PCT_ROW/ display format=6.1 "Percent";
run;

title3 "Race Distribution";
proc report data=RACE_SUMMARY nowd;
    columns TRT01P RACE COUNT PCT_ROW;
    define TRT01P / group "Treatment";
    define RACE   / group "Race";
    define COUNT  / display "Count";
    define PCT_ROW/ display format=6.1 "Percent";
run;

footnote1 "Source: ADSL";
footnote2 "Population: Safety Population (SAFFL='Y')";

ods pdf close;
title;
footnote;

/* qaulity check: summary datasets */
proc print data=AGE_SUMMARY;  run;
proc print data=SEX_SUMMARY;  run;
proc print data=RACE_SUMMARY; run;

