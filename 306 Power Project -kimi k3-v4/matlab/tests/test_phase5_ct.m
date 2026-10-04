function [np, nf] = test_phase5_ct()
T = t_case('test_phase5_ct');
S = phase5_ct(12019, 15000);
T = T.chk(abs(S.Isec_A-0.8012667)<1e-6, '12019/15000 = 0.8013 A secondary');
S2 = phase5_ct(7.27200442799167, 15000); % 7.272 A primary
T = T.chk(abs(S2.Isec_A-0.0004848)<1e-7, 'F1 LG 7.27 A -> 0.48 mA secondary (sensitive-EF regime)');
S3 = phase5_ct(50530.8851865359, 15000);
T = T.chk(abs(S3.Isec_A-3.3687257)<1e-5, 'F3 LLL 50.53 kA -> 3.369 A secondary');
T = T.chk(isinf(phase5_ct(0,15000).Isec_A)==0, 'zero primary gives zero secondary, not Inf');
S4 = phase5_ct(1150, 2000); % 2000/1 STUDY CT (registry device CT; fencing lives in ledger, not arithmetic)
T = T.chk(abs(S4.Isec_A-0.575)<1e-12, '2000/1 STUDY CT: 1150/2000 = 0.575 A secondary');
try, phase5_ct(100, 0); T = T.chk(false, 'zero ratio errors'); catch ME, T = T.chk(strcmp(ME.identifier,'phase5_ct:ratio'), 'zero ratio errors phase5_ct:ratio'); end
try, phase5_ct(100, -15000); T = T.chk(false, 'negative ratio errors'); catch ME, T = T.chk(strcmp(ME.identifier,'phase5_ct:ratio'), 'negative ratio errors phase5_ct:ratio'); end
[np, nf] = T.done();
end
