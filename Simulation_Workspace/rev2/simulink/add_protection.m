function add_protection(varargin)
%ADD_PROTECTION Protection demo inside Load_Flow_V2.slx (Rev2 Phase-3 settings).
% Q9 (line) 51-OC: series BRK_Q9 on dedicated VI_GRID_R->EXTGRID direct lines +
%   RELAY_Q9 (Fourier magnitudes -> IEC-SI inverse timer via Integrator+Fcn,
%   pickup 1031A TMS 0.281 from Phase-3) tripping it.
% Q0 (gen side): BRK_Q0 block placed here, WIRED VIA XML (xml_series_q0.ps1)
%   at GSUT_L tree leaves (code cannot branch occupied ports) + RELAY_Q0 27-UV
%   demo (Vb02 dip <0.8pu, 0.1s definite; OC at Q0 needs CTs there in reality).
% New blocks only; original wiring untouched. Ends with update check (sim in T4).
p=inputParser; addParameter(p,'Show',false); parse(p,varargin{:});
root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode';
mdl='Load_Flow_V2';
slx=fullfile(root,'simulink','studies',[mdl '.slx']);
load_system(slx);
lib='sps_lib'; load_system(lib);

% ---- Q9 breaker insert (dedicated direct lines) ----
hVI=get_param([mdl '/VI_GRID'],'Handle'); hEX=get_param([mdl '/EXT GRID'],'Handle');
cutExact(mdl,hVI,hEX);
add_block([lib '/Power Grid Elements/Three-Phase Breaker'],[mdl '/BRK_Q9'],'Position',[745 180 785 230]);
set_param([mdl '/BRK_Q9'],'InitialState','closed','SwitchA','on','SwitchB','on','SwitchC','on','External','on');
phV=get_param([mdl '/VI_GRID'],'PortHandles'); phB=get_param([mdl '/BRK_Q9'],'PortHandles');
phE=get_param([mdl '/EXT GRID'],'PortHandles');
for k=1:3
  add_line(mdl,phV.RConn(k),phB.LConn(k));
  add_line(mdl,phB.RConn(k),phE.RConn(k));
end
fprintf('BRK_Q9 inserted\n');

% ---- Q0 breaker block (XML wiring by xml_series_q0.ps1) ----
add_block([lib '/Power Grid Elements/Three-Phase Breaker'],[mdl '/BRK_Q0'],'Position',[60 200 100 250]);
set_param([mdl '/BRK_Q0'],'InitialState','closed','SwitchA','on','SwitchB','on','SwitchC','on','External','on');
fprintf('BRK_Q0 placed (XML wiring next)\n');

% ---- RELAY_Q9: IEC-SI OC, pickup 1031A TMS 0.281 ----
mkOC(mdl,'RELAY_Q9',[800 40 970 220],1031,0.281);
phG=get_param([mdl '/VI_GRID'],'PortHandles'); phR=get_param([mdl '/RELAY_Q9'],'PortHandles');
add_line(mdl,phG.Outport(2),phR.Inport(1)); % Iabc signal branch (legal)
add_block('simulink/Sinks/To Workspace',[mdl '/TRIP_Q9'],'Position',[990 100 1100 120], ...
  'VariableName','TRIP_Q9','SaveFormat','StructureWithTime','SampleTime','5e-5');
phT9=get_param([mdl '/TRIP_Q9'],'PortHandles'); phBe=get_param([mdl '/BRK_Q9'],'PortHandles');
% NOTE (verified): SPS external breaker treats control 0 as OPEN, so the trip
% feeds through a NOT gate: normal relay 0 -> NOT -> 1 = closed; trip 1 -> 0 = open.
add_block('simulink/Logic and Bit Operations/Logical Operator',[mdl '/NOT_Q9'],'Position',[960 130 990 160]);
set_param([mdl '/NOT_Q9'],'Operator','NOT');
phN9=get_param([mdl '/NOT_Q9'],'PortHandles');
add_line(mdl,phR.Outport(1),phN9.Inport(1));
add_line(mdl,phN9.Outport(1),phBe.Inport(1));
add_line(mdl,phR.Outport(1),phT9.Inport(1));

% ---- RELAY_Q0: 27 UV demo, dip <106232V (0.8pu), 0.1s definite ----
mkUV(mdl,'RELAY_Q0',[60 420 230 580],106232,112872,10);
add_block('built-in/Mux',[mdl '/MUX_V'],'Position',[560 450 590 530]);
set_param([mdl '/MUX_V'],'Inputs','3');
for k=1:3
  phVm=get_param([mdl '/' sprintf('Vb02_ph%d',k)],'PortHandles');
  phMx=get_param([mdl '/MUX_V'],'PortHandles');
  add_line(mdl,phVm.Outport(1),phMx.Inport(k));
