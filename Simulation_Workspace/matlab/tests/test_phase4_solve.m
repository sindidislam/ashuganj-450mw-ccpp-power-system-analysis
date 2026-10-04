function [np, nf] = test_phase4_solve()
T = t_case('test_phase4_solve');
F = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0);
T = T.chk(abs(F.I1) > 0, 'LLL fault current nonzero');
T = T.chk(F.audit_res < 1e-6, 'nodal vs Thevenin audit closes');
T = T.chk(abs(abs(F.Ia)-abs(F.Ib)) < 1e-6*abs(F.Ia), 'LLL phase symmetry');
G = phase4_solve('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0);
T = T.near(G.Ia, 3*G.I0, 1e-9, 'LG Ia = 3I0 fault branch');
T = T.chk(G.r > 0 && G.kappa > 1 && G.kappa < 2, 'kappa(r) sane, ip attached');
[np, nf] = T.done();
end
