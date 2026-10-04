# Phase-2 Task 1 — recovery, verification, and handoff report

**Status: DONE_WITH_CONCERNS — Task 1 only.**

Recovered and verified on 2026-09-16 with MATLAB 24.1.0.2537033 (R2024a), Windows 11, and PowerShell. **No existing Task-1 runtime or test file was changed during recovery.** Inspection, fresh targeted verification, preservation evidence, this report, and the review package complete the interrupted Task 1. Tasks 2–6 were not started. No subagents, repository creation, commits, worktrees, model rebuilds, or load-flow reruns were used.

Concerns below are source qualifications and deferred integration boundaries, not failing targeted tests. This report does not declare all of Phase 2 complete or validate an operating point, dynamic model, or protection study.

## 1. Authorization and recovered state

Scope: [Task-1 brief](task-1-brief.md), [implementation plan Task 1](IMPLEMENTATION_PLAN.md:24), [approved design](DESIGN.md:17), and the user's explicit Task-1-only recovery instruction.

- The pre-change baseline was already captured: **915 passed / 0 failed**, plus four saved historical LF cases with OK verdicts. It was inspected, not repeated.
- Implementation and modified generator expectations already existed. The [original red log](task-1-red.log) records expected absent-interface and obsolete-physical-limit failures.
- The [original green log tail](task-1-green.log:763) is complete: **207/0 capability + 476/0 generator + 39/0 base = 722/0**.
- The [fresh recovery green log](task-1-recovery-green.log) reproduces those counts against current files. The batch asserts all six pass/fail counters and exits 0.
- The existing [runtime-writing script](task-1-write-runtime.ps1) was inspected but **not executed**. It is historical editing evidence; rerunning it would rewrite completed work.
- The existing [progress ledger](progress.md:41) is stale: it still describes an incomplete baseline and unstarted tasks. It was deliberately not edited. This report supersedes that state **for Task 1 only**.

## 2. Requirement-by-requirement disposition

| Task-1 requirement | Evidence/result |
|---|---|
| Exact six curve arrays and honest manual-extraction metadata | Present in the provider; exact arrays, source status, manual/user extraction, and no-inspection flag tested. |
| Endpoint/interpolation/domain tests | All six endpoints, all five segment midpoints, independent 360 MW formulas, shapes, explicit curve, ten invalid-power cases, and six malformed curves pass. |
| RED before implementation | Existing log records 0/4 capability and 473/3 generator: four missing interfaces and three obsolete physical-Q expectations. |
| Finite compatibility limits at primary capacity | Provider interpolates at 360 MW using its explicit curve; lower/upper bounds are finite and dispatch applicability is explicit. |
| Preserve raw machine/source data | Runtime equality confirms all 30 primary fields, 40 full provenance records, legacy data, resistance/base quantities, and unrelated original generator fields. |
| Normalize provenance; qualify NER, excitation/SFC, grid | Implemented in the read-only source view; unresolved field units remain explicit. Context does not alter frozen numerical providers. |
| Run capability/generator/base tests; inspect diff and identity | Fresh 722/0, exact no-index backup comparisons, 937-original hash audit, and runtime identity checks completed. |

No failing Task-1 requirement was found during recovery. Therefore no production/test edits or new TDD cycle were necessary. Original RED/GREEN evidence was preserved rather than reconstructed.

## 3. Authoritative capability and physical meaning

The authoritative object is [`G.capabilityCurve`](../../../matlab/data/ashuganj_generators.m:39).

| P MW | Lower Q MVAr | Upper Q MVAr |
|---:|---:|---:|
| 0 | -231 | 335 |
| 100 | -231 | 329 |
| 200 | -220 | 311 |
| 300 | -205 | 280 |
| 389.3 | -182 | 241 |
| 458 | 0 | 0 |

Source: Siemens Generator Protection Setting Report, Attachment 1. Classification is [`PRIMARY_SOURCE_EXTRACTED`](../../../matlab/data/ashuganj_generators.m:41); extraction method is [`MANUAL_GRAPH_EXTRACTION`](../../../matlab/data/ashuganj_generators.m:43), extracted by USER, confirmed 2026-09-15. Local attachment inspection is explicitly false. These are user-confirmed graph readings, not directly tabulated manufacturer values; graphical uncertainty is not quantified.

