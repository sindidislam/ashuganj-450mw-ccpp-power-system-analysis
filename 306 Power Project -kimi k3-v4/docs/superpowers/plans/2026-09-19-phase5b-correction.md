# Phase-5b Physical-Alignment Correction — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct Phase-5 into a physically faithful protection model (physical architecture + backup-OC study layer) without rebuilding its validated framework.

**Architecture:** New `phase5b_*` MATLAB modules alongside frozen v1 files (never modify shipped v1 code — v1 manifest traceability); v2 driver writes new tag `production-v2` under `results/phase5_protection_v2/`; old `results/phase5_protection/` frozen untouched; root report updated in place (unhashed living doc) with v2 body + v1 appendix.

**Tech Stack:** MATLAB R2024a, `readtable/writetable` with explicit `'Delimiter',','`, Java SHA-256 helper, `t_case` harness.

**Spec:** `docs/superpowers/specs/2026-09-19-phase5b-physical-alignment-design.md` (parent Phase-5 spec travels too).

## Global Constraints

- Never edit `matlab/data/*`, `matlab/build/*`, `matlab/phase4/*`, `rev2/*`, `PHASE3_*`, `results/phase4_fault/*`, `results/phase5_protection/*` (frozen v1 outputs), or any shipped v1 `matlab/phase5/phase5_*.m` / `matlab/tests/test_phase5_*.m` file (new `phase5b_*` / `test_phase5b_*` files only; v1 suite must keep passing untouched).
- New provenance class USER_ASSERTED_PENDING_DOC allowed only for user-supplied 7UM622 values listed in spec S3; promotion to SOURCE-BACKED only on document ingest.
- Never tune settings/margins to force PASS; honest FAIL + conflict note.
- CTI 0.3 s is CONFIRMED (APSCL + master §21), not an assumption; TMS 0.20 uniform initial per master §21 Status C.
- All MATLAB errors `phase5b`-prefixed (reuse of v1 functions keeps their `phase5` IDs).
- Totals never proxy relay current (branch-current doctrine, hardened).

---

## File Structure (new files only)

- `matlab/phase5/phase5b_source_ledger.m` — transcribed protection-source table (C1)
- `matlab/phase5/phase5b_registry.m` — full v2 device table: 7 v1 rows corrected (1600/1 CTs, TMS 0.20, new CT columns) + physical presence rows (C2/C3/C7)
- `matlab/phase5/phase5b_pickup.m` — v2 pickup rules incl. Siemens DT baseline row (C3/C4)
- `matlab/phase5/phase5b_effectiveness.m` — primary/backup effectiveness table (C8)
- `matlab/phase5/phase5b_validate.m` — v2 legs B01+ (C5/C6/C12)
- `matlab/phase5/phase5b_writer.m` — v2 CSVs + effectiveness table + duty column split (C11)
- `matlab/phase5/run_phase5b_production.m` — v2 driver, tag `production-v2` (C11)
- `matlab/phase5/phase5b_gate.m` — extended gate incl. physical predicates (C14)
- `matlab/phase5/phase5b_tcc.m` — two-class TCCs (physical DT + study SI) (C10)
- `matlab/tests/test_phase5b_*.m` — per-task suites
- `results/phase5_protection_v2/` — v2 outputs (C11)
- Root `PHASE5_FINAL_REPORT.md` — updated in place: v2 body + §20 v1 appendix (C13)

