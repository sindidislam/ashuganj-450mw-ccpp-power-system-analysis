# Assumptions Register — Ashuganj 450 MW CCPP (South)

## Status: **4 assumptions in use — 3 approved by the user, 1 DISCLOSED BUT NOT APPROVED**

This file was `EMPTY` through Phases 0–6, when nothing had been assumed. It is no longer empty. Every assumption now in the model is listed below with its approval state, and each has a machine-readable record in `matlab/data/assumptions/`.

The one **unapproved** entry is the important item on this page. It was introduced because the model could not be built without it, it is marked `Approved_by_user = false` in its own file, and it is surfaced here rather than buried. **It needs your decision.**

A fifth assumption, **A4**, has since been **RETIRED** — the datum it stood in for was found in the transformer datasheets. It is kept below under *Retired assumptions* rather than deleted, so the change is auditable.

| # | Assumption | File | Approved | Load-flow consequence |
|---|---|---|---|---|
| A1 | External grid series resistance **R = 0** (X/R = ∞) | `grid_series_resistance_zero.m` | ✅ Q1a | Grid losses zero; boundary voltage **pessimistic** by 0.16 %; **Qgen understated by up to 17 %** |
| A2 | Auxiliary load split **9050 : 2500 : 2500 kW** across the three 6.6 kV nodes | `aux_load_allocation_split.m` | ✅ Q6B | None on any solved voltage — the three nodes are one electrical node |
| A3 | 230 kV GIS bus coupler **closed** | `gis_bus_coupler_closed.m` | ✅ Q9a | Closes the GAT loop in LF2/LF4 → **UAT loaded to 109.60 % of its ONAN rating** |
| ~~A4~~ | ~~Transformer magnetising inductance **Lm = 1e6 pu**~~ | `transformer_magnetising_inductance.m` | **RETIRED 2026‑08‑19** | Superseded: L<sub>m</sub> is now `DERIVED_FROM_VERIFIED_DATA` from the datasheet excitation current |
| A5 | Generator voltage setpoint **V = 1.00 pu** at the 22 kV bus | `generator_voltage_setpoint.m` | ❌ **NOT APPROVED** | Sets the reference for **every voltage in the model**; all pu results are relative to it |

Statuses used elsewhere in the dataset remain: `VERIFIED_PLANT` · `VERIFIED_ENGINEERING_DOCUMENT` · `VERIFIED_PGCB` · `VERIFIED_PROJECT_DATA` · `DERIVED_FROM_VERIFIED_DATA` · `ESTIMATED` · `MISSING` · `CONFLICTING` · `NOT_APPLICABLE`. Only the four live parameters above carry `ENGINEERING_ASSUMPTION`.

---

## The assumption that is NOT approved

### ~~A4~~ — Transformer magnetising inductance — **RETIRED 2026‑08‑19, superseded by verified data**

> **This is no longer an assumption.** It is recorded here because it was one for part of the project's life, and because the measured bound published while it was live turned out to be **6.7× too pessimistic**. Deleting the entry would hide that.

**What was missing, and what closed it.** All three transformers document their **no-load LOSS** (GSUT 159 kW, UAT 14 kW, GAT 23 kW), so the iron-loss resistance R<sub>m</sub> was always *derived* — GSUT 3239.0 pu, UAT 1785.7 pu, GAT 1087.0 pu on their own ratings. What appeared to be absent was the **no-load CURRENT**, from which L<sub>m</sub> comes, so the magnetising branch was left numerically open at 1e6 pu. The datum was subsequently **found in the datasheets themselves**, under *"Excitation current — at 100 % of the rated voltage"*: **GSUT 0.13 %**, UAT ≈ 0.3 %, GAT 0.3 %.

L<sub>m</sub> is therefore now `DERIVED_FROM_VERIFIED_DATA`:

