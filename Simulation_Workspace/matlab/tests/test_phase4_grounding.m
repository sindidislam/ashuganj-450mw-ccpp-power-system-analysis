function [np, nf] = test_phase4_grounding()
T = t_case('test_phase4_grounding');
Z = phase4_grounding('primary');
T = T.near(Z.n, 25.40341184, 1e-6, 'turns ratio n');
T = T.near(Z.R_refl, 1690.773333, 1e-4, 'reflected 2.62 ohm');
T = T.near(Z.R_NER_HV, 1750.773333, 1e-4, 'additive R_NER_HV');
T = T.near(Z.Z3ZN_ohm, 5252.32, 1e-2, '3ZN ohms');
T = T.near(Z.Z3ZN_pu_machine, 4970.1706, 1e-2, '3ZN pu machine base');
T = T.near(Z.ZN_UAT_ohm, 796.743371, 1e-3, 'UAT 5-A equivalent');
T = T.near(Z.ZN_GAT_LV_ohm, 796.743371, 1e-3, 'GAT LV 5-A equivalent, NOT solid');
T = T.near(Z.ZN_UAT_alt_ohm, 265.581124, 1e-3, 'alternative I0 reading');
Q = phase4_grounding('quoted60');
T = T.near(Q.R_NER_HV, 60, 1e-9, 'quoted-60 alternative kept visible');
try, phase4_grounding('solid'); T = T.chk(false, 'solid NER forbidden');
catch ME, T = T.chk(true, 'solid NER forbidden'); end
[np, nf] = T.done();
end
