function [P,A] = phase5b_parameters()
%PHASE5B_PARAMETERS Numerically closed Phase-5 engineering study inputs.
% P contains scalar finite numbers. A preserves a provenance record for each
% number. Study settings and defaults are not commissioned plant settings.
% These local study parameters do not modify the locked Phase-2/3/4 models.
P=struct(); rows=cell(0,12);
user='User master prompt, 2026-09-20';
gen='fwdtechnicaldatasldrequestforbueteeetermproject/Generator Data_South.pdf';
gsut='fwdtechnicaldatasldrequestforbueteeetermproject/GSUT Data Sheet_South.pdf';
book='fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj South (2).xlsx';
source=gen; section='PDF p.1 / report p.6, 2.1.1-2.1.2';
put('GEN_S_MVA',458,'MVA','VERIFIED','Generator technical/protection report',source,section,'direct rating');
put('GEN_V_kV',22,'kV','VERIFIED','Generator technical/protection report',source,section,'direct rating');
put('GEN_rated_A',12019,'A','VERIFIED','Generator technical/protection report',source,section,'documented rounded current');
put('GEN_maximum_operating_A',14309,'A','VERIFIED','Generator technical/protection report',source,section,'documented maximum current');
put('GEN_phase_CT',15000,'A/A','VERIFIED','Generator phase CT T1/T2 indication',source,section,'15000/1');
put('GEN_51_pickup_A',1.2*P.GEN_maximum_operating_A,'A','DERIVED','Maximum-through-load study philosophy',source,section,'1.20*14309');
put('GEN_51_secondary_A',P.GEN_51_pickup_A/P.GEN_phase_CT,'A','DERIVED','Primary pickup divided by phase CT',source,section,'17170.8/15000');
study('GEN_51_TMS',0.10,'1','ENGINEERING_ASSUMPTION','IEC Standard Inverse coordination starting value','0.08 to 0.15');
study('GEN_51N_CT',20,'A/A','ENGINEERING_ASSUMPTION','Dedicated sensitive neutral CT adopted; actual installed CT unavailable','10/1;20/1;25/1');
study('GEN_51N_secondary_A',0.20,'A','ENGINEERING_ASSUMPTION','Sensitive stator ground overcurrent study dial','4 A central;5 A sensitivity');
put('GEN_51N_pickup_A',P.GEN_51N_CT*P.GEN_51N_secondary_A,'A','DERIVED','Dedicated neutral CT study basis',user,'GEN-51N','20*0.20');
study('GEN_51N_TMS',0.15,'1','ENGINEERING_ASSUMPTION','IEC Standard Inverse neutral coordination starting value','0.10 to 0.25');
study('GEN_87G_pu',0.20,'pu','ENGINEERING_ASSUMPTION','Generator differential threshold for study detectability','Review commissioned bias/start characteristic');
put('GEN_87G_pickup_A',P.GEN_87G_pu*P.GEN_rated_A,'A','DERIVED','Study start on documented rated current',gen,section,'0.20*12019');
study('GEN_87G_highset_enabled',0,'boolean','ENGINEERING_ASSUMPTION','High-set OFF; not relied upon','Enable only with actual setting pages');
study('GEN_87G_time_s',0.045,'s','ENGINEERING_STUDY_PROXY','Detection/operation proxy; not measured manufacturer operation','Actual relay timing validation');

put('GEN_Xdpp_sat_pu',0.2248,'pu','VERIFIED','Workbook explicitly saturated entry',book,'Ashuganj South K3','direct machine-base value');
put('GEN_Xdpp_unsat_pu',0.2608,'pu','CONDITIONAL_ASSUMPTION','Workbook Xd double-prime unqualified; adopted unsaturated study interpretation',book,'Ashuganj South J3','raw Xd double-prime; saturation interpretation conditional');
put('GEN_X2_pu',0.2242,'pu','VERIFIED','Workbook saturated negative-sequence entry',book,'Ashuganj South P3','direct machine-base value');
put('GEN_X0_pu',0.1280,'pu','VERIFIED','Workbook zero-sequence entry',book,'Ashuganj South Q3','direct machine-base value');
put('GEN_Ra_ohm',0.00089,'ohm','VERIFIED','Workbook explicitly states ohm',book,'Ashuganj South U3','direct resistance; temperature not supplied');
put('GEN_R1_pu',P.GEN_Ra_ohm/(P.GEN_V_kV^2/P.GEN_S_MVA),'pu','DERIVED','Machine-base resistance conversion',book,'Ashuganj South C3,D3,U3','0.00089/(22^2/458)');
put('GEN_R2_pu',P.GEN_R1_pu,'pu','ENGINEERING_ASSUMPTION','Missing negative-sequence resistance represented as R1',user,'Generator sequence resistance','R2=R1');
put('GEN_R0_pu',1.5*P.GEN_R1_pu,'pu','ENGINEERING_ASSUMPTION','Preliminary zero-sequence resistance estimate',user,'Generator sequence resistance','R0=1.5*R1');

