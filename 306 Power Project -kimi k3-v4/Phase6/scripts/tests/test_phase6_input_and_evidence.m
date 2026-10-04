function test_phase6_input_and_evidence()
%TEST_PHASE6_INPUT_AND_EVIDENCE Reject invalid settings and misleading results.
addpath(fileparts(fileparts(mfilename('fullpath'))));
P=init_phase6_parameters();S=phase6_normalize_scenario(P);
assert(isinf(S.dcLossTime_s) && isinf(S.dcRestoreTime_s));
accepted=phase6_normalize_scenario(P,struct('faultType','slg', ...
    'faultLocation','gis230','networkProfile','phase3_baseline', ...
    'manualOpenTime_s',0,'generatorTripTime_s',Inf));
assert(strcmp(accepted.faultType,'SLG') && strcmp(accepted.faultLocation,'GIS230'), ...
    'Accepted categorical settings must be normalized for the control panel.');
bad={
    'faultStart_s',Inf;
    'faultDuration_s',Inf;
    'faultResistance_ohm',Inf;
    'groundResistance_ohm',NaN;
    'stopTime_s',1+1i;
    'dispatch_MW',[180 360];
    'faultEnabled',NaN;
    'batteryAvailable',2;
    'chargerAvailable',[true false];
    'GAT_in','yes';
    'relayMask',[true true true true true true NaN];
    'breakerFailed',[0 0 0 0 2];
    'manualOpen',[0 0 0 0 -1];
    'manualOpenTime_s',-1;
    'generatorTripTime_s',NaN;
    'dcLossTime_s',-1;
    'dcRestoreTime_s',-Inf;
    'measurementScale',complex(ones(1,19),ones(1,19))};
for k=1:size(bad,1)
    mustReject(@()phase6_normalize_scenario(P,struct(bad{k,1},bad{k,2})),bad{k,1});
end
mustReject(@()phase6_normalize_scenario(P, ...
    struct('dcLossTime_s',.5,'dcRestoreTime_s',.2)),'DC restore before loss');
mustReject(@()phase6_normalize_scenario(P, ...
    struct('faultEnabled',true,'faultStart_s',3,'stopTime_s',2)), ...
    'enabled fault after requested stop');
fprintf('PHASE6_SCENARIO_VALIDATION_PASS\n');

% SimulationOutput fixtures exercise the completion gate independently of
% plant physics. A finite partial record must never be cached as complete.
good=Simulink.SimulationOutput();good.tout=[0;.1;.2];
runScenario=struct('stopTime_s',.2);
phase6_assert_complete_run(good,runScenario);
partial=Simulink.SimulationOutput();partial.tout=[0;.05;.1];
mustReject(@()phase6_assert_complete_run(partial,runScenario),'partial run');
empty=Simulink.SimulationOutput();empty.tout=[];
mustReject(@()phase6_assert_complete_run(empty,runScenario),'empty run');
invalid=Simulink.SimulationOutput();invalid.tout=[0;NaN;.2];
mustReject(@()phase6_assert_complete_run(invalid,runScenario),'invalid time record');
fprintf('PHASE6_RUN_COMPLETION_GATE_PASS\n');

% NaN comparison errors do not satisfy error > tolerance. This fixture
% catches a default PASS that survives a nonfinite measured quantity.
time=(0:.001:.1).';
summary=ones(numel(time),24);summary(:,1)=NaN;
out=struct('phase6_summary',timeseries(summary,time), ...
    'phase6_phasors',timeseries(ones(numel(time),228),time));
info=struct('scenario',S,'network',struct('profile',phase6_electrical_profile(P,S)), ...
    'controls',struct('relayParameters',phase6_relay_parameters(P)));
[comparison,~]=phase6_compare_reference(out,info);
badRows=~isfinite(comparison.Measured);
assert(any(badRows) && all(startsWith(string(comparison.Status(badRows)),"INVALID")), ...
    'A nonfinite measured comparison must be labelled invalid, never PASS.');
info.scenario.networkProfile='PHASE5_STUDY';
[comparison,~]=phase6_compare_reference(out,info);
assert(all(startsWith(string(comparison.Status(badRows)),"INVALID")), ...
    'A different-profile qualification must not hide invalid measurements.');
fprintf('PHASE6_REFERENCE_NONFINITE_GATE_PASS\n');
end

function mustReject(action,label)
rejected=false;
try,action();catch,rejected=true;end
assert(rejected,'Phase6:InvalidInputAccepted','Expected rejection: %s.',label);
end
