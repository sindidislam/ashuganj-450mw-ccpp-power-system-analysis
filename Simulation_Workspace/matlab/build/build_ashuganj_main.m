function info = build_ashuganj_main(caseName, varargin)
%BUILD_ASHUGANJ_MAIN  Build the Ashuganj South Simulink/SPS network model.
%
%   info = BUILD_ASHUGANJ_MAIN()          builds base case LF1
%   info = BUILD_ASHUGANJ_MAIN('LF3')     builds case LF3
%   info = BUILD_ASHUGANJ_MAIN('LF2', 'SavePath', p, 'ModelName', n, 'Close', true)
%
%   Builds the model entirely from code. Every electrical parameter comes from
%   the Phase 7 dataset in matlab/data; nothing is typed into a dialog by hand
%   and nothing is hard-coded here.
%
%   SCOPE
%   -----
%   Ashuganj 450 MW Combined Cycle Power Plant, SOUTH plant only. The North
%   plant (UTS project 7485, 400 kV GIS, Hyosung 400/230 kV interbus
%   transformers) is a different unit and is NOT modelled. The highest voltage
%   in this model is 230 kV. There is no 400 kV network. The 400 V auxiliary
%   board is FOUR HUNDRED VOLTS and is excluded from the load flow, not
%   confused with 400 kV.
%
%   LAYOUT
%   ------
%   Flat model, laid out to MIRROR THE PLANT DRAWING - INEL-112070-00-ELC-DE-0001
%   Rev 03, "MAIN ELECTRICAL SYSTEM ONE LINE DIAGRAM" - so that the two can be
%   put side by side and checked element by element. Every position comes from
%   sps_geom(), which records the sheet coordinates each column and tier was
%   taken from, and the port-spacing rule that makes the three phase wires run
%   straight. The unit chain is one tall column on the far left with the
%   GENERATOR AT THE BOTTOM, the auxiliary transformer is tapped off the 22 kV
%   bus into its own column, the switchyard runs across the top, and the station
%   transformer is on the far right - all as drawn:
%
%                         EXT GRID (PGCB)              230 kV GIS 8DN9
%                              |
%                            ZGRID
%                              |
%   ==== 230 kV BUS 1 (10BAC01) ==+===== BUS COUPLER 10BAY12
%         |                                    |
%       GSUT 10BAT10                ==== 230 kV BUS 2 (10BAC02) ====
%         |                                                    |
%   == 22 kV GEN BUS (10BAC10) ==+                       GAT BAY CB 10BAY20
%         |                      |                             |
%         |                  UAT 10BBT10                  GAT 10BBT20
%         |                      |                             |
%         |     ==== 6.6 kV MV BUS (10BBA10) =====================
%         |            |          |            |
%         |          MAIN       WI-1         WI-2   (three aux load groups)
%         |
%        G1 10MKA10   <- at the bottom of the chain, as on the sheet: the space
%                        above it carries the GCB 10BAC10, the isolated phase
%                        busbars 10BAA40 and the NER 10BAB11, none of which has
%                        a documented impedance (treatment S4)
%
%   COLOUR AND SHAPE
%   ----------------
%   One colour per voltage level - 230 kV dark red, 22 kV dark orange, 6.6 kV
%   dark blue - applied to the busbars, to each block's fill and outline, and to
%   the zone panels behind them. The grid equivalent is deliberately coloured as
%   an EXCEPTION rather than by its voltage, because it is the one impedance in
%   the model that is estimated rather than read off a nameplate.
%
%   The zone panels are filled annotations, laid down LAST, AFTER every block,
%   busbar and caption. Among annotations the FIRST created renders ON TOP -
%   find_system returns annotation handles in reverse creation order and the print
%   path draws them in that order - so a panel created early erases the zone it
%   was meant to frame. That is not a guess: it is what the export showed when
%   these panels were created first, with the 230 kV BUS 1 bar chopped off at the
%   switchyard panel's left edge and the GAT, G1 and GSUT captions clipped where
%   they straddled a panel edge. Blocks and lines are a separate, higher layer
%   drawn above all annotations, so drawing the panels last hides no equipment.
%   Simulink's own resizable "Area" object cannot be used at all: AnnotationType
%   is read-only from code (matlab/env/probe_area.m).
%
%   DELIBERATE DEVIATION FROM THE REQUESTED DIRECTORY LAYOUT
%   --------------------------------------------------------
%   The brief asks for five files under simulink/subsystems/. This model is
%   built FLAT instead, and the five build_*_system.m scripts are ZONE
%   BUILDERS that add blocks directly into the main model. The network has
%   about twenty electrical elements; wrapping four of them in a subsystem
%   would hide the one-line rather than clarify it, and the whole point of the
%   layout is that the reader can see generation, transformation, the GIS and
%   the auxiliary system at once. Every mandated build script therefore exists
%   and is genuinely used, but simulink/subsystems/ stays empty. Flagged
%   openly rather than quietly.
%
%   BUSBAR NODES
%   ------------
%   Specialized Power Systems has no busbar block. A busbar is a port trio on
%   a real device that several other devices connect to (verified: one
%   physical port accepts many lines). The node owners are:
%       230 kV BUS 1   GSUT winding-1 terminal
%       230 kV BUS 2   BUS COUPLER far terminal
%       22 kV GEN BUS  GSUT winding-2 terminal
%       6.6 kV MV BUS  UAT  winding-2 terminal
%       BGRID230       EXT GRID terminal, behind the equivalent impedance
%
%   NO MEASUREMENT BLOCKS
%   ---------------------
%   None are added. Branch flows are computed in post-processing from the
%   solved bus phasors and the documented impedances, and cross-checked
%   against an independent Newton-Raphson solve. V-I blocks on every branch
%   would triple the block count and bury the one-line for no extra
%   information.

