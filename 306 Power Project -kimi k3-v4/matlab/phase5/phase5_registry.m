function R = phase5_registry()
%PHASE5_REGISTRY  Device registry + topology + CT ledger (Phase-5 Task 2).
%   R = PHASE5_REGISTRY() returns struct with fields:
%     .devices    struct array (21 locked fields)
%     .ct_primary 15000 (primary protection-report ratio)
%     .ct_legacy  16000 (fenced sensitivity only, never primary)
%     .gen        Snom_MVA 458, Vnom_kV 22, Irated_A 12019, pf 0.85
%     .topology   Q0 breaker; Q1/Q2/Q9 disconnectors; Q51/Q52/Q8 earthing
%
%   6+1 rows: GEN-51, GEN-51N, GSUT-HV-51, GIS-Q0-51, GIS-Q0-50,
%   LINE-21-note, REMOTE-GRID-boundary. Every row carries provenance
%   (SOURCE-BACKED / DERIVED / ENGINEERING_ASSUMPTION / LEGACY / MISSING)
%   and assumption_class (PRIMARY / SENSITIVITY / LEGACY).
%   Only Q0 carries breaker_ref. No disconnector duty. No maker strings.
%   All errors 'phase5'-prefixed.
if nargin ~= 0
    error('phase5_registry:args', 'phase5_registry takes no arguments.');
end
ct_primary = 15000;
ct_legacy = 16000;
gen = struct('Snom_MVA', 458, 'Vnom_kV', 22, 'Irated_A', 12019, 'pf', 0.85);
topology = struct('Q0', 'breaker', ...
    'Q1', 'disconnector', 'Q2', 'disconnector', 'Q9', 'disconnector', ...
    'Q51', 'earthing', 'Q52', 'earthing', 'Q8', 'earthing');
