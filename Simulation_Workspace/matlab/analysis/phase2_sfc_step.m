function [state_next, outputs] = phase2_sfc_step(state, inputs, dt, config)
%PHASE2_SFC_STEP Discrete-time step for Static Frequency Converter (SFC).
%   [state_next, outputs] = phase2_sfc_step(state, inputs, dt, config)
%
%   Models an isolated starting frequency converter with finite power limits,
%   first-order lag response, and efficiency/loss accounting.
%
%   EQUATIONS & DATA PROVENANCE:
%   First-order exponential response for commanded output power:
%       P_target = clamp(P_cmd, P_min, P_max)  (if enabled, else 0)
%       P_out(t + dt) = P_target + (P_out(t) - P_target) * exp(-dt / tau)
%
%   Power & Loss Accounting:
%       P_in = P_out / efficiency
%       P_loss = P_in - P_out
%
%   Preserved Source Data:
%       DC Link: 2.28 kV (source verified)
%       Output Starting Current: 1876 A (source verified)
%       Note: P_out is bounded by the separately assumed 4 MW limit,
%       NOT by 2.28 kV * 1876 A.

% 1. Input validation
if nargin < 4
    error('phase2_sfc_step:MissingArgs', 'Requires state, inputs, dt, and config.');
end
if ~isnumeric(dt) || ~isscalar(dt) || dt <= 0 || isnan(dt) || isinf(dt)
    error('phase2_sfc_step:InvalidDt', 'Time step dt must be a positive finite scalar.');
end

% 2. Extract configuration parameters
eta = config.efficiency.value;
tau = config.response_s.value;
P_min = config.min_output_power_MW.value;
P_max = config.max_output_power_MW.value;
dc_link_kV = config.dc_link_kV.value;
max_out_A = config.max_starting_output_A.value;

% 3. Extract and default state
if ~isfield(state, 'P_out_MW')
    state.P_out_MW = 0.0;
end

% 4. Extract and default inputs
if isfield(inputs, 'enable')
    enable = logical(inputs.enable);
else
    enable = true;
end
if isfield(inputs, 'P_cmd_MW')
    P_cmd = double(inputs.P_cmd_MW);
else
    P_cmd = 0.0;
end

% 5. Target calculation & exponential lag update
if enable
    P_target = min(max(P_cmd, P_min), P_max);
else
    P_target = 0.0;
end

P_out_next = P_target + (state.P_out_MW - P_target) * exp(-dt / tau);
if P_out_next < 1e-9
    P_out_next = 0.0;
end

% 6. Power and Loss Accounting
if P_out_next > 0
    P_in = P_out_next / eta;
    P_loss = P_in - P_out_next;
else
    P_in = 0.0;
    P_loss = 0.0;
end

% 7. Package Next State and Outputs
state_next = struct();
state_next.P_out_MW = P_out_next;

outputs = struct();
outputs.P_out_MW = P_out_next;
outputs.P_in_MW = P_in;
outputs.P_loss_MW = P_loss;
outputs.active = (P_out_next > 1e-4);
outputs.efficiency = eta;
outputs.dc_link_kV = dc_link_kV;
outputs.max_starting_output_A = max_out_A;
end
