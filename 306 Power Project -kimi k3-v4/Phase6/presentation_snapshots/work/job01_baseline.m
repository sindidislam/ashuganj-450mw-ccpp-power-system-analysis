out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';modelFile=fullfile(p6,[mdl '.slx']);
backup=fullfile(out,'backup');if ~isfolder(backup),mkdir(backup);end
if ~isfile(fullfile(backup,[mdl '.slx'])),copyfile(modelFile,backup);end
for file={'style_phase6_model.m','phase6_color_wires.m'}
 if ~isfile(fullfile(backup,file{1})),copyfile(fullfile(p6,'scripts',file{1}),backup);end
end
load_system(modelFile);
set_param(mdl,'SimulationCommand','update');
baselineRun=sim(mdl,'StopTime','0.30','ReturnWorkspaceOutputs','on');
baselineSummary=baselineRun.get('phase6_summary');
save(fullfile(out,'work','baseline_summary.mat'),'baselineSummary');
fprintf('BASELINE_RUN_PASS final_t=%g\n',baselineSummary.Time(end));
rootBlocks=find_system(mdl,'SearchDepth',1,'Type','block');
for k=2:numel(rootBlocks)
 hp=get_param(rootBlocks{k},'PortHandles');
 if ~isempty(hp.LConn)||~isempty(hp.RConn)
  fprintf('PORTS %s L=%s R=%s\n',rootBlocks{k},mat2str(hp.LConn),mat2str(hp.RConn));
 end
end