put('GSUT_S_MVA',515,'MVA','VERIFIED','GSUT technical rating',gsut,'PDF p.3 technical p.1','direct rating');
put('GSUT_HV_kV',230,'kV','VERIFIED','GSUT technical rating',gsut,'PDF p.3 technical p.1','direct rated winding voltage');
put('GSUT_LV_kV',22,'kV','VERIFIED','GSUT technical rating',gsut,'PDF p.3 technical p.1','direct rated winding voltage');
put('GSUT_rated_exact_A',P.GSUT_S_MVA*1e6/(sqrt(3)*P.GSUT_HV_kV*1000),'A','DERIVED','GSUT nameplate current',gsut,'515 MVA and 230 kV rating','515e6/(sqrt(3)*230e3)');
put('GSUT_rated_A',round(P.GSUT_rated_exact_A,1),'A','DERIVED','Rounded nameplate current used as differential base',gsut,'515 MVA and 230 kV rating','round(515e6/(sqrt(3)*230e3),1)');
put('GSUT_maximum_load_anchor_A',P.GEN_S_MVA*1e6/(sqrt(3)*P.GSUT_HV_kV*1000),'A','DERIVED','Maximum-through-load study anchor; not GSUT rated current',gen,'Generator 458 MVA and GSUT 230 kV','458e6/(sqrt(3)*230e3)');
put('GSUT_CT',1600,'A/A','ENGINEERING_ASSUMPTION','Rev03 as-built SLD and nameplate indication; manufacturer datasheet separately indicates 1500/1','fwdtechnicaldatasldrequestforbueteeetermproject/GSUT Nameplate_South.pdf; GENERATION AND TRANSFORMERS SYSTEM.pdf; INEL-112070-00-ELC-DE-0001-REV3.pdf','Nameplate p.3; Rev03 generation/transformer SLD p.2; Rev3 main SLD p.2','central study 1600/1; exact installed protection core unverified','1500/1 documentary sensitivity;1600/1 central study');
put('GSUT_documentary_CT',1500,'A/A','SENSITIVITY','Manufacturer CT indication retained as documentary sensitivity',gsut,'PDF p.6 technical p.4, phase protection CT','1500/1; conflicts with as-built 1600/1');
put('GSUT_51_pickup_A',1380,'A','DERIVED','Maximum-through-load pickup rounded for study',gen,'458 MVA through-load anchor','round(1.20*458e6/(sqrt(3)*230e3)/10)*10');
put('GSUT_51_secondary_A',P.GSUT_51_pickup_A/P.GSUT_CT,'A','DERIVED','Study primary pickup divided by study CT',user,'GSUT-51','1380/1600');
study('GSUT_51_TMS',0.55,'1','ENGINEERING_ASSUMPTION','IEC Standard Inverse coordination starting value','0.40 to 0.80');
study('GSUT_87T_pu',0.30,'pu','ENGINEERING_STUDY_PROXY','Study detectability threshold; no full 7UT differential algorithm','Actual matching/vector compensation/restraint/saturation review');
put('GSUT_87T_pickup_A',P.GSUT_87T_pu*P.GSUT_rated_A,'A','DERIVED','Study threshold on HV nameplate base',user,'GSUT 87T','0.30*1292.8');
study('GSUT_87T_slope1_percent',30,'%','ENGINEERING_STUDY_PROXY','Preliminary percentage characteristic reference','Full differential algorithm and actual settings');
study('GSUT_87T_slope2_percent',60,'%','ENGINEERING_STUDY_PROXY','Preliminary percentage characteristic reference','Full differential algorithm and actual settings');
study('GSUT_87T_time_s',0.045,'s','ENGINEERING_STUDY_PROXY','Study detection/operation timing proxy; not verified 7UT6331 timing','Actual relay timing validation');
put('GSUT_Z1_pu',0.1663,'pu','CONDITIONAL_ASSUMPTION','Workbook study value; manufacturer design sheet separately gives 16 percent',book,'Ashuganj South (trailing space) AO3; header percent Z or pu','adopt existing workbook 0.1663 pu interpretation; not nameplate proven');
put('GSUT_copper_loss_MW',0.9122,'MW','DERIVED','Workbook total minus no-load loss; manufacturer design sheet separately gives 1095 kW',book,'Ashuganj South AN3-AL3','(1067.5-155.3)/1000');
put('GSUT_OEM_Z1_pu',0.16,'pu','SENSITIVITY','Manufacturer design impedance differs from adopted workbook value',gsut,'PDF p.3 technical p.1','16 percent design impedance; documentary sensitivity');
put('GSUT_OEM_copper_loss_MW',1.095,'MW','SENSITIVITY','Manufacturer design copper loss differs from workbook-derived loss',gsut,'PDF p.6 technical p.4','1095 kW/1000; documentary sensitivity');
put('GSUT_R1_pu',P.GSUT_copper_loss_MW/P.GSUT_S_MVA,'pu','DERIVED','Copper-loss per-unit resistance',book,'Ashuganj South AK3,AN3,AL3','0.9122/515');
put('GSUT_X1_pu',sqrt(P.GSUT_Z1_pu^2-P.GSUT_R1_pu^2),'pu','DERIVED','Series leakage reactance',book,'Ashuganj South AO3,AN3,AL3','sqrt(0.1663^2-R1^2)');
put('GSUT_vector_clock',1,'clock','VERIFIED','YNd1 connection',gsut,'Technical data vector group','YNd1 clock number; delta blocks zero-sequence transfer');
put('GSUT_HV_solid_grounded',1,'boolean','VERIFIED','Workbook solid-grounded entry and YNd1 topology',book,'Ashuganj South AP3,AQ3','HV grounded star; LV delta does not pass zero sequence');

