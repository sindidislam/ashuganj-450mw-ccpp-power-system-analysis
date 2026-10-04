function [np,nf] = test_phase5b_effectiveness()
%TEST_PHASE5B_EFFECTIVENESS Physical-base screening and numerical study proxies.
T = t_case('test_phase5b_effectiveness');
T40 = phase5_import(ashuganj_root()); R = phase5b_registry();
E = phase5b_effectiveness(T40,R.devices);
old = {'fault_location','fault_type','caseID','primary_function','primary_availability', ...
    'primary_time_s','backup_function','backup_time_s','ct_source','setting_source', ...
    'detection','determinable','not_determinable'};
T = T.chk(isequal(E.Properties.VariableNames(1:13),old),'original 13 columns retained first');
T = T.chk(height(E)==48,'40 cases plus eight generator definite-time comparators');
T = T.chk(~any(isnan(E.primary_time_s)) && ~any(isnan(E.backup_time_s)), 'required timing is numerical; Inf means no trip or no mapped pair');
T = T.chk(~any(contains(E.detection,'ASSERTABLE')),'screening makes no manufacturer-operation claim');
g = getrow(E,'F1','LLL','GEN-51-SI');
T = T.chk(strcmp(g.detection,'CONDITIONAL-DETECTABILITY') && abs(g.primary_time_s-.045)<1e-12,'87G positive screening uses a 45 ms study operate proxy');
T = T.chk(g.backup_time_s>.5 && g.backup_time_s<.7,'GEN phase backup retains the actual branch time');
lg = getrow(E,'F1','LG','GEN-51N-SI-STUDY');
T = T.chk(strcmp(lg.detection,'NO-TRIP') && isinf(lg.primary_time_s),'F1 LG below 87G pickup is an explicit no trip');
T = T.chk(lg.backup_time_s>1.5 && lg.backup_time_s<2,'F1 LG 4 A neutral backup operates on 7.27 A via dedicated 20/1 CT');
t = getrow(E,'F2','LLL','GSUT-HV-51');
T = T.chk(strcmp(t.detection,'CONDITIONAL-DETECTABILITY') && abs(t.primary_time_s-.045)<1e-12,'87T executes conditional detectability with 45 ms study proxy');
T = T.chk(t.backup_time_s>2.2 && t.backup_time_s<2.5,'F2 HV backup uses about 6.897 kA on its own 230 kV base');
tlg = E(strcmp(E.fault_location,'F2') & strcmp(E.fault_type,'LG'),:);
T = T.chk(height(tlg)==2 && all(strcmp(tlg.detection,'NO-TRIP')) && all(isinf(tlg.primary_time_s)), ...
    'both F2 LG cases use incremental earth current and do not establish differential detection from through-load');
tlgOut = getrow(E,'F2','LG','GSUT-HV-51');
T = T.chk(abs(tlgOut.primary_current_A-0.69558303224267)<1e-10 && tlgOut.primary_current_A<tlgOut.primary_pickup_A, ...
    'F2 LG 7.272 A neutral earth proxy is 0.695583 A on the 230 kV comparison base');
llg = E(strcmp(E.fault_type,'LLG') & ~strcmp(E.scope,'SENSITIVITY'),:);
T = T.chk(all(contains(llg.not_determinable,'phase backup')) && all(contains(llg.not_determinable,'neutral evaluated separately in matrix')) && ~any(contains(llg.not_determinable,'out-of-51N-scope')), ...
    'LLG row notes identify phase backup and preserve the separate matrix neutral evaluation');
b = getrow(E,'F3','LLL','GIS-Q0-51');
T = T.chk(strcmp(b.detection,'CONDITIONAL-DETECTABILITY') && abs(b.primary_time_s-.035)<1e-12,'87B executes 320 A screening and 35 ms study proxy');
f = getrow(E,'F4','LL','GIS-Q0-51');
T = T.chk(strcmp(f.detection,'CONDITIONAL-DETECTABILITY') && abs(f.primary_time_s-.035)<1e-12,'line uses B/C faulted section currents and 35 ms study proxy');
r = getrow(E,'F5','LLL','GIS-Q0-51');
T = T.chk(strcmp(r.detection,'NO-PAIR/OUT-OF-ZONE') && isinf(r.primary_time_s),'F5 explicitly has no mapped primary pair');
bl = E(strcmp(E.backup_function,'GEN-51-SIEMENS-BL'),:);
T = T.chk(all(bl.backup_time_s(~strcmp(bl.fault_type,'LG'))==3) && all(isinf(bl.backup_time_s(strcmp(bl.fault_type,'LG')))), 'DT comparator numerically returns 3 s above pickup and Inf below');
added = {'scope','time_basis','primary_pickup_A','primary_current_A', ...
    'primary_operate_proxy_s','primary_breaker_proxy_s','backup_current_A','backup_pickup_A', ...
    'supplementary_function','supplementary_time_s','supplementary_basis'};
