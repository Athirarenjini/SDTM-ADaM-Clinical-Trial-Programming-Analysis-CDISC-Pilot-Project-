/*
Purpose : Build ADSLand compare it
          against the sponsor reference data.

Population note (refered adsl):
  The reference ADSL only contains the 254 subjects who were actually
  randomized (ARM ne "Screen Failure"); the 52 Screen Failure subjects
  in DM are not in ADSL at all.Here we follow the same logic 




%let HOME=/home/&sysuserid;
libname SDTM "&HOME/sas_sdtm_project_1";
libname REF  "&HOME/sas_reference_adm_project_1";
libname ADAM "&HOME/sas_adam_project_1";


/* 
   1. Population: exclude Screen Failures from DM
*/
data dm_pop;
  set sdtm.dm;
  where arm ne 'Screen Failure' and arm ne '';
run;

/* 
   2. TRTSDT: first (minimum) nonmissing EXSTDTC per subject
*/
proc sql;
  create table trtsdt as
  select usubjid,
         min(input(exstdtc, yymmdd10.)) as trtsdt format=date9.
  from sdtm.ex
  where exstdtc ne ''
  group by usubjid;
quit;

/* 
   3. TRTEDT: identify each subject's LAST dosing interval (max EXSTDTC),
      and check whether that interval's EXENDTC is populated
 */
proc sort data=sdtm.ex out=ex_sorted;
  by usubjid exstdtc;
run;

data ex_last_interval;
  set ex_sorted;
  by usubjid exstdtc;
  if last.usubjid;
  last_int_end = input(exendtc, yymmdd10.);
  format last_int_end date9.;
  keep usubjid last_int_end;
run;

proc sql;
  create table maxexend as
  select usubjid,
         max(input(exendtc, yymmdd10.)) as maxexend format=date9.
  from sdtm.ex
  where exendtc ne ''
  group by usubjid;
quit;

data trtedt_src;
  merge dm_pop(keep=usubjid rfendtc rfstdtc arm)
        trtsdt
        ex_last_interval
        maxexend;
  by usubjid;

  rfendt_n = input(rfendtc, yymmdd10.);
  rfstdt_n = input(rfstdtc, yymmdd10.);

  /* Core rule:
     - If the subject's LAST dosing interval has a populated EXENDTC,
       treatment end = MAX(EXENDTC) across all intervals.
     - If the LAST dosing interval's EXENDTC is missing (never closed
       out before discontinuation), fall back to DM.RFENDTC.           */
  if not missing(last_int_end) then trtedt = maxexend;
  else trtedt = rfendt_n;

  format trtedt rfendt date9.;
  rfendt = rfendt_n;
  rfstdt = rfstdt_n;

  trtdur = trtedt - trtsdt + 1;

  keep usubjid trtsdt trtedt trtdur rfstdt rfendt arm;
run;

/* 
   4. Assemble ADSL
*/
data adam.adsl;
  merge dm_pop(keep=studyid usubjid siteid age sex race arm
               rename=(arm=trt01p))
        trtedt_src(keep=usubjid trtsdt trtedt trtdur rfstdt rfendt arm
                   rename=(arm=trt01a));
  by usubjid;

  length ittfl saffl $1;
  ittfl = 'Y';                                  /* all non-screen-failure subjects */
  if not missing(trtsdt) then saffl = 'Y';       /* received at least one dose */
  else saffl = 'N';

  label studyid = "Study Identifier"
        usubjid = "Unique Subject Identifier"
        siteid  = "Study Site Identifier"
        age     = "Age"
        sex     = "Sex"
        race    = "Race"
        trt01p  = "Planned Treatment for Period 01"
        trt01a  = "Actual Treatment for Period 01"
        rfstdt  = "Reference Start Date"
        rfendt  = "Reference End Date"
        ittfl   = "Intent-To-Treat Population Flag"
        trtsdt  = "Date of First Exposure to Treatment"
        trtedt  = "Date of Last Exposure to Treatment"
        trtdur  = "Duration of Treatment (days)"
        saffl   = "Safety Population Flag";

  format trtsdt trtedt rfstdt rfendt date9.;

  keep studyid usubjid siteid age sex race trt01p trt01a rfstdt rfendt
       ittfl trtsdt trtedt trtdur saffl;
run;

proc sort data=adam.adsl; by usubjid; run;
/*
Quality check*/

proc contents data=ADAM.ADSL varnum;
run;

proc print data=ADAM.ADSL(obs=10);
run;

/* Duplicate subject check - expect 0 */
proc sort data=ADAM.ADSL out=ADSL_NODUP nodupkey dupout=ADSL_DUP;
    by USUBJID;
run;

title "Duplicate Subject Check";
proc sql;
    select count(*) as Duplicate_Records from ADSL_DUP;
quit;
title;

/* Missingness on key variables */
title "ADSL Missing Value Check";
proc sql;
    select
        sum(missing(AGE))    as Missing_AGE,
        sum(missing(SEX))    as Missing_SEX,
        sum(missing(RACE))   as Missing_RACE,
        sum(missing(TRT01P)) as Missing_TRT01P,
        sum(missing(TRT01A)) as Missing_TRT01A,
        sum(missing(TRTSDT)) as Missing_TRTSDT,
        sum(missing(TRTEDT)) as Missing_TRTEDT,
        sum(missing(TRTDUR)) as Missing_TRTDUR,
        sum(missing(SAFFL))  as Missing_SAFFL,
        sum(missing(ITTFL))  as Missing_ITTFL
    from ADAM.ADSL;
quit;
title;

/* Population counts */
proc freq data=ADAM.ADSL;
    tables ITTFL SAFFL TRT01P;
run;

/* Treatment date logic - end before start */
title "Treatment Date Logic (TRTEDT < TRTSDT)";
proc print data=ADAM.ADSL;
    where not missing(TRTSDT) and not missing(TRTEDT) and TRTEDT < TRTSDT;
    var USUBJID TRTSDT TRTEDT TRTDUR;
run;
title;

/* Age range sanity check */
title "Age Range Check (outside 18-120)";
proc print data=ADAM.ADSL;
    where AGE < 18 or AGE > 120;
    var USUBJID AGE;
run;
title;

/*
COMPARE to sponsor reference
*/

proc sort data=REF.ADSL out=ADSL_REF_SORT;
    by USUBJID;
run;

proc sort data=ADAM.ADSL out=ADSL_SORT;
    by USUBJID;
run;

title "Reference ADSL vs Derived ADSL";

proc compare
    base=ADSL_REF_SORT
    compare=ADSL_SORT
    criterion=0.000001
    listall;

    id USUBJID;

    var
        STUDYID
        SITEID
        AGE
        SEX
        RACE
        TRT01P
        TRT01A
        TRTSDT
        TRTEDT
        TRTDUR
        SAFFL
        ITTFL;

run;

title;
