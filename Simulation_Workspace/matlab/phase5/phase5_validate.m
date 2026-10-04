function V = phase5_validate()
%PHASE5_VALIDATE  15-leg validation engine + Phase-4 regression (Phase-5 Task 16).
%   V = PHASE5_VALIDATE() returns struct V with field .legs, a struct array
%   with fields id (char), pass (logical), residual (double), note (char).
%   16 legs: R0 Phase-4 regression + V1..V15.
%
%   Legs (each: pass bool + residual + note; every leg must pass for the gate):
%     R0  Phase-4 regression via phase5_import: F3 LLL OUT == 50.5308851865359
%         kA within 1e-6, F1 LG OUT == 0.00727200442799167 kA within 1e-9.
%     V1  CT conversion: 12019/15000, 7.272 A->0.4848 mA, 50.53 kA->3.369 A
%         anchors + live Isec/Iprimary == 1/15000 within 1e-12.
%     V2  Pickup conversion: GEN-51 15023.75 A, GEN-51N 5 A, GIS-Q0-51
%         1.2xFL_anchor primaries + secondary consistency via phase5_ct.
%     V3  Time calc: F3 LLL finite <10 s, EF t~9.31 s, below-pickup Inf.
%     V4  Earth-fault (T12): F1 LG 7.272 A -> 0.4848 mA secondary, EF
%         must-detect margin ~1.45, Isec/Iprimary == 1/15000 within 1e-12,
%         phase-branch (8414.1 A) vs I0 (2.424 A) vs secondary distinguished.
%     V5  Inverse behaviour: SI closed form, M<=1 Inf, EI faster than SI at
%         M=10, monotonic.
%     V6  Instantaneous: DT threshold/equality semantics via phase5_curve_dt
%         + phase5_time DT branch, DT routing error, inverse never instant.
%     V7  Margin: synthetic DT pair 0.8/0.4->0.4 PASS, 0.1 FAIL, 0.3 boundary
%         PASS (CTI 0.3 s study threshold).
%     V8  Duty separation (T10+T11): 10-col schema, no time/margin cols, no
%         PASS/FAIL without rating, exactly one 50-kA NOTE row (+1.06%,
%         ESTIMATED, never PASS/FAIL), Q0 only, no IEC string.
%     V9  Min-detect: live min phase fault > GEN-51 pickup, F1 LG > GEN-51N,
%         pickup above load (no-trip-on-load).
%     V10 Max-duty: duty-table max == import-leg max on F1/F2 grid infeed,
%         NOT DETERMINABLE without rating.
%     V11 Sensitivity: 16k == 15k x 15/16 within 1e-12, fixed dial never
%         faster, fenced scope/provenance.
%     V12 Source/legacy separation + T15 provenance ledger (interim: T17
%         writer absent, so live tables from import/coord/duty/sensitivity +
%         registry are scanned): CT tag enforcement, LEGACY fencing, every
%         live-table row carries non-empty provenance/scope-equivalent
%         (import.provenance SOURCE-BACKED, sensitivity scope+provenance,
%         duty basis+note, coord reason, registry provenance).
%     V13 Topology mapping (T11 Q-semantics): Q0 breaker, Q1/Q2/Q9
%         disconnectors, Q51/Q52/Q8 earthing; breaker_ref only Q0 (Q1/Q2/Q9
%         never); live F1/F2 pairs + F3/F4/F5 NO-PAIR (topology) rows.
%     V14 Matrix coverage (T13): 40 import combos == 2x5x4 set, every combo
%         in coord >= once with pair or explicit NO-PAIR reason, closed
%         verdict domain, never silently dropped.
%     V15 No-double-neutral (T11): GEN-51N F1 LG == 3xI0 == 7.272 A within
%         1e-9, I0 == 0.00242400147599722 kA, never 9xI0, 3I0 reason tags.
%
%   Infrastructure failures (missing CSV, bad schema) error loudly with
%   phase5-prefixed identifiers; measured shortfalls yield pass=false with
%   residual + note, never retuned. All errors are 'phase5'-prefixed.
if nargin ~= 0
    error('phase5_validate:args', 'usage: V = phase5_validate().');
