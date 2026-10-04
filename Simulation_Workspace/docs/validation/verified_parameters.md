# Verified Parameters — Ashuganj 450 MW CCPP (South)

**Scope:** South unit only (project 112070, KKS `10B…`). North-plant documents excluded per user confirmation 2026‑08‑17.
**Status vocabulary:** `VERIFIED_PLANT` (nameplate / rating plate), `VERIFIED_ENGINEERING_DOCUMENT` (datasheet, as-built drawing), `VERIFIED_PROJECT_DATA` (engineer-filled form), `DERIVED_FROM_VERIFIED_DATA` (arithmetic only, shown).

Executable authority: [`ashuganj_master_data.m`](../../matlab/data/ashuganj_master_data.m:1), using [`ashuganj_generators.m`](../../matlab/data/ashuganj_generators.m:1) for generator data. [`Ashuganj_Master_Data.csv`](../../data/master/Ashuganj_Master_Data.csv) is the source ledger, not a competing runtime registry.

**REV3.1 Phase 1 generator update:** the verified [`Ahsuganj South (2).xlsx`](../../fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj%20South%20%282%29.xlsx) row 3 is the PRIMARY machine dataset. Full values, base conversions, qualifications and retained legacy data are described in [`generator_list.md`](../model/generator_list.md). Other equipment sections below are unchanged by this phase.

---

## Source hierarchy actually used

| Rank | Source | Files present |
|---|---|---|
| 1 | Original plant / engineer documents | `INEL-112070-00-ELC-DE-0001-REV3.pdf` (main SLD Rev 03), `GENERATION AND TRANSFORMERS SYSTEM.pdf` (INEL‑…‑DE‑0023 Rev 03), `Single Line Diagram_South.pdf` (GHESA Rev 00, **superseded**) |
| 2 | Original manufacturer datasheets / rating plates | `Generator Name Plate_South.pdf`, `GSUT Nameplate_South.pdf`, `UAT Nameplate_South.pdf` (UAT + GAT), `GSUT Data Sheet_South.pdf`, `UAT  Data Sheet_South.pdf` (UAT + GAT), `Generator Data_South.pdf`, `Data Sheet_230KV.pdf` |
| 4 | Engineer-filled form | `Google Sheet Form_Filled Up By APSCL.pdf` |
| 5 | Structured workbook (derived tabulation) | `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` |

**Revision governance.** The Rev 00 SLD carries its own Note 3: *"EQUIPMENT RATINGS ARE PRELIMINARY VALUES SUBJECTED TO THE ELECTRICAL CALCULATIONS AT PROJECT STAGE."* Two independent Rev 03 drawings (17.09.2014 and 29.10.2014) agree with the manufacturer datasheets. Where Rev 00 and Rev 03 differ, both values are preserved in [`conflicting_parameters.md`](conflicting_parameters.md); Rev 03 is treated as as-built by the documents' own supersession statement, not by preference.

---

## 1. Generator G1 — Siemens SGen5‑2000H

Single-shaft configuration: Siemens package **SCC5‑PAC 4000F/3000 (1S)** — one SGT5‑4000F gas turbine and one SST‑3000 steam turbine on a single shaft driving **one** generator. This is why a "450 MW" plant has a single 458 MVA machine.

