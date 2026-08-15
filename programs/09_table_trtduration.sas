
/*

Table 3 : Treatment Duration Summary
Analysis Dataset : ADSL
*/

%let HOME=/home/&sysuserid;
libname ADAM "&HOME/sas_adam_project_1";

options dlcreatedir;
libname OUT "&HOME/sas_output_project_1";
%let OUTPATH=%sysfunc(pathname(OUT));

proc means data=ADAM.ADSL noprint;
    where SAFFL='Y';
    class TRT01P;
    var TRTDUR;
    output out=TRTDUR_SUMMARY(drop=_TYPE_ _FREQ_)
        n=Subjects mean=Mean std=StdDev median=Median min=Minimum max=Maximum;
run;

ods pdf file="&OUTPATH/Table3_Treatment_Duration.pdf" style=journal;

title1 "Table 3";
title2 "Treatment Duration Summary";

proc report data=TRTDUR_SUMMARY nowd;
    where TRT01P ne "";
    columns TRT01P Subjects Mean StdDev Median Minimum Maximum;
    define TRT01P   / display "Treatment";
    define Subjects / display "N";
    define Mean     / display format=6.1 "Mean";
    define StdDev   / display format=6.1 "Std Dev";
    define Median   / display format=6.1 "Median";
    define Minimum  / display format=6.1 "Minimum";
    define Maximum  / display format=6.1 "Maximum";
run;

footnote1 "Source: ADSL";
footnote2 "Population: Safety Population (SAFFL='Y')";

ods pdf close;
title;
footnote;
