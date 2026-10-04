function build_loadflow_v2(varargin)
%BUILD_LOADFLOW_V2 Clone studies/Load_Flow.slx -> Load_Flow_V2.slx (Rev2).
% Rev2 corrections (Sep-10 master truth, param changes ONLY - no AC rewiring):
%  G1 Pref 389.3->354MW + NonIdeal SCL 2.037GVA X/R266.9 (Xd''sat, B)
%  ZGRID lumped line07+Thevenin: R 1.0->0.296ohm, X 2.657->3.062ohm (B/C;
%   equals engine D.br023 series; B03=B02 node in Simulink, engine covers B03)
%  GSUT Z 16.0->16.63% R 0.21->0.1771% own-base, Rm 155.3kW (B/D), L0=Z1 (C)
%  Aux single 12+j5 on LOAD_B6_6 (C); WI feeders 1W (SPS min, negligible)
% Additions (all API-safe patterns, XML-verified): series VI_GRID on the
%  dedicated ZGRID_R->EXTGRID direct lines (handle form); 6x single-phase
%  Voltage Measurement bus taps B01/B02 (string taps merge into branch trees -
%  verified by Dst refs in XML); handle-form sink lines; 50us sink sampling.
% NO fault blocks in the file (runner adds/deletes per case). NO GUI-branch
% surgery: R2024a code cannot branch an occupied physical port (API wall).
p=inputParser; addParameter(p,'Show',false); parse(p,varargin{:});
root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode';
src=fullfile(root,'simulink','studies','Load_Flow.slx');
dst=fullfile(root,'simulink','studies','Load_Flow_V2.slx');
mdl='Load_Flow_V2';
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist(dst,'file'), delete(dst); end
copyfile(src,dst);
load_system(dst);

% ---- corrections ----
set_param([mdl '/G1'],'Pref','354e6','NonIdealSource','on','SpecifyImpedance','on', ...
  'ShortCircuitLevel','2.0374e9','BaseVoltage','22000','XRratio','266.9');
set_param([mdl '/ZGRID'],'BranchType','RL','Resistance','0.296','Inductance','9.747e-3');
set_param([mdl '/GSUT 10BAT10'],'Winding1','[ 230000 , 0.0008855 , 0.083145 ]', ...
  'Winding2','[ 22000 , 0.0008855 , 0.083145 ]','Rm','3316.5','L0','0.1663');
set_param([mdl '/LOAD_B6_6'],'ActivePower','12e6','InductivePower','5e6');
set_param([mdl '/LOAD_B6_6_WI1'],'ActivePower','1','InductivePower','1');
set_param([mdl '/LOAD_B6_6_WI2'],'ActivePower','1','InductivePower','1');

lib='sps_lib'; load_system(lib); nl=char(10);
VI=[lib '/Sensors and Measurements/Three-Phase' nl 'V-I Measurement'];
VM=[lib '/Sensors and Measurements/Voltage Measurement'];
GND=[lib '/Utilities/Ground'];

% ---- VI_GRID series insert on dedicated direct ZGRID_R->EXTGRID lines ----
hZGRID=get_param([mdl '/ZGRID'],'Handle'); hGRID=get_param([mdl '/EXT GRID'],'Handle');
cutExact(mdl,hZGRID,hGRID);
add_block(VI,[mdl '/VI_GRID'],'Position',[700 175 740 225]);
phZ=get_param([mdl '/ZGRID'],'PortHandles'); phG=get_param([mdl '/VI_GRID'],'PortHandles');
phE=get_param([mdl '/EXT GRID'],'PortHandles');
for k=1:3
  add_line(mdl,phZ.RConn(k),phG.LConn(k));
  add_line(mdl,phG.RConn(k),phE.RConn(k));
end
verifyDst(mdl,'ZGRID','RConn','VI_GRID','LConn');
verifyDst(mdl,'VI_GRID','RConn','EXT GRID','RConn');

% ---- VI_GRID sinks (handle form, 50us) ----
sk='simulink/Sinks/To Workspace';
add_block(sk,[mdl '/Vgrd'],'Position',[860 60 970 80], ...
  'VariableName','Vgrd','SaveFormat','StructureWithTime','SampleTime','5e-5');
