function n=phase5b_verify_artifacts(out)
% Re-read actual files. Any stale CSV/PNG/document/code digest fails closed.
if nargin<1, out=fullfile(ashuganj_root(),'results','phase5_protection_v2'); end
root=ashuganj_root();
m=jsondecode(fileread(fullfile(out,'manifest.json')));
assert(strcmp(m.testCounts.runner,'run_phase5b_tests()')&&m.testCounts.NF==0,'phase5b_artifacts:runner','Wrong runner or failed tests');
n=0;
for i=1:numel(m.outputHashes)
 check(fullfile(out,m.outputHashes(i).file),m.outputHashes(i).sha256);
end
for i=1:numel(m.codeHashes), check(fullfile(root,m.codeHashes(i).file),m.codeHashes(i).sha256); end
for i=1:numel(m.inputHashes), check(fullfile(root,m.inputHashes(i).path),m.inputHashes(i).sha256); end
ls=splitlines(string(fileread(fullfile(out,'sha256.txt'))));
for i=1:numel(ls)
 if strlength(strtrim(ls(i)))==0, continue; end
 tok=regexp(char(ls(i)),'^([0-9a-fA-F]{64})  (.+)$','tokens','once');
 assert(~isempty(tok),'phase5b_artifacts:format','Malformed sha256 line'); check(fullfile(out,tok{2}),tok{1});
end
check(fullfile(out,m.tccPlots.study_png),m.tccPlots.study_sha256);
check(fullfile(out,m.tccPlots.physical_png),m.tccPlots.physical_sha256);
t=jsondecode(fileread(fullfile(out,'plots','tcc_metadata.json')));
assert(t.reference_voltage_kV==230,'phase5b_artifacts:tcc','Study TCC voltage base mismatch');
R=phase5b_registry();
for i=1:numel(t.study_settings)
 x=t.study_settings(i); d=R.devices(strcmp({R.devices.device_id},x.device_id));
 assert(x.TMS==d.tms&&x.pickup_prim==d.pickup_A,'phase5b_artifacts:tcc','TCC/live setting mismatch');
 assert(contains(t.study_title,sprintf('%.2f',d.tms)),'phase5b_artifacts:tcc','TCC title is stale');
end
 function check(p,h)
  assert(isfile(p),'phase5b_artifacts:missing','Missing artifact %s',p);
  assert(strcmpi(phase5b_sha256(p),h),'phase5b_artifacts:hash','Hash mismatch: %s',p); n=n+1;
 end
end
