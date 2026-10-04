function Z = build_generator_system(mdl, D, C)
%BUILD_GENERATOR_SYSTEM  Generator zone of the Ashuganj South model.
%
%   Z = BUILD_GENERATOR_SYSTEM(MDL, D, C) adds generator G1 to model MDL for
%   case C. Its position comes from SPS_GEOM: the G1 column at the G1 tier,
%   oriented 'up' so that its single three-phase terminal is on TOP and the
%   22 kV connection rises from it to the GSUT's LV winding.
%
%   WHERE IT SITS, AND WHY SO FAR DOWN
%   ----------------------------------
%   At the BOTTOM of the left-hand column, well below the 6.6 kV bus. That is
%   where drawing DE-0001 Rev 03 puts 10MKA10 - sheet y = 0.664, against 0.357
%   for the MV busbar - and the tall gap above it is not wasted space. On the
%   sheet it is occupied by the generator circuit breaker 10BAC10, the isolated
%   phase busbars 10BAA40, the neutral earthing resistor 10BAB11 and the
%   generator VT and CT cubicles. None of those carries a documented impedance,
%   so none of them is a block here (treatment S4), but the run of conductor
%   they live on is real and the drawing devotes a third of its height to it.
%   Keeping that proportion is what lets the two diagrams be read side by side.
%
%   G1 is the single Siemens SGen5-2000H of the single-shaft SCC5-PAC
%   4000F/3000 (1S) train: one SGT5-4000F gas turbine plus one SST-3000 steam
%   turbine on a common shaft driving ONE 458 MVA machine. That is why a
%   "450 MW" plant has one generator and not three.
%
%   REPRESENTATION (structural treatment S1)
%   ----------------------------------------
%   An IDEAL Three-Phase Source on PV control, NOT the "Synchronous Machine
%   pu Standard" block. This is a data-integrity decision, not a convenience:
%   the machine block additionally requires x_q, the armature resistance, the
%   inertia constant H and four open-circuit time constants, every one of
%   which is MISSING from the source set. Filling them would mean inventing
%   machine data. A balanced load flow uses none of them - a PV bus is fully
%   specified by |V| and P. The verified x_d = 166.3 %, x_d' = 28.65 % and
%   x_d'' = 22.48 % stay in the registry for the later short-circuit study,
%   where they are both needed and available.
%
%   DISPATCH (approved answer Q2c)
%   ------------------------------
%   P comes from the case: 389.30 MW nameplate-rated or 342.01 MW
%   site-derated. NEITHER is a measured operating point, and neither is
%   described as one.
%
%   REACTIVE LIMITS (approved answer Q3a)
%   -------------------------------------
%   Unconstrained. The only Q limits in the source set belong to the CYME
%   PSAF diesel-generator template (defect D4) and describe a different
%   machine. Solved Q is checked against the 458/518 MVA nameplate circle in
%   post-processing instead.

B = sps_blocks();
g = D.gen(1);
gm = sps_geom();
cx = gm.col.g1;

% Orientation 'up' puts the source's single three-phase terminal on its TOP
% edge, so the 22 kV connection leaves the top of the machine and rises to the
% GSUT. Because G1 and the GSUT share a column, that run is drawn as three
% straight parallel vertical segments with no bends at all - which is exactly
% how the sheet draws the isolated phase busbar run 10BAA40.
Z.src = sps_wire('add', mdl, B.source, g.Name, ...
                 gm.box(cx, gm.tier.g1, gm.src), 'up');
set_param(Z.src, ...
    'BusType',            g.LF_BusType, ...            % PV
    'NonIdealSource',     'off', ...                    % ideal - see S1
    'InternalConnection', 'Yg', ...
    'VoltagePhases',      'off', ...
    'Voltage',            sprintf('%.10g', g.Vset_pu*g.Vnom_V), ...
    'PhaseAngle',         '0', ...
    'BaseVoltage',        sprintf('%.10g', g.Vnom_V), ...
    'Frequency',          sprintf('%.10g', g.f_Hz), ...
    'Pref',               sprintf('%.10g', C.Gen_P_MW*1e6), ...
    'Qref',               '0', ...
    'Qmin',               '-inf', ...
    'Qmax',               'inf');
set_param(Z.src, 'BackgroundColor', gm.clr.fill22, ...
                 'ForegroundColor', gm.clr.v22);
% BaseVoltage must be the 22 kV nameplate, not the 25 kV block default.
% power_loadflow uses it as this bus's nominal voltage, so leaving it at the
% default reports the generator terminal against a 25 kV base and corrupts the
% per-unit network. See the note in build_external_grid.m.

Z.node_B22 = sps_wire('port', Z.src, 'R');

% ---- Labels ----------------------------------------------------------
% Two lines of tag and rating beside the machine, and nothing else. The full
% nameplate - 518 MVA at 30 C, 12019 A, YY winding, H2 at 5 bar, x_d, x_d',
% x_d'' - lives in the parameter table at the foot of the diagram. A one-line
% carries the tag and the rating; a datasheet carries the datasheet.
sps_wire('note', mdl, sprintf('G1  10MKA10'), ...
         [cx+50, gm.tier.g1+20, cx+230, gm.tier.g1+42], 11, 'bold', gm.clr.v22);
sps_wire('note', mdl, sprintf(['SGen5-2000H  458 MVA  22 kV  pf 0.85\n' ...
    'PV bus   |V| = %.2f pu   P = %.2f MW\n%s dispatch (not a measurement)'], ...
    g.Vset_pu, C.Gen_P_MW, upper(C.Gen_scenario)), ...
    [cx+50, gm.tier.g1+46, cx+330, gm.tier.g1+100], 9, 'normal');

Z.report = struct('Name', g.Name, 'P_MW', C.Gen_P_MW, 'Vset_pu', g.Vset_pu, ...
                  'Scenario', C.Gen_scenario, 'Snom_MVA', g.Snom_MVA, ...
                  'Smax_MVA', g.Smax_MVA, 'pf', g.pf);
end
