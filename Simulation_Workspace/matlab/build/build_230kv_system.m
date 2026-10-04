function Z = build_230kv_system(mdl, D, C)
%BUILD_230KV_SYSTEM  230 kV GIS zone of the Ashuganj South model.
%
%   Z = BUILD_230KV_SYSTEM(MDL, D, C) adds the 230 kV switchyard
%   representation to model MDL for case C. Positions come from SPS_GEOM: the
%   coupler stands in the coupler column and spans the BUS 1 tier down to the
%   BUS 2 tier, because its two terminals ARE those two bus nodes; the GAT bay
%   breaker stands in the GAT column with its top edge on the BUS 2 tier.
%
%   PHYSICAL PLANT
%   --------------
%   Siemens 8DN9 gas-insulated switchgear, double-busbar single-breaker,
%   3150 A bus-coupler/busbar module (bays are 2000 A modules: Generator
%   Transformer 2000 A, Line 2000 A per REV3 §3.6 audit), equipment ratings
%   50 kA / 1 s + 3 s short-time withstand and 125 kA peak withstand. Two busbars,
%   10BAC01 (BUS 1) and 10BAC02 (BUS 2), with bays 10BAY11 (GSUT), 10BAY12
%   (bus coupler) and 10BAY20 (GAT per REV3 C-17). Each bay has a Q0
%   circuit breaker and disconnectors Q1 to BUS 2 and Q2 to BUS 1, plus a Q9
%   earthing switch. Conductor ampacity MISSING, never a module rating.
%
%   WHAT IS MODELLED, AND WHAT IS NOT
%   ---------------------------------
%   Two blocks only:
%
%     BUS COUPLER  - a Three-Phase Breaker tying BUS 1 to BUS 2. Its state is
%                    an ENGINEERING ASSUMPTION: closed. The normal operating
%                    configuration is nowhere in the available document set,
%                    which is exactly why approved answer Q9a requires this to
%                    be labelled an assumption rather than a finding.
%
%     GAT BAY CB   - a Three-Phase Breaker in bay 10BAY20, open or closed
%                    according to the case (approved answer Q4c compares GAT
%                    out against GAT in).
%
%   Bay conductors, disconnectors, earthing switches, CT/VT burdens and the
%   busbars themselves are NOT modelled as impedances. Not one of them has a
%   documented impedance in the source set, and inventing values for a few
%   metres of GIS enclosure would add fabricated data for no numerical
%   benefit. They are represented as ideal connections (treatment S4).
%
%   Every busbar node is a port trio on a real device, not a separate block.
%   BUS 1 lives on the GSUT HV terminal; BUS 2 lives on the coupler's far
%   terminal. This is not a shortcut - SPS has no busbar block, and a physical
%   port accepts any number of lines.
%
%   The closed-breaker series resistance is the SPS default 0.01 ohm. Against
%   the GAT's 253.9 ohm referred to 230 kV that is 0.004 %, well below the
%   1e-4 load-flow tolerance, so it is left at default rather than zeroed.

B = sps_blocks();
g = sps_geom();

% ---- Bus coupler: BUS 1 <-> BUS 2 -------------------------------------
% Oriented 'down' so the L terminal sits on the BUS 1 tier and the R terminal
% exactly one block-height lower on the BUS 2 tier. SPS_GEOM asserts that span.
Z.coupler = sps_wire('add', mdl, B.breaker, 'BUS COUPLER', ...
                     g.box(g.col.coupler, g.tier.bus1, g.dev), 'down');
set_breaker(Z.coupler, C.Coupler_closed);
set_param(Z.coupler, 'BackgroundColor', g.clr.fill230, ...
                     'ForegroundColor', g.clr.v230);

% ---- GAT bay circuit breaker in 10BAY20 -------------------------------
% Same column as the GAT it feeds, so the 230 kV lead down to the station
% transformer is a straight vertical drop.
Z.gatcb = sps_wire('add', mdl, B.breaker, 'GAT BAY CB', ...
                   g.box(g.col.gat, g.tier.bus2, g.dev), 'down');
set_breaker(Z.gatcb, C.GAT_in);
set_param(Z.gatcb, 'BackgroundColor', g.clr.fill230, ...
                   'ForegroundColor', g.clr.v230);