Interpolation is piecewise linear; extrapolation is rejected. There is no clipping, smoothing, fitted envelope, or dispatch authorization. Primary capacity remains **360 MW** and rating remains **458 MVA**. The 458 MW tip is retained as source data only.

At 360 MW, independent expected formulas are:

- Lower: −205 + 60 × 23 / 89.3 = **−189.546472564389717 MVAr**.
- Upper: 280 − 60 × 39 / 89.3 = **253.796192609182526 MVAr**.

The formulas are [test expectations](../../../matlab/tests/test_generator_capability.m:31), not production hard-coded limits. The [provider](../../../matlab/data/ashuganj_generators.m:50) obtains both from interpolation. Actual values appear in the [identity log](task-1-identity.log). Scalar compatibility bounds apply only at the recorded 360 MW dispatch; another dispatch requires interpolation again. Supplied signs are preserved.

## 4. Complete signatures and interfaces

### 4.1 Generator provider

Signature: [`G = ashuganj_generators()`](../../../matlab/data/ashuganj_generators.m:1). No inputs; returns the existing scalar generator registry, extended rather than replaced.

- Added: [`capabilityCurve, Qlim_P_MW, Qlim_Source_status`](../../../matlab/data/ashuganj_generators.m:39).
- Changed existing values: [`Qmin_MVAr, Qmax_MVAr, Qlim_Status, Qlim_Note, Qcurve_Status, Qcurve_Note`](../../../matlab/data/ashuganj_generators.m:50).
- [`Qcurve_Source`](../../../matlab/data/ashuganj_generators.m:54) remains unchanged.
- All 140 original fields remain: **134 unchanged, six intentionally changed**; three additions produce 143 current fields.
- [`Primary, Provenance`](../../../matlab/data/ashuganj_generators.m:7) and [`Legacy`](../../../matlab/data/ashuganj_generators.m:33) are exactly equal to original runtime output.

Curve fields: [`P_MW, Qmax_MVAr, Qmin_MVAr, status, source_status, source, source_locator, extraction_method, extracted_by, confirmation_date, attachment_locally_inspected, confidence, rationale, P_unit, Q_unit, interpolation, extrapolation, interpretation_status, applicability`](../../../matlab/data/ashuganj_generators.m:39). Units are MW/MVAr; interpolation and extrapolation policies are explicit.

Physical-limit status is [`DERIVED_FROM_PRIMARY_SOURCE_EXTRACTED`](../../../matlab/data/ashuganj_generators.m:52). Underlying source status stays extraction-qualified, not promoted to verified tabulation.

### 4.2 Capability interpolator

Signature: [`[Qmin_MVAr,Qmax_MVAr] = generatorCapability(P_MW,curve)`](../../../matlab/data/generatorCapability.m:1); second input optional.

- Power input: nonempty real finite numeric array, all entries in **[0,458] MW**.
- Outputs: **lower first, upper second**, in MVAr, retaining input shape. Interpolation converts numeric data to double.
- Without a curve, obtains the generator's authoritative object. Explicit injection during provider construction prevents recursion.
- Curve: scalar structure with [`P_MW, Qmin_MVAr, Qmax_MVAr`](../../../matlab/data/generatorCapability.m:18), each a real finite numeric vector. Equal lengths of at least two; strictly increasing P beginning at 0 and ending at 458; lower never above upper.
- Errors: [`generatorCapability:InvalidP`](../../../matlab/data/generatorCapability.m:12) and [`generatorCapability:InvalidCurve`](../../../matlab/data/generatorCapability.m:20).
- Evaluates the envelope only: no 360 MW dispatch guard, MVA-circle check, operating-point acceptance, or PV-to-PQ switching.

### 4.3 Normalized parameter helper

Signature: [`r = phase2_parameter(value,unit,source,source_locator,status,confidence,rationale,varargin)`](../../../matlab/data/phase2_parameter.m:1).

Seven positional inputs, then optional name/value pairs. Value accepts numeric, logical, character, or string data. The six required metadata arguments must be nonempty text; metadata text is converted to character representation. Partial option-name matching is disabled.

