function [np,nf]=test_phase5b_physical_currents()
T=t_case('test_phase5b_physical_currents');
Ti=phase5_import(ashuganj_root()); Ti=Ti(1,:);
Ti.fault_location={'F1'}; Ti.fault_type={'LL'};
B=table(repmat(Ti.caseID,3,1),repmat({'F1'},3,1),repmat({'LL'},3,1), ...
 {'GEN';'GSUT_HV';'NER_earth'},[0;0;0],[50000;72000;0],[50000;72000;0], ...
 [50000;72000;0],repmat({'maxBC'},3,1),'VariableNames', ...
 {'caseID','location','fault_type','leg','Ia_A','Ib_A','Ic_A','Ibranch_faulted_A','phase_basis'});
B.I0_A=zeros(height(B),1);
try
 C=phase5b_physical_currents(Ti,B);
 T=T.chk(abs(C.GEN_phase_A-50000)<1e-9,'GEN current on physical 22 kV base');
 T=T.chk(abs(C.GSUT_HV_phase_A-72000*22/230)<1e-9,'HV converts source fault-base amps');
 T=T.chk(C.Q0_phase_A==C.GSUT_HV_phase_A,'Q0 transformer bay shares GSUT HV branch');
 T=T.chk(C.GEN_phase_A>0 && B.Ia_A(1)==0,'LL uses faulted B/C not healthy A');
catch ME
 T=T.chk(false,['physical-current conversion: ' ME.message]);
end
% HV earth residual must not inherit the delta-blocked generator residual.
Ti=phase5_import(ashuganj_root());
Ti=Ti(strcmp(Ti.caseID,'LF360_GAT_OUT') & strcmp(Ti.fault_location,'F3') & strcmp(Ti.fault_type,'LG'),:);
B=phase5b_cached_branches(Ti); C=phase5b_physical_currents(Ti,B);
hasResidual=all(ismember({'GEN_I0_A','GSUT_HV_I0_A','Q0_I0_A'},C.Properties.VariableNames));
T=T.chk(hasResidual,'physical branch zero-sequence columns exist');
if hasResidual
 T=T.chk(C.GEN_I0_A<1e-6,'YNd1 blocks generator zero sequence for HV earth fault');
 T=T.chk(C.GSUT_HV_I0_A>100,'HV earth residual remains observable independently of GEN neutral');
 T=T.chk(abs(C.Q0_I0_A-C.GSUT_HV_I0_A)<1e-9,'conditional Q0 residual follows transformer HV branch');
end
[np,nf]=T.done();
end
