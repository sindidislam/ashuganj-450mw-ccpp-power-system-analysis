function [np, nf] = test_line_data()
%TEST_LINE_DATA  Asserts that NO transmission line has been invented.
%
%   This is the shortest test in the suite and one of the most important. The
%   plant connects to the PGCB grid through the 230 kV GIS. The source set
%   contains NO line length, NO conductor type, NO tower geometry and NO
%   sequence impedances for any outgoing feeder. Approved answer Q7a was
%   explicit: represent the grid as an equivalent at the plant boundary, do not
%   invent a 70 km line.
%
%   A "70 km ACSR line" would be trivially easy to add and would look
%   authoritative in a report. This test exists so that if anyone ever adds
%   one, the suite fails loudly instead of the model quietly acquiring fictional
%   transmission.
%
%   WHAT ashuganj_lines() ACTUALLY IS
%   ---------------------------------
%   A branch register, not a transmission-line register. Phase-3 AUTHORIZED:
%   it has eight entries and exactly two of them are modelled: ZGRID, the
%   Thevenin grid equivalent (now at the remote bus B230_REMOTE), and L_LINE,
%   the locked 0.7 km lumped dual-circuit PI line B230_1 -> B230_REMOTE
%   (ENGINEERING_ASSUMPTION). ZGRID has Length_km = 0 and Length_Status =
%   NOT_APPLICABLE, because a Thevenin equivalent has no length - and that is a
%   different statement from a length being missing. L_LINE has Length_km = 0.7
%   and Length_Status = ENGINEERING_ASSUMPTION - the sole authorized positive
%   length. The other six entries are GIS bays, the 22 kV isolated-phase
%   busduct and the two 6.6 kV feeders, all excluded with the reason recorded.
%   (Phase-2 baseline was 7 entries / 1 modelled per PRE_HASHES.)
%
%   So the test is NOT "nothing is modelled". It is:
%     - exactly two branches are modelled: the grid equivalent + L_LINE;
%     - no branch anywhere has a non-zero length except locked L_LINE 0.7 km;
%     - no branch has per-km constants at all, invented or otherwise;
%     - every excluded branch says why it was excluded.
T = t_case('test_line_data');
L = ashuganj_lines();

T = T.eq(numel(L), 8, 'branch register holds 8 entries: 1 grid equivalent, 1 L_LINE, 3 GIS bays, 1 IPB, 2 feeders');
% Phase-3 AUTHORIZED: +L_LINE 0.7 km lumped dual-circuit; Phase-2 baseline was 7/1 per PRE_HASHES

% ---- exactly two modelled branches: grid equivalent + Phase-3 line -------
% Phase-3 AUTHORIZED 8-branch world: ZGRID (Thevenin, no length) + L_LINE
% (locked 0.7 km lumped dual-circuit PI). No other branch is modelled.
inc = find([L.Model_included]);
T = T.eq(numel(inc), 2, 'exactly TWO series branches are modelled (ZGRID + Phase-3 L_LINE)');
kZ = find(strcmp({L.Name}, 'ZGRID'), 1);
kL = find(strcmp({L.Name}, 'L_LINE'), 1);
T = T.chk(~isempty(kZ), 'ZGRID present');
T = T.chk(~isempty(kL), 'L_LINE present');
T = T.eq(L(kZ).Bus_from, 'BGRID230', 'ZGRID from internal grid node');
T = T.eq(L(kZ).Bus_to, 'B230_REMOTE', 'ZGRID to remote bus (Phase-3 move)');
T = T.eq(L(kL).Bus_from, 'B230_1', 'L_LINE from plant bus');
T = T.eq(L(kL).Bus_to, 'B230_REMOTE', 'L_LINE to remote bus');