end
root = ashuganj_root();
R = phase5_registry();
Ti = phase5_import(root);
D = phase5_duty(Ti, []);
S = phase5_sensitivity(Ti, R.devices);
[Mtrx, ~] = phase5_coord(R.devices, Ti);
ids = {'R0', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', ...
    'V10', 'V11', 'V12', 'V13', 'V14', 'V15'};
legs = repmat(struct('id', '', 'pass', false, 'residual', NaN, 'note', ''), 1, 16);
[p, r, n] = legR0(Ti);          legs(1) = mkleg(ids{1}, p, r, n);
[p, r, n] = legV1(Ti);          legs(2) = mkleg(ids{2}, p, r, n);
[p, r, n] = legV2(R, Ti);       legs(3) = mkleg(ids{3}, p, r, n);
[p, r, n] = legV3();            legs(4) = mkleg(ids{4}, p, r, n);
[p, r, n] = legV4(R, Ti);       legs(5) = mkleg(ids{5}, p, r, n);
[p, r, n] = legV5();            legs(6) = mkleg(ids{6}, p, r, n);
[p, r, n] = legV6();            legs(7) = mkleg(ids{7}, p, r, n);
[p, r, n] = legV7(R);           legs(8) = mkleg(ids{8}, p, r, n);
[p, r, n] = legV8(D);           legs(9) = mkleg(ids{9}, p, r, n);
[p, r, n] = legV9(R, Ti);       legs(10) = mkleg(ids{10}, p, r, n);
[p, r, n] = legV10(Ti, D);      legs(11) = mkleg(ids{11}, p, r, n);
[p, r, n] = legV11(Ti, S);      legs(12) = mkleg(ids{12}, p, r, n);
[p, r, n] = legV12(Ti, D, Mtrx, R, S); legs(13) = mkleg(ids{13}, p, r, n);
[p, r, n] = legV13(R, Mtrx);    legs(14) = mkleg(ids{14}, p, r, n);
[p, r, n] = legV14(Ti, Mtrx);   legs(15) = mkleg(ids{15}, p, r, n);
[p, r, n] = legV15(Mtrx);       legs(16) = mkleg(ids{16}, p, r, n);
V = struct('legs', legs);
end

function L = mkleg(id, pass, residual, note)
L = struct('id', id, 'pass', logical(pass), 'residual', double(residual), 'note', char(note));
end

function [p, r, n] = legR0(Ti)
%LEG R0  Phase-4 regression identity via phase5_import.
a = Ti(strcmp(tocell(Ti.fault_location), 'F3') & strcmp(tocell(Ti.fault_type), 'LLL') ...
    & strcmp(tocell(Ti.caseID), 'LF360_GAT_OUT'), :);
g = Ti(strcmp(tocell(Ti.fault_location), 'F1') & strcmp(tocell(Ti.fault_type), 'LG') ...
    & strcmp(tocell(Ti.caseID), 'LF360_GAT_OUT'), :);
d1 = abs(a.I_primary_kA - 50.5308851865359);
d2 = abs(g.I_primary_kA - 0.00727200442799167);
p = (d1 < 1e-6) && (d2 < 1e-9);
r = max(d1, d2);
n = sprintf('F3-LLL-OUT %.10f kA (d %.2g, tol 1e-6); F1-LG-OUT %.14f kA (d %.2g, tol 1e-9)', ...
    a.I_primary_kA, d1, g.I_primary_kA, d2);
end

function [p, r, n] = legV1(Ti)
%LEG V1  CT conversion anchors + live 1/15000 ratio.
a1 = abs(phase5_ct(12019, 15000).Isec_A - 0.8012667);
a2 = abs(phase5_ct(7.27200442799167, 15000).Isec_A - 0.0004848);
a3 = abs(phase5_ct(50530.8851865359, 15000).Isec_A - 3.3687257);
Tc = phase5_ct_table(Ti, 15000, 'PRIMARY-15000/1');
rat = Tc.I_secondary_A ./ Ti.I_primary_A;
rd = max(abs(rat - 1 / 15000));
p = (a1 < 1e-6) && (a2 < 1e-7) && (a3 < 1e-5) && (rd <= 1e-12);
r = max([a1, a2, a3]);
n = sprintf('12019A d %.2g; 7.272A d %.2g; 50.53kA d %.2g; live Isec/Iprim==1/15000 max-dev %.2g', a1, a2, a3, rd);
end

