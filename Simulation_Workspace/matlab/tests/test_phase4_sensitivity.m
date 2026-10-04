function [np, nf] = test_phase4_sensitivity()
T = t_case('test_phase4_sensitivity');
S = phase4_sensitivity('base_LF360_OUT_P15', {'C-LOW','C-HIGH'});
T = T.eq(numel(S.runs), 2, 'OFAT legs run independently');
T = T.chk(S.runs(1).kX == 2.0 && S.runs(2).kX == 3.5, 'LOW/HIGH corners hit');
G = phase4_sensitivity('base_LF360_OUT_P15', {'GAT-Z0-9.99','GAT-Z0-11.61'});
T = T.chk(strcmp(G.runs(1).gatZ0status,'SOURCE'), 'GAT-Z0 tolerance keeps SOURCE status');
try, phase4_sensitivity('base_LF360_OUT_P15', {'FULL_FACTORIAL'}); T = T.chk(false, 'factorial forbidden');
catch ME, T = T.chk(true, 'factorial forbidden'); end
L = phase4_sensitivity('base_LF360_OUT_P15', {'B-1.0'});
T = T.near(L.runs(1).lineScale, 1.42857143, 1e-6, 'length leg scales totals');
H = phase4_sensitivity('base_LF360_OUT_P15', {'H0','H2'});
T = T.chk(isfield(H.runs(1),'gatLeg') && isfield(H.runs(2),'gatLeg'), 'H-leg runs execute');
D = phase4_sensitivity('base_LF360_OUT_P15', {'A-S'});
T = T.chk(D.runs(1).kcl < 1e-6, 'S-dataset run KCL closes');
Z = phase4_sensitivity('base_LF360_OUT_P15', {'ZTH0-HAND'});
T = T.near(Z.runs(1).relerr, 0, 0.01, 'F3 Zth0 hand parallel formula within 1%');
try, phase4_sensitivity('base_LF360_OUT_P15', {'NOPE'}); T = T.chk(false, 'bad leg rejected');
catch ME, T = T.chk(true, 'bad leg rejected'); end
[np, nf] = T.done();
end
