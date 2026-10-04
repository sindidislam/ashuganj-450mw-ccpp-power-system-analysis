function Z = build_gsut_system(mdl, D)
%BUILD_GSUT_SYSTEM  Generator step-up transformer zone, Ashuganj South.
%
%   Z = BUILD_GSUT_SYSTEM(MDL, D) adds GSUT 10BAT10 to model MDL. The block's
%   position comes from SPS_GEOM: it stands in the GSUT column and spans the
%   230 kV BUS 1 tier down to the 22 kV GEN BUS tier, because its two winding
%   terminals ARE those two bus nodes. SPS_GEOM asserts that span, so the
%   transformer cannot drift off either busbar without the build stopping.
%
%   GSUT 10BAT10 : 230/22 kV, ONAN/ODAN/ODAF 355/460/515 MVA, YNd1,
%                  OLTC 25 taps on HV, principal tap 9 = 230000 V,
%                  Z = 16 % and R = 0.21 % at 515 MVA,
%                  no-load loss 159 kW, load loss 523/874/1095 kW.
%
%   The block is oriented 'down' so that the 230 kV winding is on top and the
%   22 kV winding at the bottom, which is how a plant one-line diagram is
%   drawn. Winding 1 stays the HV winding, exactly as the nameplate lists it,
%   so the YNd1 vector group maps directly onto the block.
%
%   TAP (approved answer Q8a): principal tap 9, which is 253000 - 8*2875 =
%   230000 V exactly, so the modelled ratio is precisely nominal. Taps are
%   NOT optimised to improve the solved voltage profile.
%
%   Note on the impedance base: the SPS block takes per-unit values on ITS
%   OWN NominalPower, which is how the nameplate quotes them, so nothing is
%   converted here. Converting to the 100 MVA reporting base at this point
%   would be a double conversion; that base is used only for reporting.

B  = sps_blocks();
t  = D.tx(strcmp({D.tx.Name},'GSUT'));
g  = sps_geom();
cx = g.col.gsut;

Z.tx = sps_wire('add', mdl, B.tx2, t.Label, ...
                g.box(cx, g.tier.bus1, g.tx), 'down');
apply_transformer_params(Z.tx, t);
% Filled in the 230 kV tint, outlined in the 230 kV ink: the GSUT straddles two
% levels, and it is the HV side that decides which switchyard it belongs to.
set_param(Z.tx, 'BackgroundColor', g.clr.fill230, ...
                'ForegroundColor', g.clr.v230);

Z.node_HV = sps_wire('port', Z.tx, 'L');   % 230 kV, on top,    on BUS 1
Z.node_LV = sps_wire('port', Z.tx, 'R');   % 22 kV, at bottom,  on the 22 kV bus

% ---- Labels ----------------------------------------------------------
% Tag, ratio, vector group, rating, impedance - and stop. The derived detail
% (R and X separately, X/R, Rm, Lm, the tap arithmetic) moves to the parameter
% table at the foot of the diagram, where it can be read as a table instead of
% competing with the one-line for space. A plant drawing captions a transformer
% in three lines and so does this.
%
% Annotation Position is only honoured at its left and top edge - Simulink
% refits the right and bottom to the text - so these are anchors and the space
% to the right of them is left deliberately clear.
sps_wire('note', mdl, 'GSUT  10BAT10', ...
    [cx+58, g.tier.bus1+14, cx+238, g.tier.bus1+36], 11, 'bold', g.clr.v230);
sps_wire('note', mdl, sprintf(['230/22 kV  YNd1  Z = %.1f %%\n' ...
    '355/460/515 MVA  ONAN/ODAN/ODAF\ntap %d/%d = %g V (principal)'], ...
    t.Z_pct, t.Tap_used, t.Tap_positions, t.Tap_V_used_V), ...
    [cx+58, g.tier.bus1+40, cx+298, g.tier.bus1+94], 9, 'normal');

Z.report = pack_report(t);
end

% =====================================================================
function apply_transformer_params(blk, t)
%APPLY_TRANSFORMER_PARAMS  Populate one SPS two-winding transformer block.
%   Shared by the GSUT and auxiliary zone builders so that the parameter
%   mapping exists in exactly one place.
set_param(blk, ...
    'UNITS',              'pu', ...
    'NominalPower',       sprintf('[ %.10g , %.10g ]', t.S_rating_MVA*1e6, t.f_Hz), ...
    'Winding1',           sprintf('[ %.10g , %.12g , %.12g ]', t.V_HV_V, t.R1_pu, t.L1_pu), ...
    'Winding2',           sprintf('[ %.10g , %.12g , %.12g ]', t.V_LV_V, t.R2_pu, t.L2_pu), ...
    'Winding1Connection', t.Conn_HV, ...
    'Winding2Connection', t.Conn_LV, ...
    'CoreType',           t.Model_coretype, ...
    'SetSaturation',      t.Model_saturation, ...
    'Rm',                 sprintf('%.10g', t.Rm_pu), ...
    'Lm',                 sprintf('%.10g', t.Lm_pu), ...
    'L0',                 sprintf('%.10g', t.L0_pu));
sps_wire('setopt', blk, 'Measurements', 'None');
end

% =====================================================================
function r = pack_report(t)
r = struct('Name', t.Name, 'V_HV_V', t.V_HV_V, 'V_LV_V', t.V_LV_V, ...
           'S_rating_MVA', t.S_rating_MVA, 'S_MVA', t.S_MVA, ...
           'Z_pct', t.Z_pct, 'R_pct', t.R_pct, 'X_pct', t.X_pct, ...
           'XR', t.XR_ratio, 'Rm_pu', t.Rm_pu, 'Lm_pu', t.Lm_pu, ...
           'Conn_HV', t.Conn_HV, 'Conn_LV', t.Conn_LV, ...
           'VectorGroup', t.VectorGroup, 'Tap', t.Tap_used);
end
