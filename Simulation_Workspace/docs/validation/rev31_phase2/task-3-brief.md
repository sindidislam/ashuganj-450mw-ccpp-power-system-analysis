# Phase-2 task 3
## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.


## Task 3 â€” Isolated non-ideal component behavior

**Files:** create [excitation response](../../../matlab/analysis/phase2_excitation_step.m), [SFC response](../../../matlab/analysis/phase2_sfc_step.m), [station DC response](../../../matlab/analysis/phase2_dc_step.m), and [component response tests](../../../matlab/tests/test_phase2_component_models.m).

**Interfaces:** each step takes current state, explicitly named inputs, positive finite time step and its component configuration; returns new state and observable outputs. No hidden globals, LF connections or physical field-voltage conversion. Document units and equations in each function and model documentation.

- [ ] Write tests for finite delayed response, limiter activation, invalid inputs, battery sag, SOC conservation/depletion, charger power/current bounds and standby behavior.
- [ ] Record RED execution.
- [ ] Implement first-order lags using exact exponential updates for held inputs to avoid Euler instability. Exciter command limited before field lag; source capability informs UEL; overloads are reported, not repaired by changing LF dispatch/Q.
- [ ] Implement bounded SFC power command and finite lag with efficiency accounting; do not claim a detailed motor-start simulation.
- [ ] Implement battery terminal voltage from SOC-dependent OCV minus current times resistance, finite charge accounting and cutoff. Charger is current/power limited with finite response, explicit duty/standby and loss accounting. Loads must not draw unlimited constant power as voltage collapses; use documented current/conductance treatment and report unmet demand.
- [ ] Run response tests including time-step sensitivity and finite-state assertions; no plant stability claim.
