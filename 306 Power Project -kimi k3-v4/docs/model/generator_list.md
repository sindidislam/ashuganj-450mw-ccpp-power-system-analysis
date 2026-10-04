# Generator List — Ashuganj 450 MW CCPP (South)

**One generator.** The plant is a Siemens single-shaft combined-cycle package **SCC5‑PAC 4000F/3000 (1S)** — an SGT5‑4000F gas turbine and an SST‑3000 steam turbine on a single shaft driving one generator. The proposal's phrase "SGen5‑2000H generatorS" is loose wording; the released nameplate and both Rev 03 drawings show exactly one machine, serial 12783.

---

## G1 — Siemens SGen5‑2000H

| Parameter | Value | Unit | Source | Status |
|---|---|---|---|---|
| Bus | `B22G` (22 kV) | — | Rev 03 SLD p.2 | VERIFIED_ENGINEERING_DOCUMENT |
| Type / serial / year | SGen5‑2000H / 12783 / 2013 | — | Name plate p.2 | VERIFIED_PLANT |
| Standard | IEC (60034‑1) | — | Name plate p.2 | VERIFIED_PLANT |
| Rated apparent power S_N | **458** | MVA | Name plate p.2 | VERIFIED_PLANT |
| Max apparent power S_max | 518 | MVA | Generator Data p.1 (30 °C cold gas) | VERIFIED_ENGINEERING_DOCUMENT |
| Rated voltage U_N | **22** ±5 % | kV | Name plate p.2 | VERIFIED_PLANT |
| Rated current I_N | 12019 | A | Name plate p.2 | VERIFIED_PLANT |
| Max current I_max | 14309 | A | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| Rated power factor | 0.85 lagging | — | Name plate p.2 | VERIFIED_PLANT |
| Primary active-power capacity | **360** | MW | Verified workbook B3 | VERIFIED_PROJECT_DATA |
| PF-derived/OEM reference, NOT capacity | **389.30** | MW | 458 × 0.85; Generator Data p.1 | DERIVED_FROM_VERIFIED_DATA |
| Owner/site de-rated scenario | **342.01** | MW | Owner form; exact boundary QUALIFIED | VERIFIED_PROJECT_DATA |
| Frequency | 50 | Hz | Name plate p.2 | VERIFIED_PLANT |
| Speed | 3000 | rpm | Name plate p.2 | VERIFIED_PLANT |
| Poles | 2 | — | 120 × 50 / 3000 | DERIVED_FROM_VERIFIED_DATA |
| Rotation | counterclockwise; phase sequence U‑V‑W (EE end) | — | Name plate p.2 | VERIFIED_PLANT |
| Winding connection | **YY** (double star) | — | Name plate p.2 | VERIFIED_PLANT |
| Primary d-axis synchronous / transient / subtransient | 1.783 / 0.3256 / 0.2608 | pu | Workbook H3/I3/J3 | VERIFIED_PROJECT_DATA |
| Separate saturated d-axis subtransient | 0.2248 | pu | Workbook K3 | VERIFIED_PROJECT_DATA |
| Primary quadrature synchronous / transient / subtransient | 1.751 / 0.5087 / 0.2593 | pu | Workbook L3/M3/N3 | VERIFIED_PROJECT_DATA |
| Leakage / negative sequence / zero sequence | 0.2027 / 0.2242 / 0.128 | pu | Workbook O3/P3/Q3; P3/Q3 explicitly saturated | VERIFIED_PROJECT_DATA |
| Armature resistance, raw | 0.00089 | ohm | Workbook U3 explicitly states ohm | VERIFIED_PROJECT_DATA |
| Combined turbine-generator inertia / SCR | 5.287 s / 0.601 | mixed | Workbook F3/G3 | VERIFIED_PROJECT_DATA |
| Open-circuit time constants, d transient / d subtransient / q transient / q subtransient | 7.547 / 0.045 / 0.839 / 0.070 | s | Workbook Y3/Z3/AA3/AB3 | VERIFIED_PROJECT_DATA |
| Short-circuit time constants in the same order | 1.213 / 0.035 / 0.214 / 0.035 | s | Workbook AC3/AD3/AE3/AF3 | VERIFIED_PROJECT_DATA |
| Armature time constant, Ta or Ta(3) | 0.704 | s | Workbook AG3 | VERIFIED_PROJECT_DATA |
| Saturation at 1.0 / 1.2 pu | 0.0865 / 0.408 | dimensionless | Workbook AI3/AJ3 | VERIFIED_PROJECT_DATA |
| Excitation type / designation | Static / SEMIPOL | text | Workbook AS3/AT3 | VERIFIED_PROJECT_DATA |
| Field resistance numeric | 0.10631 | UNRESOLVED | Workbook V3 under mixed pu-or-ohm heading | QUALIFIED interpretation |
| LEGACY / SATURATED SOURCE DATA: d-axis set | 1.663 / 0.2865 / 0.2248 | pu | Generator Data p.1, explicit saturated labels | Retained, NOT primary |
| **Q_max** | — | MVAr | — | **MISSING** — see below |
| **Q_min** | — | MVAr | — | **MISSING** — see below |
| Field voltage / current (rated) | 406 V / 3088 A | — | Name plate p.2 | VERIFIED_PLANT |
| No-load excitation U_exc,0 | 122 | V | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| I_2max / I_N (continuous) | 7.64 | % | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| Negative-sequence K | 7.41 | s | Generator Data p.1 | VERIFIED_ENGINEERING_DOCUMENT |
| Cooling | Hydrogen, 5 bar(g); cold gas 50 °C; water inlet 40 °C | — | Name plate p.2 | VERIFIED_PLANT |
| Insulation / duty / IP | class F/F; S1; IP65 | — | Name plate p.2 | VERIFIED_PLANT |
| Mass | 394 000 | kg | Name plate p.2 | VERIFIED_PLANT |
| Site conditions | alt 5 m; amb 6 … 46.8 °C; max water 44 °C; stator water N/A | — | Name plate p.2 | VERIFIED_PLANT |
| Generator CT | 15000/1 A (T1, T2 cores 1‑3) | — | INEL‑…‑DE‑0023 Rev 03 | VERIFIED_ENGINEERING_DOCUMENT |
| Generator VT | 22/√3 : 0.100/√3 and 0.100/3 kV | — | INEL‑…‑DE‑0023 Rev 03 | VERIFIED_ENGINEERING_DOCUMENT |

