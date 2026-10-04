function S = phase4_sanity()
%PHASE4_SANITY  Practical sanity checks with notes, gates where safe.
%
%   S = PHASE4_SANITY() runs a handful of base bolted solves through the
%   PHASE4_SOLVE entry point (never reimplemented math) and returns one
%   struct-array row per check with fields check, model_kA, value,
%   reference, ratio_or_note, verdict ('PASS'/'FAIL'/'NOTE'), note.
%
%   Base run definition: ds 'P', XoR_P 15, stage 'Ikpp', Zf 0 ohm, default
%   options except F4 fractional distance m where stated. Cases OUT and IN
%   are the LF360 pair. Governing Ik per type mirrors the ip convention in
%   the solver: LLL |I1|, LG |Ia|, LL/LLG max(|Ib|,|Ic|), all INTO fault.
%
%   kA conversion: study-pu times 100/(sqrt(3)*Vlevel) with Vlevel 22 kV
%   for F1/F2 and 230 kV otherwise (100 MVA study base).
%
%   S1 (F3 LLL vs 50 kA estimate) and S2 (F1 LG vs 7.25 A hand estimate)
%   are NOTE-only: the references are estimates, not measurements, and the
%   model includes plant infeed, so equality is NOT expected. They detect
%   absurdity; they are never presented as field-performance proof.
%   S3/S5/S6 are gates (FAIL on violation); S4 reports NOTE-only bounds.

S = struct('check', {}, 'model_kA', {}, 'value', {}, ...
    'reference', {}, 'ratio_or_note', {}, 'verdict', {}, 'note', {});
% Every base run feeding the table, for the S6 no-impossible gate.
allIk = [];  % governing Ik in study-pu, INTO fault
allIp = [];  % peak current in study-pu

% ---- S1: F3 LLL OUT vs 50 kA estimate (NOTE-only) ----
F = solve1('LF360_GAT_OUT', 'F3', 'LLL', 0.5);
ik1 = abs(F.I1);
m1 = ik1 * kBase('F3');
S(end+1) = mkRow('S1:F3LLL-vs-50kA', m1, m1, ...
    'Siemens-estimated 50 kA infeed (estimate, not measurement)', m1/50, ...
    'NOTE', ['NOTE-only: estimate is not a measurement; model includes ' ...
    'plant infeed so equality is NOT expected; reported ratio only. ' ...
    'Not field-performance proof.']);

% ---- S2: F1 LG OUT vs 7.25 A hand estimate (NOTE-only) ----
G = solve1('LF360_GAT_OUT', 'F1', 'LG', 0.5);
ia2 = abs(G.Ia);
m2A = ia2 * kBase('F1') * 1000;  % kA -> A for the ampere-scale reference
S(end+1) = mkRow('S2:F1LG-vs-7.25A', ia2 * kBase('F1'), m2A, ...
    'NER hand estimate 7.25 A (Vph/3ZN with 3ZN = 5252.32)', m2A/7.25, ...
    'NOTE', ['NOTE-only: hand estimate neglects series zero-sequence ' ...
    'reactance, assumes prefault voltage equals phase voltage, and ' ...
    'simplifies the neutral-earthing representation; model carries the ' ...
    'full sequence networks so equality is NOT expected; reported ratio ' ...
    'only. Not field-performance proof.']);