study('Q0_CT',1600,'A/A','CONDITIONAL_ASSUMPTION','Transformer-outlet protection CT for assumed Q0 bay mapping','Actual bay/core schedule confirmation');
study('Q0_51_pickup_A',1500,'A','CONDITIONAL_ASSUMPTION','Practical above 1292.8 A rated load and below 2000 A bay continuous class','Actual commissioned setting unavailable');
put('Q0_51_secondary_A',P.Q0_51_pickup_A/P.Q0_CT,'A','DERIVED','Conditional Q0 pickup on study CT',user,'Q0 transformer outlet','1500/1600');
study('Q0_51_TMS',0.80,'1','CONDITIONAL_ASSUMPTION','IEC Standard Inverse starting value with conditional bay mapping','0.60 to 1.00');
for b={{'Q0_continuous_A',2000,'A'},{'Q0_interrupting_kA',50,'kA rms'},{'Q0_making_kA',125,'kA peak'},{'Q0_shortcircuit_s',3,'s'}}
 q=b{1};put(q{1},q{2},q{3},'CONDITIONAL_ASSUMPTION','Transformer-bay breaker class; exact Q0 physical mapping not independently proven','tmp/rev3_newsrc/Data Sheet_230KV.pdf','PDF p.10 transformer-bay circuit-breaker ratings','conditional transformer-bay mapping; no substitution with 63 kA');
