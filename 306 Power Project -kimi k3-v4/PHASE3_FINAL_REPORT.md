# Phase 3 Final Report — Locked 0.7 km Lumped Dual-Circuit Mallard PI Line Model
## Ashuganj South 450 MW CCPP (EEE 306 Power Project)

**Phase:** REV3.1 Phase 3 — physical transmission/network representation (locked 0.7 km line model)
**Date:** 2026-09-18
**Status:** Phase 3 complete and frozen. Full regression suite 1388 passed / 0 failed (REV3.1 reconciliation).
**Workdir:** `C:\Users\sindi\Downloads\306 Power Project -union alpha` (no git repo; hash-based audit used throughout)
**Plan:** `docs/superpowers/plans/2026-09-18-phase3-locked-07km-line-model.md` (15 tasks, all complete, all review-clean)
**Design spec:** `docs/superpowers/specs/2026-09-18-phase3-line-model-design.md`
**Change record:** `PHASE3_CHANGELOG.md` (Tasks 1–14)
**Hash baselines:** `PHASE3_PRE_HASHES.txt` (313 lines) / `PHASE3_POST_HASHES.txt` (335 lines)

Phase 3 establishes and validates the physical transmission/network representation. Symmetrical short-circuit analysis is reserved for Phase 4 and has not been implemented in this phase.

---

## 1. Executive Summary

Phase 3 replaced the broken 70 km generic line artifact with a locked 0.7 km lumped dual-circuit Mallard 795 MCM positive-sequence PI branch (`L_LINE`, `B230_1 → B230_REMOTE`) and moved the grid Thevenin equivalent (`ZGRID`) to the new remote bus (`B230_REMOTE → BGRID230`). The locked equivalent is R 0.0277725 ohm / X 0.1425655 ohm / B 3.937996 uS (pu on 100 MVA / 230 kV: R 0.0000525 / X 0.0002695 / B 0.0020832). All six operating cases solve in 2 iterations with Verdict OK; conservation holds 6/6 (max P error 1.57e-05 MW, max Q error 1.64e-06 MVAr, max KCL 6.39e-04 MVA); sensitivity holds 9/9 OK; the full suite passes 1368/0; protected Phase-2 files are byte-identical PRE vs POST; the change table accounts for every modified/added file with authorization. Zero-sequence data remain MISSING by rule. No fault, sequence-network, relay, breaker-duty, dynamic, battery, AVR, governor, or SFC work was performed in this phase.

## 2. Scope

In scope: source audit of the supplied documents for South-230-kV line evidence; locked 0.7 km lumped dual-circuit PI implementation in `matlab/data/ashuganj_lines.m`; grid header reconciliation in `matlab/data/ashuganj_grid.m` (comments only, no numeric change); validator/runner rewrite on the Phase-2 field schema; OLD-vs-NEW compatibility analysis; loading / voltage-drop / loss reporting with independent hand checks; conservation gates; in-memory sensitivity runs; full regression; hash/change audit; this report.

Out of scope (Global Constraints, unchanged): Phase-2 generator numerics; capacity policy; fault/sequence/relay/TMS/breaker-duty/dynamic/battery/AVR/governor/SFC work; new struct status strings; any retuning of R/taps/tolerances to silence failures. The 70 km figure is retained only as a documented conflict (400-kV/North block); the 44 km Ghorasal line is a separate line and never the South link.

## 3. Phase-2 Baseline

Phase 2 closed frozen with full suite 1331/0 and `PHASE2_FINAL_REPORT.md`. Frozen generator numerics carried into Phase 3 untouched (hash-proven identical, see §25): 458 MVA, 22 kV, 360 MW dispatch cap, H 5.287 s, Xd 1.783, Xdp 0.3256, Xdpp 0.2608, Xdpp_sat 0.2248 (kept separate, never substituted), Xq 1.751, Xqp 0.5087, Xqpp 0.2593, Xl 0.2027, X2 0.2242, X0 0.128, Ra 0.00089 ohm, with time constants, Q capability curve, capacity guard, and NER grounding unchanged. Auxiliary load aggregate 14 MW / 8.676421 MVAr equivalent is unchanged. Operating cases: LF360_GAT_OUT / LF360_GAT_IN primary; LF342_GAT_OUT / LF342_GAT_IN qualified owner scenario (342.01 MW); LF389P30_GAT_OUT / LF389P30_GAT_IN historical reference only (389.30 MW, approved-exception path). Capacity policy is unchanged.

## 4. Source Hierarchy

Struct statuses use the closed enum in `matlab/data/ashuganj_master_data.m:36-38` (`VERIFIED_PLANT, VERIFIED_ENGINEERING_DOCUMENT, VERIFIED_PROJECT_DATA, DERIVED_FROM_VERIFIED_DATA, PRIMARY_VERIFIED, PRIMARY_SOURCE_QUALIFIED, ENGINEERING_ASSUMPTION, HISTORICAL, LEGACY, ESTIMATED, MISSING, NOT_APPLICABLE, AVAILABLE_NOT_DIGITIZED`). No new status strings were introduced in Phase 3. Alongside each struct status, the final tables carry a human-readable source-tier column: L1 as-built/datasheet/PGCB-supplied South row → `VERIFIED_*` / `PRIMARY_SOURCE_QUALIFIED` with document plus page/section; L2 workbook/verified dataset → `PRIMARY_SOURCE_QUALIFIED` or `VERIFIED_PROJECT_DATA` with sheet/cell; the disputed 70 km row → assumption, never verified; L4 math from source rows → `DERIVED_FROM_VERIFIED_DATA` with inputs, formula, units, result; L5 academic fill → `ENGINEERING_ASSUMPTION` with basis, finite range, sensitivity; benchmarks → `HISTORICAL` (389.30 MW) / qualified scenario (342.01 MW); superseded → `LEGACY`; absent → `MISSING` with the dependent feature disabled or scoped out. The locked 0.7 km length, Mallard conductor reference, and R/X/B carry struct status `ENGINEERING_ASSUMPTION` with derivation notes, and human-tier `DERIVED_FROM_ENGINEERING_REFERENCE` (Ghorasal-Mallard PGCB/JICA reference, not a measured South-link value).

## 5. Line data.pdf Audit

