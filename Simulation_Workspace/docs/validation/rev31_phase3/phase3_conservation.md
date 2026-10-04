# Phase 3 conservation checks — evidence note (Task 11)

Scope: independent gate across all solved cases in
`results/phase3_loadflow/phase3_system_summary.csv` (6/6).
No solver/test/data edits. Validator gates live in
`matlab/analysis/validate_phase3_network.m:40-43`
(P err > 1e-3 MW, Q err > 1e-3 MVAr, worst KCL > 0.05 MVA flag the verdict).

## 1. Sign convention

Validator (`validate_phase3_network.m:30-33`):

- `Pgen` = generator injection at B22 (+ = generating).
- `Paux` = auxiliary load (+ = consuming); `Qaux` likewise.
- `Pgrid_export` = `-Re(Sbus at BGRID230)` (+ = power leaving plant to grid).
- `branch_losses_P/Q` = sum of reconstructed branch P/Q losses (+ = dissipated).
- Balances: `P_balance_err = |Pgen − (Paux + Pgrid_export + branch_losses_P)|`,
  same form for Q. I.e. **Generation = Grid export + Loads + Losses**,
  equivalently **Generation + Grid + Loads + Losses = 0** with grid/load
  injections signed negative (consuming/exported) and losses as dissipation.
- `worst_KCL_MVA` = max bus complex-power residual magnitude
  (`ashuganj_bus_results` residuals).

Thresholds: P < 1e-3 MW, Q < 1e-3 MVAr, KCL < 0.05 MVA per case.

## 2. Per-case balance + KCL gate (reported = full-precision validator; recomp = 6-decimal CSV recompute)

| Case | P err rep (MW) | P recomp signed (MW) | Q err rep (MVAr) | Q recomp signed (MVAr) | Worst KCL (MVA) | Verdict |
|---|---|---|---|---|---|---|
| LF360_GAT_OUT | 9.404895e-07 | −1.00e-06 | 6.822496e-07 | −2.00e-06 | 3.267024e-05 | OK |
| LF360_GAT_IN | 1.147858e-05 | +1.10e-05 | 1.382889e-06 | +0.00e+00 | 5.772916e-04 | OK |
| LF342_GAT_OUT | 9.151859e-07 | +0.00e+00 | 4.852993e-07 | −1.00e-06 | 3.095205e-05 | OK |
| LF342_GAT_IN | 9.222680e-06 | +9.00e-06 | 1.635640e-06 | +2.00e-06 | 5.416526e-04 | OK |
| LF389P30_GAT_OUT | 9.974529e-07 | −1.00e-06 | 1.132818e-06 | −1.00e-06 | 3.546953e-05 | OK |
| LF389P30_GAT_IN | 1.572937e-05 | +1.60e-05 | 8.993878e-07 | +1.00e-06 | 6.386894e-04 | OK |

Result: **6/6 PASS** — max reported P err 1.57e-05 MW (≤1.6e-05 with CSV
rounding) < 1e-3; max Q err 1.64e-06 < 1e-3; max KCL 6.39e-04 < 0.05
(margin ≈ 78×). GAT_IN (looped) cases carry the larger KCL residual in
both eras (snubber residual, cf. `phase2_vs_phase3.csv` rows 20, 40);
GAT_OUT cases sit at ~3e-05 MVA. No threshold violation, no retuning.

Note on recomp-vs-reported: recomputation from the 6-decimal CSV carries
~1e-06 quantization per term, so signed recomps differ from the reported
abs errors at the 1e-06 level (e.g. LF360_GAT_OUT Q −2.0e-06 vs rep
6.8e-07). The reported full-precision validator values are authoritative;
the recomps confirm the same order and sign pattern, i.e. no hidden MW-scale
imbalance of the 70 km-artifact kind.

## 3. Independent 3I²R spot check on L_LINE (all 6 cases)

Locked L_LINE: R_eq 0.0277725 ohm, X_eq 0.1425655 ohm, B_eq 3.937996 uS
(50 Hz). Method: I = S/(√3·Vs), S = √(Pexp² + Qexp²) from grid-export P/Q
(post-ZGRID through-power proxy; ZGRID is series-only), Vs = sending-end
V230_1. Expected P ≈ 3I²R; expected net Q ≈ 3I²X − V²B.

| Case | I (A) | 3I²R (MW) | Reported line P (MW) | ΔP | 3I²X−V²B (MVAr) | Reported line Q (MVAr) | ΔQ |
|---|---|---|---|---|---|---|---|
| LF360_GAT_OUT | 870.0 | 0.063057 | 0.062928 | +129 W (+0.2 %) | 0.115805 | 0.115169 | +0.6 % |
| LF360_GAT_IN | 870.9 | 0.063189 | 0.063035 | +154 W (+0.2 %) | 0.116565 | 0.115799 | +0.7 % |
| LF342_GAT_OUT | 824.5 | 0.056636 | 0.056532 | +104 W (+0.2 %) | 0.082802 | 0.082292 | +0.6 % |
| LF342_GAT_IN | 825.4 | 0.056758 | 0.056631 | +127 W (+0.2 %) | 0.083511 | 0.082884 | +0.8 % |
| LF389P30_GAT_OUT | 944.1 | 0.074265 | 0.074087 | +178 W (+0.2 %) | 0.173417 | 0.172528 | +0.5 % |
| LF389P30_GAT_IN | 945.1 | 0.074414 | 0.074206 | +208 W (+0.2 %) | 0.174261 | 0.173221 | +0.6 % |

Expectation from brief (I ≈ 870 A → ~0.063 MW) confirmed on the LF360
pair; loss scales as I² across dispatch levels (342 → 389 MW).
Residuals are expected: the hand calc uses post-ZGRID export S while the
solver integrates exact sending-end flows and distributed PI shunts.
Agreement to <1 % on all 6 cases confirms the reported line losses.
Sign correct in all cases: P consumed in R, Q net inductive
(series 3I²X exceeds shunt V²B).

## 4. Verdict

Conservation gate **PASS 6/6**. No violation, no root-cause diagnosis
needed, no parameter/tolerance change. Evidence inputs:
`phase3_system_summary.csv`, validator `validate_phase3_network.m:30-43`.
