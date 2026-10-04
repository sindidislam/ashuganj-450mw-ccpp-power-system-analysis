function R = run_phase2_fault(varargin)
%RUN_PHASE2_FAULT Rev2 Phase 2 fault-study engine (Sep-10 master truth).
% Bolted faults via classical Zbus superposition (sources shorted in Y012,
% prefault V from P1A). All C-assumptions labelled in CSV Note column.
% Sequence boundary equations (Vf = prefault V at fault bus f):
%   LLL: I1 = Vf/Zth1; I2 = 0; I0 = 0
%   LG : I0 = I1 = I2 = Vf/(Zth0+Zth1+Zth2)
%   LL : I1 = Vf/(Zth1+Zth2); I2 = -I1; I0 = 0
%   LLG: I1 = Vf/(Zth1+Zth2*Zth0/(Zth2+Zth0));
%        I2 = -I1*Zth0/(Zth2+Zth0); I0 = -I1*Zth2/(Zth2+Zth0)
% Phase: Iabc = A*[I0;I1;I2], A=[1 1 1;1 a^2 a;1 a a^2], a=e^{j120}.
% During-fault seq voltages: Vseq(i) = Vpre_seq(i) - Zbus_seq(i,f)*Iseq.
% Gen contribution: Vseq(B01)/Zgen_seq -> kA @22kV. Grid: Vseq(B03)/Zgrid_seq.
% IEC 60909 peak: k=1.02+0.98*exp(-3/(X/R)); Ipeak=sqrt(2)*k*Isym (C-method:
% X/R from positive-seq Zth; assumed clearing 60 ms (C) for duty).
% Base cases: LLL/LG/LL/LLG @B01,B02 + LLL @B03 (9). Sens: LLL,LG @B02 over
% Xdpp{sat,unsat} x grid_k{0.7,1,1.5} x line_k{0.8,1,1.2} (36 rows).
% Usage: R=run_phase2_fault() writes rev2/results/phase2_*.csv; ('Write',false) solves only.

p=inputParser; addParameter(p,'Write',true); parse(p,varargin{:});
doWrite=p.Results.Write;

buses={'B01','B02','B03'}; Vnom=[22 230 230];
a=exp(1j*2*pi/3);
Amat=[1 1 1; 1 a^2 a; 1 a a^2];

% ---- 9 base cases ----
baseDef={ 'B01','LLL'; 'B01','LG'; 'B01','LL'; 'B01','LLG'; ...
          'B02','LLL'; 'B02','LG'; 'B02','LL'; 'B02','LLG'; 'B03','LLL'};
S0=seq_networks('Xdpp','sat','grid_k',1.0,'line_k',1.0,'gridZ0_k',1.0);
res=repmat(emptyRes(),size(baseDef,1),1);
for k=1:size(baseDef,1)
  f=find(strcmp(buses,baseDef{k,1}));
  res(k)=doFault(S0,f,Vnom(f),baseDef{k,1},baseDef{k,2},Amat);
  res(k).CaseID=sprintf('F%d-%s-%s',k,baseDef{k,1},baseDef{k,2});
end

% ---- sens 36 ----
xdList={'sat','unsat'}; gk=[0.7 1.0 1.5]; lk=[0.8 1.0 1.2]; stype={'LLL','LG'};
sens=repmat(emptySens(),36,1); si=0;
for t=1:2, for x=1:2, for g=1:3, for l=1:3
  si=si+1;
  Sq=seq_networks('Xdpp',xdList{x},'grid_k',gk(g),'line_k',lk(l),'gridZ0_k',1.0);
  r=doFault(Sq,2,230,'B02',stype{t},Amat);
  sens(si).SensID=sprintf('S-%s-B02-%s-g%.1f-l%.1f',stype{t},xdList{x},gk(g),lk(l));
  sens(si).bus='B02'; sens(si).type=stype{t}; sens(si).Xdpp=xdList{x};
  sens(si).grid_k=gk(g); sens(si).line_k=lk(l);
  sens(si).Isym_kA=r.Isym_kA; sens(si).Ipeak_kA=r.Ipeak_kA; sens(si).FaultMVA=r.FaultMVA;
