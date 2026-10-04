# v4 Manual — what changed

Isolated copy: `Simulation_Workspace\`. Main folder untouched.
Ported from Union Alpha (additive, frozen files intact):
- `PHASE4_REVIEW_GATE_PORTED_UNION_ALPHA_2026-09-24.md` (31 CSVs, 2026-09-24)
- `PHASE4_CORRECTION_PORTED_UNION_ALPHA.md` (K1–K5: aux base, taps, ZN x3, loop x4, H2)

## Fault results used (frozen Phase-4 backbone)
- F1 LLL 126.21 kA, F1 LG 7.27 A (NER), F3 LLL 50.53 kA, F3 LG 45.74 kA
- `results/phase5_protection_v2/phase5c_fault_enriched.csv`: Fault MVA = √3·V·I, first-ring legs (GEN 55.05, GSUT_HV 72.11 kA at F1), bus voltages (faulted phase → 0, prefault 22 kV / 229.76 kV)
- `phase5c_sliding_F4.csv`: F4 LLL at m = 5 / 50 / 95% (current falls with distance)
- Breaker check: 52G 100 kA doc, Q0 50 kA conditional, 6.6 kV 31.5 kA. Static loads (≤12 kA) << faults (≥45 kA): no effect.

## Protection (each from fault currents: MaxLoad < Pickup < MinFault)
- 87G (`matlab/phase5/phase5c_diff_87g.m`): In 12019.2 A, CT 15000/1, pickup 0.20pu = 2403.8 A, k1 20% to 1.0pu, k2 50%, HS 5pu = 60096 A ≤20 ms. A normal NO TRIP, B F1-ext STABLE, C 5 kA internal TRIP.
- 87T (`matlab/phase5/phase5c_diff_87t.m`): 515 MVA 22/230 kV YNd1 primary (spec 450 MVA 22/400 kV also computed). LV 11809.1 A / HV 649.5 A, CT 15000/1 + 1600/1, M 1.2702 / 2.4633, zero-seq filter on HV wye. Pickup 0.30pu = 3542.7 A, k1 25% to 1.5pu, k2 50%, HS 8pu. 2nd-harm ≥15% and 5th ≥30% BLOCK.
- Plots: `results/phase5_protection_v2/plots/diff_87g_characteristic.png`, `diff_87t_characteristic.png`

TMS example (GEN-51, IEC SI, pickup 17170.8 A, TMS 0.10):
t = 0.10 × 0.14 / ((I/17170.8)^0.02 − 1). At I = 2× pickup: t = 0.014 / 0.0140 ≈ 1.0 s.
- Q0 (`matlab/phase5/phase5d_q0_breaker_duty.m`): 63 kA, making 160.65 kA, plant 3.03 kA. 10 GVA→17.46 kA (27.7%), 20 GVA→31.90 (50.6%), 30 GVA→46.33 (73.5%), PGCB 50 kA→53.03 (84.2%, margin 15.8%), boundary 59.97 kA→63.0 (100%). Plot + `q0_breaker_duty_matrix.csv`. South GIS is 230 kV; 400 kV is the PGCB envelope.

## Hardware (missing data selected, IEC, never 0)
- `Phase6/data/assumptions/HARDWARE_SELECTION_v4.md`: GEN CT 15000/1 5P20 30 VA, GSUT HV 1600/1 (+1500/1 sensitivity, saturation flagged above 20×), 6.6 kV feeder 2000/1 5P20 15 VA, 52G 24 kV/130 kA, Q0 230 kV 50 kA cond. (+63 kA option), 6.6 kV VC 31.5 kA, 7UM62/7UT6331/7SS523/7SD5221 roles, NER 1750.77 Ω derived.

## Simulink closed-loop
- `Phase6/PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx` (copy of dynamic model + relay-hook placeholder)
- `matlab/phase6/build_dynamic_protection_sim.m`, `run_dynamic_trip_simulation.m`
- Fault at 0.50 s. 6.6 kV feeder (1729 A pickup, TMS 0.10): trip 0.317 s. 22 kV backup (17170.8 A, TMS 0.20): 1.188 s. Instant 40 ms. Current truncates in 2 cycles, V → ≥0.95 pu.
- `results/phase6/dynamic_relay_trip_validation.png` (4 traces) + `dynamic_trip_times.csv`

## Run
```
matlab -batch "addpath(genpath('matlab')); test_phase5c_differential"
matlab -batch "addpath(genpath('matlab')); test_phase5c_enrichment"
matlab -batch "addpath(genpath('matlab')); test_phase5d_q0_duty"
matlab -batch "addpath(genpath('matlab')); test_phase6_dynamic_trip"
```

## Audit
- New tests: 27 + 11 + 14 + 24 = 76 pass, 0 fail.
- Frozen Phases 0–4 unchanged (additive files only).
- No open NOT_DETERMINABLE in study model; installed-document items stay verification-only (see register).
