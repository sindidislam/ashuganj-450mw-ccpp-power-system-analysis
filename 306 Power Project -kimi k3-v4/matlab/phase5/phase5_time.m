function t = phase5_time(I_A, Is_A, TMS, family)
%PHASE5_TIME  Operating-time calculator (Phase-5 Task 7).
%   t = PHASE5_TIME(I_A, Is_A, TMS, family) returns scalar operating time in
%   seconds for measured current I_A (A) against pickup Is_A (A, same side,
%   usually secondary), time multiplier TMS (dimensionless scalar), and curve
%   family 'SI'/'VI'/'EI' (case-insensitive) or 'DT' definite-time.
%
%   Inverse path: I_A <= Is_A -> Inf (no trip); else M = I_A/Is_A and
%       t = TMS*k/((M^alpha)-1) via PHASE5_CURVE (constants from
%       PHASE5_CURVE_INFO, STUDY values per IEC 60255, never manufacturer).
%
%   DT path: branches to PHASE5_CURVE_DT(I_A, Is_A, TMS) with TMS read as
%       the definite delay tdef in seconds (scalar, >= 0): I_A >= Is_A ->
%       tdef, else Inf. Never calls PHASE5_CURVE with 'DT' (it errors loudly
%       by design). At exact equality DT trips (definite-time semantics);
%       the 'Inf if I<=Is' rule applies to the inverse path.
%
%   Scalar-only: I_A, Is_A, TMS must each be real finite scalars (I_A >= 0,
%       Is_A > 0; TMS > 0 inverse, >= 0 DT). No vector entry point is
%       provided: for arrays use PHASE5_CURVE(M, family, TMS) element-wise
%       or loop this function (deliberate; no untested vector API invented,
%       so no phase5_time_matrix function exists).
%
%   Instantaneous: default no-Iinst path — this function has no Iinst
%       override and never returns an instantaneous time; any future Iinst
%       high-set belongs to a justified device-level definite element, not
%       to this calculator.
%
%   F3 LLL anchor (secondary): I=3.3687257 A vs GEN-51 pickup secondary
%       1.0015833 A, TMS=0.1 SI -> finite t ~= 0.57 s (< 10 s).
%
%   All errors are 'phase5'-prefixed (unknown families surface as
%   'phase5_curve:family' from the delegated curve call).
if nargin ~= 4
    error('phase5_time:args', 'usage: t = phase5_time(I_A, Is_A, TMS, family).');
end
if ~isnumeric(I_A) || ~isscalar(I_A) || ~isreal(I_A) || ~isfinite(I_A) || I_A < 0
    error('phase5_time:args', 'I_A must be a real finite scalar >= 0 in A.');
end
if ~isnumeric(Is_A) || ~isscalar(Is_A) || ~isreal(Is_A) || ~isfinite(Is_A) || Is_A <= 0
    error('phase5_time:args', 'Is_A must be a real finite scalar > 0 in A.');
end
if isstring(family) && isscalar(family)
    family = char(family);
end
if ~ischar(family) || isempty(family)
    error('phase5_time:family', 'family must be ''SI'', ''VI'', ''EI'' or ''DT''.');
end
fam = upper(strtrim(family));
if strcmp(fam, 'DT')
    if ~isnumeric(TMS) || ~isscalar(TMS) || ~isreal(TMS) || ~isfinite(TMS) || TMS < 0
        error('phase5_time:args', 'TMS (tdef for DT) must be a real finite scalar >= 0 in seconds.');
    end
    t = phase5_curve_dt(I_A, Is_A, TMS);
    return;
end
if ~isnumeric(TMS) || ~isscalar(TMS) || ~isreal(TMS) || ~isfinite(TMS) || TMS <= 0
    error('phase5_time:args', 'TMS must be a real finite scalar > 0 (dimensionless).');
end
if I_A <= Is_A
    t = Inf;
    return;
end
M = I_A / Is_A;
t = phase5_curve(M, fam, TMS);
end