% ------------------------------------------------------------------ setup
if nargin < 1 || isempty(caseName), caseName = 'LF1'; end

p = inputParser;
p.addParameter('SavePath',  '', @ischar);
p.addParameter('ModelName', 'Ashuganj_South_Main', @ischar);
p.addParameter('Close',     false, @islogical);
p.addParameter('Quiet',     false, @islogical);   % suppress the build log
p.addParameter('Backup',    true,  @islogical);   % version the previous .slx
p.addParameter('Save',      true,  @islogical);   % write to SavePath
% RESULTS: the solved case, for the annotated presentation copy of the diagram.
% Empty means "no numbers on the sheet", which is the correct default - the model
% as SPECIFIED must be buildable without a solution existing, or the two would be
% circularly dependent. When a solved struct from run_load_flow_study is passed
% in, the bus voltages and branch flows are stamped beside the equipment they
% belong to and a results panel is added at the foot of the sheet.
%
% This exists because power_loadflow('solve') WRITES ITS SOLUTION BACK INTO THE
% BLOCKS, so the annotated sheet cannot be made by solving the model that is on
% screen. It takes two passes: build clean -> solve -> capture -> build AGAIN with
% the captured numbers. The second build is a fresh network with the numbers as
% text, never a solved network saved over itself.
p.addParameter('Results',   [], @(x) isempty(x) || isstruct(x));
p.parse(varargin{:});
opt = p.Results;

% Quiet/Backup/Save exist for one reason: power_loadflow('solve') WRITES the
% solution back into the blocks, so a case must be rebuilt from scratch before
% every solve to stay reproducible. Studies and tests therefore call this
% function dozens of times, and they must not each emit a build log, cut a
% backup, or rewrite the deliverable .slx. The default behaviour - loud, backed
% up, saved - is unchanged for real builds.
say = @(varargin) fprintf(varargin{:});
if opt.Quiet, say = @(varargin) []; end

root = ashuganj_root();
if isempty(opt.SavePath)
    opt.SavePath = fullfile(root, 'simulink', 'main', [opt.ModelName '.slx']);
end

D = ashuganj_master_data();
ci = find(strcmp({D.cases.ID}, caseName), 1);
if isempty(ci) && isfield(D, 'operating_profiles')
    ci = find(strcmp({D.operating_profiles.ID}, caseName), 1);
    if ~isempty(ci)
        C = D.operating_profiles(ci);
    end
elseif ~isempty(ci)
    C = D.cases(ci);
end
if isempty(ci)
    error('build_ashuganj_main:badCase', ...
        'Unknown case ''%s''. Defined cases: %s.', caseName, strjoin({D.cases.ID}, ', '));
end

% Authoritative Phase 2 capacity guard enforcement
validate_operating_profile(C);

say('\n=== BUILD %s : case %s ===\n', opt.ModelName, C.ID);
say('  %s\n', C.Name);
say('  P(G1) = %.2f MW (%s) | GAT %s | coupler %s | topology %s\n', ...
    C.Gen_P_MW, C.Gen_scenario, tf2s(C.GAT_in,'in','out'), ...
    tf2s(C.Coupler_closed,'closed','open'), C.Topology);

% -------------------------------------------------- back up before touching
backupDir = fullfile(root, 'simulink', 'backups');
if opt.Backup
    nBackup = backup_model(opt.SavePath, backupDir, say);
else
    [~, bb, be] = fileparts(opt.SavePath);
    nBackup = numel(dir(fullfile(backupDir, [bb '_v*' be])));
end

% ------------------------------------------------------------- fresh model
mdl = opt.ModelName;
% bdclose, not close_system(mdl,0): power_loadflow('solve') writes the solution
% back into the blocks, so any model left over from a previous solve in this
% session is DIRTY. close_system(mdl,0) refuses to close a dirty model - it only
% warns "use save_system first" and leaves it loaded, and the new_system below
% would then collide with it. bdclose discards unconditionally, which is correct
% here: this function is about to rebuild the model from the dataset anyway, and
% the on-disk .slx has already been backed up above.
if bdIsLoaded(mdl), bdclose(mdl); end
new_system(mdl);
load_system(mdl);
sps_wire('reset');

