function canonical = phase5b_id_aliases(varargin)
%PHASE5B_ID_ALIASES  Canonical study-ID resolution (Phase-5b Task C7).
%   CANONICAL = PHASE5B_ID_ALIASES(ID) maps study alias spellings to the
%   canonical registry IDs (binding carry-over 2):
%     'GEN-51-SI'        -> 'GEN-51'   (STUDY phase OC, canonical v1 ID)
%     'GEN-51N-SI-STUDY' -> 'GEN-51N'  (STUDY earth-fault, canonical v1 ID)
%   Canonical IDs, the PHYSICAL baseline 'GEN-51-SIEMENS-BL', and every
%   other registry device_id resolve to themselves (idempotent). The map is
%   also recorded as a comment block inside phase5b_registry.m (same table).
%   Pickup equality both directions is asserted in test_phase5b_zones
%   (alias pickup == canonical pickup for GEN and EF).
%   All errors 'phase5b'-prefixed.
if nargin ~= 1
    error('phase5b_id_aliases:args', 'usage: canonical = phase5b_id_aliases(device_id).');
end
idraw = varargin{1};
if isstring(idraw) && isscalar(idraw)
    idraw = char(idraw);
end
if ~ischar(idraw) || isempty(strtrim(idraw))
    error('phase5b_id_aliases:device', 'device_id must be non-empty char.');
end
id = strtrim(idraw);
if strcmp(id, 'GEN-51-SI')
    canonical = 'GEN-51';
elseif strcmp(id, 'GEN-51N-SI-STUDY')
    canonical = 'GEN-51N';
else
    canonical = id;
end
end
