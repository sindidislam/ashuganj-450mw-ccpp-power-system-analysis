# Phase 3 Locked 0.7 km Line Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken 70 km generic line with the locked 0.7 km lumped dual-circuit Mallard PI model and validate the network without touching frozen Phase-2 physics.

**Architecture:** Delete-and-rebuild: restore Phase-2 7-branch baseline, add one `L_LINE` PI branch `B230_1 → B230_REMOTE` (0.7 km, 2-circuit lumped) plus `ZGRID` moved to `B230_REMOTE → BGRID230`; validator/runner rewritten on the `ashuganj_bus_map` + Phase-2 field schema; gated Phase-3 tests; OLD-vs-NEW comparison explains differences physically.

**Tech Stack:** MATLAB R2024a, Simulink/Specialized Power Systems (`power_loadflow`), existing `t_case` recorder, `run_all_tests`.

**Spec:** `docs/superpowers/specs/2026-09-18-phase3-line-model-design.md` plus the FINAL locked-assumption message (0.7 km, 2 circuits, Mallard 795 MCM, R1/X1/Y1 pu/km below). The plan argues from both; executors read all three.

## Global Constraints

- Phase 2 generator numerics frozen: 458 MVA, 22 kV, 360 MW cap, H 5.287 s, Xd 1.783, Xdp 0.3256, Xdpp 0.2608, Xdpp_sat 0.2248 (separate, never substituted), Xq 1.751, Xqp 0.5087, Xqpp 0.2593, Xl 0.2027, X2 0.2242, X0 0.128, Ra 0.00089 ohm, time constants, Q curve, NER grounding.
- Cases: LF360_GAT_OUT/IN primary; LF342 qualified; LF389P30 historical only; capacity policy unchanged.
- 0.7 km = ENGINEERING_ASSUMPTION (INEL-112070-00-ELC-DE-0026 unavailable); never PRIMARY_VERIFIED; 70 km retained only as documented conflict (400-kV/North block); 44 km = separate Ghorasal line, never the South link.
- Line pu base 100 MVA / 230 kV; Zbase = 529 ohm; R1 0.00015, X1 0.00077, Y1 0.001488 pu/km → R 0.07935, X 0.40733 ohm/km, B 2.81285 uS/km; 0.7 km single R 0.055545 / X 0.285131 ohm / B 1.968998 uS; parallel eq R 0.0277725 / X 0.1425655 ohm / B 3.937996 uS (R 0.0000525 / X 0.0002695 / B 0.0020832 pu). Status human-tier DERIVED_FROM_ENGINEERING_REFERENCE, struct status ENGINEERING_ASSUMPTION with derivation note (enum in `matlab/data/ashuganj_master_data.m:36-38` is closed).
- R0/X0/B0 never `3×X1` as fact; MISSING or separately justified assumption + sensitivity.
- Grid 50 kA / 19.9 GVA / |Z| 2.6558 ohm stays ESTIMATED at the remote bus; 45.01 kA set stays separate sensitivity.
- No fault/sequence/relay/TMS/breaker-duty/dynamic/battery/AVR/governor/SFC work in Phase 3.
- No new status strings in structs; fresh build per case + `bdclose`; bus identity by handle.

---

### Task 1: Hash baseline + protected/permitted list

**Files:**
- Create: `PHASE3_PRE_HASHES.txt` (overwrite stale absolute-path file, relative paths + SHA-256)
- Modify: none
- Test: manual inspection of hash file

**Interfaces:**
- Consumes: current working tree
- Produces: `PHASE3_PRE_HASHES.txt` with `relative_path,sha256,bytes,mtime` + protected/permitted table consumed by Task 14

- [ ] **Step 1: Generate relative-path hashes (PowerShell, no MATLAB needed)**

```powershell
Get-ChildItem -Recurse -File -Include *.m,*.csv,*.md,*.mat,*.slx `
  -Exclude 'PHASE3_POST_HASHES.txt','PHASE3_CHANGELOG.md','PHASE3_FINAL_REPORT.md' |
  Where-Object { $_.FullName -notmatch '\\tmp\\|\\results\\' } |
  ForEach-Object {
    $rel = Resolve-Path -Relative $_.FullName
    $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    "$h  $rel"
  } | Set-Content -Encoding utf8 PHASE3_PRE_HASHES.txt
