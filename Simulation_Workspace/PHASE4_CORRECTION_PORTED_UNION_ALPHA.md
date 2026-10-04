# Phase-4 Correction Record (correction stream K1–K5)

## A. Files changed
- Code: `matlab/phase4/phase4_registry.m:26-29` (R.lv 6.6/6.9/0.4356/a), `matlab/phase4/phase4_grounding.m:25-31,109-122` (ZN/Z3N) + `:32-35` (C7 adjudication), `matlab/phase4/phase4_seqZ.m:28,194-195` (LV base 0.4356), `:205,217-222` (H2 1e-6), `:213-215` (loop 0.108/0.432), `:227-228` (GAT neutral), `matlab/phase4/phase4_solve.m:232-236` (registry canonicals), `:289-293` (aux 0.4356, 1214x note), `:350-370` (B6_6 gate 0.05), `:495-496,528-529,599,606,618-622,632-640,703-708` (taps/shifts), `:715-716` (H-legs), `matlab/phase4/phase4_validate.m:48` (T_B66 0.05), `:293-304` (L21), `:305-312` (L22), `:313-325` (L23), `:326-336` (L24), `:337-348` (L25), `:359-373` (L27), `:370` (any-all), `:403-404` (scalar guard). C8 literal-to-registry substitutions, behavior-identical, in `phase4_solve.m:47,59,234-236,289,350,494-496,599,617-618,716`, `phase4_seqZ.m:28,32,194,215`, `phase4_validate.m:48,338,403` (mapping per `task-k4-report.md:209-213`).
- Tests: `test_phase4_seqZ.m` (12 asserts; `task-k1-report.md:18` np=12 nf=0), `test_phase4_validate.m` (27 legs; `task-k1-report.md:24-32`; `task-k4-report.md:242-245`), `test_phase4_review_gate.m` (23/23; `PHASE4_REVIEW_GATE.md:22-44,63`), `test_phase4_stages.m` (F1-earth local-base extension; `task-9-report.md:80`), `test_phase4_sanity.m` (16 asserts; `task-k3-report.md:60-74` np=16 nf=0), `test_phase4_production.m` (21 asserts; `task-k2-report.md:62-67` np=21 nf=0), `test_phase4_matrix.m` + `run_phase4_matrix.m` (7 asserts; `task-k4-report.md:240-242`), plus new `run_phase4_production.m`, `phase4_sanity.m` (`task-k2-report.md:5-16`; `task-k3-report.md:7-14`). Topology tags use Q0 breaker, Q1/Q2/Q9 disconnector naming (`PHASE4_REVIEW_GATE.md:43`).
- Docs: `PHASE4_FINAL_REPORT.md` (K4 items `task-k4-report.md:21-153` + K5 polishes §A step 0), `docs/superpowers/specs/2026-09-18-phase4-fault-analysis-design.md` (K4 items `task-k4-report.md:154-214`; change-log item 25; ledger rows R.lv/Zbase_22/Z3N `task-k4-report.md:157-171`), ledger/spec entry + `matlab/phase4/TASK_LOG.md:25-27` (K2/K3/K4 detail lines).

## B. Files untouched
- All protected Phase-3/Rev2/sources and all other `matlab/` files outside §A: `PHASE3_FINAL_REPORT.md`, `PHASE3_CHANGELOG.md`, `matlab/data/ashuganj_lines.m`, `matlab/data/ashuganj_grid.m`, `rev2/data/iec_kappa.m`, `rev2/run_phase2_fault.m` (freeze `PHASE4_REVIEW_GATE.md:7-14`), `phase4_sources.m`, `phase4_prefault.m`, `phase4_seqPN.m`, `phase4_topology.m`, `phase4_stages.m`, `phase4_contrib.m`, `phase4_handoff.m`, `phase4_kappa.m`, `phase4_sensitivity.m`, `phase4_review_gate.m`, `run_phase4_tests.m` (behavior-identical; suite now 17 files via added tests).
- Prior results baselines retained, not overwritten; `production/` is an additive archive; working/smoke tags retained separately. C14 sweep confirms only the 3 known pre-existing drifts (`task-k4-report.md:216-228`; 335 checked, 1:04–1:06 PM stamps).

