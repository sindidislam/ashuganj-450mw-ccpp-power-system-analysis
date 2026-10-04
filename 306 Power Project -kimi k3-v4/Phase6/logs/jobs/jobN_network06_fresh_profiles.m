clear phase6_add_network phase6_electrical_profile init_phase6_parameters
rehash
network_case('PHASE3_BASELINE');
network_case('PHASE5_STUDY');
fprintf('FRESH_NETWORK_PROFILES_LF_NORMAL_02_PASS\n');

function network_case(profile)
paths=setup_phase6_workspace(); P=init_phase6_parameters(); S=P.scenario;
S.dispatch_MW=360; S.networkProfile=profile;
mdl=['P6_NETWORK_' profile]; if bdIsLoaded(mdl),close_system(mdl,0);end;new_system(mdl);
add_block('sps_lib/powergui',[mdl '/powergui']);
set_param([mdl '/powergui'],'SimulationMode','Discrete','SampleTime',mat2str(P.TsElectrical), ...
    'frequency','50','frequencyindice','50','ErrMax','1e-7');
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep',mat2str(P.TsElectrical),'StopTime','0.2');
net=phase6_add_network(mdl,P,S);
assert(numel(net.profile.loads)==3 && abs(sum([net.profile.loads.P_MW])-14)<1e-10);
assert(strcmp(get_param(net.generator,'IterativeDiscreteModel'),'Trapezoidal robust'));
keys={'GCB','Q0','LineLocal','LineRemote','GAT'};
for k=1:5
    c=[mdl '/Initial ' keys{k}];add_block('simulink/Sources/Constant',c,'Value',num2str(k~=5));
    go=[mdl '/Command ' keys{k}];add_block('simulink/Signal Routing/Goto',go,'GotoTag',['P6_BR_' keys{k}],'TagVisibility','global');
    hc=get_param(c,'PortHandles');hg=get_param(go,'PortHandles');add_line(mdl,hc.Outport,hg.Inport);
end
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
lf=power_loadflow(mdl,'solve');assert(lf.status==1);
set_param(net.pmInitial,'Value',mat2str(lf.sm.Pmec/lf.sm.Pnom,15));
set_param(net.vfInitial,'Value',mat2str(lf.sm.Vf,15));
set_param(mdl,'SimulationCommand','update');out=sim(mdl,'ReturnWorkspaceOutputs','on');
t=out.probe_genTerminal_V.time; idx=t>.16 & t<=.2;
V=out.probe_genTerminal_V.signals.values(idx,:); I=out.probe_genTerminal_I.signals.values(idx,:);
vn=sqrt(mean(V.^2,1)); genP=mean(sum(V.*I,2));
N=out.probe_neutral_I.signals.values(idx,1); nrms=sqrt(mean(N.^2));
machine=out.probe_machine.signals.values; speedError=max(abs(machine(:,1)-1));
auxV=sqrt(mean(out.probe_aux_V.signals.values(idx,:).^2,1));
auxP=mean(sum(out.probe_aux_V.signals.values(idx,:).*out.probe_aux_I.signals.values(idx,:),2));
fprintf('%s LFstatus=%d LFgenQ=%.9gMVAr Vrms=%s P=%.9gMW neutral=%.9gA maxSpeedError=%.9gpu AUX_V=%s AUX_P=%.9gMW\n', ...
    profile,lf.status,imag(lf.sm.S)*lf.basePower/1e6,mat2str(vn,12),genP/1e6,nrms,speedError,mat2str(auxV,10),auxP/1e6);
save(fullfile(paths.phase6,'logs',['network_' profile '_normal.mat']),'out','lf','net','vn','genP','nrms','speedError','auxV','auxP');
assert(all(isfinite([V(:);I(:);machine(:);N(:)])),'Nonfinite normal measurements.');
assert(all(vn>12000 & vn<13400),'Normal terminal voltage outside 0.95-1.05pu.');
assert(genP>350e6 && genP<370e6,'Normal generator power differs materially from 360MW.');
assert(speedError<.01,'Machine speed departed by more than 1 percent.');
assert(nrms<.05,'Unexpected normal generator neutral current.');
assert(auxP>13e6 && auxP<15e6,'Auxiliary total differs materially from 14MW.');
fprintf('%s_NORMAL_02_PASS\n',profile);
end
