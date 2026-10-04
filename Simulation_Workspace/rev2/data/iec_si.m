function t = iec_si(TMS, mult)
%IEC_SI IEC Standard Inverse time: t = TMS*0.14/(mult^0.02-1).
% TMS: time multiplier; mult: I/Ipickup (>1). mult<=1 -> Inf (no operate).
if mult <= 1, t = Inf; else, t = TMS*0.14/(mult^0.02-1); end
end
