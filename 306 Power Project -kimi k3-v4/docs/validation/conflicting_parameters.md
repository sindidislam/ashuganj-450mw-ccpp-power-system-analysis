# Conflicting Parameters — Ashuganj 450 MW CCPP (South)

Every conflict below preserves **both** values with both sources, states whether the two numbers refer to different operating conditions / bases / revisions, and marks whether it materially affects the load flow. **No conflict has been silently resolved.**

Legend — **Effect:** `BLOCKING` = load flow cannot proceed until decided · `MATERIAL` = changes results, resolvable by documented supersession · `NON‑BLOCKING` = recorded, no effect on balanced load flow.

---

## C1 — GSUT tap step size
| Source | Value |
|---|---|
| GSUT Data Sheet + Rating plate + Rev 03 SLD | 230 **+8×1.25 % / −16×1.25 %** |
| Google Form (APSCL) | 230 −16×**1.15 %** |

**Explanation:** the rating-plate tap table is arithmetic proof — 253000/230000 = 1.100 and 184000/230000 = 0.800, i.e. +10 %/−20 % over 24 steps = **1.25 %/step exactly**. 1.15 % would give 230000·(1−16·0.0115) = 187 680 V, which appears nowhere on the plate. The form value is a transcription typo.
**Effect:** NON‑BLOCKING (does not change the main tap). Documented; 1.25 % used, form value retained here.

---

## C2 — Generator active power: rated vs de-rated
| Source | Value | Quantity |
|---|---|---|
| Siemens Generator Data p.1 | **389.30 MW** | Rated P at 458 MVA, pf 0.85, 50 °C cold gas |
| Google Form p.2 | **342.01 MW** | "Site De-rated Active Power" |
| Prior CYME PSAF `Gener.DBF` `GEN1_DATAA` | 389.3001 MW | PGEN used in the previous model |

**Explanation:** these are **not the same quantity**. 389.30 MW is the generator's electrical rating; 342.01 MW is a site/ambient-de-rated output figure (Ashuganj max ambient 46.8 °C per the nameplate, well above the 50 °C-cold-gas rating point). Neither is a measured dispatch. Both preserved.
**Effect:** **BLOCKING** — the load-flow dispatch must be chosen. See question **Q2**.

---

## C3 — Generator apparent power rating
| Source | Value | Condition |
|---|---|---|
| Name plate + Rev 03 SLD ×2 | **458 MVA** | cold gas 50 °C — the rating |
| Generator Data p.1 | 518 MVA (S_max) | cold gas 30 °C |
| Rev 00 SLD (GHESA, 17.05.2013) | 450 MVA | *preliminary* per its own Note 3 |
| Rev 00 SLD generator CT | 16000/1 A | vs Rev 03 **15000/1 A** |

**Explanation:** 458 and 518 MVA are the same machine at two different cooling-gas temperatures — a condition difference, not a conflict. 450 MVA is a superseded preliminary value; the Rev 00 drawing states its own ratings are preliminary. 458 MVA is confirmed by the released rating plate and by two independent Rev 03 drawings.
**Effect:** MATERIAL, resolved by documented supersession + condition. Model base = 458 MVA; 518 MVA retained as the 30 °C capability; 450 MVA retained as historical.

---

## C4 — Generator reactive capability limits
| Source | Value | Traceability |
|---|---|---|
| Google Form p.2 | "+241 MVAr" | = 458·sin(acos 0.85) = **241.3 MVAr** — this is the **rated-point Q**, not a capability limit; no Q_min given |
| Excel `04_GEN_Q_CAPABILITY` | 7 points, Q_max 332.3 → 0, Q_min −228.7 → 0 | cited to "Generator Protection Setting Report, Attachment 1 / p.42 of 44" |
| Prior PSAF `Gener.DBF` `GEN1_DATAA` Q_CURVE | same 7 points, **truncated mid-record** | source of the Excel transcription |
| Prior PSAF `Gener.DBF` QMAX / QMIN scalars | **0.653 / −0.131 MVAr** | verbatim copy of the shipped `1.3MW_4.2KV_DIESEL-GENERATOR` library template — never edited |
| Original capability curve | — | **NOT PRESENT** — only pp. 6‑7 of the 39‑page report are in the project, as `Generator Data_South.pdf` |

