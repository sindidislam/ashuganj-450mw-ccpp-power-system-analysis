# Phase-4 Implementation Plan — Ashuganj South Fault Analysis (15 tasks)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Phase-4 short-circuit engine (LLL/LG/LL/LLG at F1–F5 × m, 4 stages, contributions, A–H sensitivities, 20-leg validation, Phase-5 handoff CSVs) in fresh MATLAB code driven entirely by the corrected design spec.

**Architecture:** New `matlab/phase4/` package with modules M1–M8 per spec Sec 25 (M1 input/profile provider, M2 sequence builder, M3 stage-source builder, M4 nodal solver, M5 reconstruction+extraction, M6 validation, M7 sensitivity, M8 writer) communicating ONLY through the canonical parameter registry + handoff row schema. Tests live in `matlab/tests/test_phase4_*.m` using the existing `t_case` helper, run by new `matlab/phase4/run_phase4_tests.m`. TDD red-green-refactor for every task.

**Tech Stack:** MATLAB R2024a (`matlab -batch`), existing helpers `t_case` (assert recorder), `ashuganj_root` (path anchor). No toolboxes required (plain structs, complex arithmetic, CSV I/O).

**Spec:** `docs/superpowers/specs/2026-09-18-phase4-fault-analysis-design.md` (corrected reconciliation + 4 post-review fixes: Q0-breaker wording, H2 limiting-sensitivity wording, HIGH-corner envelope wording, GAT-Z0 ±7.5% leg).

## Global Constraints

- ADD files only: everything new lives under `matlab/phase4/` (code) and `matlab/tests/test_phase4_*.m` (tests). NEVER edit any existing file: no `matlab/data/*`, no `matlab/tests/run_all_tests.m` or existing tests, no `rev2/*`, no `PHASE3_*`, no `results/phase3_loadflow/*`.
- Closed status enum only: `SOURCE/PRIMARY`, `DERIVED`, `ENGINEERING_ASSUMPTION`, `HISTORICAL`, `LEGACY`, `MISSING`. MISSING stays NaN in the registry (use `T.isnan`); never invent.
- Frozen Phase-3 numbers are asserted, never redefined: 100 MVA/230 kV, Zbase 529, R1 0.00015 / X1 0.00077 / Y1 0.001488 pu/km, R_eq 0.0277725 / X_eq 0.1425655 / B_eq 3.937996, 0.7 km, 2 circuits, MALLARD_795_MCM reference-only, B230_REMOTE = REMOTE_GRID_BUS_ASSUMED.
- No hard-coded fault-study literals: every constant is a named registry field with value+unit+base+status+source+locator+rationale+variant ID.
- No IEC 60909 compliance claims anywhere (comments, labels, headers). `ip` is "design-defined peak". `Ib` is "constant-E' reference approximation".
- Q0 = breaker connection; Q1/Q2/Q9 = disconnector connections (never collective "disconnectors"). No switching/arc/duty model.
- H2 = "limiting sensitivity / stress case" (never "bracket proof"). HIGH corner = "engineering envelope" (never proof of absolute bound).
- GAT-Z0 ±7.5% is a SOURCE-stated tolerance leg, separate from lambda_T.
- Each task ends with a MATLAB run proving its tests pass; a task is done only when its `test_phase4_*` returns 0 failures AND all earlier Phase-4 tests still return 0 failures.
- No version control in this workspace: instead of commits, each task ends by appending its test counts to `matlab/phase4/TASK_LOG.md`.
- MATLAB invocation pattern (run from project root, PowerShell): `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "addpath('matlab/tests'); addpath('matlab/phase4'); addpath('matlab/data'); addpath('matlab/utilities'); [np,nf]=test_phase4_XXX(); assert(nf==0)"`

---

### Task 1: Canonical parameter registry + frozen Phase-3 asserts (M1 foundation)

**Files:**
- Create: `matlab/phase4/phase4_registry.m`
- Test: `matlab/tests/test_phase4_registry.m`

