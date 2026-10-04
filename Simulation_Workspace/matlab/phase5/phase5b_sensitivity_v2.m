function S = phase5b_sensitivity_v2(T40,devicesProd,Rreg,varargin)
%PHASE5B_SENSITIVITY_V2 Executed Phase-5 analytical sensitivities.
% Long metric format avoids meaningless numeric blanks between unlike cases.
% Every row has scope SENSITIVITY, including CENTRAL_REFERENCE comparators.
% The external-grid/motor/CT cases are analytical screening; the locked
% Phase-4 network and fault inputs are never replaced or claimed recalculated.
% Below-pickup operation is represented by trip_enabled=0 / NO-TRIP. No
% fictitious zero operating time or unresolved NaN is exported.
if ~istable(T40)||isempty(T40),error('phase5b_sensitivity:schema','Nonempty imported fault table required');end
[P,~]=phase5b_parameters();
ids={devicesProd.device_id};
required={'GEN-51N','GSUT-HV-51'};
for k=1:numel(required)
 if ~any(strcmp(ids,required{k})),error('phase5b_sensitivity:devices','Missing device %s',required{k});end
end
n=devicesProd(strcmp(ids,'GEN-51N'));h=devicesProd(strcmp(ids,'GSUT-HV-51'));
ntms=readval(n,'tms',P.GEN_51N_TMS);htms=readval(h,'tms',P.GSUT_51_TMS);
npk=readval(n,'pickup_A',P.GEN_51N_pickup_A);hpk=readval(h,'pickup_A',P.GSUT_51_pickup_A);
rows=cell(0,15);
locs=cellstr(string(T40.fault_location));typs=cellstr(string(T40.fault_type));cases=cellstr(string(T40.caseID));
earth=find(strcmp(typs,'LG')|strcmp(typs,'LLG'));
method='PHASE-5 ANALYTICAL SCREENING SENSITIVITY';
% Dedicated neutral-CT cases retain the 0.20 A secondary dial. This makes
% the 10/20/25 CT primary pickups 2/4/5 A, respectively. The separate fixed
% primary pickup family isolates the 4 versus 5 A setting sensitivity.
for k=earth(:)'
 [in,prov]=neutral(T40,k,typs{k});
 for ct=[10 20 25]
  role=roleof(ct,20);reason='Dedicated neutral CT; fixed 0.20 A secondary; actual primary pickup recomputed';
  relay('GEN_NEUTRAL_CT',ct,role,'GEN-51N',locs{k},typs{k},cases{k},in,ct,0.20*ct,ntms,prov,reason);
 end
 for pk=[4 5]
  role=roleof(pk,4);reason='Dedicated 20/1 neutral CT; independent 4 A central-reference / 5 A sensitivity';
  relay('GEN_NEUTRAL_PICKUP',pk,role,'GEN-51N',locs{k},typs{k},cases{k},in,20,pk,ntms,prov,reason);
 end
 for resistance=[57 60 63]
  role=roleof(resistance,60);effective=resistance+P.NGT_ratio^2*P.NER_loading_LV_ohm;
  ins=in*P.NER_effective_HV_ohm/effective;
  reason='Perturb 60 ohm HV winding DC component; retain reflected 2.62 ohm LV loading. Current scales by full effective neutral resistance ratio; no network re-solve';
  relay('NER',resistance,role,'GEN-51N',locs{k},typs{k},cases{k},ins,20,npk,ntms, ...
   [prov ';60 ohm qualified project entry'],reason);
  emit('NER',resistance,role,'GEN-51N',locs{k},typs{k},cases{k},'resistance_ohm',resistance,'ohm','ENGINEERING_ASSUMPTION',prov,reason);
  emit('NER',resistance,role,'GEN-51N',locs{k},typs{k},cases{k},'effective_HV_resistance_ohm',effective,'ohm','DERIVED',prov,reason);
  emit('NER',resistance,role,'GEN-51N',locs{k},typs{k},cases{k},'LV_loading_resistance_ohm',P.NER_loading_LV_ohm,'ohm','CONDITIONAL_ASSUMPTION',prov,reason);
 end
