function [np,nf]=test_phase5b_report()
% Generate a report from real numerical tables in an isolated fixture root.
% Fixture test counts cannot overwrite or masquerade as production results.
T=t_case('test_phase5b_report');projectRoot=ashuganj_root();
root=fullfile(tempdir,['phase5b_report_' char(java.util.UUID.randomUUID())]);
out=fullfile(root,'results','phase5_protection_v2');mkdir(out);
cleanup=onCleanup(@()rmdir(root,'s')); %#ok<NASGU>
R=phase5b_registry();Ti=phase5_import(projectRoot);B=phase5b_cached_branches(Ti);
M=phase5b_coord(R.devices,Ti,B);D=phase5b_duty(Ti,[],B);E=phase5b_effectiveness(Ti,R.devices,B);
[P,A]=phase5b_parameters();Sensitivity=phase5b_sensitivity_v2(Ti,R.devices,R);V=phase5b_validate();
bundle=struct('coordMatrix',M,'duty',D,'effectiveness',E,'sensitivity',Sensitivity, ...
 'validation',table([V.legs.pass]','VariableNames',{'pass'}));
meta=struct('tag','TEST-FIXTURE','reportRoot',root,'testCounts',struct('NP',1,'NF',0));
keep=ismember({R.devices.device_id},{'GEN-51','GEN-51N','GSUT-HV-51','GIS-Q0-51'});d=R.devices(keep);
settings=table({d.device_id}',[d.pickup_A]',[d.ct_ratio]',([d.pickup_A]./[d.ct_ratio])', ...
 'VariableNames',{'device_id','setting_A_primary','ct_ratio','setting_A_secondary'});
writetable(settings,fullfile(out,'phase5_relay_settings.csv'));
phase5b_final_reports(out,bundle,P,A,meta);
rep=fileread(fullfile(root,'docs','PHASE5_FINAL_REPORT.md'));
T=T.chk(strcmp(rep,fileread(fullfile(root,'PHASE5_FINAL_REPORT.md'))),'root and docs final report are synchronized');
T=T.chk(contains(rep,'READY_FOR_REVIEW')&&contains(rep,'preliminary engineering study'),'report identifies engineering review status and study scope');
np=sum(strcmp(M.scope,'PRIMARY')&strcmp(M.verdict,'PASS'));
nc=sum(strcmp(M.verdict,'CONDITIONAL-PASS'));nfault=sum(strcmp(M.verdict,'FAIL'));
nt=sum(strcmp(M.verdict,'NO-TRIP'));nx=sum(strcmp(M.verdict,'NO-PAIR'));
summary=sprintf('%d PRIMARY PASS; %d CONDITIONAL-PASS; %d FAIL; %d NO-TRIP; %d NO-PAIR (%d total matrix rows).',np,nc,nfault,nt,nx,height(M));
T=T.chk(contains(rep,summary),'reported coordination counts match current physical-current calculations');
q=strcmp(D.breaker_ref,'Q0')&~strcmp(D.verdict,'NOTE');g=strcmp(D.breaker_ref,'52G')&~strcmp(D.verdict,'NOTE');
qmax=max(D.I_sym_kA(q));gmax=max(D.I_sym_kA(g));
duty=sprintf('Q0: maximum %.6f kA / 50 kA = %.6f. 52G: maximum %.6f kA / 100 kA = %.6f. %d duty exceedances.',qmax,qmax/50,gmax,gmax/100,sum(strcmp(D.verdict,'FAIL')));
T=T.chk(contains(rep,duty),'reported maximum duty excludes the fault-system NOTE and uses physical branch ratios');
T=T.chk(qmax<7&&contains(rep,'Ib')&&contains(rep,'Ikpp'),'report distinguishes physical initial-current screening from breaking-time duty');
central=~strcmp(E.scope,'SENSITIVITY');
eff=sprintf('%d central rows: %d CONDITIONAL-DETECTABILITY, %d NO-TRIP, %d NO-PAIR/OUT-OF-ZONE; %d separate DT sensitivity rows.', ...
 sum(central),sum(central&contains(E.detection,'DETECTABILITY')),sum(central&strcmp(E.detection,'NO-TRIP')),sum(central&contains(E.detection,'OUT-OF-ZONE')),sum(~central));
T=T.chk(contains(rep,eff),'effectiveness summary separates central results from DT sensitivity twins');
S=readtable(fullfile(out,'phase5_relay_settings.csv'),'Delimiter',',');
map={'GEN-51','GEN-51';'GEN-51N','GEN-51N';'GSUT-51','GSUT-HV-51';'Q0-51','GIS-Q0-51'};
for k=1:size(map,1)
 pattern=['(?m)^\|\s*' regexptranslate('escape',map{k,1}) '\s*\|\s*([0-9.]+)\s*A\s*\|\s*([0-9]+)/1\s*\|\s*([0-9.]+)\s*A'];
 match=regexp(rep,pattern,'tokens','once');j=strcmp(S.device_id,map{k,2});
 if isempty(match)||sum(j)~=1
  T=T.chk(false,[map{k,1} ' report and CSV setting rows are present']);
 else
  got=str2double(match);want=[S.setting_A_primary(j),S.ct_ratio(j),S.setting_A_secondary(j)];
  T=T.chk(all(abs(got-want)<1e-8),[map{k,1} ' report primary/CT/secondary values match exported settings']);
 end
end
T=T.chk(contains(rep,'1500/1')&&contains(rep,'1600/1')&&contains(rep,'unverified'),'CT documentary conflict remains disclosed beside the numerical study');
T=T.chk(contains(rep,'87G')&&contains(rep,'87T')&&contains(rep,'87B')&&contains(rep,'7SD5221')&&contains(rep,'proxies'),'differential study roles and timing limitations remain explicit');
T=T.chk(contains(rep,'0.20-A secondary')&&contains(rep,'2/4/5-A primary')&&contains(rep,'4/5-A pickup'),'report distinguishes fixed-secondary CT sensitivity from fixed-CT pickup sensitivity');
for name={'PHASE5_VALIDATION_REPORT.md','PHASE5_AI_HANDOFF.md'}
 doc=fileread(fullfile(root,'docs',name{1}));
 T=T.chk(strcmp(doc,fileread(fullfile(root,name{1})))&&contains(doc,summary),[name{1} ' is synchronized and carries the same live coordination summary']);
end
[np,nf]=T.done();
end
