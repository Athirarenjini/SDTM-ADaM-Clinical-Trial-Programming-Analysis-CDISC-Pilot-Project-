/*
Purpose : Build ADTTE (Time to First Dermatologic Event) and compare
          it against the CDISC Pilot Project reference ADaM datasets

Derivation rules below are taken directly from the project's define.xml
(ItemDef comments for ADTTE):
  PARAM/PARAMCD : "Time to First Dermatologic Event" / "TTDE"
  STARTDT       : ADSL.RFSTDTC (reference start date)
  ADT           : if ADAE.ASTDT is not missing and occurred after
                  TRTSDT (i.e. AOCC01FL='Y' on ADAE) then that event's
                  ASTDT, else ADSL.RFENDTC
  CNSR          : 0 if the event occurred, else 1
  AVAL          : ADT - STARTDT + 1
  EVNTDESC      : sponsor's exact text is reproduced here (including its
                  original spelling "Dematologic Event Occured") so
                  PROC COMPARE matches the reference exactly
  SRCDOM/SRCVAR : ADAE/ASTDT if event occurred, else ADSL/RFENDT
  SRCSEQ        : ADAE.AESEQ if SRCDOM=ADAE, else missing
  SAFFL         : ADSL.SAFFL (define.xml: ADTTE.SAFFL <- ADSL.SAFFL)


%let HOME=/home/&sysuserid;
libname REF  "&HOME/sas_reference_adm_project_1";
libname ADAM "&HOME/sas_adam_project_1";



/* first treatment-emergent dermatologic event per subject, (already
   flagged in 04_build_adae.sas )*/

data FIRST_DERM_EVENT;
    set ADAM.ADAE;
    where AOCC01FL = "Y";
    keep USUBJID ASTDT AESEQ;
run;

proc sort data=ADAM.ADSL out=ADSL_SORT;
    by USUBJID;
run;

proc sort data=FIRST_DERM_EVENT;
    by USUBJID;
run;

data ADAM.ADTTE;

    merge
        ADSL_SORT       (in=a)
        FIRST_DERM_EVENT(in=b);

    by USUBJID;

    if a;   /* keep every ITT subject, event or not */

    length PARAM $100 PARAMCD $8 EVNTDESC $30 SRCDOM $4 SRCVAR $8;

    format STARTDT ADT date9.;

    PARAM   = "Time to First Dermatologic Event";
    PARAMCD = "TTDE";

    STARTDT = RFSTDT;

    if b then do;               /* event occurred */
        ADT      = ASTDT;
        CNSR     = 0;
        EVNTDESC = "Dematologic Event Occured";   /* sponsor's exact text from define .xml */
        SRCDOM   = "ADAE";
        SRCVAR   = "ASTDT";
        SRCSEQ   = AESEQ;
    end;
    else do;                    /* censored at reference end date */
        ADT      = RFENDT;
        CNSR     = 1;
        EVNTDESC = "Study Completion Date";
        SRCDOM   = "ADSL";
        SRCVAR   = "RFENDT";
        call missing(SRCSEQ);
    end;

    if not missing(ADT) and not missing(STARTDT) then
        AVAL = ADT - STARTDT + 1;

    label
        PARAM    = "Parameter"
        PARAMCD  = "Parameter Code"
        STARTDT  = "Time to Event Origin Date for Subject"
        ADT      = "Analysis Date"
        CNSR     = "Censor"
        AVAL     = "Analysis Value"
        EVNTDESC = "Event or Censoring Description"
        SRCDOM   = "Source Domain"
        SRCVAR   = "Source Variable"
        SRCSEQ   = "Source Sequence Number"
        SAFFL    = "Safety Population Flag";

    drop ASTDT AESEQ;

run;

/*
Quality check
*/

proc contents data=ADAM.ADTTE varnum;
run;

proc print data=ADAM.ADTTE(obs=20);
    var USUBJID STARTDT ADT AVAL CNSR EVNTDESC SRCDOM SRCVAR SRCSEQ SAFFL;
run;

/* Duplicate subject check  */
proc sort data=ADAM.ADTTE out=ADTTE_NODUP nodupkey dupout=ADTTE_DUP;
    by USUBJID;
run;

title "Duplicate Subject Check";
proc sql;
    select count(*) as Duplicate_Subjects from ADTTE_DUP;
quit;
title;

/* Missingness */
title "ADTTE Missing Value Check";
proc sql;
    select
        sum(missing(STARTDT)) as Missing_STARTDT,
        sum(missing(ADT))     as Missing_ADT,
        sum(missing(AVAL))    as Missing_AVAL,
        sum(missing(CNSR))    as Missing_CNSR
    from ADAM.ADTTE;
quit;
title;

/* Censoring distribution */
proc freq data=ADAM.ADTTE;
    tables CNSR EVNTDESC SRCDOM SAFFL;
run;

proc means data=ADAM.ADTTE n nmiss min max mean;
    var AVAL;
run;

/* Logic check - event date before origin date */
title "Time-to-Event Date Logic (ADT < STARTDT)";
proc print data=ADAM.ADTTE;
    where not missing(ADT) and ADT < STARTDT;
    var USUBJID STARTDT ADT AVAL;
run;
title;

/* Logic check - negative analysis time */
title "Negative AVAL Check";
proc print data=ADAM.ADTTE;
    where not missing(AVAL) and AVAL < 0;
    var USUBJID STARTDT ADT AVAL;
run;
title;

/* Cross-check: number of CNSR=0 in ADTTE should equal number of
   AOCC01FL='Y' in ADAE */
  
proc sql noprint;
    select count(*) into :adtte_events
        from ADAM.ADTTE where CNSR=0;
    select count(*) into :adae_flags
        from ADAM.ADAE where AOCC01FL="Y";
quit;

title "Cross-check ADTTE events vs ADAE AOCC01FL count";
data _null_;
    ADTTE_Events     = &adtte_events;
    ADAE_First_Flags = &adae_flags;
    put ADTTE_Events= ADAE_First_Flags=;
run;
title;

/*
COMPARE to CDISC Pilot Project reference ADaM datasets
*/

proc sort data=REF.ADTTE out=ADTTE_REF_SORT;
    by USUBJID PARAMCD;
run;

proc sort data=ADAM.ADTTE out=ADTTE_DEV_SORT;
    by USUBJID PARAMCD;
run;

title "Reference ADTTE vs Derived ADTTE";

proc compare
    base=ADTTE_REF_SORT
    compare=ADTTE_DEV_SORT
    criterion=0.000001
    listall;

    id USUBJID PARAMCD;

    var
        STARTDT
        ADT
        AVAL
        CNSR
        EVNTDESC
        SRCDOM
        SRCVAR
        SAFFL;

run;

title;

