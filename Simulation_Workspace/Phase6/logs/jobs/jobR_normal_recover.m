paths=setup_phase6_workspace();
if ~exist('out','var') || ~isa(out,'Simulink.SimulationOutput') || ~isprop(out,'phase6_summary')
    info=build_phase6_model('Scenario',struct('stopTime_s',.3));
    out=sim(info.model,'ReturnWorkspaceOutputs','on');
end
save(fullfile(paths.phase6,'logs','integrated_normal.mat'),'info','out','-v7.3');
q=out.phase6_summary;idx=q.Time>.2;disp(array2table(mean(q.Data(idx,:),1),'VariableNames',info.controls.summaryNames));
r=out.phase6_relay;disp(max(r.Data(:,1:14),[],1));
assert(all(isfinite(q.Data),'all'),'Nonfinite model measurements');
assert(max(abs(q.Data(idx,3)-22))<.1,'Generator voltage drift');
assert(max(abs(q.Data(idx,5)-50))<.01,'Machine speed drift');
assert(~any(r.Data(:,8:14),'all'),'Spurious normal relay trip');
fprintf('INTEGRATED_NORMAL_SIM_PASS\n');
print(['-s' info.model],'-dpng','-r120',fullfile(paths.phase6,'logs','master_before_style.png'));
