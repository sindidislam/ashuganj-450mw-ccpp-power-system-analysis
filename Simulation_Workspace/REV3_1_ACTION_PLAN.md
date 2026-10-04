# REV3.1 Data Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task, only after separate implementation authorization.

**Goal:** Reconcile one authoritative machine/plant registry without discarding the source-audited Claude LF branch or historical results.

**Architecture:** Extend the existing master constructor and equipment providers, with explicit primary/legacy profiles and derived study views. LF, fault, protection and later dynamics/Simulink must consume matching versioned registry data, not independent hard-coded copies.

**Tech Stack:** MATLAB R2024a, Simulink/Specialized Power Systems, source-audited CSV/Markdown, existing custom test recorder.

**Spec:** [REV3_1_DATA_RECONCILIATION.md](REV3_1_DATA_RECONCILIATION.md), especially §§3–4, 7, 11–20.

## Global constraints

- This deliverable is a plan only. No existing code, model, test, source record or result is changed in this stage.
- Do not rewrite the LF engine, delete legacy data, globally replace numbers or change physics to satisfy tests.
- Preserve 14 MW / PF 0.85 / 8.67642073764343 MVAr auxiliaries; GSUT 355/460/515 MVA, Z 16%, R 0.21%; UAT 19/25 MVA, Z 10.5%, R 0.4%; GAT 19/25 MVA, ZPS 12%, R 0.5%.
- Preserve 6.9 kV windings versus 6.6 kV plant bus, magnetising branches, principal-tap baseline, four primary LF comparison slots, fresh model build before each solve, KCL and historical outputs.
- Separate Xdpp = 0.2608 from Xdpp_sat = 0.2248. Separate 360 MW capacity from 389.30 MW PF-derived/OEM rated reference. Neither is net export.
- No primary dispatch above 360 MW without a documented approved reconciliation exception. Old 389.30 MW cases remain explicitly legacy sensitivities.
- Keep all genuine gaps explicit. In particular, GAT ZPT/ZST and SEMIPOL control parameters remain unavailable; Rf's numeric value exists but its unit/field-base interpretation is qualified.
- Each future implementation task uses a failing regression first, the smallest approved change, a targeted rerun, independent review and a separate version-control checkpoint. Do not commit or execute these tasks during this audit.

---

## Baseline and priority

The read-only 2026-09-14 rerun returned **447 passed / 0 failed**, including **38 / 0** for grid sensitivity and **41 / 0** for magnetising sensitivity. All four existing LF cases converged and reproduced the preserved results. The reported six grid failures belong to an older log, not the present executable suite. Passing legacy tests does not validate the new dataset or the broad invariance prose.

### Task 1 — P0: Authoritative machine records and conversion tests

**Files:** [ashuganj_generators.m](matlab/data/ashuganj_generators.m), [Ashuganj_Master_Data.csv](data/master/Ashuganj_Master_Data.csv), [test_generator_data.m](matlab/tests/test_generator_data.m), [test_base_conversion.m](matlab/tests/test_base_conversion.m).

**Consumes:** verified workbook row/cell map, raw units and source distinctions in report §§2–7.  
**Produces:** canonical machine fields and provenance; derived compatibility fields for existing LF consumers; preserved legacy saturated dataset.

- [ ] Add expectations for every value in report §3, including all nine time constants, both saturation coefficients, SCR and excitation designations. Verify that the existing registry fails the new specification before implementation.
- [ ] Add separate Ra tests: machine-base 0.000842190082644628 pu, system-base 0.000183884297520661 pu, both recovering 0.00089 Ω; absolute tolerance 1e-12. Check distinct subtransient conversions 0.0569432314410480 and 0.0490829694323144 pu on 100 MVA / 22 kV.
- [ ] Introduce only the new fields/provenance and derived conversions. Preserve the old 1.663/0.2865/0.2248 source set as saturated legacy data; do not copy Rev2 grounding, auxiliary or GSUT assumptions.
- [ ] Run the generator and base-conversion tests, then the existing data selection through [run_all_tests()](matlab/tests/run_all_tests.m:1). Review expected downstream failures rather than hiding them.

**Acceptance:** complete cell-level traceability; no supplied quantity marked missing; no conversion of Rf on an invented field base; unchanged LF electrical behavior while case inputs remain unchanged.

### Task 2 — P0: Capacity-compliant cases without changing the solver

**Files:** [ashuganj_master_data.m](matlab/data/ashuganj_master_data.m), [test_topology.m](matlab/tests/test_topology.m), [build_generator_system.m](matlab/build/build_generator_system.m), targeted labels in [run_load_flow_study.m](matlab/studies/run_load_flow_study.m).

