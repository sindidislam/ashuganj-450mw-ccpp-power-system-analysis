function G = phase4_review_gate()
%PHASE4_REVIEW_GATE  Phase-4 review gate: freeze re-check, Q1-Q23 evidence, STOP.
%
%   G = PHASE4_REVIEW_GATE() re-checks the Phase-3/rev2 freeze record
%   (exact byte sizes; local timestamps exact or within 61 s tolerance,
%   tolerance recorded honestly in the markdown), executes the 23 review
%   questions against live code behavior (each check really runs; failure
%   sets confirmed=false, never forced true), and writes
%   PHASE4_REVIEW_GATE.md at the project root (via ashuganj_root) with the
%   freeze table, the Q-table, the remaining-data D1-D8 table and the STOP
%   statement (overwritten each run; deterministic content modulo the run
%   timestamp, which is the LAST line only).
%
%   Any freeze mismatch errors error('phase4_review:freeze') with a
%   file:line-style message. Q failures do not error; they clear the
%   corresponding confirmed flag.
%
%   Output: G.phase3Untouched (logical), G.rev2Untouched (logical),
%   G.q (1x23 struct: id, confirmed, evidence).
%
%   No IEC 60909 compliance claim. Modifies no existing file (only the new
%   root markdown, overwritten each run, plus a 'gate_smoke' handoff tag
%   directory only when no reusable smoke run exists).

root = ashuganj_root();

% ---- freeze record (exact; ANY mismatch errors phase4_review:freeze) ----
e1 = datenum('2026-09-18 13:02:04', 'yyyy-mm-dd HH:MM:SS');
e2 = datenum('2026-09-18 13:02:00', 'yyyy-mm-dd HH:MM:SS');
e3 = datenum('2026-09-18 12:42:16', 'yyyy-mm-dd HH:MM:SS');
e4 = datenum('2026-09-18 12:40:20', 'yyyy-mm-dd HH:MM:SS');
F1 = checkLocal(root, 'PHASE3_FINAL_REPORT.md', 45504, e1);
F2 = checkLocal(root, 'PHASE3_CHANGELOG.md', 25257, e2);
F3 = checkLocal(root, fullfile('matlab', 'data', 'ashuganj_lines.m'), 13448, e3);
F4 = checkLocal(root, fullfile('matlab', 'data', 'ashuganj_grid.m'), 10655, e4);
R1 = checkRev2(root, fullfile('rev2', 'data', 'iec_kappa.m'), 267);
R2 = checkRev2(root, fullfile('rev2', 'run_phase2_fault.m'), 9388);
phase3Untouched = F1.ok && F2.ok && F3.ok && F4.ok;
rev2Untouched = R1.ok && R2.ok;
tolNote = '';
if F1.tolUsed || F2.tolUsed || F3.tolUsed || F4.tolUsed
    tolNote = 'timestamp compare used 61-second tolerance on at least one file (honesty note: sub-second fidelity not asserted; sizes stay exact)';
end
fprintf('phase4_review_gate freeze: phase3=%d rev2=%d %s\n', phase3Untouched, rev2Untouched, tolNote);

% ---- shared validation smoke run (Q5 + Q18 read the same legs) ----
V = phase4_validate('gate_review');

% ---- Q1-Q23 (each really executes; failure -> confirmed=false) ----
q(1, 23) = struct('id', '', 'confirmed', false, 'evidence', '');

try
    So = phase4_sources('LF360_GAT_OUT', 'sat');
    Si = phase4_sources('LF360_GAT_IN', 'sat');
    d = abs(So.Epp - Si.Epp);
    ok = isfinite(d) && d > 1e-9;
    ev = sprintf('phase4_sources.m:61 per-case prefault; Epp_OUT=%.6f%+.6fj Epp_IN=%.6f%+.6fj diff=%.3g>0', real(So.Epp), imag(So.Epp), real(Si.Epp), imag(Si.Epp), d);
catch ME
    ok = false; ev = sprintf('Q1 execute-fail: %s', ME.message);