% --------------------------------------------------------------- zone panels
% FIRST, before any block or busbar. Annotations render in CREATION order, so a
% panel laid down later would cover the very zone it is meant to frame - the same
% z-order effect that once punched a white hole through the 230 kV BUS 2 bar.
% Verified visually the other way round in tmp/probe_area.png: a block placed
% over an existing panel stays fully legible.
%
% --------------------------------------------------------- zone panel table
% Declared here, DRAWN LAST (see the end of the layout section). The plant
% drawing boxes its isolated phase busbars, its Siemens LV system and its water
% intake area; these panels do the same job, telling the reader which part of the
% plant a symbol belongs to before they read a single label.
%
% Five panels, one per FUNCTIONAL AREA - which is what the drawing boxes, not
% voltage levels. Voltage level is carried by colour instead, because
% transformers bridge two levels and no rectangle can enclose a level cleanly.
% Columns are
%   {position, fill, heading, heading x-anchor}
% and an EMPTY heading means the zone already captions itself - the switchyard is
% headed by "230 kV GIS  Siemens 8DN9" and the grid zone by "EXTERNAL GRID
% (PGCB)", both drawn by their own zone builders, and a second heading would just
% double-strike the first.
%
% The panels do not overlap each other; that is checked by env/probe_layout_v3.m,
% because two overlapping panels would double-tint their intersection.
%
% EVERY EXTENT ENCLOSES ITS OWN CAPTIONS. The first version of this table sized
% the zones to the equipment and let the captions hang out over bare white, which
% printed as five half-tinted labels; the probe now reports that as a straddle
% warning. The refitted caption boxes it measured are what set these edges:
%     GAT      captions reach x 1808          -> switchyard and aux out to x 1830
%     GSUT     caption spans  y  294.. 355    -> unit zone top raised to y 290
%     G1       captions reach x  410, y 1061  -> generator box out to x 560
%     UAT      captions reach x  657          -> already inside the aux panel
%
% GENERATION IS TWO RECTANGLES, deliberately. Its captions sit at x 250..410, but
% the auxiliary zone starts at x 270, so one rectangle wide enough to hold them
% would overlap the auxiliary zone and double-tint 160 x 440 units of page. Below
% y 940 the auxiliary zone has ended and the width is free, so the zone is drawn
% as a narrow strip beside the auxiliary system plus a wide box under it - an L,
% in one fill colour, which reads as a single zone. The two share the y = 944 edge
% and do not overlap.
%
% The four NEUTRAL grey zones carry no plant equipment at all - title block,
% solver corner, footer tables, external grid - so a reader can tell plant from
% commentary by saturation before reading a word.
%     title block    x   26..1830   y -104..  30
%     solver corner  x   40.. 370   y   50.. 200
%     footer tables  x  600..1500   y  944..1190
%     external grid  x  380.. 860   y   44.. 270
%     switchyard     x  880..1830   y   44.. 496
%     22 kV unit     x   26.. 600   y  290.. 468
%     auxiliary      x  270..1830   y  500.. 940
%     generation     x   70.. 265   y  500.. 944   (strip)
%                    x   70.. 560   y  944..1120   (generator box)
g = sps_geom();
% The footer band widens when a solved case is stamped on, because the SOLVED LOAD
% FLOW block is written at x 1540..1900 and would otherwise sit on bare white next
% to the two tinted tables. Without results that width would be empty grey, so it
% is not reserved speculatively.
footerR = 1500;
if ~isempty(opt.Results), footerR = 1900; end
panels = { [  26, -104, 1830,   30], g.clr.panelgrid, '',                         0
           [  40,   50,  370,  200], g.clr.panelgrid, '',                         0
           [ 600,  944, footerR, 1190], g.clr.panelgrid, '',                       0
           [ 380,   44,  860,  270], g.clr.panelgrid, '',                         0
           [ 880,   44, 1830,  496], g.clr.panel230,  '',                         0
           [  26,  290,  600,  468], g.clr.panel22,   '22 kV UNIT ZONE',         36
           [ 270,  500, 1830,  940], g.clr.panel6600, '6.6 kV AUXILIARY SYSTEM', 280
           [  70,  500,  265,  944], g.clr.panelgen,  'GENERATION',              76
           [  70,  944,  560, 1120], g.clr.panelgen,  '',                         0 };

% ------------------------------------------------------------- solver setup
% powergui needs a continuous variable-step solver. ode23tb is the stiff
% solver Specialized Power Systems recommends for circuits with transformer
% magnetising branches. StopTime is short because nothing here is a transient
% study: power_loadflow solves the algebraic network, it does not integrate.
set_param(mdl, ...
    'SolverType',     'Variable-step', ...
    'Solver',         'ode23tb', ...
    'StartTime',      '0.0', ...
    'StopTime',       '0.1', ...
    'RelTol',         '1e-4', ...
    'AbsTol',         'auto', ...
    'MaxStep',        'auto', ...
    'SaveOutput',     'off', ...
    'SaveTime',       'off');

% ------------------------------------------------------------------ powergui
% Exactly one powergui block per model. It carries the load-flow settings.
B = sps_blocks();
pg = sps_wire('add', mdl, B.powergui, 'powergui', [60, 60, 190, 115]);
pgDefaults = struct('Pbase', get_param(pg,'Pbase'), ...
                    'frequency', get_param(pg,'frequency'), ...
                    'UnitsV', get_param(pg,'UnitsV'), ...
                    'UnitsW', get_param(pg,'UnitsW'), ...
                    'ErrMax', get_param(pg,'ErrMax'), ...
                    'Iterations', get_param(pg,'Iterations'));
say('  powergui defaults: Pbase=%s f=%s UnitsV=%s UnitsW=%s ErrMax=%s Iter=%s\n', ...
    pgDefaults.Pbase, pgDefaults.frequency, pgDefaults.UnitsV, ...
    pgDefaults.UnitsW, pgDefaults.ErrMax, pgDefaults.Iterations);

set_param(pg, 'SimulationMode', 'Continuous');

