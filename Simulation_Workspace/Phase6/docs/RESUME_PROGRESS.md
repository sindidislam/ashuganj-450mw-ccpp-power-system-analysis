# Phase 6 resume ledger — 2026-09-22

## Latest continuation — 2026-09-24 (Phase 6)

Use this section and `PHASE6_VALIDATION_REPORT.md` for current status; all
September 23 and older pending lists below are historical.

- Saved model opened/compiled in the visible R2024a desktop. The actual GUI
  normal Run action produced valid data without nuisance trips.
- Four fresh regression suites passed: DC recovery, DC supply, actuators and
  protection S-functions. The pending-trip regression first failed as intended,
  then passed after the DC pulse was changed to wait for available power.
- Integrated `dc_late_recovery_bus_3ph` passed: restoration at 0.500 s, 2 kW
  coil power from 0.501 to 0.701 s, Q0/local-line open commands at 0.551 s,
  and no opening before restoration. Evidence is in
  `logs/resume_20260924/final_checks.log` and its result directory.
- The final normal simulation and all 14 frozen operating-point comparisons
  passed. Mean active power is 360.005275 MW over 0.500-0.600 s. The model was
  returned to useful normal settings with a selectable future fault.
- `results/phase6_parameter_register.csv` now exists. Seven relay setting rows
  match the frozen study values. The seven fault-reference comparisons are
  explicitly qualified by stage/profile differences, with 21 phase means
  independently checked from saved complex phasors.
- Fresh upstream SHA-256 verification checked 490 files with zero changes at
  18:14:01 +06:00. Numerical runs, interface checks and presentation screenshots
  are retained under `logs/resume_20260924`.
- Remaining delivery work: run `logs/resume_20260924/export_remaining.m` to
  create missing JSON/figures from saved MATs and verify
  `export_remaining.done.json`; finish and check persistent styling hooks.
  Do not report completion from script preparation alone.

The DC trip interface is an aggregate initial pulse, not independent physical
coil accounting. Manual commands bypass aggregate coil demand; additional
individual requests while it stays asserted do not retrigger separate coils.
Generator-side fault results demonstrate breaker-branch isolation, not a
verified internal-fault extinction time. These are documented scope limits,
not claims of installed-plant validation.

## Historical continuation — 2026-09-23 evening (Phase 6)

Work is confined to `C:\Users\sindi\Downloads\Simulation_Workspace\Phase6`.
The normal integrated run and all six component test suites succeeded in the
previous morning session (`logs/resume_20260923_normal.log`). The saved normal
model is preserved in `logs/resume_20260923_evening/baseline_model.slx`.

- Bus 3PH: actual simulation and export completed. 87B pickup 0.153 s, trip
  request 0.187 s, Q0 and local line commands open 0.237 s. All three phases
  show sustained current cessation by 0.2476 s. The scheduled fault starts
  at 0.150 s. Healthy battery/DC supports the trip during auxiliary AC sag.
  Evidence: `results/bus_3ph/{relay_times,breaker_times,events}.csv`.
- A diagnostic print used a stale camelCase table name after successful
  simulation/export; corrected to the actual snake_case names. The numerical
  results were already saved before that harmless final display error.
- In progress: eleven additional measured fault/DC/reset scenarios, independent
  reference comparison, interactive scenario/protection controls, and live
  measurements with colored SLD presentation. Three subagents are active.
- Pending final gates: reduced dispatch, fresh saved-model compile/simulation,
  UI/callback checks, visual inspection, numerical report, teacher guide and
  preserved-upstream hash verification. Do not declare Phase 6 complete yet.

The older task list below is historical and predates the successful integrated
normal run; use this continuation section and current result evidence for status.

Plan: `Phase6/docs/PHASE6_WORK_PLAN.md` (the saved design is the specification).

The previous session left a builder skeleton, one build test, documentation and frozen input copies. `init_phase6_parameters`, `phase6_add_network` and `phase6_add_controls` were not present; no dynamic model had been saved. MATLAB R2024a is installed. This directory is not a Git repository. Work continues in the existing isolated `Phase6/` output tree, with a baseline archive and SHA-256 checks instead of a new worktree.

## Task status

1. Source hashes, checkpoint and R2024a block inspection: in progress.
2. Source-linked parameter register and contracts: pending.
3. Synchronous-machine AC network and initialization: pending.
4. Governor/AVR, measured relays and station DC trip chain: pending.
5. Normal/fault/DC scenario execution and numerical acceptance: pending.
6. Model visual inspection, teacher instructions and final review: pending.

## Interface review

| Tasks | Shared interface | Resolution |
|---|---|---|
| 1–6 | Original Phase 1–5 files | Read only; generated files stay under Phase6. |
| 2–3 | Generator, transformer, line and grid data | Reuse canonical providers; maintain the Phase 3 network profile. |
| 2–4 | Academic controls and 110 V DC data | Reuse explicit Phase 2 assumptions and retain their study classification. |
| 3–4 | AC measurements and breaker commands | Three-phase instantaneous V/I; machine measurement bus; external breaker commands. |
| 3–5 | Operating-point initialization | Solve and apply SPS load flow, then initialize controller states from that solution. |
| 4–5 | Fault and DC scenarios | Verify measured disturbance, relay state, breaker state and actual interruption separately. |
| 5–6 | Acceptance evidence | Export actual results and explicit limitations; never label a failed check successful. |

Decisions: continue the already specified Phase 6 design; a new design-approval stop is unnecessary for this resumed task. Preserve rather than recreate the historical models. Normal station DC is an academic equivalent, not an as-built supply. Missing actual controller tuning does not block an explicitly classified study model.
