% VERIFY_LAYOUT Read-only block geometry audit and rendered review evidence.
% Run after style_phase6_model. It does not save or change model behavior.
auditDir=fileparts(mfilename('fullpath'));
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
assert(bdIsLoaded(mdl),'Phase6:LayoutModel','Load the Phase6 model before the layout audit.');
outDir=fullfile(auditDir,'layout');if ~isfolder(outDir),mkdir(outDir);end
systems={mdl,[mdl '/Generator'],[mdl '/Transformer'],[mdl '/Switchyard'], ...
 [mdl '/Transmission Line'],[mdl '/Grid'],[mdl '/Auxiliaries'], ...
 [mdl '/Measurements'],[mdl '/Protection'],[mdl '/DC Supply'], ...
 [mdl '/Breaker Control'],[mdl '/Turbine and AVR'],[mdl '/Results']};
overlapRows=cell(0,7);geometryRows=cell(0,6);
for s=1:numel(systems)
 sys=systems{s};
 bb=find_system(sys,'SearchDepth',1,'Type','block');bb(strcmp(bb,sys))=[];
 bounds=zeros(numel(bb),4);
 for k=1:numel(bb)
  bounds(k,:)=get_param(bb{k},'Position');
  geometryRows(end+1,:)=[{sys,bb{k}},num2cell(bounds(k,:))]; %#ok<SAGROW>
 end
 for i=1:numel(bb)
  for j=i+1:numel(bb)
   w=min(bounds(i,3),bounds(j,3))-max(bounds(i,1),bounds(j,1));
   h=min(bounds(i,4),bounds(j,4))-max(bounds(i,2),bounds(j,2));
   if w>0 && h>0
    overlapRows(end+1,:)={sys,bb{i},bb{j},w,h,w*h,'BLOCK_BODY_OVERLAP'}; %#ok<SAGROW>
   end
  end
 end
 filename=regexprep(strrep(sys,[mdl '/'],''),'[^A-Za-z0-9_-]','_');
 try
  print(['-s' sys],'-dpng','-r110',fullfile(outDir,[filename '.png']));
 catch ME
  warning('Phase6:LayoutRender','Could not render %s: %s',sys,ME.message);
 end
end
writetable(cell2table(geometryRows,'VariableNames',{'System','Block','Left','Top','Right','Bottom'}), ...
 fullfile(outDir,'block_geometry.csv'));
writetable(cell2table(overlapRows,'VariableNames',{'System','BlockA','BlockB','Width','Height','Area','Finding'}), ...
 fullfile(outDir,'block_overlaps.csv'));
fprintf('LAYOUT_AUDIT systems=%d block_body_overlaps=%d evidence=%s\n',numel(systems),size(overlapRows,1),outDir);
% The PNGs also require visual review: label extents and wire crossings are
% not represented by Position rectangles and are not certified by this CSV.