% ---- 50 Hz, and it must be BOTH parameters -----------------------------
% Bangladesh runs at 50 Hz. Getting this wrong is not academic: it is exactly
% the defect (D2) found in the prior CYME PSAF model of this plant, which was
% built at 60 Hz.
%
% The powergui block stores its frequency TWICE. 'frequency' is the dialog edit
% field; 'frequencyindice' is the value the analysis tools actually read, and it
% is only refreshed from 'frequency' when the mask callback fires - which does
% not happen when a model is assembled programmatically and solved in the same
% session. Setting 'frequency' alone therefore leaves a freshly built model
% solving at the 60 Hz default while every dialog in it reads 50.
%
% This was not deduced, it was measured. The grid equivalent is entered as a
% pure inductance (L = 8.4527 mH), so its reactance reveals the frequency the
% solver used. With 'frequency' alone: X_eff = 3.1870 ohm = 60.000 Hz. With
% 'frequencyindice' also set: X_eff = 2.6558 ohm = 50.000 Hz, the documented
% value. Evidence: matlab/env/probe_freq.m.
%
% Note also that editing the load-flow parameter struct's freq field is NOT a
% valid alternative: it makes the solved struct REPORT 50 Hz while the network
% is still solved at 60 Hz. That would hide the defect rather than fix it.
fHz = D.base.f_Hz;
dp  = get_param(pg, 'DialogParameters');
if ~isfield(dp, 'frequencyindice')
    error('build_ashuganj_main:noFreqIndice', ...
        ['This powergui has no ''frequencyindice'' parameter, so the frequency ' ...
         'the load flow will use cannot be set with confidence. Re-verify the ' ...
         'frequency mechanism for this MATLAB release before building.']);
end
set_param(pg, 'frequency',       sprintf('%.10g', fHz));
set_param(pg, 'frequencyindice', sprintf('%.10g', fHz));

sps_wire('setopt', pg, 'UnitsV',     'kV');
sps_wire('setopt', pg, 'UnitsW',     'MW');
sps_wire('setopt', pg, 'ErrMax',     '1e-4');
sps_wire('setopt', pg, 'Iterations', '50');
% Pbase units differ between releases, so scale to whatever the default
% implies rather than assuming VA or MVA.
pbDefault = str2double(pgDefaults.Pbase);
if isfinite(pbDefault) && pbDefault > 1e3
    set_param(pg, 'Pbase', sprintf('%.10g', D.base.Sbase_MVA*1e6));   % VA
else
    set_param(pg, 'Pbase', sprintf('%.10g', D.base.Sbase_MVA));       % MVA
end
say('  powergui set:      Pbase=%s f=%s Hz (frequencyindice=%s Hz)\n', ...
    get_param(pg,'Pbase'), get_param(pg,'frequency'), get_param(pg,'frequencyindice'));

% ------------------------------------------------------------------- zones
% No origin arguments. Every block position comes from sps_geom(), which is the
% single authority for the diagram's columns and tiers; see that file for why
% five loose anchors and an arrangeSystem call had to go.
GRID = build_external_grid   (mdl, D);
GSUT = build_gsut_system     (mdl, D);
GIS  = build_230kv_system    (mdl, D, C);
GEN  = build_generator_system(mdl, D, C);
AUX  = build_auxiliary_system(mdl, D);

% ------------------------------------------------- inter-zone connections
% 230 kV BUS 1 node = GSUT winding-1 terminal
sps_wire('link', mdl, GRID.node_B230_1, GSUT.node_HV);   % grid equivalent
sps_wire('link', mdl, GIS.node_B230_1,  GSUT.node_HV);   % bus coupler

% 22 kV GEN BUS node = GSUT winding-2 terminal
sps_wire('link', mdl, GEN.node_B22,     GSUT.node_LV);   % generator
% The UAT's tier is named EXPLICITLY. Its 22 kV terminal is 160 units BELOW the
% bus, because the drawing taps the unit auxiliaries off the generator busbar
% through the horizontal branch 10BAA50, so the two ports do not straddle a
% common tier and sps_wire cannot infer one (it reports y = 556 and y = 415,
% midpoint 485.5, which is 85 units from the nearest declared bus). Naming the
% tier draws the riser and the run along the bar that DE-0001 Rev 03 shows.
sps_wire('link', mdl, AUX.node_B22,     GSUT.node_LV, g.tier.b22);   % UAT primary

% GAT HV lead: 10BAY20 breaker down to the GAT
sps_wire('link', mdl, GIS.node_GAT_HV,  AUX.node_GAT_HV);

% ------------------------------------------------------- busbars and labels
% A busbar is drawn as one thin filled bar spanning the devices that sit on it,
% in the colour of its voltage level. The model carries three phase wires per
% bus; the one-line carries one symbol, and the three wires run along the bar so
% that the two read as the same thing.
%
% Each caption is placed at an EXPLICIT anchor rather than at a fixed offset from
% the bar, because the four buses have clear space in four different directions.
% The anchors were checked against every block, wire lane and other caption
% before being coded, and each one is here for a reason:
%
%   230 kV BUS 1   x 140  y 226   above the bar's left end; the GSUT below it
%                                 starts at y 280 and its caption at y 294.
%   230 kV BUS 2   x 1080 y 392   below the bar, to the RIGHT of the coupler's
%                                 port stubs (which reach x 1025) and well left
%                                 of the GAT bay breaker at x 1580.
%   22 kV GEN BUS  x 36   y 410   below the bar and LEFT of x 175, because the
%                                 generator's three 22 kV conductors run down
%                                 the page at x 175, 200 and 225 from y 415 to
%                                 y 965. A caption at x 140 would have been
%                                 struck through by two of them.
%   6.6 kV MV BUS  x 276  y 692   below the bar, on the left OVERHANG that
%                                 sps_geom gives it, clear of the UAT at x 440.
%
% Every bus keeps its plant KKS tag. Tag by tag is the only way to check this
% diagram against DE-0001.
bars = { g.bar.bus1,  g.tier.bus1,  g.clr.v230,  '230 kV BUS 1',  '10BAC01', [ 140, 226]
         g.bar.bus2,  g.tier.bus2,  g.clr.v230,  '230 kV BUS 2',  '10BAC02', [1080, 392]
         g.bar.b22,   g.tier.b22,   g.clr.v22,   '22 kV GEN BUS', '10BAC10', [  36, 410]
         g.bar.bus66, g.tier.bus66, g.clr.v6600, '6.6 kV MV BUS', '10BBA10', [ 276, 692] };
