# Phase 3 Changelog — Locked 0.7 km Line Model (Tasks 1–14)

Seed header (per Task 14 brief):
- Task 1 PRE baseline: `PHASE3_PRE_HASHES.txt`, 313 relative-path lines, 2-col `SHA256 + rel` canonical
  (Windows `Resolve-Path -Relative` backslash form, e.g. `.\matlab\...`; zero absolute-drive lines).
  Length 33023 bytes, LastWriteTime 2026-09-18 09:54:23. Count recorded in
  `.superpowers/sdd/2026-09-18-phase3-locked-07km-line-model/task-1-report.md`.
- Task 2 deleted list (broken other-AI artifacts removed, 7-branch baseline restored, `test_line_data` 47/0 green):
  `matlab/analysis/validate_phase3_network.m`, `matlab/studies/run_phase3_load_flow.m`,
  `results/phase3_loadflow/` (recurse), `phase3_lf_test.txt`, `phase3_lf_test2.txt`,
  `phase3_lf_test3.txt`, `phase3_lf_test4.txt`, `phase3_lf_test5.txt`, `phase3_lf_test6.txt`,
  `phase3_lf_test7.txt`, `phase3_lf_test8.txt` (11 paths).
- Task 13 totals: full suite `run_all_tests('all')` fresh **1368 passed / 0 failed** (ALL 1368/0, exit 0),
  log `docs/validation/rev31_phase3/task-13-all-tests.log`. Per-file: bus 66, generator 476,
  transformer 85, line 53, load 58, base 39, topology 52, capability 224, eng-assump 9,
  phase2-systems 24, phase2-components 51, profiles 55, phase-shift 19, grid-sens 38,
  magnetising 41, phase2-loadflow 53, phase3-line 20, phase3-determinism 5.

Hash method (Task 1 command, reused verbatim for POST):
`Get-ChildItem -Recurse -File -Include *.m,*.csv,*.md,*.mat,*.slx -Exclude
'PHASE3_POST_HASHES.txt','PHASE3_CHANGELOG.md','PHASE3_FINAL_REPORT.md' |
Where-Object { FullName -notmatch '\\tmp\\|\\results\\' } | ForEach-Object {
Resolve-Path -Relative; Get-FileHash SHA256; "SHA  rel" }`.
Scope consequences (no silent changes — read this before the table):
- `results/` is excluded by the `-notmatch` filter, so `results/phase3_loadflow/*` never appears
  in PRE/POST diffs; listed in §3 instead.
- Only `*.m,*.csv,*.md,*.mat,*.slx` are hashed: `*.txt` (`phase3_lf_test*.txt`) and `*.log`
  (`task-13-all-tests.log`) never appear in diffs; listed in §3/§4 instead.
- `PHASE3_POST_HASHES.txt` / `PHASE3_CHANGELOG.md` / `PHASE3_FINAL_REPORT.md` are excluded
  from their own hashes by `-Exclude`.
- POST: 333 lines, Length 35701 bytes, LastWriteTime 2026-09-18 11:52:01.
  PRE=313, POST=333, ADDED=20, MODIFIED=11, REMOVED=0, UNCHANGED=302.
  REMOVED=0 despite Task 2 deletions because the two deleted `.m` files were recreated
  (net MODIFIED), `results/` is hash-excluded, and the eight deleted `.txt` files are
  outside the `-Include` pattern.
- `.superpowers/sdd/.../task-N-report.md` files are process ledger (reporting mechanism),
  included by the `*.md` pattern; they account for 13 of the 20 ADDED lines.

## 1. Protected-identical proof (byte-identical PRE vs POST)

