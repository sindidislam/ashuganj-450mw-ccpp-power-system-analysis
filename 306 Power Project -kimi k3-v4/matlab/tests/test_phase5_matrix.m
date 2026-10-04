function [np, nf] = test_phase5_matrix()
%TEST_PHASE5_MATRIX  Phase-5 Task 16 gap test for V9/V10/V14-live (matrix extrema).
%   Pins the live-matrix facts that validation legs V9 (min-detect), V10
%   (max-duty) and V14 (2x5x4 coverage) depend on, none asserted elsewhere:
%   the import backbone is exactly the 2-cases x 5-locs x 4-types set (40
%   unique combos, not just height 40); the live minimum phase-fault total
%   (LLL/LL/LLG, never LG earth) exceeds the GEN-51 study pickup 15023.75 A
%   and F1 LG OUT (7.272 A) exceeds the GEN-51N 5 A setting (must-detect);
%   the duty-table maximum through-current (non-NOTE rows) equals the
%   independently derived import-leg maximum and sits on an F1/F2 grid-infeed
%   row with verdict NOT DETERMINABLE (no rating invented).
%   All errors phase5-prefixed (via callees).
T = t_case('test_phase5_matrix');
root = ashuganj_root();
Ti = phase5_import(root);
% --- Exact 2x5x4 combo set (not just row count) ---
locs = cellstr(Ti.fault_location); typs = cellstr(Ti.fault_type); cases = cellstr(Ti.caseID);
got = unique(strcat(cases, '|', locs, '|', typs));
expCases = {'LF360_GAT_OUT', 'LF360_GAT_IN'};
expLocs = {'F1', 'F2', 'F3', 'F4', 'F5'};
expTyps = {'LLL', 'LG', 'LL', 'LLG'};
want = {};
for a = 1:numel(expCases)
    for b = 1:numel(expLocs)
        for c = 1:numel(expTyps)
            want{end + 1} = [expCases{a} '|' expLocs{b} '|' expTyps{c}]; %#ok<AGROW>
        end
    end
end
T = T.chk(numel(got) == 40, 'backbone holds 40 unique (case,loc,type) combos');
T = T.chk(isequal(sort(got), sort(want')), 'combo set is exactly 2 cases x 5 locs x 4 types');
% --- V9 min-detect: live minima vs study pickups ---
R = phase5_registry();
ids = {R.devices.device_id};
d51 = R.devices(strcmp(ids, 'GEN-51'));
d51N = R.devices(strcmp(ids, 'GEN-51N'));
isPhase = strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG');
IminPhase = min(Ti.I_primary_A(isPhase));
P51 = phase5_pickup(d51, double(R.gen.Irated_A), IminPhase);
T = T.chk(P51.setting < IminPhase, 'live min phase fault exceeds GEN-51 pickup (must-detect)');
T = T.chk(P51.setting > double(R.gen.Irated_A), 'GEN-51 pickup above rated 12019 A (no-trip-on-load)');
gLG = Ti(strcmp(locs, 'F1') & strcmp(typs, 'LG') & strcmp(cases, 'LF360_GAT_OUT'), :);
PN = phase5_pickup(d51N, 0, double(gLG.I_primary_A));
T = T.chk(PN.setting < double(gLG.I_primary_A), 'GEN-51N 5 A below live F1 LG OUT (must-detect)');
T = T.chk(abs(double(gLG.I_primary_A) / PN.setting - 1.45) < 0.05, 'live EF margin ~1.45');
% --- V10 max-duty: duty-table max == import-leg max, F1/F2 grid infeed ---
D = phase5_duty(Ti, []);
isNote = strcmp(D.verdict, 'NOTE');
Dd = D(~isNote, :);
[dutyMax, imax] = max(Dd.I_sym_kA);
T = T.chk(isfinite(dutyMax), 'duty-table max through-current finite');
T = T.chk(any(strcmp(Dd.location(imax), {'F1', 'F2'})), 'max duty sits on F1/F2 grid-infeed row');
expMax = max([max(Ti.leg_GRID_kA(strcmp(locs, 'F1') | strcmp(locs, 'F2'))), ...
    max(Ti.leg_GSUT_HV_kA(~(strcmp(locs, 'F1') | strcmp(locs, 'F2'))))]);
T = T.chk(abs(dutyMax - expMax) < 1e-9, 'duty max equals import-leg max (no total substituted)');
T = T.chk(strcmp(Dd.verdict{imax}, 'NOT DETERMINABLE FROM AVAILABLE DATA'), ...
    'max-duty row NOT DETERMINABLE without rating (never PASS/FAIL)');
fprintf('  INFO  matrix extrema: IminPhase=%.3f A IminEarth=%.5f A dutyMax=%.4f kA\n', ...
    IminPhase, double(gLG.I_primary_A), dutyMax);
[np, nf] = T.done();
end
