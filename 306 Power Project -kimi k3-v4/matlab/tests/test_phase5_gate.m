function [np, nf] = test_phase5_gate()
%TEST_PHASE5_GATE  Phase-5 Task 19 quality-gate tests (TDD).
%   Locks interface G = phase5_gate() / G = phase5_gate(ov):
%   17-predicate read-only consumer of results/phase5_protection/ +
%   PHASE5_FINAL_REPORT.md + results/phase4_fault/production/ (modifies
%   nothing); prints a checklist; errors phase5_gate-prefixed on any fail.
%   Optional struct ov overrides shipped tables/report text in-memory only
%   (negative-path injection); ov.noThrow=true returns G without erroring.
%   G struct fields: .n (17), .ids, .pass (logical row), .note (cellstr),
%   .npas.
T = t_case('test_phase5_gate');

% --- Live gate on shipped outputs passes 17/17 ---
G = phase5_gate();
T = T.chk(isstruct(G) && G.n == 17, 'gate returns struct with n=17 predicates');
T = T.chk(all(G.pass), 'live gate passes all 17 predicates on shipped outputs');
T = T.chk(G.npass == 17, 'live gate npass==17');

% --- Predicate table shape locked ---
T = T.chk(numel(G.ids) == 17 && numel(G.note) == 17, 'ids/notes cover 17 predicates');
T = T.chk(any(strcmp(G.ids, 'regression')) && any(strcmp(G.ids, 'report-match')) ...
    && any(strcmp(G.ids, 'no-Phase3/4-change')), 'key predicate ids present');

% --- Negative path 1: forged PASS verdict in duty breaks rating-provenance ---
root = ashuganj_root();
Bd = readtable(fullfile(root, 'results', 'phase5_protection', ...
    'phase5_breaker_duty.csv'), 'Delimiter', ',');
isNote = strcmp(Bd.verdict, 'NOTE');
kBad = find(~isNote, 1, 'first');
Bd.verdict{kBad} = 'PASS';
ov = struct('duty', Bd, 'noThrow', true);
Gn = phase5_gate(ov);
hit = strcmp(Gn.ids, 'rating-provenance');
T = T.chk(~Gn.pass(hit), 'synthetic duty PASS fails rating-provenance predicate');
T = T.chk(Gn.npass < 17, 'synthetic duty PASS reduces npass below 17');
try
    phase5_gate(struct('duty', Bd));
    T = T.chk(false, 'throwing gate must error on synthetic duty PASS');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5_gate', 11), ...
        'gate failure error is phase5_gate-prefixed');
end

% --- Negative path 2: dropped matrix row breaks matrix-complete ---
Md = readtable(fullfile(root, 'results', 'phase5_protection', ...
    'phase5_coordination_matrix.csv'), 'Delimiter', ',');
ov2 = struct('coordMatrix', Md(1:end - 1, :), 'noThrow', true);
Gn2 = phase5_gate(ov2);
hit2 = strcmp(Gn2.ids, 'matrix-complete');
T = T.chk(~Gn2.pass(hit2), '95-row matrix fails matrix-complete predicate');
try
    phase5_gate(struct('coordMatrix', Md(1:end - 1, :)));
    T = T.chk(false, 'throwing gate must error on 95-row matrix');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5_gate', 11), ...
        'matrix failure error is phase5_gate-prefixed');
end

% --- Negative path 3: tampered regression value breaks regression ---
Fd = readtable(fullfile(root, 'results', 'phase5_protection', ...
    'phase5_fault_inputs.csv'), 'Delimiter', ',');
rF3 = strcmp(Fd.fault_location, 'F3') & strcmp(Fd.fault_type, 'LLL') ...
    & strcmp(Fd.caseID, 'LF360_GAT_OUT');
Fd.I_primary_kA(rF3) = Fd.I_primary_kA(rF3) + 1.0;
Gn3 = phase5_gate(struct('faultInputs', Fd, 'noThrow', true));
T = T.chk(~Gn3.pass(strcmp(Gn3.ids, 'regression')), ...
    'shifted F3 LLL value fails regression predicate');

[np, nf] = T.done();
end
