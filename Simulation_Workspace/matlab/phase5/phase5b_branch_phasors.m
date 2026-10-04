function B = phase5b_branch_phasors(T40)
%PHASE5B_BRANCH_PHASORS  Identity-gated branch-phasor recompute for LL/LLG B/C (Phase-5b Task C6b).
%   B = PHASE5B_BRANCH_PHASORS(T40) where T40 is the phase5_import 40-row
%   backbone. The frozen Phase-4 writer stores leg magnitudes as |Ia| ONLY
%   (phase4_handoff legRow: row(k) = abs(C.legs.(tags{k}).Ia)*Ibase), while
%   LL/LLG faults involve phases B/C -- so Ia evidence is wrong-phase for
%   B/C overcurrent elements. The leg phasors (Ia/Ib/Ic complex per leg)
%   exist inside phase4_contrib but were never written to CSV. This module
%   recomputes them.
%
%   For each (caseID,location,fault_type) backbone row, the module calls the
%   FROZEN phase4_contrib read-only (never modified):
%     C = phase4_contrib(caseID, 'P', 15, loc, type, 'Ikpp', [], 'bolted')
%   Backbone opts discovery (from run_phase4_matrix legDesc plus
%   run_phase4_production merge order, modifying nothing):
%     - ds 'P', XoR_P 15: legDesc base defaults (base = LF360_GAT_OUT,
%       GAT-IN = LF360_GAT_IN; both keep ds P, XoR 15; each OFAT leg varies
%       exactly one factor, so backbone rows are base-opts rows).
%     - stage 'Ikpp', t_break []: backbone segment covers {Ikpp,ip} and the
%       import keeps stage Ikpp; per-leg ip has no table
%       (phase4_contrib:ipNoTable), so Ikpp is the only leg-bearing stage;
%       t_break is ignored for non-Ib stages (handoff passes [] too).
%     - ZfMode 'bolted': legDesc base ZfMode (Zf_ohm 0).
%     - m = 0.5: phase4_solve default (matrix F4 subset guard) matching the
%       import F4-primary-m==0.5 guard.
%     - caseID/loc/type come from the T40 row itself (F1/F2 labels kept
%       distinct though values are identical).
%
%   Magnitudes are in amperes at fault voltage level with the SAME Ibase
%   convention as the frozen handoff writer: Ibase = 100/(sqrt(3)*Vlevel) kA
%   with Vlevel from loc (F1/F2 22 kV, F3/F4/F5 230 kV); A = |Ipu|*Ibase*1000.
%   (The handoff applies the single fault-level Ibase to every leg of the
%   row; this module does exactly the same, which is what makes the identity
%   gate below satisfiable. Per-leg own-voltage bases are NOT used.)
%
%   IDENTITY GATE (binding): recomputed |Ia| per (row,leg) must equal the
%   production contributions CSV leg value (results/phase4_fault/production/
%   phase4_contributions.csv, first stable row per (caseID,location,
%   fault_type) among stage Ikpp & m==0.5 -- the same backbone-first
%   dedup the phase5_import backbone relies on) within 1e-6 relative
%   (rel = |rec-ref|/max(|ref|,1e-30), ref in kA). ANY failure -- numeric
%   mismatch, missing production reference row, missing leg column, a finite
%   production leg with no recomputed counterpart (omission), or a mismatch
%   against the T40-carried import leg value (auxiliary cross-check under the
%   same gate: T40 legs ARE the import join of the CSV values, pinned by the
%   C5 branch audit, so both references must agree) -- errors
%   error('phase5b_branch_phasors:identity', 'BLOCKED ...') listing the first
%   failing rows. Loudly BLOCKED, no fallback values, no tolerance widening.
%   Production stops on an identity failure rather than fabricating a current.
%
%   Faulted-phase branch magnitude per type (B/C evidence for C8):
%     LLL -> max(|Ia|,|Ib|,|Ic|), phase_basis 'maxABC';
%     LG  -> |Ia| (A-phase faulted), phase_basis 'Ia';
%     LL, LLG -> max(|Ib|,|Ic|) (B/C faulted), phase_basis 'maxBC'.
%
%   Output B is a table with locked columns (this order):
%     caseID, location, fault_type, leg, Ia_A, Ib_A, Ic_A,
%     Ibranch_faulted_A, phase_basis, I0_A.
%   I0_A is abs(Ia+Ib+Ic)/3 from COMPLEX phasors, on the same fault base.
%   One row per (backbone row x present contrib leg). leg names are the raw
%   phase4_contrib field names (GEN, GSUT_LV, GSUT_HV, UAT, GAT_HV, GAT_LV,
%   LINE_total, LINE_B1, LINE_B2, GRID, NER_earth); absent legs (GAT iff OUT,
%   NER_earth unless LG/LLG, LINE_B1/B2 unless F4) are omitted, never
%   zero-filled. Subset inputs (fewer rows, same columns) are accepted for
%   testing; production use is the full 40-row backbone.
%
%   All errors are 'phase5b'-prefixed. No existing file is modified; no
%   re-solve of Phase-4 defaults is altered (phase4_contrib is called, never
%   edited).
if nargin ~= 1
    error('phase5b_branch_phasors:args', ...
        'usage: B = phase5b_branch_phasors(T40).');
