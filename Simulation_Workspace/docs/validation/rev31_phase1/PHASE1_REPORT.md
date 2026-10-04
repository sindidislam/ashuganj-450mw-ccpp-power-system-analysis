# REV3.1 Phase 1 — generator registry migration and live-data audit

**Scope:** generator data/registry and data tests only. No authorization or implementation of Phase 2 or later work. Source verification and baseline began 2026-09-14; implementation continued 2026-09-15.

## A. Exact existing files modified

1. [`ashuganj_generators.m`](../../../matlab/data/ashuganj_generators.m:1): existing authoritative equipment provider extended; explicit workbook PRIMARY record, derived compatibility/base views, source metadata, and saturated LEGACY record.
2. [`Ashuganj_Master_Data.csv`](../../../data/master/Ashuganj_Master_Data.csv): generator rows only; legacy rows retained, obsolete missingness labelled superseded, 40 primary/provenance rows appended. No non-generator record changed.
3. [`test_generator_data.m`](../../../matlab/tests/test_generator_data.m:1): new source-driven expectations and genuine-gap checks.
4. [`test_base_conversion.m`](../../../matlab/tests/test_base_conversion.m:42): distinct subtransient and armature-resistance conversions/inverses.
5. [`run_all_tests.m`](../../../matlab/tests/run_all_tests.m:19): comments only, removing obsolete quadrature-missing example.
6. [`t_case.m`](../../../matlab/tests/t_case.m:15): comments only, qualifying missingness by available source evidence. Recorder implementation unchanged.
7. [`missing_parameters.md`](../missing_parameters.md): generator missingness corrected; genuine gaps retained.
8. [`verified_parameters.md`](../verified_parameters.md): generator primary/legacy and capacity/reference distinctions.
9. [`generator_list.md`](../../model/generator_list.md): primary machine values, provenance/base interpretation and qualifications.

New files in this evidence directory are Phase 1 audit deliverables, not runtime registries. The exact pre-edit scope was recorded before implementation in [`planned_changes.txt`](planned_changes.txt). [`baseline_hashes.csv`](baseline_hashes.csv) records all 926 original files; [`file_integrity.csv`](file_integrity.csv) names every modified and unchanged file with before/after SHA-256.

## B. Exact files not modified

**917 of 926 pre-existing files are byte-identical.** Their exact names and hashes are the UNCHANGED rows of [`file_integrity.csv`](file_integrity.csv), rather than an abbreviated claim about directories.

This includes the master assembly/case definitions, all builders, load-flow analysis/solver paths, transformer/grid/load data and assumptions, topology tests, model tests, all Rev2 code/results/reports, all saved Simulink models/backups, source workbooks/PDFs, and historical reports/results. In particular: [`ashuganj_master_data.m`](../../../matlab/data/ashuganj_master_data.m), [`build_generator_system.m`](../../../matlab/build/build_generator_system.m), [`build_ashuganj_main.m`](../../../matlab/build/build_ashuganj_main.m), [`run_load_flow_study.m`](../../../matlab/studies/run_load_flow_study.m), and [`ashuganj_branch_flows.m`](../../../matlab/analysis/ashuganj_branch_flows.m).

No Git repository exists in this workspace. Full SHA-256 inventory and external original-file backups were used instead. No commits, branch changes, report rebuilds, saved-model rebuilds, or historical-result overwrites occurred.

## C–D. Executed tests and LF regression

| Run | Passed | Failed | Evidence |
|---|---:|---:|---|
| Unchanged complete baseline | 447 | 0 | [`baseline_tests.log`](baseline_tests.log) |
| New targeted expectations against old provider | 35 | 35 expected | [`red_tests.log`](red_tests.log) |
| First corrected generator/base/data/full run | 361 / 39 / 703 / 800 | 0 throughout | [`post_tests.log`](post_tests.log) |

Final strengthened run: **generator 476/0; base conversion 39/0; all data/master checks 818/0; complete ten-file suite 915/0**. Evidence: [final_tests.log](final_tests.log). The increased count is additional data/provenance coverage, not removed physics tests.

All four LF cases were freshly built in memory, with both result writing and model saving disabled. Comparison to the captured pre-change MATLAB results used exact missing-value-aware equality for complete bus tables, branch tables, residual tables, generator/export P/Q, system/branch losses, worst residual, iterations and verdicts. **All four matched exactly.** Timing and transient model handles were not comparison targets.

