function S = ashuganj_phase2_systems(G,A)
%ASHUGANJ_PHASE2_SYSTEMS Isolated metadata-only component configuration.
% S = ashuganj_phase2_systems() uses canonical generator and assumptions.
% S = ashuganj_phase2_systems(G) or ashuganj_phase2_systems(G,A) accepts the
% scalar generator (NOT master) and a complete engineering_assumptions struct.
% Six objects: excitation, sfc, stationDC, governor, pss, dynamicReadiness.
% Numeric/categorical parameters are records; text policies are descriptors.
% No solver, builder, load-flow allocation, field base, or dynamics changed.
% Override value AND selected_value together, retaining schema/units/paths.
% Ranges may narrow/widen inside the central reasonable range. Cross-field
% physical consistency is checked too. Extra/missing keys are rejected.
if nargin < 1
    G = ashuganj_generators();
end
if nargin < 2
    A = engineering_assumptions();
end
machineKeys = {'Snom_MVA','P_capacity_MW','Vnom_kV','H_s','Ra_ohm', ...
    'Ra_pu_machine','Xd','Xdp','Xdpp','Xq','Xqp','Xqpp','Xl', ...
    'Td0p_s','Td0pp_s','Tq0p_s','Tq0pp_s'};
validate_generator(G,machineKeys);
validate_assumptions(A);
S = struct();
keys = fieldnames(A);
for k = 1:numel(keys)
    r = A.(keys{k});
    S = put_record(S,strsplit(r.component_path,'.'),r);