end
if ~istable(T40) || height(T40) < 1
    error('phase5b_branch_phasors:schema', ...
        'T40 must be a non-empty table (phase5_import backbone).');
end
if any(strcmp(T40.Properties.VariableNames, 'fault_location'))
    locCol = 'fault_location';
elseif any(strcmp(T40.Properties.VariableNames, 'location'))
    locCol = 'location';
else
    error('phase5b_branch_phasors:schema', ...
        'T40 missing location column (fault_location/location).');
end
need = {'fault_type', 'caseID'};
for k = 1:numel(need)
    if ~any(strcmp(T40.Properties.VariableNames, need{k}))
        error('phase5b_branch_phasors:schema', ...
            'T40 missing required column %s.', need{k});
    end
end
n = height(T40);
locs = cell(n, 1);
types = cell(n, 1);
cases = cell(n, 1);
for i = 1:n
    lo = T40.(locCol){i};
    ty = T40.fault_type{i};
    ca = T40.caseID{i};
    if isstring(lo) && isscalar(lo), lo = char(lo); end
    if isstring(ty) && isscalar(ty), ty = char(ty); end
    if isstring(ca) && isscalar(ca), ca = char(ca); end
    if ~ischar(lo) || ~any(strcmp(lo, {'F1', 'F2', 'F3', 'F4', 'F5'}))
        error('phase5b_branch_phasors:schema', ...
            'T40 row %d: unknown location (use F1/F2/F3/F4/F5).', i);
    end
    if ~ischar(ty) || ~any(strcmp(ty, {'LLL', 'LG', 'LL', 'LLG'}))
        error('phase5b_branch_phasors:schema', ...
            'T40 row %d: unknown fault_type (use LLL/LG/LL/LLG).', i);
    end
    if ~ischar(ca) || isempty(strtrim(ca))
        error('phase5b_branch_phasors:schema', ...
            'T40 row %d: caseID must be non-empty char.', i);
    end
    locs{i} = lo;
    types{i} = ty;
    cases{i} = strtrim(ca);
end

% --- Production contributions reference (read-only; backbone-first dedup) ---
root = ashuganj_root();
Fc = fullfile(root, 'results', 'phase4_fault', 'production', ...
    'phase4_contributions.csv');
if exist(Fc, 'file') ~= 2
    error('phase5b_branch_phasors:identity', ...
        ['BLOCKED: production contributions CSV missing: ' Fc]);
end
K = readtable(Fc);
Kb = K(strcmp(K.stage, 'Ikpp') & K.m == 0.5, :);
kkeys = strcat(Kb.caseID, '|', Kb.location, '|', Kb.fault_type);
[~, ika] = unique(kkeys, 'stable');
Kb1 = Kb(ika, :);

