function [np, nf] = test_phase5_instantaneous()
%TEST_PHASE5_INSTANTANEOUS  Phase-5 Task 16 gap test for V6 (instantaneous / definite-time).
%   Pins the DT semantics that validation leg V6 depends on:
%   phase5_curve_dt(I>=Is)->tdef, I<Is->Inf, I==Is trips (definite-time
%   equality); phase5_time DT branch delegates identically; phase5_curve
%   with family 'DT' errors 'phase5_curve:family' routing to phase5_curve_dt;
%   the default inverse path never returns an instantaneous time (no Iinst
%   override: F3 LLL anchor reproduces the SI closed form, >> 0.05 s).
%   All errors phase5-prefixed.
T = t_case('test_phase5_instantaneous');
% --- Definite-time threshold semantics ---
T = T.chk(phase5_curve_dt(2.0, 1.0, 0.4) == 0.4, 'DT I>Is trips at tdef 0.4 s');
T = T.chk(phase5_curve_dt(1.0, 1.0, 0.4) == 0.4, 'DT I==Is trips (definite-time equality)');
T = T.chk(isinf(phase5_curve_dt(0.999, 1.0, 0.4)), 'DT I<Is gives Inf (no trip)');
T = T.chk(phase5_curve_dt(5.0, 1.0, 0.0) == 0.0, 'DT tdef 0 allowed (true instantaneous element)');
% --- phase5_time DT branch delegates identically ---
T = T.chk(phase5_time(2.0, 1.0, 0.4, 'DT') == 0.4, 'phase5_time DT branch trips at tdef');
T = T.chk(isinf(phase5_time(0.5, 1.0, 0.4, 'DT')), 'phase5_time DT branch below pickup Inf');
T = T.chk(phase5_time(1.0, 1.0, 0.4, 'DT') == 0.4, 'phase5_time DT equality trips');
% --- phase5_curve routes DT away loudly ---
try
    phase5_curve(2, 'DT', 0.1);
    T = T.chk(false, 'phase5_curve DT must error');
catch ME
    T = T.chk(strcmp(ME.identifier, 'phase5_curve:family'), 'phase5_curve DT errors phase5_curve:family');
end
% --- Default inverse path never instantaneous (no Iinst override) ---
tInv = phase5_time(3.3687257, 1.0015833, 0.1, 'SI');  % F3 LLL secondary anchor
tExp = 0.1 * 0.14 / ((3.3687257 / 1.0015833) ^ 0.02 - 1);
T = T.chk(abs(tInv - tExp) < 1e-9, 'inverse path reproduces SI closed form (no 0.05 s shortcut)');
T = T.chk(tInv > 0.05, 'inverse path never returns instantaneous 0.05 s unprompted');
% --- Errors phase5-prefixed ---
try
    phase5_curve_dt(-1, 1.0, 0.4);
    T = T.chk(false, 'negative I must error');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'negative-I error phase5-prefixed');
end
try
    phase5_time(2.0, 1.0, 0.4, 'NOPE');
    T = T.chk(false, 'unknown family must error');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'unknown-family error phase5-prefixed');
end
[np, nf] = T.done();
end