end
source = phase2_source_data(G);
S.excitation.id = 'ACADEMIC_STATIC_EXCITATION';
S.sfc.id = 'ISOLATED_STARTING_CONVERTER';
S.stationDC.id = 'ISOLATED_STATION_DC';
S.governor.id = 'ACADEMIC_GOVERNOR_TURBINE';
S.pss.id = 'DISABLED_GENERIC_PSS';
S.dynamicReadiness.id = 'PRIMARY_MACHINE_READINESS';
S.excitation.type = source_record(source.excitation.type);
S.excitation.designation = source_record(source.excitation.designation);
S.excitation.no_load_voltage_V = source_record(source.excitation.no_load_voltage_V);
S.excitation.model = 'GENERIC_TWO_LAG_NOT_IDENTIFIED_SEMIPOL_MODEL';
S.excitation.field.physical_base = 'UNRESOLVED_NOT_USED';
S.excitation.field.normalization = 'ABSTRACT_NO_LOAD_EFD_NOT_122V_NOT_RATED_FIELD';
S.excitation.avr.equation = 'Tavr*dVr/dt=Kavr*(Vref-Vt)-Vr; Tfield*dEfd/dt=Vr_limited-Efd';
S.excitation.avr.state_policy = 'BOUNDED_LAG_STATES_NO_HIDDEN_INTEGRATOR_WINDUP';
S.excitation.oel.input_definition = 'Efd/rated_field_reference_pu; NOT Efd/no_load_reference_pu';
S.excitation.oel.equation = 'Lag bounded gain*max(Efd/rated_field_reference_pu-threshold_pu,0); subtract correction';
S.excitation.uel.equation = 'Qboundary=interp1(source_P,source_Qmin,P)+inset_MVAr; lag bounded gain*max(Qboundary-Q,0); add correction';
S.excitation.uel.domain_policy = 'REJECT_OUTSIDE_CURVE_OR_PRIMARY_CAPACITY; REPORT_INFEASIBLE_INSET_NOT_CLIP';
S.excitation.uel.curve = curve_records(G.capabilityCurve);
S.excitation.stator.current_base = 'Snom_MVA/(sqrt(3)*Vnom_kV) kA; primary machine base';
S.excitation.stator.active_overload_action = 'DISPATCH_ACTION_NOT_EXCITATION_REPAIR';
S.excitation.stator.response_policy = 'BOUNDED_REACTIVE_CORRECTION_ONLY; ACTIVE_CURRENT_EXCESS_REPORTED';
S.excitation.limiters.coordination = 'REPORT_CONFLICTS; NO_CLOSED_LOOP_TUNING_OR_STABILITY_CLAIM';
S.sfc.dc_link_kV = source_record(source.sfc.dc_link_kV);
S.sfc.max_starting_output_A = source_record(source.sfc.max_starting_output_A);
S.sfc.power_limit_side = 'OUTPUT';
S.sfc.accounting = 'Pinput=Poutput/efficiency; no DC-current inference from OUTPUT current';
S.sfc.electrical_boundary = 'NO_GENERATOR_FIELD_OR_STATION_DC_CONNECTION';
S.stationDC.electrical_boundary = 'ISOLATED_NO_FIELD_OR_SFC_CONNECTION';
S.stationDC.accounting = 'NOT_ADDED_TO_FROZEN_14MW_AUXILIARY';
S.stationDC.battery.ocv_interpolation = 'linear';
S.stationDC.battery.sign_convention = 'POSITIVE_CURRENT_DISCHARGES_BANK';
S.stationDC.battery.equation = 'Vterminal=OCV(SOC)-I*Rbank; dSOC/dt=-I/(3600*capacity_Ah) for discharge; charge uses charge_efficiency';
S.stationDC.battery.cutoff_policy = 'STOP_DISCHARGE_AT_SOC_MIN_OR_TERMINAL_CUTOFF; STOP_CHARGE_AT_SOC_MAX; REJECT_INVALID_STATE_TIME';
S.stationDC.charger.mode = 'DUTY_STANDBY';
S.stationDC.charger.rating_side = 'DC_OUTPUT_PER_UNIT';
S.stationDC.charger.equation = 'Lag bounded voltage_gain*(Vfloat-Vbus); simultaneous current and Pdc/Vbus bounds; Pac=Pdc/efficiency';
S.stationDC.charger.full_soc_policy = 'SUPPLY_LOAD_ONLY_AT_FULL_SOC; NO_FORCED_OVERVOLTAGE_OR_OVERCHARGE';
S.stationDC.charger.redundancy = 'STANDBY_REPLACES_FAILED_DUTY_NOT_PARALLEL_DOUBLE_OUTPUT';
S.stationDC.loads.excitation_electronics_scope = 'AUXILIARY_ELECTRONICS_NOT_FIELD_POWER';
S.stationDC.loads.pulse_policy = 'TRIP_AND_CLOSE_ADDITIONAL_NONREPEATING_PULSES_WITH_SEPARATE_DURATIONS';
S.stationDC.loads.emergency_policy = 'ADDITIONAL_SWITCHED_LOAD_FOR_CALLER_SELECTED_DURATION';
S.governor.max_power_MW = source_record(source.generator.P_capacity_MW);
S.governor.power_base_MVA = source_record(source.generator.Snom_MVA);
S.governor.model = 'GENERIC_DROOP_TWO_LAG_READINESS_ONLY';
S.governor.equation = 'Power-pu correction=(speed_reference_pu-speed_pu)/droop_pu; governor then turbine lag; clamp to primary MW bounds';
S.pss.tuning = 'UNTUNED_GENERIC_DISABLED';
S.pss.input = 'SPEED_DEVIATION_PU';
S.pss.model = 'GENERIC_WASHOUT_TWO_LEAD_LAG_NOT_PLANT_PSS';
S.dynamicReadiness.dataset_id = G.Dataset_ID;
S.dynamicReadiness.model = 'STANDARD_SIXTH_ORDER';
S.dynamicReadiness.validation = 'DATA_ONLY_NOT_DYNAMICALLY_VALIDATED';
S.dynamicReadiness.reactance_selection = 'PRIMARY_UNQUALIFIED_NOT_SATURATED_REPLACEMENT';
S.dynamicReadiness.field_base = 'UNRESOLVED_NOT_USED';
S.dynamicReadiness.unresolved = 'Damping, OCC, detailed rotor circuit and physical field base remain unresolved; no invented zero defaults';
for k = 1:numel(machineKeys)
    key = machineKeys{k};
    S.dynamicReadiness.machine.(key) = source_record(source.generator.(key));
