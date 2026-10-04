function R = run_phase3_protection(varargin)
%RUN_PHASE3_PROTECTION Rev2 Phase 3 OC/EF coordination (Sep-10 master truth).
% Starting assumptions, ALL C (master §21): OC pickup 1.2xFL, IEC-SI,
% TMS 0.2 (OC) / 0.15 (EF); EF pickup 0.2A sec; grading margin 0.3s;
% diff bias/start 0.3pu slopes 30/60% (xfmr), gen diff start 0.2pu.
% CT rule (C): next standard tap of {400,800,1600} above 1.25xFL.
% Method: downstream relays fixed at starting TMS; upstream TMS solved from
%   t_up(I) = t_down(I)+0.3 at the common fault current. TMS>1.0 -> REVIEW.
% Fault currents read from rev2/results/phase2_fault_currents.csv (true kA).
% GSUT-HV relay sees: B01 faults = grid infeed (Igrid, series-exact);
%   B02/B03 faults = gen share referred (Igen*22/230, series-exact).
% B11 LV fault estimated: Thevenin Zth1(B01) + UAT Z (ignores aux shunt, C).
% Usage: R=run_phase3_protection() writes phase3_*.csv; ('Write',false) solves.
p=inputParser; addParameter(p,'Write',true); parse(p,varargin{:});
doWrite=p.Results.Write;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'data'));
D=ashuganj_rev2_registry();

% ---- max load currents (P1A) ----
T1=readtable(fullfile(here,'results','phase1_system_summary.csv'),'FileType','text');
iA=strcmp(T1.CaseID,'P1A');
Sgs=T1.Sgs_MVA(iA); Iline=T1.Line_I_A(iA);
FL.gsutHV=Sgs*1e6/(sqrt(3)*230e3);      % ~859A
FL.line=Iline;                          % ~859A
Saux=hypot(D.aux.P_MW,D.aux.Q_MVAr);    % 13MVA
FL.uatHV=Saux*1e6/(sqrt(3)*22e3);       % ~341A
FL.uatLV=Saux*1e6/(sqrt(3)*6.6e3);      % ~1137A

% ---- fault currents per zone (Phase-2 CSV, true kA) ----
T2=readtable(fullfile(here,'results','phase2_fault_currents.csv'),'FileType','text');
base=~startsWith(T2.CaseID,'S');
isBus=@(b) strcmp(T2.Bus,b)&base;
isTyp=@(t) strcmp(T2.FaultType,t);
% gen share referred to HV in kA (series-exact): Igen(22kV)*22/230
genHV=@(b,t) T2.Igen_kA_22kV(find(isBus(b)&isTyp(t),1))*22/230;
grd=@(b,t) T2.Igrid_kA_230kV(find(isBus(b)&isTyp(t),1));
FT={'LLL','LG','LL','LLG'};
% GSUT-HV sees (kA): B01 faults via grid infeed; B02/B03 via gen share
fGSUT=[arrayfun(@(k) grd('B01',FT{k}),1:4), arrayfun(@(k) genHV('B02',FT{k}),1:4), genHV('B03','LLL')]*1e3; % -> A
% LINE sees grid infeed everywhere (kA -> A)
fLINE=[arrayfun(@(k) grd('B01',FT{k}),1:4), arrayfun(@(k) grd('B02',FT{k}),1:4), grd('B03','LLL')]*1e3; % -> A
% B11 LV fault estimate (Thevenin B01 + UAT series, C-approx)
TZ=readtable(fullfile(here,'results','phase2_sequence_Z.csv'),'FileType','text');
iB=strcmp(TZ.Bus,'B01');
Zth=TZ.Zth1_R_pu(iB)+1j*TZ.Zth1_X_pu(iB);
Zuat=D.uat.R_pu_sys+1j*D.uat.X_pu_sys;
Ipu_B11=1/abs(Zth+Zuat);
I_B11=Ipu_B11*100/(sqrt(3)*6.6)*1e3; % A @6.6kV
I_B11HV=I_B11*6.6/22;               % A referred to 22kV
% EF residuals: neutral current = 3I0 from LG/LLG cases (I0_mag_pu -> A @230kV)
Ib230=100/(sqrt(3)*230)*1e3; % A
resB02=3*max(T2.I0_mag_pu(isBus('B02')))*Ib230; % A, worst ground fault @B02

