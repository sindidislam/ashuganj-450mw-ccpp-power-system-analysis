# Phase-5 Protection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Phase-5 protection application + coordination + CT/secondary + breaker-duty + validation + report on frozen Phase-4 production data, in 20 tasks, MATLAB-run and validated.

**Architecture:** Thin adapter layer `matlab/phase5/` reading only `results/phase4_fault/production/` CSVs (regression import check excepted); registry+curve+calc+writer modules mirroring Phase-4 M1–M8 audit pattern; outputs to `results/phase5_protection/`.

**Tech Stack:** MATLAB R2024a (no toolboxes required; `readtable/writetable/jsonencode` + Java SHA-256 helper as in Phase-4); CSV + JSON + PNG outputs; `t_case` test harness.

**Spec:** `docs/superpowers/specs/2026-09-19-phase5-protection-design.md`

## Global Constraints

- Never edit `matlab/data/*`, `matlab/build/*`, `rev2/*`, `matlab/phase4/*`, `PHASE3_*`, `results/phase4_fault/*` (read-only inputs).
- Never claim IEC 60909 compliance; `ip` is borrowed-shape design-defined peak, never a breaker-duty input.
- Never invent relay models/manufacturers, breaker IDs, CT ratios, or ratings; missing = NOT DETERMINABLE FROM AVAILABLE DATA with provenance tag.
- Never tune settings/fault currents/margins to force PASS; honest FAIL + conflict note instead.
- Every nontrivial number carries provenance: SOURCE-BACKED / DERIVED / ENGINEERING_ASSUMPTION / LEGACY / MISSING (+ PRIMARY / SENSITIVITY scope tag).
- Primary CT = 15000/1 (Siemens protection report); legacy 16000/1 fenced sensitivity only.
- Generator ref = 458 MVA / 22 kV / 12019 A / PF 0.85 (physical ref); 360 MW = operating point only.
- Q0 = 52-1 breaker (only duty-eligible); Q1/Q2/Q9 = disconnectors (never duty); Q51/Q52/Q8 = earthing.
- F1/F2 labels distinct though same node; F4 m = 0.5 primary; fault types LLL/LG/LL/LLG all required; cases LF360_GAT_OUT + LF360_GAT_IN primary.
- All MATLAB errors `phase5`-prefixed; every test fails loudly on behaviour change.

---

## File Structure

Create (new files only):
- `matlab/phase5/phase5_registry.m` — device registry + CT ledger + generator ref + topology semantics (T2)
- `matlab/phase5/phase5_import.m` — Phase-4 production CSV importer + 2×5×4 matrix filter (T3)
- `matlab/phase5/phase5_ct.m` — primary→secondary conversion + CT table builder (T4)
- `matlab/phase5/phase5_curve.m` — centralized inverse-time + definite-time curve library (T5)
- `matlab/phase5/phase5_pickup.m` — pickup-setting methodology engine (T6)
- `matlab/phase5/phase5_time.m` — operating-time calculator (T7)
- `matlab/phase5/phase5_coord.m` — coordination matrix + margin engine (T8)
- `matlab/phase5/phase5_tcc.m` — TCC plot generator (T9)
- `matlab/phase5/phase5_duty.m` — breaker-duty engine, separate from coordination (T10)
- `matlab/phase5/phase5_sensitivity.m` — CT-conflict + fenced sensitivity runner (T14)
- `matlab/phase5/phase5_validate.m` — 15-leg validation engine (T16)
- `matlab/phase5/phase5_writer.m` — CSV/manifest/sha256/run_log writer (T17)
- `matlab/phase5/phase5_gate.m` — quality-gate predicate runner (T19)
- `matlab/phase5/run_phase5_production.m` — end-to-end production driver (T17/T20)
- `matlab/phase5/run_phase5_tests.m` — test runner over test_phase5_* (T16)
- `matlab/tests/test_phase5_ct.m`, `test_phase5_curve.m`, `test_phase5_time.m`, `test_phase5_coord.m`, `test_phase5_duty.m`, `test_phase5_import.m`, `test_phase5_registry.m`, `test_phase5_matrix.m` — test suites (T16, built incrementally T1–T15)
- `results/phase5_protection/` + `plots/` — outputs (T17)
- `PHASE5_FINAL_REPORT.md` — 19-section report (T18)