| File | SHA (PRE = POST) | Status |
|---|---|---|
| `matlab/data/ashuganj_generators.m` | identical | PROTECTED-OK |
| `matlab/data/ashuganj_transformers.m` | identical | PROTECTED-OK |
| `matlab/data/ashuganj_loads.m` | identical | PROTECTED-OK |
| `matlab/data/ashuganj_buses.m` | identical | PROTECTED-OK |
| `matlab/data/ashuganj_operating_profiles.m` | identical | PROTECTED-OK |
| `matlab/data/validate_operating_profile.m` | `F12B6A6C7DE6…` both files | PROTECTED-OK |
| `matlab/studies/run_load_flow_study.m` | identical | PROTECTED-OK |
| `matlab/build/build_ashuganj_main.m` | identical | PROTECTED-OK |
| `matlab/build/build_230kv_system.m` | identical | PROTECTED-OK |
| `matlab/build/build_auxiliary_system.m` | identical | PROTECTED-OK |
| `matlab/build/build_generator_system.m` | identical | PROTECTED-OK |
| `matlab/build/build_gsut_system.m` | identical | PROTECTED-OK |
| `matlab/build/sps_blocks.m`, `sps_geom.m`, `sps_wire.m` | identical | PROTECTED-OK |
| `matlab/analysis/ashuganj_bus_map.m` | identical | PROTECTED-OK |
| `matlab/analysis/ashuganj_bus_results.m` | identical | PROTECTED-OK |

Solver-builder exception: the ONLY builder delta is `matlab/build/build_external_grid.m`
lines 100–114 (code fallback + mandated comment, one authorized hunk; the "two hunks"
in the brief = code + comment within that hunk, single ruling `progress.md:40`).
All other builders byte-identical. No Phase-2 physics numerics touched
(458 MVA / 22 kV / 360 MW cap / H / Xd family / Ra / time constants / Q curve / NER
unchanged by hash proof above).

## 2. Change table (hash scope: File | Before | After | Changed? | Authorized? | Reason)

Short SHAs are 12-char prefixes; full hashes verifiable in PRE/POST files.
`—` = not present in that baseline.

