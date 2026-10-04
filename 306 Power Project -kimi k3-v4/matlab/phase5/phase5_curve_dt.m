function t = phase5_curve_dt(I, Is, tdef)
%PHASE5_CURVE_DT  Definite-time operating time (Phase-5 Task 5).
%   t = PHASE5_CURVE_DT(I, Is, tdef) with I measured current (A), Is pickup
%   threshold (A, scalar, > 0, same side as I), tdef definite delay (s,
%   scalar, >= 0). Units: I, Is in A (same side, usually secondary); t in
%   seconds. Element-wise over array I:
%       I >= Is -> tdef;  I < Is -> Inf (no trip).
%   Called out by PHASE5_CURVE for family 'DT' (inverse form has no DT
%   constants). All errors are 'phase5'-prefixed.
if nargin ~= 3
    error('phase5_curve:args', 'usage: t = phase5_curve_dt(I, Is, tdef).');
end
if ~isnumeric(I) || ~isreal(I) || isempty(I) || any(isnan(I(:))) || any(I(:) < 0)
    error('phase5_curve:args', 'I must be real numeric >= 0 in A (no NaN/negative).');
end
if ~isnumeric(Is) || ~isscalar(Is) || ~isreal(Is) || ~isfinite(Is) || Is <= 0
    error('phase5_curve:args', 'Is must be a real finite scalar > 0 in A.');
end
if ~isnumeric(tdef) || ~isscalar(tdef) || ~isreal(tdef) || ~isfinite(tdef) || tdef < 0
    error('phase5_curve:args', 'tdef must be a real finite scalar >= 0 in seconds.');
end
t = Inf(size(I));
t(I >= Is) = tdef;
end
