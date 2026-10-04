# Phase 5 final engineering acceptance record

Scope: resume and close the "Finalize phase 5 engineering" session. Phase 6 is separate and was not changed.

Status: READY_FOR_REVIEW. Final production and the independent postproduction audit passed on 2026-09-21.

## Recovered stopping point

The previous session completed final production on 2026-09-20: 528 tests passed, zero failed, 14/14 validation legs passed, and 276 artifact-hash comparisons passed. It stopped during final plot and handoff review. The original evidence remains in `tmp/phase5_final_audit/final_production.log` and `postproduction_audit.json`.

## Resumed verification and corrections, 2026-09-21

- [x] Personally verified the saved package: 55 protected Phase-2/3/4 files and 276 artifact-hash comparisons passed before closeout edits.
- [x] Personally reran the full Phase-5b suite: 528 passed, zero failed. Evidence: `tmp/phase5_final_audit/resume_verification_20260921.log`.
- [x] Visually inspected both production TCC PNGs. Titles, pickup annotations, legends, axes, conditional mapping and study-proxy qualifications are legible and match the final settings.
- [x] Independent read-only review confirmed 188 finite parameters, all 1793 sensitivity metric rows in 14 families, 31 functional trip rows, and exact agreement of the 44-file code/test change inventory with the pre-correction ZIP.
- [x] Independent direct arithmetic confirmed every one of the 76 finite coordination times; maximum absolute difference was 1.07e-13 s.
- [x] Independent review confirmed physical branch duty, excluding the explicitly marked system-reference NOTE row: Q0 6.897014754 kA / 50 = 0.137940295; 52G 55.048709681 kA / 100 = 0.550487097.
- [x] Corrected the source-audit row that still named 40 kA / X/R 10 as central. The final preliminary Phase-5 screening uses 45.01 kA / 10.99; the frozen Phase-4 network remains separate.
- [x] Updated the student manual's Phase-5 settings, neutral CT, current bases, examples, coordination/duty/effectiveness counts, sensitivities, proxy limitations, run guide and verification-only next actions. Its Phase 0-4 sections are preserved.
- [x] Added the student manual and the completed engineering plan to final manifest coverage. Closeout documents are covered by the existing `docs/PHASE5_*` inventory.
- [x] Final production rerun passed 528 tests with zero failures, 14/14 validation legs and 282 artifact-hash comparisons. Independent PowerShell verification passed 291 comparisons including the nine root/docs mirror checks.
- [x] The closeout review confirmed the updated manual examples and requested explicit LG qualification of the 7.27-A generator-earth-fault description; that wording was corrected. This does not apply the LG result to LLG faults.

The superseded closeout inputs are recoverable from `tmp/phase5_final_audit/pre_closeout_20260921.zip`.

## Engineering acceptance

- [x] Central settings: GEN-51 17170.8 A / 15000:1 / TMS 0.10; GEN-51N 4 A / 20:1 / TMS 0.15; GSUT-51 1380 A / 1600:1 / TMS 0.55; conditional Q0-51 1500 A / 1600:1 / TMS 0.80.
- [x] Nameplate and maximum-through-load currents are distinct. Source qualifications, GSUT CT and impedance/loss conflicts, NGT interpretation, grid conventions and Q0 physical identity are explicit.
- [x] All required central numerical parameters have finite values and provenance. Infinity denotes resolved non-operation; `NOT_APPLICABLE_TO_ROW` denotes a structurally irrelevant field, not an unresolved setting.
- [x] The 5-A neutral pickup and alternative CT/grid/motor/NER cases are numerical sensitivities, isolated from the central coordination matrix.
- [x] Coordination: 12 PRIMARY PASS; 12 CONDITIONAL-PASS; 0 FAIL; 24 NO-TRIP; 48 NO-PAIR, total 96.
- [x] Effectiveness: 28 CONDITIONAL-DETECTABILITY; 4 NO-TRIP; 8 NO-PAIR/OUT-OF-ZONE, total 40 central rows; 8 DT sensitivity rows remain separate.
- [x] Distance 21, 50BF, functional 86/trip logic, 64G defaults, neutral grounding, external grid, motor and CT-saturation screenings are numerically represented with their stated limitations.
- [x] No unconditional commissioning, manufacturer-algorithm or full interrupting-duty claim is made. No upstream fault current or equipment rating was altered to obtain a pass.

## Final package verification

The final production command regenerates the ten required CSVs plus parameter/trip tables, both TCC PNGs and metadata, synchronized reports, manifest and SHA-256 ledger. It runs the Phase-5b suite and verifies protected inputs and all final hashes after writing the outputs.

- Final production log: `tmp/phase5_final_audit/closeout_production_20260921.log`.
- Independent postproduction audit: `tmp/phase5_final_audit/closeout_audit_20260921.json`.
- Human-readable report: `docs/PHASE5_FINAL_REPORT.md`.
- Continuation handoff: `docs/PHASE5_AI_HANDOFF.md`.

```powershell
matlab -batch "addpath(genpath('matlab')); run_phase5b_production('final-engineering','overwrite',true);"
& .\tmp\phase5_final_audit\verify_final.ps1 -OutputPath 'tmp/phase5_final_audit/closeout_audit_20260921.json'
```

The engineering study is ready for review. Remaining plant-specific work requires installed relay settings, CT core/tap/excitation/burden data, PGCB sequence equivalents, confirmed Q0 ratings and timing, neutral-grounding tests, 64G manual/injection verification and commissioned trip wiring. These are verification-only items; they do not leave the preliminary numerical study open.