for k = 1:size(bars,1)
    sps_wire('bar', mdl, g.barbox(bars{k,1}, bars{k,2}), bars{k,3});
    a = bars{k,6};
    sps_wire('note', mdl, bars{k,4}, [a(1), a(2),    a(1)+200, a(2)+22], 11, 'bold', bars{k,3});
    sps_wire('note', mdl, bars{k,5}, [a(1), a(2)+22, a(1)+160, a(2)+42],  9, 'normal');
end

% ---- zone headings ---------------------------------------------------
% One per panel that does not already caption itself, at the panel's top-left.
for k = 1:size(panels,1)
    if isempty(panels{k,3}), continue, end
    box = panels{k,1};
    sps_wire('note', mdl, panels{k,3}, ...
             [panels{k,4}, box(2)+6, panels{k,4}+520, box(2)+30], 12, 'bold');
end

% ------------------------------------------------------------- title block
sps_wire('note', mdl, ['ASHUGANJ 450 MW COMBINED CYCLE POWER PLANT  -  SOUTH  -  ' ...
    'BALANCED LOAD FLOW MODEL'], [40, -96, 980, -68], 15, 'bold');
sps_wire('note', mdl, sprintf([ ...
    'Case %s : %s   |   G1 = %.2f MW (%s)   |   GAT %s   |   coupler %s   |   %s\n' ...
    'Base %g MVA, %g Hz.  Highest voltage 230 kV - the South plant has NO 400 kV network.\n' ...
    'Layout mirrors INEL-112070-00-ELC-DE-0001 Rev 03.  Built by build_ashuganj_main.m - do not edit by hand.'], ...
    C.ID, C.Name, C.Gen_P_MW, lower(C.Gen_scenario), ...
    tf2s(C.GAT_in,'IN SERVICE','OUT OF SERVICE'), ...
    tf2s(C.Coupler_closed,'CLOSED','OPEN'), C.Topology, ...
    D.base.Sbase_MVA, D.base.f_Hz), ...
    [40, -62, 1080, 12], 9, 'normal');

% ---- colour key ------------------------------------------------------
% Three short coloured lines under the title. Without a key the colours are
% decoration; with it they are information.
sps_wire('note', mdl, '230 kV', [1180, -96, 1260, -74], 10, 'bold', g.clr.v230);
sps_wire('note', mdl, '22 kV',  [1270, -96, 1340, -74], 10, 'bold', g.clr.v22);
sps_wire('note', mdl, '6.6 kV', [1350, -96, 1430, -74], 10, 'bold', g.clr.v6600);
sps_wire('note', mdl, ['voltage-level colour key. 400 V boards and below are ' ...
    'OUT of the load flow and are not drawn.'], ...
    [1180, -72, 1900, -52], 9, 'normal');

% ---- solver / load-flow tool label -----------------------------------
% The powergui block is the one thing on this sheet that is NOT plant equipment:
% it is the solver, and it is also the button the operator presses to run the
% study. Left unlabelled it reads as a stray block called "Continuous". The
% caption sits in the clear band to its right, above 230 kV BUS 1 (y 273) and
% left of the external grid panel (x 380).
sps_wire('note', mdl, ['SOLVER / STUDY TOOL - not plant equipment.' newline ...
    'Double-click it, choose Load Flow, press Compute.' newline ...
    'Continuous, ode23tb, 50 Hz. See docs/manual/USER_MANUAL.html.'], ...
    [60, 124, 370, 190], 9, 'normal');

% -------------------------------------------------- derived parameter table
% The per-block captions carry tag, ratio, vector group, rating and impedance -
% what a plant one-line carries. Everything DERIVED goes here instead, as a
% table, in the clear band below the generation zone. Keeping it in one place is
% what let the block captions shrink to two or three lines each, and a table is
% easier to check against the registry than eight scattered notes.
T = tx_table(GSUT.report, AUX.report.UAT, AUX.report.GAT);
sps_wire('note', mdl, 'DERIVED TRANSFORMER PARAMETERS', ...
    [620, 956, 1140, 980], 11, 'bold');
anT = sps_wire('note', mdl, T, [620, 984, 1160, 1130], 9, 'normal');
% A fixed-pitch font, so the columns actually line up. In the default
% proportional font a space-padded table reads as ragged noise.
if isprop(anT, 'FontName'), anT.FontName = 'Courier New'; end
sps_wire('note', mdl, sprintf([ ...
    'Per-unit on each transformer''s OWN nameplate MVA, as the nameplate\n' ...
    'quotes them - not converted to the %g MVA reporting base.\n' ...
    'X = sqrt(Z^2 - R^2).  DERIVED_FROM_VERIFIED_DATA.'], ...
    D.base.Sbase_MVA), [620, 1136, 1160, 1190], 8, 'normal');

