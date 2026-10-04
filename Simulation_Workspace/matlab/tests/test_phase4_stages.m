function [np, nf] = test_phase4_stages()
T = t_case('test_phase4_stages');
R = phase4_stages('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',[],'bolted');
T = T.eq(R.stage, 'Ikpp', 'stage labelled');
B = phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ib',0.06,'bolted');
T = T.eq(B.t_break, 0.06, 't_break attached, never defaulted');
try, phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ib',[],'bolted'); T = T.chk(false, 'missing t_break errors');
catch ME, T = T.chk(true, 'missing t_break errors'); end
E = phase4_stages('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0,'earth');
T = T.chk(abs(E.Ifault) < abs(R.Ifault), 'earth probe reduces LG current');
T = T.near(E.Zf_ohm, 0.01*529, 1e-9, 'earth probe ohmic at 230 kV');
% Final-review fix TEST EXTENSION (controller-authorized): F1 earth probe on level base.
Rb1 = phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ikpp',[],'bolted');
E1 = phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ikpp',0,'earth');
T = T.near(E1.Zf_ohm, 0.01*4.84, 1e-9, 'F1 earth probe ohmic at 22 kV');
T = T.near(E1.Zf_pu, 0.01, 1e-12, 'F1 earth probe pu on level base');
T = T.chk(abs(abs(E1.Ifault)-abs(Rb1.Ifault))/abs(Rb1.Ifault) < 0.01, 'F1 earth probe ~= bolted within 1% (NER-dominated insensitivity)');
[np, nf] = T.done();
end
