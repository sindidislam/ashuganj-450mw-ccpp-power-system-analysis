# PHASE-4 AUDIT AND CORRECTION RECORD — REV3.1 Fault Analysis
## Ashuganj South 450 MW CCPP — Master-Prompt Audit of 2026-09-18

**Date:** 2026-09-18. **Scope:** `PHASE4_FINAL_REPORT.md`, design spec `docs/superpowers/specs/2026-09-18-phase4-fault-analysis-design.md`, `matlab/phase4/`, `matlab/tests/test_phase4_*.m`, `results/phase4_fault/`.
**Method:** source-hierarchy audit (L1 Siemens/OEM → L2 workbook → L3 frozen Phase-3 → L4 design → L5 legacy, never promoted); independent recomputation in MATLAB + PowerShell; phrase scans; SHA-256 sweep vs `PHASE3_POST_HASHES.txt`; full suite re-run after corrections.
**Rule applied throughout:** no correct engineering value changed for a legacy look-alike; every correction traces to a source, arithmetic, or explicit modelling decision below.

---

## A. EXACT CORRECTIONS MADE

| # | File | Old wording/value | Corrected wording/value | Reason + source/locator |
|---|---|---|---|---|
| 1 | `matlab/phase4/phase4_registry.m:54` | `R.grid.P.Ik_kA` status `ENGINEERING_ASSUMPTION` | status `SOURCE/PRIMARY`, rationale `Level-1 Siemens direct source quantity; Siemens own word ESTIMATED, confidence inherited as estimate, never firm` | Master prompt §9: Ik'' = 50 kA is a Level-1 Siemens direct report (`Generator Data_South.pdf` p.2 / report p.7 §2.4); ESTIMATED is Siemens' own qualifier. Value 50 unchanged. |
| 2 | design spec §5 ledger, Grid row | `ENGINEERING_ASSUMPTION (Ik) / DERIVED` / `ESTIMATED confidence inherited` | `SOURCE/PRIMARY (Ik: Level-1 Siemens direct source with ESTIMATED qualifier) / DERIVED` / extended qualifier | Same as 1, ledger consistency. |
| 3 | design spec §15 | `Ik'' ≈ 50 kA (ENGINEERING_ASSUMPTION as estimated)` | `Ik'' ≈ 50 kA (SOURCE/PRIMARY with ESTIMATED qualifier: Level-1 Siemens direct source, Siemens own word estimated)` | Same as 1, prose consistency. Q10 row already read "Siemens estimated" — untouched. |
| 4 | `matlab/phase4/phase4_handoff.m:335`, `run_phase4_matrix.m:496` | Ib footnote `... at t_break=%.2f s; ZfMode=%s` | appended `(chosen study reference time, not a measured breaker clearing time)` | Prompt §14: t_break = 0.06 s must be labelled study reference time, never imply a clearing time. Prior substring asserts (`constant-E`, `no-AVR`, `single-earth`) preserved. |
| 5 | handoff + matrix steady footnotes | `constant-field synchronous reference; ...` | `constant-field synchronous (constant-Eq) steady reference; ...` | Prompt §14 Isteady definition wording; `no-AVR` substring preserved. |
| 6 | `run_phase4_matrix.m` diary line + header comment | `t_break=0.06 s documented default` | `t_break=0.06 s chosen study reference time (not a measured breaker clearing time)` | Same as 4. |
| 7 | `PHASE4_FINAL_REPORT.md` status line | `Full suite 118 passed / 0 failed (15 test files)` | `Phase-4 regression suite reported by the implementation: 118 passed, 0 failed across 15 test suites` | Prompt §16 wording discipline. |
| 8 | report intro + §8 | `full sequence networks` / `independent validation` / `20/20 independent legs pass` | `full positive-, negative-, and zero-sequence network formulation using the adopted source-backed, derived, and engineering-assumption parameters` / `independent internal validation engine` / `Independent internal validation engine: 20/20 legs passed` | Prompt §21. |
| 9 | report §1 base-run sentence | bare base choices | appended provenance tags (X/R 15, k0g 1.5, MID, H1, coupler-CLOSED = assumptions/conventions; Zf = 0 design base; 0.7-km locked assumptions; dataset-P inherits Siemens-estimated confidence) | Prompt §21 provenance-beside-assumptions. |
| 10 | report §1 duration anchors | `Ib(0.06 s)` | `Ib(t_break = 0.06 s chosen study reference time — not a measured breaker clearing time)` | Prompt §14. |
| 11 | report §1 + §13 STOP hash sentences | `byte-identical (hash sweep: only 3 ... drifts)` / `byte-identical apart from 3 ... drifts` | `Phase 4 introduced no changes to the protected Phase-3/Rev2 files. Three pre-existing Phase-3-window differences relative to the earlier baseline were already present and are unrelated to Phase 4.` | Prompt §17 contradiction ban. |
| 12 | report §4 M2 line | `Z2 = Z1 justified static equalities` | `Z2_gen = Ra + jX2 (0.2242 qualified); transformers Z2 = Z1 by stated static-equipment assumption; line R2 = R1 / X2 = X1 / B2 = B1 short-line assumption; grid Z2 = Z1 within dataset` | Prompt §8 anti-blanket rule. |
| 13 | report §6 secondary dataset | `secondary 45.01-kA dataset` | `LEGACY secondary 45.01-kA/X/R-10.99 dataset, sensitivity-only, never merged` | Prompt §9/§20. |
| 14 | report §8 validation line | `5-ohm-normalized-probe` | `normalized-earth-probe (0.01 pu → 0.0484 ohm at F1)` | Prompt §13: fixed-ohm probe language forbidden; the probe was always the normalized path (validation log confirms 0.0484 ohm), only the report wording was wrong. |
| 15 | report §3 | (no generator data) | added non-negotiable generator line (458/22/50 Hz; Siemens-corroborated d-axis triple; qualified q/X2/X0/Ra; 360 MW primary; 389.30 MW Siemens rated) | Prompt §2 traceability in report. |
| 16 | report §9 | Rev2-only section | retitled `Rev2 Disposition + Legacy Conflict Fence` + 10-row legacy table (16.63→16.0, 14→12, UAT prelim→10.5/9.3, CT unresolved/out-of-scope, SCR provenance, capability provenance + DERIVED 360-MW interp, 45.01 kA, solid grounding, 354 MW, 12+j5, old line params) | Prompt §20 fencing in report. |
| 17 | report new §12 / §13 | (absent) / STOP was §12 | added Equipment-Rating Observation (F3 50.40 kA adjacent to 50-kA rating; NOT a failure; no duty verdict; Phase-5 uses through-currents + ratings); STOP renumbered §13 | Prompt §19. |
| 18 | report misc | `re-verified at gate close` | `re-checked at gate close` | Avoid proximity to banned `independently verified` phrasing. |
| 19 | (prior session, referenced) | F1/F2 Zf divided by 529 | level-base divisor (4.84 F1/F2, 529 else) | Final-review fix wave; re-verified here (§E). |