% ---- lengths: ZGRID zero/NOT_APPLICABLE; L_LINE locked 0.7 EA ------------
% Zero length on the equivalent is correct and deliberate; the ONLY positive
% length allowed anywhere is the locked Phase-3 L_LINE 0.7 km.
for i = 1:numel(L)
    nm = L(i).Label;
    if ~isempty(L(i).Length_km)
        if strcmp(L(i).Name, 'L_LINE')
            T = T.eq(L(i).Length_km, 0.7, sprintf('%s locked 0.7 km - the sole authorized line', nm));
            T = T.eq(L(i).Length_Status, 'ENGINEERING_ASSUMPTION', sprintf( ...
                '%s length is ENGINEERING_ASSUMPTION, never verified', nm));
        else
            T = T.eq(L(i).Length_km, 0, sprintf('%s has zero length - no line invented', nm));
            T = T.chk(strcmp(L(i).Length_Status, 'NOT_APPLICABLE'), sprintf( ...
                ['%s length is NOT_APPLICABLE, not MISSING: a Thevenin equivalent ' ...
                 'has no length, which is not the same as a length being unknown'], nm));
        end
    end
end

% ---- no per-km constant exists at all ----------------------------------
% Not "is NaN" - ABSENT. There is no field for a distributed constant anywhere in
% the register, because there is no distributed element in the model to hold one.
f = fieldnames(L);
for c = {'R1_ohm_per_km','X1_ohm_per_km','B1_S_per_km','R0_ohm_per_km','X0_ohm_per_km'}
    T = T.chk(~any(strcmp(f, c{1})), sprintf( ...
        'no %s field exists in the register - a per-km constant was never even created', c{1}));
end

% ---- every excluded branch justifies itself ----------------------------
for i = 1:numel(L)
    if L(i).Model_included, continue, end
    nm = L(i).Label;
    T = T.chk(~isempty(L(i).Exclusion_reason), sprintf( ...
        '%s records WHY it is excluded, so the omission is auditable', nm));
    T = T.chk(~isempty(L(i).Model_treatment), sprintf( ...
        '%s records how it is treated instead (%s)', nm, L(i).Model_treatment));
end

% ---- the two 6.6 kV feeders are the honest kind of missing --------------
% Their ratings are MISSING and stay MISSING. This is what makes the Q6B load
% split a reporting segregation rather than an electrical one, and the register
% has to say so rather than quietly filling in a cable size.
for nm = {'FDR_WI1','FDR_WI2'}
    k = find(strcmp({L.Name}, nm{1}), 1);
    T = T.chk(~isempty(k), sprintf('%s is present in the register', nm{1}));
    T = T.isnan(L(k).Rated_A, sprintf( ...
        '%s current rating stays MISSING (NaN) - no cable size invented', nm{1}));
    T = T.eq(L(k).Rated_A_Status, 'MISSING', sprintf('%s rating labelled MISSING', nm{1}));
    T = T.chk(contains(L(k).Exclusion_reason, 'MISSING'), sprintf( ...
        '%s states that size, length AND impedance are all missing', nm{1}));
end

% ---- the GIS bay ratings ARE documented by module class, never as ampacity ---
% REV3 §3.6 units-column audit: Generator Transformer module 2000 A, Line module
% 2000 A, Bus coupler module 3150 A. 3150 A is coupler/busbar only. Conductor
% ampacity is MISSING and is never a module rating.
for nm = {'BAY_GSUT','BAY_GRID'}
    k = find(strcmp({L.Name}, nm{1}), 1);
    T = T.eq(L(k).Rated_A, 2000, sprintf('%s carries the documented 2000 A module rating (bays, not busbar)', nm{1}));
    T = T.eq(L(k).Rated_A_Status, 'VERIFIED_ENGINEERING_DOCUMENT', ...
        sprintf('%s rating is VERIFIED', nm{1}));
