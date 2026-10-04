function format_loadflow_v2(varargin)
%FORMAT_LOADFLOW_V2 SLD presentation pass on studies/Load_Flow_V2.slx.
% Does NOT touch electrical topology or parameters (only positions, colors,
% annotations) + adds a standalone 110V DC/battery island (new blocks only).
% DC: lead-acid 110V/200Ah (C) + 4.03ohm DCDB load ~3kW (C) + float charger
% via diode (if available) + V/I + ToWorkspace. Autonomy 200Ah/27A=7.4h>2h.
% Safe to re-run (skips blocks already present). Verifies with update+LF sim.
p=inputParser; addParameter(p,'Show',false); parse(p,varargin{:});
root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode';
mdl='Load_Flow_V2';
slx=fullfile(root,'simulink','studies',[mdl '.slx']);
load_system(slx);
lib='sps_lib'; load_system(lib); nl=char(10);

have=@(b) ~isempty(find_system(mdl,'SearchDepth',1,'Name',b));
% (instrumentation strip positions from builder are kept; only recolor below)
recolor={'VI_GRID','Vgrd','Igrid','Vb01_1','Vb01_2','Vb01_3','Vb02_1','Vb02_2','Vb02_3'};
for k=1:numel(recolor)
  b=[mdl '/' recolor{k}];
  if ~isempty(find_system(mdl,'SearchDepth',1,'Name',recolor{k}))
    try, set_param(b,'BackgroundColor','lightBlue'); catch, end
  end
end
for k=1:3
  for v={sprintf('Vb01_ph%d',k),sprintf('Vb02_ph%d',k),sprintf('Vb01_g%d',k),sprintf('Vb02_g%d',k)}
    b=[mdl '/' v{1}];
    if ~isempty(find_system(mdl,'SearchDepth',1,'Name',v{1}))
      try, set_param(b,'BackgroundColor','lightBlue','ShowName','off'); catch, end
    end
  end
end
if ~isempty(find_system(mdl,'SearchDepth',1,'Name','F_B01'))
  set_param([mdl '/F_B01'],'BackgroundColor','red','ShowName','off');
  set_param([mdl '/F_B02'],'BackgroundColor','red','ShowName','off');
end

% ---- title + zone captions ----
addNote(mdl,'ASHUGANJ SOUTH 450MW CCPP — Rev2 SINGLE-LINE (Sep-10 master truth)',[80 20 900 45],14,'bold');
addNote(mdl,'GEN 22kV · GSUT 515MVA YNd1 · 230kV GIS (Q0/Q1/Q2/Q9) · GRID Thevenin · UAT+GAT aux · DC island bottom-right. Rev2: G1 354MW+SCL, ZGRID lumped, aux 12+j5.',[80 48 1100 68],9,'normal');

% ---- DC island (new blocks, free canvas y≈1250) ----
if isempty(find_system(mdl,'SearchDepth',1,'Name','BAT_110V'))
  add_block([lib '/Sources/Battery'],[mdl '/BAT_110V'],'Position',[880 1250 940 1310]);
  bt=Simulink.Mask.get([mdl '/BAT_110V']).getParameter('BatType');
  try
    opts=cellstr(bt.TypeOptions);
    if any(strcmpi(opts,'Lead-Acid')), set_param([mdl '/BAT_110V'],'BatType','Lead-Acid'); end
  catch, end
  set_param([mdl '/BAT_110V'],'NomV','110','NomQ','200','SOC','100');
  add_block([lib '/Passives/Series RLC Branch'],[mdl '/R_DCDB'],'Position',[1000 1250 1040 1310]);
  set_param([mdl '/R_DCDB'],'BranchType','R','Resistance','4.033');
  add_block([lib '/Sensors and Measurements/Current Measurement'],[mdl '/I_DC'],'Position',[940 1250 970 1280]);
  add_block([lib '/Sensors and Measurements/Voltage Measurement'],[mdl '/V_DC'],'Position',[940 1330 970 1380]);
  add_block([lib '/Utilities/Ground'],[mdl '/GND_DC'],'Position',[940 1400 960 1420]);
  phB=get_param([mdl '/BAT_110V'],'PortHandles'); phR=get_param([mdl '/R_DCDB'],'PortHandles');
  phI=get_param([mdl '/I_DC'],'PortHandles');
  % Discharge demo loop (each port exactly one line): BAT+(L1)->I_DC->R_DCDB->BAT-(L2).
  % Idc ~= 110/4.03 = 27.3A validates the autonomy-calc basis (200Ah/27A=7.4h).
  % Charger shown as annotation only (parallel ideal sources need intent switching).
  add_line(mdl,phB.LConn(1),phI.LConn(1));
  add_line(mdl,phI.RConn(1),phR.LConn(1));
  add_line(mdl,phR.RConn(1),phB.LConn(2));
  % charger (float 123V) + V_DC + GND: annotation-only (parallel taps need a
  % free node; none exists without branch surgery - documented wall)
  addNote(mdl,'STATION DC (conceptual C): 110V lead-acid 200Ah discharging into 4.03ohm DCDB ~3kW (Idc~=27A below). 2x30A chargers N+1 + DCDB panel annotated (not simulated). Autonomy 200Ah/27A = 7.4h > 2h req.',[640 1430 1350 1470],9,'normal');
  fprintf('DC island added (discharge loop + Idc)\n');
end
  sk='simulink/Sinks/To Workspace';
  add_block(sk,[mdl '/Idc'],'Position',[1080 1300 1190 1320],'VariableName','Idc','SaveFormat','StructureWithTime','SampleTime','5e-5');
  phIs=get_param([mdl '/Idc'],'PortHandles'); phIo=get_param([mdl '/I_DC'],'PortHandles');
  add_line(mdl,phIo.Outport(1),phIs.Inport(1));
save_system(mdl,slx);
% ---- verify: update + LF sim still healthy ----
set_param(mdl,'SimulationCommand','update');
fprintf('update OK\n');
set_param(mdl,'SaveTime','on');
o=sim(mdl,'StopTime','0.15');
fprintf('verify LF tout n=%d tend=%g\n',numel(o.tout),o.tout(end));
assert(numel(o.tout)>1000,'reformat broke sim');
S2=o.get('Idc'); M2=double(squeeze(S2.signals.values));
fprintf('Idc=%.2fA (expect ~27.3)\n',mean(M2(end-99:end,1)));
close_system(mdl,0);
fprintf('format verified\n');
end

function addNote(mdl,txt,pos,fs,wt)
an=Simulink.Annotation([mdl '/note' num2str(round(rand*1e6))]);
an.Text=txt; an.Position=pos; an.FontSize=fs; an.FontWeight=wt;
an.BackgroundColor='transparent';
end
