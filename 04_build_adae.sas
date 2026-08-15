/*Purpose: Built ADAE(Adverse Events Analysis Dataset) and compare it
          against the sponsor reference data.

Derivation rules (from define.xml ItemDef comments for ADAE):
  ASTDT   : AESTDTC converted to a SAS date.
              - length 10 ("YYYY-MM-DD")           -> full date, no imputation
              - length 7  ("YYYY-MM", day missing)  -> impute day = 01
              - length 4  ("YYYY", month+day missing)-> leave ASTDT missing
  AENDT   : AEENDTC converted the same way, but with NO imputation --
            partial end dates are left missing (no rule specifies otherwise).
  TRTEMFL : "Y" if ASTDT >= TRTSDT (and both non-missing), else "N".
  ASTDY/AENDY : day relative to TRTSDT, +1 if on/after TRTSDT.
  CQ01NAM : "DERMATOLOGIC EVENTS" if AEDECOD contains APPLICATION,
            DERMATITIS, ERYTHEMA, or BLISTER, OR AEBODSYS = "SKIN AND
            SUBCUTANEOUS TISSUE DISORDERS" and AEDECOD not in
            (COLD SWEAT, HYPERHIDROSIS, ALOPECIA). Otherwise missing.
  AOCC01FL: Subset to CQ01NAM='DERMATOLOGIC EVENTS' and TRTEMFL='Y', sort
            by USUBJID/ASTDT/AESEQ, flag the FIRST record within each
            subject -- within that subset
*/

%let HOME=/home/&sysuserid;
libname SDTM "&HOME/sas_sdtm_project_1";
libname REF  "&HOME/sas_reference_adm_project_1";
libname ADAM "&HOME/sas_adam_project_1";

/* 
   1. Convert AE dates (partial-date safe), merge subject-level info
 */
data ae_dates;
  set sdtm.ae;

  length _stlen _enlen 8;
  _stlen = length(strip(aestdtc));
  _enlen = length(strip(aeendtc));

  /* ASTDT: impute day=01 for YYYY-MM; leave missing for YYYY or blank */
  if missing(aestdtc) then astdt = .;
  else if _stlen = 10 then astdt = input(aestdtc, yymmdd10.);
  else if _stlen = 7  then astdt = input(cats(aestdtc, '-01'), yymmdd10.);
  else astdt = .;

  /* AENDT: full dates only, no imputation for partial end dates */
  if missing(aeendtc) then aendt = .;
  else if _enlen = 10 then aendt = input(aeendtc, yymmdd10.);
  else aendt = .;

  format astdt aendt date9.;
  drop _stlen _enlen;
run;

proc sql;
  create table adae0 as
  select a.studyid, a.usubjid, a.aeseq, a.aeterm, a.aedecod, a.aebodsys,
         a.aesev, a.aeser, a.aerel, a.aeout, a.aestdtc, a.aeendtc,
         a.astdt, a.aendt,
         b.trt01p, b.trt01a, b.ittfl, b.trtsdt, b.trtedt, b.saffl
  from ae_dates as a
  inner join adam.adsl as b
  on a.usubjid = b.usubjid;
quit;

/*
   2. Derive analysis day, treatment-emergent flag, dermatologic query
 */
data adam.adae;
  set adae0;

  /* Analysis relative day: no day 0, day 1 = TRTSDT */
  if not missing(astdt) then do;
    if astdt >= trtsdt then astdy = astdt - trtsdt + 1;
    else astdy = astdt - trtsdt;
  end;
  if not missing(aendt) then do;
    if aendt >= trtsdt then aendy = aendt - trtsdt + 1;
    else aendy = aendt - trtsdt;
  end;

  /* Treatment-emergent: ASTDT >= TRTSDT (per define.xml comment).
     No upper bound at TRTEDT -- events with onset after the recorded
     TRTEDT are still flagged treatment-emergent under this rule. */
length trtemfl $1;
if not missing(astdt) and not missing(trtsdt) and astdt >= trtsdt then trtemfl = 'Y';
else trtemfl = 'N';

  /* Customized Query 01: Dermatologic Events */
  length cq01nam $19;
  if index(aedecod,'APPLICATION') > 0
     or index(aedecod,'DERMATITIS') > 0
     or index(aedecod,'ERYTHEMA')   > 0
     or index(aedecod,'BLISTER')    > 0
     or (aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
         and aedecod not in ('COLD SWEAT','HYPERHIDROSIS','ALOPECIA'))
  then cq01nam = 'DERMATOLOGIC EVENTS';
  else cq01nam = '';

  label studyid = "Study Identifier"
        usubjid = "Unique Subject Identifier"
        aeseq   = "Sequence Number"
        aeterm  = "Reported Term for the Adverse Event"
        aedecod = "Dictionary-Derived Term"
        aebodsys= "Body System or Organ Class"
        aesev   = "Severity/Intensity"
        aeser   = "Serious Event"
        aerel   = "Causality"
        aeout   = "Outcome of Adverse Event"
        aestdtc = "Start Date/Time of Adverse Event"
        aeendtc = "End Date/Time of Adverse Event"
        trt01p  = "Planned Treatment for Period 01"
        trt01a  = "Actual Treatment for Period 01"
        ittfl   = "Intent-To-Treat Population Flag"
        trtsdt  = "Date of First Exposure to Treatment"
        trtedt  = "Date of Last Exposure to Treatment"
        saffl   = "Safety Population Flag"
        trtemfl = "Treatment Emergent Analysis Flag"
        cq01nam = "Customized Query 01 Name"
        astdt   = "Analysis Start Date"
        aendt   = "Analysis End Date"
        astdy   = "Analysis Start Relative Day"
        aendy   = "Analysis End Relative Day";

  format trtsdt trtedt astdt aendt date9.;
