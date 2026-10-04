# Phase 6 parameter provider implementation

Completed 2026-09-22 in `C:/Users/sindi/Downloads/306 Power Project -kimi k3`.

`scripts/init_phase6_parameters.m` now supplies the required scalar `P` without writing output files or running upstream models. It calls `setup_phase6_workspace` and returns unchanged canonical generator, transformers, lines, grid, loads, engineering assumptions, and Phase 2 systems metadata. The transformer registry already supplies derived SPS winding R/L, magnetizing values, core selection and saturation choices, so no second conversion or reconstructed transformer data was introduced.

Frozen Phase 3 summary and bus tables are loaded with preserved variable names. `P.reference.primary` selects exactly one `LF360_GAT_OUT` summary row, enforced by an assertion. The Phase 5 settings, device, trip, fault-current and relay-current tables are loaded under the required `P.protection` fields. `P.protection.parameters` contains the entire frozen `phase5_parameter_values.csv` table, without regeneration or edits.

## Builder interface

| Field | Value / behavior |
|---|---|
| `P.f_Hz` | 50 |
| `P.Sbase_VA` | 100e6, reporting/network base |
| `P.TsElectrical` | 50e-6 s, explicit numerical assumption |
| `P.TsControl` | 0.001 s, explicit numerical assumption |
| `P.numericalShunt_W` | 10 W, numerical assumption rather than installed load |
| `P.machine.Sn_VA`, `.Vn_V` | 458e6 VA and 22000 V line-to-line RMS |
| `P.machine.Rs_pu` | 0.000842190082644628 from 0.00089/(22²/458) |
| `P.machine.reactances_pu` | `[1.783 .3256 .2608 1.751 .5087 .2593 .2027]`, order Xd Xdp Xdpp Xq Xqp Xqpp Xl |
| `P.machine.timeConstants_s` | `[7.547 .045 .839 .07]`, open-circuit Td0p Td0pp Tq0p Tq0pp |
| `P.machine.H_s`, `.damping_pu`, `.polePairs` | 5.287 s combined train inertia, zero assumed damping, one pole pair |
| `P.machine.P_W`, `.Vref_pu` | Frozen 360e6 W dispatch; canonical assumption voltage reference 1 pu |
| `P.scenario.networkProfile` | `PHASE3_BASELINE` by default; runner may explicitly choose `PHASE5_STUDY` |
| `P.scenario.faultResistance_ohm`, `.groundResistance_ohm` | Both 0.01 ohm, declared engineering numerical assumptions |

All other required scenario defaults match `PARAMETER_TASK_BRIEF.md`: normal/no fault, `3PH`, `GIS230`, fault start 1 s, duration 0.15 s, stop 2 s, protection/battery/charger enabled, DC loss/restore times Inf, GAT out.

The normalized machine uses the canonical unqualified Xdpp value 0.2608 under its retained unsaturated study interpretation, with saturation qualification recorded. Saturated Xdpp=0.2248 remains visible in the unchanged canonical generator and frozen Phase 5 parameters; it is not silently substituted into the normalized vector. Round rotor and open-circuit time-constant options must be selected by the builder.

`P.generator.Rf_numeric=0.10631` and its unresolved unit/field-base metadata remain intact. No normalized `P.machine.Rf_pu` is created. The register labels this numeric source entry `PLACEHOLDER_NOT_FOR_FINAL_RESULT` and explicitly states that it is unresolved and unused. Fault switch resistance is a different quantity.

## Provenance and export

`P.register` has `Parameter`, `Value`, `Unit`, `Classification`, `Source`, and `Notes`. Values are text to preserve scalars, vectors, categorical values, Inf, and missing NaN values in one CSV-compatible column. It includes raw generator provenance, every normalized machine input, all canonical academic assumption records, numeric/categorical network registry inputs, all frozen Phase 5 parameter rows, relay setting/CT rows, and scenario/numerical choices.

Only the five requested classifications are used. Original source statuses, qualifications and derivations remain in the notes. The estimated canonical grid is not promoted to verified PGCB data. Phase 5 manufacturer-default study values are `USER_ASSERTED`. Derived Phase 5 values with mixed assumed/source lineage are conservatively classified as engineering assumptions while preserving their exact original `DERIVED` status and equation. Individual CT source classifications remain visible in their Phase 5 parameter rows; combined relay setting rows retain the full frozen provenance text.

`scripts/phase6_write_parameter_register.m` is the explicit writer:

```matlab
P = init_phase6_parameters();
P.scenario.networkProfile = 'PHASE5_STUDY'; % explicit runner selection
phase6_write_parameter_register(P, outputCsv);
```

With no output path it writes `Phase6/results/phase6_parameter_register.csv`. It refreshes scenario register entries from the selected `P.scenario` before export, so overrides do not export stale initializer defaults. It does not mutate the caller's data. To read the mixed `Value` column back in MATLAB, explicitly set its import type to string; automatic detection may infer numeric from the early rows.

The provider does not implement the network-profile switch itself. The builder/runner owns that switch. Canonical `P.grid` remains the Phase 3 50 kA estimated grid with R=0; the frozen Phase 5 table separately contains its 45.01 kA / X/R 10.99 screening equivalent. Phase 3's R=0 is restricted to the balanced baseline and must not acquire an unqualified fault/DC-offset interpretation. Grounding topology, actual controller integration, electrical initialization and dynamic network validation remain the network implementation's responsibility. See `GROUNDING_REVIEW.md` for sequence-equivalent and CT-boundary considerations.

## Verification evidence

The active task-local MATLAB R2024a worker ran all jobs after clearing the provider, writer and test functions and calling `rehash`. No additional MATLAB process or UI session was started.

- `logs/jobs/jobGroundingParamRed.m.log`: expected assertion that the central provider was missing, before implementation.
- `logs/jobs/jobGroundingParamGreen.m.log`: initial provider contract test passed.
- `logs/jobs/jobGroundingParamOverrideRedFix.m.log`: expected assertion that export must capture selected scenario overrides, before the writer correction. An earlier test attempt exposed automatic CSV type inference; the test import was fixed to request string values before this meaningful red run.
- `logs/jobs/jobGroundingParamOverrideGreen.m.log` and `.done`: final full test **PASS**, `success=true`, finished 22-Sep-2026 08:44:06.

The final test checks exact canonical struct identity; independent Rs/reactance/time-constant arithmetic; primary-row uniqueness and dispatch; unchanged Phase 3 grid with the separate full Phase 5 table; scenario defaults; numerical assumptions; allowed classifications; unique register names; all assumption and Phase 5 parameter coverage; unresolved/unused Rf; explicit CSV export including overridden scenario values; and unchanged SHA-256 hashes for the canonical generator, transformer, line, grid source files and frozen Phase 5 parameter CSV. Temporary export files are removed by the test.

Files delivered: `scripts/init_phase6_parameters.m`, `scripts/phase6_write_parameter_register.m`, `scripts/tests/test_phase6_parameters.m`, this report, and task-local worker verification jobs/logs. Upstream source files and production builder code were not edited.