`Line data.pdf` was audited as regional inventory, not as South-link proof. Its candidates are: Ghorasal 44 km Mallard 795 MCM; Comilla 79 km Finch 1113 MCM; Sirajganj 144 km Twin AAAC. None is proven as the South tap; all are excluded from the South link and retained only as engineering references. The full machine-readable audit is `docs/validation/rev31_phase3/phase3_source_audit.csv` (header + 11 rows, 12 lines): South 230-kV outgoing existence VERIFIED_ENGINEERING_DOCUMENT L1 (Data Sheet_230KV.pdf line module 2000 A — proves a bay exists, not its destination); South destination MISSING; South length MISSING (0.7 km enters only as locked engineering assumption in Task 4); Form 70 km length / R0 0.06667 ohm/km / X0 0.39472 ohm/km / B1 3.4011 uS/km CONFLICT-DOCUMENTED L2-disputed (Google Sheet Form Section 3 block whose B1 baseline reads "Standard 400 kV bundled" and whose Sections 4–5 read "400 kV Bus Fault [Contact PGCB]", "400 kV GIS Bay CT"; retained as conflict only per `docs/model/branch_list.md:67`); Form R1/X1 MISSING (blank in source); Ghorasal 44 km SECONDARY_SOURCE L2 (excluded from South link, engineering reference only); INEL-112070-00-ELC-DE-0026 MISSING (authoritative GIS drawing unavailable; work does not block on it). Every model-bound row resolves to a classified status; no row is left unclassified.

## 6. Topology

Phase-2 baseline restored in Task 2: 7 register entries, exactly 1 modelled series branch (the grid equivalent), verified by `test_line_data` 47/0 green before rebuild. Phase-3 locked topology: `B230_1 --[L_LINE 0.7 km PI]--> B230_REMOTE --[ZGRID]--> BGRID230 (swing)`. Register holds 8 entries (7 Phase-2 + L_LINE); exactly 2 modelled branches (ZGRID + L_LINE). New bus `B230_REMOTE` is the remote (grid-side) end of the physical line and the connection point of the grid equivalent. `B230_REMOTE` is defined as REMOTE_GRID_BUS_ASSUMED — the assumed model boundary for the external 230-kV network; the actual destination substation is not established (INEL drawing unavailable) and no verified PGCB bus is claimed. Solver wiring uses port handles; bus identity is by handle, never by index. Every case is fresh-built per case plus `bdclose`; `power_loadflow` 50 Hz balanced solve.

## 7. Candidate Reconciliation

Candidates considered: (a) 70 km Finch double-circuit from the Google-Form Section 3 row — rejected as the South model because the row sits in the 400-kV/North block (B1 baseline "Standard 400 kV bundled", Sections 4–5 are 400-kV items), R1/X1 are blank even there, and Z1/Z0 read "Contact PGCB"; retained only as a documented conflict. (b) Ghorasal 44 km Mallard — rejected as the South link because it is a separate documented line; retained as the engineering reference for per-km constants. (c) Comilla 79 km Finch and Sirajganj 144 km Twin AAAC — regional inventory, no South-tap proof, excluded. (d) Locked 0.7 km Mallard lumped dual-circuit PI — selected: short GIS-to-grid link length as supervisor-locked engineering assumption, conductor from the Ghorasal-Mallard reference family, both circuits in service lumped into one PI branch. The 70 km artifact's failure signature (53 MW-scale spreads, `-129.26 %` drop artifact, validator crash on `LF.busname_to_idx`) is documented in the design spec §2 and is not reproduced by the locked model (see §16).

## 8. Selected Connection

Selected: assumed 0.7-km double-circuit 230-kV line, modeled using PGCB-documented Mallard 795 MCM parameters as an engineering reference, lumped single-branch PI equivalent, `B230_1 → B230_REMOTE`, label `SOUTH GIS TO GRID 0.7KM D/C EQ (MALLARD REF)`. Struct fields: `Length_km = 0.7` (`ENGINEERING_ASSUMPTION`, note records the locked EA, the unavailable INEL drawing, the 70 km conflict retention, and the 44 km separation); `Physical_circuit_count = 2`; `Model_representation = 'LUMPED_DUAL_CIRCUIT_PI'`; `Conductor_reference = 'MALLARD_795_MCM'` (`ENGINEERING_ASSUMPTION`); `Vnom_V = 230000`; `Model_block = 'sps_lib/Passives/Three-Phase PI Section Line'`; `BranchType = 'PI'`; `Model_included = true`. Grid equivalent moved to the remote bus with placement note (plant bus connects via L_LINE). `B230_REMOTE` is REMOTE_GRID_BUS_ASSUMED — the assumed model boundary for the external 230-kV network; actual destination substation not established (INEL drawing unavailable). Destination substation beyond the grid equivalent remains MISSING and is not invented.

## 9. Conductor

Conductor reference Mallard 795 MCM is an engineering assumption sourced to the Ghorasal-Mallard PGCB/JICA reference family, not a measured South-link value. Per-km positive-sequence constants on the 100 MVA / 230 kV base (Zbase = 529 ohm): r1 0.00015 pu/km → 0.07935 ohm/km; x1 0.00077 pu/km → 0.40733 ohm/km; y1 (shunt) 0.001488 pu/km → B 2.81285 uS/km. No per-km constant is stored as a total and no total as a per-km constant; single-circuit 0.7 km totals and the parallel equivalent are derived explicitly in §11. Thermal ampacity for the South conductor is MISSING (see §17); the 2000 A figure in the source set is the 230 kV GIS line-bay module rating and is never used as a conductor rating.

## 10. Geometry

No South-link tower geometry, bundle configuration, phase spacing, sag, or earth-wire data was located in the source set; geometry is MISSING and no geometry was invented. The lumped nominal-PI representation does not require explicit geometry once R/X/B equivalents are fixed, and none was back-derived. Mutual impedance between the two physical circuits is declared MISSING (assumed negligible for the balanced lumped equivalent, not proven zero); the single-circuit-out sensitivity (R/X ×2, B /2) bounds the both-in-service assumption. Nominal-pi adequacy for 0.7 km at 50 Hz balanced load flow follows from wavelength-vs-length scale and the sub-MVAr charging magnitude recorded in §19; fault-location readiness at 0/25/50/75/100 % is a topology property for Phase 4 and no fault values are computed now.

## 11. Positive-Sequence

Base: 100 MVA / 230 kV, Zbase = 529 ohm. Per-km: r1 0.00015 / x1 0.00077 / y1 0.001488 pu/km → 0.07935 / 0.40733 ohm/km, 2.81285 uS/km. Single-circuit 0.7 km: R 0.055545 ohm / X 0.285131 ohm / B 1.968998 uS. Locked lumped dual-circuit equivalent (R_eq = r1_km·L/2, X_eq = x1_km·L/2, B_eq = 2·b1_km·L): R 0.0277725 ohm / X 0.1425655 ohm / B 3.937996 uS, i.e. pu R 0.0000525 / X 0.0002695 / B 0.0020832. Capacitance at 50 Hz: C = B/(2·pi·50) = 3.937996e-6/(2·pi·50) = 1.253503e-08 F, stored as `C_F` with `C_Status = 'ENGINEERING_ASSUMPTION'`. R/X/B notes record the human tier `DERIVED_FROM_ENGINEERING_REFERENCE` with the exact arithmetic shown above. Gated by `test_phase3_line_model` (20/0) with 1e-9 ohm / 1e-15 F tolerances, and re-verified after sensitivity runs (20/0 PASS with committed values byte-identical).

