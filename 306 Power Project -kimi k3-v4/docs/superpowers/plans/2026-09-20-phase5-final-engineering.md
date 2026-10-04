# Phase 5 final engineering correction plan

**Goal:** Complete the existing Phase-5b study with numerical assumptions, exact provenance, isolated screening cases, consistent outputs and reproducible verification.

**Architecture:** Keep Phase-2/3/4 code and output bytes fixed. Preserve the Phase-5 import and IEC curve engines. Resolve central settings once, enforce scope at the matrix boundary, and add an explicit analytical screening table for parameter uncertainty. Generate documentation and hashes from final live tables.

**Specification:** User master prompt, 2026-09-20, sections 0-55. This is the authorized implementation specification.

**Constraints:** Actual installed settings are never inferred from study assumptions. Q0 remains conditional at 50 kA. Sensitivities never replace the frozen fault backbone or central relay settings. Non-operation is represented by infinity; structurally inapplicable fields are explicitly marked, not treated as missing study parameters.

- [x] Preserve upstream hashes and inspect original evidence, including ambiguous PDF pages.
- [x] Add regression tests for current semantics, neutral CT, scope, numerical sensitivity, runner and artifact verification; demonstrate the existing failures.
- [x] Close numerical parameters and provenance in `phase5b_parameters.m`, `phase5b_registry.m`, and `phase5b_pickup.m`.
- [x] Correct matrix scope/current selection, conditional duty and protection detectability in the existing Phase-5b modules.
- [x] Execute neutral CT/pickup, GSUT CT, grid strength/XR/zero sequence, NER, motor and CT-saturation screening cases.
- [x] Regenerate both TCCs from live settings; validate independently against IEC SI equations.
- [x] Run `run_phase5b_tests()` and the production workflow; update obsolete tests to the newly authorized engineering requirements without weakening numerical checks.
- [x] Generate reports, decision log, numerical register and AI handoff from final CSVs; archive superseded final reports and clearly separate v1 regression artifacts.
- [x] Hash final CSVs, plots, documentation and code; verify every entry and upstream byte preservation; independently review the package.

The 2026-09-20 production log records 528/0 and 276 verified artifact hashes. Resume verification on 2026-09-21 independently reproduced 528/0 and verified all 55 protected inputs. The remaining closeout corrected stale Phase-5 text in the student manual and the source-audit grid-selection row, and added the student manual and this plan to manifest coverage. See `docs/PHASE5_CLOSEOUT_CHECKLIST.md` for acceptance evidence; the final production rerun and postproduction audit cover those documentation changes. Phase 6 is a separate task.

**Reproduction:** `matlab -batch "addpath(genpath('matlab')); run_phase5b_production('final-engineering','overwrite',true);"`
