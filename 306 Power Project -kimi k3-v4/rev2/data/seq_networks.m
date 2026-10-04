function S = seq_networks(varargin)
%SEQ_NETWORKS Sequence networks for Ashuganj South Rev2 fault study (Sep-10 truth).
% Classical 3-node Thevenin model, 100 MVA base.
%   Nodes: 1 B01 (22 kV gen terminal), 2 B02 (230 kV GIS), 3 B03 (230 kV grid).
%   Y1/Y2: gen subtransient shunt at B01 (source shorted) + GSUT B01-B02
%          + line07 B02-B03 + grid Thevenin shunt at B03.
%   Y0: gen Z0 shunt at B01 (solid neutral, B); NO B01-B02 branch because
%       GSUT YNd1 LV delta blocks zero-seq (B); GSUT Z0 (=Z1 leakage, C)
%       shunt at B02 (HV solidly grounded); line0 B02-B03; grid Z0 shunt B03.
% Base assumptions (all labelled C in outputs):
%   - Gen Xd''/X2/X0 pu taken on own 458 MVA base (master silent on base;
%     reconciliation P1-GEN-XD unit implies own-base) -> x100/458 to system.
%   - GSUT Z0 = Z1 leakage magnitude.
%   - Grid Z0 = Z1 (gridZ0_k scales 1-3x sens).
%   - Shunt line susceptance neglected for SC (charging ~0.4 A vs ~46 kA).
% Usage: S = seq_networks('Xdpp','sat','grid_k',1.0,'line_k',1.0,'gridZ0_k',1.0)
%   Xdpp: 'sat' 0.2248 primary (B) | 'unsat' 0.2608 sens (B).

p = inputParser;
addParameter(p,'Xdpp','sat');
addParameter(p,'grid_k',1.0);
addParameter(p,'line_k',1.0);
addParameter(p,'gridZ0_k',1.0);
parse(p,varargin{:});
o = p.Results;

D = ashuganj_rev2_registry();
kGen = 100/D.gen.Snom_MVA; % own -> system base
if strcmpi(o.Xdpp,'sat')
  X1g = D.gen.Xdpp_sat*kGen; xdNote = 'Xdpp_sat0.2248(B)';
else
  X1g = D.gen.Xdpp*kGen; xdNote = 'Xdpp_unsat0.2608(B-sens)';
end
X2g = D.gen.X2*kGen; X0g = D.gen.X0*kGen;
R1g = D.gen.R1_pu*kGen; R0g = D.gen.R0_pu*kGen; % R2=R1(C) R0=1.5R1(C)
Zgen1 = R1g+1j*X1g; Zgen2 = R1g+1j*X2g; Zgen0 = R0g+1j*X0g;

Zgsut = D.gsut.R1_pu_sys + 1j*D.gsut.X1_pu_sys; % Z2=Z1; Z0 same leakage (C)
Zline1 = (D.line07.R_pu + 1j*D.line07.X_pu)*o.line_k;
Zb230 = 230^2/100;
R0ln = (0.25*0.7)/2/Zb230; X0ln = (1.20*0.7)/2/Zb230; % master §9 C per-km
Zline0 = (R0ln+1j*X0ln)*o.line_k;
Zgrid1 = (D.grid.R_pu + 1j*D.grid.X_pu)*o.grid_k; % Rth0.268/Xth2.94 (B/C)
Zgrid0 = Zgrid1*o.gridZ0_k; % C: Z0=Z1 base

% ---- Ybus 012 (3-node) ----
ygen1=1/Zgen1; ygen2=1/Zgen2; ygen0=1/Zgen0;
ygs=1/Zgsut; yl1=1/Zline1; yl0=1/Zline0; yg1=1/Zgrid1; yg0=1/Zgrid0;
Y1 = [ygen1+ygs, -ygs, 0; -ygs, ygs+yl1, -yl1; 0, -yl1, yl1+yg1];
Y2 = [ygen2+ygs, -ygs, 0; -ygs, ygs+yl1, -yl1; 0, -yl1, yl1+yg1];
Y0 = [ygen0, 0, 0; 0, ygs+yl0, -yl0; 0, -yl0, yl0+yg0];

