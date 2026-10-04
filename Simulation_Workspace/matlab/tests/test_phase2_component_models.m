function [np, nf] = test_phase2_component_models()
%TEST_PHASE2_COMPONENT_MODELS Tests for isolated non-ideal component models:
%   - Excitation / AVR / Limiters (phase2_excitation_step)
%   - Starting Frequency Converter (phase2_sfc_step)
%   - Station DC / Battery / Charger / Loads (phase2_dc_step)
%
%   Verifies exact exponential lag formulation, limiter activation,
%   finite power/current ceilings, non-ideal battery sag and cutoff,
%   charger duty/standby behavior, and absence of ideal/infinite sources.

T = t_case('Phase 2 Component Models');

% Load component configurations
S = ashuganj_phase2_systems();
cfg_exc = S.excitation;
cfg_sfc = S.sfc;
cfg_dc  = S.stationDC;

%% 1. Exciter / AVR / Limiter Tests
% 1.1 Quiescent steady state at nominal
s0_exc = struct('Efd', 1.0, 'Vr', 1.0, 'oel_state', 0.0, 'uel_state', 0.0, 'stator_state', 0.0);
in_nom = struct('Vt_pu', 1.0, 'Vref_pu', 1.0, 'P_MW', 300.0, 'Q_MVAr', 0.0, 'It_pu', 0.65);
[s1, out1] = phase2_excitation_step(s0_exc, in_nom, 0.01, cfg_exc);
T = T.eq(out1.Efd >= 0.99 && out1.Efd <= 1.01, true, 'exciter_quiescent_equilibrium');
T = T.eq(out1.oel_active, false, 'oel_inactive_at_nominal');
T = T.eq(out1.uel_active, false, 'uel_inactive_at_nominal');
T = T.eq(out1.stator_limiter_active, false, 'stator_limiter_inactive_at_nominal');

% 1.2 Step response to terminal voltage dip (Vt = 0.98 pu)
% AVR gain Ka=200, error = 0.02 pu -> target Vr = 4.0 pu.
% Over 0.1 s, Efd should increase smoothly.
s_step = s0_exc;
in_dip = in_nom; in_dip.Vt_pu = 0.98;
for k = 1:20
    [s_step, out_step] = phase2_excitation_step(s_step, in_dip, 0.01, cfg_exc);
end
T = T.eq(out_step.Efd > 1.05, true, 'exciter_positive_step_response');
T = T.eq(out_step.Efd < 5.0, true, 'exciter_finite_exponential_lag');

% 1.3 Exciter command saturation limits (-5 pu to +5 pu)
in_heavy_dip = in_nom; in_heavy_dip.Vt_pu = 0.50; % Error = 0.5 * 200 = 100 pu -> must clamp at +5.0 pu
s_heavy = s0_exc;
for k = 1:500 % 5.0 s (10 * Te)
    [s_heavy, out_heavy] = phase2_excitation_step(s_heavy, in_heavy_dip, 0.01, cfg_exc);
end
T = T.near(out_heavy.Efd, 5.0, 1e-3, 'exciter_positive_ceiling_clamp');
T = T.eq(out_heavy.saturated_ceiling, true, 'exciter_ceiling_flag');

in_heavy_ov = in_nom; in_heavy_ov.Vt_pu = 1.50; % Error = -0.5 * 200 = -100 pu -> must clamp at -5.0 pu
s_ov = s0_exc;
for k = 1:500
    [s_ov, out_ov] = phase2_excitation_step(s_ov, in_heavy_ov, 0.01, cfg_exc);
end
T = T.near(out_ov.Efd, -5.0, 1e-3, 'exciter_negative_floor_clamp');
T = T.eq(out_ov.saturated_floor, true, 'exciter_floor_flag');

% 1.4 OEL activation: high Efd triggers OEL reduction
% Threshold is 1.075 * 2.5 = 2.6875 Efd pu. Let Efd be 3.5 pu.
s_oel = struct('Efd', 3.5, 'Vr', 3.5, 'oel_state', 0.0, 'uel_state', 0.0, 'stator_state', 0.0);
[s_oel_next, out_oel] = phase2_excitation_step(s_oel, in_nom, 0.1, cfg_exc);
T = T.eq(out_oel.oel_active, true, 'oel_activates_on_field_exceedance');
T = T.eq(out_oel.oel_correction > 0, true, 'oel_positive_correction');