run;

/* 
   3. First-occurrence flag for the dermatologic query (AOCC01FL)
      Subset to CQ01NAM='DERMATOLOGIC EVENTS' AND TRTEMFL='Y' FIRST,
      then flag first.USUBJID within that subset only.
 */

/* ADAM.ADAE must be explicitly sorted by the BY variables used in the
   final merge below -- SDTM.AE's row order is not guaranteed to already
   be USUBJID/AESEQ,so skipping this causes a mid-step BY-sort error
   and a silently truncated output dataset. */
proc sort data=adam.adae; by usubjid aeseq; run;

data adae_derm;
  set adam.adae;
  where cq01nam = 'DERMATOLOGIC EVENTS' and trtemfl = 'Y';
run;

proc sort data=adae_derm; by usubjid astdt aeseq; run;

data adae_derm;
  set adae_derm;
  by usubjid;
  length aocc01fl $1;
  if first.usubjid then aocc01fl = 'Y';
  else aocc01fl = '';
  keep usubjid aeseq aocc01fl;
run;

/* Re-sort to USUBJID/AESEQ -- the previous sort was USUBJID/ASTDT/AESEQ
   for the first-occurrence logic, which is not the same physical order
   as USUBJID/AESEQ needed for this merge (AESEQ does not necessarily
   track chronological ASTDT order). */
proc sort data=adae_derm; by usubjid aeseq; run;

data adae_final;
  merge adam.adae adae_derm;
  by usubjid aeseq;
run;

proc sort data=adae_final out=adam.adae; by usubjid aeseq; run;

/*
Quality check */

proc contents data=ADAM.ADAE varnum;
run;

proc print data=ADAM.ADAE(obs=15);
run;

/* Duplicate AE check */
proc sort data=ADAM.ADAE out=ADAE_NODUP nodupkey dupout=ADAE_DUP;
    by USUBJID AESEQ;
run;

title "Duplicate AE Check";
proc sql;
    select count(*) as Duplicate_Records from ADAE_DUP;
quit;
title;

/* Missingness */
title "ADAE Missing Value Check";
proc sql;
    select
        sum(missing(ASTDT))   as Missing_ASTDT,
        sum(missing(AENDT))   as Missing_AENDT,
        sum(missing(ASTDY))   as Missing_ASTDY,
        sum(missing(AENDY))   as Missing_AENDY,
        sum(missing(TRTEMFL)) as Missing_TRTEMFL
    from ADAM.ADAE;
quit;
title;

/* TRTEMFL / CQ01NAM / AOCC01FL frequency */
proc freq data=ADAM.ADAE;
    tables TRTEMFL CQ01NAM AOCC01FL / missing;
run;

/* Logic check - AE end before start */
title "Date Logic Check (AENDT < ASTDT)";
proc print data=ADAM.ADAE;
    where not missing(ASTDT) and not missing(AENDT) and AENDT < ASTDT;
    var USUBJID ASTDT AENDT;
run;
title;

/* Logic check - flagged TRTEMFL=Y but ASTDT before TRTSDT (should be none) */
title "Treatment-Emergent Logic Check";
proc print data=ADAM.ADAE;
    where TRTEMFL='Y' and ASTDT < TRTSDT;
    var USUBJID TRTSDT ASTDT TRTEMFL;
run;
title;

/* AOCC01FL sanity check - should be exactly 0 or 1 'Y' per subject */
title "AOCC01FL Count Per Subject (expect max = 1)";
proc sql;
    select USUBJID, count(*) as N_Flagged
    from ADAM.ADAE
    where AOCC01FL = "Y"
    group by USUBJID
    having count(*) > 1;
quit;
title;

/*
COMPARE to sponsor reference
*/

proc sort data=REF.ADAE out=ADAE_REF_SORT;
    by USUBJID AESEQ;
run;

proc sort data=ADAM.ADAE out=ADAE_DEV_SORT;
    by USUBJID AESEQ;
run;

title "Reference ADAE vs Derived ADAE";

proc compare
    base=ADAE_REF_SORT
    compare=ADAE_DEV_SORT
    criterion=0.000001
    listall;

    id USUBJID AESEQ;

    var
        STUDYID
        TRTSDT
        TRTEDT
        ASTDT
        AENDT
        ASTDY
        AENDY
        AETERM
        AEDECOD
        AEBODSYS
        AESEV
        AESER
        AEREL
        AEOUT
        TRTEMFL
        SAFFL
        CQ01NAM
        AOCC01FL;

run;

title;
