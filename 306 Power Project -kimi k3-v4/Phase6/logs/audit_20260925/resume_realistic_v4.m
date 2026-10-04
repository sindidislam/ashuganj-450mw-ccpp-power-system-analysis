function resume_realistic_v4()
phase6=fileparts(fileparts(fileparts(mfilename('fullpath'))));root=fileparts(phase6);
addpath(genpath(fullfile(root,'matlab')));
addpath(fullfile(phase6,'scripts'),fullfile(phase6,'scripts','tests'));
setup_phase6_workspace();opengl software;set(0,'DefaultFigureRenderer','painters');
record=jsondecode(fileread(fullfile(phase6,'logs','audit_20260925','realistic_verification.json')));
if isfield(record,'error'),record=rmfield(record,'error');end
record.status='RUNNING';
try
 mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';load_system(fullfile(phase6,[mdl '.slx']));
 originalR=phase6_relay_parameters();
 phase6_interactive_settings(mdl,'apply',struct('relay',originalR));
 fault=struct('faultEnabled',true,'faultType','3PH','faultStart_s',.15, ...
 'faultDuration_s',.30,'stopTime_s',.60,'protectionEnabled',true);
 zones={'GEN','87G';'GSUT_HV','87T';'LINE230','87L'};
 record.zones=struct('location',{},'relay',{},'trip_s',{});
 for k=1:size(zones,1)
  fault.name=['v4_' lower(zones{k,1}) '_3ph'];fault.faultLocation=zones{k,1};
  if k==1
   tr=readtable(fullfile(phase6,'results',fault.name,'relay_times.csv'));
  else
   z=run_dynamic_trip_simulation(fullfile(phase6,'results',fault.name),root,fault);
   tr=z.export.tables.relay_times;
  end
  trip=tr.First_trip_request_s(string(tr.Relay)==zones{k,2});
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

end
