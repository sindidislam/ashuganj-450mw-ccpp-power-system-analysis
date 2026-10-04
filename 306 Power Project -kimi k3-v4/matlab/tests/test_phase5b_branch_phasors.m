function [np, nf] = test_phase5b_branch_phasors()
%TEST_PHASE5B_BRANCH_PHASORS  Phase-5b Task C6b identity-gated branch-phasor recompute.
%   Locked interface under test: B = phase5b_branch_phasors(T40) where T40 is
%   the phase5_import 40-row backbone. The module re-solves each
%   (caseID,location,fault_type) backbone row through the FROZEN
%   phase4_contrib (read-only: ds 'P', XoR_P 15, stage 'Ikpp', t_break [],
%   ZfMode 'bolted' -- backbone opts discovered from run_phase4_matrix
%   legDesc base/GAT-IN plus run_phase4_production backbone-first merge
%   order) and emits one table row per (backbone row x present leg) with
%   |Ia|,|Ib|,|Ic| in amperes (fault-level Ibase convention of the frozen
%   phase4_handoff legRow) plus the faulted-phase branch magnitude
%   Ibranch_faulted_A (LLL maxABC / LG Ia / LL-LLG maxBC) and phase_basis.
%
%   IDENTITY GATE (binding): recomputed |Ia| per (row,leg) must equal the
%   production contributions CSV leg value within 1e-6 relative; ANY failure
%   errors phase5b_branch_phasors:identity (BLOCKED, no fallback values, no
%   tolerance widening). Downstream C8 then uses NOT-DETERMINABLE for LL/LLG
%   B/C -- acceptable fallback.
%
%   Live-data properties asserted here (documented, all observed on the
%   frozen production data, never assumed):
%     - LL rows: max(|Ib|,|Ic|) >= |Ia| on every emitted leg row (B/C are the
%       faulted phases; stored |Ia| alone understates B/C elements, e.g.
%       F1 LL GEN |Ib| = 51.79 kA vs |Ia| = 8.32 kA).
%     - LLG rows: max(|Ib|,|Ic|) >= |Ia| on every emitted leg row (earth
%       carries part of the return, B/C still dominate per leg).
%     - NER_earth legs: |Ia| == |Ib| == |Ic| (I1 = I2 = 0 by construction).
%   If any of these ever stops holding on live data, the corresponding check
%   fails loudly (never silently relaxed).
%
%   TDD RED note: first run failed with undefined function
%   phase5b_branch_phasors as required; GREEN after module creation.
T = t_case('test_phase5b_branch_phasors');
root = ashuganj_root();

% --- Live T40 backbone (read-only import) ---
T40 = phase5_import(root);
T = T.chk(height(T40) == 40, 'T40 backbone has 40 rows (2x5x4)');

% --- Module call (identity gate runs inside; BLOCKED would error here) ---
B = phase5b_branch_phasors(T40);

% --- Locked output schema ---
want = {'caseID', 'location', 'fault_type', 'leg', 'Ia_A', 'Ib_A', 'Ic_A', ...
    'Ibranch_faulted_A', 'phase_basis', 'I0_A'};
T = T.chk(istable(B), 'B is a table');
T = T.chk(isequal(B.Properties.VariableNames, want), 'locked output columns in order');
T = T.chk(height(B) > height(T40), 'one row per (backbone row x leg): more rows than T40');
T = T.chk(all(ismember(B.phase_basis, {'Ia', 'maxBC', 'maxABC'})), ...
    'phase_basis vocabulary Ia/maxBC/maxABC');
T = T.chk(all(isfinite(B.Ia_A) & isfinite(B.Ib_A) & isfinite(B.Ic_A) ...
    & isfinite(B.Ibranch_faulted_A)), 'all branch magnitudes finite (never NaN-filled)');
T = T.chk(all(B.Ia_A >= 0 & B.Ib_A >= 0 & B.Ic_A >= 0 & B.Ibranch_faulted_A >= 0), ...
    'magnitudes non-negative');

% --- Every backbone key is covered, no invented keys ---
keysT40 = strcat(T40.caseID, '|', T40.fault_location, '|', T40.fault_type);
keysB = strcat(B.caseID, '|', B.location, '|', B.fault_type);
T = T.chk(all(ismember(keysB, keysT40)), 'no invented (case,loc,type) keys in B');
T = T.chk(all(ismember(keysT40, keysB)), 'every backbone key covered in B');

% --- Known-leg spot check: F1 LG OUT GEN (C5-pinned 8.4141 kA through current) ---
hit = strcmp(B.caseID, 'LF360_GAT_OUT') & strcmp(B.location, 'F1') ...
    & strcmp(B.fault_type, 'LG') & strcmp(B.leg, 'GEN');
T = T.chk(sum(hit) == 1, 'unique F1 LG OUT GEN branch row');
if sum(hit) == 1
    T = T.chk(abs(B.Ia_A(hit) - 8414.11669538933) / 8414.11669538933 < 1e-6, ...
        'F1 LG OUT GEN |Ia| 8414.12 A reproduces production leg (1e-6)');
    T = T.chk(abs(B.Ibranch_faulted_A(hit) - B.Ia_A(hit)) == 0, ...
        'LG faulted branch is |Ia| exactly');
    T = T.chk(strcmp(B.phase_basis(hit), 'Ia'), 'LG phase_basis Ia');
end

