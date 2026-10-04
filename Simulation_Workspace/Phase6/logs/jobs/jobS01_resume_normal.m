% Fresh-session recovery, component tests, and a measured integrated run.
phase6root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(phase6root,'scripts'));
addpath(fullfile(phase6root,'scripts','tests'));
paths = setup_phase6_workspace();
fprintf('RESUME_MATLAB %s\n',version);
tests = {@test_phase6_parameters,@test_phase6_measurement, ...
    @test_phase6_relays,@test_phase6_dc,@test_phase6_actuators, ...
    @test_phase6_protection_sfunctions};
for testIndex=1:numel(tests)
    fprintf('TEST_START %s\n',func2str(tests{testIndex}));
    feval(tests{testIndex});
    fprintf('TEST_PASS %s\n',func2str(tests{testIndex}));
end
info = build_phase6_model('Scenario',struct('stopTime_s',.4));
fprintf('FRESH_INTEGRATED_BUILD_PASS\n');
out = sim(info.model,'ReturnWorkspaceOutputs','on');
save(fullfile(paths.phase6,'logs','integrated_normal.mat'),'info','out','-v7.3');
q=out.phase6_summary; idx=q.Time>.2;
disp(array2table(mean(q.Data(idx,:),1),'VariableNames',info.controls.summaryNames));
r=out.phase6_relay;disp(max(r.Data(:,1:14),[],1));
assert(all(isfinite(q.Data),'all'),'Nonfinite model measurements');
assert(max(abs(q.Data(idx,3)-22))<.1,'Generator voltage drift');
assert(max(abs(q.Data(idx,5)-50))<.01,'Machine speed drift');
assert(max(abs(q.Data(idx,1)-360))<1,'Generator active power drift');
assert(~any(r.Data(:,8:14),'all'),'Spurious normal relay trip');
fprintf('INTEGRATED_NORMAL_SIM_PASS\n');
print(['-s' info.model],'-dpng','-r120',fullfile(paths.phase6,'logs','master_before_style.png'));
result = export_phase6_results(out,info);
disp(result);
fprintf('NORMAL_EXPORT_PASS\n');
