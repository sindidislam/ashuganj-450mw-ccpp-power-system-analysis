paths=setup_phase6_workspace();
orig=fullfile(paths.project,'simulink','main','Ashuganj_South_Main.slx');
load_system(orig);
oldmdl='Ashuganj_South_Main';
fprintf('ORIGINAL_MODEL %s\n',orig);
bl=find_system(oldmdl,'SearchDepth',1,'Type','Block');
for k=1:numel(bl), fprintf('%s | %s | %s\n',bl{k},get_param(bl{k},'BlockType'),get_param(bl{k},'MaskType'));end
for nm={'PreLoadFcn','PostLoadFcn','InitFcn','StartFcn','StopFcn'},fprintf('%s=%s\n',nm{1},get_param(oldmdl,nm{1}));end
fprintf('ORIGINAL solver=%s mode=%s\n',get_param(oldmdl,'Solver'),get_param([oldmdl '/powergui'],'SimulationMode'));
close_system(oldmdl,0);
probe='P6_CONNECTION_PROBE';new_system(probe);
s=add_block('built-in/Subsystem',[probe '/Generator']);
p=add_block('built-in/PMIOPort',[s '/A']);
disp(get_param(p,'ObjectParameters')); disp(get_param(p,'PortHandles'));
fprintf('Port=%s Side=%s\n',get_param(p,'Port'),get_param(p,'Side'));
close_system(probe,0);
help Simulink.BlockDiagram.createSubsystem
