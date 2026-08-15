/*

 Purpose : Assign project libraries and import SDTM + reference ADaM
           files, one domain at a time.
*/

%let HOME=/home/&sysuserid;
options dlcreatedir;

/* Assign project libraries.
   SDTM =  raw SDTM datasets (dm, ae, ex, ds, suppae)
   REF  = the SPONSOR'S reference ADaM datasets (adsl, adae, adtte) -
          kept in a SEPARATE library 
   ADAM = derived ADaM datasets */

libname SDTM "&HOME/sas_sdtm_project_1";
libname REF  "&HOME/sas_reference_adm_project_1";
libname ADAM "&HOME/sas_adam_project_1";

/* check that the libraries are assigned correctly */
libname SDTM list;
libname REF list;
libname ADAM list;


/*
 Import SDTM domains
*/

/* Import DM */

libname DMXPT xport "&HOME/sas_sdtm_project_1/dm.xpt";

proc copy in=DMXPT out=SDTM;
run;

libname DMXPT clear;


/* Import AE */

libname AEXPT xport "&HOME/sas_sdtm_project_1/ae.xpt";

proc copy in=AEXPT out=SDTM;
run;

libname AEXPT clear;


/* Import EX */

libname EXXPT xport "&HOME/sas_sdtm_project_1/ex.xpt";

proc copy in=EXXPT out=SDTM;
run;

libname EXXPT clear;


/* Import DS */

libname DSXPT xport "&HOME/sas_sdtm_project_1/ds.xpt";

proc copy in=DSXPT out=SDTM;
run;

libname DSXPT clear;


/* Import SUPPAE */

libname SUPXPT xport "&HOME/sas_sdtm_project_1/suppae.xpt";

proc copy in=SUPXPT out=SDTM;
run;

libname SUPXPT clear;


/* check all SDTM datasets came in */
proc datasets library=SDTM;
quit;


/*
 Import sponsor REFERENCE ADaM datasets
*/

/* Import ADSL reference */

libname ADSLXPT xport "&HOME/sas_reference_adm_project_1/adsl.xpt";

proc copy in=ADSLXPT out=REF;
run;

libname ADSLXPT clear;


/* Import ADAE reference */

libname ADAEXPT xport "&HOME/sas_reference_adm_project_1/adae.xpt";

proc copy in=ADAEXPT out=REF;
run;

libname ADAEXPT clear;


/* Import ADTTE reference */

libname ADTTEXPT xport "&HOME/sas_reference_adm_project_1/adtte.xpt";

proc copy in=ADTTEXPT out=REF;
run;

libname ADTTEXPT clear;


/* check all reference ADaM datasets */
proc datasets library=REF;
quit;