% 1.5 UEL activation: reactive power below source Qmin(P) + 5 MVAr
% At P = 300 MW, Qmin = -205 MVAr. Inset = 5 MVAr -> threshold = -200 MVAr.
% With Q = -215 MVAr (15 MVAr below threshold), UEL must activate.
in_uel = in_nom; in_uel.P_MW = 300.0; in_uel.Q_MVAr = -215.0;
[s_uel_next, out_uel] = phase2_excitation_step(s0_exc, in_uel, 0.05, cfg_exc);
T = T.eq(out_uel.uel_active, true, 'uel_activates_below_inset_boundary');
T = T.eq(out_uel.uel_correction > 0, true, 'uel_positive_boost_correction');

% 1.6 Stator current limiter: stator current > 1.0 pu
in_stator = in_nom; in_stator.It_pu = 1.15; in_stator.Q_MVAr = 100.0; % overexcited stator overload
[s_stator_next, out_stator] = phase2_excitation_step(s0_exc, in_stator, 0.05, cfg_exc);
T = T.eq(out_stator.stator_limiter_active, true, 'stator_limiter_activates_on_overcurrent');
T = T.eq(out_stator.stator_overload_alarm, true, 'stator_overload_alarm_raised');

% 1.7 Input validation
try
    phase2_excitation_step(s0_exc, in_nom, -0.01, cfg_exc);
    err_exc_neg = false;
catch
    err_exc_neg = true;
end
T = T.chk(err_exc_neg, 'exciter_rejects_negative_dt');

try
    phase2_excitation_step(s0_exc, in_nom, 0, cfg_exc);
    err_exc_zero = false;
catch
    err_exc_zero = true;
end
T = T.chk(err_exc_zero, 'exciter_rejects_zero_dt');


%% 2. SFC Component Tests
% 2.1 Starting power ramping with finite response (tau = 0.03 s)
s0_sfc = struct('P_out_MW', 0.0);
in_sfc_ramp = struct('P_cmd_MW', 2.0, 'enable', true);
[s1_sfc, out1_sfc] = phase2_sfc_step(s0_sfc, in_sfc_ramp, 0.03, cfg_sfc);
% After 1 time constant (dt = 0.03 s), output should reach 2 * (1 - exp(-1)) = 2 * 0.63212 = 1.2642 MW
T = T.near(out1_sfc.P_out_MW, 2.0 * (1 - exp(-1)), 1e-3, 'sfc_exponential_lag_response');
T = T.eq(out1_sfc.active, true, 'sfc_active_flag');

% 2.2 Efficiency and loss accounting (efficiency = 0.97)
% P_in = P_out / 0.97, P_loss = P_in - P_out
T = T.near(out1_sfc.P_in_MW, out1_sfc.P_out_MW / 0.97, 1e-4, 'sfc_efficiency_input_power');
T = T.near(out1_sfc.P_loss_MW, out1_sfc.P_in_MW - out1_sfc.P_out_MW, 1e-4, 'sfc_loss_accounting');

% 2.3 Output power limits [0, 4 MW]
in_sfc_over = struct('P_cmd_MW', 10.0, 'enable', true); % Exceeds 4 MW maximum
s_sfc_over = s0_sfc;
for k = 1:100 % 1.0 s
    [s_sfc_over, out_sfc_over] = phase2_sfc_step(s_sfc_over, in_sfc_over, 0.01, cfg_sfc);
end
T = T.near(out_sfc_over.P_out_MW, 4.0, 1e-3, 'sfc_clamps_at_max_power_4MW');

in_sfc_neg = struct('P_cmd_MW', -1.0, 'enable', true); % Negative power request
[~, out_sfc_neg] = phase2_sfc_step(s0_sfc, in_sfc_neg, 0.01, cfg_sfc);
T = T.near(out_sfc_neg.P_out_MW, 0.0, 1e-6, 'sfc_clamps_negative_power_to_zero');