Interfaces (locked):
- `L = phase5b_source_ledger()` → struct array `.source_id,.claim,.value,.locator,.class` (class ∈ SOURCE-BACKED/DERIVED/USER_ASSERTED_PENDING_DOC/ENGINEERING_ASSUMPTION/MISSING).
- `R = phase5b_registry()` → struct `.devices` (v1 21 fields + physical_CT_ratio, selected_CT_core, protection_function, study_CT_ratio, layer ∈ PHYSICAL/STUDY), `.gen` (adds Imax_A 14309), `.topology` (adds breaker_52G `10BAC10`, rating_100kA).
- `P = phase5b_pickup(device, Iload_A, Imin_fault_A)` → v1 fields; Siemens-baseline device (ansi `50/51-DT`) returns setting/unit/basis/source/validation with tdef + `??` flag and NO inverse time.
- `E = phase5b_effectiveness(T40, devices)` → table cols fault_location,fault_type,caseID,primary_function,primary_availability,primary_time_s,backup_function,backup_time_s,ct_source,setting_source,detection,determinable,not_determinable.
- `V = phase5b_validate()` → `.legs` (B01+ legs with pass/residual/note).
- `G = phase5b_gate()` → v1 17 predicates re-run against v2 outputs + physical predicates (armed automatically).

---

### Task C1: Protection source ledger ingest

**Files:** Create `matlab/phase5/phase5b_source_ledger.m`; Test `matlab/tests/test_phase5b_ledger.m`.

