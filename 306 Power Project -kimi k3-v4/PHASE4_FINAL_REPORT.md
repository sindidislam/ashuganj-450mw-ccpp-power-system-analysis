# Phase 4 Final Report — Short-Circuit (Fault) Analysis, Bolted + Resistive LLL/LG/LL/LLG
## Ashuganj South 450 MW CCPP (EEE 306 Power Project)

**Phase:** REV3.1 Phase 4 — fault analysis / short circuit only
**Date:** 2026-09-18
**Status:** Phase 4 complete. Phase-4 regression suite reported by the implementation: 161 passed, 0 failed across 17 test files; independent internal validation engine: 27/27 legs passed; review gate 23/23 confirmed (`PHASE4_REVIEW_GATE.md`).
**Workdir:** `C:\Users\sindi\Downloads\306 Power Project -union alpha` (no git repo; hash-based audit used throughout)
**Plan:** `docs/superpowers/plans/2026-09-18-phase4-implementation.md` (15 tasks, all complete, all review-clean)
**Design spec:** `docs/superpowers/specs/2026-09-18-phase4-fault-analysis-design.md` (REV3.1 master reconciliation + 4 post-review fixes)
**Review gate:** `PHASE4_REVIEW_GATE.md` (freeze table, Q1–Q23 evidence, D1–D8, STOP)
**Code:** `matlab/phase4/` (19 files, M1–M8 + runners) + `matlab/tests/test_phase4_*.m` (17 suites)
**Results:** `results/phase4_fault/` (production archive + smoke_run, t14_smoke, t14_incheck, t14_f4check, t14_stages + run logs; scratch/probe tags are not the archive)

Phase 4 computes symmetrical short-circuit currents at the five mandatory locations (F1 22-kV gen bus, F2 GSUT-side interface, F3 230-kV GIS bus, F4 South line at m, F5 remote bus) for all four fault types, driven by the frozen Phase-3 prefault states, with full positive-, negative-, and zero-sequence network formulation using the adopted source-backed, derived, and engineering-assumption parameters, design-defined stages, per-source contributions, compact sensitivities, and an independent internal validation engine. No relay settings, breaker duties, CT selections, coordination, stability, AVR/governor, or SFC work was performed in this phase.

---

## 1. Executive Summary

Base run (LF360 OUT/IN, dataset P 50-kA Siemens-estimated, X/R 15, MID line-zero band, Xd''_sat, H1 closed-tertiary base, Zf = 0, coupler closed), initial symmetrical RMS (Ik'') governing-phase kA with design-defined first-peak ip in parentheses (kA peak). Provenance of the base choices: X/R = 15 is an ENGINEERING_ASSUMPTION band representative (not a measurement); k0g = 1.5, MID band, H1, and coupler-CLOSED are modelling assumptions/conventions; Zf = 0 is the bolted design base; 0.7-km line parameters are locked Phase-3 assumptions; dataset-P figures inherit Siemens-estimated confidence (see §6 and the design-spec provenance ledger):

| Loc | LLL OUT | LG OUT | LL OUT | LLG OUT | LLL IN | LG IN | LL IN | LLG IN |
|---|---|---|---|---|---|---|---|---|
| F1 | 126.2 (348.3) | 0.00727 (0.0201) | 109.3 (301.5) | 109.3 (301.5) | 128.3 (354.6) | 0.00727 (0.0201) | 111.2 (307.2) | 111.2 (307.2) |
| F2 | = F1 (same node) | = F1 | = F1 | = F1 | = F1 | = F1 | = F1 | = F1 |
| F3 | 50.53 (129.8) | 45.74 (117.5) | 43.76 (112.4) | 48.50 (124.6) | 50.55 (129.8) | 45.89 (117.8) | 43.78 (112.4) | 48.65 (124.9) |
| F4 m=0.5 | 51.06 (131.3) | 46.12 (118.6) | 44.22 (113.7) | 48.97 (125.9) | 51.08 (131.3) | 46.26 (118.9) | 44.23 (113.7) | 49.13 (126.3) |
| F5 | 53.09 (137.4) | 48.47 (125.4) | 45.97 (119.0) | 51.18 (132.5) | 53.11 (137.4) | 48.61 (125.8) | 45.99 (119.0) | 51.18 (132.4) |