```
Lm(pu) = 1 / sqrt( I0^2 - (1/Rm)^2 )        I0 = datasheet excitation current at 100 % Un
```

giving **GSUT 791.9 pu**, **GAT 350.2 pu**. Note the subtraction in quadrature: the GAT's 350.2 pu is *larger* than the naive `1/I0 = 333.3 pu`, because the real component already accounted for by R<sub>m</sub> is removed rather than double-counted.

**Measured outcome of the correction: +0.5164 MVAr** on generator reactive output (magnetising Q rose 0.001 → 0.795 MVAr), i.e. **1.66 %** of the generator's 31.159 MVAr — and it moved the 6.6 kV bus by only −4.79e‑04 pu (0.0479 %), **27× less than conflict C13's 4.55 %**.

**Why the retirement matters more than the number.** The bound published while A4 was live was **+3.4406 MVAr**. The actual correction was **+0.5164 MVAr — 6.7× smaller**. The old bound was not wrong as arithmetic; it was evaluated at a 1 % magnetising current, which is **7.7× the GSUT's own documented 0.13 %**. A sensitivity probe swept over a physically implausible range produces an honest-looking bound that is nonetheless badly misleading. The historical sweep is retained below for exactly that reason.

**Historical bound (superseded).** `test_magnetising_sensitivity.m` closed L<sub>m</sub> to 500, 200 and 100 pu (≈0.2 %, 0.5 %, 1.0 % magnetising current) and re-solved:

| L<sub>m</sub> | Qgen (MVAr) | Loss (MW) | V 6.6 kV (pu) | V 230 kV (pu) |
|---|---|---|---|---|
| 1e6 (as built) | +31.1595 | 0.81612 | 1.0013903 | 0.998686 |
| 500 (~0.2 % I<sub>m</sub>) | +31.8476 | 0.81642 | 1.0010583 | 0.998663 |
| 200 (~0.5 % I<sub>m</sub>) | +32.8801 | 0.81688 | 1.0005606 | 0.998630 |
| 100 (~1.0 % I<sub>m</sub>) | +34.6000 | 0.81766 | 0.9997322 | 0.998574 |

- The omission **understates reactive absorption**, monotonically. Worst case **+3.4406 MVAr, 11.04 % of the 31.1595 MVAr the generator supplies** — and that is at a 1 % magnetising current, well above what units of this class would show.
- It barely touches anything else: real loss moves ≤ 0.00154 MW (the no-load *loss* is documented and already in the model), the 230 kV boundary ≤ 1.12e-04 pu, the 6.6 kV bus ≤ 1.66e-03 pu.
- **The 6.6 kV movement is 27× smaller than conflict C13**, which shifts that same bus voltage by 4.55 % depending on whether 6600 V or the 6.9 kV winding is taken as base. An unresolved *source conflict* dominates this *undocumented parameter* by more than an order of magnitude.

**What closed it:** the datasheet line *"Excitation current — at 100 % of the rated voltage"*, which was present in the transformer datasheets all along. The lesson recorded for the rest of the project: **before logging an assumption, re-read the datasheet for the datum under a different name.** "No-load current" was absent; "excitation current" was not.

### A5 — Generator voltage setpoint, 1.00 pu at the 22 kV bus

**What is missing.** No document states the AVR setpoint, the voltage schedule, or a measured operating voltage. The generator is a PV bus, so the load flow *requires* a magnitude.

**Why it cannot be bounded the way A4 can.** A4 has a physically narrow range. A5 does not: 1.00 pu is a *convention*, and 0.98 or 1.02 pu are equally defensible operating points. Every per-unit voltage reported in this study is measured **relative to this choice**, so it is not an error bar on a result — it is the datum the results are expressed against. The 22 kV bus reads exactly 1.000000 pu in all four cases **because it was set to**, not because it was solved.

**What would close it:** the AVR setpoint, a voltage schedule, or one measured 22 kV reading.

---

## The three approved assumptions

