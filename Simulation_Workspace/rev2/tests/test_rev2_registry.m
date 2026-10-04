function test_rev2_registry()
%TEST_REV2_REGISTRY 9 acceptance assertions for Rev2 registry (TDD RED->GREEN).
D = ashuganj_rev2_registry();
assert(D.meta.Sbase_MVA==100,'Sbase must be 100 MVA');
assert(D.meta.f_Hz==50,'Frequency must be 50 Hz');
assert(D.gen.Pmax_MW==360,'Pmax must be 360 MW (not 389.3)');
assert(abs(D.gen.R1_pu-0.00089/(22^2/458))<1e-9,'R1 pu derivation wrong');
assert(abs(D.gsut.X1_pu_own-0.16629)<1e-4,'GSUT X1 must be ~0.16629');
assert(strcmp(D.gen.Earthing,'Solidly grounded'),'Earthing must be solid (new dataset)');
assert(D.aux.P_MW==12 && D.aux.Q_MVAr==5,'Aux must be 12+j5');
assert(abs(D.uat.a_LV-6.6/6.9)<1e-9,'Off-nominal tap wrong');
assert(abs(D.grid.Ssc_GVA-17.93)<0.05,'Grid Ssc must be 17.93 GVA');
fprintf('test_rev2_registry: 9/9 PASS Rev=%s\n',D.meta.Revision);
end
