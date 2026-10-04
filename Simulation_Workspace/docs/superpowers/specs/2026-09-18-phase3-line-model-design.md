# Phase 3 Line-Model Design (Option A, revised) — Ashuganj South 450 MW CCPP

Date: 2026-09-18. Status: DRAFT for user review. No implementation authorized by this doc.
Phase 1 = completed. Phase 2 = completed and frozen. Phase 3 = authorized ONLY (no fault/relay/dynamic work).

## 1. Intent and non-goals

Build a practical, physically reasonable, academically defensible 230-kV plant-to-grid network model for handoff to Phase 4, with full source traceability. No short-circuit/sequence/relay/TMS/breaker-duty/EMT work. No battery/DC expansion. No AVR/governor/SFC retuning. No LF solver redesign. No Phase 4–7.

## 2. Baseline finding (why delete-and-rebuild)

Other-AI Phase-3 progress is broken and is removed, not repaired:

- `matlab/data/ashuganj_lines.m:60-87` adds `L_LINE` (70 km D/C Finch) with 2 modelled branches; `matlab/data/ashuganj_lines.m:208` asserts `sum==2`. This breaks `matlab/tests/test_line_data.m:34,38` (7 entries, 1 modelled, Q7a) and cascades to 20 failures in the fresh `run_all_tests('all')` run (1271 passed / 20 failed: line/phase-shift/grid/magnetising/phase2-load-flow).
- `matlab/analysis/validate_phase3_network.m:27` crashes (`LF.busname_to_idx` does not exist; Phase-2 pattern is `ashuganj_bus_map`), and `matlab/studies/run_phase3_load_flow.m:84-116` reads fields the validator never produces. `results/phase3_loadflow/` is empty; `phase3_lf_test*.txt` show the crash and a `-129.26 %` voltage-drop artifact.
- `matlab/data/ashuganj_grid.m:22-23` still states "No 70 km line", contradicting the lines file. Headers must be reconciled, not left contradictory.

Decision (user-approved): delete `L_LINE` block, both Phase-3 files, empty results dir, and `phase3_lf_test*.txt`; restore the Phase-2 7-branch baseline; re-implement clean per this spec.

## 3. Revision 1 — 70 km is CONDITIONAL, not automatic L2

Suggestion "adopt 70 km as PLANT-PROVIDED / LEVEL-2" is accepted ONLY conditionally. Evidence check:

- `tmp/rev3_txt/Google Sheet Form_Filled Up By APSCL.txt:73-75` prints `B1 [3.4011 S/km]` next to "Standard 400 kV bundled" and `L [70 km]` in the same Section 3 block; Section 4–5 continue with `400 kV Bus Fault [Contact PGCB]`, `400 kV GIS Bay CT`.
- `docs/model/branch_list.md:55-67` therefore records: South 230-kV outgoing existence CONFIRMED (Line module 2000 A), but identity/length/circuits/R1/X1/B1/R0/X0 for 230 kV = MISSING; the 70 km + R0/X0/B1 numbers sit under a 400-kV North heading and are out of scope; R1/X1 are blank even there.
- `Line data.pdf` candidates (Ghorasal 44 km Mallard 795 MCM; Comilla 79 km Finch 1113 MCM; Sirajganj 144 km Twin AAAC) are regional inventory, none proven as the South tap.

Spec rule: 70 km may enter the model as the supervisor-permitted modelling length, but its status is `ENGINEERING_ASSUMPTION (supervisor-directed, L2-form value under dispute)` unless/until a South-230-kV source row is produced. It MUST NOT be recorded as `VERIFIED_*`/`PRIMARY_*`. The conflict table keeps both rows: (a) supervisor direction to use 70 km; (b) audit finding that the only located 70 km row is 400-kV North. Same conditional treatment for R0 0.06667 / X0 0.39472 / B1 3.4011 carried by the current `L_LINE`. R1 0.062 / X1 0.40 (Finch typical) have no located source row at all and stay `ENGINEERING_ASSUMPTION`. C0 60 % stays assumption. Missing Level-1 drawing `INEL-112070-00-ELC-DE-0026` stays documented as unavailable; work does not block on it.

## 4. Revision 2 — single-branch D/C equivalent, explicit

The lumped branch represents two identical balanced D/C circuits in parallel, both in service, with negligible mutual coupling:

- `R_eq = (r1_km * L) / 2`, `X_eq = (x1_km * L) / 2`, `B_eq = 2 * b1_km * L`, `L = 70 km` (per §3 status).
- Per-circuit values, the `/2` and `×2` steps, units (Ω/km → Ω total; µS/km → F total via `C = B/(2π·50)`), and the 100-MVA/230-kV pu conversion (`Zbase = Vbase²/Sbase`) are shown with numbers in the derivation sheet. No per-km constant is stored as a total and vice versa.
- Sensitivity: single-circuit-out case (`R_eq×2`, `X_eq×2`, `B_eq/2`) is run and reported; mutual impedance is declared MISSING, not zero-by-proof.
- Topology: `B230_1 --[L_LINE 70 km PI]--> B230_REMOTE --[ZGRID]--> BGRID230 (swing)`. Nominal-pi is adequate for 70 km at 50 Hz balanced LF; justification (wavelength vs length, charging magnitude) is recorded rather than assumed from convenience. Fault-location readiness (0/25/50/75/100 %) is a topology property for Phase 4; no fault values are computed now.

## 5. Revision 3 — 2.66 Ω derivation verified, provenance fenced

Verified by execution (PowerShell, same arithmetic as code): `Ssc = √3·230 kV·50 kA = 19918.5842870421 MVA`; `Z = V²/Ssc = 2.65581123827228 Ω` (reported as ≈2.66 Ω). Chain in `matlab/data/ashuganj_grid.m:74-111` (`Ssc → Z → X=Z` at R=0 → `L=X/(2π·50)`) is arithmetically correct.