**Interfaces:**
- Consumes: nothing (reads frozen `matlab/data/ashuganj_lines.m`, `ashuganj_grid.m` read-only at runtime for cross-check only).
- Produces: `R = phase4_registry()` struct with fields `R.frozen` (system base, line R1/X1/Y1, R_eq/X_eq/B_eq, length, circuits, conductor ref, topology endpoints), `R.machine` (458 MVA/22 kV + generator reactances + Ra), `R.grid` (dataset P and S inputs), `R.gat/uat/gsut` (transformer % figures), each entry a struct `struct('value',..,'unit',..,'base',..,'status',..,'source',..,'locator',..,'rationale',..,'variant',..)`. MISSING items present as `value = NaN` (Z_PT, Z_ST, NGT series, R0/X0/B0 point values, neutral devices).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_registry()
T = t_case('test_phase4_registry');
R = phase4_registry();
T = T.eq(R.frozen.Zbase_ohm.value, 529, 'Zbase frozen 529 ohm');
T = T.eq(R.frozen.R_eq_ohm.value, 0.0277725, 'R_eq frozen');
T = T.eq(R.machine.Xdpp_sat.value, 0.2248, 'Xdpp_sat primary');
T = T.eq(R.machine.X2.value, 0.2242, 'X2 distinct from Xdpp_sat');
T = T.isnan(R.gat.Z_PT.value, 'Z_PT stays MISSING NaN');
T = T.isnan(R.line.R0_ohm.value, 'R0 point value stays MISSING NaN');
T = T.eq(R.grid.P.Ik_kA.value, 50, 'dataset P 50 kA');
T = T.eq(R.grid.S.XoR.value, 10.99, 'dataset S X/R 10.99');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "addpath('matlab/tests'); test_phase4_registry()"`
Expected: FAIL with "Undefined function 'phase4_registry'".

- [ ] **Step 3: Write minimal implementation** — `phase4_registry.m` building the struct above; frozen values cross-checked at runtime against `ashuganj_lines()` (R_ohm/X_ohm/C_F/length/circuits) with `error()` on mismatch (fail-loud, never redefine).

- [ ] **Step 4: Run test to verify it passes**

Run: same as Step 2 wrapped with `[np,nf]=test_phase4_registry(); assert(nf==0)`.
Expected: PASS, 8/8.

- [ ] **Step 5: Log** — append `T1 phase4_registry + test_phase4_registry: np=8 nf=0` to `matlab/phase4/TASK_LOG.md`.

### Task 2: Prefault provider M1 (frozen solved states, kV-column rule)

**Files:**
- Create: `matlab/phase4/phase4_prefault.m`
- Test: `matlab/tests/test_phase4_prefault.m`

**Interfaces:**
- Consumes: `phase4_registry()`, CSVs `results/phase3_loadflow/phase3_bus_results.csv` + `phase3_system_summary.csv` (read via `ashuganj_root()` absolute paths).
- Produces: `F = phase4_prefault(caseID)` struct with `Vt_B22_kV, Ang_B22_deg, Pgen_MW, Qgen_MVAr, V230_1_kV, Ang230_1_deg, Vremote_kV, AngRemote_deg, GAT_in, auxP, auxQ, couplerClosed=true` for `LF360_GAT_OUT` / `LF360_GAT_IN`. REJECTS `LF342/LF389P30` as primary (error unless `'allowNonPrimary',true`), REJECTS any use of a `*_pu` solver-base column (function only reads `*_kV`/`Angle_deg`/`P_inj_MW`/`Q_inj_MVAr` columns by name).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_prefault()
T = t_case('test_phase4_prefault');
F = phase4_prefault('LF360_GAT_OUT');
T = T.eq(F.Vt_B22_kV, 22.0, 'B22 22 kV OUT');
T = T.near(F.Ang_B22_deg, -22.7815, 1e-3, 'B22 angle OUT');
T = T.eq(F.Pgen_MW, 360.0, 'P frozen 360');
T = T.near(F.Qgen_MVAr, 27.832638, 1e-4, 'Q OUT differs from IN');
G = phase4_prefault('LF360_GAT_IN');
T = T.chk(abs(G.Qgen_MVAr - F.Qgen_MVAr) > 1, 'OUT/IN Q differ: no shared EMF');
T = T.near(F.Vremote_kV, 229.731274, 1e-3, 'V_REMOTE_kV OUT (kV column, never solver pu)');
try, phase4_prefault('LF389P30_GAT_OUT'); T = T.chk(false, 'historical rejected as primary');
catch ME, T = T.chk(contains(ME.identifier,'phase4'), 'historical rejected as primary'); end
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — same MATLAB pattern; expected FAIL "Undefined function 'phase4_prefault'".
- [ ] **Step 3: Write minimal implementation** — CSV lookup by `Case_ID`+`Bus_Name`, exact expected numbers cross-checked with tolerance asserts inside the function.
- [ ] **Step 4: Run test to verify it passes** — expected 7/7; also re-run `test_phase4_registry` (0 failures).
- [ ] **Step 5: Log** — append T2 counts to TASK_LOG.md.

### Task 3: Grounding equivalents — NER + UAT/GAT LV 5-A (M2 grounding inputs)

**Files:**
- Create: `matlab/phase4/phase4_grounding.m`
- Test: `matlab/tests/test_phase4_grounding.m`

**Interfaces:**
- Consumes: `phase4_registry()`.
- Produces: `Z = phase4_grounding(variant)` with `variant='primary'` (additive R_NER_HV = 60 + n^2*2.62) or `'quoted60'` (60-ohm-complete alternative): fields `n, R_refl, R_NER_HV, ZN_ohm, Z3ZN_ohm, Z3ZN_pu_machine, ZN_UAT_ohm (796.743), ZN_GAT_LV_ohm (796.743), ZN_UAT_alt_ohm (265.581), NGT_mode ('neglected'|'bounded')`. `ZN=0` as primary is an `error()`.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_grounding()
T = t_case('test_phase4_grounding');
Z = phase4_grounding('primary');
T = T.near(Z.n, 25.40341184, 1e-6, 'turns ratio n');
T = T.near(Z.R_refl, 1690.773333, 1e-4, 'reflected 2.62 ohm');
T = T.near(Z.R_NER_HV, 1750.773333, 1e-4, 'additive R_NER_HV');
T = T.near(Z.Z3ZN_ohm, 5252.32, 1e-2, '3ZN ohms');
T = T.near(Z.Z3ZN_pu_machine, 4970.1706, 1e-2, '3ZN pu machine base');
T = T.near(Z.ZN_UAT_ohm, 796.743371, 1e-3, 'UAT 5-A equivalent');
T = T.near(Z.ZN_GAT_LV_ohm, 796.743371, 1e-3, 'GAT LV 5-A equivalent, NOT solid');
T = T.near(Z.ZN_UAT_alt_ohm, 265.581124, 1e-3, 'alternative I0 reading');
Q = phase4_grounding('quoted60');
T = T.near(Q.R_NER_HV, 60, 1e-9, 'quoted-60 alternative kept visible');
try, phase4_grounding('solid'); T = T.chk(false, 'solid NER forbidden');
catch ME, T = T.chk(true, 'solid NER forbidden'); end
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — pure arithmetic from registry values (no literals: n from V1/V2 registry fields).
- [ ] **Step 4: Run test to verify it passes** — expected 10/10 + earlier suites green.
- [ ] **Step 5: Log** — append T3 counts.

### Task 4: Stage-source builder M3 (E''/E'/Eq per case, Park declared)

**Files:**
- Create: `matlab/phase4/phase4_sources.m`
- Test: `matlab/tests/test_phase4_sources.m`

**Interfaces:**
- Consumes: `phase4_registry()`, `phase4_prefault(caseID)`, `XdRole` (`'sat'` 0.2248 primary / `'unsat'` 0.2608 sensitivity).
- Produces: `S = phase4_sources(caseID, XdRole)` with `Vt_pu, It_pu, Epp (complex), Edp, Eqp, Eq, delta_rad, parkConvention (string, printed once), Xdpp_used`. FORBIDS: `|V|`-only, shared OUT/IN, averaging sat/unsat, X2/X0 as Xd'' (all `error()` paths tested).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_sources()
T = t_case('test_phase4_sources');
S = phase4_sources('LF360_GAT_OUT', 'sat');
T = T.chk(isfield(S,'parkConvention') && ~isempty(S.parkConvention), 'Park convention declared');
T = T.eq(S.Xdpp_used, 0.2248, 'sat role uses 0.2248');
T = T.chk(abs(imag(S.Epp)) > 1e-6, 'Epp is complex phasor, angle carried');
U = phase4_sources('LF360_GAT_IN', 'sat');
T = T.chk(abs(U.Epp - S.Epp) > 1e-4, 'OUT/IN EMFs differ');
A = phase4_sources('LF360_GAT_OUT', 'unsat');
T = T.eq(A.Xdpp_used, 0.2608, 'unsat role uses 0.2608');
T = T.chk(isfield(S,'Edp') && isfield(S,'Eqp') && isfield(S,'Eq'), 'transient + steady sources present');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — eqs. (9-1)–(9-13): Vt complex, St/458, It = conj(St./Vt), Zpp = Ra + jXd, Epp = Vt + Zpp*It; two-axis E'd/E'q via Xq-projection delta; Eq constant-field. Same-case consistency enforced by signature.
- [ ] **Step 4: Run test to verify it passes** — expected 6/6 + earlier suites green.
- [ ] **Step 5: Log** — append T4 counts.

### Task 5: Positive/negative sequence builder M2-PN (machine, transformers, line, grid)

**Files:**
- Create: `matlab/phase4/phase4_seqPN.m`
- Test: `matlab/tests/test_phase4_seqPN.m`

**Interfaces:**
- Consumes: `phase4_registry()`, grid split `(XoR_P)` for dataset P or `'S'` profile select, study base 100 MVA.
- Produces: `N = phase4_seqPN('P', 15)` struct with pu-on-100MVA impedances: `Z1gen_pp (sat/unsat switchable), Z2gen, Z1gsut==Z2gsut, Z1uat==Z2uat, Z1gat==Z2gat (PS abstraction), Z1line==Z2line (frozen totals), Z1grid/Z2grid (R/X split of |Z|=2.65581124)`, plus `R15/X15` check fields. `Rgrid=0` input is an `error()`; XN-pairing is an `error()`.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_seqPN()
T = t_case('test_phase4_seqPN');
N = phase4_seqPN('P', 15);
T = T.near(N.Z1grid_R + 1j*N.Z1grid_X, 0.17666194 + 1j*2.64992904, 1e-6, 'grid P split at X/R=15');
T = T.near(abs(N.Z1grid_R + 1j*N.Z1grid_X), 2.65581124/529, 1e-9, '|Z| fixed, split-only');
T = T.eq(N.Z2gsut_R, N.Z1gsut_R, 'GSUT Z2=Z1 justified static equality');
T = T.near(N.Z1line_X_pu, 0.1425655/529, 1e-12, 'line X frozen total');
S = phase4_seqPN('S', NaN);
T = T.near(S.Z1grid_R + 1j*S.Z1grid_X, (0.267344 + 1j*2.938108)/529, 1e-6, 'dataset S fixed split');
try, phase4_seqPN('P', 0); T = T.chk(false, 'Rgrid=0 fenced out');
catch ME, T = T.chk(true, 'Rgrid=0 fenced out'); end
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — S-ratio transfers (same level), %→pu on own ratings, eqs. (15-1)–(15-5); transformer/line justified equalities with comment rationale.
- [ ] **Step 4: Run test to verify it passes** — expected 6/6 + earlier suites green.
- [ ] **Step 5: Log** — append T5 counts.

### Task 6: Zero-sequence builder M2-Z (NER, transformer legs, line band, grid k0g, H-legs)

**Files:**
- Create: `matlab/phase4/phase4_seqZ.m`
- Test: `matlab/tests/test_phase4_seqZ.m`

**Interfaces:**
- Consumes: registry, `phase4_grounding(variant)`, band select `kR/kX/kB`, `k0g`, GAT leg `H0/H1/H2 + lambda_T`, grid dataset select.
- Produces: `Z = phase4_seqZ(opts)` with `Z0gen_pu, Z3ZN_pu, Z0gsut_pu (+solid neutral), Z0uat_pu + ZN_UAT_pu, Z0gat_HVLV_pu + Z_T0_loop_pu + neutrals, Z0line_pu (band), Z0grid_pu (k0g*Z1 same dataset)`, gating mask struct per location, aux-shunt OPEN flag. `X0=3X1`/`R0=R1`/`Z0m` requests are `error()`.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_seqZ()
T = t_case('test_phase4_seqZ');
Z = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
T = T.near(Z.Z0line_R, 3.5*0.0277725/529, 1e-12, 'R0 = kR*R_eq');
T = T.near(Z.Z0line_X, 2.75*0.1425655/529, 1e-12, 'X0 = kX*X_eq');
T = T.near(Z.Z_T0_loop_pu, 1.0*0.108, 1e-9, 'H1 loop = lambda*Z0_PS');
T = T.near(Z.ZN_GAT_LV_ohm, 796.743371, 1e-3, 'GAT LV neutral 5-A, never solid');
T = T.chk(Z.auxShuntOpen, 'aux shunt OPEN in zero base');
T = T.near(Z.Z0grid_mag_pu, 1.5*abs(Z.Z1grid_pu), 1e-12, 'Z0grid = k0g*Z1 same dataset');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — per Sec 8/11–14: branch forms, 3x AFTER conversion, H0 (open tee) / H1 (lambda loop) / H2 (short limit), GAT-Z0 ±7.5% as separate `Z0gat_tol` factor option.
- [ ] **Step 4: Run test to verify it passes** — expected 6/6 + earlier suites green.
- [ ] **Step 5: Log** — append T6 counts.

### Task 7: Topology + m-division + two-circuit B-view (Sec 18 indices)

**Files:**
- Create: `matlab/phase4/phase4_topology.m`
- Test: `matlab/tests/test_phase4_topology.m`

**Interfaces:**
- Consumes: registry + band/leg selects (passed through to M2).
- Produces: `Y = phase4_topology(m, view, coupler)` with bus index map (`B22, B230_1, B230_2, B230_REMOTE, BGRID230, B6_6, F4node`), branch list per sequence for `view='lumped'` (F1/F2/F3/F5) or `view='B'` (F4: faulted GIS-side/remote-side + healthy whole, Z_branch = 2*Z_eq, B_branch = B_eq/2), m-sections per (18-4)–(18-8) with restoration asserts (18-3/18-6/18-8 inside the function). F1/F2 share the node index but keep distinct labels. Coupler `'open'` splits B230_1/B230_2 (+zero-split). Q0 breaker / Q1/Q2/Q9 disconnector tags attached (no switching model).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_topology()
T = t_case('test_phase4_topology');
Y = phase4_topology(0.5, 'B', 'closed');
T = T.near(Y.Zs_branch_pu, 2*Y.Zs_eq_pu, 1e-12, 'Z_branch = 2*Z_eq');
T = T.near(Y.Zs_S + Y.Zs_R, Y.Zs_eq_pu, 1e-12, 'm-section sum restores total');
T = T.eq(Y.nodeF1, Y.nodeF2, 'F1/F2 same node, labels kept separate');
T = T.eq(Y.labelF1, 'F1_B22', 'F1 label kept'); T = T.eq(Y.labelF2, 'F2_GSUT_LV', 'F2 label kept');
O = phase4_topology(0, 'lumped', 'open');
T = T.chk(O.nodeB230_1 ~= O.nodeB230_2, 'coupler open splits GIS nodes');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — node/branch tables + asserts.
- [ ] **Step 4: Run test to verify it passes** — expected 6/6 + earlier suites green.
- [ ] **Step 5: Log** — append T7 counts.

### Task 8: Nodal solver M4 + Thevenin audit + ip (Sec 17/19)

**Files:**
- Create: `matlab/phase4/phase4_solve.m`, `matlab/phase4/phase4_kappa.m` (fresh body implementing kappa(r) = 1.02+0.98*exp(-3r); header states design-defined shape shared with rev2/data/iec_kappa.m pattern, NO IEC claim)
- Test: `matlab/tests/test_phase4_solve.m`

**Interfaces:**
- Consumes: topology + M2 impedances + M3 source + fault spec (`type`, `Zf_pu`, stage).
- Produces: `F = phase4_solve(...)` with sequence currents at fault (INTO fault), Thevenin-scalar audit residual, retained voltages, `ip = kappa*sqrt(2)*Ik''` + `r/kappa` (magnitude only). Thevenin-only solving forbidden by construction (function always builds Ybus).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_solve()
T = t_case('test_phase4_solve');
F = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0);
T = T.chk(abs(F.I1) > 0, 'LLL fault current nonzero');
T = T.chk(F.audit_res < 1e-6, 'nodal vs Thevenin audit closes');
T = T.chk(abs(abs(F.Ia)-abs(F.Ib)) < 1e-6*abs(F.Ia), 'LLL phase symmetry');
G = phase4_solve('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0);
T = T.near(G.Ia, 3*G.I0, 1e-9, 'LG Ia = 3I0 fault branch');
T = T.chk(G.r > 0 && G.kappa > 1 && G.kappa < 2, 'kappa(r) sane, ip attached');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — Ybus + injection per sequence, (17-1)–(17-15), Fortescue both directions, rotation by cyclic permutation, kappa.
- [ ] **Step 4: Run test to verify it passes** — expected 6/6 + earlier suites green.
- [ ] **Step 5: Log** — append T8 counts.

### Task 9: Stages Ib/steady + Zf normalized probes (Sec 19/21)

**Files:**
- Create: `matlab/phase4/phase4_stages.m`
- Test: `matlab/tests/test_phase4_stages.m`

**Interfaces:**
- Consumes: same as T8 + `t_break` (Ib, mandatory input — missing `t_break` is `error()`), `ZfMode` (`'bolted'` 0 / `'earth'` 0.01 pu / `'phase'` 0.002 pu with level base printed).
- Produces: `R = phase4_stages(...)` rows for Ik''/ip/Ib(t_break)/Ik-steady with stage labels + footnotes (constant-E' reference approximation; LLG single-earth note). Fixed-ohm cross-level Zf is `error()`.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_stages()
T = t_case('test_phase4_stages');
R = phase4_stages('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0,'bolted');
T = T.eq(R.stage, 'Ikpp', 'stage labelled');
B = phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ib',0.06,'bolted');
T = T.eq(B.t_break, 0.06, 't_break attached, never defaulted');
try, phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ib',[],'bolted'); T = T.chk(false, 'missing t_break errors');
catch ME, T = T.chk(true, 'missing t_break errors'); end
E = phase4_stages('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0,'earth');
T = T.chk(abs(E.Ifault) < abs(R.Ifault), 'earth probe reduces LG current');
T = T.near(E.Zf_ohm, 0.01*529, 1e-9, 'earth probe ohmic at 230 kV');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — transient network (E'/Xd') at t_break input, synchronous network (Eq/Xd), Zf insertion table (3x earth / undivided phase), labels.
- [ ] **Step 4: Run test to verify it passes** — expected 5/5 + earlier suites green.
- [ ] **Step 5: Log** — append T9 counts.

### Task 10: Contributions M5 (Sec 20: extraction, signing, KCL, tags)

**Files:**
- Create: `matlab/phase4/phase4_contrib.m`
- Test: `matlab/tests/test_phase4_contrib.m`

**Interfaces:**
- Consumes: solver outputs + topology (per-leg branch currents, toward-fault re-signed inside).
- Produces: `C = phase4_contrib(...)` per-leg phasors (GEN/GSUT-HV/GSUT-LV/UAT/GAT-HV/GAT-LV/LINE-total-or-B1/B2/GRID/NER-earth), KCL residuals (20-1)–(20-4), through-tags, B6_6 UAT-vs-GAT split (no pre-judged labels), GAT-OUT leg ABSENT (field missing, never zero-filled). `ip` per-leg request is `error()`.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_contrib()
T = t_case('test_phase4_contrib');
C = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0,'bolted');
T = T.chk(C.kcl_seq < 1e-6, 'per-sequence KCL closes');
T = T.chk(C.kcl_ph < 1e-6, 'per-phase KCL closes');
O = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0,'bolted');
T = T.chk(~isfield(O.legs,'GAT_HV'), 'GAT OUT leg absent, not zero-filled');
I = phase4_contrib('LF360_GAT_IN','P',15,'F3','LLL','Ikpp',0,'bolted');
T = T.chk(isfield(I.legs,'GAT_HV'), 'GAT IN leg present');
try, phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','ip',0,'bolted'); T = T.chk(false, 'per-leg ip forbidden');
catch ME, T = T.chk(true, 'per-leg ip forbidden'); end
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — leg extraction → (17-16) → KCL sums → tags.
- [ ] **Step 4: Run test to verify it passes** — expected 5/5 + earlier suites green.
- [ ] **Step 5: Log** — append T10 counts.

### Task 11: Validation engine M6 (20 legs, Sec 23)

**Files:**
- Create: `matlab/phase4/phase4_validate.m`
- Test: `matlab/tests/test_phase4_validate.m`

**Interfaces:**
- Consumes: full run outputs (tasks 8–10) + all asserts.
- Produces: `V = phase4_validate(runID)` with 20 leg results (1 round-trip seq→ph, 2 ph→seq, 3–6 analytical-vs-nodal LLL/LG/LL/LLG, 7–8 KCL seq/ph, 9 earth IN=3I0, 10 NER gating, 11 GSUT block, 12 UAT path, 13 GAT path, 14 H-leg LL/LLL invariance, 15 F3/m=0–F5/m=1 continuity, 16 F1/F2 separation, 17 two-circuit restoration, 18 deterministic rerun, 19 phase symmetry, 20 source conservation) each PASS/FAIL + residual + printed tol (T-RT/T-AN/T-KCL/T-DEAD/T-CONT/T-DET). Any Rev2/Siemens/X0=3X1 oracle use is impossible by construction (no such inputs).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_validate()
T = t_case('test_phase4_validate');
V = phase4_validate('smoke_LF360_OUT_P15_F3_LLL');
T = T.eq(numel(V.legs), 20, '20 validation legs present');
T = T.chk(all([V.legs.pass]), 'smoke run passes all 20 legs');
T = T.chk(isfield(V,'tolsPrinted') && V.tolsPrinted, 'tolerances printed with checks');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — start with legs 1–9 + 17–20 on the smoke run (legs 10–16 activated in Task 12 against wider runs); each leg independently re-derives (separate Fortescue re-implementation for round-trip, closed-form scalars vs Ybus path).
- [ ] **Step 4: Run test to verify it passes** — expected 3/3 + earlier suites green.
- [ ] **Step 5: Log** — append T11 counts.

### Task 12: Sensitivity runner M7 (A–H + GAT-Z0 + joints, Sec 22)

**Files:**
- Create: `matlab/phase4/phase4_sensitivity.m`
- Test: `matlab/tests/test_phase4_sensitivity.m`

**Interfaces:**
- Consumes: base-run descriptor + leg select.
- Produces: OFAT reruns for A (X/R 10/15/20, k0g 1.0/1.5/2.0, S-profile), B (0.5/0.7/1.0), C (LOW/MID/HIGH + conditional X), D (unsat/salient/X2-X0 bounds/two-axis), E (NER tol/quoted-vs-reflected/NGT/UAT-L1 joint/GAT-LV/HV-neutral), F (0 vs probes), G (coupler open), H (H1 base/H0/H2/lambda 0.5-2.0/H3/H4 + GAT-Z0 9.99/10.8/11.61 SOURCE-tolerance). Full-factorial request is `error()`.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_sensitivity()
T = t_case('test_phase4_sensitivity');
S = phase4_sensitivity('base_LF360_OUT_P15', {'C-LOW','C-HIGH'});
T = T.eq(numel(S.runs), 2, 'OFAT legs run independently');
T = T.chk(S.runs(1).kX == 2.0 && S.runs(2).kX == 3.5, 'LOW/HIGH corners hit');
G = phase4_sensitivity('base_LF360_OUT_P15', {'GAT-Z0-9.99','GAT-Z0-11.61'});
T = T.chk(strcmp(G.runs(1).gatZ0status,'SOURCE'), 'GAT-Z0 tolerance keeps SOURCE status');
try, phase4_sensitivity('base_LF360_OUT_P15', {'FULL_FACTORIAL'}); T = T.chk(false, 'factorial forbidden');
catch ME, T = T.chk(true, 'factorial forbidden'); end
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — leg table dispatcher over tasks 8–10 entry points, band min/max collector with supplying-leg names.
- [ ] **Step 4: Run test to verify it passes** — expected 4/4 + earlier suites green. Complete validation legs 10–16 here (needs multi-run evidence).
- [ ] **Step 5: Log** — append T12 counts.

### Task 13: Handoff writer M8 (Sec 26 schema CSVs — data only)

**Files:**
- Create: `matlab/phase4/phase4_handoff.m`
- Test: `matlab/tests/test_phase4_handoff.m`

**Interfaces:**
- Consumes: run + sensitivity + validation structures.
- Produces: CSVs under `results/phase4_fault/` (new folder): `phase4_fault_currents.csv`, `phase4_contributions.csv`, `phase4_bands.csv`, `phase4_ct_data.csv` with full Sec-26 schema (type/location/m/case/dataset/band/Xd-role/NER-variant/GAT-variant/Zf/topology/stage/unit-base + ip r-kappa / Ib t_break / LLG footnote columns). Schema checker rejects incomplete rows (`error()`). Writer emits NO settings/duties/verdicts (assert: no pickup/TMS/grading/duty columns exist).

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_handoff()
T = t_case('test_phase4_handoff');
H = phase4_handoff('smoke_run');
T = T.chk(isfield(H,'schemaOK') && H.schemaOK, 'full schema on every row');
T = T.chk(~H.hasSettingsCols, 'no pickup/TMS/grading/duty columns');
T = T.chk(exist(fullfile(H.dir,'phase4_fault_currents.csv'),'file')==2, 'currents CSV written');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — schema table + csvwritecell-style writer (use `writetable`), CT data (primary + candidate ratios + secondary + frozen Phase-3 FL anchors, selection never made).
- [ ] **Step 4: Run test to verify it passes** — expected 3/3 + earlier suites green.
- [ ] **Step 5: Log** — append T13 counts.

### Task 14: Full-matrix run + runner + banding (M7×M8 at scale)

**Files:**
- Create: `matlab/phase4/run_phase4_tests.m`, `matlab/phase4/run_phase4_matrix.m`
- Test: runner itself (no new test file; reuses all `test_phase4_*`).

**Interfaces:**
- Consumes: all tasks 1–13.
- Produces: `run_phase4_tests()` → [np, nf] over all Phase-4 test files (mirrors `run_all_tests` pattern, separate function so existing files stay untouched); `run_phase4_matrix()` executes F1–F5 × 4 types × 4 stages × OUT/IN × P-band/S × C-corners × H-legs × Zf × coupler per Sec-22 OFAT+joints, writes Sec-26 CSVs + band tables. Long run: executed with MATLAB `-batch` + `diary` log to `results/phase4_fault/run_log.txt`.

- [ ] **Step 1: Write the failing check** — `run_phase4_tests` must list all 10 test files; assert its list equals the files on disk:

```matlab
d = dir(fullfile(fileparts(mfilename('fullpath')),'..','tests','test_phase4_*.m'));
assert(numel(d) == 10, 'runner covers all 10 Phase-4 test files');
```

- [ ] **Step 2: Run to verify it fails** — expected undefined-function FAIL for `run_phase4_tests`.
- [ ] **Step 3: Write minimal implementation** — loop `feval` with try/catch + summary (same shape as `run_all_tests`), matrix driver calling Tasks 8–10/12–13 entry points.
- [ ] **Step 4: Run `run_phase4_tests` to verify all green** — expected 0 failures total.
- [ ] **Step 5: Log** — append T14 totals.

### Task 15: Review gate — freeze re-check, 23-question checklist, STOP

**Files:**
- Create: `matlab/phase4/phase4_review_gate.m`, `PHASE4_REVIEW_GATE.md` (project root, new file)
- Test: `matlab/tests/test_phase4_review_gate.m` (asserts freeze timestamps/sizes + spec-file presence + no-forbidden-column scan of handoff CSVs)

**Interfaces:**
- Consumes: everything.
- Produces: `PHASE4_REVIEW_GATE.md` with (1) freeze evidence (`Get-Item` sizes/timestamps of PHASE3 files + `matlab/data` + `rev2` spot files, must equal Task-1 record), (2) Q1–Q23 line-by-line confirmation against implementation behavior, (3) remaining-data list (Sec 27 D1–D8), (4) STOP statement: no protection work started.

- [ ] **Step 1: Write the failing test**

```matlab
function [np, nf] = test_phase4_review_gate()
T = t_case('test_phase4_review_gate');
G = phase4_review_gate();
T = T.chk(G.phase3 Untouched && G.rev2Untouched, 'freeze intact');
T = T.eq(numel(G.q), 23, '23 questions answered');
T = T.chk(all([G.q.confirmed]), 'all confirmed against code behavior');
[np, nf] = T.done();
end
```

- [ ] **Step 2: Run test to verify it fails** — expected undefined-function FAIL.
- [ ] **Step 3: Write minimal implementation** — filesize/timestamp reader + checklist struct + markdown writer.
- [ ] **Step 4: Run test to verify it passes** — expected 3/3 + FULL `run_phase4_tests` green. Then STOP: no Phase-5 code.
- [ ] **Step 5: Log** — append T15 + totals. Declare Phase-4 implementation complete pending human approval.

## Self-Review

**1. Spec coverage:** Secs 3/5→T1; Sec 16→T2; Sec 10/12/13-grounding→T3; Sec 9→T4; Sec 6/7/15→T5; Sec 8/11–14→T6; Sec 18→T7; Sec 17/19-ip→T8; Sec 19-Ib-steady/21→T9; Sec 20→T10; Sec 23→T11 (+T12 completion); Sec 22→T12; Sec 26→T13; matrix→T14; Sec 24/27/28→T15. Q1–Q23 each answered by T2–T13 and gated in T15. Gaps: none.

**2. Placeholder scan:** No TBD/TODO/"appropriate handling" steps; every step names exact files, function signatures, assertion code, and run commands. "Minimal implementation" steps reference exact spec equations per task.

**3. Type consistency:** Registry struct → prefault struct → grounding struct → sources struct → seq structs → topology → solver → stages → contrib → validation/sensitivity → handoff tables. Field names (`Xdpp_used`, `parkConvention`, `Z3ZN_pu_machine`, `t_break`, `k0g`, `lambda_T`) fixed at first use and reused verbatim downstream.

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-09-18-phase4-implementation.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
