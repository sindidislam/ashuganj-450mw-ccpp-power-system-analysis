function k = phase4_kappa(r)
%PHASE4_KAPPA  Design-defined peak-factor shape for the Phase-4 fault study.
%
%   k = PHASE4_KAPPA(r) returns k = 1.02 + 0.98*exp(-3*r) with
%   r = R/X of the positive-sequence Thevenin impedance at the fault node.
%
%   The function-body shape is shared with the rev2/data/iec_kappa.m
%   pattern (relabelled); no other Rev2 code is reused here.
%
%   NOT IEC 60909 compliant: this is a design-defined peak-factor curve for
%   the Ashuganj South Phase-4 study only, not an IEC 60909 calculation.

if ~(isnumeric(r) && isscalar(r) && isfinite(r))
    error('phase4_kappa:badR', 'r must be a finite scalar R/X value.');
end
k = 1.02 + 0.98*exp(-3*r);
end