**Consumes:** Task 1 machine/capacity records.  
**Produces:** revisioned four-case primary matrix and explicit historical sensitivity profiles.

- [ ] Add tests separating 458 MVA, rated PF 0.85, 389.30 MW reference and 360 MW capacity; a primary 389.30 MW case must be rejected without an approved exception.
- [ ] Recommend LF1/LF2 = 360 MW with GAT out/in; retain LF3/LF4 = 342.01 MW as qualified scenarios, pending confirmation of the owner's power boundary. Keep old 389.30 MW cases/results under explicit legacy IDs and revisions.
- [ ] Preserve all auxiliary/transformer/tap inputs. Ensure case generator-voltage settings propagate to the builder instead of being shadowed by the generator-record default.
- [ ] Run all four new cases with result/model writing disabled; compare against the report's preserved legacy table without expecting identical dispatch-dependent losses or Q. Require current KCL and independent loss checks to remain satisfied.

**Acceptance:** four primary comparison slots, correct capacity guard and no LF engine rewrite. No cosmetic 6.6 kV normalization.

### Task 3 — P0: Grid provenance and sensitivity root causes

**Files:** [ashuganj_grid.m](matlab/data/ashuganj_grid.m), [grid_series_resistance_zero.m](matlab/data/assumptions/grid_series_resistance_zero.m), [ashuganj_lines.m](matlab/data/ashuganj_lines.m), [test_grid_sensitivity.m](matlab/tests/test_grid_sensitivity.m), [test_line_data.m](matlab/tests/test_line_data.m), targeted notes in [ashuganj_branch_flows.m](matlab/analysis/ashuganj_branch_flows.m).

**Consumes:** Siemens estimated grid dataset and separate GIS ratings; report §§10–11.  
**Produces:** unchanged primary physical equivalent with corrected provenance, coherent secondary profiles and physically meaningful sensitivity checks.

- [ ] Test distinct network-estimate and equipment-rating records; retain the primary R = 0 assumption and 2.65581123827228 Ω magnitude. Record 45.01 kA / X/R 10.99 as secondary, with explicit voltage-factor interpretation.
- [ ] Add a regression that compares model impedance with the case-local reconstruction inputs for both magnitude and R/X sweeps. Correct the magnitude sweep's stale data copy; retain the already corrected finite-X/R path.
- [ ] Replace plant-loss/boundary-export invariance with independent 3I²R and branch/source conservation checks. Preserve narrowly scoped radial PV/UAT invariance and all old measured evidence.
- [ ] Re-run grid sensitivity; record each probe's model/dataset fingerprint, grid loss, plant loss, boundary export, swing delivery, Q and KCL. Do not tune resistance, taps or tolerances to pass.

**Acceptance:** six historical failures individually accounted for, no claim that they remain current, no mixed R/X/Z tuple, no universal voltage-direction claim inferred from equipment withstand.

### Task 4 — P1: Loss accounting and documentation synchronization

**Files:** [ashuganj_transformers.m](matlab/data/ashuganj_transformers.m), [test_transformer_data.m](matlab/tests/test_transformer_data.m), [test_magnetising_sensitivity.m](matlab/tests/test_magnetising_sensitivity.m), plus the exact documentation/UI files listed in report §20.

**Consumes:** source loss/current tables, existing Rm/Xm and auxiliary accounting.  
**Produces:** explicit separate core/copper/cooling records and documentation matching the selected master.

- [ ] Add tests for 1282 − 159 − 1095 = 28 kW, 125.25 − 14 − 110 = 1.25 kW and 140.25 − 23 − 116 = 1.25 kW. Preserve stage-specific cooling distinctions.
- [ ] Synchronize each magnetising-sweep model override with reconstruction data; verify the no-load current quadrature identity and independent P/Q balances.
- [ ] Keep core loss and winding loss represented only once. Do not append rated copper/core losses to solved network loss or add cooling to 14 MW before resolving aggregate overlap.
- [ ] Update resolved-missing lists, saturation/source qualifiers and stale “Lm open” comments; append corrections to earlier REV3 claims without deleting history. Update generated-report content producers before a separately authorized report rebuild.

**Acceptance:** no core/copper/magnetising double counting, unchanged documented transformer impedances, cooling treatment explicitly bounded, and GAT tertiary gaps retained.

### Task 5 — P2: Registry consumer migration and fault/protection safety gate

