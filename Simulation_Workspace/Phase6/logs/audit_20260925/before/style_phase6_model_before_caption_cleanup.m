function style_phase6_model(mdl)
%STYLE_PHASE6_MODEL Functional SLD presentation with wired live measurements.
% Electrical blocks and conserving connections are preserved.
mdl=char(mdl);set_param(mdl,'ScreenColor','white');
layout={ ...
 'Generator',[430 705 610 825],'orange'; ...
 'Transformer',[440 345 600 465],'orange'; ...
 'Switchyard',[430 120 620 210],'blue'; ...
 'Transmission Line',[830 120 1030 210],'blue'; ...
 'Grid',[1210 120 1370 210],'blue'; ...
 'Auxiliaries',[840 405 1060 515],'magenta'; ...
 'Measurements',[840 675 1060 755],'darkGreen'; ...
 'Protection',[430 935 650 1015],'red'; ...
 'DC Supply',[830 935 1050 1015],'magenta'; ...
 'Breaker Control',[1140 935 1360 1015],'red'; ...
 'Turbine and AVR',[50 935 280 1015],'darkGreen'; ...
 'Results',[1140 700 1360 780],'darkGreen'};
for k=1:size(layout,1)
 p=[mdl '/' layout{k,1}];set_param(p,'Position',layout{k,2},'ForegroundColor',layout{k,3}, ...
  'BackgroundColor','white','FontSize','12','FontWeight','bold','ShowName','on');
 set_param(p,'Mask','on','MaskDisplay',symbol(layout{k,1}), ...
  'MaskIconUnits','normalized','MaskIconOpaque','opaque','MaskIconRotate','off');
end
set_param([mdl '/Generator Breaker'],'Position',[480 555 560 615],'ForegroundColor','orange','FontSize','11');
set_param([mdl '/GCB command'],'Position',[290 555 420 580],'ShowName','off');
set_param([mdl '/powergui'],'Position',[55 45 185 85],'FontSize','10');

actions={'Scenario',[45 160 265 225],'Operating point'; ...
 'Faults',[45 285 265 350],'Fault type and location'; ...
 'Protection Settings',[45 410 265 475],'Pickups, CTs and timing'};
for k=1:size(actions,1)
 p=[mdl '/' actions{k,1}];if getSimulinkBlockHandle(p)<0,add_block('built-in/Subsystem',p);end
 set_param(p,'Position',actions{k,2},'BackgroundColor','lightBlue','ForegroundColor','blue','FontSize','12', ...
  'FontWeight','bold','Mask','on','MaskDisplay',centerIcon(sprintf('text(0.5,0.62,''%s'');text(0.5,0.25,''Double-click to edit'');',actions{k,3})), ...
  'MaskIconUnits','normalized','OpenFcn','phase6_interactive_settings(bdroot);');
end
livePath=[mdl '/Measurements/Live RMS Readings'];
sensorNames={'Generator inner','Generator terminal','Transformer LV','Transformer HV','Bus incoming', ...
 'Bus outgoing','GAT HV','Line local','Line remote','Auxiliary','Grid','Neutral', ...
 'Fault generator','Fault unit LV','Fault transformer HV','Fault bus','Fault line','Fault grid','Fault auxiliary'};
if getSimulinkBlockHandle(livePath)<0
 add_block('built-in/Subsystem',livePath,'Position',[1130 400 1350 475],'BackgroundColor','[0.90, 0.97, 0.92]','FontSize','13');
 for k=1:19
  col=floor((k-1)/7);row=mod(k-1,7);x=25+col*460;y=85+row*165;
  source=[livePath sprintf('/Source %d',k)];sel=[livePath sprintf('/Select %d',k)];
  gain=[livePath sprintf('/Units %d',k)];dispPath=[livePath '/' sensorNames{k}];
  add_block('simulink/Signal Routing/From',source,'GotoTag','P6_RMS','Position',[x y x+75 y+20],'ShowName','off');
  add_block('simulink/Signal Routing/Selector',sel,'Position',[x+100 y x+130 y+40], ...
   'NumberOfDimensions','1','InputPortWidth','114','IndexMode','One-based', ...
   'IndexOptionArray',{'Index vector (dialog)'},'IndexParamArray',{mat2str((k-1)*6+(1:6))},'ShowName','off');
  add_block('simulink/Math Operations/Gain',gain,'Gain','[.001 .001 .001 1 1 1]', ...
   'Multiplication','Element-wise(K.*u)','Position',[x+150 y x+185 y+45],'ShowName','off');
  add_block('simulink/Sinks/Display',dispPath,'Position',[x+215 y-20 x+345 y+105], ...
   'Format','short','FontSize','12','ForegroundColor','darkGreen','BackgroundColor','white');
  connect(livePath,source,1,sel,1);connect(livePath,sel,1,gain,1);connect(livePath,gain,1,dispPath,1);
 end
 a=Simulink.Annotation(livePath,'LIVE RMS MEASUREMENTS | Each display: Va, Vb, Vc in kV; Ia, Ib, Ic in A');
 a.Position=[35 15];a.FontSize=16;a.FontWeight='bold';
