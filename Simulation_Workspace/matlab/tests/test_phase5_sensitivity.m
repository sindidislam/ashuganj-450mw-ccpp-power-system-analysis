function [np, nf] = test_phase5_sensitivity()
%TEST_PHASE5_SENSITIVITY  Phase-5 Task 14 fenced CT sensitivity tests (TDD).
%   Locks interface S = phase5_sensitivity(T40, devices):
%   recomputes GEN-zone relay-currents + operating times + coordination
%   margins under LEGACY-16000/1 (2000/1 STUDY CTs untouched), returning a
%   NEW table with scope='SENSITIVITY' on every row (primary outputs never
%   overwritten: inputs verified unmodified, no output calls, no shared
%   workspace state). Uses phase5_ct_table(T,16000,'LEGACY-16000/1') +
%   phase5_time + phase5_pickup (delegated, never reimplemented).
%   Relay dial held fixed at the PRIMARY-CT secondary pickup, so the 16k
%   secondary drop reads honestly slower-or-unchanged (never faster).
%   All errors phase5-prefixed.
T = t_case('test_phase5_sensitivity');
root = ashuganj_root();
Ti = phase5_import(root);
T = T.chk(height(Ti) == 40, 'T40 backbone 40 rows (2x5x4 Ikpp)');
R = phase5_registry();
devices = R.devices;
Ti_before = Ti;
dev_before = devices;

S = phase5_sensitivity(Ti, devices);

% --- New table, GEN-zone rows: 40 GEN-51 + 20 GEN-51N earth (LG/LLG) = 60 ---
T = T.chk(istable(S), 'S is a table (new outputs, never merged into primary)');
n51 = sum(strcmp(S.device_id, 'GEN-51'));
n51N = sum(strcmp(S.device_id, 'GEN-51N'));
T = T.chk(n51 == 40, 'GEN-51 covers all 40 combos (2000/1 STUDY CTs untouched elsewhere)');
T = T.chk(n51N == 20, 'GEN-51N covers LG/LLG earth combos only (20 rows)');
T = T.chk(height(S) == 60, 'S has 60 GEN-zone sensitivity rows');

% --- Locked columns present ---
need = {'fault_location', 'fault_type', 'caseID', 'device_id', 'I_primary_A', ...
    'I_sec_primary_A', 'I_sec_sens_A', 'ct_primary', 'ct_legacy', 'ct_tag', ...
    'pickup_primary_A', 't_primary_s', 't_sens_s', 'dt_s', 'direction', ...
    'margin_primary_s', 'margin_sens_s', 'dmargin_s', 'margin_direction', ...
    'verdict_primary', 'verdict_sens', 'scope', 'provenance', 'reason'};
has = S.Properties.VariableNames;
for k = 1:numel(need)
    T = T.chk(any(strcmp(has, need{k})), ['S carries column ' need{k}]);
end

% --- Fenced scope + LEGACY provenance on EVERY row ---
T = T.chk(all(strcmp(S.scope, 'SENSITIVITY')), 'every row scope SENSITIVITY');
T = T.chk(all(strcmp(S.ct_tag, 'LEGACY-16000/1')), 'every row ct_tag LEGACY-16000/1');
T = T.chk(all(~cellfun(@isempty, strfind(S.provenance, 'LEGACY'))), ...
    'every row provenance LEGACY-tagged CT source');
T = T.chk(all(S.ct_primary == 15000) && all(S.ct_legacy == 16000), ...
    'ct_primary 15000 / ct_legacy 16000 stamped per row');

% --- Purity: PRIMARY-scope inputs unmodified (new table out, nothing merged) ---
% NOTE: isequaln (not isequal) because this harness treats NaN payloads as
% unequal under isequal while isequaln regards NaN==NaN (import leg columns
% carry genuine NaN gaps, e.g. leg_GAT_HV_kA F1/F2; verified pre-call).
T = T.chk(isequaln(Ti, Ti_before), 'pure: T40 input table unmodified (no PRIMARY data touched)');
T = T.chk(isequaln(devices, dev_before), 'pure: devices input unmodified');
T = T.chk(~any(strcmp(Ti.Properties.VariableNames, 'scope')), ...
    'pure: T40 carries no scope column (separate sensitivity table)');

% --- CT ratio: 16k secondary == 15k x 15/16 within 1e-12 ---
fin = isfinite(S.I_sec_primary_A) & isfinite(S.I_sec_sens_A);
T = T.chk(any(fin), 'finite secondary rows present for ratio check');
T = T.chk(all(abs(S.I_sec_sens_A(fin) - S.I_sec_primary_A(fin) * 15 / 16) < 1e-12), ...
    '16k secondary == 15k x 15/16 within 1e-12');
Tleg = phase5_ct_table(Ti, 16000, 'LEGACY-16000/1');
T = T.chk(all(abs(Tleg.I_secondary_A - Ti.I_primary_A / 16000) < 1e-15), ...
    'contract audit: phase5_ct_table legacy secondary == primary/16000');

