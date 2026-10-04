% Measured acceptance runs. All writes stay inside this Phase6 tree.
phase6=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(phase6,'scripts'));paths=setup_phase6_workspace();
baseline=load(fullfile(paths.results,'bus_3ph','probe.mat'),'info');
info=baseline.info;load_system(info.path);mdl=info.model;
P=init_phase6_parameters();
cases={ ...
 struct('name','generator_3ph','faultLocation','GEN','faultType','3PH'), ...
 struct('name','transformer_lv_ll','faultLocation','GSUT_LV','faultType','LL'), ...
 struct('name','transformer_hv_llg','faultLocation','GSUT_HV','faultType','LLG'), ...
 struct('name','line_slg','faultLocation','LINE230','faultType','SLG'), ...
 struct('name','grid_external_ll','faultLocation','GRID230','faultType','LL'), ...
 struct('name','generator_slg','faultLocation','GEN','faultType','SLG'), ...
 struct('name','dc_loss_bus_3ph','faultLocation','GIS230','dcLossTime_s',.08), ...
 struct('name','dc_recovery_bus_3ph','faultLocation','GIS230','dcLossTime_s',.08,'dcRestoreTime_s',.30), ...
 struct('name','protection_disabled','faultLocation','GIS230','protectionEnabled',false,'faultDuration_s',.08,'stopTime_s',.4), ...
 struct('name','charger_unavailable','faultEnabled',false,'chargerAvailable',false,'stopTime_s',.4), ...
 struct('name','reset_normal','faultEnabled',false,'stopTime_s',.4)};
