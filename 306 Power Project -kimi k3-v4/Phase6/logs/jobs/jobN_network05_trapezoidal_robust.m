clear phase6_add_network phase6_electrical_profile
rehash
paths=setup_phase6_workspace(); mdl='P6_NETWORK_TEST';
load(fullfile(paths.phase6,'logs','network_probe.mat'),'net');
set_param(net.generator,'IterativeDiscreteModel','Trapezoidal robust');
fprintf('SOLVER model=%s legacy=%s\n',get_param(net.generator,'IterativeDiscreteModel'),get_param(net.generator,'IterativeModel'));
lf=power_loadflow(mdl,'solve');assert(lf.status==1);
set_param(net.pmInitial,'Value',mat2str(lf.sm.Pmec/lf.sm.Pnom,15));
set_param(net.vfInitial,'Value',mat2str(lf.sm.Vf,15));
set_param(mdl,'StopTime','0.2');
set_param(mdl,'SimulationCommand','update');out=sim(mdl,'ReturnWorkspaceOutputs','on');
t=out.probe_genTerminal_V.time; idx=t>.16 & t<=.2;
V=out.probe_genTerminal_V.signals.values(idx,:); I=out.probe_genTerminal_I.signals.values(idx,:);
vn=sqrt(mean(V.^2,1)); genP=mean(sum(V.*I,2));
N=out.probe_neutral_I.signals.values(idx,1); nrms=sqrt(mean(N.^2));
machine=out.probe_machine.signals.values;
fprintf('ROBUST_DIAG Vrms=%s P=%.9gMW neutral=%.9gA maxSpeedError=%.9gpu\n',mat2str(vn,12),genP/1e6,nrms,max(abs(machine(:,1)-1)));
save(fullfile(paths.phase6,'logs','network_robust_diagnostic.mat'),'out','lf','net','vn','genP','nrms','machine');
assert(all(isfinite([V(:);I(:);machine(:);N(:)])),'Nonfinite normal measurements.');
assert(all(vn>12000 & vn<13400),'Normal terminal voltage outside 0.95-1.05pu.');
assert(genP>350e6 && genP<370e6,'Normal generator power differs materially from 360MW.');
assert(max(abs(machine(:,1)-1))<.01,'Machine speed departed by more than 1 percent.');
assert(nrms<.05,'Unexpected normal generator neutral current.');
fprintf('NETWORK_TRAPEZOIDAL_ROBUST_NORMAL_02_PASS\n');