NOT changed (deliberately): all engineering values (recompute matches §E); spec body (phrase hits all denials/correct-wording contexts); CSV numbers (identical physics; footnotes refreshed by suite re-run).

## B. DATA CONSISTENCY MATRIX (value / unit / base / source / status / implementation use)

Generator — `Snom 458 MVA / Vnom 22 kV / 50 Hz / PF-ref 0.85` (nameplate + Siemens §2.1, SOURCE/PRIMARY; PF not a fault input — prefault P/Q come from solved CSVs). `Xd 1.783 / Xd' 0.3256 / Xd''_sat 0.2248 pu` (Siemens §2.1.1-corroborated saturated triple; E''/E'/Eq derivation + stage reactances). `Xd''_unsat 0.2608 / Xq 1.751 / Xq' 0.5087 / Xq'' 0.2593 / Xl 0.2027 / X2 0.2242 / X0 0.128 pu / Ra 0.00089 ohm` (workbook row 3, SOURCE/PRIMARY project data with QUALIFIED rationale; X2/X0 never Siemens-OEM-verified, never substituted). `H 5.287 s / SCR 0.601 / capability 6 points` — correctly ABSENT from fault physics (no dynamics in scope); provenance in §C. Dispatch 360 MW primary (operating profiles + solved CSVs); Siemens rated 389.30 MW (reference only).
NER — `V1 22/√3 kV / V2 500 V / 135 kVA / 20 s` (Siemens §2.3, SOURCE/PRIMARY) → `n 25.40341184 / Rrefl 1690.773333 / RNER 1750.773333 / 3ZN 5252.32 ohm` (DERIVED, additive per heading; §D). Use: generator-neutral zero branch ONLY (validated L10/L11). NGT series MISSING (neglected-vs-bounded sensitivity).
GSUT — `230/22 kV / YNd1 / 355/460/515 MVA / Z 16.0% / R 0.21% / Z0 15.8% on 515 MVA tap 9` (datasheet, SOURCE/PRIMARY). HV neutral solid = documented engineering equivalent (ASSUMPTION, "no measured record" in code/ledger — never called measured). LV delta blocks zero.
UAT — `22/6.9 kV / Dyn11 / 19/25 MVA / Z 10.5% / R ≈0.4% / Z0 ≈9.3% on 25 MVA` (datasheet, SOURCE/PRIMARY). 5-A limit (SOURCE constraint) → `ZN_UAT ≈ 796.743 ohm` DERIVED equivalent (alternatives = sensitivities). Winding 6.9 kV vs plant bus 6.6 kV dual-base rule; no 6.9-kV bus invented (grep-clean).
GAT — `230/6.9/3.32 kV / YNyn0+d11 / 19/25 MVA / Z_PS ≈12% / R ≈0.5% / Z0_PS ≈10.8% ±7.5%` (datasheet-in-UAT-docs, SOURCE/PRIMARY pairwise). HV solid ASSUMPTION; LV 5-A → `ZN_GAT_LV ≈ 796.743 ohm` DERIVED equivalent. Z_PT/Z_ST MISSING → H0 open approx / H1 closed equivalent base (λ 1.0→0.108 pu, 0.5/2.0 sens) / H2 limiting sensitivity (never proof, never exact model, never auto-dominant).
Grid — `Ik'' 50 kA` (SOURCE/PRIMARY + ESTIMATED qualifier, corr. 1–3) → `Sk'' 19918.58 MVA / |Z1| 2.65581124 ohm` DERIVED (magnitude, never X; XN 2.66 separately reported, never paired — code holds it informational only). `X/R 15 [10,20] / k0g 1.5 [1.0,2.0]` ENGINEERING_ASSUMPTION bands. Secondary `45.01 kA / 10.99` LEGACY sensitivity-only, never merged. Rgrid = 0 LF-only, absent from fault code (grep-clean).
Line — `0.7 km / 2 ckt / MALLARD_795_MCM reference-only`; `R1 0.00015 / X1 0.00077 / Y1 0.001488 pu/km / Zbase 529`; `R_eq 0.0277725 / X_eq 0.1425655 / B_eq 3.937996` (frozen ASSUMPTIONs, runtime-asserted). F4 explicit branches `Z_branch = 2·Z_eq / B_branch = B_eq/2`, m ∈ {0,.25,.5,.75,1}, restoration-asserted. R0/X0/B0 source-MISSING → `kR [2.0,5.0] / kX [2.0,3.5] / kB [0.60,0.85]`, base (3.5, 2.75, 0.725) → 0.09720375 / 0.392055125 / 2.8550471 (ASSUMPTION band, never measured/verified/proof-of-mutual).
Fault framework — F1–F5 (+B6_6 auxiliary-only), F1/F2 same node separate labels, REMOTE assumed boundary; `Zf = 0` base + `0.01 pu earth (3×) / 0.002 pu phase (undivided)` local-base sensitivities (F1 0.0484/0.00968, F3 5.29/1.058 ohm); stages Ik''/Ib(t_break study-reference)/Isteady/Ip(design-defined κ shape, no per-leg table, no IEC claim).

## C. LEGACY CONFLICT TABLE

In report §9 (corr. 16) and code-verified absent: 16.63% (no hit in phase4/), 14%-GAT (no hit), UAT prelims (code holds 10.5/≈0.4/≈9.3 only), 15000/1-vs-16000/1 CT (no CT-selection logic in code; unresolved, out of scope), SCR 0.58-vs-0.601 (neither in fault code; 0.601 kept as project-data only), 45.01 kA (sensitivity-only dataset S), solid grounding (rejected; `ZN = 0` primary errors), 354 MW + 12 MW+j5 (historical; code uses frozen 14 MW aux from CSVs), old line params (code holds frozen Mallard totals only), X0 = 3X1 / R0 = R1 / B0 = B1 (only denial comments + band math; no factual use), Rgrid = 0 in faults (no code path), XN-pairing (imaginary-R proof stands; no pairing path).

## D. NUMERICAL ARITHMETIC CHECKS (independent PowerShell recomputation — all match)

`Zbase = 230²/100 = 529` ✓. `n = (22000/√3)/500 = 25.40341184` ✓. `Rrefl = 2.62·n² = 1690.773333` ✓. `RNER = 60 + Rrefl = 1750.773333` ✓. `3ZN = 5252.32` ✓. `|Z1| = 230000/(√3·50000) = 2.65581124` ✓. `Sk'' = √3·230·50 = 19918.58` ✓. `R0 = 3.5·0.0277725 = 0.09720375 / X0 = 2.75·0.1425655 = 0.392055125 / B0 = 0.725·3.937996 = 2.8550471` ✓. `GAT 10.8·0.925 = 9.99 / 10.8·1.075 = 11.61` ✓. `Zf: 0.01·4.84 = 0.0484 / 0.002·4.84 = 0.00968 / 0.01·529 = 5.29 / 0.002·529 = 1.058` ✓. Capability `α = 60/89.3 = 0.67189250 → Qmax = 280 + α(241−280) = 253.7962 / Qmin = −205 + α(−182+205) = −189.5465` ✓ (DERIVED reference; solved prefault Q 27.83/23.67 MVAr lies well within — consistency note, not an input).

## E. FAULT-RESULT CHECK (fresh MATLAB recompute vs prompt §18 + report §1)

| Loc | LLL | LG | LL | LLG | §18/report | Δ |
|---|---|---|---|---|---|---|
| F1 | 126.214 | 0.00694452 | 106.734 | 106.735 | 126.2 / 0.00695 / 106.7 / 106.7 | display rounding only |
| F3 | 50.3999 | 45.4917 | 43.5580 | 48.3077 | 50.40 / 45.49 / 43.56 / 48.31 | same |
| F4 m=.5 | 50.9257 | 45.8744 | 44.0161 | 48.7717 | 50.93 / 45.87 / 44.02 / 48.77 | same |
| F5 | 52.9560 | 48.2198 | 45.7722 | 50.9815 | 52.96 / 48.22 / 45.77 / 50.98 | same |
Max delta = display rounding (≤ 0.05%); zero numerical discrepancy. IN values likewise unchanged (not re-listed; code path untouched by this audit). m-set (LG Ia / LLL kA): m=0 → 45.4917/50.3999 ≡ F3 exactly; m=0.25 → 45.4545/50.4861; m=0.5 → 45.8744/50.9257; m=0.75 → 46.7771/51.7371; m=1 → 48.2198/52.956 ≡ F5 exactly; monotonic; audits ≤ 5.6e-15. CSV spot (`t14_smoke` F3 rows, bands 45.137–45.492) consistent. No verification invented: every figure above is executed output.

## F. CLAIM-PRECISION CHECK

Scanned (code + spec + report) for: `fully verified / independently verified / upper bound / IEC 60909 (compliance senses) / measured (neutral/arc/footing/line) / source (mislabelled derived) / full physical model / exact three-winding model / zero voltage sag`. Findings: zero genuine violations. All `IEC 60909` hits are mandated NOT-compliant disclaimers; all `upper bound` hits are the Ib-reword change-log/denial contexts; `measured` hits are negations ("no measured record/link") or test-attribution prose; `dominant` hits are the mandated no-pre-judged-labels rule + honest residual note; no `exact three-winding / full physical / zero-sag` claims exist. Report items corrected under A (7/8/11/14). Spec: no changes required (hits verified as denials/definitions).

## G. PROTECTED FILE CHECK

SHA-256 sweep vs `PHASE3_POST_HASHES.txt` (335 entries): 332 match; the only 3 differences are `matlab/data/phase2_source_data.m` + two Phase-3-plan ledger files, all timestamped 1:04–1:06 PM — i.e. pre-existing Phase-3-window drifts that predate this audit session (first audit write ≈ 6 PM class) and are unrelated to Phase 4. No Phase-3 report/data, Rev2, or results-baseline file was created, modified, or deleted by Phase-4 work or this audit. Report wording corrected per prompt §17 (A-11).

## H. FINAL STATUS

CONFIRMED (source-backed): generator ratings + saturated d-axis triple + 360 MW dispatch pair; NER device rows; GSUT/UAT/GAT nameplate % figures + neutral wordings; 50-kA Siemens estimate (as estimate); frozen Phase-3 interface; all §E fault results (recomputed identical).
DERIVED (arithmetic, checked §D): Sk''/|Z1|, NER reflection + 3ZN, line equivalents, GAT tol values, Zf ohmics, capability interpolation.
ENGINEERING ASSUMPTIONS (labelled, with sensitivities): Mallard reference, 0.7 km, X/R 15 [10,20], k0g 1.5 [1.0–2.0], line-zero band, H1 λ-model, GSUT/GAT-HV solid neutrals, 5-A equivalents, NGT-neglected base, aux shunt, Zf probes, t_break 0.06 s study time.
GENUINELY MISSING: tower/soil/shielding/transposition/mutuals, grid test record, X2/X0 test conditions, NGT series Z, Z_PT/Z_ST, UAT/GAT LV neutral devices, full Siemens report + turbine doc + INEL-0026 + JICA file, motor-infeed data, breaker clearing times, CT-selection basis.
DEFERRED TO PHASE 5: relay pickup/TMS/grading, CT selection, breaker-duty evaluation with through-currents + ratings (esp. F3 ≈ 50.40 kA adjacency — observation only here), coordination, and any scope beyond fault currents. STOP: no Phase 5 implementation performed.
Recorded limitation (no rebuild; quantified negligible): the solver stamps series R/X only — line shunt B (≈ 0.26 A/end vs kA-scale faults, ~5e-6 relative) is not stamped; topology-level shunt-division asserts hold; effect bounded below any result precision shown.
