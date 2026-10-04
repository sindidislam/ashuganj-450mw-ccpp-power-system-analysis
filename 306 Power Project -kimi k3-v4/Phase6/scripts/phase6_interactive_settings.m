function result=phase6_interactive_settings(mdl,action,payload)
%PHASE6_INTERACTIVE_SETTINGS Editable study controls and measured results.
% GUI: phase6_interactive_settings(mdl)
% Automation: 'get', 'apply', 'run', 'export', 'plot'. Apply payload fields
% are scenario (validated S overrides) and relay (complete numeric R).
if nargin<1||isempty(mdl),mdl='PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL';end
if nargin<2,action='ui';end
if nargin<3,payload=struct();end
mdl=char(mdl);result=[];load_system(mdl);key=['Phase6Interactive_' mdl];
switch lower(action)
 case 'get'
  result=context(mdl);return
 case 'apply'
  result=applySettings(mdl,payload);rmLatest(key);refreshOpenPanel(key);return
 case 'run'
  rmLatest(key);
  if ~isempty(fieldnames(payload)),applySettings(mdl,payload);end
  c=context(mdl);out=sim(mdl,'ReturnWorkspaceOutputs','on');
  phase6_assert_complete_run(out,c.S);
  setappdata(0,key,struct('out',out,'info',c.info));
  assignin('base','phase6_out',out);assignin('base','phase6_info',c.info);
  refreshOpenPanel(key);result=out;return
 case 'export'
  assert(isappdata(0,key),'Phase6:NoRun','Run the current settings before exporting.');
  last=getappdata(0,key);phase6_assert_complete_run(last.out,last.info.scenario);
  result=export_phase6_results(last.out,last.info);return
 case 'plot'
  assert(isappdata(0,key),'Phase6:NoRun','Run a simulation first.');
  last=getappdata(0,key);sensor=1;if isfield(payload,'sensor'),sensor=payload.sensor;end
  result=plotSensor(last,sensor);return
 case 'ui'
 otherwise,error('Phase6:Action','Unknown action %s.',action);
end
old=findall(0,'Type','figure','Tag',key);
if ~isempty(old),refreshOpenPanel(key);figure(old(1));result=old(1);return;end
c=context(mdl);
screen=get(0,'ScreenSize');
panelPosition=[20 45 min(1160,screen(3)-40) min(780,screen(4)-110)];
fig=figure('Name','Ashuganj South | Scenario, protection and measurements', ...
 'NumberTitle','off','MenuBar','none','ToolBar','none','Color',[.95 .97 .99], ...
 'Position',panelPosition,'Tag',key,'Resize','on');result=fig;
uicontrol(fig,'Style','text','String','ASHUGANJ SOUTH  |  DYNAMIC STUDY CONTROL', ...
 'Units','normalized','Position',[.025 .93 .95 .045],'FontSize',17,'FontWeight','bold', ...
 'HorizontalAlignment','left','BackgroundColor',[.95 .97 .99],'ForegroundColor',[.08 .18 .30]);
tabs=uitabgroup(fig,'Units','normalized','Position',[.02 .17 .96 .74]);
scenarioTab=uitab(tabs,'Title','Operating point and faults');
relayTab=uitab(tabs,'Title','Protection settings');
measurementTab=uitab(tabs,'Title','Measured voltages and currents');
labels={'Scenario name','Generation (MW)','Fault type','Fault location', ...
 'Fault starts (s)','Fault duration (s)','Stop time (s)','Fault resistance (ohm)', ...
 'Ground resistance (ohm)','DC loss time (s, Inf = none)','DC restore time (s)'};
fields={'name','dispatch_MW','faultType','faultLocation','faultStart_s','faultDuration_s', ...
 'stopTime_s','faultResistance_ohm','groundResistance_ohm','dcLossTime_s','dcRestoreTime_s'};
