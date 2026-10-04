function [np,nf]=test_phase5b_artifacts()
% Real-file mutation tests for final integrity checks, isolated from production.
T=t_case('test_phase5b_artifacts'); root=ashuganj_root();
out=fullfile(root,'tmp','phase5_final_audit',['artifact_test_' char(java.util.UUID.randomUUID())]);
mkdir(out); mkdir(fullfile(out,'plots'));
S=phase5b_tcc(fullfile(out,'plots'),root);
csv=fullfile(out,'test.csv'); put(csv,'value,unit');
code=fullfile(out,'fixture_code.m'); put(code,'% isolated hash fixture');
files={'test.csv','plots/tcc_study.png','plots/tcc_physical.png','plots/tcc_metadata.json'};
h=struct('file',{},'sha256',{});
for i=1:numel(files), h(i)=struct('file',files{i},'sha256',phase5b_sha256(fullfile(out,files{i}))); end
codename=strrep(code(numel(root)+2:end),'\','/');
m=struct('testCounts',struct('runner','run_phase5b_tests()','NP',1,'NF',0), ...
 'outputHashes',h,'codeHashes',struct('file',codename,'sha256',phase5b_sha256(code)), ...
 'inputHashes',struct('path',{},'sha256',{}),'tccPlots', ...
 struct('study_png',files{2},'physical_png',files{3},'study_sha256',h(2).sha256,'physical_sha256',h(3).sha256));
put(fullfile(out,'manifest.json'),jsonencode(m));
put(fullfile(out,'sha256.txt'),[phase5b_sha256(fullfile(out,'manifest.json')) '  manifest.json']);
T=T.chk(phase5b_verify_artifacts(out)>0,'valid manifest, code and TCC hashes accepted');
for path={csv,fullfile(out,'plots','tcc_study.png'),fullfile(out,'plots','tcc_physical.png'),code}
 fid=fopen(path{1},'r'); bytes=fread(fid,Inf,'*uint8'); fclose(fid);
 fid=fopen(path{1},'a'); fwrite(fid,uint8(32),'uint8'); fclose(fid);
 rejected=false;
 try, phase5b_verify_artifacts(out); catch ME, rejected=strcmp(ME.identifier,'phase5b_artifacts:hash'); end
 T=T.chk(rejected,['byte mutation rejected: ' path{1}]);
 fid=fopen(path{1},'w'); fwrite(fid,bytes,'uint8'); fclose(fid);
end
T=T.chk(phase5b_verify_artifacts(out)>0,'restored artifacts verify again');
src=fileread(which('run_phase5b_production'));
T=T.chk(contains(src,'[NP, NF] = run_phase5b_tests()')&&~contains(src,'= run_phase5_tests()'),'production invokes Phase-5b runner only');
T=T.chk(strfind(src,'phase5b_finalize_manifest(out,meta)')<strfind(src,'phase5b_verify_artifacts(out)'), ...
 'production verifies final artifact hashes after finalization');
T=T.chk(S.reference_voltage_kV==230,'final TCC metadata records physical reference base');
[np,nf]=T.done();
end
function put(p,s)
fid=fopen(p,'w'); assert(fid>=0); fprintf(fid,'%s\n',s); fclose(fid);
end
