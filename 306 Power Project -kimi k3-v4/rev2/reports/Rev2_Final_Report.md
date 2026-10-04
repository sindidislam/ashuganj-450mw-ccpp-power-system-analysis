# Ashuganj South 450MW CCPP (South) — Rev2 Final Report (EEE 306 G03)

Date: 2026-09-10. MATLAB R2024a. Source of truth: `Ashuganj_South_Final_Master_Data_and_Assumptions (1).md` (Sep-10, 1004 lines).
Base: 100 MVA, 50 Hz. All numbers below are copied verbatim from `rev2/results/*.csv` (no hand computation).
Status letters: A project/official, B strong secondary, C engineering assumption, D derived.
**No C-value is presented as a measured plant fact.**

## 1. Phase 1 — Load flow re-baseline (P1A base: 354MW gross, 12+j5 aux, radial)

| Case | Pgen | GAT | V_B02 | V_B11 | Qgen | Pexport | Ploss | Sgs | GSUT%ONAN/ODAF | UAT%ONAN | I_line |
|---|---|---|---|---|---|---|---|---|---|---|---|
| P1A base | 354 | OUT | 1.0004 | 0.9328 | 19.93 | 340.91 | 1.09 | 342.39 | 96.45/66.48 | 70.16 | 859A |
| P1B upper | 360 | OUT | 1.0003 | 0.9328 | 20.57 | 346.88 | 1.12 | 348.41 | 98.14/67.65 | 70.16 | 874A |
| P1C transfer ABNORMAL | 354 | IN | 1.0002 | 0.9431 | 17.31 | 340.89 | 1.11 | 336.05 | 94.66/65.25 | 97.98 | 860A |
| P1D weak 1.5×Zth | 354 | OUT | 1.0003 | 0.9328 | 19.98 | 340.62 | 1.38 | 342.38 | 96.45/66.48 | 70.16 | 859A |
| P1E strong 0.7×Zth | 354 | OUT | 1.0003 | 0.9328 | 20.01 | 341.09 | 0.91 | 342.38 | 96.45/66.48 | 70.16 | 859A |
| P1F line 0.8× | 354 | OUT | 1.0003 | 0.9328 | 19.99 | 340.93 | 1.07 | — | — | — | 859A |
| P1G line 1.2× | 354 | OUT | 1.0004 | 0.9328 | 19.86 | 340.90 | 1.10 | — | — | — | 859A |

Balance closes: 354−12−1.09=340.91 ✓. All converged 5 iterations, mismatch <6e-14.
Qgen ~20MVAr is the PV solution (the 72MVAr C-guess was a starting assumption only).

## 2. Phase 2 — Fault study (classical Zbus, Xd''sat 0.2248 primary, kA true)

| Case | Type | Isym kA | Ipeak kA (IEC60909 κ) | X/R | MVA | Igen kA@22kV | Igrid kA@230kV | Simulink Igrid |
|---|---|---|---|---|---|---|---|---|
| F1 B01 | LLL | 122.36 | 338.6 | 66.7 | 4663 | 54.82 | 6.59 | STALLED-engine-only |
| F2 B01 | LG | 111.17 | 307.7 | 66.7 | 4236 | 70.67 | 4.03 | 4.25 (+5.5%) |
| F3 B01 | LL | 106.03 | 293.4 | 66.7 | 4040 | 52.08 | 6.14 | STALLED-engine-only |
| F4 B01 | LLG | 117.76 | 325.9 | 66.7 | 4487 | 64.99 | 6.09 | 6.19 (+1.6%) |
| F5 B02 | LLL | 46.25 | 115.6 | 11.0 | 18424 | 33.15 | 43.16 | 43.24 (+0.2%) PASS |
| F6 B02 | LG | 46.52 | 116.2 | 11.0 | 18532 | 23.15 | 41.88 | 43.16 (+3.0%) PASS |
| F7 B02 | LL | 40.05 | 100.1 | 11.0 | 15957 | 33.27 | 37.81 | 38.12 (+0.8%; Vdip −0.104 REVIEW) |
| F8 B02 | LLG | 46.39 | 115.9 | 11.0 | 18482 | 32.34 | 42.61 | 43.24 (+1.5%; peak −19% REVIEW) |
| F9 B03 | LLL | 48.06 | 120.8 | 11.7 | 19145 | 33.05 | 44.98 | engine-only (lumped node) |

