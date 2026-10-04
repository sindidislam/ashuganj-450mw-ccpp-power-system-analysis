# Phase-4 Fault-Analysis Design Specification â€” Ashuganj 450 MW CCPP (South)

Date: 2026-09-18 (REV3.1 Phase 4 Master Technical Reconciliation)
Status: DESIGN ONLY â€” implementation-ready specification. No MATLAB code written, no fault currents calculated, no protection settings generated.
Baseline superseded: `docs/superpowers/specs/2026-09-18-phase4-fault-analysis-design.md` (4888-line concatenated working-draft assembly, Tasks 1â€“15).
This document: the corrected, implementation-ready Phase-4 DESIGN SPECIFICATION. It replaces the baseline assembly in full.

Rule: closed source-status enum only â€” SOURCE/PRIMARY, DERIVED, ENGINEERING_ASSUMPTION, HISTORICAL, LEGACY, MISSING.
No silent upgrades. Every technical value carries value + unit + base + source + locator + status + rationale.

---

## Change log versus the baseline assembly (what this reconciliation corrected)

1. Sec 10/13/22/23/26 â€” GAT LV neutral: was "solid (ZN = 0)" with "DOMINANT GAT-fed share" stated as fact. Now: LV neutral is ~5-A-limited ENGINEERING_ASSUMPTION (`ZN_GAT_LV â‰ˆ 796.743 ohm` derived equivalent); HV neutral is solid ENGINEERING_ASSUMPTION. All "both neutrals solid" statements removed.
2. Plant-wide - phrase GAT-dominant removed; replaced with neutral per-run reporting rule (dominance determined numerically, never asserted).
3. Sec 8/14/22 â€” phrase "evidence-derived" / "EVIDENCE-DERIVED" replaced with "ENGINEERING_ASSUMPTION reference band informed by overhead ACSR earth-return engineering behavior and available reference-class data."
4. Sec 8/14 â€” universal laws "R0 > R1, X0 > X1, B0 < B1" replaced with expected-for-adopted-overhead-line-model constraints (modelling constraints, not universal physical laws).
5. Sec 19/22/25/26 â€” "Ib is an upper bound" replaced with "Ib(t_break) is a constant-E' reference approximation at specified t_break." No default clearing time. No guaranteed-bound claim.
6. Sec 21/22/25 â€” fixed-ohm Zf probes (5-ohm earth / 1-ohm phase) replaced with normalized local-base per-unit sensitivity (`Zf_earth = 0.01 pu`, `Zf_phase = 0.002 pu` local fault-voltage base) with ohmic equivalents tabulated per location. Zf = 0 bolted base retained.
7. Sec 18/20/25/26 â€” GIS terminology corrected: Q0 = CIRCUIT BREAKER (52-1); Q1/Q2 = BUS DISCONNECTORS (89B2-1/89B1-1); Q9 = LINE DISCONNECTOR (89-1/89G); Q51/Q52 = maintenance earthing switches; Q8 = high-speed earthing switch (57-series devices). All "Q0/Q1/Q2/Q9 disconnectors" collective statements removed.
8. Sec 18/20 â€” Phase-4 LINE FAULTS (F4) now use TWO EXPLICIT IDENTICAL CIRCUIT BRANCHES (`Z_branch = 2*Z_eq`, `B_branch = B_eq/2` per sequence, same rule for zero). Bus faults F1/F2/F3/F5 stay on the frozen lumped base. Single-lumped-branch representation of 25/50/75% line faults forbidden.
9. Sec 18/20/22 â€” F1/F2 same-electrical-node rule: keep both reporting labels, no artificial separating impedance.
10. Sec 15/25 â€” Phase-3 `Rgrid = 0` fenced as BALANCED LOAD-FLOW ASSUMPTION ONLY; forbidden in all Phase-4 fault networks (re-stated as assert).
11. Sec 8/15/22 â€” grid Z0: `k0g = [1.0, 1.5, 2.0]`, base 1.5, per dataset; same-angle scaling labelled engineering simplification; ADDED compact independent zero-sequence R/X sensitivity.
12. Sec 10 â€” NER reconciliation fixed to the recommended physical interpretation with exact source-heading evidence: n â‰ˆ 25.40341184, `R_loading_reflected â‰ˆ 1690.773333 ohm`, `R_NER_HV â‰ˆ 1750.773333 ohm` (conditional, see Sec 10), `3*ZN â‰ˆ 5252.32 ohm â‰ˆ 4970.1706 pu` machine base (derived checks). "Choose 60 OR 1690.77" forbidden unless source wording proves inclusion.
13. Sec 12/13 â€” UAT/GAT LV 5-A equivalents quantified: `ZN â‰ˆ 796.743 ohm` derived engineering equivalents (not device data) with mandatory alternative-interpretation sensitivities.
14. Sec 13/22 â€” GAT tertiary: base is now the explicit equivalent circulating-tertiary representation `Z_T0_loop = lambda_T * Z0_PS` (25-MVA base, lambda base 1.0 / low 0.5 / high 2.0 â†’ 0.108 / 0.054 / 0.216 pu). H0/H1/H2 legs retained as approximation/sensitivity legs. H1 is the base leg.
15. Sec 9/19 â€” saliency: Xq'' = 0.2593 vs Xd''_sat = 0.2248 spread (â‰ˆ15%) requires qualified saliency sensitivity where implementation supports it; silent Xq'' = Xd'' forbidden.
16. Sec 7/15 â€” negative-sequence equalities kept ONLY with stated physical rationale per element (transformers, line, grid-within-dataset); universal silent X2 = X1 forbidden.
17. Sec 4/6/7/9 â€” X2/X0 classified as SOURCE/PRIMARY workbook project-data entries with QUALIFIED rationale; Siemens-OEM-verified claims forbidden.
18. Sec 14 â€” line-zero band base representative + derived ohm checks added (R0 â‰ˆ 0.09720375, X0 â‰ˆ 0.392055125, B0 â‰ˆ 2.8550471 microS) with LOW/HIGH corners mandatory.
19. Sec 15 â€” grid primary X/R band [10, 20], base 15, with derived R â‰ˆ 0.17666194 / X â‰ˆ 2.64992904 ohm; secondary dataset fixed values restated; datasets never mixed; 3.25-ohm figure fenced.
20. Sec 19/24 â€” kappa-shaped peak factor relabelled "design-defined peak-factor shape" everywhere; no IEC 60909 compliance claim for any quantity.
21. Sec 18 â€” B6_6 classified AUXILIARY VALIDATION-ONLY (not a mandatory Phase-5 main location unless explicitly approved).
22. Sec 25 â€” implementation architecture rewritten to M1â€“M8 with canonical Phase-4 parameter registry (value/unit/base/status/source/locator/rationale/variant ID), no hard-coded literals.
23. Sec 5 â€” provenance ledger rebuilt to the corrected figures (NER additive interpretation, GAT LV 5-A, normalized Zf, k0g triple, lambda_T).
25. Post-review corrections (4 items, pre-approval): (a) Sec 20 + Sec 22-G + Sec 18 GIS parenthetical - Q0 is a breaker connection, Q1/Q2/Q9 are disconnector connections; no collective Q-switch disconnector language remains. (b) H2 relabelled limiting sensitivity / stress case everywhere; no claim that the lambda_T = 0.5-2.0 range proves a physical bound (Z_PT/Z_ST MISSING). (c) Mutual-coupling coverage relabelled: HIGH corner is an engineering envelope for the expected mutual direction, not a mathematical proof of an absolute bound (Sec 18 F4 paragraph, Sec 22-C, Sec 27-D1). (d) Compact GAT-Z0 source-tolerance leg added: 10.8% nominal / 9.99% / 11.61% as SOURCE-stated tolerance per IEC 60076-1, run at H1 base, separate from lambda_T (Sec 13 item 7, Sec 22-H, Q8/Q19 rows).`n`n24. All sections â€” 45.01-kA and 50-kA grid datasets kept separate; Mallard kept reference-only; 0.7-km line frozen; line R1/X1/B1 unchanged.
25. 2026-09-19 correction entry (C1/C2/C4/C5/C7 + L27 fix, one paragraph): C1 placed LV-zone ohmic conversions on the 6.6-kV base with the aux impedance stamped as-computed; C2 applied the documented nominal LV tap with the UAT Dyn11 shift treatment pinned by the B6_6 prefault-reproduction gate; C4 stamped the H1 closed-tertiary loop value with its dual-base identity; C5 kept H0 as the tertiary-open leg opposite H1/H2 with LL/LLL invariance across legs; C7 fixed neutral semantics to physical ZN with single-counted stamped 3ZN branch values; the L27 fix added the non-scalar pass/residual structural guard to the validation assembly. All six are code-correctness corrections with no physics redefinition; validation is 27/27 with the review gate at 23/23.

---

## Table of contents (28 sections)

1. Objective â€” Sec 1
2. Scope â€” Sec 2
3. Frozen Phase-3 interface â€” Sec 3
4. Source audit â€” Sec 4
5. Provenance ledger â€” Sec 5
6. Positive sequence â€” Sec 6
7. Negative sequence â€” Sec 7
8. Zero sequence â€” Sec 8
9. Generator EMF â€” Sec 9
10. Generator NER â€” Sec 10
11. GSUT â€” Sec 11
12. UAT â€” Sec 12
13. GAT + tertiary â€” Sec 13
14. South-line zero parameters â€” Sec 14
15. External grid â€” Sec 15
16. Prefault cases â€” Sec 16
17. Fault equations â€” Sec 17
18. Fault locations and m â€” Sec 18
19. Fault stages â€” Sec 19
20. Contributions â€” Sec 20
21. Zf â€” Sec 21
22. Sensitivity matrix â€” Sec 22
23. Validation â€” Sec 23
24. Rev2 matrix â€” Sec 24
25. Implementation architecture â€” Sec 25
26. Phase-5 handoff â€” Sec 26
27. Risks / missing data â€” Sec 27
28. STOP boundary â€” Sec 28

---

## Review-gate table Q1â€“Q23 (corrected answers, consistent with Secs 1â€“28)

