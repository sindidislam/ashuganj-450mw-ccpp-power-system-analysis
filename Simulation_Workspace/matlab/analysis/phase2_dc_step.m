function [state_next, outputs] = phase2_dc_step(state, inputs, dt, config)
%PHASE2_DC_STEP Discrete-time step for station DC system (Battery, Charger, Loads).
%   [state_next, outputs] = phase2_dc_step(state, inputs, dt, config)
%
%   Models an isolated academic 110 VDC station system with:
%   - Lead-acid battery bank (55 cells, 200 Ah, 0.05 ohm internal resistance)
%   - Dual 20 kW battery chargers (duty/standby redundancy, float 123.75 V)
%   - DC auxiliary loads (2.4 kW continuous, trip/close pulses, emergency)
%
%   NON-IDEAL CHARACTERISTICS:
%   - Finite internal resistance produces terminal voltage sag: Vterm = Vocv - I*R
%   - Coulombic charge efficiency (0.90) and finite charge/discharge bounds
%   - Full-SOC overcharge prevention (charger supplies load only)
%   - Undervoltage (105 V) and reserve SOC (0.20) cutoff
%   - Standby charger replaces failed duty unit without doubling output

% 1. Input validation
if nargin < 4
    error('phase2_dc_step:MissingArgs', 'Requires state, inputs, dt, and config.');
end
if ~isnumeric(dt) || ~isscalar(dt) || dt <= 0 || isnan(dt) || isinf(dt)
    error('phase2_dc_step:InvalidDt', 'Time step dt must be a positive finite scalar.');
end

% 2. Extract configuration parameters
% Battery
Vnom_batt   = config.battery.nominal_voltage_V.value;
C_Ah        = config.battery.capacity_Ah.value;
R_bank      = config.battery.internal_resistance_ohm.value;
ocv_soc     = config.battery.ocv_soc.value;
ocv_V       = config.battery.ocv_V.value;
soc_min     = config.battery.soc_min.value;
soc_max     = config.battery.soc_max.value;
V_cutoff    = config.battery.cutoff_voltage_V.value;
I_disch_max = config.battery.max_discharge_A.value;
I_chg_max   = config.battery.max_charge_A.value;
eta_chg     = config.battery.charge_efficiency.value;

% Charger
P_chg_rated = config.charger.rated_power_kW.value;
eta_charger = config.charger.efficiency.value;
V_float     = config.charger.float_voltage_V.value;
I_chg_lim   = config.charger.max_current_A.value;
tau_chg     = config.charger.response_s.value;
K_v_chg     = config.charger.voltage_gain_A_per_V.value;

% Loads
P_relay     = config.loads.continuous.relay_kW.value;
P_ctrl      = config.loads.continuous.control_kW.value;
P_inst      = config.loads.continuous.instrumentation_kW.value;
P_comm      = config.loads.continuous.communications_kW.value;
P_em_ctrl   = config.loads.continuous.emergency_control_kW.value;
P_exc_el    = config.loads.continuous.excitation_electronics_kW.value;
P_cont      = P_relay + P_ctrl + P_inst + P_comm + P_em_ctrl + P_exc_el;

P_trip_pulse = config.loads.trip.power_kW.value;
T_trip_dur   = config.loads.trip.duration_s.value;
P_close_pulse = config.loads.close.power_kW.value;
T_close_dur  = config.loads.close.duration_s.value;
P_emerg_add  = config.loads.emergency_additional_kW.value;

% 3. Extract and validate state
if ~isfield(state, 'soc'), state.soc = 1.0; end
if state.soc < 0 || state.soc > 1.0
    error('phase2_dc_step:InvalidSOC', 'Battery SOC must be within [0, 1].');
end
if ~isfield(state, 'V_batt'), state.V_batt = ocv_V(2); end
if ~isfield(state, 'I_batt'), state.I_batt = 0.0; end
if ~isfield(state, 'charger_P_kW'), state.charger_P_kW = P_cont; end
if ~isfield(state, 'trip_timer_s'), state.trip_timer_s = 0.0; end
if ~isfield(state, 'close_timer_s'), state.close_timer_s = 0.0; end

% 4. Extract inputs
trip_cmd    = isfield(inputs, 'trip_cmd') && logical(inputs.trip_cmd);
close_cmd   = isfield(inputs, 'close_cmd') && logical(inputs.close_cmd);
emerg_cmd   = isfield(inputs, 'emergency_cmd') && logical(inputs.emergency_cmd);
charger_avail = ~isfield(inputs, 'charger_available') || logical(inputs.charger_available);
duty_idx    = 1;
if isfield(inputs, 'duty_charger_index')
    duty_idx = inputs.duty_charger_index;
end
standby_active = (duty_idx == 2);

% 5. Pulse Timer Updates & Load Calculation
trip_timer = state.trip_timer_s;
if trip_cmd
    trip_timer = T_trip_dur;