| Returned field / option | Contract |
|---|---|
| [`value`](../../../matlab/data/phase2_parameter.m:20) | Retains supplied value. |
| [`unit, source, source_locator, status, confidence, rationale`](../../../matlab/data/phase2_parameter.m:21) | Required nonempty text. Units and qualifications are not invented. |
| [`selected_value`](../../../matlab/data/phase2_parameter.m:36) | Set to supplied value. |
| [`assumption_basis`](../../../matlab/data/phase2_parameter.m:24) | Default NOT_APPLICABLE. |
| [`reasonable_range, assumed_range`](../../../matlab/data/phase2_parameter.m:25) | Default empty numeric arrays for ordinary source records. |
| [`source_status`](../../../matlab/data/phase2_parameter.m:27) | Defaults to status; separately overridable to retain input-source classification on a derived record. |
| [`derivation`](../../../matlab/data/phase2_parameter.m:28) | Default empty text; equation may be recorded separately. |
| [`interpretation_status`](../../../matlab/data/phase2_parameter.m:29) | Default DIRECT; qualification separate from source classification. |

These are the required **14 lowercase fields**. Records classified exactly as [`ENGINEERING_ASSUMPTION`](../../../matlab/data/phase2_parameter.m:37) require nonempty finite real numeric selected values, explicit basis, finite ordered two-element ranges, assumed range inside reasonable range, and every selected value inside the assumed range. Degenerate ranges allow an explicitly fixed assumption. Violations raise [`phase2_parameter:InvalidAssumption`](../../../matlab/data/phase2_parameter.m:44).

Missing evidence may retain NaN with missing status/unresolved units. This helper constructs records and validates assumption ranges; it is not an independent source-verification service or complete physical validator. Callers remain responsible for honest status/source inputs.

### 4.4 Read-only normalized source view

Signature: [`S = phase2_source_data(G)`](../../../matlab/data/phase2_source_data.m:1). No input uses the generator automatically. An injected input must be the scalar generator record, **not the assembled master**.

Top-level fields: [`dataset_id, generator, capabilityCurve, excitation, sfc, ner, grid, cooling`](../../../matlab/data/phase2_source_data.m:1).

- [`generator`](../../../matlab/data/phase2_source_data.m:17): 40 normalized records from existing provenance; each retains full [`raw_provenance`](../../../matlab/data/phase2_source_data.m:31). Values follow provenance rather than an independent primary registry. Tests alter an injected provenance value and verify the view follows it.
- Locators retain original sheet/cell details, including original sheet text/trailing space.
- [`capabilityCurve`](../../../matlab/data/phase2_source_data.m:34): same authoritative object. This specialized curve object is not an ordinary parameter leaf.
- Other group leaves are parameter records, with additional SFC side labels where applicable.

| Group/leaves | Values and qualification |
|---|---|
| [`excitation.type, excitation.designation, excitation.no_load_voltage_V`](../../../matlab/data/phase2_source_data.m:35) | Static, SEMIPOL, 122 V no-load excitation. Not controller gains, commissioned settings, or a defined field base. |
| [`sfc.dc_link_kV, sfc.max_starting_output_A`](../../../matlab/data/phase2_source_data.m:42) | 2.28 kV DC link; 1876 A maximum starting OUTPUT current. DC_LINK and OUTPUT side labels prevent conflation; their product is not verified converter power. |
| [`ner.primary_kV, ner.secondary_V, ner.rating_kVA, ner.duration_s`](../../../matlab/data/phase2_source_data.m:49) | 22/√3 kV phase voltage, 500 V secondary, 135 kVA for 20 s, not continuous. |
| [`ner.hv_dc_resistance_ohm, ner.loading_resistance_ohm, ner.grounding`](../../../matlab/data/phase2_source_data.m:55) | Approximate 60 ohm HV DC resistance and 2.62 ohm secondary loading resistor; source question marks and QUALIFIED interpretation retained. High-resistance NER 10BAB11 remains. Not added across sides or promoted to a zero-sequence equivalent. |
| [`grid.estimate_Isc_kA, grid.estimate_Ssc_GVA`](../../../matlab/data/phase2_source_data.m:63) | 50 kA and source-rounded 19.919 GVA, ESTIMATED; do not replace frozen grid arithmetic. |
| [`grid.sensitivity_Isc_kA, grid.sensitivity_XR`](../../../matlab/data/phase2_source_data.m:70) | 45.01 kA, X/R 10.99; separate SECONDARY_SOURCE_CONTEXT, not selected grid strength. Original secondary attachment not re-inspected. |
| [`cooling.gsut_total_kW, cooling.gsut_no_load_kW, cooling.gsut_load_kW, cooling.gsut_cooling_kW`](../../../matlab/data/phase2_source_data.m:76) | 1282, 159, 1095 kW; residual **28 kW = 1282 − 159 − 1095**. Derivation and source classification separate; nothing added to frozen LF demand. |

