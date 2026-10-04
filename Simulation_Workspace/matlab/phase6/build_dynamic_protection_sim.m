function S=build_dynamic_protection_sim(outDir,root)
%BUILD_DYNAMIC_PROTECTION_SIM Build the measured v4 electrical protection loop.
% S=build_dynamic_protection_sim() or (outDir,root).
% Explicit rebuild resets saved scenario/relay edits to the source defaults.
% outDir must be a subfolder of this installation's Phase6/results.
% No copied model, disconnected hook or synthesized waveform is used.
if nargin<1,outDir=[];end
if nargin<2,root=[];end
paths=phase6_trip_paths(outDir,root);
backup='';
if isfile(paths.file)
    backupDir=fullfile(paths.phase6,'backups');
    if ~isfolder(backupDir),mkdir(backupDir);end
    backup=fullfile(backupDir,['closed_loop_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')) '.slx']);
    copyfile(paths.file,backup);
end
info=build_phase6_model('ModelName',paths.model,'SavePath',paths.file);
c=phase6_interactive_settings(paths.model,'get');
if ~isfolder(paths.output),mkdir(paths.output);end
paths=phase6_trip_paths(paths.output,paths.project);
relay=string({'GEN51';'GSUT51';'GEN51N';'87G';'87T';'87B';'87L'});
pickup=c.R.pickup_A(:);ct=c.R.ctRatio(:);
tms=[string(c.R.tms(:));repmat("not applicable",4,1)];
delay=[repmat("not applicable",3,1);string(c.R.delay_s(:))];
slope1=[repmat("not applicable",3,1);string(c.R.slope1(:))];
slope2=[repmat("not applicable",3,1);string(c.R.slope2(:))];
settings=table(relay,pickup,ct,tms,delay,slope1,slope2, ...
    'VariableNames',{'Relay','Pickup_A_primary','CT_ratio','TMS','Delay_s','Slope1','Slope2'});
params=fullfile(paths.output,'closed_loop_trip_params.csv');writetable(settings,params);
meta=struct('dataOrigin','actual Simulink model build; no simulation claimed by build', ...
    'model',paths.file,'activeProtection',c.R,'scenario',c.S, ...
    'note','Not applicable denotes an unused relay setting. Inf event times mean disabled. 87L adds 5 ms communications allowance to its local delay. New phase5c differential calculators are separate studies.');
metaPath=fullfile(paths.output,'closed_loop_trip_meta.json');
fid=fopen(metaPath,'w','n','UTF-8');assert(fid>=0,'Phase6:Write','Cannot write %s.',metaPath);
cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(meta,'PrettyPrint',true));clear cleanup
S=struct('info',info,'model_dst',paths.file,'params_csv',params, ...
    'meta_json',metaPath,'backup',backup,'sim_mode','measured-simulink');
fprintf('PHASE6_V4_BUILD_PASS %s\n',paths.file);
end
