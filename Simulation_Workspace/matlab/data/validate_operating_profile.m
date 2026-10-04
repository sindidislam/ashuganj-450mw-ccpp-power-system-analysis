function ok = validate_operating_profile(profile, P_capacity_MW)
%VALIDATE_OPERATING_PROFILE Validates an operating profile and enforces capacity guard.
%   ok = validate_operating_profile(profile, P_capacity_MW)
%
%   Enforces:
%   1. Primary dispatch guard: P_dispatch <= P_capacity (360 MW).
%      Only cases with approved_exception == true may exceed 360 MW (historical cases).
%   2. Rejection of illegal exceptions on primary cases.
%   3. Verified voltage setpoints (1.00 pu).
%   4. Auxiliary load compliance (14 MW).
%   5. Finite capability-derived reactive power limits.

if nargin < 2 || isempty(P_capacity_MW)
    P_capacity_MW = 360.00;
end

if ~isstruct(profile) || ~isscalar(profile)
    error('validate_operating_profile:InvalidProfile', 'Profile must be a scalar struct.');
end

required_fields = {'ID', 'Gen_P_MW', 'GAT_in', 'Topology', 'Gen_Vset_pu', 'Grid_Vset_pu'};
for k = 1:numel(required_fields)
    if ~isfield(profile, required_fields{k})
        error('validate_operating_profile:MissingField', 'Profile missing required field: %s', required_fields{k});
    end
end

P_dispatch = profile.Gen_P_MW;
has_exception = isfield(profile, 'approved_exception') && logical(profile.approved_exception);
status_str = '';
if isfield(profile, 'status'), status_str = profile.status; end

% 1. Capacity Guard: P <= 360 MW for primary cases
if P_dispatch > P_capacity_MW
    if ~has_exception
        error('validate_operating_profile:CapacityExceeded', ...
            'Dispatch %.2f MW exceeds capacity %.2f MW without approved exception.', ...
            P_dispatch, P_capacity_MW);
    end
else
    % Primary case trying to set approved_exception is illegal
    if has_exception && ~strcmp(status_str, 'HISTORICAL')
        error('validate_operating_profile:IllegalException', ...
            'Approved exception is reserved for historical cases only; illegal on primary case within capacity.');
    end
end

% 2. Voltage Setpoints
if abs(profile.Gen_Vset_pu - 1.00) > 1e-4
    error('validate_operating_profile:InvalidGenVset', 'Generator terminal voltage setpoint must be 1.00 pu.');
end
if abs(profile.Grid_Vset_pu - 1.00) > 1e-4
    error('validate_operating_profile:InvalidGridVset', 'Grid voltage setpoint must be 1.00 pu.');
end

% 3. Auxiliary Load
if isfield(profile, 'Load_P_MW') && abs(profile.Load_P_MW - 14.0) > 1e-3
    error('validate_operating_profile:InvalidAuxLoad', 'Auxiliary active power load must be 14.0 MW.');
end

% 4. Finite Q limits
if isfield(profile, 'Gen_Q_MVAr_limit')
    qlim = profile.Gen_Q_MVAr_limit;
    if numel(qlim) ~= 2 || any(~isfinite(qlim)) || qlim(1) > qlim(2)
        error('validate_operating_profile:InvalidQLimits', 'Gen_Q_MVAr_limit must be finite [Qmin, Qmax].');
    end
end

ok = true;
end
