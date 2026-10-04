phase6=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(phase6,'scripts'));paths=setup_phase6_workspace();
base=load(fullfile(paths.results,'generator_slg','probe.mat'),'info');info=base.info;
load_system(info.path);mdl=info.model;S=info.scenario;
S.name='generator_slg_timed';S.faultDuration_s=2.15;S.stopTime_s=2.5;
mw=get_param(mdl,'ModelWorkspace');assignin(mw,'S',S);info.scenario=S;
set_param(mdl,'StopTime','2.5');
keys=fieldnames(info.network.faults);
for j=1:numel(keys)
 times=[1e6 1e6+1];if strcmp(keys{j},'GEN'),times=[.15 2.3];end
 set_param(info.network.faults.(keys{j}),'FaultA','on','FaultB','off','FaultC','off','GroundFault','on','SwitchTimes',mat2str(times));
end
out=sim(mdl,'ReturnWorkspaceOutputs','on');
dest=fullfile(paths.results,S.name);if ~isfolder(dest),mkdir(dest);end
save(fullfile(dest,'probe.mat'),'info','out','-v7.3');
[tables,signals,metadata]=phase6_result_tables(out,info);
save(fullfile(dest,'simulation_data.mat'),'info','out','tables','signals','metadata','-v7.3');
fields=fieldnames(tables);for j=1:numel(fields),writetable(tables.(fields{j}),fullfile(dest,[fields{j} '.csv']));end
assert(any(out.phase6_relay.Data(:,10)),'Neutral inverse relay did not trip');
assert(any(out.phase6_breakers.Data(:,1)==0),'Neutral trip did not open GCB');
disp(tables.relay_times(3,:));fprintf('NEUTRAL_TIMED_TRIP_PASS\n');
close_system(mdl,0);
% A different dispatch requires a fresh solved operating point.
S=struct('name','reduced_180MW','dispatch_MW',180,'stopTime_s',.4);
dest=fullfile(paths.results,S.name);if ~isfolder(dest),mkdir(dest);end
info=build_phase6_model('Scenario',S,'SavePath',fullfile(dest,'PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx'));
out=sim(info.model,'ReturnWorkspaceOutputs','on');
q=out.phase6_summary;ix=q.Time>.2;
assert(max(abs(q.Data(ix,1)-180))<1,'Reduced active power deviation');
assert(max(abs(q.Data(ix,3)-22))<.1,'Reduced voltage deviation');
assert(max(abs(q.Data(ix,5)-50))<.01,'Reduced speed deviation');
assert(~any(out.phase6_relay.Data(:,8:14),'all'),'Reduced dispatch nuisance trip');
save(fullfile(dest,'probe.mat'),'info','out','-v7.3');
export_phase6_results(out,info,dest);fprintf('REDUCED_DISPATCH_PASS\n');
close_system(info.model,0);
