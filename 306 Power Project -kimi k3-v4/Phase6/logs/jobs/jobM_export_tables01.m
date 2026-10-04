clear phase6_result_tables export_phase6_results
rehash
addpath('C:\Users\sindi\Downloads\306 Power Project -kimi k3\Phase6\scripts');
phase6_export_fixture_test();

function phase6_export_fixture_test()
% Explicit unit-test fixture only; no production artifacts are generated.
paths=setup_phase6_workspace();
P=init_phase6_parameters();S=phase6_normalize_scenario(P,struct( ...
    'name','UNIT_TEST_FIXTURE','faultEnabled',true,'faultLocation','GEN', ...
    'faultStart_s',.050,'faultDuration_s',.080,'stopTime_s',.160));
t=(0:.001:.160).';n=numel(t);raw=zeros(n,114);phasors=zeros(n,228);
sensors={'genInner','genTerminal','gsutLV','gsutHV','busIn','busOut','gatHV', ...
    'lineLocal','lineRemote','aux','grid','neutral','faultGEN','faultLV', ...
    'faultHV','faultGIS','faultLINE','faultGRID','faultAUX'};
for p=1:3
    wave=sqrt(2)*50*cos(2*pi*50*t-(p-1)*2*pi/3);
    raw(:,(13-1)*6+3+p)=wave.*(t>=.050&t<.130);
    raw(:,(18-1)*6+3+p)=wave*10;
    raw(:,(2-1)*6+3+p)=wave.*(t<.115);
    phasors(t>=.071&t<.130,(13-1)*12+6+p)=50;
end
phasors(t>=.030,(2-1)*12+7)=20000;
phasors(t>=.035,(2-1)*12+9)=21000;
rel=zeros(n,43);rel(:,22:24)=Inf;rel(t>=.031,1)=1;rel(t>=.070,8)=1;
rel(t>=.070,15)=.040;
br=[ones(n,4) zeros(n,2)];br(t>=.110,1)=0;
dc=repmat([110 10 12 22 .8 1 0 0 0 0 1320 0],n,1);
summary=repmat(1:24,n,1);summary(t<.020,:)=0;
fixture=struct('phase6_raw',timeseries(raw,t),'phase6_phasors',timeseries(phasors,t), ...
    'phase6_rms',timeseries(zeros(n,114),t),'phase6_relay',timeseries(rel,t), ...
    'phase6_dc',timeseries(dc,t),'phase6_breakers',timeseries(br,t), ...
    'phase6_machine',timeseries(zeros(n,4),t),'phase6_summary',timeseries(summary,t));
infoFixture=struct('scenario',S,'controls',struct('sensorNames',{sensors}, ...
    'summaryNames',{cellstr("Summary_"+string(1:24))},'relayParameters',phase6_relay_parameters(P)));
[tables,~,metadata]=phase6_result_tables(fixture,infoFixture);
assert(contains(metadata.dataOrigin,'unit-test'));
assert(height(tables.raw_timeseries)==n&&width(tables.raw_timeseries)==115);
assert(height(tables.phase_pickup)==19);
assert(all(abs(tables.fault_summary.Initial_current_waveform_RMS_A-50)<1e-10));
assert(all(abs(tables.fault_summary.Full_window_fundamental_current_RMS_A-50)<1e-10));
assert(all(tables.fault_summary.Fault_branch_sensor=="faultGEN"));
assert(abs(tables.relay_times.First_pickup_s(1)-.031)<1e-12);
assert(abs(tables.relay_times.First_trip_request_s(1)-.070)<1e-12);
assert(isnan(tables.relay_times.First_trip_request_s(2)));
assert(all(abs(tables.breaker_times.Open_command_s(1:3)-.110)<1e-12));
assert(all(abs(tables.breaker_times.Current_cessation_s(1:3)-.115)<1e-12));
assert(all(tables.breaker_times.Status(13:15)=="initially_open_no_open_transition"));
assert(abs(tables.phase_pickup.Measured_threshold_crossing_s(1)-.030)<1e-12);
assert(isnan(tables.phase_pickup.Measured_threshold_crossing_s(2)));
assert(abs(tables.phase_pickup.Measured_threshold_crossing_s(3)-.035)<1e-12);
assert(tables.phase_pickup.Phase(7)=="neutral");
assert(all(abs(tables.load_point.Mean-(1:24).')<1e-12));
assert(~any(tables.events.Time_s<.020));
infoFixture.scenario.faultEnabled=false;
T=phase6_result_tables(fixture,infoFixture);
assert(all(isnan(T.fault_summary.Initial_current_waveform_RMS_A)));
assert(all(T.fault_summary.Initial_window_status=="fault_not_enabled"));
bad=false;try,export_phase6_results(fixture,infoFixture,fullfile(paths.phase6,'logs','unsafe')); ...
catch e,bad=strcmp(e.identifier,'Phase6:UnsafeOutput');end
assert(bad,'Output path escape must be rejected before any files are written.');
bad=false;try,export_phase6_results(fixture,infoFixture,fullfile(paths.results,'UNIT_TEST_FIXTURE')); ...
catch e,bad=strcmp(e.identifier,'Phase6:ProductionDataRequired');end
assert(bad,'Struct fixtures must not be exported as production simulation results.');
fprintf('PHASE6_EXPORT_TABLES_UNIT_TEST_PASS: selected branch, full RMS/DFT windows, NaN/no-event status, phase thresholds, relay/open/current-cessation separation, warmup exclusion, and output/data guards.\n');
end
