# Source File Inventory (Phase 0) — Ashuganj 450 MW CCPP (South)

Working directory: `F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project` (note the leading space in `" Level 3 Term 1"`). Not a git repository.

**349 source files** as delivered, before any deliverable was created.

| Extension | Count | What it is |
|---|---|---|
| `.dbf` | 186 | CYME PSAF dBASE equipment libraries |
| `.ntx` | 61 | PSAF index files |
| `.cgp` | 61 | PSAF name stubs (5–12 bytes each, hold only the table name) |
| `.dbt` | 15 | dBASE memo files |
| **`.pdf`** | **11** | **the engineering documents** |
| `.log` | 3 | `EXPORT.LOG`, `UpdateDBF.log`, one more |
| `.stu` | 2 | PSAF study files |
| `.nwt` | 2 | PSAF network files (tab-delimited) |
| `.nwk` | 2 | PSAF network files |
| `.zip` | 1 | `fwdtechnicaldatasldrequestforbueteeetermproject.zip` — **contains 15 PDFs** |
| `.xlsx` | 1 | `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` |
| `.rar` | 1 | `psaf export (1).rar` — **could not be opened** |
| `.ver` | 1 | `dbf.ver` |
| `.tmp` | 1 | `tmp7D1.tmp` (0 bytes) |
| `.ini` | 1 | `PSAF.INI` |

Directories: `.` · `./fwdtechnicaldatasldrequestforbueteeetermproject` · `./psaf export (1)` · `./psaf export (1)/psaf export` · `./psaf export (1)/psaf export/database`

---

## Critical Phase 0 finding: the ZIP held 5 unextracted PDFs

`fwdtechnicaldatasldrequestforbueteeetermproject.zip` contains **15** PDFs but only **10** had been extracted to disk. Extracting the remaining 5 surfaced one genuinely needed South document and four out-of-scope North-plant documents. Had this not been caught, the model could have been contaminated with a 400 kV level that does not exist in the South plant.

---

## A. South documents — READ AND USED (11)

| File | Pages | Document ID / Rev | Date | Content |
|---|---|---|---|---|
| `INEL-112070-00-ELC-DE-0001-REV3.pdf` | 2 | INEL‑112070‑00‑ELC‑DE‑0001 **Rev 03**, dwg 456‑10‑D‑E‑11010 | 17.09.2014 | **THE AUTHORITATIVE MAIN SLD.** All equipment ratings, the **MV MOTOR TABLE**, LV distribution, Notes 1–4 |
| `GENERATION AND TRANSFORMERS SYSTEM.pdf` | 3 | INEL‑112070‑00‑ELC‑DE‑0023 **Rev 03**, dwg 456‑10‑D‑E‑11110 | 29.10.2014 | Protection & measure one-line. **Independent corroboration** of every Rev 03 rating; CT/VT ratios; relay types |
| `Single Line Diagram_South.pdf` | 1 | GHESA‑112070‑00‑ELC‑DE‑0001 **Rev 00** | 17.05.2013 | **SUPERSEDED** — its own Note 3 says ratings are preliminary. Retained for the conflict log |
| `Generator Name Plate_South.pdf` | 2 | Siemens BD1015‑10MK‑MDA010‑320008, UNID 492946978, "Final Release Manufacturing" | — | **Highest-authority generator source.** SGen5‑2000H S/N 12783 |
| `GSUT Nameplate_South.pdf` | 3 | RATING PLATE 10BAT10 **Rev 01**, S009‑112070‑00‑ELC‑PE‑0003 | 04/06/14 | Siemens Guangzhou S/N 881264. Full 25-position tap table, CT schedule |
| `UAT Nameplate_South.pdf` | 4 | RATING PLATE 10BBT10 & 10BBT20 **Rev 03**, STWH‑579UAT‑0008 / STWH‑580GAT‑0008, S009‑112070‑00‑ELC‑PE‑1003 | 11/06/14 | Siemens Wuhan. **Both UAT (S/N 100579) and GAT (S/N 100580)** |
| `Generator Data_South.pdf` | 2 | pp. **6–7** of S001‑112070‑00‑ELC‑CL‑0002 "Generator Protection Setting Report" BD1015‑10CHA‑&EFQ030‑760522 | — | x_d/x_d′/x_d″, S_max, NER data, **external grid figures** |
| `GSUT Data Sheet_South.pdf` | 9 | S009‑112070‑00‑ELC‑HD‑0001 Rev 00 | 24/02/14 | **Z at three taps** (15.5/16.0/16.9 %), R, Z₀, losses, cooling |
| `UAT  Data Sheet_South.pdf` | 24 | STWH‑579UAT‑0007 / STWH‑580GAT‑0007 Rev 00 | 27/03/14 | **UAT and GAT impedances**, R, Z₀, losses |
| `Data Sheet_230KV.pdf` | 14 | KKS 07485‑20‑ADA‑EHP‑SIE‑001 **Rev 1** | — | **230 kV GIS data sheet — Siemens 8DN9.** Extracted from the ZIP this audit |
| `Google Sheet Form_Filled Up By APSCL.pdf` | — | engineer-filled form | — | Station aux demand 14 MW @ 0.85 pf; several transcription errors; a **400 kV block that is North-scope** |

