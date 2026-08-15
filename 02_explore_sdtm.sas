/*
Purpose : Explore SDTM source data AND run the QC checks (structure,
          duplicates, missingness, ranges) 
*/

%let HOME=/home/&sysuserid;
libname SDTM "&HOME/sas_sdtm_project_1";

/*
STEP 1: SDTM.DM Source Data  ->  required before building ADSL
*/

title "DM Dataset Structure";
proc contents data=SDTM.DM varnum;
run;

title "DM Record Count";
proc sql;
    select count(*) as Subjects
    from SDTM.DM;
quit;

/* Duplicate Subject Check */
proc sort
    data=SDTM.DM
    out=DM_NODUP
    nodupkey
    dupout=DM_DUP;
    by USUBJID;
run;

title "Duplicate Subjects in DM";
proc sql;
    select count(*) as Duplicate_Subjects
    from DM_DUP;
quit;

/* Missing Values */
title "DM Missing Value Assessment";
proc sql;
    select
        sum(missing(AGE))    as Missing_AGE,
        sum(missing(SEX))    as Missing_SEX,
        sum(missing(RACE))   as Missing_RACE,
        sum(missing(ARM))    as Missing_ARM,
        sum(missing(ACTARM)) as Missing_ACTARM
    from SDTM.DM;
quit;

/* Frequency Review */

title "DM Demographic Distribution";
proc freq data=SDTM.DM;
    tables SEX RACE ARM ACTARM / missing;
run;

/* Age Summary */
title "DM Age Summary";
proc means data=SDTM.DM n nmiss mean min max;
    var AGE;
run;

title;


/*
STEP 2: SDTM.EX Source Data  ->  required before ADSL treatment dates
*/

title "EX Dataset Structure";
proc contents data=SDTM.EX varnum;
run;

title "EX Record Count";
proc sql;
    select count(*) as Exposure_Records,
           count(distinct USUBJID) as Subjects
    from SDTM.EX;
quit;

/* Duplicate Exposure Check */
proc sort
    data=SDTM.EX
    out=EX_NODUP
    nodupkey
    dupout=EX_DUP;
    by USUBJID EXSEQ;
run;

title "Duplicate EX Records";
proc sql;
    select count(*) as Duplicate_Records
    from EX_DUP;
quit;

/* Missing Dates */
title "EX Missing Dates";
proc sql;
    select
        sum(missing(EXSTDTC)) as Missing_EXSTDTC,
        sum(missing(EXENDTC)) as Missing_EXENDTC
    from SDTM.EX;
quit;

/* Treatment Distribution */
title "EX Treatment Distribution";
proc freq data=SDTM.EX;
    tables EXTRT / missing;
run;

/* Invalid Date Order - end date before start date */
title "EX Treatment Date Logic (EXENDTC < EXSTDTC)";
proc print data=SDTM.EX;
    where
        not missing(EXSTDTC)
        and not missing(EXENDTC)
        and input(EXENDTC,yymmdd10.) < input(EXSTDTC,yymmdd10.);
    var USUBJID EXSTDTC EXENDTC;
run;

title;


/*
STEP C: SDTM.AE Source Data  ->  required before building ADAE
*/

title "AE Dataset Structure";
proc contents data=SDTM.AE varnum;
run;

title "AE Record Count";
proc sql;
    select count(*) as AE_Records,
           count(distinct USUBJID) as Subjects
    from SDTM.AE;
quit;

/* Duplicate AE Check */
proc sort
    data=SDTM.AE
    out=AE_NODUP
    nodupkey
    dupout=AE_DUP;
    by USUBJID AESEQ;
run;

title "Duplicate AE Records";
proc sql;
    select count(*) as Duplicate_Records
    from AE_DUP;
quit;

/* Partial Date Assessment - drives how ASTDT conversion is written
   (03/04 impute a missing DAY as '01', per the sponsor's own convention
   found in define.xml; month+day both missing is left unimputed) */
title "AE Start Date Completeness (drives ASTDT conversion logic)";
proc sql;
    select
        sum(length(strip(AESTDTC))=10) as Complete_Dates,
        sum(length(strip(AESTDTC))=7)  as YearMonth_Dates,
        sum(length(strip(AESTDTC))=4)  as YearOnly_Dates,
        sum(missing(AESTDTC))          as Missing_Dates
    from SDTM.AE;
quit;

/* Severity / Seriousness / Relationship / Outcome */
title "AE Severity, Seriousness, Relationship, Outcome";
proc freq data=SDTM.AE;
    tables AESEV AESER AEREL AEOUT / missing;
run;

/* AEDECOD / AEBODSYS distribution - drives the dermatologic event flag
   used later in ADTTE (CQ01NAM) */
title "AE Preferred Term and Body System";
proc freq data=SDTM.AE;
    tables AEBODSYS / missing;
run;

title;

