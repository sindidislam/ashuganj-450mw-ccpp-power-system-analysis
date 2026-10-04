# Phase 5 source audit

Audit date: 2026-09-20. Scope: read-only audit of technical sources and existing provenance, with no changes to the Phase 2-4 data providers, solvers, or results. This audit distinguishes a value actually printed in a source from a model choice made using that value. A printed engineering estimate is not a measured system quantity.

## Review method and coverage

All 18 technical text files in `tmp/rev3_txt` and `tmp/rev3_newsrc` were read and searched with their original form-feed page boundaries retained. The corresponding 18 PDFs were inventoried. Relevant original pages were rendered with the Windows PDF renderer and visually inspected, because the existing PDF text extraction frequently shifts table columns by one or more rows. Original XLSX cells were read directly from their OOXML archive without modifying the workbook. Existing files in `data/master`, `matlab/data`, and the technical documents in `docs` were searched and compared with the source documents; those project transcriptions are not independent corroboration of a manufacturer's value.

The most consequential visual checks were the two generator-report pages, GSUT rating plate and datasheet, South protection one-line, main Rev 03 one-line, GIS transformer-bay circuit-breaker pages, and regional line tables. Textually blank or incomplete pages were not assumed to contain absent data: the GSUT impedance boxes were checked visually and are actually blank. Scratch extraction, renderer, page images and hashes are under `tmp/phase5_source_audit`.

## Status vocabulary

| Status | Meaning in Phase 5 |
|---|---|
| VERIFIED | The stated documentary value or physical identity was directly checked. Its source qualifications still apply. |
| DERIVED | Arithmetic from explicitly identified inputs and assumptions. |
| ENGINEERING_ASSUMPTION | Selected study input or functional scheme without sufficient plant evidence. |
| CONDITIONAL_ASSUMPTION | An equipment-to-duty mapping or interpretation valid only under an explicitly stated condition. |
| ENGINEERING_STUDY_PROXY | Simplified relay characteristic, detection or timing representation; not a commissioned setting. |
| MANUFACTURER_DEFAULT_STUDY_VALUE | Manufacturer-default study classification. For the seven 64G entries, this classification is explicitly required by the user; the asserted manufacturer origin remains USER_ASSERTED_PENDING_DOC because the exact local manual page was not found. The classification does not establish documentary verification. |
| SENSITIVITY | Alternative input, retained separately from the selected central case. |
| USER_ASSERTED_PENDING_DOC | A reported value whose asserted original document is not locally available or not sufficient to establish the claim. |

`FUNCTIONAL_ENGINEERING_ASSUMPTION` is a descriptive subtype of `ENGINEERING_ASSUMPTION`, not a competing canonical status. Provenance of a numeric input and validity of a derived conclusion must remain separate.

## Generator, CTs and sequence data

| Item | Checked evidence | Status and interpretation |
|---|---|---|
| Generator 458 MVA, 22 kV +/-5%, 12019 A, PF 0.85, 50 Hz | `fwdtechnicaldatasldrequestforbueteeetermproject/Generator Name Plate_South.pdf`, PDF p.2; `Generator Data_South.pdf`, PDF p.1 / report p.6, section 2.1.1 | VERIFIED documentary ratings. `458e6/(sqrt(3)*22000)=12019.38 A` is DERIVED. |
| Maximum operating current 14309 A | `Generator Data_South.pdf`, PDF p.1 / report p.6, section 2.1.1, Imax row | VERIFIED printed value. The same table gives Smax 518 MVA at 30 degrees C cold gas. 518 MVA at nominal 22 kV gives 13593.97 A; 14309.45 A is obtained at 20.9 kV, the -5% voltage limit. Do not incorrectly describe 14309 A as the nominal-voltage 518-MVA current. |
| Generator CT T1 and T2 | Same report section 2.1.2: each has cores 1, 2, 3, all 15000/1 A; cores 1/3 protection systems 1/2 and core 2 measurement | VERIFIED. CT ratio and pickup-current base are different quantities. |
| Generator phase and residual VTs | Same report section 2.1.3: T5/T6 phase 22kV/sqrt(3):100V/sqrt(3), ratio 220; T6 residual 22kV/sqrt(3):100V/3, ratio 381.05 | VERIFIED. Residual VT ratio is not the NGT turns ratio. |
| OEM saturated reactances | Same report section 2.1.1: Xd=166.3%, Xd'=28.65%, Xd''=22.48%, explicitly saturated | VERIFIED documentary values; keep separate from the workbook data set. |
| Workbook sequence/machine data | `fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj South (2).xlsx`, sheet `Ashuganj South ` (trailing space), row 3; H1 says Reactance in pu. H3=1.783, I3=0.3256, J3=0.2608, K3=0.2248, P3=0.2242, Q3=0.128; K2/P2/Q2 explicitly say saturated | VERIFIED workbook transcription. Machine-base interpretation 458 MVA/22 kV comes from C3/D3 and remains an identified interpretation. X2 and X0 are not absent from the source set. |
| Stator resistance | Same workbook U3 is the string `0.00089 ohm` | VERIFIED unit-specific input. Conversion to machine or system per unit is DERIVED. |
| Negative-sequence capability | Generator report p.6: I2max/IN=7.64%, K=(I2/IN)^2 t=7.41 s | VERIFIED capability data, not an automatic relay pickup/time setting. |

