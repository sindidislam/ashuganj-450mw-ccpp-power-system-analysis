function [np,nf] = test_phase5b_final_engineering()
% Numerical contract from the user's final engineering specification.
T=t_case('test_phase5b_final_engineering');
R=phase5b_registry(); d=R.devices; ids={d.device_id};
g=d(strcmp(ids,'GSUT-87T'));
T=T.chk(abs(g.rated_A-1292.8)<1e-9,'87T base is GSUT nameplate current');
T=T.chk(abs(g.pickup_A-387.84)<1e-9,'87T threshold on HV base');
n=d(strcmp(ids,'GEN-51N'));
T=T.chk(n.ct_ratio==20 && n.pickup_A==4,'registry resolved dedicated neutral CT and 4 A');
h=d(strcmp(ids,'GSUT-HV-51'));
T=T.chk(h.pickup_A==1380 && strcmp(h.ct_source,'ENGINEERING_ASSUMPTION'),'resolved GSUT pickup and CT conflict status');
q=d(strcmp(ids,'GIS-Q0-51'));
T=T.chk(q.pickup_A==1500 && strcmp(q.assumption_class,'CONDITIONAL'),'Q0 numerical conditional setting');
try
 [P,A]=phase5b_parameters();
 T=T.chk(abs(P.GEN_51_pickup_A-1.2*14309)<1e-9,'GEN 51 independent multiplication');
 T=T.chk(abs(P.GSUT_maximum_load_anchor_A-458e6/(sqrt(3)*230e3))<1e-9,'GSUT exact load derivation');
 T=T.chk(abs(P.GRID_Zth_ohm-230e3/(sqrt(3)*45010))<1e-12,'grid impedance from current not conflicting report Z');
 T=T.chk(abs(P.GRID_Xth_ohm/P.GRID_Rth_ohm-10.99)<1e-12,'grid XR decomposition');
 T=T.chk(all(isfinite(A.value)) && all(strlength(string(A.source_file))>0),'all model parameters finite with provenance');
 Ti=phase5_import(ashuganj_root()); S=phase5b_sensitivity_v2(Ti,d,R);
 T=T.chk(all(ismember([10;20;25],S.scenario_value(strcmp(S.family,'GEN_NEUTRAL_CT')))),'neutral CT numerical cases');
 T=T.chk(all(ismember([4;5],S.scenario_value(strcmp(S.family,'GEN_NEUTRAL_PICKUP')))),'4 A and 5 A actual calculated cases');
 T=T.chk(all(ismember([1500;1600],S.scenario_value(strcmp(S.family,'GSUT_CT')))),'GSUT documentary CT cases');
 T=T.chk(all(ismember([30;40;45.01;50],S.scenario_value(strcmp(S.family,'GRID_STRENGTH')))),'grid strength calculated cases');
 T=T.chk(all(ismember([57;60;63],S.scenario_value(strcmp(S.family,'NER')))),'NER calculated cases');
 T=T.chk(all(ismember([4;5;6],S.scenario_value(strcmp(S.family,'MOTOR')))),'motor calculated cases');
 T=T.chk(all(strcmp(S.scope,'SENSITIVITY')),'screening table cannot overwrite primary');
 k=strcmp(S.family,'GEN_NEUTRAL_CT');
 sec=S.value(k & strcmp(S.metric,'I_secondary_A'));
 pri=S.value(k & strcmp(S.metric,'I_primary_A'));
 ct=S.value(k & strcmp(S.metric,'ct_ratio'));
 T=T.chk(all(abs(sec-pri./ct)<1e-12),'neutral CT secondary arithmetic');
catch ME
 T=T.chk(false,['numerical closure interface: ' ME.message]);
end
[np,nf]=T.done();
end
