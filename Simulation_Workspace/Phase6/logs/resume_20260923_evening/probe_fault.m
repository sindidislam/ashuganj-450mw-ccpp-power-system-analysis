phase6=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(phase6,'scripts')); paths=setup_phase6_workspace();
S=struct('name','bus_3ph','faultEnabled',true,'faultType','3PH', ...
 'faultLocation','GIS230','faultStart_s',.15,'faultDuration_s',.3,'stopTime_s',.6);
dest=fullfile(paths.results,S.name);if ~isfolder(dest),mkdir(dest);end
info=build_phase6_model('Scenario',S,'SavePath',fullfile(dest,'PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx'));
fprintf('FAULT_PROBE_BUILD_PASS\n');
out=sim(info.model,'ReturnWorkspaceOutputs','on');
save(fullfile(dest,'probe.mat'),'info','out','-v7.3');
fprintf('FAULT_PROBE_SIM_PASS\n');
result=export_phase6_results(out,info,dest);
disp(result.tables.relay_times);disp(result.tables.breaker_times);
fprintf('FAULT_PROBE_EXPORT_PASS\n');