end
study('BUS_87B_pu',0.20,'pu','ENGINEERING_STUDY_PROXY','Practical bus differential study threshold','Actual 7SS523 commissioning values');
study('BUS_87B_base_A',1600,'A','ENGINEERING_STUDY_PROXY','Selected GIS CT primary base for study pickup','GIS selected-core confirmation');
put('BUS_87B_pickup_A',P.BUS_87B_pu*P.BUS_87B_base_A,'A','DERIVED','Numerical study bus differential proxy',user,'87B','0.20*1600');
study('BUS_87B_slope_percent',30,'%','ENGINEERING_STUDY_PROXY','Preliminary study characteristic','Actual percentage/characteristic confirmation');
study('BUS_87B_time_s',0.035,'s','ENGINEERING_STUDY_PROXY','Bus detection/operation proxy','Actual relay timing validation');
study('LINE_87L_pu',0.20,'pu','ENGINEERING_STUDY_PROXY','7SD5221 primary line differential system proxy','Actual pickup/bias/compensation/comms/remote settings');
study('LINE_87L_base_A',1600,'A','ENGINEERING_STUDY_PROXY','Selected GIS CT base for line study proxy','Actual selected CT ratio');
put('LINE_87L_pickup_A',P.LINE_87L_pu*P.LINE_87L_base_A,'A','DERIVED','Primary-current differential study threshold',user,'7SD5221','0.20*1600');
study('LINE_87L_time_s',0.035,'s','ENGINEERING_STUDY_PROXY','7SD5221 detection/operation proxy','Actual local/remote relay timing');
study('LINE_87L_clearing_s',0.050,'s','ENGINEERING_STUDY_PROXY','System-level line scheme clearing proxy','Actual breaker and communication delay');
study('BF_230kV_s',0.15,'s','ENGINEERING_ASSUMPTION','Preliminary 230 kV 50BF delay, not commissioned timer','Actual trip/auxiliary contacts and breaker timing');
study('BF_22kV_s',0.12,'s','ENGINEERING_ASSUMPTION','Preliminary generator breaker 50BF delay, not commissioned timer','Actual GCB trip/auxiliary timing');
study('CTI_s',0.30,'s','ENGINEERING_STUDY_CRITERION','Central coordination criterion, not installed relay parameter','Timing tolerance and utility criterion review');

for b={{'GEN_64G_U20min_V',1,'V'},{'GEN_64G_I20min_A',0.010,'A'},{'GEN_64G_trip_R_ohm',20,'ohm'},{'GEN_64G_alarm_R_ohm',100,'ohm'},{'GEN_64G_trip_delay_s',1,'s'},{'GEN_64G_alarm_delay_s',10,'s'},{'GEN_64G_correction_angle_deg',0,'deg'}}
 q=b{1};put(q{1},q{2},q{3},'MANUFACTURER_DEFAULT_STUDY_VALUE','Manufacturer-default origin asserted by user; local manual not verified. Siemens 7UM62 study value adopted without commissioning claim',user,'64G default dataset; manufacturer-page verification pending','adopt supplied default numerically; not commissioned setting');
end
put('NER_R_ohm',60,'ohm','CONDITIONAL_ASSUMPTION','Documented/qualified RHV-DC entry marked question; adopted central winding-resistance component',gen,'PDF p.2 / report p.7, 2.3','60 ohm is HV-winding DC resistance, not effective stator-neutral resistance; inverse-current sensitivity uses complete effective resistance','57/60/63 ohm HV DC component; reflected LV loading retained; as-installed measurement unavailable');
put('NER_rating_kVA',135,'kVA','VERIFIED','Generator neutral-grounding transformer short-time rating',gen,'PDF p.2 / report p.7, 2.3','documented rating');
put('NER_duration_s',20,'s','VERIFIED','Generator neutral-grounding transformer short-time rating',gen,'PDF p.2 / report p.7, 2.3','documented duration');
put('NER_primary_kV',22/sqrt(3),'kV','DERIVED','Neutral-grounding transformer winding voltage',gen,'PDF p.2 / report p.7, 2.3','22/sqrt(3)');
put('NER_secondary_V',500,'V','VERIFIED','Neutral-grounding transformer secondary',gen,'PDF p.2 / report p.7, 2.3','documented voltage');
put('NGT_ratio',P.NER_primary_kV*1000/P.NER_secondary_V,'1','DERIVED','Neutral-grounding transformer voltage ratio',gen,'PDF p.2 / report p.7, 2.3','(22000/sqrt(3))/500');
put('NER_loading_LV_ohm',2.62,'ohm','CONDITIONAL_ASSUMPTION','Secondary loading-resistor entry marked double question; retained frozen study interpretation',gen,'PDF p.2 / report p.7, 2.3','qualified 2.62 ohm LV loading resistor');
put('NER_effective_HV_ohm',P.NER_R_ohm+P.NGT_ratio^2*P.NER_loading_LV_ohm,'ohm','DERIVED','Additive qualified HV-winding DC and reflected LV loading resistor; matches locked Phase-4 grounding','matlab/phase4/phase4_grounding.m; fwdtechnicaldatasldrequestforbueteeetermproject/Generator Data_South.pdf','primary grounding variant; source PDF p.2 / report p.7, 2.3','60+(22000/sqrt(3)/500)^2*2.62; not a measured effective neutral resistance','57/60/63 ohm HV DC component; reflected 2.62 ohm loading fixed');

