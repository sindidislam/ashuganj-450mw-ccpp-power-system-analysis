clear phase6_add_network phase6_electrical_profile
rehash
paths=setup_phase6_workspace(); mdl='P6_NETWORK_TEST';
assert(bdIsLoaded(mdl),'Network fixture from jobN_network02 must be loaded.');
load(fullfile(paths.phase6,'logs','network_probe.mat'),'net','lf');
tags={'genTerminal_V','genTerminal_I','aux_V','aux_I','grid_V','grid_I','neutral_I'};
for k=1:numel(tags)
    f=[mdl '/Probe From ' tags{k}]; w=[mdl '/Probe Log ' tags{k}];
    add_block('simulink/Signal Routing/From',f,'GotoTag',['P6_' tags{k}]);
    add_block('simulink/Sinks/To Workspace',w,'VariableName',['probe_' tags{k}],'SaveFormat','Structure With Time');
    hf=get_param(f,'PortHandles'); hw=get_param(w,'PortHandles'); add_line(mdl,hf.Outport,hw.Inport);
end
f=[mdl '/Probe Machine From']; bs=[mdl '/Probe Machine Select']; mux=[mdl '/Probe Machine Mux']; ws=[mdl '/Probe Machine Log'];
add_block('simulink/Signal Routing/From',f,'GotoTag','P6_MACHINE');
add_block('simulink/Signal Routing/Bus Selector',bs,'OutputSignals','w,Peo,Qeo');
add_block('simulink/Signal Routing/Mux',mux,'Inputs','3');
add_block('simulink/Sinks/To Workspace',ws,'VariableName','probe_machine','SaveFormat','Structure With Time');
hf=get_param(f,'PortHandles'); hb=get_param(bs,'PortHandles'); hm=get_param(mux,'PortHandles'); hw=get_param(ws,'PortHandles');
add_line(mdl,hf.Outport,hb.Inport);
for k=1:3,add_line(mdl,hb.Outport(k),hm.Inport(k));end
add_line(mdl,hm.Outport,hw.Inport);
set_param(net.pmInitial,'Value',mat2str(lf.sm.Pmec/lf.sm.Pnom,15));
set_param(net.vfInitial,'Value',mat2str(lf.sm.Vf,15));
set_param(mdl,'StopTime','0.2');
set_param(mdl,'SimulationCommand','update');out=sim(mdl,'ReturnWorkspaceOutputs','on');
t=out.probe_genTerminal_V.time; idx=t>.16 & t<=.2;
V=out.probe_genTerminal_V.signals.values(idx,:); I=out.probe_genTerminal_I.signals.values(idx,:);
vn=sqrt(mean(V.^2,1)); genP=mean(sum(V.*I,2));
N=out.probe_neutral_I.signals.values(idx,1); nrms=sqrt(mean(N.^2));
machine=out.probe_machine.signals.values;
assert(all(isfinite([V(:);I(:);machine(:);N(:)])),'Nonfinite normal measurements.');
assert(all(vn>12000 & vn<13400),'Normal terminal voltage outside 0.95-1.05pu.');
assert(genP>350e6 && genP<370e6,'Normal generator power differs materially from 360MW.');
assert(max(abs(machine(:,1)-1))<.01,'Machine speed departed by more than 1 percent.');
assert(nrms<.05,'Unexpected normal generator neutral current.');
fprintf('NORMAL_02_PASS Vrms=[%g %g %g] V P=%.9gMW neutral=%.9gA maxSpeedError=%.9gpu\n',vn,genP/1e6,nrms,max(abs(machine(:,1)-1)));
save(fullfile(paths.phase6,'logs','network_normal_measurements.mat'),'out','lf','net','vn','genP','nrms');
