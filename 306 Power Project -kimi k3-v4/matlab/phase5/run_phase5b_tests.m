function [NP, NF] = run_phase5b_tests(varargin)
%RUN_PHASE5B_TESTS  Phase-5b test runner (Phase-5b Task C12).
%   [NP, NF] = RUN_PHASE5B_TESTS() runs every matlab/tests/test_phase5b_*.m
%   suite (discovered via the test_phase5b_ledger anchor on the path, so gap
%   suites are picked up without runner edits) plus the 14-leg
%   phase5b_validate() engine (R0 Phase-4 regression + B01..B13), accumulates
%   passed/failed counts (each validation leg counts one check), and prints
%   'phase5b_tests: NP passed, NF failed'.
%   A suite that errors counts one failure and the runner continues, so one
%   broken suite never hides the rest; the error text stays loud.
%   The frozen v1 runner is never called or modified (see plan global
%   constraints).
%   All errors raised here are 'phase5b'-prefixed.
if nargin ~= 0
    error('phase5b_tests:args', 'usage: [NP, NF] = run_phase5b_tests().');
end
anchor = which('test_phase5b_ledger');
if isempty(anchor)
    error('phase5b_tests:path', 'test_phase5b_ledger not on path (run with addpath(genpath(''matlab''))).');
end
tdir = fileparts(anchor);
list = dir(fullfile(tdir, 'test_phase5b_*.m'));
NP = 0; NF = 0;
for k = 1:numel(list)
    [~, name] = fileparts(list(k).name);
    try
        [np, nf] = feval(name);
        NP = NP + np; NF = NF + nf;
    catch ME
        NF = NF + 1;
        fprintf('  ERROR %s: %s (%s)\n', name, ME.message, ME.identifier);
    end
end
try
    V = phase5b_validate();
    for k = 1:numel(V.legs)
        if V.legs(k).pass
            NP = NP + 1;
        else
            NF = NF + 1;
        end
        if V.legs(k).pass
            st = 'PASS';
        else
            st = 'FAIL';
        end
        fprintf('  %s %s residual=%.6g note=%s\n', st, V.legs(k).id, V.legs(k).residual, V.legs(k).note);
    end
catch ME
    NF = NF + 1;
    fprintf('  ERROR phase5b_validate: %s (%s)\n', ME.message, ME.identifier);
end
fprintf('phase5b_tests: %d passed, %d failed\n', NP, NF);
end
