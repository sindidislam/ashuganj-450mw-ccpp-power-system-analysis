paths=setup_phase6_workspace();clear phase6_add_network phase6_electrical_profile;rehash;
P=init_phase6_parameters();S=P.scenario;S.dispatch_MW=360;
mdl='P6_NETWORK_TEST';if bdIsLoaded(mdl),close_system(mdl,0);end;new_system(mdl);
add_block('sps_lib/powergui',[mdl '/powergui']);set_param([mdl '/powergui'],'SimulationMode','Discrete','SampleTime','50e-6','frequency','50','frequencyindice','50','ErrMax','1e-7');
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','50e-6','StopTime','0.05');
net=phase6_add_network(mdl,P,S);
keys={'GCB','Q0','LineLocal','LineRemote','GAT'};
for k=1:5
    c=[mdl '/Initial ' keys{k}];add_block('simulink/Sources/Constant',c,'Value',num2str(k~=5));
    go=[mdl '/Command ' keys{k}];add_block('simulink/Signal Routing/Goto',go,'GotoTag',['P6_BR_' keys{k}],'TagVisibility','global');
    hc=get_param(c,'PortHandles');hg=get_param(go,'PortHandles');add_line(mdl,hc.Outport,hg.Inport);
end
lf=power_loadflow(mdl,'solve');assert(lf.status==1);disp(lf.sm);disp(lf.bus);
set_param(mdl,'SimulationCommand','update');out=sim(mdl,'ReturnWorkspaceOutputs','on');disp(out);
save(fullfile(paths.phase6,'logs','network_probe.mat'),'lf','net');
fprintf('NETWORK_COMPILE_AND_SIM_PASS\n');