| Parameter | Value | Unit | Source | Status |
|---|---|---|---|---|
| Type / serial | SGen5‑2000H, S/N 12783 (2013) | — | Name plate p.2 | VERIFIED_PLANT |
| Rated apparent power S_N | **458** | MVA | Name plate p.2; corroborated Rev 03 ×2 | VERIFIED_PLANT |
| Max apparent power S_max | 518 | MVA | Generator Data p.1 (cold gas 30 °C) | VERIFIED_ENGINEERING_DOCUMENT |
| Rated voltage U_N | **22 ± 5 %** | kV | Name plate p.2 | VERIFIED_PLANT |
| Rated current I_N | 12019 | A | Name plate p.2 — check 458e6/(√3·22e3)=12019.2 ✔ | VERIFIED_PLANT |
| Max current I_max | 14309 | A | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| Rated power factor | 0.85 lagging | — | Name plate p.2 | VERIFIED_PLANT |
| Primary active-power capacity | **360** | MW | Verified workbook B3 | VERIFIED_PROJECT_DATA |
| PF-derived/OEM active-power reference | **389.30** | MW | Generator Data p.1 — 458·0.85; NOT capacity | DERIVED_FROM_VERIFIED_DATA |
| Owner/site de-rated scenario | **342.01** | MW | Owner form; exact power boundary QUALIFIED | VERIFIED_PROJECT_DATA |
| Frequency / speed | 50 Hz / 3000 rpm | — | Name plate p.2 | VERIFIED_PLANT |
| Poles | 2 | — | 120·50/3000 | DERIVED_FROM_VERIFIED_DATA |
| Winding connection | YY (double star) | — | Name plate p.2 | VERIFIED_PLANT |
| Primary d-axis synchronous / transient / subtransient reactance | 1.783 / 0.3256 / 0.2608 | pu | Workbook H3/I3/J3; interpreted 458 MVA / 22 kV base | VERIFIED_PROJECT_DATA |
| Separate primary saturated subtransient reactance | 0.2248 | pu | Workbook K3 | VERIFIED_PROJECT_DATA |
| LEGACY / SATURATED SOURCE DATA: d-axis set | 1.663 / 0.2865 / 0.2248 | pu | Generator Data p.1, explicit saturated labels | VERIFIED_ENGINEERING_DOCUMENT |
| Field voltage / current | 406 V / 3088 A | — | Name plate p.2 | VERIFIED_PLANT |
| U_exc,0 | 122 | V | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| I_2max/I_N ; K | 7.64 % ; 7.41 s | — | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| Cooling | H₂, 5 bar(g); cold gas 50 °C; class F/F; IP65; S1 | — | Name plate p.2 | VERIFIED_PLANT |
| Site conditions | alt 5 m; amb 6…46.8 °C; water inlet 40 °C, max 44 °C | — | Name plate p.2 | VERIFIED_PLANT |

Generator circuit breaker **10BAC10**: 22 kV, 12.4 kA continuous, 100 kA sym. rms breaking — Rev 03 SLD p.2, corroborated INEL‑…‑DE‑0023 Rev 03.

Neutral earthing transformer **10BAB11** (high-resistance grounding): 22/√3 : 500 V, 135 kVA / 20 s, R_HV‑DC 60 Ω, secondary loading resistor 2.62 Ω — Generator Data p.1 + Rev 03 SLD.

---

## 2. Generator step-up transformer GSUT 10BAT10

| Parameter | Value | Source | Status |
|---|---|---|---|
| Manufacturer / serial | Siemens Transformer (Guangzhou), S/N 881264 (2014) | Rating plate p.1 | VERIFIED_PLANT |
| Standards | IEC 60076‑1, ‑3, ‑5 | Rating plate p.1 | VERIFIED_PLANT |
| Ratio | 230 / 22 kV | Rating plate p.1 | VERIFIED_PLANT |
| Vector group | **YNd1** (LV lags HV 30°) | Rating plate p.1 | VERIFIED_PLANT |
| Rated power | **355 / 460 / 515 MVA** (ONAN/ODAN/ODAF) | Rating plate p.1 | VERIFIED_PLANT |
| Z (main tap, 75 °C) | **16.0 %** on **515 MVA** | Data Sheet p.3‑4; Rev 03 ×2 | VERIFIED_ENGINEERING_DOCUMENT |
| Z (lower / higher tap) | 15.5 % / 16.9 % on 515 MVA | Data Sheet p.3‑4 | VERIFIED_ENGINEERING_DOCUMENT |
| R (main tap, 75 °C) | 0.21 % on 515 MVA | Data Sheet p.3‑4 | VERIFIED_ENGINEERING_DOCUMENT |
| X/R (main tap) | 76.2 | √(16²−0.21²)/0.21 = 76.19 | DERIVED_FROM_VERIFIED_DATA |
| Z₀ (main tap) | 15.8 % on 515 MVA | Data Sheet p.3‑4 | VERIFIED_ENGINEERING_DOCUMENT |
| OLTC | 230 **+8×1.25 % / −16×1.25 %**, 25 positions | Rating plate p.2‑3 | VERIFIED_PLANT |
| OLTC principal tap | **position 9 = 230000 V** | Rating plate p.2‑3 | VERIFIED_PLANT |
| OLTC type | VACUTAP 3×VRF I 1601Y‑72.6/C, S/N 14271G, 1601 A | Rating plate p.1 | VERIFIED_PLANT |
| No-load loss | 159 kW | Data Sheet p.3 | VERIFIED_ENGINEERING_DOCUMENT |
| Load loss | 523 / 874 / 1095 kW at 355/460/515 MVA, 75 °C | Data Sheet p.3 | VERIFIED_ENGINEERING_DOCUMENT |
| Temp rise oil / winding | 60 / 65 K | Rating plate p.1 | VERIFIED_PLANT |
| BIL | HV LI1050 AC460; HV‑N LI250 AC95; LV LI125 AC50 | Rating plate p.1 | VERIFIED_PLANT |
| SC duration | 3 s | Rating plate p.1 | VERIFIED_PLANT |
| HV connection to GIS | **XLPE cable, 230 kV** | Rev 03 SLD p.2 | VERIFIED_ENGINEERING_DOCUMENT |

