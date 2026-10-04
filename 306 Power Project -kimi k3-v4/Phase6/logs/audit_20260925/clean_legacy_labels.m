% CLEAN_LEGACY_LABELS Apply reviewed caption-only edits to the 11 live models.
% All originals are backed up before the first model is edited. source_clone
% and simulink/backups are intentionally outside the strict allowlist.
auditDir=fileparts(mfilename('fullpath'));
projectDir=fileparts(fileparts(fileparts(auditDir)));
plan=jsondecode(fileread(fullfile(auditDir,'legacy_caption_plan.json')));
allowed=[{'simulink\main\Ashuganj_South_Main.slx'; ...
 'simulink\studies\Load_Flow.slx';'simulink\studies\Load_Flow_V2.slx'}; ...
 arrayfun(@(k)sprintf('simulink\\studies\\Load_Flow_LF%d.slx',k),(1:4)','UniformOutput',false); ...
 arrayfun(@(k)sprintf('simulink\\studies\\Load_Flow_LF%d_Annotated.slx',k),(1:4)','UniformOutput',false)];
models=unique({plan.Model},'stable');
assert(all(ismember(models,allowed)),'Phase6:LegacyAllowlist','Unexpected legacy model in caption plan.');
for k=1:numel(models)
 src=fullfile(projectDir,models{k});
 assert(isfile(src),'Phase6:LegacyMissing','Missing model: %s',src);
 [~,name]=fileparts(src);
 if bdIsLoaded(name)
  assert(strcmpi(char(java.io.File(get_param(name,'FileName')).getCanonicalPath()), ...
   char(java.io.File(src).getCanonicalPath())),'Phase6:WrongProject','Loaded model is from another project: %s',name);
  assert(strcmp(get_param(name,'Dirty'),'off'),'Phase6:DirtyLegacy','Save existing edits before caption cleanup: %s',name);
 end
 dst=fullfile(auditDir,'before','legacy_models',models{k});
 if ~isfile(dst)
  folder=fileparts(dst);if ~isfolder(folder),mkdir(folder);end
  [ok,msg]=copyfile(src,dst);assert(ok,'Phase6:LegacyBackup','%s',msg);
 end
end
captionLog=cell(0,4);
for k=1:numel(models)
 src=fullfile(projectDir,models{k});[~,name]=fileparts(src);
 wasLoaded=bdIsLoaded(name);load_system(src);
 items=plan(strcmp({plan.Model},models{k}));
 aa=find_system(name,'FindAll','on','LookUnderMasks','all','Type','annotation');
 objects=arrayfun(@(h)get_param(h,'Object'),aa,'UniformOutput',false);
 changed=0;
 for j=1:numel(items)
  old=items(j).OldText;new=items(j).NewText;
  matches=find(cellfun(@(a)strcmp(a.Text,old),objects));
  if isempty(matches)
   assert(any(cellfun(@(a)strcmp(a.Text,new),objects)), ...
    'Phase6:LegacyCaptionMismatch','Caption not found in %s (SID %s).',name,items(j).Sid);
  else
   for q=reshape(matches,1,[]),objects{q}.Text=new;end
   changed=changed+numel(matches);
  end
  captionLog(end+1,:)={models{k},items(j).Sid,numel(matches),new}; %#ok<SAGROW>
 end
 if changed>0,save_system(name,src);end
 fprintf('LEGACY_CAPTIONS %s changed=%d\n',name,changed);
 if ~wasLoaded,close_system(name,0);end
end
writetable(cell2table(captionLog,'VariableNames',{'Model','AnnotationSID','Changed','Caption'}), ...
 fullfile(auditDir,'legacy_caption_changes.csv'));
fprintf('Legacy caption cleanup complete; originals retained in before/legacy_models.\n');