end
% Use balanced HV branch currents only; the frozen CSV LL/LLG leg magnitude
% is phase A and cannot be used as faulted phase B/C. F1/F2 values are on
% the 22 kV fault base and are explicitly converted to the HV winding base.
[ihv,hprov]=hvprobe(T40,locs,typs,P);
for ct=[1500 1600]
 role=roleof(ct,1600);
 relay('GSUT_CT',ct,role,'GSUT-HV-51','SCREEN','SCREEN','SCREEN',ihv,ct,hpk,htms,hprov, ...
  'Documentary CT sensitivity; primary 1380 A retained by retuning secondary dial');
 relay('GSUT_CT_FIXED_DIAL',ct,role,'GSUT-HV-51','SCREEN','SCREEN','SCREEN',ihv,ct,ct*P.GSUT_51_secondary_A,htms,hprov, ...
  'Documentary CT sensitivity with fixed 0.8625 A secondary dial; primary pickup changes');
end

% Grid equivalent at its own 230 kV terminals, c=1.0. No generator/line
% branch or frozen Phase-4 fault current is silently added or rescaled.
for isk=[30 40 45.01 50]
 grid('GRID_STRENGTH',isk,roleof(isk,45.01),isk,P.GRID_XR,3,0);
end
for xr=[5 10.99 20]
 grid('GRID_XR',xr,roleof(xr,10.99),P.GRID_Isc_kA,xr,3,0);
end
for ratio=[2 3 4]
 grid('GRID_ZERO',ratio,roleof(ratio,3),P.GRID_Isc_kA,P.GRID_XR,ratio,0);
end
grid('GRID_REPORTED_Z',3.25,'DOCUMENTARY_SENSITIVITY',230e3/(sqrt(3)*3.25)/1000,P.GRID_XR,3,3.25);
% Manufacturer design sheet conflicts are real documentary alternatives.
% A transformer-only bolted-fault screen is a sensitivity index, not a
% recalculation of the plant fault study or proof of as-installed impedance.
for z=[P.GSUT_Z1_pu P.GSUT_OEM_Z1_pu]
 role=roleof(z,P.GSUT_Z1_pu);
 if z==P.GSUT_Z1_pu,loss=P.GSUT_copper_loss_MW;else,loss=P.GSUT_OEM_copper_loss_MW;end
 r=loss/P.GSUT_S_MVA;x=sqrt(z^2-r^2);
 prov='Workbook AO3=.1663; AN3-AL3=.9122 MW; OEM datasheet p.3 design16 percent and p.6 copper1095 kW';
 reason='Transformer-only infinite-source screening on 515 MVA/230 kV base; no plant fault matrix regeneration';
 vals={'Z1_pu',z,'pu';'R1_pu',r,'pu';'X1_pu',x,'pu';'copper_loss_MW',loss,'MW'; ...
  'transformer_only_fault_kA',P.GSUT_rated_exact_A/z/1000,'kA'};
 for j=1:size(vals,1),emit('GSUT_IMPEDANCE',z,role,'GSUT','SCREEN','SCREEN','SCREEN',vals{j,1},vals{j,2},vals{j,3},'SENSITIVITY',prov,reason);end
end
for loss=[P.GSUT_copper_loss_MW P.GSUT_OEM_copper_loss_MW]
 role=roleof(loss,P.GSUT_copper_loss_MW);r=loss/P.GSUT_S_MVA;x=sqrt(P.GSUT_Z1_pu^2-r^2);
 prov='Workbook derived912.2 kW versus OEM design1095 kW; neither inferred to be measured loss';
 reason='Copper-loss-only series R/X sensitivity at fixed central0.1663 pu magnitude';
 vals={'copper_loss_MW',loss,'MW';'R1_pu',r,'pu';'X1_pu',x,'pu';'XR',x/r,'1'};
 for j=1:size(vals,1),emit('GSUT_COPPER_LOSS',loss,role,'GSUT','SCREEN','SCREEN','SCREEN',vals{j,1},vals{j,2},vals{j,3},'SENSITIVITY',prov,reason);end