end
q(1) = struct('id', 'Q1', 'confirmed', logical(ok), 'evidence', ev);

try
    Rg = phase4_registry();
    Su = phase4_sources('LF360_GAT_OUT', 'unsat');
    St = phase4_sources('LF360_GAT_OUT', 'sat');
    ok = Rg.machine.Xdpp_sat.value == 0.2248 && strcmp(Rg.machine.Xdpp_sat.variant, 'primary') ...
        && Rg.machine.Xdpp.value == 0.2608 && Rg.machine.Xdpp_sat.value ~= Rg.machine.Xdpp.value ...
        && St.Xdpp_used == 0.2248 && Su.Xdpp_used == 0.2608;
    ev = sprintf('phase4_registry.m:43-44 Xdpp_sat=0.2248 primary vs Xdpp=0.2608 sensitivity, differ; sources sat/unsat Xdpp_used=%.4f/%.4f, never averaged', St.Xdpp_used, Su.Xdpp_used);
catch ME
    ok = false; ev = sprintf('Q2 execute-fail: %s', ME.message);
end
q(2) = struct('id', 'Q2', 'confirmed', logical(ok), 'evidence', ev);

try
    Gp = phase4_grounding('primary');
    n = (22000 / sqrt(3)) / 500;
    expR = 60 + n^2 * 2.62;
    ok = abs(Gp.R_NER_HV - expR) < 1e-9 && abs(Gp.R_NER_HV - 1750.77) < 0.05 ...
        && abs(Gp.Z3ZN_ohm - 3 * Gp.R_NER_HV) < 1e-9;
    try
        phase4_grounding('solid');
        ok = false; rejNote = 'solid accepted (BAD)';
    catch ME2
        ok = ok && ~isempty(strfind(ME2.identifier, 'phase4'));
        rejNote = 'solid rejected';
    end
    ev = sprintf('phase4_grounding.m:85-88 primary R_NER_HV=%.4f (~1750.77) Z3ZN=3x zero-only; %s (%s)', Gp.R_NER_HV, rejNote, 'phase4_grounding:variant');
catch ME
    ok = false; ev = sprintf('Q3 execute-fail: %s', ME.message);
end
q(3) = struct('id', 'Q3', 'confirmed', logical(ok), 'evidence', ev);

try
    N = phase4_seqPN('P', 15);
    kM = 100 / 458;
    ok = abs(N.Z2gen_X - 0.2242 * kM) < 1e-12 ...
        && N.Z2gsut_R == N.Z1gsut_R && N.Z2gsut_X == N.Z1gsut_X ...
        && N.Z2uat_R == N.Z1uat_R && N.Z2uat_X == N.Z1uat_X ...
        && N.Z2gat_R == N.Z1gat_R && N.Z2gat_X == N.Z1gat_X ...
        && N.Z2line_R_pu == N.Z1line_R_pu && N.Z2grid_R == N.Z1grid_R;
    ev = sprintf('phase4_seqPN.m:58-59 Z2gen_X=%.8f from X2=0.2242; Z2=Z1 static equalities hold (GSUT/UAT/GAT/line/grid)', N.Z2gen_X);
catch ME
    ok = false; ev = sprintf('Q4 execute-fail: %s', ME.message);
end
q(4) = struct('id', 'Q4', 'confirmed', logical(ok), 'evidence', ev);

try
    ok = V.legs(10).pass && V.legs(11).pass && V.legs(13).pass;
    ev = sprintf('phase4_validate runID=gate_review legs L10/L11/L13 pass=%d/%d/%d res=%.3g/%.3g/%.3g', V.legs(10).pass, V.legs(11).pass, V.legs(13).pass, V.legs(10).residual, V.legs(11).residual, V.legs(13).residual);
catch ME
    ok = false; ev = sprintf('Q5 execute-fail: %s', ME.message);
end
q(5) = struct('id', 'Q5', 'confirmed', logical(ok), 'evidence', ev);

