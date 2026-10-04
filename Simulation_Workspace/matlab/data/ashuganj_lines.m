function L = ashuganj_lines()
%ASHUGANJ_LINES  Line / cable / series-branch database - Ashuganj SOUTH.
%
%   L = ASHUGANJ_LINES() returns a struct array of every series branch that
%   is NOT a transformer.  Most entries are deliberately zero-impedance: the
%   South plant is a compact single-shaft block with GIS, so the electrical
%   distances are short AND, more importantly, no cable or busduct impedance
%   is documented anywhere in the source set.  Rather than invent lengths and
%   impedances, those connections are modelled as direct nodes-in-common and
%   the omission is stated.
%
%   Approved answer Q7a: NO 70 km transmission line to a remote grid bus is
%   created.  The external-grid equivalent sits at the PLANT BOUNDARY.  The
%   one genuinely modelled series impedance is therefore the grid equivalent
%   itself, and it is an ESTIMATE, clearly labelled (approved answer Q1a).
%
%   See also ASHUGANJ_GRID, ASHUGANJ_MASTER_DATA.

k = 0; L = struct([]);

% =====================================================================
% 1.  The external grid equivalent series branch  (MODELLED)
% =====================================================================
% Placed as an EXPLICIT branch rather than inside the source block, because
% SPS enforces the swing voltage at the source TERMINAL: an internal source
% impedance would be short-circuited by the load-flow voltage constraint and
% would have no effect on the solved plant-boundary voltage.
k=k+1;
L(k).Name              = 'ZGRID';
L(k).Label             = 'GRID EQUIV Z';
L(k).Bus_from          = 'BGRID230';
L(k).Bus_to            = 'B230_REMOTE';
L(k).Placement_Note    = ['Phase-3: grid equivalent moved to remote bus; ', ...
                          'plant bus connects via L_LINE.'];
L(k).Vnom_V            = 230000;
L(k).Model_included    = true;
L(k).Model_block       = 'sps_lib/Passives/Three-Phase Series RLC Branch';
L(k).BranchType        = 'L';       % pure inductance: R is zero by Q1a
L(k).R_ohm             = 0;
L(k).R_Status          = 'ENGINEERING_ASSUMPTION';
L(k).R_Note            = ['Q1a approved: the grid X/R ratio is NOT ', ...
                          'documented, so no resistance is invented. R = 0 ', ...
                          'makes the grid equivalent purely reactive, which ', ...
                          'is the standard treatment when X/R is unknown ', ...
                          'and which slightly OVERSTATES the reactive ', ...
                          'coupling and UNDERSTATES grid losses. See ', ...
                          'matlab/data/assumptions/grid_series_resistance_zero.m'];
L(k).X_ohm             = [];        % filled below from the grid data
L(k).X_Status          = 'ESTIMATED';
L(k).Length_km         = 0;
L(k).Length_Status     = 'NOT_APPLICABLE';
L(k).Length_Note       = ['Zero by construction. This is a Thevenin ', ...
                          'EQUIVALENT at the plant boundary, not a physical ', ...
                          'line, so it has no length, no charging ', ...
                          'capacitance and no thermal rating (Q7a).'];
L(k).C_F               = 0;
L(k).C_Status          = 'NOT_APPLICABLE';

% =====================================================================
% 1b. Locked 0.7 km lumped dual-circuit PI line  (MODELLED, Phase 3)
% =====================================================================
k=k+1;
L(k).Name = 'L_LINE';
L(k).Label = 'SOUTH GIS TO GRID 0.7KM D/C EQ (MALLARD REF)';
L(k).Bus_from = 'B230_1';
L(k).Bus_to = 'B230_REMOTE';
L(k).Vnom_V = 230000;
L(k).Model_included = true;
L(k).Model_block = 'sps_lib/Passives/Three-Phase PI Section Line';
L(k).BranchType = 'PI';
L(k).Length_km = 0.7;
L(k).Length_Status = 'ENGINEERING_ASSUMPTION';
L(k).Length_Note = 'Locked Phase-3 EA: 0.7 km GIS-to-grid; INEL-112070-00-ELC-DE-0026 unavailable. 70 km retained only as documented 400-kV/North conflict; 44 km is the separate Ghorasal line.';
L(k).Physical_circuit_count = 2;
L(k).Model_representation = 'LUMPED_DUAL_CIRCUIT_PI';
L(k).Conductor_reference = 'MALLARD_795_MCM';
L(k).Conductor_Status = 'ENGINEERING_ASSUMPTION';
L(k).R_ohm = 0.0277725;  L(k).R_Status = 'ENGINEERING_ASSUMPTION';
L(k).R_Note = 'DERIVED_FROM_ENGINEERING_REFERENCE (human tier): (0.00015 pu/km*529)/2*0.7; ref Ghorasal-Mallard PGCB/JICA, NOT measured South link.';
L(k).X_ohm = 0.1425655;  L(k).X_Status = 'ENGINEERING_ASSUMPTION';
L(k).X_Note = 'DERIVED_FROM_ENGINEERING_REFERENCE (human tier): (0.00077 pu/km*529)/2*0.7; same reference.';
L(k).C_F = 3.937996e-6/(2*pi*50);  L(k).C_Status = 'ENGINEERING_ASSUMPTION';
L(k).C_Note = 'DERIVED_FROM_ENGINEERING_REFERENCE (human tier): B=3.937996 uS (2x1.968998) at 50 Hz; C=B/(2*pi*50).';
L(k).R0_ohm = NaN; L(k).R0_Status = 'MISSING';
L(k).X0_ohm = NaN; L(k).X0_Status = 'MISSING';
L(k).C0_F = NaN;   L(k).C0_Status = 'MISSING';