F1/F2 LG ≈ 7.27 A primary: NER-dominated (3ZN ≈ 5252.32 ohm vs Vph 12701.71 V → hand estimate 2.418 A sequence, 7.255 A faulted-phase; code 7.272 A = 1.002×, 1.003× vs the rounded 7.25 A sanity reference, reconciled). F1/F2 rows are identical because both labels map to the same electrical node (no artificial impedance inserted, per design). Nodal-vs-Thevenin audit residuals ≤ 3e-14 everywhere; prefault-reproduction gate 0.033/0.033 (OUT/IN) against the 0.10 error bound. r = R1/X1 at fault node recomputed from the production κ (κ = ip/(√2·Ik''), r = −ln((κ−1.02)/0.98)/3): F1 0.0171 (κ 1.9511), F3 0.0694 (κ 1.8159), F4 0.0683 (κ 1.8185), F5 0.0635 (κ 1.8301). Duration anchors at F3 LG OUT: Ib(t_break = 0.06 s chosen study reference time — not a measured breaker clearing time) 45.55 kA, steady 45.03 kA (ordering Ik'' 45.74 > Ib 45.55 > steady 45.03 holds). Sensitivity example: F3 LG line-zero corners LOW/MID/HIGH → 46.10/45.74/45.38 kA (range 45.38–46.10); LEGACY secondary 45.01-kA/X/R-10.99 dataset (41.99 kA at F3 LG), sensitivity-only, never merged. Phase 4 introduced no changes to the protected Phase-3/Rev2 files. Three pre-existing Phase-3-window differences relative to the earlier baseline were already present and are unrelated to Phase 4.

## 2. Scope

In scope: per-case EMF derivation from frozen solved states; NER grounding implementation; GSUT/UAT/GAT sequence models + GAT tertiary decision; South-line zero reference band; dual-profile grid equivalent; two-circuit F4 + m-division + GIS topology; LLL/LG/LL/LLG equations + normalized Zf + design-defined stages + toward-fault contributions; compact A–H sensitivity matrix; 27-leg independent validation; Rev2 single-function reuse; M1–M8 architecture; Phase-5 handoff CSVs; this report.

Out of scope (binding, unchanged): MATLAB edits to any pre-existing file (all Phase-4 code is new files only); relay pickup/TMS/grading/differential settings; CT ratio selection; breaker pass/fail or duty evaluation; protection coordination; transient stability; battery/DC; AVR/governor/SFC implementation; substation/bay invention; geometry/soil invention; X0 = 3X1 / R0 = R1 / B0 = B1 as fact; solid-grounding revival; Q-as-breaker modelling; uncontrolled sweeps; IEC 60909 compliance claims of any kind; MISSING → VERIFIED promotion.

## 3. Frozen Phase-3 Interface (unchanged, hash-verified)

100 MVA / 230 kV, Zbase = 529 ohm. South positive reference R1 0.00015 / X1 0.00077 / Y1 0.001488 pu/km; lumped dual-circuit 0.7-km equivalent R 0.0277725 ohm / X 0.1425655 ohm / B 3.937996 uS; MALLARD_795_MCM reference-only (not the verified South conductor); B230_REMOTE = REMOTE_GRID_BUS_ASSUMED (actual substation unknown). Generator (non-negotiable values, implementation-held): 458 MVA / 22 kV / 50 Hz; saturated d-axis Xd 1.783 / Xd' 0.3256 / Xd''_sat 0.2248 (Siemens §2.1.1-corroborated 166.3/28.65/22.48%) with unsaturated alternative Xd''_unsat 0.2608 kept distinct (never averaged); qualified q-axis Xq 1.751 / Xq' 0.5087 / Xq'' 0.2593; Xl 0.2027 / X2 0.2242 / X0 0.128 / Ra 0.00089 ohm (qualified project data, not Siemens-OEM-verified; X2 never replaced by Xd''). Primary Phase-4 dispatch 360 MW; Siemens rated P 389.30 MW. Primary prefault pair LF360_GAT_OUT (B22 22.0 kV ∠−22.7815°, Q 27.83 MVAr) / LF360_GAT_IN (∠−22.8687° class, Q 23.67 MVAr — hence per-case EMFs, never shared). Freeze evidence: PHASE3 reports 45504 B 13:02:04 / 25257 B 13:02:00; lines/grid data 13448 B 12:42:16 / 10655 B 12:40:20 — all re-checked at gate close.