**Consistency checks (all pass):** 458 × 0.85 = 389.3 MW ✔ · 458e6/(√3 × 22e3) = 12019.2 A ✔ · 518e6/(√3 × 22e3) = 13594 A (vs stated I_max 14309 A — I_max corresponds to the machine's short-time current capability rather than exactly S_max/√3V, recorded as documented, not adjusted).

---

## Ratings that are *not* dispatch

| Quantity | Value | What it is |
|---|---|---|
| 458 MVA | apparent-power rating | Machine rating at 50 °C cold gas |
| 360 MW | primary capacity | Workbook active-power capacity |
| 389.30 MW | PF-derived/OEM reference | 458 × 0.85; NOT primary capacity |
| 518 MVA | S_max | Machine capability at 30 °C cold gas |
| 450 MVA | Rev 00 SLD | **Preliminary**, superseded (Rev 00 Note 3) |
| 342.01 MW | Google Form | "Site De-rated Active Power" — a site/ambient figure, a **different quantity** |

**None of these is a measured operating point.** The 342.01 MW owner/site scenario has a qualified boundary: neither net export nor generator-terminal power is established by that label. Phase 1 leaves all four existing LF dispatch inputs untouched; it does not authorize new primary dispatch above 360 MW. Capacity enforcement belongs to separately authorized Phase 2.

## REV3.1 authoritative registry and base interpretation

The existing [`ashuganj_master_data.m`](../../matlab/data/ashuganj_master_data.m:9) consumes [`ashuganj_generators.m`](../../matlab/data/ashuganj_generators.m:1). Its primary workbook record and compatibility views are generated together; legacy data are explicitly separate. The source ledger is not a runtime input.

Source: [`Ahsuganj South (2).xlsx`](../../fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj%20South%20%282%29.xlsx), sheet **Ashuganj South** with one trailing space, row 3. SHA-256: 6D4286B9D0B771CEE80FB305F3C0AE7B9D34CC1EA8A3B8F2F022BA0D07240A60. Each supplied field retains cell, raw heading/value/unit, normalized value/unit, source status, confidence, base, designation and interpretation. Raw excitation trailing spaces are preserved.

Reactances are interpreted on 458 MVA / 22 kV; the workbook does not separately declare that base. Unqualified subtransient 0.2608 and saturated 0.2248 must never be merged. Negative/zero sequence source saturation qualifiers remain explicit.

| Derived quantity | Value |
|---|---:|
| Machine impedance base | 1.056768558951965 ohm |
| Machine-base armature resistance | 0.000842190082644628 pu |
| 100 MVA / 22 kV impedance base | 4.84 ohm |
| 100 MVA armature resistance | 0.000183884297520661 pu |
| Unqualified subtransient on 100 MVA | 0.0569432314410480 pu |
| Saturated subtransient on 100 MVA | 0.0490829694323144 pu |

Both resistance inverse conversions recover 0.00089 ohm. System-base views are derived once. Field resistance is not stator-base converted and has no invented field base. Detailed rotor parameters, Ta(1), damping, controller settings and a complete measured OCC remain unresolved. Data registration is not dynamic validation. Generator NER remains distinct from workbook GSUT solid grounding.

---

## Why Q limits are `MISSING`, not available

The only reactive figures in the project are:

1. Google Form "+241 MVAr" — this equals 458 × sin(acos 0.85) = **241.3 MVAr**, i.e. the **Q at the rated point**, not a capability limit. No Q_min is given.
2. Excel `04_GEN_Q_CAPABILITY` — a 7-point curve marked "DIGITIZED", cited to "Generator Protection Setting Report, Attachment 1 / p.42 of 44".

Chain of custody for (2): Excel ← prior PSAF `Gener.DBF` record `GEN1_DATAA` Q_CURVE ← report **p.42**, which is **not in the project** (only pp. 6‑7 are, as `Generator Data_South.pdf`). The DBF blob is also **truncated mid-record** (`{432.000000;152.000000` — the 6th point's Q_min and the whole 7th point are lost), and Q_min/Q_max is a near-constant ≈0.69 at every point, which a real capability curve does not do.

Separately, the QMAX/QMIN **scalars** in that same DBF record are **0.653 / −0.131 MVAr** — byte-identical to the shipped `1.3MW_4.2KV_DIESEL-GENERATOR` library template, never edited. See [`../validation/prior_psaf_model_defects.md`](../validation/prior_psaf_model_defects.md) D1–D2.

**Nothing will be entered for Q_max/Q_min without your instruction — question Q3.**

---

## Grounding

**NER 10BAB11**, high-resistance: 22/√3 : 500 V, 135 kVA / 20 s, R_HV‑DC 60 Ω, secondary loading resistor 2.62 Ω (Generator Data p.1 + Rev 03 SLD).

The Google Form's label "Low‑Reactance" is inconsistent with this equipment. The prior model's 730 Ω / 0.1 Ω is a proven library artefact. Not load-flow blocking (no balanced zero-sequence current); blocking later for single-line-to-ground faults.

---

## Emergency diesel generators (not load-flow sources)

10BUK01, 10BUK02 — 1000 kVA, cos φ 0.8, 400 V. Rev 03 **Note 4**: *"DISCONNECTOR SWITCH WILL REMAIN OPEN WHILE EDG IS SYNCHRONIZED WITH THE GRID"* → normally out of service. Excluded from the load flow unless you direct otherwise.