put('SOUTH_length_km',0.7,'km','ENGINEERING_ASSUMPTION','Existing project study profile; original local route survey not located','Ashuganj_South_Final_Master_Data_and_Assumptions.pdf','p.2 South connection study line table','adopt 0.7 km from user/frozen study profile; no original PGCB route proof');
put('SOUTH_circuits',2,'count','ENGINEERING_ASSUMPTION','Existing project study profile; original local route survey not located','Ashuganj_South_Final_Master_Data_and_Assumptions.pdf','p.2 South connection study line table','adopt two circuits from user/frozen study profile');
for b={{'R1',0.080,'ohm/km'},{'X1',0.350,'ohm/km'},{'B1',4.2,'uS/km'},{'R0',0.250,'ohm/km'},{'X0',1.20,'ohm/km'},{'B0',2.8,'uS/km'}}
 q=b{1};study(['SOUTH_' q{1} '_per_km'],q{2},q{3},'ENGINEERING_ASSUMPTION','Practical preliminary line electrical data; exact conductor/tower geometry unavailable','Sensitivity to actual line geometry/electrical test data');
 if q{1}(1)=='B',u='uS';else,u='ohm';end
 put(['SOUTH_' q{1} '_total_' u],P.SOUTH_length_km*q{2},u,'DERIVED','Per-circuit impedance/admittance; two circuits stored separately',user,'South 0.7 km line',['0.7*' num2str(q{2},12)]);
end
for z=1:3
 ratios=[0.8 1.2 2];times=[0 0.30 0.80];
 study(sprintf('DIST21_zone%d_fraction',z),ratios(z),'1','ENGINEERING_STUDY_PROXY','Distance backup reach; line differential is primary','Actual 21 scheme and short-line accuracy review');
 put(sprintf('DIST21_zone%d_R_ohm',z),ratios(z)*P.SOUTH_R1_total_ohm,'ohm','DERIVED','Backup distance reach on per-circuit line impedance',user,'Distance 21',[num2str(ratios(z)) '*0.056']);
 put(sprintf('DIST21_zone%d_X_ohm',z),ratios(z)*P.SOUTH_X1_total_ohm,'ohm','DERIVED','Backup distance reach on per-circuit line impedance',user,'Distance 21',[num2str(ratios(z)) '*0.245']);
 study(sprintf('DIST21_zone%d_time_s',z),times(z),'s','ENGINEERING_STUDY_PROXY','Backup distance delay; zero denotes instantaneous study stage','Actual commissioned reach and timer pages');
end
% Regional line impedances are per circuit; circuit count is never an
% implicit division of these values. Source conductor descriptions are not
% invented for the undocumented short South connection.
regional={ 'NORTH_BHULTA',69,0.031,0.320,0.280,1.150,'Twin Finch 1113 MCM'; ...
 'GHORASAL_ASHUGANJ_230',44,0.0855,0.40,0.25,1.45,'Mallard 795 MCM'; ...
 'ASHUGANJ_COMILLA_NORTH',79,0.062,0.40,0.25,1.45,'Finch 1113 MCM'; ...
 'ASHUGANJ_SIRAJGANJ',144,0.065,0.340,0.240,1.250,'Twin AAAC'; ...
 'ASHUGANJ_KISHOREGANJ',52,0.083,0.380,0.250,1.450,'ACCC Grosbeak 636'};
