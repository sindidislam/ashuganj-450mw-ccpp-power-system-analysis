# Phase-2 Task 1 — independent review

## Verdicts

**Spec compliance: REQUEST CHANGES — one important provenance finding (I1).** The capability implementation and preservation boundary satisfy the reviewed requirements, but the new cooling metadata drops an explicit source qualification.

**Code quality: APPROVE WITH NONBLOCKING OBSERVATIONS.** No separate critical/important algorithmic or maintainability defect was found in this static review. This verdict does not waive I1 or approve integration.

**Critical findings: none. Important findings: one. Overall: Task 1 is not unconditionally approved.**

Updated: 2026-09-16. This document is both the requested review deliverable and the resumable progress file. Only this document was written during the review.

### Review boundary

Independent, read-only inspection of the Task-1 implementation. No implementation changes, subagents, MATLAB execution, test reruns, load-flow solves, or master integration. The user's supplied fresh result of **722 passed / 0 failed** is accepted as existing runtime evidence, not a reviewer-run result.

### Completed

- Read the [task brief](task-1-brief.md), [implementation report](task-1-report.md), and [review package](task-1-review-package.txt), including all six product files and all six original-file diffs.
- Cross-checked the [approved design](DESIGN.md:17) and [Task-1 implementation requirements](IMPLEMENTATION_PLAN.md:24).
- Inspected the exact six curve points, manual-extraction provenance, interpolation/domain/shape handling, primary-capacity compatibility limits, all 14 helper metadata fields, assumption-range validation, normalized source groups, and capability-test assertions.
- Independently performed read-only SHA-256 comparisons: **937 originals; 935 unchanged; two changed; zero missing**. The changed originals are only [`ashuganj_generators.m`](../../../matlab/data/ashuganj_generators.m) and [`test_generator_data.m`](../../../matlab/tests/test_generator_data.m). All six backed-up originals match the baseline inventory. All six current product files match the package's declared hashes and byte counts.
- Inspected the package's existing RED/GREEN and identity evidence without rerunning it.
- Read the local [generator source excerpt](../../../fwdtechnicaldatasldrequestforbueteeetermproject/Generator%20Data_South.pdf) to cross-check excitation/SFC/NER/grid context. This is **not** inspection of the capability attachment; the exact six user-manually-extracted points remain binding.
- Read the [GSUT source datasheet](../../../fwdtechnicaldatasldrequestforbueteeetermproject/GSUT%20Data%20Sheet_South.pdf), including its loss table and design-finalization footnote.

## I1 — Important: retain the cooling datasheet's design-finalization qualification

**Location:** [`phase2_source_data.m:76–83`](../../../matlab/data/phase2_source_data.m:76). **Affected regression coverage:** [`test_generator_capability.m:117–122`](../../../matlab/tests/test_generator_capability.m:117).

The normalized 1282 kW total is created with high confidence and the helper's default direct interpretation. The derived 28 kW cooling record has qualified interpretation, but its rationale qualifies only auxiliary overlap/LF accounting; neither record explains the input datasheet's provisional-design qualification.

**Source evidence:** the [GSUT datasheet](../../../fwdtechnicaldatasldrequestforbueteeetermproject/GSUT%20Data%20Sheet_South.pdf), section 1.7, printed technical page 4 (PDF page 6), marks **both 1282 kW total guaranteed losses and 28 kW cooling consumption** with an asterisk. The footnote on printed technical page 7 (PDF page 9) states: “marked values might be subject due change after finalizing the transformer's detailed design.” This qualification is absent from the normalized records and the report's [cooling disposition](task-1-report.md:125).

**Why important:** honest source qualification is a binding requirement of this provenance task; see the [approved metadata design](DESIGN.md:27). Verification that a number occurs in an engineering document is not evidence that its design-finalization caveat has been resolved. Exact subtraction establishes **28 = 1282 − 159 − 1095**, not a finalized/as-built cooling demand. A consumer of the normalized source view cannot recover this caveat from the current record. This is a metadata/spec-compliance blocker, **not** an arithmetic error or evidence that the frozen electrical model changed.

**Required disposition for a separately authorized correction:** retain the exact numbers, document identity, source classification and derivation, but explicitly carry the source's marked/provisional-design qualification in the total-loss record and propagate it to the derived cooling record. Qualify confidence/interpretation accordingly and cover that qualification in the existing provenance tests. Do not replace 28 kW with another value, invent an uncertainty range, or alter transformer/LF/auxiliary data. No correction was implemented in this review.

## Spec-compliance assessment