## GSUT rating, impedance, losses and CT conflict

The available GSUT manufacturer sources do **not** establish 16.63% and 912.2 kW as manufacturer test/nameplate values. The user can select them for the Phase 5 study, but their actual provenance must be retained.

| Item | Checked evidence | Status and consequence |
|---|---|---|
| 515 MVA, 230/22 kV, YNd1 | `GSUT Nameplate_South.pdf`, PDF p.3, S/N 881264; `GSUT Data Sheet_South.pdf`, PDF p.3 / technical p.1 section 1.1; generator report PDF p.2 / report p.7 section 2.2 | VERIFIED. Plate also gives 355/460/515 MVA stages and 1292.8 A HV at 515 MVA. |
| Manufacturer main-tap impedance | GSUT datasheet PDF p.3: 16% on 515 MVA, lower/main/higher taps 15.5/16/16.9%. Generator report p.7 and South Rev 03 protection one-line PDF p.2 also state 16% | VERIFIED documentary 16%. The GSUT plate PDF p.3 impedance-voltage boxes are visually **blank**, not 16.63%. |
| Selected 16.63% alternative | Original workbook above AO3=0.1663; AO2 says Percentage of Impedance (%Z or in pu). `Ashuganj_South_Final_Master_Data_and_Assumptions.pdf`, PDF p.2 section 5, interprets it as 0.1663 pu (16.63%) | VERIFIED raw workbook value; per-unit interpretation/selection must be disclosed. It conflicts with the available 16% manufacturer datasheet. No factory-test sheet was found to settle the difference. Do not assert that similarity to another number proves transcription contamination. |
| Selected 912.2 kW load loss | Workbook AL3=155.3, No Load Losses PNL (kW); AN3=1067.5, Total full load losses PFL (kW) or pu. Master PDF p.2 section 5 derives 912.2 | DERIVED: 1067.5-155.3=912.2 kW, assuming the full-load total excludes separately counted cooling. Rpu=912.2/515000=0.00177126214. This is a workbook route, not a printed copper-loss/nameplate test value. |
| Manufacturer losses | GSUT datasheet PDF p.6 / technical p.4 section 1.7: no-load 159 kW; at 515 MVA, 100% rated condition, copper loss 1095 kW; cooling 28 kW; total 1282 kW | VERIFIED documentary values. Marked design-finalization footnotes on PDF p.9 qualify the indicated values. Do not silently combine these with the workbook loss route. |
| GSUT zero-sequence/resistance | Datasheet PDF p.3 / technical p.1: main resistive component 0.21%, zero sequence impedance 15.8%, both marked with design footnote | VERIFIED as qualified manufacturer design data, not measured commissioned sequence impedance. Zero-sequence use must respect grounded-star/delta winding topology. |
| Earlier phase protection CT | Datasheet PDF p.5 section 1.6.1 continues to PDF p.6: 1500/1, 30 VA, 5P20 | VERIFIED older datasheet record; conflicts with later plate/Rev 03 drawings. |
| GSUT plate protection CT | Plate PDF p.3 CT table: HV/HV0, T2/T4/T6/T7/T8, Protection, S1-S2, 1600/1, 30 VA, 5P20 | VERIFIED plate record. South Rev 03 main/protection SLD also shows 1600/1 phase protection CTs. The 1500/1 claim must not be presented as an uncontested final plate ratio. |
| Plate measurement CT | Same plate table: HV, T1/T3/T5, Measure, 1600/1, 5 VA, class 0.2S | VERIFIED; not interchangeable with the protection core. |