end
for key = {'Xdpp_sat','S10','S12'}
    S.dynamicReadiness.saturation.(key{1}) = source_record(source.generator.(key{1}));
end
S.dynamicReadiness.saturation.policy = 'SOURCE_COEFFICIENTS_AND_SATURATED_XDPP_SEPARATE_NOT_REPLACEMENT_OR_FULL_OCC';
f = phase2_parameter(G.f_Hz,'Hz','Generator Name Plate_South.pdf', ...
    'Existing ashuganj_generators transcription: f_Hz / f_Status',G.f_Status, ...
    'Existing primary transcription','Rated frequency retained; no new attachment inspection.');
S.dynamicReadiness.frequency_Hz = source_record(f);
end

function validate_generator(G,keys)
try
    assert(isstruct(G) && isscalar(G));
    assert(all(isfield(G,{'Primary','Provenance','Dataset_ID','capabilityCurve', ...
        'Uexc0_V','SFC_DC_link_kV','SFC_Imax_A','f_Hz','f_Status'})));
    for key = [keys {'Xdpp_sat','S10','S12'}]
        n = key{1}; v = G.(n);
        assert(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>0);
        assert(isequal(v,G.Provenance.(n).Normalized_value));
        if isfield(G.Primary,n)
            assert(isequal(v,G.Primary.(n)));
        end
    end
    for key = {'Uexc0_V','SFC_DC_link_kV','SFC_Imax_A','f_Hz'}
        v = G.(key{1});
        assert(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v>0);
    end
    assert(G.P_capacity_MW<=G.Snom_MVA);
    generatorCapability(G.P_capacity_MW,G.capabilityCurve);
catch
    error('ashuganj_phase2_systems:InvalidGenerator', ...
        'Require scalar canonical generator with finite primary inputs consistent with its provenance.');
end
end

function validate_assumptions(A)
D = engineering_assumptions(); keys = fieldnames(D);
try
    assert(isstruct(A) && isscalar(A) && isequal(sort(fieldnames(A)),sort(keys)));
    for k = 1:numel(keys)
        key = keys{k}; r = A.(key); d = D.(key);
        assert(isstruct(r) && isscalar(r) && all(isfield(r,fieldnames(d))));
        assert(strcmp(r.status,'ENGINEERING_ASSUMPTION') && strcmp(r.source_status,r.status));
        assert(strcmp(r.unit,d.unit) && strcmp(r.assumption_key,key) && ...
            strcmp(r.component_path,d.component_path));
        assert(isequal(size(r.value),size(d.value)) && isequal(r.selected_value,r.value));
        assert(isequal(r.reasonable_range,d.reasonable_range));
        phase2_parameter(r.value,r.unit,r.source,r.source_locator,r.status,r.confidence, ...
            r.rationale,'assumption_basis',r.assumption_basis, ...
            'reasonable_range',r.reasonable_range,'assumed_range',r.assumed_range, ...
            'source_status',r.source_status,'derivation',r.derivation, ...
            'interpretation_status',r.interpretation_status);
    end
catch
    error('ashuganj_phase2_systems:InvalidAssumptions', ...
        'Require complete central keys, metadata, stable units/paths and finite selected values within approved reasonable ranges.');