| # | Question | Corrected answer (decision + section) |
|---|----------|----------------------------------------|
| Q1 | Generator internal EMF? | Per-case solved-state derivation: Vt from B22 V/angle, St = Pgen+jQgen, St_pu = St/458, It = conj(St_pu/Vt), Z'' = Ra+jXd''_sel, E'' = Vt+Z''*It. Separate E'' for LF360_GAT_OUT and LF360_GAT_IN. No 1+j0, no Vprefault-only, no Vprefault/Xd'' shortcut. Sec 9. |
| Q2 | Which Xd''? | PRIMARY Xd''_sat = 0.2248 pu; SENSITIVITY Xd''_unsat = 0.2608 pu. Never averaged. Legacy 0.2248 triple is the same Siemens transcription, not an independent source. X2/X0 never substituted. Qualified saliency sensitivity (Xq'' = 0.2593) where supported; no silent Xq'' = Xd''. Sec 9. |
| Q3 | Generator NER? | High-resistance grounding via NER 10BAB11 (22/sqrt(3) kV : 500 V, 135 kVA / 20 s). Recommended interpretation: n â‰ˆ 25.40341184, R_loading reflected â‰ˆ 1690.773333 ohm; 60-ohm quantity read as HV winding DC resistance per source heading, so R_NER_HV â‰ˆ 1750.773333 ohm pre-NGT-reactance; 3*ZN â‰ˆ 5252.32 ohm â‰ˆ 4970.1706 pu machine base (derived checks). 3*ZN in generator neutral zero branch ONLY. NGT series impedance MISSING. Sec 10. |
| Q4 | Negative sequence? | Dedicated network. Generator X2 = 0.2242 pu (workbook project-data, QUALIFIED rationale, no Siemens-OEM claim). Transformers Z2 = Z1 only with stated static-plant rationale per unit. Line Z2 follows positive self model in balanced-line approximation; mutual negative neglected by construction (geometry unavailable). Grid Z2 = Z1 within each dataset with stated assumption. Sec 7. |
| Q5 | Zero-sequence path continuity? | LG/LLG use zero network; LLL/LL do not. Included where connected: generator X0+3ZN, GSUT zero path, UAT LV zero path, GAT zero path, South-line R0/X0/B0, grid Z0. No path bypasses winding connections: GSUT YNd1 delta blocks LV<->HV zero; UAT Dyn11 delta blocks HV zero, permits LV zero-to-neutral; GAT YNyn0 gives HV+LV zero with tertiary-delta treatment. Sec 8. |
| Q6 | GSUT? | 230/22 kV, 515 MVA, YNd1, Z1 = 16.0%, R1 = 0.21%, Z0 â‰ˆ 15.8%. HV star neutral grounded; solid grounding is ENGINEERING_ASSUMPTION (no neutral-impedance data). LV delta blocks external zero transfer. Positive/negative transfer retains series impedance + vector-group phase shift. Rev2 Z0 = Z1 rejected. Sec 11. |
| Q7 | UAT? | 22/6.9 kV, 19/25 MVA, Dyn11, Z1 = 10.5%, R â‰ˆ 0.4%, Z0 â‰ˆ 9.3%. LV neutral device R/X MISSING; source constraint is 5-A ground-fault limit, read primarily as IN = 3*I0 â‰ˆ 5 A â†’ ZN_UAT â‰ˆ Vph/5 â‰ˆ 796.743 ohm derived engineering equivalent (not device data). Mandatory alternative-interpretation + R/X-split sensitivity. HV delta blocks zero outside LV aux system. Sec 12. |
| Q8 | GAT tertiary? | Physical 230/6.9/3.32 kV, 19/25 MVA, tertiary â‰ˆ 8.33 MVA, YNyn0+d11. Known Z_PS â‰ˆ 12%, R â‰ˆ 0.5%, Z0_PS â‰ˆ 10.8%. Z_PT/Z_ST MISSING â†’ full three-winding exact model impossible; Z_PT/Z_ST never fabricated. HV neutral solid-to-earth ASSUMPTION; LV neutral NOT solid â€” ~5-A-limited equivalent ZN_GAT_LV â‰ˆ 796.743 ohm (DERIVED ENGINEERING_ASSUMPTION). Base zero model: explicit equivalent circulating-tertiary Z_T0_loop = lambda_T*Z0_PS (25-MVA base; 1.0 / 0.5 / 2.0 â†’ 0.108 / 0.054 / 0.216 pu). Dual identity: 0.108 pu on the 25-MVA base = 0.432 pu stamped on the 100-MVA base (loop identity L24, residual 0). H0/H1/H2 are approximation/sensitivity legs (H1 base); H2 is the 1e-6 short-limit limiting sensitivity / stress case, never proof. Tertiary affects LG/LLG zero only; LL/LLL invariance asserted. B6_6 UAT+GAT LV neutrals are explicit parallel branches. GAT-Z0 +/-7.5% source-tolerance leg (9.99% / 10.8% / 11.61%, Sec 22-H). Sec 13. |
| Q9 | South-line R0/X0/B0? | MISSING as source values. X0 = 3*X1 / R0 = R1 / B0 = B1 as facts forbidden. ENGINEERING_ASSUMPTION reference band: kR in [2.0, 5.0], kX in [2.0, 3.5], kB in [0.60, 0.85]; base (3.5, 2.75, 0.725) â†’ R0 â‰ˆ 0.09720375 ohm, X0 â‰ˆ 0.392055125 ohm, B0 â‰ˆ 2.8550471 microS. LOW/HIGH corners mandatory. "ENGINEERING_ASSUMPTION reference band informed by overhead ACSR earth-return engineering behavior and available reference-class data." R0>R1 etc. are expected-for-model constraints, not universal laws. Sec 14. |
| Q10 | External grid R/X? | Primary: Siemens estimated Ik'' â‰ˆ 50 kA, Sk'' â‰ˆ 19.919 GVA, XN â‰ˆ 2.66 ohm; derived |Z1| â‰ˆ 2.65581124 ohm (magnitude, not X). 2.66 and 2.65581124 never paired as exact R/X. Fault-study X/R band [10, 20], base 15 â†’ R â‰ˆ 0.17666194, X â‰ˆ 2.64992904 ohm (DERIVED ENGINEERING_ASSUMPTION). Secondary separate: 45.01 kA, X/R 10.99 â†’ |Z| â‰ˆ 2.950246, R â‰ˆ 0.267344, X â‰ˆ 2.938108 ohm. Never mixed. 3.25-ohm historical figure not primary. Grid Z0 MISSING â†’ Z0 = k0g*Z1, k0g [1.0, 1.5, 2.0], base 1.5, same-angle scaling is simplification + independent zero R/X sensitivity. Sec 15. |
| Q11 | Prefault state? | Frozen Phase-3 solved states; primary LF360_GAT_OUT / LF360_GAT_IN. No rerun, no flat 1+j0. Uses B22 V+angle, B230_1 V+angle, B230_REMOTE V+angle, generator P/Q, aux P/Q, GAT/UAT/coupler/grid states. V_REMOTE_kV used, never internal solver-base V_REMOTE_pu. LF389P30 historical/sensitivity only. Sec 16. |
| Q12 | Fault locations? | Mandatory F1 = B22 22-kV bus; F2 = 22-kV GSUT-side interface; F3 = 230-kV South GIS bus; F4 = South 230-kV line (m = 0/0.25/0.50/0.75/1.00); F5 = B230_REMOTE. B6_6 AUXILIARY VALIDATION-ONLY (not mandatory Phase-5 main set unless approved). F1/F2 same-node: keep both labels, no artificial impedance. Sec 18. |
| Q13 | m-factor and two circuits? | Phase 3 frozen lumped D/C for balanced load flow. Phase-4 LINE FAULTS use two explicit identical branches preserving the total: Z_branch = 2*Z_eq, B_branch = B_eq/2 per sequence (same rule for zero). Faulted circuit splits m*Z_branch / (1-m)*Z_branch; healthy circuit end-to-end. Mutual coupling not explicitly modelled (geometry missing); never claimed physically absent. Healthy sharing I_B1 â‰ˆ I_B2 â‰ˆ I_total/2 is ENGINEERING_ASSUMPTION (anchor â‰ˆ870 A total / â‰ˆ435 A per circuit, not a fault current). Sec 18. |
| Q14 | GIS topology? | Q0 = CIRCUIT BREAKER (52-1); Q1/Q2 = BUS DISCONNECTORS (89B2-1/89B1-1); Q9 = LINE DISCONNECTOR (89-1/89G); Q51/Q52 = maintenance earthing; Q8 = high-speed earthing (57-series). Q0/Q1/Q2/Q9 never collectively called disconnectors. No breaker duty in Phase 4. Balanced-fault simplification represents only topology-defining devices. Coupler CLOSED primary ASSUMPTION, OPEN sensitivity with documented bay assignment. No invented bay number (INEL-â€¦-DE-0026 unavailable). Sec 18. |
| Q15 | Fault impedance? | Base Zf = 0 (bolted baseline). Sensitivity normalized to local base: Zf_earth = 0.01 pu, Zf_phase = 0.002 pu local fault-voltage base, ohmic equivalents tabulated per location. Earth faults: 3*Zf in zero earth path. LL/LLL: Zf without 3x multiplier. Assumed values never called measured arc/footing resistance. LLG: one common earth-path impedance; phase-to-phase arc inside LLG neglected (stated). Sec 21. |
| Q16 | Fault stages? | PROJECT-DESIGN DEFINITIONS, not IEC 60909 compliance. Ik'': subtransient E''+Xd'' RMS. ip: design-defined first-peak estimate kappa(r) = 1.02+0.98*exp(-3r), ip = kappa*sqrt(2)*Ik'', r = R1/X1 fault-node Thevenin; labelled "ip (design-defined peak)". Ib(t_break): transient-stage RMS at USER-SUPPLIED t_break via E'/two-axis source; no default clearing time; "constant-E' reference approximation at specified t_break", never guaranteed upper bound. Steady state: constant-field synchronous reference (Xd/Xq), no AVR/governor, no IEC claim. Sec 19. |
| Q17 | Source contributions? | FULL NODAL sequence solution, then branch extraction + phase reconstruction. Every contribution signed TOWARD THE FAULT. Reported separately: Generator, GSUT-HV, GSUT-LV, UAT branch, GAT-HV/GAT-LV, LINE-total, LINE-B1, LINE-B2, GRID, NER-earth. GAT OUT: branch absent. GAT IN: branch present. UAT passive (no motor infeed invented). F4: faulted-circuit South-side + remote-side + healthy-circuit + total. ip has no per-leg table. Sec 20. |
| Q18 | Validation? | INDEPENDENT validation, 27 legs (Sec 23: L01-L20 originals + V-A B6_6 gate + V-B tap sanity + V-C aux sanity + V-D loop identity + V-E H2-vs-H0 structural+ordering + V-F all-type continuity + V-G handoff LL/LLG completeness): sequence/phase round trips, LLL/LG/LL/LLG analytical-vs-nodal, per-sequence/per-phase KCL, earth KCL IN = 3I0, NER gating, GSUT delta blocking, UAT/GAT zero paths, GAT H0/H1/H2 LL/LLL invariance, F3/m=0 vs F5/m=1 continuity, F1/F2 no-invented-impedance distinction, two-circuit restoration, deterministic rerun, phase symmetry, source-current conservation. Rev2/Siemens-50kA/X0=3X1/R0=R1 never oracles. Sec 23. |
| Q19 | Sensitivities? | Compact matrix Aâ€“H (Sec 22): A grid (50-kA primary X/R 10/15/20, k0g 1.0/1.5/2.0, 45.01-kA secondary); B length 0.5/0.7/1.0 km; C line-zero LOW/MID/HIGH + conditional cross-corners; D generator (sat/unsat, X2/X0 bounds, Xq'' saliency where supported); E grounding (NER interpretation/tolerance, NGT neglected-vs-bounded, UAT 5-A alternative, GAT LV 5-A + HV finite-ground); F Zf (0 vs normalized probes); G topology (coupler closed/open); H GAT (closed-tertiary base, open sensitivity, short limiting sensitivity / stress case, GAT-Z0 +/-7.5% source-tolerance leg, neutral alternatives). No uncontrolled full-factorial sweep. Sec 22. |
| Q20 | Rev2 reusable? | ONLY rev2/data/iec_kappa.m function body, relabelled "design-defined peak-factor shape", no IEC claim. Patterns (sequence Ybus structure, nodal injection, analytical scalar equations, KCL test concepts, contribution tagging) may inform fresh code but are written fresh. Sec 24. |
| Q21 | Rev2 rejected? | All else HISTORICAL ONLY or REBUILD: solid generator grounding, 354-MW P1A basis, 12 MW+j5 aux, legacy 0.268+j2.94 grid tuple, 0.08/0.35/4.2 line parameters, old gridZ0_k mechanism, hardcoded P1A prefault, old Vpre fallback, old current-base referral, old CT-selection logic, old breaker-duty results, old fault-current CSVs, old sequence-Z CSVs. Rev2 untouched; Rev2 earth outputs never validation. Sec 24. |
| Q22 | Phase-5 handoff? | DATA only, no protection decisions. Fields per Sec 26 (type, location, m, prefault case, grid dataset, line-zero band, Xd'' role, NER variant, GAT variant, Zf, topology, stage, RMS/phase/sequence currents, contributions, per-circuit currents, breaker through-current tags, t_break for Ib, ip kappa/r). No pickup/TMS/grading/differential/CT-selection/pass-fail. Sec 26. |
| Q23 | Final boundary? | Phase 4 = FAULT ANALYSIS / SHORT CIRCUIT ONLY. No relay coordination, protection settings, breaker-duty evaluation, stability, battery/DC, AVR/governor/SFC implementation. Sec 28. |

---

## Sec 1 â€” Objective

1. Produce the corrected, implementation-ready DESIGN for Phase-4 short-circuit analysis of Ashuganj South: bolted and resistive LLL/LG/LL/LLG faults at F1â€“F5 (plus F4 m-fractions), driven by frozen Phase-3 prefault states, with full sequence networks, design-defined stages, contribution extraction, compact sensitivities, and independent validation.
2. Rule exactly what of Rev2 may be reused (one function body) versus rebuilt versus kept historical-only.
3. Define the fresh MATLAB implementation architecture (M1â€“M8) and the canonical parameter registry.
4. Define the Phase-5 handoff DATA contract (no protection decisions).
5. Record residual risks, missing data, and the explicit STOP boundary. No implementation, no numeric results in Phase 4.

## Sec 2 â€” Scope

In scope: positive/negative/zero sequence design; per-case EMF derivation; NER grounding; GSUT/UAT/GAT models + tertiary decision; South-line zero band; dual-profile grid equivalent; two-circuit + m-division + GIS topology; fault equations + Zf + stages + contributions; compact sensitivity + independent validation; Rev2 disposition; M1â€“M8 architecture; handoff data; risks/boundary.
Out of scope (binding): MATLAB code; fault-current numbers; breaker duties; CT selection; relay settings/coordination; stability; battery/DC; AVR/governor/SFC; substation/bay invention; geometry/soil invention; X0 = 3X1 / R0 = R1 / B0 = B1 as fact; solid-grounding revival; Q-as-breaker modelling; uncontrolled sweeps; IEC 60909 compliance claims; MISSING â†’ VERIFIED promotion; any modification to .m files, Phase-3 files, or Rev2 files.

## Sec 3 â€” Frozen Phase-3 interface

DO NOT CHANGE THESE VALUES.

| Parameter | Value | Unit | Base | Source / locator | Status |
|---|---|---|---|---|---|
| System base | 100 MVA / 230 kV, Zbase = 529 ohm | MVA/kV/ohm | â€” | PHASE3_FINAL_REPORT.md Â§Â§9/11/21 | DERIVED (arithmetic, frozen) |
| South R1 | 0.00015 | pu/km | 100 MVA / 230 kV | PHASE3_FINAL_REPORT.md:53,61; ashuganj_lines.m:79 | ENGINEERING_ASSUMPTION |
| South X1 | 0.00077 | pu/km | 100 MVA / 230 kV | PHASE3_FINAL_REPORT.md:53,61; ashuganj_lines.m:81 | ENGINEERING_ASSUMPTION |
| South Y1 | 0.001488 | pu/km | 100 MVA / 230 kV | PHASE3_FINAL_REPORT.md:53,61 (REPORT ONLY; no .m literal) | ENGINEERING_ASSUMPTION |
| R_eq | 0.0277725 | ohm (pu 0.0000525) | 100 MVA / 230 kV | PHASE3_FINAL_REPORT.md:19,61; ashuganj_lines.m:78 | ENGINEERING_ASSUMPTION |
| X_eq | 0.1425655 | ohm (pu 0.0002695) | 100 MVA / 230 kV | PHASE3_FINAL_REPORT.md:19,61; ashuganj_lines.m:80 | ENGINEERING_ASSUMPTION |
| B_eq | 3.937996 | microS (pu 0.0020832) | 100 MVA / 230 kV | PHASE3_FINAL_REPORT.md:19,61; ashuganj_lines.m:82-83 | ENGINEERING_ASSUMPTION |
| C_eq | 1.253503e-08 | F | 50 Hz | C = B/(2*pi*50) | ENGINEERING_ASSUMPTION |
| Length | 0.7 | km | physical | PHASE3_FINAL_REPORT.md:49,61; ashuganj_lines.m:71 | ENGINEERING_ASSUMPTION (locked planning basis) |
| Circuits / model | 2 / LUMPED_DUAL_CIRCUIT_PI | â€” | â€” | PHASE3_FINAL_REPORT.md:49; ashuganj_lines.m:74-75 | Locked planning basis |
| Conductor ref | MALLARD_795_MCM | â€” | â€” | PHASE3_FINAL_REPORT.md:49,53; ashuganj_lines.m:76-77 | ENGINEERING_ASSUMPTION (Ghorasal-Ashuganj PGCB line-family reference; NOT verified as the actual South-link conductor) |
| South R0/X0/B0 | NaN (source level) | â€” | 100 MVA / 230 kV | ashuganj_lines.m:84-86; PHASE3_FINAL_REPORT.md:65 | MISSING |
| Topology | B230_1 â†’ L_LINE â†’ B230_REMOTE â†’ ZGRID â†’ BGRID230 | â€” | â€” | ashuganj_lines.m:31-32,65-66; ashuganj_grid.m:38-39 | Frozen |
| Remote bus | B230_REMOTE = REMOTE_GRID_BUS_ASSUMED (actual receiving substation unknown) | â€” | â€” | PHASE3_FINAL_REPORT.md Â§Â§6,8 | ENGINEERING_ASSUMPTION (boundary) |

Freeze evidence (read-only, 2026-09-18): PHASE3_FINAL_REPORT.md 45504 B 13:02:04; PHASE3_CHANGELOG.md 25257 B 13:02:00; matlab/data/ashuganj_lines.m 13448 B 12:42:16; matlab/data/ashuganj_grid.m 10655 B 12:40:20.

## Sec 4 â€” Source audit

