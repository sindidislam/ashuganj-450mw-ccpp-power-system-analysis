# Task 1 — scoped I1 re-review after fix1

Date: 2026-09-16.

## Verdicts

- **Spec compliance: APPROVE for I1.** The original important provenance finding is addressed; its request-changes blocker is closed.
- **Code quality: APPROVE for the metadata/test delta.** No new defect or breakage was identified by static inspection and the existing targeted evidence.
- **New critical/important findings: none within this scope.** Prior nonblocking observations remain; this is not a fresh whole-Task-1 audit or integration approval.

## Scope and evidence

Reviewed [I1 and its required disposition](task-1-review.md:27), the [final fix addendum](task-1-report.md:266), the [current cooling metadata](../../../matlab/data/phase2_source_data.m:74), and the [inserted provenance tests](../../../matlab/tests/test_generator_capability.m:123). The original source finding is accepted as prior evidence; no source document was reopened.

The missing [`task-1-fix1-package.txt`](task-1-fix1-package.txt) was recovered from the original review package's byte-counted [metadata source section](task-1-review-package.txt:516), [test source section](task-1-review-package.txt:607), and [report section](task-1-review-package.txt:1159), not by reconstructing old code from recollection. It contains three small unified diffs and existing log evidence, not another full source archive.

## Spec-compliance checks

| I1 requirement | Assessment |
|---|---|
| Retain the marked/provisional-design qualification in both records | **Pass.** The [shared locator](../../../matlab/data/phase2_source_data.m:76) preserves the transcription reference and identifies the marked loss table at technical p.4/PDF p.6 and footnote at technical p.7/PDF p.9. Both [total](../../../matlab/data/phase2_source_data.m:80) and [cooling](../../../matlab/data/phase2_source_data.m:87) rationales explicitly say subject to change after detailed-design finalization, not finalized/as-built. |
| Qualify confidence and interpretation without erasing provenance | **Pass.** [Total confidence and interpretation](../../../matlab/data/phase2_source_data.m:79) are qualified; [cooling confidence](../../../matlab/data/phase2_source_data.m:86) distinguishes arithmetic confidence from pending source finalization. Engineering-document source classification and derived cooling classification are retained. |
| Preserve numbers, derivation and accounting boundary | **Pass.** The [metadata diff](task-1-fix1-package.txt:36) leaves 1282/159/1095/28 kW, document identity, units, derivation and numerical inputs unchanged. No-load/load records are untouched. Frozen-LF/transformer-loss exclusion and unresolved auxiliary overlap remain; no uncertainty range is supplied. |
| Add regression coverage for this omission | **Pass.** The [21-line insertion](../../../matlab/tests/test_generator_capability.m:123) adds 17 assertions: three classification checks plus seven checks for each marked record. Required text markers must all be present; empty uncertainty ranges are checked. Existing value, derivation and provenance assertions remain. |

## Quality and regression assessment

The fresh archive/current comparison found exactly one cooling-metadata hunk, one test insertion, and the append-only report addendum. There are no other changes within those three compared files. The test's existing content and CRLF endings are preserved; the metadata file retains LF endings. This supports the addendum's claim that temporary formatting damage is absent from the final test delta.

The metadata edit changes descriptive arguments and the total record's interpretation, not arithmetic or control flow. The test loop checks both records independently, produces scalar conditions, and does not alter subsequent assertions. No new helper, numerical provider, or dependency is introduced by the inspected delta.

Existing [RED evidence](task-1-fix1-red.log:211) records **215 passed / 9 failed**: exactly five total-record and four cooling-record qualification failures. Existing [GREEN evidence](task-1-fix1-green.log:211) records **224 passed / 0 failed**, including its final success marker. Assertion-line counts were independently counted from the saved logs and agree with their summaries. The 17 added checks account for 207 original assertions plus eight new passes/nine expected failures in RED, then all 224 passes in GREEN. **These are historical runs, not reviewer-run tests.**

## Handoff and limits

The [recovered package](task-1-fix1-package.txt:1) is explicitly labelled as recovery evidence. Contrary to the interrupted addendum's anticipated package description, the exact original MATLAB launch commands were not recovered; process exits are attributed to the addendum, not independently observed. This evidence limitation does not reopen the metadata finding.

Only this review and the missing fix package were written. No runtime/test edits, tests, MATLAB execution, subagents, broad hashes, source re-audits, LF solves, or later-task work were performed. No preservation claim is made for files outside the three-file comparison. **I1 closed; stop at Task 1.**
