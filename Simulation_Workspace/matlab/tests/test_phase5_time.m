function [np, nf] = test_phase5_time()
T = t_case('test_phase5_time');
t = phase5_time(3.3687257, 1.0015833, 0.1, 'SI'); % F3 LLL secondary vs GEN-51 pickup secondary
T = T.chk(isfinite(t)&&t>0&&t<10, 'F3 LLL finite time <10 s');
T = T.chk(abs(phase5_time(0.0004848, 0.0003333, 0.5, 'SI')-9.31)<0.1, 'EF leg executes (value checked in validation)');
T = T.chk(isinf(phase5_time(0.5, 1.0, 0.1, 'SI')), 'below pickup Inf');
[np, nf] = T.done();
end