| # | Source | Verdict | Locator | Status hint |
|---|---|---|---|---|
| 1 | Ahsuganj South (2).xlsx (workbook row 3: ratings, reactances Xd/Xd'/Xd''/Xq-family/Xl/Ra, X2-sat P3, X0-sat Q3) | FOUND | workspace root; serialized in matlab/data/ashuganj_generators.m:71-102 (SHA recorded :109) | SOURCE/PRIMARY project-data (transcription), QUALIFIED base/saturation interpretation |
| 2 | Generator Data_South.pdf (Siemens S001 pp. 6â€“7: Â§2.1.1 saturated d-axis triple 166.3/28.65/22.48%, NER 10BAB11 clause, Â§2.4 grid estimate) | FOUND (partial: 2 of 39 pp) | fwdtechnicaldatasldrequestforbueteeetermproject/Generator Data_South.pdf | SOURCE/PRIMARY (partial) |
| 3 | Generator Name Plate_South.pdf (SGen5-2000H, 458 MVA, 22 kV, 0.85 pf) | FOUND | same folder | SOURCE/PRIMARY |
| 4 | Single Line Diagram_South.pdf (GHESA Rev 00, preliminary note) | FOUND (superseded) | same folder | HISTORICAL / SUPERSEDED |
| 5 | INEL-112070-00-ELC-DE-0001-REV3.pdf (authoritative main SLD Rev 03) | FOUND | same folder | SOURCE/PRIMARY |
| 6 | GENERATION AND TRANSFORMERS SYSTEM.pdf (INEL-â€¦-DE-0023 Rev 03; is DE-0023, NOT DE-0026) | FOUND | same folder | SOURCE/PRIMARY |
| 7 | GSUT Data Sheet_South.pdf (S009-â€¦-HD-0001 Rev 00) + GSUT Nameplate_South.pdf (10BAT10, S/N 881264) | FOUND | same folder | SOURCE/PRIMARY |
| 8 | UAT Data Sheet_South.pdf (STWH-579UAT-0007/STWH-580GAT-0007 Rev 00, covers UAT S/N 100579 AND GAT S/N 100580) + UAT Nameplate_South.pdf | FOUND | same folder | SOURCE/PRIMARY |
| 9 | GSUT Nameplate / UAT Nameplate as above | FOUND | same folder | SOURCE/PRIMARY |
| 10 | UAT Nameplate_South.pdf | FOUND | same folder | SOURCE/PRIMARY |
| 11 | PGCB Line data.pdf (regional inventory; Ghorasal 44 km Mallard / Comilla 79 km Finch / Sirajganj 144 km Twin AAAC â€” none proven as South tap) | FOUND as regional list; MISSING as South proof | same folder | MISSING-as-South-proof (CONFLICT-DOCUMENTED) |
| 12 | JICA/PGCB Mallard parameter file (12248464.pdf family) | MISSING (file; cited second-hand only) | filename search zero hits | MISSING |
| 13 | Phase-2 final report + evidence bundle | FOUND | PHASE2_FINAL_REPORT.md; docs/validation/rev31_phase2/ | SOURCE/PRIMARY |
| 14 | Phase-3 final report + changelog | FOUND | PHASE3_FINAL_REPORT.md; PHASE3_CHANGELOG.md | SOURCE/PRIMARY |
| 15 | Phase-3 MATLAB data (lines/grid/buses/transformers/profiles) | FOUND (read-only) | matlab/data/ashuganj_*.m | DERIVED / ENGINEERING_ASSUMPTION per field |
| 16 | Phase-3 load-flow results (bus results 54 rows, system summary 6 rows, .mat) | FOUND | results/phase3_loadflow/ | DERIVED validation |
| 17 | Rev2 fault/sequence files + results + reports | FOUND (read-only) | rev2/ | LEGACY / HISTORICAL-ONLY candidate (Sec 24) |
| 18 | Provenance ledgers + data-request documents | FOUND | rev2/data/reconciliation_register.csv; docs/DATA_TO_COLLECT.md; docs/ENGINEER_DATA_REQUEST_NEXT_PHASE.md | HISTORICAL / request list |
| X1 | INEL-112070-00-ELC-DE-0026 (authoritative 230-kV GIS drawing) | MISSING | zero filename hits | MISSING (bay number + destination substation unknown) |
| X2 | Full Siemens S001 report (39 pp + Attachment 1) + turbine doc | MISSING (partial only via item 2) | â€” | MISSING |
| X3 | Standalone GAT document | MISSING (covered inside item 8) | â€” | MISSING (partial coverage) |

Exact source wordings verified by text-layer inspection (see Appendix B): NER heading (V1 = 22 kV/3, V2 = 500 V, TRU 25.4, 135 kVA / 20 s, RHV-DC 60 ?, R1 2.62 ??); UAT LV neutral "Accessible to be earthed through impedance that limits the fault to 5A"; GAT HV neutral "Accessible to be solidly earthed" vs GAT LV neutral "Accessible to be earthed through impedance that limit the fault to 5A"; GIS device codes 52-1(Q0) / 89B2-1(Q1) / 89B1-1(Q2) / 89-1(Q9) / 57-1(Q8/Q51/Q52).

## Sec 5 â€” Provenance ledger

Closed enum only. Rationale holds human-readable finer notes without new executable statuses.

| Parameter | Value | Unit | Base | Source | Locator | Status | Rationale |
|---|---|---|---|---|---|---|---|
| south R1/X1/Y1 | 0.00015 / 0.00077 / 0.001488 | pu/km | 100 MVA / 230 kV | Mallard family ref (file MISSING) | PHASE3_FINAL_REPORT.md:53,61; lines.m:79,81 (Y1 report-only) | ENGINEERING_ASSUMPTION | Frozen reference, never PRIMARY (JICA file MISSING) |
| south R_eq/X_eq/B_eq | 0.0277725 / 0.1425655 / 3.937996 | ohm/ohm/microS | 100 MVA / 230 kV | Frozen D/C equivalent 0.7 km | PHASE3_FINAL_REPORT.md:19,61; lines.m:78,80,82-83 | ENGINEERING_ASSUMPTION | R_eq = r1Â·L/2 etc. (REPORT Â§11 chain) |
| south length/circuits/conductor | 0.7 / 2 / MALLARD_795_MCM | km/-/â€” | physical | Locked planning basis | PHASE3_FINAL_REPORT.md:49; lines.m:71,74-77 | ENGINEERING_ASSUMPTION | Reference only, not measured South link |
| south R0/X0/B0 | (band, Sec 14) | ohm | 100 MVA / 230 kV | Reference band on frozen parents | lines.m:84-86 (NaN); this spec Sec 14 | MISSING (source) / ENGINEERING_ASSUMPTION (band) | Never 3X1/R1/B1 as fact |
| gen Snom/Vnom | 458 / 22 | MVA/kV | machine | Workbook C3/D3 + Siemens Â§2.1 + nameplate | generators.m:72,74; Gen Data p.1 | SOURCE/PRIMARY | Multi-source corroborated |
| gen Xd/Xd'/Xd''unsat/Xd''sat | 1.7830 / 0.3256 / 0.2608 / 0.2248 | pu | 458 MVA / 22 kV (QUALIFIED interp.) | Workbook H3/I3/J3/K3; K3 dual-attested Siemens Â§2.1.1 22.48% | generators.m:77-80 | SOURCE/PRIMARY (Xd''_sat DIRECTLY-SOURCE-BACKED saturated; others WORKBOOK-DERIVED+QUALIFIED) | Saturation/base UNQUALIFIED except Xd''_sat; never claim Siemens verification beyond Â§2.1.1 |
| gen Xq/Xq'/Xq''/Xl | 1.7510 / 0.5087 / 0.2593 / 0.2027 | pu | same (QUALIFIED) | Workbook L3/M3/N3/O3 | generators.m:81-84 | SOURCE/PRIMARY (WORKBOOK-DERIVED+QUALIFIED) | No q-axis data in surviving Siemens extract |
| gen X2 | 0.2242 | pu | same (QUALIFIED) | Workbook P3 "X2 (sat)" | generators.m:85 | SOURCE/PRIMARY (WORKBOOK-DERIVED+QUALIFIED, SAT per workbook heading) | Project-data entry, NOT Siemens-OEM-verified; distinct cell from K3 |
| gen X0 | 0.128 | pu | same (QUALIFIED) | Workbook Q3 "X0 (sat)" | generators.m:86 | SOURCE/PRIMARY (WORKBOOK-DERIVED+QUALIFIED, SAT per workbook heading) | Project-data entry, NOT Siemens-OEM-verified |
| gen Ra | 0.00089 | ohm | stator | Workbook U3 (ohm explicit) | generators.m:87 | SOURCE/PRIMARY (WORKBOOK-DERIVED+QUALIFIED) | Temp/test conditions not supplied |
| NER device/V1/V2/rating | 10BAB11 / 22/sqrt(3) kV / 500 V / 135 kVA / 20 s | â€”/kV/V/kVA/s | neutral | Siemens Â§2.3 NER clause | Gen Data p.1/report p.6 Â§2.3 | SOURCE/PRIMARY | High-resistance arrangement (NGT + loading resistor) |
| NER R_HV_quoted | ~60 | ohm | HV side | Same clause (RHV-DC heading) | Gen Data Â§2.3 | SOURCE/PRIMARY (quoted figure) | Read as HV winding DC resistance per heading; separate row from R_loading |
| NER R_loading | 2.62 | ohm | 500-V secondary | Same clause | Gen Data Â§2.3 | SOURCE/PRIMARY | Physical secondary resistor |
| NER R_NER_HV (reconciled) | â‰ˆ 1750.773333 | ohm | HV side | Derived: 60 + nÂ²Â·2.62 | This spec Sec 10 (eqs. 10-1â€“10-4) | DERIVED (conditional on heading reading) | Pre-NGT-reactance; see Sec 10 conditional |
| NER 3ZN | â‰ˆ 5252.32 (â‰ˆ 4970.1706 pu mach.) | ohm (pu) | 22-kV / 458 MVA-22 kV | 3Ã—R_NER_HV (resistive-dominant) | Sec 10 | DERIVED check | Zero neutral branch only |
| NGT series Z | â€” | ohm | HV side | â€” | â€” | MISSING | Neglected-vs-bounded rule (Sec 10) |
| GSUT Z/R/Z0 | 16.0 / 0.21 / 15.8 | % | 515 MVA 230/22 kV tap 9 | GSUT sheet + nameplate | transformers.m:121-132 | SOURCE/PRIMARY | YNd1; Z0 test-connection QUALIFIED reading; plates blank = NOT_APPLICABLE |
| GSUT HV neutral | solid (ZN = 0) | ohm | 230-kV neutral | Connection Yg; no device in source set | transformers.m:108 | ENGINEERING_ASSUMPTION | Stated position, not measured record |
| UAT Z/R/Z0 | 10.5 / â‰ˆ0.4 / â‰ˆ9.3 | % | 25 MVA 22/6.9 kV tap 3 | UAT sheet + nameplate | transformers.m:218-225 | SOURCE/PRIMARY | Dyn11; â‰ˆ markers preserved |
| UAT 5-A limit | 5 | A | 6.9-kV LV | UAT sheet LV-neutral clause | UAT sheet Â§LV neutral | SOURCE/PRIMARY (limit constraint) | Current limit, NOT impedance |
| UAT ZN_UAT_LV | â‰ˆ 796.743 | ohm | 6.9-kV neutral | Derived: (6900/sqrt(3))/5 | Sec 12 eq. 12-3 | DERIVED ENGINEERING_ASSUMPTION | Bounded equivalent, IN = 3I0 reading |
| UAT Z3N_UAT_equiv (stamped) | ~2390.23 | ohm | 6.9-kV neutral zero branch | 3xZN_UAT_LV, single-counted HERE only | Sec 12 / phase4_grounding.m:121 | DERIVED ENGINEERING_ASSUMPTION | STAMPED zero-branch value (single x3, never downstream); physical value stays ZN_UAT_LV |
| UAT/LV device R/X | â€” | ohm | LV neutral | â€” (10BBW10 candidate unresolved) | â€” | MISSING | Bounded rule (Sec 12) |
| GAT Z_PS/R | â‰ˆ12.0 / â‰ˆ0.5 | % | 25 MVA 230/6.9 kV tap 13 | GAT-in-UAT-docs (S/N 100580) | transformers.m:294-298 | SOURCE/PRIMARY (pairwise HVâ€“LV only) | Pairwise-INCOMPLETE |
| GAT Z0_PS | â‰ˆ10.8 | % | 25 MVA | Same set | transformers.m:299-300 | SOURCE/PRIMARY (pairwise) | Test-connection QUALIFIED reading |
| GAT Z_PT/Z_ST | â€” | % | 25 MVA | â€” | transformers.m:301-304 | MISSING | Three-winding exact model impossible |
| GAT HV neutral | solid (ZN = 0) | ohm | 230-kV neutral | "Accessible to be solidly earthed" | UAT/GAT sheet GAT clause | ENGINEERING_ASSUMPTION | Source-supported wording, no device data |
| GAT LV neutral equiv. | â‰ˆ 796.743 | ohm | 6.9-kV neutral | Derived: (6900/sqrt(3))/5 from 5-A clause | Sec 13 | DERIVED ENGINEERING_ASSUMPTION | "Earthed through impedance that limit the fault to 5A" â€” NOT solid |
| GAT Z3N_GAT_equiv (stamped) | ~2390.23 | ohm | 6.9-kV neutral zero branch | 3xZN_GAT_LV, single-counted HERE only | Sec 13 / phase4_grounding.m:122 | DERIVED ENGINEERING_ASSUMPTION | STAMPED zero-branch value (single x3, never downstream); physical value stays ZN_GAT_LV |
| LV Vbus nominal (R.lv) | 6.6 | kV | plant MV bus | phase3_bus_results.csv Vnom_kV column (B6_6 rows) | phase4_registry.m:26 | SOURCE/PRIMARY | pu base voltage of LV zone; never the winding voltage |
| LV Vwind nominal (R.lv) | 6.9 | kV | transformer LV winding | UAT/GAT data sheets (LV winding rating) | phase4_registry.m:27 | SOURCE/PRIMARY | winding nominal; distinct from 6.6-kV bus |
| LV Zbase (R.lv) | 0.4356 | ohm | 100MVA-6.6kV | 6.6^2/100 arithmetic | phase4_registry.m:28 | DERIVED | ohmic base of LV zone; aux/neutral pu conversions use this, never 529 |
| LV tap nominal (R.lv) | 1.045454545 | dimensionless | physical | Vwind/Vbus 6.9/6.6 documented ratio | phase4_registry.m:29 | DERIVED | off-nominal LV tap magnitude; checked by L22 tap sanity (residual 0) |
| Zbase_22 | 4.84 | ohm | 100MVA-22kV | 22^2/100 arithmetic | phase4_registry.m:25 | DERIVED | level base for 22-kV Zf reporting (spec Sec 21) |
| GAT Z_T0_loop base/low/high | 0.108 / 0.054 / 0.216 | pu | 25 MVA | lambda_T Ã— Z0_PS (1.0/0.5/2.0) | Sec 13 | ENGINEERING_ASSUMPTION | Equivalent circulating-tertiary loop, NOT Z_PT/Z_ST; dual identity 0.108 pu on 25-MVA base = 0.432 pu stamped on 100-MVA base (L24 loop identity, residual 0); H2 = 1e-6 short-limit limiting sensitivity / stress case on the 100-MVA base (never proof; phase4_seqZ.m:205-221) |
| Grid Ik''/Sk''/|Z1| (P) | 50 / 19918.58 / 2.65581124 | kA/MVA/ohm | 230 kV | Siemens Â§2.4 estimate | Gen Data p.2; grid.m:68-120 | SOURCE/PRIMARY (Ik: Level-1 Siemens direct source with ESTIMATED qualifier) / DERIVED (|Z|, Sk) | Siemens own word estimated; confidence inherited as estimate, never firm |
| Grid XN reported | 2.66 | ohm | 230 kV | Siemens Â§2.4 rounded | Gen Data Â§2.4 | ENGINEERING_ASSUMPTION | Separately reported; never paired with |Z| |
| Grid X/R (P) | [10, 20], base 15 | â€” | 230 kV | Reference band (no source pair) | Sec 15 | ENGINEERING_ASSUMPTION (band) | R â‰ˆ 0.17666194, X â‰ˆ 2.64992904 at base |
| Grid Ik/X/R (S) | 45.01 / 10.99 | kA/â€” | 230 kV | Secondary 2019 compilation | Master-Data md:524-543 | LEGACY | Sensitivity only; derived |Z| â‰ˆ 2.950246, R â‰ˆ 0.267344, X â‰ˆ 2.938108 (c = 1) |
| Grid Z0 | k0g Ã— Z1, k0g [1.0, 1.5, 2.0] base 1.5 | â€” | 230 kV | Band per dataset | Sec 15 | ENGINEERING_ASSUMPTION Ã— dataset confidence | Same-angle scaling is simplification + independent R/X sensitivity |
| Prefault LF360 OUT/IN | 360.00 / 360.00 | MW | plant | Operating profiles | profiles.m:36-37; phase3 CSVs | SOURCE/PRIMARY (PRIMARY_VERIFIED) | Per-case EMF pair |
| Zf base / earth / phase | 0 / 0.01 pu / 0.002 pu | pu local base | fault level | Design base + sensitivity | Sec 21 | DESIGN BASE / ENGINEERING_ASSUMPTION | Ohmic equivalents tabulated (Sec 21) |

## Sec 6 â€” Positive sequence

1. Machine base 458 MVA / 22 kV (QUALIFIED interpretation: rating-derived, no separate literal base declaration). Network base frozen 100 MVA / 230 kV, Zbase = 529 ohm.
2. Generator enters as series impedance behind the Sec-9 source: steady (Xd = 1.7830, Xq = 1.7510, saliency retained), transient (Xd' = 0.3256, Xq' = 0.5087), subtransient (Xd''_sel + Ra). No silent round-rotor substitution.
3. Reactance transfer same level: X_sys = X_mach Ã— (S_sys/S_mach). Across 22 â†” 230 kV the implementation states the voltage-ratio treatment explicitly. Transformer % â†’ pu on own rating via X = sqrt(ZÂ²âˆ’RÂ²), then S-ratio transfer.
4. Ra transfer: Ra_pu_mach = 0.00089/Zbase_mach; retained in derivation chain; omission per stage needs stated justification, never silent.
5. GSUT positive: Z1 = (0.21% + jX)/100 pu on 515 MVA, X DERIVED, tap 9 nominal, series total governing (per-winding split is representation only). YNd1 âˆ’30Â° HVâ†’LV shift carried to phase reconstruction (negative conjugate, Sec 7/17).
6. UAT positive: Z1 from 10.5% / â‰ˆ0.4% on 25 MVA tap 3; branch B22 â†’ B6_6 in positive network for aux flow + contribution accounting.
7. GAT positive view: two-winding Z_PS â‰ˆ 12% / â‰ˆ0.5% HVâ€“LV abstraction on 25 MVA tap 13 â€” exact for BALANCED load flow with unloaded tertiary omitted; APPROXIMATION ONLY for faults (tertiary decision Sec 13). GAT IN/OUT loop closure follows prefault case.
8. South-line positive: frozen lumped dual-circuit PI (R_eq/X_eq/B_eq, endpoints L_LINE B230_1 â†’ B230_REMOTE). m-division + circuit-split rules Sec 18. Zero (MISSING) Sec 14; NER Sec 10; grid R/X Sec 15; EMF/Xd'' Sec 9; X2 Sec 7 (not here); X0 Sec 8 (not here).

## Sec 7 â€” Negative sequence

1. Generator: Z2_gen = Ra_pu_mach + jÂ·X2, X2 = 0.2242 pu machine base (QUALIFIED). Sourceless network (no EMF; prefault is balanced positive). X2 is workbook project-data SOURCE/PRIMARY with QUALIFIED rationale (SAT per workbook heading); Siemens verification NEVER claimed. X2 (P3) vs Xd''_sat (K3) are DISTINCT cells; never merged/averaged/substituted (0.0006 pu proximity is coincidence).
2. Transformers: Z2 = Z1 per unit with STATED rationale (static, non-rotating, linear passive plant; identical leakage path for both phase orders at 50 Hz; no contrary test data). Status DERIVED (justified equality) inheriting parent confidence. Conjugate phase-shift handling (Â±30Â° YNd1/Dyn11; GAT 0Â°) applied in reconstruction (Sec 17).
3. South line: R2 = R1, X2_line = X1, B2 = B1 on frozen totals (JUSTIFIED for short passive symmetric 0.7-km plant at 50 Hz; earth-return asymmetry is zero-sequence-only). m-division and branch-split rules identical to positive (Sec 18). Inter-circuit negative mutual NEGLECTED BY CONSTRUCTION (second-order at lumped-PI scale; stated, never hidden).
4. Grid: Z2_grid = Z1_grid WITHIN EACH dataset (meshed-Thevenin approximation absent contrary data; machine d/q asymmetry averages at equivalent level), inheriting dataset confidence (ESTIMATED primary / LEGACY sensitivity). Phase-3 Rgrid = 0 NEVER enters. Residual negative-specific R/X doubt rides sensitivity A2r (same-|Z|, perturbed-X/R, ENGINEERING_ASSUMPTION, admitted only with recorded need).
5. NER impedance NEVER appears in negative sequence (no neutral leg, no 3x factor).

## Sec 8 â€” Zero sequence

1. Generator branch (sourceless): terminal zero node (B22 zero) â€” Z0_gen = Ra_pu_mach + jÂ·0.128 â€” neutral node N â€” 3Â·ZN â€” EARTH. X0 = 0.128 pu machine base (QUALIFIED), workbook project-data, no Siemens claim. 3x factor AFTER pu conversion (order stated, result identical). X0/Xd''_sat/X2 never merged.
2. GSUT leg: HV zero node (B230_1 zero) â€” Z0_GSUT = 15.8% (515 MVA, QUALIFIED test-connection reading) â€” HV neutral node â€” ZN = 0 solid (ENGINEERING_ASSUMPTION) â€” EARTH. LV zero terminals (B22 zero) OPEN (LV delta block). NO HVâ†”LV zero transfer either direction. Positive/negative transfer preserved.
3. UAT leg: LV zero node (B6_6 zero) â€” Z0_UAT â‰ˆ 9.3% (25 MVA, â‰ˆ + QUALIFIED test reading) â€” LV neutral node N_UAT â€” ZN_UAT_LV (Sec 12 bounded equivalent) â€” EARTH. HV zero terminals (B22 zero) OPEN (HV delta block). Confined to B6_6 aux-bus earth faults; small by construction.
4. GAT block: two-winding HVâ€“LV zero through-path (Z0_PS â‰ˆ 10.8% pairwise, tertiary OPEN as H0 / closed equivalent as H1 base per Sec 13) with HV teeâ†’earth (solid ASSUMPTION) and LV teeâ†’earth (5-A equivalent per Sec 13). Closed d11 tertiary is a circulating path with NO neutral (no tertiary ZN exists). GAT IN/OUT gating per case. B6_6 UAT + GAT LV neutrals are EXPLICIT PARALLEL branches, never lumped. No tertiary fault location. LL/LLL invariance across H-legs required (Sec 23).
5. South-line zero: lumped dual-circuit PI zero branch B230_1 zero â†” B230_REMOTE zero, R0_eq = kRÂ·R_eq, X0_eq = kXÂ·X_eq, B0_eq = kBÂ·B_eq (Sec 14 band), C0 = B0/(2Ï€Â·50). m-division + split per Sec 18. Inter-circuit Z0m: base IGNORED BY CONSTRUCTION (no second branch at lumped level â€” representation fact, not physics claim); explicit-variant APPROXIMATED-as-ignored with stated NON-CONSERVATIVE direction (understates effective zero, overstates LG/LLG current); explicit Z0m modelling FORBIDDEN without geometry/soil data.
6. Grid zero: B230_REMOTE zero â€” Z0_grid(ds) = k0gÂ·Z1_grid(ds) â€” EARTH, per dataset (never merged), k0g âˆˆ [1.0, 1.5, 2.0] base 1.5 (ENGINEERING_ASSUMPTION ratio Ã— dataset confidence). MISSING as data in both datasets. Same-angle scaling is an ENGINEERING SIMPLIFICATION plus mandatory independent zero R/X sensitivity (Sec 22-A). Phase-3 R = 0 NEVER enters.
7. Aux-load Y(grounded) LF shunt EXCLUDED (OPEN) from fault zero base (no neutral data; downstream LV deltas block regardless; UAT/GAT LV legs carry legitimate B6_6 paths). Stated, never hidden.
8. Gating: entire zero network ENERGISED for LG/LLG (Zf per Sec 21), DEAD for LLL/bolted LL. Per-location legs: B22/F2 â†’ generator branch ONLY (GSUT LV OPEN, UAT HV OPEN, grid/line zero carry no current); F3 (coupler-closed one node) â†’ GSUT HV + line zero (m = 0 end) + grid Z0 + GAT loop if IN (NER excluded); F4 â†’ line zero divided per m-rule fed from both ends (plant side + grid side), GAT per H-leg; F5 â†’ grid Z0 dominant + full line zero from plant side; B6_6 (auxiliary validation-only) â†’ UAT LV leg IN PARALLEL WITH GAT LV leg (per-run split reported; GAT OUT leaves UAT-only small current).
9. Conventions: passive sign; nodeâ†’earth drops; ohms + pu WITH bases printed (bare Z0 forbidden); machine Z0_pu = Z0_ohm/(22Â²/458); study transfer with stated cross-voltage treatment; line/grid Z0_pu = Z0_ohm/529; I0 = (Ia+Ib+Ic)/3, IN = 3Â·I0; KCL residuals logged per zero node.

## Sec 9 â€” Generator EMF

1. Cases: PRIMARY pair LF360_GAT_OUT (360.00 MW, radial) / LF360_GAT_IN (360.00 MW, looped), PRIMARY_VERIFIED. LF342 qualified and LF389P30 historical (+ LF1â€“LF4 aliases) are sensitivity-only with labels preserved, never PRIMARY.
2. Extraction per case (from phase3_bus_results.csv + phase3_system_summary.csv + .mat; implementation reads files, never reruns LF): B22 V_kV + angle (magnitude AND angle; slack BGRID230 = 0Â°); Gen P/Q (P frozen 360 MW; Q differs OUT vs IN â€” proof against shared EMF); aux 14 MW / 8.676421 MVAr frozen; transformer taps frozen nominal; GAT/UAT/coupler states per case (coupler CLOSED base); grid slack 1.00 pu; V_REMOTE_kV (Ã·230) â€” NEVER solver-base V_REMOTE_pu (â‰ˆ2.297 determinism-test field).
3. Equations (pu machine base unless stated; j = âˆšâˆ’1; degâ†’rad at I/O; St leaving machine):
   (9-1) |Vt_c| = V_B22_kV(c)/22; (9-2) Î¸t_c = Angle(B22,c)Â·Ï€/180; (9-3) Vt_c = |Vt_c|(cosÎ¸t_c + jÂ·sinÎ¸t_c);
   (9-4) St_c = P_MW + jQ_MVAr; (9-5) St_pu = St_c/458; (9-6) It_c = conj(St_pu/Vt_c).
   Subtransient: (9-7) Z''_sel = Ra_pu_mach + jÂ·Xd''_sel; (9-8) E''_c = Vt_c + Z''_selÂ·It_c (complex, per case; PRIMARY Xd''_sat = 0.2248, SENSITIVITY Xd''_unsat = 0.2608; Ra retained).
   Primary form is classical round-rotor subtransient approximation (unsat pair spread 0.6%, negligible); with PRIMARY saturated selection the d/q spread (â‰ˆ15% vs Xq'' 0.2593, whose saturation is UNQUALIFIED) requires the Sec-22-D saliency sensitivity â€” error bounded, not hidden. No third Xd'' value.
   Transient (two-axis normative; Xd' = 0.3256 vs Xq' = 0.5087, 56% spread â€” saliency NOT negligible): (9-9) Î´c = arg(Vt_c + (Ra + jXq)Â·It_c), Xq = 1.7510; (9-10) Park projection (Vd,Vq,Id,Iq) with implementation's Park sign convention stated once and used consistently; (9-11) E'd_c = Vd_c + Xq'Â·Iq_c, E'q_c = Vq_c âˆ’ Xd'Â·Id_c (+Ra per convention). Documented Xd'-only fallback E'_c = Vt_c + (Ra + jXd')Â·It_c permitted ONLY as labelled APPROXIMATION with mandatory two-axis sensitivity. Time constants parameterise between-stage decay (Sec 19), not the source anchor.
   Steady: (9-12/9-13) Eq_c from (Vd,Vq,Id,Iq) with Xd = 1.7830 / Xq = 1.7510, CONSTANT FIELD (no AVR/governor/SFC); S10/S12 not a full OCC; Rf (UNRESOLVED) NEVER in any source equation.
