function test_phase6_dc()
%TEST_PHASE6_DC Physical current/energy tests for the station DC equivalent.
addpath(fileparts(fileparts(mfilename('fullpath'))));
assert(exist('phase6_dc_step','file') == 2,'phase6:dcMissing', ...
    'Station DC current-balance engine must exist.');
D = phase6_dc_parameters(); dt = .001;
U = struct('auxVoltage_pu',1,'batteryAvailable',true, ...
    'chargerAvailable',true,'tripDemand',false);
[Y,state] = phase6_dc_step(U,[],dt,D);
assert(Y.dcHealthy && ~Y.lowVoltage && ~Y.chargerFailure);
assert(abs(Y.Vdc_V-123.75)<1e-9 && abs(Y.Ibattery_A)<1e-9);
assert(abs(Y.Icharger_A-2400/123.75)<1e-9 && Y.SOC==1);
balance(Y,2400);

% Real loaded-voltage root, independently derived from V=116-.05*2400/V.
U.chargerAvailable = false;
[Y,~] = phase6_dc_step(U,[],dt,D);
expectedV = (116+sqrt(116^2-4*.05*2400))/2;
assert(abs(Y.Vdc_V-expectedV)<1e-9 && Y.Ibattery_A>0 && Y.Icharger_A==0);
assert(abs(Y.SOC-(1-Y.Ibattery_A*dt/(3600*200)))<1e-12);
assert(Y.dcHealthy && Y.chargerFailure && ~Y.tripUnavailable);
balance(Y,2400);
U.tripDemand = true;
[Y,state] = phase6_dc_step(U,[],dt,D);
assert(Y.dcHealthy && Y.tripCoilPower_W==2000 && Y.Vdc_V<expectedV);
assert(Y.Ibattery_A>2400/expectedV && Y.Icharger_A==0);
balance(Y,4400);
energy = Y.tripCoilPower_W*dt;
for k=2:500
    [Y,state] = phase6_dc_step(U,state,dt,D);
    energy = energy+Y.tripCoilPower_W*dt;
end
assert(abs(energy-400)<1e-7,'A held trip request must deliver one 400 J pulse.');
assert(Y.tripCoilPower_W==0);
U.tripDemand=false; [~,state]=phase6_dc_step(U,state,dt,D);
U.tripDemand=true; [Y,~]=phase6_dc_step(U,state,dt,D);
assert(Y.tripCoilPower_W==2000,'A new rising edge must re-arm the pulse.');
[Y,state]=phase6_dc_step(U,[],.3,D);
assert(abs(Y.tripCoilPower_W*.3-400)<1e-9,'Coarse steps must preserve finite pulse energy.');
[Y,~]=phase6_dc_step(U,state,.3,D);
assert(Y.tripCoilPower_W==0);

% Hardware availability alone must not invent AC input power.
U.tripDemand=false; U.chargerAvailable=true; U.auxVoltage_pu=.79;
[Y,~]=phase6_dc_step(U,[],dt,D);
assert(Y.Icharger_A==0 && Y.chargerACPower_W==0 && Y.Ibattery_A>0);
assert(Y.chargerFailure && Y.dcHealthy);
U.batteryAvailable=false;
[Y,state]=phase6_dc_step(U,[],dt,D);
assert(Y.Vdc_V==0 && Y.Iload_A==0 && Y.Ibattery_A==0 && Y.Icharger_A==0);
assert(~Y.dcHealthy && Y.lowVoltage && Y.tripUnavailable && abs(Y.unservedPower_W-2400)<1e-9);
U.tripDemand=true; [Y,state]=phase6_dc_step(U,state,dt,D);
assert(Y.tripCoilPower_W==0 && abs(Y.unservedPower_W-4400)<1e-9);
U.auxVoltage_pu=1;
for k=1:1000, [Y,state]=phase6_dc_step(U,state,dt,D); end
assert(Y.dcHealthy && Y.Vdc_V==123.75 && Y.Ibattery_A==0);
balance(Y,2400);
assert(abs(Y.chargerACPower_W-2400/.925)<1e-7);

% Standby is replacement capacity; all simultaneous loads stay single-rated.
U = struct('auxVoltage_pu',1,'batteryAvailable',false, ...
    'chargerAvailable',true,'tripDemand',true,'closeDemand',true,'emergencyLoad',true);
