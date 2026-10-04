% Complete missing presentation exports from saved simulation data; no sim.
% Prior scenario jobs save variables out and info in simulation_data.mat.
p6expRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(p6expRoot,'scripts'));
p6expLog=fullfile(p6expRoot,'logs','resume_20260924');
diary(fullfile(p6expLog,'export_remaining.log'));
p6expCleanup=onCleanup(@()diary('off'));
p6expNames={'01_voltage_frequency','02_speed_power','03_fault_waveforms', ...
    '04_protection_breakers','05_station_dc'};
p6expRequired={'scenario_metadata.json'};
for p6expK=1:numel(p6expNames)
    p6expRequired(end+1:end+2)={[p6expNames{p6expK} '.png'],[p6expNames{p6expK} '.pdf']};
end
p6expDirs=dir(fullfile(p6expRoot,'results'));
p6expCount=0;p6expExisting=0;p6expScenarios={};
for p6expK=1:numel(p6expDirs)
    if ~p6expDirs(p6expK).isdir || startsWith(p6expDirs(p6expK).name,'.'),continue;end
    p6expDest=fullfile(p6expDirs(p6expK).folder,p6expDirs(p6expK).name);
    p6expMat=fullfile(p6expDest,'simulation_data.mat');
    if ~isfile(p6expMat),continue;end
    p6expScenarios{end+1}=p6expDirs(p6expK).name;
    p6expComplete=true;
    for p6expJ=1:numel(p6expRequired)
        p6expFile=dir(fullfile(p6expDest,p6expRequired{p6expJ}));
        p6expComplete=p6expComplete&&~isempty(p6expFile)&&p6expFile.bytes>0;
    end
    if p6expComplete,p6expExisting=p6expExisting+1;continue;end
    fprintf('EXPORT_SAVED_START %s\n',p6expDirs(p6expK).name);
    p6expVariables=whos('-file',p6expMat);
    assert(all(ismember({'out','info'},{p6expVariables.name})), ...
        'Phase6:MissingSavedVariables','Saved scenario must contain out and info: %s',p6expMat);
    p6expSaved=load(p6expMat,'out','info');
    assert(isa(p6expSaved.out,'Simulink.SimulationOutput'));
    assert(strcmp(char(p6expSaved.info.scenario.name),p6expDirs(p6expK).name), ...
        'Phase6:ScenarioDirectoryMismatch','Saved scenario name differs from its directory.');
    p6expResult=export_phase6_results(p6expSaved.out,p6expSaved.info,p6expDest);
    for p6expJ=1:numel(p6expRequired)
        p6expFile=dir(fullfile(p6expDest,p6expRequired{p6expJ}));
        assert(~isempty(p6expFile)&&p6expFile.bytes>0, ...
            'Phase6:IncompleteExport','Missing or empty output: %s',p6expRequired{p6expJ});
    end
    p6expCount=p6expCount+1;
    fprintf('EXPORT_SAVED_PASS %s\n',p6expDirs(p6expK).name);
    clear p6expSaved p6expResult;
end
assert(~isempty(p6expScenarios),'Phase6:NoSavedScenarios','No saved simulation_data.mat files found.');
p6expReport=struct('success',true,'exported',p6expCount,'already_complete',p6expExisting, ...
    'total_scenarios',numel(p6expScenarios),'scenarios',{p6expScenarios}, ...
    'completed_at',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z''')));
p6expFid=fopen(fullfile(p6expLog,'export_remaining.done.json'),'w');
assert(p6expFid>=0);fprintf(p6expFid,'%s\n',jsonencode(p6expReport,'PrettyPrint',true));fclose(p6expFid);
fprintf('EXPORT_REMAINING_DONE exported=%d existing=%d total=%d\n', ...
    p6expCount,p6expExisting,numel(p6expScenarios));
clear p6expCleanup;
clear p6exp*;
