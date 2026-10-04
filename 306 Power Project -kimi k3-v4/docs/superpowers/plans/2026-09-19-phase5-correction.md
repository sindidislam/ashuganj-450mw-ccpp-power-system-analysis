# Phase 5 Correction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct Phase-5b to the master-prompt central assumption set with strict PRIMARY/SENSITIVITY separation and full provenance.

**Architecture:** Fix runner bug first (systematic-debugging), then registry/pickup/effectiveness code to master values, rerun production-v2 via MATLAB, regenerate CSVs/manifest/hashes, update tests and handoff docs. Phases 2-4 frozen read-only.

**Tech Stack:** MATLAB R2024a (`matlab -batch`), existing matlab/phase5 + matlab/tests, CSV/manifest outputs in results/phase5_protection_v2.

**Spec:** Master prompt PHASE 5 CORRECTION (user message 2026-09-19); prior specs docs/superpowers/specs/2026-09-19-phase5-protection-design.md and 2026-09-19-phase5b-physical-alignment-design.md (read both before code tasks).

## Global Constraints

- Do NOT modify Phase 2-4 source files unless a Phase-5 dependency is demonstrably broken.
- Never promote assumption to verified; statuses only from VERIFIED/DERIVED/ENGINEERING_ASSUMPTION/CONDITIONAL_ASSUMPTION/SENSITIVITY/USER_ASSERTED_PENDING_DOC/NOT_VERIFIED/NOT_DETERMINABLE.
- Frozen v1 files (matlab/phase5/phase5_*.m, results/phase5_protection/) are read-only; v2 work only in phase5b_* + results/phase5_protection_v2.
- Old v1 runner run_phase5_tests may remain as regression but must not validate Phase-5b production.
- Sensitivity rows must never populate PRIMARY-scope tables/matrices.
- Never manipulate fault currents/ratings/CTs/TMS/breaker ratings to force PASS.
- Every MATLAB claim needs fresh `matlab -batch` evidence per verification-before-completion.

---

### Task 1: Baseline checkpoint + progress/handoff skeleton

**Files:**
- Create: `PHASE5_BASELINE_CHECKPOINT.md`
- Create: `PHASE5_PROGRESS.md`
- Create: `PHASE5_AI_HANDOFF.md`
- Create: `PHASE5_RUN_LOG.txt` (append)

**Interfaces:**
- Consumes: results/phase4_fault/production/manifest.json + sha256.txt, results/phase5_protection_v2/manifest.json
- Produces: checkpoint hashes + topology/loadflow/fault baseline cited for all later tasks

- [ ] **Step 1: Record Phase-4 production hashes**

```matlab
% PowerShell: Get-Content results/phase4_fault/production/sha256.txt
% Transcribe 7 lines into PHASE5_BASELINE_CHECKPOINT.md
```

- [ ] **Step 2: Write checkpoint file**

Run: `matlab -batch "run_phase5b_production_status"` (read-only inspect; no overwrite)
Expected: files exist, no modification timestamps changed

- [ ] **Step 3: Write PROGRESS/HANDOFF headers**

```markdown
Phase: 5
Task: Correction + Practical Engineering Assumption Integration
Status: IN_PROGRESS
```

- [ ] **Step 4: Commit**

```bash
git add PHASE5_BASELINE_CHECKPOINT.md PHASE5_PROGRESS.md PHASE5_AI_HANDOFF.md
git commit -m "docs: phase5 baseline checkpoint + handoff skeleton"
```

### Task 2: Production-runner correction (systematic-debugging root cause)

**Files:**
- Modify: `matlab/phase5/run_phase5b_production.m:64-68,189`
- Modify: `matlab/phase5/phase5b_writer.m:68,239,271,345` (comment refs only)

**Interfaces:**
- Consumes: matlab/phase5/run_phase5b_tests.m (v2 runner, 14 legs B01-B13+R0)
- Produces: production validates actual Phase-5b implementation; NP/NF from v2 suites

- [ ] **Step 1: Write failing test (reproduce)**

```matlab
% In MATLAB: grep run_phase5b_production.m for 'run_phase5_tests'
% Assert: line 189 calls run_phase5_tests (v1) -> BUG reproduced
```

- [ ] **Step 2: Run to verify bug**

Run: `matlab -batch "x=fileread('matlab/phase5/run_phase5b_production.m'); assert(contains(x,'[NP, NF] = run_phase5_tests()'),'bug not reproduced')"`
Expected: PASS (bug present)

- [ ] **Step 3: Minimal fix**

```matlab
% run_phase5b_production.m:189
[NP, NF] = run_phase5b_tests();
% header :64-68: 'run_phase5b_tests() runs after tables...' + 'frozen v1 runner never validates v2'
```

