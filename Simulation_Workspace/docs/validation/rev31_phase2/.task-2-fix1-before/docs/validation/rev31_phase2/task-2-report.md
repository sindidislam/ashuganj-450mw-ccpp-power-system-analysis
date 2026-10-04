# Phase 2 Task 2 — central assumptions and isolated subsystem data

**DONE — Task 2 only.** Implemented against the approved [Task-2 brief](task-2-brief.md). Baseline 915/0 and four LF cases, and Task-1 acceptance, were supplied as completed prerequisites; neither was repeated or changed. No subagents, Git operations, master integration, solver/build changes, LF solves, dynamic components, or later tasks.

## Deliverables and scope

Exactly four new MATLAB files:

- [`engineering_assumptions.m`](../../../matlab/data/engineering_assumptions.m): 72 finite academic parameter records.
- [`ashuganj_phase2_systems.m`](../../../matlab/data/ashuganj_phase2_systems.m): six separate metadata-only component objects.
- [`test_engineering_assumptions.m`](../../../matlab/tests/test_engineering_assumptions.m): nine grouped contract cases.
- [`test_phase2_systems.m`](../../../matlab/tests/test_phase2_systems.m): 17 grouped contract cases.

Everything else added is Task-2 evidence in this directory. All **976 pre-existing files match their start SHA-256 hashes**, including source documents, Task-1 files/evidence, master, suite runner, solver, builders, grid/transformer/load providers, Rev2, history, and editor configuration. No pre-existing file was edited. Because there are no modified originals, no replacement backups were needed; the [start inventory](task-2-start-hashes.csv) and [verification log](task-2-verification.log) establish the boundary. Both tests match their [pre-implementation hashes](task-2-test-first-hashes.csv).

MATLAB writes used the four new Task-2 PowerShell writer scripts, with direct UTF-8 terminal writes and exact readback comparisons. No formatter/configuration edit. The writers are editing evidence, not ordinary runtime dependencies; do not replay them over future work.

## Exact public signatures and override contract

1. [`A = engineering_assumptions()`](../../../matlab/data/engineering_assumptions.m:1): no arguments; scalar structure keyed by stable parameter names. Full key-to-component mapping, selected values, units, ranges and reasons are in section **Central catalog** below and the machine-readable [catalog](task-2-assumption-catalog.csv).
2. [`S = ashuganj_phase2_systems(G,A)`](../../../matlab/data/ashuganj_phase2_systems.m:1): both arguments optional by omission. No arguments obtains canonical generator and default assumptions; one obtains default assumptions. The first argument is the scalar [`ashuganj_generators()`](../../../matlab/data/ashuganj_generators.m:1) result, **not the master**. The second is the entire registry, not a partial override structure.
3. [`[np,nf] = test_engineering_assumptions()`](../../../matlab/tests/test_engineering_assumptions.m:1).
4. [`[np,nf] = test_phase2_systems()`](../../../matlab/tests/test_phase2_systems.m:1).

Every modeled numeric/logical value is a metadata record. Consumers read [`value`](../../../matlab/data/phase2_parameter.m:20), not the record itself. Required common fields are [`value, unit, source, source_locator, status, confidence, rationale, assumption_basis, reasonable_range, assumed_range, selected_value, source_status, derivation, interpretation_status`](../../../matlab/data/phase2_parameter.m:20). Registry records additionally expose [`assumption_key, component_path`](../../../matlab/data/engineering_assumptions.m:8).

Overrides must update both [`value, selected_value`](../../../matlab/data/ashuganj_phase2_systems.m:117), retain shape, units, key and component path, retain the registry's reasonable range, and provide containing assumed ranges and complete metadata. Assumed ranges may change within the reasonable range. Missing/extra keys, nonfinite values, mismatched selected values, remapped fields or promoted assumption statuses are rejected. Cross-field checks additionally reject unreachable OEL thresholds, reversed OCV, unusable initial SOC, insufficient charger rating/current, or an over-budget load set. Tests exercise an inclusive range boundary and two valid injected overrides.

Errors: [`ashuganj_phase2_systems:InvalidGenerator`](../../../matlab/data/ashuganj_phase2_systems.m:104), [`ashuganj_phase2_systems:InvalidAssumptions`](../../../matlab/data/ashuganj_phase2_systems.m:131), and [`ashuganj_phase2_systems:InconsistentConfiguration`](../../../matlab/data/ashuganj_phase2_systems.m:169). This is a canonical data-provider interface, not a general source-verification API. Generator values must agree with their supplied primary/provenance records; arbitrary edited source claims are not independently authenticated.

## Status, ranges and provenance