`Data Sheet_230KV.pdf` deserves a note: its transmittal **cover page** carries a North (project 7485 / TSK) review stamp, but all 13 **body pages** are titled *"ASHUGANJ 450 MW COMBINED CYCLE POWER PLANT (SOUTH)"* with header *"TSK INELECTRA"*. It is the South GIS data sheet and is in scope.

---

## B. North-plant documents — EXCLUDED FROM SCOPE (4)

All four were inside the ZIP and unextracted. User confirmed 2026‑08‑17: *"we are modeling only south part not north."*

| File | Pages | Identification |
|---|---|---|
| `SLD_230 KV.pdf` | 2 | "ASHUGANJ CCPP PROJECT (**NORTH**)", UTS project **7485**, PO 7485‑1209, vendor TSK, (1)‑G71770‑AD067‑S005 Rev 0, KKS 07485‑20‑ADA‑EDU‑SIE‑001 Rev 0, 09‑12‑2014, TECNICAS REUNIDAS |
| `SLD _400 Kv.pdf` | 2 | "Single Line Diagram **400 KV** GIS", (1)‑G71770‑AC066‑S005 Rev 2, KKS 07485‑20‑ACA‑EDU‑SIE‑001 Rev 2, 19‑05‑2015 |
| `Data Sheet_400 KV.pdf` | 19 | "Data Sheet **400 KV** GIS", KKS 07485‑20‑ACA‑EHP‑SIE‑001 Rev 0 |
| `name plate_Interbus Transformer.pdf` | 3 (4 sheets) | PO 0748512010, "**400/230KV INTERBUS TRANSFORMERS**", vendor **HYOSUNG**, NT14‑BA1‑010 Rev 5, KKS 07485‑20‑ADT‑JDB‑HYO‑001 Rev 4, 15/04/2015; VACUTAP OLTC |

**Why this matters.** The North unit has a 400 kV GIS and 400/230 kV interbus autotransformers; the South unit's highest voltage is 230 kV. Using these would fabricate a 400 kV network. It also explains the Google Form's 400 kV block (CT 1600/1, PT 400000/110 V, R₀ 0.06667 Ω/km, X₀ 0.39472 Ω/km, B₁ 3.4011 µS/km, 70 km) — North data, never to be used for South.

---

## C. Project documents — READ (2)

| File | Content |
|---|---|
| `grp3_eee306_jan26_project_proposal_v2.pdf` | BUET EEE 306, January 2026, Power System I Laboratory, Group‑03, Section C‑1. Instructors Md. Kamrul Hasan (Lecturer, EEE, BUET), Md. Mahadi Jaman (PT, EEE, BUET). Students 2206136 Sasshata Talukder · 2206147 S. M. Sindid Islam Mahodi · 2206152 Rajib Khan · 2206153 Iftekhar‑E‑Islam · 2206155 Abu Mohammed Ibn Julker Nahin. Abstract cites SGT5‑4000F GT, HRSG, SST‑3000 ST, APSCL, River Meghna, ~75 km from Dhaka (a **geographic** distance — not the 70 km line length). Planned tool CYME PSAF; workflow collect → SLD → base load flow → LLL/LG/LLG faults → CB ratings → OC/differential relay selection → TMS/PS → re-simulate → conclude |
| `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` | 14 sheets, **all audited**: `00_README`, `01_SOURCES`, `02_BUS_PSAF`, `03_GENERATOR_PSAF`, `04_GEN_Q_CAPABILITY`, `05_TRANSFORMERS_PSAF`, `06_AUX_TRANSFORMERS`, `07_LINES_CABLES_PSAF`, `08_LOADS_PSAF`, `09_MOTORS_PSAF`, `10_EXTERNAL_GRID`, `11_NOMINAL_VS_RATED`, `12_PSAF_BUS_FIELD_GUIDE`, `13_VALIDATION_NOTES`. A **rank‑5 derived tabulation** — useful, and in places demonstrably contaminated with Rev 00 values (conflict C16) |