end

% Equivalent motor contribution uses |12+j5|=13 MVA and the same aggregate
% power factor for the 9 MW MV and 3 MW LV components. Referred currents at
% 230 kV are arithmetic source-current screening, not a network fault sum.
totalS=hypot(P.MOTOR_P_MW,P.MOTOR_Q_Mvar);pf=P.MOTOR_P_MW/totalS;
for mult=[4 5 6]
 role=roleof(mult,5);prov='ENGINEERING_ASSUMPTION: equivalent 12 MW + 5 MVAr; 9 MW MV + 3 MW LV';
 reason='IEC-style ILR/Ir screening; no detailed individual motor reactances or full network recalculation';
 specs={'load_MVA',totalS,'MVA';'MV_rated_A',P.MOTOR_MV_P_MW/pf*1e3/(sqrt(3)*P.MOTOR_MV_V_kV),'A'; ...
  'LV_rated_A',P.MOTOR_LV_P_MW/pf*1e3/(sqrt(3)*P.MOTOR_LV_V_kV),'A'; ...
  'MV_contribution_A',mult*P.MOTOR_MV_P_MW/pf*1e3/(sqrt(3)*P.MOTOR_MV_V_kV),'A'; ...
  'LV_contribution_A',mult*P.MOTOR_LV_P_MW/pf*1e3/(sqrt(3)*P.MOTOR_LV_V_kV),'A'; ...
  'contribution_230kV_A',mult*totalS*1e6/(sqrt(3)*230e3),'A'; ...
  'contribution_22kV_A',mult*totalS*1e6/(sqrt(3)*22e3),'A';'ILR_Ir',mult,'1'};
 for j=1:size(specs,1),emit('MOTOR',mult,role,'EQUIVALENT_MOTOR','SCREEN','SCREEN','SCREEN',specs{j,1},specs{j,2},specs{j,3},'ENGINEERING_ASSUMPTION',prov,reason);end
end

% 5P20 is a rated-burden accuracy-limit statement, not a knee-point curve.
% 75-percent transfer is deliberately an illustrative response perturbation,
% not an inferred saturation law or prediction of CT failure.
isHV=ismember(locs,{'F3','F4','F5'}); currents=double(T40.I_primary_A(isHV));
currents=currents(isfinite(currents)&currents>=0);
if isempty(currents),imax=2*P.CT_accuracy_boundary_A;else,imax=max(currents);end
ctcases=[0,max(imax,P.CT_accuracy_boundary_A),1;20,P.CT_accuracy_boundary_A,1;40,max(imax,2*P.CT_accuracy_boundary_A),P.CT_above_boundary_transfer];
for k=1:size(ctcases,1)
 x=ctcases(k,1);input=ctcases(k,2);transfer=ctcases(k,3);
 if x==0,role='IDEAL_REFERENCE';elseif x==20,role='ACCURACY_BOUNDARY';else,role='ABOVE_BOUNDARY_PROXY';end
 prov='CONDITIONAL_ASSUMPTION:1600/1 5P20 selected-core screening; actual excitation and burden unavailable';
 reason='Synthetic CT input-current perturbation based on HV-site fault envelope, not actual Q0 CT duty; 32 kA is nominal 20*In boundary, not automatic CT failure';
 relay('CT_SATURATION',x,role,'GSUT-HV-51','SCREEN','SCREEN','SCREEN',input*transfer,1600,hpk,htms,prov,reason);
 emit('CT_SATURATION',x,role,'GSUT-HV-51','SCREEN','SCREEN','SCREEN','actual_fault_current_A',input,'A','ENGINEERING_STUDY_PROXY',prov,reason);
 emit('CT_SATURATION',x,role,'GSUT-HV-51','SCREEN','SCREEN','SCREEN','transfer_factor',transfer,'1','ENGINEERING_STUDY_PROXY',prov,reason);
 emit('CT_SATURATION',x,role,'GSUT-HV-51','SCREEN','SCREEN','SCREEN','accuracy_boundary_A',32000,'A','DERIVED',prov,reason);