has = all(ismember(added,E.Properties.VariableNames));
T = T.chk(has,'numeric assumptions and time scope are explicit columns');
if has
    T = T.chk(all(contains(E.time_basis,'ENGINEERING_STUDY_PROXY')),'timing provenance is explicit');
    T = T.chk(abs(t.primary_pickup_A-387.84)<1e-9 && t.primary_current_A>5000 && t.primary_current_A<5300,'87T compares both currents on same HV base and uses 387.84 A threshold');
    T = T.chk(abs(b.primary_pickup_A-320)<1e-12 && abs(f.primary_pickup_A-320)<1e-12,'87B and line threshold use adopted 1600 A CT base');
    T = T.chk(abs(f.primary_breaker_proxy_s-.05)<1e-12,'line 50 ms breaker-clearing proxy remains separate from 35 ms operate proxy');
    T = T.chk(strcmp(lg.supplementary_function,'GEN-64G') && lg.supplementary_time_s==1 && contains(lg.supplementary_basis,'20Hz') && contains(lg.supplementary_basis,'not simulated'),'64G 1 s proxy never treats a 50 Hz fault as a 20 Hz injection test');
    T = T.chk(abs(lg.backup_pickup_A-4)<1e-12 && lg.backup_current_A>7.2 && lg.backup_current_A<7.3,'neutral current and pickup remain independently auditable');
    T = T.chk(all(strcmp(bl.scope,'SENSITIVITY')),'unverified 3 s comparator is isolated as sensitivity');
end
% The registry owns proxy timing. Different adopted timers must propagate
% without changing phase currents or claiming a simulated 20 Hz response.
B=phase5b_cached_branches(T40);
shifted=R.devices;
shifted(strcmp({shifted.device_id},'LINE-7SD')).trip_delay_s=.063;
shifted(strcmp({shifted.device_id},'GEN-64G')).trip_delay_s=1.25;
sub=strcmp(T40.caseID,'LF360_GAT_OUT') & ((strcmp(T40.fault_location,'F4') & strcmp(T40.fault_type,'LL')) | (strcmp(T40.fault_location,'F1') & strcmp(T40.fault_type,'LG')));
Es=phase5b_effectiveness(T40(sub,:),shifted,B);
ls=getrow(Es,'F4','LL','GIS-Q0-51'); gs=getrow(Es,'F1','LG','GEN-51N-SI-STUDY');
T=T.chk(abs(ls.primary_breaker_proxy_s-.063)<1e-12,'line clearing proxy follows the registry timer');
T=T.chk(abs(gs.supplementary_time_s-1.25)<1e-12,'64G supplementary proxy follows the registry timer');
% A deliberately small LV terminal must fail the HV pickup comparison.
sub=strcmp(T40.caseID,'LF360_GAT_OUT') & strcmp(T40.fault_location,'F2') & strcmp(T40.fault_type,'LLL');
Bs=B; hit=strcmp(Bs.caseID,'LF360_GAT_OUT') & strcmp(Bs.location,'F2') & strcmp(Bs.fault_type,'LLL') & strcmp(Bs.leg,'GEN');
Bs{hit,{'Ia_A','Ib_A','Ic_A','Ibranch_faulted_A'}}=2000*ones(1,4);
Et=phase5b_effectiveness(T40(sub,:),R.devices,Bs);
T=T.chk(strcmp(Et.detection{1},'NO-TRIP') && abs(Et.primary_current_A-191.304347826087)<1e-9,'2 kA LV terminal is only 191.3 A on HV base, below 387.84 A pickup');
try
    phase5b_effectiveness(table(),R.devices); T = T.chk(false,'empty table rejected');
catch ME
    T = T.chk(startsWith(ME.identifier,'phase5b_effectiveness'),'schema error is scoped');
end
[np,nf] = T.done();
end
function r=getrow(E,loc,typ,backup)
hit=strcmp(E.fault_location,loc)&strcmp(E.fault_type,typ)&strcmp(E.caseID,'LF360_GAT_OUT')&strcmp(E.backup_function,backup);
assert(sum(hit)==1,'Expected exactly one effectiveness row.');
r=table2struct(E(hit,:));
end
