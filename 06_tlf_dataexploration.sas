/*
Purpose : Explore ADSL ahead of building the summary tables.
*/


%let HOME=/home/&sysuserid;
libname ADAM "&HOME/sas_adam_project_1";

title "Safety Population by Treatment";
proc freq data=ADAM.ADSL;
    where SAFFL='Y';
    tables TRT01P;
run;
title;

title "Age Summary";
proc means data=ADAM.ADSL n mean std median min max maxdec=1;
    where SAFFL='Y';
    class TRT01P;
    var AGE;
run;
title;

title "Sex Distribution";
proc freq data=ADAM.ADSL;
    where SAFFL='Y';
    tables SEX*TRT01P / missing;
run;
title;

title "Race Distribution";
proc freq data=ADAM.ADSL;
    where SAFFL='Y';
    tables RACE*TRT01P / missing;
run;
title;