% --- Faulted-phase selection wiring per type ---
isLLL = strcmp(B.fault_type, 'LLL');
T = T.chk(all(B.Ibranch_faulted_A(isLLL) ...
    == max([B.Ia_A(isLLL), B.Ib_A(isLLL), B.Ic_A(isLLL)], [], 2)), ...
    'LLL faulted branch is max(|Ia|,|Ib|,|Ic|)');
T = T.chk(all(strcmp(B.phase_basis(isLLL), 'maxABC')), 'LLL phase_basis maxABC');
isLG = strcmp(B.fault_type, 'LG');
T = T.chk(all(B.Ibranch_faulted_A(isLG) == B.Ia_A(isLG)), ...
    'LG faulted branch is |Ia|');
T = T.chk(all(strcmp(B.phase_basis(isLG), 'Ia')), 'LG phase_basis Ia');
isLL = strcmp(B.fault_type, 'LL');
T = T.chk(all(B.Ibranch_faulted_A(isLL) ...
    == max([B.Ib_A(isLL), B.Ic_A(isLL)], [], 2)), ...
    'LL faulted branch is max(|Ib|,|Ic|)');
T = T.chk(all(strcmp(B.phase_basis(isLL), 'maxBC')), 'LL phase_basis maxBC');
isLLG = strcmp(B.fault_type, 'LLG');
T = T.chk(all(B.Ibranch_faulted_A(isLLG) ...
    == max([B.Ib_A(isLLG), B.Ic_A(isLLG)], [], 2)), ...
    'LLG faulted branch is max(|Ib|,|Ic|)');
T = T.chk(all(strcmp(B.phase_basis(isLLG), 'maxBC')), 'LLG phase_basis maxBC');

% --- Live-data property: faulted B/C magnitude >= unfaulted |Ia| (LL/LLG) ---
isBC = isLL | isLLG;
T = T.chk(sum(isBC) > 0, 'LL/LLG branch rows present for B/C property');
if any(isBC)
    gap = (B.Ibranch_faulted_A(isBC) - B.Ia_A(isBC)) ...
        ./ max(B.Ia_A(isBC), 1e-30);
    T = T.chk(all(gap >= -1e-9), 'LL/LLG max(B,C) >= |Ia| on every leg row (live data)');
    T = T.chk(any(gap > 1), 'LL/LLG B/C strictly exceeds |Ia| somewhere (wrong-phase Ia understates)');
end

% --- Live-data property: NER_earth legs carry I0 only (|Ia|==|Ib|==|Ic|) ---
isNER = strcmp(B.leg, 'NER_earth');
T = T.chk(sum(isNER) > 0, 'NER_earth branch rows present (LG/LLG)');
if any(isNER)
    tolNER = 1e-6 * max(B.Ibranch_faulted_A(isNER), 1);
    T = T.chk(all(abs(B.Ib_A(isNER) - B.Ia_A(isNER)) <= tolNER ...
        & abs(B.Ic_A(isNER) - B.Ia_A(isNER)) <= tolNER), ...
        'NER_earth |Ia|==|Ib|==|Ic| (I1=I2=0 series earth leg)');
end

% --- Spot values proving B/C content beyond stored |Ia| ---
gLL = strcmp(B.caseID, 'LF360_GAT_OUT') & strcmp(B.location, 'F1') ...
    & strcmp(B.fault_type, 'LL') & strcmp(B.leg, 'GEN');
T = T.chk(sum(gLL) == 1, 'unique F1 LL OUT GEN branch row');
if sum(gLL) == 1
    T = T.chk(abs(B.Ib_A(gLL) - 51787.332) / 51787.332 < 1e-6, ...
        'F1 LL OUT GEN |Ib| 51787.33 A (faulted-phase content, not stored anywhere)');
    T = T.chk(B.Ibranch_faulted_A(gLL) > 6 * B.Ia_A(gLL), ...
        'F1 LL OUT GEN faulted branch > 6x stored |Ia| (B/C evidence for C8)');
end

% --- Subset sanity: unperturbed 2-row call passes (perturbation is what trips) ---
Bsub = phase5b_branch_phasors(T40(1:2, :));
T = T.chk(istable(Bsub) && height(Bsub) > 2, 'unperturbed 2-row subset passes identity');

% --- BLOCKED path: synthetic shifted input must fail identity, never pass ---
Tshift = T40(1:2, :);
Tshift.leg_GEN_kA(1) = Tshift.leg_GEN_kA(1) * 1.01;
try
    phase5b_branch_phasors(Tshift);
    T = T.chk(false, 'shifted input BLOCKED (identity must fail, never silently pass)');
catch ME
    T = T.chk(strcmp(ME.identifier, 'phase5b_branch_phasors:identity'), ...
        'BLOCKED error carries phase5b_branch_phasors:identity');
    T = T.chk(~isempty(strfind(ME.message, 'BLOCKED')), 'BLOCKED message states BLOCKED');
end

% --- Errors phase5b-prefixed ---
try
    phase5b_branch_phasors();
    T = T.chk(false, 'no-args errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5b', 7), 'no-args error phase5b-prefixed');
end
try
    phase5b_branch_phasors(table());
    T = T.chk(false, 'empty table errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5b', 7), 'schema error phase5b-prefixed');
end
try
    Tbad = T40(1:2, :);
    Tbad.fault_type = {'XX'; 'LG'};
    phase5b_branch_phasors(Tbad);
    T = T.chk(false, 'bad fault_type errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5b', 7), 'vocabulary error phase5b-prefixed');
end

[np, nf] = T.done();
end
