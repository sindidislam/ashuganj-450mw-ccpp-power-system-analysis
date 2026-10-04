function V=phase5b_validate(varargin)
% Implementation checks do not turn conditional studies into commissioned proof.
if nargin~=0, error('phase5b_validate:args','No arguments accepted.'); end
root=ashuganj_root(); [P,A]=phase5b_parameters(); R=phase5b_registry(); d=R.devices;
Ti=phase5_import(root); B=phase5b_cached_branches(Ti);
[M,~,C]=phase5b_coord(d,Ti,B); S=phase5b_sensitivity_v2(Ti,d,R,B);
D=phase5b_duty(Ti,[],B); E=phase5b_effectiveness(Ti,d,B); Z=phase5b_zones();
legs=struct('id',{},'pass',{},'residual',{},'note',{});
k3=strcmp(Ti.caseID,'LF360_GAT_OUT')&strcmp(Ti.fault_location,'F3')&strcmp(Ti.fault_type,'LLL');
k1=strcmp(Ti.caseID,'LF360_GAT_OUT')&strcmp(Ti.fault_location,'F1')&strcmp(Ti.fault_type,'LG');
r=max(abs([Ti.I_primary_kA(k3)-50.5308851865359,Ti.I_primary_kA(k1)-.00727200442799167]));
add('R0',r<1e-9,r,'Locked Phase-4 identity: F3 50.5308851865 kA; F1 0.007272004428 kA');
g=d(strcmp({d.device_id},'GSUT-HV-51')); n=d(strcmp({d.device_id},'GEN-51N'));
add('B01',g.ct_ratio==1600&&strcmp(g.ct_source,'ENGINEERING_ASSUMPTION')&&n.ct_ratio==20,0,'GSUT documentary conflict; dedicated neutral CT');
b=d(strcmp({d.device_id},'GEN-51-SIEMENS-BL'));
add('B02',b.trip_delay_s==3&&strcmp(b.assumption_class,'SENSITIVITY'),0,'Numerical 3 s documentary comparator; not commissioned');
add('B03',abs(g.rated_A-1292.8)<1e-9&&g.pickup_A==1380&&P.GEN_51_pickup_A==17170.8,0,'Rated versus maximum-load semantics and derived phase pickups');
add('B04',all(isfinite(C.GEN_phase_A))&&all(abs(C.GSUT_HV_phase_A-C.GSUT_HV_fault_base_A.*C.source_voltage_kV/230)<1e-8),0,'Faulted B/C phase recovery and physical CT-base conversion');
q=strcmp(D.breaker_ref,'Q0');
add('B05',all(D.rating_kA(q)==50)&&all(abs(D.duty_ratio(q)-D.I_sym_kA(q)/50)<1e-12),0,'Q0 50 kA conditional rating; branch duty ratio');
add('B06',~isempty(Z)&&any(strcmp({Z.device_id},'GEN-87G'))&&any(strcmp({Z.device_id},'GSUT-87T')),0,'Functional engineering trip matrix represented');
active=isfinite(E.primary_time_s); good=~contains(string(E.detection),'ASSERTABLE');
add('B07',all(good)&&all(ismember(E.primary_time_s(active),[.035 .045])),0,'Study detectability and explicit numerical timing proxies');
req={'GEN_NEUTRAL_CT','GEN_NEUTRAL_PICKUP','GSUT_CT','GRID_STRENGTH','GRID_XR','GRID_ZERO','NER','MOTOR','CT_SATURATION'};
add('B08',all(ismember(req,S.family))&&all(isfinite(S.value)),0,'All required numerical sensitivity families executed');
five=strcmp(S.family,'GEN_NEUTRAL_PICKUP')&S.scenario_value==5;
add('B09',n.pickup_A==4&&n.ct_ratio==20&&any(five)&&all(strcmp(S.scope(five),'SENSITIVITY')),0,'4 A PRIMARY; 5 A sensitivity only');
q=contains(M.downstream,'Q0')|contains(M.upstream,'Q0');
add('B10',all(strcmp(M.scope(q),'CONDITIONAL'))&&~any(strcmp(M.verdict(q),'PASS')),0,'Primary and conditional coordination segregated');
err=0;
for i=1:height(M)
 for side={'down','up'}
  if strcmp(side{1},'down'), id=M.downstream{i}; else, id=M.upstream{i}; end
  j=find(strcmp({d.device_id},id),1); t=M.(['t_' side{1} '_s'])(i);
  if isempty(j)||~isfinite(t), continue; end
  I=M.(['I_' side{1} '_A'])(i); Is=d(j).pickup_A/d(j).ct_ratio;
  th=.14*d(j).tms/((I/Is)^.02-1); err=max(err,abs(th-t));
 end
end
add('B11',err<1e-10,err,'All finite IEC SI coordination times independently recalculated');
add('B12',all(isfinite(A.value))&&all(strlength(string(A.source_file))>0)&&all(strlength(string(A.derivation))>0),0,'Numerical closure and per-parameter provenance');
count=phase5b_verify_baseline();
add('B13',count>0,0,sprintf('Same tolerances and protected byte identity for %d upstream files',count));
V=struct('legs',legs);
 function add(id,pass,residual,note)
  legs(end+1)=struct('id',id,'pass',logical(pass),'residual',double(residual),'note',note);
 end
end