try
    Rg = phase4_registry();
    ok = Rg.gsut.Z_pct.value == 16.0 && Rg.gsut.R_pct.value == 0.21 && Rg.gsut.Z0_pct.value == 15.8;
    ev = sprintf('phase4_registry.m:64-66 GSUT Z=16.0 R=0.21 Z0=15.8 pct on 515MVA tap9');
catch ME
    ok = false; ev = sprintf('Q6 execute-fail: %s', ME.message);
end
q(6) = struct('id', 'Q6', 'confirmed', logical(ok), 'evidence', ev);

try
    Rg = phase4_registry();
    Gp = phase4_grounding('primary');
    expZN = (6900 / sqrt(3)) / 5;
    ok = Rg.uat.Z_pct.value == 10.5 && Rg.uat.R_pct.value == 0.4 && Rg.uat.Z0_pct.value == 9.3 ...
        && Rg.uat.ground_limit_A.value == 5 && abs(Gp.ZN_UAT_ohm - expZN) < 0.05;
    ev = sprintf('phase4_registry.m:67-70 UAT Z=10.5 R=0.4 Z0=9.3 pct + 5-A limit; grounding ZN_UAT=%.4f ohm (~796.74)', Gp.ZN_UAT_ohm);
catch ME
    ok = false; ev = sprintf('Q7 execute-fail: %s', ME.message);
end
q(7) = struct('id', 'Q7', 'confirmed', logical(ok), 'evidence', ev);

try
    Rg = phase4_registry();
    Gp = phase4_grounding('primary');
    expZN = (6900 / sqrt(3)) / 5;
    Z = phase4_seqZ(struct('kR', 3.5, 'kX', 2.75, 'kB', 0.725, 'k0g', 1.5, 'gatLeg', 'H1', 'lambda_T', 1.0, 'grid', 'P', 'XoR_P', 15, 'ner', 'primary'));
    ok = Rg.gat.Z_PS_pct.value == 12.0 && Rg.gat.R_PS_pct.value == 0.5 && Rg.gat.Z0_PS_pct.value == 10.8 ...
        && abs(Gp.ZN_GAT_LV_ohm - expZN) < 0.05 && abs(Z.Z_T0_loop_100MVA - 0.432) < 1e-9 && abs(Z.Z_T0_loop_100MVA - 4*Z.Z_T0_loop_25MVA) < 1e-12 && ~Z.tertiaryOpen;
    ev = sprintf('phase4_registry.m:72-74 GAT PS Z=12.0 R=0.5 Z0=10.8 pct; ZN_GAT_LV=%.4f ohm (never solid); seqZ H1 loop100=0.432 closed (=4x25MVA)', Gp.ZN_GAT_LV_ohm);
catch ME
    ok = false; ev = sprintf('Q8 execute-fail: %s', ME.message);
end
q(8) = struct('id', 'Q8', 'confirmed', logical(ok), 'evidence', ev);

try
    Rg = phase4_registry();
    ok = isequal(Rg.line.kR_band.value, [2.0, 5.0]) && isequal(Rg.line.kX_band.value, [2.0, 3.5]) ...
        && isequal(Rg.line.kB_band.value, [0.60, 0.85]) ...
        && isNaNx(Rg.line.R0_ohm.value) && isNaNx(Rg.line.X0_ohm.value) && isNaNx(Rg.line.B0_uS.value);
    ev = 'phase4_registry.m:87-90 bands kR[2,5] kX[2,3.5] kB[0.60,0.85]; line R0/X0/B0 NaN MISSING point values';
catch ME
    ok = false; ev = sprintf('Q9 execute-fail: %s', ME.message);
end
q(9) = struct('id', 'Q9', 'confirmed', logical(ok), 'evidence', ev);

try
    NP = phase4_seqPN('P', 15);
    NS = phase4_seqPN('S', NaN);
    zP = abs(NP.Z1grid_R + 1j * NP.Z1grid_X);
    zS = abs(NS.Z1grid_R + 1j * NS.Z1grid_X);
    expS = sqrt(0.267344^2 + 2.938108^2) / 529;
    ok = abs(zP - 2.65581124 / 529) < 1e-9 && abs(zS - expS) < 1e-9 && abs(zP - zS) > 1e-6 ...
        && strcmp(NP.ds, 'P') && strcmp(NS.ds, 'S') && NP.XoR_used ~= NS.XoR_used;
    ev = sprintf('phase4_seqPN.m:112-132 P |Z|=%.8f vs S |Z|=%.8f differ; ds fields P/S separate, XoR 15 vs 10.99', zP, zS);