## 12. Zero-Sequence Status

R0, X0, B0 (C0) are MISSING, never invented: `R0_ohm = NaN / R0_Status = 'MISSING'`; `X0_ohm = NaN / X0_Status = 'MISSING'`; `C0_F = NaN / C0_Status = 'MISSING'` (`ashuganj_lines.m:84-86`). The `3×X1` shortcut was never used as fact. Balanced-LF executability is preserved by a builder-only placeholder authorized in ledger ruling `progress.md:40`: `matlab/build/build_external_grid.m:100-114` substitutes finite positive-sequence R/X/C into the PI dialog's second vector element when the data are NaN, gated by `isfinite`, with a mandated comment; the dataset NaN/MISSING values are untouched. Phase-4 fault readiness for zero sequence is therefore explicitly not claimed (see §28).

## 13. Line Model Selection

Selected: single-branch lumped nominal-PI equivalent representing two identical balanced circuits in parallel, both in service, negligible mutual coupling. Justification recorded rather than assumed from convenience: at 0.7 km / 50 Hz the line is electrically short (charging ≈ 0.208 MVAr at 230 kV, series drop ≈ 29 V or 0.013 %), so distributed-parameter refinement adds nothing to balanced load flow while the lumped PI keeps loss/drop/charging bookkeeping exact to hand-check agreement (<1 % on P and Q across all six cases). Alternatives rejected: per-circuit two-branch PI (doubles state for identical halves; SCO case covers the contingency arithmetically); distributed-parameter line (unjustified for 0.7 km balanced LF); retaining the 70 km Finch model (wrong line, wrong voltage block, MW-scale artifacts). The SPS modal-propagation warning (`419281 km/s > 300000 km/s` on L_LINE) is a cosmetic short-lumped-PI heuristic artifact present in all solves; load flow converges normally (2 iterations) and transient/propagation work is out of scope.

## 14. Grid Equivalent

Grid Thevenin equivalent stays ESTIMATED at the remote bus: Isc 50 kA (ESTIMATED Siemens §2.4 external-grid source quantity — UNgrid 230 kV; XN 2,66 estimated [=2.66, European decimal]; Sk 19.919 [=19,919 MVA]; Ik 50 kA; line prints XN = UNgrid/(3·Ik′′) with root lost, executed math uses √3 giving 2.65581124 ohm; `Isc_Status = 'ESTIMATED'`), Ssc = √3·230 kV·50 kA = 19918.5842870421 MVA, |Z| = V²/Ssc = 2.65581123827228 ohm DERIVED (XN ≈ 2.66 is the separately-reported rounded estimate — never paired as exact R/X), R = 0 ohm (`ENGINEERING_ASSUMPTION` EA-FOR-BALANCED-LF-ONLY per Q1a), X = |Z| (`ESTIMATED`), L = X/(2·pi·50). Equipment 50 kA/1 s+3 s, 125 kA peak, 50 kA making are independent EQUIPMENT RATINGS, not this source. The derivation chain in `matlab/data/ashuganj_grid.m:74-113` is arithmetically verified. Placement: equivalent sits at B230_REMOTE behind the 0.7 km physical line (`ashuganj_lines.m:31-32` ZGRID `BGRID230 → B230_REMOTE`; `ashuganj_grid.m` header, `G.Bus_remote = 'B230_REMOTE'` display field + `G.Grid_equivalent_bus = 'B230_REMOTE'` semantic field, legacy `Bus_boundary = 'B230_1'` fallback kept; `Model_Note` span → B230_REMOTE). No numeric change was made to the estimate in Phase 3. The secondary 45.01 kA / X/R 10.99 set stays a separate sensitivity profile (Ssc 17930.71 MVA, |Z| 2.950246 ohm, R 0.267344 ohm, X 2.938108 ohm, X/R 10.99, executed c=1 values per `matlab/studies/rev3_b1_derivations.m:267-275`); 50 kA is never combined with X/R 10.99, and the circulating |Z| = 3.25 ohm figure is consistent with 45.01 kA only at voltage factor c ≈ 1.10, never mixed into the primary. Rgrid = 0 is an engineering modelling assumption for the balanced Phase-3 load-flow equivalent (infinite X/R); it must not be carried unchanged into fault/protection calculations where X/R and DC offset matter.

## 15. Integration

Delete-and-rebuild executed per plan: Task 2 removed the broken other-AI artifacts (`validate_phase3_network.m`, `run_phase3_load_flow.m`, `results/phase3_loadflow/`, eight `phase3_lf_test*.txt` scratch files — 11 paths) and restored the 7-branch baseline with `sum([L.Model_included]) == 1` (47/0 green); Task 4 appended the locked L_LINE PI plus the ZGRID→B230_REMOTE move with asserts `numel == 8`, `sum == 2`; Task 5 rewrote the validator on the `ashuganj_bus_map` + Phase-2 field schema (31 runner-consumed fields); Task 6 rewrote the runner (fresh build → solve → validate → close → record → optionally write, with non-convergence guard). Two reporting-alignment fixes were authorized by ledger ruling and are confined to post-processing with data untouched: `ashuganj_branch_flows.m` (ZGRID span → B230_REMOTE when L_LINE is modelled with legacy fallback kept; new `pi_line_branch()` nominal-PI reconstruction named `L_LINE`; per-bus vbase renormalization, ×1.0 identity for Phase-2) and the V_REMOTE_kV / V_pu_nom display normalization (kV sourced from bus results; CSV pu emitted as V_kV/Vnom when block base differs from nominal). Solver, builders (except the §12 placeholder), datasets, and thresholds were not retuned.

## 16. LF Compatibility