```

- [ ] **Step 2: Run it and verify it is relative-path and non-empty**

Run: `powershell -NoProfile -Command " (Get-Content PHASE3_PRE_HASHES.txt -TotalCount 3); (Get-Content PHASE3_PRE_HASHES.txt).Count "`
Expected: first lines show `SHA  ./matlab/...` (no `G:\`), count > 100

- [ ] **Step 3: Record protected/permitted table at top of Task 14 working notes (no code)**

Protected (byte-identical required): `matlab/data/ashuganj_generators.m`, `ashuganj_transformers.m`, `ashuganj_loads.m`, `ashuganj_buses.m`, `ashuganj_operating_profiles.m`, `validate_operating_profile.m`, solver builders except line/grid hookup, `run_load_flow_study.m` engine.
Permitted: `matlab/data/ashuganj_lines.m` (line block only), `matlab/data/ashuganj_grid.m` (header comments only, no numeric change), new `matlab/analysis/validate_phase3_network.m`, `matlab/studies/run_phase3_load_flow.m`, `matlab/tests/test_phase3_*.m`, `test_line_data.m` gated update, results/docs/hash/changelog/report artifacts.

- [ ] **Step 4: Checkpoint**

Run: `powershell -NoProfile -Command "Get-Item PHASE3_PRE_HASHES.txt | Format-List Length,LastWriteTime"`
Expected: file exists, recent timestamp; record line count in `PHASE3_CHANGELOG.md` draft header

---

### Task 2: Delete broken other-AI artifacts, restore 7-branch baseline

**Files:**
- Modify: `matlab/data/ashuganj_lines.m:57-87,194-210` (remove L_LINE block + 2-branch asserts, restore 1-branch asserts)
- Delete: `matlab/analysis/validate_phase3_network.m`, `matlab/studies/run_phase3_load_flow.m`, `results/phase3_loadflow/*`, `phase3_lf_test*.txt`
- Test: `matlab/tests/test_line_data.m` (existing, must return to 47/0 before Task 4)

**Interfaces:**
- Consumes: `PHASE3_PRE_HASHES.txt`
- Produces: clean 7-branch `ashuganj_lines()` with `sum([L.Model_included])==1`, `ZGRID BGRID230→B230_1`

- [ ] **Step 1: Write the failing check (already exists — run it to confirm red)**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); [p,f]=test_line_data(); fprintf('line %d/%d\n',p,f); exit(f>0)"`
Expected: FAIL (`got 8 expected 7`, `got 2 expected 1`, ERRORED line 39)

- [ ] **Step 2: Delete the broken files**

```powershell
Remove-Item -LiteralPath "matlab\analysis\validate_phase3_network.m" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "matlab\studies\run_phase3_load_flow.m" -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "results\phase3_loadflow" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "phase3_lf_test.txt","phase3_lf_test2.txt","phase3_lf_test3.txt","phase3_lf_test4.txt","phase3_lf_test5.txt","phase3_lf_test6.txt","phase3_lf_test7.txt","phase3_lf_test8.txt" -ErrorAction SilentlyContinue
```

- [ ] **Step 3: Restore the 7-branch register (minimal edit in `ashuganj_lines.m`)**

Delete lines 57-87 (the `1.1 Physical 230 kV Transmission Line` block). Change `L(1).Bus_to` back to `'B230_1'`. Replace the integrity block with:

```matlab
assert(sum([L.Model_included]) == 1, ...
    'ashuganj_lines: exactly one series branch should be modelled (the grid equivalent).');
```

- [ ] **Step 4: Verify green before proceeding**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); [p,f]=test_line_data(); fprintf('line %d/%d\n',p,f); exit(f>0)"`
Expected: `line 47/0`, exit 0

- [ ] **Step 5: Checkpoint**

Record deleted files + restored assertion in `PHASE3_CHANGELOG.md` draft

---

### Task 3: Source audit + conflict table

**Files:**
- Create: `docs/validation/rev31_phase3/phase3_source_audit.csv`
- Modify: none
- Test: inspection (every model-bound row has a source file + page/section/cell)

**Interfaces:**
- Consumes: `fwdtechnicaldatasldrequestforbueteeetermproject/Line data.pdf`, `Google Sheet Form_Filled Up By APSCL.pdf`, `Data Sheet_230KV.pdf`, Rev 03 SLD/GIS excerpts, `docs/model/branch_list.md:55-67`
- Produces: CSV with `parameter,value,unit,doc,locator,status,tier,notes` consumed by Tasks 4-6

- [ ] **Step 1: Extract the Google-Form block verbatim (proves the conflict)**

Read `tmp/rev3_txt/Google Sheet Form_Filled Up By APSCL.txt:59-104` and record: R0 0.06667/km, X0 0.39472/km, B1 3.4011 S/km, L 70 km sit in the Section 3 block whose B1 baseline reads "Standard 400 kV bundled" and whose Sections 4-5 read "400 kV Bus Fault [Contact PGCB]", "400 kV GIS Bay CT". R1/X1 blank, Z1/Z0 "Contact PGCB".

- [ ] **Step 2: Write the CSV (minimum rows)**

```csv
parameter,value,unit,doc,locator,status,tier,notes
south_230kv_outgoing_existence,Line module 2000 A,A,Data Sheet_230KV.pdf,body pages,VERIFIED_ENGINEERING_DOCUMENT,L1,proves a line bay exists not its destination
south_230kv_destination,MISSING,,,MISSING,,destination substation not in source set
south_230kv_length,MISSING,,,MISSING,,0.7 km enters only as EA in Task 4
form_70km_length,70,km,Google Sheet Form_Filled Up By APSCL.pdf,Sec 3 Outgoing Circuit L,CONFLICT-DOCUMENTED,L2-disputed,400-kV/North block per branch_list.md:67; retained as conflict only
form_R0,0.06667,ohm/km,Google Sheet Form_Filled Up By APSCL.pdf,Sec 3 R0,CONFLICT-DOCUMENTED,L2-disputed,same block dispute; never South-230kV source
form_X0,0.39472,ohm/km,Google Sheet Form_Filled Up By APSCL.pdf,Sec 3 X0,CONFLICT-DOCUMENTED,L2-disputed,same block dispute
form_B1,3.4011,uS/km,Google Sheet Form_Filled Up By APSCL.pdf,Sec 3 B1,CONFLICT-DOCUMENTED,L2-disputed,same block dispute; unit recorded as uS not S
form_R1,MISSING,,,MISSING,,blank in source; Finch-typical only as EA
form_X1,MISSING,,,MISSING,,blank in source; Finch-typical only as EA
ghorsal_44km,44,km,Line data.pdf + PGCB/JICA docs,as cited,SECONDARY_SOURCE,L2,EXCLUDED from South link; engineering reference only
INEL_DE_0026,MISSING,,,MISSING,,authoritative GIS drawing unavailable; work does not block on it
```

- [ ] **Step 3: Verify every model-bound row resolves (no row ends in TBD)**

Run: `powershell -NoProfile -Command "Import-Csv docs/validation/rev31_phase3/phase3_source_audit.csv | Where-Object { $_.status -eq '' -or $_.doc -eq '' -and $_.status -notmatch 'MISSING' }"`
Expected: no output (empty = all rows classified)

- [ ] **Step 4: Checkpoint**

Record CSV path + row count in changelog draft

---

### Task 4: Locked 0.7 km lumped dual-circuit PI in `ashuganj_lines.m` + grid header fix

**Files:**
- Modify: `matlab/data/ashuganj_lines.m` (add locked L_LINE PI + move ZGRID to remote bus + asserts 8/2)
- Modify: `matlab/data/ashuganj_grid.m:22-23` header comments only (state remote-bus placement; no numeric change)
- Test: `matlab/tests/test_phase3_line_model.m` (Task 7, written first per TDD — this task stays red until Task 7 passes)

**Interfaces:**
- Consumes: Task 3 CSV + locked numbers below
- Produces: `D.lines` with `ZGRID (L, R=0)` + `L_LINE (PI, locked 0.7 km eq)` consumed by Tasks 5, 9-12

Locked numbers (100 MVA / 230 kV, Zbase 529 ohm): r1 0.00015 / x1 0.00077 / y1 0.001488 pu/km → 0.07935 / 0.40733 ohm/km, 2.81285 uS/km; single 0.7 km R 0.055545 / X 0.285131 ohm / B 1.968998 uS; eq R 0.0277725 / X 0.1425655 ohm / B 3.937996 uS (pu R 0.0000525 / X 0.0002695 / B 0.0020832). Metadata: `physical_circuit_count=2`, `model_representation=LUMPED_DUAL_CIRCUIT_PI`, `length_km=0.7`, `conductor_reference=MALLARD_795_MCM`, all statuses ENGINEERING_ASSUMPTION with derivation note; human-tier column DERIVED_FROM_ENGINEERING_REFERENCE.

- [ ] **Step 1: Write the failing test first (see Task 7 for full file — create it now, run, watch fail)**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); [p,f]=test_phase3_line_model(); fprintf('p3line %d/%d\n',p,f); exit(f>0)"`
Expected: FAIL (`L_LINE not found`)

- [ ] **Step 2: Minimal implementation — append after ZGRID block in `ashuganj_lines.m`**

```matlab
k=k+1;
L(k).Name = 'L_LINE';
L(k).Label = 'SOUTH GIS TO GRID 0.7KM D/C MALLARD EQ';
L(k).Bus_from = 'B230_1';
L(k).Bus_to = 'B230_REMOTE';
L(k).Vnom_V = 230000;
L(k).Model_included = true;
L(k).Model_block = 'sps_lib/Passives/Three-Phase PI Section Line';
L(k).BranchType = 'PI';
L(k).Length_km = 0.7;
L(k).Length_Status = 'ENGINEERING_ASSUMPTION';
L(k).Length_Note = 'Locked Phase-3 EA: 0.7 km GIS-to-grid; INEL-112070-00-ELC-DE-0026 unavailable. 70 km retained only as documented 400-kV/North conflict; 44 km is the separate Ghorasal line.';
L(k).Physical_circuit_count = 2;
L(k).Model_representation = 'LUMPED_DUAL_CIRCUIT_PI';
L(k).Conductor_reference = 'MALLARD_795_MCM';
L(k).Conductor_Status = 'ENGINEERING_ASSUMPTION';
L(k).R_ohm = 0.0277725;  L(k).R_Status = 'ENGINEERING_ASSUMPTION';
L(k).R_Note = 'DERIVED_FROM_ENGINEERING_REFERENCE (human tier): (0.00015 pu/km*529)/2*0.7; ref Ghorasal-Mallard PGCB/JICA, NOT measured South link.';
L(k).X_ohm = 0.1425655;  L(k).X_Status = 'ENGINEERING_ASSUMPTION';
L(k).X_Note = 'DERIVED_FROM_ENGINEERING_REFERENCE (human tier): (0.00077 pu/km*529)/2*0.7; same reference.';
L(k).C_F = 3.937996e-6/(2*pi*50);  L(k).C_Status = 'ENGINEERING_ASSUMPTION';
L(k).C_Note = 'DERIVED_FROM_ENGINEERING_REFERENCE (human tier): B=3.937996 uS (2x1.968998) at 50 Hz; C=B/(2*pi*50).';
L(k).R0_ohm = NaN; L(k).R0_Status = 'MISSING';
L(k).X0_ohm = NaN; L(k).X0_Status = 'MISSING';
L(k).C0_F = NaN;   L(k).C0_Status = 'MISSING';
```

Also change `L(1).Bus_to` to `'B230_REMOTE'` with note `Phase-3: grid equivalent moved to remote bus; plant bus connects via L_LINE`, and update asserts to `numel==8`, `sum==2`.

- [ ] **Step 3: Grid header fix (comments only)**

In `ashuganj_grid.m` replace the Q7a comment with: `% Phase 3: equivalent sits at B230_REMOTE behind the 0.7 km physical line (Task 4). Numerical estimate unchanged (ESTIMATED).` plus `G.Bus_boundary` stays `'B230_1'` only if builder resolves plant-side naming — otherwise add `G.Bus_remote='B230_REMOTE'` as a display field without changing solver wiring. No numeric change.

- [ ] **Step 4: Run the new test (still red until Task 7 asserts match — record output)**

Run: same command as Step 1
Expected: still FAIL until Task 7 file is complete (this is the TDD red state; do not fix by editing the test to match typos — fix the implementation)

- [ ] **Step 5: Checkpoint**

Record `R/X/B` values + `ZGRID` move in changelog draft

---

### Task 5: Rewrite `validate_phase3_network` on the Phase-2 schema

**Files:**
- Create: `matlab/analysis/validate_phase3_network.m` (overwrite deleted stub)
- Modify: none
- Test: Task 9 solves (val struct must contain every field the runner prints)

**Interfaces:**
- Consumes: `LF` (power_loadflow result), `D=ashuganj_master_data()`, `C=info.case`, `info` (zones, model)
- Produces: `val` with `converged,iterations,Pgen_MW,Qgen_MVAr,Sgen_MVA,PFgen,PF_type,Paux_MW,Qaux_MVAr,Vgen_pu,Vgen_kV,V230_1_pu,V230_1_kV,V230_2_pu,V230_2_kV,V6_6_pu,V6_6_kV,V_REMOTE_pu,line_P_loss_MW,line_Q_loss_MVAr,branch_losses_P_MW,branch_losses_Q_MVAr,P_balance_err_MW,Q_balance_err_MVAr,worst_KCL_MVA,capability_*,verdict`

- [ ] **Step 1: Write minimal validator (copy Phase-2 pattern, add remote bus + line split)**

```matlab
function val = validate_phase3_network(LF, D, C, info)
val = struct(); val.case_id = C.ID; val.case_name = C.Name;
val.converged = (LF.status == 1 && isempty(LF.error));
val.iterations = LF.iterations;
if ~val.converged, val.verdict = 'DID_NOT_CONVERGE'; val.status = 'FAILED'; return; end
Sb = D.base.Sbase_MVA;
node = ashuganj_bus_map(LF, D, info.zones);
val.Pgen_MW = real(LF.bus(node.B22).Sbus)*Sb;
val.Qgen_MVAr = imag(LF.bus(node.B22).Sbus)*Sb;
val.Sgen_MVA = abs(LF.bus(node.B22).Sbus)*Sb;
val.PFgen = abs(val.Pgen_MW)/val.Sgen_MVA;
val.PF_type = 'Lagging'; if val.Qgen_MVAr < 0, val.PF_type = 'Leading'; end
val.Paux_MW = C.Load_P_MW; val.Qaux_MVAr = C.Load_Q_MVAr;
val.Vgen_pu = abs(LF.bus(node.B22).Vbus); val.Vgen_kV = val.Vgen_pu*22.0;
val.V230_1_pu = abs(LF.bus(node.B230_1).Vbus); val.V230_1_kV = val.V230_1_pu*230.0;
val.V230_2_pu = abs(LF.bus(node.B230_2).Vbus); val.V230_2_kV = val.V230_2_pu*230.0;
val.V6_6_pu = abs(LF.bus(node.B6_6).Vbus); val.V6_6_kV = val.V6_6_pu*6.6;
val.V_REMOTE_pu = abs(LF.bus(node.B230_REMOTE).Vbus); val.V_REMOTE_kV = val.V_REMOTE_pu*230.0;
R = ashuganj_branch_flows(LF, D, C, info.zones);
[B, res] = ashuganj_bus_results(LF, D, C, R, info.zones);
val.branch_flows = R; val.bus_results = B; val.residuals = res;
ok = ~isnan([R.P_loss_MW]);
val.branch_losses_P_MW = sum([R(ok).P_loss_MW]);
val.branch_losses_Q_MVAr = sum([R(ok).Q_loss_MVAr]);
il = find(strcmp({R.Name},'L_LINE'),1);
if isempty(il), val.line_P_loss_MW = NaN; val.line_Q_loss_MVAr = NaN;
else, val.line_P_loss_MW = R(il).P_loss_MW; val.line_Q_loss_MVAr = R(il).Q_loss_MVAr; end
val.Pgrid_export_MW = -real(LF.bus(node.BGRID230).Sbus)*Sb;
val.Qgrid_export_MVAr = -imag(LF.bus(node.BGRID230).Sbus)*Sb;
val.P_balance_err_MW = abs(val.Pgen_MW-(val.Paux_MW+val.Pgrid_export_MW+val.branch_losses_P_MW));
val.Q_balance_err_MVAr = abs(val.Qgen_MVAr-(val.Qaux_MVAr+val.Qgrid_export_MVAr+val.branch_losses_Q_MVAr));
val.worst_KCL_MVA = max([res.Residual_MVA]);
cap = check_generator_operating_point(val.Pgen_MW, val.Qgen_MVAr, D.gen(1).Snom_MVA, D.gen(1).capabilityCurve);
val.capability_status = cap.status; val.Qmax_allowed_MVAr = cap.Qmax_allowed_MVAr;
val.Qmin_allowed_MVAr = cap.Qmin_allowed_MVAr; val.Q_upper_margin_MVAr = cap.Q_upper_margin_MVAr;
val.Q_lower_margin_MVAr = cap.Q_lower_margin_MVAr; val.MVA_margin = cap.MVA_margin; val.Q_clipped = cap.Q_clipped;
issues = {};
if abs(val.Pgen_MW-C.Gen_P_MW) > 1e-3, issues{end+1} = 'DISPATCH_MISMATCH'; end
if val.worst_KCL_MVA > 0.05, issues{end+1} = sprintf('KCL_RESIDUAL_HIGH (%.3e MVA)',val.worst_KCL_MVA); end
if val.P_balance_err_MW > 1e-3, issues{end+1} = sprintf('ACTIVE_BALANCE_MISMATCH (err %.6f MW)',val.P_balance_err_MW); end
if val.Q_balance_err_MVAr > 1e-3, issues{end+1} = sprintf('REACTIVE_BALANCE_MISMATCH (err %.6f MVAr)',val.Q_balance_err_MVAr); end
if ~strcmp(val.capability_status,'WITHIN_CAPABILITY'), issues{end+1} = ['CAPABILITY_' val.capability_status]; end
if isempty(issues), val.verdict = 'OK'; else, val.verdict = strjoin(issues,'; '); end
val.status = 'OK';
end
```

- [ ] **Step 2: Syntax-check without solving**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); disp(exist('validate_phase3_network','file')); exit(0)"`
Expected: `2` (file found), exit 0

- [ ] **Step 3: Checkpoint**

Record validator field list in changelog draft (runner in Task 6 depends on these exact names)

---

### Task 6: Rewrite `run_phase3_load_flow` to the Phase-2 field schema

**Files:**
- Create: `matlab/studies/run_phase3_load_flow.m`
- Modify: none
- Test: Task 9 (`Write=false` solve of LF360 pair must return 2 records with `Gen_V_pu`, `V230_1_kV`, `Loss_P_MW`, `Worst_KCL_MVA`, `Verdict`)

**Interfaces:**
- Consumes: `validate_phase3_network` val struct from Task 5
- Produces: `S` records + CSV/MAT writers to `results/phase3_loadflow/` consumed by Tasks 9-12

- [ ] **Step 1: Write runner (fresh build → solve → validate → close → record → optionally write)**

```matlab
function S = run_phase3_load_flow(varargin)
p = inputParser;
addParameter(p,'Cases',{'LF360_GAT_OUT','LF360_GAT_IN'});
addParameter(p,'Write',true,@islogical);
addParameter(p,'OutputDir','',@ischar);
parse(p,varargin{:}); opt = p.Results;
root = ashuganj_root();
if isempty(opt.OutputDir), outDir = fullfile(root,'results','phase3_loadflow');
else, outDir = opt.OutputDir; end
D = ashuganj_master_data();
if ischar(opt.Cases) && strcmp(opt.Cases,'all'), case_ids = {D.operating_profiles.ID};
elseif ischar(opt.Cases), case_ids = {opt.Cases};
else, case_ids = opt.Cases; end
if opt.Write && ~exist(outDir,'dir'), mkdir(outDir); end
S = []; all_bus_results = {};
for i = 1:numel(case_ids)
  cid = case_ids{i};
  info = build_ashuganj_main(cid,'Quiet',true,'Backup',false,'Save',false);
  C = info.case; t0 = tic;
  LF = power_loadflow(info.model,'solve'); elapsed = toc(t0);
  val = validate_phase3_network(LF,D,C,info);
  if bdIsLoaded(info.model), bdclose(info.model); end
  s = struct('ID',cid,'Name',C.Name,'GAT_in',C.GAT_in,'Converged',val.converged,...
    'Iterations',val.iterations,'Solve_time_s',elapsed,'Gen_P_MW',val.Pgen_MW,...
    'Gen_Q_MVAr',val.Qgen_MVAr,'Gen_S_MVA',val.Sgen_MVA,'Gen_PF',val.PFgen,...
    'Gen_PF_type',val.PF_type,'Gen_V_pu',val.Vgen_pu,'Gen_V_kV',val.Vgen_kV,...
    'V230_1_kV',val.V230_1_kV,'V230_2_kV',val.V230_2_kV,'V6_6_kV',val.V6_6_kV,...
    'V_REMOTE_kV',val.V_REMOTE_kV,'Paux_MW',val.Paux_MW,'Qaux_MVAr',val.Qaux_MVAr,...
    'Export_P_MW',val.Pgrid_export_MW,'Export_Q_MVAr',val.Qgrid_export_MVAr,...
    'Loss_P_MW',val.branch_losses_P_MW,'Loss_Q_MVAr',val.branch_losses_Q_MVAr,...
    'Line_P_loss_MW',val.line_P_loss_MW,'Line_Q_loss_MVAr',val.line_Q_loss_MVAr,...
    'Worst_KCL_MVA',val.worst_KCL_MVA,'P_balance_err_MW',val.P_balance_err_MW,...
    'Q_balance_err_MVAr',val.Q_balance_err_MVAr,'Capability_status',val.capability_status,...
    'Q_upper_margin_MVAr',val.Q_upper_margin_MVAr,'Q_lower_margin_MVAr',val.Q_lower_margin_MVAr,...
    'MVA_margin',val.MVA_margin,'Verdict',val.verdict);
  S = [S;s]; all_bus_results{end+1} = struct('case_id',cid,'table',val.bus_results);
end
if opt.Write && ~isempty(S)
  writetable(struct2table(rmfield(S,{'Name','Gen_PF_type','Capability_status','Verdict'})),fullfile(outDir,'phase3_system_summary.csv'));
  save(fullfile(outDir,'phase3_loadflow_results.mat'),'S','all_bus_results');
end
end
```

- [ ] **Step 2: Dry-run without writing**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); S=run_phase3_load_flow('Cases',{'LF360_GAT_OUT'},'Write',false); disp(S.Verdict); exit(0)"`
Expected: `OK` (or a named mismatch, never a missing-field error)

- [ ] **Step 3: Checkpoint**

Record runner output fields in changelog draft

---

### Task 7: Phase-3 line-model tests (TDD green for Task 4)

**Files:**
- Create: `matlab/tests/test_phase3_line_model.m`
- Modify: `matlab/tests/test_line_data.m` — gated update ONLY (change 7→8, 1→2 with Phase-3 reason comment; no other assertion weakened)
- Test: this file (20 checks)

**Interfaces:**
- Consumes: `ashuganj_lines()`, `ashuganj_grid()`
- Produces: green gate for the locked model, consumed by Task 13 regression

- [ ] **Step 1: Write the failing test**

```matlab
function [np,nf] = test_phase3_line_model()
T = t_case('Phase 3 locked 0.7 km line model');
L = ashuganj_lines();
T = T.eq(numel(L),8,'register holds 8 entries (7 Phase-2 + L_LINE)');
inc = find([L.Model_included]);
T = T.eq(numel(inc),2,'two modelled branches (ZGRID + L_LINE)');
k = find(strcmp({L.Name},'L_LINE'),1);
T = T.chk(~isempty(k),'L_LINE present');
T = T.eq(L(k).Bus_from,'B230_1','L_LINE from plant bus');
T = T.eq(L(k).Bus_to,'B230_REMOTE','L_LINE to remote bus');
T = T.eq(L(k).Vnom_V,230000,'230 kV');
T = T.eq(L(k).Length_km,0.7,'locked 0.7 km');
T = T.eq(L(k).Length_Status,'ENGINEERING_ASSUMPTION','0.7 km is EA not verified');
T = T.eq(L(k).Physical_circuit_count,2,'two physical circuits');
T = T.eq(L(k).Model_representation,'LUMPED_DUAL_CIRCUIT_PI','lumped dual-circuit PI');
T = T.eq(L(k).Conductor_reference,'MALLARD_795_MCM','Mallard reference');
T = T.near(L(k).R_ohm,0.0277725,1e-9,'R_eq 0.0277725 ohm');
T = T.near(L(k).X_ohm,0.1425655,1e-9,'X_eq 0.1425655 ohm');
T = T.near(L(k).C_F,3.937996e-6/(2*pi*50),1e-15,'C from B_eq 3.937996 uS');
T = T.eq(L(k).R0_Status,'MISSING','R0 missing not invented');
T = T.eq(L(k).X0_Status,'MISSING','X0 missing not invented');
T = T.eq(L(k).C0_Status,'MISSING','C0 missing not invented');
Gr = ashuganj_grid();
T = T.near(Gr.X_ohm,2.65581123827228,1e-9,'grid |Z| 2.6558 ohm preserved');
T = T.eq(Gr.R_ohm,0,'grid R still 0');
T = T.eq(Gr.Isc_Status,'ESTIMATED','grid stays ESTIMATED');
[np,nf] = T.done();
end
```

- [ ] **Step 2: Run to confirm green after Task 4**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); [p,f]=test_phase3_line_model(); fprintf('p3line %d/%d\n',p,f); exit(f>0)"`
Expected: PASS 20/0

- [ ] **Step 3: Gated update of `test_line_data.m` (authorized Phase-3 change)**

Change `numel(L),7` → `8` and `numel(inc),1` → `2` with comment `% Phase-3 AUTHORIZED: +L_LINE 0.7 km lumped dual-circuit; Phase-2 baseline was 7/1 per PRE_HASHES`. No other line weakened.

- [ ] **Step 4: Checkpoint**

Record test counts in changelog draft

---

### Task 8: Fresh-build determinism test

**Files:**
- Create: `matlab/tests/test_phase3_determinism.m`
- Modify: none
- Test: this file

**Interfaces:**
- Consumes: `build_ashuganj_main`, `power_loadflow`, `validate_phase3_network`
- Produces: guard against mutation/frequency/workspace flakiness for Tasks 9-13

- [ ] **Step 1: Write the test**

```matlab
function [np,nf] = test_phase3_determinism()
T = t_case('Phase 3 fresh-build determinism');
info1 = build_ashuganj_main('LF360_GAT_OUT','Quiet',true,'Backup',false,'Save',false);
LF1 = power_loadflow(info1.model,'solve');
v1 = validate_phase3_network(LF1,ashuganj_master_data(),info1.case,info1);
if bdIsLoaded(info1.model), bdclose(info1.model); end
info2 = build_ashuganj_main('LF360_GAT_OUT','Quiet',true,'Backup',false,'Save',false);
LF2 = power_loadflow(info2.model,'solve');
v2 = validate_phase3_network(LF2,ashuganj_master_data(),info2.case,info2);
if bdIsLoaded(info2.model), bdclose(info2.model); end
T = T.near(v1.Pgen_MW,v2.Pgen_MW,1e-9,'P deterministic');
T = T.near(v1.Qgen_MVAr,v2.Qgen_MVAr,1e-9,'Q deterministic');
T = T.near(v1.V_REMOTE_pu,v2.V_REMOTE_pu,1e-12,'Vremote deterministic');
T = T.near(v1.worst_KCL_MVA,v2.worst_KCL_MVA,1e-12,'KCL deterministic');
T = T.eq(v1.verdict,v2.verdict,'verdict deterministic');
[np,nf] = T.done();
end
```

- [ ] **Step 2: Run it**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); [p,f]=test_phase3_determinism(); fprintf('determ %d/%d\n',p,f); exit(f>0)"`
Expected: PASS 5/0

- [ ] **Step 3: Checkpoint**

Record in changelog draft

---

### Task 9: Solve + OLD-vs-NEW compatibility

**Files:**
- Modify: none (reads only)
- Create: `docs/validation/rev31_phase3/phase2_vs_phase3.csv` (via runner outputs)
- Test: `run_phase3_load_flow('Write',false)` for LF360 pair + LF342 pair + LF389P30 pair

**Interfaces:**
- Consumes: Tasks 4-6 + `results/phase2_loadflow/phase2_system_summary.csv` (OLD baseline)
- Produces: NEW `results/phase3_loadflow/` + comparison table for Task 15

- [ ] **Step 1: Solve NEW cases without writing**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); S=run_phase3_load_flow('Cases',{'LF360_GAT_OUT','LF360_GAT_IN'},'Write',false); fprintf('%s %s Pbal=%.2e KCL=%.2e\n',S(1).ID,S(1).Verdict,S(1).P_balance_err_MW,S(1).Worst_KCL_MVA); exit(0)"`
Expected: `OK` with P err < 1e-3, KCL < 0.05 (0.7 km line is short; unlike the 70 km artifact, it must not inject MW-scale imbalance)

- [ ] **Step 2: Write NEW artifacts**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); run_phase3_load_flow('Cases','all','Write',true); exit(0)"`
Expected: `results/phase3_loadflow/phase3_system_summary.csv` + `.mat` exist

- [ ] **Step 3: Build OLD-vs-NEW table (generator P/Q, grid P/Q, total + line loss, V230/V22/V6.6, transformer + line loading, iters, KCL) and explain differences physically (short-line series drop + charging), never forcing OLD numbers**

- [ ] **Step 4: Checkpoint**

Record NEW export/loss/voltages in changelog draft

---

### Task 10: Loading, voltage drop, losses

**Files:**
- Modify: none (analysis of Task 9 outputs)
- Create: section inputs for final report (no new code unless a helper is needed)
- Test: manual calc check: `I=S/(√3·V)`, `loading=|I|/rating` (rating MISSING → report "Thermal rating unavailable"), `ΔV%=(|Vs|-|Vr|)/|Vs|·100`, `Ploss/Qloss` from branch reconstruction

- [ ] **Step 1: Compute line current/loading/drop/loss for LF360 pair from `phase3_system_summary.csv` + bus results; show formulas + units + numbers**
- [ ] **Step 2: Verify drop/loss sign and size against hand calc `ΔV≈(RP+XQ)/V` with the locked 0.7 km R/X; record agreement**
- [ ] **Step 3: Checkpoint**

---

### Task 11: Conservation checks

**Files:**
- Modify: none
- Test: validator balances (P err < 1e-3 MW, Q err < 1e-3 MVAr, worst KCL < 0.05 MVA) for every solved case + independent `3I²R` spot check on L_LINE

- [ ] **Step 1: Run balances**

Run: same Task 9 solve; assert all `Verdict==OK`
Expected: PASS (0.7 km line contributes sub-kW to sub-10-kW scale loss; no 53 MW spreads as in the 70 km artifact)

- [ ] **Step 2: Checkpoint**

---

### Task 12: Sensitivity

**Files:**
- Modify: none (in-memory overrides only; no committed parameter change)
- Test: three runs — single-circuit-out (R/X ×2, B /2), R/X/B ±20 %, grid 50 kA ESTIMATED vs 45.01 kA secondary profile

- [ ] **Step 1: Run sensitivities with `Write=false` overrides; record export/loss/V/KCL movement**
- [ ] **Step 2: Confirm movements are small and monotonic (0.7 km) and do not reproduce the 70 km artifact's 53 MW swings**
- [ ] **Step 3: Checkpoint**

---

### Task 13: Full regression

**Files:**
- Modify: `matlab/tests/run_all_tests.m` (register the two new Phase-3 tests in the `all` list only; no existing test weakened)
- Test: `run_all_tests('all')`

**Interfaces:**
- Consumes: Tasks 7-8 + all Phase-2 tests
- Produces: `docs/validation/rev31_phase3/task-6-all-tests.log` (fresh) for the final report

- [ ] **Step 1: Register tests**

```matlab
phase3Tests = {'test_phase3_line_model','test_phase3_determinism'};
list = [dataTests, phase2DataTests, modelTests, phase2ModelTests, phase3Tests];
```

- [ ] **Step 2: Run full suite fresh**

Run: `& "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" -batch "run('matlab/ashuganj_setup.m'); [np,nf]=run_all_tests('all'); fprintf('ALL %d/%d\n',np,nf); exit(nf>0)"`
Expected: 0 failures; any failure is investigated per systematic-debugging (root cause first), never silenced by retuning R/taps/tolerance

- [ ] **Step 3: Checkpoint (save full log to `docs/validation/rev31_phase3/`)**

---

### Task 14: Hash/change audit

**Files:**
- Create: `PHASE3_POST_HASHES.txt`, `PHASE3_CHANGELOG.md` (final)
- Modify: none
- Test: diff PRE vs POST matches the authorized table; every protected file byte-identical

**Interfaces:**
- Consumes: Task 1 PRE hashes + working changelog drafts
- Produces: `File | Before | After | Changed? | Authorized? | Reason` table for the final report

- [ ] **Step 1: Regenerate POST hashes with the same relative-path command as Task 1**
- [ ] **Step 2: Diff and verify: protected files unchanged; only Task 1-permitted files differ; new files listed as ADDED**
- [ ] **Step 3: Write `PHASE3_CHANGELOG.md` (every modified/added/deleted file + reason + source basis + test impact; no silent changes)**

---

### Task 15: `PHASE3_FINAL_REPORT.md`

**Files:**
- Create: `PHASE3_FINAL_REPORT.md` (root) + `docs/validation/rev31_phase3/` evidence bundle
- Modify: none
- Test: checklist — all 10 deliverables present (§42 of the prompt): source audit, topology, parameter table, classification, assumption justification, LF compat, sensitivity, tests, hash audit, this report

**Interfaces:**
- Consumes: Tasks 1-14 artifacts
- Produces: frozen Phase 3

- [ ] **Step 1: Write the 28-section report per §48 (Exec Summary → Phase-4 Readiness), including the §49 boundary sentence: "Phase 3 establishes and validates the physical transmission/network representation. Symmetrical short-circuit analysis is reserved for Phase 4 and has not been implemented in this phase."**
- [ ] **Step 2: Include battery note verbatim per §45 (110 VDC bay supply supported; 55-cell/200 Ah/0.05 Ω/20 kW/123.75 V float are academic assumptions; no IEEE 485 claim) without modifying the Phase-2 battery model**
- [ ] **Step 3: Freeze: record POST hashes, close changelog, mark the 46-completion-criteria boxes**

---

## Self-Review

- Spec coverage: locked 0.7 km numbers + conversions (§4 of this plan) trace to the FINAL message; 70 km/44 km exclusions + conflict table trace to §42 items 1-8; single-branch formula + sensitivity trace to §§10/13/20; grid 2.6558 Ω fencing traces to §12; taxonomy mapping traces to §§17-18/44; determinism traces to the revision request; hashes/changelog/report trace to §§40-42/46/48; battery note traces to §§28/45; no-fault/relay/dynamic scope traces to §§29-31/49.
- Placeholder scan: no TBD/TODO/"appropriate"/"similar to Task N"; every code step shows actual MATLAB/PowerShell; every run step shows the exact `-batch` command and expected output.
- Type consistency: `validate_phase3_network` field names in Task 5 exactly match `run_phase3_load_flow` accesses in Task 6 and the determinism assertions in Task 8; `L_LINE` field names in Task 4 exactly match Task 7 assertions; no git commands (no git repo — checkpoints use the changelog + hash files instead).
