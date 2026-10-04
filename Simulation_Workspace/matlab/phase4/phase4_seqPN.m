function N = phase4_seqPN(ds, XoR_P)
%PHASE4_SEQPN  Positive/negative-sequence impedances on 100 MVA / 230 kV.
%
%   N = PHASE4_SEQPN(ds, XoR_P) returns positive- and negative-sequence
%   resistances and reactances in pu on 100 MVA / 230 kV (ohms divided
%   by 529). ds selects the grid dataset: 'P' splits the fixed magnitude
%   2.65581124 ohm with XoR_P; 'S' ignores XoR_P and uses the fixed
%   0.267344 / 2.938108 ohm split of the 10.99 profile.
%
%   Machine transfer: machine reactances given in pu on 458 MVA / 22 kV
%   transfer to the study base by the MVA ratio 100/458 alone. Voltage
%   bases are taken at the nominal zone voltages (22 kV machine zone,
%   230 kV study zone) with the step-up ratio absorbed in the base
%   definition, so no additional voltage factor is applied. Stator ohm
%   values are referred through (230/22)^2 before dividing by 529, which
%   is algebraically identical to pu-machine conversion via 100/458.
%
%   Step-up 22 kV to 230 kV handling: impedances referred through the
%   step-up transformer are carried in pu on the study base with the same
%   treatment -- MVA-ratio transfer only, voltage ratio absorbed in the
%   bases -- consistent with the base handling used for source equivalents.
%   Negative sequence equals positive sequence for static plant (GSUT, UAT,
%   GAT, line, grid) as a justified static equality; the machine uses its
%   distinct 0.2242 negative-sequence reactance.
%
%   Provenance (values from phase4_registry, frozen Phase-3 totals from
%   ashuganj_lines): machine 0.2248 sat / 0.2608 unsat / 0.2242 neg-seq on
%   458 MVA with Ra 0.00089 ohm stator; GSUT 16.0 % / 0.21 % on 515 MVA;
%   UAT 10.5 % / 0.4 % on 25 MVA; GAT 12.0 % / 0.5 % on 25 MVA; line
%   0.0277725 / 0.1425655 ohm frozen totals; grid P magnitude 2.65581124
%   ohm; grid S fixed 0.267344 / 2.938108 ohm.
%
%   No neutral leg is modelled here.

if isstring(ds)
    ds = char(ds);
end
if ~(ischar(ds) && numel(ds) == 1 && (ds == 'P' || ds == 'S'))
    error('phase4_seqPN:badDataset', 'ds must be ''P'' or ''S''.');
end

R = phase4_registry();
Zbase = R.frozen.Zbase_ohm.value; % 529

% ---- machine (458 MVA / 22 kV qualified) ----
Snom_m = R.machine.Snom_MVA.value; % 458
Vnom_m = R.machine.Vnom_kV.value; % 22
Xdpp_sat = R.machine.Xdpp_sat.value; % 0.2248
Xdpp_uns = R.machine.Xdpp.value; % 0.2608
X2m = R.machine.X2.value; % 0.2242
Ra_ohm = R.machine.Ra_ohm.value; % 0.00089
kM = 100 / Snom_m;
Ra_pu = (Ra_ohm / (Vnom_m^2 / Snom_m)) * kM;
N.Z1gen_sat_R = Ra_pu;
N.Z1gen_sat_X = Xdpp_sat * kM;
N.Z1gen_unsat_R = Ra_pu;
N.Z1gen_unsat_X = Xdpp_uns * kM;
N.Z2gen_R = Ra_pu;
N.Z2gen_X = X2m * kM;

% ---- GSUT 16.0 % / 0.21 % on 515 MVA ----
Zg_pct = R.gsut.Z_pct.value; % 16.0
Rg_pct = R.gsut.R_pct.value; % 0.21
Zg_pu_r = Zg_pct / 100;
Rg_pu_r = Rg_pct / 100;
Xg_pu_r = sqrt(Zg_pu_r^2 - Rg_pu_r^2);
kG = 100 / 515;
N.Z1gsut_R = Rg_pu_r * kG;
N.Z1gsut_X = Xg_pu_r * kG;
N.Z2gsut_R = N.Z1gsut_R;
N.Z2gsut_X = N.Z1gsut_X;