end
add_line(mdl,phMx.Outport(1),phR0In(mdl));
add_block('simulink/Sinks/To Workspace',[mdl '/TRIP_Q0'],'Position',[250 470 360 490], ...
  'VariableName','TRIP_Q0','SaveFormat','StructureWithTime','SampleTime','5e-5');
phR0=get_param([mdl '/RELAY_Q0'],'PortHandles'); phT0=get_param([mdl '/TRIP_Q0'],'PortHandles');
phB0=get_param([mdl '/BRK_Q0'],'PortHandles');
add_block('simulink/Logic and Bit Operations/Logical Operator',[mdl '/NOT_Q0'],'Position',[120 470 150 500]);
set_param([mdl '/NOT_Q0'],'Operator','NOT');
phN0=get_param([mdl '/NOT_Q0'],'PortHandles');
add_line(mdl,phR0.Outport(1),phN0.Inport(1));
add_line(mdl,phN0.Outport(1),phB0.Inport(1));
add_line(mdl,phR0.Outport(1),phT0.Inport(1));
save_system(mdl,slx);
fprintf('API part done; run xml_series_q0.ps1 next\n');
if p.Results.Show, open_system(mdl); else, close_system(mdl,0); end
end

function h=phR0In(mdl)
phR=get_param([mdl '/RELAY_Q0'],'PortHandles'); h=phR.Inport(1);
end

function cutExact(mdl,hs,hd)
ls=find_system(mdl,'FindAll','on','Type','line');
for k=1:numel(ls)
  try, s=get_param(ls(k),'SrcBlockHandle'); d=get_param(ls(k),'DstBlockHandle'); catch, continue; end
  if isequal(s,hs) && isequal(d,hd), delete_line(ls(k)); end
end
end

function mkOC(mdl,name,pos,Is,TMS)
%MKOC IEC-SI overcurrent: Fourier magnitudes -> max -> inverse timer.
add_block('built-in/SubSystem',[mdl '/' name],'Position',pos);
s=[mdl '/' name];
add_block('built-in/Inport',[s '/Iabc'],'Position',[30 90 60 110]);
add_block('built-in/Demux',[s '/demux'],'Position',[120 80 160 170]);
set_param([s '/demux'],'Outputs','3','BusSelectionMode','off');
lib='sps_lib'; load_system(lib); nl=char(10);
FT=[lib '/Sensors and Measurements/Fourier'];
ph={};
for k=1:3
  f=[s '/F' num2str(k)];
  add_block(FT,f,'Position',[200 (45+50*k) 240 (65+50*k)]);
  set_param(f,'Freq','50','n','1');
  ph{end+1}=get_param(f,'PortHandles'); %#ok<AGROW>
end
add_block('built-in/MinMax',[s '/mx'],'Position',[300 95 340 135]);
set_param([s '/mx'],'Function','max','Inputs','3');
add_block('simulink/Logic and Bit Operations/Compare To Constant',[s '/pu'],'Position',[390 90 450 130]);
set_param([s '/pu'],'relop','>','const',sprintf('%.6g',Is));
add_block('built-in/Fcn',[s '/rate'],'Position',[390 150 480 190]);
set_param([s '/rate'],'Expr',sprintf('(((u/%.6g)^0.02)-1)/(%.6g*0.14)',Is,TMS));
add_block('built-in/Constant',[s '/zero'],'Position',[390 200 430 220]);
set_param([s '/zero'],'Value','0');
add_block('built-in/Switch',[s '/gate'],'Position',[540 100 580 180]);
set_param([s '/gate'],'Criteria','u2 ~= 0','Threshold','0');
add_block('built-in/Integrator',[s '/acc'],'Position',[630 100 670 160]);
set_param([s '/acc'],'InitialCondition','0');
add_block('simulink/Logic and Bit Operations/Compare To Constant',[s '/drop'],'Position',[390 240 450 280]);
set_param([s '/drop'],'relop','<','const',sprintf('%.6g',0.95*Is));
add_block('simulink/Logic and Bit Operations/Compare To Constant',[s '/fired'],'Position',[720 100 780 140]);
set_param([s '/fired'],'relop','>=','const','1');
add_block('built-in/Outport',[s '/trip'],'Position',[830 100 860 120]);
phS=get_param([s '/Iabc'],'PortHandles'); phD=get_param([s '/demux'],'PortHandles');
add_line(s,phS.Outport(1),phD.Inport(1));
for k=1:3
  add_line(s,phD.Outport(k),ph{k}.Inport(1));
  add_line(s,ph{k}.Outport(1),get_param([s '/mx'],'PortHandles').Inport(k));