### A1 — Grid R = 0 (approved Q1a)

Your stated reason: *"We don't have verified PGCB grid strength. Use the available 2.656 Ω only as an explicitly labelled estimate, not as verified data."*

**This record previously stated three consequences that measurement disproved.** They are corrected here, and the wrong wording is quoted rather than deleted so the correction is auditable. `test_grid_sensitivity.m` Part 2 holds |Z| at the documented 2.6558 Ω and sweeps only the R/X split (X/R = ∞, 20, 10, 5):

| Claim as written | Measured | Verdict |
|---|---|---|
| Grid losses zero → reported loss is plant loss only | 0 → 0.3535 → **0.7040** → 1.3862 MW | **True, but understated.** At X/R = 10 the grid equivalent would dissipate 0.704 MW — comparable to the plant's own 0.816 MW. R = 0 does not make a small change to "system loss"; it changes what the phrase *means* |
| "angle shift slightly **overstated**" | +1.0787 → +1.0801 → +1.0795 → +1.0729° — spread **0.0072°**, non-monotonic | **WRONG.** The angle is *invariant*. Holding \|Z\| pins X to within 2 %, so the R/X split has almost nothing to move |
| "magnitude drop slightly **understated**" | 0.998686 → 0.999497 → **1.000304** → 1.001889 pu | **WRONG, AND BACKWARDS.** The boundary voltage *rises*. R = 0 **overstates** the sag — the model is pessimistic, not optimistic. A reader trusting the old wording would have corrected in the wrong direction |
| "**NO** effect on generator output" | Qgen +31.1595 → +28.5344 → **+25.9209** → +20.7928 MVAr | **WRONG for MVAr** (−16.81 % at X/R = 10, −33.27 % at X/R = 5). True for MW: 389.30 MW is a dispatch setpoint, spread 4.33e-08 MW |
| No effect on plant-internal voltages or loadings | 22 kV to 1e-6 pu; 6.6 kV spread 3.71e-08 pu; UAT loading spread 1.34e-04 MVA | **True.** The only claim that survived intact |

**The most consequential finding is a comparison.** Moving X/R from ∞ to 10 shifts the boundary voltage **1.62e-03 pu**; *doubling* the estimated |Z| shifts it only **1.27e-03 pu**. The number that is merely **assumed** matters *more* than the acknowledged-weakest **estimated** number. Mechanism: this plant delivers **+3.745 pu of P against −0.297 pu of Q** at the boundary, a ratio of 12.6 : 1, so R·P dominates X·Q and the usual mostly-reactive transmission intuition inverts. Hand check: R = 0.2643 Ω = 4.995e-04 pu on the 529 Ω base × 3.738 pu = **+1.867e-03 pu**, right sign, slightly above the measured 1.619e-03 pu rise, the balance being the smaller X·Q term moving the other way.

**Therefore the report must flag BOTH grid numbers as limiting.** Flagging the 2.6558 Ω estimate alone — which the earlier version of this record and of the test concluded — understates the uncertainty at the plant boundary.

> The wrong claims were not found by re-reading the prose. They were found because the test asserted the record **literally** and six assertions failed. Thresholds were not loosened; the claims were rewritten to state what was measured.

#### Why the "assume an IEEE-standard X/R" instruction was NOT applied here — 2026‑08‑20

You asked that missing R/X values be filled with IEEE-standard assumptions, with web lookups permitted. **For the external grid that instruction was deliberately not carried out**, for three reasons, and the decision is flagged for you rather than taken silently:

