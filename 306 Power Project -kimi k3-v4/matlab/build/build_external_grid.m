function Z = build_external_grid(mdl, D)
%BUILD_EXTERNAL_GRID  External grid zone of the Ashuganj South model.
%
%   Z = BUILD_EXTERNAL_GRID(MDL, D) adds the PGCB 230 kV equivalent to model
%   MDL using dataset D. The zone's position comes from SPS_GEOM, which holds
%   the whole diagram's column and tier grid, so that the three phase wires
%   between blocks run straight instead of wandering.
%   Returns a struct of block paths and the 1x3 port-handle arrays that
%   represent the zone's electrical nodes.
%
%   The zone is TWO blocks, and their separation is the whole point:
%
%     1. An IDEAL Three-Phase Source on 'swing' control, holding 1.00 pu at
%        the notional node BGRID230.
%     2. An EXPLICIT Three-Phase Series RLC Branch carrying the equivalent
%        impedance between BGRID230 and the plant boundary B230_1.
%
%   Putting the impedance OUTSIDE the source is deliberate. Specialized Power
%   Systems enforces the swing voltage at the source TERMINAL, so an
%   impedance placed inside the source block would be bypassed by the
%   load-flow voltage constraint and the grid would appear infinitely stiff
%   at B230_1. With the impedance outside, the boundary voltage genuinely
%   responds to plant export - which is the only reason to model a grid
%   impedance at all. (Structural treatment S6.)
%
%   The impedance itself is the ESTIMATED Siemens external-grid source quantity
%   (§2.4: UNgrid 230 kV; XN 2,66 estimated [=2.66]; Sk 19.919 [=19,919 MVA];
%   Ik 50 kA; executed |Z| = 2.65581124 ohm via √3), because no verified PGCB
%   grid strength exists anywhere in the source set. Equipment 50 kA/1 s+3 s,
%   125 kA peak, 50 kA making are separate EQUIPMENT RATINGS. Approved answer
%   Q1a permits this only as an explicitly labelled estimate. R = 0 exactly,
%   because X/R is undocumented.

B = sps_blocks();
G = D.grid;
g = sps_geom();
cx = g.col.grid;

% ---- Ideal swing source ------------------------------------------------
% Orientation 'down' puts the source's single three-phase terminal on its
% BOTTOM edge, so the grid feeds downward into the switchyard - the direction
% it is drawn on the SLD.
Z.src = sps_wire('add', mdl, B.source, 'EXT GRID', ...
                 g.box(cx, g.tier.src, g.src), 'down');
set_param(Z.src, ...
    'BusType',            G.LF_BusType, ...          % swing
    'NonIdealSource',     'off', ...                  % ideal: Z is external
    'InternalConnection', G.InternalConnection, ...   % Yg
    'VoltagePhases',      'off', ...
    'Voltage',            sprintf('%.10g', G.Vset_V), ...
    'PhaseAngle',         sprintf('%.10g', G.PhaseAngle_deg), ...
    'BaseVoltage',        sprintf('%.10g', G.Vnom_V), ...
    'Frequency',          sprintf('%.10g', G.f_Hz), ...
    'Qmin',               '-inf', ...
    'Qmax',               'inf');
% BaseVoltage is NOT cosmetic here. power_loadflow reads it as the source's
% nominal voltage (it appears in the solved struct as vsrc.Vnom) and uses it to
% per-unitise the network at this bus. Left at the 25 kV block default it makes
% the 2.6558 ohm grid equivalent look roughly 85 times larger than it is
% ((230/25)^2), which collapses the 230 kV bus to 0.06 pu and drives the
% generator to thousands of MVAr. Verified by probe: matlab/env/probe_params.m.
% It does NOT inject an impedance, because NonIdealSource is off.
set_param(Z.src, 'BackgroundColor', g.clr.fill230, ...
                 'ForegroundColor', g.clr.v230);

% ---- Explicit equivalent impedance ------------------------------------
% Orientation 'up' puts the L terminal on the BOTTOM, landing it exactly on
% the 230 kV BUS 1 tier, and the R terminal on top facing the source. Both
% terminals therefore sit in this column's port lanes and both wire runs are
% straight verticals.

L_idx = find(strcmp({D.lines.Name}, 'L_LINE'));
has_line = ~isempty(L_idx) && D.lines(L_idx).Model_included;

if has_line
    % Move ZGRID up to make room for L_LINE
    y_zgrid = g.tier.zgrid - 80;
else
    y_zgrid = g.tier.zgrid;
end

Z.br = sps_wire('add', mdl, B.series, 'ZGRID', ...
                g.box(cx, y_zgrid, g.ser), 'up');
if G.R_ohm == 0
    set_param(Z.br, 'BranchType', 'L');               % pure inductance
    set_param(Z.br, 'Inductance', sprintf('%.12g', G.L_H));
else
    set_param(Z.br, 'BranchType', 'RL');
    set_param(Z.br, 'Resistance', sprintf('%.12g', G.R_ohm));
    set_param(Z.br, 'Inductance', sprintf('%.12g', G.L_H));