% =====================================================================
% 2.  230 kV GIS internal connections  (zero impedance)
% =====================================================================
k=k+1;
L(k).Name              = 'BAY_GSUT';
L(k).Label             = 'BAY 10BAY11';
L(k).Bus_from          = 'B230_1';
L(k).Bus_to            = 'GSUT_HV';
L(k).Vnom_V            = 230000;
L(k).Model_included    = false;
L(k).Model_treatment   = 'direct connection (zero impedance)';
L(k).Rated_A           = 2000;
L(k).Rated_A_Status    = 'VERIFIED_ENGINEERING_DOCUMENT';
L(k).Rated_A_Source    = ['GIS Data Sheet_230KV Generator Transformer module 2000 A ', ...
                          '(REV3 §3.6 units-column audit; Line module 2000 A, ', ...
                          'Bus coupler module 3150 A — 3150 A is coupler/busbar only). ', ...
                          'Conductor ampacity MISSING, never this module rating.'];
L(k).Exclusion_reason  = ['GIS bay 10BAY11 (Q0 circuit-breaker, Q1 to ', ...
                           'BUS 2, Q2 to BUS 1, Q9 earthing switch). The ', ...
                           'busduct and bay impedances are MISSING and are ', ...
                           'in any case negligible against the GSUT 16 %%. ', ...
                           'The GSUT HV terminal is therefore the SAME ', ...
                           'electrical node as B230_1.'];
L(k).Notes             = ['Double-busbar single-breaker: the bay can be ', ...
                          'selected to BUS 1 or BUS 2 via Q2/Q1. Approved ', ...
                          'answer Q10a: with the coupler closed the ', ...
                          'selection does not materially affect the ', ...
                          'balanced network, so GSUT is shown on BUS 1.'];

k=k+1;
L(k).Name              = 'BAY_GAT';
L(k).Label             = 'BAY 10BAY20';
L(k).Bay_label_note    = ['REV3.1 reconciliation: Label corrected 10BAY12->10BAY20 per ', ...
                          'REV3 C-17 (BAY_GAT=10BAY20) + GIS SLD GAT(F13) 10BAY20 + builder ', ...
                          'GAT BAY CB 10BAY20 convention. Prior 10BAY12 was the bus-coupler/protection ', ...
                          'panel designation, not the GAT bay — recorded as panel-label conflict, now resolved.'];
L(k).Bus_from          = 'B230_2';
L(k).Bus_to            = 'GAT_HV';
L(k).Vnom_V            = 230000;
L(k).Model_included    = false;
L(k).Model_treatment   = 'direct connection (zero impedance) + switching breaker';
L(k).Rated_A           = 2000;
L(k).Rated_A_Status    = 'VERIFIED_ENGINEERING_DOCUMENT';
L(k).Rated_A_Source    = ['Transformer-bay class 2000 A: GIS SLD shows GAT(F13) 10BAY20 with Q0 breaker ', ...
                          '(same Q0 designation as GSUT bay); CB datasheet headed TRANSFORMER BAY carries ', ...
                          '2000 A continuous (REV3 §3.6b/C-36, Q0-verified); module table GT 2000 A / Line 2000 A / ', ...
                          'Coupler 3150 A (REV3 §3.6). Conductor ampacity MISSING, never this module rating.'];
L(k).Exclusion_reason  = ['As BAY_GSUT. The bay IMPEDANCE is omitted, but ', ...
                          'the bay CIRCUIT-BREAKER is modelled explicitly ', ...
                          'because approved answer Q4c requires the GAT to ', ...
                          'be switched in and out between cases.'];
L(k).Notes             = 'GAT shown on BUS 2 so that the loop crosses the coupler.';

k=k+1;
L(k).Name              = 'BAY_GRID';
L(k).Label             = 'LINE BAY (bay number MISSING — NOT 10BAY20)';
L(k).Bay_label_note    = ['REV3.1 reconciliation: prior Label BAY 10BAY20 collided with corrected BAY_GAT=10BAY20; ', ...
                          '10BAY11/12/20 are GSUT/coupler/GAT per SLD+builder convention, so the outgoing line-bay number ', ...
                          'is MISSING (INEL-0026 unavailable). Label carries the conflict note, not a bay number.'];
