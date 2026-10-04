# Emergency supply and results presentation

> Execution: independent MATLAB emergency study, Phase 4/5 data presentation, Phase 6 data presentation, followed by integration and review.

**Goal:** Add the missing generator-off emergency case to v4 and present existing Phase 4–6 evidence clearly.

**Architecture:** New emergency calculations write only to `results/emergency_supply`. Read-only Python adapters prepare per-case CSV tables and static engineering plots under `results/presentation`. A searchable local HTML report is the front door. Existing numerical cases, models, parameters and saved evidence stay unchanged.

**User constraints:** Use the nested v4 project. Do not touch other cases; just add this case. No deletion, relocation, overwrite or rerun of existing cases.

**Engineering constraints:** A disconnected generator supplies no P/Q and performs no voltage regulation. DC supports explicitly represented DC loads; it cannot energize the full AC auxiliary system. Unavailable EDG ratings, essential-load schedules and transfer characteristics must remain unresolved or explicitly identified scenario inputs. Protection affects interruption and energy exposure, not the initial prospective fault level. Phase 4, revised Phase 5 screening and Phase 6 electrical profiles must be identified separately.

## Tasks

- [x] Emergency study: `matlab/studies/run_emergency_supply_study.m` and a focused test. Read existing load-flow baseline, solve the disconnected-generator grid supply condition, report supply paths and DC/EDG limitations. Run MATLAB checks with retained evidence. DONE 2026-09-25: 5 cases (E1 GAT / E2 GSUT+UAT / E3 parallel / E4 blackout / E5 charger-out) in `results/emergency_supply/` (11 CSVs + run log); `test_emergency_supply` PASS; RUN_EMERGENCY_SUPPLY writes only that folder.
- [x] Fault/protection adapter: `tools/results_presentation/fault_protection.py`. Read production Phase 4 and current Phase 5 v2 outputs. Export fault level, MVA, first-ring contributions, settings, coordination and unresolved conditions per case. Check arithmetic and source reconciliation. DONE 2026-09-25: phase4 4 tables/4 figs, phase5 4 tables/4 figs; MVA reconciliation all PASS (incl. F1 LG ~7.27 A sanity).
- [x] Dynamic adapter: `tools/results_presentation/dynamic_results.py`. Read saved Phase 6 scenarios. Export measured fault/relay/breaker/DC results and comparable before/after figures, with correct RMS/peak/window definitions and profile distinctions. DONE 2026-09-25: 6 tables/4 figs incl. bus_3ph before/after chain (87B 0.153/0.187 s, Q0 open 0.237 s, cessation ~0.24 s).
- [x] Integration: `tools/results_presentation/build_results.py`, static assets, `results/index.html`, and `START_RESULTS.html`. Provide navigation, searchable tables, full CSV downloads, per-case evidence, readable graphs, assumptions and reproducible commands. Check links, render the report, review calculations and verify original-file hashes. DONE 2026-09-25: `results/presentation/index.html` (4 sections, 1554 rows, 15 figs); preservation 643/643 unchanged; integrity tests 3/3 OK. One stale baseline entry (display-only Phase6 script, predates task) re-baselined with supersession note.

## Interfaces

Each Python adapter takes `(root: Path, output: Path)` and returns JSON-compatible sections with `title`, `intro`, `tables`, `figures`, `notes`. Tables have `title`, `columns`, `rows`, `csv`; figures have `title`, `path`, `caption`. Paths are relative to the generated presentation directory. Emergency source CSVs are converted by the integration layer.

## Validation and progress

Preservation is checked against a SHA-256 inventory of existing numerical output and model/source files. Scientific checks cover power balance, actual zero generator injection, source-linked values, correct MVA definitions, phasor contribution interpretation and measured relay/breaker times. The browser report must load without network dependencies and without invalid local links.

Ruling: original folders remain in place because the latest explicit instruction prohibits touching existing cases. Organization is supplied by an indexed presentation package and clear links to original raw evidence.

Ruling: this is a non-Git project; no commits or worktree creation are applicable. v4 is the explicitly authorized workspace.
