function [Y,x]=phase6_control_step(u,x,C)
%PHASE6_CONTROL_STEP Measured voltage/speed control; u=[w Vt unitTrip].
if isempty(x),x=[C.pm0 C.pm0 C.vf0];end
assert(numel(u)==3&&all(isfinite(u)));
if u(3)>0.5
    valve=0; field=0;
else
    valve=min(C.powerMax_pu,max(C.powerMin_pu,C.pm0+(1-u(1))/C.droop));
    field=min(C.fieldMax_pu,max(C.fieldMin_pu,C.vf0+C.avrGain*(C.vref-u(2))));
end
x(1)=x(1)+(valve-x(1))*(-expm1(-C.Ts/C.governorTime_s));
x(2)=x(2)+(x(1)-x(2))*(-expm1(-C.Ts/C.turbineTime_s));
x(3)=x(3)+(field-x(3))*(-expm1(-C.Ts/C.avrTime_s));
Y=[x(2) x(3)];
end