edits=struct();
for k=1:numel(fields)
 col=floor((k-1)/6);row=mod(k-1,6);x=.035+col*.49;y=.85-row*.125;
 uicontrol(scenarioTab,'Style','text','String',labels{k},'Units','normalized', ...
  'Position',[x y .24 .05],'HorizontalAlignment','left','FontSize',11);
 if strcmp(fields{k},'faultType')
  opts={'NONE','3PH','SLG','LL','LLG'};val=1;
  if c.S.faultEnabled,val=find(strcmp(opts,c.S.faultType));end
  edits.(fields{k})=uicontrol(scenarioTab,'Style','popupmenu','String',opts,'Value',val, ...
   'Units','normalized','Position',[x+.25 y .18 .06],'FontSize',11);
 elseif strcmp(fields{k},'faultLocation')
  opts={'GEN','GSUT_LV','GSUT_HV','GIS230','LINE230','GRID230','AUX66'};
  edits.(fields{k})=uicontrol(scenarioTab,'Style','popupmenu','String',opts, ...
   'Value',find(strcmp(opts,c.S.faultLocation)),'Units','normalized','Position',[x+.25 y .18 .06],'FontSize',11);
 else
  value=c.S.(fields{k});if isnumeric(value),value=num2str(value,12);end
  edits.(fields{k})=uicontrol(scenarioTab,'Style','edit','String',value, ...
   'Units','normalized','Position',[x+.25 y .18 .065],'FontSize',11,'BackgroundColor','white');
 end
end
toggles={'protectionEnabled','batteryAvailable','chargerAvailable','GAT_in'};
toggleLabels={'Protection enabled','Battery available','Charger available','GAT in service'};checks=struct();
for k=1:4
 checks.(toggles{k})=uicontrol(scenarioTab,'Style','checkbox','String',toggleLabels{k}, ...
  'Value',c.S.(toggles{k}),'Units','normalized','Position',[.025+(k-1)*.245 .055 .245 .07],'FontSize',11);
end
uicontrol(relayTab,'Style','text','String', ...
 'Primary pickups and CT ratios are editable study values. Blank cells do not apply and are ignored.', ...
 'Units','normalized','Position',[.025 .88 .95 .08],'HorizontalAlignment','left','FontSize',11);
relayNames={'GEN 51','GSUT 51','GEN 51N','Generator 87G','Transformer 87T','Bus 87B','Line 87L'};
relayTable=uitable(relayTab,'Data',relayData(c),'RowName',relayNames, ...
 'ColumnName',{'Enabled','Pickup (A primary)','CT ratio','TMS (51)','Delay (s)','Slope 1','Slope 2'}, ...
 'ColumnEditable',true(1,7),'ColumnFormat',{'logical','numeric','numeric','numeric','numeric','numeric','numeric'}, ...
 'Units','normalized','Position',[.025 .26 .95 .59],'FontSize',12,'ColumnWidth',{65 150 110 100 100 100 100});
uicontrol(relayTab,'Style','text','String', ...
 sprintf('IEC Standard Inverse: t = 0.14 x TMS / ((I / pickup)^0.02 - 1)\nDifferential: measured spill must exceed pickup and bias/restraint threshold.\nEdits are saved in this model and its result metadata; the Phase 5 source CSVs remain unchanged.'), ...
 'Units','normalized','Position',[.025 .045 .95 .18],'HorizontalAlignment','left','FontSize',11);
sensorLabels={'Generator inner','Generator terminal','Transformer LV','Transformer HV','Bus incoming', ...
 'Bus outgoing','GAT HV','Line local','Line remote','Auxiliary','Grid','Neutral', ...
 'Fault generator','Fault unit LV','Fault transformer HV','Fault bus','Fault line','Fault grid','Fault auxiliary'};
meters=uitable(measurementTab,'Data',nan(19,6),'RowName',sensorLabels, ...
 'ColumnName',{'Va RMS (kV)','Vb RMS (kV)','Vc RMS (kV)','Ia RMS (A)','Ib RMS (A)','Ic RMS (A)'}, ...
 'Units','normalized','Position',[.02 .17 .96 .77],'FontSize',11,'ColumnWidth',{125 125 125 125 125 125});