## C. Every numerical correction
- Aux: 0.005009 → ~6.08 pu (÷529 → ÷0.4356, 1214×). Before treatment pu on 529 (`task-8-report.md:35-36`); after `Zaux_ohm/Zbase_LV` (`phase4_solve.m:292-293`); LV base 0.4356 (`phase4_registry.m:28`); frozen 529 (`phase4_registry.m:24`); ratio 529/0.4356 = 1214.37 arithmetic; 1214x base-error note (`phase4_solve.m:289-290`); L23 residual 1.63e-16 (`phase4_validate.m:325`; `task-k4-report.md:242-245`).
- UAT/GAT LV tap: 1.0 → 0.95652·e∓j30 (UAT, conjugate neg seq) / 0.95652 (GAT, 0° incl. zero). After magnitude 0.95652 (`phase4_solve.m:618`); UAT −30° pos / +30° neg (`phase4_solve.m:599,606`); GAT 0° both sequences (`phase4_solve.m:632-640,703-708`); nominal a = 6.9/6.6 = 1.045454545 (`phase4_registry.m:29`; spec `design.md:293`); L22 residual 0 (`phase4_validate.m:312`; `task-k4-report.md:242-245`). Before unity superseded; direction pinned by §D gate.
- ZN LV branch: 796.74 → 2390.23 ohm single-count. Physical 796.743371 (`phase4_grounding.m:118-119`; `test_phase4_grounding.m:9-10`; `test_phase4_seqZ.m:14`); stamped 3× ≈2390.2301 (`phase4_grounding.m:121-122`; `task-k4-report.md:253-257` executed (6900/√3)/5×3 = 2390.23011444505; spec ledger `design.md:197,204`). Adjudication, stated plainly: prompt §7 literal (stamp 796.743 with no ×3) would give Ia = 15 A, contradicting the 5-A source limit and the generator-NER precedent (physical + 3ZN stamped, F1 LG 7.25-A hand-check); the ×3 below is therefore REQUIRED, applied exactly once (`phase4_grounding.m:32-35`); adopted single-×3 with Ia ≈ 5 A (`phase4_grounding.m:25-31`); prompt §7 overridden on physics; explicit approval invited if 15 A intended.
- Tertiary loop stamped: 0.108 → 0.432 pu + dual identities. 25-MVA 0.108 (`phase4_seqZ.m:213`; `test_phase4_seqZ.m:6`); 100-MVA 0.432 = 4× (`phase4_seqZ.m:214-215`; `test_phase4_seqZ.m:7-8`; `phase4_review_gate.m:144-145`; `task-k4-report.md:166-169`).
- H2: omitted → 1e-6 stamped (ordering H2>H1>H0 live). Short-limit 1e-6 (`phase4_seqZ.m:205`; `phase4_solve.m:61,715`); H0 open NaN (`phase4_seqZ.m:210`); H2 branch (`phase4_seqZ.m:217-222`); L25 violation count 0 + ordering (`phase4_validate.m:337-348`; `task-k4-report.md:242-245`).
- ZN pu base: 0.4761 → 0.4356. 0.4761 = 6.9²/100 winding base superseded; 0.4356 = 6.6²/100 bus base adopted (ohmic table `design.md:406`; `phase4_registry.m:28`; `phase4_seqZ.m:194`; `phase4_validate.m:317`).
- Ik status: ENGINEERING_ASSUMPTION → SOURCE/PRIMARY+ESTIMATED (value 50 unchanged). 50 kA (`phase4_registry.m:59`; `PHASE4_AUDIT.md:14-16` corr. 1–3, value unchanged).
- C8 literal→registry substitutions, behavior-identical, files listed in §A (mapping `task-k4-report.md:209-213`).

## D. Every modelling correction
- LV zone on 6.6-kV base (`phase4_registry.m:26-28`; `phase4_solve.m:234,289-293`; `phase4_seqZ.m:28,194`; `phase4_validate.m:317`).
- Explicit nominal taps + Dyn11 shift (GAT 0°) with B6_6-gate evidence (`phase4_solve.m:599,606,618-622,632-640,703-708`; `phase4_registry.m:29`; L22 residual 0 `phase4_validate.m:312`). Shift direction confirmed: no-shift residual 0.495 (defect-scale; code records defect signatures 0.50–1.00 demonstrated pre-fix `phase4_solve.m:356`; pre-gate sweep no-shift 31% trips vs +30° 4.75% passes `task-8-report.md:39-42`) vs shifted 0.025691/0.028839 (`task-k1-report.md:24-25`; `phase4_solve.m:351`; `phase4_validate.m:48,304`).
- B6_6 complex gate added: tol 0.05 from measured 0.0257/0.0288, ~2× margin, 10–20× below defect class (`phase4_solve.m:351,355-356`; `phase4_validate.m:48`; `task-k1-brief.md:10-15`; `task-k1-report.md:24-25`).
- H2 short-limit topology (`phase4_seqZ.m:205,217-222`; L25 `phase4_validate.m:337-348`).
- ZN single-count semantics (`phase4_grounding.m:25-35,121-122`; `phase4_seqZ.m:32-34,194-195,227-228`).
- V-A..V-G legs (L21 B6_6 gate, L22 tap, L23 aux, L24 loop identity, L25 H2-vs-H0, L26 continuity, L27 handoff; `phase4_validate.m:8-10,293-373`; residuals `task-k4-report.md:242-245`: L21 0.028839/0.05, L22 0, L23 1.63e-16, L24 0, L25 0, L26 4.87e-16, L27 0).
- Sanity module (`phase4_sanity.m`; 16/16 `task-k3-report.md:60-74`; suite 140/140 at K3 time).
- Production package (`run_phase4_production.m`; 21/0 subset, 161/0 full `task-k2-report.md:62-75`; 464/204/20/2040/33 §J).
- L27 any-'all' fix + assembly scalar guard (`phase4_validate.m:370` any-all; `:403-404` guard). Transport-anomaly scare root-caused to `any()`-over-matrix returning a row vector + fprintf format recycling in the new L27 leg (double-print, impossible 100/115/61 values; `task-k1-report.md:47`; `progress.md:81`); no solver/math defect.

