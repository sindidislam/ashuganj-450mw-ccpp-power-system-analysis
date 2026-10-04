# Task 2 — independent review

## Verdicts

- **Specification compliance: PASS for the specified canonical/default, data-only deliverables.** This does not approve every accepted override; the validation gaps below remain.
- **Code quality: CHANGES REQUESTED before downstream consumption**, for R1–R2. No master integration or dynamic-response implementation is requested.

## Scope and evidence

Read the [brief](task-2-brief.md), [report](task-2-report.md), and all four current new MATLAB files. The worker package was absent, so created [task-2-review-package.txt](task-2-review-package.txt) containing their full byte-preserved contents, lengths and SHA-256 hashes; all four embedded snapshots were checked against unchanged inputs. There are no original-file diffs. Directly used metadata helpers and relevant canonical generator records were consulted only to trace validation/provenance.

Accepted the supplied **26 new grouped contract cases / 765 targeted total passing** evidence; no tests were run or logs re-audited. No subagents, source-PDF reads, runtime/test edits, or unrelated-file audit. Counterexamples below are static code traces, not executed reproductions.

## Findings

### R1 — Medium: unrecognized/non-primary source status is promoted to verified

[`source_record()`](../../../matlab/data/ashuganj_phase2_systems.m:186) selects qualified status for only two conditions and otherwise unconditionally assigns primary-verified status to both public status fields. [`validate_generator()`](../../../matlab/data/ashuganj_phase2_systems.m:99) checks numeric consistency but not eligibility of source statuses.

Concrete counterexample: keep the canonical generator values and change only [`G.f_Status`](../../../matlab/data/ashuganj_phase2_systems.m:94) to LEGACY. Generator validation still accepts the positive frequency; the [metadata constructor](../../../matlab/data/phase2_parameter.m:21) accepts that nonempty status; the output frequency becomes PRIMARY_VERIFIED while its retained raw record says LEGACY. This is promotion of an explicitly declared weaker status, not the separate problem of authenticating edited source documents. Default canonical records map correctly, but the fallback is unsafe.

**Required:** explicitly map recognized primary statuses and reject or preserve weaker/unknown statuses; do not default them to verified. Add a focused regression case when implementation work resumes. Existing [source-identity coverage](../../../matlab/tests/test_phase2_systems.m:69) exercises only canonical statuses.

### R2 — Medium: charger load-budget validation omits the bus-voltage current ceiling

The [cross-field checks](../../../matlab/data/ashuganj_phase2_systems.m:160) establish charger rated-power capability at float voltage, then compare peak load only with rated kW and battery discharge current. They do not establish that one duty charger covers the accepted load at lower bus voltage, despite the [stated charger-coverage check](../../../matlab/tests/test_engineering_assumptions.m:103).

Concrete accepted selections, updating both payload and selected value: [`charger_max_current_A`](../../../matlab/data/engineering_assumptions.m:52) = 165 A, [`load_trip_kW`](../../../matlab/data/engineering_assumptions.m:62) = 3 kW, [`load_close_kW`](../../../matlab/data/engineering_assumptions.m:64) = 5 kW, and [`load_emergency_additional_kW`](../../../matlab/data/engineering_assumptions.m:66) = 8 kW. All remain within their existing assumed ranges. Peak demand is 18.4 kW; 165 A × 123.75 V = 20.419 kW passes the float check, and 18.4 kW / 105 V = 175.24 A passes the battery limit. Yet the charger can supply only **17.325 kW at 105 V** (18.15 kW at nominal 110 V), below that peak.

**Required:** either enforce charger-only coverage against both current and power ceilings over the declared service-voltage envelope, or explicitly classify such configurations as requiring battery assistance rather than treating the rating-only check as coverage. This is a static data-contract issue; no response simulation is needed. The existing [charger rejection case](../../../matlab/tests/test_phase2_systems.m:197) covers only insufficient current at float. Defaults are unaffected: 12.4 kW is below the default 18.9 kW current-limited capability at cutoff.

### R3 — Low: interrupted report handoff is incomplete

The [Central catalog section](task-2-report.md:118) ends after its introductory paragraph, without the advertised mapping table. The [package description](task-2-report.md:112) promises report/catalog/harness/log content that was absent and is not part of this four-file fallback. The fallback header states its actual scope. Complete or correct those report claims during follow-up; the central registry itself remains available and readable.

## Checked without additional findings

- [Central registry](../../../matlab/data/engineering_assumptions.m:9): 72 stable, uniquely mapped records; finite real values and containing finite ranges; explicit academic status, basis, locator and selected value. Required AVR 200/0.02/0.5, ±5 limits, OEL 1.075, stator 1.0, SFC 0.97/0.03, battery 110 V/55 cells/200 Ah/0.05 ohm, charger 20 kW/two duty-standby units/0.925, and governor 0.05/0.2/0.75 match the brief. Additional gains, times, references, limits and positive separate loads are centralized.
- [Component assembly](../../../matlab/data/ashuganj_phase2_systems.m:23): six distinct objects; source type/designation Static/SEMIPOL; original evidence retained; manual curve extraction remains qualified, with no local-inspection claim. Abstract no-load/rated-field references remain separate from 122 V and unresolved physical field resistance. The 1876 A starting OUTPUT current is not DC current or an inferred converter power rating.
- [Station configuration](../../../matlab/data/ashuganj_phase2_systems.m:58): default OCV/SOC/cutoff and finite current limits are coherent; float is distinct from nominal voltage; full-SOC overcharge prevention is explicitly a future policy, not implemented behavior. Field, SFC, station DC and frozen auxiliary accounting remain separated.
- [Readiness](../../../matlab/data/ashuganj_phase2_systems.m:79): exact primary sixth-order inputs and existing single-conversion resistance are selected; 0.2608 and saturated 0.2248 remain separate. PSS stays disabled/untuned; unresolved damping/OCC/field base are not fabricated. [Override validation](../../../matlab/data/ashuganj_phase2_systems.m:124) otherwise checks complete keys, metadata, units/paths, shape, finite containing ranges and selected-value equality, with useful OEL/SOC/OCV checks.
