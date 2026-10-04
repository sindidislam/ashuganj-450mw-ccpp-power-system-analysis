# Phase-5 Protection Study Design — Ashuganj South 450 MW CCPP

**Date:** 2026-09-19
**Status:** Approved (user: "Approved, start Phase-5")
**Classification:** ARCHITECTURAL (new protection subsystem on frozen Phase-4)
**Phase-4 base:** `results/phase4_fault/production/` (464 currents + 204 contrib + 20 bands + 2040 ct + 33 analytic + manifest + sha256 + run_log), 27/27 validation, review gate 23/23.
**Plan:** `docs/superpowers/plans/2026-09-19-phase5-implementation.md`

## 1. Objective
Extend frozen Phase-4 fault-current package into protection application + relay coordination + CT/secondary analysis + breaker-duty (where source data permits) + validation + report. No Phase-3 redesign, no Phase-4 equation rewrite, no silent production-result changes.

## 2. Freeze boundary
Protected/canonical: Phase-3 network + protected data files, Phase-4 source/provenance, sequence/grounding/topology implementation, production outputs, review gate, final report. Phase-5 reads production CSVs only. Exception: genuine interface bug → document first, smallest justified change. Regression test T1 proves import identity within tolerance before any output.

## 3. Architecture (thin adapter, recommended; B/C rejected)
- `matlab/phase5/` new files only: `phase5_registry.m`, `phase5_import.m`, `phase5_ct.m`, `phase5_curve.m`, `phase5_pickup.m`, `phase5_time.m`, `phase5_coord.m`, `phase5_duty.m`, `phase5_sensitivity.m`, `phase5_validate.m`, `phase5_tcc.m`, `phase5_writer.m`, `phase5_gate.m`, `run_phase5_production.m`, `run_phase5_tests.m`.
- `matlab/tests/test_phase5_*.m` new test files only.
- `results/phase5_protection/` new outputs only (+ `plots/`).
- Rejected B (live re-solve Phase-4 per calc — violates freeze, risks divergence). Rejected C (spreadsheet/manual — untestable, no regression).

## 4. Components
1. **Registry** (`phase5_registry.m`): device_id, device_type, equipment/location, ANSI_function, zone, CT_ratio, CT_source, rated I, Vnom, fault_input_source, pickup, TMS, curve_family, EF pickup/TMS, breaker_ref, upstream/downstream, provenance, status, assumption_class. Only SLD-proven equipment: B22 gen bus, GSUT, 230-kV GIS (Q0=52-1 breaker; Q1/Q2/Q9=disconnectors; Q51/Q52/Q8=earthing), South line, B230_REMOTE. No invented relay models/manufacturers; ANSI 51/51N/50/50N study functions.
2. **Import** (`phase5_import.m`): 2 cases × 5 locs × 4 types backbone from production currents CSV (Ikpp stage); F1=F2 same-node labels kept distinct; F4 m=0.5 primary + m-section sensitivity; sensitivity legs fenced, never merged.
3. **CT** (`phase5_ct.m`): `I_relay = I_primary / CT_ratio`, ratio recorded per row. Primary 15000/1 (Siemens protection report); legacy 16000/1 fenced sensitivity. Generator ref 458 MVA/22 kV/12019 A/PF0.85 (physical ref only; 360 MW = operating point, not nameplate).
4. **Curves** (`phase5_curve.m`): single centralized IEC inverse-time formulation `t = TMS * k / ((I/Is)^alpha - 1)` (+ definite-time/instantaneous), constants + units + doc, testable, no scattered literals.
5. **Pickup/time** (`phase5_pickup.m`, `phase5_time.m`): pickup records SETTING/UNIT/BASIS/SOURCE/VALIDATION; considers pre-fault load, 12019 A rated, fault range, CT, downstream, min-detect, no-trip-on-load, margin. No tuning-to-pass.
6. **Coordination** (`phase5_coord.m`): topology-built hierarchy; per pair: I_down, I_up, t_down, t_up, margin `dt = t_up - t_down`, PASS/FAIL + reason. Numerical margin, not visual.
7. **TCC** (`phase5_tcc.m`): publication plots with device/function/CT/pickup/TMS/curve + pickup points + fault markers; split figures when crowded; no fabricated manufacturer.
8. **Duty** (`phase5_duty.m`): separate from coordination; symmetrical RMS through-current vs documented rating only; peak/asymm only with X/R-kappa project data; no IEC-compliance claim. 50-kA estimated ref vs F3 LLL 50.53 kA = numerical comparison only, no PASS/FAIL without rating+duty basis.
9. **Sensitivity/provenance** (`phase5_sensitivity.m` + ledger): PRIMARY/SENSITIVITY/LEGACY/ENGINEERING_ASSUMPTION/MISSING/SOURCE-BACKED/DERIVED/NOT-DETERMINABLE labels; 15k-vs-16k min case; neutral-impedance counted once (3ZN zero-only; phase vs I0 vs secondary distinguished).

## 5. Data flow
SOURCE DATA → FAULT CURRENT (Phase-4 import) → PROTECTION INPUT (CT) → SETTING BASIS → OPERATING TIME → COORDINATION CHECK → RESULT. Never reverse-engineered from desired PASS.

## 6. Error handling
Missing param → mark NOT DETERMINABLE FROM AVAILABLE DATA; qualified assumption only as fenced sensitivity. No missing→invented promotion. Phase-4 import mismatch → hard error. Coordination shortfall → honest FAIL + conflict note.

## 7. Testing
`run_phase5_tests.m` + `test_phase5_*.m`: 15 required legs (CT conversion, pickup conversion, time calc, earth-fault, inverse behaviour, instantaneous, margin, duty, min-detect, max-duty, sensitivity, source/legacy separation, topology mapping, 2×5×4 coverage, no-double-neutral) + Phase-4 regression (import identity). Loud failures on change. MATLAB-run only (`matlab -batch`).

## 8. Outputs
`results/phase5_protection/`: phase5_device_registry.csv, phase5_relay_settings.csv, phase5_fault_inputs.csv, phase5_relay_currents.csv, phase5_coordination_matrix.csv, phase5_coordination_margins.csv, phase5_breaker_duty.csv, phase5_sensitivity.csv, phase5_validation.csv, manifest.json, sha256.txt, run_log.txt, plots/*.png, PHASE5_FINAL_REPORT.md (19 sections), quality-gate record. No Phase-4 overwrite.

## 9. Spec self-review
No TBD/TODO; no contradictions (F1=F2 labels vs same node kept; ip borrowed-shape peak labelled design-defined, not IEC); single-plan scope (protection only — stability/AVR/SFC excluded); no ambiguous column (every CSV schema fixed in plan Task T17).

## 10. Handoff
Implementation via `docs/superpowers/plans/2026-09-19-phase5-implementation.md`, subagent-driven, 20 tasks, MATLAB validation each task.