end, end, end, end

% ---- grid Z0 sens (C) LG@B02 ----
sensZ0=repmat(struct('gridZ0_k',0,'Isym_kA',0,'Ipeak_kA',0),3,1);
for q=1:3
  Sz=seq_networks('Xdpp','sat','grid_k',1.0,'line_k',1.0,'gridZ0_k',q);
  rz=doFault(Sz,2,230,'B02','LG',Amat);
  sensZ0(q).gridZ0_k=q; sensZ0(q).Isym_kA=rz.Isym_kA; sensZ0(q).Ipeak_kA=rz.Ipeak_kA;
end

% ---- sequence Z table (base params) ----
Ztab=repmat(struct('bus','','Zth1',0,'Zth0',0,'Zth2',0),3,1);
for b=1:3
  Ztab(b).bus=buses{b}; Ztab(b).Zth1=S0.Zbus1(b,b);
  Ztab(b).Zth2=S0.Zbus2(b,b); Ztab(b).Zth0=S0.Zbus0(b,b);
end

% ---- breaker duty (230 kV GIS; 50 kA = withstand ONLY per master §17) ----
iQ0=max([res.IgsutHV_kA]);   % gen-side through main breaker Q0
iQ9=max([res.Iline_kA]);     % grid-side through line bay Q9
iBus=max([res([5 6 7 8 9]).Isym_kA]); % busbar through-fault (B02/B03 cases)
duty=repmat(struct('breaker','','sees','','I_kA',0,'Withstand_kA',50, ...
  'Interrupt_kA',50,'clearing_ms',60,'margin_kA',0,'verdict','','note',''),4,1);
mkrow=@(n,s,i,nt) struct('breaker',n,'sees',s,'I_kA',i,'Withstand_kA',50, ...
  'Interrupt_kA',50,'clearing_ms',60,'margin_kA',50-i, ...
  'verdict',passfail(i),'note',nt);
duty(1)=mkrow('Q0','gen-side max via GSUT (HV kA)',iQ0,'withstand B §17; interrupt 50kA CLASS ASSUMED (C); clearing 60ms (C)');
duty(2)=mkrow('Q1','busbar BB1 through-fault max @B02/B03',iBus,'withstand B §17; interrupt assumed (C)');
duty(3)=mkrow('Q2','busbar BB2 through-fault max @B02/B03',iBus,'withstand B §17; interrupt assumed (C)');
duty(4)=mkrow('Q9','grid-side max via line07 (kA)',iQ9,'disconnector; withstand check only; interrupt N/A');
for k=1:4
  if duty(k).I_kA>50, duty(k).verdict='REVIEW'; end
end

R.res=res; R.sens=sens; R.sensZ0=sensZ0; R.Ztab=Ztab; R.duty=duty;
R.rev='Rev2-2026-09-10-Phase2'; R.date='2026-09-10';

