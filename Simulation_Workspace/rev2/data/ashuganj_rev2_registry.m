function D = ashuganj_rev2_registry()
%ASHUGANJ_REV2_REGISTRY Versioned data registry Rev2 (Sep-10 master truth).
% 100 MVA reporting base, 50 Hz. Statuses A/B/C/D per master legend.
% Old matlab/* Aug model is PROVISIONAL and must not override these values.
% See rev2/data/reconciliation_register.csv for supersession log.

D.meta.Project = 'Ashuganj South 450MW CCPP (South) Rev2';
D.meta.SourceTruth = 'Ashuganj_South_Final_Master_Data_and_Assumptions (1).md Sep-10';
D.meta.Revision = 'Rev2-2026-09-10-Phase1';
D.meta.Date = '2026-09-10';
D.meta.Sbase_MVA = 100; D.meta.Sbase_Status = 'C'; % master §9C + user reporting directive
D.meta.f_Hz = 50; D.meta.f_Status = 'C'; % master §4/§9 C/system assumption

% ---- Generator SGen5-2000H (B unless noted) ----
G.Name='G1'; G.Model='SGen5-2000H'; G.Train='SGT5-4000F+SST-3000 1S single-shaft';
G.Snom_MVA=458; G.Snom_Status='B'; G.Vnom_kV=22; G.Vnom_Status='B';
G.Pmax_MW=360; G.Pmax_Status='B'; G.Pmin_MW=180; G.Pmin_Status='C';
G.Qmax_MVAr=200; G.Qmin_MVAr=-200; G.QLim_Status='C';
G.H_s=5.287; G.H_Status='B';
G.Xd=1.783; G.Xdp=0.3256; G.Xdpp_sat=0.2248; G.Xdpp=0.2608; % primary sat / sens
G.Xq=1.751; G.Xqp=0.5087; G.Xqpp=0.2593; G.Xl=0.2027;
G.X2=0.2242; G.X0=0.1280; G.Dyn_Status='B';
G.Ra_ohm=0.00089; G.Ra_Status='B';
% R in pu on own base: Zbase=22^2/458=1.05677 ohm
Zb_gen = 22^2/458;
G.R1_pu = G.Ra_ohm/Zb_gen; % ~0.000842 D
G.R1_Status='D'; G.R2_pu=G.R1_pu; G.R2_Status='C'; G.R0_pu=1.5*G.R1_pu; G.R0_Status='C';
G.Earthing='Solidly grounded'; G.Earthing_Status='B'; % supersedes old NER
G.Vset_pu=1.00; G.Vset_Status='C';
D.gen=G;

% ---- GSUT 10BAT10 515MVA 22/230kV YNd1 solid (B/D) ----
T.Name='GSUT'; T.S_MVA_stages=[355 460 515]; T.S_base_MVA=515;
T.V_HV_kV=230; T.V_LV_kV=22; T.Vec='YNd1'; T.Neutral='Solidly grounded'; T.Vec_Status='B';
T.Z1_pu_own=0.1663; T.Z1_Status='B'; T.R1_pu_own=0.001771; T.R1_Status='D';
T.X1_pu_own=sqrt(T.Z1_pu_own^2-T.R1_pu_own^2); % ~0.16629 D
T.X1_Status='D';
% to 100 MVA system base
T.R1_pu_sys=T.R1_pu_own*(100/T.S_base_MVA);
T.X1_pu_sys=T.X1_pu_own*(100/T.S_base_MVA);
T.tap_a=1.0; T.tap_Status='C nominal used';
D.gsut=T;

% ---- UAT 10BBT10 (retain nameplate detail over §24 generic) ----
U.Name='UAT'; U.S_stages=[19 25]; U.S_base=25; U.V_HV_kV=22; U.V_LV_kV=6.9;
U.Vec='Dyn11'; U.Status='B-nameplate'; U.Z_pct=10.5; U.R_pct=0.4;
U.Z_pu_own=U.Z_pct/100; U.R_pu_own=U.R_pct/100;
U.X_pu_own=sqrt(U.Z_pu_own^2-U.R_pu_own^2);
U.R_pu_sys=U.R_pu_own*(100/U.S_base); U.X_pu_sys=U.X_pu_own*(100/U.S_base);
U.a_LV=6.6/6.9; % off-nominal: 6.9kV winding onto 6.6kV bus -> 0.95652 C-model
U.a_Status='C off-nominal applied on LV';
D.uat=U;

% ---- GAT 10BBT20 (two-winding equiv; tertiary omitted, Zpt/Zst MISSING) ----
GT.Name='GAT'; GT.S_stages=[19 25]; GT.S_base=25; GT.V_HV_kV=230; GT.V_LV_kV=6.9;
GT.Vec='YNyn0+d11 (modelled YNyn0, tertiary omitted)'; GT.Status='B-nameplate';
GT.Zps_pct=12.0; GT.R_pct=0.5; GT.Z_pu_own=GT.Zps_pct/100; GT.R_pu_own=GT.R_pct/100;
GT.X_pu_own=sqrt(GT.Z_pu_own^2-GT.R_pu_own^2);
GT.R_pu_sys=GT.R_pu_own*(100/GT.S_base); GT.X_pu_sys=GT.X_pu_own*(100/GT.S_base);
GT.a_LV=6.6/6.9; GT.Zpt_Status='MISSING'; GT.Zst_Status='MISSING';
D.gat=GT;

% ---- Buses ----
D.bus.B01.kV=22;  D.bus.B01.type='PV';   D.bus.B01.Vset=1.0;
D.bus.B02.kV=230; D.bus.B02.type='PQ';
D.bus.B03.kV=230; D.bus.B03.type='slack'; D.bus.B03.Vset=1.0; D.bus.B03.ang=0;
D.bus.B11.kV=6.6; D.bus.B11.type='PQ'; % plant aux bus (C voltage)
D.bus.B04.kV=400; D.bus.B04.type='PQ-external-regional';
D.bus.B05.kV=400; D.bus.B05.type='PQ-external-regional';

% ---- Aux load (C, single aggregate, do NOT double count) ----
D.aux.P_MW=12; D.aux.Q_MVAr=5; D.aux.bus='B11'; D.aux.Status='C';
D.aux.P_pu=12/100; D.aux.Q_pu=5/100;

% ---- Grid Thevenin B/C (adopt Rth/Xth as given; record |Z| contradiction) ----
D.grid.Isc_kA=45.01; D.grid.Ssc_GVA=17.93; D.grid.XR=10.99;
D.grid.Rth_ohm=0.268; D.grid.Xth_ohm=2.94; D.grid.Status='B/C-preliminary';
D.grid.Zmag_reported_ohm=3.25; D.grid.Zmag_calc_ohm=2.952; % 230^2/17930
D.grid.Note='Adopt Rth/Xth; |Z| contradiction logged; GIS 50kA withstand ONLY, never grid level';
Zb230=230^2/100; D.grid.R_pu=D.grid.Rth_ohm/Zb230; D.grid.X_pu=D.grid.Xth_ohm/Zb230;

% ---- 0.7km 2ckt connection B02-B03 (B route/cct, C electrics) ----
D.line07.len_km=0.7; D.line07.ckts=2;
D.line07.R1_ohm_km=0.08; D.line07.X1_ohm_km=0.35; D.line07.B1_uS_km=4.2; D.line07.Elec_Status='C';
D.line07.R_ohm=(0.08*0.7)/2; D.line07.X_ohm=(0.35*0.7)/2; D.line07.B_uS=4.2*0.7*2;
D.line07.R_pu=D.line07.R_ohm/Zb230; D.line07.X_pu=D.line07.X_ohm/Zb230;
D.line07.B_pu=D.line07.B_uS*1e-6*Zb230;
% series B02-B03 = line + grid Thevenin
D.br023.R_pu=D.line07.R_pu+D.grid.R_pu; D.br023.X_pu=D.line07.X_pu+D.grid.X_pu;
D.br023.B_pu=D.line07.B_pu;

% ---- Operating cases Phase 1 ----
% P1A base 354 radial; P1B 360 upper; P1C transfer ABNORMAL GAT IN;
% P1D weak 1.5xZth; P1E strong 0.7xZth; P1F line 0.8x; P1G line 1.2x
D.cases(1)=struct('ID','P1A','P_MW',354,'GAT_in',false,'grid_k',1.0,'line_k',1.0,'Note','Base 354MW gross radial NORMAL');
D.cases(2)=struct('ID','P1B','P_MW',360,'GAT_in',false,'grid_k',1.0,'line_k',1.0,'Note','Upper 360MW Pmax radial');
D.cases(3)=struct('ID','P1C','P_MW',354,'GAT_in',true,'grid_k',1.0,'line_k',1.0,'Note','ABNORMAL transfer sens GAT IN - not normal op');
D.cases(4)=struct('ID','P1D','P_MW',354,'GAT_in',false,'grid_k',1.5,'line_k',1.0,'Note','Weak grid 1.5x Zth sens');
D.cases(5)=struct('ID','P1E','P_MW',354,'GAT_in',false,'grid_k',0.7,'line_k',1.0,'Note','Strong grid 0.7x Zth sens');
D.cases(6)=struct('ID','P1F','P_MW',354,'GAT_in',false,'grid_k',1.0,'line_k',0.8,'Note','Line 0.8x sens C-values');
D.cases(7)=struct('ID','P1G','P_MW',354,'GAT_in',false,'grid_k',1.0,'line_k',1.2,'Note','Line 1.2x sens C-values');
end