% --- Recompute + gate ---
outCase = cell(0, 1);
outLoc = cell(0, 1);
outType = cell(0, 1);
outLeg = cell(0, 1);
outIa = zeros(0, 1);
outIb = zeros(0, 1);
outIc = zeros(0, 1);
outBr = zeros(0, 1);
outBasis = cell(0, 1);
outI0 = zeros(0, 1);
fail = {};
for i = 1:n
    lo = locs{i};
    ty = types{i};
    ca = cases{i};
    if any(strcmp(lo, {'F1', 'F2'}))
        Vlevel = 22;
    else
        Vlevel = 230;
    end
    Ibase = 100 / (sqrt(3) * Vlevel);  % kA, handoff convention
    C = phase4_contrib(ca, 'P', 15, lo, ty, 'Ikpp', [], 'bolted');
    hit = strcmp(Kb1.caseID, ca) & strcmp(Kb1.location, lo) ...
        & strcmp(Kb1.fault_type, ty);
    if sum(hit) ~= 1
        fail{end+1} = sprintf('row %d %s %s %s: %d production reference rows (want 1)', ...
            i, ca, lo, ty, sum(hit)); %#ok<AGROW>
        continue;
    end
    ref = Kb1(find(hit, 1, 'first'), :);
    legs = fieldnames(C.legs);
    emitted = cell(0, 1);
    for q = 1:numel(legs)
        leg = legs{q};
        L = C.legs.(leg);
        aA = abs(L.Ia) * Ibase * 1000;
        bA = abs(L.Ib) * Ibase * 1000;
        cA = abs(L.Ic) * Ibase * 1000;
        switch ty
            case 'LLL'
                br = max([aA, bA, cA]);
                basis = 'maxABC';
            case 'LG'
                br = aA;
                basis = 'Ia';
            otherwise  % LL, LLG: B/C faulted
                br = max(bA, cA);
                basis = 'maxBC';
        end
        col = ['leg_' leg '_kA'];
        if ~any(strcmp(ref.Properties.VariableNames, col))
            fail{end+1} = sprintf('row %d %s %s %s leg %s: no production leg column %s', ...
                i, ca, lo, ty, leg, col); %#ok<AGROW>
            continue;
        end
        rv = ref.(col);
        if ~isfinite(rv)
            fail{end+1} = sprintf('row %d %s %s %s leg %s: production leg value not finite', ...
                i, ca, lo, ty, leg); %#ok<AGROW>
            continue;
        end
        recK = aA / 1000;
        if abs(recK - rv) / max(abs(rv), 1e-30) > 1e-6
            fail{end+1} = sprintf(['row %d %s %s %s leg %s: recomputed |Ia| %.12g kA vs ' ...
                'production %.12g kA (rel %.3g > 1e-6)'], ...
                i, ca, lo, ty, leg, recK, rv, ...
                abs(recK - rv) / max(abs(rv), 1e-30)); %#ok<AGROW>
            continue;
        end
        if any(strcmp(T40.Properties.VariableNames, col))
            tv = T40.(col)(i);  % leg columns are numeric (phase5_import join)
            if isfinite(tv) && abs(recK - tv) / max(abs(tv), 1e-30) > 1e-6
                fail{end+1} = sprintf(['row %d %s %s %s leg %s: recomputed |Ia| %.12g kA vs ' ...
                    'T40-carried %.12g kA (rel %.3g > 1e-6)'], ...
                    i, ca, lo, ty, leg, recK, tv, ...
                    abs(recK - tv) / max(abs(tv), 1e-30)); %#ok<AGROW>
                continue;
            end
        end
        outCase{end+1, 1} = ca; %#ok<AGROW>
        outLoc{end+1, 1} = lo; %#ok<AGROW>
        outType{end+1, 1} = ty; %#ok<AGROW>
        outLeg{end+1, 1} = leg; %#ok<AGROW>
        outIa(end+1, 1) = aA; %#ok<AGROW>
        outIb(end+1, 1) = bA; %#ok<AGROW>
        outIc(end+1, 1) = cA; %#ok<AGROW>
        outBr(end+1, 1) = br; %#ok<AGROW>
        outBasis{end+1, 1} = basis; %#ok<AGROW>
        outI0(end+1, 1) = abs(L.Ia + L.Ib + L.Ic)/3 * Ibase * 1000; %#ok<AGROW>
        emitted{end+1, 1} = leg; %#ok<AGROW>
    end
    % Omission guard: every finite production leg must have been emitted.
    vn = ref.Properties.VariableNames;
    for q = 1:numel(vn)
        tok = regexp(char(vn{q}), '^leg_(.+)_kA$', 'tokens', 'once');
        if isempty(tok)
            continue;
        end
        if isfinite(ref.(vn{q})) && ~any(strcmp(emitted, tok{1}))
            fail{end+1} = sprintf('row %d %s %s %s leg %s: finite production leg omitted', ...
                i, ca, lo, ty, tok{1}); %#ok<AGROW>
        end
    end
end
if ~isempty(fail)
    nshow = min(numel(fail), 10);
    error('phase5b_branch_phasors:identity', ...
        ['BLOCKED: identity gate failed on %d (row,leg) checks (tolerance 1e-6 relative, ' ...
         'no fallback values). First %d: %s'], ...
        numel(fail), nshow, strjoin(fail(1:nshow), ' | '));
end

B = table(outCase, outLoc, outType, outLeg, outIa, outIb, outIc, outBr, outBasis, outI0, ...
    'VariableNames', {'caseID', 'location', 'fault_type', 'leg', 'Ia_A', ...
    'Ib_A', 'Ic_A', 'Ibranch_faulted_A', 'phase_basis', 'I0_A'});
end
