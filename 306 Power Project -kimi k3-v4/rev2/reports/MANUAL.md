# OPERATING MANUAL — Ashuganj South Rev2 Study (EEE 306 G03)

Covers: how to run everything, what to show, what the results mean, and whether
they are practically realistic (checked against industry practice, Sep 2026).

## PART A — HOW TO RUN

Requires MATLAB R2024a + Simulink + Specialized Power Systems. No toolboxes beyond that.

### A1. Full engine run (~2 min, reproduces all CSVs + plots)

```matlab
cd rev2
run_full_project('All')
```

Per-phase: `run_full_project('Phase1' | 'Phase2' | 'Phase3')`.
Expected tail lines (acceptance):
`Phase1 acceptance: CONVERGED + PBAL OK` (7/7 cases, mismatch ≤5.7e-14)
`Phase2 acceptance: CSVs + SYMMETRY OK`
`Phase3 acceptance: CSVs + GRADING + TMS-CAP OK`

### A2. Simulink cross-check (~20 min)

```matlab
cd rev2/simulink
run_loadflow_v2_tests('Write',true)   % uses simulink/studies/Load_Flow_V2.slx
```

LF sanity → 8 fault cases (XML branch taps, fault at 0.05 s, Stop 0.25 s).
Writes `rev2/results/phase2_simulink_check.csv`. Taps are added/removed per case
automatically; the stored file is always tap-free. B01-LLL/LL stall the solver
(documented wall) → recorded STALLED-engine-only; B03 is engine-only (lumped node).

### A3. GUI + dashboard

```matlab
cd rev2; addpath data tests simulink gui
ashuganj_rev2_gui        % 9 tabs: overview/LF/faults/protection/results/docs/model/tests/animation
```

Open `rev2/plots/dashboard.html` in any browser (no server): animated power-flow
(P1A..P1G), fault+trip timeline scrubber, recovery envelope (illustrative),
battery discharge vs autonomy. Hi-res SLD: `rev2/plots/sld_V2_hires.png`.

### A4. Rebuilds (only if you change data or layout)

```matlab
cd rev2/simulink
build_loadflow_v2()      % re-clone Load_Flow.slx + Rev2 corrections (overwrites V2)
format_loadflow_v2()     % re-apply SLD captions + DC island + verify sim
cd ../gui
build_dashboard()        % regenerate dashboard.html from current CSVs
```

## PART B — WHAT TO SHOW (viva/demo script, 15 min)

1. (2 min) GUI Overview + `phase1_system_summary.csv` P1A row: 354 MW gross,
   340.91 MW export (354−12−1.09 closes), V_B02 1.0004, V_B11 0.9328 LOW.
2. (3 min) Fault table: B02-LLL 46.25 kA vs PGCB-2019 45.01 kA — grid-dominated,
   consistent. Breaker table: all PASS, Q1/Q2 margin +1.94 kA (thin — say it).
3. (3 min) Dashboard fault scrubber F5: flash at 50 ms, Q0/Q9 trip at 110 ms.
4. (2 min) Sensitivities: 12/36 rows exceed 50 kA under strong grid — the F8 warning.
5. (3 min) Protection tables: 5/5 grading margins ≥0.300 s; TCC plot; GSUT-HV
   sensitivity 2.15× thin, covered by 87B.
6. (2 min) Simulink check CSV: grid-share RMS +0.2…+5.5% independent agreement.

## PART C — RESULT EXPLANATIONS

- **Export 340.91 MW**: 354 gross − 12 aux − 1.09 losses. Matches BPDB's ~342 MW
  scheduled band for the 1×360 MW South unit.
- **Qgen ~20 MVAr**: PV solution of the NR solver (the 72 MVAr was only a starting guess).
- **B11 0.9328 pu**: UAT impedance 0.42 pu @100 MVA plus off-nominal 6.6/6.9 kV tap
  drops 0.42×0.13 ≈ 0.055 pu plus angle effects. Real plant issue, not a model bug.
- **B02 faults ≈46 kA**: grid Thevenin alone gives 45.01 kA (2019 study); the unit
  adds ~3.2 kA through GSUT. LG ≈ LLL because grid Z0 ≈ Z1.
- **B01 faults 106–122 kA**: stiff grid feeding BACK through GSUT (69 kA @22 kV)
  plus the unit's own 54–71 kA. X/R 67 → 339 kA first peak (DC component).
- **Peaks below IEC envelope in sims** (e.g. −19%): inception-angle luck; the IEC κ
  value is the worst-case envelope — REVIEW there means "envelope bounds sim", correct.
- **B02-LL healthy-phase dip −0.104**: prefault-angle sensitivity between flat-start
  sim and P1A-dispatched engine; RMS currents still agree (+0.8%).
- **EF times 0.2/0.5 s at 46.79 kA neutral (3I0)**: fast because 46.79 kA/320 A = 146× pickup.
- **UAT-HV TMS 0.318 / LINE TMS 0.281 / LINE-EF 0.375**: solved upstream for 0.3 s
  margins — results, not inputs.
- **DC island Idc 29.7 A vs 27.3 A calc**: fully-charged lead-acid terminal ≈120 V
  (2.18 V/cell × 55), so 120/4.03 = 29.8 A — consistent, conceptual model.

## PART E — PROTECTION INSIDE SIMULINK (V2 model)

