% Fresh v4 integration evidence and the manual's protection-setting rerun.
phase6=fileparts(fileparts(fileparts(mfilename('fullpath'))));
root=fileparts(phase6);addpath(genpath(fullfile(root,'matlab')));
addpath(fullfile(phase6,'scripts'),fullfile(phase6,'scripts','tests'));
setup_phase6_workspace();
test_phase6_input_and_evidence;
[np,nf]=test_phase6_dynamic_trip;assert(nf==0);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
load_system(fullfile(phase6,[mdl '.slx']));
c=phase6_interactive_settings(mdl,'get');originalR=c.R;
fault=struct('name','manual_bus_default','faultEnabled',true, ...
 'faultType','3PH','faultLocation','GIS230','faultStart_s',.15, ...
 'faultDuration_s',.30,'stopTime_s',.60,'protectionEnabled',true);
baseline=run_dynamic_trip_simulation(fullfile(phase6,'results','manual_bus_default'),root,fault);
editedR=originalR;editedR.delay_s(3)=.100;
phase6_interactive_settings(mdl,'apply',struct('relay',editedR));
fault.name='manual_bus_delay_100ms';
edited=run_dynamic_trip_simulation(fullfile(phase6,'results','manual_bus_delay_100ms'),root,fault);
a=baseline.export.tables.relay_times;b=edited.export.tables.relay_times;
t1=a.First_trip_request_s(string(a.Relay)=="87B");t2=b.First_trip_request_s(string(b.Relay)=="87B");
assert(abs((t2-t1)-.065)<.003,'Phase6:SettingRerun','Changing 87B delay did not change the measured trip by 65 ms.');
fprintf('MANUAL_SETTING_RERUN_PASS default=%.6f edited=%.6f shift=%.6f\n',t1,t2,t2-t1);
phase6_interactive_settings(mdl,'apply',struct('relay',originalR));
normal=struct('name','v4_normal','faultEnabled',false,'stopTime_s',.60);
final=run_dynamic_trip_simulation(fullfile(phase6,'results','v4_normal'),root,normal);
[comparison,settings]=phase6_compare_reference(final.out,final.info);
assert(all(string(comparison.Status)=="PASS"),'Phase6:NormalReference','Normal operating point did not pass.');
writetable(comparison,fullfile(phase6,'results','v4_normal','operating_point_comparison.csv'));
writetable(settings,fullfile(phase6,'results','v4_normal','setting_consistency.csv'));
save_system(mdl);open_system(mdl);set_param(mdl,'ZoomFactor','FitSystem');
print(['-s' mdl],'-dpng','-r120',fullfile(phase6,'logs','audit_20260925','verified_model.png'));
record=struct('date',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
 'matlab',version,'integrationChecksPassed',np,'integrationChecksFailed',nf, ...
 'default87BTrip_s',t1,'edited87BTrip_s',t2,'tripShift_s',t2-t1, ...
 'normalReferencePasses',height(comparison),'status','PASS');
fid=fopen(fullfile(phase6,'logs','audit_20260925','verification.json'),'w');
fprintf(fid,'%s\n',jsonencode(record,'PrettyPrint',true));fclose(fid);
fprintf('V4_VERIFICATION_PASS\n');
