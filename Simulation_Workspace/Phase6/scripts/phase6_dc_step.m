function [Y,state] = phase6_dc_step(U,state,dt,D)
%PHASE6_DC_STEP Station DC Thevenin battery, bounded charger and actual loads.
% Positive battery current discharges; raw trip/close edges start timed loads.
% Coil demand is solved before DC availability; a pending trip waits for power.
% The input is one aggregate request: later individual trips while it remains
% high do not retrigger this pulse. Manual breaker commands bypass this input.
assert(isnumeric(dt) && isscalar(dt) && isreal(dt) && isfinite(dt) && dt>0, ...
    'phase6:dcTimeStep','DC time step must be positive finite seconds.');
assert(isnumeric(U.auxVoltage_pu) && isscalar(U.auxVoltage_pu) ...
    && isreal(U.auxVoltage_pu) && isfinite(U.auxVoltage_pu) && U.auxVoltage_pu>=0, ...
    'phase6:dcACVoltage','AC voltage must be a nonnegative measured magnitude.');
battery=logical(U.batteryAvailable);
charger=logical(U.chargerAvailable) && U.auxVoltage_pu>=D.acPickup_pu;
trip=logical(U.tripDemand);
close=false; emergency=false;
if isfield(U,'closeDemand'), close=logical(U.closeDemand); end
if isfield(U,'emergencyLoad'), emergency=logical(U.emergencyLoad); end
assert(isscalar(battery) && isscalar(trip) && isscalar(close) && isscalar(emergency), ...
    'phase6:dcInputShape','DC availability and demand inputs must be scalar.');
floatV=D.charger_float_voltage_V;
% Conservative power ceiling at maximum possible bus voltage guarantees both
% current and power bounds throughout startup, sag and charge transitions.
chargerLimit=min(D.charger_max_current_A,1000*D.charger_rated_power_kW/floatV);
if isempty(state)
    state=struct('SOC',D.dc_soc_initial,'chargerCurrentCommand_A',0,'Vdc_V',0, ...
        'previousTrip',false,'previousClose',false,'tripRemaining_s',0,'closeRemaining_s',0);
    if charger
        state.chargerCurrentCommand_A=min(chargerLimit,D.continuousLoad_W/floatV);
        state.Vdc_V=floatV;
    end
end
assert(isfinite(state.SOC) && state.SOC>=D.dc_soc_min && state.SOC<=D.dc_soc_max, ...
    'phase6:dcSOC','SOC must be inside its usable canonical interval.');
if trip && ~state.previousTrip, state.tripRemaining_s=D.load_trip_duration_s; end
if close && ~state.previousClose, state.closeRemaining_s=D.load_close_duration_s; end
tripPower=1000*D.load_trip_kW*min(dt,state.tripRemaining_s)/dt;
closePower=1000*D.load_close_kW*min(dt,state.closeRemaining_s)/dt;
state.closeRemaining_s=max(0,state.closeRemaining_s-dt);
state.previousTrip=trip; state.previousClose=close;
requested=D.continuousLoad_W+tripPower+closePower ...
    +1000*D.load_emergency_additional_kW*double(emergency);
E=D.dc_ocv_V(1)+diff(D.dc_ocv_V)*state.SOC;
capacityC=3600*D.dc_capacity_Ah;
dischargeLimit=0; chargeLimit=0;
if battery
    dischargeLimit=min(D.dc_max_discharge_A,max(0,state.SOC-D.dc_soc_min)*capacityC/dt);
    chargeLimit=min(D.dc_max_charge_A,max(0,D.dc_soc_max-state.SOC)*capacityC ...
        /(D.dc_charge_efficiency*dt));
end

if charger
    if ~battery || chargeLimit==0
        % Canonical full-SOC policy: load-only support without forced charge.
        % Load feed-forward is required for the isolated charger at float.
        target=requested/floatV+D.charger_voltage_gain_A_per_V*max(0,floatV-state.Vdc_V);
    else
        % Charge path cannot remain falsely at float after a reserve cutoff.
        % Its conducting-voltage ceiling follows the bank plus charge limiter.
        sensed=min(state.Vdc_V,E+D.dc_internal_resistance_ohm*chargeLimit);
        target=D.charger_voltage_gain_A_per_V*max(0,floatV-sensed);
        chargeVoltage=min(floatV,E+D.dc_internal_resistance_ohm*chargeLimit);
        target=min(target,requested/chargeVoltage+chargeLimit);
    end
    target=min(chargerLimit,max(D.charger_min_current_A,target));
    available=state.chargerCurrentCommand_A ...
        +(target-state.chargerCurrentCommand_A)*(-expm1(-dt/D.charger_response_s));