Field-resistance units/base remain unresolved. Unqualified subtransient reactance **0.2608 pu** stays distinct from saturated **0.2248 pu**. Raw stator resistance **0.00089 ohm** and original machine/system-base conversions remain unchanged.

### 4.5 Test interfaces

- [`[np,nf] = test_generator_capability()`](../../../matlab/tests/test_generator_capability.m:1).
- [`[np,nf] = test_generator_data()`](../../../matlab/tests/test_generator_data.m:1).
- [`[np,nf] = test_base_conversion()`](../../../matlab/tests/test_base_conversion.m:1).

The [hand-rolled assertion recorder](../../../matlab/tests/t_case.m:42) emits one PASS/FAIL line per check and returns **assertion counts**, not MATLAB unit-test object counts. Recovery counted log lines independently and matched all per-file summaries.

## 5. Exact tests, counts, and verification

### 5.1 Existing baseline: inspected, not rerun

The [baseline summary](baseline_tests.log:955) records:

| Suite | Passed | Failed |
|---|---:|---:|
| [Bus data](../../../matlab/tests/test_bus_data.m) | 61 | 0 |
| [Generator data](../../../matlab/tests/test_generator_data.m) | 476 | 0 |
| [Transformer data](../../../matlab/tests/test_transformer_data.m) | 85 | 0 |
| [Line data](../../../matlab/tests/test_line_data.m) | 47 | 0 |
| [Load data](../../../matlab/tests/test_load_data.m) | 58 | 0 |
| [Base conversion](../../../matlab/tests/test_base_conversion.m) | 39 | 0 |
| [Topology](../../../matlab/tests/test_topology.m) | 52 | 0 |
| [Transformer phase shift](../../../matlab/tests/test_transformer_phase_shift.m) | 18 | 0 |
| [Grid sensitivity](../../../matlab/tests/test_grid_sensitivity.m) | 38 | 0 |
| [Magnetising sensitivity](../../../matlab/tests/test_magnetising_sensitivity.m) | 41 | 0 |
| **Total** | **915** | **0** |

Read-only checks of [baseline_lf.mat](baseline_lf.mat) confirm four result records, baseline 915/0 counters, IDs LF1–LF4, four OK verdicts, and exact equality of all saved case records with current frozen definitions. This is **not** a fresh numerical solve comparison.

### 5.2 Original TDD and fresh recovery evidence

| Stage | Capability pass/fail | Generator pass/fail | Base pass/fail | Total pass/fail |
|---|---:|---:|---:|---:|
| Original RED | 0/4 | 473/3 | Not run in that log | **473/7** |
| Original GREEN | 207/0 | 476/0 | 39/0 | **722/0** |
| Fresh recovery GREEN | 207/0 | 476/0 | 39/0 | **722/0** |

Seven RED failures: missing curve, interpolator, parameter helper, source view; old negative-infinite lower bound; old positive-infinite upper bound; obsolete physical-limit status. Tests guard missing interfaces, so RED reports four existence failures rather than attempting all downstream capability assertions.

Generator tests remain at 476 checks: only three obsolete expectations/comments were replaced. Base tests were unmodified. The 722 targeted count is not a complete post-change suite and must not be added to the old 915 baseline as one fresh run.

### 5.3 Capability assertion breakdown

| Area | Passing assertions |
|---|---:|
| Curve/provider, exact arrays, extraction metadata, applicability | 13 |
| Interpolator, endpoints, midpoints, 360 MW formulas, shapes, custom curve, invalid inputs/curves | 28 |
| Parameter helper/schema/defaults/ranges/missing-source distinction | 11 |
| Source view: existence/default equivalence, 120 checks across 40 provenance records, 33 further source/qualification checks | 155 |
| **Total** | **207** |

