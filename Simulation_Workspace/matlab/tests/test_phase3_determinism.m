function [np,nf] = test_phase3_determinism()
T = t_case('Phase 3 fresh-build determinism');
info1 = build_ashuganj_main('LF360_GAT_OUT','Quiet',true,'Backup',false,'Save',false);
LF1 = power_loadflow(info1.model,'solve');
v1 = validate_phase3_network(LF1,ashuganj_master_data(),info1.case,info1);
if bdIsLoaded(info1.model), bdclose(info1.model); end
info2 = build_ashuganj_main('LF360_GAT_OUT','Quiet',true,'Backup',false,'Save',false);
LF2 = power_loadflow(info2.model,'solve');
v2 = validate_phase3_network(LF2,ashuganj_master_data(),info2.case,info2);
if bdIsLoaded(info2.model), bdclose(info2.model); end
T = T.near(v1.Pgen_MW,v2.Pgen_MW,1e-9,'P deterministic');
T = T.near(v1.Qgen_MVAr,v2.Qgen_MVAr,1e-9,'Q deterministic');
T = T.near(v1.V_REMOTE_pu,v2.V_REMOTE_pu,1e-12,'Vremote deterministic');
T = T.near(v1.worst_KCL_MVA,v2.worst_KCL_MVA,1e-12,'KCL deterministic');
T = T.eq(v1.verdict,v2.verdict,'verdict deterministic');
[np,nf] = T.done();
end