S.Y1=Y1; S.Y2=Y2; S.Y0=Y0;
S.Zbus1=inv(Y1); S.Zbus2=inv(Y2); S.Zbus0=inv(Y0);
S.Zgen1=Zgen1; S.Zgen2=Zgen2; S.Zgen0=Zgen0;
S.Zgsut=Zgsut; S.Zline1=Zline1; S.Zline0=Zline0; S.Zgrid1=Zgrid1; S.Zgrid0=Zgrid0;
S.busNames={'B01','B02','B03'}; S.Vnom_kV=[22 230 230];
S.params.Xdpp=o.Xdpp; S.params.grid_k=o.grid_k; S.params.line_k=o.line_k;
S.params.gridZ0_k=o.gridZ0_k; S.params.xdNote=xdNote;

% ---- Prefault V from P1A (parse phase1 CSV; fallback exact P1A numbers) ----
[Vpre, Sgen_pre, Iexp_pu] = get_prefault(D);
S.Vpre1=Vpre; S.Vpre2=zeros(3,1); S.Vpre0=zeros(3,1);
S.Sgen_pre_pu=Sgen_pre; S.Iexp_pu=Iexp_pu;
S.note = sprintf(['Prefault P1A base; genX own-base interp(C); GSUT-Z0=Z1(C); ' ...
  'gridZ0=Z1x%.1f(C); shuntB neglected; %s'],o.gridZ0_k,xdNote);
end

function [Vpre,Sgen,Iexp] = get_prefault(D)
% Parse rev2/results/phase1_bus_results.csv P1A rows; fallback hardcoded P1A.
% B03 is the floating line/grid junction (NOT the ideal source): its prefault
% voltage is COMPUTED from the P1A export current (V=E+Iexp*Zgrid, BASE Z:
% prefault is P1A reality; sens scales only the fault network - standard).
% Copying P1A's B03 row (the ideal-source terminal, 1.0pu) here would force
% 83pu through Zline (caught by test_phase2_kcl). Assert current continuity.
Zgrid1=(D.grid.R_pu+1j*D.grid.X_pu);
Zline1=(D.line07.R_pu+1j*D.line07.X_pu);
Vpre=[1.0;1.0;1.0]; Sgen=(354+1j*19.925)/100; Iexp=conj((340.91-1j*30.12)/100/1.0);
try
  here=fileparts(mfilename('fullpath'));
  csv=fullfile(here,'..','results','phase1_bus_results.csv');
  T=readtable(csv,'FileType','text');
  iP=strcmp(T.CaseID,'P1A');
  V=zeros(3,1); Pq=zeros(3,1);
  buses={'B01','B02','B03'};
  for b=1:3
    r=find(iP & strcmp(T.Bus,buses{b}),1);
    V(b)=T.V_pu(r)*exp(1j*T.Ang_deg(r)*pi/180);
    Pq(b)=(T.P_MW(r)+1j*T.Q_MVAr(r))/100;
  end
  Sgen=Pq(1); % B01 injection = gen output
  Sexp=-(Pq(3)); % power delivered into Egrid (P3<0 = export)
  Iexp=conj(Sexp/1.0); % Egrid = 1angle0
  V(3)=1.0+Iexp*Zgrid1; % floating junction prefault
  % continuity: same series current through Zline and Zgrid (2% tol covers aux)
  Iln=(V(2)-V(3))/Zline1;
  assert(abs(Iln-Iexp)/max(abs(Iexp),eps)<0.02,'prefault line/grid current mismatch');
  Vpre=V;
catch ME
  Vpre=[1.0*exp(1j*7.4747*pi/180); 1.000353*exp(1j*1.1402*pi/180); 1.0+Iexp*Zgrid1];
  warning('seq_networks:prefault','CSV parse failed (%s); using hardcoded P1A.',ME.message);
end
end
