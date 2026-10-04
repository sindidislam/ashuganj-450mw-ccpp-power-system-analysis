# Load-Flow Readiness — Ashuganj 450 MW CCPP (South)

> ## HISTORICAL — this is the readiness assessment made *before* Q1–Q11 were answered
>
> It records the state of the data audit at the point the eleven blocking questions
> were put, and it is kept unchanged for that reason: it is the evidence that the
> model was not built until the audit was finished. **Its verdict and its statement
> about assumptions are both out of date.** The questions were answered, five
> assumptions were approved, and all four cases have since been solved. For the
> current position read `docs/manual/PROJECT_UPDATE.html` (§9 lists every
> assumption and what it is worth in the answers). The one paragraph that had
> become factually wrong — the claim that the assumptions folder is empty — has
> been corrected in place below rather than left to mislead; nothing else in this
> file has been touched.

**Verdict at the time of writing: NOT READY.** Nineteen parameters are missing and blocking, reducible to **eleven decisions** (Q1–Q11). Everything else needed for a balanced steady-state load flow is verified.

---

## Environment — READY ✔ (Phase 8 complete)

| Item | Result |
|---|---|
| MATLAB | **R2024a (24.1.0.2537033)**, PCWIN64 |
| Simulink | 24.1 |
| Simscape | 24.1 |
| **Simscape Electrical** | **24.1** ✔ |
| Simulink Fault Analyzer | 24.1 (available for the later fault phase) |
| Licences | `Simulink` = 1, **`Power_System_Blocks` = 1**, `Simscape` = 1 |
| `powergui` on path | yes |
| **`power_loadflow` on path** | **yes** ✔ |
| Specialized library root | `C:\Program Files\MATLAB\R2024a\toolbox\physmod\powersys\powersys` |

**Toolchain decision:** **Specialized Power Systems (`powerlib`)** — `powergui` + `power_loadflow`, phasor/load-flow mode, 50 Hz. This is the correct library for a utility-scale positive-sequence load flow in R2024a and it is fully licensed. No obsolete blocks will be used.

---

## Data readiness by component

| Component | Ready? | What is missing |
|---|---|---|
| **Generator G1 (electrical ratings)** | ✔ | — 458 MVA, 22 kV, pf 0.85, x_d/x_d′/x_d″ all verified |
| **Generator dispatch** | ✘ | P setpoint (**Q2**), |V| setpoint (**Q2**), Q limits (**Q3**) |
| **GSUT 10BAT10** | ✔ | — ratio, MVA (×3 stages), Z 16 %@515 MVA, R, Z₀, 25-tap table all verified. Only the *in-service cooling stage* (**Q11**) and *tap in service* (**Q8**) undecided |
| **UAT 10BBT10** | ✔ | — 22/6.9 kV, 19/25 MVA, Z 10.5 %@25 MVA verified. Tap in service (**Q8**) |
| **GAT 10BBT20** | ◑ | Z_PT and Z_ST (**Q5**); and whether it is in service at all (**Q4**) |
| **230 kV GIS** | ◑ | Bus coupler state (**Q9**), per-bay busbar selection (**Q10**). Ratings all verified |
| **Buses** | ✔ | — all 11 plant buses identified with nominal voltage, rated current, I_sc. Only the 230 kV voltage tolerance is undocumented (**Q8** side note) |
| **Outgoing 230 kV line** | ✘ | R₁, X₁, length, identity, circuit count — **all missing** (**Q7**) |
| **In-station links** (XLPE cable, SF₆ duct, MV feeders) | ◑ | No impedance data; proposed as zero-impedance connections, stated in results |
| **External grid** | ✘ | R or X/R (**Q1**); and whether the estimated S_k″ = 19 919 MVA should be used at all (**Q1**) |
| **Loads** | ✘ | Only one aggregate 14 MW @ 0.85 pf; no per-bus split, no LV loads, no motor pf/efficiency (**Q6**) |
| **Shunt compensation** | ✔ (none) | No shunt appears in any document, and the prior PSAF model has no shunt section. Modelled as none |
| **Study bases** | ✘ | System base MVA (**Q11**). Frequency = **50 Hz**, verified from every South document |

---

## The nineteen blocking items, mapped to eleven questions

| Question | Blocking items resolved |
|---|---|
| **Q1** — grid representation and impedance | M‑B1, M‑B2 |
| **Q2** — generator dispatch P and voltage/Q setpoint | M‑B3, M‑B4 |
| **Q3** — generator Q limits | M‑B5 |
| **Q4** — GAT in service or standby | M‑B10 |
| **Q5** — GAT three-winding vs two-winding representation | M‑B11 |
| **Q6** — load model | M‑B12, M‑B13, M‑B14 |
| **Q7** — outgoing line: omit or supply R₁/X₁ | M‑B6, M‑B7 |
| **Q8** — tap positions in service | M‑B15 |
| **Q9** — GIS bus coupler state | M‑B16 |
| **Q10** — per-bay busbar selection | M‑B17 |
| **Q11** — system base MVA and GSUT cooling stage | M‑B18, M‑B19 |

Full detail in [`missing_parameters.md`](missing_parameters.md).

In-station link impedances (M‑B8, M‑B9) are listed as blocking in the strict sense that no value exists, but they are resolved by the *stated* zero-impedance treatment rather than by a decision — a short in-station XLPE cable and SF₆ duct are genuinely negligible against a 16 % / 12 % transformer, and that will be written into the report rather than papered over with a per-km value from a textbook.