% ---- relay build ----
mkOC=@(zone,ct,fl,fmax,fmin,tms) mkRelay(zone,ct,fl,fmax,fmin,tms);
relays=[ ...
  mkOC('GSUT-HV 51',ctap(FL.gsutHV),FL.gsutHV,max(fGSUT),min(fGSUT),0.2), ...
  mkOC('LINE-Q9 51',ctap(FL.line),FL.line,0,0,0.2), ... % faults/TMS set below
  mkOC('UAT-HV 51',ctap(FL.uatHV),FL.uatHV,I_B11HV,I_B11HV,0.2), ...
  mkOC('UAT-LV 51',ctap(FL.uatLV),FL.uatLV,I_B11,I_B11,0.2)];
relays(2).maxFault_A=max(fLINE); relays(2).minFault_A=min(fLINE);
for k=1:numel(relays)
  relays(k).Is_sec=relays(k).pickup_A/relays(k).CT;
  relays(k).t_maxFault=iec_si(relays(k).TMS,relays(k).maxFault_A/relays(k).pickup_A);
  relays(k).t_minFault=iec_si(relays(k).TMS,relays(k).minFault_A/relays(k).pickup_A);
  relays(k).sensVerdict=tern(relays(k).minFault_A/relays(k).pickup_A>=2,'PASS','REVIEW');
end
% ---- EF relays ----
mkEF=@(zone,ct,tms) struct('zone',zone,'CT',ct,'pickup_sec',0.2, ...
  'pickup_A',0.2*ct,'TMS',tms,'t_LG',iec_si(tms,resB02/(0.2*ct)));
ef=[mkEF('GSUT-NEF 51N',1600,0.15), mkEF('LINE-EF 51N',1600,0.15)];

% ---- coordination: solve upstream TMS ----
% P1 [B11]: UAT-HV backs UAT-LV
tLV=relays(4).t_maxFault;
relays(3).TMS=(tLV+0.3)/iec_si(1,I_B11HV/relays(3).pickup_A);
relays(3).t_maxFault=iec_si(relays(3).TMS,relays(3).maxFault_A/relays(3).pickup_A);
relays(3).t_minFault=relays(3).t_maxFault;
% P2 [B01 through-fault 6.59kA, series]: LINE backs GSUT-HV
Ithru=max(fGSUT); % 6.59kA B01-LLL grid infeed
tG=iec_si(relays(1).TMS,Ithru/relays(1).pickup_A);
relays(2).TMS=(tG+0.3)/iec_si(1,Ithru/relays(2).pickup_A);
relays(2).t_maxFault=iec_si(relays(2).TMS,relays(2).maxFault_A/relays(2).pickup_A);
relays(2).t_minFault=iec_si(relays(2).TMS,relays(2).minFault_A/relays(2).pickup_A);
% E1 [B02 residual]: LINE-EF backs GSUT-NEF
ef(2).TMS=(ef(1).t_LG+0.3)/iec_si(1,resB02/ef(2).pickup_A);
ef(2).t_LG=iec_si(ef(2).TMS,resB02/ef(2).pickup_A);

% ---- coordination table ----
T87=0.10; % 87B+BF assumed operating time, s (C)
mkC=@(prim,back,IkA,tP,tB) struct('primary',prim,'backup',back,'Icheck_kA',IkA, ...
  't_prim_s',tP,'t_back_s',tB,'margin_s',tB-tP, ...
  'verdict',tern(tB-tP>=0.3-1e-9,'PASS','REVIEW'));
coord=[ ...
  mkC('UAT-LV 51','UAT-HV 51',I_B11/1e3,relays(4).t_maxFault,relays(3).t_maxFault), ...
  mkC('GSUT-HV 51','LINE-Q9 51',Ithru/1e3,tG,iec_si(relays(2).TMS,Ithru/relays(2).pickup_A)), ...
  mkC('87B busbar (0.1s C)','LINE-Q9 51 @B03',grd('B03','LLL'),T87,iec_si(relays(2).TMS,grd('B03','LLL')*1e3/relays(2).pickup_A)), ...
  mkC('87B busbar (0.1s C)','GSUT-HV 51 @B02gen',genHV('B02','LLL'),T87,iec_si(relays(1).TMS,genHV('B02','LLL')*1e3/relays(1).pickup_A)), ...
  mkC('GSUT-NEF 51N','LINE-EF 51N',resB02/1e3,ef(1).t_LG,ef(2).t_LG)];
