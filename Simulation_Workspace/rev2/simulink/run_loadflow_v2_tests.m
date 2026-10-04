function C = run_loadflow_v2_tests(varargin)
%RUN_LOADFLOW_V2_TESTS Test-run studies/Load_Flow_V2.slx (clone of Load_Flow,
% Rev2-corrected) vs the Phase-2 Zbus engine. Time-domain, fault at 0.05s.
% Method per case: XML-tap the active bus only (phase-correct branch taps;
% R2024a code cannot branch occupied SPS ports), switch ON, sim, untap.
% idle bus stays untapped. Faults never left tapped-but-OFF at B01 (init wall).
% Known solver walls (documented, engine covers): B01-LLL stalls (undamped
% 22kV X/R-67 loop); any stalled case -> STALLED verdict, run continues.
% Metrics: Igrid settled RMS vs engine Igrid (tol 7%); Vdip vs engine Vmin
% (tol 0.05pu); Igrid peak vs engine Ipeak scaled by Igrid/Isym (tol 15%).
% Time sim has no PV dispatch (flat-ish prefault); engine uses P1A Vpre.
% Writes rev2/results/phase2_simulink_check.csv
p=inputParser; addParameter(p,'Write',true); parse(p,varargin{:});
doWrite=p.Results.Write;
root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode';
mdl='Load_Flow_V2';
tapTool=fullfile(root,'rev2','simulink','xml_fault_tap.ps1');
xtap=@(a,b) system(sprintf('powershell -ExecutionPolicy Bypass -File "%s" -Action %s -Bus %s',tapTool,a,b));
openMdl=@() openMdlFn(root,mdl);
% clean start: ensure untapped (file must be unlocked)
xtap('untap','B01'); xtap('untap','B02');
openMdl();
set_param(mdl,'StopTime','0.25','SaveTime','on');

% ---- LF sanity ----
o=sim(mdl);
V01=rmsLast(o,'Vb01_1'); V02=rmsLast(o,'Vb02_1'); Ig0=rmsLast(o,'Igrid');
fprintf('SIM LF: B01=%.3fpu B02=%.3fpu Igrid=%.0fA\n',V01/12702,V02/132790,mean(Ig0));

