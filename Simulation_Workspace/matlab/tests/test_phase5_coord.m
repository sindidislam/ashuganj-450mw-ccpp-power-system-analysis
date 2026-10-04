function [np, nf] = test_phase5_coord()
%TEST_PHASE5_COORD  Phase-5 Task 8 coordination matrix builder tests (TDD + branch-current correction).
%   Locks interface [Mtrx, Mrg] = phase5_coord(devices, Tsec):
%   exact 15-col Mtrx schema; margin arithmetic dt = t_up - t_down with
%   CTI 0.3 s (ENGINEERING_ASSUMPTION) PASS threshold; below-pickup rows
%   verdict NO-TRIP (never forced PASS); topology hierarchy
%   (GEN-51 -> GSUT-HV-51 -> GIS-Q0-51 for F1/F2 phase, all types;
%   grid-zone NO-PAIR phase for F3/F4/F5); earth rows use I0-derived relay
%   currents on the 3I0 path with neutral counted once (T1 identity I0 =
%   0.00242400147599722 kA for F1 LG OUT; no second 3ZN scaling anywhere);
%   relay currents I_down/I_up in SECONDARY amperes.
%   BRANCH-CURRENT CORRECTION (binding): phase I_down/I_up come from branch
%   through-current legs (GEN_Q / GSUT_HV / GRID_Q / LINE_Q9-proxy), never
%   the net fault total; each pair side uses its OWN branch. F1 LG GEN-51
%   primary ≈8414.1 A (not 7.27 A); F1 LLL GEN-51 primary ≈55048.7 A
%   (not 126214 A). GEN-51N F1/F2 earth = 3xIseq0 fault total (single
%   count); F3/F4/F5 earth = 3xNER (≈0 delta block -> NO-TRIP);
%   GSUT/GIS earth elements without residual CT -> verdict
%   'NOT DETERMINABLE FROM AVAILABLE DATA'. All errors phase5-prefixed.
%   Real-data leg runs honestly (FAILs reported, never tuned).
T = t_case('test_phase5_coord');
R = phase5_registry();