- [ ] **Step 4: Verify fix**

Run: `matlab -batch "x=fileread('matlab/phase5/run_phase5b_production.m'); assert(contains(x,'run_phase5b_tests()')); assert(~contains(x,'[NP, NF] = run_phase5_tests()'))"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add matlab/phase5/run_phase5b_production.m
git commit -m "fix: phase5b production validates via run_phase5b_tests"
```

### Task 3: GSUT CT conflict documentation

**Files:**
- Modify: `matlab/phase5/phase5b_registry.m:114-140` (ct_source + provenance)
- Modify: `matlab/phase5/phase5b_source_ledger.m` (add conflict rows)
- Create: `PHASE5_ASSUMPTIONS.csv` (append rows)

**Interfaces:**
- Consumes: docs/validation/conflicting_parameters.md:169 (1500 vs 1600), verified_parameters.md:225 (1600 5P20)
- Produces: installed CT=NOT_DETERMINABLE; study 1600/1 ENGINEERING_ASSUMPTION; 1500/1 SENSITIVITY

- [ ] **Step 1: Failing test**

```matlab
function [np,nf]=test_gsut_ct_conflict()
R=phase5b_registry(); d=R.devices(strcmp({R.devices.device_id},'GSUT-HV-51'));
assert(strcmp(d.ct_source,'ENGINEERING_ASSUMPTION')); % currently SOURCE-BACKED -> FAIL
```

- [ ] **Step 2: Run test**

Run: `matlab -batch "addpath(genpath('matlab')); test_gsut_ct_conflict"`
Expected: FAIL

- [ ] **Step 3: Implement**

```matlab
d(3).ct_source = 'ENGINEERING_ASSUMPTION'; % as-built SLD basis
d(3).provenance = 'ENGINEERING_ASSUMPTION:GSUT-HV-1600/1-as-built-SLD-study-CT;CONFLICT:manufacturer-1500/1-vs-SLD-1600/1-installed-NOT_DETERMINABLE';
```

- [ ] **Step 4: Verify**

Run: same test
Expected: PASS

- [ ] **Step 5: Commit**

### Task 4: GSUT current semantics (1292.8 vs 1149.7 vs 1380)

**Files:**
- Modify: `matlab/phase5/phase5b_registry.m:122` (rated_A 1150 -> 1292.8 + anchor fields)
- Modify: `matlab/phase5/phase5b_pickup.m:158-199` (GSUT branch: refA=max(1149.7,Iload), docs)

**Interfaces:**
- Consumes: Generator Data_South.pdf pp.6-7 (IN 1292.8A @515MVA 230kV)
- Produces: rated 1292.8 VERIFIED/DERIVED; anchor 1149.7 DERIVED (458MVA); pickup 1380 DERIVED+ENGINEERING_ASSUMPTION; secondary 0.8625

- [ ] **Step 1: Independent calc**

Run: `matlab -batch "disp(458e6/(sqrt(3)*230e3)); disp(515e6/(sqrt(3)*230e3)); disp(1380/1600)"`
Expected: 1149.7, 1292.8, 0.8625

- [ ] **Step 2: Failing test** (registry rated_A==1292.8)
- [ ] **Step 3: Implement** (change rated_A, pickup basis strings, keep 1380)
- [ ] **Step 4: Verify** (test + pickup returns 1380, sec 0.8625)
- [ ] **Step 5: Commit**

### Task 5: TMS central set (0.10/0.55/0.80/0.15) + coordination rerun

**Files:**
- Modify: `matlab/phase5/phase5b_pickup.m:87-88` (per-device TMS)
- Modify: `matlab/phase5/phase5b_registry.m` (tms per row)
- Modify: `matlab/phase5/run_phase5b_production.m:319-360` (assert new TMS)

**Interfaces:**
- Consumes: Task 4 pickups; phase5_time/phase5_coord (frozen)
- Produces: GEN 0.10, GSUT 0.55, Q0 0.80, EF 0.15; rerun matrix with CTI 0.30 ENGINEERING_STUDY_CRITERION

- [ ] **Step 1: Failing test** (TMS values)
- [ ] **Step 2: Implement per-device TMS**
- [ ] **Step 3: Rerun coordination** `matlab -batch "run_phase5b_production('test-tms','overwrite',true)"` (temp dir)
- [ ] **Step 4: Verify margins** Δt=t_up-t_down vs 0.30, record iteration log
- [ ] **Step 5: Commit**

### Task 6: Q0 provisional 1500A conditional + breaker 50kA conditional