## Grounding and stator earth protection

`Generator Data_South.pdf`, PDF p.2 / report p.7, section 2.3, visually states NGT primary **22 kV/sqrt(3)**, secondary **500 V**, TRU **25.4**, rating **135 kVA / 20 s**. These are VERIFIED documentary ratings. The same table labels **60 ohm as HV-winding DC resistance RHV-DC**, followed by `?`, and **2.62 ohm as loading resistor R1**, followed by `??`. The numbers and their question marks are both part of the evidence.

Accordingly, 60 ohm must not be promoted to a verified effective generator neutral-earth resistance. For the study interpretation that R1 is on the NGT secondary, the referred resistor is `2.62*(22000/sqrt(3)/500)^2=1690.7733 ohm`; adding the reported HV winding resistance gives `1750.7733 ohm`, and a simple terminal LG current estimate is `12701.7059/1750.7733=7.25491 A`. Using rounded TRU=25.4 changes the result slightly. A full sequence-network result can differ, but the interpretation is conditional and cannot become commissioning evidence. Existing Phase 2 qualifications must remain intact.

`GENERATION AND TRANSFORMERS SYSTEM.pdf`, PDF p.2, drawing sheet 1 lower left, shows NGT 10BAB11, 20-Hz generator/filter equipment and 64G(100%) in generator protection. It establishes the arrangement and function presence. It does not provide the proposed 64G pickup/delay/resistance settings.

The local generator report contains only **pages 6-7 of 39**, not the complete relay setting report or 7UM622 manual. No local manufacturer manual page was found for the proposed 64G values U0=1 V, I0=10 mA, Rtrip=20 ohm, Ralarm=100 ohm, ttrip=1 s, talarm=10 s, correction angle=0 degrees. The user's explicit instruction selects these numerical values with classification **MANUFACTURER_DEFAULT_STUDY_VALUE**. That study classification is retained in the parameter ledger, while the asserted manufacturer origin is **USER_ASSERTED_PENDING_DOC** until a precise manual/model/function/page is supplied. The values are not VERIFIED or commissioned settings. Exact commissioned 87G/87T/87B/7SD/50BF setting files and trip wiring are also absent.

## Breaker identities and functional topology

The source that resolves physical identities is `GENERATION AND TRANSFORMERS SYSTEM.pdf`, drawing INEL-112070-00-ELC-DE-0023 Rev 03 dated 29.10.2014, PDF pp.2-3 (drawing sheets 1-2). The main drawing `INEL-112070-00-ELC-DE-0001-REV3.pdf`, PDF p.2, provides independent equipment/topology corroboration.

| Source identity | Physical role / checked mapping |
|---|---|
| 10BAC10, 52G(Q0) | Generator circuit breaker in 22-kV isolated-phase busduct. Protection one-line PDF p.2 explicitly prints 12.4 kA, 22 kV, 100 kA sym r.m.s. These documentary ratings are VERIFIED; an actual interrupting-duty conclusion still needs the correct current at contact separation, DC component and applicable rating basis. |
| 10ADA10 / D07, 52-1(Q0) | GSUT 230-kV GIS transformer-bay circuit breaker on PDF p.2. Qualify Q0 by this location; it is not the generator Q0 or GAT Q0. |
| 10ADA10 / D02, 52-1(Q0) | GAT 230-kV GIS transformer-bay circuit breaker on PDF p.3. |
| 10BAY11 and 10BAY12 | GSUT/UAT transformer **protection panels**, as the equipment-location legend states. These are not the primary GIS bay identifiers. |
| 10BAY20 | GAT transformer **protection panel**, not an outgoing line-bay identifier. |
| 89B2-1(Q1), 89B1-1(Q2) | Bus selector **disconnectors** to buses 2/1. They are not line breakers. |
| 89-1(Q9), 57-1(Q8) | Line-side disconnector and earthing switch respectively. Calling Q9 an earthing switch is incorrect. |
| 52A-1, 52A-2 | UAT and GAT 6.6-kV incomer breakers. Both connect to 10BBA10, shown as 6.6 kV, 3150 A, 31.5 kA(1 s). |
| 86/GSUT, 86/UAT, 86/GAT | Source lockout functions with shown outputs to associated breakers. A complete commissioned matrix is not established by the simplified study representation. |
| Busbar and line breaker sets | South sheets show two GIS busbars and 87B/50BF presence but defer the detailed GIS arrangement to INEL-112070-00-ELC-DE-0026, which is unavailable locally. Additional section/line breakers may be represented as functional equivalent sets without invented plant tags. |