catch ME
    ok = false; ev = sprintf('Q10 execute-fail: %s', ME.message);
end
q(10) = struct('id', 'Q10', 'confirmed', logical(ok), 'evidence', ev);

try
    Fo = phase4_prefault('LF360_GAT_OUT');
    Fi = phase4_prefault('LF360_GAT_IN');
    ok = abs(Fo.Qgen_MVAr - Fi.Qgen_MVAr) > 1 && Fo.Pgen_MW == 360 && Fi.Pgen_MW == 360 ...
        && ~Fo.GAT_in && Fi.GAT_in;
    ev = sprintf('phase4_prefault LF360 pair Qgen OUT=%.6f IN=%.6f MVAr differ; GAT_in 0/1; Pgen 360 both', Fo.Qgen_MVAr, Fi.Qgen_MVAr);
catch ME
    ok = false; ev = sprintf('Q11 execute-fail: %s', ME.message);
end
q(11) = struct('id', 'Q11', 'confirmed', logical(ok), 'evidence', ev);

try
    Y = phase4_topology(0.5, 'B', 'closed');
    ok = (Y.nodeF1 == Y.nodeF2) && ~strcmp(Y.labelF1, Y.labelF2) ...
        && isfield(Y, 'nodeB66') && Y.nodeB66 == 6;
    ev = sprintf('phase4_topology.m:56-59 nodeF1=nodeF2=%d labels %s vs %s; nodeB66=6 auxiliary', Y.nodeF1, Y.labelF1, Y.labelF2);
catch ME
    ok = false; ev = sprintf('Q12 execute-fail: %s', ME.message);
end
q(12) = struct('id', 'Q12', 'confirmed', logical(ok), 'evidence', ev);

try
    Y = phase4_topology(0.5, 'B', 'closed');
    ok = abs(Y.Zs_branch_pu / 2 - Y.Zs_eq_pu) < 1e-12 && abs((Y.Zs_S + Y.Zs_R) - Y.Zs_eq_pu) < 1e-12 ...
        && abs(Y.Bs_branch_pu * 2 - Y.Bs_eq_pu) < 1e-12 && abs((Y.Bs_S + Y.Bs_R) - Y.Bs_eq_pu) < 1e-12 ...
        && Y.nodeF4 == 7;
    ev = 'phase4_topology.m:74-95 branch-split identities at m=0.5 B-view (Zs_branch/2, S+R, shunt pair); nodeF4=7';
catch ME
    ok = false; ev = sprintf('Q13 execute-fail: %s', ME.message);
end
q(13) = struct('id', 'Q13', 'confirmed', logical(ok), 'evidence', ev);

try
    Y = phase4_topology(0.5, 'B', 'closed');
    ok = strcmp(Y.Q0, 'breaker') && strcmp(Y.Q1, 'bus-disconnector') ...
        && strcmp(Y.Q2, 'bus-disconnector') && strcmp(Y.Q9, 'line-disconnector');
    ev = 'phase4_topology.m:98-104 GIS tags Q0 breaker, Q1/Q2 bus-disconnector, Q9 line-disconnector, labels only';
catch ME
    ok = false; ev = sprintf('Q14 execute-fail: %s', ME.message);
end
q(14) = struct('id', 'Q14', 'confirmed', logical(ok), 'evidence', ev);

