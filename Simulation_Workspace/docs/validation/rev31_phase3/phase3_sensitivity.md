# Phase 3 sensitivity runs — evidence note (Task 12)

Scope: three in-memory sensitivity sets on the locked 0.7 km lumped
dual-circuit Mallard PI model. Anchor case `LF360_GAT_OUT`
(baseline Export 345.2073 MW / −26.2675 MVAr, total loss 0.792747 MW,
line loss 0.062928 MW / 0.115169 MVAr, V230_1 229.760 kV,
V_REMOTE 229.731 kV, KCL 3.267e-05 MVA, Verdict OK, 2 iterations).

Method (in-memory only, no committed parameter change): per run, a
workspace-only copy `Ds` of `ashuganj_master_data()` carries the
overridden numerics; the model is fresh-built from the COMMITTED data
(`Save=false, Backup=false`), the `L_LINE` / `ZGRID` block dialogs are
retuned via `set_param` to match `Ds`, the case is solved with
`power_loadflow`, validated against `Ds` (so solver and the
`ashuganj_branch_flows` reconstruction agree on one network), then
discarded with `bdclose`. Nothing is written to any data file, results
directory, or `.slx`. First attempt note: validating overridden-block
solves against the UNmodified `D` flags phantom KCL/balance verdicts
(up to 345 MVA) because reconstruction then uses different impedances
than the solver — a method artifact, not physics. All rows below use
the consistent `Ds` method and close cleanly.

## Set (a): single-circuit-out (R/X x2, B /2)

| Run | Export P (MW) | Export Q (MVAr) | Total loss (MW) | Line P (MW) | Line Q (MVAr) | V230_1 (kV) | V_REMOTE (kV) | KCL (MVA) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| BASE | 345.2073 | −26.2675 | 0.792747 | 0.062928 | 0.115169 | 229.760 | 229.731 | 3.267e-05 | OK |
| SCO (1 ckt) | 345.1444 | −26.9774 | 0.855641 | 0.125847 | 0.542081 | 229.781 | 229.723 | 3.374e-05 | OK |

Movement: export −62.9 kW (= line-loss doubling 0.062928 → 0.125847 MW,
exact 2x resistive scaling), Q −0.71 MVAr, plant bus +21 V, remote −8 V.
Small, correct direction, OK verdict.

## Set (b): R/X/B ±20 % (one at a time)

| Run | ΔExport P (kW) | ΔExport Q (kVAr) | ΔLine P (kW) | ΔLine Q (kVAr) | ΔV230_1 (V) | ΔV_REMOTE (V) | KCL (MVA) | Verdict |
|---|---|---|---|---|---|---|---|---|
| R +20 % | −12.6 | −99.1 | +12.6 | −0.0 | +8 | −1 | 3.399e-05 | OK |
| R −20 % | +12.5 | +99.1 | −12.6 | +0.0 | −7 | +1 | 3.227e-05 | OK |
| X +20 % | −0.1 | −25.7 | +0.0 | +64.6 | −2 | −0 | 3.891e-05 | OK |
| X −20 % | +0.0 | +25.8 | −0.0 | −64.6 | +3 | +1 | 2.676e-05 | OK |
| B +20 % | +0.0 | +35.8 | −0.0 | −41.6 | +1 | +1 | 4.017e-05 | OK |
| B −20 % | +0.0 | −35.8 | +0.0 | +41.6 | +0 | +0 | 2.654e-05 | OK |

Monotonic and symmetric in every pair: R moves P loss (±12.6 kW =
±20 % of 3I²R) and leaves Q untouched; X moves net line Q only
(±64.6 kVAr ≈ ±20 % of series 3I²X = 0.324 MVAr) with export P fixed
to ≤0.1 kW; B moves net line Q only (∓41.6 kVAr = ∓V²·0.2B) with
export P fixed. Voltage moves are single volts. All OK, 2 iterations.

## Set (c): grid 50 kA ESTIMATED vs 45.01 kA secondary profile (separate sensitivity)

| Run | Export P (MW) | Export Q (MVAr) | Total loss (MW) | Line P/Q (MW/MVAr) | V230_1 (kV) | V_REMOTE (kV) | KCL (MVA) | Verdict |
|---|---|---|---|---|---|---|---|---|
| BASE (50 kA, R=0, \|Z\| 2.6558 Ω) | 345.2073 | −26.2675 | 0.792747 | 0.062928 / 0.115169 | 229.760 | 229.731 | 3.267e-05 | OK |
| GRID45 (45.01 kA, X/R 10.99) | 344.6026 | −31.2232 | 1.397421 | 0.062859 / 0.114250 | 230.071 | 230.045 | 3.341e-05 | OK |

Secondary profile numerics (executed c=1 values, cf.
`matlab/studies/rev3_b1_derivations.m:267-275`): Ssc = 17930.71 MVA,
\|Z\| = 2.950246 Ω, R = 0.267344 Ω, X = 2.938108 Ω, X/R = 10.99.
Movement: export −0.605 MW, all of it grid resistive loss
(hand check 3I²R = 3·868.3²·0.267344 = 0.605 MW ✓), export Q −4.96 MVAr
(grid X absorption), plant bus +311 V (P export through grid R lifts
the plant end), line P/Q essentially unchanged (−69 W / −0.9 kVAr:
the line current barely moves). OK verdict, KCL 3.34e-05 MVA.

