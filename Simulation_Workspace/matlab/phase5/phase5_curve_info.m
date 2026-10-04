function [k, alpha] = phase5_curve_info(family)
%PHASE5_CURVE_INFO  Centralized IEC inverse-time constants (Phase-5 Task 5).
%   [k, alpha] = PHASE5_CURVE_INFO(family) returns the STUDY constants for
%   the IEC 60255 inverse-time formulation used by PHASE5_CURVE:
%       t = TMS * k / ((M^alpha) - 1),  M = I/Is (dimensionless).
%   Families (case-insensitive):
%       'SI'  Standard Inverse:        k = 0.14, alpha = 0.02
%       'VI'  Very Inverse:            k = 13.5, alpha = 1.0
%       'EI'  Extremely Inverse:       k = 80.0, alpha = 2.0
%       'DT'  Definite Time:           k = NaN, alpha = NaN (no inverse
%             constants; use PHASE5_CURVE_DT(I, Is, tdef) instead).
%   Single source of truth: PHASE5_CURVE delegates here, never hardcodes.
%   Constants are labelled STUDY (IEC 60255 study values), never a relay
%   manufacturer/model. Unknown family errors 'phase5_curve:family'.
%   All errors are 'phase5'-prefixed.
if nargin ~= 1
    error('phase5_curve:args', 'usage: [k,alpha] = phase5_curve_info(family).');
end
if isstring(family) && isscalar(family)
    family = char(family);
end
if ~ischar(family) || isempty(family)
    error('phase5_curve:family', 'family must be ''SI'', ''VI'', ''EI'' or ''DT''.');
end
switch upper(strtrim(family))
    case 'SI'
        k = 0.14; alpha = 0.02;
    case 'VI'
        k = 13.5; alpha = 1.0;
    case 'EI'
        k = 80.0; alpha = 2.0;
    case 'DT'
        k = NaN; alpha = NaN;
    otherwise
        error('phase5_curve:family', 'unknown curve family ''%s'' (want SI/VI/EI/DT).', family);
end
end