% TMS cap check
for k=1:numel(relays)
  if relays(k).TMS>1.0, coord(end+1)=mkC('TMS cap','review',0,0,-1); end
end

% ---- differential (settings echo + CT mismatch, C) ----
Ihv_rated=515e6/(sqrt(3)*230e3); Ilv_rated=458e6/(sqrt(3)*22e3);
diff.gsut=struct('start_pu',0.3,'slope1',0.30,'slope2',0.60, ...
  'CT_HV','1600/1 (A/B)','CT_LV','12000/1 (C-proposal, data request)', ...
  'Isec_HV',Ihv_rated/1600,'Isec_LV',Ilv_rated/12000, ...
  'note','39% raw mismatch compensated numerically; slopes per master C');
diff.gen=struct('start_pu',0.2,'note','C; phase CTs per OEM data request');

R.relays=relays; R.ef=ef; R.coord=coord; R.diff=diff;
R.B11.Ifault_kA=I_B11/1e3; R.B11.note='Thevenin B01+UAT approx (C); aux shunt ignored';
R.resB02_A=resB02; R.rev='Rev2-2026-09-10-Phase3';

if doWrite
  fid=fopen(fullfile(here,'results','phase3_settings.csv'),'w');
  fprintf(fid,'Relay,CT,FL_A,Pickup_A,Is_sec_A,TMS,t_maxFault_s,t_minFault_s,maxFault_kA,minFault_kA,SensVerdict,Note_StatusC\n');
  for k=1:numel(relays)
    r=relays(k);
    fprintf(fid,'%s,%d,%.1f,%.1f,%.4f,%.3f,%.3f,%.3f,%.2f,%.2f,%s,%s\n',r.zone,r.CT,r.FL_A, ...
      r.pickup_A,r.Is_sec,r.TMS,r.t_maxFault,r.t_minFault,r.maxFault_A/1e3,r.minFault_A/1e3, ...
      r.sensVerdict,'pickup 1.2xFL(C); IEC-SI(C); CT rule(C)');
  end
  for k=1:numel(ef)
    e=ef(k);
    fprintf(fid,'%s,%d,,%.1f,%.4f,%.3f,%.3f,,%.2f,,,%s\n',e.zone,e.CT,e.pickup_A, ...
      e.pickup_sec,e.TMS,e.t_LG,resB02/1e3,'EF 0.2Asec TMS0.15start(C)');
  end
  fprintf(fid,'GSUT-DIFF,,,,,bias0.30pu/s1-30%%/s2-60%%,,,,,,C; CT mismatch note\n');
  fprintf(fid,'GEN-DIFF,,,,,start0.20pu,,,,,,C\n');
  fclose(fid);
  fid=fopen(fullfile(here,'results','phase3_coordination.csv'),'w');
  fprintf(fid,'Primary,Backup,Icheck_kA,t_prim_s,t_back_s,Margin_s,Verdict,Note_StatusC\n');
  for k=1:numel(coord)
    c=coord(k);
    fprintf(fid,'%s,%s,%.2f,%.3f,%.3f,%.3f,%s,%s\n',c.primary,c.backup,c.Icheck_kA, ...
      c.t_prim_s,c.t_back_s,c.margin_s,c.verdict,'margin 0.3s(C); 87B 0.1s(C)');
  end
  fclose(fid);
  fprintf('Wrote rev2/results/phase3_*.csv (B11 %.1fkA, resB02 %.1fkA)\n',R.B11.Ifault_kA,resB02/1e3);
  for k=1:numel(coord)
    fprintf('%s <- %s @%.2fkA: %.3fs vs %.3fs m=%.3f %s\n',coord(k).primary, ...
      coord(k).backup,coord(k).Icheck_kA,coord(k).t_prim_s,coord(k).t_back_s,coord(k).margin_s,coord(k).verdict);
  end
end
end

function c=ctap(fl)
taps=[400 800 1600];
c=taps(find(taps>=1.25*fl,1,'first'));
end

function r=mkRelay(zone,ct,fl,fmax,fmin,tms)
r=struct('zone',zone,'CT',ct,'FL_A',fl,'pickup_A',1.2*fl,'Is_sec',0, ...
  'TMS',tms,'maxFault_A',fmax,'minFault_A',fmin,'t_maxFault',0,'t_minFault',0,'sensVerdict','');
end

function s=tern(c,a,b), if c, s=a; else, s=b; end, end