% --- Branch parity with coordination (controller-verified F1 numbers) ---
rLG = S(strcmp(S.fault_location, 'F1') & strcmp(S.fault_type, 'LG') ...
    & strcmp(S.caseID, 'LF360_GAT_OUT') & strcmp(S.device_id, 'GEN-51'), :);
T = T.chk(height(rLG) == 1, 'F1 LG OUT GEN-51 sensitivity row present');
T = T.chk(abs(rLG.I_primary_A - 8414.11669538933) < 1e-6, ...
    'F1 LG GEN-51 relay primary ~= 8414.1 A branch (not 7.27 A net total)');
rE = S(strcmp(S.fault_location, 'F1') & strcmp(S.fault_type, 'LG') ...
    & strcmp(S.caseID, 'LF360_GAT_OUT') & strcmp(S.device_id, 'GEN-51N'), :);
T = T.chk(height(rE) == 1, 'F1 LG OUT GEN-51N sensitivity row present');
T = T.chk(abs(rE.I_primary_A - 7.27200442799167) < 1e-9, ...
    'F1 LG GEN-51N relay primary == 7.272 A 3I0 fault total (neutral once)');

% --- Margin deltas vs primary reported, slower/faster direction honest ---
finM = isfinite(S.margin_primary_s) & isfinite(S.margin_sens_s);
T = T.chk(all(abs(S.dmargin_s(finM) - (S.margin_sens_s(finM) - S.margin_primary_s(finM))) < 1e-9), ...
    'dmargin == margin_sens - margin_primary where computable');
T = T.chk(all(isnan(S.dmargin_s(~(isfinite(S.margin_primary_s) & isfinite(S.margin_sens_s))))), ...
    'dmargin NaN where any margin side not computable (never invented)');
bothT = isfinite(S.t_primary_s) & isfinite(S.t_sens_s);
T = T.chk(all(S.t_sens_s(bothT) >= S.t_primary_s(bothT) - 1e-9), ...
    'honest direction: 16k with fixed dial never faster (slower-or-unchanged)');
T = T.chk(~any(strcmp(S.direction, 'faster')), 'no faster rows under 16k (fixed dial)');
T = T.chk(all(ismember(S.direction, {'slower', 'unchanged', 'unchanged-no-trip', ...
    'slower-no-trip', 'NOT-DETERMINABLE'})), 'direction domain closed');
T = T.chk(all(ismember(S.margin_direction, {'tighter', 'unchanged', 'wider', 'N/A'})), ...
    'margin_direction domain closed (tighter/unchanged/wider/N/A)');
vd = [S.verdict_primary; S.verdict_sens];
T = T.chk(all(ismember(vd, {'PASS', 'FAIL', 'NO-TRIP', 'NO-PAIR', ...
    'NOT DETERMINABLE FROM AVAILABLE DATA'})), 'verdict domain closed (never tuned)');

% --- Static purity: no output calls, no shared workspace state in source ---
src = fileread(fullfile(ashuganj_root(), 'matlab', 'phase5', 'phase5_sensitivity.m'));
T = T.chk(isempty(strfind(src, 'writetable')), 'pure: source has no writetable call');
T = T.chk(isempty(strfind(src, 'writecell')), 'pure: source has no writecell call');
T = T.chk(isempty(strfind(src, 'fopen')), 'pure: source has no fopen call');
T = T.chk(isempty(strfind(src, 'global')), 'pure: source uses no shared workspace state');
T = T.chk(isempty(strfind(src, 'persistent')), 'pure: source uses no persistent state');

% --- Errors phase5-prefixed ---
try, phase5_sensitivity([], devices); T = T.chk(false, 'empty T40 errors'); ...
catch ME, T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'empty T40 errors phase5-prefixed'); end
try, phase5_sensitivity(Ti, []); T = T.chk(false, 'empty devices errors'); ...
catch ME, T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'empty devices errors phase5-prefixed'); end
try, phase5_sensitivity(Ti, devices(1)); T = T.chk(false, 'missing GEN-51N errors'); ...
catch ME, T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'missing GEN-51N errors phase5-prefixed'); end

nP = sum(strcmp(S.verdict_sens, 'PASS')); nF = sum(strcmp(S.verdict_sens, 'FAIL'));
nNT = sum(strcmp(S.verdict_sens, 'NO-TRIP')); nNP = sum(strcmp(S.verdict_sens, 'NO-PAIR'));
nND = sum(strcmp(S.verdict_sens, 'NOT DETERMINABLE FROM AVAILABLE DATA'));
fprintf(['  INFO  sens verdicts: PASS=%d FAIL=%d NO-TRIP=%d NO-PAIR=%d NOT-DETERMINABLE=%d' ...
    ' (deltas honest, never tuned)\n'], nP, nF, nNT, nNP, nND);
T = T.chk(nP + nF + nNT + nNP + nND == height(S), 'verdict counts cover all rows');

[np, nf] = T.done();
end