**Files:** [ashuganj_rev2_registry.m](rev2/data/ashuganj_rev2_registry.m), [seq_networks.m](rev2/data/seq_networks.m), [run_phase2_fault.m](rev2/run_phase2_fault.m), [run_phase3_protection.m](rev2/run_phase3_protection.m), their four existing registry/fault/KCL/protection tests, and the exact orchestration/Simulink consumers listed in report §20.

**Consumes:** one approved master profile and matched LF snapshot.  
**Produces:** explicit study adapters and revised fault/protection inputs; legacy runs remain reproducible and visibly historical.

- [ ] Add rejection tests for stale LF/fault fingerprints, hard-coded prefault fallbacks and inconsistent machine/system bases.
- [ ] Add generator NER/3Zn, GSUT delta-blocking, transformer zero-sequence and impedance-limited auxiliary-neutral tests. Gate GAT earth-fault scope on the missing three-winding/neutral details.
- [ ] Preserve separate saturated initial-fault and unsaturated comparison profiles. Review standards corrections separately; do not label classical superposition as a complete IEC 60909 implementation.
- [ ] Correct device classes and current bases: breaker versus disconnector duties, generator versus GSUT-rated currents, scoped CT/VT records, relay residual/through currents and clearing-time components.
- [ ] Run fault/KCL tests before protection coordination; permit no new plant-validated earth-fault or relay-setting claim until the grounding/source/method gaps are resolved.

**Acceptance:** common registry/case lineage, no solid-ground substitution from the GSUT workbook column, no stale legacy outputs silently driving new protection settings.

### Task 6 — P3: Dynamic/export design implementation, separately authorized

**New proposed files:** [export_simulink_parameters.m](matlab/data/export_simulink_parameters.m), [test_simulink_parameter_export.m](matlab/tests/test_simulink_parameter_export.m), [build_dynamic_generator_system.m](matlab/build/build_dynamic_generator_system.m), [test_dynamic_machine_initialization.m](matlab/tests/test_dynamic_machine_initialization.m). Existing hard-coded adapter: [build_loadflow_v2.m](rev2/simulink/build_loadflow_v2.m).

**Consumes:** report §17 machine/formulation design, approved block mapping, matched LF initialization and separately labelled control assumptions.  
**Produces:** master-fed export and a separate experimental sixth-order model, not an assertion of plant validation.

- [ ] Approve the exact block/state/base/saturation convention before coding; distinguish standard-model independent inputs from retained decrement-validation data.
- [ ] Add exporter propagation tests by changing one in-memory primary parameter; verify mapped outputs change and historical source records do not. Unsupported mappings or missing mandatory controls must fail explicitly.
- [ ] Remove hard-coded primary electrical values from active exporters only after registry-driven equivalents pass; preserve historical builders/outputs under legacy profiles.
- [ ] Implement the separate sixth-order machine using unsaturated-design Xdpp = 0.2608 and one saturation formulation; retain Xdpp_sat = 0.2248 for its selected fault methodology.
- [ ] Validate no-disturbance equilibrium and LF P/Q/V matching before disturbances. Any generic AVR/governor is prominently non-plant-specific; no invented SEMIPOL tuning.

**Acceptance:** no ideal-source-as-dynamic-machine claim; no automatic doubling of saturation; no claim of measured plant fidelity without validation data.

### Task 7 — P3: Voltage/tap sensitivity and final review

**Files:** targeted case/builder/test extensions to [ashuganj_master_data.m](matlab/data/ashuganj_master_data.m), [build_generator_system.m](matlab/build/build_generator_system.m), [ashuganj_transformers.m](matlab/data/ashuganj_transformers.m); no solver replacement.

- [ ] Run generator setpoint 0.98/1.00/1.02 pu at principal taps first, then report §14's one-at-a-time adjacent tap matrix. UAT taps are offline scenarios; incomplete tap-impedance data remain an approximation flag.
- [ ] Preserve 1.000911168/1.020279743 pu legacy LF1/LF2 MV results for comparison; do not use them as calibration targets for new dispatch cases.
- [ ] Require all study outputs to identify registry, method, topology, power boundary and assumptions. Preserve nonconvergence and capability limitations rather than hiding cases.
- [ ] Independently review the changes and compare file hashes/result revisions before accepting any implementation milestone.

## Execution boundary

Tasks above are **not executed by this reconciliation task**. The LF engine, all existing data/code/tests and historical results remain unchanged. Implement registry and test/provenance corrections first; migrate fault/protection only after their safety gates; treat dynamics and voltage/tap studies as later separately reviewed work. Stop here pending separate authorization.