- NEW records use PRIMARY_VERIFIED, PRIMARY_SOURCE_QUALIFIED or ENGINEERING_ASSUMPTION. HISTORICAL/LEGACY remain available hierarchy categories but no new historical/legacy model parameter is selected.
- Direct existing primary transcriptions map to PRIMARY_VERIFIED. Existing qualified interpretations and derived machine resistance map to PRIMARY_SOURCE_QUALIFIED. This is vocabulary normalization, **not fresh attachment inspection or an upgrade of the preserved raw evidence**.
- Source records retain the entire previous record in [`raw_source`](../../../matlab/data/ashuganj_phase2_systems.m:189); original [`raw_provenance`](../../../matlab/data/phase2_source_data.m:31) remains alongside it wherever originally present. Raw evidence retains its historical status strings unchanged.
- Curve leaves use PRIMARY_SOURCE_QUALIFIED with [`qualification`](../../../matlab/data/ashuganj_phase2_systems.m:228) PRIMARY_SOURCE_EXTRACTED. The complete original curve remains under [`excitation.uel.curve.raw_source`](../../../matlab/data/ashuganj_phase2_systems.m:212), including manual user extraction and the false local-inspection flag.
- Academic ranges are screening/sensitivity choices, not measured confidence intervals or plant tolerances. A source scalar receives a fixed selected-value interval; a source array receives its numeric extent. Their [`range_basis`](../../../matlab/data/ashuganj_phase2_systems.m:201) explicitly rejects interpreting these as measurement uncertainty or operating permission. Categorical type/designation records have empty numeric ranges, marked not applicable.

## Task-3 configuration handoff

Top-level objects are [`excitation, sfc, stationDC, governor, pss, dynamicReadiness`](../../../matlab/data/ashuganj_phase2_systems.m:5). Each has a distinct text identity. All assumption-backed leaf paths are exhaustively enumerated in the Central catalog; **do not recreate constants in Task 3**. Full text policy/descriptor fields are in the [component assembly](../../../matlab/data/ashuganj_phase2_systems.m:35).

### Excitation and limiter bases

- [`excitation.type, excitation.designation, excitation.no_load_voltage_V`](../../../matlab/data/ashuganj_phase2_systems.m:38) are source records: **Static / SEMIPOL / 122 V**. The implemented configuration is generic, not an identified SEMIPOL controller.
- AVR: gain **200 pu/pu**, lag **0.02 s**, field-response lag **0.5 s**, signed command limits **−5/+5 Efd pu**, terminal-voltage reference **1 pu**. States are bounded lags, not an unbounded hidden integrator; Task 3 must implement and test the described state policy.
- **Efd no-load normalization = 1 abstract pu; assumed rated-field proxy = 2.5 Efd pu.** OEL acts on Efd divided by that 2.5 reference, threshold **1.075 rated-field pu**, equivalent to **2.6875 Efd pu**. Its finite response is **1 s**, gain **5 Efd pu/rated-field pu**. This is not measured field current. **122 V does not define the Efd base. No physical Rf base or volts/amperes conversion exists.** Tests change the source no-load voltage and raw field resistance and verify model reference independence.
- UEL: **5 MVAr inset** above piecewise-linear source lower-Q boundary, **0.1 s** lag, **0.05 Efd pu/MVAr** gain. Source arrays are metadata leaves [`excitation.uel.curve.P_MW, Qmin_MVAr, Qmax_MVAr`](../../../matlab/data/ashuganj_phase2_systems.m:214); use their values or the untouched raw source with the existing interpolator. No curve clipping or extrapolation. Reject requests outside source domain/primary dispatch applicability; report infeasible inset rather than clipping at the zero-width source tip.
- Stator threshold **1.0 current pu** on primary machine S/V base, **0.2 s** response and gain **5 Efd pu/current pu**. Active-current overload requires dispatch action, not excitation repair. Common correction magnitude limits **0–5 Efd pu**. All gains, references, limits and times have central records. Limiter coordination/conflicts are explicitly unvalidated.

### SFC

[`sfc.dc_link_kV, sfc.max_starting_output_A`](../../../matlab/data/ashuganj_phase2_systems.m:53) retain **2.28 kV DC_LINK** and **1876 A OUTPUT** with original evidence and side labels. Efficiency **0.97**, lag **0.03 s**, output-power range **0–4 MW**, with 4 MW explicitly separately assumed. It is **not** 2.28 kV times 1876 A. No DC-current value or electrical connection to field/battery is inferred. Input power accounting is output divided by efficiency; it is not added to frozen LF loads.

### Station DC, battery, charger and loads

