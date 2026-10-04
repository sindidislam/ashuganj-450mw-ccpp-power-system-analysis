function Z = build_auxiliary_system(mdl, D)
%BUILD_AUXILIARY_SYSTEM  Auxiliary power zone of the Ashuganj South model.
%
%   Z = BUILD_AUXILIARY_SYSTEM(MDL, D) adds the unit auxiliary transformer,
%   the station auxiliary transformer and the 6.6 kV auxiliary load to model
%   MDL. Positions come from SPS_GEOM. Both transformers stand on the same
%   tier and both are 100 units tall, so their LV terminals land together on
%   the 6.6 kV bus tier and the busbar between them is one straight line - the
%   UAT feeding down from 22 kV on the left, the GAT feeding down from 230 kV
%   on the right, which is the parallel pair the SLD shows.
%
%   UAT 10BBT10 : 22/6.9 kV, ONAN/ONAF 19/25 MVA, Dyn11, off-circuit 5-tap,
%                 principal tap 3 = 22000 V, Z = 10.5 % and R = 0.4 % at
%                 25 MVA, no-load loss 14 kW, load loss 110 kW.
%
%   GAT 10BBT20 : 230/6.9/3.32 kV three-winding, YNyn0+d11, ONAN/ONAF
%                 19/25 MVA, windings 25/25/8.33 MVA, OLTC 25 taps,
%                 principal tap 13 = 230000 V, Z(P-S) = 12 % and R = 0.5 %
%                 at 25 MVA, no-load loss 23 kW, load loss 116 kW.
%
%   GAT REPRESENTATION (approved answer Q5a, treatment S2)
%   ------------------------------------------------------
%   Modelled as a TWO-winding 230/6.9 kV transformer on the documented
%   positive-sequence Z(P-S) = 12 %. The 3.32 kV / 1448.6 A delta tertiary is
%   explicitly OMITTED, not approximated: Z(P-T) and Z(S-T) are both MISSING
%   from the source set, and the three-winding block cannot be populated
%   without them. The tertiary is unloaded in the documented configuration, so
%   for a balanced load flow it carries no power and its omission changes no
%   solved quantity. It would matter for zero-sequence and harmonic studies,
%   which are out of scope here.
%
%   When the GAT is in service it closes a LOOP: 22 kV -> GSUT -> 230 kV
%   BUS 1 -> coupler -> BUS 2 -> GAT -> 6.6 kV, in parallel with
%   22 kV -> UAT -> 6.6 kV. The prior CYME PSAF model omitted the GAT
%   entirely (defect D6), so it could only ever produce the radial answer.
%
%   OFF-NOMINAL TURNS RATIO (conflict C13)
%   --------------------------------------
%   Both transformers have a 6.9 kV LV winding, while the switchgear and the
%   loads are rated 6.6 kV. The transformer winding voltages are set to the
%   documented 6900 V and the load nominal voltage to the documented 6600 V.
%   Forcing the winding to 6600 V to make the ratio "tidy" would move the
%   solved MV voltage by roughly +4.5 %, i.e. it would manufacture a
%   comfortable answer out of a real off-nominal ratio.
%
%   LOAD ALLOCATION (approved answer Q6B)
%   -------------------------------------
%   The documented 14 MW total is split 9050:2500:2500 kW across the main
%   6.6 kV bus and the two water-intake feeders in proportion to documented
%   motor ratings. The SPLIT ITSELF is an approved assumption; the total is
%   documented. Because the feeder impedances are undocumented and therefore
%   modelled as zero, this split has EXACTLY ZERO effect on any solved
%   quantity relative to a single lumped load. It is retained because it makes
%   the one-line match the plant, not because it changes the numbers.

B = sps_blocks();
g = sps_geom();

uat = D.tx(strcmp({D.tx.Name},'UAT'));
gat = D.tx(strcmp({D.tx.Name},'GAT'));

