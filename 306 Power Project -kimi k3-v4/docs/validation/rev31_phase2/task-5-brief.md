# Phase-2 task 5
## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.


## Task 5 â€” Phase-2 LF validation and results

**Files:** create [operating-point checks](../../../matlab/analysis/check_generator_operating_point.m), [LF validator](../../../matlab/analysis/validate_phase2_load_flow.m), [Phase-2 runner](../../../matlab/studies/run_phase2_load_flow.m), [plotter](../../../matlab/analysis/plot_generator_capability.m), [LF tests](../../../matlab/tests/test_phase2_load_flow.m). Extend [dispatcher](../../../matlab/ashuganj.m) with explicit Phase-2 action; prevent default primary execution from silently using historical dispatch. Historical report producers are not rebuilt.

**Interfaces:** operating-point check returns original P/Q, S/PF, interpolated bounds, Q/MVA margins and capacity/capability verdicts. LF validator consumes the original runner result plus dataset; sums finite reconstructed branch P/Q losses, compares independent balances, and retains all bus/branch/residual detail. Runner selects primary by default or all six explicitly, invokes the unchanged study with both writing/model-saving disabled, then writes only to new Phase-2 locations when requested.

- [ ] Write tests for boundary points, deliberate curve violation with unchanged Q, MVA exceedance, primary overdispatch, six-case convergence and independent balances.
- [ ] Record RED data-only execution; run LF tests only after profile integration.
- [ ] Implement independent balance residuals Pgen-Paux-Pgrid-sum(branch P losses) and Qgen-Qaux-Qgrid-sum(branch Q losses), tolerance 0.001 each. Report excluded merged-node unobservable branches explicitly, never turn unknown flows into measured zero.
- [ ] Report generator/230 kV/22 kV/6.6 kV voltages, transformer end loading at every cooling stage, all losses, export, iterations, convergence, KCL and margins. Stop acceptance on primary overdispatch or MVA exceedance; preserve offending evidence.
- [ ] Generate source curves, primary allowable region capped at 360 MW, MVA circle and distinct primary/qualified/historical markers. Do not shade historical dispatch as approved primary operation.
- [ ] Compare historical numerical fields, complete LF bus/branch/residual tables and iteration/verdict values against captured baseline; ignore only timing/model handles and intentionally extended metadata.
