function result = export_phase6_results(out,info,outputDir)
%EXPORT_PHASE6_RESULTS Export only actual dynamic simulation logs into Phase6/results.
% RESULT = export_phase6_results(OUT,INFO,OUTPUTDIR) writes labeled CSV files,
% the original SimulationOutput and metadata in MAT, metadata JSON, and five
% figures in PNG/PDF. INFO is the build_phase6_model result. No model is run.
% OUTPUTDIR must resolve canonically inside this project's Phase6/results.

phase6=fileparts(fileparts(mfilename('fullpath')));
phase6=char(java.io.File(phase6).getCanonicalPath());
base=char(java.io.File(fullfile(phase6,'results')).getCanonicalPath());
assert(startsWith(lower(base),[lower(phase6) filesep]), ...
    'Phase6:UnsafeOutput','Phase6/results must resolve inside the Phase6 workspace.');
if nargin<3||isempty(outputDir)
    name=regexprep(char(string(info.scenario.name)),'[^A-Za-z0-9_-]','_');
    outputDir=fullfile(base,name);
end
destination=char(java.io.File(char(outputDir)).getCanonicalPath());
assert(strcmpi(destination,base)||startsWith(lower(destination),[lower(base) filesep]), ...
    'Phase6:UnsafeOutput','Results must be written inside %s.',base);
assert(isa(out,'Simulink.SimulationOutput'),'Phase6:ProductionDataRequired', ...
    'Production exports require a Simulink.SimulationOutput. Unit-test fixtures belong in table-layer tests.');
phase6_assert_complete_run(out,info.scenario);
[tables,signals,metadata]=phase6_result_tables(out,info);
if ~isfolder(destination),mkdir(destination);end
% Recheck after directory creation to detect junction/path redirection.
destination=char(java.io.File(destination).getCanonicalPath());
assert(strcmpi(destination,base)||startsWith(lower(destination),[lower(base) filesep]), ...
    'Phase6:UnsafeOutput','The resolved output directory escapes Phase6/results.');
metadata.exportedAt=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
metadata.model=info.model;
metadata.modelFile=info.path;
metadata.relayParameters=info.controls.relayParameters;
metadata.networkParameters=info.network.profile;
if isfield(info,'machineParameters'),metadata.machineParameters=info.machineParameters;end
metadata.outputDirectory=destination;
metadata.matFile='simulation_data.mat';
metadata.jsonNonfiniteEncoding='JSON null may represent NaN/Inf; MAT and CSV preserve numeric values and event status columns explain missing events.';
if isfield(info,'loadflow')&&isstruct(info.loadflow)&&isfield(info.loadflow,'status')
    metadata.loadflowStatus=info.loadflow.status;
end
tableNames=fieldnames(tables);files=cell(0,1);
for k=1:numel(tableNames)
    path=safeFile(destination,[tableNames{k} '.csv'],base);
    writetable(tables.(tableNames{k}),path);files{end+1,1}=path; %#ok<AGROW>
end
dataPath=safeFile(destination,'simulation_data.mat',base);
save(dataPath,'out','info','signals','tables','metadata','-v7.3');
files{end+1,1}=dataPath;
jsonPath=safeFile(destination,'scenario_metadata.json',base);
fid=fopen(jsonPath,'w','n','UTF-8');assert(fid>=0,'Phase6:ResultWrite','Cannot write %s.',jsonPath);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(metadata,'PrettyPrint',true));clear cleanup
files{end+1,1}=jsonPath;

name=char(string(info.scenario.name));
S=info.scenario;sm=signals.summary;valid=sm.time>=.020;
t=sm.time(valid);summary=sm.data(valid,:);
assert(~isempty(t),'Phase6:ShortRecord','Plots require samples at or after 20 ms.');
fig=newFigure('Voltage and frequency',name,1150);
tl=tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');
voltageColumns=[3 9 21];voltageLabels={'Generator V_{LL} (kV)','230 kV bus V_{LL} (kV)','Auxiliary V_{LL} (kV)'};
for k=1:3
    ax=nexttile(tl);plot(ax,t,summary(:,voltageColumns(k)),'LineWidth',1.25);
    ylabel(ax,voltageLabels{k},'Interpreter','tex');decorate(ax,S);