end
% Make the six readings an explicit 3-by-2 matrix: rows A/B/C, columns V/I.
% A flat vector wraps by display width and previously mixed Vc with Ia.
for k=1:numel(sensorNames)
 col=floor((k-1)/7);row=mod(k-1,7);x=25+col*460;y=85+row*165;
 gain=[livePath sprintf('/Units %d',k)];dispPath=[livePath '/' sensorNames{k}];
 shape=[livePath sprintf('/Phase matrix %d',k)];
 if getSimulinkBlockHandle(shape)<0
  h=get_param(gain,'PortHandles');ln=get_param(h.Outport,'Line');
  if ln~=-1,delete_line(ln);end
  add_block('simulink/Math Operations/Reshape',shape,'OutputDimensionality','Customize', ...
   'OutputDimensions','[3 2]','Position',[x+195 y x+225 y+40],'ShowName','off');
  connect(livePath,gain,1,shape,1);connect(livePath,shape,1,dispPath,1);
 end
 set_param(dispPath,'Position',[x+260 y-20 x+390 y+105]);
end
aa=find_system(livePath,'FindAll','on','SearchDepth',1,'Type','annotation');
for h=reshape(aa,1,[])
 a=get_param(h,'Object');
 if contains(a.Text,'LIVE RMS MEASUREMENTS')
  a.Text='LIVE RMS MEASUREMENTS | Rows: phases A, B, C. Left column: voltage (kV). Right column: current (A).';
  a.FontSize=14;
 end
end
button=[mdl '/Live Three Phase Measurements'];
if getSimulinkBlockHandle(button)<0,add_block('built-in/Subsystem',button);end
set_param(button,'Position',[840 790 1060 860],'BackgroundColor','[0.90, 0.97, 0.92]','ForegroundColor','darkGreen', ...
 'FontSize','11','Mask','on','MaskDisplay',centerIcon('text(.5,.65,''19 measured locations'');text(.5,.27,''Open phase V / I meters'');'), ...
 'MaskIconUnits','normalized','OpenFcn', ...
 'open_system([bdroot ''/Measurements/Live RMS Readings'']);set_param([bdroot ''/Measurements/Live RMS Readings''],''ZoomFactor'',''FitSystem'');');

meterSource=[mdl '/Live Meter Signals'];
if getSimulinkBlockHandle(meterSource)<0
 add_block('built-in/Subsystem',meterSource,'Position',[1430 285 1450 1100]);
 add_block('simulink/Signal Routing/From',[meterSource '/Actual plant summary'],'GotoTag','P6_SUMMARY','Position',[30 40 170 65]);
 indices=[1 2 3 4 5 8 9 10 21 18 19 20 13 11 14 15 16 17];
 labels={'Generator MW','Generator MVAr','Generator kV','Generator kA','Frequency Hz', ...
  'Transformer HV kA','Bus voltage kV','Grid current kA','Auxiliary kV','DC voltage V', ...
  'Battery SOC percent','DC healthy','Relay trip','Fault current kA','GCB closed','Q0 closed','Line local closed','Line remote closed'};
 for k=1:numel(indices)
  sl=[meterSource sprintf('/Channel %d',indices(k))];op=[meterSource sprintf('/Meter %d',k)];
  add_block('simulink/Signal Routing/Selector',sl,'Position',[245 30+55*k 300 60+55*k], ...
   'NumberOfDimensions','1','InputPortWidth','24','IndexMode','One-based', ...
   'IndexOptionArray',{'Index vector (dialog)'},'IndexParamArray',{num2str(indices(k))});
  add_block('simulink/Sinks/Out1',op,'Port',num2str(k),'Position',[390 35+55*k 420 55+55*k]);
  connect(meterSource,[meterSource '/Actual plant summary'],1,sl,1);connect(meterSource,sl,1,op,1);
  dp=[mdl '/' labels{k}];y=285+(k-1)*46;
  add_block('simulink/Sinks/Display',dp,'Position',[1570 y 1730 y+28],'Format','short', ...
   'FontSize','12','ForegroundColor','darkGreen','BackgroundColor','white');
  connect(mdl,meterSource,k,dp,1);
 end
 set_param(meterSource,'Mask','on','MaskDisplay','','MaskIconOpaque','opaque','ShowName','off', ...
  'BackgroundColor','white','ForegroundColor','white','ShowPortLabels','none');
