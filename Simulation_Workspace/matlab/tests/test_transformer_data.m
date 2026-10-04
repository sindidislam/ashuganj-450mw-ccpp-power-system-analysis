function [np, nf] = test_transformer_data()
%TEST_TRANSFORMER_DATA  Nameplate, derivation and conflict checks on the three
%   transformers: GSUT 10BAT10, UAT 10BBT10 and GAT 10BBT20.
%
%   Two things are being defended here.
%
%   (1) Every DERIVED quantity is re-derived from the nameplate and compared,
%       so that a hand-edited number in the data file cannot survive. X from Z
%       and R, the R/2 and L/2 winding split, and Rm from the no-load loss are
%       all recomputed here independently of the code that produced them.
%
%   (2) Conflict C13 stays visible. The UAT and GAT LV windings are rated
%       6.9 kV while the plant MV busbar is 6.6 kV. Both numbers are correct
%       and they are not the same number. Silently modelling 22/6.6 would put
%       the MV bus about 4.5 % high and would look perfectly plausible. This
%       test asserts the 6.9 kV winding value is still 6.9 kV.
T = t_case('test_transformer_data');
X  = ashuganj_transformers();
Sb = 100;

T = T.eq(numel(X), 3, 'three transformers: GSUT, UAT, GAT');

for i = 1:numel(X)
    x = X(i);
    nm = x.Label;

    % ---- X from Z and R ------------------------------------------------
    Xexp = sqrt(x.Z_pct^2 - x.R_pct^2);
    T = T.near(x.X_pct, Xexp, 1e-9, ...
        sprintf('%s: X = sqrt(Z^2-R^2) = %.6f %%', nm, Xexp));
    T = T.chk(x.X_pct < x.Z_pct, sprintf('%s: X < Z', nm));

    % ---- per unit on the transformer'S OWN rating ----------------------
    T = T.near(x.Z_pu, x.Z_pct/100, 1e-12, ...
        sprintf('%s: Z_pu is on its own %g MVA rating, not the system base', nm, x.S_rating_MVA));
    T = T.near(x.R_pu, x.R_pct/100, 1e-12, sprintf('%s: R_pu on own rating', nm));
    T = T.near(x.X_pu, x.X_pct/100, 1e-12, sprintf('%s: X_pu on own rating', nm));

    % ---- the 50/50 winding split the SPS block expects -----------------
    T = T.near(x.R1_pu, x.R_pu/2, 1e-12, sprintf('%s: R1 = R/2', nm));
    T = T.near(x.R2_pu, x.R_pu/2, 1e-12, sprintf('%s: R2 = R/2', nm));
    T = T.near(x.L1_pu, x.X_pu/2, 1e-12, sprintf('%s: L1 = X/2', nm));
    T = T.near(x.L2_pu, x.X_pu/2, 1e-12, sprintf('%s: L2 = X/2', nm));
    T = T.near(x.R1_pu + x.R2_pu, x.R_pu, 1e-12, sprintf('%s: split preserves R', nm));
    T = T.near(x.L1_pu + x.L2_pu, x.X_pu, 1e-12, sprintf('%s: split preserves X', nm));

    % ---- magnetising resistance from the no-load loss ------------------
    RmExp = x.S_rating_MVA*1e3 / x.P_noload_kW;      % pu = S/Ploss
    T = T.near(x.Rm_pu, RmExp, 1e-6*RmExp, ...
        sprintf('%s: Rm = S/P_noload = %.1f pu (%g kW at %g MVA)', ...
                nm, RmExp, x.P_noload_kW, x.S_rating_MVA));

    % ---- zero sequence -------------------------------------------------
    T = T.near(x.L0_pu, x.Z0_pct/100, 1e-12, sprintf('%s: L0_pu from Z0 %%', nm));

    % ---- taps ----------------------------------------------------------
    T = T.chk(x.Tap_principal >= 1 && x.Tap_principal <= x.Tap_positions, ...
        sprintf('%s: principal tap %d is inside 1..%d', nm, x.Tap_principal, x.Tap_positions));
    T = T.eq(x.Tap_used, x.Tap_principal, ...
        sprintf('%s: model uses the DOCUMENTED principal tap (Q8a), not an optimised one', nm));

    % ---- frequency ------------------------------------------------------
    T = T.eq(x.f_Hz, 50, sprintf('%s: 50 Hz', nm));
end

% ---- named nameplate values, verbatim -----------------------------------
% Select on Name, not Label. Label carries the KKS as well ('GSUT 10BAT10'), so
% matching it against 'GSUT' silently returns a 0x1 struct and every field
% reference below expands to zero arguments instead of failing where the mistake
% is. The same slip was found in ashuganj_branch_flows.m.
G = X(strcmp({X.Name}, 'GSUT'));
T = T.eq(numel(G), 1,                   'GSUT selected by Name (Label is ''GSUT 10BAT10'')');
T = T.eq(G.KKS, '10BAT10',              'GSUT KKS 10BAT10');
T = T.eq(G.V_HV_V, 230000,              'GSUT HV 230 kV');
T = T.eq(G.V_LV_V,  22000,              'GSUT LV 22 kV');
T = T.eq(G.Z_pct,      16,              'GSUT Z 16 %');
T = T.eq(G.S_rating_MVA, 515,           'GSUT Z is quoted at the 515 MVA ODAF rating');
T = T.eq(G.VectorGroup, 'YNd1',         'GSUT YNd1');
% S_MVA is the list of COOLING STAGES of one unit. S_windings_MVA is a different
% quantity and exists only on the GAT: the individual ratings of its three
% windings. Confusing the two would be a 355/460/515 vs 25/25/8.33 error.
T = T.near(G.S_MVA, [355 460 515], 1e-9, ...
                                        'GSUT ONAN/ODAN/ODAF 355/460/515 MVA');