else
    % AC/hardware loss removes the source immediately; no fictitious stored
    % charger energy is permitted by its control-lag state.
    available=0;
end
[V,Ib,Ic,served]=solve_bus(E,available,requested,dischargeLimit,chargeLimit,battery,D);
% Retain the bounded command while charging is possible. At SOC reserve,
% load-only float current is lower than the current needed at battery OCV;
% overwriting the command with delivered load current would prevent recovery.
if battery && chargeLimit>0
    state.chargerCurrentCommand_A=available;
else
    state.chargerCurrentCommand_A=Ic;
end
state.Vdc_V=V;
if Ib>=0, deltaSOC=-Ib*dt/capacityC;
else, deltaSOC=-D.dc_charge_efficiency*Ib*dt/capacityC; end
state.SOC=min(D.dc_soc_max,max(D.dc_soc_min,state.SOC+deltaSOC));
Y.Vdc_V=V;
Y.Ibattery_A=Ib;
Y.Icharger_A=Ic;
Y.Iload_A=Ib+Ic;
Y.SOC=state.SOC;
Y.unservedPower_W=max(0,requested-served);
Y.lowVoltage=V<D.dc_cutoff_voltage_V;
Y.batteryLow=~battery || state.SOC<=D.dc_soc_min;
Y.chargerFailure=~charger;
Y.dcHealthy=~Y.lowVoltage && Y.unservedPower_W<=D.serviceTolerance_W;
% Do not spend the useful trip interval during loss or incomplete DC service.
% Brownout coil energy is still reported below, but cannot complete a trip.
if Y.dcHealthy, state.tripRemaining_s=max(0,state.tripRemaining_s-dt); end
Y.tripUnavailable=~Y.dcHealthy;
Y.chargerACPower_W=V*Ic/D.charger_efficiency;
Y.tripCoilPower_W=tripPower*min(1,served/requested);
end

function [V,Ib,Ic,served] = solve_bus(E,available,P,dischargeLimit,chargeLimit,battery,D)
% For unconstrained battery conduction, choose the stable high-voltage root:
% V^2-(E+R*Ic)*V+R*P=0. Check direction-specific limits before accepting it.
R=D.dc_internal_resistance_ohm;
if chargeLimit==0 && available>=P/D.charger_float_voltage_V
    % At full SOC the charge-blocked bank must not drag a supported float bus
    % to OCV. It reconnects for discharge only when the charger is insufficient.
    V=D.charger_float_voltage_V; Ib=0; Ic=P/V; served=P; return
end
if battery && (dischargeLimit>0 || chargeLimit>0)
    discriminant=(E+R*available)^2-4*R*P;
    if discriminant>=0
        trialV=(E+R*available+sqrt(discriminant))/2;
        trialIb=P/trialV-available;
        if trialIb>=0 && trialIb<=dischargeLimit && trialV>D.dc_cutoff_voltage_V
            V=trialV; Ib=trialIb; Ic=available; served=P; return
        elseif trialIb<0 && chargeLimit>0
            Ib=max(-chargeLimit,trialIb); V=E-R*Ib;
            Ic=P/V-Ib; served=P; return
        elseif trialIb>dischargeLimit && dischargeLimit>0
            V=E-R*dischargeLimit;
            if V>D.dc_cutoff_voltage_V
                Ib=dischargeLimit; Ic=min(available,max(0,P/V-Ib));
                served=min(P,V*(Ib+Ic)); return
            end
        end
    end
end
% Battery cannot serve this operating point. The charger regulates at float
% when able; below that point, the load becomes a rated-voltage resistance.
% This is a declared brownout equivalent, avoiding a nonphysical nonzero bus
% voltage with zero supply and avoiding the constant-power startup singularity.
Ib=0;
nominalLoadCurrent=P/D.charger_float_voltage_V;
Ic=min(available,nominalLoadCurrent);
V=D.charger_float_voltage_V*min(1,Ic/nominalLoadCurrent);
served=V*Ic;
end