for r=1:size(regional,1)
 prefix=regional{r,1};len=regional{r,2};
 volts=[400 230 230 230 132];pages=[1 2 2 2 4];sn=[5 3 5 16 25];
 citation=sprintf('PDF p.%d, %g kV table row %d',pages(r),volts(r),sn(r));
 put([prefix '_length_km'],len,'km','VERIFIED',['Source line length; conductor ' regional{r,7}],'fwdtechnicaldatasldrequestforbueteeetermproject/Line data.pdf',citation,'direct length; 230 kV Ghorasal line distinct from 132 kV line');
 put([prefix '_circuits'],2,'count','VERIFIED','Source double-circuit route','fwdtechnicaldatasldrequestforbueteeetermproject/Line data.pdf',citation,'two circuits');
 put([prefix '_voltage_kV'],volts(r),'kV','VERIFIED','Original table voltage class; Kishoreganj is 132 kV, not 230 kV','fwdtechnicaldatasldrequestforbueteeetermproject/Line data.pdf',citation,'source voltage class; regional references not inserted into South equivalent');
 seqs={'R1','X1','R0','X0'};
 for j=1:4
  val=regional{r,j+2};
  study([prefix '_' seqs{j} '_ohm_per_km'],val,'ohm/km','ENGINEERING_ASSUMPTION','Retained practical regional line electrical screening value','Actual conductor geometry and sequence parameters');
  put([prefix '_' seqs{j} '_total_ohm'],len*val,'ohm','DERIVED','Source length times study per-km electrical value',user,prefix,[num2str(len) '*' num2str(val)]);
 end
end

gridbasis='Secondary historical Ashuganj South fault level; not official current PGCB Thevenin';
gridsrc='Ashuganj_South_Final_Master_Data_and_Assumptions.pdf';
put('GRID_Isc_kA',45.01,'kA','DERIVED_FROM_SECONDARY_GRID_DATA',gridbasis,gridsrc,'p.2 section 8; p.4 W5 cites secondary 2019 compilation','adopt documented secondary fault level','30/40/45.01/50 kA grid-only screening');
put('GRID_XR',10.99,'1','DERIVED_FROM_SECONDARY_GRID_DATA',gridbasis,gridsrc,'p.2 section 8; p.4 W5 cites secondary 2019 compilation','reported secondary X/R','X/R 5/10.99/20 grid-only screening');
put('GRID_Zth_ohm',230e3/(sqrt(3)*P.GRID_Isc_kA*1000),'ohm','DERIVED_FROM_SECONDARY_GRID_DATA',gridbasis,gridsrc,'Secondary grid derivation','230000/(sqrt(3)*45010)');
put('GRID_Rth_ohm',P.GRID_Zth_ohm/sqrt(1+P.GRID_XR^2),'ohm','DERIVED_FROM_SECONDARY_GRID_DATA',gridbasis,gridsrc,'Secondary grid derivation','Zth/sqrt(1+10.99^2)');
put('GRID_Xth_ohm',P.GRID_XR*P.GRID_Rth_ohm,'ohm','DERIVED_FROM_SECONDARY_GRID_DATA',gridbasis,gridsrc,'Secondary grid derivation','10.99*Rth');
put('GRID_Ssc_GVA',sqrt(3)*230*P.GRID_Isc_kA/1000,'GVA','DERIVED_FROM_SECONDARY_GRID_DATA',gridbasis,gridsrc,'Secondary grid derivation','sqrt(3)*230kV*45.01kA');
put('GRID_reported_Z_ohm',3.25,'ohm','SENSITIVITY','Conflicting secondary source impedance at c=1; implied c about1.1 could explain the difference but source convention is unverified',gridsrc,'Secondary grid conflict','3.25/Zth(c=1) is implied voltage factor; central remains 45.01 kA-derived');
study('GRID_Z2_Z1_ratio',1,'1','ENGINEERING_SCREENING_ASSUMPTION','No PGCB negative-sequence equivalent available; Z2=Z1','PGCB sequence-equivalent verification');
study('GRID_Z0_Z1_ratio',3,'1','ENGINEERING_SCREENING_ASSUMPTION','Central screening Z0=3Z1, not PGCB data','Z0/Z1=2;3;4');
for z=2:3
 if z==2,mult=1;seq=2;else,mult=3;seq=0;end
 put(sprintf('GRID_R%d_ohm',seq),mult*P.GRID_Rth_ohm,'ohm','ENGINEERING_SCREENING_ASSUMPTION','Preliminary grid sequence screening equivalent',user,'Grid sequence assumptions',sprintf('%g*Rth',mult));
 put(sprintf('GRID_X%d_ohm',seq),mult*P.GRID_Xth_ohm,'ohm','ENGINEERING_SCREENING_ASSUMPTION','Preliminary grid sequence screening equivalent',user,'Grid sequence assumptions',sprintf('%g*Xth',mult));
