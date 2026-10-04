function res = check_generator_operating_point(Pgen, Qgen, Snom, curve)
%CHECK_GENERATOR_OPERATING_POINT Evaluates generator operating point against P-Q capability curve.
%   res = CHECK_GENERATOR_OPERATING_POINT(Pgen, Qgen, Snom, curve)
%
%   Checks:
%   1. Apparent power Sgen = sqrt(Pgen^2 + Qgen^2) <= Snom (458 MVA default)
%   2. Reactive power limits from piecewise-linear capability curve:
%      Qmin_allowed <= Qgen <= Qmax_allowed
%   3. Operating margins:
%      Q_upper_margin = Qmax_allowed - Qgen
%      Q_lower_margin = Qgen - Qmin_allowed
%      MVA_margin = Snom - Sgen
%   4. Operating power factor and designation (Lagging / Leading / Unity)
%
%   CRITICAL COMPLIANCE RULES:
%   - Prompt §10: NEVER clip Q. NEVER modify Q to force compliance.
%   - Violations are reported truthfully and transparently.

if nargin < 3 || isempty(Snom)
    Snom = 458.0; % Authoritative Snom from generator nameplate
end

if nargin < 4 || isempty(curve)
    % Retrieve authoritative capability curve without altering caller state
    G = ashuganj_generators();
    curve = G.capabilityCurve;
end

% 1. Core Operating Quantities
Sgen = sqrt(Pgen.^2 + Qgen.^2);
if Sgen > 0
    pf = abs(Pgen) ./ Sgen;
else
    pf = 1.0;
end

if Qgen > 1e-4
    pf_type = 'Lagging';
elseif Qgen < -1e-4
    pf_type = 'Leading';
else
    pf_type = 'Unity';
end

% 2. Piecewise-Linear Capability Curve Evaluation
[qmin_allowed, qmax_allowed] = generatorCapability(Pgen, curve);

% 3. Margins
q_upper_margin = qmax_allowed - Qgen;
q_lower_margin = Qgen - qmin_allowed;
mva_margin = Snom - Sgen;

% 4. Status Evaluation
violations = {};
if Qgen > qmax_allowed + 1e-4
    violations{end+1} = 'VIOLATION_QMAX';
end
if Qgen < qmin_allowed - 1e-4
    violations{end+1} = 'VIOLATION_QMIN';
end
if Sgen > Snom + 1e-4
    violations{end+1} = 'VIOLATION_MVA';
end

if isempty(violations)
    status = 'WITHIN_CAPABILITY';
elseif numel(violations) == 1
    status = violations{1};
else
    status = 'VIOLATION_MULTIPLE';
end

% 5. Build Result Record
res = struct();
res.P_MW = Pgen;
res.Q_MW = Qgen; % Prompt and physics require exact unclipped Q
res.Q_MVAr = Qgen;
res.S_MVA = Sgen;
res.Snom_MVA = Snom;
res.PF = pf;
res.PF_type = pf_type;
res.Qmax_allowed_MVAr = qmax_allowed;
res.Qmin_allowed_MVAr = qmin_allowed;
res.Q_upper_margin_MVAr = q_upper_margin;
res.Q_lower_margin_MVAr = q_lower_margin;
res.MVA_margin = mva_margin;
res.status = status;
res.violations = violations;
res.Q_clipped = false; % Explicit assertion of non-clipping policy per prompt §10
res.provenance = curve.status;
end
