function [np, nf] = test_phase4_topology()
T = t_case('test_phase4_topology');
Y = phase4_topology(0.5, 'B', 'closed');
T = T.near(Y.Zs_branch_pu, 2*Y.Zs_eq_pu, 1e-12, 'Z_branch = 2*Z_eq');
T = T.near(Y.Zs_S + Y.Zs_R, Y.Zs_eq_pu, 1e-12, 'm-section sum restores total');
T = T.eq(Y.nodeF1, Y.nodeF2, 'F1/F2 same node, labels kept separate');
T = T.eq(Y.labelF1, 'F1_B22', 'F1 label kept'); T = T.eq(Y.labelF2, 'F2_GSUT_LV', 'F2 label kept');
O = phase4_topology(0, 'lumped', 'open');
T = T.chk(O.nodeB230_1 ~= O.nodeB230_2, 'coupler open splits GIS nodes');
[np, nf] = T.done();
end