| Requirement | Independent assessment |
|---|---|
| Exact user-extracted curve | **Pass.** [`ashuganj_generators.m:39–49`](../../../matlab/data/ashuganj_generators.m:39) contains P = 0, 100, 200, 300, 389.3, 458 MW; lower Q = −231, −231, −220, −205, −182, 0 MVAr; upper Q = 335, 329, 311, 280, 241, 0 MVAr. No point, sign or endpoint was reinterpreted. |
| Extraction provenance | **Pass.** Source and record status remain [`PRIMARY_SOURCE_EXTRACTED`](../../../matlab/data/ashuganj_generators.m:41). Manual method, user identity, confirmation date, attachment locator, explicit no-local-inspection flag, unquantified graphical uncertainty, units and dispatch caveat are present. |
| Interpolation and domain | **Pass by inspection and existing evidence.** [`generatorCapability.m:10–34`](../../../matlab/data/generatorCapability.m:10) rejects empty/non-numeric/non-real/nonfinite/out-of-domain P, validates scalar curves and finite ordered vectors, and performs linear interpolation without extrapolation or clipping. Bounds are lower first, upper second; reshaping preserves input dimensions. Increasing P and endpoint checks enforce the full 0–458 MW curve domain. Ordered endpoint bounds remain ordered within each linear segment. |
| Optional curve / recursion | **Pass.** Default lookup uses the authoritative provider; [`explicit curve injection`](../../../matlab/data/ashuganj_generators.m:50) during provider construction terminates the dependency without recursive default lookup. An explicit two-point curve is independently exercised in the [tests](../../../matlab/tests/test_generator_capability.m:40). |
| Physical compatibility limits | **Pass.** The provider interpolates at unchanged primary 360 MW and records dispatch applicability; it does not hard-code expected answers. Independent formulas give lower −189.546472564389717 and upper 253.796192609182526 MVAr. The [360 MW formulas](../../../matlab/tests/test_generator_capability.m:31) are test expectations only. The 458 MW source tip does not authorize dispatch. |
| Primary/raw/legacy/base identity | **Pass.** The provider diff is confined to the capability block. Primary 458 MVA/360 MW, distinct 0.2608/0.2248 pu reactances, raw 0.00089 ohm resistance, base conversions, unresolved field base and high-resistance NER are untouched. Existing [identity evidence](task-1-review-package.txt:3599) reports 30 primary fields and 40 provenance records equal to baseline, plus legacy identity; runtime identity was not repeated. |
| Normalized source/helper | **Pass except I1.** Full helper schema is described below. Normalization retains each original provenance record, including raw units, base/interpretation qualifications and exact sheet/cell locator details. It is not a second independently hard-coded machine registry. |
| Excitation, SFC and NER context | **Pass.** [`phase2_source_data.m:35–61`](../../../matlab/data/phase2_source_data.m:35) keeps Static/SEMIPOL and 122 V separate from controller/field bases; labels SFC DC-link and output-current sides separately; retains 22/√3 kV, 500 V, 135 kVA/20 s, approximate/question-marked 60 and 2.62 ohm, and high-resistance grounding. No verified converter power or cross-side grounding equivalent is invented. |
| Grid context | **Pass.** [`phase2_source_data.m:62–73`](../../../matlab/data/phase2_source_data.m:62) retains estimated 50 kA/19.919 GVA separately from qualified secondary 45.01 kA/X/R 10.99. No selected grid strength or frozen impedance is changed. |
| Tests / three changed assertions | **Pass for the reviewed behavior, with I1's coverage omission.** Exact arrays, endpoints, every segment midpoint, 360 MW formulas, shapes, injected curve, ten invalid-P cases and six malformed curves are covered. A fresh read-only diff ignoring carriage returns confirms that [`test_generator_data.m:169–177`](../../../matlab/tests/test_generator_data.m:169) has only the three intended semantic assertion changes and associated comments. |
| Frozen scope / no master integration | **Pass.** The independent 937-original hash audit found only the two authorized changed originals, no missing files, and all six original backups intact. Solver, grid/transformer/load providers, builders, Rev2, source files, historical outputs, master, dispatcher, runner and topology test remain unchanged within that inventory. |

## Full helper and provenance contract review

[`phase2_parameter.m:15–47`](../../../matlab/data/phase2_parameter.m:15) produces all **14 lowercase fields**:

