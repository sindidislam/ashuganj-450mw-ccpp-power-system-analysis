# Load List — Ashuganj 450 MW CCPP (South)

The project contains exactly **two** load statements, and they are not the same kind of quantity.

---

## Statement 1 — aggregate station auxiliary demand

| Parameter | Value | Source | Status |
|---|---|---|---|
| Active power P | **14 MW** | `Google Sheet Form_Filled Up By APSCL.pdf` p.2 | VERIFIED_PROJECT_DATA (Medium confidence) |
| Power factor | **0.85** | same | VERIFIED_PROJECT_DATA (Medium confidence) |
| Reactive power Q | **8.676 MVAr** | 14 × tan(acos 0.85) | DERIVED_FROM_VERIFIED_DATA |
| Apparent power S | **16.471 MVA** | 14 / 0.85 | DERIVED_FROM_VERIFIED_DATA |
| Location | "MV BUSBAR" (i.e. `B6_6` / 10BBA10) | Excel `08_LOADS_PSAF` | derived attribution |

The same form block also states a **12–15 MW baseline band**, inside which 14 MW sits.

Excel `08_LOADS_PSAF` records exactly this: `LD_AUX`, P = 14, Q = 8.676420737643433, MVA = 16.470588235294116, PF 0.85, "CONFIRMED P/PF; Q/MVA derived". Arithmetic re-verified: 14/0.85 = 16.4706 ✔ and 16.4706 × sin(acos 0.85) = 8.6764 ✔.

---

## Statement 2 — MV motor schedule (**rated** shaft powers, Rev 03 SLD p.2)

| KKS tag | Service | Bus | Rated kW | Feeder CB |
|---|---|---|---|---|
| 10LAC71AP001 | HP/IP boiler feedwater pump 1 | `B6_6` (10BBA10) | 2265 | 1250 A |
| 10LAC72AP001 | HP/IP boiler feedwater pump 2 | `B6_6` | 2265 | 1250 A |
| 10LCB11AP001 | Condensate pump 1 | `B6_6` | 770 | 1250 A |
| 10LCB12AP001 | Condensate pump 2 | `B6_6` | 770 | 1250 A |
| 10EKH10AN001 | Gas booster compressor 1 | `B6_6` | 1210 | 1250 A |
| 10EKH10AN002 | Gas booster compressor 2 | `B6_6` | 1210 | 1250 A |
| 10PGC1SAP001 | Closed-circuit cooling water pump 1 | `B6_6` | 280 | 1250 A |
| 10PGC20AP001 | Closed-circuit cooling water pump 2 | `B6_6` | 280 | 1250 A |
| | **subtotal `B6_6`** | | **9 050** | |
| 00PAC10AP001 | Circulating water pump 1 | `B6_6_WI1` (10BBW10) | 2220 | — |
| 10PCC10AP001 | Open-circuit cooling water pump 1 | `B6_6_WI1` | 280 | — |
| | **subtotal `B6_6_WI1`** | | **2 500** | |
| 00PAC20AP001 | Circulating water pump 2 | `B6_6_WI2` (10BBW20) | 2220 | — |
| 10PCC20AP001 | Open-circuit cooling water pump 2 | `B6_6_WI2` | 280 | — |
| | **subtotal `B6_6_WI2`** | | **2 500** | |
| | **TOTAL** | | **14 050 kW** | |

**These are nameplate shaft ratings.** Converting them to electrical bus demand needs each motor's **efficiency** and **power factor**, neither of which is given anywhere. It also needs the **running/standby split**: eight of these twelve motors are in obvious 1+1 duty/standby pairs (BFW 1/2, condensate 1/2, gas booster 1/2, CCCW 1/2, CW 1/2, OCCW 1/2). If half of each pair were standby, the running rated total would be ~7 025 kW, not 14 050 kW.

---

## The coincidence that must not be over-read

14 MW (form) and 14 050 kW (rated motor sum) agree to within 0.4 %, **and** 14 MW also sits inside the form's own stated 12–15 MW baseline band. So the documents cannot distinguish between:

- (a) 14 MW is a measured/estimated operating demand;
- (b) 14 MW is the rated motor sum, rounded;
- (c) 14 MW is a generic baseline figure the form pre-populated.

The number is usable, but it must **not** be reported as a measured operating point. See [`../validation/conflicting_parameters.md`](../validation/conflicting_parameters.md) **C11**.

---

## What is MISSING

| Item | Status |
|---|---|
| Per-bus load allocation between `B6_6`, `B6_6_WI1`, `B6_6_WI2` | **MISSING** — the 14 MW is a single aggregate |
| **All 400 V loads** (`B400_UA1`, `B400_UA2`, `B400_ST`, `B400_EU`, `B400_WI`) | **MISSING** — no source gives any LV load |
| Motor efficiency and power factor (per motor) | **MISSING** |
| Motor running vs standby status | **MISSING** |
| LV switchgear motors (75 < P ≤ 200 kW) | **MISSING** — Excel `09_MOTORS_PSAF` marks PARTIAL, all fields blank |
| LV MCC motors (P ≤ 75 kW) | **MISSING** — Excel `09_MOTORS_PSAF` PARTIAL |
| SFC / excitation transformer loading | **MISSING** (both are intermittent/auxiliary duty anyway) |
| Lighting and small-power loads | **MISSING** |
| Any reactive compensation / shunt | **MISSING** — the prior PSAF model has no shunt section either |

Excel `09_MOTORS_PSAF` confirms the only motor datum it holds is **GSUT cooling fans, 0.4 kV, 0.25 kW per fan** (from GSUT Data Sheet p.5). The workbook **omits the Rev 03 MV MOTOR TABLE entirely** — that table, found in the drawing, is the only per-load data in the whole project.

The documents that would fix this are **INEL‑112070‑00‑ELC‑DE‑0009** (MV one-line) and **INEL‑112070‑00‑ELC‑DE‑0010** (LV one-line), both cited by the Rev 03 drawing and both **absent**.

---

## Load model options (decision required — question Q6)

| Option | What it means | Consequence |
|---|---|---|
| **A** | One aggregate PQ load, 14 MW + 8.676 MVAr, at `B6_6` | Simplest; matches the only stated demand figure. `B6_6_WI1`, `B6_6_WI2` and all 400 V buses carry **zero** load — they appear in the model but flow nothing |
| **B** | Split the 14 MW across `B6_6` / `B6_6_WI1` / `B6_6_WI2` in proportion to the rated motor subtotals (9050 : 2500 : 2500 = 64.4 % : 17.8 % : 17.8 %) → 9.02 / 2.49 / 2.49 MW | More realistic branch loadings on the water-intake feeders. The proportion is **derived from verified rated kW**, but the allocation itself is an **ENGINEERING_ASSUMPTION** requiring your written approval |
| **C** | Model all 12 motors individually at their rated kW with an assumed efficiency and pf | Needs **two invented numbers per motor**. Not recommended — it would put assumptions at the core of the result |

**Nothing will be applied until you choose.** No load-model option has been implemented; no assumption file has been written, because no assumption has been approved.
