# PROGRESS.md — Ashuganj South 450MW CCPP (EEE 306 G03)

> ## ⚠ SUPERSEDED FOR CURRENT WORK — see [`REV3_PROGRESS.md`](REV3_PROGRESS.md)
> This file is the **Rev1/Rev2 historical record** (Phases 1–4, complete 2026-09-10). It is retained
> deliberately and must not be deleted. **Two of its instructions below are void for Rev3:**
> - *"Do NOT reread PDFs"* — Rev3 exists **because** the primary PDFs were not fully read. Re-reading them
>   overturned the generator earthing, `X2`/`X0`, GSUT `Z`, the auxiliary load and the grid equivalent.
> - *"Source of truth: Sep-10 master"* — that file is a **tier-4 secondary compilation**. It silently applied
>   IEC 60909 `c = 1.0` while its own text specified the source-reported `|Z| = 3.25 Ω`, understating grid
>   impedance by 10.1 %. Tier-1 OEM documents govern.
>
> **Rev2's earth-fault results are wrong by ~4 orders of magnitude** (`F2 B01 LG = 111.17 kA` vs ≈7.25 A
> actual): the registry set `G.Earthing = 'Solidly grounded'` where the Siemens protection report specifies
> a high-resistance NER (`10BAB11`). Do not reuse the LG/LLG rows in §"Exact results Phase 2".
> Rev2's three-phase, load-flow and protection *architecture* remain sound and are being carried forward.

> PHASED EXECUTION. Fresh session: read THIS + `Ashuganj_South_Final_Master_Data_and_Assumptions (1).md` + files listed under Next-task only. Do NOT reread PDFs / old logs / `matlab/` Aug tree / `results/load_flow/`.
> Source of truth: Sep-10 master (1004 lines). Old `matlab/`, `simulink/*.slx`, `results/load_flow/*` are PROVISIONAL.

## Phase status
- [x] Phase 1: Re-baseline data + rebuild load flow — COMPLETE 2026-09-10 (see Exact results)
- [x] Phase 2: Fault-study engine + results + Simulink V2 cross-check — COMPLETE 2026-09-10 (see Phase 2 record)
- [x] Phase 3: Protection coordination — COMPLETE 2026-09-10 (see Phase 3 record)
- [x] Phase 4: Report + final verification + demo guide — COMPLETE 2026-09-10 (see Phase 4 record)

## Phase 4 completion record (2026-09-10, MATLAB R2024a)
- Files: `rev2/reports/Rev2_Final_Report.md` (scope, exact tables, assumptions, F1–F8, limitations, file index, verification record),
  `rev2/reports/DEMO_GUIDE.md` (repro commands, per-phase show list, viva answers).
- `run_full_project('All')` fresh rerun: Phase1 CONVERGED+PBAL OK (7/7, pbal ≤5.7e-14) ·
  Phase2 CSVs+SYMMETRY OK · Phase3 CSVs+GRADING+TMS-CAP OK. All CSV numbers deterministic (match report).
- Simulink suite last full run: 6/6 simmed cases grid-share +0.2…+5.5%, 2 solver-wall engine-only (`phase2_simulink_check.csv`).
- PROJECT COMPLETE. New work belongs in a new phase entry, not in Phases 1–4.

## Follow-on (2026-09-10, user-requested, same session)
- SLD presentation pass: `rev2/simulink/format_loadflow_v2.m` — title/caption annotations,
  zone colors, DC island (BAT_110V 110V/200Ah lead-acid + R_DCDB 4.03ohm + I_DC + Idc sink;
  discharge demo Idc=29.7A vs 27.3A calc; autonomy 7.4h>2h). LF re-verified post-format
  (tout full) + full Simulink suite re-ran IDENTICAL numbers (electrically inert).
- GUI: `rev2/gui/ashuganj_rev2_gui.m` — 9 tabs (Overview, Load Flow, Fault Analysis with
  single-case Simulink run + waveforms, Protection, Results CSV viewer, Documents viewer,
  Model open/rebuild/format, Tests tick-and-run, one-line fault Animation with Q0/Q9 trip).
  Headless construction check passes (9 tabs, callbacks wired). Launch: `ashuganj_rev2_gui`.
- Dashboard: `rev2/gui/build_dashboard.m` (+ template) → `rev2/plots/dashboard.html`
  (self-contained, no server): animated power-flow P1A..P1G, fault+trip timeline scrubber
  F1..F9, voltage-recovery envelope (labelled illustrative — no machine model in scope),
  DC discharge vs 2h autonomy. Verified: placeholders filled, all IDs present, JS balanced.
