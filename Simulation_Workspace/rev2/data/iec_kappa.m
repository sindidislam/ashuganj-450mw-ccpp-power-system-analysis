function kap = iec_kappa(XR)
%IEC_KAPPA Peak factor per IEC 60909: k = 1.02 + 0.98*exp(-3/(X/R)).
% XR: X/R ratio at fault point (positive-seq). XR<=0 -> k=1.02 (resistive limit, C-method note).
if XR <= 0, kap = 1.02; else, kap = 1.02 + 0.98*exp(-3/XR); end
end