The 230-kV circuit-breaker datasheet is `tmp/rev3_newsrc/Data Sheet_230KV.pdf`, PDF pp.9-14. Every breaker page is headed **230 KV CIRCUIT BREAKERS - TRANSFORMER BAY**. PDF p.10 directly gives 2000 A continuous, 50 kA rated symmetrical interrupting, 125 kA making/peak and 3 s short-circuit duration. These are VERIFIED equipment-class data. Mapping that class to an identified transformer-bay Q0 is a **CONDITIONAL_ASSUMPTION** when no per-bay serial/rating plate is available. Extending it to line or bus-coupler breakers requires its own condition; it is not proved by the generic name Q0.

PDF p.2 is a **disconnector** datasheet: generator-transformer module 2000 A, line module 2000 A, bus-coupler module 3150 A; 50 kA for both 1 s and 3 s and 125 kA peak. These must not be mistaken for independent circuit-breaker interrupting proofs or conductor ampacity. PDF pp.10-11 list several breaking/opening figures under different rows, including opening 33 +/-3 ms and breaking envelopes/operating-point values. Do not collapse all those figures into one relay-plus-breaker clearing time.

A requested functional trip matrix is appropriately ENGINEERING_ASSUMPTION, subtype FUNCTIONAL_ENGINEERING_ASSUMPTION: severe generator protection can request 86G, 52G and the qualified GSUT Q0; transformer protection can request 86T and both sources of transformer energization; bus protection can request the affected-section breaker set/lockout; line differential the associated local/remote line ends; breaker failure the adjacent source-removal set. That design does not assert that all these outputs, lockout tags, timers or station-wire routes were verified on the local drawing.

## Line evidence and voltage-level conflicts

The assumed South GIS-to-grid connection of **0.7 km and two circuits** is preserved as the authorized study geometry. It is not established by the present original line inventory or South drawings. `Ashuganj_South_Final_Master_Data_and_Assumptions.pdf`, pp.1-2, proposes it, while `matlab/data/ashuganj_lines.m` correctly records its length and conductor as ENGINEERING_ASSUMPTION. The missing INEL-0026 drawing cannot be treated as inspected evidence. Positive/negative/zero-sequence line R/X/B and mutual coupling remain selected study inputs; `Line data.pdf` gives physical inventory, not sequence parameters.

The following original `fwdtechnicaldatasldrequestforbueteeetermproject/Line data.pdf` rows were checked visually. Route km and circuit km are different columns.

| PDF page / row | Voltage | Line | Route km | Circuit km | Circuits | Conductor |
|---|---:|---|---:|---:|---|---|
| 1 / 5 | 400 kV | Ashuganj(N)-Bhulta | 69.00 | 138.00 | Double | Twin Finch, 1113 MCM |
| 2 / 3 | 230 kV | Ghorasal-Ashuganj | 44.00 | 88.00 | Double | Mallard, 795 MCM |
| 2 / 5 | 230 kV | Ashuganj-Comilla North | 79.00 | 158.00 | Double | Finch, 1113 MCM |
| 2 / 16 | 230 kV | Ashuganj-Sirajganj | 144.00 | 288.00 | Double | Twin AAAC, 37/4.176 mm |
| 4 / 25 | **132 kV** | Ashuganj-Kishoreganj | 52.0 | 104 | Double | ACCC Grosbeak, 636 MCM |
| 4 / 2 | 132 kV | Brahmanbaria-Ashuganj | 16.5 | 33 | Double | Grosbeak, 636 MCM |
| 4 / 3 | 132 kV | Ashuganj-Ghorasal | 45.3 | 90.64 | Double | ACCC Grosbeak, 636 MCM |
| 5 / 129 | 132 kV | Ashuganj-Shahjibazar | 53.0 | 53.0 | Single | Grosbeak, 636 MCM |