- Hi-res SLD: `rev2/plots/sld_V2_hires.png` (6463×7558).
- `run_full_project('All')` re-verified green after all additions (this session).
- DATA AUDIT 2026-09-11 (user-requested): re-read master .md + condensed PDF + old
  matlab/data + PSAF xlsx + V2 masks + recomputed 10/10 registry derivations exact.
  Fixes: Sbase/f statuses A/B→C (master §9C/§4C); +3 reconciliation rows (GSUT-Z0
  old-15.8% superseded/negligible, magnetizing omission <1MVAr, base/freq labels).
  V2 already plate-correct (UAT Rm 1785.7/Lm 339.3, GSUT Rm 3316.5/Lm 791.9) — no change.
  xlsx confirmed as superseded old source (389MW/166.3%/blanks). All tests re-pass.
- MANUAL: `rev2/reports/MANUAL.md` (run/show/explain + 12-row practicality validation vs
  PGCB tenders, OEM GCB classes, CCPP benchmarks, IEEE 485/946 + PART E protection-in-Simulink).
- Protection-in-Simulink (this session): BRK_Q9 (API insert) + BRK_Q0 (XML series insert
  at GSUT_L) + RELAY_Q9 true IEC-SI OC (1031A/0.281) + RELAY_Q0 27-UV demo + NOT gates
  (SPS external 0=open, verified) + TRIP sinks. Trip demo B02-LLL: Q0 0.137s, Q9 0.511s,
  Igrid 1.47kA→44kA→0A. Backup: Load_Flow_V2_protection_base_2026-09-11.slx.
- Simulink walls update: never save/close with fault taps (teardown crash — untap first);
  phasor-time dropped (Battery has no phasor model). Full setup re-ran:
  engine All green + Simulink suite identical + GUI headless green (this session).

## Phase 1 completed files (new files only; `matlab/` untouched)
- Backup: `simulink/backups/Ashuganj_South_Main_preRev2_2026-09-10.slx` (153165 B)
- `rev2/data/ashuganj_rev2_registry.m` (Rev2-2026-09-10-Phase1, 100MVA/50Hz)
- `rev2/data/reconciliation_register.csv` (27 rows: adopted value/status/supersession/consequence)
- `rev2/run_phase1_loadflow.m` (transparent polar NR, off-nominal a=0.9565, equations in header)
- `rev2/tests/test_rev2_registry.m` (9 assertions)
- `rev2/run_full_project.m` (entry: `run_full_project('Phase1'|'Phase2'|'All')`)
- `rev2/results/phase1_system_summary.csv`, `phase1_bus_results.csv`, `phase1_branch_results.csv`, `phase1_registry_snapshot.txt`
- `rev2/plots/phase1_bus_voltage.png`, `phase1_export.png`

## Exact results Phase 1 (from `rev2/results/phase1_system_summary.csv`, 100MVA base)
| Case | Pgen | GAT | V_B02 | V_B11 | Qgen | Pexport | Ploss | Sgs | GSUT%ONAN/ODAF | SUAT%ONAN | I_line |
|---|---|---|---|---|---|---|---|---|---|---|---|
| P1A base | 354 | OUT | 1.0004 | 0.9328 | 19.93 | 340.91 | 1.09 | 342.39 | 96.45/66.48 | 70.16 | 859A |
| P1B upper | 360 | OUT | 1.0003 | 0.9328 | 20.57 | 346.88 | 1.12 | 348.41 | 98.14/67.65 | 70.16 | 874A |
| P1C transfer ABNORMAL | 354 | IN | 1.0002 | 0.9431 | 17.31 | 340.89 | 1.11 | 336.05 | 94.66/65.25 | 97.98 | 860A |
| P1D weak 1.5×Zth | 354 | OUT | 1.0003 | 0.9328 | 19.98 | 340.62 | 1.38 | 342.38 | 96.45/66.48 | 70.16 | 859A |
| P1E strong 0.7×Zth | 354 | OUT | 1.0003 | 0.9328 | 20.01 | 341.09 | 0.91 | 342.38 | 96.45/66.48 | 70.16 | 859A |
| P1F line 0.8× | 354 | OUT | 1.0003 | 0.9328 | 19.99 | 340.93 | 1.07 | — | — | — | 859A |
| P1G line 1.2× | 354 | OUT | 1.0004 | 0.9328 | 19.86 | 340.90 | 1.10 | — | — | — | 859A |
- Balance closes: 354−12−1.09=340.91 ✓. All converged 5 it, mismatch <6e-14.
- FINDING F1: B11 0.9328pu (6.16kV) LOW in all radial cases — UAT 0.42pu @100MVA + a=0.9565 off-nominal. Report as limitation; do NOT hide. P1C transfer lifts to 0.9431pu but drives UAT to 97.98% ONAN (18.62MVA) with GAT 7.08MVA circulating — confirms parallel NOT normal.
- FINDING F2: GSUT 96.45% ONAN at 354MW (no forced cooling needed); 98.14% at 360MW. Old 105.87% was at 389MW — superseded.
- FINDING F3: 230kV GIS lightly loaded (~860A = 27% of 3150A). Grid sens moves export ±0.25MW, losses 0.91–1.38MW. Line 0.8–1.2× negligible (0.7km short).
- Qgen ~20MVAr (PV solution), NOT initial 72MVAr C-guess — 72 was starting assumption only.

