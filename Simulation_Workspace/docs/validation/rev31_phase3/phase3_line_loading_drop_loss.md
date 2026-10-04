# Phase 3 L_LINE loading, voltage drop, loss — evidence note (Task 10)

Scope: analysis of Task 9 outputs only. No solver/test/data edits.
Inputs: `results/phase3_loadflow/phase3_system_summary.csv`,
`results/phase3_loadflow/phase3_bus_results.csv`,
`docs/validation/rev31_phase3/phase2_vs_phase3.csv`.
Locked model (Task 4): lumped dual-circuit PI, 0.7 km, R_eq 0.0277725 ohm,
X_eq 0.1425655 ohm, B_eq 3.937996 uS (50 Hz).

## 1. Line current and loading (LF360 pair)

Formula: I = S / (√3 · V), S = √(P² + Q²) from grid-export P/Q
(through-power proxy; ZGRID is series-only so export S ≈ line S).
V = sending-end V230_1 (Vr-based I differs by ~0.01 %, negligible).

| Case | P exp (MW) | Q exp (MVAr) | S (MVA) | Vs (kV) | I (A) |
|---|---|---|---|---|---|
| LF360_GAT_OUT | 345.207254 | −26.267474 | 346.2052 | 229.760477 | 869.96 |
| LF360_GAT_IN | 345.194542 | −30.029544 | 346.4983 | 229.714716 | 870.87 |

Loading: **Thermal rating unavailable** — `matlab/data/ashuganj_lines.m:55`
states the line carries no thermal rating. The 2000 A figure in the source
set is the 230 kV GIS line-bay module rating (proves a bay exists, not a
conductor ampacity) and is NOT used as a rating. Loading percent is
therefore NaN by rule, not by omission. No rating is invented.
Equivalent D/C branch current ≈870 A; ≈435 A per identical circuit under
equal sharing; relay/breaker duty in later phases must use per-circuit current.

## 2. Voltage drop — model result, not measured

Formula: ΔV% = (|Vs| − |Vr|) / |Vs| · 100, both from `phase3_bus_results.csv`
V_kV (correct columns post Task 9 display fix). These are solved load-flow
voltages, not field measurements.

| Case | Vs B230_1 (kV) | Vr B230_REMOTE (kV) | ΔV (V) | ΔV% |
|---|---|---|---|---|
| LF360_GAT_OUT | 229.760477 | 229.731274 | 29.203 | 0.012710 |
| LF360_GAT_IN | 229.714716 | 229.687837 | 26.879 | 0.011701 |

Plant-end vs OLD (Phase 2): OUT +24.017 V (+0.010455 %),
IN +21.900 V (+0.009534 %) → ≈ +0.01 % rise; remote bus sits ~29/27 V
below the plant bus. Sign and size are consistent with a 0.7 km short line:
half-shunt charging supports the plant end while series drop puts the
remote end marginally lower.

## 3. P/Q line loss with hand-check agreement

Reported (branch reconstruction): OUT 0.062928 MW / 0.115169 MVAr;
IN 0.063035 MW / 0.115799 MVAr. Both positive: P consumed in R (3I²R),
Q net inductive (series 3I²X exceeds shunt V²B) — correct sign.

Hand check with locked R/X/B and the Vs-based I above:

| Case | 3I²R (MW) | rep P | Δ | 3I²X (MVAr) | V²B (MVAr) | net Q (MVAr) | rep Q | Δ |
|---|---|---|---|---|---|---|---|---|
| OUT | 0.063057 | 0.062928 | +129 W (+0.2 %) | 0.323691 | 0.207886 | 0.115805 | 0.115169 | +0.00064 (+0.6 %) |
| IN | 0.063189 | 0.063035 | +154 W (+0.2 %) | 0.324369 | 0.207804 | 0.116565 | 0.115799 | +0.00077 (+0.7 %) |

Residuals are expected: the hand calc uses post-ZGRID export S while the
solver integrates exact sending-end flows and distributed PI shunts.
Agreement to <1 % confirms the reported losses.

## 4. Drop/loss cross-check ΔV ≈ (R·P + X·Q)/V

Using signed plant→grid Q (= Export_Q, negative = Q imported from grid):

| Case | (R·P+X·Q)/Vs (V) | measured ΔV (V) |
|---|---|---|
| OUT | 25.43 | 29.203 |
| IN | 23.10 | 26.879 |

Same sign (Vs > Vr), same order, ~13–14 % low — expected of a first-order
formula that ignores shunt-charging distribution and uses post-ZGRID Q.
Consistency proof: R·P dominates the negative X·|Q| term; using unsigned
|Q| would give ≈ 58 V (≈ 2× measured), so the signed-Q form is the
physically consistent one. Loss deltas independently match hand calcs
(§3) and the OLD→NEW export delta equals L_LINE 3I²R to <4e-05 MW
(`phase2_vs_phase3.csv` rows 5, 25).

## 5. SPS propagation-speed warning (cosmetic, no action)

Each fresh build/solve logs: propagation speed 419281 km/s > 300000 km/s
for mode 1 in block L_LINE. Expected artifact of the 0.7 km short lumped
PI (tiny L/C → superluminal modal speed in the warning heuristic).
Load flow converges normally (iter 2, Verdict OK 6/6); transient/propagation
work is out of Phase 3 scope per Global Constraints. Noted, not chased.

Verdict: drop/loss sign and size verified against two independent hand
calcs; loading unreportable as percent (rating MISSING) with current
≈ 870 A stated instead.
