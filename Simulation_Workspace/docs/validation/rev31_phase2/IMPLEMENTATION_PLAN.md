# Rev3.1 Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development or executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Implement the six registry-backed LF profiles, extracted capability limits, honest finite academic control/DC components, and Phase-2 validation evidence.

**Architecture:** Extend the existing master and generator provider. Keep the balanced solver and network physics unchanged; validate physical limits outside the solve. Separate excitation, SFC and station DC objects share a central assumption registry, not electrical connections.

**Tech Stack:** MATLAB R2024a, Simscape Electrical Specialized Power Systems, Windows PowerShell for read-only audit/hash operations.

**Spec:** [Approved design](DESIGN.md).

## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.

## Task 1 — Authoritative capability and provenance

**Files:** extend [generator provider](../../../matlab/data/ashuganj_generators.m); create [capability interpolator](../../../matlab/data/generatorCapability.m), [parameter record helper](../../../matlab/data/phase2_parameter.m), [normalized source view](../../../matlab/data/phase2_source_data.m), and [capability tests](../../../matlab/tests/test_generator_capability.m). Update only obsolete unlimited-physical-Q assertions in [generator tests](../../../matlab/tests/test_generator_data.m).

**Interfaces:** generator provider gains a capabilityCurve object containing P_MW, Qmax_MVAr, Qmin_MVAr and full extraction provenance. Interpolator accepts real finite P in [0,458] and optional curve; returns lower then upper MVAr. Parameter helper returns the required lowercase metadata schema. Source view references existing primary provenance and records source-qualified NER, excitation/SFC and grid context, without altering the frozen providers.

- [ ] Write endpoint/interpolation/domain tests and finite physical-limit expectations, including exact six source arrays and manual extraction status.
- [ ] Run new tests and record expected missing-function/field failures.
- [ ] Implement the six-point authoritative curve and reject extrapolation. At 360 MW use lower = -205 + 60*23/89.3 and upper = 280 - 60*39/89.3. These formulas are test expectations, not production hard-coded limits.
- [ ] Set compatibility physical Q limits to the primary-capacity interpolated limits, clearly identify their dispatch applicability, and preserve raw machine/source metadata.
- [ ] Normalize metadata from the existing source records. Keep unresolved field units explicit. Include NER 22/sqrt(3) kV, 500 V, 135 kVA/20 s, approximate 60/2.62 ohm with source qualification. Retain grid estimate 50 kA/19.919 GVA and separate 45.01 kA, X/R 10.99 sensitivity context without modifying the grid model.
- [ ] Run capability/generator/base tests; inspect diff and primary-value identity.

## Task 2 — Central finite assumption registry and isolated component data

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

## Task 3 — Isolated non-ideal component behavior

**Files:** create [excitation response](../../../matlab/analysis/phase2_excitation_step.m), [SFC response](../../../matlab/analysis/phase2_sfc_step.m), [station DC response](../../../matlab/analysis/phase2_dc_step.m), and [component response tests](../../../matlab/tests/test_phase2_component_models.m).

**Interfaces:** each step takes current state, explicitly named inputs, positive finite time step and its component configuration; returns new state and observable outputs. No hidden globals, LF connections or physical field-voltage conversion. Document units and equations in each function and model documentation.

- [ ] Write tests for finite delayed response, limiter activation, invalid inputs, battery sag, SOC conservation/depletion, charger power/current bounds and standby behavior.
- [ ] Record RED execution.
- [ ] Implement first-order lags using exact exponential updates for held inputs to avoid Euler instability. Exciter command limited before field lag; source capability informs UEL; overloads are reported, not repaired by changing LF dispatch/Q.
- [ ] Implement bounded SFC power command and finite lag with efficiency accounting; do not claim a detailed motor-start simulation.
- [ ] Implement battery terminal voltage from SOC-dependent OCV minus current times resistance, finite charge accounting and cutoff. Charger is current/power limited with finite response, explicit duty/standby and loss accounting. Loads must not draw unlimited constant power as voltage collapses; use documented current/conductance treatment and report unmet demand.
- [ ] Run response tests including time-step sensitivity and finite-state assertions; no plant stability claim.

## Task 4 — Operating profile migration

**Files:** create [profiles](../../../matlab/data/ashuganj_operating_profiles.m), [capacity guard](../../../matlab/data/validate_operating_profile.m), [profile tests](../../../matlab/tests/test_operating_profiles.m); extend [master](../../../matlab/data/ashuganj_master_data.m). Adjust case-count/dispatch expectations in [topology tests](../../../matlab/tests/test_topology.m) and [generator tests](../../../matlab/tests/test_generator_data.m) without dropping legacy regression assertions.

**Interfaces:** profiles accept the assembled dataset and return six canonical cases and four historical aliases in the existing builder-compatible field schema plus lowercase provenance/identity fields. Master exposes canonical operating_profiles, primary_cases, historical_cases and builder-visible cases. No builder changes are needed. Capacity guard rejects invalid or inconsistent identity/dispatch and primary exceptions.