expected=[4 5 5 7 0 0 6 6 0 0 0];
report=struct('name',{},'passed',{},'maxFault_A',{},'tripRelays',{},'openedBreakers',{},'minDC_V',{},'maxSpeed_pu',{},'detail',{});
for k=1:numel(cases)
 o=struct('faultEnabled',true,'faultStart_s',.15,'faultDuration_s',.3,'stopTime_s',.6);
 f=fieldnames(cases{k});for j=1:numel(f),o.(f{j})=cases{k}.(f{j});end
 S=phase6_normalize_scenario(P,o);info.scenario=S;
 destination=fullfile(paths.results,S.name);if ~isfolder(destination),mkdir(destination);end
 fprintf('SCENARIO_START %s %s\n',S.name,char(datetime('now')));
 item=struct('name',S.name,'passed',false,'maxFault_A',NaN,'tripRelays','','openedBreakers','','minDC_V',NaN,'maxSpeed_pu',NaN,'detail','');
 try
  mw=get_param(mdl,'ModelWorkspace');assignin(mw,'S',S);
  set_param(mdl,'StopTime',num2str(S.stopTime_s));
  locations=fieldnames(info.network.faults);
  phases=[1 1 1];ground='off';
  if strcmpi(S.faultType,'SLG'),phases=[1 0 0];ground='on';end
  if strcmpi(S.faultType,'LL'),phases=[0 1 1];end
  if strcmpi(S.faultType,'LLG'),phases=[0 1 1];ground='on';end
  labels={'off','on'};
  for j=1:numel(locations)
   times=[1e6 1e6+1];if S.faultEnabled&&strcmpi(S.faultLocation,locations{j}),times=[S.faultStart_s S.faultStart_s+S.faultDuration_s];end
   set_param(info.network.faults.(locations{j}),'FaultA',labels{phases(1)+1},'FaultB',labels{phases(2)+1}, ...
    'FaultC',labels{phases(3)+1},'GroundFault',ground,'SwitchTimes',mat2str(times), ...
    'FaultResistance',num2str(S.faultResistance_ohm),'GroundResistance',num2str(S.groundResistance_ohm));
  end
  out=sim(mdl,'ReturnWorkspaceOutputs','on');
  save(fullfile(destination,'probe.mat'),'out','info','-v7.3');
  [tables,signals,metadata]=phase6_result_tables(out,info);
  n=fieldnames(tables);for j=1:numel(n),writetable(tables.(n{j}),fullfile(destination,[n{j} '.csv']));end
  save(fullfile(destination,'simulation_data.mat'),'out','info','signals','tables','metadata','-v7.3');
  q=out.phase6_summary;r=out.phase6_relay;b=out.phase6_breakers;d=out.phase6_dc;
  valid=q.Time>=.04;
  assert(all(isfinite(q.Data),'all'),'Nonfinite plant quantities');
  item.maxFault_A=max(tables.fault_summary.Initial_peak_abs_current_A,[],'omitnan');
  tripped=any(r.Data(:,8:14)>.5,1);opened=any(b.Data(:,1:4)<.5,1);
  names={'GEN51','GSUT51','GEN51N','87G','87T','87B','87L'};bn={'GCB','Q0','LineLocal','LineRemote'};
  item.tripRelays=strjoin(names(tripped),',');item.openedBreakers=strjoin(bn(opened),',');
  item.minDC_V=min(d.Data(d.Time>=.04,1));item.maxSpeed_pu=max(q.Data(valid,6));
  if S.faultEnabled
   assert(item.maxFault_A>1,'Selected fault did not produce measured current');
   before=r.Time<S.faultStart_s;assert(~any(r.Data(before,8:14),'all'),'Trip before disturbance');
  end
  if expected(k)>0
   assert(tripped(expected(k)),sprintf('Expected relay %s did not trip',names{expected(k)}));
  end
  if strcmp(S.name,'dc_loss_bus_3ph')
   assert(~any(opened),'Breaker opened with DC unavailable');
   mask=d.Time>=.1;assert(all(d.Data(mask,6)==0)&&all(d.Data(mask,10)==1),'DC loss not visible');
  elseif strcmp(S.name,'dc_recovery_bus_3ph')
   assert(~any(b.Data(b.Time<S.dcRestoreTime_s,1:4)<.5,'all'),'Breaker opened before DC restoration');
   assert(opened(2)&&opened(3),'Restored DC did not execute latched bus trip');
  elseif expected(k)>0
   assert(any(opened),'Protection request did not open breaker');
   assert(any(isfinite(tables.breaker_times.Current_cessation_s)),'No measured current interruption');
  elseif strcmp(S.name,'grid_external_ll')
   assert(~any(tripped(4:7)),'External fault caused differential trip');
  elseif strcmp(S.name,'protection_disabled')
   assert(~any(tripped)&&~any(opened),'Disabled protection tripped');
  elseif ~S.faultEnabled
   assert(~any(tripped)&&~any(opened),'Spurious normal trip');
   assert(max(abs(q.Data(valid,3)-22))<.1,'Normal voltage deviation');
   assert(max(abs(q.Data(valid,5)-50))<.02,'Normal frequency deviation');
   if ~S.chargerAvailable
    mask=d.Time>=.04;assert(all(d.Data(mask,9)==1)&&all(d.Data(mask,6)==1),'Battery did not support failed charger');
    assert(all(d.Data(mask,2)>0)&&all(abs(d.Data(mask,3))<1e-9),'Charger outage current balance');
   end
  end
  item.passed=true;item.detail='Measured acceptance assertions passed';
  fprintf('SCENARIO_PASS %s fault_peak_A=%.6g relays=%s breakers=%s\n',S.name,item.maxFault_A,item.tripRelays,item.openedBreakers);
 catch err
  item.detail=getReport(err,'extended','hyperlinks','off');fprintf(2,'SCENARIO_FAIL %s\n%s\n',S.name,item.detail);
 end
 report(end+1)=item;writetable(struct2table(report),fullfile(paths.results,'scenario_validation.csv'));
 save(fullfile(paths.results,'scenario_validation.mat'),'report');
end
close_system(mdl,0);
fprintf('SCENARIO_BATCH_DONE passed=%d total=%d\n',sum([report.passed]),numel(report));