## 4. Method (M1–M8, one line each)

M1 input/profile provider: reads frozen CSVs through kV columns only (solver-base pu columns never touched). M2 sequence builder: pos/neg (Z2_gen = Ra + jX2 with X2 = 0.2242 qualified project data; transformers Z2 = Z1 by stated static-equipment assumption; line R2 = R1 / X2 = X1 / B2 = B1 short-line assumption; grid Z2 = Z1 within dataset, never across datasets) + zero (gen X0 + 3ZN, GSUT HV leg, UAT LV bounded leg, GAT H-legs, line band, grid k0g, aux shunt OPEN). M3 stage sources: E'' = Vt + Z''·It per case (Xd''_sat primary, unsat sensitivity; closure residuals ~1e-16; Eq +1.787 OUT-sat hand-verified), two-axis E', constant-field Eq. M4 nodal solver: explicit Ybus + Norton sources + inter-layer fault branches (genuinely nodal; Thevenin scalars audit-only); prefault-reproduction gate; ip = κ√2·Ik'' with design-defined κ shape. M5 contributions: toward-fault-signed legs, feeder-partition KCL (residuals ~1e-15), through-tags, no per-leg ip. M6 validation: 27 independent legs. M7 sensitivity: OFAT A–H + GAT-Z0 SOURCE-tolerance leg + F1-exact analytic joints; factorial rejected. M8 writer: Sec-26 schema CSVs, data only. All solves are direct (backslash); Newton-Raphson appears nowhere because every network is linear by design (code-proven: no iteration, no damping; sole linearization is the spec-mandated aux shunt). LV aux zone uses the 6.6-kV ohmic base (Zbase 0.4356 ohm; `phase4_registry.m:28`; aux sanity L23 stamped-vs-recomputed residual 1.63e-16). UAT/GAT LV physics uses the 6.9-kV winding nominal with the documented 6.9/6.6 nominal tap (a = 1.045454545; registry `R.lv` rows; tap sanity L22 residual 0); UAT Dyn11 ±30°/conjugate shift treatment is checked by the B6_6 prefault-reproduction gate (0.05 bound; L21 OUT 0.025691 / IN 0.028839). GAT tertiary base is the H1 closed-tertiary loop (0.432 pu on the 100-MVA base = 4× the 25-MVA 0.108 pu; loop-identity L24 residual 0) with H2 as the 1e-6 short-limit limiting-sensitivity leg (structural + ordering gate L25 residual 0; never proof). Neutral convention keeps ZN as the physical neutral impedance with the single-counted stamped 3ZN branch value (`phase4_grounding.m:25-31,109-122`; single-count legs in `test_phase4_seqZ`).

## 5. Base Results (how to read §1)

Ik'' = governing-phase RMS (LG |Ia|, LL/LLG max(|Ib|,|Ic|), LLL |I1|); ip = design-defined first-peak magnitude (NOT IEC 60909 ip). kA at fault level (study-pu × 100/(√3·Vlevel)). F4 at m = 0.5 (two explicit circuits, Z_branch = 2·Z_eq); F1/F2 labels share one node. Full per-run phasors, sequence components, r/κ, audit/pre residuals live in `results/phase4_fault/` CSVs + run logs.

## 6. Sensitivity Snapshot