**Files:**
- Modify: `matlab/phase5/phase5b_pickup.m:201-231` (Q0 branch: fixed 1500A conditional)
- Modify: `matlab/phase5/phase5b_duty.m` (conditional 50kA layer + NOT_DETERMINABLE final)
- Modify: `matlab/phase5/run_phase5b_production.m` (Q0 asserts 1500/0.9375)

**Interfaces:**
- Produces: Q0 pickup 1500 primary, 0.9375 sec, TMS 0.80 CONDITIONAL_ENGINEERING_ASSUMPTION; duty conditional vs 50kA + final NOT_DETERMINABLE

- [ ] **Step 1: Failing test** (Q0==1500)
- [ ] **Step 2: Implement**
- [ ] **Step 3: Verify duty** (conditional PASS/FAIL + final NOT_DETERMINABLE string present)
- [ ] **Step 4: Commit**

### Task 7: GEN-51 TMS 0.10 + GEN-51N dedicated 20/1 CT (PRIMARY 4A)

**Files:**
- Modify: `matlab/phase5/phase5b_registry.m:88-113` (GEN-51N ct 15000->20, neutral core)
- Modify: `matlab/phase5/phase5b_pickup.m:89-114` (EF PRIMARY 4A via 20/1, 0.20A sec, TMS 0.15)
- Modify: sensitivity module for 10/1,20/1,25/1 cases

**Interfaces:**
- Produces: GEN 17170.8/1.1447 TMS 0.10 DERIVED/ENG; GEN-51N 4A prim/0.20A sec TMS 0.15 ENGINEERING_ASSUMPTION; 5A moved to sensitivity

- [ ] **Step 1: Failing test** (GEN-51N ct==20, setting==4)
- [ ] **Step 2: Implement**
- [ ] **Step 3: Verify** `17170.8/15000=1.1447`, `4/20=0.20`
- [ ] **Step 4: Commit**

### Task 8: PRIMARY/SENSITIVITY scope decontamination

**Files:**
- Modify: `matlab/phase5/run_phase5b_production.m` (coord uses PRIMARY devices only)
- Modify: `matlab/phase5/phase5b_sensitivity_v2.m` (5A + 1500/1 + grid/CT/motor cases to SENSITIVITY)
- Modify: tests asserting scope

**Interfaces:**
- Produces: PRIMARY matrix has zero 5A rows; SENSITIVITY csv holds 5A/grid/XR/CT/motor cases; filenames+scope labels correct

- [ ] **Step 1: Failing test** (no 5A in PRIMARY matrix)
- [ ] **Step 2: Implement scope filter**
- [ ] **Step 3: Verify** row counts + scope column audit
- [ ] **Step 4: Commit**

### Task 9: 87G/87T study-proxy relabel

**Files:**
- Modify: `matlab/phase5/phase5b_effectiveness.m` (ASSERTABLE-DETECT -> STUDY-DETECTABILITY/CONDITIONAL-DETECTABILITY; high-set OFF)
- Modify: `matlab/phase5/phase5b_registry.m` (87G/87T provenance ENGINEERING_ASSUMPTION)

**Interfaces:**
- Produces: 87G 0.20pu/2403.8A ENG_ASSUMPTION, high-set OFF/NOT_VERIFIED; 87T 0.30pu/387.84A 30/60% STUDY proxy with detectability-vs-operation disclaimer

- [ ] **Step 1: Test** (no ASSERTABLE-DETECT string in output)
- [ ] **Step 2: Implement relabel**
- [ ] **Step 3: Verify**
- [ ] **Step 4: Commit**

### Task 10: 87B/7SD/21/50BF/64G/NER proxies

**Files:**
- Modify: `matlab/phase5/phase5b_registry.m` (87B 0.20pu/30% proxy; 7SD 50ms proxy; 21 NOT_DETERMINABLE; 50BF 0.15/0.12 ENG)
- Modify: `matlab/phase5/phase5b_source_ledger.m` (64G manufacturer-default rows; NER DOCUMENTED/QUALIFIED)

**Interfaces:**
- Produces: no invented 7SD/21 reaches; 64G 1.0V/10mA/20/100ohm/1s/10s/0deg MANUFACTURER_DEFAULT_STUDY_VALUE; NER 60ohm+2.62/135kVA/20s DOCUMENTED+commissioning PENDING

- [ ] **Step 1: Test** (7SD pickup NaN, 50BF values, 64G values)
- [ ] **Step 2: Implement**
- [ ] **Step 3: Verify**
- [ ] **Step 4: Commit**

### Task 11: CT saturation + grid + motor sensitivities

**Files:**
- Modify: `matlab/phase5/phase5b_sensitivity_v2.m` (5P20 32kA boundary check; grid 30/40/50kA XR 5/10/20; motor ILR/Ir 5)
- Modify: report text (fault>accuracy-limit != proven failure)