end
sps_wire('setopt', Z.br, 'Measurements', 'None');
set_param(Z.br, 'BackgroundColor', g.clr.fill22, 'ForegroundColor', g.clr.v22);

% ---- Optional Transmission Line (Phase 3 Integration) -----------------
if has_line
    LL = D.lines(L_idx);
    
    % Place Pi Section Line at g.tier.zgrid so its bottom port aligns with bus1
    Z.line = sps_wire('add', mdl, B.pisection, LL.Name, ...
                      g.box(cx, g.tier.zgrid, g.ser), 'up');
                      
    w = 2 * pi * D.grid.f_Hz;
    L1 = LL.X_ohm / w;
    % Balanced-LF placeholder only: substitutes pos-seq for NaN zero-seq for PI dialog.
    % Data R0/X0/C0 remain NaN MISSING per locked set.
    % Never 3xX1 as fact.
    % Phase-4 fault work must replace this.
    if isfinite(LL.R0_ohm), R0_use = LL.R0_ohm; else, R0_use = LL.R_ohm; end
    if isfinite(LL.X0_ohm), X0_use = LL.X0_ohm; else, X0_use = LL.X_ohm; end
    if isfinite(LL.C0_F), C0_use = LL.C0_F; else, C0_use = LL.C_F; end
    L0_use = X0_use / w;
    
    set_param(Z.line, ...
        'Resistances', sprintf('[%.12g %.12g]', LL.R_ohm, R0_use), ...
        'Inductances', sprintf('[%.12g %.12g]', L1, L0_use), ...
        'Capacitances', sprintf('[%.12g %.12g]', LL.C_F, C0_use), ...
        'Length', '1', ...
        'Frequency', sprintf('%.12g', D.grid.f_Hz));
        
    sps_wire('setopt', Z.line, 'Measurements', 'None');
    set_param(Z.line, 'BackgroundColor', g.clr.fill22, 'ForegroundColor', g.clr.v22);

    % Wire source 'R' to ZGRID 'R'
    sps_wire('link', mdl, sps_wire('port', Z.br, 'R'), sps_wire('port', Z.src, 'R'));
    % Wire ZGRID 'L' to L_LINE 'R'
    sps_wire('link', mdl, sps_wire('port', Z.br, 'L'), sps_wire('port', Z.line, 'R'));
    
    % Exported nodes
    Z.node_BGRID230 = sps_wire('port', Z.src, 'R');
    Z.node_B230_REMOTE = sps_wire('port', Z.br, 'L');
    Z.node_B230_1   = sps_wire('port', Z.line, 'L');
else
    % Wire source 'R' to ZGRID 'R'
    sps_wire('link', mdl, sps_wire('port', Z.br, 'R'), sps_wire('port', Z.src, 'R'));
    % ---- Exported nodes ---------------------------------------------------
    Z.node_BGRID230 = sps_wire('port', Z.src, 'R');   % behind the impedance
    Z.node_B230_1   = sps_wire('port', Z.br,  'L');   % plant boundary
end

% ---- Labels ----------------------------------------------------------
% Anchored to the LEFT of the column, in the band above 230 kV BUS 1 that this
% zone owns. Annotation Position is only honoured at its LEFT and TOP: Simulink
% refits the right and bottom edges to the text. So these coordinates are
% anchors, and the space to their right is deliberately left empty.
sps_wire('note', mdl, 'EXTERNAL GRID  (PGCB)', ...
         [cx-290, g.tier.src+6, cx-70, g.tier.src+30], 12, 'bold', g.clr.v230);
sps_wire('note', mdl, sprintf('230 kV   swing bus   %.2f pu   %g Hz', ...
         G.Vset_V/G.Vnom_V, G.f_Hz), ...
         [cx-290, g.tier.src+34, cx-70, g.tier.src+54], 9, 'normal');
sps_wire('note', mdl, sprintf('Z_grid = j%.4f ohm', G.X_ohm), ...
         [cx-290, g.tier.src+g.src.h+6, cx-110, g.tier.src+g.src.h+28], ...
         10, 'bold', g.clr.v22);
sps_wire('note', mdl, sprintf(['X/R = %s\nESTIMATED Siemens §2.4 50 kA source,\n' ...
    'NOT verified PGCB data - the weakest\nnumber in the model'], xr_word(G)), ...
         [cx-290, g.tier.src+g.src.h+30, cx-30, g.tier.src+g.src.h+98], 9, 'normal');

Z.report = struct('Vset_V', G.Vset_V, 'R_ohm', G.R_ohm, 'X_ohm', G.X_ohm, ...
                  'L_H', G.L_H, 'Status', G.X_Status);
end

% =====================================================================
function w = xr_word(G)
%XR_WORD  Render the grid X/R for the diagram caption.
%   With R = 0 exactly the ratio is infinite, and printing "Inf" is more honest
%   than printing a large finite number that looks measured.
if G.R_ohm == 0
    w = 'infinite - R not documented';
else
    w = sprintf('%.1f', G.X_ohm / G.R_ohm);
end
end
