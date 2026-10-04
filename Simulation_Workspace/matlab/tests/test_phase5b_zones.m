function [np,nf] = test_phase5b_zones()
%TEST_PHASE5B_ZONES Functional isolation paths, scope and export contract.
% Catches unresolved trip fields, loss of either generator/GSUT source path,
% whole-station bus tripping, invented line tags and unverified wiring claims.
T=t_case('test_phase5b_zones');
R=phase5b_registry(); Z=phase5b_zones(); ids={Z.device_id};
original={'zone','device_id','ansi','role','primary_for_fault', ...
    'trip_52G','trip_Q0','lockout_86','bf_path','note'};
extra={'status','subtype','action_condition','trip_other_breakers', ...
    'trip_excitation','trip_turbine','bf_timer_s','source', ...
    'actual_trip_wiring_verified'};
T=T.chk(isstruct(Z)&&all(isfield(Z,original)),'original zone/export fields retained');
hasExtra=all(isfield(Z,extra));
T=T.chk(hasExtra,'functional actions have typed scope, provenance and timers');
T=T.chk(numel(unique(ids))==numel(ids),'one functional row per registry device');
T=T.chk(all(ismember(ids,{R.devices.device_id})),'functional rows retain actual registry IDs');
T=T.chk(any(strcmp(ids,'GSUT-86')),'original GSUT-86 lockout inventory retained');
T=T.chk(any(strcmp(ids,'GEN-51N')),'confirmed neutral overcurrent has a functional trip row');
T=T.chk(all(ismember({'G','T','B','L'},unique({Z.zone}))),'four protection zones retained');
faults={'F1','F2','F3','F4'}; wants={'87G','87T','87B','7SD5221'};
for k=1:4
    hit=Z(strcmp({Z.primary_for_fault},faults{k}));
    T=T.chk(numel(hit)==1&&strcmp(hit.ansi,wants{k}),[faults{k} ' has its own primary function']);
end
for id={'GEN-87G','GEN-64G','GEN-51N'}
    hit=Z(strcmp(ids,id{1})); ok=numel(hit)==1;
    if ok
        ok=contains(hit.trip_52G,'52G')&&contains(hit.trip_52G,'10BAC10')&& ...
            contains(hit.trip_Q0,'10ADA10/D07')&&contains(hit.lockout_86,'86G');
    end
    T=T.chk(ok,[id{1} ' severe fault removes generator and grid energization']);
    if numel(hit)==1&&hasExtra
        T=T.chk(contains(hit.action_condition,'CONFIRMED')&&hit.trip_excitation&&hit.trip_turbine, ...
            [id{1} ' requires confirmed operation and shuts down unit sources']);
    end
end
zt=Z(strcmp(ids,'GSUT-87T'));
T=T.chk(numel(zt)==1&&contains(zt.trip_52G,'10BAC10')&& ...
    contains(zt.trip_Q0,'10ADA10/D07')&&contains(zt.lockout_86,'86T'), ...
    'transformer differential removes generator and HV source paths');
if hasExtra
    T=T.chk(contains(zt.trip_other_breakers,'52A-1'),'transformer isolation includes possible UAT backfeed');
    zb=Z(strcmp(ids,'GIS-87B'));
    T=T.chk(contains(zb.trip_Q0,'IF_CONNECTED')&&contains(zb.trip_other_breakers,'AFFECTED_SECTION')&& ...
        contains(zb.lockout_86,'AFFECTED_SECTION'), ...
        'bus differential isolates affected section without blanket station trip');
    zl=Z(strcmp(ids,'LINE-7SD'));
    T=T.chk(strcmp(zl.trip_52G,'NO_DIRECT_TRIP')&&contains(zl.trip_other_breakers,'LOCAL_AND_REMOTE_LINE_END'), ...
        'line differential trips its local and remote ends without direct generator trip');
    T=T.chk(contains(zl.trip_other_breakers,'EQUIVALENT_SET')&&contains(zl.note,'identities require verification'), ...
        'unavailable line breaker names remain an explicit functional set');
    zd=Z(strcmp(ids,'LINE-21-note'));
    T=T.chk(contains(zd.action_condition,'CONFIRMED_ZONE_OPERATION'), ...
        'selected distance reaches lead to a confirmed zone trip condition');
    T=T.chk(contains(zd.trip_other_breakers,'LOCAL_LINE_END')&&strcmp(zd.trip_Q0,'NO_DIRECT_TRANSFORMER_BAY_TRIP'), ...
        'distance backup isolates its line end without inventing a transformer-bay route');
    T=T.chk(abs(zd.bf_timer_s-.15)<1e-12&&contains(zd.bf_path,'50BF'), ...
        'distance backup initiates the numerical 230 kV breaker-failure stage');
    bf=Z(strcmp(ids,'GIS-50BF')); gcb=Z(strcmp(ids,'GEN-52G'));
    T=T.chk(abs(bf.bf_timer_s-.15)<1e-12&&contains(bf.action_condition,'PERSISTENT_CURRENT_AFTER_TRIP')&& ...
        contains(bf.trip_other_breakers,'ADJACENT'), ...
        '230 kV breaker failure uses a 0.15 s current-persistence stage and adjacent isolation');
    T=T.chk(abs(gcb.bf_timer_s-.12)<1e-12&&contains(gcb.bf_path,'10ADA10/D07'), ...
        'generator breaker failure uses a 0.12 s stage and qualified GSUT bay backup');
    za=Z(strcmp(ids,'GEN-59N'));
    T=T.chk(strcmp(za.trip_52G,'NO_AUTOMATIC_TRIP_ASSIGNED')&&strcmp(za.lockout_86,'NONE'), ...
        'unselected residual-voltage alarm does not silently become severe trip');
    T=T.chk(all(strcmp({Z.status},'ENGINEERING_ASSUMPTION'))&& ...
        all(strcmp({Z.subtype},'FUNCTIONAL_ENGINEERING_ASSUMPTION'))&&~any([Z.actual_trip_wiring_verified]), ...
        'functional design stays separate from verified commissioned wiring');
    T=T.chk(all(isfinite([Z.bf_timer_s]))&&all([Z.bf_timer_s]>=0), ...
        'trip export has numeric BF timers, zero for functions without a BF stage');
    for id={'GEN-87G','GEN-64G','GEN-51N','GSUT-87T','GIS-87B','LINE-7SD','GIS-50BF'}
        hit=Z(strcmp(ids,id{1}));
        if numel(hit)==1
            blob=strjoin({hit.trip_52G,hit.trip_Q0,hit.lockout_86,hit.bf_path,hit.trip_other_breakers},' ');
            T=T.chk(~contains(blob,'NOT-DETERMINABLE'),[id{1} ' functional actions are concrete']);
        end
    end
end
tab=struct2table(Z);
T=T.chk(height(tab)==numel(Z)&&all(ismember(original,tab.Properties.VariableNames)), ...
    'trip logic remains directly exportable through struct2table');
try
    phase5b_zones(1); T=T.chk(false,'arguments rejected');
catch ME
    T=T.chk(strcmp(ME.identifier,'phase5b_zones:args'),'arguments rejected with stable zone error');
end
[np,nf]=T.done();
end
