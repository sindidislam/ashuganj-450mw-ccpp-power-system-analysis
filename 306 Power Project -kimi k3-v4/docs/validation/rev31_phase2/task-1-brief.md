# Phase-2 task 1
## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.


## Task 1 â€” Authoritative capability and provenance

**Files:** extend [generator provider](../../../matlab/data/ashuganj_generators.m); create [capability interpolator](../../../matlab/data/generatorCapability.m), [parameter record helper](../../../matlab/data/phase2_parameter.m), [normalized source view](../../../matlab/data/phase2_source_data.m), and [capability tests](../../../matlab/tests/test_generator_capability.m). Update only obsolete unlimited-physical-Q assertions in [generator tests](../../../matlab/tests/test_generator_data.m).

**Interfaces:** generator provider gains a capabilityCurve object containing P_MW, Qmax_MVAr, Qmin_MVAr and full extraction provenance. Interpolator accepts real finite P in [0,458] and optional curve; returns lower then upper MVAr. Parameter helper returns the required lowercase metadata schema. Source view references existing primary provenance and records source-qualified NER, excitation/SFC and grid context, without altering the frozen providers.

- [ ] Write endpoint/interpolation/domain tests and finite physical-limit expectations, including exact six source arrays and manual extraction status.
- [ ] Run new tests and record expected missing-function/field failures.
- [ ] Implement the six-point authoritative curve and reject extrapolation. At 360 MW use lower = -205 + 60*23/89.3 and upper = 280 - 60*39/89.3. These formulas are test expectations, not production hard-coded limits.
- [ ] Set compatibility physical Q limits to the primary-capacity interpolated limits, clearly identify their dispatch applicability, and preserve raw machine/source metadata.
- [ ] Normalize metadata from the existing source records. Keep unresolved field units explicit. Include NER 22/sqrt(3) kV, 500 V, 135 kVA/20 s, approximate 60/2.62 ohm with source qualification. Retain grid estimate 50 kA/19.919 GVA and separate 45.01 kA, X/R 10.99 sensitivity context without modifying the grid model.
- [ ] Run capability/generator/base tests; inspect diff and primary-value identity.
