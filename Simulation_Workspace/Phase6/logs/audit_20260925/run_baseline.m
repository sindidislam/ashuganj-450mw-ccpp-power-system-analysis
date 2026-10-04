% Fresh, read-only baseline of unit logic and the delivered v4 model.
auditRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
projectRoot=fileparts(auditRoot);
addpath(fullfile(auditRoot,'scripts'),fullfile(auditRoot,'scripts','tests'));
setup_phase6_workspace();
addpath(fullfile(projectRoot,'matlab','phase6'),fullfile(projectRoot,'matlab','tests'));
fprintf('AUDIT_ENV %s\n',version);ver;
tests={'test_phase6_parameters','test_phase6_relays','test_phase6_measurement', ...
 'test_phase6_dc','test_phase6_dc_recovery','test_phase6_actuators','test_phase6_protection_sfunctions', ...
 'test_phase5c_differential','test_phase5c_enrichment','test_phase5d_q0_duty'};
for k=1:numel(tests)
 try,feval(tests{k});fprintf('AUDIT_TEST_PASS %s\n',tests{k});
 catch err,fprintf('AUDIT_TEST_FAIL %s\n%s\n',tests{k},getReport(err,'extended','hyperlinks','off'));end
end
target=fullfile(auditRoot,'PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx');
load_system(target);[~,mdl]=fileparts(target);
c=phase6_interactive_settings(mdl,'get');
fprintf('AUDIT_SAVED_MODEL %s\nINFO_MODEL %s\nINFO_PATH %s\n',get_param(mdl,'FileName'),c.info.model,c.info.path);
fprintf('AUDIT_SAVED_SCENARIO %s\n',jsonencode(c.S));
fprintf('AUDIT_HOOK_COUNT %d\n',numel(find_system(mdl,'SearchDepth',1,'Name','CL_TripRelayHook')));
try,phase6_interactive_settings(mdl,'apply',struct('scenario',struct('name','audit_baseline')));
 fprintf('AUDIT_RENAMED_APPLY_PASS\n');
catch err,fprintf('AUDIT_RENAMED_APPLY_FAIL\n%s\n',getReport(err,'extended','hyperlinks','off'));end
close_system(mdl,0);
fprintf('AUDIT_BASELINE_FINISHED\n');
