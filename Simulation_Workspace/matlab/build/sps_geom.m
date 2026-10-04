function g = sps_geom()
%SPS_GEOM  One-line-diagram layout constants for the Ashuganj South model.
%
%   g = SPS_GEOM() returns the column centres, tier heights, block sizes,
%   colours and the box helpers that every zone builder uses. It is the SINGLE
%   place the diagram geometry is defined.
%
%   THE LAYOUT MIRRORS DRAWING DE-0001 REV 03
%   -----------------------------------------
%   The whole point of this diagram is that it can be laid beside the governing
%   plant one-line, INEL-112070-00-ELC-DE-0001 Rev 03, and checked element by
%   element. So the arrangement is not chosen for the convenience of the solver;
%   it is copied from the drawing. Positions measured off the Rev 03 sheet,
%   normalised to its 4525 x 3200 extent:
%
%       element                 sheet x     sheet y    this model
%       ----------------------  ----------  ---------  ------------------
%       "To 230 kV GIS" (left)     0.117      0.021    EXT GRID band, top
%       GSUT 10BAT10               0.135      0.120    col.gsut, tier.bus1
%       IPB 10BAA40 / 22 kV        0.110      0.177    col.g1,   tier.b22
%       GCB 10BAC10                0.125      0.304    (ideal - treatment S4)
%       GENERATOR 10MKA10          0.125      0.664    col.g1,   tier.g1
%       UAT 10BBT10                0.255      0.233    col.uat,  tier.aux
%       MV BUS 10BBA10          0.170-0.714   0.357    bar.bus66, tier.bus66
%       "To 230 kV GIS" (right)    0.714      0.127    tier.bus2 band
%       GAT 10BBT20                0.719      0.230    col.gat,  tier.aux
%       load feeders            0.187-0.699   0.416    tier.load
%
%   Three consequences of copying the drawing rather than inventing a layout:
%
%     * The GENERATOR sits at the BOTTOM of a long left-hand column, well below
%       the 6.6 kV bus, exactly as on the sheet. The 22 kV connection up to the
%       GSUT is therefore one long vertical line - which is what the drawing
%       shows as the isolated phase busbar run 10BAA40. It passes to the LEFT of
%       the 6.6 kV busbar and crosses nothing (asserted below).
%     * The UAT is in its OWN column to the right of the unit chain, tapped off
%       the 22 kV bus by a horizontal run. That run is the drawing's branch
%       10BAA50. An earlier version of this file forced the UAT into the GSUT's
%       column to save two bends; the drawing does not do that, and matching the
%       drawing is worth more than the two bends.
%     * The 230 kV switchyard has NO counterpart on DE-0001 - the sheet shows
%       only two "To 230 kV GIS" arrows, one above the GSUT and one above the
%       GAT. The model expands that into BUS 1, BUS 2, the coupler and the GAT
%       bay breaker, placed in the band ABOVE the GSUT and spanning right to the
%       GAT column, i.e. exactly between the two places the arrows point.
%
%   THE PORT-SPACING RULE (measured, and NOT what it looks like)
%   -----------------------------------------------------------
%   Specialized Power Systems spreads a block's three physical ports along the
%   edge they sit on. Measured with matlab/env/probe_style.m in R2024a:
%
%       block type                       w=70        w=80        w=90
%       -------------------------------  ----------  ----------  ----------
%       Three-Phase Transformer (2 Wdg)  (n/a)       +-25        +-30
%       Breaker / Source / Load / RLC    +-25        +-25        (n/a)
%
%   So ONLY the transformer's port spacing tracks its width (inset 15). Every
%   other block is PINNED at +-25 whatever its width. That kills the obvious
%   idea of widening everything to spread the phase wires out: widen the
%   transformer and its ports no longer line up with anything else.
%
%   Therefore port_dx is FIXED at 25 and every block is 80 wide - the one width
%   at which all five block types put their ports on
%
%       cx - 25,   cx,   cx + 25
%
%   Extra breathing room comes from bigger gaps between columns and tiers, and
%   from taller blocks, never from wider ones. Heights do not affect port x.
%
%   ORIENTATION
%   -----------
%   For orientation 'down' the L ports are on TOP and the R ports on the
%   BOTTOM; 'up' reverses it. Winding 1 (HV) is the L side on every SPS
%   transformer, so 'down' draws each transformer with HV on top and LV
%   underneath, which is how a plant one-line is drawn.
%
%   See also SPS_WIRE, BUILD_ASHUGANJ_MAIN.