end
put('MOTOR_P_MW',12,'MW','ENGINEERING_ASSUMPTION','Equivalent plant auxiliary active load; individual motor schedules unavailable','Ashuganj_South_Final_Master_Data_and_Assumptions.pdf','p.2 section 9, explicitly engineering assumption','adopt 12 MW preliminary aggregate','MV/LV split and contribution ILR/Ir=4;5;6');
put('MOTOR_Q_Mvar',5,'MVAr','ENGINEERING_ASSUMPTION','Equivalent plant auxiliary reactive load','Ashuganj_South_Final_Master_Data_and_Assumptions.pdf','p.2 section 9, explicitly engineering assumption','adopt 5 MVAr preliminary aggregate','Actual auxiliary load and motor schedule');
study('MOTOR_MV_P_MW',9,'MW','ENGINEERING_ASSUMPTION','MV-motor-dominated aggregate load component','No invented individual motor reactances');
study('MOTOR_LV_P_MW',3,'MW','ENGINEERING_ASSUMPTION','LV aggregate load component','No invented individual motor reactances');
study('MOTOR_MV_V_kV',6.6,'kV','ENGINEERING_ASSUMPTION','Equivalent MV motor terminal voltage','SLD auxiliary bus connection verification');
study('MOTOR_LV_V_kV',0.4,'kV','ENGINEERING_ASSUMPTION','Equivalent LV motor terminal voltage','SLD LV bus connection verification');
study('MOTOR_ILR_Ir',5,'1','ENGINEERING_ASSUMPTION','IEC-style screening locked-rotor/current ratio','ILR/Ir=4;5;6');
put('CT_accuracy_limit_factor',20,'1','CONDITIONAL_ASSUMPTION','5P20 class from CT documentation; exact selected core/burden not established','fwdtechnicaldatasldrequestforbueteeetermproject/GSUT Nameplate_South.pdf','p.3 HV protection CT','nominal accuracy-limit factor');
put('CT_accuracy_boundary_A',P.CT_accuracy_limit_factor*P.GSUT_CT,'A','DERIVED','Nominal 5P20 screening boundary, not automatic failure threshold','fwdtechnicaldatasldrequestforbueteeetermproject/GSUT Nameplate_South.pdf','p.3 HV protection CT','20*1600=32000');
study('CT_above_boundary_transfer',0.75,'1','ENGINEERING_STUDY_PROXY','Illustrative high-current attenuation sensitivity; no precise knee point inferred','Ideal versus 75 percent transfer; actual excitation/burden tests');

A=cell2table(rows,'VariableNames',{'parameter','value','unit','status','basis','source_file', ...
 'source_section','derivation','engineering_reason','sensitivity','verification_required','actual_installed_value_verified'});
A.value=cell2mat(rows(:,2));
assert(all(isfinite(A.value)),'phase5b_parameters:numeric','Study parameters must be finite');

 function study(name,val,unit,status,basis,sens)
  put(name,val,unit,status,basis,user,'Final Phase-5 engineering correction','adopted study value',sens);
 end
 function put(name,val,unit,status,basis,src,sect,deriv,sens)
  if nargin<9,sens='Central value; related numerical sensitivities in phase5_sensitivity.csv';end
  assert(isscalar(val)&&isreal(val)&&isfinite(val),'phase5b_parameters:numeric','%s must be a finite real scalar',name);
  assert(~isfield(P,name),'phase5b_parameters:duplicate','Duplicate parameter %s',name);
  P.(name)=double(val);
  if strcmp(status,'VERIFIED'),verified='YES_DOCUMENTARY';verify='Confirm as-installed configuration if applied to commissioning';
  else,verified='NO';verify='Actual installed setting or source qualification must be verified before commissioning';end
  reason=basis;
  if strcmp(status,'MANUFACTURER_DEFAULT_STUDY_VALUE')
   verify='Obtain exact 7UM62 manual page and commissioned setting; primary-test adjustment required';
   reason='User-provided manufacturer-default study value adopted; documentary validation pending';
  end
  rows(end+1,:)={name,double(val),unit,status,basis,src,sect,deriv,reason,sens,verify,verified};
 end
end