if doWrite
  here=fileparts(mfilename('fullpath')); out=fullfile(here,'results');
  if ~isfolder(out), mkdir(out); end
  % fault currents (base 9 + sens 36 appended with SensID in CaseID col)
  fid=fopen(fullfile(out,'phase2_fault_currents.csv'),'w');
  fprintf(fid,['CaseID,Bus,FaultType,Vnom_kV,Vpre_pu,Vpre_ang_deg,Zth1_R_pu,Zth1_X_pu,' ...
    'Zth0_R_pu,Zth0_X_pu,I0_mag_pu,I1_mag_pu,I2_mag_pu,Ia_kA,Ib_kA,Ic_kA,Isym_kA,' ...
    'Vfault_min_pu,Igen_kA_22kV,Igrid_kA_230kV,FaultMVA,XR_pos,kappa,Ipeak_kA,Note_StatusC\n']);
  for k=1:numel(res), fprintf(fid,'%s\n',resRow(res(k),'BASE sat g1.0 l1.0')); end
  for k=1:numel(sens)
    q=sens(k);
    Sq=seq_networks('Xdpp',q.Xdpp,'grid_k',q.grid_k,'line_k',q.line_k,'gridZ0_k',1.0);
    r=doFault(Sq,2,230,'B02',q.type,Amat);
    r.CaseID=q.SensID;
    fprintf(fid,'%s\n',resRow(r,sprintf('SENS %s g%.1f l%.1f gridZ0x1',q.Xdpp,q.grid_k,q.line_k)));
  end
  fclose(fid);
  % sequence Z
  fid=fopen(fullfile(out,'phase2_sequence_Z.csv'),'w');
  fprintf(fid,'Bus,Zth1_R_pu,Zth1_X_pu,Zth1_mag_pu,Zth0_R_pu,Zth0_X_pu,Zth0_mag_pu,Zth2_R_pu,Zth2_X_pu,Note_StatusC\n');
  for b=1:3
    fprintf(fid,'%s,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%s\n',Ztab(b).bus, ...
      real(Ztab(b).Zth1),imag(Ztab(b).Zth1),abs(Ztab(b).Zth1), ...
      real(Ztab(b).Zth0),imag(Ztab(b).Zth0),abs(Ztab(b).Zth0), ...
      real(Ztab(b).Zth2),imag(Ztab(b).Zth2), ...
      'genX own-base interp(C); GSUT-Z0=Z1(C); gridZ0=Z1(C); YNd1 blocks B01-B02');
  end
  fclose(fid);
  % breaker duty
  fid=fopen(fullfile(out,'phase2_breaker_duty.csv'),'w');
  fprintf(fid,'Breaker,Sees,I_kA,Withstand_kA_B,Interrupt_assumed_kA_C,Clearing_ms_assumed_C,Margin_kA,Verdict,Note_StatusC\n');
  for k=1:numel(duty)
    fprintf(fid,'%s,%s,%.3f,%.1f,%.1f,%d,%.3f,%s,%s\n',duty(k).breaker,duty(k).sees, ...
      duty(k).I_kA,duty(k).Withstand_kA,duty(k).Interrupt_kA,duty(k).clearing_ms, ...
      duty(k).margin_kA,duty(k).verdict,duty(k).note);
  end
  fclose(fid);
  fprintf('Wrote rev2/results/phase2_*.csv (%d base + %d sens rows)\n',numel(res),numel(sens));
  % console summary
  for k=1:numel(res)
    fprintf('%s %s: Isym=%.2fkA Ipeak=%.1fkA XR=%.1f MVA=%.0f (gen %.2f / grid %.2f kA)\n', ...
      res(k).CaseID,res(k).type,res(k).Isym_kA,res(k).Ipeak_kA,res(k).XR, ...
      res(k).FaultMVA,res(k).Igen_kA,res(k).Igrid_kA);
  end
end
end

function r = doFault(S,f,Vnom,bus,type,Amat)
Vpre=S.Vpre1(f);
Zth1=S.Zbus1(f,f); Zth2=S.Zbus2(f,f); Zth0=S.Zbus0(f,f);
switch type
  case 'LLL'
    I1=Vpre/Zth1; I2=0; I0=0;
  case 'LG'
    Id=Vpre/(Zth0+Zth1+Zth2); I0=Id; I1=Id; I2=Id;
  case 'LL'
    I1=Vpre/(Zth1+Zth2); I2=-I1; I0=0;
  case 'LLG'
    I1=Vpre/(Zth1+Zth2*Zth0/(Zth2+Zth0));
    I2=-I1*Zth0/(Zth2+Zth0); I0=-I1*Zth2/(Zth2+Zth0);