| Fields | Checked behavior |
|---|---|
| [`value`](../../../matlab/data/phase2_parameter.m:20), [`selected_value`](../../../matlab/data/phase2_parameter.m:36) | Supplied value is retained; selected value is the same value, not a separately selectable hidden override. General records accept numeric, logical and text data. |
| [`unit, source, source_locator, status, confidence, rationale`](../../../matlab/data/phase2_parameter.m:21) | Required nonempty/non-whitespace scalar text metadata, converted to character representation. |
| [`assumption_basis`](../../../matlab/data/phase2_parameter.m:24) | Defaults to not-applicable; an explicitly classified engineering assumption must provide a different, nonempty basis. |
| [`reasonable_range, assumed_range`](../../../matlab/data/phase2_parameter.m:25) | Default empty for ordinary source records. Engineering assumptions require finite real ordered two-element ranges, with assumed range inside reasonable range and every selected value inside the assumed range. Equal endpoints are allowed. |
| [`source_status`](../../../matlab/data/phase2_parameter.m:27) | Defaults to record status; can be supplied separately for a derived record. It does not infer verification from arithmetic. |
| [`derivation`](../../../matlab/data/phase2_parameter.m:28) | Defaults to empty text; equations are separately retained. |
| [`interpretation_status`](../../../matlab/data/phase2_parameter.m:29) | Defaults to direct interpretation; callers can preserve an explicit qualification without overwriting source classification. |

**Statuses reviewed:** [`ENGINEERING_ASSUMPTION`](../../../matlab/data/phase2_parameter.m:37) activates the finite numeric/basis/range checks; [`MISSING`](../../../matlab/tests/test_generator_capability.m:78) may retain an unknown numeric value and unresolved units. Source normalization preserves inherited plant/project/engineering-document/derived classifications and full raw records in [`phase2_source_data.m:27–31`](../../../matlab/data/phase2_source_data.m:27). Estimated and secondary-context statuses stay distinct in the [grid records](../../../matlab/data/phase2_source_data.m:63). The [cooling derivation](../../../matlab/data/phase2_source_data.m:80) correctly separates derived record status from engineering-document source status, but still needs I1's specific input qualification. Curve extraction and its derived physical-limit statuses remain separate in the [provider](../../../matlab/data/ashuganj_generators.m:41).

Status **values** are intentionally free-form nonempty text, not an enforced enumeration; only the exact engineering-assumption label activates that branch. The [report](task-1-report.md:102) explicitly documents this trusted-caller contract. No closed vocabulary was required by the reviewed Task-1 specification, so this is not independently classified as a defect. It is also not proof that arbitrary caller-supplied labels or provenance are truthful. The special curve object is not an ordinary parameter leaf; retained raw provenance appropriately keeps its original schema/capitalization.

## Code-quality observations — nonblocking

1. **Additional helper contract coverage would be useful.** The [helper tests](../../../matlab/tests/test_generator_capability.m:59) check schema presence, a valid assumption, missing assumption metadata, out-of-range selection and missing evidence. They do not independently exercise each range-order/containment/nonfinite branch, string metadata conversion, rejected partial option names, or every default. Static inspection found the required branches present; the test count should not be read as exhaustive validation.
2. **Distinguish semantic scope from byte scope.** The [exact packaged diff](task-1-review-package.txt:93) includes carriage-return normalization in untouched portions of the generator test. The fresh carriage-return-insensitive diff confirms no additional semantic edits, but “only three assertions changed” is not a byte-for-byte claim for the rest of that test file. This does not affect the protected raw/source/base records or frozen providers.
3. **Do not inflate inherited analyzer advisories into new defects.** The [report](task-1-report.md:185) acknowledges analyzer advisories, including small locator-string growth in the new source view. No lint-clean claim is made; these do not justify unrelated formatting or refactoring.

## Evidence boundaries and handoff

- **Existing runtime evidence, not rerun:** 207/0 capability + 476/0 generator + 39/0 base = **722/0**, with the supplied [fresh success marker](task-1-review-package.txt:3548). No runtime failure is alleged by I1.
- **Fresh reviewer checks:** read-only hashes of all 937 inventoried originals, all six product files against package hashes/byte counts, all six backups against baseline, and carriage-return-insensitive original/current diffs. Both command batches exited 0; individual no-index diff exit 1 denotes expected differences, not command failure.
- **Source inspection limit:** local generator and GSUT excerpts were read for contextual provenance; the capability attachment and original secondary grid attachment were not independently inspected. User-manually-extracted curve points remain authoritative.
- **Deferred by design:** master/profile/suite registration, case-limit migration, physical operating-point enforcement and later component/LF integration are not Task-1 defects and were not performed. Frozen unbounded solver settings are not physical capability.
- **No implementation edits or subagents.** Only this review/progress document was written. The existing report/package/history were not corrected or regenerated.

### Resumable progress / stop point

- [x] Requirements, report, package and current code reviewed.
- [x] Full helper/provenance schema and curve behavior assessed.
- [x] Independent preservation and semantic-diff checks completed without tests.
- [x] Separate verdicts and exact finding recorded.
- [ ] I1 remediation — **not authorized or implemented in this read-only review**.

**Stop at Task 1.** A future authorized remediation should address I1 within the new normalized metadata/tests and update its evidence; it must not alter the binding curve points, primary values, frozen providers or historical records. This review does not authorize master integration or Tasks 2–6.