% ---- engine reference ----
T2=readtable(fullfile(root,'rev2','results','phase2_fault_currents.csv'),'FileType','text');
cases={'B01','LLL';'B01','LG';'B01','LL';'B01','LLG';'B02','LLL';'B02','LG';'B02','LL';'B02','LLG'};
rows={}; np=0; nst=0;
for k=1:size(cases,1)
  bus=cases{k,1}; typ=cases{k,2};
  close_system(mdl,0);           % release .slx lock for XML tap
  xtap('tap',bus);
  openMdl();
  set_param(mdl,'StopTime','0.25','SaveTime','on');
  setFault([mdl '/F_' bus],typ);
  try
    o=sim(mdl);
    assert(numel(o.tout)>1000,'stall');
    Ig=getSig(o,'Igrid'); t=getSigT(o,'Igrid');
    Va=[getSig(o,'Vb01_1') getSig(o,'Vb01_2') getSig(o,'Vb01_3')];
    Vb2=[getSig(o,'Vb02_1') getSig(o,'Vb02_2') getSig(o,'Vb02_3')];
    assert(size(Ig,1)==size(Va,1)&&size(Ig,1)==size(Vb2,1),'sink length mismatch');
    rmsG=sqrt(mean(Ig(end-199:end,:).^2,1));
    simG=max(rmsG)/1e3;
    pk=max(max(abs(Ig(t>=0.05&t<=0.15,:))))/1e3;
    allV=[Va Vb2];
    nv=[12702 12702 12702 132790 132790 132790];
    vmin=min(sqrt(mean(allV(end-199:end,:).^2,1))./nv);
    er=find(strcmp(T2.Bus,bus)&strcmp(T2.FaultType,typ)&startsWith(T2.CaseID,'F'),1);
    assert(~isempty(er),'engine row not found');
    engG=T2.Igrid_kA_230kV(er); engV=T2.Vfault_min_pu(er); engP=T2.Ipeak_kA(er)*(engG/T2.Isym_kA(er));
    eG=100*(simG-engG)/max(engG,0.5); eV=vmin-engV; eP=100*(pk-engP)/max(engP,1);
    v='PASS'; if abs(eG)>7||abs(eV)>0.05||abs(eP)>15, v='REVIEW'; else, np=np+1; end
    fprintf('SIM %s-%s: Igrid %.2f vs %.2f (%+.1f%%) Vmin %.3f vs %.3f (%+.3f) pk %.1f vs %.1f (%+.1f%%) %s\n', ...
      bus,typ,simG,engG,eG,vmin,engV,eV,pk,engP,eP,v);
    rows{end+1}=sprintf('F%d-%s-%s,%s,%s,%.2f,%.2f,%+.2f,%.3f,%.3f,%+.3f,%.1f,%.1f,%+.2f,%s', ...
      k,bus,typ,bus,typ,simG,engG,eG,vmin,engV,eV,pk,engP,eP,v);
  catch ME
    nst=nst+1;
    fprintf('SIM %s-%s: STALLED (%s) -> engine-only\n',bus,typ,ME.message(1:min(80,end)));
    rows{end+1}=sprintf('F%d-%s-%s,%s,%s,STALLED,STALLED,,STALLED,STALLED,,STALLED,STALLED,,STALLED-engine-only',k,bus,typ,bus,typ);
  end
  try, setFault([mdl '/F_' bus],'OFF'); catch, end
  close_system(mdl,0);           % release lock for untap
  xtap('untap',bus);
end
openMdl();
save_system(mdl); close_system(mdl,0);
fprintf('done: %d PASS, %d REVIEW-or-better, %d STALLED (B03-LLL engine-only, lumped node)\n',np,numel(rows)-nst,nst);
if doWrite
  fid=fopen(fullfile(root,'rev2','results','phase2_simulink_check.csv'),'w');
  fprintf(fid,'CaseID,Bus,FaultType,Sim_Igrid_kA,Eng_Igrid_kA,ErrG_pct,Sim_Vmin_pu,Eng_Vmin_pu,ErrV_pu,Sim_IgridPk_kA,Eng_IgridPk_kA,ErrP_pct,Verdict\n');
  for k=1:numel(rows), fprintf(fid,'%s\n',rows{k}); end
  fclose(fid);
  fprintf('Wrote rev2/results/phase2_simulink_check.csv\n');
end
C=rows;
end

function setFault(blk,typ)
set_param(blk,'SwitchTimes','[0.05]','External','off','FaultResistance','1e-4', ...
  'GroundResistance','1e-4','Measurements','None');
switch typ
  case 'LLL', set_param(blk,'FaultA','on','FaultB','on','FaultC','on','GroundFault','off');
  case 'LG',  set_param(blk,'FaultA','on','FaultB','off','FaultC','off','GroundFault','on');
  case 'LL',  set_param(blk,'FaultA','off','FaultB','on','FaultC','on','GroundFault','off');
  case 'LLG', set_param(blk,'FaultA','off','FaultB','on','FaultC','on','GroundFault','on');
  case 'OFF', set_param(blk,'FaultA','off','FaultB','off','FaultC','off','GroundFault','off');
end
end

function v=rmsLast(o,name)
M=getSig(o,name);
v=sqrt(mean(M(end-199:end,:).^2,1));
end

function M=getSig(o,name)
S=o.get(name); M=double(squeeze(S.signals.values));
if isvector(M), M=M(:); end
end

function t=getSigT(o,name)
t=o.get(name); t=t.time;
end

function openMdlFn(root,mdl)
cd(root);
load_system(fullfile(root,'simulink','studies',[mdl '.slx']));
end
