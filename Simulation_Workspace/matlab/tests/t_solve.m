function [LF, D, C, info] = t_solve(caseID)
%T_SOLVE  Build a case from scratch and solve its load flow. Test helper.
%
%   [LF, D, C, info] = T_SOLVE('LF1')
%
%   REBUILD, ALWAYS
%   ---------------
%   power_loadflow('solve') does not merely return a solution, it WRITES the
%   solution back into the blocks: source Voltage and PhaseAngle and load
%   NominalVoltage all come back multiplied by the solved per-unit values
%   (measured in matlab/env/probe_mutation.m). Solving twice in a row therefore
%   solves a slightly different model the second time. Every solve in the test
%   suite and in the studies is preceded by a fresh build for that reason, and
%   the build is silent, un-backed-up and unsaved so that running tests can
%   never touch the deliverable .slx.
%
%   After the 50 Hz fix the solution is repeatable to seven figures across fresh
%   builds, which is what makes the tests below meaningful rather than noisy.

D  = ashuganj_master_data();
ci = find(strcmp({D.cases.ID}, caseID), 1);
assert(~isempty(ci), 't_solve: unknown case ''%s''.', caseID);
C  = D.cases(ci);

info = build_ashuganj_main(caseID, 'Quiet', true, 'Backup', false, 'Save', false);
LF   = power_loadflow(info.model, 'solve');
end
