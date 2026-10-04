function [np,nf] = test_engineering_assumptions()
%TEST_ENGINEERING_ASSUMPTIONS Grouped contracts, not per-leaf count inflation.
T = t_case('test_engineering_assumptions');
cases = {@metadata_contract, @exciter_defaults, @limiter_bases, ...
    @sfc_defaults, @battery_defaults, @charger_defaults, @load_budget, ...
    @governor_defaults, @pss_disabled};
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

function metadata_contract()
A = engineering_assumptions();
assert(isstruct(A) && isscalar(A) && ~isempty(fieldnames(A)));
keys = fieldnames(A); paths = cell(size(keys));
textFields = {'unit','source','source_locator','status','confidence', ...
    'rationale','assumption_basis','source_status','interpretation_status'};
for k = 1:numel(keys)
    r = A.(keys{k});
    assert(isstruct(r) && isscalar(r),keys{k});
    assert(all(isfield(r,[textFields {'value','selected_value', ...
        'reasonable_range','assumed_range','derivation','assumption_key','component_path'}])),keys{k});
    for j = 1:numel(textFields)
        assert(ischar(r.(textFields{j})) && ~isempty(strtrim(r.(textFields{j}))),keys{k});
    end
    assert(strcmp(r.status,'ENGINEERING_ASSUMPTION') && ...
        strcmp(r.source_status,'ENGINEERING_ASSUMPTION'),keys{k});
    assert(~strcmp(r.assumption_basis,'NOT_APPLICABLE'),keys{k});
    assert(isnumeric(r.value) && isreal(r.value) && ~isempty(r.value) && ...
        all(isfinite(r.value(:))) && isequal(r.value,r.selected_value),keys{k});
    b = r.reasonable_range; a = r.assumed_range;
    assert(isnumeric(b) && isreal(b) && numel(b)==2 && all(isfinite(b)) && b(1)<=b(2),keys{k});
    assert(isnumeric(a) && isreal(a) && numel(a)==2 && all(isfinite(a)) && ...
        b(1)<=a(1) && a(1)<=a(2) && a(2)<=b(2) && ...
        all(r.value(:)>=a(1) & r.value(:)<=a(2)),keys{k});
    assert(strcmp(r.assumption_key,keys{k}),keys{k});
    paths{k} = r.component_path;
end
assert(numel(unique(paths))==numel(keys),'Component paths must be unique.');
end

function exciter_defaults()
A = engineering_assumptions();
assert(isequal(values(A,{'exc_avr_gain','exc_avr_time_s','exc_field_time_s', ...
    'exc_command_min_pu','exc_command_max_pu','exc_voltage_reference_pu', ...
    'exc_no_load_reference_pu'}),[200 .02 .5 -5 5 1 1]));
end

function limiter_bases()
A = engineering_assumptions();
assert(isequal(values(A,{'exc_oel_rated_field_reference_pu','exc_oel_threshold_pu', ...
    'exc_stator_threshold_pu'}),[2.5 1.075 1]));
assert(A.exc_oel_rated_field_reference_pu.value*A.exc_oel_threshold_pu.value < A.exc_command_max_pu.value);
assert(A.exc_oel_rated_field_reference_pu.value > A.exc_no_load_reference_pu.value);
assert(all(values(A,{'exc_oel_time_s','exc_oel_gain','exc_uel_inset_MVAr', ...
    'exc_uel_time_s','exc_uel_gain_pu_per_MVAr','exc_stator_time_s','exc_stator_gain'})>0));
assert(A.exc_limiter_min_correction_pu.value==0 && A.exc_limiter_max_correction_pu.value==5);
end

function sfc_defaults()
A = engineering_assumptions();
assert(isequal(values(A,{'sfc_efficiency','sfc_response_s','sfc_min_output_power_MW', ...
    'sfc_max_output_power_MW'}),[.97 .03 0 4]));
assert(A.sfc_max_output_power_MW.value ~= 2.28*1876/1000,'No opposite-side power inference.');
end

function battery_defaults()
A = engineering_assumptions();
assert(isequal(values(A,{'dc_nominal_voltage_V','dc_cell_count','dc_capacity_Ah', ...
    'dc_internal_resistance_ohm'}),[110 55 200 .05]));
assert(isequal(A.dc_ocv_soc.value,[0 1]) && isequal(A.dc_ocv_V.value,[105 116]));
assert(isequal(values(A,{'dc_soc_min','dc_soc_max','dc_soc_initial','dc_cutoff_voltage_V'}),[.2 1 1 105]));
assert(all(values(A,{'dc_max_discharge_A','dc_max_charge_A','dc_charge_efficiency'})>0));
assert(A.dc_charge_efficiency.value<=1);
end

function charger_defaults()
A = engineering_assumptions();
assert(isequal(values(A,{'charger_nominal_voltage_V','charger_rated_power_kW', ...
    'charger_unit_count','charger_active_units','charger_efficiency', ...
    'charger_float_voltage_V'}),[110 20 2 1 .925 123.75]));
assert(A.charger_float_voltage_V.value>A.dc_ocv_V.value(end));
assert(A.charger_max_current_A.value*A.charger_float_voltage_V.value>=20000);
assert(all(values(A,{'charger_response_s','charger_voltage_gain_A_per_V'})>0));
assert(A.charger_min_current_A.value==0);
end

function load_budget()
A = engineering_assumptions();
keys = {'load_relay_kW','load_control_kW','load_instrumentation_kW', ...
    'load_communications_kW','load_emergency_control_kW','load_excitation_electronics_kW'};
continuous = values(A,keys);
assert(all(continuous>0) && abs(sum(continuous)-2.4)<1e-12);
assert(all(values(A,{'load_trip_kW','load_trip_duration_s','load_close_kW', ...
    'load_close_duration_s','load_emergency_additional_kW'})>0));
peak = sum(continuous)+sum(values(A,{'load_trip_kW','load_close_kW','load_emergency_additional_kW'}));
assert(peak<A.charger_rated_power_kW.value,'One duty charger covers the academic load budget.');
assert(1000*peak/A.dc_cutoff_voltage_V.value<A.dc_max_discharge_A.value);
end

function governor_defaults()
A = engineering_assumptions();
assert(isequal(values(A,{'gov_droop_pu','gov_response_s','gov_turbine_time_s', ...
    'gov_speed_reference_pu','gov_turbine_gain','gov_min_power_MW'}),[.05 .2 .75 1 1 0]));
end

function pss_disabled()
A = engineering_assumptions();
assert(A.pss_enabled.value==0 && isequal(A.pss_enabled.assumed_range,[0 0]));
assert(all(values(A,{'pss_gain','pss_washout_s','pss_lead1_s','pss_lag1_s','pss_lead2_s','pss_lag2_s'})>0));
assert(A.pss_output_min_pu.value<0 && A.pss_output_max_pu.value>0);
end

function v = values(A,keys)
v = cellfun(@(key) A.(key).value,keys);
end