- Breaker duty vs 50kA withstand (B) / 50kA interrupting ASSUMED (C), 60ms (C):
  Q0 6.59 PASS(+43.4), Q1/Q2 48.06 PASS(+1.94 THIN), Q9 43.17 PASS(+6.83).
- Sensitivity (36 rows: Xd''sat/unsat × grid 0.7/1.0/1.5 × line 0.8/1.0/1.2): **12/36 rows exceed 50kA**;
  max S-LLL-B02-sat-g0.7-l0.8 = 64.40kA / 160.4kA peak (see F8).
- LL healthy-phase voltage ≈0.50pu (F3 0.4997, F7 0.5002 ✓ classical); LLG phases differ 0.3%
  (F4: 117.42 vs 117.76kA — real R/X-spread effect, not an error).
- B02/B03 46–48kA vs PGCB-2019 45.01kA: consistent (grid-dominated + gen infeed).
- KCL closure residuals: F1 0.133 (=aux), F5 0.036, F9 0.039pu.
- Symmetries verified: LG I1=I2=I0, LL I0=0/Ib=−Ic, LLL balanced, LLG Vb=Vc=0.

## 3. Phase 3 — Protection coordination (all starting values C per master §21)

| Relay | CT | FL | Pickup | TMS | t@maxF | t@minF | Sens |
|---|---|---|---|---|---|---|---|
| GSUT-HV 51 | 1600/1 | 859A | 1031A | 0.200 | 0.741s@6.59kA | 1.818s@2.21kA | 2.15 PASS(thin) |
| LINE-Q9 51 | 1600/1 | 859A | 1031A | 0.281 | 0.502s@44.98kA | 1.424s@4.03kA | 3.91 PASS |
| UAT-HV 51 | 800/1 | 341A | 409A | 0.318 | 0.809s@5.94kA | 0.809s | 14.5 PASS |
| UAT-LV 51 | 1600/1 | 1137A | 1365A | 0.200 | 0.509s@19.82kA | 0.509s | 14.5 PASS |
| GSUT-NEF 51N | 1600/1 | — | 320A (0.2Asec) | 0.150 | 0.200s@46.79kA | — | PASS |
| LINE-EF 51N | 1600/1 | — | 320A (0.2Asec) | 0.375 | 0.500s@46.79kA | — | PASS |
| GSUT diff | HV1600/LV12000(C-req) | — | start 0.30pu S1 30% S2 60% | — | — | — | 39% mismatch compensated |
| GEN diff | OEM CTs (data req.) | — | start 0.20pu | — | — | — | C |

| Pair | Icheck | t_prim | t_back | margin |
|---|---|---|---|---|
| UAT-LV → UAT-HV @19.82kA | 0.509 | 0.809 | 0.300 PASS |
| GSUT-HV → LINE-Q9 @6.59kA | 0.741 | 1.041 | 0.300 PASS |
| 87B(0.1s C) → LINE-Q9 @44.98kA | 0.100 | 0.502 | 0.402 PASS |
| 87B(0.1s C) → GSUT-HV @3.17kA | 0.100 | 1.233 | 1.133 PASS |
| GSUT-NEF → LINE-EF @46.79kA | 0.200 | 0.500 | 0.300 PASS |

B11 LV fault estimate 19.8kA (B01-Thevenin + UAT, C-approx, aux shunt ignored).

## 4. Simulink cross-check (`simulink/studies/Load_Flow_V2.slx`, clone of Load_Flow.slx)

Rev2 corrections + lumped ZGRID + VI_GRID + 6 VM taps + 2 fault blocks (XML branch taps;
originals untouched). SLD presentation: title/caption annotations, zone colors, DC island
(BAT_110V 110V/200Ah lead-acid + R_DCDB 4.03ohm + Idc; discharge 29.7A demo, autonomy calc).

Rev2 corrections + lumped ZGRID + VI_GRID + 6 VM taps + 2 fault blocks (XML branch taps;
originals untouched). Grid-share RMS agrees +0.2%…+5.5% (6/6 simmed cases); Vdips exact
except B02-LL healthy phase (−0.104 REVIEW, prefault-angle sensitivity); peaks match where
inception aligns, else below IEC envelope as expected (REVIEW = correct disposition).
B01-LLL/LL stall the R2024a solver (undamped X/R-67 loop) → engine-only, documented.
Time-domain sim has no PV dispatch (flat-start); engine uses P1A prefault — accepted basis.

## 5. Assumptions register (C — never plant facts)