- [ ] Write tests for all six IDs, exact dispatches, unique canonical combinations, finite curve-derived limits, metadata, 360 MW guard and historical-only exceptions.
- [ ] Record RED execution.
- [ ] Create profiles from generator capacity/reference/scenario fields, never independent copies of machine parameters. Preserve old LF1–LF4 aliases and original topology/setpoints.
- [ ] Populate master with profiles and separate component/source objects. Keep original frozen numerical providers unchanged.
- [ ] Run data/topology/profile tests; verify old alias dispatches remain [389.30,389.30,342.01,342.01].

## Task 5 — Phase-2 LF validation and results

**Files:** create [operating-point checks](../../../matlab/analysis/check_generator_operating_point.m), [LF validator](../../../matlab/analysis/validate_phase2_load_flow.m), [Phase-2 runner](../../../matlab/studies/run_phase2_load_flow.m), [plotter](../../../matlab/analysis/plot_generator_capability.m), [LF tests](../../../matlab/tests/test_phase2_load_flow.m). Extend [dispatcher](../../../matlab/ashuganj.m) with explicit Phase-2 action; prevent default primary execution from silently using historical dispatch. Historical report producers are not rebuilt.

**Interfaces:** operating-point check returns original P/Q, S/PF, interpolated bounds, Q/MVA margins and capacity/capability verdicts. LF validator consumes the original runner result plus dataset; sums finite reconstructed branch P/Q losses, compares independent balances, and retains all bus/branch/residual detail. Runner selects primary by default or all six explicitly, invokes the unchanged study with both writing/model-saving disabled, then writes only to new Phase-2 locations when requested.

- [ ] Write tests for boundary points, deliberate curve violation with unchanged Q, MVA exceedance, primary overdispatch, six-case convergence and independent balances.
- [ ] Record RED data-only execution; run LF tests only after profile integration.
- [ ] Implement independent balance residuals Pgen-Paux-Pgrid-sum(branch P losses) and Qgen-Qaux-Qgrid-sum(branch Q losses), tolerance 0.001 each. Report excluded merged-node unobservable branches explicitly, never turn unknown flows into measured zero.
- [ ] Report generator/230 kV/22 kV/6.6 kV voltages, transformer end loading at every cooling stage, all losses, export, iterations, convergence, KCL and margins. Stop acceptance on primary overdispatch or MVA exceedance; preserve offending evidence.
- [ ] Generate source curves, primary allowable region capped at 360 MW, MVA circle and distinct primary/qualified/historical markers. Do not shade historical dispatch as approved primary operation.
- [ ] Compare historical numerical fields, complete LF bus/branch/residual tables and iteration/verdict values against captured baseline; ignore only timing/model handles and intentionally extended metadata.

## Task 6 — Integration, audit and final report

**Files:** extend [suite runner](../../../matlab/tests/run_all_tests.m); create Phase-2 documentation, audit/evidence/result tables under the new Phase-2 locations. No original historical reports are modified.

- [ ] Add all new data and component/LF test files to the complete suite with a separate fast data selection.
- [ ] Run generator, base, master/data, topology, capability, capacity, assumptions, subsystem and response tests, then complete suite. Save actual counts and logs; require zero failures.
- [ ] Run all six fresh LF cases and exact historical baseline comparison, plus plot generation and source/assumption table export.
- [ ] Scan requested numeric/text patterns repository-wide; classify text matches as PRIMARY LIVE CODE, PRIMARY DATA, ENGINEERING_ASSUMPTION, HISTORICAL, LEGACY, DOCUMENTATION, COMMENT, TEST EXPECTATION or UNUSED/DEAD. Inventory binary coverage; inspect workbook/container text read-only where feasible, clearly state PDF/image/database limitations. Exclude generated audit recursion.
- [ ] Rehash all 937 original files. Produce exact modified/unchanged paths, reason/type ledger and new-file manifest; verify protected files unchanged. Verify generator primary structure and transformer/grid/load numerical identity against baseline.
- [ ] Independently review implementation scope, provenance, limiter bases, battery conservation, source-vs-assumption distinctions and test assertions; fix only Phase-2 issues, rerun impacted/full tests.
- [ ] Produce report sections A–AF, complete source and engineering-assumption tables, all LF results and regression discrepancies, exception treatment, Rev2 readiness only, and recommended Phase-3 scope without implementing it.

## Self-review

All approved design sections map to Tasks 1–6. No plant field base, SFC DC current or charger installation is inferred. Frozen solver limits are explicitly distinguished from finite physical registry limits. Phase-2 output paths are separate from historical results. The only original runtime files planned for edits are the generator provider, master and dispatcher; the suite runner and affected data/topology expectations also change. New isolated components cannot alter LF physics.