**Nameplate arithmetic verification (all pass):** 515/(√3·230)=1292.8 A ✔ · 515/(√3·22)=13515.3 A ✔ · 460/(√3·230)=1154.7 A ✔ · 355/(√3·230)=891.1 A ✔ · 253000/230000=1.10 ✔ · 184000/230000=0.80 ✔ → exactly 25 positions at 1.25 %/step, principal tap 9.

**Tap table (HV volts; currents ONAN/ODAN/ODAF):** pos 1 = 253000 (810.1/1049.7/1175.2) … **pos 9 = 230000 (891.1/1154.7/1292.8)** … pos 13A/13B/13C = 218500 (938.0/1215.5/1360.8) … pos 25 = 184000 (1113.9/1443.4/1616.0). LV constant 22000 V, 9316.4/12071.9/13515.3 A.

---

## 3. Unit auxiliary transformer UAT 10BBT10

| Parameter | Value | Source | Status |
|---|---|---|---|
| Type / serial | Siemens (Wuhan) TLUMTA44, S/N 100579 | Rating plate p.1 | VERIFIED_PLANT |
| Ratio | 22 / **6.9** kV | Rating plate p.1 | VERIFIED_PLANT |
| Vector group | **Dyn11** | Rating plate p.1; Rev 03 | VERIFIED_PLANT |
| Rated power | **19 / 25 MVA** (ONAN/ONAF; ONAN = 76 %) | Rating plate p.1; Rev 03 ×2 | VERIFIED_PLANT |
| Z (main tap) | **10.5 %** on **25 MVA** | Data Sheet p.4; Rev 03 ×2 | VERIFIED_ENGINEERING_DOCUMENT |
| R | ≈0.4 % on 25 MVA | Data Sheet p.4 | VERIFIED_ENGINEERING_DOCUMENT |
| Z₀ | ≈9.3 % on 25 MVA | Data Sheet p.4 | VERIFIED_ENGINEERING_DOCUMENT |
| Tap changer | Off-load DU III 600‑36‑6605(M)E, 600 A, Um 36 kV, 5 positions | Rating plate p.2 | VERIFIED_PLANT |
| Tap voltages | 23100 / 22550 / **22000** / 21450 / 20900 V | Rating plate p.2 | VERIFIED_PLANT |
| Principal tap | **position 3 = 22000 V** | Rating plate p.2 | VERIFIED_PLANT |
| Losses | no-load 14 kW; load 110 kW at 25 MVA | Data Sheet p.4 | VERIFIED_ENGINEERING_DOCUMENT |
| Insulation | HV 24/125/50; LV 7.2/60/20; LV‑N 7.2/60/20 | Rating plate p.1 | VERIFIED_PLANT |
| Rated currents | HV 656.1 A @22 kV; LV 2091.8 A @6.9 kV — check 25e6/(√3·6900)=2091.8 ✔ | Rating plate p.2 | VERIFIED_PLANT |

---

## 4. Grid/station auxiliary transformer GAT 10BBT20 (three-winding)