All six cases solve fresh with 2 iterations and Verdict OK (Write=true artifacts: `results/phase3_loadflow/phase3_system_summary.csv` 6 rows + header, 2529 B; `phase3_bus_results.csv` 54 rows, 3899 B; `phase3_loadflow_results.mat` 13908 B). LF360_GAT_OUT: export 345.207254 MW / −26.267474 MVAr, total loss 0.792747 MW / 45.423693 MVAr, line 0.062928 MW / 0.115169 MVAr, V230_1 229.760477 kV, V_REMOTE 229.731274 kV, KCL 3.267024e-05 MVA, P err 9.404895e-07 MW, Q err 6.822496e-07 MVAr. LF360_GAT_IN: export 345.194542 MW / −30.029544 MVAr, line 0.063035 MW / 0.115799 MVAr, V230_1 229.714716 kV, V_REMOTE 229.687837 kV, KCL 5.772916e-04 MVA. LF342 pair: exports 327.273302 / 327.263138 MW. LF389P30 pair: exports 374.409463 / 374.392417 MW (historical only). OLD-vs-NEW (`docs/validation/rev31_phase3/phase2_vs_phase3.csv`, header + 40 rows): Gen P fixed at 360.000000 both eras; Gen Q 28.170239 → 27.832638 (OUT) and 23.987427 → 23.668784 (IN) as the machine holding 22 kV redispatches around added line X plus charging; export Δ −0.062895/−0.063021 MW equals L_LINE 3I²R loss (0.062928/0.063035) within 3.3e-05/1.4e-05; V230_1 +24.017/+21.900 V (+0.010 %) as half-shunt charging at the plant end outweighs series drop; all other branch losses moved < 3.1e-05; iterations 2 → 2; KCL 6.07e-08 → 3.27e-05 (OUT) and 5.38e-04 → 5.77e-04 (IN), all far below the 0.05 gate. Nothing was forced toward OLD numbers; every delta traces to series drop plus charging plus Q redispatch. Compatibility gate: 6/6 OK. Length sensitivity (`docs/validation/rev31_phase3/phase3_sensitivity.md` set (d), 0.5/0.7/1.0 km in-memory on LF360_GAT_OUT): now 12/12 runs (9/9 + 3 length points with 0.7 shared), all Verdict OK.

## 17. Loading

Line current from through-power proxy I = S/(√3·V) with S = √(Pexp² + Qexp²) from grid-export P/Q (ZGRID is series-only so export S ≈ line S) and V = sending-end V230_1: LF360_GAT_OUT S 346.2052 MVA / Vs 229.760477 kV → 869.96 A; LF360_GAT_IN S 346.4983 MVA / Vs 229.714716 kV → 870.87 A (Vr-based I differs by ≈ 0.01 %, negligible). Thermal loading percent: Thermal rating unavailable — `matlab/data/ashuganj_lines.m:55` states the line carries no thermal rating; the 2000 A source figure is the 230 kV GIS line-bay module rating (proves a bay exists, not a conductor ampacity) and is not used as a rating. Loading percent is therefore NaN by rule, not by omission; current ≈ 870 A is stated instead. Equivalent D/C branch current ≈870 A; ≈435 A per identical circuit under equal sharing; relay/breaker duty in later phases must use per-circuit current. Transformer loadings are substantively unchanged OLD→NEW (GSUT ≈ 67.26 % of 515 MVA, Δ −0.003; UAT 69.227 % / 79.477 % → 79.462 %; GAT 0.000 % → 0.263 % back-energised magnetising only in GAT_OUT, 27.972 % → 28.001 % loop flow in GAT_IN). Full derivation: `docs/validation/rev31_phase3/phase3_line_loading_drop_loss.md` §1.

## 18. Voltage Drop

Solved load-flow voltages (model result, not field measurements), both ends from `phase3_bus_results.csv` V_kV post display fix, ΔV% = (|Vs| − |Vr|)/|Vs|·100: LF360_GAT_OUT Vs 229.760477 / Vr 229.731274 → ΔV 29.203 V, 0.012710 %; LF360_GAT_IN Vs 229.714716 / Vr 229.687837 → ΔV 26.879 V, 0.011701 %. Plant-end vs OLD: OUT +24.017 V (+0.010455 %), IN +21.900 V (+0.009534 %), ≈ +0.01 % rise; the remote bus sits ≈ 29/27 V below the plant bus. Sign and size match a 0.7 km short line: half-shunt charging supports the plant end while series drop puts the remote end marginally lower. First-order cross-check ΔV ≈ (R·P + X·Q)/V with signed plant→grid Q gives 25.43 V vs measured 29.203 V (OUT) and 23.10 V vs 26.879 V (IN): same sign, same order, ≈ 13–14 % low, as expected of a formula that ignores shunt-charging distribution and uses post-ZGRID Q; using unsigned |Q| would give ≈ 58 V (≈ 2× measured), so the signed-Q form is the physically consistent one. Full derivation: `phase3_line_loading_drop_loss.md` §§2–4.

## 19. Losses

For the assumed 0.7-km double-circuit 230-kV line, modeled using PGCB-documented Mallard 795 MCM parameters as an engineering reference, branch-reconstruction reported line loss: OUT 0.062928 MW / 0.115169 MVAr; IN 0.063035 MW / 0.115799 MVAr; both positive (P consumed in R as 3I²R; Q net inductive as series 3I²X exceeds shunt V²B) — correct sign. Independent hand check with locked R/X/B and Vs-based I: OUT 3I²R 0.063057 vs reported 0.062928 (+129 W, +0.2 %), net Q 3I²X − V²B = 0.323691 − 0.207886 = 0.115805 vs 0.115169 (+0.6 %); IN 0.063189 vs 0.063035 (+154 W, +0.2 %), net 0.116565 vs 0.115799 (+0.7 %). Residuals are expected (hand calc uses post-ZGRID export S; solver integrates exact sending-end flows and distributed PI shunts); agreement to <1 % confirms the reported losses. Total-loss deltas OLD→NEW equal the line loss (OUT +0.062896 MW total vs 0.062928 line; IN +0.063006 vs 0.063035) with no other branch moving more than 3.1e-05. Loss scales as I² across dispatches (342 → 360 → 389 MW: line P 0.0565 → 0.0629 → 0.0741 MW). All six cases ΔP ≤ +0.25 % / ΔQ ≤ +0.8 % vs OLD-era scale.

## 20. Conservation

Gate thresholds (validator `validate_phase3_network.m:40-43`): P error < 1e-3 MW, Q error < 1e-3 MVAr, worst KCL < 0.05 MVA per case. Sign convention (`validate_phase3_network.m:30-33`): Generation = Grid export + Loads + Losses with grid/load injections signed consuming/exported and branch losses as dissipation; worst_KCL_MVA is the max bus complex-power residual from `ashuganj_bus_results`. Results (reported full-precision validator values authoritative; CSV recomputation from 6-decimal columns agrees to quantization ≈ 1e-06): LF360_GAT_OUT P 9.404895e-07 / Q 6.822496e-07 / KCL 3.267024e-05 OK; LF360_GAT_IN 1.147858e-05 / 1.382889e-06 / 5.772916e-04 OK; LF342_GAT_OUT 9.151859e-07 / 4.852993e-07 / 3.095205e-05 OK; LF342_GAT_IN 9.222680e-06 / 1.635640e-06 / 5.416526e-04 OK; LF389P30_GAT_OUT 9.974529e-07 / 1.132818e-06 / 3.546953e-05 OK; LF389P30_GAT_IN 1.572937e-05 / 8.993878e-07 / 6.386894e-04 OK. Conservation gate: 6/6 PASS (margin ≈ 78× on KCL). Independent 3I²R spot check on L_LINE across all six cases agrees to <1 % on P and Q with correct sign in every case. GAT_IN looped cases carry the larger KCL residual in both eras (pre-existing snubber pattern, cf. `phase2_vs_phase3.csv` rows 20, 40). Evidence: `docs/validation/rev31_phase3/phase3_conservation.md`.

