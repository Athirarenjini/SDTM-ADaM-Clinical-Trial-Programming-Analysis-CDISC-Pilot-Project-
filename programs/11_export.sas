/* Export final ADaM datasets for Pinnacle 21 */

%let HOME=/home/&sysuserid;


/* ADSL */
libname ADSLXPT xport
    "&HOME/clinicalsasproject_1/ADSL.xpt";

data ADSLXPT.ADSL;
    set ADAM.ADSL;
run;

libname ADSLXPT clear;


/* ADAE */
libname ADAEXPT xport
    "&HOME/clinicalsasproject_1/ADAE.xpt";

data ADAEXPT.ADAE;
    set ADAM.ADAE;
run;

libname ADAEXPT clear;


/* ADTTE */
libname ADTTEXPT xport
    "&HOME/clinicalsasproject_1/ADTTE.xpt";

data ADTTEXPT.ADTTE;
    set ADAM.ADTTE;
run;

libname ADTTEXPT clear;