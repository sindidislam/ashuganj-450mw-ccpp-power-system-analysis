function [np,nf]=test_phase5b_registry()
% Active study settings are numerical; documentary ratings remain distinct.
T=t_case('test_phase5b_registry'); R=phase5b_registry(); d=R.devices;
need={'device_id','ct_ratio','pickup_A','rated_A','tms','curve','provenance','assumption_class', ...
 'physical_CT_ratio','study_CT_ratio','selected_CT_core','maximum_load_anchor_A','pickup_pu', ...
 'operate_proxy_s','trip_delay_s','highset_enabled','actual_installed_setting_verified'};
T=T.chk(all(isfield(d,need)),'registry retains settings and explicit study/provenance metadata');
T=T.chk(numel(unique({d.device_id}))==numel(d),'device identifiers are unique');
ids={'GEN-51','GEN-51N','GSUT-HV-51','GIS-Q0-51'};
cts=[15000,20,1600,1600]; picks=[17170.8,4,1380,1500]; tm=[.10,.15,.55,.80];
for k=1:numel(ids)
 r=d(strcmp({d.device_id},ids{k}));
 T=T.chk(isscalar(r)&&r.ct_ratio==cts(k)&&r.study_CT_ratio==cts(k),[ids{k} ' uses its dedicated physical/study CT basis']);
 T=T.chk(abs(r.pickup_A-picks(k))<1e-9&&abs(r.tms-tm(k))<1e-12&&strcmp(r.curve,'SI'),[ids{k} ' has executable adopted SI settings']);
 T=T.chk(~r.actual_installed_setting_verified&&strlength(string(r.provenance))>0,[ids{k} ' study setting is not promoted to installed verification']);
end
g=d(strcmp({d.device_id},'GSUT-HV-51'));
T=T.chk(abs(g.rated_A-1292.8)<1e-9&&g.maximum_load_anchor_A>1149&&g.maximum_load_anchor_A<1150,'GSUT rated current remains separate from the maximum-load anchor');
T=T.chk(abs(g.maximum_load_anchor_A-458e6/(sqrt(3)*230e3))<1e-9,'GSUT through-load anchor derives from 458 MVA at 230 kV');
T=T.chk(strcmp(g.ct_source,'ENGINEERING_ASSUMPTION')&&isnan(g.physical_CT_ratio)&&contains(g.provenance,'1500')&&contains(g.provenance,'1600'),'1600/1 study CT retains the documentary 1500/1 conflict and unverified installed ratio');
q=d(strcmp({d.device_id},'GIS-Q0-51'));
T=T.chk(strcmp(q.assumption_class,'CONDITIONAL')&&strcmp(q.breaker_ref,'Q0'),'Q0 remains a conditional breaker mapping');
hi=d(strcmp({d.device_id},'GIS-Q0-50'));
T=T.chk(~hi.highset_enabled&&isnan(hi.pickup_A),'disabled high-set has no fictitious active pickup');
ps={'GEN-87G','GSUT-87T','GIS-87B','LINE-7SD'}; pp=[2403.8,387.84,320,320]; pt=[.045,.045,.035,.035];
for k=1:numel(ps)
 r=d(strcmp({d.device_id},ps{k}));
 T=T.chk(abs(r.pickup_A-pp(k))<1e-9&&abs(r.operate_proxy_s-pt(k))<1e-12&&~r.actual_installed_setting_verified,[ps{k} ' exposes numerical detectability and timing proxies without installed claims']);
end
t=d(strcmp({d.device_id},'GSUT-87T')); b=d(strcmp({d.device_id},'GIS-87B'));
T=T.chk(t.slope1_pct==30&&t.slope2_pct==60&&b.slope1_pct==30,'differential study slope references remain explicit');
dt=d(strcmp({d.device_id},'GEN-51-SIEMENS-BL'));
T=T.chk(strcmp(dt.assumption_class,'SENSITIVITY')&&dt.trip_delay_s==3&&~dt.actual_installed_setting_verified,'3 s comparator remains an unverified sensitivity case');
T=T.chk(R.gen.Imax_A==14309&&R.gen.Irated_A==12019&&R.gen.Snom_MVA==458,'generator maximum and rated values remain distinct');
T=T.chk(strcmp(R.topology.Q0,'breaker')&&strcmp(R.topology.Q9,'disconnector')&&strcmp(R.topology.Q8,'earthing'),'breaker, disconnector and earthing roles remain distinct');
T=T.chk(strcmp(R.topology.breaker_52G,'10BAC10')&&R.topology.rating_100kA==100,'52G identity and documentary symmetrical rating retained');
try,phase5b_registry(1);T=T.chk(false,'registry rejects arguments');catch ME,T=T.chk(strcmp(ME.identifier,'phase5b_registry:args'),'registry rejects arguments');end
try,phase5b_ct_scope();T=T.chk(false,'CT scope requires device');catch ME,T=T.chk(startsWith(ME.identifier,'phase5b'),'CT scope requires device');end
[np,nf]=T.done();
end