Ten invalid power cases: below zero, just above 458, NaN, positive/negative infinity, complex, array containing NaN, empty, text, logical. Six malformed curves: absent fields, repeated P, nonfinite Q, reversed bounds, mismatched lengths, wrong domain endpoint. Exact equality checks endpoints; midpoint tolerance is 1e-10; independent 360 MW and injected-curve tolerance is 1e-12.

### 5.4 Fresh execution and analyzer findings

Fresh targeted batch began **2026-09-16 06:41:21 Asia/Dhaka**, MATLAB **24.1.0.2537033 (R2024a)**. All six checked functions resolved to this workspace. Code Analyzer ran on four runtime and two test files, followed by direct invocation of all three targeted suites and an assertion of exact counters 207,0,476,0,39,0. Success marker and **process exit 0** were confirmed. Existing interactive MATLAB was not stopped or reused.

Analyzer result: **65 non-fatal advisories**, not a lint-clean claim: six inherited newline/readability advisories, 57 inherited unnecessary-bracket advisories, and two string-growth/performance advisories in new source-view locator construction. All files parsed and relevant runtime paths executed. No unrelated style/formatter edits were made.

### 5.5 Runtime identity checks

A separate [identity batch](task-1-identity.log), exit **0**, evaluated a temporary copy of the original backed-up generator in the batch process, removed its path, then evaluated current data. The temporary copy/subdirectory was removed; backups/current sources were not edited.

Confirmed:

1. All 140 original fields remain; only the six authorized capability-related values differ; exactly three fields added.
2. All **30 primary fields**, **40 full provenance records**, and legacy data are exactly equal.
3. Every master field except the intentionally extended generator is exactly equal to original runtime output.
4. Baseline 915/0 and four OK saved cases; **4/4 exact case-record identities**.
5. Both voltage setpoints **1.00 pu**; auxiliary demand **14 MW at 0.85 PF**.
6. Finite physical bounds at 360 MW with the values above.

Identity checks are separate from, and not counted in, the 722 assertions. Exact targeted rerun instructions are in the [review package](task-1-review-package.txt).

## 6. Changed files and scope preservation

### 6.1 Product changes relative to original baseline

| File | Task-1 change, already present when recovery started |
|---|---|
| [`matlab/data/ashuganj_generators.m`](../../../matlab/data/ashuganj_generators.m) | Replace only obsolete physical-Q/undigitized-curve block with curve/provenance and derived bounds. |
| [`matlab/tests/test_generator_data.m`](../../../matlab/tests/test_generator_data.m) | Replace only three obsolete physical-Q assertions and explanatory comments. |
| [`matlab/data/generatorCapability.m`](../../../matlab/data/generatorCapability.m) | New interpolator. |
| [`matlab/data/phase2_parameter.m`](../../../matlab/data/phase2_parameter.m) | New normalized parameter helper. |
| [`matlab/data/phase2_source_data.m`](../../../matlab/data/phase2_source_data.m) | New read-only normalized source view. |
| [`matlab/tests/test_generator_capability.m`](../../../matlab/tests/test_generator_capability.m) | New capability/provenance/helper tests. |

Recovery rewrote none of these. Their exact SHA-256 and byte counts are in the [start snapshot](task-1-recovery-start-hashes.csv) and review package.

### 6.2 Original-file audit

The [baseline inventory](baseline_hashes.csv) covers **937 originals**. The [integrity manifest](task-1-original-integrity.csv) records baseline/current hash, size, and status for each:

- **935 unchanged; two modified; zero missing**.
- Modified originals are exactly the generator provider and generator test above.
- All **six backups** match their original baseline hashes.
- Protected groups entirely unchanged: **46 Rev2, 75 results, 40 Simulink, nine builder, and 15 supplied engineer-document-directory files**. Original files outside those groups are also covered by the 937-entry manifest.