## 21. Register — REV3.1 reconciliation 11-row vocabulary (struct status = closed enum only; human tier = report-only)

Struct statuses use the closed enum in `matlab/data/ashuganj_master_data.m:36-38` only.
Human-tier labels (`ESTIMATED_SIEMENS_SOURCE_QUANTITY`, `DERIVED`,
`EA-FOR-BALANCED-LF-ONLY`, `REMOTE_GRID_BUS_ASSUMED`, `NOT_FULLY_VERIFIED`,
`ENGINEERING_REFERENCE_FROM_PGCB`, `DERIVED_FROM_ENGINEERING_REFERENCE`) live in the
Human-tier / Basis columns only, never as struct statuses.

| # | Parameter | Value | Unit | Struct status | Human tier (report-only) | Basis |
|---|---|---|---|---|---|---|
| 1 | South-link length L | 0.7 | km | ENGINEERING_ASSUMPTION | EA (locked Phase-3) | locked EA; INEL-112070-00-ELC-DE-0026 unavailable; 70 km (400-kV/North conflict) + 44 km Ghorasal (separate line) fenced, never the South link |
| 2 | Conductor reference | MALLARD_795_MCM | — | ENGINEERING_ASSUMPTION | ENGINEERING_REFERENCE_FROM_PGCB | Ghorasal-Mallard PGCB/JICA family ref, not a measured South-link value |
| 3 | Positive-seq R1 / X1 / B1 (lumped dual-circuit; C = B/(2·pi·50) = 1.253503e-08 F) | 0.0277725 / 0.1425655 / 3.937996 | ohm/ohm/uS | ENGINEERING_ASSUMPTION | DERIVED_FROM_ENGINEERING_REFERENCE | (0.00015 / 0.00077 pu/km·529)/2·0.7; B 2·1.968998 uS; pu 0.0000525/0.0002695/0.0020832 on 100 MVA/230 kV |
| 4 | Grid source current | 50 | kA | ESTIMATED | ESTIMATED_SIEMENS_SOURCE_QUANTITY | Siemens §2.4: UNgrid 230 kV; XN 2,66 estimated [=2.66]; Sk 19.919 [=19,919 MVA, European decimals]; Ik 50 kA; root lost in print, executed √3 |
| 5 | Grid \|Z\| | 2.65581123827228 | ohm | DERIVED_FROM_VERIFIED_DATA (arithmetic; input ESTIMATED) | DERIVED | V²/Ssc chain; XN ≈ 2.66 is the separately-reported rounded estimate — never paired as exact R/X |
| 6 | Grid R (X/R = inf) | 0 | ohm | ENGINEERING_ASSUMPTION | EA-FOR-BALANCED-LF-ONLY | Q1a balanced-LF equivalent only; must not carry into fault/protection (X/R, DC offset) |
| 7 | Zero-seq R0 / X0 / C0 | NaN | ohm/ohm/F | MISSING | MISSING | never 3×X1 as fact; builder PI-dialog placeholder only; Phase-4 input |
| 8 | South conductor ampacity | MISSING (loading NaN by rule; ≈870 A stated, ≈435 A/circuit) | — | MISSING | MISSING | no thermal rating in source set; 2000 A is a GIS bay-module rating, never ampacity |
| 9 | GIS topology beyond modelled bays | bay existence verified; full topology not established | — | MISSING (unverified part) | NOT_FULLY_VERIFIED | destination substation MISSING; INEL-0026 unavailable; no verified PGCB bus claimed |
| 10 | Remote bus B230_REMOTE | B230_REMOTE | — | (display/semantic field) | REMOTE_GRID_BUS_ASSUMED | assumed model boundary behind L_LINE; legacy `Bus_boundary='B230_1'` kept as fallback; solver uses port handles |
| 11 | GIS bay module ratings | GSUT 2000 A (10BAY11) / Line-bay 2000 A (number MISSING, NOT 10BAY20) / GAT 2000 A transformer-bay (10BAY20 per C-17; prior 10BAY12 panel-label conflict resolved) / coupler 3150 A only | A | VERIFIED_ENGINEERING_DOCUMENT | module classes (report-only detail) | REV3 §3.6 units-column audit (GT 2000 / Line 2000 / Coupler 3150); CB TRANSFORMER-BAY sheet 2000 A; SLD GAT(F13) 10BAY20 + Q0; 3150 A is coupler/busbar only |

Supplementary (not part of the 11-row vocabulary, retained for completeness):
LF389P30 389.30 MW HISTORICAL benchmark (approved-exception path); LF342 342.01 MW
qualified owner scenario; superseded 70 km Finch model (removed; documented conflict only,
LEGACY-equivalent); station battery bank 55 cells / 200 Ah / 0.05 ohm / 20 kW / 123.75 V
float (ENGINEERING_ASSUMPTION, academic — see battery note in §23).

## 22. Missing Data

Explicitly MISSING (dependent features disabled or scoped out, never filled silently): South-link destination substation; South-link measured length (0.7 km EA used instead); South-link measured R1/X1/B1 and R0/X0/B0 (EA reference values for positive sequence; zero sequence left NaN); South-link tower/bundle/geometry and mutual impedance; South-link conductor thermal ampacity (loading reported as amperes); authoritative GIS drawing INEL-112070-00-ELC-DE-0026; plant-specific battery/charger duty-cycle, manufacturer, aging, temperature, end-of-life data (IEEE 485 not claimed); 400-kV/North R1/X1 (blank even in the Form) and Z1/Z0 fault capacities ("Contact PGCB"). Each MISSING item names the consequence: no percent loading, no zero-sequence/fault model, no destination-specific Phase-4 targeting beyond the remote-bus equivalent, no battery compliance claim.

## 23. Conflicts