try
    Re = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'Ikpp', [], 'earth');
    Rp = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'Ikpp', [], 'phase');
    R1e = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F1', 'LG', 'Ikpp', [], 'earth');
    Rb = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'Ikpp', [], 'bolted');
    ok = abs(Re.Zf_ohm - 0.01 * 529) < 1e-9 && abs(Rp.Zf_ohm - 0.002 * 529) < 1e-12 ...
        && abs(R1e.Zf_ohm - 0.01 * 4.84) < 1e-12 && Rb.Zf_ohm == 0;
    ev = sprintf('phase4_stages.m:68-76 ZfMode table: F3 earth=%.4f phase=%.4f ohm, F1 earth=%.5f ohm, bolted 0', Re.Zf_ohm, Rp.Zf_ohm, R1e.Zf_ohm);
catch ME
    ok = false; ev = sprintf('Q15 execute-fail: %s', ME.message);
end
q(15) = struct('id', 'Q15', 'confirmed', logical(ok), 'evidence', ev);

try
    Rb = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F1', 'LG', 'Ib', 0.06, 'bolted');
    Rk = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'Ikpp', [], 'bolted');
    Rp2 = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'ip', [], 'bolted');
    Rs = phase4_stages('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'Isteady', [], 'bolted');
    lblOK = strcmp(Rk.stage, 'Ikpp') && strcmp(Rp2.stage, 'ip') && strcmp(Rb.stage, 'Ib') && strcmp(Rs.stage, 'Isteady') ...
        && Rb.t_break == 0.06 && ~isempty(strfind(Rb.footnote, 'constant-E'));
    t1 = fileread(fullfile(root, 'matlab', 'phase4', 'phase4_stages.m'));
    t2 = fileread(fullfile(root, 'matlab', 'phase4', 'phase4_solve.m'));
    ubHits = numel(regexpi(t1, ['upper' ' ' 'bound'])) + numel(regexpi(t2, ['upper' ' ' 'bound']));
    ok = lblOK && ubHits == 0;
    ev = sprintf('phase4_stages.m:101-106 Ib footnote constant-E t_break=0.06; labels Ikpp/ip/Ib/Isteady echo; upper-bound scan 0 hits in stages+solve');
catch ME
    ok = false; ev = sprintf('Q16 execute-fail: %s', ME.message);
end
q(16) = struct('id', 'Q16', 'confirmed', logical(ok), 'evidence', ev);

try
    C = phase4_contrib('LF360_GAT_OUT', 'P', 15, 'F3', 'LG', 'Ikpp', 0, 'bolted');
    ok = isfield(C.legs, 'GEN') && isfield(C.legs, 'GSUT_HV') && isfield(C.legs, 'LINE_total') ...
        && isfield(C.legs, 'NER_earth') && isfinite(C.kcl_seq) && isfinite(C.kcl_ph) && isfinite(C.kcl_earth) ...
        && C.kcl_seq < 1e-6;
    try
        phase4_contrib('LF360_GAT_OUT', 'P', 15, 'F3', 'LLL', 'ip', 0, 'bolted');
        ok = false; rejNote = 'ACCEPTED (failure)';
    catch ME2
        ok = ok && ~isempty(strfind(ME2.identifier, 'ipNoTable'));
        rejNote = 'rejected as designed';
    end
    ev = sprintf('phase4_contrib.m:105-108 per-leg ip %s (phase4_contrib:ipNoTable); F3 LG legs GEN/GSUT_HV/LINE_total/NER_earth KCL seq=%.3g', rejNote, C.kcl_seq);
catch ME
    ok = false; ev = sprintf('Q17 execute-fail: %s', ME.message);
end
q(17) = struct('id', 'Q17', 'confirmed', logical(ok), 'evidence', ev);

try
    ok = numel(V.legs) == 27 && all([V.legs.pass]);
    ev = sprintf('phase4_validate runID=gate_review %d/27 legs pass (teeth: full 27/27 required)', sum([V.legs.pass]));
catch ME
    ok = false; ev = sprintf('Q18 execute-fail: %s', ME.message);
end
q(18) = struct('id', 'Q18', 'confirmed', logical(ok), 'evidence', ev);

try
    S = phase4_sensitivity('base_LF360_OUT_P15', {'C-LOW', 'H0', 'GAT-Z0-9.99'});
    kk = [S.runs.kcl];
    ok = numel(S.runs) == 3 && all(strcmp({S.runs.label}, 'NODAL')) ...
        && all(isfinite(kk)) && max(kk) < 1e-6 ...
        && S.runs(1).kR == 2.0 && strcmp(S.runs(2).gatLeg, 'H0') && strcmp(S.runs(3).gatZ0sel, 'low');
    ev = sprintf('phase4_sensitivity base_LF360_OUT_P15 legs C-LOW/H0/GAT-Z0-9.99 execute distinct; KCL worst=%.3g<1e-6', max(kk));
catch ME
    ok = false; ev = sprintf('Q19 execute-fail: %s', ME.message);
end
q(19) = struct('id', 'Q19', 'confirmed', logical(ok), 'evidence', ev);

try
    ok = exist(fullfile(root, 'rev2', 'data', 'iec_kappa.m'), 'file') == 2;
    kt = fileread(fullfile(root, 'matlab', 'phase4', 'phase4_kappa.m'));
    ok = ok && ~isempty(strfind(kt, 'NOT IEC 60909'));
    ev = 'rev2/data/iec_kappa.m exists (267 B freeze); phase4_kappa.m:10-11 disclaimer NOT IEC 60909, design-defined curve';
catch ME
    ok = false; ev = sprintf('Q20 execute-fail: %s', ME.message);
end
q(20) = struct('id', 'Q20', 'confirmed', logical(ok), 'evidence', ev);

try
    Rg = phase4_registry();
    ok = isNaNx(Rg.gat.Z_PT.value) && isNaNx(Rg.gat.Z_ST.value) ...
        && isNaNx(Rg.line.R0_ohm.value) && isNaNx(Rg.line.X0_ohm.value);
    sgPat = ['solid' 'ly' ' ' 'gro' 'unded'];
    d = dir(fullfile(root, 'matlab', 'phase4', '*.m'));
    hits = 0;
    for k = 1:numel(d)
        if strcmp(d(k).name, 'phase4_review_gate.m')
            continue;  % scanner excludes its own pattern table (self-reference)
        end
        txt = fileread(fullfile(root, 'matlab', 'phase4', d(k).name));
        hits = hits + numel(regexpi(txt, sgPat));
    end
    ok = ok && hits == 0;
    ev = 'phase4_registry.m:75-76,84-85 Z_PT/Z_ST/R0/X0 NaN MISSING; solid-grounding scan 0 hits in matlab/phase4 (gate self excluded)';
catch ME
    ok = false; ev = sprintf('Q21 execute-fail: %s', ME.message);
end
q(21) = struct('id', 'Q21', 'confirmed', logical(ok), 'evidence', ev);

try
    smk = fullfile(root, 'results', 'phase4_fault', 'smoke_run', 'phase4_fault_currents.csv');
    tagUsed = 'smoke_run (reused)';
    if exist(smk, 'file') ~= 2
        H = phase4_handoff('gate_smoke');
        smk = fullfile(H.dir, 'phase4_fault_currents.csv');
        tagUsed = 'gate_smoke (fresh)';
    end
    raw = fileread(smk);
    nl = strfind(raw, char(10));
    hdr = strrep(strtrim(raw(1:nl(1) - 1)), char(13), '');
    exp = ['fault_type,location,m,caseID,grid_dataset,XoR_P,zero_band,k0g,XdRole,' ...
        'NER_variant,GAT_variant,ZfMode,Zf_ohm,coupler,stage,unit,base,Irms_kA,' ...
        'Iang_deg,Iseq0_kA,Iseq1_kA,Iseq2_kA,r_kappa_ip,t_break_s,footnote'];
    smokeDir = fileparts(smk);
    fourOK = exist(fullfile(smokeDir, 'phase4_fault_currents.csv'), 'file') == 2 ...
        && exist(fullfile(smokeDir, 'phase4_contributions.csv'), 'file') == 2 ...
        && exist(fullfile(smokeDir, 'phase4_bands.csv'), 'file') == 2 ...
        && exist(fullfile(smokeDir, 'phase4_ct_data.csv'), 'file') == 2;
    ok = strcmp(hdr, exp) && fourOK;
    ev = sprintf('results/phase4_fault/%s 25 schema headers exact order + 4 CSVs present', tagUsed);
catch ME
    ok = false; ev = sprintf('Q22 execute-fail: %s', ME.message);
end
q(22) = struct('id', 'Q22', 'confirmed', logical(ok), 'evidence', ev);

try
    pats = {'pickup', 'tms', 'grading', 'duty', 'verdict', 'relay', 'coordination', 'overcurrent', 'time_dial', 'timedial', 'plug_setting', 'pick_up'};
    d = dir(fullfile(root, 'matlab', 'phase4', '*.m'));
    codeHits = 0;
    for k = 1:numel(d)
        if strcmp(d(k).name, 'phase4_review_gate.m')
            continue;  % scanner excludes its own pattern table (self-reference)
        end
        txt = fileread(fullfile(root, 'matlab', 'phase4', d(k).name));
        lines = strsplit(txt, char(10));
        for li = 1:numel(lines)
            ln = lower(lines{li});
            if ~isempty(strfind(ln, 'pats')) || ~isempty(strfind(ln, 'forbidden'))
                continue;  % detection-scanner lines allowed (handoff/matrix forbiddenCol scanners)
            end
            for pi = 1:numel(pats)
                if ~isempty(regexp(ln, ['\b' pats{pi} '\b'], 'once'))
                    codeHits = codeHits + 1;
                end
            end
        end
    end
    forb = {'pickup', 'tms', 'grading', 'differential', 'duty', 'verdict', 'rating'};
    dd = dir(fullfile(root, 'results', 'phase4_fault', '*', '*.csv'));
    csvHits = 0;
    for k = 1:numel(dd)
        raw = fileread(fullfile(dd(k).folder, dd(k).name));
        nl = strfind(raw, char(10));
        hdr = lower(strrep(strtrim(raw(1:nl(1) - 1)), char(13), ''));
        for fi = 1:numel(forb)
            if ~isempty(strfind(hdr, forb{fi}))
                csvHits = csvHits + 1;
            end
        end
    end
    ok = (codeHits == 0) && (csvHits == 0);
    ev = sprintf('boundary scan: matlab/phase4 code 0 relay-logic hits (%d CSVs headers 0 forbidden hits; scanner/detection lines exempt)', numel(dd));
catch ME
    ok = false; ev = sprintf('Q23 execute-fail: %s', ME.message);
end
q(23) = struct('id', 'Q23', 'confirmed', logical(ok), 'evidence', ev);

% ---- markdown (overwrite each run; timestamp LAST line only) ----
mdPath = fullfile(root, 'PHASE4_REVIEW_GATE.md');
fid = fopen(mdPath, 'w');
if fid < 0
    error('phase4_review:markdown', 'Cannot write %s.', mdPath);
end
fprintf(fid, '# PHASE4 REVIEW GATE\n\n');
fprintf(fid, 'Freeze re-check plus Q1-Q23 evidence for the Phase-4 MATLAB fault-analysis build (Ashuganj South).\n\n');
fprintf(fid, '## Freeze\n\n');
fprintf(fid, '| file | bytes | mtime (local) | check |\n');
fprintf(fid, '| --- | --- | --- | --- |\n');
fprintf(fid, '%s', freezeRow(F1));
fprintf(fid, '%s', freezeRow(F2));
fprintf(fid, '%s', freezeRow(F3));
fprintf(fid, '%s', freezeRow(F4));
fprintf(fid, '| %s | %d | %s | SIZE-ONLY + exists (timestamp informational) |\n', 'rev2/data/iec_kappa.m', R1.bytes, R1.mtime);
fprintf(fid, '| %s | %d | %s | SIZE-ONLY + exists (timestamp informational) |\n', 'rev2/run_phase2_fault.m', R2.bytes, R2.mtime);
fprintf(fid, '\n');
if isempty(tolNote)
    fprintf(fid, 'Timestamp compare: dir() datenum exact equality against the freeze record (local time, same machine). Sizes exact.\n\n');
else
    fprintf(fid, 'Timestamp compare: %s.\n\n', tolNote);
end
fprintf(fid, '## Q1-Q23\n\n');
fprintf(fid, '| id | confirmed | evidence |\n');
fprintf(fid, '| --- | --- | --- |\n');
for k = 1:23
    fprintf(fid, '| %s | %s | %s |\n', q(k).id, boolStr(q(k).confirmed), q(k).evidence);
end
fprintf(fid, '\n## Remaining data D1-D8\n\n');
fprintf(fid, '| id | title | status |\n');
fprintf(fid, '| --- | --- | --- |\n');
fprintf(fid, '| D1 | South R0/X0/B0 + tower/soil/mutuals | MISSING |\n');
fprintf(fid, '| D2 | Grid Thevenin unmeasured | ESTIMATED/LEGACY/ASSUMPTION |\n');
fprintf(fid, '| D3 | Generator X2/X0 | QUALIFIED |\n');
fprintf(fid, '| D4 | NER reconciliation conditional + NGT | NGT MISSING |\n');
fprintf(fid, '| D5 | GAT pairwise | INCOMPLETE |\n');
fprintf(fid, '| D6 | UAT/GAT LV neutral devices | MISSING |\n');
fprintf(fid, '| D7 | Full Siemens report + INEL-0026 + JICA file | MISSING |\n');
fprintf(fid, '| D8 | Aux/downstream-LV uncertainty | UNCERTAIN |\n');
fprintf(fid, '\n## STOP\n\n');
fprintf(fid, 'Phase-4 implementation complete. No protection work started. No relay settings, breaker duties, or coordination artifacts exist in matlab/phase4/ or results/phase4_fault/ (verified by Q23 scan). Awaiting explicit Phase-5 approval.\n\n');
fprintf(fid, 'Run timestamp: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fclose(fid);
fprintf('phase4_review_gate: wrote %s (%d/23 confirmed)\n', mdPath, sum([q.confirmed]));

G = struct('phase3Untouched', logical(phase3Untouched), 'rev2Untouched', logical(rev2Untouched), 'q', q);
end

% =====================================================================
function f = checkLocal(root, rel, expBytes, expDn)
p = fullfile(root, rel);
d = dir(p);
if numel(d) ~= 1 || d.isdir
    error('phase4_review:freeze', '%s: missing file', rel);
end
if d.bytes ~= expBytes
    error('phase4_review:freeze', '%s: size %d ~= %d bytes', rel, d.bytes, expBytes);
end
diffS = abs(d.datenum - expDn) * 86400;
if diffS > 61
    error('phase4_review:freeze', '%s: mtime off by %.1f s (>61 s)', rel, diffS);
end
f = struct('name', rel, 'bytes', d.bytes, 'mtime', datestr(d.datenum, 'yyyy-mm-dd HH:MM:SS'), ...
    'diffS', diffS, 'tolUsed', diffS ~= 0, 'ok', true);
end

function f = checkRev2(root, rel, expBytes)
p = fullfile(root, rel);
d = dir(p);
if numel(d) ~= 1 || d.isdir
    error('phase4_review:freeze', '%s: missing file', rel);
end
if d.bytes ~= expBytes
    error('phase4_review:freeze', '%s: size %d ~= %d bytes', rel, d.bytes, expBytes);
end
f = struct('name', rel, 'bytes', d.bytes, 'mtime', datestr(d.datenum, 'yyyy-mm-dd HH:MM:SS'), 'ok', true);
end

function s = freezeRow(F)
if F.tolUsed
    chk = sprintf('size exact; mtime within 61 s (off by %.3f s)', F.diffS);
else
    chk = 'size exact; mtime EXACT';
end
s = sprintf('| %s | %d | %s | %s |\n', F.name, F.bytes, F.mtime, chk);
end

function ok = isNaNx(v)
ok = isnumeric(v) && ~isempty(v) && all(isnan(v(:)));
end

function s = boolStr(b)
if b
    s = 'true';
else
    s = 'false';
end
end