end
% Route existing electrical connections after moving equipment. This changes
% geometry only, with no add/delete of conserving ports or physical lines.
lines=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','line');
for h=reshape(lines,1,[])
 try,Simulink.BlockDiagram.routeLine(h);catch,end
end
% Line ForegroundColor is not a writable R2024a parameter. Use the supported
% HiliteAncestors property, with custom schemes restored after each reload.
phase6_color_wires(mdl);
% Compilation may clear highlighting. Restore it when simulation starts and
% stops as well as when the saved model loads. Preserve existing callbacks.
for name={'PostLoadFcn','StartFcn','StopFcn'}
 callback=get_param(mdl,name{1});
 if ~contains(callback,'phase6_color_wires')
  set_param(mdl,name{1},[callback newline 'phase6_color_wires(bdroot);']);
 end
end
annotations=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','annotation');
for a=reshape(annotations,1,[])
 try
  obj=get_param(a,'Object');txt=obj.Text;
  if contains(txt,'ASHUGANJ SOUTH'),obj.Position=[435 0];obj.FontSize=22;
  elseif contains(txt,'Dynamic study'),obj.Position=[1130 35];obj.FontSize=11;end
 catch,end
end
if ~hasNote(mdl,'230 kV'),note(mdl,'230 kV  |  SWITCHYARD - SOUTH LINE - PGCB GRID',[650 65],14);end
if ~hasNote(mdl,'Live readings'),note(mdl,'Live readings',[1510 215],16);end
if ~hasNote(mdl,'Color key'),note(mdl,'Color key: blue = 230 kV   orange = unit 22 kV   purple = auxiliaries / DC   green = measurements',[410 1135],12);end
set_param(mdl,'ZoomFactor','FitSystem');
end

function connect(parent,src,sp,dst,dp)
s=get_param(src,'PortHandles');d=get_param(dst,'PortHandles');add_line(parent,s.Outport(sp),d.Inport(dp),'autorouting','on');
end
function note(parent,text,pos,sz),a=Simulink.Annotation(parent,text);a.Position=pos;a.FontSize=sz;end
function yes=hasNote(mdl,term)
yes=false;aa=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','annotation');
for h=reshape(aa,1,[]),o=get_param(h,'Object');if contains(o.Text,term),yes=true;return;end;end
end
function code=symbol(name)
switch name
 case 'Generator'
  code='t=linspace(0,2*pi,80);plot(.5+.23*cos(t),.56+.30*sin(t));text(.5,.58,''G'');text(.5,.12,''458 MVA | 22 kV'');';
 case 'Transformer'
  code='t=linspace(0,2*pi,80);plot(.5+.20*cos(t),.64+.22*sin(t));plot(.5+.20*cos(t),.36+.22*sin(t));text(.5,.06,''515 MVA | YNd1'');';
 case 'Switchyard'
  code='plot([.1 .9],[.6 .6]);plot([.1 .9],[.54 .54]);text(.5,.22,''230 kV GIS'');';
 case 'Transmission Line'
  code='plot([.1 .9],[.65 .65]);plot([.1 .9],[.48 .48]);text(.5,.18,''0.7 km | two circuits'');';
 case 'Grid'
  code='plot([.25 .5 .75],[.35 .85 .35]);plot([.35 .65],[.60 .60]);plot([.2 .8],[.35 .35]);text(.5,.13,''PGCB equivalent'');';
 case 'Auxiliaries'
  code='text(.5,.68,''UAT / GAT'');text(.5,.38,''6.6 kV bus'');text(.5,.12,''14 MW plant load'');';
 case 'Protection'
  code='text(.5,.67,''51 / 51N / 87G / 87T'');text(.5,.30,''87B / 87L'');';
 case 'DC Supply'
  code='text(.5,.67,''110 V | 200 Ah'');text(.5,.30,''Battery + charger + trip coils'');';
 case 'Turbine and AVR'
  code='text(.5,.67,''Governor and turbine'');text(.5,.30,''Excitation / AVR'');';
 case 'Breaker Control'
  code='text(.5,.67,''DC-fed trip circuits'');text(.5,.30,''Breaker mechanisms'');';
 case 'Measurements'
  code='text(.5,.67,''Measured three-phase V / I'');text(.5,.30,''RMS + synchronized phasors'');';
 otherwise
  code='text(.5,.67,''Waveforms and event records'');text(.5,.30,''Open scopes / export results'');';
end
code=centerIcon(code);
end
function code=centerIcon(code)
code=regexprep(code,'text\(([^;]+)\);','text($1,''horizontalAlignment'',''center'');');
end
