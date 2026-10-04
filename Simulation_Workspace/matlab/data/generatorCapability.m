function [Qmin_MVAr,Qmax_MVAr] = generatorCapability(P_MW,curve)
%GENERATORCAPABILITY Piecewise-linear physical capability, lower then upper.
% [Qmin_MVAr,Qmax_MVAr] = generatorCapability(P_MW [,curve])
% P_MW is a nonempty real finite numeric array in [0,458] MW. Output arrays
% retain its shape. No extrapolation, clipping or dispatch authorization.
% Optional scalar curve has numeric vector fields P_MW, Qmin_MVAr,
% Qmax_MVAr, equal lengths >=2, strictly increasing P from 0 to 458,
% finite real entries and ordered Q bounds. It supports provider construction
% without recursion. Omitted curve comes from ashuganj_generators().
if ~isnumeric(P_MW) || isempty(P_MW) || ~isreal(P_MW) || ...
        any(~isfinite(P_MW(:))) || any(P_MW(:)<0 | P_MW(:)>458)
    error('generatorCapability:InvalidP','P must be real finite numeric MW in [0,458].');
end
if nargin < 2
    G = ashuganj_generators();
    curve = G.capabilityCurve;
end
fields = {'P_MW','Qmin_MVAr','Qmax_MVAr'};
if ~isstruct(curve) || ~isscalar(curve) || ~all(isfield(curve,fields))
    error('generatorCapability:InvalidCurve','Curve must contain P and both Q bounds.');
end
for k=1:numel(fields)
    v = curve.(fields{k});
    if ~isnumeric(v) || ~isvector(v) || ~isreal(v) || numel(v)<2 || any(~isfinite(v(:)))
        error('generatorCapability:InvalidCurve','Curve fields must be real finite numeric vectors.');
    end
end
p = double(curve.P_MW(:)); lo = double(curve.Qmin_MVAr(:)); hi = double(curve.Qmax_MVAr(:));
if numel(p)~=numel(lo) || numel(p)~=numel(hi) || ...
        any(diff(p)<=0) || p(1)~=0 || p(end)~=458 || any(lo>hi)
    error('generatorCapability:InvalidCurve','Curve lengths, domain or bound ordering are invalid.');
end
Qmin_MVAr = reshape(interp1(p,lo,double(P_MW(:)),'linear'),size(P_MW));
Qmax_MVAr = reshape(interp1(p,hi,double(P_MW(:)),'linear'),size(P_MW));
end