| File | Before (PRE) | After (POST) | Changed? | Authorized? | Reason |
|---|---|---|---|---|---|
| `matlab/data/ashuganj_lines.m` | `3ACAE31BF25E…` | `C578683E7C16…` | YES | YES (Task 2+4) | Task 2 restored 7-branch baseline (removed 70 km L_LINE block, ZGRID→B230_1, assert 1); Task 4 added locked 0.7 km L_LINE PI (R 0.0277725 / X 0.1425655 ohm / B 3.937996 uS, 2-circuit lumped, EA) + ZGRID→B230_REMOTE + asserts 8/2. Source: locked EA set + source-audit conflict table. Tests: `test_phase3_line_model` 20/0, `test_line_data` 53/0 |
| `matlab/data/ashuganj_grid.m` | `3302632E4862…` | `C7D39788313A…` | YES | YES (Task 4, comments only) | Header comment states remote-bus placement; added display-only `G.Bus_remote`; `Model_Note` span →B230_REMOTE. No numeric change (X 2.65581124, R 0, ESTIMATED verified). Tests: `test_phase3_line_model` grid trio 3/3 |
| `matlab/analysis/validate_phase3_network.m` | `E552E75FE847…` (broken stub) | `6D41B4AA2710…` | YES | YES (Task 5 + Task 9 display fix) | Task 5 rewrote validator on bus_map schema (31 runner-consumed fields); Task 9 fix sources `V_REMOTE_kV` from bus_results `V_kV` (was `Vpu*230` → ~528 kV wart). Reporting only. Tests: 6/6 Verdict OK, determinism 5/0 |
| `matlab/studies/run_phase3_load_flow.m` | `80DD3C76F861…` (broken stub) | `C68A88E94C52…` | YES | YES (Task 6 + Task 9 writer fix) | Task 6 rewrote runner (fresh build→solve→validate→close→record, non-convergence guard, fprintf writers); Task 9 writer emits `V_pu_nom=V_kV/Vnom` when bases differ (was raw solver-base 2.297). Tests: LF360 pair OK, 6/6 OK |
| `matlab/build/build_external_grid.m` | `55A82204EC16…` | `81AA5BE1A004…` | YES | YES (ruling `progress.md:40`) | Balanced-LF placeholder: `isfinite`-gated pos-seq substitution for NaN R0/X0/C0 in PI dialog only + mandated comment; data R0/X0/C0 stay NaN MISSING; never 3×X1. Tests: unblocked solve, `test_phase3_line_model` 20/0 |
| `matlab/analysis/ashuganj_branch_flows.m` | `883407BF75FA…` | `6A4B804CE1F3…` | YES | YES (ruling Task 9) | Reporting alignment: ZGRID span →B230_REMOTE when L_LINE modelled (legacy fallback kept), new `pi_line_branch()` for L_LINE, per-bus vbase renorm (×1.0 identity for Phase-2). Data untouched. Tests: KCL 18.9 MVA→3.3e-05, `test_transformer_phase_shift` 19/0 |
| `matlab/tests/test_line_data.m` | `EEBB7CDB4172…` | `487799B8CC3B…` | YES | YES (Task 7 gated + Task 13 ruling `:71`) | 7/1→8/2 counts + ZGRID/L_LINE index fix + length-loop L_LINE 0.7 EA allowance + X-compare retarget to ZGRID + header update. No physics check weakened. Tests: 53/0 |
| `matlab/tests/run_all_tests.m` | `A9DF1E364631…` | `FECD4091D8F8…` | YES | YES (Task 13) | Registered `test_phase3_line_model`, `test_phase3_determinism` in `all` list only. Tests: ALL 1368/0 |
| `matlab/tests/test_grid_sensitivity.m` | `8E4A3F1B74B2…` | `E3A6E17ACBF1…` | YES | YES (ruling `progress.md:74`) | Measure ZGRID hand-calc angle at `B230_REMOTE` (2 sites + comments); tolerance 0.05 untouched. Tests: 37→38/0 |
| `matlab/tests/test_magnetising_sensitivity.m` | `B495DDEDEF4D…` | `93E3DAC792B0…` | YES | YES (ruling `progress.md:74`) | Hand decomposition adds L_LINE `P_loss_MW`; tolerance 2% untouched. Tests: 40→41/0 |
| `.superpowers/.../progress.md` | `9F4A13563142…` | `7CBB51AA4BBE…` | YES | YES (ledger) | SDD rulings + task completions (process, not model). No test impact |
| `docs/validation/rev31_phase3/phase3_source_audit.csv` | — | `29BA1754850E…` | ADDED | YES (Task 3) | 11-row source/conflict table (header + 11). Source: Line data.pdf, Form PDF Sec 3–5, Data Sheet 230KV, branch_list.md:55-67. Tests: inspection gate (no TBD) |
| `docs/validation/rev31_phase3/phase2_vs_phase3.csv` | — | `602C19546438…` | ADDED | YES (Task 9) | OLD-vs-NEW table (41 lines: header + rows). Source: phase2 summary + phase3 solves. Tests: hand-check agreement |
| `docs/validation/rev31_phase3/phase3_line_loading_drop_loss.md` | — | `EBD343C2D5E3…` | ADDED | YES (Task 10) | Loading/drop/loss note, LF360 pair, formulas + hand checks. Tests: analysis only |
| `docs/validation/rev31_phase3/phase3_conservation.md` | — | `28DA1EF79CAA…` | ADDED | YES (Task 11) | 6-case balance/KCL + 3I²R table. Tests: 6/6 PASS gate |
| `docs/validation/rev31_phase3/phase3_sensitivity.md` | — | `24859AA40A66…` | ADDED | YES (Task 12) | 3-set in-memory sensitivity note (9/9 OK). Tests: lock check 20/0 |
| `matlab/tests/test_phase3_line_model.m` | — | `A68A7D3223A2…` | ADDED | YES (Task 7) | 20-check locked-model gate (verbatim plan). Tests: 20/0 |
| `matlab/tests/test_phase3_determinism.m` | — | `CB18D4B37677…` | ADDED | YES (Task 8) | 5-check fresh-build determinism (verbatim plan). Tests: 5/0 |
| `.superpowers/.../task-1-report.md` … `task-13-report.md` (13 files) | — | (see POST hashes) | ADDED | YES (ledger) | Per-task evidence reports (process, not model) |