% 2.4 Disable behavior
in_sfc_dis = struct('P_cmd_MW', 2.0, 'enable', false);
s_sfc_dis = struct('P_out_MW', 2.0);
for k = 1:100
    [s_sfc_dis, out_sfc_dis] = phase2_sfc_step(s_sfc_dis, in_sfc_dis, 0.01, cfg_sfc);
end
T = T.near(out_sfc_dis.P_out_MW, 0.0, 1e-3, 'sfc_ramps_to_zero_when_disabled');

% 2.5 Input validation
try
    phase2_sfc_step(s0_sfc, in_sfc_ramp, -0.01, cfg_sfc);
    err_sfc_neg = false;
catch
    err_sfc_neg = true;
end
T = T.chk(err_sfc_neg, 'sfc_rejects_negative_dt');


%% 3. Station DC / Battery / Charger Tests
% 3.1 Quiescent steady state at full SOC (SOC = 1.0)
% Total continuous load = 0.3 + 0.5 + 0.4 + 0.2 + 0.3 + 0.7 = 2.4 kW.
% Charger active and available: at full SOC, charger supplies load only to avoid overcharging.
s0_dc = struct('soc', 1.0, 'V_batt', 116.0, 'I_batt', 0.0, 'charger_P_kW', 2.4, ...
    'trip_timer_s', 0.0, 'close_timer_s', 0.0);
in_dc_norm = struct('trip_cmd', false, 'close_cmd', false, 'emergency_cmd', false, ...
    'charger_available', true, 'duty_charger_index', 1);
[s1_dc, out1_dc] = phase2_dc_step(s0_dc, in_dc_norm, 0.1, cfg_dc);

T = T.near(out1_dc.P_load_kW, 2.4, 1e-3, 'dc_continuous_load_2p4kW');
T = T.near(out1_dc.I_batt, 0.0, 1e-2, 'dc_battery_floating_at_full_soc');
T = T.near(out1_dc.soc, 1.0, 1e-4, 'dc_full_soc_preserved');
T = T.near(out1_dc.P_charger_kW, 2.4, 0.1, 'charger_supplies_continuous_load');
T = T.near(out1_dc.P_charger_AC_kW, out1_dc.P_charger_kW / 0.925, 1e-3, 'charger_ac_efficiency_accounting');
T = T.eq(out1_dc.battery_cutoff, false, 'battery_cutoff_false_at_nominal');

% 3.2 Trip and Close pulse demands
% Trip pulse: +2.0 kW for 0.2 s -> total load = 4.4 kW
in_trip = in_dc_norm; in_trip.trip_cmd = true;
[s_trip, out_trip] = phase2_dc_step(s0_dc, in_trip, 0.05, cfg_dc);
T = T.near(out_trip.P_load_kW, 4.4, 1e-3, 'trip_pulse_adds_2kW');
T = T.eq(s_trip.trip_timer_s > 0, true, 'trip_pulse_timer_active');

% Close pulse: +3.0 kW for 0.5 s -> total load = 5.4 kW
in_close = in_dc_norm; in_close.close_cmd = true;
[s_close, out_close] = phase2_dc_step(s0_dc, in_close, 0.05, cfg_dc);
T = T.near(out_close.P_load_kW, 5.4, 1e-3, 'close_pulse_adds_3kW');
T = T.eq(s_close.close_timer_s > 0, true, 'close_pulse_timer_active');

% Emergency switched demand: +5.0 kW
in_emerg = in_dc_norm; in_emerg.emergency_cmd = true;
[~, out_emerg] = phase2_dc_step(s0_dc, in_emerg, 0.05, cfg_dc);
T = T.near(out_emerg.P_load_kW, 7.4, 1e-3, 'emergency_switched_demand_adds_5kW');

% 3.3 Battery discharge on charger failure (Mains failure)
% When charger_available = false, battery must supply load.
% At 2.4 kW and V_term approx 115 V, I_batt = 2400 / 115 = 20.87 A.
in_no_charger = in_dc_norm; in_no_charger.charger_available = false;
s_dc_disch = s0_dc;
for k = 1:360 % 360 s (6 minutes) with dt = 1.0 s
    [s_dc_disch, out_dc_disch] = phase2_dc_step(s_dc_disch, in_no_charger, 1.0, cfg_dc);