end
ax=nexttile(tl);plot(ax,t,summary(:,5),'LineWidth',1.25);
ylabel(ax,'Frequency (Hz)');xlabel(ax,'Simulation time (s)');decorate(ax,S);
title(tl,[name ' | voltage and frequency'],'Interpreter','none');
files=[files;saveFigure(fig,destination,'01_voltage_frequency')];

fig=newFigure('Machine speed and power',name,1050);
tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);plot(ax,t,summary(:,6),'LineWidth',1.25);ylabel(ax,'Rotor speed (pu)');decorate(ax,S);
ax=nexttile(tl);plot(ax,t,summary(:,[1 22]),'LineWidth',1.25);ylabel(ax,'Active power (MW)');
legend(ax,{'Generator','Grid CT direction'},'Location','best');decorate(ax,S);
ax=nexttile(tl);plot(ax,t,summary(:,[2 23]),'LineWidth',1.25);ylabel(ax,'Reactive power (MVAr)');
legend(ax,{'Generator','Grid CT direction'},'Location','best');xlabel(ax,'Simulation time (s)');decorate(ax,S);
title(tl,[name ' | rotor and electrical power'],'Interpreter','none');
files=[files;saveFigure(fig,destination,'02_speed_power')];

sensorNames=string(info.controls.sensorNames(:));
faultSensor=string(metadata.faultMeasurement.sensor);sensor=find(sensorNames==faultSensor,1);
raw=signals.raw;rmsData=signals.rms;
plotStart=.020;plotEnd=raw.time(end);
if S.faultEnabled
    plotStart=max(.020,S.faultStart_s-.040);
    plotEnd=min(raw.time(end),S.faultStart_s+max(.160,min(S.faultDuration_s+.040,.400)));
end
if plotEnd<=plotStart,plotStart=.020;plotEnd=raw.time(end);end
ri=raw.time>=plotStart&raw.time<=plotEnd;mi=rmsData.time>=plotStart&rmsData.time<=plotEnd;
fig=newFigure('Fault branch waveforms',name,1050);
tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);plot(ax,raw.time(ri),raw.data(ri,(sensor-1)*6+(1:3))/1000,'LineWidth',1.05);
ylabel(ax,'Instantaneous phase voltage (kV)');legend(ax,{'A','B','C'},'Location','best');decorate(ax,S);
ax=nexttile(tl);plot(ax,raw.time(ri),raw.data(ri,(sensor-1)*6+(4:6))/1000,'LineWidth',1.05);
ylabel(ax,'Instantaneous branch current (kA)');legend(ax,{'A','B','C'},'Location','best');decorate(ax,S);
ax=nexttile(tl);plot(ax,rmsData.time(mi),rmsData.data(mi,(sensor-1)*6+(4:6))/1000,'LineWidth',1.25);
ylabel(ax,'Sliding waveform RMS current (kA)');legend(ax,{'A','B','C'},'Location','best');
xlabel(ax,'Simulation time (s)');decorate(ax,S);
caption=[name ' | measured ' char(faultSensor) ' branch'];
if ~S.faultEnabled,caption=[caption ' | fault disabled'];end
title(tl,caption,'Interpreter','none');
files=[files;saveFigure(fig,destination,'03_fault_waveforms')];

relay=signals.relay;br=signals.breakers;relays={'GEN51','GSUT51','GEN51N','87G','87T','87B','87L'};
fig=newFigure('Protection and breaker commands',name,1250);
tl=tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);digital(ax,relay,1:7,relays);ylabel(ax,'Pickup');decorate(ax,S);
ax=nexttile(tl);digital(ax,relay,8:14,relays);ylabel(ax,'Trip request');decorate(ax,S);
ax=nexttile(tl);digital(ax,br,1:5,{'GCB','Q0','Local','Remote','GAT'});ylabel(ax,'Closed command');decorate(ax,S);
ax=nexttile(tl);mask=relay.time>=.020;plot(ax,relay.time(mask),relay.data(mask,29:31),'LineWidth',1.2);
ylabel(ax,'Relay secondary current (A)');legend(ax,{'GEN51 max phase','GSUT51 max phase','GEN51N neutral'},'Location','best');
xlabel(ax,'Simulation time (s)');decorate(ax,S);
title(tl,[name ' | logged protection and commands (not contact feedback)'],'Interpreter','none');
files=[files;saveFigure(fig,destination,'04_protection_breakers')];

