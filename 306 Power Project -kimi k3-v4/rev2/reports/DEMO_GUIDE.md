# Demo Guide — Ashuganj South Rev2 (EEE 306 G03)

Teacher/viva walkthrough. Total: ~2 min without Simulink, ~25 min with it.
Run from the `rev2/` folder (`cd rev2`) in MATLAB R2024a.

## 1. One-command reproduction (~2 min)

```matlab
addpath('data'); addpath('tests');
run_full_project('All')
```

Expected tail output (acceptance):
- `Phase1 acceptance: CONVERGED + PBAL OK`
- `Phase2 acceptance: CSVs + SYMMETRY OK`
- `Phase3 acceptance: CSVs + GRADING + TMS-CAP OK`

Per-phase: `run_full_project('Phase1'|'Phase2'|'Phase3')`.

## 2. What to show per phase

- Phase 1: `results/phase1_system_summary.csv` — P1A row (V_B02 1.0004, V_B11 0.9328 LOW,
  export 340.91 = 354−12−1.09 ✓); `plots/phase1_bus_voltage.png`.
- Phase 2: `results/phase2_fault_currents.csv` — F5 B02-LLL 46.25kA vs PGCB-2019 45.01kA;
  `phase2_breaker_duty.csv` — all PASS, Q1/Q2 margin 1.94kA (thin);
  `plots/phase2_fault_currents.png`, `phase2_sens.png` (12/36 sens rows >50kA — F8).
- Phase 3: `results/phase3_coordination.csv` — 5/5 margins ≥0.300s; `plots/phase3_tcc.png`.
- Report: `reports/Rev2_Final_Report.md` (findings F1–F8, limitations §7).

## 3. GUI (recommended for viva demo)

```matlab
cd rev2; addpath data tests simulink gui
ashuganj_rev2_gui
```

Tabs: Overview | Load Flow (case table + plots) | Fault Analysis (engine rows +
single-case Simulink run with waveforms) | Protection (settings + TCC) |
Results (any CSV) | Documents (report/progress/master viewer) |
Model (open V2/original, rebuild/format) | Tests (tick + RUN SELECTED) |
Animation (one-line fault flash + Q0/Q9 trip at 0.11s).

Open `plots/dashboard.html` in any browser (no server needed): animated power-flow
(P1A..P1G, dash speed ~ MW), fault+trip timeline scrubber (0–250ms play),
voltage-recovery envelope (labelled illustrative — no machine model in scope),
DC discharge vs 2h autonomy animation. Hi-res SLD: `plots/sld_V2_hires.png`.

## 4. Simulink cross-check (~20 min, optional for viva)

```matlab
cd rev2/simulink
run_loadflow_v2_tests('Write',true)   % builds on studies/Load_Flow_V2.slx
```

What it does: LF sanity → 8 fault cases (XML branch taps, fault at 0.05s) vs engine.
Expected: grid-share RMS +0.2…+5.5% (6/6); B01-LLL/LL STALLED-engine-only (solver wall);
B03 engine-only (lumped node). Never leave fault taps in the file (runner untaps).
Do NOT rewire by hand: R2024a code cannot branch occupied SPS ports (see report §4);
unconnected fault blocks are benign, connected-but-OFF B01 taps stall init.

## 5. Key viva answers

- "Why is B11 0.93pu?" UAT 0.42pu @100MVA + off-nominal 6.6/6.9 tap — report limitation, tap/cap study next.
- "Is 50kA the grid level?" NO — GIS withstand only (B). Grid = 45.01kA 2019 study (B/C).
- "Will duty hold if the grid grows?" NO (F8) — 0.7×Zth gives 64.4kA. Re-study on uprate.
- "Are C-values plant facts?" NO — labelled C everywhere, replace on PGCB/OEM data.
- Old `matlab/`, `simulink/*.slx`, `results/load_flow/` are PROVISIONAL (pre-Rev2) — not used.