end
T = T.eq(out_dc_disch.I_batt > 15.0, true, 'battery_supplies_discharge_current');
T = T.eq(out_dc_disch.soc < 1.0, true, 'battery_soc_depleted_during_discharge');
T = T.near(out_dc_disch.P_charger_kW, 0.0, 1e-4, 'charger_zero_output_when_unavailable');

% 3.4 Non-ideal battery internal resistance and terminal voltage sag
% At I_batt = 100 A, with R_int = 0.05 ohm, terminal sag must be exactly I * R = 5.0 V
% V_ocv at SOC=1.0 is 116 V -> V_term = 116 - 5 = 111 V.
s_heavy_batt = s0_dc;
s_heavy_batt.charger_P_kW = 0;
in_heavy_dc = in_no_charger;
in_heavy_dc.emergency_cmd = true;
in_heavy_dc.trip_cmd = true;
in_heavy_dc.close_cmd = true;
[~, out_heavy_dc] = phase2_dc_step(s_heavy_batt, in_heavy_dc, 0.01, cfg_dc);
V_expected_sag = out_heavy_dc.V_ocv - out_heavy_dc.I_batt * 0.05;
T = T.near(out_heavy_dc.V_term, V_expected_sag, 1e-3, 'battery_terminal_voltage_sag_equals_IR');

% 3.5 Battery undervoltage and SOC cutoff
% At SOC <= 0.20 or V_term <= 105 V, cutoff must trigger and stop further discharge
s_cutoff = s0_dc; s_cutoff.soc = 0.19; % Below min SOC (0.20)
[~, out_cutoff] = phase2_dc_step(s_cutoff, in_no_charger, 1.0, cfg_dc);
T = T.eq(out_cutoff.battery_cutoff, true, 'battery_cutoff_triggers_at_soc_min');
T = T.near(out_cutoff.I_batt, 0.0, 1e-3, 'battery_disconnects_at_cutoff');

% 3.6 Charger current and power ceilings
T = T.eq(cfg_dc.charger.rated_power_kW.value, 20.0, 'charger_rated_20kW');
T = T.eq(cfg_dc.charger.max_current_A.value, 180.0, 'charger_max_180A');

% 3.7 Duty / Standby charger redundancy
% Unit 1 is duty; if unit 1 unavailable, unit 2 operates as standby
in_standby = in_dc_norm; in_standby.duty_charger_index = 2;
[~, out_standby] = phase2_dc_step(s0_dc, in_standby, 0.1, cfg_dc);
T = T.near(out_standby.P_charger_kW, 2.4, 0.1, 'standby_charger_takes_over_duty');
T = T.eq(out_standby.standby_active, true, 'standby_active_flag_set');

% 3.8 Input validation
try
    phase2_dc_step(s0_dc, in_dc_norm, -0.1, cfg_dc);
    err_dc_neg = false;
catch
    err_dc_neg = true;
end
T = T.chk(err_dc_neg, 'dc_rejects_negative_dt');

try
    s_bad_soc = s0_dc; s_bad_soc.soc = 1.5;
    phase2_dc_step(s_bad_soc, in_dc_norm, 0.1, cfg_dc);
    err_dc_soc = false;
catch
    err_dc_soc = true;
end
% 3.9 Charger closed-loop float voltage regulation toward V_float (123.75 V)
% Starting from 116 V OCV, after 20 steps (1.0 s, dt=0.05 s = 10*tau), V_bus converges to V_float (123.75 V)
s_float = s0_dc;
for k = 1:20
    [s_float, out_float] = phase2_dc_step(s_float, in_dc_norm, 0.05, cfg_dc);
end
T = T.near(out_float.V_bus, 123.75, 1e-2, 'charger_regulates_bus_to_float_voltage_123p75V');
T = T.near(out_float.V_term, 123.75, 1e-2, 'battery_terminal_held_at_float_voltage');
T = T.near(out_float.I_batt, 0.0, 1e-3, 'battery_floating_zero_trickle_at_equilibrium');

%% Final summary
[np, nf] = T.done();
end