- Battery nominal **110 V**, **55 cells**, **200 Ah**, **0.05 ohm whole-bank resistance**. Linear OCV endpoints **105–116 V** over SOC **0–1**. Usable SOC **0.2–1**, initially **1**, terminal cutoff **105 V**. Finite discharge/charge limits **200/40 A**, coulombic charge efficiency **0.9**. Positive current discharges; terminal voltage equals OCV minus current times bank resistance. Stop discharge on either SOC or terminal cutoff. No electrochemical, aging or DC fault claim.
- Charger nominal service **110 V**, **20 kW DC output each**, **two units**, **one active duty unit**, standby replaces rather than adds. Efficiency **0.925**, float **123.75 V = 2.25 V/cell**, current range **0–180 A**, response **0.1 s**, voltage-error gain **50 A/V**. Both current and power ceilings apply. At float, 20 kW requires about **161.616 A**, below 180 A. AC input at full DC output is about **21.622 kW**. This is not a 110 V ideal voltage source.
- The simple OCV model does not reproduce float polarization. At full SOC, charger logic must supply load only and prevent overcharge; it must not force a 123.75 V/116 V mismatch through bank resistance as unlimited charging. This is an explicit Task-3 policy, not a dynamic behavior already implemented here.
- Continuous assumed loads, kW: relay **0.3**, control **0.5**, instrumentation **0.4**, communications **0.2**, emergency-control electronics **0.3**, excitation auxiliary electronics **0.7**. Total **2.4 kW**. Excitation electronics are **not generator field power**.
- Additional trip pulse **2 kW for 0.2 s**; close pulse **3 kW for 0.5 s**; emergency switched demand **5 kW** for caller-selected scenario duration. Simultaneous continuous/emergency/both-pulse peak **12.4 kW**, below one duty charger. About **118.095 A** at cutoff is below the 200 A discharge bound. These arithmetic checks are data plausibility, not a battery runtime simulation.
- The station is isolated: no station DC/field/SFC connection is inferred. No DC or charger AC power is added to the frozen **14 MW** auxiliary demand; overlap remains unresolved.

### Governor, PSS and machine readiness

Governor droop **0.05**, governor lag **0.2 s**, turbine lag **0.75 s**, speed reference **1 pu**, turbine gain **1**, minimum mechanical power **0 MW**. [`governor.max_power_MW, governor.power_base_MVA`](../../../matlab/data/ashuganj_phase2_systems.m:74) reuse source **360 MW / 458 MVA** as screening bound/power-pu base, not verified turbine limits.

PSS: **disabled**, generic and untuned; gain **10**, washout **10 s**, two lead/lag pairs **0.1/0.02 s**, output bounds **±0.05 terminal-voltage pu**. Disabled selection has fixed zero ranges. No final PSS dynamics or tuning is executed.

Exact machine input record keys under [`dynamicReadiness.machine`](../../../matlab/data/ashuganj_phase2_systems.m:88):

[`Snom_MVA, P_capacity_MW, Vnom_kV, H_s, Ra_ohm, Ra_pu_machine, Xd, Xdp, Xdpp, Xq, Xqp, Xqpp, Xl, Td0p_s, Td0pp_s, Tq0p_s, Tq0pp_s`](../../../matlab/data/ashuganj_phase2_systems.m:18).

These preserve **458 MVA, 360 MW, 22 kV, H=5.287 s, Ra=0.00089 ohm**, existing single-conversion machine-pu resistance, **Xd=1.783, Xdp=0.3256, Xdpp=0.2608, Xq=1.751, Xqp=0.5087, Xqpp=0.2593, Xl=0.2027**, and open-circuit time constants **7.547/0.045/0.839/0.070 s**. Standard sixth-order selection never substitutes saturated Xdpp.

Separate records [`dynamicReadiness.saturation.Xdpp_sat, S10, S12`](../../../matlab/data/ashuganj_phase2_systems.m:92) retain **0.2248 / 0.0865 / 0.408**; they are not a full measured OCC. [`dynamicReadiness.frequency_Hz`](../../../matlab/data/ashuganj_phase2_systems.m:96) retains source **50 Hz**. Damping, detailed rotor parameters and physical field base remain unresolved descriptors, not fabricated zero/finite machine inputs. Readiness is data-only, not final dynamic validation.

## Requirement disposition

All eight Task-2 checklist items are addressed: complete metadata/ranges/identities; RED before implementation; required excitation/limiter defaults; SFC separation and finite assumptions; station/charger finite values; positive separate continuous/pulse/emergency demands; exact primary sixth-order readiness plus governor/disabled PSS; targeted tests and central-record coverage. The brief's scope does not require component step functions, operating-point enforcement, or battery/charger simulation in this task. Those are not implemented or claimed.

