function [np, nf] = test_phase5b_mindetect()
%TEST_PHASE5B_MINDETECT  Phase-5b Task C6 per-CT min-detect (replaces V9 totals logic).
%   Locked interface under test: M = phase5b_mindetect(T40, devices) returns
%   one struct row per (device, element in phase/residual/negseq) with the
%   minimum BRANCH current over zone-relevant faults, the C4 pickup, the
%   margin (min/pickup) and a verdict (DETECT / BLIND-SPOT-HONEST /
%   NOT-DETERMINABLE). Fault totals never proxy relay current: the module
%   reads leg_* branch columns only (C5-pinned branch-through-current
%   semantics); this test scans the module source for the banned total
%   literal and for I_primary references (both must be absent).
%
%   Zone relevance (locked): GEN devices <- F1/F2 (GEN_Q leg / 3I0 from NER
%   series leg / negseq branch NOT DETERMINABLE); GSUT-HV <- F1/F2/F3
%   (GSUT_HV leg); GIS-Q0 <- F3/F4/F5 (LINE_Q9 through-convention magnitude
%   = |leg_LINE_total_kA| for non-F4 rows; F4 nuance noted in module).
%
%   Stored production legs are |Ia| only (phase4_handoff legRow). For the
%   phase element only LLL (symmetric) + LG (A-phase faulted, B/C ~ 0 per
%   phase4 LG_branch0 diagnostic) rows enter the min: on LL/LLG rows the
%   stored |Ia| is the UNFAULTED-phase current and understates what B/C
%   phase elements see, so LL/LLG phase coverage is NOT-DETERMINABLE
%   (counted, never silently dropped). Residual scope is the LG
%   sensitivity-defining fault (C4 51N basis must-detect-F1-LG); LLG
%   residual is observed-but-out-of-scope and reported as a concern.
%   Negseq branch I2 is unavailable in T40/production CSVs (fault-point
%   Iseq2 is a total and is never derived per branch-current doctrine).
%
%   Reference configuration: backbone OUT case (LF360_GAT_OUT), consistent
%   with the C5-pinned audit row. A robustness re-run on the full T40
%   (both GAT cases) asserts identical verdicts with minima inside 1%%.
%
%   TDD RED note: first run failed with undefined function
%   phase5b_mindetect as required; GREEN after module creation.
T = t_case('test_phase5b_mindetect');
root = ashuganj_root();