4. EMF in pu at 22-kV level transfers numerically unchanged across S-bases; impedances scale by S-ratio; cross-voltage treatment stated explicitly.
5. Selection: PRIMARY Xd''_sat = 0.2248 (faults start at â‰ˆ1.0 pu flux; only reactance with manufacturer corroboration); SENSITIVITY Xd''_unsat = 0.2608 (high-Z/low-I bound + interpretation cover). Never averaged/merged; legacy triple is same transcription, not third case; X2/X0 never Xd''.
6. Stage mapping: Ik'' â† E''_c (+E''_alt sensitivity); Ib â† E'd/E'q (fallback only per above); steady â† Eq_c. Same case-c prefault feeds all three sources; same Xd'' role in E'' derivation AND Ik'' network (never saturated EMF with unsaturated network X).
7. Forbidden: Vprefault/Xd'' or E = Vprefault or 1âˆ 0Â° without (9-1)â€“(9-8); |V|-only EMF; shared OUT/IN EMF; recomputed/relabeled prefault; V_REMOTE_pu as 230-kV pu; averaging/merging Xd'' values; X2/X0 as Xd''; Rf in sources.

## Sec 10 â€” Generator NER

1. Device 10BAB11: V1 = 22/sqrt(3) kV (phase-to-ground, no further sqrt(3) in reflection), V2 = 500 V, rating 135 kVA / 20 s (short-time basis; 20 s is NOT a clearing-time input). All SOURCE/PRIMARY (Siemens Â§2.3 clause).
2. Exact source-heading evidence: the clause table carries "Rated apparent power / HV-winding resistance â€¦ 135 kVA / 20 s", then "RHV-DC â€¦ 60 â€¦ ?" and "R1 â€¦ 2.62 â€¦ ??" with TRU 25.4. The 60-ohm quantity is therefore read as the HV winding DC resistance and the 2.62-ohm quantity as the secondary loading resistor â€” SEPARATE source rows. (TRU 25.4 corroborates the ratio arithmetic below.)
3. Reflection (ohms; ideal single-phase ratio; NGT series handled separately):
   (10-1) n = V1/V2 = (22000/sqrt(3))/500 â‰ˆ 25.40341184.
   (10-2) Z_HV = nÂ²Â·Z_LV (general secondary-to-primary).
   (10-3) R_refl = nÂ²Â·2.62 â‰ˆ 1690.773333 ohm (design transfer of the physical resistor).
4. Equivalent neutral impedance: (10-4) ZN = R_NER_HV + Z_NGT_series_HV, phase-neutral ohms at 22-kV level.
   Recommended interpretation: R_NER_HV = 60 + 1690.773333 â‰ˆ 1750.773333 ohm (pre-NGT-reactance), because the 60-ohm row is the HV winding DC resistance, not a complete equivalent. CONDITIONAL: if later exact-source evidence proves the 60-ohm number is an already-reflected complete equivalent INCLUDING the secondary resistor, do NOT add (adopt 60-ohm-class figure with both rows cited). The implementation SHALL NOT choose either 60 OR 1690.77 alone unless exact source wording proves inclusion. Resistor dominance intended (Re >> Im after treatment); R/X split reported; no un-sourced reactance injected.
5. NGT series/magnetising MISSING: adopt (a) NEGLECT (Z_NGT_series_HV = 0) with resistor-dominance justification, or (b) BOUNDED uk%-style ENGINEERING_ASSUMPTION with justification + sensitivity (Sec 22-E). Either way never SOURCE/PRIMARY; magnetising neglected-open, stated.
6. Zero-sequence entry: (10-5) 3Â·ZN in series in the GENERATOR NEUTRAL branch ONLY (V_N = ZNÂ·(3Â·I0) âŸº V0_drop = (3Â·ZN)Â·I0). NEVER in positive/negative; NEVER 1xZN in zero except labelled error-check sensitivity. Derived checks: 3Â·ZN â‰ˆ 5252.32 ohm; machine Zbase 22Â²/458 â‰ˆ 1.056768559 ohm; 3ZN â‰ˆ 4970.1706 pu machine base (not new source data). Pu: ZN_pu_machine = ZN_ohm/Zbase_machine; study transfer by S-ratio same level; 3x AFTER conversion (order stated). Report ohms + both pu bases; bare ZN forbidden.
7. Gating: Nâ€“earth leg ENERGISED for LG/LLG, DEAD for LLL/bolted LL. Generator earth current limited PRINCIPALLY by 3Â·ZN (+ jX0_gen); NER participates in NO 230-kV/line/remote fault (GSUT delta block, Sec 11).
8. Checks (equations, no results): print n with locators; evaluate (10-3) + record reconciliation outcome (i) AGREE within tolerance â†’ adopt reconciled value citing both rows, or (ii) DISAGREE â†’ keep both visible, adopt one primary with physical rationale, carry other as Sec-22-E sensitivity (never edit source values); thermal-consistency S_2_check = V2_faultÂ²/R_loading vs 135 kVA/20 s (flag only); NER-dominance share |3Â·ZN|/|jX0_gen + 3Â·ZN| diagnostic.
9. Rev2 solid grounding (registry Earthing = 'Solidly grounded') REJECTED. ZN = 0 as primary FORBIDDEN. Rev2 solid-grounded LG/LLG quantities HISTORICAL-ONLY, never seed/verify Phase-4 earth values.

## Sec 11 â€” GSUT

1. 10BAT10, YNd1, 230/22 kV, 515 MVA (ODAF impedance base; loading vs 355/460/515 stages). SOURCE/PRIMARY.
2. Positive: Z = 16.0%, R = 0.21% at principal tap 9 (nominal; no off-nominal correction). X = sqrt(ZÂ²âˆ’RÂ²) DERIVED. Series total governs (per-winding split representation-only). Tap extremes (16.9/15.5%) recorded, forbidden as inputs.
3. Negative: Z2 = Z1 (justified static-plant equality, Sec 7). YNd1 âˆ’30Â° HVâ†’LV; negative conjugate +30Â° in reconstruction.
4. Zero: HV zero node (B230_1 zero) â€” Z0 = 15.8% series (515 MVA; QUALIFIED test-connection reading: winding excited / delta state unstated in surviving extract) â€” HV neutral â€” ZN = 0 solid (ENGINEERING_ASSUMPTION; no neutral device in source set) â€” EARTH. LV zero terminals OPEN (delta block). NO HVâ†”LV zero transfer either direction. HV-neutral leg ENERGISED for HV/line/remote LG/LLG, DEAD for LLL/LL and for all LV-side views. Magnetising shunt neglected-open in fault networks (stated). Core construction MISSING â€” non-gating (no tank correction invented; no core sweep; Z0 tolerance sensitivity covers residual).
5. Sensitivity: Z0 test-connection/tolerance bounded Â±tolerance (base 15.8% as given); HV-neutral solid-vs-finite labelled error-check only if admitted (base solid, never presented as measured).
6. Rev2 Z0 = Z1 C-rule REJECTED (superseded by measured-type 15.8%).