| Frozen case | Dispatch MW | MV voltage pu | Loss MW | Swing export MW | Verdict |
|---|---:|---:|---:|---:|---|
| LF1 | 389.30 | 1.000911168 | 0.816493662 | 374.483506233 | OK; exact baseline match |
| LF2 | 389.30 | 1.020279743 | 0.833419291 | 374.466580642 | OK; exact baseline match |
| LF3 | 342.01 | 1.000907610 | 0.680192057 | 327.329807893 | OK; exact baseline match |
| LF4 | 342.01 | 1.020818101 | 0.690257248 | 327.319742715 | OK; exact baseline match |

These remain historical comparison dispatches. LF1/LF2 exceed the newly registered 360 MW capacity and are **not** newly approved capacity-compliant primary operating cases. Their inputs and existing labels were explicitly frozen by Phase 1 instructions. No capacity enforcement was inserted yet.

## E. Authoritative generator values and source qualification

Authority remains source documents → existing master → existing generator provider. The CSV is a provenance ledger, not a second executable master. The provider does not read Rev2, source workbooks, or CSVs at runtime.

Primary dataset ID: GEN-R31-WORKBOOK-ROW3. Source: [`Ahsuganj South (2).xlsx`](../../../fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj%20South%20%282%29.xlsx), sheet **Ashuganj South** with exactly one trailing space, row 3. SHA-256: **6D4286B9D0B771CEE80FB305F3C0AE7B9D34CC1EA8A3B8F2F022BA0D07240A60**. Direct read-only ZIP/XML extraction confirmed the values, headings, merged groups and raw text before writing the registry. Numeric XML serialization is preserved as raw text; floating-point decimal tails are not different engineering values.

| Quantity | Primary value | Cell/source |
|---|---:|---|
| Apparent rating | 458 MVA | C3 |
| Active capacity | 360 MW | B3 |
| Nominal voltage | 22 kV | D3 |
| Combined turbine-generator inertia | 5.287 s | F3 |
| SCR | 0.601 | G3 |
| d-axis synchronous / transient / unqualified subtransient | 1.783 / 0.3256 / 0.2608 pu | H3 / I3 / J3 |
| Separate saturated d-axis subtransient | 0.2248 pu | K3 |
| q-axis synchronous / transient / subtransient | 1.751 / 0.5087 / 0.2593 pu | L3 / M3 / N3 |
| Leakage / negative-sequence / zero-sequence | 0.2027 / 0.2242 / 0.128 pu | O3 / P3 / Q3 |
| Raw armature resistance | 0.00089 ohm | U3 |
| Field resistance numeric only | 0.10631; unit/base unresolved | V3 |
| Open-circuit d transient / d subtransient / q transient / q subtransient | 7.547 / 0.045 / 0.839 / 0.070 s | Y3 / Z3 / AA3 / AB3 |
| Short-circuit constants in the same order | 1.213 / 0.035 / 0.214 / 0.035 s | AC3 / AD3 / AE3 / AF3 |
| Armature time constant, Ta or Ta(3) | 0.704 s | AG3 |
| Saturation coefficients at 1.0 / 1.2 pu | 0.0865 / 0.408 | AI3 / AJ3 |
| Excitation type / designation | Static / SEMIPOL | AS3 / AT3 |
| Rated/reference PF | 0.85 | Retained nameplate source |
| PF-derived/OEM reference | 389.30 MW | 458 × 0.85; retained Siemens reference |
| Qualified owner/site de-rated scenario | 342.01 MW | Retained owner form |

The canonical [`Xdpp`](../../../matlab/data/ashuganj_generators.m:61) and [`Xdpp_sat`](../../../matlab/data/ashuganj_generators.m:62) are distinct. Compatibility percentages derive from the canonical values. P3/Q3 remain explicitly SATURATED; unqualified source labels are not overstated as literal unsaturated declarations.

Reactance base is interpreted as 458 MVA / 22 kV, not claimed as an independently printed base declaration. H is combined train inertia. Field resistance retains the raw mixed heading and QUALIFIED interpretation; no field base or stator conversion is invented. Static/SEMIPOL does not establish control parameters. Two saturation coefficients do not establish a full measured OCC. The owner 342.01 MW boundary is unresolved, not silently designated net export or generator-terminal power. Generator earthing remains high-resistance NER 10BAB11; workbook AQ3 Solid Ground belongs to GSUT.

## F. Legacy retention

[`Legacy`](../../../matlab/data/ashuganj_generators.m:33) retains **1.663 / 0.2865 / 0.2248 pu**, explicitly designated **LEGACY / SATURATED SOURCE DATA**, not selected primary. Each legacy reactance carries the Siemens document, PDF p.1 / report p.6 §2.1.1 locator, raw percent interpretation, normalized pu, base, dataset designation and saturated qualifier. Existing 518 MVA cold-gas condition, nameplate current/frequency, negative-sequence capability and other source-backed supplementary fields remain.