sensorMenu=uicontrol(measurementTab,'Style','popupmenu','String',sensorLabels,'Units','normalized', ...
 'Position',[.035 .06 .30 .07],'FontSize',11);
uicontrol(measurementTab,'Style','pushbutton','String','Plot selected V / I waveforms', ...
 'Units','normalized','Position',[.37 .055 .31 .075],'FontSize',11,'Callback',@plotClick);
uicontrol(measurementTab,'Style','text','String','Table: latest completed run. Live meters are on the Simulink canvas.', ...
 'Units','normalized','Position',[.70 .025 .28 .10],'FontSize',10);
status=uicontrol(fig,'Style','text','String','Ready. Apply settings, then run. All values are academic study settings.', ...
 'Units','normalized','Position',[.025 .02 .95 .055],'HorizontalAlignment','left','FontSize',11, ...
 'BackgroundColor',[.95 .97 .99]);
buttons={'Apply and save','Run simulation','Stop','Export results','Reset defaults'};
callbacks={@applyClick,@runClick,@stopClick,@exportClick,@defaultsClick};
for k=1:5
 uicontrol(fig,'Style','pushbutton','String',buttons{k},'Units','normalized', ...
  'Position',[.025+(k-1)*.194 .095 .18 .055],'FontSize',11,'Callback',callbacks{k});
end
setappdata(fig,'Phase6RefreshCallback',@refreshPanel);
refreshPanel();

 function refreshPanel()
  now=context(mdl);
  for z=1:numel(fields)
   fld=fields{z};h=edits.(fld);value=now.S.(fld);
   if strcmp(get(h,'Style'),'popupmenu')
    if strcmp(fld,'faultType')&&~now.S.faultEnabled,value='NONE';end
    opts=get(h,'String');index=find(strcmp(opts,value),1);
    assert(~isempty(index),'Phase6:PanelSetting','Unknown active %s setting.',fld);
    set(h,'Value',index);
   else
    if isnumeric(value),value=num2str(value,12);end
    set(h,'String',value);
   end
  end
  for z=1:numel(toggles),set(checks.(toggles{z}),'Value',now.S.(toggles{z}));end
  set(relayTable,'Data',relayData(now));
  if isappdata(0,key)
   last=getappdata(0,key);
   if ~isequaln(last.info,now.info),rmLatest(key);end
  end
  if isappdata(0,key)
   refreshMeters();set(status,'String','Settings and measurements show the latest completed run.');
  else
   set(meters,'Data',nan(19,6));
   set(status,'String','Current saved settings shown. Run simulation to refresh measurements.');
  end
 end

 function request=readControls()
  now=context(mdl);sc=now.S;
  for z=1:numel(fields)
   fld=fields{z};h=edits.(fld);
   if strcmp(get(h,'Style'),'popupmenu'),opts=get(h,'String');value=opts{get(h,'Value')};
   else,value=get(h,'String');if ~strcmp(fld,'name'),value=str2double(value);end;end
   if strcmp(fld,'faultType')
    sc.faultEnabled=~strcmp(value,'NONE');if sc.faultEnabled,sc.faultType=value;end
   else,sc.(fld)=value;end
  end
  for z=1:4,sc.(toggles{z})=logical(get(checks.(toggles{z}),'Value'));end
  data=get(relayTable,'Data');rr=now.R;
  sc.relayMask=logical(cell2mat(data(:,1))).';
  rr.pickup_A=cell2mat(data(:,2)).';rr.ctRatio=cell2mat(data(:,3)).';
  rr.pickupSecondary_A=rr.pickup_A./rr.ctRatio;
  rr.tms=cell2mat(data(1:3,4)).';rr.delay_s=cell2mat(data(4:7,5)).';
  rr.slope1=cell2mat(data(4:7,6)).';rr.slope2=cell2mat(data(4:7,7)).';
  request=struct('scenario',sc,'relay',rr);
 end
 function applyClick(~,~)
  try,phase6_interactive_settings(mdl,'apply',readControls());set(status,'String','Settings applied and saved. Ready to run.');
  catch err,showError(err);end
 end
 function runClick(~,~)
  try
   set(status,'String','Applying settings and running the physical model...');drawnow;
   phase6_interactive_settings(mdl,'run',readControls());refreshMeters();
   set(status,'String','Run complete. Live model meters and the measured-results table now show this run.');
  catch err,showError(err);end
 end
 function stopClick(~,~),set_param(mdl,'SimulationCommand','stop');end
 function exportClick(~,~)
  try,r=phase6_interactive_settings(mdl,'export');set(status,'String',['Exported: ' r.outputDir]);
  catch err,showError(err);end
 end
 function defaultsClick(~,~)
  try
   now=context(mdl);sc=phase6_normalize_scenario(now.P,struct());
   phase6_interactive_settings(mdl,'apply',struct('scenario',sc,'relay',phase6_relay_parameters(now.P)));
   delete(fig);phase6_interactive_settings(mdl);
  catch err,showError(err);end
 end
 function refreshMeters()
  last=getappdata(0,key);raw=last.out.phase6_rms;
  vals=reshape(raw.Data(end,:),6,19).';vals(:,1:3)=vals(:,1:3)/1000;
  set(meters,'Data',vals);
 end
 function plotClick(~,~)
  try,phase6_interactive_settings(mdl,'plot',struct('sensor',get(sensorMenu,'Value')));
  catch err,showError(err);end
 end
 function showError(err),set(status,'String',err.message);errordlg(err.message,'Study controls');end