## 3. Created artifacts outside hash scope (no silent changes)

| File | Reason | Source basis | Test impact |
|---|---|---|---|
| `results/phase3_loadflow/phase3_system_summary.csv` (2529 B, 6 rows+header) | Task 9 NEW solves, all cases Write=true | Runner + validator solves | 6/6 Verdict OK |
| `results/phase3_loadflow/phase3_bus_results.csv` (3899 B, 54 rows) | Task 9 bus evidence | Same solves | V_REMOTE ≈229.7 kV, pu ≈0.999 post-fix |
| `results/phase3_loadflow/phase3_loadflow_results.mat` (13908 B) | Task 9 MAT archive (`S`, `all_bus_results`) | Same solves | Consumed by Tasks 10–12 |
| `docs/validation/rev31_phase3/task-13-all-tests.log` (fresh, ends ALL 1368/0) | Task 13 full-suite diary | `run_all_tests('all')` | 1368/0 evidence |
| `PHASE3_POST_HASHES.txt` (333 lines) | This task Step 1 | Task 1 command verbatim | Format check §5 |
| `PHASE3_CHANGELOG.md` (this file) | This task Step 3 | Tasks 1–13 reports + PRE/POST diff | Inspection |
| `.superpowers/.../task-14-report.md` | This task report | Task 14 work | Inspection |

## 4. Deleted files (Task 2; outside hash scope — hence REMOVED=0 in §2)

| File | Reason | Source basis | Test impact |
|---|---|---|---|
| `matlab/analysis/validate_phase3_network.m` (broken 4004 B) | Deleted as other-AI artifact, then recreated (net MODIFIED, §2) | Task 2 brief | Gated `test_line_data` 47/0 |
| `matlab/studies/run_phase3_load_flow.m` (broken 8423 B) | Same as above (net MODIFIED, §2) | Task 2 brief | Same |
| `results/phase3_loadflow/` (old dir) | Deleted, then recreated with validated outputs (§3) | Task 2 brief | 6/6 OK replaces stale |
| `phase3_lf_test.txt` … `phase3_lf_test8.txt` (8 files) | Deleted scratch outputs (`.txt` outside hash scope) | Task 2 brief | None (scratch) |

No other files deleted. No file deleted in Tasks 3–14.

## 5. Verification (this task)