These are VERIFIED regional inventory entries, not proof that their impedances or destinations equal the South 0.7-km equivalent. The master PDF p.2 incorrectly places the Kishoreganj entry at **230 kV**; the original inventory explicitly places it in the **132-kV table**. Preserve this conflict instead of silently marking both descriptions verified. The engineer questionnaire's 70-km outgoing line and 400-kV CT/VT block do not identify the 0.7-km South connection.

## Grid and auxiliary assumptions

| Claim | Actual source and proper status |
|---|---|
| 50 kA, XN approximately 2.66 ohm, Sk approximately 19919 MVA at 230 kV | Generator report PDF p.2 / report p.7 section 2.4 explicitly labels the grid impedance **estimated**. VERIFIED as a printed estimate, selected as ENGINEERING_ASSUMPTION or SENSITIVITY, not official measured PGCB fault strength. Its numerical coincidence with equipment ratings does not change its stated grid role. |
| 45.01 kA, X/R 10.99, magnitude Z=3.25 ohm | Root master PDF p.2 section 8, with p.4 source W5 pointing to a secondary Scribd 2019 fault-level compilation. The original compilation is not present in the inventoried source set. Retain as secondary/user-asserted context, USER_ASSERTED_PENDING_DOC for original verification, or SENSITIVITY when used. |
| Reconciliation of 45.01 and 3.25 | DERIVED voltage factor `c=45.01*sqrt(3)*3.25/230=1.10160`. With c=1, impedance is 2.95024566 ohm; with c=1.1 it is 3.24527023 ohm. From 3.25 and X/R 10.99, R=0.29450671 ohm, X=3.23662877 ohm. These are alternative stated bases, not values to mix silently. |
| Selected Phase-5 central screening grid 45.01 kA / X/R 10.99; sweeps 30/40/45.01/50 and 5/10.99/20 | DERIVED from secondary historical fault-level data at c=1: Zth=2.950245766 ohm, Rth=0.267343748 ohm, Xth=2.938107792 ohm. The 40-kA and X/R=10 earlier study selections are not the final Phase-5 central values. The alternatives are SENSITIVITY; none is an official current PGCB equivalent. Preserve the Phase 2-4 frozen grid separately. |
| Auxiliary load 12 MW+j5 MVAr | Root master PDF p.2 section 9 and p.3 section 11 explicitly class it as C, an ENGINEERING_ASSUMPTION. It is not a verified motor electrical model or motor running schedule. |
| Auxiliary 14 MW at PF 0.85 | `Google Sheet Form_Filled Up By APSCL.pdf`, PDF p.2 section 3, owner-filled value. VERIFIED documentary owner response; boundary/allocation still requires interpretation. |
| IEC Standard Inverse and 300-ms grading interval | Same owner form, PDF pp.3-4 section 5. VERIFIED stated preference/criterion. A computed margin satisfying 0.30 s remains DERIVED for the particular modeled devices, currents and clearing assumptions. |

The questionnaire explicitly answers Contact PGCB for grid short-circuit strength and positive/zero-sequence equivalent. In particular, R0/X0 for the remote grid is not independently supplied by that form. A motor locked-rotor ratio of 5, distribution of 12+j5 among motors and motor decrement curves are engineering screening assumptions until appropriate motor data and operating statuses are obtained.

## Source inventory

The first thirteen files are in `fwdtechnicaldatasldrequestforbueteeetermproject/`, with matching extracted text in `tmp/rev3_txt/`. The remaining five PDFs and texts are together in `tmp/rev3_newsrc/`. Cover pages are included in the PDF page counts and evidence locators above.