## G. Base-conversion verification

| Quantity | Verified value |
|---|---:|
| Machine impedance base, 22²/458 | 1.056768558951965 ohm |
| Machine armature resistance | 0.000842190082644628 pu |
| 100 MVA / 22 kV impedance base | 4.84 ohm |
| System armature resistance | 0.000183884297520661 pu |
| Machine resistance × machine base | 0.00089 ohm |
| System resistance × system base | 0.00089 ohm |
| Unqualified subtransient ×100/458 | 0.0569432314410480 pu |
| Saturated subtransient ×100/458 | 0.0490829694323144 pu |

Tolerance is 1e-12 for the data conversion checks. Forward/inverse and machine/system round trips pass; saturated and unqualified results remain distinct. Existing transformer/grid conversion checks remain intact.

## H. Duplicate-value repository audit

[`occurrence_audit.csv`](occurrence_audit.csv) records every matched occurrence in the text scan, with value/parameter, exact file, line, column, one classification, active status, action and context. [`search_coverage.csv`](search_coverage.csv) inventories all 926 original files: 438 text-scanned and 488 initially binary. [`container_occurrences.csv`](container_occurrences.csv) additionally searches workbook/model XML read-only, including saved model artifacts.

The search includes all eleven requested numeric strings, alternate percent forms 166.3/28.65/22.48 and 389.3, and broad generator-parameter names/assignments. Broad matching deliberately includes unrelated angle/layout/rating words; these are not automatically generator errors. Text classifications total **5,547 occurrences**: 2,991 DOCUMENTATION; 1,208 HISTORICAL RESULT; 309 COMMENT; 276 PRIMARY LIVE CODE; 250 LEGACY CODE; 280 UNUSED/DEAD CODE; 233 TEST EXPECTATION. Container scan adds **315 occurrences**: 223 DOCUMENTATION and 92 HISTORICAL RESULT.

**Coverage limitation:** this is exhaustive for matched text and inspected workbook/model XML, not an assertion that PDF image contents, compressed archives, database binary records or raster images have been semantically enumerated. These files are inventoried/hash-protected; source PDF findings use the reviewed reconciliation. New audit outputs are excluded from the recursive scan to avoid self-replicating matches. No search result was globally replaced.

| Value / Parameter | File | Classification | Active? | Action |
|---|---|---|---|---|
| Workbook generator set | [`ashuganj_generators.m`](../../../matlab/data/ashuganj_generators.m:51) | PRIMARY LIVE CODE | Yes | Sole current primary machine transcription |
| 1.663 / 0.2865 / 0.2248 legacy set | [`ashuganj_generators.m`](../../../matlab/data/ashuganj_generators.m:33) | LEGACY CODE | Constructed, not selected | Retained saturated provenance |
| 0.2248 saturated primary | [`ashuganj_generators.m`](../../../matlab/data/ashuganj_generators.m:62) | PRIMARY LIVE CODE | Yes | Correct separate saturated field, not old unqualified input |
| 389.30 LF1 | [`ashuganj_master_data.m`](../../../matlab/data/ashuganj_master_data.m:16) | PRIMARY LIVE CODE | Yes | Frozen case input; migrate in Phase 2 |
| 389.30 LF2 | [`ashuganj_master_data.m`](../../../matlab/data/ashuganj_master_data.m:17) | PRIMARY LIVE CODE | Yes | Frozen case input; migrate in Phase 2 |
| 342.01 LF3/LF4 | [`ashuganj_master_data.m`](../../../matlab/data/ashuganj_master_data.m:18) | PRIMARY LIVE CODE | Yes | Frozen scenario interpretation; qualify boundary in Phase 2 |
| Case dispatch and nameplate reads | [`build_generator_system.m`](../../../matlab/build/build_generator_system.m:63) | PRIMARY LIVE CODE | Yes | Master-fed electrical inputs; no reactance inserted |
| 166.3 / 28.65 / 22.48 and obsolete missingness | [`build_generator_system.m`](../../../matlab/build/build_generator_system.m:28) | COMMENT | No calculation | Protected stale explanation; report, do not alter builder |
| Master/case data reads | [`build_ashuganj_main.m`](../../../matlab/build/build_ashuganj_main.m:145) | PRIMARY LIVE CODE | Yes | No independent machine registry |
| Obsolete missingness | [`sps_blocks.m`](../../../matlab/build/sps_blocks.m:42) | DOCUMENTATION | Metadata only | Stale explanation retained under builder freeze |
| Obsolete missingness/display semantics | [`gui_symbols.m`](../../../matlab/gui/gui_symbols.m:118) | DOCUMENTATION | GUI rendering | Reported; GUI not migrated |
| Generator source expectations | [`test_generator_data.m`](../../../matlab/tests/test_generator_data.m:32) | TEST EXPECTATION | Tests | Updated from verified source |
| Legacy LF dispatch expectations | [`test_topology.m`](../../../matlab/tests/test_topology.m:78) | TEST EXPECTATION | Tests | Frozen, unchanged |
| Independent workbook/saturated calculations | [`rev3_b1_derivations.m`](../../../matlab/studies/rev3_b1_derivations.m:45) | LEGACY CODE | Manually callable audit | Not a production data provider; retained |
| Independent saturated calculation | [`rev3_a4_numeric_checks.m`](../../../tmp/rev3_a4_numeric_checks.m:48) | UNUSED/DEAD CODE | Manual probe only | Not on current workflow path |
| Old generator source impedance calculation | [`rev3_plate_numeric_checks.m`](../../../tmp/rev3_plate_numeric_checks.m:112) | UNUSED/DEAD CODE | Manual probe only | Retained source-audit calculation |
| Old PF reference check | [`rev3_partA_checks.m`](../../../tmp/rev3_partA_checks.m:10) | UNUSED/DEAD CODE | Manual probe only | Retained source-audit calculation |
| Independent Rev2 generator data | [`ashuganj_rev2_registry.m`](../../../rev2/data/ashuganj_rev2_registry.m:16) | LEGACY CODE | Rev2-only callable | Frozen competing source; not adopted |
| Independent nonideal source and 354 MW | [`build_loadflow_v2.m`](../../../rev2/simulink/build_loadflow_v2.m:26) | LEGACY CODE | Rev2-only callable | Frozen dangerous alternate builder |
| Old values in saved outputs/models | [`system_summary.csv`](../../../results/load_flow/system_summary.csv), [`Ashuganj_South_Main.slx`](../../../simulink/main/Ashuganj_South_Main.slx) | HISTORICAL RESULT | Stored; models can be opened | Preserve; fresh unsaved models used for regression |

