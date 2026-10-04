function [np, nf] = run_phase4_tests()
%RUN_PHASE4_TESTS  Phase-4 runner over all test_phase4_*.m files.
%
%   [np, nf] = RUN_PHASE4_TESTS() discovers the fourteen test_phase4_*.m
%   files (dir('test_phase4_*.m') in matlab/tests/, resolved relatively via
%   fileparts(mfilename): this runner lives in matlab/phase4/, tests in
%   matlab/tests/) and runs each with try/catch per file plus error
%   capture. Summary print mirrors run_all_tests shape. Separate function;
%   run_all_tests.m is never edited. Asserts nothing itself; returns
%   totals. Callers must have matlab/tests, matlab/phase4, matlab/data
%   and matlab/utilities on path.

here = fileparts(mfilename('fullpath'));
testDir = fullfile(fileparts(here), 'tests');
d = dir(fullfile(testDir, 'test_phase4_*.m'));
list = cell(1, numel(d));
for k = 1:numel(d)
    [~, nm, ~] = fileparts(d(k).name);
    list{k} = nm;
end
list = sort(list);

fprintf('\n');
fprintf('########################################################################\n');
fprintf('#  PHASE-4 FAULT ANALYSIS - TEST RUNNER                                #\n');
fprintf('#  %d test files\n', numel(list));
fprintf('########################################################################\n');

np = 0; nf = 0;
summary = struct([]);
for i = 1:numel(list)
    name = list{i};
    t0 = tic;
    try
        [p, f] = feval(name);
        err = '';
    catch ME
        p = 0; f = 1;
        err = ME.message;
        fprintf('\n*** %s ERRORED: %s\n', name, ME.message);
        for s = 1:min(4, numel(ME.stack))
            fprintf('      at %s line %d\n', ME.stack(s).name, ME.stack(s).line);
        end
    end
    np = np + p; nf = nf + f;
    summary(i).name = name;
    summary(i).pass = p;
    summary(i).fail = f;
    summary(i).secs = toc(t0);
    summary(i).err  = err;
end

fprintf('\n');
fprintf('########################################################################\n');
fprintf('#  SUMMARY                                                             #\n');
fprintf('########################################################################\n');
for i = 1:numel(summary)
    s = summary(i);
    if s.fail == 0, mark = 'PASS'; else, mark = 'FAIL'; end
    fprintf('  %-4s  %-34s %4d passed  %3d failed  %6.1f s%s\n', ...
        mark, s.name, s.pass, s.fail, s.secs, tern(isempty(s.err), '', '  [ERRORED]'));
end
fprintf('  %s\n', repmat('-', 1, 68));
fprintf('  TOTAL %-34s %4d passed  %3d failed  %6.1f s\n', '', np, nf, sum([summary.secs]));
if nf == 0
    fprintf('\n  ALL CHECKS PASSED.\n\n');
else
    fprintf('\n  %d CHECK(S) FAILED - the model is NOT validated.\n\n', nf);
end
end

% =====================================================================
function s = tern(c, a, b)
if c, s = a; else, s = b; end
end