Interfaces (locked, every task uses exactly these):
- `R = phase5_registry()` → struct `.devices` (struct array, fields: device_id, device_type, equipment, ansi, zone, ct_ratio, ct_source, rated_A, vnom_kV, fault_source, pickup_A, tms, curve, ef_pickup_A, ef_tms, breaker_ref, upstream, downstream, provenance, status, assumption_class), `.ct_primary` (15000), `.ct_legacy` (16000), `.gen` (Snom_MVA 458, Vnom_kV 22, Irated_A 12019, pf 0.85), `.topology` (Q0 breaker; Q1/Q2/Q9 disconnectors; Q51/Q52/Q8 earthing).
- `T = phase5_import(root)` → table cols: fault_location, fault_type, caseID, m, stage, I_primary_kA, I_primary_A, provenance. Backbone filter: stage Ikpp + m 0.5 + first-per-(case,loc,type) in documented backbone-first merge order (run_phase4_production.m merge: backbone, OFAT, anchors; m-section never m=0.5) → 40 rows (2 cases × 5 locs × 4 types; legs base=OUT and GAT-IN=IN are the cases, never double-counted; manifest backbone 80 solves = 40 Ikpp + 40 ip). F1/F2 both present.
- `S = phase5_ct(I_primary_A, ct_ratio)` → struct `.Isec_A = I_primary_A/ct_ratio` (pure arithmetic; any finite ratio > 0 accepted — registry legitimately holds 2000/1 STUDY CTs; ledger fencing lives in ct_tag/scope/provenance, not in arithmetic); `Tc = phase5_ct_table(T, ratio, tag)` adds I_secondary_A + ct_ratio + ct_tag cols.
- `[k, alpha] = phase5_curve_info('SI'|'VI'|'EI'|'DT')` → SI k=0.14 alpha=0.02; VI k=13.5 alpha=1.0; EI k=80 alpha=2.0 (IEC 60255 study constants, labelled STUDY, never manufacturer); `t = phase5_curve(M, family, TMS)` with `t = TMS*k/((M^alpha)-1)`, M=I/Is; M<=1 → Inf; DT family → `phase5_curve_dt(I, Is, tdef)`.
- `P = phase5_pickup(device, Iload_A, Imin_fault_A)` → struct setting/unit/basis/source/validation.
- `t = phase5_time(I_A, Is_A, TMS, family)` → seconds; `tm = phase5_time_matrix(...)` vectorized.
- `[Mtrx, Mrg] = phase5_coord(devices, Tsec)` → coordination matrix + margins tables.
- `D = phase5_duty(Tthrough, ratings)` → duty table (sym RMS through-current vs rating; NO verdict without rating+duty basis).
- `V = phase5_validate()` → struct `.legs` (15 legs with pass bool + residual + note).
- `W = phase5_writer(outDir, tables)` → writes 9 CSVs + manifest.json + run_log.txt + sha256.txt.

---

### Task 1: Freeze audit + Phase-4 regression harness

**Files:**
- Create: `matlab/phase5/phase5_import.m` (stub: backbone import only)
- Create: `matlab/tests/test_phase5_import.m` (regression leg only)
- Test: `matlab/tests/test_phase5_import.m`