% ---- Unit auxiliary transformer ---------------------------------------
% 'down' puts the 22 kV winding on top. The UAT stands in its OWN column to the
% right of the unit chain, and its HV terminal is 160 units below the 22 kV bus
% tier, so the connection up to the bus is drawn as a riser and then a run along
% the bar. That is the drawing's horizontal branch 10BAA50, which is how
% DE-0001 Rev 03 taps the unit auxiliaries off the generator busbar.
Z.uat = sps_wire('add', mdl, B.tx2, uat.Label, ...
                 g.box(g.col.uat, g.tier.aux, g.tx), 'down');
apply_tx2(Z.uat, uat);
% Tinted on the 22 kV side, because that is where the UAT is fed from.
set_param(Z.uat, 'BackgroundColor', g.clr.fill22, ...
                 'ForegroundColor', g.clr.v22);

Z.node_B22  = sps_wire('port', Z.uat, 'L');   % 22 kV, on top
Z.node_B6_6 = sps_wire('port', Z.uat, 'R');   % 6.6 kV busbar node, at the bottom

% ---- Station auxiliary transformer ------------------------------------
% Same tier as the UAT, in the GAT column directly under its 230 kV bay
% breaker, so the HV lead is a straight vertical drop from BUS 2.
Z.gat = sps_wire('add', mdl, B.tx2, gat.Label, ...
                 g.box(g.col.gat, g.tier.aux, g.tx), 'down');
apply_tx2(Z.gat, gat);
% Tinted on the 230 kV side: the GAT is a grid-fed transformer, and colouring it
% like the switchyard is what makes the parallel path visible at a glance.
set_param(Z.gat, 'BackgroundColor', g.clr.fill230, ...
                 'ForegroundColor', g.clr.v230);

Z.node_GAT_HV = sps_wire('port', Z.gat, 'L');   % 230 kV lead up to BUS 2
sps_wire('link', mdl, sps_wire('port', Z.gat, 'R'), Z.node_B6_6, g.tier.bus66);

% ---- 6.6 kV loads -----------------------------------------------------
% 'down' puts each load's single terminal on its TOP edge, so every load hangs
% below the 6.6 kV busbar instead of beside it.
L = D.loads([D.loads.Model_included]);
assert(numel(L) == numel(g.col.load), ...
    ['build_auxiliary_system: %d modelled loads but %d load columns in ', ...
     'sps_geom. Add or remove a column - do not let two loads share one.'], ...
    numel(L), numel(g.col.load));
Z.load = cell(1, numel(L));
for i = 1:numel(L)
    lcx = g.col.load(i);
    Z.load{i} = sps_wire('add', mdl, B.load, L(i).Name, ...
                         g.box(lcx, g.tier.load, g.load), 'down');
    set_param(Z.load{i}, ...
        'Configuration',    L(i).Configuration, ...
        'NominalVoltage',   sprintf('%.10g', L(i).Vnom_V), ...
        'NominalFrequency', sprintf('%.10g', L(i).f_Hz), ...
        'ActivePower',      sprintf('%.10g', L(i).P_MW*1e6), ...
        'InductivePower',   sprintf('%.10g', L(i).Q_MVAr*1e6), ...
        'CapacitivePower',  '0', ...
        'LoadType',         L(i).LoadType);
    sps_wire('setopt', Z.load{i}, 'Measurements', 'None');
    set_param(Z.load{i}, 'BackgroundColor', g.clr.fill6600, ...
                         'ForegroundColor', g.clr.v6600);
    % The tier is passed explicitly. A load sits BELOW the 6.6 kV bus while the
    % bus node itself is the UAT's LV terminal ON it, so the two ports are not
    % on a common tier and sps_wire cannot infer one. Naming it draws the feeder
    % as a vertical riser up to the bar and then a run along the bar, instead of
    % an autorouted detour.
    sps_wire('link', mdl, sps_wire('port', Z.load{i}, 'L'), Z.node_B6_6, ...
             g.tier.bus66);
    sps_wire('note', mdl, L(i).Label, ...
        [lcx-46, g.tier.load+g.load.h+8, lcx+114, g.tier.load+g.load.h+28], ...
        10, 'bold', g.clr.v6600);
    sps_wire('note', mdl, sprintf('%.3f MW  %.3f MVAr', L(i).P_MW, L(i).Q_MVAr), ...
        [lcx-46, g.tier.load+g.load.h+30, lcx+114, g.tier.load+g.load.h+50], ...
        9, 'normal');