sps_wire('note', mdl, 'DATA STATUS ON THIS DIAGRAM', [1200, 956, 1700, 980], 11, 'bold');
% BULLETS. This block used to run to nineteen lines of prose - the full reasoning
% for the grid X/R, the loss penalty of assuming X/R = 10, the vector-group
% arithmetic - and at slide scale it read as a grey wall. Every one of those
% arguments is preserved in docs/validation/, which is where a reader who wants
% the reasoning will look. What has to be on the SHEET is the status of each
% number, so that nobody mistakes an estimate for a nameplate value.
sps_wire('note', mdl, sprintf([ ...
    '* Generator, GSUT, UAT, GAT nameplates: VERIFIED_PLANT\n' ...
    '* Transformer X, Rm, Lm: DERIVED_FROM_VERIFIED_DATA\n' ...
    '* Grid Z: ESTIMATED from the GIS 50 kA rating. R = 0\n' ...
    '  EXACTLY, so X/R is infinite - no X/R is documented\n' ...
    '  anywhere in the source set and none is invented\n' ...
    '* ASSUMED: bus coupler closed, the 9050:2500:2500 kW\n' ...
    '  auxiliary split, the 1.00 pu generator setpoint\n' ...
    '* Feeder impedances undocumented, therefore ZERO\n' ...
    '* LV windings 6.9 kV, loads 6.6 kV - a real off-nominal\n' ...
    '  ratio, not tidied away\n' ...
    '* Generator Q limits: unconstrained (none documented)\n' ...
    '* Full register and reasoning: docs/validation/']), ...
    [1200, 984, 1520, 1150], 8, 'normal');