---

## D. Prior CYME PSAF model — AUDITED, NOT USED AS A DATA SOURCE

| File | Size | Finding |
|---|---|---|
| `AUTOSAVE.nwk` / `AUTOSAVE.NWT` | — | 11 useful buses + junk rows (`B0`, `B1`, malformed `0.00000`); G1 at `B22G` PGen 389.3, grounding 730/0.1 Ω; `T1` (UAT position) references generic library type; `GSUT 10BAT10` TCUL branch; **no `[Line]`, no `[Load]`, no shunt sections** |
| `psaf export (1)/psaf export/ONGOING.nwk` | — | Same topology; G1 grounding 9999/9999 Ω |
| `AUTOSAVE.STU` | 26 693 B | `PARAMETERS  125, 100, **60**, UNTITLED` → **60 Hz** on a 50 Hz plant |
| `psaf export (1)/psaf export/ongoing.stu` | 26 390 B | Identical parameters |
| `database/Gener.DBF` | 35 243 B | 17 shipped library generators + one project record `GEN1_DATAA` whose QMAX/QMIN/RGROUND/XGROUND are **byte-identical to the 1.3 MW diesel template** |
| `database/txvar.DBF` | 8 258 B | One project record `10BAT10`; Z/X/R correct, **TAPMN = 88.00 % where the nameplate requires 80.00 %** |
| `database/txfix.DBF` | 9 702 B | **No project entries**; `T1` uses `10/126_0500` = 500 MVA, 10/120 kV, Z 1.92 % |
| `database/twinding.DBF` | 3 412 B | **Field descriptors only — GAT 10BBT20 was never modelled** |
| `database/load.DBF` | 1 268 B | Only PSAF's 5 generic load models. **No project loads** |
| `database/line.DBF` | 14 974 B | Field descriptors only. **No project lines** |
| `EXPORT.LOG` | — | "PSAF Version 2.81 / PSAF Revision 2.8" |
| `dbf.ver` | — | `[UPDATE] Date=16\8\2026 Version=2.90` |
| `UpdateDBF.log` | 34 022 B | "13 August 2026 2:3:13"; French *"Suppression d'un champs non existant"* removing `REFCOUNTER`/`ASSOCIATE`/`SPARE1` |
| `PSAF.INI` | 11 425 B | `DATABASE=D:\ACADEMICS\L-3 T-1\EEE 306\PROJECT\PROJECT PSAF`, `BUS_DEFAULT_BASE_OPERATING_VOLTAGE=13.800000`, `UNITLENGTH=FALSE`, `UNITS_IN_NA=1` |
| `.cgp` × 61 | 5–12 B each | Name stubs only (`Gener.cgp` = "GENER") |
| `tmp7D1.tmp` | 0 B | empty |

Full defect analysis: [`prior_psaf_model_defects.md`](prior_psaf_model_defects.md).

---

## E. Could NOT be read (1)

| File | Size | Reason |
|---|---|---|
| `psaf export (1).rar` | 47 721 B | **No RAR extractor on this machine** — `unrar`, `7z`, `7za` and `p7zip` are all absent. The folder `psaf export (1)/psaf export/` (74 entries, incl. `database/` with 67 entries) exists on disk and is **presumed** to be the archive's contents, but that is **unverified**. If the RAR holds anything the folder does not, it has not been read |

---

## Tooling notes (why some reads were harder than they should be)

| Constraint | Workaround used |
|---|---|
| **Python not installed** (`python`/`python3` resolve to the Microsoft Store alias stub) | `pdftotext`, `unzip`, `sed`, `awk`; MATLAB R2024a as scripting fallback |
| **`pdftoppm` not installed** (only `pdftotext.exe` in `/mingw64/bin`) | PDF **page rendering is unavailable**, so drawings could not be re-verified visually — only via text extraction. This is why the Rev 03 LV auxiliary-transformer block carries slightly lower confidence than the main equipment block |
| **`strings` not installed** | Produced a silent false negative (0 project-tag hits in every DBF). Replaced with `grep -a` on the binaries, which then found the real project records `GEN1_DATAA` and `10BAT10` |
| Large-format drawings | `pdftotext -layout` emits multi-thousand-character lines; switched to `-raw` token streams and bounded windows |
| Excel XML namespace | `workbook.xml` uses the `x:` prefix (`<x:sheet name=…>`); first grep missed all sheet names |
| **GAT tap-table OCR error** | Position 14 rendered "227275 V"; the printed 63.5 A implies 227125 V. Caught by cross-checking current against voltage |