| Technical file | PDF pages | Review/use |
|---|---:|---|
| Ahsuganj South derived from engineers (1).pdf | 1 | Same extracted content as the preliminary South single-line. Its preliminary status is retained, not used to supersede Rev 03. |
| Ahsuganj South derived from engineers (2).pdf | 3 | Same extracted content as the generation/transformers protection one-line. Duplicate content is not independent corroboration. |
| GENERATION AND TRANSFORMERS SYSTEM.pdf | 3 | Rev 03 protection/measure one-line, original pp.2-3 visually reviewed for breaker/control/CT topology. |
| Generator Data_South.pdf | 2 | Report pp.6-7 of 39; both visually checked in full. Does not contain the relay-setting pages or full manual. |
| Generator Name Plate_South.pdf | 2 | Nameplate source; actual values on p.2. |
| Google Sheet Form_Filled Up By APSCL.pdf | 4 | Owner responses and mixed-voltage questionnaire; all extracted pages reviewed. |
| GSUT Data Sheet_South.pdf | 9 | All extracted pages reviewed; original pp.3 and 6 visually checked for impedance/CT/loss row alignment; footnote p.9 retained. |
| GSUT Nameplate_South.pdf | 3 | Original plate p.3 visually checked; impedance blanks and CT1600/1 established. |
| INEL-112070-00-ELC-DE-0001-REV3.pdf | 2 | Authoritative main South Rev 03 drawing, p.2 equipment/topology visual review. |
| Line data.pdf | 7 | All extracted pages searched; original pp.1,2,4,5 checked for relevant regional rows and voltage headings. |
| Single Line Diagram_South.pdf | 1 | Preliminary Rev 00; its Note 3 says equipment ratings are preliminary. Retain only as historical conflict evidence when Rev 03 differs. |
| UAT  Data Sheet_South.pdf | 24 | UAT and GAT data, 25-MVA bases, grounding and sequence sections reviewed in text. No new Phase 2-4 changes. |
| UAT Nameplate_South.pdf | 4 | UAT/GAT plate drawings and existing rendered plates considered as equipment context; blank test-data fields must not prove numeric impedances. |
| Data Sheet_230KV.pdf | 14 | Cover references North, but body explicitly South. Original pp.2,3,10,11 visually reviewed; transformer-bay breaker section pp.9-14 separated from disconnectors. |
| Data Sheet_400 KV.pdf | 19 | North 400-kV equipment source; not a South 230-kV breaker rating. |
| name plate_Interbus Transformer.pdf | 3 | North 400/230-kV Hyosung interbus transformer, contextual only. |
| SLD _400 Kv.pdf | 2 | Explicit North project; body drawing rendered for scope check. Not the missing South GIS drawing. |
| SLD_230 KV.pdf | 2 | Explicit North project; body drawing rendered for scope check. Not the South INEL-0026 drawing. |

Additional sources inspected: original `Ahsuganj South (2).xlsx` row-3 generator and GSUT cells; root `Ashuganj_South_Final_Master_Data_and_Assumptions.pdf`, all four extracted pages; `data/master/Ashuganj_Master_Data.csv`; the generator/transformer/grid/line/operating-profile/Phase-2 source providers in `matlab/data`; and the relevant existing source inventories, conflicting/verified/missing parameter registers, topology records, Phase-3 source audit, Phase-4 grounding/sequence provenance, Phase-5 assumption ledger and project manuals in `docs`. These latter records were cross-checks, not substitutes for original PDF evidence. Historical log assertions that the GSUT plate proves 16% or that Q1/Q2 are line circuit breakers are not accepted where the original drawing contradicts them.

## Remaining verification requests

Needed for final plant-setting approval: the complete generator protection setting report and applicable 7UM622 manual/function version; verified 64G measurement scaling and setting pages; actual neutral resistor/NGT test/nameplate records; South GIS drawing INEL-0026 or S008-112070-00-ELC-DE-1011 and per-bay breaker/CT schedules; commissioned relay files and trip/86/50BF wiring; official PGCB sequence equivalents with voltage-factor convention; and motor electrical/decrement/operating data. Their absence does not prevent a declared functional engineering study, but prevents asserting commissioned settings or unconditional breaker-duty compliance.