---

## What is already fully ready to build

The following are complete, cross-corroborated and require no further input:

1. **Network graph** (11 plant buses + 1 modelled grid node; 3 impedance-bearing transformer branches) — [`../model/network_topology.md`](../model/network_topology.md)
2. **Generator electrical data** — 458 MVA, 22 kV ±5 %, pf 0.85, 2 poles, 50 Hz, x_d 166.3 %, x_d′ 28.65 %, x_d″ 22.48 %
3. **GSUT** — 230/22 kV YNd1, 355/460/515 MVA, Z 16 % / R 0.21 % / Z₀ 15.8 % on 515 MVA, X/R 76.2, full 25-position tap table
4. **UAT** — 22/6.9 kV Dyn11, 19/25 MVA, Z 10.5 % / R 0.4 % on 25 MVA, X/R 26.2, 5-tap table
5. **GAT** — 230/6.9/3.32 kV YNyn0+d11, 19/25 MVA (25/25/8.33), Z_PS 12 % / R 0.5 % on 25 MVA, X/R 24.0, 25-position tap table
6. **Bus nominal voltages, rated currents, short-circuit ratings and voltage tolerances** (except 230 kV tolerance)
7. **MV motor schedule** — 12 motors, KKS tags, rated kW, feeder CB ratings
8. **Auxiliary transformer inventory** — 11 units with ratios, ratings, groups, impedances
9. **50 Hz** system frequency
10. **Base-conversion arithmetic** — verified by hand for every nameplate figure quoted

---

## Validation checks already performed and passed

| Check | Result |
|---|---|
| Generator: 458 × 0.85 = 389.3 MW | ✔ matches Siemens P_N |
| Generator: 458e6/(√3 × 22e3) = 12019.2 A | ✔ matches nameplate I_N 12019 A |
| GSUT: 515/(√3 × 230) = 1292.8 A | ✔ matches nameplate |
| GSUT: 515/(√3 × 22) = 13515.3 A | ✔ matches nameplate |
| GSUT: 460/(√3 × 230) = 1154.7 A · 355/(√3 × 230) = 891.1 A | ✔ both match |
| GSUT tap span: 253000/230000 = 1.10 · 184000/230000 = 0.80 → 25 pos at 1.25 %/step | ✔ exact |
| GSUT: X/R from Z 16 % and R 0.21 % = 76.19 | ✔ matches prior `txvar.DBF` 76.200 |
| UAT: 25e6/(√3 × 6900) = 2091.8 A | ✔ matches nameplate |
| GAT tap span: 264500/230000 = 1.15 · 195500/230000 = 0.85 → 25 pos at 1.25 %/step | ✔ exact |
| GAT: 25e6/(√3 × 230e3) = 62.75 A | ✔ matches nameplate 62.8 A |
| GAT tertiary: √3 × 3320 × 1448.6 = 8.33 MVA | ✔ matches winding rating |
| Grid triple: √3 × 230 × 50 = 19 918.6 MVA · 230²/19 919 = 2.656 Ω | ✔ internally consistent — and all three derive from I_k″ = 50 kA = the GIS withstand rating |
| Aux load: 14/0.85 = 16.4706 MVA · × sin(acos 0.85) = 8.6764 MVAr | ✔ matches Excel `08_LOADS_PSAF` |
| MV motor table sum: 9050 + 2500 + 2500 | ✔ = 14 050 kW ≈ the form's 14 MW |
| GAT tap 14 OCR "227275 V" vs printed 63.5 A | ✘ caught — true value 227125 V |

---

## Explicit statement on assumptions

**Corrected 2026-08-21.** The sentence that stood here — *"No assumption has been
made, and `matlab/data/assumptions/` is empty"* — was true when this assessment was
written and is no longer true. It was written before the eleven questions were
answered. That folder now holds five files, and they are not all the same kind of
thing:

| File | What it assumes | Standing |
|---|---|---|
| `grid_series_resistance_zero.m` | the grid equivalent's resistance, taken as zero | **active** — registered in `D.assumptions` |
| `aux_load_allocation_split.m` | how the 14 MW auxiliary demand splits across the three 6.6 kV boards | **active** — registered in `D.assumptions` |
| `gis_bus_coupler_closed.m` | the 230 kV bus coupler is closed in the normal state | **active** — registered in `D.assumptions` |
| `generator_voltage_setpoint.m` | the generator terminal voltage set-point, 1.00 pu | **disclosed, not approved** — not registered in `D.assumptions`; the value the model uses comes from `D.gen(1).Vset_pu` |
| `transformer_magnetising_inductance.m` | the magnetising branch of each transformer | **superseded** — registered under `D.superseded`, enters nothing into the model, retained as audit trail |

They are kept in that folder and **not** in `matlab/data/`, so no assumed number can
be read as plant data. What each is worth in the answers is §9 of
`docs/manual/PROJECT_UPDATE.html`.

The generator set-point is the one to be aware of when reading any voltage in this
study: it is the datum every other voltage is measured against, and it is an
assumption rather than an operating record.

The principle the paragraph below stated has held throughout, and still holds:

> The solver will **not** be helped to converge by inventing data. If a decision produces a non-convergent or physically odd case, that will be reported as such.

Nothing was filled in to make a case solve. All four cases converge in two
iterations on the parameters as documented.