end

function c=context(mdl)
mw=get_param(mdl,'ModelWorkspace');
c.P=getVariable(mw,'P');c.S=getVariable(mw,'S');c.R=getVariable(mw,'R');
assert(hasVariable(mw,'Phase6BuildInfo'),'Phase6:RebuildRequired','Run build_phase6_model once to update this older saved model.');
c.info=getVariable(mw,'Phase6BuildInfo');c.info.path=get_param(mdl,'FileName');
c.info.scenario=c.S;c.info.controls.relayParameters=c.R;
end

function info=applySettings(mdl,request)
assert(strcmp(get_param(mdl,'SimulationStatus'),'stopped'),'Phase6:Running','Stop the current simulation before changing settings.');
c=context(mdl);S=c.S;R=c.R;
if isfield(request,'scenario')
 fields=fieldnames(request.scenario);for k=1:numel(fields),S.(fields{k})=request.scenario.(fields{k});end
end
S=phase6_normalize_scenario(c.P,S);
assert(S.faultStart_s<S.stopTime_s||~S.faultEnabled,'Phase6:FaultTime','Fault start must be before stop time.');
if isfield(request,'relay'),R=request.relay;end
positive={'pickup_A',7;'ctRatio',7;'tms',3;'delay_s',4};
for k=1:size(positive,1)
 v=R.(positive{k,1});assert(isnumeric(v)&&isreal(v)&&isequal(size(v),[1 positive{k,2}])&&all(isfinite(v))&&all(v>0), ...
  'Phase6:RelaySetting','%s must contain positive finite values.',positive{k,1});
end
for fld={'slope1','slope2'}
 v=R.(fld{1});assert(isnumeric(v)&&isreal(v)&&isequal(size(v),[1 4])&&all(isfinite(v))&&all(v>=0)&&all(v<=2),'Phase6:RelaySlope','Slopes must be between 0 and 2.');