add_block(sk,[mdl '/Igrid'],'Position',[860 110 970 130], ...
  'VariableName','Igrid','SaveFormat','StructureWithTime','SampleTime','5e-5');
phGs=get_param([mdl '/Vgrd'],'PortHandles'); phIs=get_param([mdl '/Igrid'],'PortHandles');
add_line(mdl,phG.Outport(1),phGs.Inport(1));
add_line(mdl,phG.Outport(2),phIs.Inport(1));

% ---- bus voltage taps B01 (GSUT R) + B02 (GSUT L), 3 phases each ----
addVTap(mdl,'GSUT 10BAT10','R','Vb01');
addVTap(mdl,'GSUT 10BAT10','L','Vb02');
% ---- fault blocks (UNCONNECTED in file; runner taps via XML per case) ----
FT=[lib '/Power Grid Elements/Three-Phase Fault'];
add_block(FT,[mdl '/F_B01'],'Position',[280 290 320 340]);
add_block(FT,[mdl '/F_B02'],'Position',[120 120 160 170]);
setFaultOff([mdl '/F_B01']); setFaultOff([mdl '/F_B02']);
set_param(mdl,'StopTime','0.3');
save_system(mdl,dst);
fprintf('Built Load_Flow_V2.slx\n');
if p.Results.Show, open_system(mdl); else, close_system(mdl,0); end
end

function cutExact(mdl,hs,hd)
ls=find_system(mdl,'FindAll','on','Type','line');
for k=1:numel(ls)
  try, s=get_param(ls(k),'SrcBlockHandle'); d=get_param(ls(k),'DstBlockHandle'); catch, continue; end
  if isequal(s,hs) && isequal(d,hd), delete_line(ls(k)); end
end
end

function verifyDst(mdl,sb,ss,db,ds)
phS=get_param([mdl '/' sb],'PortHandles'); phD=get_param([mdl '/' db],'PortHandles');
hD=get_param([mdl '/' db],'Handle');
ok=true;
for k=1:3
  eval(['ln=get_param(phS.' ss '(k),''Line'');']);
  try, d=get_param(ln,'DstBlockHandle'); catch, d=-1; end
  if ~any(d==hD), ok=false; end
end
if ~ok, error('build_loadflow_v2:wiring','%s->%s not connected',sb,db); end
fprintf('wired %s->%s OK\n',sb,db);
end

function addVTap(mdl,nodeBlk,side,base)
%ADDVTAP 3x single-phase Voltage Measurement + grounds + sinks on a bus node.
% String taps merge into the branch tree (verified via Dst refs in XML).
sk='simulink/Sinks/To Workspace';
lib='sps_lib'; load_system(lib);
VM=[lib '/Sensors and Measurements/Voltage Measurement'];
GND=[lib '/Utilities/Ground'];

for k=1:3
  vm=[base '_ph' num2str(k)]; gd=[base '_g' num2str(k)];
  add_block(VM,[mdl '/' vm],'Position',[860 100+90*k 900 130+90*k]);
  add_block(GND,[mdl '/' gd],'Position',[860 140+90*k 880 160+90*k]);
  if strcmpi(side,'L'), np=[nodeBlk '/LConn' num2str(k)]; else, np=[nodeBlk '/RConn' num2str(k)]; end
  add_line(mdl,np,[vm '/LConn1'],'autorouting','on');
  phG=get_param([mdl '/' gd],'PortHandles'); phVm=get_param([mdl '/' vm],'PortHandles');
  add_line(mdl,phVm.LConn(2),phG.LConn(1));
  add_block(sk,[mdl '/' base '_' num2str(k)],'Position',[930 100+90*k 1040 120+90*k], ...
    'VariableName',[base '_' num2str(k)],'SaveFormat','StructureWithTime','SampleTime','5e-5');
  phV=get_param([mdl '/' vm],'PortHandles'); phS=get_param([mdl '/' base '_' num2str(k)],'PortHandles');
  add_line(mdl,phV.Outport(1),phS.Inport(1));
end
fprintf('voltage taps %s OK (verify Dst refs in XML)\n',base);
end


function setFaultOff(blk)
set_param(blk,'FaultA','off','FaultB','off','FaultC','off','GroundFault','off', ...
  'SwitchTimes','[0.05]','External','off','FaultResistance','1e-4', ...
  'GroundResistance','1e-4','Measurements','None');
end
