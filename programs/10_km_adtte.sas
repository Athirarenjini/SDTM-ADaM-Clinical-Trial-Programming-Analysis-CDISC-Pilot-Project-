/*
Purpose : Kaplan-Meier analysis of ADTTE (Time to First Dermatologic
          Event), by planned treatment (TRT01P).

Uses:
  AVAL     - analysis time (days), from ADTTE (ADT - STARTDT + 1)
  CNSR     - 0 = event occurred, 1 = censored, from ADTTE
  TRT01P   - planned treatment group, from ADTTE (carried from ADSL)


Analysis Dataset : ADTTE
Population : Safety Population (SAFFL='Y')

*/

%let HOME=/home/&sysuserid;
libname ADAM "&HOME/sas_adam_project_1";

options dlcreatedir;
libname OUT "&HOME/sas_output_project_1";
%let OUTPATH=%sysfunc(pathname(OUT));

ods pdf file="&OUTPATH/KM_Plot_ADTTE.pdf" style=journal;

title1 "Kaplan-Meier Plot";
title2 "Time to First Dermatologic Event by Planned Treatment";

proc lifetest data=ADAM.ADTTE plots=survival(atrisk);
    where SAFFL = "Y";
    time AVAL*CNSR(1);   /* AVAL = analysis time, CNSR=1 means censored */
    strata TRT01P;
run;

footnote1 "Source: ADTTE";
footnote2 "Population: Safety Population (SAFFL='Y')";
footnote3 "CNSR=1 (censored) subjects marked with + on the curve";

ods pdf close;
title;
footnote;