dc=signals.dc;mask=dc.time>=.020;td=dc.time(mask);dd=dc.data(mask,:);
fig=newFigure('Station DC response',name,1200);
tl=tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);plot(ax,td,dd(:,1),'LineWidth',1.25);ylabel(ax,'DC bus voltage (V)');decorate(ax,S);
ax=nexttile(tl);plot(ax,td,dd(:,2:4),'LineWidth',1.2);ylabel(ax,'DC current (A)');
legend(ax,{'Battery (+ discharge)','Charger','Load'},'Location','best');decorate(ax,S);
ax=nexttile(tl);plot(ax,td,100*dd(:,5),'LineWidth',1.25);ylabel(ax,'Battery SOC (%)');decorate(ax,S);
ax=nexttile(tl);digital(ax,dc,6:10,{'Healthy','Low V','Battery low','Charger fail','Trip unavailable'});
ylabel(ax,'DC indications');xlabel(ax,'Simulation time (s)');decorate(ax,S);
title(tl,[name ' | station DC supply'],'Interpreter','none');
files=[files;saveFigure(fig,destination,'05_station_dc')];

result=struct('outputDir',destination,'files',{files},'tables',tables,'metadata',metadata);
fprintf('PHASE6_EXPORT_PASS: %s; %d CSV tables; 5 PNG/PDF figures; original simulation MAT.\n', ...
    destination,numel(tableNames));
end

function fig=newFigure(label,scenario,height)
fig=figure('Visible','off','Color','white','Name',[scenario ' | ' label], ...
    'Renderer','painters', ...
    'Units','pixels','Position',[100 100 1250 height]);
set(fig,'DefaultAxesFontName','Arial','DefaultAxesFontSize',11, ...
    'DefaultAxesLineWidth',.8,'DefaultTextInterpreter','none', ...
    'DefaultLegendInterpreter','none','DefaultAxesColorOrder', ...
    [0 .35 .65;.82 .25 .12;.15 .56 .32;.55 .30 .70;.82 .60 .05;.15 .60 .65;.35 .35 .35]);
end

function decorate(ax,S)
grid(ax,'on');box(ax,'off');ax.GridAlpha=.16;
if S.faultEnabled
    limits=xlim(ax);
    if S.faultStart_s>=limits(1)&&S.faultStart_s<=limits(2)
        xline(ax,S.faultStart_s,'--','Fault on','Color',[.25 .25 .25], ...
            'LabelVerticalAlignment','bottom','HandleVisibility','off');
    end
end
end

function digital(ax,d,columns,names)
mask=d.time>=.020;offset=(0:numel(columns)-1)*1.4;
stairs(ax,d.time(mask),double(d.data(mask,columns)>.5)+offset,'LineWidth',1.1);
yticks(ax,offset+.5);yticklabels(ax,names);ylim(ax,[-.2 offset(end)+1.2]);
end

function files=saveFigure(fig,destination,name)
cleanup=onCleanup(@()close(fig)); %#ok<NASGU>
phase6=fileparts(fileparts(mfilename('fullpath')));
base=char(java.io.File(fullfile(phase6,'results')).getCanonicalPath());
png=safeFile(destination,[name '.png'],base);pdf=safeFile(destination,[name '.pdf'],base);
exportgraphics(fig,png,'Resolution',220);
exportgraphics(fig,pdf,'ContentType','image','Resolution',220);
files={png;pdf};
end

function path=safeFile(destination,name,base)
path=char(java.io.File(fullfile(destination,name)).getCanonicalPath());
assert(startsWith(lower(path),[lower(base) filesep]), ...
    'Phase6:UnsafeOutput','Output file resolves outside Phase6/results: %s',path);
end