end
if nargin>=4 && ~isempty(varargin{1})
 qmax=breakermax(varargin{1});
 qbasis='maximum all-phase physical Q0 transformer-bay current across imported fault cases';
elseif height(T40)==40
 B=phase5b_cached_branches(T40);qmax=breakermax(B);
 qbasis='maximum all-phase physical Q0 transformer-bay current across identity-checked frozen fault cases';
else
 qmax=ihv;qbasis='balanced physical GSUT-HV branch probe for partial/synthetic input; not an all-fault maximum';
end
for rating=[50 63]
 role=roleof(rating,50);prov='CONDITIONAL_ASSUMPTION:Q0 mapped to transformer bay; 63 kA equipment sensitivity only';
 reason=['Conditional breaker branch screen using ' qbasis '; 63 kA is not evidence of installed Q0 rating'];
 emit('BREAKER_RATING',rating,role,'GIS-Q0','SCREEN','SCREEN','SCREEN','fault_kA',qmax/1000,'kA','DERIVED',prov,reason);
 emit('BREAKER_RATING',rating,role,'GIS-Q0','SCREEN','SCREEN','SCREEN','interrupting_rating_kA',rating,'kA','CONDITIONAL_ASSUMPTION',prov,reason);
 emit('BREAKER_RATING',rating,role,'GIS-Q0','SCREEN','SCREEN','SCREEN','duty_ratio',qmax/1000/rating,'1','DERIVED',prov,reason);
end
S=cell2table(rows,'VariableNames',{'family','scenario_value','case_role','scope','method', ...
 'device_id','fault_location','fault_type','caseID','metric','value','unit','status','provenance','reason'});
S.scenario_value=cell2mat(rows(:,2));S.value=cell2mat(rows(:,11));
assert(all(isfinite(S.value)),'phase5b_sensitivity:numeric','Every emitted metric must be finite');

 function relay(fam,x,role,dev,loc,typ,cs,current,ct,pickup,tms,prov,reason)
  if current>pickup,status='STUDY-TRIP';trip=1;else,status='NO-TRIP';trip=0;end
  vals={'I_primary_A',current,'A';'I_secondary_A',current/ct,'A';'ct_ratio',ct,'A/A'; ...
   'pickup_primary_A',pickup,'A';'pickup_secondary_A',pickup/ct,'A'; ...
   'pickup_margin',current/pickup,'1';'TMS',tms,'1';'trip_enabled',trip,'boolean'};
  for ii=1:size(vals,1),emit(fam,x,role,dev,loc,typ,cs,vals{ii,1},vals{ii,2},vals{ii,3},status,prov,reason);end
  if trip
   seconds=phase5_time(current/ct,pickup/ct,tms,'SI');
   emit(fam,x,role,dev,loc,typ,cs,'operating_time_s',seconds,'s',status,prov,reason);
  end
 end
 function grid(fam,x,role,isk,xr,zratio,zoverride)
  z=230e3/(sqrt(3)*isk*1000);if zoverride>0,z=zoverride;end
  r=z/sqrt(1+xr^2);xx=xr*r;kappa=1.02+0.98*exp(-3/xr);
  prov='DERIVED_FROM_SECONDARY_GRID_DATA central; ENGINEERING_SCREENING_ASSUMPTION variations';
  reason='Grid-only equivalent at 230 kV with c=1; frozen Phase-4 inputs unchanged; not current official PGCB data';
  if strcmp(fam,'GRID_REPORTED_Z')
   reason=[reason '; 3.25 ohm is inconsistent with 45.01 kA only on the same c=1 basis; implied c about1.1 could explain the discrepancy but source convention is unverified'];
   emit(fam,x,role,'PGCB_EQUIVALENT','SCREEN','SCREEN','SCREEN','implied_voltage_factor',3.25/P.GRID_Zth_ohm,'1','DERIVED',prov,reason);
  end
  vals={'Isc3ph_kA',isk,'kA';'Zth_ohm',z,'ohm';'Rth_ohm',r,'ohm';'Xth_ohm',xx,'ohm'; ...
   'XR',xr,'1';'Ssc_GVA',sqrt(3)*230*isk/1000,'GVA';'Z2_Z1',1,'1';'Z0_Z1',zratio,'1'; ...
   'R2_ohm',r,'ohm';'X2_ohm',xx,'ohm';'R0_ohm',zratio*r,'ohm';'X0_ohm',zratio*xx,'ohm'; ...
   'earth_fault_kA',3*isk/(2+zratio),'kA';'kappa',kappa,'1';'peak_current_kA',sqrt(2)*kappa*isk,'kA peak'; ...
   'Q0_50kA_grid_only_duty_ratio',isk/50,'1'};
  for ii=1:size(vals,1),emit(fam,x,role,'PGCB_EQUIVALENT','SCREEN','SCREEN','SCREEN',vals{ii,1},vals{ii,2},vals{ii,3},'ENGINEERING_SCREENING_ASSUMPTION',prov,reason);end
 end
 function emit(fam,x,role,dev,loc,typ,cs,metric,value,unit,status,prov,reason)
  assert(isfinite(value)&&isscalar(value)&&isreal(value),'phase5b_sensitivity:numeric','Metric %s must be finite real scalar',metric);
  rows(end+1,:)={fam,x,role,'SENSITIVITY',method,dev,loc,typ,cs,metric,value,unit,status,prov,reason};
 end
