function manifest=phase5b_finalize_manifest(out,meta)
% Hash only after CSVs, plots, metadata and final documentation are complete.
root=ashuganj_root();
files=dir(fullfile(out,'**','*')); paths={};
for i=1:numel(files)
 if files(i).isdir||ismember(files(i).name,{'manifest.json','sha256.txt'}), continue; end
 paths{end+1}=fullfile(files(i).folder,files(i).name); %#ok<AGROW>
end
docs=dir(fullfile(root,'docs','PHASE5_*'));
for i=1:numel(docs)
 if ~docs(i).isdir, paths{end+1}=fullfile(docs(i).folder,docs(i).name); end %#ok<AGROW>
end
paths{end+1}=fullfile(root,'docs','NOT_DETERMINABLE_REGISTER.md');
paths{end+1}=fullfile(root,'docs','manual','phase5_protection_manual.html');
paths{end+1}=fullfile(root,'docs','manual','student_manual_phases_0_to_5.html');
paths{end+1}=fullfile(root,'docs','superpowers','plans','2026-09-20-phase5-final-engineering.md');
mirrors=dir(fullfile(root,'PHASE5_*'));
for i=1:numel(mirrors)
 if ~mirrors(i).isdir&&~endsWith(mirrors(i).name,'.zip'), paths{end+1}=fullfile(mirrors(i).folder,mirrors(i).name); end %#ok<AGROW>
end
paths{end+1}=fullfile(root,'NOT_DETERMINABLE_REGISTER.md');
paths=unique(paths,'stable');
outputHashes=struct('file',{},'sha256',{});
for i=1:numel(paths)
 outputHashes(end+1)=struct('file',relout(paths{i}),'sha256',phase5b_sha256(paths{i})); %#ok<AGROW>
end
code=dir(fullfile(root,'matlab','phase5','*.m'));
tests=dir(fullfile(root,'matlab','tests','test_phase5b_*.m'));
code=[code;tests]; codeHashes=struct('file',{},'sha256',{});
for i=1:numel(code)
 p=fullfile(code(i).folder,code(i).name);
 codeHashes(end+1)=struct('file',strrep(p(numel(root)+2:end),'\','/'),'sha256',phase5b_sha256(p)); %#ok<AGROW>
end
input=readtable(fullfile(root,'docs','PHASE5_PROTECTED_BASELINE.csv'),'TextType','string','Delimiter',',');
manifest=struct('tag',meta.tag,'timestamp_local',datestr(now,'yyyy-mm-ddTHH:MM:SS'), ...
 'root_path_convention','outputHashes relative to this manifest; codeHashes/inputHashes relative to project root', ...
 'testCounts',struct('runner','run_phase5b_tests()','NP',meta.testCounts.NP,'NF',meta.testCounts.NF), ...
 'inputHashes',table2struct(input),'codeHashes',codeHashes,'outputHashes',outputHashes, ...
 'grid_scenario','45.01 kA central preliminary ANALYTICAL SCREENING; locked Phase-4 fault matrix retained', ...
 'tccPlots',struct('study_png','plots/tcc_study.png','physical_png','plots/tcc_physical.png', ...
 'study_sha256',phase5b_sha256(fullfile(out,'plots','tcc_study.png')), ...
 'physical_sha256',phase5b_sha256(fullfile(out,'plots','tcc_physical.png'))));
fid=fopen(fullfile(out,'manifest.json'),'w'); assert(fid>=0); fprintf(fid,'%s\n',jsonencode(manifest,'PrettyPrint',true)); fclose(fid);
fid=fopen(fullfile(out,'sha256.txt'),'w'); assert(fid>=0);
for i=1:numel(outputHashes), fprintf(fid,'%s  %s\n',outputHashes(i).sha256,outputHashes(i).file); end
for i=1:numel(codeHashes), fprintf(fid,'%s  ../../%s\n',codeHashes(i).sha256,codeHashes(i).file); end
fprintf(fid,'%s  manifest.json\n',phase5b_sha256(fullfile(out,'manifest.json'))); fclose(fid);
 function r=relout(p)
  if startsWith(p,[out filesep]), r=p(numel(out)+2:end);
  else, assert(startsWith(p,[root filesep])); r=['..' filesep '..' filesep p(numel(root)+2:end)]; end
  r=strrep(r,'\','/');
 end
end