## Sec 12 â€” UAT

1. 10BBT10, Dyn11, 22/6.9 kV, 19/25 MVA (impedance base 25 MVA), LV LEADS HV 30-degree (applied as documented nominal LV tap a = 6.9/6.6 = 1.045454545 on the 6.9-kV winding basis with 6.6-kV bus reporting; tap sanity L22 residual 0; B6_6 prefault-reproduction gate 0.05 bounds the shift treatment, L21 OUT 0.025691 / IN 0.028839; wider vector-shift angle behaviour beyond this applied treatment is a pre-existing limitation (conjugate in negative). SOURCE/PRIMARY.
2. Positive/negative: Z = 10.5%, R â‰ˆ 0.4% (approximate marker preserved) at principal tap 3 (off-circuit; nominal ratio is physical fact). X DERIVED. Branch B22 â†’ B6_6 in pos/neg networks.
3. Zero: LV zero node (B6_6 zero) â€” Z0 â‰ˆ 9.3% (25 MVA; â‰ˆ + QUALIFIED test reading) â€” N_UAT â€” ZN_UAT_LV â€” EARTH. HV zero terminals OPEN (HV delta block; mirror of GSUT block).
4. LV neutral: SOURCE constraint is the 5-A ground-fault limit ("Accessible to be earthed through impedance that limits the fault to 5A"). Device R/X MISSING (10BBW10 cubicle candidate unresolved). Primary reading: 5 A is the LV ground/neutral current limit, IN = 3Â·I0 â‰ˆ 5 A. Equivalent (12-3): |ZN_UAT_LV| = Vph_LV/I_lim_bound, Vph_LV = 6900/sqrt(3) â†’ ZN_UAT â‰ˆ 796.743 ohm. This is a DERIVED ENGINEERING equivalent of the 5-A constraint â€” NOT measured device resistance, NEVER SOURCE/PRIMARY. R/X split stated (resistive-dominant expected physics; any X needs ASSUMPTION label + justification + sensitivity).
5. Mandatory sensitivity: alternative 5-A reading (I0 or faulted-phase current; e.g. 5 A as I0 â†’ â‰ˆ265.581 ohm) + R/X-split uncertainty. Joint L1+H3 with GAT at B6_6 (Sec 22).
6. Contribution: UAT zero ONLY for B6_6 aux-bus earth faults (SMALL bounded share, reported diagnostic); NO zero to 22-kV/230-kV/line/remote faults (HV-delta block). Pos/neg current anywhere the divider drives it (passive branch, never a source; no motor infeed invented).
7. Dual-base rule: winding physics on 6.9 kV; MV-bus pu REPORTING on 6.6-kV system nominal (Um 7.2 kV). Both bases printed beside every ohmicâ†”pu figure; 6.6 kV as winding voltage FORBIDDEN (â‰ˆ4.5% error).

## Sec 13 â€” GAT + tertiary

1. 10BBT20, YNyn0+d11, 230/6.9/3.32 kV, 19/25 MVA, tertiary â‰ˆ 8.33 MVA. HV star earthed + LV star earthed, 0Â° HVâ†’LV; d11 stabilising tertiary (no external terminals, no bus, no load). SOURCE/PRIMARY (figures inside UAT-doc set; NO standalone GAT doc â€” partial coverage, never a complete 3-winding source).
2. Known pairwise (HVâ€“LV, principal tap 13, 25 MVA): Z_PS â‰ˆ 12%, R â‰ˆ 0.5%, Z0_PS â‰ˆ 10.8% (Â±7.5% tolerance per IEC 60076-1). Z_PT and Z_ST MISSING â†’ full three-winding exact sequence model (13-1â€“13-3 star-equivalent forms) UNDERSPECIFIED. Z_PT/Z_ST NEVER fabricated.
3. Grounding (CORRECTED): HV neutral solid-to-earth ASSUMPTION ("Accessible to be solidly earthed"; no device data). LV neutral NOT solid: "Accessible to be earthed through impedance that limit the fault to 5A" â†’ primary engineering equivalent ZN_GAT_LV â‰ˆ (6900/sqrt(3))/5 â‰ˆ 796.743 ohm (DERIVED ENGINEERING_ASSUMPTION, not measured resistor data). Previous "both neutrals solid" statements are REMOVED everywhere.
4. Base zero model: explicit equivalent circulating-tertiary representation (NOT Z_PT/Z_ST): Z_T0_loop = lambda_TÂ·Z0_PS on 25-MVA common base; lambda_T_base = 1.0 â†’ Z_T0_loop,base â‰ˆ 0.108 pu; compact sensitivity lambda_T_LOW = 0.5 â†’ â‰ˆ0.054 pu, lambda_T_HIGH = 2.0 â†’ â‰ˆ0.216 pu (all ENGINEERING_ASSUMPTIONS; loop of the closed tertiary, not pairwise impedances). Legs: H0 = tertiary-open approximation; H1 = closed-tertiary equivalent base (lambda 1.0); H2 = tertiary-short limiting check. H0/H1/H2 are approximation/sensitivity legs, not measurements. Closed delta LOWERS Z0 vs open â†’ open omission is NON-CONSERVATIVE for LG/LLG current (conservative for retained voltage); hence H-legs MANDATORY. Tertiary affects LG/LLG zero ONLY; LL/LLL invariance across H-legs asserted and validated (Sec 23).
5. Positive/negative: two-winding HVâ€“LV abstraction Z1 = Z2 (within pairwise-incomplete caveat), branch B230_2 â†’ B6_6, 0Â° shift both sequences. Exact for balanced LF (unloaded tertiary omitted); approximation for faults (labelled + warning + H-legs wherever shown). GAT 0-degree HV-to-LV shift both sequences is the applied treatment (see item 1 YNyn0+d11 0-degree note); wider vector-shift angle behaviour beyond 0 degrees is a pre-existing limitation.
6. Topology: GAT OUT â†’ branch OPEN all sequences (leg ABSENT, not zero-filled). GAT IN â†’ branch CLOSED per above with H-legs. Never one shared state across OUT/IN. B6_6 UAT + GAT LV neutrals EXPLICIT PARALLEL branches, never lumped; per-run split reported WITHOUT pre-judged "dominant" labels (dominance determined numerically). No tertiary fault location. Mandatory GAT-touching locations: GIS bus / B230_2 side and B6_6.
7. Sensitivity minimum: H1 base vs H0 for every LG/LLG location the GAT feeds; H2 limiting sensitivity / stress case; lambda 0.5/2.0; H3 neutral alternative (GAT LV/HV non-solid, joint with UAT L1 at B6_6); H4 test-reading alternative (10.8% with tertiary open during test). GAT-Z0 source-tolerance leg: Z0_PS at 10.8% nominal / 9.99% (-7.5%) / 11.61% (+7.5%) - source-stated tolerance per IEC 60076-1, carried as SOURCE-stated tolerance, NOT an engineering assumption (detail Sec 22-H). H-legs LG/LLG-only.

## Sec 14 â€” South-line zero parameters

1. Status: R0/X0/B0 MISSING as source values (code NaN + report; no tower/soil/test data; JICA file absent; regional analogues fenced). Adopted figures are ENGINEERING_ASSUMPTION reference band â€” wording: "ENGINEERING_ASSUMPTION reference band informed by overhead ACSR earth-return engineering behavior and available reference-class data." The word "evidence-derived" SHALL NOT be used.
2. Physics class: stranded ACSR OVERHEAD link (earth-return zero physics; cable/sheath physics excluded), 0.7 km SHORT (absolute zero ohms stay small under any ratio â€” wide-but-honest band is study-practical), dual-circuit corridor (mutual exists physically, inseparable from lumped total â€” Sec 8.5).
3. Band (binding; per-km == lumped-total ratios; linear scaling):
   kR = R0/R1 âˆˆ [2.0, 5.0], base 3.5; kX = X0/X1 âˆˆ [2.0, 3.5], base 2.75; kB = B0/B1 âˆˆ [0.60, 0.85], base 0.725.
   MIDs are arithmetic band centres (stated base representatives), not measurements/optima/endorsed physics.
   Application: R0_eq = kRÂ·R_eq; X0_eq = kXÂ·X_eq; B0_eq = kBÂ·B_eq; C0 = B0/(2Ï€Â·50); per-km r0 = kRÂ·r1 etc.
   Base derived checks (implementation evaluates; not new source data): R0_eq â‰ˆ 0.09720375 ohm; X0_eq â‰ˆ 0.392055125 ohm; B0_eq â‰ˆ 2.8550471 microS.
   Consistency envelope (diagnostic): zero X/R = (kX/kR)Â·(X1/R1), X1/R1 â‰ˆ 5.13 â†’ envelope [2.05, 8.98]; base-mid â‰ˆ 4.03 (earth-resistance lowering vs 5.13 â€” expected direction for the adopted model). Outside envelope = modelling error.
4. Expectation wording (binding): R0 > R1, X0 > X1, B0 < B1 are EXPECTED for the adopted overhead-line engineering model (larger earth-return flux area + earth-path resistance; earth-image/shielding capacitance reduction) and are enforced as MODELLING CONSTRAINTS. They are NOT universal physical laws. Any leg with R0 â‰¤ R1, X0 â‰¤ X1, or B0 â‰¥ B1 is REJECTED for this plant.
5. LOW corner (2.0, 2.0, 0.60) vs HIGH corner (5.0, 3.5, 0.85) MANDATORY for every LG/LLG location the line feeds; conditional cross-corners (high-R/low-X etc.) only where discrimination needs them. kX = 3.0 inside the band does NOT endorse X0 = 3Â·X1 (point-3.0 shortcut remains forbidden as base).
6. Forbidden: X0 = 3Â·X1 / R0 = R1 (or R0 = 0) / B0 = B1 as fact; importing 400-kV/North-block or Rev2 C-electrics or gridZ0_k as South inputs; inventing tower/spacing/soil/GMR to "compute" X0/Z0m; any adopted zero figure with SOURCE/PRIMARY status; bare Phase-3 Z = 12% GAT in zero diagrams.

## Sec 15 â€” External grid

1. Exactly TWO datasets, never merged (no 50 kA Ã— 10.99, no 45.01 kA Ã— 2.6558-ohm, no XN Ã— |Z| pairs). Phase-3 LF profile (R = 0, X = 2.65581124) is a THIRD object of a different kind (LF assumption), not a dataset.
2. Dataset P (PRIMARY-ESTIMATED, Siemens Â§2.4, own word "estimated"): Ik'' â‰ˆ 50 kA (SOURCE/PRIMARY with ESTIMATED qualifier: Level-1 Siemens direct source, Siemens own word estimated) â†’ Sk'' = âˆš3Â·VÂ·Ik â‰ˆ 19918.58 MVA (DERIVED) â†’ |Z1| = VÂ²/Sk â‰ˆ 2.65581124 ohm (DERIVED magnitude â€” NEVER called X). XN â‰ˆ 2.66 is the separately-reported rounded estimate (order corroboration only; pairing with |Z| as exact R/X is FORBIDDEN â€” imaginary-R proof: 2.66 > 2.65581124). Equipment 50-kA ratings elsewhere are separate facts, not infeed proof.
3. Fault-study R/X for P: MISSING as data â†’ BOUNDED ENGINEERING_ASSUMPTION band (15-5): (X/R)_P âˆˆ [10, 20], base 15 (arithmetic centre, not measurement/optimum/endorsed physics); R1_P = |Z1_P|/âˆš(1+(X/R)Â²), X1_P = R1_PÂ·(X/R), |Z| FIXED, split-only sensitivity. Derived base checks: R â‰ˆ 0.17666194 ohm, X â‰ˆ 2.64992904 ohm. Band rationale: meshed 230-kV Thevenin is high-X/R; <10 needs distribution/radial physics (no evidence); >20 needs near-ideal reactive plant (contradicted by finite 10.99 reading in family). LOW end = most damping; HIGH end = least damping (kappa toward ceiling). Secondary 10.99 inside band is coincidence, not endorsement/narrowing/merging.
4. Dataset S (SENSITIVITY-SECONDARY, LEGACY 2019 compilation): Ik = 45.01 kA, X/R = 10.99 â†’ |Z| â‰ˆ 2.950246, R â‰ˆ 0.267344, X â‰ˆ 2.938108 ohm (DERIVED inside profile at c = 1; Ssc â‰ˆ 17930.71 MVA). Fixed split, no band; exercised via P-vs-S comparison. 3.25-ohm circulating figure consistent ONLY at c â‰ˆ 1.10 â€” reconciliation note, never a study impedance.
5. Phase-3 Rgrid = 0 (infinite X/R) is BALANCED LOAD-FLOW ASSUMPTION ONLY â€” SHALL NOT enter ANY fault sequence network (positive/negative/zero). Violation direction: R = 0 maximises X share at fixed |Z|, drives kappa to ceiling, OVERSTATES ip, understates damping â€” non-conservative for duty.
6. Location: Thevenin at/above REMOTE_GRID_BUS_ASSUMED (branch B230_REMOTE â†” BGRID230), ideal source behind Z1_grid(ds) per dataset; source magnitude/angle follows Sec-9 EMF-from-prefault method (never flat 230 kVâˆ 0Â° without sanction).
7. Sequence hooks: Z2_grid = Z1_grid within dataset (Sec 7); Z0_grid = k0gÂ·Z1_grid within dataset, k0g âˆˆ [1.0, 1.5, 2.0] base 1.5 (Sec 8 + independent zero R/X sensitivity).
8. Conversions (implementation evaluates): (15-1) Sk'' = âˆš3Â·V_LLÂ·Ik''; (15-2) |Z| = V_LLÂ²/Sk'' = V_LL/(âˆš3Â·Ik''); (15-3) R = |Z|/âˆš(1+(X/R)Â²); (15-4) X = RÂ·(X/R) â€” (15-3/15-4) applied WITHIN one dataset only; c = 1 stated (S7 c â‰ˆ 1.10 fenced); pu via /529.

## Sec 16 â€” Prefault cases

PRIMARY: LF360_GAT_OUT (360.00 MW, radial) + LF360_GAT_IN (360.00 MW, looped), PRIMARY_VERIFIED. Each fault run uses its own case's solved state; OUT/IN never averaged, never shared EMF. Per case: B22 V+angle; B230_1 V+angle; B230_REMOTE V+angle (V_REMOTE_kV); generator P/Q; aux P/Q (14/8.676421 frozen); transformer taps (frozen nominal); GAT status; UAT IN; coupler CLOSED; grid slack 1.00 pu. No LF rerun; no flat 1+j0. LF389P30 pair HISTORICAL/sensitivity only; LF342 pair QUALIFIED sensitivity only. (Field inventory per Sec 9 table.)

## Sec 17 â€” Fault equations

1. Study base 230-kV: 100 MVA / 230 kV, Zbase = 529 ohm; machine level 458 MVA / 22 kV per Sec 9. Fault-level Zf conversion Sec 21. Operator a = e^{j2Ï€/3}; radians in equations. Stage labels mandatory (Sec 19); RMS/peak never mixed; ip magnitude-only.
2. Reference: LG phase A; LL/LLG pair Bâ€“C; others by CYCLIC ROTATION (one reference connection per type + rotation; four parallel derivations forbidden).
3. Drive: Vf = complex prefault positive-sequence voltage at fault node propagated from the case's solved state (Sec 9/16). Flat 1âˆ 0Â° FORBIDDEN. Negative/zero networks sourceless; coupling ONLY at fault node.
4. Thevenin Z1(F,S)/Z2(F)/Z0(F) seen from F (stage-dependent ONLY in Z1 via E''/E'/Eq; Z2/Z0 passive except band/dataset/H-leg in force, all stated per run). FULL NODAL sequence solution (Ybus + injection) for all bus/branch currents; Thevenin scalars below are the INDEPENDENT audit (|I_nodal âˆ’ I_thevenin| â‰¤ tol).
5. Sign: sequence fault currents INTO fault; branch contributions TOWARD fault (Sec 20); generator derivation sign (It leaving) re-signed at boundary and documented.
6. LLL (positive only, Zf_LLL undivided): (17-1) I1 = Vf/(Z1+Zf_LLL); (17-2) I2 = I0 = 0; (17-3) V1F = Vf âˆ’ I1Â·Z1 (= I1Â·Zf_LLL), V2F = V0F = 0 at node; (17-4) Ia = I1, Ib = aÂ²I1, Ic = aI1 (|Ia|=|Ib|=|Ic| = |I1| audit). Per-stage evaluation; ip derived (Sec 19).
7. LG/A (1-2-0 series, 3Â·Zf_LG loop): (17-5) I1 = I2 = I0 = Vf/(Z1+Z2+Z0+3Â·Zf_LG); (17-6) V1F = Vf âˆ’ I1Z1, V2F = âˆ’I2Z2, V0F = âˆ’I0Z0 (audit V1F+V2F+V0F = 3Â·Zf_LGÂ·I0, = 0 bolted); (17-7) Ia = 3I0 (faulted, into fault/earth), Ib = Ic = 0 AT THE FAULT BRANCH (retained bus voltages from nodal solution, generally â‰  0). Z0 = full Thevenin zero incl. 3ZN leg where connected, transformer legs where gated, line/grid bands in force.
8. LL/Bâ€“C (1-2 parallel opposed, Zf_LL inter-phase undivided, zero DEAD incl. NER): (17-8) I1 = âˆ’I2 = Vf/(Z1+Z2+Zf_LL), I0 = 0; (17-9) V1F = Vf âˆ’ I1Z1, V2F = I1Z2, V0F = 0 (audit V1F âˆ’ V2F = Zf_LLÂ·I1); (17-10) Ia = 0, Ib = âˆ’jâˆš3Â·I1, Ic = +jâˆš3Â·I1 (audit Ib + Ic = 0, |Ib| = |Ic| = âˆš3|I1|).
9. LLG/Bâ€“C-earth (positive series with (negative âˆ¥ (zero + 3Â·Zf_LLG))): (17-11) Z0e = Z0 + 3Â·Zf_LLG; (17-12) I1 = Vf/(Z1 + Z2âˆ¥Z0e) = Vf(Z2+Z0e)/(Z1Z2+Z1Z0e+Z2Z0e); (17-13) I2 = âˆ’I1Â·Z0e/(Z2+Z0e), I0 = âˆ’I1Â·Z2/(Z2+Z0e); (17-14) V1F = Vf âˆ’ I1Z1, V2F = âˆ’I2Z2, V0F = âˆ’I0Z0 (audit V1F = V2F = V0F + 3Â·ZfÂ·I0, common when bolted); (17-15) Ia = I1+I2+I0 (healthy, â‰ˆ small, = 0 only if Z2 = Z0e), Ib/Ic faulted phases, earth Ie = Ia+Ib+Ic = 3I0. Single common earth impedance; phase-to-phase arc inside LLG NEGLECTED by construction (footnote travels with every LLG result).
10. Fortescue (binding, applied at fault branch AND every contribution leg after toward-fault re-signing): (17-16) phase-from-sequence matrix; (17-17) sequence-from-phase (1/3 matrix) for audit; (17-18) voltages same matrices. Round-trip identity to solver tolerance is a validation leg (Sec 23) via INDEPENDENT re-implementation, never same-call self-check.
11. Nodes: F1â€“F5 exactly (Sec 18); all four types everywhere; F3/m = 0 and F5/m = 1 kept as SEPARATE rows for continuity validation.

## Sec 18 â€” Fault locations and m

1. Mandatory main set: F1 = B22 generator 22-kV bus; F2 = 22-kV GSUT-side interface; F3 = 230-kV South GIS bus (B230_1/B230_2 ONE node, coupler-CLOSED base); F4 = South 230-kV line at m; F5 = B230_REMOTE (REMOTE_GRID_BUS_ASSUMED). B6_6 = AUXILIARY VALIDATION-ONLY (UAT/GAT grounding behavior check; NOT mandatory Phase-5 main set unless explicitly approved).
2. F1 vs F2: DISTINCT REPORTING points (terminal vs transformer-interface through-fault discrimination; different contribution legs). If both map to the SAME electrical solver node, keep both labels â€” DO NOT insert artificial impedance to force different results.
3. m = fractional distance from South GIS toward remote bus; mandatory set m = 0 / 0.25 / 0.50 / 0.75 / 1.00 (minimum {0, 0.50, 1.00} with recorded reason â€” solver-node or band-run budget, never silent). m is pu of frozen 0.7 km (physical km = mÃ—0.7 informational only).
4. Phase-3 frozen lumped D/C equivalent retained for BALANCED load flow. Bus faults F1/F2/F3/F5 solve on the lumped base (zero new impedance, full prefault/fault topology consistency).
5. Phase-4 LINE FAULTS (F4) USE TWO EXPLICIT IDENTICAL CIRCUIT BRANCHES: per sequence s, Z_branch = 2Â·Z_eq (R_branch = 2Â·R_eq, X_branch = 2Â·X_eq), each branch B_branch = B_eq/2 (PI halves at each branch end). Same rule for zero-sequence assumed parameters. Paralleling restores the frozen total â€” asserted to solver tolerance before any fault run (Z_parallel = Z_branch/2). FORBIDDEN: two full Z_eq branches in parallel (halves impedance â€” reverse double-count); lumped + explicit simultaneously (double-count); different per-km constants per circuit (symmetry is locked basis).
6. F4 at m: faulted circuit South-side section = mÂ·Z_branch, remote-side = (1âˆ’m)Â·Z_branch (series R+jX; shunt PI-preserving per (18-7/18-8): GIS end keeps mÂ·B/2, remote end (1âˆ’m)Â·B/2, fault node takes B/2; sums asserted). Healthy circuit remains end-to-end. Zero divides by the SAME formalism per band end (ends divided independently, never averaged). Mutual coupling NOT explicitly modelled (geometry missing); NEVER claimed physically absent. Real double-circuit mutual for co-phasal zero flux is â‰¥ 0, so ignoring it UNDERSTATES effective lumped zero and OVERSTATES line-fed LG/LLG current â€” NON-CONSERVATIVE for current magnitude (conservative for retained voltage); covered by the Sec-14 HIGH corner adopted as an engineering envelope for the expected mutual-coupling direction - not a mathematical proof of an absolute bound - for the 0.7-km link (mandatory C-legs). Explicit Z0m values / Carson computations / km factors FORBIDDEN.
7. Healthy no-fault sharing: I_B1 â‰ˆ I_B2 â‰ˆ I_total/2 (equal-sharing ENGINEERING_ASSUMPTION; identical parallel branches, no data otherwise). Anchor â‰ˆ870 A total / â‰ˆ435 A per circuit is a PREFAULT reporting scale, NOT a fault current. Real asymmetry splits the half only â€” bus-fault totals invariant; per-circuit/CT legs move (at most one symmetric Â±tolerance probe, never blind sweep).
8. Endpoint coincidence: m = 0 and m = 1 line faults reported SEPARATELY from bus faults F3/F5 at the same node group; lim mâ†’0 â‰¡ F3 line-side structure, lim mâ†’1 â‰¡ F5 (continuity validation legs, Sec 23 â€” never merged/averaged).
9. GIS topology: Q0 = CIRCUIT BREAKER (52-1(Q0)); Q1 = BUS DISCONNECTOR (89B2-1(Q1)); Q2 = BUS DISCONNECTOR (89B1-1(Q2)); Q9 = LINE DISCONNECTOR (89-1(Q9)/89G(Q9)); Q51/Q52 = maintenance earthing switches (57B-1(Q51)/57-1(Q52)); Q8 = high-speed earthing switch (57-1(Q8)). Q0/Q1/Q2/Q9 NEVER collectively called disconnectors. Balanced-fault simplification represents ONLY topology-defining devices (closed Q0 breaker + Q1/Q2/Q9 disconnector connections as zero-impedance topology connections â€” tags only, no switching/arc/failure/timing; earthing switches OPEN/absent; no GIS-enclosure/sheath physics). Bus coupler CLOSED = primary ENGINEERING_ASSUMPTION (B230_1/B230_2 one node all sequences); OPEN = sensitivity only (two nodes F3a/F3b + zero-split, documented bay assignment). Outgoing bay number NOT invented (INEL-â€¦-DE-0026 unavailable). GAT HV tee at GIS engaged iff GAT IN. No breaker duty in Phase 4; protection-stage device-class expansion belongs to Phase 5.

## Sec 19 â€” Fault stages

All PROJECT-DESIGN DEFINITIONS, NOT IEC 60909 COMPLIANCE CLAIMS. Full-compliance sentences ("per IEC 60909", "IEC-compliant Ik''/ip/Ib") FORBIDDEN in spec, code comments, plots, handoffs.

| Stage | Kind | Solution | Source (Sec 9) | Network |
|---|---|---|---|---|
| Ik'' initial symmetrical | RMS, t = 0+ | YES subtransient nodal | E''_c (sens E''_alt) | Xd''_sel (0.2248 sat / 0.2608 sens) + Ra per justification |
| ip first peak | INSTANTANEOUS peak magnitude | NO â€” derived from Ik'' + R/X | none | R/X of Z1(F,Ik'') Thevenin |
| Ib(t_break) breaking | RMS delayed | YES transient nodal at prescribed t_break | E'd_c/E'q_c (fallback only per Sec 9) | Xd'/Xq' |
| Ik-steady sustained | RMS sustained | YES synchronous nodal | Eq_c constant-field | Xd/Xq |

1. Ik'': subtransient nodal solution per Sec 17 with stage (Vf, Z1, Z2, Z0); linear magnetics frozen at prefault (saturated primary); E'' constant over first cycles; balanced prefault; bolted base (Sec 21). No DC/peak content (separate ip). Near-generator saliency error bounded by Sec-22-D variant. LG/LLG point Ik'' without its band is INCOMPLETE.
2. ip: (19-1) kappa(r) = 1.02 + 0.98Â·exp(âˆ’3Â·r); (19-2) ip = kappaÂ·âˆš2Â·Ik'' (kA peak, governing phase: LG |Ia|, LL/LLG max(|Ib|,|Ic|), LLL |I1|). r = R1/X1 from FAULT-NODE Thevenin Z1(F,Ik'') (not branch R/X); three-phase kappa form used for ALL types as uniform design definition. Label "ip (design-defined peak)". Assumptions: single-exponential DC decay by fault-node X/R; prefault load neglected in peak increment; frozen network to first peak. Limitations: magnitude only (phasor arithmetic on ip FORBIDDEN); kappa SHAPE borrowed from IEC far-from-generator peak form but NOT IEC-compliant ip (no c factor, motor infeed, correctors, exact DC transfer â€” see borrowed-vs-missing table); near-generator AC+DC multi-time-constant asymmetry NOT captured (F1/F2 under-capture risk; report r + kappa beside every ip); earth-path R (NER-dominated at F1) excluded from r by definition (positive-network r; stated simplification).
3. Ib(t_break): transient nodal solution at USER-SUPPLIED t_break (protection-stage INPUT, seconds + zone; NO default clearing time in Phase 4; Rev2 60 ms assumption NOT carried). E' held constant over delay (stated simplification); topology frozen (no switching/breaker action); same linearity/Zf rules. Correct wording: "constant-E' reference approximation at specified t_break." NEVER "upper bound" / "guaranteed bound". No DC at parting, no arc voltage â€” symmetrical-RMS delayed quantity, not a duty input alone. Xd'-only fallback only with mandated two-axis sensitivity. Never labelled with rating or pass/fail.
4. Steady: synchronous nodal solution, Eq_c CONSTANT FIELD (no AVR/governor/SFC; excitation forcing is sensitivity-only with ASSUMPTION label, never base). No S10/S12 OCC refinement; no Rf anywhere. Understates where AVR would force up, overstates where field collapses â€” CONSTANT-FIELD REFERENCE, not rating. Longest-time bound only.
5. Borrowed-vs-missing (binding): borrowed as design definitions â€” symmetrical-RMS Thevenin structure; kappa equation SHAPE; breaking-current CONCEPT (transient-network embodiment, NOT Âµ/q factors); steady-state CONCEPT. MISSING (voiding any IEC label) â€” voltage factor c (prefault Vf is the drive instead); motor infeed (aux motors not fault sources); KG/KT/KS correctors; Âµ/q breaking factors; exact multi-time-constant DC transfer; IEC min/max cases (covered instead by Sec-22 compact matrix).
6. Reporting: every row carries stage label + methodology/assumptions/limitations reference; stages never mixed in one unlabeled "current" column; consistency Sec-9 rules (same case-c prefault; same Xd'' role in E'' and network; grid/line legs from own equivalents).

## Sec 20 â€” Contributions

1. Base solver: FULL NODAL sequence-network solution per RMS stage; branch sequence currents extracted, phase-reconstructed per leg via (17-16); NO Thevenin-only solving (audit only); superposition-by-source audit-only (mishandles F4 two-branch + GAT loop unless full topology retained).
2. Direction: EVERY contribution signed TOWARD THE FAULT (fault currents INTO fault, Sec 17). Physical branch identity kept (HV vs LV reported separately where both exist); away-pointing load-flow legs appear with negative real part â€” CORRECT, never "rectified". Line through-reporting keeps GISâ†’remote positive ONLY for through-current tags; KCL sums use toward-fault re-signed values. Generator derivation sign re-signed at boundary and documented.
3. Leg inventory per location (each: sequence currents â†’ phase per Sec 17; P always, N always, 0 ONLY for LG/LLG where topology connects earth return):
   F1 (B22): GEN (machineâ†’F1 behind stage source); GSUT-LV (grid+line infeed DOWN through GSUT, re-signed); UAT-HV/LV (aux branch draw, negative-toward-fault load split â€” NEVER a source; no motor infeed); NER-earth (LG/LLG only, part of I0 return). Sequences: GEN P(+N/0 behind machine per stage/passive); GSUT-LV P+N (0 BLOCKED â€” LV delta); UAT P+N only; NER 0-only.
   F2 (GSUT LV interface): GEN (through F1 node toward F2); GSUT-LV (grid+line down toward F2); UAT branch (as F1); NER-earth (LG/LLG, upstream via neutral). Same gating as F1.
   F3 (GIS one node): GSUT-HV (generator up through GSUT); LINE-total (toward F3; B-view splits where reported); GRID-via-line (remote infeed over line); GAT-HV (iff IN per-case gating; iff OUT leg ABSENT, not zero-filled). P+N always; 0 FULL meshed for LG/LLG (GSUT-HV solid neutral + line band + grid zero + GAT loop when IN).
   F4 (line, m): GIS-side faulted-branch leg; REMOTE-side faulted-branch leg; HEALTHY-circuit whole leg; GRID inside remote-side legs; GEN inside GIS-side legs; GAT loop (iff IN) inside GIS-side split. P+N always; 0 per band end, magnetically independent by construction + mandatory C-legs. Report faulted GIS-side + remote-side + healthy + TOTAL per phase; no lumped equivalence claimed for faulted state.
   F5 (B230_REMOTE): GRID-direct (at/above node); LINE-total from GIS end (B-view splits where reported); GEN-via-line; GAT loop (iff IN, via GIS). P+N always; 0 line + grid for LG/LLG.
   FORBIDDEN legs: tertiary-only node; B6_6/aux-LV fault node (auxiliary validation-only, Sec 18); beyond-remote leg; sheath/enclosure leg; zero-filled absent legs; NER current to 230 kV or grid/line zero into generator neutral (delta block).
4. KCL asserts (implementation asserts; Sec 23 validates): (20-1) per sequence Î£legs = fault; (20-2) per phase Î£legs = fault; (20-3) earth Î£3Â·I0_legs = Ie = 3Â·I0_fault; (20-4) LLL |Ia|â‰ˆ|Ib|â‰ˆ|Ic|, LL Ib+Icâ‰ˆ0, LG fault-branch Ib = Ic = 0 (legs individually nonzero).
5. Per-stage contribution tables for Ik'', Ib(t_break), Ik-steady. ip has NO contribution table (derived magnitude; per-leg ip FORBIDDEN).
6. Breaker/CT through-current tags (labels only, no duties): GEN-Q, GSUT-HV, GSUT-LV, LINE-Q9 (total), LINE-B1/B2 (per-circuit), GRID-Q, GAT-HV (iff IN). Q0 = breaker connection; Q1/Q2/Q9 = disconnector connections. All are represented as closed zero-impedance topology connections in the fault-network abstraction; no switching/arc/duty model is included; CT conversion + duration/stage attachment in Sec 26 handoff.

## Sec 21 â€” Zf

1. Base: Zf = 0 (bolted metallic fault) at every location Ã— type Ã— stage. Maximum symmetrical current (duty-handoff conservative), reproducible audit baseline (F3/m = 0, F5/m = 1 continuity), adds no new data. DESIGN BASE (not measurement).
2. Sensitivity NORMALIZED to local fault-voltage base (binding; same fixed ohmic number across 22-kV and 230-kV systems FORBIDDEN):
   Zf_earth = 0.01 pu (LG + LLG earth path; enters as 3Â·Zf in (17-5)/(17-11));
   Zf_phase = 0.002 pu (LL inter-phase + LLL three-phase; enters UNDIVIDED in (17-1)/(17-8)).
   Purely resistive probes (reactance in Zf needs nonexistent justification). ENGINEERING_ASSUMPTION justified test magnitudes â€” NEVER presented/plotted/handed off as realistic footing/arc resistance; never called measured arc/footing resistance. Reversing 3x/1x factors REJECTED.
   Ohmic equivalents (implementation prints per location; study bases: 230 kV â†’ 529 ohm; 22 kV â†’ 4.84 ohm; 6.9 kV â†’ 0.4761 ohm; 6.6 kV â†’ 0.4356 ohm):
   230-kV faults: earth 5.29 ohm, phase 1.058 ohm. 22-kV faults: earth 0.0484 ohm, phase 0.00968 ohm.
   6.9-kV (B6_6 aux): earth 0.004761 ohm, phase 0.0009522 ohm. 6.6-kV reporting: earth 0.004356 ohm, phase 0.0008712 ohm.
3. Runs repeat base with ONLY Zf changed (same case/dataset/band/Xd''-role/m; FÃ—G and FÃ—H joints only where admitted, Sec 22). Additional values only via compact matrix with recorded reason â€” never uncontrolled sweep.
4. LLG simplification: ONE common earth-path impedance; phase-to-phase arc impedance inside LLG channel NEGLECTED by construction (footnote travels with every LLG result).
5. Provenance: Zf_base 0 ohm DESIGN BASE; Zf_earth_sens 0.01 pu / Zf_phase_sens 0.002 pu ENGINEERING_ASSUMPTION (this section locator).

## Sec 22 â€” Sensitivity matrix

Compact OFAT matrix from the base run; full-factorial / Monte-Carlo / random / optimiser / grid sweeps FORBIDDEN. Named joints ONLY (below); any other cross-product needs recorded technical reason + review, never silent. Every variant carries value/unit/base/source/locator/status/rationale. GAT IN/OUT gating preserved under every leg (OUT = absent, never zero-filled). Prefault fence: LF360 pair is the matrix base; LF342/LF389P30 are out-of-matrix labelled extras only.

Base run: LF360 OUT+IN per-case sources (Xd''_sat 0.2248; X2 0.2242; X0 0.128); grid P |Z| = 2.65581124 + (X/R) 15 + k0g 1.5; line 0.7 km frozen totals + MID (3.5, 2.75, 0.725); reconciled NER primary (3Â·ZN zero-only); GSUT 15.8% + solid; UAT 9.3% + 796.743-ohm primary reading; GAT H1 closed-tertiary base; Zf = 0; coupler CLOSED; F1â€“F5 Ã— 4 types Ã— 4 stages; m full set (minimum {0, 0.50, 1.00} with reason).

A â€” GRID: P-band (X/R) 10 / 15 / 20 (|Z| FIXED); P-vs-S duality (45.01 kA / 10.99 fixed profile, never cross-paired); per-dataset k0g 1.0 / 1.5 / 2.0; A2r residual negative-specific perturbed-X/R (same-|Z|, ASSUMPTION, admitted only with recorded need). Rgrid = 0 / XN-pairing / 3.25-ohm-as-impedance all fenced out.
B â€” LENGTH: 0.5 / 0.7 / 1.0 km; pos/neg AND zero totals scale with length rule, RATIOS HELD (MID at B-ends; C-corners at B-ends only if admitted cross).
C â€” LINE ZERO: C0 MID base; C-LOW (2.0, 2.0, 0.60) vs C-HIGH (5.0, 3.5, 0.85) mandatory every LG/LLG location the line feeds; C-X cross-corners only where discrimination needs them (inside [2.05, 8.98] envelope); band-end absolute spreads + LG/LLG spreads reported as bounded-perturbation diagnostic. HIGH corner is adopted as an engineering envelope intended to cover the expected direction of mutual-coupling uncertainty; this is not a mathematical proof of an absolute bound (tower/soil/shielding geometry MISSING - Sec 8/18).
D â€” GENERATOR: D1 Xd''_unsat 0.2608 (E'' + network consistent); D2 salient Zq'' (Xq'' = 0.2593) variant where implemented (LL/LLG F1/F2 â€” bounds â‰ˆ15% saturation-mixing spread; silent Xq'' = Xd'' forbidden); D3 X2 bounded/error-check alternatives (never base; E1/E2 REJECTED as fact); D4 X0 bounded alternatives + JOINT with E at B22 LG; D5 two-axis vs Xd'-only fallback for Ib.
E â€” GROUNDING: E1 NER resistor tolerance band (via 10-3); E2 quoted-vs-reflected alternative (both visible; never edit source); E3 NGT neglected-vs-bounded; E4 1xZN-in-zero labelled error-check ONLY (base strictly 3Â·ZN); E5 UAT-L1 joint (primary vs alternative 5-A reading + R/X split, JOINT with H3 at B6_6); GAT LV 5-A equivalent sensitivity (â‰ˆ796.743 vs alternative reading); GAT HV neutral finite-ground sensitivity. ZN = 0 solid as primary FORBIDDEN.
F â€” Zf: 0 vs normalized probes (0.01 pu earth / 0.002 pu phase, Sec 21); T12-style check: F1-LG probe shows LOW sensitivity (3Â·ZN â‰« probe) â€” insensitivity IS a validation leg.
G â€” TOPOLOGY: coupler CLOSED base vs OPEN sensitivity (F3a/F3b two nodes + zero-split, never averaged); Q0 stays a closed breaker connection; Q1/Q2/Q9 stay closed disconnector connections; earthing switches OPEN; no bay/substation invention.
H â€” GAT: H1 closed-tertiary base (lambda 1.0) vs H0 open sensitivity (minimum) + H2 short limiting sensitivity / stress case + lambda 0.5/2.0 + H3 neutral alternatives (+H4 test-reading where admitted). LG/LLG ONLY; LLL/LL invariance required. H0/H1 Ã— C-LOW/C-HIGH 2Ã—2 admitted where loop closes (sole permitted 2-factor impedance bracket). GAT-Z0 leg (compact): Z0_PS = 10.8% nominal vs 10.8%x(1-0.075) = 9.99% vs 10.8%x(1+0.075) = 11.61%, run at H1 base (lambda 1.0); status is SOURCE-stated tolerance (GAT data sheet, IEC 60076-1), never relabelled ENGINEERING_ASSUMPTION. This leg bounds the documented pairwise-figure tolerance separately from the tertiary approximation (lambda_T/H0/H1/H2), so the +/-7.5% variation is never hidden inside lambda_T.
Joints permitted (ONLY): D4+E (S3+S4) at B22 LG; E5+H3 at B6_6 LG; conditional CÃ—B; FÃ—G and FÃ—H where earth-path topology changes probe effect; HÃ—C 2Ã—2 above. m-set runs at MID + C-LOW/C-HIGH at {0, 0.50, 1.00} minimum unless full set practical with reason.

## Sec 23 â€” Validation

INDEPENDENT validation only. Solver-vs-same-algorithm self-checks FORBIDDEN (same-call sequenceâ†’phase; Thevenin-by-reducing-same-Ybus; any Rev2 solid-grounded LG/LLG quantity; Siemens/45.01-kA infeeds as Ik'' oracles; X0 = 3X1 / R0 = R1 expectations; H-vs-H as correctness proof). Thevenin-scalar audit allowed ONLY because scalar closed-form arithmetic and Ybus nodal factorisation share no code path except inventoried impedances. Tolerance failure blocks handoff (retolerance needs recorded justification, never silent).

1. Sequenceâ†’phase round trip ((17-16)â†’(17-17) identity per fault branch AND per leg, independent re-implementation).
2. Phaseâ†’sequence round trip (independent direction; same identity requirement).
3. LLL analytical scalar vs nodal ((17-1)â€“(17-4); V1F = I1Â·Zf identity; symmetry).
4. LG analytical scalar vs nodal ((17-5)â€“(17-7); V-sum = 3Â·ZfÂ·I0; fault-branch Ib = Ic = 0, Ia = 3I0).
5. LL analytical scalar vs nodal ((17-8)â€“(17-10); V-diff = ZfÂ·I1; Ib + Ic = 0, |Ib| = âˆš3|I1|).
6. LLG analytical scalar vs nodal ((17-11)â€“(17-15); V-equality audit; Ie = 3I0 earth identity).
7. KCL per sequence ((20-1) every location Ã— type Ã— RMS stage).
8. KCL per phase ((20-2) same coverage).
9. Earth-current KCL: IN = 3I0 at N/N_UAT/GAT-tee nodes + (20-3) Î£3Â·I0 â‰¡ Ie.
10. Generator NER gating: earth legs DEAD (â‰¤ tol) for LLL/bolted LL, ENERGISED for LG/LLG; NER-dominance diagnostic + F-probe insensitivity at F1-LG.
11. GSUT delta zero-sequence blocking: B22-LG grid/line-zero legs carry NO current; 230-kV LG transformer-fed zero from GSUT-HV neutral only.
12. UAT zero path: HV OPEN â†” LV leg; GAT OUT leaves UAT-only small B6_6 current; B6_6 parallel split reported per run (no pre-judged labels).
13. GAT zero path: HVâ†”LV through-path with IN/OUT gating; H-leg LL/LLL invariance (identical within round-trip tol).
14. GAT H0/H1/H2 LL/LLL invariance (tertiary affects zero-only) â€” cross-run identity, not correctness proof.
15. F3/m = 0 vs F5/m = 1 endpoint continuity (SEPARATE rows; lim-equivalence within looser continuity tol; never merged/averaged) + bolted-LLL m-monotonicity split per end.
16. F1/F2 distinction without invented impedance (separate rows; adjacency â‰  identity).
17. Line two-circuit impedance restoration ((18-3) branch/2; (18-6) m-sums; (18-8) shunt sums at every m/band-end) + zero-X/R envelope [2.05, 8.98] + stage-ordering diagnostic |Ik-steady| â‰¤ |Ib| â‰¤ |Ik''| (FLAGGED for review where inverted â€” grid-fed shares need not decay monotonically; diagnostic, not hard assert).
18. Deterministic rerun (identical inputs â†’ identical outputs; no RNG/date-dependence; solver settings + code hashes logged) + full row-schema audit (Sec 19/22 schema; ip magnitude-only + kappa/r attached; Ib t_break attached; LLG footnote attached).
19. Phase-symmetry checks ((20-4): LLL equal magnitudes; LL pair opposition; LG branch zeros; LLG earth identity; legs individually nonzero).
20. Source-current conservation: per-case chain (|Vt|,Î¸t,P,Q)â†’(Vt,St_pu,It)â†’(E'',E'd/E'q,Eq) re-derivable from CSV fields alone; source-bus nodal KCL (injected â‰¡ Î£ branches at B22/remote buses); Vf propagation audit (flat 1âˆ 0Â° SHALL fail).
21. V-A B6_6 gate: B6_6 aux-bus prefault reproduction vs frozen Phase-3 complex voltage on the 6.6-kV base (L21 OUT 0.025691 / IN 0.028839 vs 0.05 bound).
22. V-B tap sanity: applied UAT/GAT LV tap equals the documented 6.9/6.6 nominal ratio 1.045454545 (L22 residual 0).
23. V-C aux sanity: stamped aux per-unit impedance independently recomputed from frozen Phase-3 aux power over the 0.4356-ohm base (L23 residual 1.63e-16).
24. V-D loop identity: GAT H1 loop 100-MVA value equals 4x the 25-MVA value at 0.432 pu (L24 residual 0).
25. V-E H2-vs-H0 separation: H2 stamps the GATLOOP branch H0 lacks with passivity ordering I(H2) >= I(H1) >= I(H0) on F3-IN LG (L25 violation count 0; structural+ordering only, never proof).
26. V-F all-type continuity: F4 m=0/1 vs F3/F5 endpoint continuity for LG/LL/LLG governing currents extends the LLL-only leg (L26 residual 4.87e-16 vs 0.05 bound).
27. V-G handoff LL/LLG completeness: probe matrix tag carries LL/LLG rows with the required schema columns and non-empty footnotes (L27 violation count 0).
Tolerances (design thresholds, printed with each check + solver settings): T-RT (round-trip/preservation/identities), T-AN (analytical-vs-nodal), T-KCL (sequence/phase/earth residuals vs â€–I_faultâ€–), T-DEAD (dead legs vs â€–I_faultâ€– + absolute floor), T-CONT (continuity, looser than T-AN, separate), T-DET (determinism). YNd1/Dyn11 conjugate shifts + GAT 0Â° + toward-fault signing consumed in all applicable legs.

## Sec 24 â€” Rev2 matrix

Verdicts (one per item): SAFE TO REUSE / REUSE AFTER DATA-INTERFACE ADAPTATION / REBUILD / HISTORICAL ONLY.

| Item | Verdict | Reason |
|---|---|---|
| rev2/data/iec_kappa.m (Îº = 1.02+0.98Â·exp(âˆ’3/(X/R)) function body) | SAFE TO REUSE (function body only) | Pure function, no Rev2 data dependency; computes exactly (19-1). MANDATORY relabel "design-defined peak-factor shape"; r = fault-node Thevenin R1/X1 from Ik'' network; ip magnitude-only, no per-leg reporting; no IEC claim. |
| rev2/run_phase2_fault.m (engine) | REBUILD | Sound audit-scalar equations, but unusable as code: hard-wired 3-node topology (no F1â€“F5/m/GAT-loop/B-view); solid grounding; P1A single prefault; legacy grid; C-line/zero; scalar-only solving (Sec 17 forbids as base); no E''/E'/Eq per-case sources; no Ib/steady stages; assumed clearing/interrupt. |
| rev2/data/seq_networks.m (Y012/Zbus builder) | REBUILD | Ybus+injection PATTERN informs M2/M4 only; every data leg superseded (solid gen Z0; GSUT/grid Z0 = Z1; C-line R0/X0; R0 = 1.5R1; shunt-B neglected; P1A Vpre + fallback + B03 fix-up; legacy Rth/Xth tuple; silent base interp; no NER/transformer-zero/band/m/coupler/tertiary structure). Too many embedded assumptions to patch â€” never adapted. |
| rev2/data/iec_si.m (protection curve helper) | HISTORICAL ONLY | Protection-side; Phase 4 has no settings/coordination. Phase-5 protection stage may consume; never the fault engine or validation. |
| rev2/tests/* (fault + KCL tests) | REBUILD | Test INTENT informs Sec 23; every assert is Rev2-topology-bound (3-node dims; solid-ground oracles; kappa value kept but relabelled; 9/36 counts superseded by F1â€“F5 Ã— m Ã— Aâ€“H; duty margins tied to legacy currents + assumed 50 kA). Rewrite to Sec-23 tolerances. |
| rev2/results/phase2_fault_currents.csv, phase2_sequence_Z.csv, phase2_breaker_duty.csv, phase2_simulink_check.csv | HISTORICAL ONLY | Computed under solid grounding + 354-MW P1A + legacy grid + C-line. NEVER seed/verify Phase-4 values (esp. earth faults). Audit trail / history plots only. |
| rev2/data/ashuganj_rev2_registry.m + reconciliation_register.csv | HISTORICAL ONLY | Independent registry decoupled from Phase-3 data; every value class superseded/fenced (solid earthing rejected; P1Aâ€“P1G â†’ LF360/LF342/LF389P30 + frozen aux; legacy grid tuple â†’ Sec-15 dual profiles; 0.08/0.35/4.2 line â†’ frozen Mallard totals; GSUT figures â†’ Sec-11 SOURCE figures; aux handling â†’ Sec-12 dual-base rule). Read as rejection history, never input. |
| rev2/run_phase3_protection.m, phase3_settings/coordination.csv | HISTORICAL ONLY | Protection coordination + starting values; outside Phase-4 boundary. Through-path tag STRUCTURE informs Sec-20/26 tags only. |
| rev2/simulink/* + run_full_project.m | HISTORICAL ONLY | Tied to Rev2 SLX + legacy basis + absolute paths; any future time-domain cross-check specified fresh. |

Rejected as Phase-4 input (binding): solid generator grounding; 354-MW P1A basis; 12 MW + j5 aux; legacy 0.268+j2.94 mixed grid tuple; 0.08/0.35/4.2 line parameters; old gridZ0_k mechanism; hardcoded P1A prefault; old Vpre fallback; old current-base referral; old CT-selection logic; old breaker-duty results; old fault-current CSVs; old sequence-Z CSVs. Rev2 files UNMODIFIED (Sec 28 checks).

## Sec 25 â€” Implementation architecture

Fresh implementation against current matlab/data architecture AFTER design approval. Modules:

M1 â€” Phase-4 fault input/profile provider (reads frozen Phase-3 CSVs/MAT/profiles; kV-column rule; per-case prefault bundles; t_break + Zf + variant-ID inputs; NO defaults for t_break).
M2 â€” positive/negative/zero sequence network builder (Secs 6/7/8/11â€“15 rules; lumped base + on-demand explicit B-view via (18-1)â€“(18-3) with restoration assert; m-division (18-4)â€“(18-8); GAT H-legs; coupler states).
M3 â€” stage-specific source builder (Sec-9 equations (9-1)â€“(9-13); E''/E'd-E'q/Eq per case; Park convention declared once; Xd'' roles consistent).
M4 â€” full nodal fault solver (Sec-17 per RMS stage; Ybus + injection; Thevenin-scalar INDEPENDENT audit; ip derived via (19-1/19-2), no separate solution).
M5 â€” phase reconstruction + contribution extractor (Fortescue per leg; toward-fault signing; Sec-20 inventory; KCL asserts (20-1)â€“(20-4); through-tags; NO per-leg ip).
M6 â€” validation engine (Sec-23 legs 1-27 with printed tol_* + solver settings + hashes; failure blocks handoff).
M7 â€” sensitivity runner (Sec-22 OFAT base + named joints; band min/max with supplying legs named).
M8 â€” result writer/reporting (Sec-26 schema; currents + contributions + bands + tags + CT data + footnotes; NO settings/duties/verdicts).

Canonical Phase-4 parameter object/registry: every entry carries value + unit + base + status + source + locator + rationale + variant ID. No hard-coded fault-study literals anywhere (M1â€“M8 communicate ONLY through registry structs + Sec-26 row schema; no hidden globals). Binding asserts (implementation SHALL error): (18-3)/(18-6)/(18-8) restoration within T-RT; zero-X/R inside [2.05, 8.98]; realised (X/R)_P equals admitted input; XN-|Z| pairing / cross-dataset merge / S7-as-impedance / Rgrid = 0 in fault networks all error; ZN outside generator/UAT-LV neutral zero legs errors; 1xZN outside labelled E4 errors; ZN = 0 primary errors; missing Park declaration / missing t_break on Ib / stage mixing / per-leg ip / Q-as-breaker / switching sequences / bay-substation invention / X0 = 3X1-R0 = R1-B0 = B1-invented-Z0m-as-fact all error.

## Sec 26 â€” Phase-5 handoff

Phase 4 hands DATA, not protection decisions. Per-row schema (REJECTED if incomplete): fault type + location (+m for F4) + prefault case + grid dataset (+(X/R)_P value or S) + line-zero band end (LOW/MID/HIGH + k0g where LG/LLG) + Xd'' role + NER variant + GAT variant (H-leg + lambda + neutral IDs) + Zf + topology state (coupler/GAT) + stage label + unit/base. ip rows add r + kappa(r) (+ under-capture/positive-r footnotes); Ib rows add t_break (+ constant-E' footnote); LLG rows add single-earth-impedance footnote; steady rows add no-AVR footnote.
Contents: (a) fault-branch phasors by location (RMS magnitude + angle kA; ip magnitude kA peak; retained bus voltages from nodal solution; fault MVA where defined; F1/F2 separate; F3/m = 0 and F5/m = 1 separate); (b) min/max bands over COMPACT matrix only (line-zero corners + k0g ends + NER alternatives + GAT H0/H1 minimum where loop closes; MID/base identified; supplying legs named; point LG/LLG without band INCOMPLETE); (c) per-RMS-stage source contributions with KCL residuals (GEN/GSUT-HV/GSUT-LV/UAT/GAT-HV+GAT-LV/LINE-total/LINE-B1/LINE-B2/GRID/NER-earth; F4 faulted-side/remote-side/healthy/total; B6_6 UAT-vs-GAT split per run WITHOUT pre-judged labels; HV-LG plant-vs-grid zero split per band end); (d) per-circuit line currents (B1/B2 vs Q9 total; healthy equal-sharing stated); (e) breaker through-current tags GEN-Q/GSUT-HV/GSUT-LV/LINE-Q9/LINE-B1/LINE-B2/GRID-Q/GAT-HV (labels only); (f) CT DATA (primary per stage + ip peak where applicable; candidate ratios listed, never selected; secondary = primary/ratio; ratio base + accuracy context where sourced; frozen Phase-3 full-load anchors, never P1A FL); (g) sensitivity identifiers + spreads + discrimination statements; (h) duration/stage data (t_break-attached Ib; r/kappa-attached ip; footnoted steady; NO assumed clearing time).
NO: relay pickup, TMS, grading, differential settings/slopes, CT ratio selection, breaker pass/fail, coordination tables/plots, substation names.

## Sec 27 â€” Risks / missing data

| # | Risk | Status | Design mitigation | Data request (Phase-5 handoff notes) |
|---|---|---|---|---|
| D1 | South-line R0/X0/B0 unmeasured; tower/soil/shielding/transposition/mutuals unknown | MISSING point values; ENGINEERING_ASSUMPTION band | Wide band + mandatory LOW/HIGH + HIGH corner as engineering envelope for the expected mutual direction (not a proof of an absolute bound) + [2.05, 8.98] envelope assert | Tower geometry/phasing/ground-wire/soil survey; measured per-km R0/X0/B0; mutual test if explicit model ever admitted |
| D2 | Grid Thevenin unmeasured (50 kA ESTIMATED; 45.01 kA LEGACY; primary X/R MISSING-as-data; Z0 MISSING both) | ESTIMATED/LEGACY/ASSUMPTION | Dual profiles never merged + (X/R)_P band + k0g triple + independent zero-R/X sensitivity + P-vs-S duality | PGCB test record at REMOTE_GRID_BUS_ASSUMED (Ik'', X/R, X0/X1 + zero R/X, c-factor basis, date/operating condition) |
| D3 | Generator X2/X0 + base/saturation QUALIFIED (no Siemens corroboration; test conditions MISSING) | WORKBOOK-DERIVED+QUALIFIED | D1â€“D5 alternatives + salient Zq'' + two-axis-vs-Xd'-only + D4+E joint at B22 LG | OEM test record (X2/X0 conditions, saturation, base declaration, unsaturated counterparts) |
| D4 | NER 60-vs-1690.77 reconciliation conditional + NGT series-X MISSING | SOURCE pair + MISSING rule | Additive recommended interpretation with heading evidence + conditional fallback + E1â€“E4 + dominance/5-ohm legs | NER transformer test (series Z, uk%, magnetising), resistor tolerance + thermal record, 10BAB11 as-built single-line |
| D5 | GAT pairwise-INCOMPLETE (Z_PT/Z_ST MISSING; 10.8% test reading QUALIFIED; LV neutral device MISSING) | MISSING + ASSUMPTION | Explicit lambda_T loop base + H0/H1/H2 + lambda 0.5/2.0 + H3/H4 + LL/LLL invariance + non-conservatism warning | Complete GAT test (Z_PS/Z_PT/Z_ST per sequence, tertiary state during test, neutral records â€” ENGINEER_DATA_REQUEST item 8) |
| D6 | UAT LV neutral device MISSING (10BBW10 candidate unresolved; 5-A limit only) | MISSING device + SOURCE limit | 796.743-ohm bounded equivalent + stated reading + R/X split + E5/L1+H3 joint | LV neutral device records (R/X or NGT ratio + resistor; cubicle single-line confirmation) |
| D7 | Full Siemens 39-pp report + turbine doc + INEL-0026 GIS drawing + JICA/Mallard file MISSING | MISSING | Fences (no verification claimed; no bay/substation invention; Y1 report-only locator; GAT-via-UAT-docs partial); GIS Sec-18 table as assumption | S001 full report + turbine doc; INEL-0026 (bays, coupler logic); JICA 12248464 family sheet |
| D8 | Aux/shunt + downstream-LV uncertainty (14 MW apportionment; Y(grounded) LF shunt; LV boards out of boundary; no motor infeed data) | ASSUMPTION / OUT-OF-SCOPE | Aux-shunt OPEN in zero base; UAT small-by-construction diagnostic; no motor infeed (missing-per-Sec-19) | Aux survey (neutral impedances, board single-lines) only if LV-fault scope ever expands |

Method limits travelling with every handoff row: design-defined non-IEC stages; ip borrowed single-r shape (near-generator under-capture + positive-r-only); Ib constant-E' reference approximation (no DC/arc); steady constant-field (no AVR); LLG single-earth-impedance (phase-phase arc neglected); mutual ignored/approximated non-conservative for earth magnitude; GAT open-tertiary non-conservative for LG/LLG magnitude; F1/F2 ip+Ib carry largest methodology spread (saliency + saturation-mixing + short-link band + NER tolerance stack â€” bands are decision inputs, not trimmable margins); bands bound the COMPACT matrix only (not worst-case ratings / IEC min-max / protection margins â€” widening needs new data D1â€“D8, never wider assumptions).

## Sec 28 â€” STOP boundary

1. Phase 4 = FAULT ANALYSIS / SHORT CIRCUIT ONLY. No relay coordination, protection settings, breaker-duty evaluation, dynamic/transient stability, battery/DC, AVR implementation, governor implementation, SFC implementation.
2. After this design specification is approved: STOP. Do NOT write MATLAB code. Do NOT run fault calculations. Do NOT generate final fault-current results. Do NOT modify Phase 3. Do NOT modify Rev2. WAIT FOR EXPLICIT IMPLEMENTATION APPROVAL.
3. No .m / Phase-3 / Rev2 / historical-CSV / protection / plot file modified in this task (evidence: Sec 3 freeze table + Final Checks below). No MISSING â†’ VERIFIED promotion anywhere (closed enum preserved). No unresolved issue silently converted into verified fact.
4. First Phase-5 act (after approval): implement M1â€“M8 per Sec 25 with all Sec-25 asserts active, Park declaration printed, and Sec-23 validation gating every handoff write.

---

## Appendix A â€” Derived-check arithmetic (implementation evaluates; not source data)

n = (22000/âˆš3)/500 â‰ˆ 25.40341184. R_loading_reflected = nÂ²Â·2.62 â‰ˆ 1690.773333 ohm.
R_NER_HV (recommended) = 60 + 1690.773333 â‰ˆ 1750.773333 ohm. 3Â·ZN â‰ˆ 5252.32 ohm.
Machine Zbase = 22Â²/458 â‰ˆ 1.056768559 ohm â†’ 3ZN â‰ˆ 4970.1706 pu.
ZN_UAT â‰ˆ ZN_GAT_LV â‰ˆ (6900/âˆš3)/5 â‰ˆ 796.743 ohm (primary IN = 3I0 reading; alternative I0-reading â‰ˆ 265.581 ohm).
|Z1_grid,P| = 230000/(âˆš3Â·50000) â‰ˆ 2.65581124 ohm; Sk'' â‰ˆ 19918.58 MVA; X/R = 15 â†’ R â‰ˆ 0.17666194, X â‰ˆ 2.64992904 ohm.
Secondary: |Z| = 230000/(âˆš3Â·45010) â‰ˆ 2.950246 ohm; Ssc â‰ˆ 17930.71 MVA; X/R = 10.99 â†’ R â‰ˆ 0.267344, X â‰ˆ 2.938108 ohm.
Line-zero base: R0 â‰ˆ 3.5Â·0.0277725 = 0.09720375; X0 â‰ˆ 2.75Â·0.1425655 = 0.392055125; B0 â‰ˆ 0.725Â·3.937996 = 2.8550471 microS.
Zf ohmics: 230 kV â†’ earth 5.29 / phase 1.058; 22 kV â†’ earth 0.0484 / phase 0.00968; 6.9 kV â†’ earth 0.004761 / phase 0.0009522; 6.6 kV â†’ earth 0.004356 / phase 0.0008712.
kappa(r) = 1.02 + 0.98Â·exp(âˆ’3r) (r = R1/X1; identical to 1.02 + 0.98Â·exp(âˆ’3/(X/R))).
GAT Z_T0_loop: 1.0Â·0.108 â‰ˆ 0.108 pu base; 0.5 â†’ â‰ˆ0.054; 2.0 â†’ â‰ˆ0.216 pu (25-MVA base).

## Appendix B â€” Exact source wordings relied upon

B1. Generator Data_South.pdf p.7 Â§2.3 NER table: primary "22 kV/3", secondary "500 V", TRU "25,4"; "Rated apparent power / HV-winding resistance â€¦ 135 kVA / 20 s"; "RHV-DC â€¦ 60 â€¦ ?"; "R1 â€¦ 2,62 â€¦ ??". (Additive reading: RHV-DC = HV winding DC resistance; R1 = secondary loading resistor.)
B2. UAT data sheet (10BBT10): "Vector group Dyn11"; "Neutral of the low voltage winding Accessible to be earthed through impedance that limits the fault to 5A"; Z main tap "10.5", R main "â‰ˆ0.4", Z0 main "â‰ˆ9.3".
B3. GAT data sheet (10BBT20, inside UAT-doc set): "Vector group YNyn0+d11"; HV neutral "Accessible to be solidly earthed"; LV neutral "Accessible to be earthed through impedance that limit the fault to 5A"; Z main "12.0", R main "â‰ˆ0.5", Z0 main "â‰ˆ10.8 â€¦ Â±7.5% in acc. to IEC60076-1 â€¦ between HV primary and LV secondary windings"; tertiary "3.32" kV.
B4. GSUT data sheet: "YNd1"; HV neutral "Accessible to be solidly earthed"; Z0 main tap "15.8".
B5. GENERATION AND TRANSFORMERS SYSTEM.pdf (DE-0023): device codes "52-1(Q0)" (breaker), "89B2-1(Q1)" / "89B1-1(Q2)" (bus disconnectors), "89-1(Q9)" / "89G (Q9)" (line disconnector), "57-1(Q51)" / "57-1(Q52)" / "57-1(Q8)" (earthing switches); GSUT "YNd1 Z=16% (BASE 515 MVA)".
B6. Generator Data_South.pdf Â§2.4 grid: "Grid impedance (estimated) XN 2,66"; "Sk 19.919 MVA" (= 19,919 MVA); "Ik 50 kA"; formula line "XN = UNgrid / (3 * IK'')" (sic â€” approximate; this spec uses |Z| = V/(âˆš3Â·Ik) for the magnitude derivation and never pairs XN with |Z|).
B7. Siemens Â§2.1.1: saturated d-axis triple "166,3 % / 28,65 % / 22,48 %" (â†’ Xd''_sat = 0.2248 corroboration).

## Appendix C â€” Freeze evidence for this task

Read-only verification at reconciliation close: PHASE3_FINAL_REPORT.md 45504 B 2026-09-18 13:02:04; PHASE3_CHANGELOG.md 25257 B 2026-09-18 13:02:00; matlab/data/ashuganj_lines.m 13448 B 2026-09-18 12:42:16; matlab/data/ashuganj_grid.m 10655 B 2026-09-18 12:40:20 â€” identical to Task-1 frozen record (Sec 3). No .m / Phase-3 / Rev2 file created, modified, or deleted by this task; only this specification file was written.

(End of corrected specification.)
