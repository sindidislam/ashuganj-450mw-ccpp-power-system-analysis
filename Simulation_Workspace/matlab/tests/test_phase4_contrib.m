function [np, nf] = test_phase4_contrib()
T = t_case('test_phase4_contrib');
C = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0,'bolted');
T = T.chk(C.kcl_seq < 1e-6, 'per-sequence KCL closes');
T = T.chk(C.kcl_ph < 1e-6, 'per-phase KCL closes');
O = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0,'bolted');
T = T.chk(~isfield(O.legs,'GAT_HV'), 'GAT OUT leg absent, not zero-filled');
I = phase4_contrib('LF360_GAT_IN','P',15,'F3','LLL','Ikpp',0,'bolted');
T = T.chk(isfield(I.legs,'GAT_HV'), 'GAT IN leg present');
try, phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','ip',0,'bolted'); T = T.chk(false, 'per-leg ip forbidden');
catch ME, T = T.chk(true, 'per-leg ip forbidden'); end
[np, nf] = T.done();
end