## E. Before/after prefault
- B6_6: 0.0045/0.0047 → 1.0075/1.0243 pu (targets 1.000909/1.020670). After solved 1.007457/1.024263, targets 1.000909/1.020670, d6 0.025691/0.028839 (`task-k1-report.md:24-25`); before collapsed magnitudes superseded (collapsing note `phase4_solve.m:290`; brief §E requirement).
- pre_res: 0.0475/0.0538 → 0.0328/0.0328. Before 0.047510/0.053768 (`task-10-report.md:14`; `task-11-report.md:46`; `task-8-report.md:64-65`; baseline `task-k1-brief.md:23`); after 0.032777/0.032803 (`task-k1-report.md:28-31`; `task-k4-report.md:242-245`; `TASK_LOG.md:27`; backbone `task-k4-report.md:87-90`; L20 maxPre 0.032803 vs 0.10 `phase4_validate.m:43-47`). Aux bug was the dominant driver (`phase4_solve.m:289-290`).

## F. Before/after fault results (OUT base)
- F1 LG I1: 0.000882 → 0.000924 pu (Ia 6.95 → 7.27 A). Before I1 0.000882 (`task-11-report.md:46,97`; `task-9-report.md:80`), Ia 0.00264622 (`task-9-report.md:80`), 6.94452 A (`PHASE4_AUDIT.md:59`); after 0.00727200442799167 kA = 7.272004 A (`task-k4-report.md:58-62` production row).
- F3 LLL: 200.779 → 201.301 pu (50.40 → 50.53 kA). Before 200.779041 (`task-10-report.md:14`; `task-11-report.md:46`; `task-13-report.md:23`), 50.3999 kA (`PHASE4_AUDIT.md:60`); after 50.5308851865359 kA (`task-k4-report.md:62-64`; `phase4_fault_currents.csv:18` verified this task).
- F3 LG: 60.409 → 60.735 pu (45.49 → 45.74 kA). Before 60.408726 (`task-10-report.md:14`; `task-13-report.md:23`), 45.4917 kA (`PHASE4_AUDIT.md:60`); after 45.7377472846575 kA (`task-k4-report.md:62-64`; `phase4_fault_currents.csv:20` verified this task). pu/kA via Ibase 2.624319 kA (F1/F2 22 kV) / 0.251022 kA (F3/F4/F5 230 kV) (`task-13-report.md:12`); LG Ia = 3×I1.
- GAT-IN earth paths shift (loop ×4 weaker tertiary effect `phase4_seqZ.m:214` + ×3 LV neutral `phase4_grounding.m:121-122`); IN LG 45.8917695676112 kA vs OUT 45.7377472846575 kA (`task-k4-report.md:65-66,262-264` micro-duplicate note).
- H2-vs-H0 LG now distinct with ordering (L25 loopH0=0/loopH2=1/ord=1 residual 0; `phase4_validate.m:342-348`; `task-k4-report.md:242-245`).

## G. Difference percentages for §F
- F1 LG: +4.8% seq ((0.000924−0.000882)/0.000882 = 4.76%) / +4.6% Ia (7.272 vs 6.945; before `PHASE4_AUDIT.md:59`, after `task-k4-report.md:58-62`).
- F3 LLL: +0.26% ((201.301−200.779)/200.779; before `task-10-report.md:14`, after `phase4_fault_currents.csv:18`).
- F3 LG: +0.54% ((60.735−60.409)/60.409; before `task-13-report.md:23`, after `phase4_fault_currents.csv:20`).