end
V1=S.Vpre1-S.Zbus1(:,f)*I1; V2=-S.Zbus2(:,f)*I2; V0=-S.Zbus0(:,f)*I0;
Vf_abc=Amat*[V0(f);V1(f);V2(f)];
Ibase=100/(sqrt(3)*Vnom); % kA on 100MVA (S_kVA/(sqrt3*V_kV))
Iabc=Amat*[I0;I1;I2]*Ibase;
Isym=max(abs(Iabc));
% contributions (phase domain, max phase)
Ib22=100/(sqrt(3)*22); Ib230=100/(sqrt(3)*230); % kA bases
Egen1=S.Vpre1(1)+conj(S.Sgen_pre_pu/S.Vpre1(1))*S.Zgen1; Ig_abc=Amat*[(0-V0(1))/S.Zgen0; (Egen1-V1(1))/S.Zgen1; (0-V2(1))/S.Zgen2]*Ib22;
Ie_abc=Amat*[(0-V0(3))/S.Zgrid0; (1-V1(3))/S.Zgrid1; (0-V2(3))/S.Zgrid1]*Ib230;
Igs_abc=Amat*[0; (V1(1)-V1(2))/S.Zgsut; (V2(1)-V2(2))/S.Zgsut]*Ib230;
Iln_abc=Amat*[(V0(2)-V0(3))/S.Zline0; (V1(2)-V1(3))/S.Zline1; (V2(2)-V2(3))/S.Zline1]*Ib230;
XR=imag(Zth1)/real(Zth1); kap=iec_kappa(XR);
r=emptyRes();
r.bus=bus; r.type=type; r.Vnom_kV=Vnom; r.Vpre=Vpre;
r.Zth0=Zth0; r.Zth1=Zth1; r.Zth2=Zth2;
r.I0=I0; r.I1=I1; r.I2=I2; r.Iabc_kA=Iabc; r.Vabc_fault_pu=Vf_abc;
r.Isym_kA=Isym; r.Igen_kA=max(abs(Ig_abc)); r.Igrid_kA=max(abs(Ie_abc));
r.IgsutHV_kA=max(abs(Igs_abc)); r.Iline_kA=max(abs(Iln_abc));
r.Igen_kA_ph=Ig_abc; r.Igrid_kA_ph=Ie_abc; r.Iline_kA_ph=Iln_abc; r.IgsutHV_kA_ph=Igs_abc;
r.FaultMVA=sqrt(3)*Vnom*Isym; r.XR=XR; r.kappa=kap; r.Ipeak_kA=sqrt(2)*kap*Isym;
end

function r = emptyRes()
r=struct('CaseID','','bus','','type','','Vnom_kV',0,'Vpre',0,'Zth0',0,'Zth1',0, ...
  'Zth2',0,'I0',0,'I1',0,'I2',0,'Iabc_kA',[0;0;0],'Vabc_fault_pu',[0;0;0], ...
  'Isym_kA',0,'Igen_kA',0,'Igrid_kA',0,'IgsutHV_kA',0,'Iline_kA',0, ...
  'Igen_kA_ph',[0;0;0],'Igrid_kA_ph',[0;0;0],'Iline_kA_ph',[0;0;0],'IgsutHV_kA_ph',[0;0;0], ...
  'FaultMVA',0,'XR',0,'kappa',0,'Ipeak_kA',0);
end

function q = emptySens()
q=struct('SensID','','bus','','type','','Xdpp','','grid_k',0,'line_k',0, ...
  'Isym_kA',0,'Ipeak_kA',0,'FaultMVA',0);
end

function s = resRow(r,note)
s=sprintf(['%s,%s,%s,%.1f,%.6f,%.4f,%.6e,%.6e,%.6e,%.6e,%.6f,%.6f,%.6f,' ...
  '%.3f,%.3f,%.3f,%.3f,%.6f,%.3f,%.3f,%.1f,%.2f,%.4f,%.2f,%s'], ...
  r.CaseID,r.bus,r.type,r.Vnom_kV,abs(r.Vpre),angle(r.Vpre)*180/pi, ...
  real(r.Zth1),imag(r.Zth1),real(r.Zth0),imag(r.Zth0), ...
  abs(r.I0),abs(r.I1),abs(r.I2),abs(r.Iabc_kA(1)),abs(r.Iabc_kA(2)), ...
  abs(r.Iabc_kA(3)),r.Isym_kA,min(abs(r.Vabc_fault_pu)), ...
  r.Igen_kA,r.Igrid_kA,r.FaultMVA,r.XR,r.kappa,r.Ipeak_kA,note);
end

function v = passfail(i)
if i<=50, v='PASS'; else, v='REVIEW'; end
end





