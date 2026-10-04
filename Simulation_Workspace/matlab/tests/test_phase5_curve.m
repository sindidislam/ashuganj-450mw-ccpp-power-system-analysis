function [np, nf] = test_phase5_curve()
T = t_case('test_phase5_curve');
[k,a] = phase5_curve_info('SI');
T = T.chk(abs(k-0.14)<1e-12&&abs(a-0.02)<1e-12, 'SI constants IEC 60255 study values');
t1 = phase5_curve(2, 'SI', 0.1);
T = T.chk(abs(t1-0.1*0.14/((2^0.02)-1))<1e-9, 'SI t at M=2 matches closed form');
T = T.chk(isinf(phase5_curve(1,'SI',0.1)), 'M<=1 gives Inf (no trip)');
T = T.chk(phase5_curve(10,'EI',0.1)<phase5_curve(10,'SI',0.1), 'EI faster than SI at M=10');
[np, nf] = T.done();
end