Vgen/Vgrid 1.0∠0; aux 12+j5; line R/X/B + Z0; gen R2=R1, R0=1.5R1; Q limits ±200;
taps nominal; Zth adopted as Rth0.268/Xth2.94 (|Z| 2.95 vs 3.25 contradiction logged);
GAT-parallel abnormal only; gen X own-MVA-base interpretation; GSUT Z0=Z1; grid Z0=Z1
(sens 1–3×); shunt B neglected for SC; Ron/Rg 1e-4; clearing 60ms; interrupt 50kA class;
OC/EF/diff starts + TMS starts + 0.3s grade + 87B 0.1s + CT rule + B11 estimate + Lm.
GIS 50kA = withstand ONLY, never grid level.

## 6. Findings

- F1: B11 0.9328pu (6.16kV) LOW in all radial cases — tap/cap study needed; P1C transfer lifts
  to 0.9431pu but drives UAT to 97.98% ONAN with GAT circulating — parallel NOT normal.
- F2: GSUT 96.45% ONAN at 354MW (no forced cooling); 98.14% at 360MW.
- F3: 230kV GIS lightly loaded (~860A = 27% of 3150A); grid sens ±0.25MW export.
- F4: B01 fault 106–122kA @22kV (gen share 52–71kA) exceeds typical 63kA gen-breaker class.
- F5: Q1/Q2 duty margin only 3.9% — confirm real interrupting nameplate.
- F6: GSUT-HV OC sensitivity 2.15× (thin) — 87B primary covers.
- F7: solved TMS (UAT-HV 0.318, LINE 0.281, LINE-EF 0.375) are coordination results.
- **F8 (critical): strong-grid sens (0.7×Zth) reaches 64.40kA/160.4kA peak — EXCEEDS the 50kA
  GIS rating. Any future grid strengthening at Ashuganj invalidates the duty verdict:
  re-study before new incomers/uprates.**

## 7. Limitations (carry into viva/report defence)

B11 undervoltage unresolved; B04/B05/400kV not in fault Ybus; YNd1 Z0 per leakage (C);
aux lumped single-node; no dynamic/AVR study (Phase-4 scope not taken); protection uses
starting settings only (no commissioned relay files); gen-breaker rating unknown;
time-domain LF has no dispatch (powergui-LF/Phase-4 business); B03≡B02 node in Simulink.

## 8. File index

- `rev2/data/`: ashuganj_rev2_registry.m, reconciliation_register.csv, seq_networks.m, iec_kappa.m, iec_si.m
- `rev2/`: run_phase1_loadflow.m, run_phase2_fault.m, run_phase3_protection.m, run_full_project.m
- `rev2/tests/`: test_rev2_registry.m, test_phase2_fault.m, test_phase2_kcl.m, test_phase3_protection.m
- `rev2/results/`: phase1_*.csv/txt (4), phase2_*.csv (4), phase3_*.csv (2)
- `rev2/plots/`: phase1 ×2, phase2 ×3, phase3 ×1 PNG
- `rev2/reports/`: this file + DEMO_GUIDE.md
- `rev2/simulink/`: build_loadflow_v2.m, run_loadflow_v2_tests.m, xml_fault_tap.ps1, recompute_verdicts.m,
  format_loadflow_v2.m (SLD captions + DC island)
- `rev2/gui/`: ashuganj_rev2_gui.m (9 tabs), test_gui_headless.m, build_dashboard.m,
  dashboard_template.html
- `rev2/plots/`: dashboard.html (animated: powerflow/fault+trip/recovery/battery),
  sld_V2_hires.png (6463×7558 model export)
- `simulink/studies/Load_Flow_V2.slx` (Rev2 SLD: title/captions, DC island BAT_110V 200Ah + R_DCDB + Idc,
  VI_GRID, 6 VM taps, F_B01/F_B02 untapped in file; + untouched originals + backups)

## 9. Verification record (MATLAB R2024a, 2026-09-10)

test_rev2_registry 9/9 · test_phase2_fault ALL · test_phase2_kcl 3/3 · test_phase3_protection ALL ·
run_full_project('Phase1') CONVERGED+PBAL OK · ('Phase2') CSVs+SYMMETRY OK · ('Phase3') CSVs+GRADING+TMS-CAP OK.
Bugs caught by tests this project: Vpre3 floating-junction (83pu), ×1000 kA mislabel,
superposition contributions, GSUT Z0 phantom, KCL sign, iec_si expectation, sens-scale prefault.