end
assert(all(R.slope2>=R.slope1),'Phase6:RelaySlope','Slope 2 must not be below slope 1.');
R.pickupSecondary_A=R.pickup_A./R.ctRatio;
phase6=fileparts(fileparts(mfilename('fullpath')));
dest=char(java.io.File(get_param(mdl,'FileName')).getCanonicalPath());
assert(startsWith(lower(dest),[lower(char(java.io.File(phase6).getCanonicalPath())) filesep]) ...
 && ~contains(lower(dest),[filesep 'source_clone' filesep]),'Phase6:UnsafeOutput','Edit only the Phase6 working model.');
structural=S.dispatch_MW~=c.S.dispatch_MW||~strcmpi(S.networkProfile,c.S.networkProfile)||S.GAT_in~=c.S.GAT_in;
if structural
 info=build_phase6_model('Scenario',S,'SavePath',dest,'ModelName',mdl);open_system(mdl);
else,info=c.info;end
mw=get_param(mdl,'ModelWorkspace');assignin(mw,'S',S);assignin(mw,'R',R);
info.scenario=S;info.path=dest;info.controls.relayParameters=R;
info.userSettingNote='Editable academic study values; exact active settings retained with this run.';
assignin(mw,'Phase6Metadata',info.controls);assignin(mw,'Phase6BuildInfo',info);
set_param(mdl,'StopTime',num2str(S.stopTime_s,15));
phases=[1 1 1];ground='off';
if strcmpi(S.faultType,'SLG'),phases=[1 0 0];ground='on';end
if strcmpi(S.faultType,'LL'),phases=[0 1 1];end
if strcmpi(S.faultType,'LLG'),phases=[0 1 1];ground='on';end
values={'off','on'};locations=fieldnames(info.network.faults);
for k=1:numel(locations)
 times=[1e6 1e6+1];
 if S.faultEnabled&&strcmpi(S.faultLocation,locations{k}),times=[S.faultStart_s S.faultStart_s+S.faultDuration_s];end
 set_param(info.network.faults.(locations{k}),'FaultA',values{phases(1)+1},'FaultB',values{phases(2)+1}, ...
  'FaultC',values{phases(3)+1},'GroundFault',ground,'SwitchTimes',mat2str(times), ...
  'FaultResistance',num2str(S.faultResistance_ohm,15),'GroundResistance',num2str(S.groundResistance_ohm,15));
end
set_param(mdl,'SimulationCommand','update');save_system(mdl,dest);
end

function data=relayData(c)
data=cell(7,7);
for k=1:7
 data(k,:)={c.S.relayMask(k),c.R.pickup_A(k),c.R.ctRatio(k),[],[],[],[]};
 if k<=3,data{k,4}=c.R.tms(k);else
  data{k,5}=c.R.delay_s(k-3);data{k,6}=c.R.slope1(k-3);data{k,7}=c.R.slope2(k-3);
 end
end
end

function rmLatest(key),if isappdata(0,key),rmappdata(0,key);end;end

function refreshOpenPanel(key)
panels=findall(0,'Type','figure','Tag',key);
for panel=panels(:).'
 if isappdata(panel,'Phase6RefreshCallback')
  callback=getappdata(panel,'Phase6RefreshCallback');callback();
 end
end
end

function fig=plotSensor(last,sensor)
assert(isscalar(sensor)&&sensor>=1&&sensor<=19&&sensor==round(sensor));
raw=last.out.phase6_raw;rms=last.out.phase6_rms;ix=(sensor-1)*6;
fig=figure('Name',['Measured waveforms | ' last.info.controls.sensorNames{sensor}],'Color','white');
tiledlayout(fig,2,1,'TileSpacing','compact');
nexttile;plot(raw.Time,raw.Data(:,ix+(1:3))/1000);ylabel('Instantaneous phase voltage (kV)');grid on;legend('A','B','C');
nexttile;plot(raw.Time,raw.Data(:,ix+(4:6)));hold on;
plot(rms.Time,rms.Data(:,ix+(4:6)),'LineWidth',1.2);ylabel('Phase current (A)');xlabel('Time (s)');grid on;
legend('Ia','Ib','Ic','Ia RMS','Ib RMS','Ic RMS');
end
