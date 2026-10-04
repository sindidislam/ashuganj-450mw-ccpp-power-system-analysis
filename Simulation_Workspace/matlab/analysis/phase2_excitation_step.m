function [state_next, outputs] = phase2_excitation_step(state, inputs, dt, config)
%PHASE2_EXCITATION_STEP Discrete-time step for isolated excitation system.
%   [state_next, outputs] = phase2_excitation_step(state, inputs, dt, config)
%
%   Models a generic academic static excitation system (SEMIPOL placeholder)
%   with AVR, field response lag, command limits, and OEL/UEL/stator limiters.
%
%   EQUATIONS & NUMERICAL METHOD:
%   First-order lags are updated using exact exponential state transitions
%   for piecewise-constant inputs:
%       x(t + dt) = x_target + (x(t) - x_target) * exp(-dt / T)
%   This guarantees unconditional stability regardless of time step dt.
%
%   AVR & Exciter:
%       Error = Vref - Vt
%       Vr_target = 1.0 + Ka * Error
%       T_avr * dVr/dt = Vr_target - Vr
%       Vr_limited = clamp(Vr - delta_oel + delta_uel +/- delta_stator, Efd_min, Efd_max)
%       Te * dEfd/dt = Vr_limited - Efd
%
%   Limiters:
%       OEL: activates when Efd / rated_field_ref > oel_threshold
%       UEL: activates when Q < Qmin(P) + uel_inset
%       Stator: activates when It > stator_threshold (continuous)

% 1. Input validation
if nargin < 4
    error('phase2_excitation_step:MissingArgs', 'Requires state, inputs, dt, and config.');
end
if ~isnumeric(dt) || ~isscalar(dt) || dt <= 0 || isnan(dt) || isinf(dt)
    error('phase2_excitation_step:InvalidDt', 'Time step dt must be a positive finite scalar.');
end

% 2. Extract configuration parameters
Ka = config.avr.gain.value;
Tavr = config.avr.response_s.value;
Efd_min = config.avr.command_min_pu.value;
Efd_max = config.avr.command_max_pu.value;
Te = config.field.response_s.value;

rated_field_ref = config.oel.rated_field_reference_pu.value;
oel_thresh = config.oel.threshold_pu.value;
Toel = config.oel.response_s.value;
Koel = config.oel.gain.value;

uel_inset = config.uel.inset_MVAr.value;
Tuel = config.uel.response_s.value;
Kuel = config.uel.gain_pu_per_MVAr.value;

stator_thresh = config.stator.threshold_pu.value;
Tstator = config.stator.response_s.value;
Kstator = config.stator.gain.value;

corr_min = config.limiters.min_correction_pu.value;
corr_max = config.limiters.max_correction_pu.value;

% 3. Extract and default state
if ~isfield(state, 'Efd'), state.Efd = 1.0; end
if ~isfield(state, 'Vr'), state.Vr = 1.0; end
if ~isfield(state, 'oel_state'), state.oel_state = 0.0; end
if ~isfield(state, 'uel_state'), state.uel_state = 0.0; end
if ~isfield(state, 'stator_state'), state.stator_state = 0.0; end

% 4. Extract and default inputs
Vt = inputs.Vt_pu;
Vref = inputs.Vref_pu;
P_MW = inputs.P_MW;
Q_MVAr = inputs.Q_MVAr;
It_pu = inputs.It_pu;

% 5. AVR Error and Raw Command
Verr = Vref - Vt;
Vr_target = 1.0 + Ka * Verr;
% Exact exponential lag update for AVR state
Vr = Vr_target + (state.Vr - Vr_target) * exp(-dt / Tavr);

% 6. OEL Limiter
Efd_field_pu = state.Efd / rated_field_ref;
if Efd_field_pu > oel_thresh
    oel_active = true;
    oel_err = Efd_field_pu - oel_thresh;
    oel_target = min(max(Koel * oel_err, corr_min), corr_max);
else
    oel_active = false;
    oel_target = 0.0;
end
oel_state = oel_target + (state.oel_state - oel_target) * exp(-dt / Toel);

% 7. UEL Limiter
[Qmin_curve, ~] = generatorCapability(P_MW, config.uel.curve.raw_source);
Q_boundary = Qmin_curve + uel_inset;
if Q_MVAr < Q_boundary
    uel_active = true;
    uel_err = Q_boundary - Q_MVAr;
    uel_target = min(max(Kuel * uel_err, corr_min), corr_max);
else
    uel_active = false;
    uel_target = 0.0;
end
uel_state = uel_target + (state.uel_state - uel_target) * exp(-dt / Tuel);

% 8. Stator Current Limiter
if It_pu > stator_thresh
    stator_active = true;
    stator_alarm = true;
    stator_err = It_pu - stator_thresh;
    stator_target = min(max(Kstator * stator_err, corr_min), corr_max);
else
    stator_active = false;
    stator_alarm = false;
    stator_target = 0.0;
end
stator_state = stator_target + (state.stator_state - stator_target) * exp(-dt / Tstator);

% Direction of stator correction depends on reactive operating regime
if Q_MVAr >= 0
    stator_correction_signed = -stator_state;
else
    stator_correction_signed = +stator_state;
end

% 9. Net Command and Saturation
Vr_net = Vr - oel_state + uel_state + stator_correction_signed;

sat_ceiling = (Vr_net >= Efd_max);
sat_floor   = (Vr_net <= Efd_min);
Vr_limited  = min(max(Vr_net, Efd_min), Efd_max);

% 10. Field Response Lag
Efd_next = Vr_limited + (state.Efd - Vr_limited) * exp(-dt / Te);

% 11. Package Next State and Outputs
state_next = struct();
state_next.Efd = Efd_next;
state_next.Vr = Vr;
state_next.oel_state = oel_state;
state_next.uel_state = uel_state;
state_next.stator_state = stator_state;

outputs = struct();
outputs.Efd = Efd_next;
outputs.Vr = Vr;
outputs.Vr_net = Vr_net;
outputs.Vr_limited = Vr_limited;
outputs.oel_active = oel_active;
outputs.oel_correction = oel_state;
outputs.uel_active = uel_active;
outputs.uel_correction = uel_state;
outputs.stator_limiter_active = stator_active;
outputs.stator_correction = stator_state;
outputs.stator_overload_alarm = stator_alarm;
outputs.saturated_ceiling = sat_ceiling;
outputs.saturated_floor = sat_floor;
end
