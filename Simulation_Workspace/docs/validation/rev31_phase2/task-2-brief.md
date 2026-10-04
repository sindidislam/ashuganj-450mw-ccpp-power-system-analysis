# Phase-2 task 2
## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.


## Task 2 â€” Central finite assumption registry and isolated component data

**Files:** create [assumptions](../../../matlab/data/engineering_assumptions.m), [component registry](../../../matlab/data/ashuganj_phase2_systems.m), [assumption tests](../../../matlab/tests/test_engineering_assumptions.m), and [component-data tests](../../../matlab/tests/test_phase2_systems.m).

**Interfaces:** assumption registry returns a struct keyed by stable parameter names; each field is a metadata record with value, unit, source, source_locator, status, confidence, rationale, assumption_basis, reasonable_range, assumed_range and selected_value. Component registry accepts generator and assumption registry, and returns separate excitation, sfc, stationDC, governor, pss and dynamicReadiness objects.

- [ ] Write tests requiring complete metadata, finite values, selected values within ranges, distinct subsystem identities and exact source type/designation.
- [ ] Record RED execution before implementation.
- [ ] Implement AVR 200 pu/pu, 0.02 s, field lag 0.5 s, +/-5 pu command limits; academic rated-field reference and 1.075 pu OEL with finite lag; curve-based UEL inset; 1.0 pu stator continuous threshold and finite response. Each additional gain/time/reference is an assumption record.
- [ ] Implement SFC 0.97 efficiency, 0.03 s response and separately assumed finite converter power limit; retain 1876 A as output starting current, not DC current.
- [ ] Implement station nominal 110 V, 55 cells, 200 Ah, 0.05 ohm bank resistance; finite SOC/OCV endpoints and cutoff. Charger 20 kW each, two units in duty/standby, 92.5% efficiency, finite current/control response and explicitly assumed float target distinct from nominal 110 V.
- [ ] Implement continuous relay/control/instrumentation/communications/emergency-control/excitation-electronics loads, separate trip/close pulse powers and durations, emergency additional load. All positive finite, with plausible ranges and no assertion of installed plant ratings.
- [ ] Implement readiness governor droop 0.05, lag 0.2 s, turbine lag 0.75 s; optional generic PSS finite gain/washout/lead-lag, disabled/untuned. Machine readiness selects exact primary standard sixth-order inputs, not saturated replacement; no inferred physical field base.
- [ ] Run data tests and verify every new numeric assumption has a central record.
