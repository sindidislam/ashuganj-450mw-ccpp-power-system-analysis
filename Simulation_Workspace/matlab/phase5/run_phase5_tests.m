function [NP, NF] = run_phase5_tests()
%RUN_PHASE5_TESTS  Phase-5 test runner (Phase-5 Task 16).
%   [NP, NF] = RUN_PHASE5_TESTS() runs every matlab/tests/test_phase5_*.m
%   suite (discovered via the test_phase5_ct anchor on the path, so gap
%   suites are picked up without runner edits) plus the 16-leg
%   phase5_validate() engine (R0 Phase-4 regression + V1..V15), accumulates
%   passed/failed counts (each validation leg counts one check), and prints
%   'phase5_tests: NP passed, NF failed'.
%   A suite that errors counts one failure and the runner continues, so one
%   broken suite never hides the rest; the error text stays loud.
%   All errors are 'phase5'-prefixed.
if nargin ~= 0
    error('phase5_tests:args', 'usage: [NP, NF] = run_phase5_tests().');
end
anchor = which('test_phase5_ct');
if isempty(anchor)
    error('phase5_tests:path', 'test_phase5_ct not on path (run with addpath(genpath(''matlab''))).');
end
tdir = fileparts(anchor);
list = dir(fullfile(tdir, 'test_phase5_*.m'));
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
    V = phase5_validate();
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
    fprintf('  ERROR phase5_validate: %s (%s)\n', ME.message, ME.identifier);
end
fprintf('phase5_tests: %d passed, %d failed\n', NP, NF);
end
