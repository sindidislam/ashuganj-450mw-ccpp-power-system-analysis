probe='P6_CONNECTION_OPTIONS';new_system(probe);
s=[probe '/Generator']; add_block('built-in/Subsystem',s);
p=add_block('built-in/PMIOPort',[s '/A']);
dp=get_param(p,'ObjectParameters');
for nm={'Port','Side','Orientation','ConnectionType','Position'},if isfield(dp,nm{1}),disp(nm{1});disp(get_param(p,nm{1}));end;end
disp(get_param(p,'PortHandles'));
disp(get_param(s,'PortHandles'));
close_system(probe,0);
help Simulink.BlockDiagram.createSubsystem
