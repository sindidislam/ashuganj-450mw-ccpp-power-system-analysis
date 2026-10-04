function info = build_phase6_model(varargin)
%BUILD_PHASE6_MODEL Rebuild the isolated dynamic Ashuganj South study model.
% Never writes the original simulink/ or Phase 1-5 trees.
ip = inputParser;
ip.addParameter('SavePath','',@(x)ischar(x)||isstring(x));
ip.addParameter('Close',false,@(x)islogical(x)&&isscalar(x));
ip.addParameter('Scenario',struct(),@isstruct);
ip.parse(varargin{:});

phase6 = fileparts(fileparts(mfilename('fullpath')));
setup_phase6_workspace();
mdl = 'PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL';
savePath = char(ip.Results.SavePath);
if isempty(savePath)
    savePath = fullfile(phase6,'model',[mdl '.slx']);
end
% Canonical paths block any accidental write through a relative path or junction.
base = char(java.io.File(phase6).getCanonicalPath());
dest = char(java.io.File(savePath).getCanonicalPath());
if ~startsWith(lower(dest),[lower(base) filesep]) || ...
        startsWith(lower(dest),[lower(base) filesep 'source_clone' filesep]) || ...
        ~strcmpi([mdl '.slx'],extractAfter(dest,find(dest==filesep,1,'last')))
    error('Phase6:UnsafeOutput','SavePath must be the Phase 6 model file outside source_clone: %s',dest);
end

P = init_phase6_parameters();
S = phase6_normalize_scenario(P,ip.Results.Scenario);

if bdIsLoaded(mdl), bdclose(mdl); end
new_system(mdl);
cleanup = onCleanup(@()closeOnError(mdl));
load_system(mdl);
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'StartTime','0','StopTime',num2str(S.stopTime_s),'FixedStep',num2str(P.TsElectrical,15), ...
    'SaveTime','on','TimeSaveName','tout','SaveOutput','off', ...
    'SignalLogging','on','SignalLoggingName','logsout');
pg = add_block('sps_lib/powergui',[mdl '/powergui'], ...
    'Position',[45 85 150 125]);
set_param(pg,'SimulationMode','Discrete','SampleTime',num2str(P.TsElectrical,15),'frequency','50', ...
    'frequencyindice','50','Pbase','100e6','ErrMax','1e-7');

mw = get_param(mdl,'ModelWorkspace');
assignin(mw,'P',P);
assignin(mw,'S',S);

net = phase6_add_network(mdl,P,S);
% Solve against the physical breaker initial states and direct machine inputs.
keys={'GCB','Q0','LineLocal','LineRemote','GAT'}; temporary={};
for k=1:5
    c=[mdl '/LF initial ' keys{k}];g=[mdl '/LF command ' keys{k}];
    add_block('simulink/Sources/Constant',c,'Value',num2str(k<5||S.GAT_in));
    add_block('simulink/Signal Routing/Goto',g,'GotoTag',['P6_BR_' keys{k}],'TagVisibility','global');
    hc=get_param(c,'PortHandles');hg=get_param(g,'PortHandles');add_line(mdl,hc.Outport,hg.Inport);
    temporary(end+1:end+2)={c,g};
end
LF=power_loadflow(mdl,'solve');
assert(LF.status==1,'Phase6:LoadFlow','Physical network load-flow initialization did not converge.');
for k=1:2:numel(temporary)
    h=get_param(temporary{k},'PortHandles');ln=get_param(h.Outport,'Line');if ln~=-1,delete_line(ln);end
    delete_block(temporary{k});delete_block(temporary{k+1});
end
ctrl = phase6_add_controls(mdl,P,S,net,LF);
assignin(mw,'Phase6LoadFlow',LF);
titleNote = Simulink.Annotation([mdl '/phase6_title']);
titleNote.Text = sprintf('ASHUGANJ SOUTH\n450 MW combined-cycle power plant');
titleNote.Position = [255 -50];
titleNote.FontSize = 16;
titleNote.FontWeight = 'bold';
titleNote.BackgroundColor = 'transparent';
statusNote = Simulink.Annotation([mdl '/phase6_status']);
statusNote.Text = sprintf('Dynamic study  |  %g MW  |  50 Hz\nDouble-click equipment to open its subsystem.',S.dispatch_MW);
statusNote.Position = [1090 15];
statusNote.FontSize = 10;
statusNote.BackgroundColor = 'transparent';

% Find the owning Phase6 tree even for a saved scenario below results/.
% The old fixed two-parent callback incorrectly selected results/scripts.
set_param(mdl,'PostLoadFcn', [ ...
    'p6startupdir=fileparts(get_param(bdroot,''FileName'')); ' ...
    'while ~isfile(fullfile(p6startupdir,''scripts'',''setup_phase6_workspace.m'')), ' ...
    'p6startupparent=fileparts(p6startupdir); ' ...
    'assert(~strcmp(p6startupparent,p6startupdir),''Phase6:MissingScripts'',''Cannot locate the Phase6 scripts folder.''); ' ...
    'p6startupdir=p6startupparent; end; ' ...
    'addpath(fullfile(p6startupdir,''scripts'')); setup_phase6_workspace; ' ...
    'clear p6startupdir p6startupparent;']);
info = struct('model',mdl,'path',dest,'scenario',S,'network',net,'controls',ctrl,'loadflow',LF);
assignin(mw,'Phase6BuildInfo',info);
if exist('style_phase6_model','file')==2
    style_phase6_model(mdl);
end
set_param(mdl,'SimulationCommand','update');
save_system(mdl,dest);
if ip.Results.Close, close_system(mdl,0); end
clear cleanup
end

function closeOnError(mdl)
% Keep the generated model visible on successful interactive builds; on a
% failed build, discard the partial unsaved in-memory model.
if bdIsLoaded(mdl) && ~strcmp(get_param(mdl,'Dirty'),'off')
    close_system(mdl,0);
end
end
