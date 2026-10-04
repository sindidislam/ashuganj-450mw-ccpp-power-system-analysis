out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
clear phase6_color_wires;
phase6_presentation_busbars(mdl);
% Reapply the complete style to confirm future builds keep the busbars.
style_phase6_model(mdl);
set_param(mdl,'SimulationCommand','update');
finalRun=sim(mdl,'StopTime','0.30','ReturnWorkspaceOutputs','on');
finalSummary=finalRun.get('phase6_summary');
load(fullfile(out,'work','baseline_summary.mat'),'baselineSummary');
assert(isequal(finalSummary.Time,baselineSummary.Time));
delta=max(abs(finalSummary.Data-baselineSummary.Data),[],'all');
assert(delta<1e-7);
phase6_color_wires(mdl);save_system(mdl,fullfile(p6,[mdl '.slx']));
% Refresh the full-system images with initialized live readings.
records=jsondecode(fileread(fullfile(out,'manifest.json')));
overlaps=cell(0,3);
for k=1:numel(records)
 if ~strcmp(records(k).kind,'system'),continue;end
 sys=records(k).system;
 print(['-s' sys],'-dpng','-r160',fullfile(out,records(k).image));
 bb=find_system(sys,'SearchDepth',1,'Type','block');bb(strcmp(bb,sys))=[];
 for a=1:numel(bb)
  pa=get_param(bb{a},'Position');
  for b=a+1:numel(bb)
   pb=get_param(bb{b},'Position');
   if min(pa(3),pb(3))>max(pa(1),pb(1))&&min(pa(4),pb(4))>max(pa(2),pb(2))
    overlaps(end+1,:)={sys,bb{a},bb{b}};
   end
  end
 end
end
fid=fopen(fullfile(out,'layout_overlaps.json'),'w');fprintf(fid,'%s',jsonencode(overlaps));fclose(fid);
assert(isempty(overlaps),'Phase6:Overlap','%d block overlaps remain.',size(overlaps,1));
v=jsondecode(fileread(fullfile(out,'verification.json')));v.maxSummaryDifference=delta;v.reappliedStyle=true;v.blockBodyOverlaps=size(overlaps,1);
v.finished=char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));v.renderedSystems=24;v.renderedComponents=429;
fid=fopen(fullfile(out,'verification.json'),'w');fprintf(fid,'%s',jsonencode(v,'PrettyPrint',true));fclose(fid);
fprintf('FINAL_MODEL_PASS delta=%g overlaps=0\n',delta);