function [p, r, n] = legV2(R, Ti)
%LEG V2  Pickup primaries + secondary consistency.
ids = {R.devices.device_id};
d51 = R.devices(strcmp(ids, 'GEN-51'));
d51N = R.devices(strcmp(ids, 'GEN-51N'));
dQ0 = R.devices(strcmp(ids, 'GIS-Q0-51'));
typs = tocell(Ti.fault_type);
IminPhase = min(Ti.I_primary_A(strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG')));
P51 = phase5_pickup(d51, double(R.gen.Irated_A), IminPhase);
PN = phase5_pickup(d51N, 0, 7.27200442799167);
PG = phase5_pickup(dQ0, 869.956651959241, IminPhase);
c1 = abs(P51.setting - 15023.75);
c2 = abs(PN.setting - 5);
c3 = abs(PG.setting - 1.2 * 869.956651959241);
c4 = abs(phase5_ct(P51.setting, 15000).Isec_A - P51.setting / 15000);
p = (c1 < 1e-9) && (c2 < 1e-12) && (c3 < 1e-9) && (c4 < 1e-15);
r = max([c1, c2, c3]);
n = sprintf('GEN-51 %.2f A (d %.2g); GEN-51N %.4f A; GIS-Q0-51 %.6f A (1.2xFL_anchor); sec-consistency d %.2g', ...
    P51.setting, c1, PN.setting, PG.setting, c4);
end

function [p, r, n] = legV3()
%LEG V3  Operating-time anchors.
tA = phase5_time(3.3687257, 1.0015833, 0.1, 'SI');
tE = phase5_time(0.0004848, 0.0003333, 0.5, 'SI');
p = isfinite(tA) && (tA > 0) && (tA < 10) && (abs(tE - 9.31) < 0.1) ...
    && isinf(phase5_time(0.5, 1.0, 0.1, 'SI'));
r = abs(tE - 9.31);
n = sprintf('F3-LLL t %.4f s (<10 s); EF t %.4f s (d %.4f vs 9.31); below-pickup Inf', tA, tE, r);
end

function [p, r, n] = legV4(R, Ti)
%LEG V4  Low-earth-fault physics (T12): secondary, must-detect, ratio, distinguished paths.
locs = tocell(Ti.fault_location); typs = tocell(Ti.fault_type); cases = tocell(Ti.caseID);
hit = strcmp(locs, 'F1') & strcmp(typs, 'LG') & strcmp(cases, 'LF360_GAT_OUT');
IfLG = double(Ti.I_primary_A(hit));
legGEN = double(Ti.leg_GEN_kA(hit)) * 1000;
Ssec = phase5_ct(IfLG, 15000);
e1 = abs(Ssec.Isec_A - 0.0004848);
rat = abs(Ssec.Isec_A / IfLG - 1 / 15000);
ids = {R.devices.device_id};
PN = phase5_pickup(R.devices(strcmp(ids, 'GEN-51N')), 0, IfLG);
marg = IfLG / PN.setting;
tEF = phase5_time(Ssec.Isec_A, PN.setting / 15000, 0.5, 'SI');
I0 = IfLG / 3;
p = (e1 < 1e-7) && (rat <= 1e-12) && (PN.setting < IfLG) && (abs(marg - 1.45) < 0.05) ...
    && isfinite(tEF) && (abs(legGEN - 8414.11669538933) < 1e-6) ...
    && (abs(I0 - 2.42400147599722) < 1e-9) ...
    && (legGEN > 1000) && (I0 < 10) && (Ssec.Isec_A < 0.01);
r = e1;
n = sprintf(['7.272 A -> %.7f A-sec (d %.2g); margin %.4f (~1.45); tEF %.3f s; ' ...
    'phase-branch %.2f A vs I0 %.5f A vs sec %.7f A distinguished'], ...
    Ssec.Isec_A, e1, marg, tEF, legGEN, I0, Ssec.Isec_A);
end

function [p, r, n] = legV5()
%LEG V5  Inverse behaviour: closed form, no-trip, EI-vs-SI ordering, monotonic.
[k, a] = phase5_curve_info('SI');
t2 = phase5_curve(2, 'SI', 0.1);
s10 = phase5_curve(10, 'SI', 0.1);
e10 = phase5_curve(10, 'EI', 0.1);
p = (abs(k - 0.14) < 1e-12) && (abs(a - 0.02) < 1e-12) ...
    && (abs(t2 - 0.1 * 0.14 / ((2 ^ 0.02) - 1)) < 1e-9) ...
    && isinf(phase5_curve(1, 'SI', 0.1)) && (e10 < s10) && (t2 > s10);
r = s10 - e10;
n = sprintf('SI closed-form ok; M<=1 Inf; EI(10) %.5f s < SI(10) %.5f s (gap %.5f s); monotonic', e10, s10, r);
end

function [p, r, n] = legV6()
%LEG V6  Instantaneous / definite-time semantics.
tT = phase5_time(2.0, 1.0, 0.4, 'DT');
tI = phase5_time(3.3687257, 1.0015833, 0.1, 'SI');
tX = 0.1 * 0.14 / ((3.3687257 / 1.0015833) ^ 0.02 - 1);
try
    phase5_curve(2, 'DT', 0.1);
    routed = false;
catch ME
    routed = strcmp(ME.identifier, 'phase5_curve:family');
end
p = (phase5_curve_dt(2.0, 1.0, 0.4) == 0.4) && (phase5_curve_dt(1.0, 1.0, 0.4) == 0.4) ...
    && isinf(phase5_curve_dt(0.5, 1.0, 0.4)) && (tT == 0.4) ...
    && isinf(phase5_time(0.5, 1.0, 0.4, 'DT')) && routed ...
    && (abs(tI - tX) < 1e-9) && (tI > 0.05);
r = abs(tT - 0.4);
n = sprintf('DT trip/Inf/equality ok; DT routing error ok; inverse t %.4f s (never 0.05 s shortcut)', tI);
end

function [p, r, n] = legV7(R)
%LEG V7  Margin arithmetic on synthetic DT pairs via phase5_coord.
ids = {R.devices.device_id};
dD = R.devices(strcmp(ids, 'GEN-51'));
dU = R.devices(strcmp(ids, 'GSUT-HV-51'));
dD.pickup_A = 1000; dD.tms = 0.4; dD.curve = 'DT';
dU.pickup_A = 1000; dU.tms = 0.8; dU.curve = 'DT';
Tsyn = cell2table({'F1', 'LLL', 'CASE_A', 126.21414119005, 126214.14119005, 'SYN'}, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', 'I_primary_A', 'provenance'});
[M, ~] = phase5_coord([dD, dU, R.devices(strcmp(ids, 'GIS-Q0-51'))], Tsyn);
rw = M(strcmp(M.downstream, 'GEN-51') & strcmp(M.upstream, 'GSUT-HV-51'), :);
dU2 = dU; dU2.tms = 0.5;
[Mf, ~] = phase5_coord([dD, dU2, R.devices(strcmp(ids, 'GIS-Q0-51'))], Tsyn);
rf = Mf(strcmp(Mf.downstream, 'GEN-51') & strcmp(Mf.upstream, 'GSUT-HV-51'), :);
dU3 = dU; dU3.tms = 1.3; dD3 = dD; dD3.tms = 1.0;
[Mb, ~] = phase5_coord([dD3, dU3, R.devices(strcmp(ids, 'GIS-Q0-51'))], Tsyn);
rb = Mb(strcmp(Mb.downstream, 'GEN-51') & strcmp(Mb.upstream, 'GSUT-HV-51'), :);
m = abs(rw.margin_s - 0.4);
p = (m < 1e-12) && strcmp(rw.verdict{1}, 'PASS') ...
    && strcmp(rf.verdict{1}, 'FAIL') && strcmp(rb.verdict{1}, 'PASS');
r = m;
n = sprintf('0.8/0.4 -> %.4f s PASS; tight 0.1 FAIL; boundary 0.3 PASS (CTI 0.3 s)', rw.margin_s);
end

function [p, r, n] = legV8(D)
%LEG V8  Duty separation + T11 50-kA guard.
exp10 = {'location', 'breaker_ref', 'fault_type', 'caseID', 'I_sym_kA', ...
    'I_peak_kA', 'rating_kA', 'basis', 'verdict', 'note'};
isNote = strcmp(D.verdict, 'NOTE');
Dd = D(~isNote, :);
nRow = D(isNote, :);
noIEC = ~table_has(D, 'IEC');
schema = isequal(D.Properties.VariableNames, exp10) ...
    && ~any(strcmp(D.Properties.VariableNames, 't_up_s')) ...
    && ~any(strcmp(D.Properties.VariableNames, 't_down_s')) ...
    && ~any(strcmp(D.Properties.VariableNames, 'margin_s'));
honest = all(strcmp(Dd.verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA')) ...
    && ~any(strcmp(Dd.verdict, 'PASS')) && ~any(strcmp(Dd.verdict, 'FAIL')) ...
    && all(isnan(Dd.rating_kA)) && all(~cellfun(@isempty, strfind(Dd.basis, 'MISSING')));
q0only = all(strcmp(D.breaker_ref, 'Q0'));
note1 = (sum(isNote) == 1) && (abs(nRow.I_sym_kA - 50.5308851865359) < 1e-6) ...
    && (abs(nRow.rating_kA - 50.0) < 1e-12) && ~isempty(strfind(nRow.note{1}, '+1.06%')) ...
    && ~isempty(strfind(nRow.basis{1}, 'ESTIMAT')) && strcmp(nRow.verdict{1}, 'NOTE');
p = schema && honest && q0only && note1 && noIEC;
r = 0;
n = sprintf(['10-col schema, no time/margin cols; %d duty rows NOT DETERMINABLE; ' ...
    'one NOTE row %.4f kA +1.06%% ESTIMATED (never PASS/FAIL); Q0 only; no IEC'], ...
    height(Dd), nRow.I_sym_kA);
end

function [p, r, n] = legV9(R, Ti)
%LEG V9  Minimum-detect vs study pickups on live import.
ids = {R.devices.device_id};
typs = tocell(Ti.fault_type);
locs = tocell(Ti.fault_location); cases = tocell(Ti.caseID);
IminPhase = min(Ti.I_primary_A(strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG')));
P51 = phase5_pickup(R.devices(strcmp(ids, 'GEN-51')), double(R.gen.Irated_A), IminPhase);
gLG = Ti(strcmp(locs, 'F1') & strcmp(typs, 'LG') & strcmp(cases, 'LF360_GAT_OUT'), :);
PN = phase5_pickup(R.devices(strcmp(ids, 'GEN-51N')), 0, double(gLG.I_primary_A));
m1 = IminPhase - P51.setting;
m2 = double(gLG.I_primary_A) - PN.setting;
p = (m1 > 0) && (m2 > 0) && (P51.setting > double(R.gen.Irated_A));
r = min(m1, m2);
n = sprintf('IminPhase %.2f A vs GEN-51 %.2f A (margin %.2f A); F1-LG %.5f A vs GEN-51N %.2f A (margin %.5f A)', ...
    IminPhase, P51.setting, m1, double(gLG.I_primary_A), PN.setting, m2);
end

function [p, r, n] = legV10(Ti, D)
%LEG V10  Maximum duty through-current identity.
isNote = strcmp(D.verdict, 'NOTE');
Dd = D(~isNote, :);
[dutyMax, imax] = max(Dd.I_sym_kA);
locs = tocell(Ti.fault_location);
expMax = max([max(Ti.leg_GRID_kA(strcmp(locs, 'F1') | strcmp(locs, 'F2'))), ...
    max(Ti.leg_GSUT_HV_kA(~(strcmp(locs, 'F1') | strcmp(locs, 'F2'))))]);
d = abs(dutyMax - expMax);
p = isfinite(dutyMax) && (d < 1e-9) ...
    && any(strcmp(Dd.location(imax), {'F1', 'F2'})) ...
    && strcmp(Dd.verdict{imax}, 'NOT DETERMINABLE FROM AVAILABLE DATA');
r = d;
n = sprintf('max duty %.4f kA on %s %s %s (grid infeed, d %.2g vs import legs; NOT DETERMINABLE w/o rating)', ...
    dutyMax, Dd.location{imax}, Dd.fault_type{imax}, Dd.caseID{imax}, d);
end

function [p, r, n] = legV11(Ti, S)
%LEG V11  Fenced sensitivity: 15/16 ratio + fixed-dial never-faster.
prim = double(Ti.I_primary_A(:));
dev = max(abs(prim / 16000 - (prim / 15000) * 15 / 16));
bothT = isfinite(S.t_primary_s) & isfinite(S.t_sens_s);
dir = all(S.t_sens_s(bothT) >= S.t_primary_s(bothT) - 1e-9) ...
    && ~any(strcmp(S.direction, 'faster'));
p = (dev <= 1e-12) && dir && all(strcmp(S.scope, 'SENSITIVITY'));
r = dev;
n = sprintf('16k == 15k x 15/16 max-dev %.2g (tol 1e-12); fixed dial never-faster; scope SENSITIVITY', dev);
end

function [p, r, n] = legV12(Ti, D, Mtrx, R, S)
%LEG V12  Source/legacy separation + T15 provenance ledger over live tables.
viol = 0;
try
    phase5_ct_table(Ti, 15000, 'LEGACY-16000/1');
    viol = viol + 1;
catch ME
    if ~strcmp(ME.identifier, 'phase5_ct_table:tag'), viol = viol + 1; end
end
try
    phase5_ct_table(Ti, 16000, 'PRIMARY-15000/1');
    viol = viol + 1;
catch ME
    if ~strcmp(ME.identifier, 'phase5_ct_table:tag'), viol = viol + 1; end
end
if ~all(strcmp(S.scope, 'SENSITIVITY')), viol = viol + 1; end
if ~all(strcmp(S.ct_tag, 'LEGACY-16000/1')), viol = viol + 1; end
if ~all(~cellfun(@isempty, strfind(S.provenance, 'LEGACY'))), viol = viol + 1; end
if ~all(~cellfun(@isempty, Ti.provenance)), viol = viol + 1; end
for k = 1:height(Ti)
    if strncmp(Ti.provenance{k}, 'SOURCE-BACKED', 13), continue; end
    viol = viol + 1;
end
if ~all(~cellfun(@isempty, S.scope)) || ~all(~cellfun(@isempty, S.provenance)), viol = viol + 1; end
if ~all(~cellfun(@isempty, D.basis)) || ~all(~cellfun(@isempty, D.note)), viol = viol + 1; end
if ~all(~cellfun(@isempty, Mtrx.reason)), viol = viol + 1; end
for k = 1:numel(R.devices)
    if isempty(R.devices(k).provenance), viol = viol + 1; end
end
p = (viol == 0);
r = viol;
n = sprintf('CT tag mismatch errors enforced; LEGACY fencing on %d sens rows; provenance/scope non-empty on import(%d)/duty(%d)/coord(%d)/registry(%d)', ...
    height(S), height(Ti), height(D), height(Mtrx), numel(R.devices));
end

function [p, r, n] = legV13(R, Mtrx)
%LEG V13  Topology mapping + T11 Q-semantics on live matrix.
topo = strcmp(R.topology.Q0, 'breaker') && strcmp(R.topology.Q1, 'disconnector') ...
    && strcmp(R.topology.Q2, 'disconnector') && strcmp(R.topology.Q9, 'disconnector') ...
    && strcmp(R.topology.Q51, 'earthing') && strcmp(R.topology.Q52, 'earthing') ...
    && strcmp(R.topology.Q8, 'earthing');
qref = true;
for k = 1:numel(R.devices)
    br = R.devices(k).breaker_ref;
    if ~(isempty(br) || strcmp(br, 'Q0')), qref = false; end
    if any(strcmp(br, {'Q1', 'Q2', 'Q9'})), qref = false; end
end
p1 = Mtrx(strcmp(Mtrx.downstream, 'GEN-51') & strcmp(Mtrx.upstream, 'GSUT-HV-51') ...
    & (strcmp(Mtrx.fault_location, 'F1') | strcmp(Mtrx.fault_location, 'F2')), :);
np_ = Mtrx(strcmp(Mtrx.downstream, 'GIS-Q0-51') & strcmp(Mtrx.upstream, 'REMOTE-GRID-boundary') ...
    & strcmp(Mtrx.verdict, 'NO-PAIR'), :);
npReason = all(~cellfun(@isempty, strfind(np_.reason, 'NO-PAIR (topology)')));
p = topo && qref && (height(p1) == 16) && (height(np_) == 24) && npReason;
r = 0;
n = sprintf('Q0 breaker / Q1,Q2,Q9 disconnectors / Q51,Q52,Q8 earthing; breaker_ref Q0-only; F1/F2 pairs %d; grid NO-PAIR %d explicit', ...
    height(p1), height(np_));
end

function [p, r, n] = legV14(Ti, Mtrx)
%LEG V14  2x5x4 matrix coverage (T13): every combo >= once, never dropped.
locs = tocell(Ti.fault_location); typs = tocell(Ti.fault_type); cases = tocell(Ti.caseID);
want = unique(strcat(cases, '|', locs, '|', typs));
ml = tocell(Mtrx.fault_location); mt = tocell(Mtrx.fault_type); mc = tocell(Mtrx.caseID);
got = unique(strcat(mc, '|', ml, '|', mt));
missing = setdiff(want, got);
dom = {'PASS', 'FAIL', 'NO-TRIP', 'NO-PAIR', 'NOT DETERMINABLE FROM AVAILABLE DATA'};
p = (height(Ti) == 40) && (numel(want) == 40) && isempty(missing) ...
    && all(ismember(Mtrx.verdict, dom)) && all(~cellfun(@isempty, Mtrx.reason));
r = numel(missing);
n = sprintf('import %d rows / %d combos; coord covers all %d combos (missing %d); verdict domain closed; reasons non-empty', ...
    height(Ti), numel(want), numel(got), r);
end

function [p, r, n] = legV15(Mtrx)
%LEG V15  No-double-neutral (T11): 3xI0 single count on live GEN-51N row.
ml = tocell(Mtrx.fault_location); mt = tocell(Mtrx.fault_type); mc = tocell(Mtrx.caseID);
gre = Mtrx(strcmp(Mtrx.downstream, 'GEN-51N') & strcmp(ml, 'F1') ...
    & strcmp(mt, 'LG') & strcmp(mc, 'LF360_GAT_OUT'), :);
Iprim = gre.I_down_A * 15000;
e1 = abs(Iprim - 7.27200442799167);
e2 = abs((Iprim / 1000) / 3 - 0.00242400147599722);
no9 = abs(Iprim - 9 * 2.42400147599722) > 1;
tags = ~isempty(strfind(gre.reason{1}, '3I0')) ...
    && ~isempty(strfind(gre.reason{1}, 'neutral-counted-once'));
p = (height(gre) == 1) && (e1 < 1e-9) && (e2 < 1e-9) && no9 && tags;
r = max(e1, e2);
n = sprintf('GEN-51N F1-LG %.8f A == 3xI0 (d %.2g); I0 %.14f kA (d %.2g); never 9xI0; 3I0 tags', Iprim, e1, Iprim / 3000, e2);
end

function c = tocell(v)
%TOCELL  Normalize table text column to cellstr.
if iscell(v)
    c = v(:);
elseif isstring(v)
    c = cellstr(v(:));
elseif ischar(v)
    c = cellstr(v);
else
    error('phase5_validate:schema', 'text column must be cell/string/char.');
end
end

function tf = table_has(D, pat)
%TABLE_HAS  True if pattern appears in any variable name or string cell.
tf = ~isempty(strfind(strjoin(D.Properties.VariableNames, '|'), pat));
if tf, return; end
for k = 1:numel(D.Properties.VariableNames)
    col = D.(D.Properties.VariableNames{k});
    if iscell(col)
        for i = 1:numel(col)
            vv = col{i};
            if (ischar(vv) || isstring(vv)) && ~isempty(strfind(char(vv), pat))
                tf = true; return;
            end
        end
    elseif ischar(col) || isstring(col)
        if ~isempty(strfind(char(col), pat)), tf = true; return; end
    end
end
end