T = T.eq(G.Cooling, {'ONAN','ODAN','ODAF'}, 'GSUT three cooling stages named');
T = T.chk(isempty(G.S_windings_MVA), ...
    'GSUT has no per-winding rating list - it is a two-winding unit');
T = T.eq(G.P_noload_kW, 159,            'GSUT no-load loss 159 kW');
T = T.eq(G.Tap_positions, 25,           'GSUT OLTC 25 positions');
T = T.eq(G.Tap_principal,  9,           'GSUT principal tap 9');
T = T.eq(G.Tap_V_used_V, 230000,        'GSUT tap 9 = 230000 V');

U = X(strcmp({X.Name}, 'UAT'));
T = T.eq(U.KKS, '10BBT10',              'UAT KKS 10BBT10');
T = T.eq(U.V_HV_V, 22000,               'UAT HV 22 kV');
T = T.eq(U.V_LV_V,  6900,               'CONFLICT C13 PRESERVED: UAT LV winding is 6.9 kV');
T = T.eq(U.Z_pct,    10.5,              'UAT Z 10.5 %');
T = T.eq(U.VectorGroup, 'Dyn11',        'UAT Dyn11');
% The UAT is the one unit that CANNOT be re-tapped in service. That is why its
% tap position is a fixed modelling input rather than a control variable, and it
% is the reason Q8a (documented principal taps, not optimised) is not merely a
% reporting convention for this transformer - there is no on-load mechanism to
% optimise. The data records the side as well, which matters: it taps on the
% 22 kV HV winding, so the tap acts on the generator side of the auxiliary feed.
T = T.chk(strcmpi(U.Tap_type, 'Off-circuit on HV'), sprintf( ...
    'UAT tap changer is OFF-CIRCUIT, on the HV winding ("%s")', U.Tap_type));
T = T.chk(contains(lower(U.Tap_type), 'off-circuit'), ...
    'UAT cannot be re-tapped in service - the tap is a fixed model input');
G_ = X(strcmp({X.Name}, 'GSUT'));
T = T.chk(contains(lower(G_.Tap_type), 'oltc'), sprintf( ...
    'GSUT has an ON-LOAD tap changer ("%s"), held at the documented principal tap by Q8a', G_.Tap_type));

A = X(strcmp({X.Name}, 'GAT'));
T = T.eq(A.KKS, '10BBT20',              'GAT KKS 10BBT20');
T = T.eq(A.V_HV_V, 230000,              'GAT HV 230 kV');
T = T.eq(A.V_LV_V,   6900,              'CONFLICT C13 PRESERVED: GAT LV winding is 6.9 kV');
T = T.eq(A.V_TV_V,   3320,              'GAT tertiary 3.32 kV recorded');
T = T.near(A.S_windings_MVA, [25 25 8.33], 1e-9, ...
    'GAT per-winding ratings 25 / 25 / 8.33 MVA (HV / LV / tertiary)');
T = T.near(A.S_MVA, [19 25], 1e-9,      'GAT ONAN/ONAF 19/25 MVA cooling stages');
T = T.eq(A.Z_pct,      12,              'GAT Z_PS 12 %');
T = T.isnan(A.Z_PT_pct,                 'GAT Z_PT stays MISSING (NaN)');
T = T.isnan(A.Z_ST_pct,                 'GAT Z_ST stays MISSING (NaN)');
T = T.chk(contains(lower(A.Model_block), 'two') || contains(A.Model_block, 'Two'), ...
    'GAT modelled as a TWO-winding transformer (Q5a): unloaded tertiary omitted');

% ---- the 6.9 vs 6.6 kV consequence, quantified --------------------------
B    = ashuganj_buses();
b66  = B(strcmp({B.Name}, 'B6_6'));
err  = (U.V_LV_V/b66.Vnom_V - 1)*100;
T = T.near(err, 4.5455, 0.01, ...
    sprintf('modelling 22/6.6 instead of 22/6.9 would misplace the MV bus by %.2f %%', err));

% ---- base conversion for reporting only ---------------------------------
T = T.near(convert_to_system_base(G.Z_pu, G.S_rating_MVA, Sb), 0.0310679, 1e-6, ...
    'GSUT 16 % at 515 MVA = 3.1068 % on 100 MVA');
T = T.near(convert_to_system_base(U.Z_pu, U.S_rating_MVA, Sb), 0.4200, 1e-9, ...
    'UAT 10.5 % at 25 MVA = 42.00 % on 100 MVA');
T = T.near(convert_to_system_base(A.Z_pu, A.S_rating_MVA, Sb), 0.4800, 1e-9, ...
    'GAT 12 % at 25 MVA = 48.00 % on 100 MVA');

[np, nf] = T.done();
end