F = {'device_id','device_type','equipment','ansi','zone','ct_ratio','ct_source','rated_A','vnom_kV','fault_source','pickup_A','tms','curve','ef_pickup_A','ef_tms','breaker_ref','upstream','downstream','provenance','status','assumption_class'};
% Row 1: GEN-51
d(1).device_id = 'GEN-51';
d(1).device_type = 'oc';
d(1).equipment = 'B22-generator-bus';
d(1).ansi = '51';
d(1).zone = 'generator';
d(1).ct_ratio = 15000;
d(1).ct_source = 'SOURCE-BACKED';
d(1).rated_A = 12019;
d(1).vnom_kV = 22;
d(1).fault_source = 'Phase-4-production-import';
d(1).pickup_A = NaN;
d(1).tms = NaN;
d(1).curve = '';
d(1).ef_pickup_A = NaN;
d(1).ef_tms = NaN;
d(1).breaker_ref = '';
d(1).upstream = 'GSUT-HV-51';
d(1).downstream = '';
d(1).provenance = 'SOURCE-BACKED:protection-report-CT-15000/1-B22';
d(1).status = 'ACTIVE-STUDY';
d(1).assumption_class = 'PRIMARY';
% Row 2: GEN-51N (earth-fault)
d(2).device_id = 'GEN-51N';
d(2).device_type = 'ef';
d(2).equipment = 'B22-generator-bus';
d(2).ansi = '51N';
d(2).zone = 'generator';
d(2).ct_ratio = 15000;
d(2).ct_source = 'SOURCE-BACKED';
d(2).rated_A = 12019;
d(2).vnom_kV = 22;
d(2).fault_source = 'Phase-4-production-import';
d(2).pickup_A = NaN;
d(2).tms = NaN;
d(2).curve = '';
d(2).ef_pickup_A = NaN;
d(2).ef_tms = NaN;
d(2).breaker_ref = '';
d(2).upstream = 'GSUT-HV-51';
d(2).downstream = '';
d(2).provenance = 'SOURCE-BACKED:protection-report-CT-15000/1-B22-EF';
d(2).status = 'ACTIVE-STUDY';
d(2).assumption_class = 'PRIMARY';
% Row 3: GSUT-HV-51 (HV CT ratio assumed)
d(3).device_id = 'GSUT-HV-51';
d(3).device_type = 'oc';
d(3).equipment = 'GSUT-HV-230kV';
d(3).ansi = '51';
d(3).zone = 'transformer-HV';
d(3).ct_ratio = 2000;
d(3).ct_source = 'ENGINEERING_ASSUMPTION';
d(3).rated_A = 1150;
d(3).vnom_kV = 230;
d(3).fault_source = 'Phase-4-production-import';
d(3).pickup_A = NaN;
d(3).tms = NaN;
d(3).curve = '';
d(3).ef_pickup_A = NaN;
d(3).ef_tms = NaN;
d(3).breaker_ref = '';
d(3).upstream = 'GIS-Q0-51';
d(3).downstream = 'GEN-51';
d(3).provenance = 'ENGINEERING_ASSUMPTION:GSUT-HV-CT-2000/1-ratio-assumed-study-only';
d(3).status = 'ACTIVE-STUDY';
d(3).assumption_class = 'PRIMARY';
% Row 4: GIS-Q0-51 (only duty-eligible breaker ref Q0)
d(4).device_id = 'GIS-Q0-51';
d(4).device_type = 'oc';
d(4).equipment = '230kV-GIS';
d(4).ansi = '51';
d(4).zone = 'grid';
d(4).ct_ratio = 2000;
d(4).ct_source = 'ENGINEERING_ASSUMPTION';
d(4).rated_A = 2000;
d(4).vnom_kV = 230;
d(4).fault_source = 'Phase-4-production-import';
d(4).pickup_A = NaN;
d(4).tms = NaN;
d(4).curve = '';
d(4).ef_pickup_A = NaN;
d(4).ef_tms = NaN;
d(4).breaker_ref = 'Q0';
d(4).upstream = 'REMOTE-GRID-boundary';
d(4).downstream = 'GSUT-HV-51';
d(4).provenance = 'ENGINEERING_ASSUMPTION:GIS-CT-2000/1-ratio-assumed-study-only';
d(4).status = 'ACTIVE-STUDY';
d(4).assumption_class = 'PRIMARY';
% Row 5: GIS-Q0-50 (high-set, disabled unless justified)
d(5).device_id = 'GIS-Q0-50';
d(5).device_type = 'oc-instantaneous';
d(5).equipment = '230kV-GIS';
d(5).ansi = '50';
d(5).zone = 'grid';
d(5).ct_ratio = 2000;
d(5).ct_source = 'ENGINEERING_ASSUMPTION';
d(5).rated_A = 2000;
d(5).vnom_kV = 230;
d(5).fault_source = 'Phase-4-production-import';
d(5).pickup_A = NaN;
d(5).tms = NaN;
d(5).curve = '';
d(5).ef_pickup_A = NaN;
d(5).ef_tms = NaN;
d(5).breaker_ref = 'Q0';
d(5).upstream = 'REMOTE-GRID-boundary';
d(5).downstream = 'GSUT-HV-51';
d(5).provenance = 'ENGINEERING_ASSUMPTION:GIS-CT-2000/1-high-set-study-only';
d(5).status = 'DISABLED-unless-justified';
d(5).assumption_class = 'PRIMARY';
% Row 6: LINE-21-note (distance, note only)
d(6).device_id = 'LINE-21-note';
d(6).device_type = 'note';
d(6).equipment = 'South-line-230kV';
d(6).ansi = '21';
d(6).zone = 'line';
d(6).ct_ratio = NaN;
d(6).ct_source = 'MISSING';
d(6).rated_A = NaN;
d(6).vnom_kV = 230;
d(6).fault_source = 'Phase-4-production-import';
d(6).pickup_A = NaN;
d(6).tms = NaN;
d(6).curve = '';
d(6).ef_pickup_A = NaN;
d(6).ef_tms = NaN;
d(6).breaker_ref = '';
d(6).upstream = 'REMOTE-GRID-boundary';
d(6).downstream = 'GIS-Q0-51';
d(6).provenance = 'MISSING:distance-settings-not-determinable-from-available-data';
d(6).status = 'NOTE-only-no-settings-invented';
d(6).assumption_class = 'PRIMARY';
% Row 7: REMOTE-GRID-boundary (monitoring only, no device)
d(7).device_id = 'REMOTE-GRID-boundary';
d(7).device_type = 'boundary';
d(7).equipment = 'B230-REMOTE';
d(7).ansi = '';
d(7).zone = 'grid-boundary';
d(7).ct_ratio = NaN;
d(7).ct_source = 'MISSING';
d(7).rated_A = NaN;
d(7).vnom_kV = 230;
d(7).fault_source = 'Phase-4-production-import';
d(7).pickup_A = NaN;
d(7).tms = NaN;
d(7).curve = '';
d(7).ef_pickup_A = NaN;
d(7).ef_tms = NaN;
d(7).breaker_ref = '';
d(7).upstream = '';
d(7).downstream = 'GIS-Q0-51';
d(7).provenance = 'MISSING:remote-grid-no-device-monitoring-only';
d(7).status = 'MONITORING-only';
d(7).assumption_class = 'PRIMARY';
% Locked-field guard
if ~isequal(sort(fieldnames(d)'), sort(F))
    error('phase5_registry:schema', 'devices struct fields do not match locked interface.');
end
R = struct('devices', d, 'ct_primary', ct_primary, 'ct_legacy', ct_legacy, 'gen', gen, 'topology', topology);
end