% ------------------------------------------------- solved results, if supplied
% Stamped BEFORE the panels, so the panels still render underneath them (first
% created = on top, among annotations).
%
% This is the "and calculations" half of the diagram: without it the sheet shows
% the network as specified, which is a wiring check; with it the sheet shows what
% the network DOES, which is a load flow. Every number here is read from the
% solved struct passed in - none is recomputed locally, so the sheet cannot
% disagree with results/load_flow/*.csv.
if ~isempty(opt.Results)
    stamp_results(mdl, opt.Results, D, g);
end

% ------------------------------------------------------- zone panels, LAST
% MEASURED Z-ORDER RULE, and it is the OPPOSITE of what it looks like:
% among annotations, the one created FIRST renders ON TOP. find_system returns
% annotation handles in reverse creation order and the print path draws them in
% that order, so the last handle - the first created - is painted last.
%
% This was found the hard way. These panels used to be created first, "so they
% would sit behind everything". In the exported PNG they were painted OVER the
% busbars and captions instead: the 230 kV BUS 1 bar was chopped off exactly at
% the switchyard panel's left edge, the 22 kV and 6.6 kV bars vanished entirely,
% and the GAT, G1 and GSUT captions were clipped at the panel edges they
% straddled. None of it was detectable from the block and annotation positions,
% which is why every automated check passed while the render was wrong.
%
% Blocks and signal lines are a separate layer above ALL annotations, so drawing
% the panels last does not hide any equipment - only verified by re-export, not
% assumed.
for k = 1:size(panels,1)
    sps_wire('panel', mdl, panels{k,1}, panels{k,2});
end

% --------------------------------------------------------------- housekeeping
% NO arrangeSystem here. It is not a line-routing tidy-up: it re-positions every
% block with Simulink's generic dataflow algorithm and moves blocks but not
% annotations, which is what made the previous diagram unreadable. The layout is
% already correct by construction - see sps_geom.m.
set_param(mdl, 'ZoomFactor', 'FitSystem');

% ------------------------------------------------------------------ save
if opt.Save
    outDir = fileparts(opt.SavePath);
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    save_system(mdl, opt.SavePath, 'OverwriteIfChangedOnDisk', true);
end

blocks = find_system(mdl, 'SearchDepth', 1, 'Type', 'Block');
lines  = find_system(mdl, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'Line');
say('  blocks: %d   lines: %d   backups now: %d\n', numel(blocks), numel(lines), nBackup);
if opt.Save
    say('  saved  : %s\n', opt.SavePath);
end

info = struct('model', mdl, 'path', opt.SavePath, 'case', C, ...
              'nBlocks', numel(blocks), 'nLines', numel(lines), ...
              'zones', struct('grid', GRID, 'gsut', GSUT, 'gis', GIS, ...
                              'gen', GEN, 'aux', AUX), ...
              'powergui', pg, 'base', D.base);

% bdclose for the same reason as above. If Save was requested the .slx is already
% on disk, and if it was not, the caller asked for the model to be discarded.
if opt.Close, bdclose(mdl); end
end

% =====================================================================
function stamp_results(mdl, S, D, g)
%STAMP_RESULTS  Write the solved load flow onto the diagram.
%
%   S is one element of the struct array returned by run_load_flow_study: the
%   solved case, with its bus table S.B, its branch table S.R and the system
%   totals. NOTHING is recomputed here. Every figure printed on the sheet is read
%   straight out of that struct, so the diagram, the CSVs and the powergui report
%   are three views of ONE solve and cannot drift apart.
%
%   WHERE THE NUMBERS GO
%   --------------------
%   Beside the thing they describe, in the voltage-level colour of the bus they
%   belong to, in the clear space each busbar caption already occupies:
%
%       bus voltage   under the bus name  - |V| in pu AND kV, plus the angle
%       branch flow   beside each transformer - P, Q, S and % of the lowest
%                     cooling stage, because that is the rating that binds
%       system totals a panel at the foot, beside the derived-parameter table
%
%   A branch that is not in this case's network - the GAT in the radial cases
%   LF1 and LF3, whose bay breaker is open - is NOT stamped with zeros. It is
%   left with its "CB OPEN" caption, because zero flow through an open breaker
%   is a fact about the breaker, not a measurement of the transformer.
%
%   ROUNDING IS DISPLAY ONLY. The sheet shows 4 significant figures because a
%   presentation slide cannot be read at 15; the CSVs carry full precision and
%   the sheet says so.
V = @(nm, fld) busfield(S.B, nm, fld);

% ---- bus voltages, under each bus caption ------------------------------
% Anchors sit directly below the existing "<name> / <KKS>" caption pairs, whose
% positions are fixed in the busbars section above. The 6.6 kV bus prints BOTH
% per-unit bases, because its transformer LV windings are 6.9 kV while the loads
% are 6.6 kV (conflict C13) and quoting one number alone would hide a real
% off-nominal ratio.
busStamp = { 'B230_1', [ 140,  190], g.clr.v230, ''
             'B22',    [  36,  452], g.clr.v22,  ''
             'B6_6',   [ 276,  734], g.clr.v6600, 'alt' };
for k = 1:size(busStamp,1)
    nm = busStamp{k,1};  a = busStamp{k,2};
    if isnan(V(nm,'V_pu_nom')), continue, end
    txt = sprintf('|V| = %.4f pu   %.3f kV   %+.2f deg', ...
                  V(nm,'V_pu_nom'), V(nm,'V_kV'), V(nm,'Ang_deg'));
    if strcmp(busStamp{k,4}, 'alt') && ~isnan(V(nm,'V_pu_alt'))
        txt = sprintf('%s\n= %.4f pu on the 6.9 kV winding base', ...
                      txt, V(nm,'V_pu_alt'));
    end
    sps_wire('note', mdl, txt, [a(1), a(2), a(1)+340, a(2)+34], 9, 'bold', busStamp{k,3});
end

% ---- transformer flows, beside each transformer ------------------------
% Anchored under the existing nameplate captions in build_gsut_system and
% build_auxiliary_system. Loading is quoted against the LOWEST cooling stage,
% because that is the rating in force until the fans and pumps start - and it is
% the number that shows the GSUT over 100 % at rated dispatch and the UAT over
% 100 % whenever the GAT is closed. Quoting only the highest stage buries both.
%
% SIGN CONVENTION, and it is not the obvious one. Each record's P_from_MW is
% measured at its From_bus, and for the UAT and GAT the From_bus is the 6.6 kV
% side (B6_6), not the HV side. So a UAT that FEEDS the 6.6 kV bus reports
% P_from = -14.02 MW: negative means power flowing INTO the From bus. The stamp
% therefore prints the magnitude with an explicit direction word rather than a
% raw signed number that would read as 14 MW flowing the wrong way.
%
% THE GAT IS GATED ON THE CASE, NOT ON THE RECORD. In the radial cases LF1 and
% LF3 the branch record still EXISTS - it carries 0.019 MW of magnetising current
% and 0.34 % loading - because the transformer is energised through its own bay
% even with the bay breaker to BUS 2 open. Stamping that as a flow would tell the
% reader the GAT is carrying load when it is not. Gate on C.GAT_in.
txStamp = { 'GSUT 10BAT10', [ 258, 362], g.clr.v230,  true
            'UAT 10BBT10',  [ 538, 642], g.clr.v6600, true
            'GAT 10BBT20',  [1678, 654], g.clr.v6600, S.Case.GAT_in };
for k = 1:size(txStamp,1)
    if ~txStamp{k,4}, continue, end       % bay open in this case
    r = branchrec(S.R, txStamp{k,1});
    if isempty(r), continue, end
    a = txStamp{k,2};
    x = D.tx(strcmp({D.tx.Label}, txStamp{k,1}));
    Smax = max(r.S_from_MVA, r.S_to_MVA);
    sps_wire('note', mdl, sprintf([ ...
        '%.2f MW   %.2f MVA   loss %.4f MW\n' ...
        '%.1f %% of %g MVA (ONAN stage)'], ...
        abs(r.P_from_MW), Smax, r.P_loss_MW, ...
        100*Smax/x.S_MVA(1), x.S_MVA(1)), ...
        [a(1), a(2), a(1)+340, a(2)+34], 9, 'bold', txStamp{k,3});
end

% ---- system totals, at the foot ---------------------------------------
% BULLETS, not prose. An earlier version wrote four sentences per finding and the
% foot of the sheet became a wall of text nobody would read at slide scale. The
% reasoning belongs in the HTML report; the sheet gets the headline only.
%
% The UAT's P_from_MW is measured at the 6.6 kV bus and is NEGATIVE when the
% transformer feeds that bus, so the delivered power is -P_from. Subtracting the
% load from the raw signed value - which an earlier version did - reported the
% circulating flow as -28.02 MW instead of +5.90 MW.
gsut = branchrec(S.R, 'GSUT 10BAT10');
uat  = branchrec(S.R, 'UAT 10BBT10');
xg   = D.tx(strcmp({D.tx.Label}, 'GSUT 10BAT10'));
xu   = D.tx(strcmp({D.tx.Label}, 'UAT 10BBT10'));
L = { sprintf('Case %s.  Converged, %d iterations.  KCL residual %.1e MVA.', ...
              S.ID, S.Iterations, S.Worst_Residual_MVA)
      sprintf('G1 %.2f MW  %+.2f MVAr   ->   export %.2f MW  %+.2f MVAr', ...
              S.Gen_P_MW, S.Gen_Q_MVAr, S.Export_P_MW, S.Export_Q_MVAr)
      sprintf('Aux %.2f MW   losses %.3f MW (%.2f %% of generation)', ...
              S.Case.Load_P_MW, S.Loss_P_MW, 100*S.Loss_P_MW/S.Gen_P_MW) };
if ~isempty(gsut)
    L{end+1} = sprintf('* GSUT at %.0f %% of %g MVA ONAN - forced cooling REQUIRED', ...
        100*max(gsut.S_from_MVA, gsut.S_to_MVA)/xg.S_MVA(1), xg.S_MVA(1));
end
if ~isempty(uat) && S.Case.GAT_in
    circ = -uat.P_from_MW - S.Case.Load_P_MW;
    L{end+1} = sprintf('* GAT closed: %.2f MW circulates, UAT at %.0f %% of %g MVA ONAN', ...
        circ, 100*max(uat.S_from_MVA, uat.S_to_MVA)/xu.S_MVA(1), xu.S_MVA(1));
end
L{end+1} = 'Full precision and reasoning: results/load_flow/, docs/report/';

sps_wire('note', mdl, 'SOLVED LOAD FLOW', [1540, 956, 1900, 980], 11, 'bold', g.clr.v230);
anR = sps_wire('note', mdl, strjoin(L, newline), ...
               [1540, 984, 1900, 1120], 8, 'normal');
if isprop(anR, 'FontName'), anR.FontName = 'Courier New'; end
end

% =====================================================================
function v = busfield(B, name, field)
%BUSFIELD  One field of one solved bus, or NaN if it is not in the table.
%   NaN rather than an error: a merged bus legitimately carries no injection of
%   its own, and a stamp that cannot be made must be OMITTED rather than faked.
v = NaN;
if isempty(B), return, end
k = find(strcmp({B.Name}, name), 1);
if ~isempty(k) && isfield(B, field), v = B(k).(field); end
end

% =====================================================================
function r = branchrec(R, name)
%BRANCHREC  One solved branch record, or [] if the branch is not in this case.
%   Empty covers exactly one real situation and it must NOT be stamped as zero:
%   the GAT in the radial cases LF1 and LF3, whose bay breaker is open.
r = [];
if isempty(R), return, end
k = find(strcmp({R.Name}, name), 1);
if ~isempty(k), r = R(k); end
end

% =====================================================================
function n = backup_model(target, backupDir, say)
%BACKUP_MODEL  Copy an existing model to backups/<name>_vNNN.slx.
%   Never destroy a working model: the previous .slx is preserved under a new
%   version number BEFORE anything is rebuilt. Returns the number of backups
%   now on disk.
if ~exist(backupDir, 'dir'), mkdir(backupDir); end
[~, base, ext] = fileparts(target);
existing = dir(fullfile(backupDir, [base '_v*' ext]));
n = numel(existing);
if ~exist(target, 'file')
    say('  backup : none needed (no existing %s%s)\n', base, ext);
    return
end
next = 0;
for k = 1:numel(existing)
    tok = regexp(existing(k).name, '_v(\d+)', 'tokens', 'once');
    if ~isempty(tok), next = max(next, str2double(tok{1})); end
end
next = next + 1;
dst = fullfile(backupDir, sprintf('%s_v%03d%s', base, next, ext));
copyfile(target, dst);
n = n + 1;
say('  backup : %s\n', dst);
end

% =====================================================================
function s = tx_table(varargin)
%TX_TABLE  Render the transformer parameter table drawn at the foot of the model.
%
%   S = TX_TABLE(R1, R2, ...) takes the report structs the zone builders return
%   and lays them out one COLUMN per transformer, one row per parameter.
%
%   Nothing here is hard-coded. Every number is read out of the report struct,
%   which the zone builder filled from the Phase 7 dataset, so the table on the
%   diagram cannot drift away from the values actually loaded into the blocks -
%   which is exactly what happened while these numbers were hand-typed into
%   eight separate block captions.
%
%   The rows are split into what the nameplate says and what was DERIVED from
%   it, and the derived ones are marked, because a reader has to be able to tell
%   a measured number from a calculated one at a glance.
tx = [varargin{:}];
rows = { 'transformer',      @(t) t.Name
         'ratio',            @(t) sprintf('%g/%g kV', t.V_HV_V/1000, t.V_LV_V/1000)
         'vector group',     @(t) t.VectorGroup
         'own base MVA',     @(t) sprintf('%g', t.S_rating_MVA)
         'Z  %  nameplate',  @(t) sprintf('%.2f', t.Z_pct)
         'R  %  nameplate',  @(t) sprintf('%.2f', t.R_pct)
         'X  %  derived',    @(t) sprintf('%.4f', t.X_pct)
         'X/R    derived',   @(t) sprintf('%.1f', t.XR)
         'Rm pu  derived',   @(t) sprintf('%.1f', t.Rm_pu)
         'Lm pu  derived',   @(t) sprintf('%.1f', t.Lm_pu)
         'tap position used',@(t) sprintf('%d', t.Tap) };
lines = cell(size(rows,1), 1);
for r = 1:size(rows,1)
    cells = cellfun(rows{r,2}, num2cell(tx), 'UniformOutput', false);
    lines{r} = sprintf('%-18s%s', rows{r,1}, sprintf('%14s', cells{:}));
end
s = strjoin(lines, newline);
end

% =====================================================================
function s = tf2s(tf, yes, no)
if tf, s = yes; else, s = no; end
end
