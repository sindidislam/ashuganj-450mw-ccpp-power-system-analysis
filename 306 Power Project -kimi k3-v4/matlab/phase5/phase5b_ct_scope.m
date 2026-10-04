function tf = phase5b_ct_scope(varargin)
%PHASE5B_CT_SCOPE  Legacy-16000/1 sensitivity scope helper (Phase-5b Task C2).
%   TF = PHASE5B_CT_SCOPE(DEVICE_ID) returns true only for generator-CT
%   devices (spec S4: legacy 16000/1 sensitivity narrowed to the generator
%   CT conflict only, never substituted into non-generator devices).
%   Forward-compatible IDs (C3/C4 SI variants + Siemens baseline) are
%   included so the scope survives the C3/C4 row split.
%   All errors 'phase5b'-prefixed.
if nargin ~= 1
    error('phase5b_ct_scope:args', 'usage: tf = phase5b_ct_scope(device_id).');
end
idraw = varargin{1};
if isstring(idraw) && isscalar(idraw)
    idraw = char(idraw);
end
if ~ischar(idraw) || isempty(strtrim(idraw))
    error('phase5b_ct_scope:device', 'device_id must be non-empty char.');
end
id = strtrim(idraw);
gen_ids = {'GEN-51', 'GEN-51-SI', 'GEN-51-SIEMENS-BL'};
tf = any(strcmp(id, gen_ids));
end