1. **It is not a missing value — it is an approved decision.** You approved `R = 0` as Q1a on 2026‑08‑17, with a stated reason. Overwriting an explicit approval with a textbook figure is precisely the substitution the project's integrity rules forbid. `ashuganj_grid.m:152` enforces it with `assert(G.R_ohm == 0)`.
2. **The change would be material, not cosmetic.** Measured, X/R = 10 adds **0.704 MW** of loss *inside the grid equivalent* — comparable to the plant's entire 0.816 MW — and cuts generator MVAr by **16.8 %**. The rules require asking before adopting a change of that size, and that loss is not a plant loss at all: it is dissipation in a Thévenin equivalent standing in for the whole PGCB network, which would corrupt the reported "system loss".
3. **The citation could not be verified in this session.** Web search returned `tool type 'web_search_20250305' is not supported for this model`, so no IEEE Std 399 table and no PGCB fault level could be retrieved and read. Writing *"X/R = 10 per IEEE Std 399"* on the strength of recollection would have put an unverifiable citation next to a fabricated number — the worst of both. **A caption that made exactly that claim was found on the diagram and has been corrected** (`build_ashuganj_main.m`, DATA STATUS block): it read *"R from an IEEE Std 399 X/R assumption"* while the dataset carried R = 0.

**What is in place instead.** The X/R sensitivity is already swept and published (X/R = ∞, 20, 10, 5) in `test_grid_sensitivity.m` Part 2, so a reader can read off the effect of any X/R without the model asserting one. **This is strictly more informative than picking a single value.**

**To adopt an IEEE figure, two things are needed from you:** approval to supersede Q1a, and a decision on whether grid-equivalent loss should be reported separately from plant loss (it must be, or "total loss" stops meaning anything).

### A2 — Auxiliary load split 9050 : 2500 : 2500 kW (approved Q6B)

Your qualifier: *"the allocation must be labelled an assumption."* It is, in `aux_load_allocation_split.m`, and in the `P_load_alloc_MW` / `Q_load_alloc_MVAr` columns of `bus_results.csv`, which are held **separate from every solver-output column** so allocated input and solved output can never be added together.

Allocated as 9.0178 / 2.4911 / 2.4911 MW (the documented kW ratio, scaled to the 14.000 MW total), plus 5.5887 / 1.5438 / 1.5438 MVAr.

**Consequence for the load flow: none.** The 6.6 kV feeder impedances to the two water-intake nodes are `MISSING` (treatment **S7**), so the three nodes are a **single electrical node** to the solver. The split changes which row of a table a number is printed on; it changes no solved quantity. It would become first-order the moment those feeder impedances were documented.

### A3 — 230 kV GIS bus coupler closed (approved Q9a)

Your qualifier: *"clearly label it as an assumption because the normal state wasn't found in the available document set."* The GIS arrangement, bay numbering (10BAY11/12/20), 3150 A busbar and 50 kA/1 s withstand **are** documented; only the normal coupler position is absent.

**This record also previously predicted the wrong mechanism.** It said the auxiliary load would divide between the UAT and the GAT according to their impedances. Measured, **the load does not divide at all**:

- Closing the coupler makes BUS 1 and BUS 2 one node, closing the loop 22 kV → UAT → 6.6 kV → GAT → 230 kV. The two paths have very different impedances, so their angles differ and a **circulating export flow** appears.
- In LF2 the 6.6 kV bus settles **1.72° ahead** of the 230 kV bus, and ≈5.9 MW of export **detours** through the UAT and GAT instead of the GSUT. The GAT *exports* from the auxiliary bus rather than feeding it.
- The UAT therefore carries the 14 MW auxiliary load **plus** that circulating 5.9 MW. Opposing signs on `P_LV` make it explicit: UAT −19.9047 MW against GAT +5.9051 MW, differing by the 14.000 MW load to within the KCL residual.
- **UAT loading rises from 91.09 % to 109.60 % of its 19 MVA ONAN rating (LF1→LF2), and 91.09 % → 101.50 % (LF3→LF4).** Both looped cases exceed the natural-cooling rating. Against the 25 MVA ONAF stage the worst case is 83.30 %. *(These figures are from the current run, after the A4 retirement re-derived L<sub>m</sub>; an earlier version of this record quoted 90.64 / 109.50 / 90.65 / 101.39 / 83.22 %, taken from a run with the magnetising branch open.)*
- Confirmed independently on the GSUT: HV throughput falls 374.486 → 368.596 MW, a 5.890 MW reduction matching the 5.871 MW arriving via the GAT. Total export is essentially unchanged (374.484 → 374.467 MW); only routing and losses move, the detour costing about **17 kW**.