else
    trip_timer = max(0.0, trip_timer - dt);
end

close_timer = state.close_timer_s;
if close_cmd
    close_timer = T_close_dur;
else
    close_timer = max(0.0, close_timer - dt);
end

P_load = P_cont;
if trip_timer > 0
    P_load = P_load + P_trip_pulse;
end
if close_timer > 0
    P_load = P_load + P_close_pulse;
end
if emerg_cmd
    P_load = P_load + P_emerg_add;
end

% 6. OCV Calculation from SOC (linear lookup)
Vocv = ocv_V(1) + (ocv_V(2) - ocv_V(1)) * state.soc;

% 7. Battery and Charger Coordination
battery_cutoff = false;
P_unmet = 0.0;

if charger_avail
    % Charger is supplying DC bus with closed-loop voltage regulation toward V_float
    if state.soc >= 0.999
        % Full-SOC policy: battery is floating (I_batt = 0), charger supplies load
        % and regulates DC bus toward float voltage (V_float = 123.75 V) with finite lag
        P_chg_target = min(P_load, P_chg_rated);
        P_chg_next = P_chg_target + (state.charger_P_kW - P_chg_target) * exp(-dt / tau_chg);
        I_batt = 0.0;
        V_bus = V_float + (state.V_batt - V_float) * exp(-dt / tau_chg);
        V_term = V_bus;
    else
        % Battery needs recharging: charger supplies load + bounded recharge current
        I_chg_raw = (V_float - Vocv) / R_bank;
        P_chg_avail = max(0.0, P_chg_rated - P_load);
        I_chg_avail = min(I_chg_lim - P_load * 1000 / V_float, P_chg_avail * 1000 / V_float);
        I_chg_target = max(0.0, min([I_chg_raw, I_chg_avail, I_chg_max]));
        I_batt = -I_chg_target; % negative means charging
        
        V_term = Vocv - I_batt * R_bank;
        V_bus = V_term;
        P_chg_target = min(P_load + (I_chg_target * V_term / 1000), P_chg_rated);
        P_chg_next = P_chg_target + (state.charger_P_kW - P_chg_target) * exp(-dt / tau_chg);
    end
else
    % Mains/charger failure: Battery supplies load
    P_chg_next = 0.0;
    
    % Check cutoff conditions
    if state.soc <= soc_min || Vocv <= V_cutoff
        battery_cutoff = true;
        I_batt = 0.0;
        V_term = Vocv;
        V_bus = 0.0;
        P_unmet = P_load;
    else
        % Solve quadratic for battery discharge current:
        % P_load_W = (Vocv - I_batt * R_bank) * I_batt
        % R_bank * I^2 - Vocv * I + P_load_W = 0
        P_load_W = P_load * 1000;
        discriminant = Vocv^2 - 4 * R_bank * P_load_W;
        if discriminant >= 0
            I_sol = (Vocv - sqrt(discriminant)) / (2 * R_bank);
            I_batt = min(I_sol, I_disch_max);
        else
            % Voltage collapse: limit to max discharge current
            I_batt = I_disch_max;
        end
        V_term = Vocv - I_batt * R_bank;
        V_bus = V_term;
        
        if V_term <= V_cutoff
            battery_cutoff = true;
            I_batt = 0.0;
            V_bus = 0.0;
            P_unmet = P_load;
        end
    end
end

% 8. SOC Integration
if I_batt > 0
    % Discharging
    dSOC = -(I_batt * dt) / (3600 * C_Ah);
elseif I_batt < 0
    % Charging (with coulombic efficiency)
    dSOC = -(eta_chg * I_batt * dt) / (3600 * C_Ah);
else
    dSOC = 0.0;
end
soc_next = min(max(state.soc + dSOC, 0.0), soc_max);

% 9. Charger AC Power and Losses
if P_chg_next > 0
    P_charger_AC = P_chg_next / eta_charger;
    P_charger_losses = P_charger_AC - P_chg_next;
else
    P_charger_AC = 0.0;
    P_charger_losses = 0.0;
end

% 10. Package Next State and Outputs
state_next = struct();
state_next.soc = soc_next;
state_next.V_batt = V_term;
state_next.I_batt = I_batt;
state_next.charger_P_kW = P_chg_next;
state_next.trip_timer_s = trip_timer;
state_next.close_timer_s = close_timer;

outputs = struct();
outputs.soc = soc_next;
outputs.V_ocv = Vocv;
outputs.V_term = V_term;
outputs.V_bus = V_bus;
outputs.I_batt = I_batt;
outputs.P_load_kW = P_load;
outputs.P_charger_kW = P_chg_next;
outputs.P_charger_AC_kW = P_charger_AC;
outputs.charger_losses_kW = P_charger_losses;
outputs.battery_cutoff = battery_cutoff;
outputs.P_unmet_kW = P_unmet;
outputs.standby_active = standby_active;
end
