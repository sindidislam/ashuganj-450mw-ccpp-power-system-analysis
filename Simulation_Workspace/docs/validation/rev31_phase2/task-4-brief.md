# Phase-2 task 4
## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.


## Task 4 â€” Operating profile migration

**Files:** create [profiles](../../../matlab/data/ashuganj_operating_profiles.m), [capacity guard](../../../matlab/data/validate_operating_profile.m), [profile tests](../../../matlab/tests/test_operating_profiles.m); extend [master](../../../matlab/data/ashuganj_master_data.m). Adjust case-count/dispatch expectations in [topology tests](../../../matlab/tests/test_topology.m) and [generator tests](../../../matlab/tests/test_generator_data.m) without dropping legacy regression assertions.

**Interfaces:** profiles accept the assembled dataset and return six canonical cases and four historical aliases in the existing builder-compatible field schema plus lowercase provenance/identity fields. Master exposes canonical operating_profiles, primary_cases, historical_cases and builder-visible cases. No builder changes are needed. Capacity guard rejects invalid or inconsistent identity/dispatch and primary exceptions.

- [ ] Write tests for all six IDs, exact dispatches, unique canonical combinations, finite curve-derived limits, metadata, 360 MW guard and historical-only exceptions.
- [ ] Record RED execution.
- [ ] Create profiles from generator capacity/reference/scenario fields, never independent copies of machine parameters. Preserve old LF1â€“LF4 aliases and original topology/setpoints.
- [ ] Populate master with profiles and separate component/source objects. Keep original frozen numerical providers unchanged.
- [ ] Run data/topology/profile tests; verify old alias dispatches remain [389.30,389.30,342.01,342.01].
