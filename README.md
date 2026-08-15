# SDTM to ADaM: Clinical Trial Programming 

A beginner-level SAS programming project that converts CDISC SDTM datasets into
ADaM analysis datasets and produces a few standard clinical trial summary tables.

This is a **learning/portfolio project**, not a regulatory submission.

## What this project does

1. Explore and QC the source SDTM domains (DM, EX, AE)
2. Build three ADaM datasets: **ADSL**, **ADAE**, **ADTTE**
3. QC each dataset and compare it to the CDISC Pilot Project reference dataset with `PROC COMPARE`
4. Produce a few summary tables and a Kaplan-Meier plot
5. Validate the final datasets with Pinnacle 21 Community
6. Document everything in a traceability workbook

```
SDTM (DM, EX, AE) → ADaM (ADSL, ADAE, ADTTE) → Summary Tables / KM Plot
```

## Data source

This project uses the **CDISC SDTM/ADaM Pilot Project** dataset, which is
provided by CDISC as a public pilot/teaching dataset:

https://github.com/cdisc-org/sdtm-adam-pilot-project

The raw CDISC Pilot Project data are not redistributed in this repository.
Please obtain the source data directly from the official CDISC repository
above and review the applicable CDISC Terms of Use before using or
redistributing the data.

Only my own code, derived-dataset structures, and documentation are included here.

## Datasets built

|Dataset|Description|Records|
|-|-|-|
|ADSL|One row per subject (demographics, treatment, population flags)|254 subjects|
|ADAE|One row per adverse event|1,191 records|
|ADTTE|Time to First Treatment-Emergent Dermatologic Event|254 subjects|

The source DM domain has 306 subjects total; 52 were Screen Failures and are
excluded from ADSL, leaving the 254-subject analysis population above.

## Key results

**Subjects by planned treatment**

|Treatment|N|
|-|-:|
|Placebo|86|
|Xanomeline High Dose|84|
|Xanomeline Low Dose|84|

**Subjects with ≥1 treatment-emergent adverse event**

|Treatment|Subjects with TEAE|Safety N|%|
|-|-:|-:|-:|
|Placebo|65|86|75.6%|
|Xanomeline High Dose|76|84|90.5%|
|Xanomeline Low Dose|77|84|91.7%|

**Treatment duration (days)**

|Treatment|N|Mean|SD|Median|Min|Max|
|-|-:|-:|-:|-:|-:|-:|
|Placebo|86|149.1|60.3|182.0|7|210|
|Xanomeline High Dose|84|99.4|70.6|76.5|1|200|
|Xanomeline Low Dose|84|99.0|68.2|82.5|2|212|

## Validation

* Every ADaM dataset was reconciled against the CDISC Pilot Project reference
dataset using `PROC COMPARE` — all three currently show **0 unequal records**.
* All three datasets were also run through **Pinnacle 21 Community**. Most
findings are expected for a small 3-dataset beginner project checked against
the full CDISC Pilot Project Define.xml (e.g. variables/datasets out of scope). One
finding (TRTEMFL using Y/N instead of Pinnacle 21's generic Y/null rule) was
deliberately kept because it matches this study's own Define.xml and is
needed to reconcile against the reference data. Full details are in the
traceability workbook.
* **Pinnacle 21 validation note:** the validation report was generated using
the CDISC Pilot Project's publicly available Define.xml metadata during
local validation. The Define.xml itself is not redistributed in this
repository — see the Data source section above for where to obtain it.

## Project structure

```
programs/
  00\_setup.sas
  02\_explore\_sdtm.sas
  03\_build\_adsl.sas
  04\_build\_adae.sas
  05\_build\_adtte.sas
  06\_tlf\_dataexploration.sas
  07\_table\_demographics.sas
  08\_table\_teae.sas
  09\_table\_trtduration.sas
  10\_km\_adtte.sas
  11\_export.sas

validation/
  pinnacle21-report.xlsx

docs/
  ADaM_Traceability.xlsx

README.md
```

## How to reproduce

1. Download the CDISC Pilot Project SDTM data from the link above.
2. Load DM, EX, and AE into a SAS library.
3. Update the `%let HOME=...` path at the top of each program if needed.
4. Run the programs in order (01 through 11).

## Known limitations

* `TRT01A` (actual treatment) is derived from `DM.ARM`, the same field used
for planned treatment, so it doesn't capture within-study dose changes.
This was a deliberate choice to match the CDISC Pilot Project reference
dataset — see the traceability workbook for details.
* Partial adverse event start dates (year-month only) are imputed to day 01;
year-only dates are left missing. No further date imputation was implemented.
* DM, EX, and AE were used for the final ADaM derivations. Other SDTM domains
(LB, VS, DS) and the SUPPAE supplemental qualifier dataset were retained
from the source Pilot package for exploration/reference but were not
required for the final derivations.
* This project only covers ADSL, ADAE, and ADTTE — not a full ADaM package.

## Skills demonstrated

SAS programming, CDISC SDTM/ADaM, dataset derivation, QC and `PROC COMPARE`
reconciliation, Pinnacle 21 validation, traceability documentation, and basic
clinical trial summary tables (demographics, safety, treatment duration,
Kaplan-Meier).

## Attribution

Source data: CDISC SDTM/ADaM Pilot Project
(https://github.com/cdisc-org/sdtm-adam-pilot-project), used under CDISC's
Terms of Use and not redistributed here. This repository contains only my
own programs, derived-dataset documentation, and analysis. It is an
independent learning project and is not affiliated with or endorsed by CDISC.

