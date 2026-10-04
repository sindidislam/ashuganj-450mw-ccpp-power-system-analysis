function [np, nf] = test_phase5_registry()
%TEST_PHASE5_REGISTRY  Phase-5 Task 2 registry + topology + CT ledger tests.
%   Verbatim Task-2 checks plus provenance / topology / manufacturer guards.
T = t_case('test_phase5_registry');
R = phase5_registry();
% --- Verbatim Task-2 block (plan Interfaces) ---
T = T.chk(isstruct(R)&&isfield(R,'devices'), 'registry struct with devices');
T = T.chk(R.ct_primary==15000&&R.ct_legacy==16000, 'CT ledger 15000 primary / 16000 legacy');
T = T.chk(R.gen.Irated_A==12019, 'generator rated 12019 A');
T = T.chk(strcmp(R.topology.Q0,'breaker')&&strcmp(R.topology.Q1,'disconnector'), 'Q0 breaker, Q1 disconnector');
ids = {R.devices.device_id};
T = T.chk(any(strcmp(ids,'GEN-51'))&&any(strcmp(ids,'GIS-Q0-51')), 'GEN-51 + GIS-Q0-51 present');
q = R.devices(strcmp(ids,'GIS-Q0-51'));
T = T.chk(strcmp(q.breaker_ref,'Q0'), 'only Q0 carries breaker_ref');
T = T.chk(all(~strcmp({R.devices.device_type},'disconnector-duty')), 'no disconnector duty invented');
% --- 6+1 device rows ---
T = T.chk(numel(R.devices)>=7, '6+1 device rows minimum (7 rows)');
need_ids = {'GEN-51','GEN-51N','GSUT-HV-51','GIS-Q0-51','GIS-Q0-50','LINE-21-note','REMOTE-GRID-boundary'};
for k = 1:numel(need_ids)
    T = T.chk(any(strcmp(ids,need_ids{k})), ['device present: ' need_ids{k}]);
end
% --- Locked interface: 21 device fields ---
exp_fields = {'device_id','device_type','equipment','ansi','zone','ct_ratio','ct_source','rated_A','vnom_kV','fault_source','pickup_A','tms','curve','ef_pickup_A','ef_tms','breaker_ref','upstream','downstream','provenance','status','assumption_class'};
T = T.chk(isequal(sort(fieldnames(R.devices)'),sort(exp_fields)), 'devices struct has locked 21 fields');
% --- Locked interface: gen + topology ---
T = T.chk(R.gen.Snom_MVA==458&&R.gen.Vnom_kV==22&&R.gen.Irated_A==12019&&R.gen.pf==0.85, 'gen 458 MVA / 22 kV / 12019 A / pf 0.85');
T = T.chk(strcmp(R.topology.Q0,'breaker'), 'topology Q0 breaker');
T = T.chk(strcmp(R.topology.Q1,'disconnector')&&strcmp(R.topology.Q2,'disconnector')&&strcmp(R.topology.Q9,'disconnector'), 'topology Q1/Q2/Q9 disconnectors');
T = T.chk(strcmp(R.topology.Q51,'earthing')&&strcmp(R.topology.Q52,'earthing')&&strcmp(R.topology.Q8,'earthing'), 'topology Q51/Q52/Q8 earthing');
% --- Provenance rules ---
allowed_prov = {'SOURCE-BACKED','DERIVED','ENGINEERING_ASSUMPTION','LEGACY','MISSING'};
for i = 1:numel(R.devices)
    pv = R.devices(i).provenance;
    ok = false;
    for j = 1:numel(allowed_prov)
        if strncmp(pv, allowed_prov{j}, numel(allowed_prov{j}))
            ok = true; break;
        end
    end
    T = T.chk(ok, ['provenance tagged: ' R.devices(i).device_id]);
end
allowed_ac = {'PRIMARY','SENSITIVITY','LEGACY'};
for i = 1:numel(R.devices)
    T = T.chk(any(strcmp(R.devices(i).assumption_class,allowed_ac)), ['assumption_class tagged: ' R.devices(i).device_id]);
end
% --- CT 16000 only with ct_source LEGACY ---
for i = 1:numel(R.devices)
    if R.devices(i).ct_ratio==16000
        T = T.chk(strcmp(R.devices(i).ct_source,'LEGACY'), ['CT 16000 fenced LEGACY: ' R.devices(i).device_id]);
    else
        T = T.chk(~strcmp(R.devices(i).ct_source,'LEGACY')||R.devices(i).ct_ratio==16000, ['no LEGACY misuse: ' R.devices(i).device_id]);
    end
end
% --- Only Q0 carries breaker_ref ---
for i = 1:numel(R.devices)
    br = R.devices(i).breaker_ref;
    T = T.chk(isempty(br)||strcmp(br,'Q0'), ['breaker_ref only Q0 or empty: ' R.devices(i).device_id]);
end
% --- No manufacturer / model strings anywhere ---
forbidden = {'siemens','abb','sel-','general electric','alstom','micom','7um','7sa','7sj','7ut','rel5','ret5','manufacturer','model number'};
strfields = {'device_id','device_type','equipment','ansi','zone','ct_source','fault_source','curve','breaker_ref','upstream','downstream','provenance','status','assumption_class'};
for i = 1:numel(R.devices)
    blob = '';
    for f = 1:numel(strfields)
        v = R.devices(i).(strfields{f});
        if ischar(v), blob = [blob ' ' lower(v)]; end
    end
    hit = false;
    for b = 1:numel(forbidden)
        if ~isempty(strfind(blob, forbidden{b})), hit = true; break; end
    end
    T = T.chk(~hit, ['no manufacturer/model strings: ' R.devices(i).device_id]);
end
[np, nf] = T.done();
end