% --- T40 backbone import (read-only) + OUT reference scope ---
T40full = phase5_import(root);
T = T.chk(height(T40full) == 40, 'T40 backbone has 40 rows (2x5x4)');
T40 = T40full(strcmp(T40full.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(height(T40) == 20, 'OUT reference T40 has 20 rows (1x5x4)');

% --- Devices: live v2 registry + C4 -SI alias rows ---
R = phase5b_registry();
devs = R.devices;
g = devs(strcmp({devs.device_id}, 'GEN-51')); g.device_id = 'GEN-51-SI';
e = devs(strcmp({devs.device_id}, 'GEN-51N')); e.device_id = 'GEN-51N-SI-STUDY';
devs = [devs, g, e];

M = phase5b_mindetect(T40, devs);

% --- Locked schema ---
T = T.chk(isstruct(M), 'M is struct array');
want = {'device_id', 'element', 'zone_locs', 'branch_tag', 'n_zone', ...
    'n_used', 'min_branch_A', 'min_loc', 'min_type', 'min_case', ...
    'pickup_A', 'pickup_src', 'margin', 'verdict', 'determinable', 'reason'};
T = T.chk(all(isfield(M, want)), 'locked interface fields present');
T = T.chk(numel(M) == numel(devs) * 3, 'one row per (device, element)');
T = T.chk(all(ismember({M.element}, {'phase', 'residual', 'negseq'})), ...
    'element vocabulary phase/residual/negseq');
T = T.chk(all(ismember({M.verdict}, {'DETECT', 'BLIND-SPOT-HONEST', ...
    'NOT-DETERMINABLE'})), 'verdict vocabulary locked');

% --- GEN-51-SI phase: blindness reproduced numerically ---
r = pick(M, 'GEN-51-SI', 'phase');
T = T.chk(~isempty(r), 'GEN-51-SI phase row present');
T = T.chk(r.determinable, 'GEN-51-SI phase determinable');
T = T.chk(abs(r.min_branch_A - 8414.11669538933) < 0.01, ...
    'GEN-51-SI min-branch F1 LG 8414.12 A');
T = T.chk(strcmp(r.min_type, 'LG'), 'GEN phase min on LG type');
T = T.chk(ismember(r.min_loc, {'F1', 'F2'}), 'GEN phase min in GEN zone F1/F2');
T = T.chk(strcmp(r.min_case, 'LF360_GAT_OUT'), 'GEN phase min on OUT reference case');
T = T.chk(abs(r.pickup_A - 17170.8) / 17170.8 < 1e-9, ...
    'GEN-51-SI pickup 17170.8 A (C4 rule 1.20x14309)');
T = T.chk(r.margin < 1, 'GEN-51-SI margin < 1 (blind)');
T = T.chk(abs(r.margin - 8414.11669538933 / 17170.8) < 1e-9, ...
    'GEN-51-SI margin 0.4900 vs pickup');
T = T.chk(strcmp(r.verdict, 'BLIND-SPOT-HONEST'), ...
    'GEN-51-SI verdict BLIND-SPOT-HONEST (non-PASS)');
T = T.chk(r.n_zone == 8 && r.n_used == 4, ...
    'GEN phase scope locked: 8 zone rows, 4 used (LLL+LG; LL/LLG excluded as unfaulted-phase Ia)');
g0 = pick(M, 'GEN-51', 'phase');
T = T.chk(abs(g0.min_branch_A - r.min_branch_A) / r.min_branch_A < 1e-12, ...
    'GEN-51 alias agrees with GEN-51-SI');

% --- GEN-51N-SI-STUDY residual: sensitive earth-fault detection ---
s = pick(M, 'GEN-51N-SI-STUDY', 'residual');
T = T.chk(~isempty(s), 'GEN-51N-SI-STUDY residual row present');
T = T.chk(s.determinable, 'GEN residual determinable (3I0 from NER series leg)');
T = T.chk(abs(s.min_branch_A - 7.27200442799157) < 1e-3, ...
    'GEN-51N-SI min 7.272 A (3x NER branch)');
T = T.chk(abs(s.pickup_A - 4) < 1e-12, 'GEN-51N PRIMARY pickup 4 A via 20/1');
T = T.chk(abs(s.margin - 7.27200442799157 / 4) < 1e-6, ...
    'GEN-51N-SI margin 1.818 (detects)');
T = T.chk(strcmp(s.verdict, 'DETECT'), 'GEN-51N-SI verdict DETECT');
s0 = pick(M, 'GEN-51N', 'residual');
T = T.chk(strcmp(s0.verdict, 'DETECT') && abs(s0.margin - s.margin) < 1e-12, ...
    'GEN-51N alias agrees with GEN-51N-SI-STUDY');

% --- Negseq: honestly NOT DETERMINABLE (branch I2 unavailable) ---
n1 = pick(M, 'GEN-51-SI', 'negseq');
T = T.chk(~isempty(n1) && ~n1.determinable, 'GEN negseq not determinable');
T = T.chk(strcmp(n1.verdict, 'NOT-DETERMINABLE'), 'GEN negseq verdict NOT-DETERMINABLE');
T = T.chk(isnan(n1.min_branch_A) && isnan(n1.margin), ...
    'GEN negseq min/margin stay NaN (never derived from fault-point Iseq2)');
T = T.chk(~isempty(strfind(n1.reason, 'I2')), 'GEN negseq reason cites branch I2');
n2 = pick(M, 'GSUT-HV-51', 'negseq');
T = T.chk(~n2.determinable && strcmp(n2.verdict, 'NOT-DETERMINABLE'), ...
    'GSUT negseq NOT-DETERMINABLE');
n3 = pick(M, 'GIS-Q0-51', 'negseq');
T = T.chk(~n3.determinable && strcmp(n3.verdict, 'NOT-DETERMINABLE'), ...
    'GIS negseq NOT-DETERMINABLE');

% --- GSUT-HV-51 phase: F1/F2/F3 zone, detects ---
h = pick(M, 'GSUT-HV-51', 'phase');
T = T.chk(h.determinable && strcmp(h.verdict, 'DETECT'), 'GSUT-HV-51 phase DETECT');
T = T.chk(abs(h.min_branch_A - 3218.40382095249) < 0.05, ...
    'GSUT-HV-51 min-branch F3 LLL 3218.40 A');
T = T.chk(abs(h.pickup_A - 1380) / 1380 < 1e-9, 'GSUT-HV-51 pickup 1380 A (C4)');
T = T.chk(h.margin > 1, 'GSUT-HV-51 margin > 1');
T = T.chk(h.n_zone == 12 && h.n_used == 6, ...
    'GSUT phase scope locked: 12 zone rows (F1/F2/F3 x4), 6 used (LLL+LG)');

% --- GIS-Q0-51 phase: F3/F4/F5 zone, detects ---
q = pick(M, 'GIS-Q0-51', 'phase');
T = T.chk(q.determinable && strcmp(q.verdict, 'DETECT'), 'GIS-Q0-51 phase DETECT');
T = T.chk(abs(q.min_branch_A - 3207.56204219366) < 0.05, ...
    'GIS-Q0-51 min-branch F5 LLL 3207.56 A');
T = T.chk(abs(q.pickup_A - 1500) / 1500 < 1e-12, ...
    'GIS-Q0-51 pickup 1500 A CONDITIONAL provisional (C4)');
T = T.chk(q.margin > 1, 'GIS-Q0-51 margin > 1');

% --- Totals ban: detection logic never touches fault totals ---
src = fileread(which('phase5b_mindetect'));
T = T.chk(isempty(strfind(src, '43758')), 'totals ban: banned total literal absent from module source');
T = T.chk(isempty(strfind(src, 'I_primary')), 'totals ban: I_primary never referenced in module');
T = T.chk(isempty(strfind(src, 'Irms_kA')), 'totals ban: Irms_kA never referenced in module');
T40no = T40;
T40no.I_primary_kA = []; T40no.I_primary_A = [];
M2 = phase5b_mindetect(T40no, devs);
T = T.chk(isequaln(M, M2), 'detection identical with totals columns removed (branch-only proof)');

% --- Robustness: full T40 (both GAT cases) keeps every verdict ---
Mf = phase5b_mindetect(T40full, devs);
rf = pick(Mf, 'GEN-51-SI', 'phase');
T = T.chk(strcmp(rf.verdict, 'BLIND-SPOT-HONEST'), ...
    'full-T40 GEN-51-SI verdict still BLIND-SPOT-HONEST');
T = T.chk(abs(rf.min_branch_A - r.min_branch_A) / r.min_branch_A < 0.01, ...
    'full-T40 GEN phase min inside 1% of OUT reference');
sf = pick(Mf, 'GEN-51N-SI-STUDY', 'residual');
T = T.chk(strcmp(sf.verdict, 'DETECT'), 'full-T40 GEN-51N-SI verdict still DETECT');
T = T.chk(abs(sf.min_branch_A - s.min_branch_A) / s.min_branch_A < 0.01, ...
    'full-T40 GEN residual min inside 1% of OUT reference');
hf = pick(Mf, 'GSUT-HV-51', 'phase');
T = T.chk(strcmp(hf.verdict, 'DETECT'), 'full-T40 GSUT verdict still DETECT');
qf = pick(Mf, 'GIS-Q0-51', 'phase');
T = T.chk(strcmp(qf.verdict, 'DETECT'), 'full-T40 GIS verdict still DETECT');

% --- Errors phase5b-prefixed ---
try
    phase5b_mindetect();
    T = T.chk(false, 'no-args errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5b', 7), 'no-args error phase5b-prefixed');
end
try
    phase5b_mindetect(table(), devs);
    T = T.chk(false, 'empty table errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5b', 7), 'schema error phase5b-prefixed');
end
try
    phase5b_mindetect(T40, 'not-a-struct');
    T = T.chk(false, 'bad devices errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5b', 7), 'devices error phase5b-prefixed');
end

[np, nf] = T.done();
end

function r = pick(M, id, el)
%PICK  Scalar struct row for (device, element); empty struct when absent.
hit = strcmp({M.device_id}, id) & strcmp({M.element}, el);
if sum(hit) == 1
    r = M(hit);
else
    r = [];
end
end