No solver, builder, transformer/grid/load numerical provider, source document, historical output, master, dispatcher, suite runner, or topology-test edit was made. The [master](../../../matlab/data/ashuganj_master_data.m), [dispatcher](../../../matlab/ashuganj.m), [suite runner](../../../matlab/tests/run_all_tests.m), and [topology test](../../../matlab/tests/test_topology.m) match backups exactly. Hash comparison establishes preservation, not semantic source-document inspection.

### 6.3 New recovery artifacts

[Report](task-1-report.md), [review package](task-1-review-package.txt), [fresh targeted log](task-1-recovery-green.log), [identity log](task-1-identity.log), [original integrity manifest](task-1-original-integrity.csv), [recovery-start snapshot](task-1-recovery-start-hashes.csv), and [final verification log](task-1-final-verification.log).

The start snapshot covers **27 pre-existing files**: six Task-1 product files and all pre-existing Phase-2 evidence, including baseline artifacts, original RED/GREEN logs, plans/briefs/ledger, editing script, and six backups. These are rechecked at completion. Temporary identity-copy material is removed, not a deliverable.

## 7. Exact review package

The [plain-text package](task-1-review-package.txt) contains:

1. Scope/status, targeted counts, rerun command, and diff-exit semantics.
2. **Actual Git no-index diff output for all six backed-up originals versus their current counterparts**, with exact command and exit code: two modified pairs return 1; four unchanged pairs return 0. No repository is needed or created.
3. **Full unabridged text of all six current Task-1 runtime/test files**, including four new files and both modified originals, with path/byte count/SHA-256.
4. Full existing runtime-writing script, clearly marked historical and not rerun.
5. This report and the original RED/GREEN, fresh targeted, and identity logs.

File contents are copied directly as byte-counted sections, not reformatted or reconstructed. Diff generation disables external diff/text-conversion hooks and automatic line-ending conversion. Final verification checks section bytes against source files and regenerates all six diffs for comparison.

## 8. Direct review findings and concerns

**No blocking Task-1 defect found.** Review was direct in this session, not an independent reviewer/subagent review.

1. **Extraction uncertainty:** manual graph readings are user-approved, but graphical uncertainty is unquantified and the attachment was not independently inspected. The 458 MW tip is not dispatch approval.
2. **Physical versus solver limits:** physical generator bounds are finite at 360 MW. The approved [PV builder settings](../../../matlab/build/build_generator_system.m:74) remain mathematically unbounded to preserve the frozen solve. They are not physical capability or grounding, and Task 1 does not enforce/clamp operating points.
3. **Frozen historical case/grid metadata:** the unchanged [master case limit field](../../../matlab/data/ashuganj_master_data.m:21) still contains infinite historical limits, and the [grid provider](../../../matlab/data/ashuganj_grid.m:133) retains its approved unlimited mathematical context. Task 1 does not claim all repository limit fields are finite. Case/profile physical-limit migration belongs to later authorized work; it was not performed here.
4. **Integration deferred:** the [explicit suite list](../../../matlab/tests/run_all_tests.m:38) does not yet register the new capability suite; recovery invoked it directly. The master does not yet expose the new normalized source object or update its status vocabulary. Those changes are outside Task 1. No complete post-change suite, new LF solve, or six-profile integration is claimed.
5. **Source qualification:** unresolved field resistance/base, approximate/question-marked NER resistance, estimated grid strength, secondary sensitivity context, and unresolved cooling/auxiliary overlap remain. No physical field base, verified SFC power, grounding equivalent, or electrical coupling is inferred.
6. **Review/test limits:** analyzer advisories remain; existing test guards provide RED absence checks rather than exhaustive validation of every unsupported data type. The source-view injected argument is a trusted generator record, not a general untrusted-input API. The parameter helper cannot independently certify a caller's provenance labels.
7. **Stale documentation:** the progress ledger and any historical unlimited-Q wording remain untouched to honor preservation. This report documents the Task-1 handoff rather than silently rewriting history.

These concerns justify DONE_WITH_CONCERNS without expanding scope. No Rev2, solver, builder, source/history, master, runner, or later-task edits were made.

## 9. Final disposition

**DONE_WITH_CONCERNS.** Task 1's existing implementation is retained, its complete original GREEN is confirmed, fresh targeted tests pass **722/0**, runtime primary/provenance identity is verified, and the original-file boundary is preserved. The report and exact review package complete the interrupted handoff. **Stop at Task 1; Tasks 2–6 remain unexecuted by this recovery.**