Line-zero band (F3 LG OUT): LOW/MID/HIGH corners → 46.10/45.74/45.38 kA faulted-phase (range 45.38–46.10; HIGH corner adopted as engineering envelope for mutual direction, not a proof). Grid: X/R 10/20 ends (45.76/45.73 kA at F3 LG OUT) + 45.01-kA/X/R-10.99 secondary (41.99 kA at F3 LG) + k0g 1.0/2.0 per dataset (50.88/42.00 kA at F3 LG OUT). Generator: Xd'' unsat run (45.66 kA at F3 LG OUT) + Xq'' saliency analytic bound + X2/X0 bounded/error-check variants. Grounding: NER quoted-vs-reflected + tolerance, NGT neglected-vs-bounded, UAT 5-A alternative reading, GAT LV 5-A + HV finite-ground sensitivities. GAT: H1 closed-tertiary base (λ = 1.0 → 0.108 pu) vs H0 open vs H2 short limiting sensitivity + λ 0.5/2.0 + GAT-Z0 ±7.5% SOURCE-tolerance leg (9.99/10.8/11.61%). Zf: 0 vs 0.01 pu earth / 0.002 pu phase (F1-earth ≈ bolted within 1% is the CORRECT NER-dominated insensitivity signal). Coupler closed base vs open sensitivity. No uncontrolled factorial anywhere.

## 7. Contributions Snapshot

Feeder-partition KCL closes ~1e-15 per sequence/phase/earth on all base runs. F3 LG OUT is grid-plus-plant fed through GSUT-HV, line, grid-zero, and (IN only) the GAT loop; generator NER participates in no HV fault (delta block verified: line/grid zero legs carry no current for B22 LG). GAT OUT removes the GAT leg in all sequences (absent, never zero-filled). B6_6 UAT/GAT-LV neutrals reported as explicit parallel shares without pre-judged labels. ip has no contribution table.

## 8. Validation

Independent internal validation engine: 27/27 legs passed (L01–L20 originals + L21 V-A B6_6 gate + L22 V-B tap sanity + L23 V-C aux sanity + L24 V-D loop identity + L25 V-E H2-vs-H0 structural+ordering + L26 V-F all-type continuity + L27 V-G handoff LL/LLG completeness; seq↔ph round trips via independent re-implementation; LLL/LG/LL/LLG analytical-vs-nodal ≤ 3e-14; KCL seq/ph/earth; NER gating + normalized-earth-probe (0.01 pu → 0.0484 ohm at F1) insensitivity 2.76e-05 note-only; GSUT block; UAT/GAT paths incl. IN-case nonzero; H0/H1/H2 LL/LLL invariance on OUT and IN; F3↔m=0 / F5↔m=1 continuity exact and separate; F1/F2 label separation; two-circuit restoration + zero-X/R 4.03 in [2.05, 8.98]; determinism; symmetry; source conservation). Phase-4 regression suite reported by the implementation: 161 passed, 0 failed across 17 test files; review gate 23/23 confirmed with live predicates. Rev2 earth outputs, Siemens infeeds, and X0 = 3X1 were never oracles.

## 9. Rev2 Disposition + Legacy Conflict Fence

Reused exactly one function body (`iec_kappa.m` κ shape, relabelled design-defined peak factor, no IEC claim). Everything else HISTORICAL ONLY or REBUILT: solid grounding, 354-MW basis, legacy grid tuple, C-line electrics, old Z0 mechanism, P1A prefault, CT-selection logic, duty results, CSVs. Rev2 files unmodified.

Legacy values are fenced below. Level-5 legacy values are never silently promoted into current Phase-4 physics:

