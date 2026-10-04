function t = phase5_curve(M, family, TMS)
%PHASE5_CURVE  Centralized IEC inverse-time operating time (Phase-5 Task 5).
%   t = PHASE5_CURVE(M, family, TMS) with M = I/Is (dimensionless current
%   multiple), family 'SI'/'VI'/'EI' (case-insensitive), TMS dimensionless
%   time multiplier (scalar, > 0). Units: I, Is in A (same side, usually
%   secondary); TMS dimensionless; t in seconds.
%       t = TMS * k / ((M^alpha) - 1),  M <= 1 -> Inf (no trip).
%   Constants (k, alpha) come from PHASE5_CURVE_INFO (single source; STUDY
%   values per IEC 60255, never manufacturer). Element-wise over array M.
%   Family 'DT' is definite-time and needs (I, Is, tdef): this errors with
%   'phase5_curve:family' directing to PHASE5_CURVE_DT. Unknown family
%   errors 'phase5_curve:family'. All errors are 'phase5'-prefixed.
if nargin ~= 3
    error('phase5_curve:args', 'usage: t = phase5_curve(M, family, TMS).');
end
if ~isnumeric(M) || ~isreal(M) || isempty(M) || any(isnan(M(:))) || any(M(:) < 0)
    error('phase5_curve:args', 'M = I/Is must be real numeric >= 0 (no NaN/negative).');
end
if isstring(family) && isscalar(family)
    family = char(family);
end
if ~ischar(family) || isempty(family)
    error('phase5_curve:family', 'family must be ''SI'', ''VI'', ''EI'' or ''DT''.');
end
if ~isnumeric(TMS) || ~isscalar(TMS) || ~isreal(TMS) || ~isfinite(TMS) || TMS <= 0
    error('phase5_curve:args', 'TMS must be a real finite scalar > 0 (dimensionless).');
end
fam = upper(strtrim(family));
if strcmp(fam, 'DT')
    error('phase5_curve:family', 'DT is definite-time: use phase5_curve_dt(I, Is, tdef).');
end
[k, alpha] = phase5_curve_info(fam);
t = TMS * k ./ ((M .^ alpha) - 1);
t(M <= 1) = Inf;
end