## Verification and exact commands

MATLAB **24.1.0.2537033 (R2024a)**, Windows 11, 2026-09-16. Tests report **grouped contract cases** for new files, not one inflated count per field/range check. Existing suites report individual recorder assertions. The combined total is stated with that distinction.

| Execution | Assumptions | Systems | Capability | Generator | Base | Result |
|---|---:|---:|---:|---:|---:|---|
| Actual [RED](task-2-red.log) before either runtime existed | 0/9 | 0/17 | — | — | — | All new cases failed for absent interfaces |
| Initial targeted [GREEN](task-2-green.log) | 9/0 | 17/0 | — | — | — | 26/0; success marker |
| Final targeted [regression GREEN](task-2-regression-green.log) | 9/0 | 17/0 | 224/0 | 476/0 | 39/0 | **765/0; process exit 0** |

Final log PASS/FAIL lines were independently recounted: 765/0 = **26 new contract cases + 739 existing assertions**. This is **not** a complete repository suite or a new 915-test baseline. No LF, protection, sequence or dynamic integration test ran.

RED's checks execute real providers, catch the missing-interface errors and record failures; they do not manufacture mocks. Both tests are byte-identical from RED through final GREEN. Cases cover exact defaults, recursive record contracts, raw provenance, no-field-base coupling, source current sides, primary/saturated separation, complete registry-to-component mapping, overrides/boundary, eight malformed record variants, SOC/OCV, OEL and charger inconsistencies, invalid generator and unchanged caller inputs.

The first [regression attempt](task-2-regression.log) stopped after the new and capability tests passed: the narrow path omitted the existing data/assumptions directory needed by the generator test's master call. Corrected only the new verification harness to add the full MATLAB tree, retained the failed log, then reran all five suites. No production/test edit was made for this harness issue.

Exact final command from workspace root: [`powershell -NoProfile -ExecutionPolicy Bypass -File docs/validation/rev31_phase2/task-2-verify.ps1`](task-2-verify.ps1:1). The script contains the full MATLAB batch, analyzer, catalog export, exact expected counters, log recount and hash checks. The executable is MATLAB R2024a under Program Files. The compact package also carries literal standalone RED/GREEN commands for copy/paste.

For a non-writing targeted rerun from MATLAB with workspace root current, execute [`addpath(genpath('matlab')); [a,b]=test_engineering_assumptions(); [c,d]=test_phase2_systems(); assert(isequal([a b c d],[9 0 17 0]));`](../../../matlab/tests/test_phase2_systems.m:1). Add [`[e,f]=test_generator_capability(); [g,h]=test_generator_data(); [i,j]=test_base_conversion(); assert(isequal([e f g h i j],[224 0 476 0 39 0]));`](../../../matlab/tests/test_generator_capability.m:1) for existing targeted regression.

Code Analyzer: **three non-blocking advisories**, not lint-clean: one scalar-length performance suggestion in component path insertion and two sort/transpose suggestions in subsystem tests. All four files parsed and the tested runtime paths executed. Full IDs/lines appear in the regression log.

## Direct review and limits

Direct self-review checked brief/defaults, metadata/ranges, no hidden numeric component assumptions, exact source metadata retention, OEL reference separation, isolated power/current domains, charger/battery budget and frozen file hashes. No independent/subagent review is claimed. No blocking defect was found for Task-2 data scope.

All new assumption leaves are exact central records; source numeric leaves are source-backed and explicitly ranged. Qualitative identity/policy strings are descriptors, not tunable numeric parameters. Additional future component equations must obtain new numeric selections from this registry rather than adding hidden constants.

This is an academic configuration, not plant calibration. In particular curve uncertainty, field base, damping/OCC, limiter coordination, float polarization, battery aging and dynamic tuning remain unresolved or simplified. Source scalar ranges are selection constraints, not evidence of zero source uncertainty.

## Review package

[`task-2-review-package.txt`](task-2-review-package.txt) contains **full unabridged copies of the four new MATLAB files**, their byte counts/hashes, this report, catalog, exact verification harness, full Task-2 RED and initial GREEN logs, final targeted regression log, and compact scope-verification evidence. The failed regression-path diagnostic is included as an explicitly labeled excerpt. No prior giant review package, original source document, or historical dump is embedded. Section byte counts permit exact extraction/verification.

**Stop at Task 2.** Master/runner integration and Task-3 component functions remain untouched.

## Central catalog

The following table is generated from the executed registry. All rows are ENGINEERING_ASSUMPTION. Ranges are in the stated unit; selected vectors retain their shape. Each component path denotes a record, whose numeric payload is its value field. Fixed ranges are intentional approved selections, not missing values.
