phase6=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(phase6,'scripts'));paths=setup_phase6_workspace();
clear build_phase6_model style_phase6_model phase6_interactive_settings;
fprintf('INTERFACE_BUILD_START\n');
info=build_phase6_model('Scenario',struct('stopTime_s',.4));
fprintf('INTERFACE_BUILD_PASS\n');
mdl=info.model;
c=phase6_interactive_settings(mdl,'get');
assert(c.S.dispatch_MW==360);
assert(numel(find_system(mdl,'LookUnderMasks','all','MaskType','Three-Phase Fault'))==7);
assert(numel(find_system(mdl,'LookUnderMasks','all','MaskType','Three-Phase Breaker'))==5);
f=phase6_interactive_settings(mdl);drawnow;
saveas(f,fullfile(phase6,'logs','resume_20260923_evening','control_panel.png'));
close(f);
out=phase6_interactive_settings(mdl,'run');
assert(~any(out.phase6_relay.Data(:,8:14),'all'));
print(['-s' mdl],'-dpng','-r130',fullfile(phase6,'logs','resume_20260923_evening','styled_model.png'));
print(['-s' mdl '/Measurements/Live RMS Readings'],'-dpng','-r120',fullfile(phase6,'logs','resume_20260923_evening','live_phase_meters.png'));
fprintf('INTERFACE_NORMAL_RUN_PASS\n');
% Verify settings edit changes the actual measured relay response and metadata.
R=c.R;R.delay_s(3)=.07;
request=struct('scenario',struct('name','interactive_bus_trip','faultEnabled',true,'faultLocation','GIS230', ...
 'faultType','3PH','faultStart_s',.15,'faultDuration_s',.3,'stopTime_s',.5),'relay',R);
out=phase6_interactive_settings(mdl,'run',request);
c2=phase6_interactive_settings(mdl,'get');
assert(c2.R.delay_s(3)==.07&&c2.info.controls.relayParameters.delay_s(3)==.07);
rr=out.phase6_relay;it=find(rr.Data(:,13),1);assert(~isempty(it));
assert(rr.Time(it)>.21&&rr.Time(it)<.24,'Edited bus relay delay was not applied');
result=phase6_interactive_settings(mdl,'export');
fprintf('INTERACTIVE_SETTING_RESPONSE_PASS trip_s=%.4f\n',rr.Time(it));
% Final model reopens in the documented normal state.
phase6_interactive_settings(mdl,'apply',struct('scenario',c.S,'relay',c.R));
out=phase6_interactive_settings(mdl,'run');
save(fullfile(phase6,'results','final_normal.mat'),'info','out','-v7.3');
print(['-s' mdl],'-dpng','-r130',fullfile(phase6,'logs','resume_20260923_evening','styled_model.png'));
fprintf('INTERFACE_FINAL_NORMAL_PASS\n');