| Parameter | Value | Source | Status |
|---|---|---|---|
| Type / serial | Siemens (Wuhan) TLSN7A54, S/N 100580 | Rating plate p.3 | VERIFIED_PLANT |
| Ratio | 230 / **6.9** / **3.32** kV | Rating plate p.3; Rev 03 ×2 | VERIFIED_PLANT |
| Vector group | **YNyn0+d11** (tertiary = stabilizing delta) | Rating plate p.3 | VERIFIED_PLANT |
| Rated power | 19 / 25 MVA (ONAN/ONAF) | Rating plate p.3 | VERIFIED_PLANT |
| Winding ratings | **25 / 25 / 8.33 MVA** | Rating plate p.3 | VERIFIED_PLANT |
| Z_PS (HV‑LV, main tap) | **12.0 %** on **25 MVA** | Data Sheet p.14; Rev 03 ×2 | VERIFIED_ENGINEERING_DOCUMENT |
| R | ≈0.5 % on 25 MVA | Data Sheet p.14 | VERIFIED_ENGINEERING_DOCUMENT |
| Z₀ | ≈10.8 % on 25 MVA | Data Sheet p.14 | VERIFIED_ENGINEERING_DOCUMENT |
| OLTC | 230 **±12×1.25 %**, 25 positions (264500 … 195500 V) | Rating plate p.3‑4 | VERIFIED_PLANT |
| OLTC principal tap | **position 13 = 230000 V @ 62.8 A** | Rating plate p.4 | VERIFIED_PLANT |
| OLTC type | VM III 350Y‑123/C, S/N 14273W, 350 A, Um 126 kV | Rating plate p.3 | VERIFIED_PLANT |
| Tertiary rating | 3320 V, 1448.6 A — check √3·3320·1448.6 = 8.33 MVA ✔ | Rating plate p.4 | VERIFIED_PLANT |
| Losses | no-load 23 kW; load 116 kW at 25 MVA | Data Sheet p.14 | VERIFIED_ENGINEERING_DOCUMENT |
| Insulation | HV 245/1050/460; HV‑N 52/250/95; LV 7.2/60/20; stab. winding Um 3.6 kV / 40 kVp / 10 kV | Rating plate p.3 | VERIFIED_PLANT |
| HV connection to GIS | **SF₆ bus duct** | Rev 03 SLD p.2; INEL‑…‑DE‑0023 Rev 03 | VERIFIED_ENGINEERING_DOCUMENT |

**Nameplate arithmetic verification:** 264500/230000 = 1.15 ✔ · 195500/230000 = 0.85 ✔ · 25/(√3·230)=62.75 A ✔ · 25/(√3·6.9)=2091.8 A ✔.

> **This transformer is a second, independent source into the 6.6 kV MV bus, fed from the 230 kV GIS.** It is present on both Rev 03 drawings and on the rating plate. It is absent from the prior CYME PSAF model and from the target topology sketch. See question **Q4**.

---

## 5. 230 kV GIS (Siemens 8DN9)

Source: `Data Sheet_230KV.pdf` body pages (all titled "ASHUGANJ 450 MW COMBINED CYCLE POWER PLANT (SOUTH)", header "TSK INELECTRA", KKS 07485‑20‑ADA‑EHP‑SIE‑001 Rev 1) + Rev 03 drawings.

| Parameter | Value | Status |
|---|---|---|
| Type | Siemens **8DN9** | VERIFIED_ENGINEERING_DOCUMENT |
| Rated voltage / U_m | 230 / 245 kV | VERIFIED_ENGINEERING_DOCUMENT |
| Frequency | 50 Hz | VERIFIED_ENGINEERING_DOCUMENT |
| Busbar arrangement | **BUS 1 / BUS 2**, double busbar, single breaker per bay | VERIFIED_ENGINEERING_DOCUMENT |
| Bay devices | Q0 = CB, Q1 = disconnector to BUS 2, Q2 = disconnector to BUS 1, Q9 = earthing switch | VERIFIED_ENGINEERING_DOCUMENT |
| Bays identified | 10BAY11, 10BAY12, 10BAY20 | VERIFIED_ENGINEERING_DOCUMENT |
| Module rated currents | Generator transformer 2000 A · Line 2000 A · **Bus coupler 3150 A** | VERIFIED_ENGINEERING_DOCUMENT |
| Rated short-time withstand | 50 kA (1 s and 3 s) | VERIFIED_ENGINEERING_DOCUMENT |
| Rated peak withstand | 125 kA | VERIFIED_ENGINEERING_DOCUMENT |
| Fault making current | 50 kA / making 125 kA | VERIFIED_ENGINEERING_DOCUMENT |
| LI withstand | 1050 kVp line-to-ground; 1200 kVp across open disconnector | VERIFIED_ENGINEERING_DOCUMENT |
| PF withstand | 460 kV / 530 kV | VERIFIED_ENGINEERING_DOCUMENT |
| CB total breaking time | 54 + 6 ms | VERIFIED_ENGINEERING_DOCUMENT |
| SF₆ filling / alarm | 6.1 / 6.9 bar | VERIFIED_ENGINEERING_DOCUMENT |
| Mechanism supply | 110 V DC, −15/+10 % | VERIFIED_ENGINEERING_DOCUMENT |