## Assumptions (C) — all labelled in CSV Note column + snapshot
C: Vgen 1.00, Vgrid 1.00∠0, aux 12+j5, line R/X/B+Z0, R2=R1/R0=1.5R1, Qlim±200, taps nominal, Zth B/C (Rth0.268/Xth2.94, |Z| 2.95 vs 3.25 contradiction adopted as Rth/Xth), GAT-parallel abnormal only, DC/AVR for Phase 4 only. GIS 50kA = withstand ONLY, never grid level. No C presented as plant fact.

## Tests run (fresh evidence this session, MATLAB R2024a)
- `test_rev2_registry`: 9/9 PASS
- `run_full_project('Phase1')`: 7/7 converged, mismatch max 5.7e-14, `Phase1 acceptance: CONVERGED + PBAL OK`
- Command: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "cd('G:/.../rev2'); run_full_project('Phase1')"`
- Superpowers used: writing-plans + test-driven-development + verification-before-completion + systematic-debugging (nested-function + power-balance-invariant fixes, 2 fixes, root-caused).

## Limitations (must carry to report)
- B11 undervoltage 0.93pu needs tap/cap study — not fixed in Phase 1.
- Regional B04/B05 + 400kV not in Phase 1 Ybus (external-grid representation deferred to Phase 2 optional).
- Zero-seq (YNd1 blocking) not exercised in balanced LF — Phase 2 must enforce: no gen Z0 through GSUT delta to 230kV.
- Old LF1-LF4 numbers (389MW, R=0) NOT reused; reproduced-from-Rev2 only above.

## EXACT NEXT TASK — Phase 4 (reads ONLY this + master md + `rev2/results/*.csv`)
1. Write `rev2/reports/Rev2_Final_Report.md`: scope, data truth (Sep-10 master), exact Phase 1/2/3 tables (copy CSV numbers), assumptions register (all C), findings F1–F7, limitations, file index. No new numbers — only CSV values.
2. Write `rev2/reports/DEMO_GUIDE.md`: one-command repro (`run_full_project('All')` + simulink runner), what to show per phase, expected outputs, time budget (~25min with Simulink, ~2min without).
3. Run `run_full_project('All')` fresh, record acceptance lines here.
4. Mark Phase 4 complete, stop. No new engineering in Phase 4.

## Phase 3 completion record (2026-09-10, MATLAB R2024a)
- Files: `rev2/data/iec_si.m`, `rev2/run_phase3_protection.m`, `rev2/tests/test_phase3_protection.m`,
  `rev2/results/phase3_settings.csv`, `phase3_coordination.csv`, `rev2/plots/phase3_tcc.png`, Phase3 hook in `run_full_project.m`.
- Method: pickup 1.2×FL (C), CT next-tap ≥1.25×FL (C), IEC-SI, downstream TMS fixed (0.2 OC / 0.15 EF),
  upstream TMS solved for 0.3s margin (C); GSUT-HV sees B01 faults as grid infeed (series-exact)
  and B02/B03 as gen share ×22/230 (series-exact); B11 fault 19.8kA via B01-Thevenin+UAT (C-approx).
### Exact settings Phase 3 (from CSVs)
| Relay | CT | FL | Pickup | TMS | t@maxF | t@minF | Sens |
|---|---|---|---|---|---|---|---|
| GSUT-HV 51 | 1600/1 | 859A | 1031A | 0.200 | 0.741s@6.59kA | 1.818s@2.21kA | 2.15 PASS(thin) |
| LINE-Q9 51 | 1600/1 | 859A | 1031A | 0.281 | 0.502s@44.98kA | 1.424s@4.03kA | 3.91 PASS |
| UAT-HV 51 | 800/1 | 341A | 409A | 0.318 | 0.809s@5.94kA | 0.809s | 14.5 PASS |
| UAT-LV 51 | 1600/1 | 1137A | 1365A | 0.200 | 0.509s@19.82kA | 0.509s | 14.5 PASS |
| GSUT-NEF 51N | 1600/1 | — | 320A (0.2Asec) | 0.150 | 0.200s@46.79kA | — | PASS |
| LINE-EF 51N | 1600/1 | — | 320A (0.2Asec) | 0.375 | 0.500s@46.79kA | — | PASS |
| GSUT diff | HV1600/LV12000(C-req) | — | start 0.30pu S1 30% S2 60% | — | — | — | 39% mismatch compensated (note) |
| GEN diff | OEM CTs (data req.) | — | start 0.20pu | — | — | — | C |
| Pair | Icheck | t_prim | t_back | margin |
|---|---|---|---|---|
| UAT-LV → UAT-HV @19.82kA | 0.509 | 0.809 | 0.300 PASS |
| GSUT-HV → LINE-Q9 @6.59kA | 0.741 | 1.041 | 0.300 PASS |
| 87B(0.1s C) → LINE-Q9 @44.98kA | 0.100 | 0.502 | 0.402 PASS |
| 87B(0.1s C) → GSUT-HV @3.17kA | 0.100 | 1.233 | 1.133 PASS |
| GSUT-NEF → LINE-EF @46.79kA | 0.200 | 0.500 | 0.300 PASS |
- Tests: test_phase3_protection ALL PASS; run_full_project('Phase3') acceptance OK.
- FINDING F6: GSUT-HV sensitivity 2.15× (thin for far gen-share faults) — 87B primary covers; note.
- FINDING F7: UAT-HV/LINE-EF TMS (0.318/0.375) are solved results, not the 0.2/0.15 starts.

## Phase 2 completion record (2026-09-10, MATLAB R2024a)

### New files (old `matlab/`, `simulink/*.slx` untouched except V2 clone)
- `rev2/data/seq_networks.m` (3-node classical Thevenin Y012; YNd1 Z0 block; prefault P1A + computed B03)
- `rev2/data/iec_kappa.m` (IEC 60909 κ)
- `rev2/run_phase2_fault.m` (LLL/LG/LL/LLG engine, contributions, κ peaks, duty)
- `rev2/tests/test_phase2_fault.m` (symmetries: LG I1=I2=I0, LL I0=0/Ib=-Ic, LLL balanced, LLG Vb=Vc=0)
- `rev2/tests/test_phase2_kcl.m` (KCL closure F1/F5/F9: 0.133/0.036/0.039pu — caught Vpre3 + unit bugs)
- `rev2/results/phase2_fault_currents.csv` (9 base + 36 sens), `phase2_sequence_Z.csv`, `phase2_breaker_duty.csv`
- `rev2/plots/phase2_fault_currents.png`, `phase2_breaker_duty.png`, `phase2_sens.png`
- `simulink/studies/Load_Flow_V2.slx` (CLONE of Load_Flow.slx: Rev2 corrections + lumped ZGRID + VI_GRID + 6 VM taps + 2 fault blocks; original untouched)
- `rev2/simulink/build_loadflow_v2.m`, `run_loadflow_v2_tests.m`, `xml_fault_tap.ps1`, `recompute_verdicts.m`
- `rev2/results/phase2_simulink_check.csv` (6 sim-validated, 2 solver-wall engine-only)
- `run_full_project.m` Phase2 hook (tests + engine + plots + acceptance)

### Exact results Phase 2 (base: Xd''sat, grid×1.0, line×1.0, kA true)
| Case | Type | Isym | Ipeak(κ) | XR | MVA | Igen | Igrid | Sim Igrid (err) |
|---|---|---|---|---|---|---|---|---|
| F1 B01 | LLL | 122.36 | 338.6 | 66.7 | 4663 | 54.82 | 6.59 | STALLED-engine-only |
| F2 B01 | LG | 111.17 | 307.7 | 66.7 | 4236 | 70.67 | 4.03 | 4.25 (+5.5%) |
| F3 B01 | LL | 106.03 | 293.4 | 66.7 | 4040 | 52.08 | 6.14 | STALLED-engine-only |
| F4 B01 | LLG | 117.76 | 325.9 | 66.7 | 4487 | 64.99 | 6.09 | 6.19 (+1.6%) |
| F5 B02 | LLL | 46.25 | 115.6 | 11.0 | 18424 | 33.15 | 43.16 | 43.24 (+0.2%) PASS |
| F6 B02 | LG | 46.52 | 116.2 | 11.0 | 18532 | 23.15 | 41.88 | 43.16 (+3.0%) PASS |
| F7 B02 | LL | 40.05 | 100.1 | 11.0 | 15957 | 33.27 | 37.81 | 38.12 (+0.8%, Vdip −0.104 REVIEW) |
| F8 B02 | LLG | 46.39 | 115.9 | 11.0 | 18482 | 32.34 | 42.61 | 43.24 (+1.5%, peak −19% REVIEW) |
| F9 B03 | LLL | 48.06 | 120.8 | 11.7 | 19145 | 33.05 | 44.98 | engine-only (lumped node) |
- Breaker duty vs 50kA withstand (B) / 50kA interrupting ASSUMED (C), 60ms (C): Q0 6.59 PASS(+43.4), Q1/Q2 48.06 PASS(+1.94 THIN), Q9 43.17 PASS(+6.83).
- Sens: Xd''sat/unsat × grid 0.7/1.0/1.5 × line 0.8/1.0/1.2 (36 rows) + gridZ0 1–3× (LG@B02).
- Reality match: B02/B03 46–48kA vs PGCB-2019 45.01kA (grid-dominated + gen infeed ✓); peaks 115–121kA approach 125kA-class peak capability — report note.
- FINDING F4: B01 106–122kA @22kV (gen 52–71kA share) exceeds typical 63kA gen-breaker class — Phase-3 protection note + report limitation.
- FINDING F5: Q1/Q2 margin only 3.9% — confirm real interrupting nameplate before claiming adequacy.
- Bugs caught/fixed this phase: Vpre3 floating-junction error (83pu KCL violation), ×1000 kA-unit mislabel, contribution superposition (E−V)/Z, GSUT Z0 series phantom.
- Simulink walls (documented, R2024a): code cannot branch occupied SPS ports (use XML branch-tap tool); connected-OFF fault + B01-LLL/LL stall solver (engine covers); time-sim has no PV dispatch (flat-start; engine uses P1A Vpre); ZGRID lumped (0.7km + Thevenin, = engine series) so B03≡B02 node in Simulink.
- Tests: test_rev2_registry 9/9, test_phase2_fault ALL, test_phase2_kcl 3/3, run_full_project('Phase2') acceptance CONVERGED/CSVs/SYMMETRY OK.

## EXACT NEXT TASK — Phase 2 (fresh session reads ONLY this + master md + `rev2/data/*` + `rev2/results/phase1_*.csv`)
Build `rev2/run_phase2_fault.m` + `rev2/data/seq_networks.m`:
1. Prefault V from P1A (B01 1.0∠?, B02 1.0004).
2. Zbus 012: gen Xd''sat 0.2248 primary / 0.2608 sens, X2 0.2242, X0 0.128 + R1/R2/R0; GSUT Z1/Z2 same leakage, Z0 per YNd1 (HV grounded / LV delta blocks, model explicitly); UAT Dyn11 / GAT YNyn0 phase+Z0 paths; line Z0 from master C + grid Z0 (assume Z0=Z1 unless master gives, sens 1–3×, label C).
3. Faults LLL/LG/LL/LLG at B01 + B02, LLL at B03; per case output prefault V, Zth012, Iseq, Iphase, Vduring, gen vs grid contribution, Isym/FaultMVA/XR, Ipeak (state IEC60909 κ method), breaker duty vs 50kA/1s withstand + Q0/Q1/Q2/Q9 interrupting (state assumed clearing time), pass/fail withstand-vs-interrupting distinguished.
4. Sens: Xd'' both values × grid 0.7/1.0/1.5 × line 0.8/1.0/1.2.
5. Write `rev2/results/phase2_fault_currents.csv`, `phase2_sequence_Z.csv`, `phase2_breaker_duty.csv` + plots; verify I1=I2=I0 for LG, I0=0 for LL, V symmetries; update THIS file with exact kA table before Phase 3.
