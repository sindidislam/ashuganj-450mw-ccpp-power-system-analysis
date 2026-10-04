function [np,nf] = test_phase2_systems()
%TEST_PHASE2_SYSTEMS Data contracts only; no dynamic or LF execution.
T = t_case('test_phase2_systems');
cases = {@identities_and_defaults, @all_leaves_are_records, @exact_source_identity, ...
    @oel_not_a_voltage_base, @uel_source_curve, @sfc_side_separation, ...
    @station_dc_configuration, @primary_sixth_order_selection, ...
    @central_record_coverage, @override_propagation, @range_boundary_override, ...
    @reject_malformed_records, @reject_inconsistent_battery, ...
    @reject_inconsistent_exciter, @reject_inconsistent_charger, ...
    @reject_invalid_generator, @preserve_inputs};
for k = 1:numel(cases)
    try
        cases{k}();
        T = T.chk(true,func2str(cases{k}));
    catch err
        T = T.chk(false,[func2str(cases{k}) ': ' err.identifier ' ' err.message]);
    end
end
[np,nf] = T.done();
end

function identities_and_defaults()
S = ashuganj_phase2_systems();
assert(isequal(S,ashuganj_phase2_systems(ashuganj_generators(),engineering_assumptions())));
groups = {'excitation','sfc','stationDC','governor','pss','dynamicReadiness'};
assert(isequal(sort(fieldnames(S)),sort(groups')));
ids = cellfun(@(n) S.(n).id,groups,'UniformOutput',false);
assert(numel(unique(ids))==6);
assert(S.pss.enabled.value==0 && strcmp(S.pss.tuning,'UNTUNED_GENERIC_DISABLED'));
assert(strcmp(S.stationDC.charger.mode,'DUTY_STANDBY'));
assert(strcmp(S.dynamicReadiness.validation,'DATA_ONLY_NOT_DYNAMICALLY_VALIDATED'));
end

function all_leaves_are_records()
walk(ashuganj_phase2_systems());
end

function walk(s)
if isstruct(s) && isscalar(s) && isfield(s,'value')
    fields = {'value','unit','source','source_locator','status','confidence', ...
        'rationale','assumption_basis','reasonable_range','assumed_range','selected_value', ...
        'source_status','derivation','interpretation_status'};
    assert(all(isfield(s,fields)) && isequal(s.value,s.selected_value));
    allowed = {'PRIMARY_VERIFIED','PRIMARY_SOURCE_QUALIFIED','ENGINEERING_ASSUMPTION','HISTORICAL','LEGACY'};
    assert(ismember(s.status,allowed) && ismember(s.source_status,allowed));
    assert(~isempty(s.unit) && ~isempty(s.source) && ~isempty(s.source_locator) && ...
        ~isempty(s.confidence) && ~isempty(s.rationale) && ~isempty(s.assumption_basis));
    if isnumeric(s.value)
        assert(isreal(s.value) && ~isempty(s.value) && all(isfinite(s.value(:))));
        a = s.assumed_range; b = s.reasonable_range;
        assert(numel(a)==2 && numel(b)==2 && all(isfinite([a b])) && ...
            b(1)<=a(1) && a(1)<=a(2) && a(2)<=b(2) && ...
            all(s.value(:)>=a(1) & s.value(:)<=a(2)));
    else
        assert(ischar(s.value) && isempty(s.assumed_range) && isempty(s.reasonable_range));
    end
elseif isstruct(s) && isscalar(s)
    names = fieldnames(s);
    for k = 1:numel(names)
        if ~ismember(names{k},{'raw_source','raw_provenance'})
            walk(s.(names{k}));
        end
    end
else
    assert(ischar(s),'Every numeric/logical model leaf must be a metadata record.');
end
end

function exact_source_identity()
G = ashuganj_generators(); old = phase2_source_data(G); S = ashuganj_phase2_systems(G);
assert(strcmp(S.excitation.type.value,'Static') && strcmp(S.excitation.designation.value,'SEMIPOL'));
assert(strcmp(S.excitation.type.status,'PRIMARY_VERIFIED'));
assert(isequal(S.excitation.type.raw_source,old.excitation.type));
assert(isequal(S.excitation.type.raw_provenance,G.Provenance.Excitation_type));
assert(S.excitation.no_load_voltage_V.value==122);
assert(isequal(S.excitation.no_load_voltage_V.raw_source,old.excitation.no_load_voltage_V));
assert(strcmp(S.dynamicReadiness.machine.Xdpp.status,'PRIMARY_SOURCE_QUALIFIED'));
assert(isequal(S.dynamicReadiness.machine.Xdpp.raw_provenance,G.Provenance.Xdpp));
end

function oel_not_a_voltage_base()
G = ashuganj_generators(); S = ashuganj_phase2_systems(G);
assert(S.excitation.field.no_load_reference_pu.value==1);
assert(S.excitation.oel.rated_field_reference_pu.value==2.5);
assert(S.excitation.oel.threshold_pu.value==1.075);
assert(abs(S.excitation.oel.rated_field_reference_pu.value*S.excitation.oel.threshold_pu.value-2.6875)<1e-12);
assert(strcmp(S.excitation.field.physical_base,'UNRESOLVED_NOT_USED'));
G.Uexc0_V = 150; G.Rf_numeric = 999;
R = ashuganj_phase2_systems(G);
assert(R.excitation.no_load_voltage_V.value==150);
assert(isequal(R.excitation.field,S.excitation.field) && isequal(R.excitation.oel,S.excitation.oel));
assert(~isfield(S.dynamicReadiness.machine,'Rf_numeric'));
end

function uel_source_curve()
G = ashuganj_generators(); S = ashuganj_phase2_systems(G);
C = S.excitation.uel.curve;
assert(isequal(C.P_MW.value,[0 100 200 300 389.3 458]));
assert(isequal(C.Qmin_MVAr.value,[-231 -231 -220 -205 -182 0]));
assert(isequal(C.Qmax_MVAr.value,[335 329 311 280 241 0]));
assert(strcmp(C.Qmin_MVAr.status,'PRIMARY_SOURCE_QUALIFIED') && ...
    strcmp(C.Qmin_MVAr.qualification,'PRIMARY_SOURCE_EXTRACTED'));
assert(isequal(C.raw_source,G.capabilityCurve) && ~C.raw_source.attachment_locally_inspected);
assert(strcmp(C.interpolation,'linear') && strcmp(C.extrapolation,'REJECT'));
assert(S.excitation.uel.inset_MVAr.value==5 && S.excitation.uel.response_s.value>0);
assert(strcmp(S.excitation.stator.active_overload_action,'DISPATCH_ACTION_NOT_EXCITATION_REPAIR'));
end

function sfc_side_separation()
S = ashuganj_phase2_systems();
assert(S.sfc.dc_link_kV.value==2.28 && strcmp(S.sfc.dc_link_kV.side,'DC_LINK'));
assert(S.sfc.max_starting_output_A.value==1876 && strcmp(S.sfc.max_starting_output_A.side,'OUTPUT'));
assert(S.sfc.max_output_power_MW.value==4 && strcmp(S.sfc.power_limit_side,'OUTPUT'));
assert(strcmp(S.sfc.max_output_power_MW.status,'ENGINEERING_ASSUMPTION'));
assert(~isfield(S.sfc,'dc_current_A') && S.sfc.efficiency.value==.97 && S.sfc.response_s.value==.03);
end

function station_dc_configuration()
S = ashuganj_phase2_systems(); D = S.stationDC;
assert(D.battery.nominal_voltage_V.value==110 && D.charger.nominal_voltage_V.value==110);
assert(D.battery.cell_count.value==55 && D.charger.unit_count.value==2 && D.charger.active_units.value==1);
assert(D.charger.float_voltage_V.value==123.75 && D.charger.rated_power_kW.value==20);
assert(D.charger.efficiency.value==.925);
assert(strcmp(D.electrical_boundary,'ISOLATED_NO_FIELD_OR_SFC_CONNECTION'));
assert(strcmp(D.accounting,'NOT_ADDED_TO_FROZEN_14MW_AUXILIARY'));
assert(strcmp(D.loads.excitation_electronics_scope,'AUXILIARY_ELECTRONICS_NOT_FIELD_POWER'));
assert(D.loads.trip.power_kW.value>0 && D.loads.close.duration_s.value>0);
assert(strcmp(D.battery.ocv_interpolation,'linear'));
end

function primary_sixth_order_selection()
G = ashuganj_generators(); S = ashuganj_phase2_systems(G); M = S.dynamicReadiness.machine;
keys = {'Snom_MVA','P_capacity_MW','Vnom_kV','H_s','Ra_ohm','Ra_pu_machine', ...
    'Xd','Xdp','Xdpp','Xq','Xqp','Xqpp','Xl','Td0p_s','Td0pp_s','Tq0p_s','Tq0pp_s'};
assert(isequal(sort(fieldnames(M)),sort(keys')));
for k = 1:numel(keys)
    assert(isequal(M.(keys{k}).value,G.(keys{k})),keys{k});
end
assert(M.Xdpp.value==.2608 && S.dynamicReadiness.saturation.Xdpp_sat.value==.2248);
assert(~isfield(M,'Xdpp_sat') && ~isfield(M,'Damping'));
assert(S.governor.max_power_MW.value==360 && S.governor.power_base_MVA.value==458);
assert(strcmp(S.dynamicReadiness.reactance_selection,'PRIMARY_UNQUALIFIED_NOT_SATURATED_REPLACEMENT'));
assert(S.dynamicReadiness.saturation.S10.value==G.S10 && S.dynamicReadiness.saturation.S12.value==G.S12);
end

function central_record_coverage()
A = engineering_assumptions(); S = ashuganj_phase2_systems(); keys = fieldnames(A);
for k = 1:numel(keys)
    r = at_path(S,A.(keys{k}).component_path);
    assert(isequal(r,A.(keys{k})),keys{k});
end
end

function override_propagation()
A = engineering_assumptions(); A = select(A,'exc_avr_gain',150);
A = select(A,'load_trip_kW',2.5);
S = ashuganj_phase2_systems(ashuganj_generators(),A);
assert(S.excitation.avr.gain.value==150 && S.stationDC.loads.trip.power_kW.value==2.5);
end

function range_boundary_override()
A = engineering_assumptions(); A = select(A,'sfc_max_output_power_MW',3);
S = ashuganj_phase2_systems(ashuganj_generators(),A);
assert(S.sfc.max_output_power_MW.value==3,'Inclusive assumed-range boundary must be accepted.');
end

function reject_malformed_records()
G = ashuganj_generators(); A = engineering_assumptions();
bad = {rmfield(A,'exc_avr_gain')};
B = A; B.extra = A.exc_avr_gain; bad{end+1} = B;
B = A; B.exc_avr_gain.value = NaN; bad{end+1} = B;
B = A; B.exc_avr_gain.selected_value = 100; bad{end+1} = B;
B = A; B.exc_avr_gain.assumed_range = [210 220]; bad{end+1} = B;
B = A; B.exc_avr_gain.component_path = 'sfc.efficiency'; bad{end+1} = B;
B = A; B.exc_avr_gain.status = 'PRIMARY_VERIFIED'; bad{end+1} = B;
B = A; B.exc_avr_gain.rationale = ''; bad{end+1} = B;
for k = 1:numel(bad)
    must_error(@() ashuganj_phase2_systems(G,bad{k}),'ashuganj_phase2_systems:InvalidAssumptions');
end
end

function reject_inconsistent_battery()
G = ashuganj_generators(); A = engineering_assumptions();
B = select(A,'dc_ocv_V',[116 105]);
must_error(@() ashuganj_phase2_systems(G,B),'ashuganj_phase2_systems:InconsistentConfiguration');
B = select(A,'dc_soc_initial',.1); B.dc_soc_initial.assumed_range = [0 1];
must_error(@() ashuganj_phase2_systems(G,B),'ashuganj_phase2_systems:InconsistentConfiguration');
end

function reject_inconsistent_exciter()
A = engineering_assumptions(); A = select(A,'exc_oel_rated_field_reference_pu',3);
A = select(A,'exc_command_max_pu',3);
must_error(@() ashuganj_phase2_systems(ashuganj_generators(),A), ...
    'ashuganj_phase2_systems:InconsistentConfiguration');
end

function reject_inconsistent_charger()
A = engineering_assumptions(); A = select(A,'charger_max_current_A',150);
must_error(@() ashuganj_phase2_systems(ashuganj_generators(),A), ...
    'ashuganj_phase2_systems:InconsistentConfiguration');
end

function reject_invalid_generator()
G = ashuganj_generators();
must_error(@() ashuganj_phase2_systems([]),'ashuganj_phase2_systems:InvalidGenerator');
G.Xdpp = NaN;
must_error(@() ashuganj_phase2_systems(G),'ashuganj_phase2_systems:InvalidGenerator');
G = ashuganj_generators(); G.Xdpp = G.Xdpp_sat;
must_error(@() ashuganj_phase2_systems(G),'ashuganj_phase2_systems:InvalidGenerator');
end

function preserve_inputs()
G = ashuganj_generators(); A = engineering_assumptions(); oldG = G; oldA = A;
ashuganj_phase2_systems(G,A);
assert(isequaln(G,oldG) && isequaln(A,oldA));
end

function A = select(A,key,value)
A.(key).value = value; A.(key).selected_value = value;
end

function r = at_path(s,path)
parts = strsplit(path,'.'); r = s;
for k = 1:numel(parts)
    r = r.(parts{k});
end
end

function must_error(f,id)
try
    f();
catch err
    assert(strcmp(err.identifier,id),['Unexpected error: ' err.identifier]);
    return
end
error('test_phase2_systems:ExpectedError','Expected %s',id);
end