end

% ---- Labels ----------------------------------------------------------
% Two lines per transformer: tag, then ratio / group / rating / impedance. The
% derived numbers (R and X apart, X/R, Rm, Lm, tap arithmetic) are in the
% parameter table at the foot of the diagram. Annotation Position is honoured at
% its left and top edge only, so these are anchors with clear space to the right.
sps_wire('note', mdl, 'UAT  10BBT10', ...
    [g.col.uat+58, g.tier.aux+14, g.col.uat+238, g.tier.aux+36], 11, 'bold', g.clr.v22);
sps_wire('note', mdl, sprintf(['22/6.9 kV  Dyn11  Z = %.1f %%\n' ...
    '19/25 MVA  ONAN/ONAF\ntap %d/%d = %g V (principal)'], ...
    uat.Z_pct, uat.Tap_used, uat.Tap_positions, uat.Tap_V_used_V), ...
    [g.col.uat+58, g.tier.aux+40, g.col.uat+278, g.tier.aux+94], 9, 'normal');

sps_wire('note', mdl, 'GAT  10BBT20', ...
    [g.col.gat+58, g.tier.aux+14, g.col.gat+238, g.tier.aux+36], 11, 'bold', g.clr.v230);
sps_wire('note', mdl, sprintf(['230/6.9 kV  YNyn0  Z = %.1f %%\n' ...
    '19/25 MVA  ONAN/ONAF\ntap %d/%d = %g V (principal)\n' ...
    '3.32 kV tertiary - not modelled'], ...
    gat.Z_pct, gat.Tap_used, gat.Tap_positions, gat.Tap_V_used_V), ...
    [g.col.gat+58, g.tier.aux+40, g.col.gat+298, g.tier.aux+112], 9, 'normal');
% One compact line under the load row records the total and points at the two
% things a reader has to know about it. The full statement of the split, the zero
% feeder impedances and the off-nominal 6.9/6.6 kV ratio is in the DATA STATUS
% panel; repeating four lines of it here would sit on top of the generator, which
% now occupies the bottom of the left-hand column.
sps_wire('note', mdl, sprintf(['6.6 kV auxiliary total  %.3f MW / %.3f MVAr  at pf %.2f       ' ...
    'total is documented; the %g : %g : %g kW split between the three groups is assumed'], ...
    sum([L.P_MW]), sum([L.Q_MVAr]), D.loads(1).pf, 9050, 2500, 2500), ...
    [min(g.col.load)-46, g.tier.load+g.load.h+58, ...
     max(g.col.load)+180, g.tier.load+g.load.h+78], 9, 'normal');

Z.report = struct('UAT', pack(uat), 'GAT', pack(gat), ...
                  'Load_P_MW', sum([L.P_MW]), 'Load_Q_MVAr', sum([L.Q_MVAr]), ...
                  'nLoads', numel(L));
end

% =====================================================================
function apply_tx2(blk, t)
%APPLY_TX2  Populate one SPS two-winding transformer block from a registry row.
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
function r = pack(t)
r = struct('Name', t.Name, 'V_HV_V', t.V_HV_V, 'V_LV_V', t.V_LV_V, ...
           'S_rating_MVA', t.S_rating_MVA, 'S_MVA', t.S_MVA, ...
           'Z_pct', t.Z_pct, 'R_pct', t.R_pct, 'X_pct', t.X_pct, ...
           'XR', t.XR_ratio, 'Rm_pu', t.Rm_pu, 'Lm_pu', t.Lm_pu, ...
           'Conn_HV', t.Conn_HV, 'Conn_LV', t.Conn_LV, ...
           'VectorGroup', t.VectorGroup, 'Tap', t.Tap_used);
end