% ---- block sizes -------------------------------------------------------
% One width, 80, for every block: the only value at which the transformer's
% port spacing (inset 15) and every other block's pinned spacing both come out
% at 25. Do not change a width without re-running matlab/env/probe_style.m.
g.tx   = struct('w', 80, 'h', 120);   % Three-Phase Transformer (Two Windings)
g.dev  = struct('w', 80, 'h', 100);   % Three-Phase Breaker
g.load = struct('w', 80, 'h',  80);   % Three-Phase Parallel RLC Load
g.src  = struct('w', 80, 'h', 110);   % Three-Phase Source
g.ser  = struct('w', 80, 'h',  60);   % Three-Phase Series RLC Branch
g.port_dx = 25;                       % resulting port offset from cx

% box(cx, ytop, size) -> [left top right bottom], centred on the column.
g.box = @(cx, ytop, s) [cx - s.w/2, ytop, cx + s.w/2, ytop + s.h];

% ---- column centres ----------------------------------------------------
% Left to right, in the drawing's own order: the unit chain on the far left,
% the auxiliary tap next to it, the switchyard above and across, and the grid
% auxiliary transformer on the far right.
g.col.g1      =  200;   % GENERATOR 10MKA10 - bottom of the left-hand chain
g.col.gsut    =  200;   % GSUT 10BAT10 - directly ABOVE the generator
g.col.uat     =  480;   % UAT 10BBT10 - its own column, tapped off 22 kV
g.col.grid    =  700;   % EXT GRID source and the grid equivalent branch
g.col.coupler = 1000;   % bus coupler 10BAY12
g.col.gat     = 1620;   % GAT 10BBT20 and its bay breaker 10BAY20 - far right
g.col.load    = [480, 860, 1240];   % the three 6.6 kV load groups

% The generator shares the GSUT's column. That is the one column identity the
% drawing DOES use: 10BAT10, the isolated phase busbars and 10MKA10 are all on
% the same vertical centre line, so the 22 kV connection is a single straight
% run. Breaking this would turn the drawing's cleanest feature into a detour.
assert(g.col.g1 == g.col.gsut, ...
    ['sps_geom: the generator must share the GSUT column. DE-0001 Rev 03 puts ', ...
     '10BAT10, the isolated phase busbars 10BAA40 and 10MKA10 on one vertical ', ...
     'centre line, and that is what makes the 22 kV run a single segment.']);

% The UAT must be to the RIGHT of the unit chain, because its 22 kV lead is
% drawn as the horizontal branch 10BAA50 off the generator busbar. If it ever
% slid back into the GSUT column the branch would vanish and the diagram would
% stop matching the sheet.
assert(g.col.uat > g.col.gsut, ...
    ['sps_geom: the UAT must sit to the RIGHT of the GSUT column so its 22 kV ', ...
     'lead reads as the drawing''s horizontal branch 10BAA50.']);
assert(g.col.gat > g.col.coupler && g.col.coupler > g.col.grid, ...
    'sps_geom: switchyard columns must run grid -> coupler -> GAT, left to right.');

% ---- tiers (top edge of the block that sits on each) -------------------
g.tier.src    =   60;   % EXT GRID source
g.tier.zgrid  =  220;   % grid equivalent series branch
g.tier.bus1   =  280;   % 230 kV BUS 1  - GSUT HV, ZGRID plant side, coupler
g.tier.bus2   =  380;   % 230 kV BUS 2  - coupler far side, GAT bay CB
g.tier.b22    =  400;   % 22 kV GEN BUS - GSUT LV, UAT HV lead, generator lead
g.tier.aux    =  560;   % UAT and GAT block tops
g.tier.bus66  =  680;   % 6.6 kV MV BUS - UAT LV, GAT LV
g.tier.load   =  780;   % the three load blocks
g.tier.g1     =  980;   % GENERATOR top edge - bottom of the left-hand chain