% ---- Wire the coupler's BUS 2 side to the GAT bay ---------------------
sps_wire('link', mdl, sps_wire('port', Z.gatcb, 'L'), sps_wire('port', Z.coupler, 'R'));

% ---- Exported nodes ---------------------------------------------------
Z.node_B230_1  = sps_wire('port', Z.coupler, 'L');   % BUS 1 side
Z.node_B230_2  = sps_wire('port', Z.coupler, 'R');   % BUS 2 side
Z.node_GAT_HV  = sps_wire('port', Z.gatcb,   'R');   % GAT HV lead

% ---- Labels ----------------------------------------------------------
% The heading and the GIS specification sit in the band ABOVE 230 kV BUS 1, to
% the right of the grid equivalent, which no block or busbar occupies. The
% specification used to float in mid-page beside the 22 kV bus, where it read as
% a caption for the wrong zone entirely.
%
% Annotation Position is honoured at its left and top edge only, so these are
% anchors with clear space to their right.
xc = g.col.coupler + 60;
sps_wire('note', mdl, '230 kV GIS   Siemens 8DN9', ...
         [xc, g.tier.src+4, xc+320, g.tier.src+28], 12, 'bold', g.clr.v230);
sps_wire('note', mdl, sprintf(['double busbar, single breaker\n' ...
    '3150 A  50 kA / 1 s  125 kA peak\n' ...
    'bays 10BAY11 / 10BAY12 / 10BAY20\n' ...
    'bay conductors, disconnectors, earthing switches and\n' ...
    'CT/VT burdens are ideal - none has a documented Z']), ...
    [xc, g.tier.src+32, xc+400, g.tier.src+120], 9, 'normal');
sps_wire('note', mdl, sprintf('10BAY12 COUPLER  %s', upper(state_word(C.Coupler_closed))), ...
    [g.col.coupler+58, g.tier.bus1+16, g.col.coupler+258, g.tier.bus1+38], ...
    10, 'bold', g.clr.v230);
sps_wire('note', mdl, 'assumed state - not found in the document set', ...
    [g.col.coupler+58, g.tier.bus1+40, g.col.coupler+438, g.tier.bus1+60], 9, 'normal');
% One note only. This caption was accidentally duplicated: two annotations with
% identical text at an identical Position render as one smeared double-struck
% label, because each is drawn independently over the other.
sps_wire('note', mdl, sprintf('10BAY20 CB  %s', upper(state_word(C.GAT_in))), ...
    [g.col.gat+58, g.tier.bus2+16, g.col.gat+238, g.tier.bus2+38], ...
    10, 'bold', g.clr.v230);
sps_wire('note', mdl, sprintf('case %s', C.ID), ...
    [g.col.gat+58, g.tier.bus2+40, g.col.gat+218, g.tier.bus2+60], 9, 'normal');

Z.report = struct('Coupler_closed', C.Coupler_closed, 'GAT_in', C.GAT_in, ...
                  'Busbar_A', 3150, 'Withstand_kA', 50, ...
                  'BreakerResistance_ohm', 0.01);
end

% =====================================================================
function set_breaker(blk, closed)
%SET_BREAKER  Fix a Three-Phase Breaker permanently open or permanently closed.
%   SwitchTimes is pushed far beyond any simulation horizon rather than left
%   empty: an empty matrix makes the block's mask initialisation fail
%   ("Failed to evaluate mask initialization commands"), verified in
%   matlab/env/probe_ports.m.
if closed, st = 'closed'; else, st = 'open'; end
set_param(blk, ...
    'InitialState',        st, ...
    'SwitchA',             'on', ...
    'SwitchB',             'on', ...
    'SwitchC',             'on', ...
    'SwitchTimes',         '[1e6]', ...
    'External',            'off', ...
    'BreakerResistance',   '0.01', ...
    'SnubberResistance',   '1e6', ...
    'SnubberCapacitance',  'inf');
sps_wire('setopt', blk, 'Measurements', 'None');
end

% =====================================================================
function w = state_word(closed)
if closed, w = 'closed'; else, w = 'open'; end
end