[Y,state]=phase6_dc_step(U,[],dt,D);
for k=1:150
    [Y,state]=phase6_dc_step(U,state,dt,D);
    assert(Y.Icharger_A<=180+1e-9 && Y.Icharger_A*Y.Vdc_V<=20000+1e-7);
    balance(Y,12400);
end
assert(Y.dcHealthy,'One charger must supply the canonical simultaneous demand.');

% Loaded-voltage cutoff is independent of the SOC reserve threshold.
Dc=D; Dc.dc_soc_initial=.3;
U.batteryAvailable=true; U.chargerAvailable=false;
[Y,~]=phase6_dc_step(U,[],dt,Dc);
assert(Y.SOC==.3 && ~Y.batteryLow && Y.lowVoltage && ~Y.dcHealthy);
assert(Y.Vdc_V==0 && Y.Ibattery_A==0 && abs(Y.unservedPower_W-12400)<1e-8);

% Discharge reserve must stop delivery; charger restoration must recharge it.
Dr = D; Dr.dc_soc_initial=.2;
U = struct('auxVoltage_pu',1,'batteryAvailable',true, ...
    'chargerAvailable',false,'tripDemand',false);
[Y,state]=phase6_dc_step(U,[],dt,Dr);
assert(Y.SOC==.2 && Y.Vdc_V==0 && Y.batteryLow && ~Y.dcHealthy);
U.chargerAvailable=true;
for k=1:2000
    [Y,state]=phase6_dc_step(U,state,dt,Dr);
    assert(Y.SOC>=.2 && Y.SOC<=1 && Y.Ibattery_A>=-40-1e-9);
    balance(Y,2400);
end
assert(Y.SOC>.2 && Y.Ibattery_A<0 && Y.dcHealthy,'Reserve state must be rechargeable.');

% Recharge follows coulombic efficiency and can approach full without chatter.
Dr.dc_soc_initial=.6;
[~,state]=phase6_dc_step(U,[],dt,Dr);
socBefore=state.SOC;
chargedAh=0;
for k=1:3000
    [Y,state]=phase6_dc_step(U,state,dt,Dr);
    chargedAh=chargedAh+(max(-Y.Ibattery_A,0)*.9-max(Y.Ibattery_A,0))*dt/3600;
    balance(Y,2400);
end
assert(Y.SOC>socBefore && abs(Y.SOC-socBefore-chargedAh/200)<1e-10);
assert(abs(Y.Ibattery_A+40)<.01,'Stable charge limit should settle at 40 A.');
Dr.dc_soc_initial=1-1e-8;
[~,state]=phase6_dc_step(U,[],dt,Dr);
for k=1:1000, [Y,state]=phase6_dc_step(U,state,dt,Dr); end
assert(Y.SOC<=1 && Y.SOC>1-1e-7 && abs(Y.Ibattery_A)<1e-8);
assert(abs(Y.Vdc_V-123.75)<1e-8);

% A step ending at reserve cannot spend charge that does not exist.
Dr.dc_soc_initial=.20000001; U.chargerAvailable=false;
[Y,~]=phase6_dc_step(U,[],1,Dr);
assert(Y.SOC>=.2 && Y.unservedPower_W>0 && Y.Ibattery_A<=.0072+1e-9);
balance(Y,2400);

% Supplied canonical records control physical capacity, with no string rounding.
P.assumptions=engineering_assumptions();
P.assumptions.dc_capacity_Ah.value=100;
P.assumptions.dc_capacity_Ah.selected_value=100;
D2=phase6_dc_parameters(P);
U.chargerAvailable=false;
[Y,~]=phase6_dc_step(U,[],dt,D2);
assert(abs(Y.SOC-(1-Y.Ibattery_A*dt/(3600*100)))<1e-12);
fprintf('PHASE6_DC_TESTS_PASS: current balance, battery/charger, pulse, AC failure, SOC, recovery.\n');
end

function balance(Y,demand)
assert(abs(Y.Icharger_A+Y.Ibattery_A-Y.Iload_A)<1e-8,'DC Kirchhoff current balance failed.');
assert(abs(Y.Vdc_V*Y.Iload_A+Y.unservedPower_W-demand)<1e-6,'DC load power balance failed.');
assert(Y.unservedPower_W>=-1e-8 && Y.Iload_A>=0);
end
