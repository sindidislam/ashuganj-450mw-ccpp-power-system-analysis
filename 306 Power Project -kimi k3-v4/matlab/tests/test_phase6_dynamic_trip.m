function [np,nf,evidence] = test_phase6_dynamic_trip()
%TEST_PHASE6_DYNAMIC_TRIP Measured protection and breaker integration checks.
% Requires MATLAB, Simulink and Specialized Power Systems. No synthetic
% waveform, optional simulation fallback or copied placeholder can pass.
% Generated evidence stays in Phase6/results/regression_<unique id>.
% Run: addpath(genpath('matlab')); test_phase6_dynamic_trip
root=ashuganj_root();
addpath(fullfile(root,'Phase6','scripts'));
outDir=fullfile(root,'Phase6','results', ...
    ['regression_' char(java.util.UUID.randomUUID())]);
T=t_case('test_phase6_dynamic_trip');
fprintf('Preserved integration evidence: %s\n',outDir);

S=build_dynamic_protection_sim(outDir,root);
assert(isfield(S,'info') && isfield(S,'sim_mode') ...
    && strcmp(S.sim_mode,'measured-simulink'), ...
    'Phase6:MeasuredModelRequired', ...
    'The builder must return a real model build, not a copied placeholder.');
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
T=T.chk(strcmp(S.info.model,mdl),'build metadata names the actual saved model');
T=T.chk(isfile(S.model_dst) && isfile(S.params_csv) && isfile(S.meta_json), ...
    'working model and active-setting evidence exist');
load_system(S.model_dst);
cleanup=onCleanup(@()closeTestModel(mdl)); %#ok<NASGU>
mw=get_param(mdl,'ModelWorkspace'); savedInfo=getVariable(mw,'Phase6BuildInfo');
T=T.chk(strcmp(savedInfo.model,mdl),'saved workspace metadata names the working model');
T=T.chk(isempty(find_system(mdl,'SearchDepth',1,'Name','CL_TripRelayHook')), ...
    'saved model contains no unconnected relay hook');
T=T.chk(~isempty(find_system(mdl,'LookUnderMasks','all', ...
    'FunctionName','phase6_relay_sfun')), ...
    'saved model contains the measured-current relay engine');

% A real normal run catches spurious trips and broken machine initialization.
normal=struct('name','regression_normal','faultEnabled',false, ...
    'protectionEnabled',true,'stopTime_s',.60);
normalOut=phase6_interactive_settings(mdl,'run',struct('scenario',normal));
normalContext=phase6_interactive_settings(mdl,'get');
[normalTables,normalSignals]=phase6_result_tables(normalOut,normalContext.info);
T=T.chk(isa(normalOut,'Simulink.SimulationOutput'), ...
    'normal case returns a SimulationOutput');
T=T.chk(all(normalSignals.relay.data(:,8:14)==0,'all'), ...
    'normal case has no relay trips');
T=T.chk(all(normalSignals.breakers.data(:,1:4)>.5,'all'), ...
    'normal case retains the four initially closed breakers');
window=normalSignals.summary.time>=.40;
power=mean(normalSignals.summary.data(window,1));
T=T.chk(any(window) && abs(power-360)<3.6, ...
    'normal measured generator power is within 1 percent of 360 MW');
save(fullfile(outDir,'normal_regression.mat'), ...
    'normalOut','normalContext','normalTables','power','-v7.3');

% This call must run the electrical model through the actual fault/trip.
fault=struct('name','regression_bus_3ph','faultEnabled',true, ...
    'faultType','3PH','faultLocation','GIS230', ...
    'faultStart_s',.15,'faultDuration_s',.30,'stopTime_s',.60, ...
    'protectionEnabled',true);
R=run_dynamic_trip_simulation(outDir,root,fault);
T=T.chk(isa(R.out,'Simulink.SimulationOutput') ...
    && strcmp(R.sim_mode,'measured-simulink'), ...
    'fault evidence comes from the full Simulink run');
T=T.chk(isfile(R.times_csv) && isfile(R.png), ...
    'measured relay CSV and protection figure are exported');
