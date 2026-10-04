% FINISH_LAYOUT Apply final geometry, compile, save and render without a run.
finishAudit=fileparts(mfilename('fullpath'));
finishPhase6=fileparts(fileparts(finishAudit));
finishProject=fileparts(finishPhase6);
addpath(genpath(fullfile(finishProject,'matlab')));
addpath(fullfile(finishPhase6,'scripts'));
setup_phase6_workspace();
clear style_phase6_model;
opengl software;set(0,'DefaultFigureRenderer','painters');
finishModel='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
finishFile=fullfile(finishPhase6,[finishModel '.slx']);
finishStatus=struct('status','RUNNING','modelFile',finishFile,'simulationRun',false);
try
 backupFile=fullfile(finishAudit,'before','closed_loop_before_final_geometry.slx');
 if ~isfile(backupFile),copyfile(finishFile,backupFile);end
 load_system(finishFile);
 style_phase6_model(finishModel);
 set_param(finishModel,'SimulationCommand','update');
 save_system(finishModel,finishFile);
 run(fullfile(finishAudit,'verify_layout.m'));
 finishOverlaps=readtable(fullfile(finishAudit,'layout','block_overlaps.csv'));
 assert(height(finishOverlaps)==0,'Phase6:LayoutOverlap','Remaining block-body overlaps: %d',height(finishOverlaps));
 finishPNGs=dir(fullfile(finishAudit,'layout','*.png'));
 assert(numel(finishPNGs)>=13,'Phase6:LayoutImages','Missing rendered layout evidence.');
 print(['-s' finishModel],'-dpng','-r120',fullfile(finishAudit,'verified_model.png'));
 finishStatus.status='PASS';finishStatus.blockBodyOverlaps=height(finishOverlaps);
 finishStatus.renderedSystems=numel(finishPNGs);finishStatus.compiled=true;
 finishStatus.finished=char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
 fid=fopen(fullfile(finishAudit,'layout_status.json'),'w');
 fprintf(fid,'%s\n',jsonencode(finishStatus,'PrettyPrint',true));fclose(fid);
 fprintf('FINAL_LAYOUT_PASS zero overlaps; saved, compiled, rendered %d systems.\n',numel(finishPNGs));
 close_system(finishModel,0);
catch finishError
 finishStatus.status='FAIL';finishStatus.error=getReport(finishError,'extended','hyperlinks','off');
 fid=fopen(fullfile(finishAudit,'layout_status.json'),'w');
 fprintf(fid,'%s\n',jsonencode(finishStatus,'PrettyPrint',true));fclose(fid);
 rethrow(finishError);
end
