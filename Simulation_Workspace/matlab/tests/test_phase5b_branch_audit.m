function [np, nf] = test_phase5b_branch_audit()
%TEST_PHASE5B_BRANCH_AUDIT  Phase-5b Task C5 8.414 kA audit + rename + regression pin.
%   Test-only task: NO production module. Read-only audit over Phase-4 data
%   plus the v1 import join (phase5_import, T3 join: contributions
%   leg_GEN_kA feeds the import leg values; see phase5_import.m Through-current
%   join block). Leg semantics per phase4_contrib.m lines 1-140: legs are
%   toward-fault-signed branch currents; KCL partition runs over the
%   feeding-leg set per location (F1/F2 seq1/2 {GEN,GSUT_LV,UAT}, seq0 {GEN};
%   through-legs reported but excluded).
%
%   Target row: contributions F1 LG LF360_GAT_OUT Ikpp m==0.5:
%     leg_GEN_kA == 8.4141 (+/-1e-4), KCL residuals < 1e-9.
%   Prefault anchor: phase4_ct_data.csv GEN_Q row FL_anchor 9.4757 kA.
%   Evidence rule (plan): NOT pure prefault iff |leg-anchor|/anchor > 0.05
%   AND NOT net fault current iff leg/total > 100
%     -> verdict 'branch-through-current-magnitude'.
%   Rename contract: any consumer labelling this number must use
%   'branch-through-current' (never prefault, never net fault current).
%   Any deviation (leg equals prefault exactly, KCL fails, join mismatch)
%   trips a loud FAIL = BLOCKED signal; never force the verdict.
%
%   TDD RED note: first committed draft asserted leg_GEN_kA==8.4141 with
%   tol 1e-9 (deliberately wrong: true value 8.41411669... differs by
%   ~1.7e-5) and FAILED as required; relaxed to the plan tol 1e-4 for GREEN.
T = t_case('test_phase5b_branch_audit');
root = ashuganj_root();

% --- Contributions row F1 LG LF360_GAT_OUT Ikpp (read-only) ---
Fc = fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_contributions.csv');
T = T.chk(exist(Fc, 'file') == 2, 'contributions CSV exists');
K = readtable(Fc, 'Delimiter', ',');
hit = strcmp(K.fault_type, 'LG') & strcmp(K.location, 'F1') ...
    & strcmp(K.caseID, 'LF360_GAT_OUT') & strcmp(K.stage, 'Ikpp') & K.m == 0.5;
T = T.chk(sum(hit) == 1, 'unique F1 LG OUT Ikpp m==0.5 contributions row');
r = K(hit, :);
leg = r.leg_GEN_kA;
total = r.Irms_kA;
T = T.chk(abs(leg - 8.4141) < 1e-4, 'leg_GEN_kA == 8.4141 (+/-1e-4)');
T = T.chk(all([r.kcl_seq, r.kcl_ph, r.kcl_earth] < 1e-9), 'KCL residuals < 1e-9');
T = T.chk(~isnan(leg) && ~isnan(total), 'leg and total present (never fabricated)');

% --- Prefault anchor GEN_Q 9.4757 kA from phase4_ct_data.csv (read-only) ---
Fa = fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_ct_data.csv');
T = T.chk(exist(Fa, 'file') == 2, 'ct_data CSV exists');
A = readtable(Fa, 'Delimiter', ',');
ahit = strcmp(A.fault_type, 'LG') & strcmp(A.location, 'F1') ...
    & strcmp(A.caseID, 'LF360_GAT_OUT') & strcmp(A.through_path, 'GEN_Q') ...
    & strcmp(A.stage, 'Ikpp') & strcmp(A.kind, 'RMS');
T = T.chk(sum(ahit) == 1, 'unique GEN_Q Ikpp RMS anchor row');
ar = A(ahit, :);
anchor = ar.FL_anchor_kA;
T = T.chk(abs(anchor - 9.4757) < 1e-3, 'FL_anchor GEN_Q 9.4757 kA');
T = T.chk(abs(ar.primary_kA - leg) < 1e-9, 'ct_data primary_kA equals contributions leg (same through current)');

% --- Evidence rule: NOT pure prefault AND NOT net fault current ---
rel = abs(leg - anchor) / anchor;
T = T.chk(rel > 0.05, 'NOT pure prefault: |leg-anchor|/anchor > 0.05 (redistribution present)');
T = T.chk(abs(leg - anchor) > 1e-9, 'leg differs from prefault exactly (never forced equal)');
legover = leg / total;
T = T.chk(legover > 100, 'NOT net fault current: leg/total > 100');
T = T.chk(abs(leg - total) > 1e-9, 'leg differs from net fault current exactly');

% --- Semantic verdict string ---
if rel > 0.05 && legover > 100
    verdict = 'branch-through-current-magnitude';
else
    verdict = 'BLOCKED-see-evidence';
end
T = T.chk(strcmp(verdict, 'branch-through-current-magnitude'), 'verdict branch-through-current-magnitude');

% --- Rename contract: v1 import (T3) join carries the same number ---
Ti = phase5_import(root);
irow = Ti(strcmp(Ti.fault_location, 'F1') & strcmp(Ti.fault_type, 'LG') ...
    & strcmp(Ti.caseID, 'LF360_GAT_OUT'), :);
T = T.chk(height(irow) == 1, 'import F1 LG OUT row present');
T = T.chk(abs(irow.leg_GEN_kA - leg) < 1e-9, 'import join carries same leg_GEN (T3 join identity)');
T = T.chk(strcmp(verdict, 'branch-through-current-magnitude'), 'rename contract: consumers must label it branch-through-current');

[np, nf] = T.done();
end