end
v = @(key) A.(key).value;
consistent = v('exc_command_min_pu')<v('exc_command_max_pu') && ...
    v('exc_no_load_reference_pu')<v('exc_oel_rated_field_reference_pu') && ...
    v('exc_oel_rated_field_reference_pu')*v('exc_oel_threshold_pu')<v('exc_command_max_pu') && ...
    v('exc_limiter_min_correction_pu')<v('exc_limiter_max_correction_pu') && ...
    v('sfc_min_output_power_MW')<v('sfc_max_output_power_MW') && ...
    isequal(v('dc_ocv_soc'),[0 1]) && all(diff(v('dc_ocv_V'))>0) && ...
    v('dc_soc_min')<v('dc_soc_max') && v('dc_soc_initial')>=v('dc_soc_min') && ...
    v('dc_soc_initial')<=v('dc_soc_max') && ...
    v('dc_cutoff_voltage_V')>=min(v('dc_ocv_V')) && ...
    v('dc_cutoff_voltage_V')<max(v('dc_ocv_V')) && ...
    v('charger_float_voltage_V')>max(v('dc_ocv_V')) && ...
    v('charger_nominal_voltage_V')==v('dc_nominal_voltage_V') && ...
    v('charger_min_current_A')<v('charger_max_current_A') && ...
    v('charger_max_current_A')*v('charger_float_voltage_V')>=1000*v('charger_rated_power_kW') && ...
    v('dc_max_charge_A')<=v('charger_max_current_A') && ...
    v('pss_output_min_pu')<v('pss_output_max_pu');
continuous = v('load_relay_kW')+v('load_control_kW')+v('load_instrumentation_kW')+ ...
    v('load_communications_kW')+v('load_emergency_control_kW')+v('load_excitation_electronics_kW');
peak = continuous+v('load_trip_kW')+v('load_close_kW')+v('load_emergency_additional_kW');
consistent = consistent && peak<v('charger_rated_power_kW') && ...
    1000*peak/v('dc_cutoff_voltage_V')<v('dc_max_discharge_A');
if ~consistent
    error('ashuganj_phase2_systems:InconsistentConfiguration', ...
        'Individually ranged selections violate field, SOC/OCV, charger, or load-budget relationships.');
end
end

function s = put_record(s,parts,r)
name = parts{1};
if numel(parts)==1
    s.(name) = r;
else
    if ~isfield(s,name)
        s.(name) = struct();
    end
    s.(name) = put_record(s.(name),parts(2:end),r);
end
end

function r = source_record(old)
% Range for source scalars is fixed selection, not invented measurement error.
r = old;
r.raw_source = old;
qualified = strcmp(old.interpretation_status,'QUALIFIED') || ...
    strcmp(old.source_status,'DERIVED_FROM_VERIFIED_DATA');
if qualified
    status = 'PRIMARY_SOURCE_QUALIFIED';
else
    status = 'PRIMARY_VERIFIED';
end
r.status = status;
r.source_status = status;
if isnumeric(r.value)
    r.reasonable_range = [min(r.value(:)) max(r.value(:))];
    r.assumed_range = r.reasonable_range;
    r.range_basis = 'FIXED_SOURCE_SELECTION_NOT_UNCERTAINTY_OR_OPERATING_RANGE';
else
    r.reasonable_range = [];
    r.assumed_range = [];
    r.range_basis = 'CATEGORICAL_SOURCE_VALUE_NUMERIC_RANGE_NOT_APPLICABLE';
end
% Existing raw_provenance is retained alongside the untouched normalized view.
end

function C = curve_records(raw)
C.raw_source = raw;
C.interpolation = raw.interpolation;
C.extrapolation = raw.extrapolation;
for key = {'P_MW','Qmin_MVAr','Qmax_MVAr'}
    n = key{1}; unit = raw.Q_unit;
    if strcmp(n,'P_MW')
        unit = raw.P_unit;
    end
    v = raw.(n); bounds = [min(v) max(v)];
    r = phase2_parameter(v,unit,raw.source,raw.source_locator, ...
        'PRIMARY_SOURCE_QUALIFIED',raw.confidence,raw.rationale, ...
        'reasonable_range',bounds,'assumed_range',bounds, ...
        'interpretation_status','QUALIFIED');
    r.qualification = 'PRIMARY_SOURCE_EXTRACTED';
    r.range_basis = 'EXTRACTED_ARRAY_EXTENT_NOT_MEASUREMENT_UNCERTAINTY';
    C.(n) = r;
end
end