Conflict 1 — 70 km: Google-Form Section 3 row (L 70 km, R0 0.06667, X0 0.39472, B1 3.4011 with unit recorded as uS not S) sits in the 400-kV/North block per `branch_list.md:67`; R1/X1 blank, Z1/Z0 "Contact PGCB". Retained as CONFLICT-DOCUMENTED, never as South-230-kV source. Conflict 2 — 44 km: Ghorasal line is a separate documented line; used as engineering reference only, never as the South link. Conflict 3 — grid headers: `ashuganj_grid.m:22-23` previously stated "No 70 km line" while the lines file carried a 70 km L_LINE; reconciled (remote-bus placement header, no numeric change). Conflict 4 — stale boundary comments: `ashuganj_lines.m:12-15` header and `:52-55` ZGRID `Length_Note` plus `ashuganj_grid.m:5` still phrase the equivalent at the plant boundary; `Placement_Note`/`Bus_remote`/Q7a-history lines are current. Cleanup is a documentation pass with no physical effect. Conflict 5 — display warts found and fixed: validator `V_REMOTE_kV ≈ 528 kV` (100 kV block base) and bus-CSV `V_pu ≈ 2.297` on B230_REMOTE; both normalized in reporting only (CSV-facing columns), while `val.V_REMOTE_pu` intentionally remains solver-base by determinism-test contract. Conflict 6 — GIS bay panel-label conflict (REV3.1 reconciliation finding): the lines register carried BAY_GAT as `BAY 10BAY12` while REV3 C-17 + GIS SLD GAT(F13) 10BAY20 + builder `GAT BAY CB 10BAY20` convention establish BAY_GAT = 10BAY20; 10BAY12 is the bus-coupler/protection-panel designation. Corrected to `BAY 10BAY20` (transformer-bay class 2000 A: Q0 breaker, CB TRANSFORMER-BAY sheet 2000 A, module table GT 2000 A) with the conflict recorded in `Bay_label_note`. The outgoing line-bay number is MISSING (INEL-0026 unavailable; 10BAY11/12/20 are GSUT/coupler/GAT), so BAY_GRID Label carries an explicit MISSING note instead of the colliding 10BAY20; its Line-module 2000 A class is source-supported independently of the number.

Battery note (verbatim per requirement, Phase-2 model unmodified): 110 VDC is supported as a Siemens bay/control supply rating in the supplied as-built documentation. The specific station battery-bank parameters 55 cells, 200 Ah, 0.05 Ω, 20 kW charger and 123.75 V float are academic engineering assumptions; plant-specific battery/charger documentation has not been located.

## 24. Test Results

Gated Phase-3 tests written first per TDD: `test_phase3_line_model` 20/0 PASS (register 8/2, L_LINE buses/length/circuits/representation/conductor, R/X/C within 1e-9/1e-15, R0/X0/C0 MISSING, grid |Z|/R0/ESTIMATED trio); `test_phase3_determinism` 5/0 PASS (fresh double-build P/Q/Vremote/KCL/verdict identical). Full regression `run_all_tests('all')` fresh: 1388 passed / 0 failed (ALL 1388/0, exit 0), log `docs/validation/rev31_phase3/task-14b-reconciliation-tests.log` (86043 B): bus 66, generator 476, transformer 85, line 63, load 58, base 39, topology 59, capability 224, eng-assump 9, phase2-systems 24, phase2-components 51, profiles 55, phase-shift 19, grid-sens 41, magnetising 41, phase2-loadflow 53, phase3-line 20, phase3-determinism 5. Prior suite was 1368/0 at Phase-3 close; the +20 net lines are the REV3.1 reconciliation semantic assertions (line 53→63: 2000 A modules + GAT 10BAY20 + REMOTE spans + §2.4 provenance; topology 52→59: `Grid_equivalent_bus` + Phase-3 spans + 6-node graph; grid-sens 38→41: §2.4 strings + REMOTE bus). No tolerance, tap, R-value, or physics check was weakened; reconciliation corrections carry this pass (correction-only, no Phase 4). LF compatibility 6/6 OK (§16), conservation 6/6 PASS (§20), sensitivity 9/9 OK (§25 item 9/§26 summary). No failure was silenced.

## 25. Hash Audit