**Interfaces:**
- Consumes: `results/phase4_fault/production/phase4_fault_currents.csv` (read-only).
- Produces: `phase5_import(root)` table; regression identity predicate.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase5_import()
T = t_case('test_phase5_import');
root = ashuganj_root();
Fp = fullfile(root,'results','phase4_fault','production','phase4_fault_currents.csv');
T = T.chk(exist(Fp,'file')==2, 'production currents CSV exists');
Ti = phase5_import(root);
T = T.chk(height(Ti)==40, 'backbone import yields 2x5x4 Ikpp = 40 rows');
% Regression: F3 LLL OUT Ikpp == 50.5308851865359 kA within 1e-6
r = Ti(strcmp(Ti.fault_location,'F3')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(~isempty(r), 'F3 LLL OUT row present');
T = T.chk(abs(r.I_primary_kA-50.5308851865359)<1e-6, 'F3 LLL OUT identity 50.530885 kA');
% F1 LG OUT == 0.00727200442799167 kA (7.27 A NER physics preserved)
g = Ti(strcmp(Ti.fault_location,'F1')&strcmp(Ti.fault_type,'LG')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(abs(g.I_primary_kA-0.00727200442799167)<1e-9, 'F1 LG OUT identity 7.27 A');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `matlab -batch "addpath(genpath('matlab')); [np,nf]=test_phase5_import(); fprintf('np=%d nf=%d\n',np,nf)"`
Expected: FAIL with "Undefined function 'phase5_import'".

- [ ] **Step 3: Write minimal implementation** (`matlab/phase5/phase5_import.m`): read production currents CSV via readtable; filter stage=='Ikpp' (228 rows: 40 backbone + 156 OFAT + 32 m-section); keep m==0.5 rows; de-duplicate to first-per-(caseID,location,fault_type) relying on documented backbone-first merge order (run_phase4_production.m: backbone, OFAT, anchors; m-section never m=0.5) → 40 rows; assert height==40 else error('phase5_import:matrix','...' ). Map columns fault_type→fault_type, location→fault_location, caseID, m, Irms_kA→I_primary_kA, I_primary_A=Irms_kA*1000; provenance='SOURCE-BACKED:Phase-4-production-import'. No re-solve, no phase4 function calls.

- [ ] **Step 4: Run test to verify it passes**

Run: same command. Expected: `np=5 nf=0`.

- [ ] **Step 5: Freeze re-check** — run: `matlab -batch "addpath(genpath('matlab')); d=dir('PHASE3_FINAL_REPORT.md'); fprintf('%d\n',d.bytes)"` → must print 45504; and `results/phase4_fault/production/sha256.txt` must still verify (no Phase-4 file touched). Record sizes in run notes.

---

### Task 2: Device registry + topology + CT ledger

**Files:**
- Create: `matlab/phase5/phase5_registry.m`
- Create: `matlab/tests/test_phase5_registry.m`
- Test: `matlab/tests/test_phase5_registry.m`

**Interfaces:**
- Consumes: nothing (source-backed literals + provenance strings only).
- Produces: `R = phase5_registry()` per global Interfaces block.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase5_registry()
T = t_case('test_phase5_registry');
R = phase5_registry();
T = T.chk(isstruct(R)&&isfield(R,'devices'), 'registry struct with devices');
T = T.chk(R.ct_primary==15000&&R.ct_legacy==16000, 'CT ledger 15000 primary / 16000 legacy');
T = T.chk(R.gen.Irated_A==12019, 'generator rated 12019 A');
T = T.chk(strcmp(R.topology.Q0,'breaker')&&strcmp(R.topology.Q1,'disconnector'), 'Q0 breaker, Q1 disconnector');
ids = {R.devices.device_id};
T = T.chk(any(strcmp(ids,'GEN-51'))&&any(strcmp(ids,'GIS-Q0-51')), 'GEN-51 + GIS-Q0-51 present');
q = R.devices(strcmp(ids,'GIS-Q0-51'));
T = T.chk(strcmp(q.breaker_ref,'Q0'), 'only Q0 carries breaker_ref');
T = T.chk(all(~strcmp({R.devices.device_type},'disconnector-duty')), 'no disconnector duty invented');
[np, nf] = T.done();
end
```

Devices (minimum, all provenance-tagged): GEN-51 (B22, ANSI 51, CT 15000/1 SOURCE-BACKED Siemens-protection-report, zone generator), GEN-51N (B22, ANSI 51N, same CT, EF), GSUT-HV-51 (GSUT HV 230 kV, ANSI 51, CT ENGINEERING_ASSUMPTION — state ratio assumption explicitly, mark assumption_class), GIS-Q0-51 (230-kV GIS, ANSI 51, breaker_ref Q0), GIS-Q0-50 (same, ANSI 50 high-set, DISABLED-unless-justified status), LINE-21-note (South line distance — NOTE row only, no settings invented), REMOTE-GRID-boundary (F5, monitoring only, no device). No manufacturer/model strings anywhere (assert with strfind scan in test).

- [ ] **Step 2: Run test** → FAIL undefined function.
- [ ] **Step 3: Implement** `phase5_registry.m` with the 6+1 rows above; every row: provenance one of SOURCE-BACKED/DERIVED/ENGINEERING_ASSUMPTION/LEGACY/MISSING; assumption_class PRIMARY/SENSITIVITY/LEGACY.
- [ ] **Step 4: Run test** → PASS.
- [ ] **Step 5: Provenance scan** — `matlab -batch` assert: no 'Siemens relay model' / manufacturer strings in registry; CT 16000 appears only with ct_source='LEGACY'.

---

### Task 3: Fault-input matrix completion (2×5×4 + F1/F2 + F4-m)

**Files:**
- Modify: `matlab/phase5/phase5_import.m` (add m-section + label handling + contribution join)
- Modify: `matlab/tests/test_phase5_import.m` (add F1/F2 + m legs)
- Test: same

**Interfaces:**
- Consumes: production currents + contributions CSVs.
- Produces: full `phase5_import` with F1/F2 rows identical values but distinct labels; F4 m noted 0.5 primary.

- [ ] **Step 1: Extend test** with:

```matlab
a = Ti(strcmp(Ti.fault_location,'F1')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
b = Ti(strcmp(Ti.fault_location,'F2')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(abs(a.I_primary_kA-b.I_primary_kA)<1e-9, 'F1==F2 values, distinct labels, no artificial Z');
T = T.chk(all(Ti.m(strcmp(Ti.fault_location,'F4'))==0.5), 'F4 primary m=0.5');
T = T.chk(~any(strcmp(Ti.provenance,'scratch')), 'no scratch/probe provenance');
```

- [ ] **Step 2: Run** → FAIL on new checks.
- [ ] **Step 3: Implement** label preservation (never collapse F1/F2), m guard, provenance constant; join per-leg through-currents from contributions CSV where available (NaN + 'MISSING-leg' note where absent — never fabricate).
- [ ] **Step 4: Run** → PASS, 40 rows.

---

### Task 4: CT secondary + rated-current reference

**Files:**
- Create: `matlab/phase5/phase5_ct.m`
- Create: `matlab/tests/test_phase5_ct.m`

**Interfaces:**
- Consumes: import table; ratio scalar.
- Produces: `phase5_ct`, `phase5_ct_table` per Interfaces.

- [ ] **Step 1: Write failing test**

```matlab
function [np, nf] = test_phase5_ct()
T = t_case('test_phase5_ct');
S = phase5_ct(12019, 15000);
T = T.chk(abs(S.Isec_A-0.8012667)<1e-6, '12019/15000 = 0.8013 A secondary');
S2 = phase5_ct(7.27200442799167, 15000); % 7.272 A primary (corrected: plan draft literal evaluated to 7272 A; intent per comment + Note)
T = T.chk(abs(S2.Isec_A-0.0004848)<1e-7, 'F1 LG 7.27 A -> 0.48 mA secondary (sensitive-EF regime)');
S3 = phase5_ct(50530.8851865359, 15000);
T = T.chk(abs(S3.Isec_A-3.3687257)<1e-5, 'F3 LLL 50.53 kA -> 3.369 A secondary');
T = T.chk(isinf(phase5_ct(0,15000).Isec_A)==0, 'zero primary gives zero secondary, not Inf');
[np, nf] = T.done();
end
```

(Note: 7.272 A primary /15000 = 0.4848 mA — asserts low-EF physics survives CT conversion.)

- [ ] **Step 2: Run** → FAIL undefined.
- [ ] **Step 3: Implement** one-line conversion + table builder stamping ct_ratio + ct_tag ('PRIMARY-15000/1' or 'LEGACY-16000/1').
- [ ] **Step 4: Run** → PASS.

---

### Task 5: Centralized curve library

**Files:**
- Create: `matlab/phase5/phase5_curve.m` (holds info + time + DT in one file, subfunctions)
- Create: `matlab/tests/test_phase5_curve.m`

**Interfaces:** per Interfaces block.

- [ ] **Step 1: Write failing test**

```matlab
function [np, nf] = test_phase5_curve()
T = t_case('test_phase5_curve');
[k,a] = phase5_curve_info('SI');
T = T.chk(abs(k-0.14)<1e-12&&abs(a-0.02)<1e-12, 'SI constants IEC 60255 study values');
t1 = phase5_curve(2, 'SI', 0.1);
T = T.chk(abs(t1-0.1*0.14/((2^0.02)-1))<1e-9, 'SI t at M=2 matches closed form');
T = T.chk(isinf(phase5_curve(1,'SI',0.1)), 'M<=1 gives Inf (no trip)');
T = T.chk(phase5_curve(10,'EI',0.1)<phase5_curve(10,'SI',0.1), 'EI faster than SI at M=10');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** with constants centralized in `phase5_curve_info` (single source; error('phase5_curve:family') on unknown); document units (I,Is in A secondary; TMS dimensionless; t seconds).
- [ ] **Step 4: Run** → PASS.

---

### Task 6: Pickup methodology engine

**Files:**
- Create: `matlab/phase5/phase5_pickup.m`
- Modify: registry-driven defaults (no registry edit; function reads device struct).

**Interfaces:** `P = phase5_pickup(device, Iload_A, Imin_fault_A)`.

Study settings (documented basis, never tuned-to-pass): GEN-51 phase pickup = 1.25×12019 A primary (15023.75 A; BASIS 'above rated + below min phase fault'; SOURCE 'DERIVED-study-setting'; VALIDATION 'min phase fault F-sweep check in T16'); GEN-51N EF pickup = 0.05×CTsec-rated-equivalent primary 750 A? NO — must respect 7.27 A physics: EF pickup primary 5 A? Record honestly: with 15000/1 CT, 5 A primary = 0.33 mA secondary — flag SENSITIVE, assumption_class ENGINEERING_ASSUMPTION, validation 'detects F1 LG 7.27 A with margin 1.45, susceptible to noise — reported as limitation'. GIS-Q0-51 pickup = 1.2× frozen-flow anchor from ct_data FL_anchor column (derive, cite). Every output: setting/unit/basis/source/validation fields.

- [ ] **Step 1–4:** TDD with test asserting fields present + GEN-51 pickup 15023.75 A + GEN-51N pickup < 7.27 A (must-detect) + pickup > normal load anchor (no-trip-on-load).
- [ ] **Step 5:** Record BASIS strings verbatim into `phase5_relay_settings.csv` later.

---

### Task 7: Operating-time engine

**Files:**
- Create: `matlab/phase5/phase5_time.m`
- Create: `matlab/tests/test_phase5_time.m` (earth-fault + instantaneous legs live here)

- [ ] **Step 1: Failing test**

```matlab
function [np, nf] = test_phase5_time()
T = t_case('test_phase5_time');
t = phase5_time(3.3687257, 1.0015833, 0.1, 'SI'); % F3 LLL secondary vs GEN-51 pickup secondary
T = T.chk(isfinite(t)&&t>0&&t<10, 'F3 LLL finite time <10 s');
T = T.chk(abs(phase5_time(0.0004848, 0.0003333, 0.5, 'SI')-9.31)<0.1, 'EF leg executes (F1 LG secondary vs GEN-51N pickup secondary, t~9.3 s slow-sensitive)');
T = T.chk(isinf(phase5_time(0.5, 1.0, 0.1, 'SI')), 'below pickup Inf');
[np, nf] = T.done();
end
```

- [ ] **Step 2–4:** implement `t=Inf if I<=Is else curve`; instantaneous: if `isfield(device,'Iinst')` and I>=Iinst → t=0.05 s definite (only where justified; default no-Iinst → never instantaneous; test asserts default path).

---

### Task 8: Coordination matrix builder

**Files:**
- Create: `matlab/phase5/phase5_coord.m`
- Create: `matlab/tests/test_phase5_coord.m`

Hierarchy (topology-built): GEN-51 (downstream) → GSUT-HV-51 → GIS-Q0-51 (upstream) for F1/F2 faults; LINE-side → GIS-Q0-51 → GRID-boundary for F3/F4/F5. Matrix cols: downstream, upstream, fault_location, fault_type, caseID, I_fault_kA, I_down_A, I_up_A, t_down_s, t_up_s, ct_down, ct_up, margin_s, verdict, reason. Margin `dt=t_up-t_down`; PASS iff dt>=0.3 (CTI study threshold, labelled ENGINEERING_ASSUMPTION) else FAIL + reason. Earth rows use I0-derived relay currents (3I0 path noted; neutral counted once — assert in test).

- [ ] **Step 1–4:** TDD: margin arithmetic test (t_up 0.8/t_down 0.4 → 0.4 PASS) + below-pickup row verdict 'NO-TRIP' (never forced PASS) + column schema exact.

---

### Task 9: TCC plots

**Files:**
- Create: `matlab/phase5/phase5_tcc.m`

Two figures minimum: (a) generator-zone TCC (GEN-51 + GEN-51N + GSUT-HV-51, F1 LLL/LG markers); (b) grid-zone TCC (GIS-Q0-51 + GSUT-HV-51, F3 markers). Log-log current (A secondary) vs time; each curve labelled device/function/CT/pickup/TMS/curve; pickup points + fault markers; no manufacturer strings. Outputs `results/phase5_protection/plots/tcc_gen.png`, `tcc_grid.png`. Test: files exist + non-zero bytes + no fabricated strings (scan title/labels).

---

### Task 10: Breaker-duty engine (separate)

**Files:**
- Create: `matlab/phase5/phase5_duty.m`
- Create: `matlab/tests/test_phase5_duty.m`

Uses symmetrical RMS **through-current** (from contributions/ct_data through_path legs, never total bus Ikpp vs transformer duty). Cols: location, breaker_ref, fault_type, caseID, I_sym_kA, I_peak_kA(design-defined, informational), rating_kA, basis, verdict, note. Ratings: Q0 rating MISSING unless source proves it → verdict 'NOT DETERMINABLE FROM AVAILABLE DATA' (never PASS/FAIL invented). 50-kA estimated ref row: comparison NOTE only (`phase5_duty` emits `note_50kA` field: F3 LLL 50.53 vs 50.00 → +1.06%, SOURCE 'estimated', verdict NOTE). X/R-kappa peak only informational. Test asserts: no 'IEC' string in duty table; no PASS without rating.

---

### Task 11: 50-kA + Q-semantics + neutral-count guards

**Files:** fold into `phase5_duty.m` (50-kA note), `phase5_registry.m` (assert Q-mapping — already T2), `phase5_validate.m` legs (T16). No new module.
Checks: duty table contains exactly one `NOTE` row for 50-kA comparison; `phase5_registry` Q1/Q2/Q9 never carry breaker_ref (test scan); neutral impedance counted once (test: F1 LG I0 path uses 3ZN from grounding once — numeric check `abs(I0-0.00242400147599722 kA)<1e-9` on import row proves no double-count vs production).

---

### Task 12: Low-earth-fault physics validation leg

Covered in `phase5_validate.m` L-leg: F1 LG primary 7.272 A → secondary 0.4848 mA → EF pickup must-detect with margin; phase-vs-I0-vs-secondary distinguished in relay-currents CSV (cols I_phase_A, I0_A, Isec_A). Test asserts ratio Isec/Iprimary == 1/15000 within 1e-12.

---

### Task 13: 2×5×4 matrix coverage guard

Covered in `phase5_validate.m`: assert relay-currents table has 40 primary rows (2 cases × 5 locs × 4 types Ikpp backbone) and coordination matrix covers every (case,loc,type) with ≥1 downstream/upstream pair where topology defines one, else explicit 'NO-PAIR (topology)' reason — never silently dropped. Hand-selected-subset test: fail if any of 40 combos missing per case.

---

### Task 14: Sensitivity engine (CT 15k vs 16k fenced)

**Files:** Create `matlab/phase5/phase5_sensitivity.m`. Recomputes relay-currents + times + margins under LEGACY-16000/1, output `phase5_sensitivity.csv` with scope='SENSITIVITY' (primary outputs never overwritten). Test: 16k secondary == 15k×15/16 within 1e-12; primary results identical handles (no merge — separate table).

---

### Task 15: Provenance ledger

Every writer row carries provenance + scope columns (writer enforces non-empty; error('phase5_writer:provenance') otherwise). Ledger values tallied into validation CSV. Test scans all 9 CSVs for empty provenance/scope.

---

### Task 16: Validation suite (15 legs + regression)

**Files:** Create `matlab/phase5/phase5_validate.m`, `matlab/phase5/run_phase5_tests.m`, 8 test files listed in File Structure.
Legs: V1 CT conversion, V2 pickup conversion, V3 time calc, V4 earth-fault, V5 inverse behaviour, V6 instantaneous, V7 margin, V8 duty separation, V9 min-detect, V10 max-duty, V11 sensitivity, V12 source/legacy separation, V13 topology mapping, V14 matrix coverage, V15 no-double-neutral (+ regression leg R0 import identity from T1). Each leg: pass bool + residual + note; all must pass for gate. `run_phase5_tests.m` runs all test_phase5_* + phase5_validate, prints `phase5_tests: NP passed, NF failed`.

---

### Task 17: Writer + production driver + outputs

**Files:** Create `matlab/phase5/phase5_writer.m`, `matlab/phase5/run_phase5_production.m`.
Schemas (exact): device_registry (17 cols per Interfaces), relay_settings (setting/unit/basis/source/validation/...), fault_inputs (8 cols), relay_currents (fault_location/fault_type/caseID/I_primary_A/I_primary_kA/CT_ratio/I_secondary_A/I0_A/provenance/scope), coordination_matrix (15 cols T8), coordination_margins (pair/margin/verdict), breaker_duty (10 cols T10), sensitivity (T14), validation (leg/pass/residual/note). Plus manifest.json (tag, timestamp, input manifest SHA, code hashes, row counts, validation ref), sha256.txt (all CSVs+manifest+run_log), run_log.txt. `run_phase5_production('production')` end-to-end; overwrite guard mirrors Phase-4 (`phase5_production:exists`).

---

### Task 18: 19-section technical report

**Files:** Create/refresh `PHASE5_FINAL_REPORT.md` (repo root, mirroring Phase-4 naming).
Sections 1–19 per master prompt §24. Language rules: 'study setting'/'engineering assumption'/'source-backed'/'qualified model' only; forbidden: 'fully realistic'/'exact plant settings'/'IEC compliant'/'actual relay settings' (gate scans). Numbers must match CSVs (spot-check script in gate).

---

### Task 19: Quality gate

**Files:** Create `matlab/phase5/phase5_gate.m`. 17 predicates from master §25 (regression, cases, locs, types, CT, relay, matrix, margins, duty-separation, rating provenance, assumption tags, legacy fenced, no-scratch, manifest+hashes, report-match, no-IEC-claim, no-Phase3/4-change). Prints checklist; non-zero exit on any fail. Report-agreement check recomputes 3 spot numbers from CSVs vs report text.

---

### Task 20: Final deliverable assembly (A–M)

Run production + tests + gate live; collect: A changed files, B new files, C test counts, D regression, E settings, F matrix, G duty, H sensitivity, I source-backed list, J assumptions, K missing, L limitations, M Phase-6 scope. Present as chat summary + append to report §19. Do not claim completion unless tests + outputs actually generated.

## Self-Review

- Spec coverage: freeze §1→T1; inputs §2-5→T3/T13; registry §6→T2; CT §7→T4/T14; rated §8→T2/T4; OC/EF §9→T5-T7; pickup §10→T6; coordination §11→T8; TCC §12→T9; duty §13→T10; 50 kA §14→T10/T11; Q §15→T2/T11; low-EF §16→T11/T12; no-tune §17→T6/T19; matrix §18→T3/T13; sensitivity §19→T14; provenance §20→T15; tests §21→T16; regression §22→T1; outputs §23→T17; report §24→T18; gate §25→T19; stop-rule §26→T10/T15; deliverable §27→T20. All covered.
- Placeholder scan: no TBD/TODO; every step has exact code/commands; no 'appropriate handling' vagueness; no 'similar to Task N' references.
- Type consistency: `phase5_import` table cols fixed T1/T3/T13; curve signature identical T5/T7; duty table cols T10/T19; writer schemas T17 match T8/T10/T14 outputs.