% ---- voltage-level colours --------------------------------------------
% One colour per voltage level, used for busbars, block fills and zone panels,
% so that a reader can tell at a glance which level a symbol belongs to. Dark
% shades for the bars and text, light tints of the same hue for block fills.
% RGB triplets rather than named colours because the named set has no usable
% dark orange, and because 'none' is REJECTED for both BackgroundColor and
% ForegroundColor in R2024a (measured, matlab/env/probe_style.m).
g.clr.v230      = '[0.75 0.10 0.10]';   % 230 kV - dark red
g.clr.v22       = '[0.85 0.45 0.00]';   % 22 kV  - dark orange
g.clr.v6600     = '[0.05 0.30 0.75]';   % 6.6 kV - dark blue
g.clr.fill230   = '[1.00 0.91 0.91]';   % light tints for block fills
g.clr.fill22    = '[1.00 0.95 0.85]';
g.clr.fill6600  = '[0.89 0.94 1.00]';
g.clr.panel230  = '[0.99 0.95 0.95]';   % very light tints for zone panels
g.clr.panel22   = '[1.00 0.98 0.93]';
g.clr.panel6600 = '[0.95 0.97 1.00]';
g.clr.panelgen  = '[0.96 0.96 0.90]';
% Neutral grey marks the four zones that are NOT Ashuganj South plant equipment:
% the external grid (a boundary condition, PGCB's network and not ours), the
% solver corner, the drawing title block and the footer data tables. A reader can
% therefore tell plant from annotation by saturation alone, before reading a word.
g.clr.panelgrid = '[0.95 0.95 0.95]';
g.clr.ink       = '[0.20 0.20 0.20]';   % body text

% ---- busbar bar geometry ----------------------------------------------
% A busbar is drawn as one thin filled annotation, which is the correct
% one-line symbol: three phase wires, one bus symbol. The bar is centred on
% the tier so the wires that form the node run along it.
%
% bar_h was 8 while the page was 1100 x 670. On the DE-0001-matched page, which
% is 1874 x 1274, an 8-unit bar prints as a hairline that disappears against a
% tinted zone panel - the 22 kV and 6.6 kV bars were both invisible in the
% exported PNG. 14 is the thinnest that still reads as a busbar at the whole-page
% scale the presentation will use, and it stays well under the 40-unit threshold
% that env/probe_layout_v3.m uses to tell a bar from a zone panel.
g.bar_h    = 14;
g.bar_pad  = 45;    % how far the bar overhangs the outermost port trio

% Each busbar's horizontal extent is [leftmost column, rightmost column] of
% the devices that sit on it. Written as columns rather than raw pixels so
% that moving a column moves its busbar with it.
g.bar.bus1  = [g.col.gsut,        g.col.coupler];
g.bar.bus2  = [g.col.coupler,     g.col.gat];
g.bar.b22   = [g.col.g1,          g.col.uat];
% The 6.6 kV bar reaches further LEFT than its leftmost feeder - to sheet
% x = 0.170 against the first feeder's 0.187. DE-0001 Rev 03 draws it that way,
% and that overhang is where this diagram puts the bus caption, in clear space to
% the left of the UAT instead of on top of it.
g.bar.bus66 = [min(g.col.load) - 140, g.col.gat];

% barbox(span, tier) -> [left top right bottom] for sps_wire('bar', ...).
g.barbox = @(span, ytier) [span(1) - g.port_dx - g.bar_pad, ytier - g.bar_h/2, ...
                           span(2) + g.port_dx + g.bar_pad, ytier + g.bar_h/2];

% ---- self-consistency -------------------------------------------------
% These are the relationships that make the wires straight. Asserting them
% here means the layout cannot drift silently: change a tier without changing
% the block height it has to match and the build stops instead of producing
% another unreadable diagram.
assert(g.tier.zgrid + g.ser.h == g.tier.bus1, ...
    ['sps_geom: the grid equivalent branch (h = %d) must land its plant-side ', ...
     'terminal exactly on the 230 kV BUS 1 tier.'], g.ser.h);
assert(g.tier.bus1 + g.tx.h == g.tier.b22, ...
    ['sps_geom: the GSUT (h = %d) must span BUS 1 to the 22 kV bus exactly, ', ...
     'because its two winding terminals ARE those two bus nodes.'], g.tx.h);
assert(g.tier.bus1 + g.dev.h == g.tier.bus2, ...
    ['sps_geom: the bus coupler (h = %d) must span BUS 1 to BUS 2 exactly, ', ...
     'because its two terminals ARE those two bus nodes.'], g.dev.h);
assert(g.tier.aux + g.tx.h == g.tier.bus66, ...
    ['sps_geom: the UAT and GAT (h = %d) must land their LV terminals exactly ', ...
     'on the 6.6 kV bus tier.'], g.tx.h);
assert(g.tier.src + g.src.h < g.tier.zgrid, ...
    'sps_geom: the EXT GRID source overlaps the grid equivalent branch.');
assert(g.tier.bus2 + g.dev.h < g.tier.aux, ...
    'sps_geom: the GAT bay CB overlaps the GAT.');
assert(g.tier.bus66 < g.tier.load, ...
    'sps_geom: the loads are above the bus they hang from.');
assert(g.tier.load + g.load.h < g.tier.g1, ...
    'sps_geom: the generator overlaps the 6.6 kV load row.');
assert((g.tx.w - 30)/2 == g.port_dx, ...
    ['sps_geom: the transformer''s port spacing is (w-30)/2 and must equal ', ...
     'port_dx = %d, so tx.w must stay 80. Re-measure with ', ...
     'matlab/env/probe_style.m before changing it.'], g.port_dx);
assert(g.load.w == g.dev.w && g.src.w == g.dev.w && g.ser.w == g.dev.w && ...
       g.tx.w == g.dev.w, ...
    ['sps_geom: every block must share one width (80). Breaker, source, load ', ...
     'and RLC ports are PINNED at +-25 regardless of width, so only 80 makes ', ...
     'them agree with the transformer.']);

% The 22 kV bus and 230 kV BUS 2 sit only 20 units apart vertically, which is
% only readable because they never overlap horizontally: the unit chain is on
% the left of the page and the switchyard's second busbar on the right.
b22  = g.barbox(g.bar.b22,  g.tier.b22);
bus2 = g.barbox(g.bar.bus2, g.tier.bus2);
assert(b22(3) < bus2(1) || bus2(3) < b22(1), ...
    ['sps_geom: the 22 kV busbar (x %g..%g) and the 230 kV BUS 2 busbar ', ...
     '(x %g..%g) overlap horizontally and are only %d units apart vertically. ', ...
     'They would read as one bus. Move a column or separate the tiers.'], ...
    b22(1), b22(3), bus2(1), bus2(3), abs(g.tier.b22 - g.tier.bus2));

% The generator's long 22 kV run descends the left margin from tier.b22 to
% tier.g1, in the port lane col.g1 +- port_dx. On the drawing that run passes
% clear of the 6.6 kV switchgear, and it has to here too: if the 6.6 kV busbar
% ever reached left far enough to touch the lane, a 22 kV conductor would be
% drawn crossing a 6.6 kV bus with no transformer between them.
lane  = g.col.g1 + g.port_dx;
bus66 = g.barbox(g.bar.bus66, g.tier.bus66);
assert(lane < bus66(1), ...
    ['sps_geom: the generator''s 22 kV run occupies x up to %g, but the 6.6 kV ', ...
     'busbar starts at x = %g. The run would cross the 6.6 kV bus. Move the ', ...
     'load columns right or the unit chain left.'], lane, bus66(1));
for c = g.col.load
    assert(c - g.load.w/2 > lane, ...
        ['sps_geom: load column %g would overlap the generator''s 22 kV run ', ...
         '(which reaches x = %g).'], c, lane);
end
end
