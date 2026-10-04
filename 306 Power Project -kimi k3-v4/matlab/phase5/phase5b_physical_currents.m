function C=phase5b_physical_currents(Ti,B)
% Convert fault-base phasors to the voltage of each physical CT/breaker.
% The locked contribution CSV carries |Ia| on the FAULT voltage base.
% B recovers max faulted phase, with identity to that locked |Ia| archive.
n=height(Ti); vf=230*ones(n,1);
vf(ismember(Ti.fault_location,{'F1','F2'}))=22;
gen=zeros(n,1); hv=gen; neutral=gen; rawGen=gen; rawHV=gen;
genI0=gen; hvI0=gen;
for i=1:n
 rawGen(i)=readleg('GEN'); rawHV(i)=readleg('GSUT_HV');
 gen(i)=rawGen(i)*vf(i)/22;
 hv(i)=rawHV(i)*vf(i)/230;
 genI0(i)=readleg('GEN','I0_A')*vf(i)/22;
 hvI0(i)=readleg('GSUT_HV','I0_A')*vf(i)/230;
 % NER leg is I0, not the full neutral current. Refer it to 22 kV once.
 if ismember(Ti.fault_type{i},{'LG','LLG'})
  neutral(i)=3*readleg('NER_earth')*vf(i)/22;
 end
end
C=table(Ti.caseID,Ti.fault_location,Ti.fault_type,vf,rawGen,rawHV,gen,hv,hv,neutral,genI0,hvI0,hvI0, ...
 'VariableNames',{'caseID','fault_location','fault_type','source_voltage_kV', ...
 'GEN_fault_base_A','GSUT_HV_fault_base_A','GEN_phase_A','GSUT_HV_phase_A', ...
 'Q0_phase_A','GEN_neutral_A','GEN_I0_A','GSUT_HV_I0_A','Q0_I0_A'});
C.provenance=repmat({'DERIVED:phase5b_branch_phasors faulted phase; physical A = source A * Vfault/Vdevice; Q0 transformer-bay mapping CONDITIONAL_ASSUMPTION'},n,1);
 function x=readleg(leg,column)
  if nargin<2, column='Ibranch_faulted_A'; end
  k=strcmp(B.caseID,Ti.caseID{i}) & strcmp(B.location,Ti.fault_location{i}) & strcmp(B.fault_type,Ti.fault_type{i}) & strcmp(B.leg,leg);
  assert(sum(k)==1,'phase5b_physical_currents:leg','Exactly one required branch is needed: %s',leg);
  x=B.(column)(k);
  assert(isfinite(x)&&x>=0,'phase5b_physical_currents:finite','Required branch must be finite');
 end
end
