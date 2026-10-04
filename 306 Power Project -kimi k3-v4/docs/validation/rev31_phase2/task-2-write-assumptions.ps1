$ErrorActionPreference = 'Stop'
# Task-2 runtime writing evidence. Run only after recorded RED, from workspace root.
$text = @'
function A = engineering_assumptions()
%ENGINEERING_ASSUMPTIONS Central finite academic Phase-2 model selections.
% A = engineering_assumptions() returns a scalar struct keyed by stable names.
% Each leaf is a phase2_parameter record plus assumption_key/component_path.
% Ranges are engineering screening/sensitivity choices, NOT plant tolerances,
% measured confidence intervals, installed ratings, or commissioned settings.
% Columns: key, component path, value, unit, reasonable range, assumed range,
% specific basis. Every extra gain, limit, reference and load lives here.
rows = {
'exc_avr_gain','excitation.avr.gain',200,'pu/pu',[50 400],[100 300],'Generic high-gain static AVR, terminal-voltage error to Efd command; approved default.';
'exc_avr_time_s','excitation.avr.response_s',.02,'s',[.005 .1],[.01 .05],'Fast but finite electronic regulator lag; approved default.';
'exc_field_time_s','excitation.field.response_s',.5,'s',[.1 2],[.2 1],'Aggregate academic field-response lag, not an identified rotor circuit; approved default.';
'exc_command_min_pu','excitation.avr.command_min_pu',-5,'Efd pu',[-10 -1],[-7 -3],'Finite negative forcing command on abstract no-load Efd base; not negative physical field-current evidence.';
'exc_command_max_pu','excitation.avr.command_max_pu',5,'Efd pu',[1 10],[3 7],'Finite positive forcing ceiling; approved +/-5 command range.';
'exc_voltage_reference_pu','excitation.avr.voltage_reference_pu',1,'terminal V pu',[.9 1.1],[1 1],'Fixed academic terminal-voltage reference; frozen LF setpoints are not edited.';
'exc_no_load_reference_pu','excitation.field.no_load_reference_pu',1,'Efd pu',[1 1],[1 1],'Abstract no-load Efd normalization at rated terminal voltage; no volts or amperes conversion, not the 122 V datum.';
'exc_oel_rated_field_reference_pu','excitation.oel.rated_field_reference_pu',2.5,'Efd pu',[1.5 4],[2 3],'Assumed rated-field proxy is 2.5 times abstract no-load Efd, NOT measured rated field current.';
'exc_oel_threshold_pu','excitation.oel.threshold_pu',1.075,'rated-field pu',[1.02 1.15],[1.05 1.1],'OEL operates on Efd/rated_field_reference_pu; default threshold therefore corresponds to 2.6875 Efd pu.';
'exc_oel_time_s','excitation.oel.response_s',1,'s',[.1 10],[.5 3],'Finite academic overexcitation correction lag; no thermal withstand or protection claim.';
'exc_oel_gain','excitation.oel.gain',5,'Efd pu/rated-field pu',[1 20],[2 10],'Proportional correction for positive rated-field excess before bounded lag.';
'exc_uel_inset_MVAr','excitation.uel.inset_MVAr',5,'MVAr',[1 20],[2 10],'Positive inset above interpolated source lower-Q envelope; screening margin, not source accuracy.';
'exc_uel_time_s','excitation.uel.response_s',.1,'s',[.02 1],[.05 .3],'Finite underexcitation correction lag, untuned.';
'exc_uel_gain_pu_per_MVAr','excitation.uel.gain_pu_per_MVAr',.05,'Efd pu/MVAr',[.005 .2],[.02 .1],'Positive Efd correction per MVAr below the inset boundary; untuned.';
'exc_stator_threshold_pu','excitation.stator.threshold_pu',1,'stator I pu',[.95 1.1],[1 1],'Continuous current threshold on machine S/V base; active-current overload requires dispatch action.';
'exc_stator_time_s','excitation.stator.response_s',.2,'s',[.02 2],[.1 .5],'Finite reactive-current correction lag; not overcurrent protection timing.';
'exc_stator_gain','excitation.stator.gain',5,'Efd pu/stator I pu',[1 20],[2 10],'Untuned bounded correction for reactive contribution only, never an active-power repair.';
'exc_limiter_min_correction_pu','excitation.limiters.min_correction_pu',0,'Efd pu',[0 0],[0 0],'Inactive limiter correction is exactly zero; nonnegative correction magnitudes.';
'exc_limiter_max_correction_pu','excitation.limiters.max_correction_pu',5,'Efd pu',[1 10],[3 7],'Common finite magnitude cap for OEL/UEL/stator corrections, separate from signed AVR commands.';
'sfc_efficiency','sfc.efficiency',.97,'fraction',[.9 .995],[.95 .99],'Academic converter output/input power efficiency; approved default.';
'sfc_response_s','sfc.response_s',.03,'s',[.005 .2],[.01 .1],'Finite simplified converter power response, approved default.';
'sfc_min_output_power_MW','sfc.min_output_power_MW',0,'MW',[0 0],[0 0],'Starting-only model, no regenerative output-power request.';
'sfc_max_output_power_MW','sfc.max_output_power_MW',4,'MW',[1 10],[3 6],'Separately assumed OUTPUT-side starting converter power cap; not 2.28 kV DC link multiplied by 1876 A output current.';
'dc_nominal_voltage_V','stationDC.battery.nominal_voltage_V',110,'V',[110 110],[110 110],'Approved isolated station DC nominal rating, distinct from OCV and float target.';
'dc_cell_count','stationDC.battery.cell_count',55,'cells',[55 55],[55 55],'Approved series string of nominal two-volt lead-acid cells; integer count.';
'dc_capacity_Ah','stationDC.battery.capacity_Ah',200,'Ah',[100 400],[150 250],'Whole-bank nominal charge capacity; academic duty, not installed plant sizing.';
'dc_internal_resistance_ohm','stationDC.battery.internal_resistance_ohm',.05,'ohm',[.01 .15],[.03 .08],'Whole-bank lumped resistance for terminal sag, not per-cell resistance or DC fault data.';
'dc_ocv_soc','stationDC.battery.ocv_soc',[0 1],'SOC fraction',[0 1],[0 1],'Linear lookup domain from empty to full normalized charge, with discharge cutoff handled separately.';
'dc_ocv_V','stationDC.battery.ocv_V',[105 116],'V',[99 121],[103 118],'Illustrative empty/full bank OCV endpoints about 1.91/2.11 V per cell; not a measured discharge curve.';
'dc_soc_min','stationDC.battery.soc_min',.2,'SOC fraction',[0 .5],[.1 .3],'Conservative reserve cutoff, not chemical zero charge.';
'dc_soc_max','stationDC.battery.soc_max',1,'SOC fraction',[1 1],[1 1],'Normalized fully charged upper limit.';
'dc_soc_initial','stationDC.battery.soc_initial',1,'SOC fraction',[0 1],[.2 1],'Default fully charged initial condition; consumer must keep it within the usable SOC window.';
'dc_cutoff_voltage_V','stationDC.battery.cutoff_voltage_V',105,'V',[99 110],[102 108],'Loaded-terminal undervoltage cutoff; discharge stops on voltage OR SOC threshold.';
'dc_max_discharge_A','stationDC.battery.max_discharge_A',200,'A',[50 400],[150 250],'Finite approximate 1C bank discharge bound; no short-circuit or cell-life validation.';
'dc_max_charge_A','stationDC.battery.max_charge_A',40,'A',[10 80],[20 60],'Finite approximate C/5 recharge bound, independently below total charger current capability.';
'dc_charge_efficiency','stationDC.battery.charge_efficiency',.9,'fraction',[.8 1],[.85 .95],'Simple coulombic charge efficiency; discharge capacity already uses terminal current.';
'charger_nominal_voltage_V','stationDC.charger.nominal_voltage_V',110,'V',[110 110],[110 110],'Charger nominal service class, not its regulation target.';
'charger_rated_power_kW','stationDC.charger.rated_power_kW',20,'kW',[10 40],[20 20],'Approved per-unit DC OUTPUT rating; AC input is DC output divided by efficiency.';
'charger_unit_count','stationDC.charger.unit_count',2,'units',[2 2],[2 2],'Approved two 100-percent-rated units, not two simultaneously active supplies.';
'charger_active_units','stationDC.charger.active_units',1,'units',[1 1],[1 1],'One duty unit; standby takeover replaces duty, never doubles normal output.';
'charger_efficiency','stationDC.charger.efficiency',.925,'fraction',[.85 .98],[.9 .95],'Approved DC-output/AC-input efficiency for accounting only.';
'charger_float_voltage_V','stationDC.charger.float_voltage_V',123.75,'V',[121 126.5],[122.1 125.4],'Illustrative 2.25 V/cell float target, distinct from 110 V nominal and 116 V full-charge OCV.';
'charger_max_current_A','stationDC.charger.max_current_A',180,'A',[100 250],[150 220],'Finite per-unit current ceiling; simultaneous 20 kW power bound also applies.';
'charger_min_current_A','stationDC.charger.min_current_A',0,'A',[0 0],[0 0],'Charger sources current only; no reverse-current sink.';
'charger_response_s','stationDC.charger.response_s',.1,'s',[.01 1],[.05 .3],'Finite first-order charging-current regulation response, untuned.';
'charger_voltage_gain_A_per_V','stationDC.charger.voltage_gain_A_per_V',50,'A/V',[10 200],[25 100],'Proportional voltage-error current demand before current/power/SOC limits.';
'load_relay_kW','stationDC.loads.continuous.relay_kW',.3,'kW',[.05 1],[.1 .5],'Continuous protection-relay electronics only, illustrative demand.';
'load_control_kW','stationDC.loads.continuous.control_kW',.5,'kW',[.1 2],[.2 1],'Continuous control electronics, not breaker coil pulses.';
'load_instrumentation_kW','stationDC.loads.continuous.instrumentation_kW',.4,'kW',[.05 1.5],[.2 .8],'Continuous measurement/transducer electronics, illustrative demand.';
'load_communications_kW','stationDC.loads.continuous.communications_kW',.2,'kW',[.05 1],[.1 .5],'Continuous communications electronics, illustrative demand.';
'load_emergency_control_kW','stationDC.loads.continuous.emergency_control_kW',.3,'kW',[.05 1],[.1 .5],'Always-on emergency-control electronics, separate from emergency switched demand.';
'load_excitation_electronics_kW','stationDC.loads.continuous.excitation_electronics_kW',.7,'kW',[.1 3],[.3 1.5],'Excitation auxiliary electronics ONLY; no generator field-power supply is inferred.';
'load_trip_kW','stationDC.loads.trip.power_kW',2,'kW',[.2 5],[1 3],'Additional aggregate illustrative trip-coil pulse power, not an installed breaker rating.';
'load_trip_duration_s','stationDC.loads.trip.duration_s',.2,'s',[.05 1],[.1 .5],'Finite illustrative trip pulse duration, not a breaker clearing time.';
'load_close_kW','stationDC.loads.close.power_kW',3,'kW',[.2 8],[1 5],'Additional aggregate illustrative close-coil pulse power, separate from trip.';
'load_close_duration_s','stationDC.loads.close.duration_s',.5,'s',[.1 2],[.2 1],'Finite illustrative close pulse duration, not switchgear operating validation.';
'load_emergency_additional_kW','stationDC.loads.emergency_additional_kW',5,'kW',[1 15],[3 8],'Additional switched emergency demand sustained for caller-selected scenario duration.';
'gov_droop_pu','governor.droop_pu',.05,'speed pu/power pu',[.03 .08],[.04 .06],'Approved 5-percent academic droop; power pu on primary machine MVA base, not an OEM controller.';
'gov_response_s','governor.response_s',.2,'s',[.05 1],[.1 .5],'Approved finite governor lag, readiness only.';
'gov_turbine_time_s','governor.turbine_response_s',.75,'s',[.2 3],[.5 1.5],'Approved lumped turbine lag, not a validated multi-shaft steam/gas model.';
'gov_speed_reference_pu','governor.speed_reference_pu',1,'speed pu',[1 1],[1 1],'Nominal synchronous-speed reference, no speed excursion tuning.';
'gov_turbine_gain','governor.turbine_gain',1,'pu/pu',[.8 1.2],[1 1],'Unity steady-state transfer for aggregate governor/turbine readiness.';
'gov_min_power_MW','governor.min_power_MW',0,'MW',[0 0],[0 0],'Academic nonnegative mechanical-power bound; upper screening bound comes from primary capacity.';
'pss_enabled','pss.enabled',0,'boolean',[0 0],[0 0],'Stored profile is disabled and untuned; enabling needs separate authorization and tuning.';
'pss_gain','pss.gain',10,'terminal V pu/speed pu',[1 30],[5 15],'Generic speed-input stabilizer gain, not a SEMIPOL setting.';
'pss_washout_s','pss.washout_s',10,'s',[1 30],[5 20],'Finite generic washout time, no frequency-response validation.';
'pss_lead1_s','pss.lead1_s',.1,'s',[.02 1],[.05 .3],'First generic lead time, stored only.';
'pss_lag1_s','pss.lag1_s',.02,'s',[.005 .2],[.01 .05],'First generic lag time, stored only.';
'pss_lead2_s','pss.lead2_s',.1,'s',[.02 1],[.05 .3],'Second generic lead time, stored only.';
'pss_lag2_s','pss.lag2_s',.02,'s',[.005 .2],[.01 .05],'Second generic lag time, stored only.';
'pss_output_min_pu','pss.output_min_pu',-.05,'terminal V pu',[-.2 -.01],[-.1 -.02],'Finite negative stabilizer-voltage bound; inactive while disabled.';
'pss_output_max_pu','pss.output_max_pu',.05,'terminal V pu',[.01 .2],[.02 .1],'Finite positive stabilizer-voltage bound; inactive while disabled.';
};
A = struct();
for k = 1:size(rows,1)
    key = rows{k,1};
    r = phase2_parameter(rows{k,3},rows{k,4}, ...
        'Approved Phase-2 Task-2 academic engineering selection', ...
        ['matlab/data/engineering_assumptions.m: ' key], ...
        'ENGINEERING_ASSUMPTION','Academic selection; not plant-validated', ...
        [rows{k,7} ' No installed plant rating or commissioned tuning is claimed.'], ...
        'assumption_basis',rows{k,7},'reasonable_range',rows{k,5}, ...
        'assumed_range',rows{k,6});
    r.assumption_key = key;
    r.component_path = rows{k,2};
    A.(key) = r;
end
end
'@
$path = 'matlab/data/engineering_assumptions.m'
[IO.File]::WriteAllText((Join-Path (Get-Location) $path), $text.Replace("`r`n", "`n") + "`n", [Text.UTF8Encoding]::new($false))
if ([IO.File]::ReadAllText((Join-Path (Get-Location) $path)) -cne ($text.Replace("`r`n", "`n") + "`n")) { throw 'Write verification failed' }
Write-Output "VERIFIED_WRITE $path"
