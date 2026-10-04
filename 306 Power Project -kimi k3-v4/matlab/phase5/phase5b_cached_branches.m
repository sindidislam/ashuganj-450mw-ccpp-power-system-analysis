function B=phase5b_cached_branches(Ti)
% Cache only identity-checked phasors, keyed by inputs and solver source bytes.
persistent priorKey priorB
root=ashuganj_root();
paths={fullfile(root,'results','phase4_fault','production','phase4_contributions.csv'), ...
 fullfile(root,'results','phase4_fault','production','phase4_fault_currents.csv'), ...
 fullfile(root,'results','phase3_loadflow','phase3_bus_results.csv'), ...
 fullfile(root,'results','phase3_loadflow','phase3_system_summary.csv')};
for folder={'phase4','data','analysis','utilities'}
 fs=dir(fullfile(root,'matlab',folder{1},'*.m'));
 for j=1:numel(fs), paths{end+1}=fullfile(fs(j).folder,fs(j).name); end %#ok<AGROW>
end
paths{end+1}=which('phase5b_branch_phasors');
md=java.security.MessageDigest.getInstance('SHA-256');
for i=1:numel(paths), md.update(java.nio.file.Files.readAllBytes(java.io.File(paths{i}).toPath())); end
md.update(uint8(jsonencode(table2struct(Ti))));
key=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
if isequal(key,priorKey), B=priorB; return; end
folder=fullfile(root,'tmp','phase5_final_audit');
if ~isfolder(folder), mkdir(folder); end
fp=fullfile(folder,['branches_' key '.mat']);
if isfile(fp)
 s=load(fp,'B','cache_key');
 assert(strcmp(s.cache_key,key),'phase5b_cached_branches:key','Cache identity mismatch'); B=s.B;
else
 B=phase5b_branch_phasors(Ti); cache_key=key; %#ok<NASGU>
 save(fp,'B','cache_key');
end
priorKey=key; priorB=B;
end