end
phM=get_param([s '/mx'],'PortHandles');
add_line(s,phM.Outport(1),get_param([s '/pu'],'PortHandles').Inport(1));
add_line(s,phM.Outport(1),get_param([s '/rate'],'PortHandles').Inport(1));
add_line(s,phM.Outport(1),get_param([s '/drop'],'PortHandles').Inport(1));
phG=get_param([s '/gate'],'PortHandles'); phZ=get_param([s '/zero'],'PortHandles');
add_line(s,get_param([s '/rate'],'PortHandles').Outport(1),phG.Inport(1));
add_line(s,get_param([s '/pu'],'PortHandles').Outport(1),phG.Inport(2));
add_line(s,phZ.Outport(1),phG.Inport(3));
phA=get_param([s '/acc'],'PortHandles');
add_line(s,phG.Outport(1),phA.Inport(1));
add_line(s,phA.Outport(1),get_param([s '/fired'],'PortHandles').Inport(1));
add_line(s,get_param([s '/fired'],'PortHandles').Outport(1),get_param([s '/trip'],'PortHandles').Inport(1));
fprintf('relay %s built\n',name);
end

function mkUV(mdl,name,pos,Vdrop,Vreset,rate)
%MKUV Definite-time undervoltage: min phase < Vdrop for 1/rate s -> trip.
add_block('built-in/SubSystem',[mdl '/' name],'Position',pos);
s=[mdl '/' name];
add_block('built-in/Inport',[s '/Vabc'],'Position',[30 90 60 110]);
add_block('built-in/Demux',[s '/demux'],'Position',[120 80 160 170]);
set_param([s '/demux'],'Outputs','3','BusSelectionMode','off');
lib='sps_lib'; load_system(lib);
FT=[lib '/Sensors and Measurements/Fourier'];
for k=1:3
  f=[s '/F' num2str(k)];
  add_block(FT,f,'Position',[200 (45+50*k) 240 (65+50*k)]);
  set_param(f,'Freq','50','n','1');
end
add_block('built-in/MinMax',[s '/mn'],'Position',[300 95 340 135]);
set_param([s '/mn'],'Function','min','Inputs','3');
add_block('simulink/Logic and Bit Operations/Compare To Constant',[s '/dp'],'Position',[390 90 450 130]);
set_param([s '/dp'],'relop','<','const',sprintf('%.6g',Vdrop));
add_block('built-in/Constant',[s '/rate'],'Position',[390 150 430 170]);
set_param([s '/rate'],'Value',sprintf('%.6g',rate));
add_block('built-in/Constant',[s '/zero'],'Position',[390 200 430 220]);
set_param([s '/zero'],'Value','0');
add_block('built-in/Switch',[s '/gate'],'Position',[540 100 580 180]);
set_param([s '/gate'],'Criteria','u2 ~= 0','Threshold','0');
add_block('built-in/Integrator',[s '/acc'],'Position',[630 100 670 160]);
set_param([s '/acc'],'InitialCondition','0');
add_block('simulink/Logic and Bit Operations/Compare To Constant',[s '/rst'],'Position',[390 240 460 280]);
set_param([s '/rst'],'relop','>','const',sprintf('%.6g',Vreset));
add_block('simulink/Logic and Bit Operations/Compare To Constant',[s '/fired'],'Position',[720 100 780 140]);
set_param([s '/fired'],'relop','>=','const','1');
add_block('built-in/Outport',[s '/trip'],'Position',[830 100 860 120]);
phS=get_param([s '/Vabc'],'PortHandles'); phD=get_param([s '/demux'],'PortHandles');
add_line(s,phS.Outport(1),phD.Inport(1));
for k=1:3
  add_line(s,phD.Outport(k),get_param([s '/F' num2str(k)],'PortHandles').Inport(1));
  add_line(s,get_param([s '/F' num2str(k)],'PortHandles').Outport(1),get_param([s '/mn'],'PortHandles').Inport(k));
end
phM=get_param([s '/mn'],'PortHandles');
add_line(s,phM.Outport(1),get_param([s '/dp'],'PortHandles').Inport(1));
add_line(s,phM.Outport(1),get_param([s '/rst'],'PortHandles').Inport(1));
phG=get_param([s '/gate'],'PortHandles');
add_line(s,get_param([s '/rate'],'PortHandles').Outport(1),phG.Inport(1));
add_line(s,get_param([s '/dp'],'PortHandles').Outport(1),phG.Inport(2));
add_line(s,get_param([s '/zero'],'PortHandles').Outport(1),phG.Inport(3));
phA=get_param([s '/acc'],'PortHandles');
add_line(s,phG.Outport(1),phA.Inport(1));
add_line(s,phA.Outport(1),get_param([s '/fired'],'PortHandles').Inport(1));
add_line(s,get_param([s '/fired'],'PortHandles').Outport(1),get_param([s '/trip'],'PortHandles').Inport(1));
fprintf('relay %s built\n',name);
end