**Operational caveat, recorded not acted on.** Paralleling the UAT and GAT onto one 6.6 kV bus from different sources is normally an **interlocked transfer** condition — momentary, during changeover — not a steady state, precisely because it parallels two sources through the auxiliary system. The measured overload is consistent with that reading. The source set contains no interlock schedule, so LF2 and LF4 are solved and reported exactly as approved answer **Q4c** specifies, and this is flagged rather than used as grounds to drop them. If an interlock schedule is later found and forbids the parallel, LF2/LF4 become transfer-*transient* cases and must be described as such.

---

## Structural treatments applied (not parameter assumptions)

Unchanged from Phase 6. These are modelling *structure* decisions taken from the source documents, not invented numbers. Each is stated in the load-flow report.

| # | Treatment | Documentary basis |
|---|---|---|
| S1 | **System frequency = 50 Hz** | Every South document (generator nameplate, both Rev 03 drawings, GIS data sheet, all rating plates). The prior PSAF study's 60 Hz is a defect, not a data source |
| S2 | **No 400 kV level, no 400 kV data** | South plant tops out at 230 kV; the 400 kV GIS and 400/230 kV interbus transformers belong to Ashuganj North (UTS 7485). User confirmed 2026‑08‑17 |
| S3 | **No 6.9 kV bus created** | 6.9 kV is the UAT/GAT LV *winding rating*; the plant MV bus is 6.6 kV nominal (U_m 7.2 kV). Excel `13_VALIDATION_NOTES` independently states *"Remove as a separate plant bus by default"* |
| S4 | **Off-nominal 22000/6900 ratio modelled explicitly into a 6600 V base** | Follows from S3; the alternative would misplace the MV bus voltage by ~4.5 % |
| S5 | **EDG 10BUK01/10BUK02 out of service** | Rev 03 SLD **Note 4**: *"DISCONNECTOR SWITCH WILL REMAIN OPEN WHILE EDG IS SYNCHRONIZED WITH THE GRID"* |
| S6 | **No shunt compensation** | No shunt or capacitor bank appears on any drawing; the prior PSAF network file has no shunt section |
| S7 | **In-station links modelled at zero impedance** (GSUT HV XLPE cable, GAT HV SF₆ bus duct, 6.6 kV water-intake feeders) | No length or impedance is documented. Short in-station links are negligible against 16 % / 12 % transformer impedances. **Stated in the report; not replaced by a per-km textbook value.** Measured consequence: the solver merges the three 6.6 kV nodes into one |
| S8 | **Rev 03 treated as as-built where it differs from Rev 00** | Rev 00 carries its own **Note 3**: *"EQUIPMENT RATINGS ARE PRELIMINARY VALUES SUBJECTED TO THE ELECTRICAL CALCULATIONS AT PROJECT STAGE."* Two independent Rev 03 drawings agree with the released rating plates. Both values are preserved in `conflicting_parameters.md` |
| S9 | **Excel workbook not used as a primary source for any value** | It is a rank‑5 derived tabulation and demonstrably carries Rev 00 values while citing Rev 03 (conflict C16), and its Q-capability curve is transcribed from a truncated PSAF record citing an absent page (C4) |
| S10 | **Prior CYME PSAF model not used as a data source** | Six evidence-backed defects — see `prior_psaf_model_defects.md`. Only values independently corroborated by an original document are reused |
| S11 | **Initial bus voltages 1.0 pu / 0° are solver starting points only** | Excel `12_PSAF_BUS_FIELD_GUIDE` states this explicitly; `13_VALIDATION_NOTES` confirms no measured solved voltage was supplied. They are never reported as results — **except** the 22 kV PV magnitude, which is assumption **A5** and is reported as set, not as solved |