Voltage-factor interpretation (never mixed into primary): the
circulating "|Z| = 3.25 Ω" figure is consistent with 45.01 kA ONLY
with a voltage factor c ≈ 1.10 (45.01 kA at c=1.10 implies 3.24527 Ω;
at c=1, 3.25 Ω implies 40.86 kA). This sensitivity uses the c=1
executed profile (2.950246 Ω), NOT 3.25 Ω, and NEVER combines 50 kA
with X/R 10.99. The primary stays 50 kA / \|Z\| 2.6558 Ω / R=0
ESTIMATED at the remote bus.

## Movement summary

- Largest line-parameter movement: SCO export −62.9 kW, line-loss
  doubling exact to <0.1 W. Largest ±20 % movement: 12.6 kW.
- Largest overall movement: GRID45 export −0.605 MW (grid R, hand-check
  exact), ≈ 1 % of the 70 km artifact's 53 MW swings — different
  universe, as required of a 0.7 km short line.
- Every run: 2 iterations, P/Q balance ≤ 3e-6 MW/MVAr, KCL ≤ 4.1e-05
  MVA (margin ≈ 1000x to the 0.05 gate), Verdict OK 9/9.
- Cosmetic: the SPS propagation-speed warning (>300000 km/s on L_LINE)
  appears in all runs including BASE (short-lump PI artifact, cf. Task 10
  note §5); convergence unaffected.

## Primary locked values unchanged

Post-run `test_phase3_line_model`: **20/0 PASS**; committed
`ashuganj_lines` L_LINE (R 0.0277725 Ω, X 0.1425655 Ω, C 1.253503e-08 F,
R0/X0/C0 MISSING) and `ashuganj_grid` (X 2.655811 Ω, R 0, ESTIMATED)
byte-identical — all overrides lived and died in the MATLAB workspace.
No data/result/model file was written by these runs.

## Set (d): length sensitivity 0.5 / 0.7 / 1.0 km (reviewer fix wave, in-memory)

Anchor `LF360_GAT_OUT`. Method: workspace-only `Ds` copy with locked
R/X scaled by L/0.7 and C (B) scaled by L/0.7; fresh build from COMMITTED
data (`Save=false, Backup=false`); `set_param` retune of the `L_LINE` PI
dialog to match `Ds`; `power_loadflow` solve; `validate_phase3_network`
against `Ds`; `bdclose`. `Write=false` path — no data/result/model writes.
Script kept outside the repo at
`C:\Users\sindi\AppData\Local\Temp\opencode\task15_lensens.m`.
Post-run `LOCKED_CHECK`: R 0.0277725 / X 0.1425655 / C 1.253503e-08 /
R0 MISSING / grid X 2.655811 / R 0 / Length 0.7 — committed data intact.

| Run | L (km) | Export P (MW) | Export Q (MVAr) | Total loss (MW) | Line P (MW) | Line Q (MVAr) | V230_1 (kV) | V_REMOTE (kV) | dV (V) | KCL (MVA) | Pbal (MW) | Qbal (MVAr) | Iter | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LEN_0.5 | 0.5 | 345.2252 | −26.1400 | 0.774779 | 0.044950 | 0.082276 | 229.754 | 229.733 | 20.910 | 1.862e-05 | 2.413e-06 | 1.467e-06 | 2 | OK |
| LEN_0.7 | 0.7 | 345.2073 | −26.2675 | 0.792747 | 0.062928 | 0.115169 | 229.760 | 229.731 | 29.204 | 3.267e-05 | 9.405e-07 | 6.822e-07 | 2 | OK |
| LEN_1.0 | 1.0 | 345.1803 | −26.4577 | 0.819698 | 0.089892 | 0.164491 | 229.771 | 229.729 | 41.569 | 6.795e-05 | 1.828e-07 | 4.233e-07 | 2 | OK |

Stability conclusion: movements are small, monotonic, and linear in L —
line P 0.044950 → 0.062928 → 0.089892 (ratios 0.7143 / 1.4286 = L/0.7
exact) and line Q 0.082276 → 0.115169 → 0.164491 (same ratios); export P
moves only −17.9 kW (0.5→0.7) and −27.0 kW (0.7→1.0); series drop
20.910 → 29.204 → 41.569 V scales with L; every run converges in
2 iterations with balances ≤ 2.5e-06 and KCL ≤ 6.8e-05 (margin ≈ 700× to
the 0.05 gate), Verdict OK 3/3. The tested 0.5–1.0 km range does not materially affect balanced load-flow convergence or the tested Phase-3 network behavior. Cosmetic: the SPS
propagation-speed warning appears on all three runs (short-lumped-PI
artifact, cf. §Movement summary); convergence unaffected.