% ---- S3/S4 grid: locs F1/F3/F5 x OUT/IN x types LLL/LG/LL/LLG ----
locs = {'F1', 'F3', 'F5'};
cases = {'LF360_GAT_OUT', 'LF360_GAT_IN'};
tags = {'OUT', 'IN'};
types = {'LLL', 'LG', 'LL', 'LLG'};
for li = 1:numel(locs)
    for ci = 1:numel(cases)
        ikT = zeros(1, numel(types));
        for ti = 1:numel(types)
            H = solve1(cases{ci}, locs{li}, types{ti}, 0.5);
            ikT(ti) = govIk(H, types{ti});
        end
        ikKA = ikT * kBase(locs{li});
        % S3 gate: Ik(LLL) > Ik(LL) at same loc-case.
        r3 = ikKA(1) / ikKA(3);
        v3 = 'PASS';
        if ~(ikKA(1) > ikKA(3)), v3 = 'FAIL'; end
        S(end+1) = mkRow(sprintf('S3:%s-%s-LLL-gt-LL', locs{li}, tags{ci}), ...
            ikKA(1), ikKA(3), ...
            'Gate: Ik(LLL) exceeds Ik(LL) at same loc-case (bolted, Ikpp)', ...
            r3, v3, sprintf('Gate: LLL %.4f kA vs LL %.4f kA.', ikKA(1), ikKA(3)));
        % S4 NOTE-only bounds: min/max across types at same loc-case.
        S(end+1) = mkRow(sprintf('S4:%s-%s-LLG-regime', locs{li}, tags{ci}), ...
            max(ikKA), min(ikKA), ...
            'Bounds: min/max Ik across LLL/LG/LL/LLG at same loc-case (bolted, Ikpp); NOTE-only, no threshold', ...
            NaN, 'NOTE', sprintf(['NOTE-only bounds across types: min %.4f kA, ' ...
            'max %.4f kA. No threshold applied.'], min(ikKA), max(ikKA)));
    end
end

% ---- S5: F4 midpoint vs end-mean per type OUT (gate, 10%) ----
for ti = 1:numel(types)
    Fm0 = solve1('LF360_GAT_OUT', 'F4', types{ti}, 0);
    Fm5 = solve1('LF360_GAT_OUT', 'F4', types{ti}, 0.5);
    Fm1 = solve1('LF360_GAT_OUT', 'F4', types{ti}, 1);
    kb = kBase('F4');
    i0 = govIk(Fm0, types{ti}) * kb;
    i5 = govIk(Fm5, types{ti}) * kb;
    i1 = govIk(Fm1, types{ti}) * kb;
    mu = (i0 + i1) / 2;
    dev = abs(i5 - mu) / mu;
    v5 = 'PASS';
    if ~(dev <= 0.10), v5 = 'FAIL'; end
    S(end+1) = mkRow(sprintf('S5:F4-%s-midpoint', types{ti}), i5, mu, ...
        'Gate: F4 midpoint Ik within 10% of mean of end solves (bolted, Ikpp, OUT)', ...
        dev, v5, sprintf('Gate: mid %.4f kA vs end-mean %.4f kA, dev %.4f.', i5, mu, dev));
end

% ---- S6: no-impossible across every run above (gate) ----
nViol = sum(~(isfinite(allIk) & allIk > 0)) + sum(~(isfinite(allIp) & allIp > 0));
nRun = numel(allIk);
v6 = 'PASS';
if ~(nViol == 0), v6 = 'FAIL'; end
S(end+1) = mkRow('S6:no-impossible', nRun, nRun, ...
    sprintf('Gate: all %d run Ik and ip finite and > 0', nRun), nViol, v6, ...
    sprintf('Gate: %d runs checked, %d violations.', nRun, nViol));

% =====================================================================
    function F = solve1(caseID, loc, type, m)
        if strcmp(loc, 'F4')
            F = phase4_solve(caseID, 'P', 15, loc, type, 'Ikpp', 0, struct('m', m));
        else
            F = phase4_solve(caseID, 'P', 15, loc, type, 'Ikpp', 0);
        end
        allIk(end+1) = govIk(F, type);
        allIp(end+1) = F.ip;
    end
end

% =====================================================================
function ik = govIk(F, type)
%GOVIK  Governing fault-current magnitude in study-pu, INTO fault.
switch type
    case 'LLL'
        ik = abs(F.I1);
    case 'LG'
        ik = abs(F.Ia);
    otherwise  % LL / LLG
        ik = max(abs(F.Ib), abs(F.Ic));
end
end

function kb = kBase(loc)
%KBASE  Study-pu to kA factor on the 100 MVA base: 100/(sqrt(3)*Vlevel)
%   with Vlevel 22 kV for F1/F2, else 230 kV.
if any(strcmp(loc, {'F1', 'F2'}))
    Vlvl = 22;
else
    Vlvl = 230;
end
kb = 100 / (sqrt(3) * Vlvl);
end

function R = mkRow(check, model_kA, value, reference, ratio_or_note, verdict, note)
R = struct('check', check, 'model_kA', model_kA, 'value', value, ...
    'reference', reference, 'ratio_or_note', ratio_or_note, ...
    'verdict', verdict, 'note', note);
end