Fence: input `Isc = 50 kA` is the ESTIMATED Siemens §2.4 external-grid source quantity (equipment 50 kA/1 s+3 s, 125 kA peak, 50 kA making are separate EQUIPMENT RATINGS; |Z| = 2.65581124 DERIVED, XN ≈ 2.66 separately reported), so every downstream figure inherits `ESTIMATED`, never verified. The secondary `45.01 kA / X/R 10.99` set stays a separate sensitivity profile; its R/X are derived only inside that profile. No mixed `50 kA + 10.99` tuple. Grid + line losses/voltage effects are reported separately so the line does not hide inside the equivalent.

## 6. Revision 4 — taxonomy mapping (no new strings)

User terms map onto the enforced enum in `matlab/data/ashuganj_master_data.m:36-38` (`VERIFIED_PLANT, VERIFIED_ENGINEERING_DOCUMENT, VERIFIED_PROJECT_DATA, DERIVED_FROM_VERIFIED_DATA, PRIMARY_VERIFIED, PRIMARY_SOURCE_QUALIFIED, ENGINEERING_ASSUMPTION, HISTORICAL, LEGACY, ESTIMATED, MISSING, NOT_APPLICABLE, AVAILABLE_NOT_DIGITIZED`):

- L1 as-built/datasheet/PGCB-supplied South row → `VERIFIED_*` / `PRIMARY_SOURCE_QUALIFIED` with document+page/section.
- L2 workbook/verified dataset → `PRIMARY_SOURCE_QUALIFIED` or `VERIFIED_PROJECT_DATA` with sheet/cell; the disputed 70 km row → assumption per §3, never `VERIFIED_*`.
- L4 math from source rows → `DERIVED_FROM_VERIFIED_DATA` (or `DERIVED_FROM_PRIMARY_SOURCE_EXTRACTED` where the generator precedent applies) with inputs+formula+units+result.
- L5 academic fill → `ENGINEERING_ASSUMPTION` with basis + finite range + sensitivity.
- Benchmarks → `HISTORICAL` (389.30 MW) / qualified scenario (342.01 MW); superseded → `LEGACY`; absent → `MISSING` (dependent feature disabled or scoped out).
- `PLANT-PROVIDED / LEVEL-2 SOURCE`, `PRIMARY_SOURCE_VERIFIED`, `DERIVED_FROM_SOURCE` MUST NOT be written into structs unless the enum + validators are updated first; the final table carries a human-readable source-tier column alongside the enforced status field.

## 7. Revision 5 — fresh-build determinism test (new)

Rationale: `power_loadflow(_, 'solve')` mutates the model; `powergui` hides a `frequencyindice` 60-Hz default; SPS library loads wipe the base workspace. New test builds the same case twice from scratch (`build_ashuganj_main(cid,'Quiet',true,'Backup',false,'Save',false)` + `bdclose`), solves, and asserts identical P/Q/V/loss/KCL within the existing Phase-2 tolerances (P balance 1e-3 MW, Q balance 1e-3 MVAr, KCL 0.05 MVA; dispatch exactness 1e-3 MW), plus `f=50 Hz`, `BranchType` (`L` for R=0 grid, `PI` for line), and bus identification by block handle, never by index. Any non-determinism fails loudly instead of entering the comparison table.

## 8. Revision 6 — Phase-2 preservation via hashes

`PHASE3_PRE_HASHES.txt` exists (88,828 B) but carries stale absolute `G:\...` paths. Phase 3 regenerates `PHASE3_PRE_HASHES.txt` (relative paths, SHA-256) BEFORE any edit, and `PHASE3_POST_HASHES.txt` + change table (`File | Before | After | Changed? | Authorized? | Reason`) at close. Protected (must stay byte-identical): generator numerics/capability/NER/capacity policy (§0 list), transformer ratings/Z/R/taps, aux 14 MW/0.85 aggregate, solver equations, operating-profile definitions. Permitted: `ashuganj_lines.m` (line block only), `ashuganj_grid.m` header/provenance comments (no numerical change to the estimate), new Phase-3 validator/runner/tests, result artifacts, docs. Any protected-byte change aborts the phase.

## 9. Work split (15 tasks, implementation plan follows after spec approval)

1. Hash baseline + protected/permitted list. 2. Source audit (Line data.pdf full + SLD/GIS + workbook + audit docs + conflict table). 3. Topology evidence table + selected connection. 4. Conductor/bundle/geometry extraction. 5. R1/X1/B1 derivation sheet. 6. R0/X0/B0 status + assumption/sensitivity design (no `3×X1` as fact). 7. Line-model implementation (single-branch PI per §4). 8. Grid-interface integration + header reconciliation. 9. Determinism test (§7). 10. Phase-3 physics tests (§38 list). 11. LF compatibility (LF360 pair primary; LF342 qualified; LF389P30 historical-only) + OLD-vs-NEW comparison. 12. Loading/drop/loss reporting. 13. Sensitivity runs. 14. Full regression (`run_all_tests('all')`) + conservation checks. 15. Hash/change audit + `PHASE3_FINAL_REPORT.md` (§§1-28 + "fault analysis reserved for Phase 4" boundary).

## 10. Acceptance

Phase 3 closes only when §46 boxes hold on the NEW network: identified connection, audited Line data.pdf, proven length/circuits/conductor status, R1/X1/B1 or explicit MISSING, R0/X0/B0 or explicit MISSING, documented derivations/assumptions, integrated topology, conserved KCL/balances, verified loading/drop/loss, compat + regression explained, hashes/changelog done, zero fault/relay/dynamic work. Unknowns stay UNKNOWN.