**Interfaces:** Consumes: master md §§17–21, Siemens pp.6–7, REV3_PROGRESS verified rows (read-only). Produces `phase5b_source_ledger()` per Interfaces.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase5b_ledger()
T = t_case('test_phase5b_ledger');
L = phase5b_source_ledger();
T = T.chk(isstruct(L)&&all(isfield(L,{'source_id','claim','value','locator','class'})), 'ledger schema');
T = T.chk(any(strcmp({L.source_id},'GIS-CT-1600')&strcmp({L.class},'SOURCE-BACKED')), 'GIS 1600/1 source-backed');
T = T.chk(any(strcmp({L.source_id},'SIEMENS-Igt-1.14A')&strcmp({L.class},'USER_ASSERTED_PENDING_DOC')), '7UM622 I> user-asserted pending doc');
T = T.chk(any(strcmp({L.source_id},'GCB-10BAC10-100kA')&strcmp({L.class},'SOURCE-BACKED')), 'GCB 100 kA source-backed');
T = T.chk(any(strcmp({L.source_id},'CTI-0.3s')&strcmp({L.class},'SOURCE-BACKED')), 'CTI 0.3 confirmed, not assumption');
[np, nf] = T.done();
end
```

Minimum 24 rows covering: Q0/Q1/Q2/Q9/Q51/Q52/Q8, GIS-50kA-withstand, CT-1600/800/400, 7SD5221×2, 7SS523, 6MD66, OC-1.2×load, TMS-0.20, 51N-0.20Asec, EF-TMS-0.15, CTI-0.3, diff-0.30pu/30/60, gen-diff-0.20pu, T1/T2-15000/1 cores, Imax-14309A, I2max-7.64%/K-7.41s, NER-60+2.62??, grid-50kA-estimated, VT-381.05, GCB-10BAC10-100kA, GSUT-1600/1-cores, GIS-bay-1600/1, 7UT6331, GAT-HVN-250/1-T6, UAT-HV-1000/1, 64G/59N/87N/50BF-presence, SIEMENS-Igt-1.14A (USER_ASSERTED_PENDING_DOC), SIEMENS-tdef-3s-?? (USER_ASSERTED_PENDING_DOC + NOT-DETERMINABLE timing), SIEMENS-87G-0.20/5.0 (USER_ASSERTED_PENDING_DOC), SIEMENS-64G-20Hz (USER_ASSERTED_PENDING_DOC).

- [ ] **Step 2: Run test** — `matlab -batch "addpath(genpath('matlab')); [np,nf]=test_phase5b_ledger()"` → FAIL undefined function.
- [ ] **Step 3: Implement** ledger with exact locator strings (`file:line`), e.g. `Ashuganj_South_Final_Master_Data_and_Assumptions (1).md:702`, `REV3_PROGRESS.md:623`, `Generator Data_South.pdf:pp.6-7`.
- [ ] **Step 4: Run test** → PASS.

### Task C2: CT correction + registry v2 (study rows)

**Files:** Create `matlab/phase5/phase5b_registry.m` (study-row half + new columns; physical rows in C7 — same function, two dispatches); Test `matlab/tests/test_phase5b_registry.m`.

- [ ] **Step 1: Test** asserts: GSUT-HV-51 + GIS-Q0-51 `ct_ratio==1600` with `ct_source='SOURCE-BACKED'`; `physical_CT_ratio`/`study_CT_ratio` columns present; GEN CTs 15000/1 unchanged; zero devices with `ct_ratio==2000`; zero with 16000; TMS study rows `==0.20`; sensitivity scope note: 16k applies to generator CT only (assert helper `phase5b_sensitivity_scope('GEN-51')==true`, others false — implement as subfunction or separate tiny file `phase5b_ct_scope.m`).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** v2 study rows (copy v1 values except CT 1600/1, TMS 0.20, new columns; GEN-51-SI pickup recomputed in C4 — registry carries pickup NaN + rule tag `RULE-1.2xMAXLOAD` for recompute by phase5b_pickup; never hard-code).
- [ ] **Step 4: Run** → PASS. v1 suite untouched (run `test_phase5_registry` to confirm still 55/0).

### Task C3: Siemens DT baseline layer

**Files:** Create `matlab/phase5/phase5b_pickup.m` (baseline branch + rule branch; full file); Test `matlab/tests/test_phase5b_pickup.m`.

- [ ] **Step 1: Test** asserts: device `GEN-51-SIEMENS-BL` (ansi `50/51-DT`, layer PHYSICAL, provenance USER_ASSERTED_PENDING_DOC): setting 17171 A (±0.5% band vs 1.2×14309 cross-check inside test), secondary 1.1447 A (±0.5%), `tdef==3.00` with `time_status='NOT-DETERMINABLE-??-PENDING-COORDINATION'`, and `phase5_time` MUST error on it (inverse prohibited — assert `phase5_curve` path never taken: pickup struct carries `curve='DT-??'` and a `use_phase5_time=false` flag); GEN-51-SI variant row separated (`layer=='STUDY'`).
- [ ] **Step 2–4:** TDD. Cross-check constant in test: `abs(1.2*14309-17171)/17171 < 0.005`.

### Task C4: Pickup/TMS re-baseline (study rules)

**Files:** Extend test + implement rule branch in `phase5b_pickup.m` (same files as C3 — second dispatch, fix-loop style).

Rules: GEN-51-SI = 1.20 × 14309 = 17170.8 A (document: max operating current basis; note convergence with Siemens baseline pickup — characteristic differs); GSUT-HV-51 = 1.2×max(1150, 870.7726) = 1380 A via 1600/1; GIS-Q0-51 = 1.2×869.956652 via 1600/1; GEN-51N-SI-STUDY = 5 A retained as sensitive case (scope SENSITIVITY); TMS 0.20 all study rows. Test asserts all four + TMS + secondary consistency (Is_sec = Is/CT).

### Task C5: 8.414 kA audit + rename + regression pin

**Files:** Create `matlab/tests/test_phase5b_branch_audit.m` (no new module — audit test over Phase-4 data + v1 import join).

- [ ] **Step 1: Test** reads production contributions row F1 LG OUT: asserts leg_GEN_kA==8.4141 (±1e-4), kcl residuals <1e-9, and classifies semantics by evidence: prefault GEN_Q anchor (FL_anchor 9.4757 kA from ct_data) vs leg (8.4141) — assert `abs(leg-prefault)/prefault > 0.05` (NOT pure prefault: redistribution present) AND `leg/total > 100` (NOT net fault current) → verdict string `branch-through-current-magnitude`. Asserts import join carries the same number (rename contract: any consumer labelling it must use `branch-through-current`).
- [ ] **Step 2–4:** TDD (pure assertions over read-only data; fails only if data/columns change — loud tripwire by design).

### Task C6: Per-CT min-detect replacing V9 totals logic

**Files:** Create `matlab/phase5/phase5b_mindetect.m` (`M = phase5b_mindetect(T40, devices)` → per (device, element ∈ phase/residual/negseq) minimum branch current over zone-relevant faults + margin vs pickup + verdict); Test `matlab/tests/test_phase5b_mindetect.m`.

Zone relevance: GEN devices ← F1/F2 rows (GEN_Q / 3I0 / I2-from-Iseq2 branch approx — use Iseq2 magnitude×3? No: negative-sequence relay sees branch I2; production gives fault-point Iseq2, not branch. Mark negseq branch NOT DETERMINABLE where branch I2 unavailable — honest); GSUT-HV ← F1/F2/F3 (GSUT_HV leg); GIS-Q0 ← F3/F4/F5 (LINE_Q9/GRID_Q legs). Test asserts: GEN-51-SI min-branch (F1 LG 8414.12 A) < pickup 17170.8 A (blindness reproduced numerically); GEN-51N-SI min 7.272 A > 5 A (detects, margin 1.454); totals (43758.86) appear NOWHERE in detection logic (scan source for `43758` → must be absent).

### Task C7: Physical registry rows + zones + 52G

**Files:** Extend `phase5b_registry.m` (physical rows) + zones in `phase5b_zones.m` (`Z = phase5b_zones()` → zone/device/function/role table G/T/B/L); Test `matlab/tests/test_phase5b_zones.m`.

Presence rows (settings only where sourced): 87G (start 0.20 pu USER_ASSERTED_PENDING_DOC + master-§21 Status-C corroboration note), 46 (capability-sourced note, no pickup invented), 40/32R/21/78/59/81/24/50-27 (presence, MISSING settings), 59N/64G/64R (presence + 381.05 VT datum where relevant), 7UT6331 87T (presence), 87N (presence), 63/49/86 (presence), 87B/7SS523 (presence), 7SD5221×2 (presence), 6MD66 (bay control note), 52G/10BAC10 (12.4 kA/100 kA), UAT/GAT functions per CT tables. Primary mapping assertions: F1→87G, F2→87T, F3→87B, F4→7SD (in zone table). Trip matrix fields all `NOT-DETERMINABLE`.

### Task C8: Effectiveness table (mandatory §15)

**Files:** Create `matlab/phase5/phase5b_effectiveness.m`; Test `matlab/tests/test_phase5b_effectiveness.m`.

Per (case,loc,type) backbone row: primary_function (zone-mapped), primary_availability (ASSERTABLE-DETECT / NOT-DETERMINABLE), primary_time_s (45 ms derived fast-main clearing where 87-class detection assertable and breaker identified, else NaN + reason; 7SD/87B timing NaN — settings missing), backup rows from v2 coord inputs, ct_source, setting_source, detection, determinable/not-determinable text. Detection rule (locked): internal fault + max terminal branch ≥ sourced pickup → ASSERTABLE-DETECT (document inward-flow justification in code comment); else NOT-DETERMINABLE (never invented). Test: F1 LLL 87G ASSERTABLE-DETECT (55.05 kA ≫ 0.20 pu×12019 ≈ 2.4 kA); F3 87B detection assertable, time NaN; F4 7SD detection assertable ONLY if branch evidence supports (else NOT-DETERMINABLE — assert whichever the data supports, documented).

### Task C9: Duty correction (52G + column split)

**Files:** Reuse `phase5_duty` engine (no new module); writer (C11) adds `equipment_rating_kA` + `equipment_basis` columns. Test `matlab/tests/test_phase5b_duty.m` drives `phase5_duty` with 52G rating struct: GEN_Q branch per fault vs 100 kA → verdicts (F1 LLL 55.05 kA → PASS; document IN-case max honestly whatever it is); Q0 rows unchanged NOT DETERMINABLE; GIS-50kA-withstand appears ONLY in equipment columns, never as interrupting rating (assert `rating_kA` NaN on Q0 rows + equipment column == 50).

### Task C10: Two-class TCCs

**Files:** Create `matlab/phase5/phase5b_tcc.m`; Test `matlab/tests/test_phase5b_tcc.m`.

Class A (physical): GEN DT I> 17,171 A vertical + 3 s?? dashed-unconfirmed line (labelled ?? PENDING), 87G pickup band marker (no curve invented). Class B (study): SI curves TMS 0.20 with v2 pickups via 1600/1 CTs. Outputs `results/phase5_protection_v2/plots/tcc_physical.png`, `tcc_study.png`. Test: files exist/non-zero; no manufacturer strings; DT line labelled ??; classes visually separated (separate files assertion).

### Task C11: v2 writer + production-v2 driver

**Files:** Create `matlab/phase5/phase5b_writer.m`, `matlab/phase5/run_phase5b_production.m` (tag `production-v2` → `results/phase5_protection_v2/`).

Schemas: v2 registry/settings/inputs/currents/coord/margins/duty(+2 equipment cols)/sensitivity/validation + NEW effectiveness table + manifest (input SHA = v1 production SHA + v1 outputs referenced, code hashes incl. phase5b_* + v1 modules used) + sha256 + run_log. Overwrite guard `phase5b_production:exists`. Provenance enforcement incl. USER_ASSERTED_PENDING_DOC as legal class. Test `test_phase5b_writer.m`: schemas, guard errors, class whitelist (SOURCE-BACKED/DERIVED/ENGINEERING_ASSUMPTION/LEGACY/MISSING/USER_ASSERTED_PENDING_DOC — anything else errors).

### Task C12: v2 validation legs

**Files:** Create `matlab/phase5/phase5b_validate.m` (legs B01–B13 per spec §17 + R0 re-import identity) + runner addition (extend `run_phase5_tests`? NO — v1 file frozen. New `run_phase5b_tests.m` running test_phase5b_* + phase5b_validate).

Legs: B01 CT mapping (1600/1 GSUT/GIS, core columns, 16k-scope-gen-only), B02 Siemens baseline (17,171/1.1447/DT-??/inverse-prohibited), B03 variant separation, B04 branch-not-total (43758 absent from detection), B05 52G presence+100 kA, B06 zone mapping + F-mapping, B07 F3→87B (detect vs time split), B08 F4→7SD, B09 51N/59N/64G split, B10 rating split (equipment≠interrupting), B11 8.414 kA trace (delegates C5 test), B12 no-conflation (no PHYSICAL row carries STUDY numbers and vice versa — cross-scan), B13 R0 identity (same tolerances as v1 R0).

### Task C13: Report rewrite (reclassify + §15 table + v1 appendix)

**Files:** Modify root `PHASE5_FINAL_REPORT.md` (living unhashed deliverable — allowed) — v2 body + §20 v1-appendix (frozen v1 numbers: settings 15023.75/5/1380/1043.95, FAIL=20/PASS=0, 40 NOT-DET duty, 344/0 suite).

Language: S1 classes enforced; forbidden list extended with `actual plant settings|commissioned settings|Siemens settings` (unless sourced), `plant protection failure`, `Generator earth-fault protection validated`. Effectiveness explanation (§16 per review). Self-scan test? Add `test_phase5b_report.m`: scans report for forbidden strings (0 hits) + spot numbers (1043→ replaced by v2 GIS pickup value; FAIL-distribution line matches v2 CSVs).

### Task C14: Extended gate + deliverable

**Files:** Create `matlab/phase5/phase5b_gate.m` (v1 17 predicates re-pointed at v2 outputs + B-predicates: physical rows present, 2000/1 absent, 16000 only gen-sensitivity, DT-?? flagged, report-vs-v2-CSV spots) + test; deliverable A–M assembly as in v1 T20 (no code changes, read-only).

## Self-Review

- Spec coverage: S1→C13; S2→C1; S3→C1/C3/C12-B02; S4→C2/C12-B01; S5→C3/C10; S6→C4; S7→C5/C6/C12-B04/B11; S8→C7/C8; S9→C9/C11; S10→C10/C11/C13/C14. All covered.
- Placeholder scan: no TBD/TODO; every step has exact code/values/commands.
- Type consistency: `phase5b_registry().devices` extends v1 21 fields (+4 named); pickup interface mirrors v1 + flags; effectiveness cols fixed C8/C11; gate reuses v1 predicate IDs P01–P17 + B01+.
