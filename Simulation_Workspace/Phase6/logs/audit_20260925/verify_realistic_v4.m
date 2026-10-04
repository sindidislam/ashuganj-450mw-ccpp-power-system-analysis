% Reproducible final checks for the finite-impedance v4 model.
phase6=fileparts(fileparts(fileparts(mfilename('fullpath'))));root=fileparts(phase6);
addpath(genpath(fullfile(root,'matlab')));
addpath(fullfile(phase6,'scripts'),fullfile(phase6,'scripts','tests'));
setup_phase6_workspace();opengl software;
set(0,'DefaultFigureRenderer','painters');
record=struct('status','RUNNING','profile','PHASE5_STUDY','matlab',version);
try
 [dp,df]=test_phase5c_differential;assert(df==0);
 record.differentialChecks=dp;
 phase5c_diff_87g(fullfile(root,'results','phase5_protection_v2','plots'),root);
 phase5c_diff_87t(fullfile(root,'results','phase5_protection_v2','plots'),root);
 test_phase6_input_and_evidence;
 [np,nf,baseline]=test_phase6_dynamic_trip;assert(nf==0);
 record.integrationChecks=np;
 mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';load_system(fullfile(phase6,[mdl '.slx']));
 c=phase6_interactive_settings(mdl,'get');originalR=c.R;
 assert(strcmp(c.S.networkProfile,'PHASE5_STUDY')&&c.P.machine.damping_pu>0);
 assert(c.info.network.profile.Rgrid>0&&c.info.network.profile.R0grid>0);
 test_phase6_panel_refresh(mdl);
 baseExport=export_phase6_results(baseline.out,baseline.info,fullfile(phase6,'results','manual_bus_default'));
 R=originalR;R.delay_s(3)=.100;
 phase6_interactive_settings(mdl,'apply',struct('relay',R));
 fault=struct('name','manual_bus_delay_100ms','faultEnabled',true, ...
  'faultType','3PH','faultLocation','GIS230','faultStart_s',.15, ...
  'faultDuration_s',.30,'stopTime_s',.60,'protectionEnabled',true);
 edited=run_dynamic_trip_simulation(fullfile(phase6,'results',fault.name),root,fault);
 a=baseExport.tables.relay_times;b=edited.export.tables.relay_times;
 t1=a.First_trip_request_s(string(a.Relay)=="87B");t2=b.First_trip_request_s(string(b.Relay)=="87B");
 assert(abs((t2-t1)-.065)<.003,'Phase6:SettingRerun','87B delay edit did not move the actual trip by 65 ms.');
 record.default87BTrip_s=t1;record.edited87BTrip_s=t2;record.tripShift_s=t2-t1;
 fprintf('REALISTIC_SETTING_RERUN_PASS default=%.6f edited=%.6f shift=%.6f\n',t1,t2,t2-t1);
 phase6_interactive_settings(mdl,'apply',struct('relay',originalR));
 zones={'GEN','87G';'GSUT_HV','87T';'LINE230','87L'};
 record.zones=struct('location',{},'relay',{},'trip_s',{});
 for k=1:size(zones,1)
  fault.name=['v4_' lower(zones{k,1}) '_3ph'];fault.faultLocation=zones{k,1};
  z=run_dynamic_trip_simulation(fullfile(phase6,'results',fault.name),root,fault);
  tr=z.export.tables.relay_times;trip=tr.First_trip_request_s(string(tr.Relay)==zones{k,2});
  assert(isscalar(trip)&&isfinite(trip)&&trip>.15&&trip<.45,'Phase6:ZoneTrip','Expected %s did not operate.',zones{k,2});
  record.zones(k)=struct('location',zones{k,1},'relay',zones{k,2},'trip_s',trip);
  fprintf('REALISTIC_ZONE_PASS %s %s %.6f\n',zones{k,1},zones{k,2},trip);
 end
 normal=struct('name','v4_normal','faultEnabled',false,'stopTime_s',2);
 final=run_dynamic_trip_simulation(fullfile(phase6,'results','v4_normal'),root,normal);
 sm=final.out.phase6_summary;ix=sm.Time>=1.9;m=mean(sm.Data(ix,:),1);
 assert(all(isfinite(sm.Data),'all')&&~any(final.out.phase6_relay.Data(:,8:14),'all'));
 assert(abs(m(1)-360)<1&&abs(m(5)-50)<.02,'Phase6:Equilibrium','Finite-friction normal equilibrium is outside tolerance.');
 c=phase6_interactive_settings(mdl,'get');
 record.normal=struct('generator_MW',m(1),'generator_MVAr',m(2),'generator_kV',m(3), ...
  'frequency_Hz',m(5),'bus_kV',m(9),'aux_kV',m(21), ...
  'mechanicalInput_MW',c.info.controls.parameters.pm0*c.P.machine.Sn_VA/1e6, ...
  'ratedFrictionLoss_MW',c.P.machine.damping_pu*c.P.machine.Sn_VA/1e6, ...
  'Rgrid_ohm',c.info.network.profile.Rgrid);
 disp(record.normal);disp(c.info.loadflow.sm(1));
 phase6_write_parameter_register(c.P);
 style_phase6_model(mdl);set_param(mdl,'SimulationCommand','update');save_system(mdl);
 set_param(mdl,'ZoomFactor','FitSystem');
 print(['-s' mdl],'-dpng','-r120',fullfile(phase6,'logs','audit_20260925','verified_model.png'));
 f=phase6_interactive_settings(mdl);drawnow;
 print(f,'-dpng','-r120',fullfile(phase6,'logs','audit_20260925','verified_panel.png'));
 if isfile(fullfile(phase6,'logs','audit_20260925','verify_layout.m'))
  run(fullfile(phase6,'logs','audit_20260925','verify_layout.m'));
 end
 record.status='PASS';record.finished=char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
 fid=fopen(fullfile(phase6,'logs','audit_20260925','realistic_verification.json'),'w');
 fprintf(fid,'%s\n',jsonencode(record,'PrettyPrint',true));fclose(fid);
 fprintf('REALISTIC_V4_VERIFICATION_PASS\n');
catch err
 record.status='FAIL';record.error=getReport(err,'extended','hyperlinks','off');
 fid=fopen(fullfile(phase6,'logs','audit_20260925','realistic_verification.json'),'w');
 fprintf(fid,'%s\n',jsonencode(record,'PrettyPrint',true));fclose(fid);rethrow(err);
end