Builders (in order): `build_loadflow_v2` → `format_loadflow_v2` → `add_protection`
→ `xml_series_q0.ps1` (Q0 into GSUT_L tree). Backup: `simulink/backups/Load_Flow_V2_protection_base_2026-09-11.slx`.

- BRK_Q9 (line, API insert on dedicated direct lines) + RELAY_Q9: true IEC-SI OC
  (Fourier magnitudes, pickup 1031 A, TMS 0.281, integrator timer, latching).
- BRK_Q0 (gen side, XML series insert) + RELAY_Q0: 27 undervoltage demo
  (Vb02 < 0.8 pu, 0.1 s definite; OC at Q0 needs physical CTs — engine covers it).
- SPS external breakers treat control **0 as OPEN**: trip feeds through NOT gates
  (normal 1 = closed). Verified: LF Igrid 1440–1474 A with relays idle.
- Trip demo (B02-LLL, fault at 0.05 s, Stop 0.8 s): **TRIP_Q0 at 0.137 s,
  TRIP_Q9 at 0.511 s**, Igrid 1.47 kA → 44 kA → 0 A (both ends cleared).
- Rules learned hard: never `save/close` with fault taps present (R2024a teardown
  crash — always untap first; runner does); code cannot branch occupied SPS ports
  (XML branch tool); unconnected fault blocks are benign; B01-LLL/LL stall the
  solver (engine-only).
- Load flow in Simulink: time-domain runs are flat-start (no PV dispatch — the P1A
  NR engine is the load-flow record); use the powergui Load Flow Analyzer tool for
  PV-honoring LF. Phasor-time-sim was tried and dropped (Battery has no phasor
   model; PV still unregulated in phasor-time).

## PART F — ARE THE RESULTS PRACTICAL? (external validation, Sep 2026)

| # | Our result | Real-world benchmark | Verdict |
|---|---|---|---|
| 1 | 230 kV GIS 50 kA, 3150 A, CT 1600/800/400 5P20 | PGCB tenders: 230 kV GIS 3000–3150 A bays at **50 kA/3 s and 40 kA/3 s** both standard; CTs 1600-800-400 A 5P20 routine | PASS — our data matches tender practice exactly. NOTE: at 40 kA-rated stations our 46–48 kA would FAIL — Ashuganj's 50 kA class is what saves the verdict |
| 2 | B01 fault 106–122 kA @22 kV, gen 12.02 kA rated | 63 kA GCBs suit units ≤200 MW (Hitachi HVR/HVS-63). Our 360 MW class uses **100 kA** (GE FKGA2, 14.1 kA cont. ≥ our 12.02 kA) / **110 kA** (Siemens HB3) | CONDITIONAL — 122 kA exceeds even the 100–110 kA class. Practical paths: 100 kA+ GCB + Is-limiter/reactor study, or accept as maximum-initial (decays in ~35 ms). Flagged as limitation F4, not hidden |
| 3 | Aux 12 MW = 3.4% of 354 MW gross | CCPP industry **2–5%** (hot-climate plants upper half) | PASS — mid-range, realistic |
| 4 | 6.6 kV aux bus, UAT Dyn11 22/6.9 kV | 6.6 kV MV standard for large motors in BD plants; off-nominal 6.9/6.6 kV windings exist | PASS (winding data B) |
| 5 | B11 0.9328 pu | Motors typically tolerate ±10% short-term, −5% continuous at rated output | REVIEW — genuine plant problem: sustained 0.93 pu risks motor heating/torque loss. Tap-change or capacitor study required (reported, not fixed) |
| 6 | 110 V DC, 55×2 V, 200 Ah, 2×30 A N+1, 2 h autonomy | 110 VDC station standard (lead-acid dominant, IEEE 485/946); autonomy is owner-policy 2–8 h; 55 cells matches 2.0 V/cell practice | PASS — 2 h defensible for a manned plant; our load (27 A) gives 7.4 h actual |
| 7 | GSUT 96–98% ONAN at 354–360 MW | ONAN rating is continuous-usable by design (ODAF only above it) | PASS — no cooling upgrade needed at current dispatch |
| 8 | OC grading 0.3 s, IEC-SI, EF 0.2 A sec | 0.25–0.4 s grading + IEC curves is textbook utility practice worldwide | PASS (as starting settings; commissioned files still required) |
| 9 | GSUT-HV OC sensitivity 2.15× | Utilities usually want ≥2 for backup OC (primary 87B/87T covers) | MARGINAL-PASS — stated with the 87B cover note |
| 10 | Xd'' 0.2248 sat / X/R 67 at 22 kV | Large 2-pole turbo-generators: Xd'' 0.2–0.3 typical; high X/R at MV terminals expected | PASS (values are B/project dataset, not assumed) |
| 11 | Strong-grid sens 64.4 kA > 50 kA | Grid strengthening over plant life is normal (PGCB expansion ongoing) | ACTION — re-study duty before any Ashuganj uprate/new infeed (F8) |
| 12 | Sim-vs-engine +0.2…+5.5% (6/6) | Independent-method agreement <6% is strong validation for a class project | PASS |

Bottom line: base-case results are practically realistic and consistent with PGCB
tender practice, OEM breaker classes, and CCPP benchmarks. Three honest exceptions
are carried openly: B11 undervoltage (F1), gen-terminal duty vs breaker class (F4),
and future-grid duty exceedance (F8).