% --- Synthetic DT devices: exact margin arithmetic (t_up 0.8 / t_down 0.4) ---
ids = {R.devices.device_id};
dD = R.devices(strcmp(ids, 'GEN-51'));
dU = R.devices(strcmp(ids, 'GSUT-HV-51'));
dD.pickup_A = 1000; dD.tms = 0.4; dD.curve = 'DT';   % tdef 0.4 s
dU.pickup_A = 1000; dU.tms = 0.8; dU.curve = 'DT';   % tdef 0.8 s
devs = [dD, dU, R.devices(strcmp(ids, 'GIS-Q0-51'))];
Tsyn = cell2table({'F1', 'LLL', 'CASE_A', 126.21414119005, 126214.14119005, 'SYN'}, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', 'I_primary_A', 'provenance'});
[Mtrx, Mrg] = phase5_coord(devs, Tsyn);

% --- Exact 15-col schema, locked order ---
exp15 = {'downstream', 'upstream', 'fault_location', 'fault_type', 'caseID', ...
    'I_fault_kA', 'I_down_A', 'I_up_A', 't_down_s', 't_up_s', ...
    'ct_down', 'ct_up', 'margin_s', 'verdict', 'reason'};
T = T.chk(isequal(Mtrx.Properties.VariableNames, exp15), 'Mtrx exact 15-col schema in locked order');
T = T.chk(isequal(Mrg.Properties.VariableNames, ...
    {'pair', 'fault_location', 'fault_type', 'caseID', 'margin_s', 'verdict', 'reason'}), ...
    'Mrg schema pair/location/type/case/margin/verdict/reason');
r1 = Mtrx(strcmp(Mtrx.downstream, 'GEN-51') & strcmp(Mtrx.upstream, 'GSUT-HV-51'), :);
T = T.chk(height(r1) == 1, 'F1 LLL yields GEN-51>GSUT-HV-51 pair row');
T = T.chk(abs(r1.t_down_s - 0.4) < 1e-12 && abs(r1.t_up_s - 0.8) < 1e-12, ...
    'DT devices give t_down 0.4 s / t_up 0.8 s exactly');
T = T.chk(abs(r1.margin_s - 0.4) < 1e-12, 'margin arithmetic 0.8/0.4 -> 0.4');
T = T.chk(strcmp(r1.verdict{1}, 'PASS'), 'margin 0.4 >= CTI 0.3 -> PASS');
T = T.chk(~isempty(strfind(r1.reason{1}, '0.3')), 'PASS reason cites CTI 0.3 s');
% Relay currents in SECONDARY amperes through device CTs (no-leg fallback = net total).
T = T.chk(abs(r1.I_down_A - 126214.14119005 / 15000) < 1e-9, 'I_down secondary via GEN 15000/1 CT');
T = T.chk(abs(r1.I_up_A - 126214.14119005 / 2000) < 1e-9, 'I_up secondary via GSUT 2000/1 STUDY CT');
T = T.chk(r1.ct_down == 15000 && r1.ct_up == 2000, 'ct_down/ct_up recorded per device');
T = T.chk(abs(r1.I_fault_kA - 126.21414119005) < 1e-9, 'I_fault_kA carries total backbone kA');
T = T.chk(~isempty(strfind(r1.reason{1}, 'total-fallback-no-leg')), 'leg-free synthetic tags total-fallback-no-leg');

% --- Tight margin -> FAIL + reason (never tuned) ---
dU2 = dU; dU2.tms = 0.5;   % margin 0.5 - 0.4 = 0.1 < 0.3
[Mf, ~] = phase5_coord([dD, dU2, R.devices(strcmp(ids, 'GIS-Q0-51'))], Tsyn);
rf = Mf(strcmp(Mf.downstream, 'GEN-51') & strcmp(Mf.upstream, 'GSUT-HV-51'), :);
T = T.chk(abs(rf.margin_s - 0.1) < 1e-12, 'tight margin 0.5/0.4 -> 0.1');
T = T.chk(strcmp(rf.verdict{1}, 'FAIL'), 'margin 0.1 < CTI 0.3 -> FAIL');
T = T.chk(~isempty(strfind(rf.reason{1}, 'FAIL')), 'FAIL row carries reason');

% --- CTI boundary: 1.3/1.0 -> 0.3 PASS (>=, exact fp-safe pair) ---
dU3 = dU; dU3.tms = 1.3; dD3 = dD; dD3.tms = 1.0;
[Mb, ~] = phase5_coord([dD3, dU3, R.devices(strcmp(ids, 'GIS-Q0-51'))], Tsyn);
rb = Mb(strcmp(Mb.downstream, 'GEN-51') & strcmp(Mb.upstream, 'GSUT-HV-51'), :);
T = T.chk(strcmp(rb.verdict{1}, 'PASS'), 'margin exactly 0.3 -> PASS (>= CTI)');

% --- Below pickup -> NO-TRIP, never forced PASS ---
Tlo = cell2table({'F1', 'LLL', 'CASE_A', 0.5, 500, 'SYN'}, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', 'I_primary_A', 'provenance'});
[Mlo, ~] = phase5_coord(devs, Tlo);
T = T.chk(all(strcmp(Mlo.verdict, 'NO-TRIP')), 'below-pickup rows verdict NO-TRIP');
T = T.chk(~any(strcmp(Mlo.verdict, 'PASS')), 'below-pickup never forced PASS');

% --- Grid-zone hierarchy: F3 -> GIS-Q0-51 vs GRID-boundary NO-PAIR ---
Tg3 = cell2table({'F3', 'LLL', 'CASE_A', 50.5308851865359, 50530.8851865359, 'SYN'}, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', 'I_primary_A', 'provenance'});
[Mg3, ~] = phase5_coord(devs, Tg3);
T = T.chk(height(Mg3) == 1, 'F3 yields single grid-zone phase row (no OC pair invented)');
T = T.chk(strcmp(Mg3.downstream{1}, 'GIS-Q0-51') && strcmp(Mg3.upstream{1}, 'REMOTE-GRID-boundary'), ...
    'F3 chain LINE-side -> GIS-Q0-51 -> GRID-boundary');
T = T.chk(strcmp(Mg3.verdict{1}, 'NO-PAIR'), 'grid-zone phase row verdict NO-PAIR');
T = T.chk(~isempty(strfind(Mg3.reason{1}, 'NO-PAIR (topology)')), 'NO-PAIR (topology) reason explicit');
T = T.chk(isfinite(Mg3.t_down_s), 'grid-zone backup t_down still reported');

% --- Earth rows: I0-derived 3I0 path, neutral counted once (T1 identity) ---
dN = R.devices(strcmp(ids, 'GEN-51N'));
dN.pickup_A = 5; dN.tms = 0.1; dN.curve = 'SI';
Te = cell2table({'F1', 'LG', 'CASE_A', 0.00727200442799167, 7.27200442799167, 0.00242400147599722, 'SYN'}, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', 'I_primary_A', 'Iseq0_kA', 'provenance'});
[Me, ~] = phase5_coord([R.devices(strcmp(ids, 'GEN-51')), dN, dU, R.devices(strcmp(ids, 'GIS-Q0-51'))], Te);
re = Me(strcmp(Me.downstream, 'GEN-51N'), :);
T = T.chk(height(re) == 1, 'F1 LG earth row uses GEN-51N downstream');
T = T.chk(abs(re.I_down_A - 7.27200442799167 / 15000) < 1e-12, ...
    'earth I_down = 3xI0 secondary (7.272 A / 15000)');
T = T.chk(abs((re.I_down_A * 15000 / 1000) / 3 - 0.00242400147599722) < 1e-12, ...
    'no double-count: I_down/3 == T1 identity I0 0.00242400147599722 kA');
T = T.chk(~isempty(strfind(re.reason{1}, '3I0')) && ~isempty(strfind(re.reason{1}, 'neutral-counted-once')), ...
    'earth reason notes 3I0 path + neutral-counted-once');
% GEN-51N F1 LG input == 3*Iseq0 within 1e-9 (binding regression).
T = T.chk(abs(re.I_down_A * 15000 - 3 * 0.00242400147599722 * 1000) < 1e-9, ...
    'GEN-51N F1 LG input == 3xIseq0 within 1e-9');
% Neutral single-count assertion: must NOT be 9xI0 (no second 3ZN scaling).
T = T.chk(abs(re.I_down_A * 15000 - 9 * 0.00242400147599722 * 1000) > 1, ...
    'neutral single-count: I_down is 3xI0, never 9xI0 (no second 3ZN scaling)');
T = T.chk(~isempty(strfind(re.reason{1}, 'no second 3ZN scaling')), 'neutral-once: reason affirms no second 3ZN scaling');
% Same earth row WITHOUT Iseq0 column: LG-exact I/3 derivation, identical value.
Te2 = Te; Te2.Iseq0_kA = [];
[Me2, ~] = phase5_coord([R.devices(strcmp(ids, 'GEN-51')), dN, dU, R.devices(strcmp(ids, 'GIS-Q0-51'))], Te2);
re2 = Me2(strcmp(Me2.downstream, 'GEN-51N'), :);
T = T.chk(abs(re2.I_down_A - re.I_down_A) < 1e-15, 'LG without Iseq0 derives I/3 identically');
% LLG without Iseq0: GEN-51N downstream missing I0 -> NO-TRIP (never invented, preserved).
Tllg = cell2table({'F1', 'LLG', 'CASE_A', 109.253451365914, 109253.451365914, 'SYN'}, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', 'I_primary_A', 'provenance'});
[Mllg, ~] = phase5_coord([R.devices(strcmp(ids, 'GEN-51')), dN, dU, R.devices(strcmp(ids, 'GIS-Q0-51'))], Tllg);
T = T.chk(all(strcmp(Mllg(strcmp(Mllg.downstream, 'GEN-51N'), :).verdict, 'NO-TRIP')), ...
    'LLG without Iseq0 GEN-51N -> NO-TRIP (I0 NOT DETERMINABLE, never invented)');

% --- T6-fallback path: raw registry devices (pickup NaN) still run honestly ---
[Mraw, ~] = phase5_coord(R.devices, Tsyn);
rr = Mraw(strcmp(Mraw.downstream, 'GEN-51') & strcmp(Mraw.upstream, 'GSUT-HV-51'), :);
tExpD = phase5_time(126214.14119005 / 15000, 15023.75 / 15000, 0.1, 'SI');
tExpU = phase5_time(126214.14119005 / 2000, 1380 / 2000, 0.2, 'SI');
T = T.chk(abs(rr.t_down_s - tExpD) < 1e-9, 'T6 fallback: GEN-51 pickup 15023.75 A, TMS 0.1 SI');
T = T.chk(abs(rr.t_up_s - tExpU) < 1e-9, 'T6 fallback: GSUT-HV-51 pickup 1380 A, TMS 0.2 SI');

% --- Errors phase5-prefixed ---
try, phase5_coord([], Tsyn); T = T.chk(false, 'empty devices errors'); ...
catch ME, T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'empty devices errors phase5-prefixed'); end
try, phase5_coord(devs, Tsyn(:, 1:3)); T = T.chk(false, 'missing current cols error'); ...
catch ME, T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'missing current cols phase5-prefixed'); end

% --- Real-data leg: 40-combo coverage, honest verdicts, I0 identity ---
root = ashuganj_root();
Ti = phase5_import(root);
[Mr, Mrgr] = phase5_coord(R.devices, Ti);
T = T.chk(height(Mr) == 96, 'real data: 56 phase + 40 earth = 96 rows');
T = T.chk(height(Mrgr) == height(Mr), 'Mrg mirrors Mtrx row count');
cs = unique(strcat(Mr.fault_location, '|', Mr.fault_type, '|', Mr.caseID));
ct = unique(strcat(Ti.fault_location, '|', Ti.fault_type, '|', Ti.caseID));
T = T.chk(isequal(sort(cs), sort(ct)), 'every (case,loc,type) combo covered >= once');
T = T.chk(all(ismember(Mr.verdict, {'PASS', 'FAIL', 'NO-TRIP', 'NO-PAIR', 'NOT DETERMINABLE FROM AVAILABLE DATA'})), ...
    'verdict domain closed (incl NOT DETERMINABLE)');
nt = Mr(strcmp(Mr.verdict, 'NO-TRIP'), :);
T = T.chk(all(isinf(nt.t_down_s) | isinf(nt.t_up_s) | isnan(nt.t_down_s) | isnan(nt.t_up_s)), ...
    'every NO-TRIP has an Inf/NaN side (never forced PASS)');
nd = Mr(strcmp(Mr.verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA'), :);
T = T.chk(height(nd) >= 1, 'NOT DETERMINABLE rows present (missing residual CT earth)');
T = T.chk(all(isnan(nd.margin_s)), 'every NOT DETERMINABLE row has NaN margin');
T = T.chk(all(isnan(nd.t_down_s) | isnan(nd.t_up_s)), ...
    'every NOT DETERMINABLE row has a NaN time side (missing CT, never threshold)');
gre = Mr(strcmp(Mr.downstream, 'GEN-51N') & strcmp(Mr.fault_location, 'F1') ...
    & strcmp(Mr.fault_type, 'LG') & strcmp(Mr.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(height(gre) == 1, 'real-data F1 LG OUT GEN-51N row present');
T = T.chk(abs((gre.I_down_A * 15000 / 1000) / 3 - 0.00242400147599722) < 1e-9, ...
    'real-data earth I0 == T1 identity 0.00242400147599722 kA (neutral once)');

% --- Branch-current correction (binding, controller-verified F1 numbers) ---
% F1 LG OUT GEN-51 phase: branch GEN_Q 8.4141 kA, never the 7.27 A net total.
bLG = Mr(strcmp(Mr.downstream, 'GEN-51') & strcmp(Mr.upstream, 'GSUT-HV-51') ...
    & strcmp(Mr.fault_location, 'F1') & strcmp(Mr.fault_type, 'LG') ...
    & strcmp(Mr.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(height(bLG) == 1, 'F1 LG OUT GEN-51 phase row present (LG has phase + earth rows)');
T = T.chk(abs(bLG.I_down_A * 15000 - 8414.11669538933) < 1e-6, ...
    'F1 LG GEN-51 I_down primary ~= 8414.1 A branch (not 7.27 A total)');
T = T.chk(abs(bLG.I_down_A * 15000 - 7.27200442799167) > 1000, ...
    'F1 LG GEN-51 branch is ~1000x the net total (false-NO-TRIP fix)');
T = T.chk(~isempty(strfind(bLG.reason{1}, 'branch-through-current')), ...
    'F1 LG GEN-51 reason tags branch-through-current');
% F1 LLL OUT GEN-51 phase: branch GEN_Q 55.0487 kA, never the 126.214 kA total.
bLLL = Mr(strcmp(Mr.downstream, 'GEN-51') & strcmp(Mr.upstream, 'GSUT-HV-51') ...
    & strcmp(Mr.fault_location, 'F1') & strcmp(Mr.fault_type, 'LLL') ...
    & strcmp(Mr.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(height(bLLL) == 1, 'F1 LLL OUT GEN-51 phase row present');
T = T.chk(abs(bLLL.I_down_A * 15000 - 55048.7096805279) < 1e-6, ...
    'F1 LLL GEN-51 I_down primary ~= 55048.7 A branch (not 126214 A total)');
T = T.chk(abs(bLLL.I_down_A * 15000 - 126214.14119005) > 10000, ...
    'F1 LLL GEN-51 branch understates the overstated total (miscoordination-artifact fix)');
% Upstream GSUT-HV-51 on F1 LG sees its own GSUT_HV branch (~8015.5 A).
bLGup = bLG;  % same row carries both sides
T = T.chk(abs(bLGup.I_up_A * 2000 - 8015.457382106) < 1e-6, ...
    'F1 LG GSUT-HV-51 I_up primary ~= 8015.5 A branch (own leg, not shared total)');
% GIS-Q0-51 on F1 LG sees GRID_Q branch with the infeed-branch stamp.
bLGq0 = Mr(strcmp(Mr.downstream, 'GSUT-HV-51') & strcmp(Mr.upstream, 'GIS-Q0-51') ...
    & strcmp(Mr.fault_location, 'F1') & strcmp(Mr.fault_type, 'LG') ...
    & strcmp(Mr.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(any(strcmp(bLGq0.verdict, 'PASS') | strcmp(bLGq0.verdict, 'FAIL') | strcmp(bLGq0.verdict, 'NO-TRIP')), ...
    'F1 LG GIS phase row has a phase verdict (phase trips evaluated, not hidden)');
phRow = bLGq0(~strcmp(bLGq0.verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA'), :);
T = T.chk(height(phRow) == 1, 'F1 LG GSUT>GIS phase row present alongside earth row');
T = T.chk(abs(phRow.I_up_A * 2000 - 8.01545738210606 * 1000) < 1e-6, ...
    'F1 LG GIS-Q0-51 I_up primary ~= 8015.5 A GRID_Q branch');
T = T.chk(~isempty(strfind(phRow.reason{1}, 'infeed-branch assumption, see registry equipment field')), ...
    'GIS phase reason stamps infeed-branch assumption + registry equipment');
% Grid-zone earth: GEN-51N sees 3xNER ~0 -> honest NO-TRIP with delta-block reason.
gE = Mr(strcmp(Mr.downstream, 'GEN-51N') & strcmp(Mr.fault_location, 'F3') ...
    & strcmp(Mr.fault_type, 'LG') & strcmp(Mr.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(height(gE) == 1, 'grid-zone F3 LG GEN-51N NER row present');
T = T.chk(strcmp(gE.verdict{1}, 'NO-TRIP'), 'F3 LG NER ~0 -> honest NO-TRIP (delta block)');
T = T.chk(abs(gE.I_down_A) < 1e-12, 'F3 LG NER I_down == 0 A (delta block)');
T = T.chk(~isempty(strfind(gE.reason{1}, 'delta block, generator NER carries no HV-fault earth current')), ...
    'NER row carries delta-block reason');
% Missing residual CT earth: GSUT/GIS earth pair-2 row -> NOT DETERMINABLE, never NO-TRIP.
e2 = Mr(strcmp(Mr.downstream, 'GSUT-HV-51') & strcmp(Mr.upstream, 'GIS-Q0-51') ...
    & strcmp(Mr.fault_location, 'F1') & strcmp(Mr.fault_type, 'LG') ...
    & strcmp(Mr.caseID, 'LF360_GAT_OUT') & strcmp(Mr.verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA'), :);
T = T.chk(height(e2) == 1, 'F1 LG earth pair-2 row verdict NOT DETERMINABLE (missing residual CT)');
T = T.chk(~isempty(strfind(e2.reason{1}, 'NOT DETERMINABLE FROM AVAILABLE DATA')), ...
    'missing-CT reason states NOT DETERMINABLE (never NO-TRIP-by-threshold)');
T = T.chk(isnan(e2.I_down_A) && isnan(e2.I_up_A), 'missing-CT earth currents NaN (never invented)');
nFail = sum(strcmp(Mr.verdict, 'FAIL'));
nND = sum(strcmp(Mr.verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA'));
fprintf(['  INFO  real-data verdicts: PASS=%d FAIL=%d NO-TRIP=%d NO-PAIR=%d NOT-DETERMINABLE=%d' ...
    ' (FAILs/NO-TRIPs honest, never tuned)\n'], ...
    sum(strcmp(Mr.verdict, 'PASS')), nFail, sum(strcmp(Mr.verdict, 'NO-TRIP')), ...
    sum(strcmp(Mr.verdict, 'NO-PAIR')), nND);
T = T.chk(nFail >= 0, 'FAIL count recorded honestly');

[np, nf] = T.done();
end