% ---- UAT 10.5 % / 0.4 % on 25 MVA ----
Zu_pct = R.uat.Z_pct.value; % 10.5
Ru_pct = R.uat.R_pct.value; % 0.4
Zu_pu_r = Zu_pct / 100;
Ru_pu_r = Ru_pct / 100;
Xu_pu_r = sqrt(Zu_pu_r^2 - Ru_pu_r^2);
kU = 100 / 25;
N.Z1uat_R = Ru_pu_r * kU;
N.Z1uat_X = Xu_pu_r * kU;
N.Z2uat_R = N.Z1uat_R;
N.Z2uat_X = N.Z1uat_X;

% ---- GAT 12.0 % / 0.5 % on 25 MVA ----
Za_pct = R.gat.Z_PS_pct.value; % 12.0
Ra_pct = R.gat.R_PS_pct.value; % 0.5
Za_pu_r = Za_pct / 100;
Ra_pu_r = Ra_pct / 100;
Xa_pu_r = sqrt(Za_pu_r^2 - Ra_pu_r^2);
kA = 100 / 25;
N.Z1gat_R = Ra_pu_r * kA;
N.Z1gat_X = Xa_pu_r * kA;
N.Z2gat_R = N.Z1gat_R;
N.Z2gat_X = N.Z1gat_X;

% ---- line frozen totals ----
Rline_ohm = R.frozen.R_eq_ohm.value; % 0.0277725
Xline_ohm = R.frozen.X_eq_ohm.value; % 0.1425655
N.Z1line_R_pu = Rline_ohm / Zbase;
N.Z1line_X_pu = Xline_ohm / Zbase;
N.Z2line_R_pu = N.Z1line_R_pu;
N.Z2line_X_pu = N.Z1line_X_pu;
N.Z1line_R = N.Z1line_R_pu;
N.Z1line_X = N.Z1line_X_pu;
N.Z2line_R = N.Z2line_R_pu;
N.Z2line_X = N.Z2line_X_pu;
N.Z1line = N.Z1line_R_pu + 1j * N.Z1line_X_pu;
N.Z2line = N.Z2line_R_pu + 1j * N.Z2line_X_pu;

% ---- grid ----
if ds == 'P'
    if ~(isscalar(XoR_P) && isfinite(XoR_P) && XoR_P >= 10 && XoR_P <= 20)
        error('phase4_seqPN:badXoR', 'XoR_P must be finite in [10,20] for dataset P.');
    end
    Zmag = R.grid.P.Zmag_ohm.value; % 2.65581124
    Rg_ohm = Zmag / sqrt(XoR_P^2 + 1);
    Xg_ohm = XoR_P * Rg_ohm;
    N.Z1grid_R = Rg_ohm / Zbase;
    N.Z1grid_X = Xg_ohm / Zbase;
    N.Z2grid_R = N.Z1grid_R;
    N.Z2grid_X = N.Z1grid_X;
    N.XoR_used = XoR_P;
else
    % Dataset S split DERIVED from registry Ik/XoR (never literals):
    % |Z| = Vll^2/Ssc with Ssc = sqrt(3)*Vll*Ik at c = 1, then R/X split.
    IkS = R.grid.S.Ik_kA.value; % 45.01
    XoRS = R.grid.S.XoR.value; % 10.99
    VllS = R.frozen.Vbase_kV.value; % 230
    ZmagS = VllS^2/(sqrt(3)*VllS*IkS);
    RgS_ohm = ZmagS/sqrt(XoRS^2 + 1);
    XgS_ohm = RgS_ohm*XoRS;
    N.Z1grid_R = RgS_ohm / Zbase;
    N.Z1grid_X = XgS_ohm / Zbase;
    N.Z2grid_R = N.Z1grid_R;
    N.Z2grid_X = N.Z1grid_X;
    N.XoR_used = 10.99;
end
N.ds = ds;
end