**Explanation:** the Excel curve is not independent evidence — it was transcribed from the PSAF DBF, which cites a document page (p.42) that is not in the project. The DBF record is truncated (the 6th point's Q_min and the whole 7th point are lost), and Q_min/Q_max is a near-constant ≈0.69 across the curve, which is not how a real salient-pole-free capability curve behaves. The QMAX/QMIN **scalars** in the same record are provably a 1.3 MW diesel-generator template artefact (0.653 MVAr for a 458 MVA machine).
**Effect:** **BLOCKING if PV Q-limits are enforced.** Q limits are **MISSING**, not verified. See question **Q3**.

---

## C5 — Generator neutral grounding
| Source | Value |
|---|---|
| Siemens Generator Data p.1 + Rev 03 SLD | NER **10BAB11**: 22/√3 : 500 V, 135 kVA/20 s, R_HV‑DC 60 Ω, loading resistor 2.62 Ω → **high-resistance grounding** |
| Google Form | grounding described as "Low-Reactance" |
| Prior PSAF `AUTOSAVE.nwk` G1 | RGROUND/XGROUND = **730 / 0.1 Ω** |
| Prior PSAF `ONGOING.nwk` G1 | 9999 / 9999 Ω |
| Prior PSAF `Gener.DBF` diesel template | RGROUND/XGROUND = **730.000 / 0.100** |

**Explanation:** the form label is wrong — a 60 Ω HV resistance plus a 2.62 Ω secondary loading resistor across a 22/√3 : 500 V transformer is textbook high-resistance grounding, not low-reactance. And the `730 / 0.1 Ω` in the previous model is **proven** to be the shipped diesel library template value, byte-for-byte, never edited; `9999/9999` is a placeholder.
**Effect:** NON‑BLOCKING for balanced load flow (zero-sequence path carries no balanced current). Blocking later for single-line-to-ground faults.

---

## C6 — GSUT rating must remain three-valued
| Value | Cooling stage |
|---|---|
| 355 MVA | ONAN |
| 460 MVA | ODAN |
| **515 MVA** | ODAF — the impedance base |

**Explanation:** not a conflict; a single transformer with three cooling stages. Z = 16 % is expressed **on 515 MVA**, so any per-unit conversion must use 515 MVA, not 355 or 460. Recorded because collapsing this to one number is a common modelling error.
**Effect:** MATERIAL for base conversion — handled in `matlab/utilities/convert_to_system_base.m`.

---

## C7 — Auxiliary transformer LV winding 6.9 kV vs plant MV bus 6.6 kV
| Quantity | Value | Source |
|---|---|---|
| UAT 10BBT10 LV **winding rated voltage** | 6.9 kV | Rating plate p.1 |
| GAT 10BBT20 LV **winding rated voltage** | 6.9 kV | Rating plate p.3 |
| MV busbar 10BBA10 **nominal system voltage** | **6.6 kV** ±10 % | Rev 03 SLD p.2 Note 1 |
| Winding **U_m** (highest voltage for equipment) | 7.2 kV | Rating plates |

**Explanation:** three distinct concepts. The transformers are wound for 6.9 kV so that under load the 6.6 kV bus sits near nominal; 7.2 kV is an insulation class, not an operating voltage. The Excel workbook's own `13_VALIDATION_NOTES` reaches the same conclusion: *"B6_9 from prior workbook → Remove as a separate plant bus by default."*
**Effect:** MATERIAL — the **off-nominal turns ratio 22/6.9 into a 6.6 kV bus must be modelled explicitly** (22000/6900 with a 6600 V base), otherwise the MV bus voltage will be wrong by ~4.5 %. No separate 6.9 kV bus is created.

---

## C8 — Prior PSAF model used the wrong transformer in the UAT position
| Item | Prior model | Actual plant |
|---|---|---|
| Branch `T1` (B22G → B6_6) | library type `10/126_0500`: **500 MVA, 10/120 kV, D‑Y, Z = 1.92 %, X/R = 36** | UAT 10BBT10: **25 MVA, 22/6.9 kV, Dyn11, Z = 10.5 %** |
| Winding connection | Pcon = D, Scon = Y | Dyn11 (D on HV ✔, yn on LV ✔) |

**Explanation:** `txfix.DBF` contains no project-specific entry; `T1` references a generic 500 MVA step-**up** unit — a 20× rating error and a 1.92 % vs 10.5 % impedance error, in the branch that determines all auxiliary-system voltages.
**Effect:** invalidates the prior model's auxiliary results. Not a data conflict — a prior-model defect. See [`prior_psaf_model_defects.md`](prior_psaf_model_defects.md).

---

## C9 — GAT 10BBT20 exists in the plant but not in the prior model or the target sketch
| Source | GAT present? |
|---|---|
| Rev 03 main SLD (INEL‑…‑DE‑0001) | **Yes** — 230/6.9/3.32 kV, HV via SF₆ bus duct to 230 kV GIS |
| Rev 03 protection one-line (INEL‑…‑DE‑0023) | **Yes** |
| Rev 00 SLD | Yes (as 230/6.9/6.9 kV, Z = 14 %) |
| UAT/GAT rating plate + data sheet | **Yes** — released, serial 100580 |
| Prior PSAF `.nwk` / `twinding.DBF` | **No entry at all** |
| Target topology sketch in the brief | **No** |

**Explanation:** GAT is a real, released, installed transformer that feeds the 6.6 kV MV bus **from the 230 kV GIS**. With both UAT and GAT closed, the 6.6 kV bus has two sources and the network contains a **loop** (22 kV → GSUT → 230 kV GIS → GAT → 6.6 kV → UAT → 22 kV). Plant practice for a start-up/standby transformer of this kind is usually one source in service at a time, but **no South document states the normal switching state.**
**Effect:** **BLOCKING** — a topology decision. See question **Q4**.

---

## C10 — GAT tap table OCR check
`pdftotext` rendered tap position 14 as "227275 V". The printed rated current for that position is 63.5 A, and 25 MVA/(√3·227125) = 63.55 A whereas 25 MVA/(√3·227275) = 63.51 A; the tap ladder from 230000 in 1.25 % steps of 2875 V gives 230000 − 2875 = **227125 V**. The true value is 227125 V; "227275" is an OCR digit swap. **NON‑BLOCKING** (position 13 is the principal tap).

---

## C11 — Station auxiliary demand: three coincident numbers
| Source | Value | Quantity |
|---|---|---|
| Google Form p.2 | **14 MW at pf 0.85** | "Station Auxiliary Demand" |
| Google Form p.2 (same block) | 12–15 MW | stated baseline band |
| Rev 03 SLD MV MOTOR TABLE | **14 050 kW** | sum of 12 motor **nameplate ratings** |

**Explanation:** 14 MW sits inside the form's own 12–15 MW baseline band **and** coincides with the rated motor sum to within 0.4 %. So it is not possible to tell from the documents whether 14 MW is (a) a measured/estimated operating demand, or (b) the rated motor sum rounded, or (c) a generic baseline. All three readings give the same number, which makes it usable, but its **provenance is ambiguous** and it must not be labelled a measured operating point. Rated shaft kW ≠ electrical demand (efficiency and pf are missing).
**Effect:** **BLOCKING** in the sense that the load model must be agreed — one aggregate 14 MW/8.676 MVAr at 6.6 kV, or a per-motor build-up. No LV (400 V) breakdown exists at all. See question **Q6**.

---

## C12 — Prior PSAF bus list contains orphans and junk
`B230_2`, `BGRID230`, all 400 V buses and both water-intake buses are **orphaned** (no branch connects them). The bus list also contains `B0`, `B1` and a malformed `0.00000` row. `B400_EU` carries an anomalous VoltSol = 1.1 pu / Angle = 1°.
**Effect:** prior-model defect, not a data conflict. The new bus list is rebuilt from the Rev 03 drawing.

---

## C13 — Google Form 400 kV block
CT 1600/1, PT 400000/110 V, R₀ 0.06667 Ω/km, X₀ 0.39472 Ω/km, B₁ 3.4011 µS/km, 70 km, fault capacity / Z₁ / Z₀ = "Contact PGCB".
**Explanation:** the South plant tops out at **230 kV**. A 400 kV GIS and 400/230 kV Hyosung interbus transformers belong to the Ashuganj **North** unit (UTS project 7485), whose drawings were in the same source ZIP. User confirmed 2026‑08‑17: *"we are modeling only south part not north."*
**Effect:** **excluded from scope.** No 400 kV level will be built. Note also that R₁/X₁ are blank even in that block, and the proposal's "~75 km from Dhaka" is a **geographic** distance that must not be confused with the 70 km line length.

---

## C14 — Grid short-circuit strength: three different quantities
| Source | Value | What it actually is |
|---|---|---|
| Siemens Generator Data p.2 | S_k″ 19 919 MVA / I_k″ 50 kA / X_N 2.66 Ω | labelled **estimated**; numerically = √3·230·50, i.e. the **GIS rated withstand** |
| GSUT rating plate | "Max. system short-circuit power HV/LV 21 218 / 3950 MVA" | transformer **design withstand**, not grid strength |
| Google Form | "Contact PGCB" | not supplied |

**Explanation:** three different concepts, all preserved. Neither withstand rating is a measured grid S_k″. Grid **R** (or X/R) is missing entirely, so even the estimated value cannot form a complete Thevenin equivalent without an assumption.
**Effect:** **BLOCKING** — the slack source needs a defined impedance. See question **Q1**.

---

## C15 — Minor documentation discrepancies (all NON‑BLOCKING)
| Item | Value A | Value B |
|---|---|---|
| GSUT protection CT ratio | 1500/1 (Data Sheet) | **1600/1** (rating plate + Rev 03) |
| GSUT LV CT | 13515/2 (Rev 03 dwg) | 13515/5 (rating plate, ITM509 core) |
| GSUT OLTC designation | VRF I 1601‑123 (Data Sheet) | VACUTAP 3×VRF I 1601Y‑72.6/C (rating plate) |
| UAT oil volume | ~8000 L (Data Sheet) | 5720 L (rating plate) |
| UAT total mass | ~36 t (Data Sheet) | 38.1 t (rating plate) |
| UAT max system SC | 157 kA / 31.5 kA (Data Sheet) | 6600 / 500 MVA (rating plate) |
| GSUT cooling motor power | 28 kW (Data Sheet) | 4×1.4 + 18×2.2 = 45.2 kW installed (rating plate) |

Typical datasheet-vs-as-built drift. The rating plate is the as-built record. None of these affect load flow.

---

## C16 — Excel workbook carries Rev 00 values while citing the Rev 03 drawing
`06_AUX_TRANSFORMERS` marks every row "CONFIRMED" and cites "Main Electrical SLD p.2", but:

| Item | Excel value (= Rev 00) | Rev 03 SLD value |
|---|---|---|
| 10BFT10 / 10BFT20 impedance | 6 % | **10.75 %** |
| Excitation transformer | 6.6/**2.5** kV, **3550** kVA | 6.6/**0.66** kV, **3560** kVA |
| SFC transformer | 6.6/**2.5** kV | 6.6/**2.0** kV |
| Control transformers | 40 kVA | **30 kVA** (tags 10BTL10/20/30/40) |
| 10BFT30 / 00BFT10 group | Dyn**1** | Dyn**11** |
| Lighting transformers | 100 kVA (00BLA10 only) | 10BLA10/10BLA20 **400 kVA** + 00BLA10 100 kVA |
| Tag naming | 10MKC01 (exc.), 10MBJ01 (SFC) | 10BMV10 (SFC) |

Also from Rev 00 vs Rev 03 more broadly: UAT 18/21 MVA Z = 8 % @21 MVA → **19/25 MVA Z = 10.5 % @25 MVA**; GAT 230/**6.9/6.9** kV 21/25 MVA Z = **14 %** → **230/6.9/3.32 kV 19/25 MVA Z = 12 %**; GCB 12 kA → **12.4 kA**; MV busbar 2500 A → **3150 A**; water-intake busbars 630 A → **1250 A**; LV boards 40 kA → **50 kA**; SFC 2500 V/3100 kVA/Z 6.1 % → 2000 V/3400 kVA/Z 4.7 %.

**Explanation:** Rev 00 contamination in a rank‑5 derived tabulation. This is exactly why the brief places original documents above the workbook. The workbook also omits the Rev 03 MV MOTOR TABLE, which is the only per-load data in the entire project.
**Effect:** NON‑BLOCKING for load flow, but the workbook must **not** be used as the primary source for any LV parameter.

---

## C17 — GAT three-winding impedances incomplete
Only **Z_PS = 12 %** on 25 MVA is documented. A three-winding transformer requires **Z_PS, Z_PT, Z_ST** to build the star equivalent (Z_P, Z_S, Z_T). Z_PT and Z_ST are **MISSING** from the data sheet and the rating plate.
**Effect:** **BLOCKING only if GAT is modelled as a three-winding unit.** The tertiary is a *stabilizing* delta with no external load, so a two-winding 230/6.9 kV representation at Z = 12 % is defensible — but that is a modelling choice that needs approval. See question **Q5**.

---

## C18 — Prior PSAF studies were configured at the wrong frequency
Both `AUTOSAVE.STU` and `psaf export (1)/psaf export/ongoing.stu` carry `PARAMETERS // Version, Base Power, Freq, Sub Title` → **`125, 100, 60, UNTITLED`**.
**Frequency = 60 Hz on a plant every South document states as 50 Hz.** Base power = 100 MVA.
**Effect:** invalidates any reactance-dependent result from the prior model. The new model will be 50 Hz. System base MVA still needs confirmation — see question **Q11**.
