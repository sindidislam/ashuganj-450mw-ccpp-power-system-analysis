function [np, nf] = test_phase4_seqZ()
T = t_case('test_phase4_seqZ');
Z = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
T = T.near(Z.Z0line_R, 3.5*0.0277725/529, 1e-12, 'R0 = kR*R_eq');
T = T.near(Z.Z0line_X, 2.75*0.1425655/529, 1e-12, 'X0 = kX*X_eq');
T = T.near(Z.Z_T0_loop_25MVA, 1.0*0.108, 1e-12, 'H1 loop 25MVA identity');
T = T.near(Z.Z_T0_loop_100MVA, 1.0*0.108*4, 1e-9, 'H1 loop 100MVA = 4x25MVA');
T = T.near(Z.Z_T0_loop_pu, 1.0*0.108*4, 1e-9, 'stamped loop is 100MVA value');
Zh2 = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H2','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
T = T.eq(Zh2.Z_T0_loop_pu, 1e-6, 'H2 explicit short-limit, not zero');
T = T.near(Z.Z3N_UAT_equiv_pu, 3*((6900/sqrt(3))/5)/(6.6^2/100), 1e-9, 'UAT 3ZN equiv single-counted on 6.6kV base');
T = T.near(Z.Z3N_GAT_equiv_pu, 3*((6900/sqrt(3))/5)/(6.6^2/100), 1e-9, 'GAT 3ZN equiv single-counted on 6.6kV base');
T = T.near(Z.ZN_UAT_ohm, (6900/sqrt(3))/5, 1e-9, 'UAT physical IN-reading preserved');
T = T.near(Z.ZN_GAT_LV_ohm, 796.743371, 1e-3, 'GAT LV neutral 5-A, never solid');
T = T.chk(Z.auxShuntOpen, 'aux shunt OPEN in zero base');
T = T.near(Z.Z0grid_mag_pu, 1.5*abs(Z.Z1grid_pu), 1e-12, 'Z0grid = k0g*Z1 same dataset');
[np, nf] = T.done();
end