---

## How each candidate assumption was resolved

The Phase-6 report listed the places where an assumption *would* be needed. Every row is now closed. **Twelve of the sixteen needed no assumption at all** — they were resolved by verified data, by running comparative cases, or by reporting in absolute units.

| Would-be assumption | Q | Resolution | Assumed? |
|---|---|---|---|
| External grid X/R (or R) | Q1 | R = 0 exactly; X = 2.6558 Ω separately labelled `ESTIMATED` | **Yes — A1** |
| Generator dispatch P | Q2 | Both dispatches solved and compared: 389.30 MW `DERIVED`, 342.01 MW `VERIFIED_PROJECT_DATA` | No — comparative cases |
| Generator \|V\| setpoint | Q2 | 1.00 pu at the 22 kV bus | **Yes — A5, unapproved** |
| Generator Q_max / Q_min | Q3 | Run unconstrained, `Qlim_Status = NOT_APPLICABLE`; the PSAF diesel template values are a defect (D4), not data | No — limits reported as unverified |
| GAT service state | Q4 | Both states solved and compared (LF1/LF3 out, LF2/LF4 in) | No — comparative cases |
| GAT Z_PT, Z_ST | Q5 | Documented two-winding Z_PS = 12 % @ 25 MVA; unloaded stabilising tertiary omitted | No — verified value, structural omission |
| Load allocation across buses | Q6 | 9050 : 2500 : 2500 kW | **Yes — A2** |
| Motor pf / efficiency | Q6 | Per-motor model not built | No — declined |
| Outgoing line R₁/X₁ | Q7 | Grid equivalent attached at the plant boundary; no line invented | No — declined |
| Tap positions | Q8 | Documented **principal** taps: GSUT 9 (230000 V), GAT 13 (230000 V), UAT 3 (22000 V) | No — verified plant data |
| 230 kV voltage tolerance | Q8 | Solved voltage reported without a pass/fail limit | No — reported bare |
| Bus coupler state | Q9 | Closed | **Yes — A3** |
| Per-bay busbar selection | Q10 | Immaterial *because* A3 merges BUS 1 and BUS 2. **Depends on A3** — reverse it and this becomes first-order | No — but conditional on A3 |
| System base MVA | Q11 | 100 MVA reporting base, plus engineering units and each bus's own base | No — a reporting choice |
| GSUT cooling stage | Q11 | Loading reported against all three ratings (355 / 460 / 515 MVA) | No — all stages reported |
| Transformer L<sub>m</sub> | *none* | Arose during model build; datum then **found** in the datasheets as *"excitation current"* (GSUT 0.13 %) and derived | No — **A4 retired 2026‑08‑19** |

---

## Where assumptions live, and where they must never go

Assumption files live **only** in `matlab/data/assumptions/`, one file per assumption, each carrying `Parameter`, `Value`, `Unit`, `Reason`, `Approved_by_user`, `Date`, `Impact`, `Impact_quantified`, `Source`, `Affects`, `Status_assigned`.

They are **never** written into `ashuganj_master_data.m`, `ashuganj_buses.m`, `ashuganj_generators.m`, `ashuganj_transformers.m`, `ashuganj_lines.m`, `ashuganj_loads.m` or `ashuganj_grid.m`, which carry verified and derived data only. Where a dataset file must *mention* an assumption (e.g. `G.XR_Note`), it carries a prose note pointing at the assumption file — never a substituted value.

**Related:** `verified_parameters.md` · `missing_parameters.md` · `conflicting_parameters.md` · `solver_behaviour.md` · `topology_validation.md` · `load_flow_readiness.md`