L(k).Bus_from          = 'B230_1';
L(k).Bus_to            = 'GRID_TIE';
L(k).Vnom_V            = 230000;
L(k).Model_included    = false;
L(k).Model_treatment   = 'direct connection (zero impedance)';
L(k).Rated_A           = 2000;
L(k).Rated_A_Status    = 'VERIFIED_ENGINEERING_DOCUMENT';
L(k).Rated_A_Source    = ['GIS Data Sheet_230KV Line module 2000 A (REV3 §3.6 units-column audit; ', ...
                          'GT module 2000 A, Bus coupler module 3150 A — 3150 A is coupler/busbar only). ', ...
                          'Conductor ampacity MISSING, never this module rating.'];
L(k).Exclusion_reason  = 'As BAY_GSUT.';
L(k).Notes             = 'Outgoing line bay towards the PGCB 230 kV network.';

% =====================================================================
% 3.  22 kV isolated-phase busduct  (zero impedance)
% =====================================================================
k=k+1;
L(k).Name              = 'IPB22';
L(k).Label             = '22 kV IPB';
L(k).Bus_from          = 'B22';
L(k).Bus_to            = 'B22';
L(k).Vnom_V            = 22000;
L(k).Model_included    = false;
L(k).Model_treatment   = 'direct connection (zero impedance)';
L(k).Rated_A           = 12400;
L(k).Rated_A_Status    = 'VERIFIED_ENGINEERING_DOCUMENT';
L(k).Exclusion_reason  = ['Isolated-phase busduct linking generator, GCB, ', ...
                          'GSUT LV and UAT HV. Its impedance is MISSING and ', ...
                          'is physically a few metres of very large ', ...
                          'conductor. All four terminals are treated as one ', ...
                          'node, B22.'];
L(k).Notes             = ['The generator circuit-breaker (12.4 kA) sits in ', ...
                          'this busduct. It is CLOSED in every load-flow ', ...
                          'case - a load flow of a generating unit with an ', ...
                          'open GCB would be a different study.'];

% =====================================================================
% 4.  6.6 kV feeder cables to the segregated load nodes  (zero impedance)
% =====================================================================
for nm = {'WI1','WI2'}
    k=k+1;
    L(k).Name              = ['FDR_' nm{1}];
    L(k).Label             = ['6.6 kV FDR ' nm{1}];
    L(k).Bus_from          = 'B6_6';
    L(k).Bus_to            = ['B6_6_' nm{1}];
    L(k).Vnom_V            = 6600;
    L(k).Model_included    = false;
    L(k).Model_treatment   = 'direct connection (zero impedance)';
    L(k).Rated_A           = NaN;
    L(k).Rated_A_Status    = 'MISSING';
    L(k).Exclusion_reason  = ['Feeder cable size, length and impedance are ', ...
                              'ALL MISSING. Modelling a cable would mean ', ...
                              'inventing three quantities. The node is ', ...
                              'therefore connected with zero impedance, ', ...
                              'which means the Q6B load split SEGREGATES ', ...
                              'the load for reporting but does NOT make it ', ...
                              'electrically remote: all three 6.6 kV nodes ', ...
                              'solve to the same voltage. This limitation ', ...
                              'is stated in the results report - the split ', ...
                              'is honest about motor grouping, not about ', ...
                              'feeder voltage drop.'];
    L(k).Notes             = 'Water-intake / large-motor group feeder (Q6B).';
end

% =====================================================================
% Fill the one modelled impedance from the grid database, so the number
% exists in exactly ONE place.
% =====================================================================
Gr = ashuganj_grid();
L(1).X_ohm    = Gr.X_ohm;
L(1).L_H      = Gr.L_H;
L(1).X_Status = Gr.X_Status;
L(1).X_Source = Gr.X_Source;

% ------------------------------------------------------------------------
% Integrity assertions
% ------------------------------------------------------------------------
assert(numel(unique({L.Name})) == numel(L), 'ashuganj_lines: duplicate name.');
assert(numel(L) == 8, ...
    'ashuganj_lines: register holds 8 entries (7 Phase-2 + L_LINE).');
assert(sum([L.Model_included]) == 2, ...
    'ashuganj_lines: exactly two series branches should be modelled (ZGRID + L_LINE).');
assert(L(1).R_ohm == 0, 'ashuganj_lines: grid R must be 0 per approved answer Q1a.');
assert(L(1).X_ohm > 0, 'ashuganj_lines: grid X must be positive.');
assert(~any([L.Vnom_V] > 230000), ...
    'ashuganj_lines: a branch above 230 kV was defined. No 400 kV in South scope.');
end