| Item | Legacy value | Current Phase-4 value | Disposition + reason |
|---|---|---|---|
| GSUT main Z | 16.63% (older consolidated records) | 16.0% on 515 MVA (current datasheet) | REJECTED legacy; datasheet governs fault physics |
| GAT main Z | 14% (old SLD) | 12.0% (Rev3/data sheet) | REJECTED legacy; Rev3 governs |
| UAT Z / Z0 | older preliminary values | 10.5% / ≈9.3% (current datasheet) | REJECTED legacy; datasheet governs |
| Generator CT | 16000/1 (older SLD) vs 15000/1 (Siemens protection report) | UNRESOLVED in Phase 4 | CT selection out of scope; no ratio decided here |
| Generator SCR | 0.58 (Siemens capability-curve attachment) vs 0.601 (project workbook) | 0.601 kept as project-data value | Provenance distinguished; 0.601 is NOT Siemens-verified; neither enters fault physics |
| Generator capability | 6 curve points (source-extracted/digitized, no invented OEM limit labels) | 360-MW interpolation Qmax ≈ +253.7962 / Qmin ≈ −189.5465 MVAr (DERIVED, not source points) | Curve not re-derived; solved prefault Q (27.83/23.67 MVAr) lies well within limits (consistency note, not a limit input) |
| Grid 45.01 kA / X/R 10.99 | secondary dataset | Sensitivity-only secondary profile | NEVER merged with primary 50-kA dataset |
| Generator grounding | solid (Rev2 registry) | High-resistance NER 10BAB11 | REJECTED for current Phase 4 |
| Dispatch 354 MW / aux 12 MW + j5 | Rev2 P1A basis | Historical/sensitivity only | Primary is LF360 pair with frozen 14 MW aux |
| Old line parameters | Rev2 C-electrics etc. | Frozen Mallard reference + zero band | REJECTED; never reused |

## 10. Handoff Inventory (Phase-5 input, data only)

`results/phase4_fault/<tag>/`: `phase4_fault_currents.csv` (25-col schema: type/location/m/case/dataset/band/Xd-role/NER/GAT/Zf/topology/stage/unit-base + kA phasors/sequences + r/κ/t_break/footnotes), `phase4_contributions.csv` (per-leg phasors + KCL residuals), `phase4_bands.csv` (min/max + supplying legs + incomplete flags), `phase4_ct_data.csv` (primary + candidate ratios + secondary + frozen-flow anchors, selection never made). No pickup/TMS/grading/duty/verdict columns (asserted by writer + gate scan). Archive tag: production/ (`phase4_fault_currents.csv` 464 rows + `phase4_contributions.csv` 204 rows + `phase4_bands.csv` 20 rows + `phase4_ct_data.csv` 2040 rows + `analytic_bounds.csv` 33 rows + `manifest.json` + `sha256.txt` + `run_log.txt`). Working tags present (not the archive): smoke_run, t14_smoke, t14_incheck (GAT columns), t14_f4check (B1/B2 columns), t14_stages (Ib/steady/t_break/footnotes); scratch/probe tags (production_segN, prod_subset, v27probe) are not the archive.

## 11. Risks / Missing Data (D1–D8, short)

D1 line R0/X0/B0 + tower/soil/mutuals MISSING (band + envelope stand in). D2 grid Thevenin unmeasured (ESTIMATED/LEGACY/ASSUMPTION profiles). D3 generator X2/X0 QUALIFIED (no OEM corroboration). D4 NER reconciliation conditional on heading reading + NGT series MISSING. D5 GAT pairwise-INCOMPLETE (Z_PT/Z_ST MISSING). D6 UAT/GAT LV neutral devices MISSING (5-A constraint only). D7 full Siemens report + turbine doc + INEL-0026 GIS drawing + JICA/Mallard file MISSING. D8 aux/downstream-LV uncertainty (no motor infeed modelled).

## 12. Equipment-Rating Observation (non-pass/fail)

The F3 calculated 230-kV LLL bus fault level (≈ 50.53 kA) is numerically adjacent to the documented 50-kA 230-kV equipment rating reference. This is NOT a breaker/equipment failure finding, and Phase 4 does not perform breaker/equipment duty assessment. Phase 5 shall use component through-currents (not total bus current compared directly to a transformer or breaker through-current duty) together with applicable equipment ratings for that evaluation.

## 13. STOP Boundary

Phase 4 = FAULT ANALYSIS / SHORT CIRCUIT ONLY. No relay coordination, protection settings, breaker-duty evaluation, stability, battery/DC, AVR/governor/SFC work was started — gate scan confirms none exists in code or results. Phase 4 introduced no changes to the protected Phase-3/Rev2 files. DO NOT implement Phase 5 without explicit approval.
