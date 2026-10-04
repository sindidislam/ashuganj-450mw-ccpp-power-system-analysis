function export_all_snapshots(mdl,out)
% Export whole SLD (top-level canvas) and project-level subsystems only.
% Block-by-block component exports omitted per presentation requirements.
raw=fullfile(out,'raw');if ~isfolder(raw),mkdir(raw);end
records=struct('id',{},'title',{},'system',{},'image',{},'area',{},'kind',{}, ...
 'block_type',{},'block_name',{},'parent_system',{},'description',{},'reference_block',{});
inventory=struct('path',{},'parent',{},'type',{},'mask_type',{},'position',{},'reference',{});
walk(mdl,'Overview');
writeJSON(fullfile(out,'block_inventory.json'),inventory);
writeJSON(fullfile(out,'manifest.json'),records);
fprintf('SNAPSHOT_INVENTORY systems=%d total=%d\n',numel(records),numel(records));

errors=struct('id',{},'path',{},'message',{});
for k=1:numel(records)
 r=records(k);file=fullfile(out,strrep(r.image,'/',filesep));
 try
  print(['-s' r.system],'-dpng','-r160',file);
 catch err
  errors(end+1)=struct('id',r.id,'path',r.system,'message',err.message); %#ok<AGROW>
  fprintf(2,'SNAPSHOT_FAILED %s %s\n',r.id,err.message);
 end
 if mod(k,5)==0 || k==numel(records),fprintf('SNAPSHOT_PROGRESS %d/%d\n',k,numel(records));end
end
writeJSON(fullfile(out,'export_errors.json'),errors);
assert(isempty(errors),'Phase6:SnapshotExport','%d system snapshots failed; inspect export_errors.json.',numel(errors));
writeJSON(fullfile(out,'export_status.json'),struct('status','PASS','total',numel(records), ...
 'systems',numel(records),'components',0, ...
 'scope','Whole plant SLD and project-level subsystems; block-by-block component exports omitted.'));
fprintf('ALL_SNAPSHOTS_PASS %d\n',numel(records));

 function walk(system,area)
  addRecord(system,area,'system');
  bb=find_system(system,'SearchDepth',1,'Type','block');bb(strcmp(bb,system))=[];
  for b=1:numel(bb)
   path=bb{b};type=get_param(path,'BlockType');ref=get_param(path,'ReferenceBlock');
   inventory(end+1)=struct('path',path,'parent',system,'type',type,'mask_type',get_param(path,'MaskType'), ...
    'position',get_param(path,'Position'),'reference',ref); %#ok<AGROW>
   nextArea=area;
   if strcmp(system,mdl)
    nextArea=get_param(path,'Name');
    if contains(nextArea,{'B_22','Generator Breaker','B01','B02'}),nextArea='Generator';
    elseif strcmp(nextArea,'GCB command'),nextArea='Breaker Control';
    elseif contains(nextArea,{'Live Meter','Live Three Phase'}) || ~strcmp(type,'SubSystem'),nextArea='Measurements';
    end
   end
   if strcmp(type,'SubSystem')&&isempty(ref)
    children=find_system(path,'SearchDepth',1,'Type','block');
    if numel(children)>1,walk(path,nextArea);end
   end
  end
 end
 function addRecord(path,area,kind)
  id=sprintf('%03d',numel(records));
  if strcmp(path,mdl)
   title='Plant overview';name='Plant overview';type='BlockDiagram';parent='';desc='Complete v4 model with voltage-coded electrical busbars.';ref='';
  else
   name=get_param(path,'Name');type=get_param(path,'BlockType');parent=get_param(path,'Parent');desc=get_param(path,'Description');ref=get_param(path,'ReferenceBlock');title=name;
  end
  slug=regexprep(strrep(path,[mdl '/'],''),'[^A-Za-z0-9_-]','_');
  if strcmp(path,mdl),slug='Plant_overview';end
  if numel(slug)>110,slug=slug(1:110);end
  records(end+1)=struct('id',id,'title',title,'system',path,'image',['raw/' id '_' slug '.png'], ...
   'area',area,'kind',kind,'block_type',type,'block_name',name,'parent_system',parent, ...
   'description',desc,'reference_block',ref); %#ok<AGROW>
 end
end

function writeJSON(path,value)
fid=fopen(path,'w');assert(fid>0,'Phase6:Write','Cannot write %s',path);
cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
