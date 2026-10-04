p6root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(p6root,'scripts'),fullfile(p6root,'scripts','tests'));
p6log=fullfile(p6root,'logs','resume_20260924');
diary(fullfile(p6log,'final_checks.log'));
clear phase6_dc_step phase6_breaker_step;
test_phase6_dc_recovery;
test_phase6_dc;
test_phase6_actuators;
test_phase6_protection_sfunctions;
mdl='PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL';
c=phase6_interactive_settings(mdl,'get');
original=c;
% Independently confirm the preceding real GUI Run button produced data.
last=getappdata(0,['Phase6Interactive_' mdl]);
assert(~isempty(last)&&isa(last.out,'Simulink.SimulationOutput'));
assert(~any(last.out.phase6_relay.Data(:,8:14),'all'));
fprintf('GUI_RUN_NORMAL_PASS\n');
counts=phase6_color_wires(mdl);disp(counts);
topLines=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','line');
disp(get_param(topLines(1),'HiliteAncestors'));drawnow;
print(['-s' mdl],'-dpng','-r120',fullfile(p6log,'colored_model.png'));
phase6_write_parameter_register(c.P);
% Restoration is intentionally after the former unpowered pulse expired.
request=struct('scenario',struct('name','dc_late_recovery_bus_3ph', ...
 'faultEnabled',true,'faultType','3PH','faultLocation','GIS230', ...
 'faultStart_s',.15,'faultDuration_s',.6,'stopTime_s',.85, ...
 'dcLossTime_s',.08,'dcRestoreTime_s',.50));
out=phase6_interactive_settings(mdl,'run',request);
c=phase6_interactive_settings(mdl,'get');
d=out.phase6_dc;b=out.phase6_breakers;r=out.phase6_relay;
assert(any(r.Data(:,13)>0),'Bus differential failed to request a trip.');
assert(~any(b.Data(b.Time<.50,1:4)<.5,'all'),'Breaker opened before restoration.');
assert(any(d.Data(d.Time>=.50 & d.Time<.56,12)>1900),'Restoration supplied no trip-coil power.');
assert(any(b.Data(b.Time>=.55,2:3)<.5,'all'),'Restored DC failed to open bus breakers.');
result=export_phase6_results(out,c.info);
fprintf('DC_LATE_RESTORE_INTEGRATED_PASS\n');
% Restore a useful normal classroom scenario with a selectable future fault.
normal=original.S;normal.faultStart_s=.15;normal.faultDuration_s=.3;
normal.stopTime_s=.6;
phase6_interactive_settings(mdl,'apply',struct('scenario',normal,'relay',original.R));
out=phase6_interactive_settings(mdl,'run');
c=phase6_interactive_settings(mdl,'get');info=c.info;
[comparison,settings]=phase6_compare_reference(out,info);
assert(all(string(comparison.Status)=='PASS'));
writetable(comparison,fullfile(p6root,'results','operating_point_comparison.csv'));
writetable(settings,fullfile(p6root,'results','setting_consistency.csv'));
export_phase6_results(out,info);
save(fullfile(p6root,'results','final_normal.mat'),'out','info','-v7.3');
save_system(mdl);phase6_color_wires(mdl);
print(['-s' mdl],'-dpng','-r150',fullfile(p6log,'final_model.png'));
print(['-s' mdl '/Measurements/Live RMS Readings'],'-dpng','-r120',fullfile(p6log,'final_phase_meters.png'));
f=findall(0,'Type','figure','Tag',['Phase6Interactive_' mdl]);delete(f);
clear phase6_interactive_settings;
f=phase6_interactive_settings(mdl);drawnow;
saveas(f,fullfile(p6log,'final_panel.png'));
fprintf('FINAL_NORMAL_AND_PRESENTATION_PASS\n');
diary off;
