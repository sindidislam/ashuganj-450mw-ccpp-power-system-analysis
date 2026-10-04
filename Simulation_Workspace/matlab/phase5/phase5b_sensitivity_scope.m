function tf = phase5b_sensitivity_scope(varargin)
%PHASE5B_SENSITIVITY_SCOPE  Plan-name alias for PHASE5B_CT_SCOPE (Phase-5b Task C2).
%   TF = PHASE5B_SENSITIVITY_SCOPE(DEVICE_ID) forwards to phase5b_ct_scope
%   (generator-CT-only true). Kept so the plan checkbox name and the locked
%   helper name resolve identically.
%   All errors 'phase5b'-prefixed.
if nargin ~= 1
    error('phase5b_sensitivity_scope:args', 'usage: tf = phase5b_sensitivity_scope(device_id).');
end
tf = phase5b_ct_scope(varargin{1});
end