Method (Task 1 command reused verbatim for POST): hash `*.m,*.csv,*.md,*.mat,*.slx` excluding `PHASE3_POST_HASHES.txt`, `PHASE3_CHANGELOG.md`, `PHASE3_FINAL_REPORT.md`, skipping `\tmp\` and `\results\`, emitting `SHA256 + relative path` (Windows backslash form). PRE: `PHASE3_PRE_HASHES.txt`, 313 lines, 33023 bytes, 2026-09-18 09:54:23, zero absolute-drive lines. POST: `PHASE3_POST_HASHES.txt`, 335 lines, 35987 bytes, 2026-09-18 13:01:54 (REV3.1 reconciliation regen; count/bytes unchanged from 12:16:11 POST because the pass modifies hashed files in place without adding/removing any), 335/335 match `^[0-9A-F]{64}  \.`, zero `G:\`. Reconciliation diff (recon PRE 335 → POST 335): ADDED 0, MODIFIED 22, REMOVED 0, UNCHANGED 313 — the 22 authorized correction hunks in `PHASE3_CHANGELOG.md` §9. Protected-identical proof: `ashuganj_generators.m`, `ashuganj_transformers.m`, `ashuganj_loads.m`, `ashuganj_buses.m`, `ashuganj_operating_profiles.m`, `validate_operating_profile.m` (F12B6A6C… both), `run_load_flow_study.m`, `build_ashuganj_main.m`, `build_auxiliary_system.m`, `build_generator_system.m`, `build_gsut_system.m`, `sps_blocks.m`/`sps_geom.m`/`sps_wire.m`, `ashuganj_bus_map.m`, `ashuganj_bus_results.m` — all byte-identical. Builder deltas are comment-only (`build_external_grid.m` §2.4 rewording + prior `:100-114` NaN-fallback hunk; `build_230kv_system.m` bay-rating header). No Rev2, historical, or solver-physics change (frozen check FROZEN-OK). REMOVED = 0 is explained: the two deleted `.m` stubs were recreated (net MODIFIED), `results/` is hash-excluded, and the eight deleted `.txt` scratch files are outside the include pattern. Scope consequences (`results/` and `*.log` outside hash scope) are recorded in the changelog with the outside-scope created/deleted tables, so nothing is silent.

## 26. Change Log

Authoritative record: `PHASE3_CHANGELOG.md` (14116 B; hash + docs only, no code/data edits in the audit task). Modified (11, all authorized): `ashuganj_lines.m` (Tasks 2+4: baseline restore then locked L_LINE + ZGRID move + 8/2 asserts); `ashuganj_grid.m` (Task 4: header comments + display-only `Bus_remote`, no numerics); `validate_phase3_network.m` (Task 5 rewrite + Task 9 display fix); `run_phase3_load_flow.m` (Task 6 rewrite + Task 9 writer fix); `build_external_grid.m` (ruling progress.md:40 NaN fallback); `ashuganj_branch_flows.m` (Task 9 ruling reporting alignment); `test_line_data.m` (Task 7 gated + Task 13 ruling 8-branch completion); `run_all_tests.m` (Task 13 registration); `test_grid_sensitivity.m` + `test_magnetising_sensitivity.m` (ruling progress.md:74 measurement corrections); ledger `progress.md`. Added (20): `phase3_source_audit.csv` (11 rows), `phase2_vs_phase3.csv` (header + 40 rows), `phase3_line_loading_drop_loss.md`, `phase3_conservation.md`, `phase3_sensitivity.md`, `test_phase3_line_model.m`, `test_phase3_determinism.m`, 13 `.superpowers` task reports. Deleted (Task 2, outside hash scope, listed): two broken `.m` stubs (net MODIFIED via recreation), old `results/phase3_loadflow/`, eight `phase3_lf_test*.txt`. Created outside hash scope: `results/phase3_loadflow/` ×3 artifacts, `task-13-all-tests.log`, POST hashes, changelog, this report. No other files created, modified, or deleted in Tasks 3–14.

## 27. Limitations

(1) Length 0.7 km, Mallard conductor, and positive-sequence R/X/B are engineering assumptions, not measurements; results move arithmetically with them (bounded by §25-item-9 sensitivities, largest line-parameter movement −62.9 kW export on single-circuit-out). (2) Zero sequence is absent: no unbalanced, fault, or switching analysis may be run on this model. (3) Thermal loading percent cannot be reported; ≈ 870 A operating current (≈435 A/circuit) is stated without an ampacity verdict — 2000 A figures are GIS bay-module ratings (GSUT 10BAY11 / line-bay / GAT 10BAY20 transformer-bay per C-17), 3150 A is the bus-coupler/busbar module only. (4) Destination substation beyond the equivalent is unknown (`B230_REMOTE` is REMOTE_GRID_BUS_ASSUMED, the assumed model boundary for the external 230-kV network; actual destination substation not established, INEL drawing unavailable; no verified PGCB bus claimed); the grid is a single Thevenin proxy, not a multi-bus external network. (5) Grid Isc 50 kA is the ESTIMATED Siemens §2.4 source quantity (equipment 50 kA/1 s+3 s, 125 kA peak, 50 kA making are separate ratings); downstream Ssc/|Z|/X inherit the estimate. (6) Mutual coupling between circuits is assumed negligible, bounded only by the SCO case. (7) GAT_IN looped cases carry larger snubber KCL residuals (≈ 6e-04 vs ≈ 3e-05) in both eras; margin to the 0.05 gate remains ≈ 78× or better. (8) `val.V_REMOTE_pu` remains solver-base (≈ 2.297); only CSV-facing columns are normalized — direct readers of the field must use `V_REMOTE_kV`. (9) Stale plant-boundary phrasing in three comment lines (§23 conflict 4) awaits a documentation pass. (10) LF389P30 has no OLD-baseline archive row for 342/389 MW dispatches; its compatibility reading is NEW-only plus I² scaling consistency.

## 28. Phase-4 Readiness

Ready for handoff: locked positive-sequence network (L_LINE PI + remote-bus grid equivalent + new B230_REMOTE node) solves deterministically (5/0) on all six cases (6/6 OK) inside the full 1388/0 suite; every number carries source/derived/assumption/missing classification (§21 11-row vocabulary); fault-location topology points (0/25/50/75/100 % along L_LINE) are available as a topology property. Required Phase-4 inputs (not started): measured or PGCB-confirmed R0/X0/B0 (or a separately justified assumption with its own sensitivity — never `3×X1` as fact); confirmed destination substation and external-network depth behind the equivalent (multi-bus reduction vs retained Thevenin); confirmed line length and conductor/ampacity from INEL-112070-00-ELC-DE-0026 or PGCB survey (replacing the 0.7 km EA and the MISSING rating); confirmed fault level at the remote bus (replacing the 50 kA ESTIMATED Siemens §2.4 source quantity). Rgrid = 0 is an engineering modelling assumption for the balanced Phase-3 load-flow equivalent (infinite X/R); it must not be carried unchanged into fault/protection calculations where X/R and DC offset matter. Phase 3 establishes and validates the physical transmission/network representation. Symmetrical short-circuit analysis is reserved for Phase 4 and has not been implemented in this phase. In practical terms, Phase 3 delivers a practical engineering-model representation with documented assumptions where data were unavailable, not a fully verified plant dataset.

---

## Appendix A — §42 deliverables checklist (10/10)

- [x] 1. Source audit (`docs/validation/rev31_phase3/phase3_source_audit.csv`, 11 rows) — §5
- [x] 2. Topology (`B230_1 → L_LINE → B230_REMOTE → ZGRID → BGRID230`, 8 entries / 2 modelled) — §6
- [x] 3. Parameter table with locked R 0.0277725 / X 0.1425655 / B 3.937996 uS + pu (0.0000525 / 0.0002695 / 0.0020832) — §11
- [x] 4. Classification register (SOURCE / DERIVED / ASSUMPTION / HISTORICAL / LEGACY / MISSING) — §21
- [x] 5. Assumption justification (EA basis + Ghorasal-Mallard reference + INEL unavailability + SCO bound) — §§4, 8–10
- [x] 6. LF compatibility 6/6 OK with OLD-vs-NEW table — §16
- [x] 7. Sensitivity note 12/12 OK (9/9: SCO + R/X/B ±20 % + GRID45; plus 3 length points 0.5/0.7/1.0 km with 0.7 shared) — sensitivity evidence §26 ref + summary below
- [x] 8. Tests 1388/0 (log `docs/validation/rev31_phase3/task-14b-reconciliation-tests.log`) — §24
- [x] 9. Hash audit (recon PRE 335 / POST 335, MODIFIED 20 authorized, protected identical, change table) — §25
- [x] 10. This report (`PHASE3_FINAL_REPORT.md`, 28 sections) — all sections above

Sensitivity summary (evidence: `docs/validation/rev31_phase3/phase3_sensitivity.md`, anchor LF360_GAT_OUT export 345.2073 MW / −26.2675 MVAr, line 0.062928 MW / 0.115169 MVAr, V230_1 229.760 kV, V_REMOTE 229.731 kV): single-circuit-out export −62.9 kW with exact ≈2× resistive scaling (0.062928 → 0.125847 MW), Q −0.71 MVAr, OK; R ±20 % moves P loss ±12.6 kW with Q untouched, X ±20 % moves net line Q ±64.6 kVAr with export P fixed to ≤0.1 kW, B ±20 % moves net line Q ∓41.6 kVAr with export P fixed, all monotonic/symmetric, single-volt moves, OK; GRID45 (45.01 kA, X/R 10.99) export −0.605 MW (all grid resistive loss, hand check 3I²R exact), Q −4.96 MVAr, plant bus +311 V, line P/Q essentially unchanged (−69 W / −0.9 kVAr), OK. Length set (d) 0.5/0.7/1.0 km: line P 0.044950 → 0.062928 → 0.089892 and line Q 0.082276 → 0.115169 → 0.164491 (exact L/0.7 ratios), export P −17.9/−27.0 kW steps, dV 20.910 → 29.204 → 41.569 V, OK 3/3. Every run 2 iterations, balances ≤ 3e-6, KCL ≤ 6.8e-05 MVA, Verdict OK 12/12 (9/9 + 3 length points with 0.7 shared) with committed values byte-identical after (line-model gate 20/0 re-PASS).

## Appendix B — §46 completion-criteria boxes (46/46)

Connection and topology:
- [x] 1. South 230-kV outgoing connection identified (bay CONFIRMED, destination MISSING stated)
- [x] 2. Line data.pdf fully audited; Ghorasal/Comilla/Sirajganj candidates reconciled as excluded inventory
- [x] 3. 70 km retained only as documented 400-kV/North conflict, never as South source
- [x] 4. 44 km fenced as the separate Ghorasal line with reference-only role
- [x] 5. Selected connection documented (0.7 km D/C Mallard lumped PI, B230_1 → B230_REMOTE)
- [x] 6. Integrated topology built fresh per case (8 entries / 2 modelled, handle-based identity)

Parameters and derivations:
- [x] 7. Base declared (100 MVA / 230 kV, Zbase 529 ohm)
- [x] 8. Per-km r1/x1/y1 with ohm/km and uS/km conversions shown
- [x] 9. Single-circuit 0.7 km totals shown (0.055545 / 0.285131 ohm / 1.968998 uS)
- [x] 10. Parallel equivalent derived with /2 and ×2 steps (0.0277725 / 0.1425655 / 3.937996)
- [x] 11. Pu equivalents shown (0.0000525 / 0.0002695 / 0.0020832)
- [x] 12. Capacitance via C = B/(2·pi·50) (1.253503e-08 F) with units
- [x] 13. R0/X0/B0 status explicit (NaN / MISSING, no 3×X1 fact)
- [x] 14. Grid derivation fenced (50 kA ESTIMATED Siemens §2.4 source quantity → 19918.58 MVA → |Z| 2.65581124 DERIVED + XN≈2.66 separate, R = 0 EA-FOR-BALANCED-LF-ONLY)

Classification and register:
- [x] 15. Closed enum honored, no new struct status strings
- [x] 16. Length/conductor/R/X/B statuses ENGINEERING_ASSUMPTION with derivation notes
- [x] 17. Human-tier DERIVED_FROM_ENGINEERING_REFERENCE recorded alongside
- [x] 18. Benchmarks classified (342 qualified, 389.30 HISTORICAL)
- [x] 19. Missing items named with disabled/scoped consequences
- [x] 20. Battery parameters fenced as academic assumptions with verbatim note

Integration and solves:
- [x] 21. Broken artifacts deleted, 7-branch baseline restored (47/0 gate)
- [x] 22. Validator rewritten on bus_map schema with all runner-consumed fields
- [x] 23. Runner rewritten (fresh build → solve → validate → close → record)
- [x] 24. ZGRID at remote bus; L_LINE PI in solver path
- [x] 25. LF360 pair primary solved OK (2 iterations, balances < 1e-3)
- [x] 26. LF342 qualified solved OK
- [x] 27. LF389P30 historical-only solved OK
- [x] 28. OLD-vs-NEW comparison explained physically, nothing forced to OLD

Verification (loading / drop / loss / conservation):
- [x] 29. Line current computed with formula, units, numbers (≈ 870 A both LF360 cases)
- [x] 30. Thermal rating MISSING stated; loading NaN by rule with 2000 A bay-rating fence
- [x] 31. Voltage drop reported with sign and size (29.203 V / 0.012710 %; 26.879 V / 0.011701 %)
- [x] 32. Drop cross-checked against ΔV ≈ (RP+XQ)/V with signed-Q consistency proof
- [x] 33. Losses hand-checked (3I²R and 3I²X − V²B, <1 % all six cases, sign correct)
- [x] 34. Conservation gate 6/6 PASS (P ≤ 1.57e-05, Q ≤ 1.64e-06, KCL ≤ 6.39e-04)

Sensitivity:
- [x] 35. Single-circuit-out run, small monotonic movement, verdict OK
- [x] 36. R/X/B ±20 % runs, symmetric/monotonic, verdicts OK
- [x] 37. Grid 50 kA vs 45.01 kA sensitivity separate, hand-check exact, verdict OK (9/9 total)

Tests:
- [x] 38. Locked-model gate 20/0 PASS
- [x] 39. Fresh-build determinism 5/0 PASS
- [x] 40. Full regression 1388/0 fresh with diary log, no weakened checks

Freeze and documentation:
- [x] 41. PRE 313 / POST 333 hashes with relative paths; protected files byte-identical
- [x] 42. Change table complete (File | Before | After | Changed? | Authorized? | Reason)
- [x] 43. Outside-scope created/deleted artifacts listed, no silent changes
- [x] 44. Boundary sentence included verbatim (§49)
- [x] 45. Battery note included verbatim (§45), Phase-2 battery model unmodified
- [x] 46. Zero fault/relay/dynamic/battery/AVR/governor/SFC work; Phase-4 inputs listed

## Appendix C — Evidence bundle

`docs/validation/rev31_phase3/`: `phase3_source_audit.csv` (11 rows + header); `phase2_vs_phase3.csv` (header + 40 rows); `phase3_line_loading_drop_loss.md` (90 lines); `phase3_conservation.md` (78 lines); `phase3_sensitivity.md` (122 lines, stability wording per reconciliation); `task-13-all-tests.log` (1703 lines, ends ALL 1368/0 — superseded) + `task-14b-reconciliation-tests.log` (ends ALL 1388/0); `recon_pre_hashes.txt` (335 lines). Root: `PHASE3_PRE_HASHES.txt` (313 lines); `PHASE3_POST_HASHES.txt` (335 lines); `PHASE3_CHANGELOG.md` (§9 reconciliation); this report. Results: `results/phase3_loadflow/phase3_system_summary.csv`, `phase3_bus_results.csv` (54 rows), `phase3_loadflow_results.mat`. Ledger: `.superpowers/sdd/2026-09-18-phase3-locked-07km-line-model/progress.md` with all rulings plus `task-1-report.md` … `task-15-report.md`.
