function [Y,x]=phase6_breaker_step(request,healthy,t,x,C,S)
%PHASE6_BREAKER_STEP Trip-coil availability, mechanism delay and open latch.
% request=[GCB Q0 lineLocal lineRemote GAT unit]; Y=[closed(1:5) unitTrip].
% Interface limit: healthy represents bus service, not individual coil power.
% Manual commands and later separate trips need per-coil demand wiring for
% full energy gating; the aggregate DC pulse covers the pending initial trip.
if isempty(x),x=[zeros(1,5) 1 1 1 1 double(S.GAT_in) 0];end
assert(isequal(size(request),[1 6]));
manual=S.manualOpen & t>=S.manualOpenTime_s;
demand=(logical(request(1:5))|manual)&logical(healthy);
x(1:5)=double(demand).*(x(1:5)+C.Ts);
open=demand & x(1:5)>=C.breakerDelay_s-16*eps & ~S.breakerFailed;
x(6:10)=x(6:10).*double(~open);
if healthy && (request(6)>0.5 || t>=S.generatorTripTime_s),x(11)=1;end
Y=x(6:11);
end
