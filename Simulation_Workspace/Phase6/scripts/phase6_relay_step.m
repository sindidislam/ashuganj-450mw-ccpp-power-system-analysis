function [Y,state] = phase6_relay_step(M,state,dt,R,enabled)
%PHASE6_RELAY_STEP Measured-current protection; no scenario/fault flag input.
% Complex RMS phasors use the directions in docs/RELAY_TASK_REPORT.md.
% Relay order: GEN51 GSUT51 GEN51N 87G 87T 87B 87L.
% Breaker order: GCB Q0 LineLocal LineRemote GAT. DC gating is downstream.
% Empty state resets; disabling does not erase an already latched trip.
assert(isnumeric(dt) && isscalar(dt) && isfinite(dt) && isreal(dt) && dt > 0, ...
    'phase6:timeStep','dt must be a positive finite interval in seconds.');
if isscalar(enabled), enabled = repmat(logical(enabled),1,7); end
assert(isequal(size(enabled),[1 7]),'phase6:enableShape', ...
    'enabled must be scalar or a seven-element row.');
enabled = logical(enabled);
names = {'IgenInner','IgenTerminal','IgsutLV','IgsutHV','IbusIn', ...
    'IbusOut','IgatHV','IlineLocal','IlineRemote'};
for k = 1:numel(names)
    I = M.(names{k});
    assert(isnumeric(I) && isequal(size(I),[1 3]) && all(isfinite(I)), ...
        'phase6:phasor','%s must contain three finite RMS current phasors.',names{k});
end
assert(isnumeric(M.Ineutral_A) && isscalar(M.Ineutral_A) ...
    && isreal(M.Ineutral_A) && isfinite(M.Ineutral_A) && M.Ineutral_A >= 0, ...
    'phase6:neutralRMS','Ineutral_A must be a nonnegative physical RMS current.');
if isempty(state)
    state = struct('trip',false(1,7),'timer_s',zeros(1,7), ...
        'inverseDuty',zeros(1,3),'differentialTimer_s',zeros(4,3));
end

primary = [max(abs(M.IgenTerminal)),max(abs(M.IgsutHV)),M.Ineutral_A];
Y.currentSecondary_A = primary./R.ctRatio(1:3);
Y.pickup = false(1,7);
assert(isfield(R,'communicationDelay_s') && isscalar(R.communicationDelay_s) ...
    && isfinite(R.communicationDelay_s) && R.communicationDelay_s>0, ...
    'Phase6:RebuildRequired','Rebuild v4 to load the finite line communications allowance.');
effectiveDelay=R.delay_s;
effectiveDelay(4)=effectiveDelay(4)+R.communicationDelay_s;
Y.operatingTime_s = [inf(1,3) effectiveDelay];
for k = 1:3
    multiple = primary(k)/R.pickup_A(k);
    if multiple > 1
        Y.operatingTime_s(k) = R.iecK*R.tms(k)/(multiple^R.iecAlpha-1);
        Y.pickup(k) = enabled(k);
    end
    if ~state.trip(k)
        if Y.pickup(k)
            state.inverseDuty(k) = state.inverseDuty(k)+dt/Y.operatingTime_s(k);
            state.timer_s(k) = state.timer_s(k)+dt;
            state.trip(k) = state.inverseDuty(k) >= 1-16*eps;
        else
            state.inverseDuty(k) = 0;
            state.timer_s(k) = 0;
        end
    end
end

% YNd1: unlike a fixed angle rotation this delta matrix also compensates
% negative sequence correctly. HV zero sequence has no LV line counterpart.
lv = M.IgsutLV;
lvHV = R.lvToHv*[lv(1)-lv(2),lv(2)-lv(3),lv(3)-lv(1)]/sqrt(3);
hvWithoutZero = M.IgsutHV-mean(M.IgsutHV);
spill = [M.IgenInner-M.IgenTerminal; lvHV-hvWithoutZero; ...
    M.IbusIn-M.IbusOut-M.IgatHV; M.IlineLocal-M.IlineRemote];
restraint = R.restraintFactor*[abs(M.IgenInner)+abs(M.IgenTerminal); ...
    abs(lvHV)+abs(hvWithoutZero); ...
    abs(M.IbusIn)+abs(M.IbusOut)+abs(M.IgatHV); ...
    abs(M.IlineLocal)+abs(M.IlineRemote)];
differential = abs(spill);
Y.differential_A = zeros(1,4);
Y.restraint_A = zeros(1,4);
Y.threshold_A = zeros(1,4);
for k = 1:4
    relay = k+3;
    threshold = max(R.pickup_A(relay), ...
        R.slope1(k)*min(restraint(k,:),R.knee_A(k)) + ...
        R.slope2(k)*max(restraint(k,:)-R.knee_A(k),0));
    margin = differential(k,:)-threshold;
    phasePickup = margin > 0 & enabled(relay);
    Y.pickup(relay) = any(phasePickup);
    % Report a single coherent operating point; never combine the maximum
    % differential of one phase with the restraint of a different phase.
    [~,phase] = max(margin);
    Y.differential_A(k) = differential(k,phase);
    Y.restraint_A(k) = restraint(k,phase);
    Y.threshold_A(k) = threshold(phase);
    if ~state.trip(relay)
        state.differentialTimer_s(k,~phasePickup) = 0;
        state.differentialTimer_s(k,phasePickup) = ...
            state.differentialTimer_s(k,phasePickup)+dt;
        state.timer_s(relay) = max(state.differentialTimer_s(k,:));
        state.trip(relay) = any(state.differentialTimer_s(k,:) ...
            >= effectiveDelay(k)-16*eps(effectiveDelay(k)));
    end
end
Y.trip = state.trip;
Y.timer_s = state.timer_s;
activeTrip = state.trip & enabled;
Y.unitTrip = any(activeTrip(1:5));
Y.breakerRequest = logical([Y.unitTrip, Y.unitTrip || activeTrip(6), ...
    activeTrip(6) || activeTrip(7), activeTrip(7), activeTrip(6)]);
end
