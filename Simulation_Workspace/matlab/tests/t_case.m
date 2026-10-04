function T = t_case(name)
%T_CASE  Minimal assertion recorder for the Ashuganj test suite.
%
%   T = T_CASE('test_name');
%   T = T.chk(condition, description);
%   T = T.eq (actual, expected, description);
%   T = T.near(actual, expected, tol, description);
%   T = T.isnan(value, description);      % for MISSING data: must stay NaN
%   [nPass, nFail] = T.done();
%
%   Deliberately hand-rolled rather than a matlab.unittest class. The point of
%   this suite is a readable audit trail printed into a log a human marker can
%   follow line by line, not a test-runner summary.
%
%   T.isnan exists because of the project's central rule. Missing parameters
%   must STAY missing without new source evidence: if GAT tertiary impedance gains a
%   number without a verified source, that is a test failure, not a fix.
%
%   T.isnan REJECTS an empty value. all(isnan([])) is true in MATLAB, so the
%   naive form would silently pass on a field that is absent from a given
%   struct-array element - the most important assertion in the suite would be
%   the easiest one to satisfy by accident. A MISSING parameter must be NaN,
%   present and explicit, never [].

T = struct();
T.name = name;
T.np   = 0;
T.nf   = 0;
T.msgs = {};

T.chk   = @(c, d)          rec(T, logical(c) && isscalar(c), d, '');
T.eq    = @(a, e, d)       rec(T, isequal(a, e), d, sprintf('got %s, expected %s', s(a), s(e)));
T.near  = @(a, e, tol, d)  rec(T, all(abs(a(:)-e(:)) <= tol), d, ...
                               sprintf('got %s, expected %s +/- %g', s(a), s(e), tol));
T.isnan = @(v, d)          rec(T, isnanx(v), d, sprintf('got %s, expected NaN', s(v)));
T.done  = @()              finish(T);

fprintf('\n--- %s %s\n', name, repmat('-', 1, max(0, 66-numel(name))));
end

% =====================================================================
function T = rec(T, ok, desc, detail)
if ok
    T.np = T.np + 1;
    fprintf('  PASS  %s\n', desc);
else
    T.nf = T.nf + 1;
    if isempty(detail)
        fprintf('  FAIL  %s\n', desc);
    else
        fprintf('  FAIL  %s   [%s]\n', desc, detail);
    end
    T.msgs{end+1} = desc;
end
% Rebind the closures so the updated counters are captured.
T.chk   = @(c, d)          rec(T, logical(c) && isscalar(c), d, '');
T.eq    = @(a, e, d)       rec(T, isequal(a, e), d, sprintf('got %s, expected %s', s(a), s(e)));
T.near  = @(a, e, tol, d)  rec(T, all(abs(a(:)-e(:)) <= tol), d, ...
                               sprintf('got %s, expected %s +/- %g', s(a), s(e), tol));
T.isnan = @(v, d)          rec(T, isnanx(v), d, sprintf('got %s, expected NaN', s(v)));
T.done  = @()              finish(T);
end

function [np, nf] = finish(T)
np = T.np; nf = T.nf;
if nf == 0
    fprintf('  => %s: %d passed, 0 failed\n', T.name, np);
else
    fprintf('  => %s: %d passed, %d FAILED\n', T.name, np, nf);
end
end

% =====================================================================
function ok = isnanx(v)
%ISNANX  Strict MISSING test: numeric, non-empty, and every element NaN.
%   all(isnan([])) is true, which would let an absent field pass the one
%   assertion in this suite that must never pass by accident.
ok = isnumeric(v) && ~isempty(v) && all(isnan(v(:)));
end

function out = s(v)
if ischar(v),        out = ['''' v ''''];
elseif islogical(v), out = mat2str(v);
elseif isnumeric(v), out = mat2str(v, 8);
elseif iscell(v),    out = sprintf('cell%s', mat2str(size(v)));
else,                out = ['<' class(v) '>'];
end
if numel(out) > 60, out = [out(1:57) '...']; end
end
