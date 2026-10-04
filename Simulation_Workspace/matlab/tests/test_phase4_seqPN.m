function [np, nf] = test_phase4_seqPN()
T = t_case('test_phase4_seqPN');
N = phase4_seqPN('P', 15);
T = T.near(N.Z1grid_R + 1j*N.Z1grid_X, (0.17666194 + 1j*2.64992904)/529, 1e-6, 'grid P split at X/R=15 (pu on 100 MVA base)');
T = T.near(abs(N.Z1grid_R + 1j*N.Z1grid_X), 2.65581124/529, 1e-9, '|Z| fixed, split-only');
T = T.eq(N.Z2gsut_R, N.Z1gsut_R, 'GSUT Z2=Z1 justified static equality');
T = T.near(N.Z1line_X_pu, 0.1425655/529, 1e-12, 'line X frozen total');
S = phase4_seqPN('S', NaN);
T = T.near(S.Z1grid_R + 1j*S.Z1grid_X, (0.267344 + 1j*2.938108)/529, 1e-6, 'dataset S fixed split');
try, phase4_seqPN('P', 0); T = T.chk(false, 'Rgrid=0 fenced out');
catch ME, T = T.chk(true, 'Rgrid=0 fenced out'); end
[np, nf] = T.done();
end
