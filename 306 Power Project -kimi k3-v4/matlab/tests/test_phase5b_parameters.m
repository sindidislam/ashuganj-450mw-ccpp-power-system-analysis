function [np,nf]=test_phase5b_parameters()
T=t_case('test_phase5b_parameters');
try
 [P,A]=phase5b_parameters();
 T=T.near(P.GEN_51_pickup_A,17170.8,1e-9,'GEN maximum load pickup');
 T=T.near(P.GSUT_rated_exact_A,515e6/(sqrt(3)*230e3),1e-9,'GSUT exact nameplate derivation');
 T=T.near(P.GSUT_maximum_load_anchor_A,458e6/(sqrt(3)*230e3),1e-9,'GSUT maximum load is distinct');
 T=T.near(P.GSUT_51_secondary_A,0.8625,1e-12,'GSUT CT secondary');
 T=T.near(P.Q0_51_secondary_A,0.9375,1e-12,'Q0 CT secondary');
 T=T.near(P.GEN_87G_pickup_A,2403.8,1e-9,'87G threshold');
 T=T.near(P.GSUT_87T_pickup_A,387.84,1e-9,'87T nameplate threshold');
 T=T.near(P.GEN_51N_pickup_A,4,1e-12,'neutral central 4 A');
 T=T.near(P.SOUTH_R1_total_ohm,0.056,1e-12,'South positive total R');
 T=T.near(P.SOUTH_X1_total_ohm,0.245,1e-12,'South positive total X');
 T=T.near(P.SOUTH_R0_total_ohm,0.175,1e-12,'South zero total R');
 T=T.near(P.SOUTH_X0_total_ohm,0.840,1e-12,'South zero total X');
 T=T.near(P.GRID_Zth_ohm,230e3/(sqrt(3)*45010),1e-12,'grid exact impedance');
 T=T.near(P.GRID_Xth_ohm/P.GRID_Rth_ohm,10.99,1e-12,'grid XR');
 T=T.near(P.CT_accuracy_boundary_A,32000,1e-12,'accuracy screening boundary');
 T=T.near(P.GEN_R1_pu,0.00089/(22^2/458),1e-12,'generator resistance correct base');
 T=T.near(P.GEN_R2_pu,P.GEN_R1_pu,1e-12,'negative sequence resistance');
 T=T.near(P.GEN_R0_pu,1.5*P.GEN_R1_pu,1e-12,'zero sequence resistance');
 T=T.near(P.GSUT_R1_pu,0.9122/515,1e-12,'GSUT copper loss R');
 T=T.near(P.NER_effective_HV_ohm,60+(22000/sqrt(3)/500)^2*2.62,1e-9,'grounding loading resistor reflected to HV');
 T=T.chk(all(isfinite(A.value)) && height(A)==numel(fieldnames(P)),'all numeric fields documented');
 T=T.chk(numel(unique(A.parameter))==height(A),'provenance parameter uniqueness');
 names=setdiff(A.Properties.VariableNames,{'value'});
 for j=1:numel(names),T=T.chk(all(strlength(string(A.(names{j})))>0),['complete provenance ' names{j}]);end
 T=T.chk(strcmp(A.status{strcmp(A.parameter,'GSUT_CT')},'ENGINEERING_ASSUMPTION'),'GSUT CT is assumption');
 T=T.chk(strcmp(A.actual_installed_value_verified{strcmp(A.parameter,'GEN_51N_CT')},'NO'),'neutral CT never verified');
catch ME
 T=T.chk(false,['parameter closure: ' ME.message]);
end
[np,nf]=T.done();
end