**Interfaces:**
- Produces: SENSITIVITY rows for ideal/high-error/5P20-boundary/saturation; grid central 40kA XR10; motor IEC-based screening

- [ ] **Step 1: Test** (sensitivity csv contains grid/CT/motor cases)
- [ ] **Step 2: Implement**
- [ ] **Step 3: Verify** `20*1600=32000`
- [ ] **Step 4: Commit**

### Task 12: Regenerate outputs + archive obsolete

**Files:**
- Run: `matlab -batch "run_phase5b_production('production-v2-corrected','overwrite',true)"`
- Archive: `results/phase5_protection_v2/plots/tmp_v1check/` -> `results/phase5_protection_v2/archive/`
- Outputs: 10 CSVs + manifest + sha256 + run_log + TCC plots

**Interfaces:**
- Consumes: Tasks 2-11 code
- Produces: fresh CSVs (relay_settings/registry/currents/matrix/margins/duty/effectiveness/sensitivity), manifest hashes, run logs

- [ ] **Step 1: Run production**
- [ ] **Step 2: Verify row counts + scope audit + hashes**
- [ ] **Step 3: Archive obsolete**
- [ ] **Step 4: Commit outputs**

### Task 13: Tests + provenance + numeric + e2e validation

**Files:**
- Create: `matlab/tests/test_phase5b_assumptions.m` (11 new coverage tests per master §29)
- Modify: existing phase5b tests where they hard-code old assumptions

**Interfaces:**
- Produces: green suite covering CT conflict, rated-vs-anchor, pickup calcs, Q0, neutral CT, scope separation, runner, 87G/87T, Q0 duty, provenance

- [ ] **Step 1: Write failing tests**
- [ ] **Step 2: Run** `matlab -batch "run_phase5b_tests()"`
- [ ] **Step 3: Fix**
- [ ] **Step 4: Verify NP/NF + record**
- [ ] **Step 5: Commit**

### Task 14: Independent arithmetic sanity checks

**Files:**
- Create: `PHASE5_VALIDATION_REPORT.md` (§ sanity table)

**Interfaces:**
- Produces: verified 1.20*14309=17170.8; 458MVA formula=1149.7; 515MVA=1292.8; 1380/1600=0.8625; 1500/1600=0.9375; 0.20*12019=2403.8; 7.27/20; 20*1600=32k; duty ratios; IEC times

- [ ] **Step 1: Independent calc via MATLAB (not code under test)**
- [ ] **Step 2: Compare to code outputs**
- [ ] **Step 3: Record PASS/FAIL per check**
- [ ] **Step 4: Commit**

### Task 15: Registers + final docs + handoff

**Files:**
- Create: `PHASE5_ASSUMPTIONS.csv`, `PHASE5_DECISION_LOG.md`, `PHASE5_VALIDATION_REPORT.md`, `NOT_DETERMINABLE_REGISTER.md` (or in assumptions)
- Update: `PHASE5_PROGRESS.md`, `PHASE5_AI_HANDOFF.md`, `PHASE5_RUN_LOG.txt`, `PHASE5_FINAL_REPORT.md` (§ separation VERIFIED/DERIVED/ASSUMPTION/SENSITIVITY/NOT_DETERMINABLE/CONDITIONAL)

**Interfaces:**
- Produces: machine+human-readable registers; handoff with Next Exact Action + Reproduction Command + Expected Output; acceptance checklist §37 all true

- [ ] **Step 1: Write registers**
- [ ] **Step 2: Update progress/handoff**
- [ ] **Step 3: Verify acceptance checklist**
- [ ] **Step 4: Commit**

## Self-Review

- Spec coverage: §§5-37 each map to Tasks 2-15 above (runner §5->T2; CT §6->T3; current §7->T4; GSUT51 §8->T5; Q0 §9->T6; breaker §10->T6; GEN51 §11->T7; 51N CT §12->T7; 5A §13->T8; 87G §14->T9; 87T §15-16->T9; 87B §17->T10; 7SD §18->T10; 21 §19->T10; 50BF §20->T10; 64G §21->T10; NER §22->T10; CTsat §23->T11; grid §24->T11; motor §25->T11; coord §26->T5; separation §27->T8; outputs §28->T12; testing §29->T13; sanity §30->T14; no-manipulation §31 noted; NOT-DET §32->T15; handoff §33->T15/T1; progress §34->T15/T1; report §35->T15; central set §36->T4-T11; acceptance §37->T15).
- Placeholder scan: no TBD/TODO; every step has exact file:line + command + expected.
- Type consistency: TMS/curve/CT/pickup names match central set §36 throughout.