*Extraction caveat:* the datasheet is a two-column form; `pdftotext` scrambles label↔value adjacency. Values above were cross-checked against Rev 03 (3150 A, 50 kA, LI1050) where possible; module-current assignments carry **Medium** confidence. None of these are load-flow inputs.

---

## 6. Buses (nominal voltages, from Rev 03 SLD p.2)

| Bus tag | Nominal | Rated current | I_sc | Tolerance (drawing Note 1) |
|---|---|---|---|---|
| 230 kV BUS 1 / BUS 2 (GIS) | 230 kV | 3150 A | 50 kA | not stated |
| 22 kV generator terminal / IPB (10BTA10/20/30/40) | 22 kV | — | — | ±5 % (generator nameplate) |
| MV busbar **10BBA10** | 6.6 kV | **3150 A** | 31.5 kA (1 s) | ±10 % |
| Water intake **10BBW10** | 6.6 kV | 1250 A | 31.5 kA | ±10 % |
| Water intake **10BBW20** | 6.6 kV | 1250 A | 31.5 kA | ±10 % |
| LV **10BFA10 / 10BFA20** | 400 V | 4000 A | 50 kA | ±10 % |
| LV **10BFA30 / 00BFA10** | 400 V | 1600 A | 50 kA | ±10 % |
| LV water intake **10BFE** | 400 V | 800 A | 50 kA | ±10 % |

Drawing Note 1 also fixes 230 V ±10 % and 110 V DC +10/−20 % for control supplies.

---

## 7. MV motor schedule (Rev 03 SLD p.2, MV MOTOR TABLE) — **rated** powers

| KKS tag | Service | Bus | Rated kW | CB |
|---|---|---|---|---|
| 10LAC71AP001 | HP/IP boiler feedwater pump 1 | 10BBA10 | 2265 | 1250 A |
| 10LAC72AP001 | HP/IP boiler feedwater pump 2 | 10BBA10 | 2265 | 1250 A |
| 10LCB11AP001 | Condensate pump 1 | 10BBA10 | 770 | 1250 A |
| 10LCB12AP001 | Condensate pump 2 | 10BBA10 | 770 | 1250 A |
| 10EKH10AN001 | Gas booster compressor 1 | 10BBA10 | 1210 | 1250 A |
| 10EKH10AN002 | Gas booster compressor 2 | 10BBA10 | 1210 | 1250 A |
| 10PGC1SAP001 | CCCW pump 1 | 10BBA10 | 280 | 1250 A |
| 10PGC20AP001 | CCCW pump 2 | 10BBA10 | 280 | 1250 A |
| | **subtotal 10BBA10** | | **9050** | |
| 00PAC10AP001 | Circulating water pump 1 | 10BBW10 | 2220 | — |
| 10PCC10AP001 | OCCW pump 1 | 10BBW10 | 280 | — |
| | **subtotal 10BBW10** | | **2500** | |
| 00PAC20AP001 | Circulating water pump 2 | 10BBW20 | 2220 | — |
| 10PCC20AP001 | OCCW pump 2 | 10BBW20 | 280 | — |
| | **subtotal 10BBW20** | | **2500** | |
| | **TOTAL** | | **14 050 kW** | |

These are **nameplate shaft ratings**, not measured electrical demand. Per-motor power factor and efficiency are **MISSING**, so rated kW cannot be converted to bus MW/MVAr without assumptions. See [`missing_parameters.md`](missing_parameters.md) M‑L2.

---