## I. Every remaining PRIMARY LIVE occurrence of old generator data

There are **no remaining selected-primary assignments of the old saturated d-axis trio**. The retained 0.2248 at provider line 62 is intentionally the separate primary saturated value (both numeric transcription and raw text), not a mistaken unqualified subtransient assignment.

The actual old active-power input exceptions are exactly **389.30 at master lines 16 and 17**. They propagate through case dispatch to the ideal PV source and solved calculations; they were not hidden or migrated. This means Phase 1 establishes sole current primary **machine-data** ownership, but does not yet establish sole registry ownership of **operating-case dispatch**. That is the expressly deferred Phase 2 work. Legacy probes and Rev2 are callable but do not feed the current entry-point chain.

## J. Rev2 consumers and independent inputs — unchanged

Current entry chain: [`RUN_ME.m`](../../../RUN_ME.m:22) → current dispatcher/setup → current master/provider/builders. It does not call the Rev2 registry. Rev2 is a separate manually callable workflow, not dead code and not safe current primary authority.

| Rev2 consumer | Independent data/dependency | Status |
|---|---|---|
| [`ashuganj_rev2_registry.m`](../../../rev2/data/ashuganj_rev2_registry.m:14) | Own machine set, 360 MW maximum, 354/360 MW cases, assumed limits, erroneous solid generator grounding | Dangerous competing primary claim; frozen |
| [`run_phase1_loadflow.m`](../../../rev2/run_phase1_loadflow.m:15) | Own registry/NR workflow; line 182 independently hard-codes generator snapshot text | Legacy executable plus documentary duplicate |
| [`seq_networks.m`](../../../rev2/data/seq_networks.m:27) | Own registry, subtransient method selection, independent prefault fallbacks around lines 78/100 | Legacy live fault inputs; not migrated |
| [`run_phase2_fault.m`](../../../rev2/run_phase2_fault.m:30) | Calls sequence network for base/sensitivity cases | Legacy executable consumer |
| [`run_phase3_protection.m`](../../../rev2/run_phase3_protection.m:18) | Own registry and legacy LF/fault CSVs; line 107 embeds 458 MVA in a GSUT LV current calculation | Legacy executable; known boundary/current-base issue deferred |
| [`build_loadflow_v2.m`](../../../rev2/simulink/build_loadflow_v2.m:26) | No master call; 354 MW, 2.0374 GVA source short-circuit level, 22 kV and X/R 266.9 literals | Independent nonideal-source builder; frozen |
| [`run_full_project.m`](../../../rev2/run_full_project.m:9) | Orchestrates Rev2 studies/tests/results | Separate legacy entry point |
| [`ashuganj_rev2_gui.m`](../../../rev2/gui/ashuganj_rev2_gui.m:9) | Rev2 results, saved-model actions and hard-coded display values | Legacy UI/execution wrapper |
| [`build_dashboard.m`](../../../rev2/gui/build_dashboard.m:1) | Legacy CSV outputs and contextual machine descriptions | Documentary consumer, not dynamic validation |
| [`add_protection.m`](../../../rev2/simulink/add_protection.m), [`run_loadflow_v2_tests.m`](../../../rev2/simulink/run_loadflow_v2_tests.m), [`recompute_verdicts.m`](../../../rev2/simulink/recompute_verdicts.m) | Saved V2 model/results and test assumptions | Legacy model consumers; no migration |
| [`test_rev2_registry.m`](../../../rev2/tests/test_rev2_registry.m:3), [`test_phase2_fault.m`](../../../rev2/tests/test_phase2_fault.m:10), [`test_phase2_kcl.m`](../../../rev2/tests/test_phase2_kcl.m), [`test_phase3_protection.m`](../../../rev2/tests/test_phase3_protection.m) | Legacy data/study expectations | Not part of current ten-file suite; not executed or changed |