- POST generation: Task 1 command verbatim; first lines show `SHA  .\…` / `.superpowers\…`
  (relative, backslash form); 333 lines (>100 PASS); 333/333 match `^[0-9A-F]{64}  \.`,
  0 match `^[0-9A-F]{64}  [A-Z]:`, 0 occurrences of `G:\`.
- Diff: PRE=313 POST=333; ADDED 20 (§2, all permitted/ledger), MODIFIED 11 (§2, all
  authorized with ruling/task), REMOVED 0 (explained above), UNCHANGED 302 (includes
  every protected file in §1).
- No code/data edits in this task (hash + docs only). No MATLAB runs. No git (no repo).

## 6. Forward / deferred minors (for Task 15 final report; no numeric impact)

- Task 1: 2-col `SHA + rel` is canonical; Windows backslash form (`.\path`) is the verbatim
  command output, not the plan's illustrative `./` form; PRE vs POST consistent.
- Task 3: mechanical CSV fix — plan's printed MISSING rows had 7 fields for the 8-col header
  (`status` parsed empty); fixed as `MISSING,,,,MISSING,,` in the 5 MISSING rows only,
  values/notes byte-identical; `ghorsal_44km` spelling kept verbatim.
- Task 4: stale plant-boundary comments remain: `ashuganj_lines.m:12-15` header
  ("equivalent sits at the PLANT BOUNDARY") and `:52-55` `Length_Note`
  ("Thevenin EQUIVALENT at the plant boundary"), plus `ashuganj_grid.m:5`
  ("network at the plant boundary") — all pre-date the ZGRID→B230_REMOTE move;
  Placement_Note/Bus_remote/Q7a-history lines are current. Cleanup is a docs pass, not physics.
- Task 10: citation-range note — evidence note cites `ashuganj_lines.m:55` (no-rating line),
  `phase2_vs_phase3.csv` rows 5/25 (export-delta check), and labels ΔV "model result, not
  measured"; carry exact ranges into final report.
- Task 11: citation ranges — validator gates `validate_phase3_network.m:40-43`, sign-convention
  formulas `:30-33` (full balance block `:30-43`); loss-scale note: brief expectation
  (~0.063 MW at ~870 A) confirmed on LF360 pair, loss scales as I² across 342/360/389 MW
  dispatches, all 6 cases ΔP ≤+0.25% / ΔQ ≤+0.8%.
- Task 12: wording clarifications — SCO "exact doubling" means ≈2× resistive scaling
  (0.062928→0.125847 MW, <0.1 W claim is solver-precision language, not metrology);
  line-Q wording: X moves net line Q only, B moves net line Q only (opposite sign), export P
  fixed; 9/9 counting = BASE anchor + 1 SCO + 6 R/X/B±20% + 1 GRID45 (all Verdict OK, 2 iters).
- Standing notes: SPS `419281 km/s > 300000 km/s` L_LINE warning is a cosmetic short-lumped-PI
  artifact (all solves, iter 2, unaffected); `val.V_REMOTE_pu` remains solver-base (~2.297)
  by determinism-test contract — only CSV-facing kV/pu columns are normalised; GAT_IN looped
  cases carry larger KCL (~6e-04 vs ~3e-05) in both eras (pre-existing snubber pattern).

## 7. Errata — reviewer correction headline wording (2026-09-18 fix wave)

The phrase "Locked numbers (all verified)" appeared only in the controller's chat summary
and never in `PHASE3_FINAL_REPORT.md` (grep over the workdir proves zero hits in the report).
No report text claimed all locked numbers were verified. The correct headline, as classified
in report §21, is "Locked model values with source/derived/assumption classifications":
230 kV nominal is source-supported; 0.7 km length is a locked engineering assumption (EA);
2 physical circuits is the locked planning basis (both in service, lumped); Mallard 795 MCM
is the PGCB-documented engineering reference (Ghorasal-Mallard family), not a measured
South-link value; R1/X1/B1 equivalents are derived-from-reference; grid 50 kA is an
ESTIMATED withstand-rating proxy; |Z| is derived from that estimate; R = 0 is an
engineering modelling assumption; R0/X0/C0, thermal rating, tower geometry, mutual coupling,
and destination substation are MISSING (dependent features disabled or scoped out).

## 8. POST regen — reviewer 6-item fix wave (2026-09-18, no full-suite re-run)

Targeted re-runs only (display-string + docs + in-memory runs; full 1368/0 suite NOT
re-run — the wave changes one display `Label` string, report/evidence wording, and
workspace-only sensitivity overrides, with no solver/builder/data-numerics edits, so the
142 s full regression adds no signal beyond the targeted gates):
`test_phase3_line_model` 20/0 PASS; `test_line_data` 53/0 PASS (PASS lines show the new
`SOUTH GIS TO GRID 0.7KM D/C EQ (MALLARD REF)` label flowing through);
`test_phase3_determinism` 5/0 PASS. Length-sensitivity 0.5/0.7/1.0 km in-memory runs on
`LF360_GAT_OUT` (Ds-method, `Write=false`, `bdclose`, script outside repo at
`C:\Users\sindi\AppData\Local\Temp\opencode\task15_lensens.m`): 3/3 Verdict OK,
committed `LOCKED_CHECK` intact (R 0.0277725 / X 0.1425655 / C 1.253503e-08 / R0 MISSING /
grid X 2.655811 / R 0 / Length 0.7).
POST regenerated with the Task 1 command verbatim (output to `PHASE3_POST_HASHES.txt`):
335 lines, Length 35987 bytes, LastWriteTime 2026-09-18 12:16:11 (final refresh after the
task-15 fix-wave appendix; count/length unchanged, hashes current); 335/335 match
`^[0-9A-F]{64}  \.`, 0 absolute-drive lines, 0 `G:\`. Previous POST was 333 lines —
delta +2 lines because `task-14-report.md` and `task-15-report.md` landed after the old
POST (ledger only); the fix wave itself adds zero new hashed files (one display-`Label`
string edit in `ashuganj_lines.m` plus wording-only edits to the hash-excluded report /
changelog and the two hashed evidence notes). No protected-file change.

## 9. REV3.1 reconciliation pass (correction-only, no Phase 4 — 2026-09-18)

Scope: §§1–4 wording/metadata corrections only (Siemens §2.4 provenance, 2000 A bay
modules, `Grid_equivalent_bus`, stability phrasing). No fault/sequence/protection work;
no Rev2 modification; no historical-results modification; no 0.7 km numerics change;
no new struct status strings (closed enum `ashuganj_master_data.m:36-38` honored —
human-tier labels below live in Source/Note/report columns only).

PRE-equivalent (before edits): `docs/validation/rev31_phase3/recon_pre_hashes.txt`,
335 lines, 35987 bytes, 2026-09-18 12:39:08 (Task-1 command verbatim; `.txt`/`.log`
outside hash scope so the recon log itself adds no lines).
POST (after edits): `PHASE3_POST_HASHES.txt`, 335 lines, 35987 bytes, 2026-09-18
13:01:54; 335/335 match `^[0-9A-F]{64}  \.`, 0 absolute-drive lines.
Diff PRE→POST: PRE 335 = POST 335 with ADDED 0, MODIFIED 22, REMOVED 0, UNCHANGED 313.
MODIFIED = the 22 authorized correction hunks below (21 model/test/evidence/spec + 1 ledger
report); no other file changed.

### File | Before | After (12-char prefixes; full hashes in PRE/POST files)

| File | Before (recon PRE) | After (POST) | Changed? | Authorized? | Reason |
|---|---|---|---|---|---|
| `.superpowers/sdd/2026-09-18-phase3-locked-07km-line-model/task-15-report.md` | `9B4D8975E274…` | `E4C090B89768…` | YES | YES (ledger) | This reconciliation pass report section (process ledger, not model). |
| `docs/superpowers/specs/2026-09-18-phase3-line-model-design.md` | `03337E1EB588…` | `FFDEFFC042FC…` | YES | YES (§1) | Design-spec fence reworded to ESTIMATED §2.4 source quantity + DERIVED \|Z\| note. |
|---|---|---|---|---|---|
| `matlab/data/ashuganj_grid.m` | `C7D39788313A…` | `7BE0EF2E9EF4…` | YES | YES (§1+§3) | §2.4 provenance wording (50 kA ESTIMATED source quantity; equipment ratings separate; \|Z\| 2.65581124 DERIVED + XN≈2.66 note); added display/semantic `Grid_equivalent_bus='B230_REMOTE'`; `Bus_boundary` kept for legacy fallback. No numerics. |
| `matlab/data/ashuganj_lines.m` | `9EA336BA15D9…` | `47765186DBDB…` | YES | YES (§2) | BAY_GSUT 3150→2000 + BAY_GRID 3150→2000 (module classes) + BAY_GAT label 10BAY12→10BAY20 with 2000 transformer-bay class + GRID label MISSING note + `Rated_A_Source`/`Bay_label_note` fields. Metadata/labels only; R/X/B/C/L/ckts untouched. |
| `matlab/build/build_external_grid.m` | `81AA5BE1A004…` | `3148C547F892…` | YES | YES (§1) | Comment + diagram-note provenance rewording to §2.4; no block/dialog numerics. |
| `matlab/build/build_230kv_system.m` | `01521BB39250…` | `A1CBA94B33DA…` | YES | YES (§1+§2) | Header comments: bays 2000 A vs 3150 A coupler/busbar module + equipment ratings + bay-number mapping. No blocks/wiring. |
| `matlab/analysis/ashuganj_branch_flows.m` | `6A4B804CE1F3…` | `9EBF2C7DB52C…` | YES | YES (§1) | One reporting-note string to Siemens §2.4; no reconstruction math. |
| `matlab/analysis/make_load_flow_plots.m` | `C90413A9B2A7…` | `0A1997862D38…` | YES | YES (§2) | 3150 A comments/legend/title fenced as bus-coupler/busbar module (bays 2000 A); no plot math. |
| `matlab/gui/gui_tab_plots.m` | `1FED96A2399C…` | `763FE173E55A…` | YES | YES (§1+§2) | Same fencing in plot description strings; no logic. |
| `matlab/data/assumptions/grid_series_resistance_zero.m` | `BDFE6E573558…` | `5705D2571885…` | YES | YES (§1) | Reason/Source reworded to §2.4 source quantity + DERIVED \|Z\| note; R=0 assumption unchanged. |
| `matlab/data/assumptions/gis_bus_coupler_closed.m` | `14810478F901…` | `BA492CC050B4…` | YES | YES (§1+§2) | Source reworded: bay numbers + 3150 coupler/busbar vs 2000 bays + equipment ratings; coupler-state assumption unchanged. |
| `matlab/studies/build_project_update.m` | `68A4B26F2512…` | `0A254F488605…` | YES | YES (§1+§2) | Manual-source strings: equipment row, grid row, dataset-layer line, key-code para, remaining-work item. Sources for HTML regen (HTML not regenerated — see below). |
| `matlab/studies/private/lr_part_theory.m` | `EF247574B92A…` | `3AA19EA8D6C2…` | YES | YES (§1) | Manual source: §2.4 provenance paragraph. |
| `matlab/studies/private/lr_part_data.m` | `42F05B59A598…` | `20B7A3F5B1D1…` | YES | YES (§1) | Manual source: grid-table status cell. |
| `matlab/studies/private/lr_part_calc.m` | `798DD5D85C9C…` | `AAC506552F83…` | YES | YES (§1+§2) | Manual sources: 3150 fencing + §2.4 grid-code block + warning para. |
| `matlab/studies/private/lr_part_next.m` | `5407231016D4…` | `0C0B0CB032A8…` | YES | YES (§1) | Manual sources: collection-table cell + estimated-para. |
| `matlab/studies/private/lr_part_quest.m` | `F64DC8D5A561…` | `1041435CA4A6…` | YES | YES (§1) | Manual source: Q7 question stem. |
| `matlab/studies/private/um_part_care.m` | `63D0E619A462…` | `1EF26511D1D6…` | YES | YES (§1) | Manual source: limitations bullet. |
| `matlab/tests/test_grid_sensitivity.m` | `E3A6E17ACBF1…` | `6D8C506DEACE…` | YES | YES (§1+§3+§6) | Header + Part-1 label + error-direction comment + 3150 fencing + 3 added semantic assertions (§2.4 strings, REMOTE bus). Tolerances/physics untouched. Tests 38→41. |
| `matlab/tests/test_line_data.m` | `487799B8CC3B…` | `A401EBC4D4C1…` | YES | YES (§2+§3+§6) | Bay 2000/2000+GAT-10BAY20 assertions + MISSING-label checks + REMOTE-span + provenance assertions. No physics weakened. Tests 53→63. |
| `matlab/tests/test_topology.m` | `CD36F4A65BD4…` | `8F755054824D…` | YES | YES (§3+§6) | `Grid_equivalent_bus` + Phase-3 ZGRID/L_LINE span assertions + 6-node REMOTE connectivity graph. Tests 52→59. |
| `docs/validation/rev31_phase3/phase3_sensitivity.md` | `397E2A293C78…` | `41CBA7A745C4…` | YES | YES (§4) | Stability sentence replaced verbatim with the mandated load-flow-convergence wording. |

### Protected / Rev2 / historical / solver-untouched verification

- Protected-identical (byte-identical recon-PRE vs POST): `ashuganj_generators.m`,
  `ashuganj_transformers.m`, `ashuganj_loads.m`, `ashuganj_buses.m`,
  `ashuganj_operating_profiles.m`, `validate_operating_profile.m`,
  `run_load_flow_study.m`, `build_ashuganj_main.m`, `ashuganj_bus_map.m`,
  `ashuganj_bus_results.m` — all OK. Builder exception: `build_230kv_system.m`
  changed comments only (authorized above); `build_external_grid.m` comments only.
  No Phase-2 physics numerics touched.
- Rev2 untouched: sampled `rev2/data/ashuganj_rev2_registry.m`,
  `rev2/reports/Rev2_Final_Report.md`, `rev2/tests/*`, `rev2/data/seq_networks.m`
  all byte-identical PRE→POST.
- Historical/benchmarks untouched: operating-profile dispatches (342.01/389.30),
  capability curve, NER, capacity guard — no edits (hash-identical via generators/
  profiles above; full suite confirms 342.01/389.30 levels).
- Solver physics untouched: 0.7 km R 0.0277725 / X 0.1425655 / B 3.937996 uS,
  2 circuits, Mallard ref, grid R 0 / X 2.65581124 / B-equivalent, 50 Hz,
  port-handle wiring — frozen check executed (`recon_frozen.m` FROZEN-OK);
  only bay `Rated_A` metadata (3150→2000 per §2) and label strings moved.
- Manual HTML not regenerated: `docs/manual/*.html` (LAB_REPORT/PROJECT_UPDATE/
  USER_MANUAL/index) were NOT rebuilt — the docs build (`build_lab_report` etc.)
  requires solved `results/load_flow/*.csv` Phase-2 artifacts plus figure copies
  and was not run cleanly in reasonable time during a correction-only pass; the
  .m sources above carry the corrected wording so the next clean docs build
  propagates it. Unregenerated files listed explicitly per brief: `docs/manual/
  LAB_REPORT.html`, `docs/manual/PROJECT_UPDATE.html`, `docs/manual/USER_MANUAL.html`,
  `docs/manual/index.html`.
- Validation: targeted `test_phase3_line_model` 20/0, `test_line_data` 63/0,
  `test_topology` 59/0, `test_grid_sensitivity` 41/0, `test_phase3_determinism` 5/0;
  full `run_all_tests('all')` fresh 1388/0 (ALL PASSED, 159.7 s), log
  `docs/validation/rev31_phase3/task-14b-reconciliation-tests.log` (86043 B).
  First `-nojvm` full run gave 1335/1 with the sole error being
  `plot_generator_capability` under `-nojvm` (environment, not model — both LF cases
  solved OK before the plot call); rerun without `-nojvm` gives 1388/0.
  Net +20 vs 1368/0 = the added semantic assertions (line +10, topology +7, grid +3);
  no tolerance/physics weakened; failures investigated by root cause per §6.