T=T.chk(strcmp(R.export.metadata.dataOrigin,'actual logged simulation samples'), ...
    'export identifies actual logged simulation samples');
tables=R.export.tables;
relay=tables.relay_times;
busTrip=relay.First_trip_request_s(string(relay.Relay)=="87B");
faultOff=fault.faultStart_s+fault.faultDuration_s;
T=T.chk(isscalar(busTrip) && isfinite(busTrip) ...
    && busTrip>fault.faultStart_s && busTrip<faultOff, ...
    '87B issues a measured trip while the bus fault is still applied');
assert(isscalar(busTrip) && isfinite(busTrip),'Phase6:BusTripRequired', ...
    'A measured 87B trip is required to evaluate breaker timing.');
Ts=R.info.controls.parameters.Ts;
for name=["Q0","LineLocal"]
    rows=tables.breaker_times(string(tables.breaker_times.Breaker)==name,:);
    delay=rows.Open_command_s-busTrip;
    T=T.chk(height(rows)==3 && all(isfinite(delay)) ...
        && all(delay>=.050-Ts-1e-10) && all(delay<=.050+3*Ts+1e-10), ...
        sprintf('%s opens after the 50 ms mechanism delay within sample latency',name));
    T=T.chk(height(rows)==3 && all(isfinite(rows.Current_cessation_s)) ...
        && all(rows.Current_cessation_s>=rows.Open_command_s) ...
        && all(rows.Current_cessation_s+rows.Required_hold_s<faultOff), ...
        sprintf('%s has sustained measured three-phase current cessation before fault removal',name));
end
raw=R.out.get('phase6_raw');
T=T.chk(raw.Time(end)>=fault.stopTime_s-1e-9, ...
    'electrical waveform record reaches the requested stop time');
persisted=readtable(R.times_csv);
persistedTrip=persisted.First_trip_request_s(string(persisted.Relay)=="87B");
T=T.chk(isscalar(persistedTrip) && abs(persistedTrip-busTrip)<1e-12, ...
    'persisted trip time matches the measured result');

% Turning protection off must leave a real energized fault, not simply
% suppress indications while a synthesized breaker trace still opens.
disabled=fault;disabled.name='regression_protection_disabled';
disabled.protectionEnabled=false;
disabledOut=phase6_interactive_settings(mdl,'run',struct('scenario',disabled));
disabledContext=phase6_interactive_settings(mdl,'get');
[disabledTables,disabledSignals]=phase6_result_tables(disabledOut,disabledContext.info);
T=T.chk(all(disabledSignals.relay.data(:,8:14)==0,'all'), ...
    'disabled protection produces no relay trips');
beforeRemoval=disabledSignals.breakers.time<faultOff;
T=T.chk(any(beforeRemoval) ...
    && all(disabledSignals.breakers.data(beforeRemoval,1:4)>.5,'all'), ...
    'disabled protection keeps the initially closed breakers closed during the fault');
sensor=find(string(disabledContext.info.controls.sensorNames)=="faultGIS");
duringFault=disabledSignals.raw.time>=.25 & disabledSignals.raw.time<.40;
faultCurrent=disabledSignals.raw.data(duringFault,(sensor-1)*6+(4:6));
T=T.chk(~isempty(faultCurrent) && max(abs(faultCurrent),[],'all')>1000, ...
    'disabled protection retains measured bus-fault current before scheduled removal');
save(fullfile(outDir,'disabled_regression.mat'), ...
    'disabledOut','disabledContext','disabledTables','-v7.3');

% Restore the verified bus-fault setup for the next interactive opening.
phase6_interactive_settings(mdl,'apply',struct('scenario',R.info.scenario));
[np,nf]=T.done();
assert(nf==0,'Phase6:DynamicTripRegression', ...
    'Measured dynamic-trip regression failed: %d checks. Evidence: %s',nf,outDir);
fprintf('PHASE6_MEASURED_DYNAMIC_TRIP_PASS: %d checks; %s\n',np,outDir);
evidence=R;
end

function closeTestModel(mdl)
if bdIsLoaded(mdl),close_system(mdl,0);end
end