No Rev2 studies directory exists; runners are directly under Rev2. Formatting/layout/XML utility files do not constitute a new current primary registry. Full matched Rev2 locations remain in the occurrence ledger.

## K. Test changes and reasons

- Replaced seven obsolete missingness assertions for supplied quadrature/sequence, armature resistance, inertia and open-circuit time-constant data.
- Replaced three old primary percent expectations with primary workbook equivalents; retained the d-axis ordering sanity check.
- Added every supplied canonical numeric/text value, source cell, raw numeric/heading/unit/group checks, normalized provenance, dataset designation, explicit saturation and unresolved-field conditions.
- Added distinct capacity/PF-reference/owner-scenario tests without changing dispatch.
- Added explicit legacy retention, generator NER, remaining rotor/control/OCC gaps, master/provider identity and frozen-case checks.
- Added both armature bases/inverses, distinct subtransient system views and round trips; no physics tolerance was relaxed.
- Corrected a newly written integration comparison to missing-value-aware equality after proving both provider structures were identical except ordinary equality rejects matching missing markers. Recorder code itself was not altered.

Independent read-only review found no numerical/conversion defect; its source-ledger and stronger-metadata coverage recommendations were addressed before final verification.

## L. Unexpected behavior and retained limitations

1. Editor save formatting treated MATLAB files as C/Objective-C and corrupted two edited files. The original backups were restored and scoped changes applied through terminal writes; subsequent MATLAB execution verified syntax. No physics file was affected. The unrelated editor configuration was not modified.
2. A PowerShell helper name collided with a built-in alias and an append overload rejected an array. The failed append was detected from output, corrected with a distinct helper and explicit text write, and did not produce accepted test evidence.
3. Python is not installed; no dependency was installed. PowerShell/MATLAB performed the work.
4. The initial new integration test used equality incompatible with intentional missing markers; diagnosed and corrected as above.
5. **No unexpected LF numerical change occurred.** The four-case exact comparison passed.
6. Protected builders/GUI/report producers still contain stale prose saying newly supplied generator data are missing; they are explicitly audited, not silently advertised as refreshed. Historical readiness/reports remain historical. Existing grid/magnetising test-design caveats from reconciliation remain outside this phase.
7. Top-level compatibility and primary records are MATLAB value snapshots created together, not mutable linked objects. Future adapters must rebuild derived views after changing an in-memory canonical profile; Phase 1 introduces no dynamic exporter.

## M. Recommended Phase 2 — not implemented

1. Migrate the four LF case definitions through registry-backed operating profiles: recommend 360 MW for the two capacity cases; retain 342.01 MW only with explicit owner-boundary qualification.
2. Preserve the old 389.30 MW cases under explicit historical sensitivity IDs; add a primary capacity guard and approved-exception mechanism.
3. Propagate dataset/case identity to future results and resolve stale builder/GUI captions without altering electrical equations.
4. Verify case-specific voltage setpoint propagation when separately authorized; do not introduce grid, transformer-loss, fault, protection or dynamic changes as a side effect.
5. Any Rev2 consumer migration needs separate approval and grounding/source/base/fingerprint safety review. This phase does not correct legacy earth-fault/protection conclusions.

**STOP: Phase 1 only. No project-completion, dynamic-validation, or corrected fault/protection claim is made.**