end
function val=readval(d,name,fallback)
val=double(d.(name));if ~isscalar(val)||~isfinite(val)||val<=0,val=fallback;end
end
function role=roleof(x,central)
if abs(x-central)<1e-10,role='CENTRAL_REFERENCE';else,role='SENSITIVITY_CASE';end
end
function current=breakermax(B)
k=strcmp(B.leg,'GSUT_HV');
assert(any(k),'phase5b_sensitivity:breaker','GSUT-HV branch required for Q0 breaker screen');
voltage=230*ones(sum(k),1);voltage(ismember(B.location(k),{'F1','F2'}))=22;
allPhase=max([B.Ia_A(k),B.Ib_A(k),B.Ic_A(k)],[],2);
current=max(allPhase.*voltage/230);
assert(isfinite(current)&&current>=0,'phase5b_sensitivity:breaker','Finite all-phase duty required');
end
function [current,prov]=neutral(T,k,typ)
if ismember('leg_NER_earth_kA',T.Properties.VariableNames)&&isfinite(T.leg_NER_earth_kA(k))
 if ismember(char(string(T.fault_location(k))),{'F1','F2'}),voltageScale=1;else,voltageScale=230/22;end
 current=3*double(T.leg_NER_earth_kA(k))*1000*voltageScale;
 prov='DERIVED:3*Phase-4 leg_NER_earth_kA*1000*Vfault/22kV; physical neutral residual counted once';
else
 if strcmp(typ,'LG'),current=7.27;else,current=3.635;end
 prov='ENGINEERING_STUDY_PROXY:7.27 A LG central from user study; LLG half-current screening because NER branch missing';
end
end
function [current,prov]=hvprobe(T,locs,typs,P)
current=[];
if ismember('leg_GSUT_HV_kA',T.Properties.VariableNames)
 for k=find(strcmp(typs,'LLL'))'
  x=double(T.leg_GSUT_HV_kA(k));
  if isfinite(x)&&x>0
   if ismember(locs{k},{'F1','F2'}),scale=22/230;else,scale=1;end
   current(end+1)=x*1000*scale; %#ok<AGROW>
  end
 end
end
if isempty(current)
 current=10*P.GSUT_rated_A;
 prov='ENGINEERING_STUDY_PROXY:10 times GSUT HV rated current for CT comparison; no usable balanced fault leg';
else
 current=max(current);
 prov='DERIVED:maximum frozen balanced GSUT_HV branch; fault base converted to physical HV 230 kV';
end
end