## H. Practical comparisons
- F3 LLL 50.53 kA (`phase4_fault_currents.csv:18`; `task-k4-report.md:62-64`) vs Siemens-estimated 50 kA (`phase4_registry.m:59-60` ESTIMATED qualifier; sanity S1 50.5309 kA ratio 1.01062 `task-k3-report.md:22,44`): observation only, no duty verdict.
- F1 LG 7.27 A (`task-k4-report.md:58-62`) vs NER hand estimate 7.25 A (`phase4_sanity.m:44` per `task-k4-report.md:80-84`; sanity S2 7.2720 A ratio 1.00304 `task-k3-report.md:25,44`): ratio 1.003; hand (22000/√3)/5252.32 = 2.41830 A seq ×3 = 7.25491 A faulted, ratio 1.002356 (`task-k4-report.md:79-84`); uncertainties: series X0, Vf≠Vph, NGT neglected (`task-k3-brief.md:9`; `task-k4-report.md:79-84`).
- B6_6 vs frozen CSV: 0.65%/0.35% magnitude (`phase4_solve.m:351-352` 0.65% magnitude + ~1.4° angle; `task-k1-brief.md:10`; shifted d6 0.025691/0.028839 `task-k1-report.md:24-25`).

## I. Validation result
- 27/27 legs, V-A..V-G all pass with residuals (`task-k4-report.md:242-245`: L21 0.028839/0.05, L22 0, L23 1.63e-16, L24 0, L25 0, L26 4.87e-16; `phase4_validate.m:293-373`; live production 27/27 `manifest.json:299-305`; `task-k2-report.md:69-71`).
- Full suite 161/161, 0 failures, 17 files (`task-k2-report.md:72-75`; `task-k4-report.md:237-245` per-file 5/10/3/7/11/21/21/3/16/9/6/12/5/15/8/6/3, 31.1 s; `TASK_LOG.md:25-27`).
- Gate 23/23 regenerated (`PHASE4_REVIEW_GATE.md:22-44` true; `:63` 2026-09-19 00:48:32; Q8 0.432 wording, Q18 27/27 `task-k4-report.md:230-234`).
- C14 exactly the 3 known pre-existing drifts (335 checked; `task-k4-report.md:216-228`).

## J. Full production output inventory
- `results/phase4_fault/production/`: `phase4_fault_currents.csv` 464 rows, `phase4_contributions.csv` 204 rows, `phase4_bands.csv` 20 rows, `phase4_ct_data.csv` 2040 rows, `analytic_bounds.csv` 33 rows (`manifest.json:189-195`; `task-k2-report.md:28-60`; line counts verified this task: 465/205/21/2041/34 incl. header), plus `manifest.json`, `sha256.txt` (7 files; hashes `task-k2-report.md:49-55`; `sha256.txt` re-read this task), `run_log.txt` (K2 diary content `task-k2-report.md:95-98`). Files list `manifest.json:196-205`. Scratch/probe tags fenced as non-archive (`manifest.json:306-312` notes; `task-k4-report.md:141-148`: production_segN, prod_subset, v27probe are not the archive; `PHASE4_FINAL_REPORT.md:12`).

## K. Remaining genuine data gaps
- D1–D8 unchanged (`PHASE4_REVIEW_GATE.md:46-58`: D1 MISSING, D2 ESTIMATED/LEGACY/ASSUMPTION, D3 QUALIFIED, D4 NGT MISSING, D5 INCOMPLETE, D6 MISSING, D7 MISSING, D8 UNCERTAIN; `PHASE4_FINAL_REPORT.md:85-87`).
- UAT/GAT vector-shift angles beyond Dyn11/0° treatment: none (wider-angle behaviour pre-existing limitation; spec `design.md:293`; `task-k4-report.md:173-184`).
- Line-shunt unstamped (~5e-6 effect, documented limitation; `PHASE4_AUDIT.md:80`; series-only note `phase4_solve.m:48-49`).
- H-leg bounds remain assumption-class (Z_PT/Z_ST MISSING `phase4_seqZ.m:22-24`; separation magnitudes are model physics `phase4_validate.m:338-341`; H2 never proof).
- Tolerance bands in E5/H3/L1 joints (additive ovr scales `phase4_grounding.m:13-24`; gatZ0sel `phase4_seqZ.m:11-16`).

## L. Phase-5 readiness
- Fault-current dataset complete with provenance/schema/bands (`production/` §J; schema `task-k4-report.md:141-148`; provenance `phase4_registry.m` + spec ledger `design.md:197-207`; bands 20 rows `manifest.json:189-195`).
- NO protection settings/duties/coordination started or present (gate-scanned; `PHASE4_REVIEW_GATE.md:44` Q23 0 hits; `:60-61`; notes `manifest.json:306-312`; `PHASE4_FINAL_REPORT.md:92-95`).
- STOP awaiting explicit Phase-5 approval (`PHASE4_REVIEW_GATE.md:59-63`; `PHASE4_FINAL_REPORT.md:93-95`).