end
% BAY_GAT = 10BAY20 per REV3 C-17 + SLD GAT(F13) 10BAY20 (prior 10BAY12 was the
% coupler/protection-panel designation — panel-label conflict, now resolved as finding).
% Transformer-bay class 2000 A (Q0 breaker, CB sheet TRANSFORMER BAY 2000 A).
k = find(strcmp({L.Name}, 'BAY_GAT'), 1);
T = T.eq(L(k).Label, 'BAY 10BAY20', 'BAY_GAT label is 10BAY20 per C-17 (not 10BAY12)');
T = T.eq(L(k).Rated_A, 2000, 'BAY_GAT carries the transformer-bay 2000 A module rating');
T = T.eq(L(k).Rated_A_Status, 'VERIFIED_ENGINEERING_DOCUMENT', 'BAY_GAT rating is VERIFIED');
% BAY_GRID outgoing line-bay number is MISSING (INEL-0026 unavailable); label carries conflict note.
k = find(strcmp({L.Name}, 'BAY_GRID'), 1);
T = T.chk(contains(L(k).Label, 'MISSING'), 'BAY_GRID label records the missing bay number explicitly');
T = T.chk(contains(L(k).Bay_label_note, '10BAY20'), 'BAY_GRID conflict note records the 10BAY20 collision');
k = find(strcmp({L.Name}, 'IPB22'), 1);
T = T.eq(L(k).Rated_A, 12400, '22 kV IPB carries the documented 12400 A rating');

% ---- no 400 kV anywhere -------------------------------------------------
T = T.chk(~any([L.Vnom_V] > 230000), ...
    'no branch above 230 kV: the 400 kV GIS is Ashuganj NORTH and is out of scope');
T = T.chk(~any([L.Vnom_V] == 400000), ...
    'and specifically nothing at 400000 V - the 400 V / 400 kV trap');

% ---- Phase-3 world: grid at REMOTE, line plant->remote; legacy fallback kept --
Gr = ashuganj_grid();
T = T.eq(Gr.Bus_boundary, 'B230_1', ...
    'legacy Bus_boundary fallback stays B230_1 (pre-Phase-3 plant boundary)');
T = T.eq(Gr.Grid_equivalent_bus, 'B230_REMOTE', ...
    'Grid_equivalent_bus is B230_REMOTE (Phase-3 remote-bus semantics)');
T = T.eq(Gr.Bus_remote, 'B230_REMOTE', 'display Bus_remote is B230_REMOTE');
% Explicit Phase-3 spans: ZGRID BGRID230<->B230_REMOTE, L_LINE B230_1->B230_REMOTE.
T = T.chk((strcmp(L(kZ).Bus_from,'BGRID230') && strcmp(L(kZ).Bus_to,'B230_REMOTE')) || ...
          (strcmp(L(kZ).Bus_from,'B230_REMOTE') && strcmp(L(kZ).Bus_to,'BGRID230')), ...
    'ZGRID spans B230_REMOTE<->BGRID230 in the Phase-3 world');
T = T.eq(L(kL).Bus_from, 'B230_1', 'L_LINE from plant bus B230_1 (Phase-3 world)');
T = T.eq(L(kL).Bus_to, 'B230_REMOTE', 'L_LINE to remote bus B230_REMOTE (Phase-3 world)');
% Siemens provenance semantics.
T = T.chk(contains(Gr.Isc_Source, '§2.4'), 'grid Isc_Source cites Siemens §2.4');
T = T.chk(contains(Gr.Isc_Source, 'EQUIPMENT RATINGS'), 'grid Isc_Source separates equipment ratings');
T = T.eq(Gr.R_ohm, 0, 'grid series resistance exactly 0 - X/R is undocumented (Q1a)');
T = T.near(Gr.Z_ohm, 2.6558, 5e-4, 'grid equivalent 2.6558 ohm');
T = T.near(Gr.L_H, Gr.X_ohm/(2*pi*50), 1e-12, ...
    'grid inductance derived at 50 Hz, so the model must solve at 50 Hz');
T = T.chk(strcmp(Gr.X_Status, 'ESTIMATED'), ...
    'grid impedance is labelled ESTIMATED, never VERIFIED');

% The register must take its impedance FROM the grid database, not hold a second
% copy of it. One number, one place.
T = T.near(L(kZ).X_ohm, Gr.X_ohm, 1e-12, ...
    'the register''s X comes from ashuganj_grid() - the estimate exists in exactly one place');
T = T.eq(L(kZ).X_Status, Gr.X_Status, 'and carries the same ESTIMATED status with it');

[np, nf] = T.done();
end
