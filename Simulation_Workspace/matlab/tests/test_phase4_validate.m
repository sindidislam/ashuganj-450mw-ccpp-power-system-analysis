function [np, nf] = test_phase4_validate()
T = t_case('test_phase4_validate');
V = phase4_validate('smoke_LF360_OUT_P15_F3_LLL');
T = T.eq(numel(V.legs), 27, '27 validation legs present');
T = T.chk(all([V.legs.pass]), 'smoke run passes all 27 legs');
T = T.chk(isfield(V,'tolsPrinted') && V.tolsPrinted, 'tolerances printed with checks');
[np, nf] = T.done();
end