## 10. Round-1 fix1 — I1 provenance qualification (2026-09-16)

**I1: FIXED / TARGETED GREEN.** This append-only addendum corrects the missing cooling qualification in section 4.4 and supersedes the earlier no-blocker assessment for this finding. The historical recovery evidence above is not a new fix-round run; independent approval is not claimed. The source's design-finalization uncertainty remains unresolved rather than being certified away.

### Source verified

Read the local [GSUT datasheet](../../../fwdtechnicaldatasldrequestforbueteeetermproject/GSUT%20Data%20Sheet_South.pdf), CTI document S009-112070-00-ELC-HD-0001, revision 00, dated 24/02/14. Section 1.7, technical page 4 (PDF page 6), marks **1282 kW total guaranteed losses at 515 MVA** and **28 kW total cooling consumption** with an asterisk. Technical page 7 (PDF page 9) states: “*) marked values might be subject due change after finalizing the transformer's detailed design”. The 159 kW no-load and 1095 kW full-load entries used here are unmarked. Exact subtraction does not establish finalized/as-built cooling demand.

### Narrow correction

- Only the normalized [total/cooling metadata](../../../matlab/data/phase2_source_data.m:76) changed. Both locators retain the existing transcription reference and add the marked loss-table and design-finalization-footnote pages. Both rationales explicitly carry the marked, subject-to-change detailed-design caveat and reject finalized/as-built interpretation.
- Total confidence is now qualified/design-finalization pending, with [`QUALIFIED`](../../../matlab/data/phase2_source_data.m:81) interpretation. Cooling retains high arithmetic confidence but explicitly qualifies the source pending design finalization; its qualified interpretation remains.
- Total record/source classification remains [`VERIFIED_ENGINEERING_DOCUMENT`](../../../matlab/data/phase2_source_data.m:39). Cooling remains [`DERIVED_FROM_VERIFIED_DATA`](../../../matlab/data/phase2_source_data.m:86), with engineering-document source classification and the unchanged derivation **1282 − 159 − 1095 = 28 kW**. Document identity, units, selected values and **1282/159/1095/28** values are unchanged; no uncertainty range was invented.
- No-load/load records, including their original locators and confidence, are unchanged. Frozen LF/transformer-loss exclusion and unresolved auxiliary overlap remain explicit. Transformer/LF/grid/load/generator providers, helpers, curve points and other source groups were not edited.

### Test-first evidence

Added **17 assertions** to the existing [capability provenance test](../../../matlab/tests/test_generator_capability.m:123): retained classifications/document identity, qualified interpretation and confidence, precise table/footnote locators, provisional rationale, and no invented ranges. Existing value/derivation assertions remain unchanged. Every required text marker is checked individually.

| Fix1 stage | Passed | Failed | MATLAB process exit |
|---|---:|---:|---:|
| [RED: new tests, pre-fix production](task-1-fix1-red.log) | 215 | 9 | 1, expected |
| [GREEN: same tests, corrected metadata](task-1-fix1-green.log) | 224 | 0 | 0 |

RED failures were exactly five total-loss qualification checks and four cooling qualification checks; all original 207 assertions passed. GREEN emitted the success marker after asserting exact counts. Both runs used MATLAB 24.1.0.2537033 (R2024a) and invoked only [`test_generator_capability()`](../../../matlab/tests/test_generator_capability.m:1). No full suite, generator/base test rerun, LF solve, large hash audit or repeated Task-1 identity work was performed.

### Fix-local preservation and handoff

Before/after diffs are limited to two code files and this report append. The test has only a 21-line insertion; existing test bytes and no-load/load source lines are retained. An editor save initially applied C-style formatting to the MATLAB test; it was restored from the fix-start snapshot before RED, and the final diff contains none of that formatting damage. Subsequent MATLAB writes bypassed that formatter without changing editor settings.

The [small fix package](task-1-fix1-package.txt) records source evidence, exact targeted commands/counts, RED failure lines, GREEN success evidence, and the three fix-local unified diffs. The original review/package/logs were not rewritten. **I1 remediation complete; source design caveat retained; stop at Task 1 round 1.** No subagents or later-task work.
