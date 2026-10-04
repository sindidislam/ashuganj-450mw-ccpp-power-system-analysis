function [np,nf] = test_phase5b_sensitivity_v2()
% Numerical sensitivities must be executed and cannot replace central values.
T=t_case('test_phase5b_sensitivity_v2');
R=phase5b_registry();
loc={'F1';'F1';'F3'}; typ={'LG';'LLG';'LLL'}; cs={'SYN';'SYN';'SYN'};
ip=[7.27;36000;72000]; ik=ip/1000;
ner=[7.27/3000;3.638/3000;0]; hv=[0;0;13];
Ti=table(loc,typ,cs,ip,ik,ner,hv,'VariableNames', ...
 {'fault_location','fault_type','caseID','I_primary_A','I_primary_kA', ...
 'leg_NER_earth_kA','leg_GSUT_HV_kA'});
try
 S=phase5b_sensitivity_v2(Ti,R.devices,R);
 T=T.chk(ismember('metric',S.Properties.VariableNames),'numerical long result schema');
 if ~ismember('metric',S.Properties.VariableNames), [np,nf]=T.done();return;end
 T=T.chk(all(strcmp(S.scope,'SENSITIVITY')),'all sensitivity rows segregated');
 T=T.chk(all(isfinite(S.value)),'all emitted result metrics finite');
 families={'GEN_NEUTRAL_CT','GEN_NEUTRAL_PICKUP','GSUT_CT','GRID_STRENGTH', ...
  'GRID_XR','GRID_ZERO','NER','MOTOR','CT_SATURATION','GRID_REPORTED_Z'};
 vals={[10 20 25],[4 5],[1500 1600],[30 40 45.01 50],[5 10.99 20], ...
  [2 3 4],[57 60 63],[4 5 6],[0 20 40],[3.25]};
 for j=1:numel(families)
  T=T.chk(all(ismember(vals{j},S.scenario_value(strcmp(S.family,families{j})))), ...
   [families{j} ' requested cases executed']);
 end
 T=T.near(metric(S,'GEN_NEUTRAL_CT',20,'I_secondary_A','LG'),7.27/20,1e-12,'neutral secondary from dedicated CT');
 T=T.near(metric(S,'GEN_NEUTRAL_CT',25,'pickup_primary_A','LG'),5,1e-12,'25/1 at fixed 0.20 secondary gives 5 A');
 T=T.near(metric(S,'GEN_NEUTRAL_CT',10,'pickup_margin','LG'),7.27/2,1e-12,'neutral pickup margin physical ratio sensitivity');
 T=T.near(metric(S,'GEN_NEUTRAL_PICKUP',4,'I_primary_A','LLG'),3.638,1e-12,'NER branch residual used instead of total fault current');
 T=T.near(metric(S,'GEN_NEUTRAL_PICKUP',5,'operating_time_s','LG'), ...
  0.14*0.15/((7.27/5)^0.02-1),1e-12,'5 A sensitivity actual IEC SI time');
 T=T.near(metric(S,'GSUT_CT',1500,'pickup_secondary_A','SCREEN'),1380/1500,1e-12,'GSUT documentary CT retuned secondary');
 T=T.near(metric(S,'GSUT_CT',1600,'I_primary_A','SCREEN'),13000,1e-12,'GSUT uses HV leg physical current');
 T=T.near(metric(S,'GRID_STRENGTH',45.01,'Zth_ohm','SCREEN'),230e3/(sqrt(3)*45010),1e-12,'grid exact central derivation');
 T=T.near(metric(S,'GRID_REPORTED_Z',3.25,'implied_voltage_factor','SCREEN'),3.25/(230e3/(sqrt(3)*45010)),1e-12,'grid conflicting impedance possible voltage-factor convention quantified');
 T=T.near(metric(S,'GRID_ZERO',3,'earth_fault_kA','SCREEN'),3*45.01/5,1e-10,'grid sequence screening calculation');
 ratio=22000/sqrt(3)/500; reff=60+ratio^2*2.62;
 T=T.near(metric(S,'NER',57,'I_primary_A','LG'),7.27*reff/(57+ratio^2*2.62),1e-12,'NER winding resistance perturbation uses complete referred load');
 T=T.near(metric(S,'MOTOR',6,'contribution_230kV_A','SCREEN'),6*13e6/(sqrt(3)*230e3),1e-12,'motor 12+j5 MVA equivalent referred to 230 kV');
 T=T.near(metric(S,'CT_SATURATION',20,'I_primary_A','SCREEN'),32000,1e-12,'5P20 boundary at 32 kA');
 T=T.near(metric(S,'BREAKER_RATING',50,'duty_ratio','SCREEN'),13/50,1e-12,'Q0 breaker screening uses physical branch rather than bus-total current');
 T=T.near(metric(S,'GSUT_COPPER_LOSS',1.095,'R1_pu','SCREEN'),1.095/515,1e-12,'OEM copper-loss documentary sensitivity calculated');
 T=T.near(metric(S,'GSUT_IMPEDANCE',0.16,'transformer_only_fault_kA','SCREEN'),515e3/(sqrt(3)*230)/0.16/1000,1e-12,'OEM impedance transformer-only screening');
 T=T.chk(all(contains(string(S.method(startsWith(string(S.family),'GRID'))),'ANALYTICAL SCREENING')), ...
  'grid rows never claim regenerated Phase 4');
 T=T.chk(all(strcmp(S.case_role(S.scenario_value==20 & strcmp(S.family,'GEN_NEUTRAL_CT')),'CENTRAL_REFERENCE')), ...
  '20/1 remains central reference within sensitivity scope');
 B=table();
 for i=1:height(Ti)
  for leg={'GEN','GSUT_HV','NER_earth'}
   if strcmp(leg{1},'GSUT_HV'),ia=13000;ib=13000;ic=13000;else,ia=0;ib=0;ic=0;end
   if i==2&&strcmp(leg{1},'GSUT_HV'),ia=200000;ib=12000;ic=12000;end
   r=table(Ti.caseID(i),Ti.fault_location(i),Ti.fault_type(i),leg,ia,ib,ic,max(ib,ic), ...
    'VariableNames',{'caseID','location','fault_type','leg','Ia_A','Ib_A','Ic_A','Ibranch_faulted_A'});
   B=[B;r]; %#ok<AGROW>
  end
 end
 SB=phase5b_sensitivity_v2(Ti,R.devices,R,B);
 T=T.near(metric(SB,'BREAKER_RATING',50,'duty_ratio','SCREEN'),200000*22/230/50000,1e-12, ...
  'breaker duty uses maximum all-phase physical branch including nonfaulted phase');
catch ME
 T=T.chk(false,['sensitivity numerical contract: ' ME.message]);
end
[np,nf]=T.done();
end
function v=metric(S,family,x,name,typ)
k=strcmp(S.family,family)&abs(S.scenario_value-x)<1e-10&strcmp(S.metric,name)&strcmp(S.fault_type,typ);
v=S.value(k);assert(numel(v)==1,'phase5b_test:metric','Expected one requested metric');
end