## 8. Auxiliary / LV transformers (Rev 03 SLD p.2)

| Tag | Ratio | Rating | Group | Z | Cooling |
|---|---|---|---|---|---|
| 10BFT10, 10BFT20 | 6600 ±2.5 ±5 % / 420 V | 2500 kVA | Dyn11 | **10.75 %** | ONAN |
| 10BFT30, 00BFT10 | 6600 / 420 V | 1000 kVA | Dyn11 | 6 % | — |
| 10BFT40 | 6600 / 420 V | 400 kVA | Dyn11 | 4 % | AN |
| 10BMV10 (SFC) | 6600 ±2.5 ±5 % / **2000 V** | 3400 kVA | Dy5 | 4.7 % | AN |
| Excitation transformer | 6600 ±2.5 ±5 % / **660 V** | **3560 kVA** | Dy5 | 6 % | AN |
| 10BTL10/20/30/40 (control) | 400 ±2.5 ±5 % V | **30 kVA** | — | — | — |
| 10BLA10, 10BLA20 (lighting) | — | **400 kVA** | — | — | AN |
| 00BLA10 (lighting) | — | 100 kVA | — | — | AN |
| 10BUK01, 10BUK02 (EDG) | 400 V | 1000 kVA, cos φ 0.8 | — | — | — |

Rev 00 gives different values for several of these; the Excel workbook reproduces the **Rev 00** values while citing the Rev 03 drawing — see [`conflicting_parameters.md`](conflicting_parameters.md) C16. None of these are load-flow blocking because no LV load data exists.

**Drawing Note 4:** *"DISCONNECTOR SWITCH WILL REMAIN OPEN WHILE EDG IS SYNCHRONIZED WITH THE GRID"* → the emergency diesel generators are normally **out of service** and are not load-flow sources.

---

## 9. Instrument transformers (recorded, not load-flow inputs)

GSUT CTs: HV/HV0 T2,T4,T6,T7,T8 = 1600/1 30VA 5P20; HV T1,T3,T5 = 1600/1 5VA 0.2S; HV‑B T9 = 1293/2 (WTI); LV‑b T10 = 13515/2 (WTI); HV‑A T11 = 1293/5 (ITM509); LV‑a T12 = 13515/5 (ITM509).
UAT CTs: T1‑T3 = 1000/1 30VA 5P20; T4 = 750/1 5VA Cl0.2 Fs10; T5 = 2300/2 20VA.
GAT CTs: T1 = 500‑250/1 30VA 5P20; T2 = 100/1 5VA Cl0.2 Fs10; T3 = 80/2 20VA; T6 = 250/1 15VA 5P20 (HV‑N); T5 = 2300/2 20VA.
Generator CT 15000/1 A (T1 & T2, cores 1‑3). VTs: 22/√3 : 0.100/√3 and 0.100/3 kV; 230/√3 kV; 6600/√3 : 110/√3 V.
Transformer differential relay F12/F13 = SIEMENS 7UT6331‑5QB92‑4BC0+L0S.

---

## 10. External 230 kV grid

| Parameter | Value | Source | Status |
|---|---|---|---|
| Nominal voltage | 230 kV | Generator Data p.2 | VERIFIED_ENGINEERING_DOCUMENT |
| I_k″ | 50 kA | Generator Data p.2 | **ESTIMATED** |
| S_k″ | 19 919 MVA | Generator Data p.2 | **ESTIMATED** |
| X_N | 2.66 Ω | Generator Data p.2 — report says *estimated* | **ESTIMATED** |

**Internal consistency:** √3·230·50 = 19 918.6 MVA ✔ and 230²/19 919 = 2.656 Ω ✔ — all three numbers derive from I_k″ = 50 kA, which is *exactly* the GIS rated short-time withstand current. That strongly suggests the "grid" was represented at the equipment-design level rather than measured, and using it gives a maximum-strength grid (optimistic voltage support). The Siemens report itself labels X_N estimated, and the APSCL form answered "Contact PGCB" for fault capacity. Grid **R** (or X/R) is **MISSING**. See question **Q1**.

Separately, the GSUT rating plate states "Max. system short-circuit power HV/LV = 21 218 / 3950 MVA". That is a transformer **design withstand** figure, not the grid's actual S_k″ — a different quantity, preserved as such.
