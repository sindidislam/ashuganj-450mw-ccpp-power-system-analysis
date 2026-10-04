function R = run_phase1_loadflow(varargin)
%RUN_PHASE1_LOADFLOW Transparent positive-sequence NR loadflow, Rev2 Phase 1.
% Equations (polar NR):
%   Pi = Vi*sum_j Vj*(Gij*cos(ti-tj)+Bij*sin(ti-tj))
%   Qi = Vi*sum_j Vj*(Gij*sin(ti-tj)-Bij*cos(ti-tj))
% Bases: 100 MVA, kV per bus, 50 Hz. Vref B01=1.0pu(C), slack B03=1.0∠0(C).
% Off-nominal UAT/GAT LV tap a=6.6/6.9 on B11 side:
%   Y_ii=y, Y_jj=y/a^2, Y_ij=-y/a (a on j side).
% Usage: R=run_phase1_loadflow() writes rev2/results/*.csv + returns struct.
%   R=run_phase1_loadflow('Write',false) solves only.

p = inputParser; addParameter(p,'Write',true); parse(p,varargin{:});
doWrite = p.Results.Write;

D = ashuganj_rev2_registry();
Sbase = D.meta.Sbase_MVA;
% bus order
names = {'B01','B02','B03','B11'};
n = 4; islack = 3; ipv = 1;
Vbase_kV = [22 230 230 6.6];

% Ybus per case (grid_k scales Zth only, line_k scales line07 only)
cases = D.cases;
R.cases = cases; R.Sbase=Sbase; R.date='2026-09-10'; R.rev=D.meta.Revision;
sys_rows = {}; bus_rows = {}; br_rows = {};

for ci = 1:numel(cases)
  C = cases(ci);
  Pgen_pu = C.P_MW/Sbase;
  % branch impedances with sensitivities
  Rth = D.grid.R_pu*C.grid_k; Xth = D.grid.X_pu*C.grid_k;
  Rln = D.line07.R_pu*C.line_k; Xln = D.line07.X_pu*C.line_k;
  Bln = D.line07.B_pu*C.line_k; % scale B with line_k approx
  R23 = Rln+Rth; X23 = Xln+Xth;
  y23 = 1/(R23+1j*X23);
  yGS = 1/(D.gsut.R1_pu_sys+1j*D.gsut.X1_pu_sys);
  yUAT = 1/(D.uat.R_pu_sys+1j*D.uat.X_pu_sys); aU = D.uat.a_LV;
  yGAT = 1/(D.gat.R_pu_sys+1j*D.gat.X_pu_sys); aG = D.gat.a_LV;
  Y = zeros(n);
  % B01-B02 GSUT a=1
  Y(1,1)=Y(1,1)+yGS; Y(2,2)=Y(2,2)+yGS; Y(1,2)=Y(1,2)-yGS; Y(2,1)=Y(2,1)-yGS;
  % B01-B11 UAT tap on 4
  Y(1,1)=Y(1,1)+yUAT; Y(4,4)=Y(4,4)+yUAT/(aU^2); Y(1,4)=Y(1,4)-yUAT/aU; Y(4,1)=Y(4,1)-yUAT/aU;
  % B02-B11 GAT if IN
  if C.GAT_in
    Y(2,2)=Y(2,2)+yGAT; Y(4,4)=Y(4,4)+yGAT/(aG^2); Y(2,4)=Y(2,4)-yGAT/aG; Y(4,2)=Y(4,2)-yGAT/aG;
  end
  % B02-B03 line+grid + charging
  Y(2,2)=Y(2,2)+y23+1j*Bln/2; Y(3,3)=Y(3,3)+y23+1j*Bln/2;
  Y(2,3)=Y(2,3)-y23; Y(3,2)=Y(3,2)-y23;
  Gmat=real(Y); Bmat=imag(Y);
  % specified injections (gen + loads); slack unknown
  Psp = zeros(n,1); Qsp = zeros(n,1);
  Psp(1)=Pgen_pu;              % PV, Q free
  Psp(2)=0; Qsp(2)=0;
  Psp(4)=-D.aux.P_pu; Qsp(4)=-D.aux.Q_pu;
  % initial flat start, B01 angle 0
  V = [1.0;1.0;1.0;1.0]; th = zeros(n,1);
  % unknowns: th(1,2,4) + V(2,4). th3=0,V1=1,V3=1 fixed.
  x = [th(1);th(2);th(4);V(2);V(4)];
  tol=1e-10; maxit=50; converged=false;
  for it=1:maxit
    th(1)=x(1); th(2)=x(2); th(4)=x(3); V(2)=x(4); V(4)=x(5);
    th(3)=0; V(1)=1.0; V(3)=1.0;
    % compute P,Q
    Pc=zeros(n,1); Qc=zeros(n,1);
    for i=1:n
      for j=1:n
        aij=th(i)-th(j);
        Pc(i)=Pc(i)+V(i)*V(j)*(Gmat(i,j)*cos(aij)+Bmat(i,j)*sin(aij));
        Qc(i)=Qc(i)+V(i)*V(j)*(Gmat(i,j)*sin(aij)-Bmat(i,j)*cos(aij));
      end
    end
    % mismatches: dP1,dP2,dP4,dQ2,dQ4
    F=[Psp(1)-Pc(1);Psp(2)-Pc(2);Psp(4)-Pc(4);Qsp(2)-Qc(2);Qsp(4)-Qc(4)];
    if max(abs(F))<tol, converged=true; break; end
    % numeric Jacobian (transparent, small system)
    h=1e-8; J=zeros(5);
    for k=1:5
      xp=x; xp(k)=xp(k)+h;
      tht=th; Vt=V;
      tht(1)=xp(1); tht(2)=xp(2); tht(4)=xp(3); Vt(2)=xp(4); Vt(4)=xp(5);
      P2=zeros(n,1); Q2=zeros(n,1);
      for i=1:n
        for j=1:n
          aij=tht(i)-tht(j);
          P2(i)=P2(i)+Vt(i)*Vt(j)*(Gmat(i,j)*cos(aij)+Bmat(i,j)*sin(aij));
          Q2(i)=Q2(i)+Vt(i)*Vt(j)*(Gmat(i,j)*sin(aij)-Bmat(i,j)*cos(aij));
        end
      end
      Fp=[Psp(1)-P2(1);Psp(2)-P2(2);Psp(4)-P2(4);Qsp(2)-Q2(2);Qsp(4)-Q2(4)];
      J(:,k)=(Fp-F)/h;
    end
    dx = -J\F; x = x+dx;
    if max(abs(dx))<1e-12, converged=true; break; end
  end
  th(1)=x(1); th(2)=x(2); th(4)=x(3); V(2)=x(4); V(4)=x(5); th(3)=0; V(1)=1.0; V(3)=1.0;
  % final injections incl slack + gen Q
  Pinj=zeros(n,1); Qinj=zeros(n,1);
  for i=1:n
    for j=1:n
      aij=th(i)-th(j);
      Pinj(i)=Pinj(i)+V(i)*V(j)*(Gmat(i,j)*cos(aij)+Bmat(i,j)*sin(aij));
      Qinj(i)=Qinj(i)+V(i)*V(j)*(Gmat(i,j)*sin(aij)-Bmat(i,j)*cos(aij));
    end
  end
  % independent mismatch (specified buses only) + branch-loss balance
  Ffin=[Psp(1)-Pinj(1);Psp(2)-Pinj(2);Psp(4)-Pinj(4);Qsp(2)-Qinj(2);Qsp(4)-Qinj(4)];
  Pbal_pu = max(abs(Ffin)); % solver mismatch, must be <1e-6 (NOT sum injections)
  % branch flows (from->to at from end), S in pu
  Vc = V.*exp(1j*th);
  % GSUT 1-2
  Igs = yGS*(Vc(1)-Vc(2)); Sgs1=Vc(1)*conj(Igs); Sgs2=Vc(2)*conj(-Igs);
  Sgs=max(abs(Sgs1),abs(Sgs2));
  % UAT 1-4 with tap: current from 1: I1 = y*(V1 - V4/a)/1? Use Y partition
  Iu1 = yUAT*Vc(1) - (yUAT/aU)*Vc(4); Su1 = Vc(1)*conj(Iu1);
  Iu4 = -(yUAT/aU)*Vc(1) + (yUAT/aU^2)*Vc(4); Su4 = Vc(4)*conj(Iu4);
  Su = max(abs(Su1),abs(Su4));
  if C.GAT_in
    Ig2 = yGAT*Vc(2)-(yGAT/aG)*Vc(4); Sg2=Vc(2)*conj(Ig2);
    Ig4 = -(yGAT/aG)*Vc(2)+(yGAT/aG^2)*Vc(4); Sg4=Vc(4)*conj(Ig4);
    Sg=max(abs(Sg2),abs(Sg4));
  else
    Sg2=0; Sg4=0; Sg=0;
  end
  I23 = y23*(Vc(2)-Vc(3)); S23=Vc(2)*conj(I23); S32=Vc(3)*conj(-I23);
  % export = power into slack negative => export positive out of plant
  Pexport_pu = -Pinj(3); Qexport_pu = -Qinj(3);
  Ploss_MW = (Pinj(1)+Pinj(3)+Psp(4))*Sbase; % Pgen+Pslack+Pload_inj = branch I2R + shunt
  % loadings
  Sgs_MVA=Sgs*Sbase; Su_MVA=Su*Sbase; Sg_MVA=Sg*Sbase;
  gs_ONAN=Sgs_MVA/355*100; gs_ODAN=Sgs_MVA/460*100; gs_ODAF=Sgs_MVA/515*100;
  u_ONAN=Su_MVA/19*100; u_ONAF=Su_MVA/25*100;
  g_ONAN=Sg_MVA/19*100; g_ONAF=Sg_MVA/25*100;
  % currents
  Igen_A = abs(Pinj(1)+1j*Qinj(1))*Sbase*1e6/(sqrt(3)*22e3*V(1));
  Igs_HV = max(abs(Sgs1),abs(Sgs2))*Sbase*1e6/(sqrt(3)*230e3);
  I23_A = abs(S23)*Sbase*1e6/(sqrt(3)*230e3*V(2));
  pfgen = Pinj(1)/max(abs(Pinj(1)+1j*Qinj(1)),eps);
  % store
  R.sol(ci).ID=C.ID; R.sol(ci).V=V; R.sol(ci).th_deg=th*180/pi;
  R.sol(ci).Pinj=Pinj; R.sol(ci).Qinj=Qinj; R.sol(ci).converged=converged;
  R.sol(ci).iters=it; R.sol(ci).Pbal_pu=Pbal_pu;
  R.sol(ci).Pexport_MW=Pexport_pu*Sbase; R.sol(ci).Qexport_MVAr=Qexport_pu*Sbase;
  R.sol(ci).Ploss_MW=Ploss_MW; R.sol(ci).Sgs_MVA=Sgs_MVA; R.sol(ci).Su_MVA=Su_MVA;
  R.sol(ci).Sg_MVA=Sg_MVA; R.sol(ci).Igen_A=Igen_A;

  sys_rows{end+1} = sprintf('%s,%.1f,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f,%d,%.2e,%s', ...
    C.ID,C.P_MW,C.GAT_in,V(1),V(2),V(3),V(4),Pinj(1)*Sbase,Qinj(1)*Sbase, ...
    Pexport_pu*Sbase,Qexport_pu*Sbase,Ploss_MW,Sgs_MVA,Su_MVA,Sg_MVA, ...
    gs_ONAN,gs_ODAF,u_ONAN,I23_A,it,abs(Pbal_pu),C.Note);
  for b=1:4
    Vm = V(b)*Vbase_kV(b);
    bus_rows{end+1}=sprintf('%s,%s,%.2f,%.6f,%.2f,%.4f,%.4f,%.4f',C.ID,names{b},Vbase_kV(b),V(b),Vm,th(b)*180/pi,Pinj(b)*Sbase,Qinj(b)*Sbase);
  end
  br_rows{end+1}=sprintf('%s,GSUT,B01-B02,%.2f,%.2f,%.2f,%.1f',C.ID,abs(Sgs1)*Sbase,abs(Sgs2)*Sbase,Sgs_MVA,Igs_HV);
  br_rows{end+1}=sprintf('%s,UAT,B01-B11,%.2f,%.2f,%.2f,%.1f',C.ID,abs(Su1)*Sbase,abs(Su4)*Sbase,Su_MVA,Su_MVA*1e6/(sqrt(3)*6.6e3));
  br_rows{end+1}=sprintf('%s,GAT,B02-B11,%.2f,%.2f,%.2f,%.1f',C.ID,abs(Sg2)*Sbase,abs(Sg4)*Sbase,Sg_MVA,Sg_MVA*1e6/(sqrt(3)*6.6e3));
  br_rows{end+1}=sprintf('%s,GRID+B02B03,B02-B03,%.2f,%.2f,%.2f,%.1f',C.ID,abs(S23)*Sbase,abs(S32)*Sbase,abs(S23)*Sbase,I23_A);
  fprintf('%s Pgen=%.1fMW GAT=%d grid_k=%.2f line_k=%.2f | V2=%.5f V4=%.5f Qgen=%.2f Pexp=%.2f Ploss=%.3f conv=%d it=%d pbal=%.1e\n', ...
    C.ID,C.P_MW,C.GAT_in,C.grid_k,C.line_k,V(2),V(4),Qinj(1)*Sbase,Pexport_pu*Sbase,Ploss_MW,converged,it,abs(Pbal_pu));
end

if doWrite
  here=fileparts(mfilename('fullpath'));
  res=fullfile(here,'results'); if ~isfolder(res), mkdir(res); end
  % system summary
  fid=fopen(fullfile(res,'phase1_system_summary.csv'),'w');
  fprintf(fid,'CaseID,Pgen_MW,GAT_in,V_B01_pu,V_B02_pu,V_B03_pu,V_B11_pu,Pgen_MW,Qgen_MVAr,Pexport_MW,Qexport_MVAr,Ploss_MW,Sgs_MVA,Su_MVA,Sg_MVA,GSUT_pct_ONAN355,GSUT_pct_ODAF515,UAT_pct_ONAN19,Line_I_A,Iters,Pbal_pu_abs,Note_StatusC\n');
  for i=1:numel(sys_rows), fprintf(fid,'%s\n',sys_rows{i}); end
  fclose(fid);
  fid=fopen(fullfile(res,'phase1_bus_results.csv'),'w');
  fprintf(fid,'CaseID,Bus,Vbase_kV,V_pu,V_kV,Ang_deg,P_MW,Q_MVAr\n');
  for i=1:numel(bus_rows), fprintf(fid,'%s\n',bus_rows{i}); end
  fclose(fid);
  fid=fopen(fullfile(res,'phase1_branch_results.csv'),'w');
  fprintf(fid,'CaseID,Branch,Ends,S_from_MVA,S_to_MVA,Smax_MVA,I_A\n');
  for i=1:numel(br_rows), fprintf(fid,'%s\n',br_rows{i}); end
  fclose(fid);
  % registry snapshot
  fid=fopen(fullfile(res,'phase1_registry_snapshot.txt'),'w');
  fprintf(fid,'Rev2 %s Date 2026-09-10 Sbase 100MVA f 50Hz\nGen 458MVA/22kV/360MW H5.287 Xd1.783 Xdp0.3256 XdppSAT0.2248 SENS0.2608 X2_0.2242 X0_0.128 Ra0.00089ohm solid(B)\nGSUT 515MVA 22/230 YNd1 Z0.1663 R0.001771 X0.16629 own(B/D) stages355/460/515\nUAT 19/25 Dyn11 10.5%%/0.4%% GAT 19/25 Zps12%%/0.5%% a_LV0.9565 (nameplate B; §24 generic superseded)\nAux 12+j5MVA B11(C) Grid 45.01kA/17.93GVA R0.268 X2.94 X/R10.99(B/C) line07 0.7km2ckt C-electrics\nAll C labelled; GIS50kA withstand only.\n',D.meta.Revision);
  fclose(fid);
  fprintf('Wrote rev2/results/phase1_*.csv\n');
end
end
