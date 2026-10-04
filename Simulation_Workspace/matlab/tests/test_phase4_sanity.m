function [np, nf] = test_phase4_sanity()
%TEST_PHASE4_SANITY  Sanity module checks: notes plus gates where safe.
%
%   S1 (F3 LLL vs 50 kA estimate) and S2 (F1 LG vs 7.25 A hand estimate)
%   are NOTE-only comparisons with wide sanity bands: they detect absurdity,
%   they do not tune physics and are never presented as field-performance
%   proof. S3/S5/S6 are gates and must all PASS.

T = t_case('test_phase4_sanity');
S = phase4_sanity();

T = T.chk(isstruct(S) && numel(S) >= 6, 'sanity table has at least S1-S6 rows');
T = T.chk(all(isfield(S, {'check','model_kA','value','reference','ratio_or_note','verdict','note'})), ...
    'every row carries check/model_kA/value/reference/ratio_or_note/verdict/note');

% Every row: non-empty check/reference text, verdict one of PASS/FAIL/NOTE.
okText = true;
okVerd = true;
for k = 1:numel(S)
    okText = okText && ischar(S(k).check) && ~isempty(strtrim(S(k).check)) ...
        && ischar(S(k).reference) && ~isempty(strtrim(S(k).reference)) ...
        && ischar(S(k).note) && ~isempty(strtrim(S(k).note));
    okVerd = okVerd && ischar(S(k).verdict) && ...
        any(strcmp(S(k).verdict, {'PASS','FAIL','NOTE'}));
end
T = T.chk(okText, 'every row has non-empty check/reference/note text');
T = T.chk(okVerd, 'no NaN/empty verdicts: every verdict is PASS/FAIL/NOTE');

% S1: F3 LLL OUT vs 50 kA estimate, wide sanity band, NOTE-only.
i1 = find(strcmp({S.check}, 'S1:F3LLL-vs-50kA'), 1);
T = T.chk(~isempty(i1), 'S1 row present');
T = T.chk(strcmp(S(i1).verdict, 'NOTE'), 'S1 is NOTE-only, never a gate');
r1 = S(i1).ratio_or_note;
T = T.chk(isfinite(r1) && r1 >= 0.8 && r1 <= 1.2, 'S1 ratio in wide sanity band [0.8,1.2]');

% S2: F1 LG OUT vs 7.25 A hand estimate, wide sanity band, NOTE-only.
i2 = find(strcmp({S.check}, 'S2:F1LG-vs-7.25A'), 1);
T = T.chk(~isempty(i2), 'S2 row present');
T = T.chk(strcmp(S(i2).verdict, 'NOTE'), 'S2 is NOTE-only, never a gate');
r2 = S(i2).ratio_or_note;
T = T.chk(isfinite(r2) && r2 >= 0.5 && r2 <= 2.0, 'S2 ratio in wide sanity band [0.5,2.0]');

% Gates: every PASS/FAIL row must PASS.
isGate = strcmp({S.verdict}, 'PASS') | strcmp({S.verdict}, 'FAIL');
T = T.chk(any(isGate), 'gate rows present');
T = T.chk(all(strcmp({S(isGate).verdict}, 'PASS')), 'all gates PASS');

% Spot-check gate families exist.
T = T.chk(any(strncmp({S.check}, 'S3:', 3)), 'S3 LLL-gt-LL rows present');
T = T.chk(any(strncmp({S.check}, 'S4:', 3)), 'S4 LLG-regime rows present');
T = T.chk(any(strncmp({S.check}, 'S5:', 3)), 'S5 F4-midpoint rows present');
T = T.chk(any(strncmp({S.check}, 'S6:', 3)), 'S6 no-impossible row present');

[np, nf] = T.done();
end
