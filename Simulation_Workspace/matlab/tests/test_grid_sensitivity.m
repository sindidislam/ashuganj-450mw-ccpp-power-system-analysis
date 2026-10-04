function [np, nf] = test_grid_sensitivity()
%TEST_GRID_SENSITIVITY  Quantifies the model's weakest number.
%
%   The external grid impedance is 2.6558 ohm, and it is ESTIMATED. It is the
%   ESTIMATED Siemens external-grid source quantity from Generator Data-South
%   §2.4 (UNgrid 230 kV; XN 2,66 estimated [=2.66]; Sk 19.919 [=19,919 MVA];
%   Ik 50 kA; executed |Z| = 2.65581124 ohm via √3), not a measured or
%   calculated PGCB fault level. Equipment 50 kA/1 s+3 s, 125 kA peak, 50 kA
%   making are separate EQUIPMENT RATINGS. Approved answer Q1a permits it only
%   as an explicitly labelled estimate. It is the single weakest input.
%
%   A number that weak must not be defended, it must be BOUNDED. This test
%   re-solves the base case with the grid impedance halved, doubled and
%   quadrupled and records what moves. Two results matter:
%
%     1. What the estimate DOES affect: the 230 kV boundary voltage, the angle
%        across the equivalent, and the reactive power the generator must
%        supply. Direction and magnitude are recorded here so the report can
%        state them instead of hiding behind one number.
%
%     2. What it does NOT affect: everything inside the plant. The generator is
%        a PV bus holding 22 kV at 1.00 pu, and the auxiliary load hangs off the
%        22 kV bus through the UAT, so the 6.6 kV voltage and the UAT loading are
%        mathematically independent of grid strength. That is the reason the
%        weakest number in the model does not undermine the auxiliary-system
%        results, and it is asserted here rather than merely claimed.
%
%        In the solved model that independence holds to about 1e-5 relative
%        rather than exactly, for two reasons that are both artefacts and neither
%        physical: the 1e6 ohm snubber of the open GAT bay, and the solver's
%        convergence tolerance. probe_snubber_coupling.m separates them by
%        measurement; the tolerances used below are set from that measurement.
%
%   The documented X/R of infinity is also checked: with R = 0 exactly, the grid
%   equivalent must dissipate exactly zero watts. Any non-zero grid loss would
%   mean a resistance had crept in from somewhere.
%
%   TWO GRID NUMBERS, TWO STATUSES, TWO PARTS
%   -----------------------------------------
%   The grid carries two unknowns and they are not the same kind of unknown:
%
%     |Z| = 2.6558 ohm   ESTIMATED  (Siemens §2.4 source quantity)  -> Part 1
%     R   = 0, X/R = inf ASSUMPTION (approved, Q1a)                  -> Part 2
%
%   Part 1 sweeps the magnitude with R held at zero, which bounds the estimate.
%   It says nothing about the assumption, because every point in it has R = 0.
%   Part 2 therefore sweeps X/R with |Z| HELD at the documented estimate, so the
%   two unknowns are separated and each is bounded on its own. Part 2 is the run
%   that grid_series_resistance_zero.m promises by name.
%
%   Promised by name in matlab/data/assumptions/grid_series_resistance_zero.m.
T = t_case('test_grid_sensitivity');
mdlName = 'Ashuganj_South_Main';

D  = ashuganj_master_data();
G  = D.grid;
% REV3.1 reconciliation: Siemens provenance semantics asserted on the data.
T = T.chk(contains(G.Isc_Source, '§2.4'), ...
    'grid Isc_Source cites Siemens §2.4 external-grid source quantity');
T = T.chk(contains(G.Isc_Source, 'EQUIPMENT RATINGS'), ...
    'grid Isc_Source separates equipment ratings from the source estimate');
T = T.chk(strcmp(G.Grid_equivalent_bus, 'B230_REMOTE'), ...
    'grid equivalent bus is B230_REMOTE (Phase-3 remote-bus semantics)');
sc = [0.5, 1.0, 2.0, 4.0];
S  = struct([]);

for i = 1:numel(sc)
    info = build_ashuganj_main('LF1', 'Quiet', true, 'Backup', false, 'Save', false);
    set_param(info.zones.grid.br, 'Inductance', sprintf('%.12g', G.L_H*sc(i)));
    LF = power_loadflow(info.model, 'solve');

    C    = info.case;
    % info.zones carries the block handles of THIS build. Bus identification is
    % by handle, and Simulink handles are per-build, so the zones must be the
    % ones from the build that was just solved - not a cached copy.
    node = ashuganj_bus_map(LF, D, info.zones);
    R    = ashuganj_branch_flows(LF, D, C, info.zones);
    Sb   = D.base.Sbase_MVA;

    S(i).scale   = sc(i);
    S(i).Z_ohm   = G.Z_ohm*sc(i);
    S(i).V230    = abs(LF.bus(node.B230_1).Vbus);
    % Phase-3 AUTHORIZED: ZGRID now spans BGRID230->B230_REMOTE; plant angle = ZGRID angle + L_LINE drop ~0.06 deg
    S(i).A230    = rad2deg(angle(LF.bus(node.B230_REMOTE).Vbus));
    S(i).V22     = abs(LF.bus(node.B22).Vbus);
    S(i).V66     = abs(LF.bus(node.B6_6).Vbus);
    S(i).Qgen    = imag(LF.bus(node.B22).Sbus)*Sb;
    S(i).Pgrid   = real(LF.bus(node.BGRID230).Sbus)*Sb;
    S(i).Qgrid   = imag(LF.bus(node.BGRID230).Sbus)*Sb;
    S(i).iter    = getfielddef(LF, 'iterations', NaN);

    kz = find(strcmp({R.Name}, 'ZGRID (grid equivalent)'), 1);
    S(i).Zloss_MW = R(kz).P_loss_MW;
    S(i).Zloss_Mv = R(kz).Q_loss_MVAr;
    S(i).Zcur_A   = R(kz).I_A;

    ku = find(strcmp({R.Name}, 'UAT 10BBT10'), 1);
    S(i).UAT_MVA  = R(ku).S_from_MVA;

    T = T.chk(true, sprintf( ...
        'Z = %6.3f ohm (x%.1f): V230 = %.6f pu, angle %+.4f deg, Qgen = %+8.4f MVAr, V6.6 = %.7f pu', ...
        S(i).Z_ohm, sc(i), S(i).V230, S(i).A230, S(i).Qgen, S(i).V66));

    if bdIsLoaded(mdlName), bdclose(mdlName); end   % bdclose forces; close_system(...,0) warns on a dirty model
end

k1 = find(sc == 1.0);

% ---- R = 0 means zero grid loss, exactly --------------------------------
for i = 1:numel(sc)
    T = T.chk(abs(S(i).Zloss_MW) < 1e-9, sprintf( ...
        ['grid equivalent dissipates %.3e MW at x%.1f - exactly zero, as R = 0 ' ...
         'and X/R = inf require (Q1a)'], S(i).Zloss_MW, sc(i)));
end
T = T.chk(S(k1).Zloss_Mv > 0, sprintf( ...
    'grid equivalent absorbs %.4f MVAr reactive at the documented estimate', S(k1).Zloss_Mv));

% ---- what the estimate DOES affect --------------------------------------
T = T.chk(all(diff([S.V230]) < 0), sprintf( ...
    ['boundary voltage falls monotonically as the grid weakens: %s pu. A weaker ' ...
     'grid sags more under the same export - the expected direction'], ...
    strjoin(arrayfun(@(s) sprintf('%.5f', s.V230), S, 'UniformOutput', false), ' -> ')));
T = T.chk(all(diff([S.Qgen]) > 0), sprintf( ...
    ['generator reactive output rises monotonically as the grid weakens: %s MVAr. ' ...
     'The machine holds 22 kV at 1.00 pu, so it must supply whatever the weaker ' ...
     'grid absorbs'], ...
    strjoin(arrayfun(@(s) sprintf('%+.3f', s.Qgen), S, 'UniformOutput', false), ' -> ')));
T = T.chk(all(diff([S.A230]) > 0), sprintf( ...
    'angle across the equivalent grows with impedance: %s deg', ...
    strjoin(arrayfun(@(s) sprintf('%+.4f', s.A230), S, 'UniformOutput', false), ' -> ')));

% The direction of the error is knowable even though its size is not: the §2.4
% source quantity is an ESTIMATE of grid strength, so treating it as firm
% UNDERSTATES the boundary voltage deviation when the grid is weaker.
% G.Isc_Warning says exactly that;
% this is the check that it is true of the model and not just of the prose.
dev1 = abs(1 - S(k1).V230);
dev2 = abs(1 - S(find(sc == 2.0)).V230);
T = T.chk(dev2 > dev1, sprintf( ...
    ['the estimate UNDERSTATES boundary voltage deviation, exactly as ' ...
     'G.Isc_Warning states: %.4f %% at the estimate against %.4f %% at twice ' ...
     'the impedance. Direction of the error is known; magnitude is not'], ...
    100*dev1, 100*dev2));

% ---- what the estimate does NOT affect ---------------------------------
% The independence claim is exact in principle: the generator is a PV bus
% holding 22 kV at 1.00 pu and the auxiliary system hangs off it through the
% UAT, so no grid impedance can reach it. In the solved model it is exact only
% to about 1e-5 relative, and probe_snubber_coupling.m separated the two reasons
% why - neither of them physical:
%
%   1. THE OPEN BREAKER SNUBBER. An open SPS breaker is not an open circuit, it
%      is a 1e6 ohm snubber. With the GAT bay open there is therefore a real
%      galvanic path 6.6 kV -> GAT -> GAT HV -> snubber -> 230 kV -> grid, and
%      the 230 kV voltage leaks back through it. Measured: raising the snubber
%      from 1e6 to 1e8 ohm cut the UAT spread from 1.68e-4 to 1.43e-5 MVA, so
%      this accounts for ~1.5e-4 MVA of it. It is an artefact of the block, not
%      plant equipment.
%
%   2. CONVERGENCE TOLERANCE. Raising the snubber a further hundredfold did NOT
%      reduce the spread again (1.43e-5 -> 1.61e-5 MVA) and the trend stopped
%      being monotonic. That plateau is the solver's own tolerance, and no
%      change to the model removes it.
%
% So the tolerances below are set above the measured artefact, not tuned until
% the test passed. 1e-3 MVA is 6x the snubber artefact and 60x the solver floor,
% and still asserts independence to 6e-5 of the UAT loading.
T = T.near([S.V22], ones(1, numel(sc)), 1e-6, ...
    'the 22 kV generator bus stays at 1.000000 pu for every grid strength - it is a PV bus');
T = T.near([S.V66], repmat(S(k1).V66, 1, numel(sc)), 1e-5, sprintf( ...
    ['the 6.6 kV auxiliary bus is INDEPENDENT of grid strength (%.7f pu ' ...
     'throughout, spread %.2e pu). The auxiliary system hangs off a regulated ' ...
     '22 kV bus, so the weakest number in the model cannot corrupt it'], ...
    S(k1).V66, max([S.V66]) - min([S.V66])));
T = T.near([S.UAT_MVA], repmat(S(k1).UAT_MVA, 1, numel(sc)), 1e-3, sprintf( ...
    ['UAT loading is likewise independent of grid strength: %.6f MVA throughout, ' ...
     'spread %.2e MVA (%.1e relative) across an 8x range of grid impedance'], ...
    S(k1).UAT_MVA, max([S.UAT_MVA]) - min([S.UAT_MVA]), ...
    (max([S.UAT_MVA]) - min([S.UAT_MVA]))/S(k1).UAT_MVA));

% The residual must stay NEGLIGIBLE, and "negligible" needs a scale. The UAT is
% a 25 MVA unit, so the whole grid sweep must not move its loading by even a
% thousandth of a per cent of its rating. This is the check that would fail if a
% real coupling ever appeared - a closed GAT bay, say - rather than an artefact.
uatSpreadPct = 100*(max([S.UAT_MVA]) - min([S.UAT_MVA])) / 25;
T = T.chk(uatSpreadPct < 1e-3, sprintf( ...
    ['and the residual is %.2e %% of the UAT''s 25 MVA rating - below any ' ...
     'engineering significance, and attributable to the snubber artefact and ' ...
     'solver tolerance rather than to grid strength'], uatSpreadPct));

% ---- the pre-stated hand calculation ------------------------------------
% ashuganj_grid.m commits to a prediction BEFORE any solve: about 1.1 deg of
% angle across the equivalent at roughly 375 MW export, with only a small
% magnitude change. A prediction written down in advance is worth more than any
% number of retrospective explanations, so it is tested literally.
% Phase-3 AUTHORIZED: S(k1).A230 / X.A230 are B230_REMOTE angles (ZGRID span); tolerance 0.05 untouched.
Pexp  = -S(k1).Pgrid;
apred = rad2deg(atan(Pexp*1e6*G.X_ohm / G.Vnom_V^2));
T = T.near(S(k1).A230, apred, 0.05, sprintf( ...
    ['solved angle across the grid equivalent %+.4f deg matches the ' ...
     'hand calculation atan(P*X/V^2) = %+.4f deg at %.2f MW export - the ' ...
     'prediction written into ashuganj_grid.m before the model was solved'], ...
    S(k1).A230, apred, Pexp));
T = T.chk(abs(S(k1).A230 - 1.1) < 0.15, sprintf( ...
    'and it matches the ~1.1 deg stated in G.Expected_effect (%.4f deg)', S(k1).A230));

% ---- current against the busbar rating (3150 A = bus-coupler/busbar module) --
% 3150 A is the GIS bus-coupler/busbar module rating, NOT a bay or conductor
% rating (bays are 2000 A modules; South-line ampacity is MISSING).
T = T.chk(S(k1).Zcur_A < 3150, sprintf( ...
    ['boundary current %.1f A is within the 3150 A bus-coupler/busbar module rating ' ...
     '(%.1f %% of it)'], S(k1).Zcur_A, 100*S(k1).Zcur_A/3150));

% =====================================================================
% PART 2 - THE X/R ASSUMPTION ITSELF
% =====================================================================
% Part 1 swept the impedance MAGNITUDE, which bounds the 2.6558 ohm ESTIMATE.
% It does not bound the R = 0 ASSUMPTION at all: every point in that sweep had
% R = 0. The two grid numbers have different statuses and need separate
% treatment, and grid_series_resistance_zero.m promises this one by name.
%
% |Z| IS HELD AT THE DOCUMENTED ESTIMATE throughout, so only the R/X split
% moves. Given X/R = k and |Z| fixed: X = |Z|/sqrt(1 + 1/k^2), R = X/k. Without
% that constraint the sweep would confound the assumption with the estimate and
% measure nothing cleanly.
%
% THE PROBE VALUES ARE NOT DATA. X/R = 20, 10 and 5 appear nowhere in the source
% set, are written into no data file, and exist only inside this test. They span
% the range quoted for transmission-connected equivalents and are used to bound
% an omission, never to fill it.
kXR   = [inf, 20, 10, 5];
X = struct([]);

for i = 1:numel(kXR)
    k = kXR(i);
    Xo = G.Z_ohm / sqrt(1 + 1/k^2);
    Ro = Xo / k;                                  % 0 exactly when k = inf
    info = build_ashuganj_main('LF1', 'Quiet', true, 'Backup', false, 'Save', false);
    if Ro == 0
        set_param(info.zones.grid.br, 'BranchType',  'L');
    else
        set_param(info.zones.grid.br, 'BranchType',  'RL');
        set_param(info.zones.grid.br, 'Resistance',  sprintf('%.12g', Ro));
    end
    set_param(info.zones.grid.br, 'Inductance', sprintf('%.12g', Xo/(2*pi*D.base.f_Hz)));
    LF = power_loadflow(info.model, 'solve');

    C    = info.case;
    node = ashuganj_bus_map(LF, D, info.zones);
    % ashuganj_branch_flows reconstructs every flow from the DATASET impedances,
    % deliberately and independently of the model - that independence is what
    % makes it a cross-check rather than an echo. Here the model has been mutated
    % away from the dataset on purpose, so the dataset copy handed to it must be
    % mutated identically or it would reconstruct the grid branch at R = 0 and
    % report zero loss while the solved network was plainly dissipating power.
    % (It did exactly that on the first run of this test.) One impedance, written
    % once, used by both - not a second copy of the loss formula living here.
    Dx = D;
    Dx.grid.R_ohm = Ro;
    Dx.grid.X_ohm = Xo;
    Dx.grid.Z_ohm = hypot(Ro, Xo);
    Dx.grid.L_H   = Xo/(2*pi*D.base.f_Hz);
    R    = ashuganj_branch_flows(LF, Dx, C, info.zones);
    Sb   = D.base.Sbase_MVA;
    kz   = find(strcmp({R.Name}, 'ZGRID (grid equivalent)'), 1);
    ku   = find(strcmp({R.Name}, 'UAT 10BBT10'), 1);

    X(i).XR       = k;
    X(i).R_ohm    = Ro;
    X(i).X_ohm    = Xo;
    X(i).Zmag     = hypot(Ro, Xo);
    X(i).V230     = abs(LF.bus(node.B230_1).Vbus);
    % Phase-3 AUTHORIZED: ZGRID now spans BGRID230->B230_REMOTE; plant angle = ZGRID angle + L_LINE drop ~0.06 deg
    X(i).A230     = rad2deg(angle(LF.bus(node.B230_REMOTE).Vbus));
    X(i).V22      = abs(LF.bus(node.B22).Vbus);
    X(i).V66      = abs(LF.bus(node.B6_6).Vbus);
    X(i).Qgen     = imag(LF.bus(node.B22).Sbus)*Sb;
    X(i).Pgen     = real(LF.bus(node.B22).Sbus)*Sb;
    X(i).Pswing   = -real(LF.bus(node.BGRID230).Sbus)*Sb;
    % Reactive at the swing node, needed to state the P/Q ratio that drives the
    % whole finding below from measurement rather than from a remembered figure.
    X(i).Qswing   = -imag(LF.bus(node.BGRID230).Sbus)*Sb;
    X(i).Zloss_MW = R(kz).P_loss_MW;
    X(i).UAT_MVA  = R(ku).S_from_MVA;
    % Power leaving the plant at the boundary, ahead of the equivalent. This is
    % the quantity the plant is responsible for; Pswing is what survives the
    % PGCB equivalent and reaches the swing node.
    X(i).Pbnd     = X(i).Pswing + X(i).Zloss_MW;
    % Loss INSIDE the plant: dispatched power, less auxiliary load, less what
    % reaches the boundary. Must be invariant under X/R - it is the number the
    % study reports, and nothing beyond the boundary may touch it.
    X(i).Pplant   = C.Gen_P_MW - C.Load_P_MW - X(i).Pbnd;

    T = T.chk(true, sprintf( ...
        'X/R = %5.4g: R = %.4f ohm, X = %.4f ohm, |Z| = %.4f ohm, V230 = %.6f pu, angle %+.4f deg, Qgen = %+8.4f MVAr, ZGRID loss = %.4f MW', ...
        k, Ro, Xo, X(i).Zmag, X(i).V230, X(i).A230, X(i).Qgen, X(i).Zloss_MW));

    if bdIsLoaded(mdlName), bdclose(mdlName); end
end

% The control has to be verified before the result is believed.
T = T.near([X.Zmag], repmat(G.Z_ohm, 1, numel(kXR)), 1e-9, sprintf( ...
    ['|Z| stayed at the documented %.4f ohm estimate at every X/R, so what ' ...
     'follows measures the R = 0 assumption alone and not the magnitude ' ...
     'estimate swept in Part 1'], G.Z_ohm));

% ---- what R = 0 costs: losses beyond the plant boundary ----------------
% This is the largest single consequence and it must not be buried. With R = 0
% the equivalent dissipates exactly nothing, so "system loss" and "plant loss"
% are the same number. Introduce a realistic X/R and they separate.
T = T.chk(X(1).Zloss_MW == 0, sprintf( ...
    'at the assumed X/R = inf the equivalent dissipates exactly %g MW', X(1).Zloss_MW));
T = T.chk(all(diff([X.Zloss_MW]) > 0), sprintf( ...
    ['loss in the equivalent rises as X/R falls: %s MW. At X/R = 10 it is ' ...
     '%.4f MW - COMPARABLE TO THE WHOLE PLANT''S %.4f MW of internal loss. ' ...
     'The assumption therefore does not make a small change to reported system ' ...
     'loss, it changes what "system loss" MEANS: with R = 0 the reported figure ' ...
     'is plant loss only, which for a plant study is the defensible reading, ' ...
     'but the report must say so rather than imply the grid is lossless'], ...
    strjoin(arrayfun(@(s) sprintf('%.4f', s.Zloss_MW), X, 'UniformOutput', false), ' -> '), ...
    X(3).Zloss_MW, X(1).Pplant));

% And the plant's own loss must not move, or the separation above is fiction.
T = T.near([X.Pplant], repmat(X(1).Pplant, 1, numel(kXR)), 5e-3, sprintf( ...
    ['while the plant''s OWN loss stays at %.5f MW (spread %.2e MW) across the ' ...
     'whole X/R range. The two loss figures are genuinely separable, which is ' ...
     'what licenses reporting the plant figure alone'], ...
    X(1).Pplant, max([X.Pplant]) - min([X.Pplant])));

% ---- what R = 0 does NOT change: everything the plant is measured by ---
% grid_series_resistance_zero.m claims no effect on generator output, transformer
% loading, auxiliary load or any per-unit voltage inside the plant. Measured, that
% claim is TRUE of every plant-internal quantity and of real power - and FALSE of
% generator REACTIVE output, which moves by a third across this sweep. The true
% half is checked here; the false half is checked, and quantified, further down
% under "the generator reactive output claim is WRONG". The record has been
% corrected to match; this test is what corrected it.
T = T.near([X.V22], ones(1, numel(kXR)), 1e-6, ...
    'the 22 kV bus holds 1.000000 pu at every X/R - the PV constraint is upstream of the grid');
T = T.near([X.V66], repmat(X(1).V66, 1, numel(kXR)), 1e-5, sprintf( ...
    'the 6.6 kV auxiliary bus is unmoved by X/R (%.7f pu, spread %.2e pu)', ...
    X(1).V66, max([X.V66]) - min([X.V66])));
T = T.near([X.UAT_MVA], repmat(X(1).UAT_MVA, 1, numel(kXR)), 1e-3, sprintf( ...
    'UAT loading is unmoved by X/R (%.6f MVA, spread %.2e MVA)', ...
    X(1).UAT_MVA, max([X.UAT_MVA]) - min([X.UAT_MVA])));
T = T.near([X.Pbnd], repmat(X(1).Pbnd, 1, numel(kXR)), 5e-3, sprintf( ...
    ['and the power the plant actually delivers to the boundary is unmoved: ' ...
     '%.4f MW, spread %.2e MW. The grid resistance changes what happens BEYOND ' ...
     'the plant, not what the plant produces - which is precisely why this ' ...
     'assumption is tolerable in a plant study'], ...
    X(1).Pbnd, max([X.Pbnd]) - min([X.Pbnd])));

% ---- the direction and size of the error in the reported voltages ------
% AN EARLIER VERSION OF THIS TEST ASSERTED THE OPPOSITE OF WHAT HAPPENS, because
% it tested the prose of grid_series_resistance_zero.m instead of the network. The
% record claimed the angle is OVERSTATED and the magnitude drop UNDERSTATED by
% taking R = 0. Both were written from the usual transmission intuition, where
% flow is largely reactive. This plant is the other case: it carries 3.745 pu of P
% across the boundary against only 0.297 pu of Q in magnitude - and the Q flows
% the other way, into the plant - so R*P dominates X*Q and the intuition inverts.
% The assertions below state the MEASURED directions. The record has been
% corrected to match them - not the reverse.
%
% ANGLE: essentially INVARIANT, and not even monotonic. delta ~ (X*P - R*Q)/V^2.
% Holding |Z| fixed, X falls only 2 % across the whole sweep (2.6558 -> 2.6042
% ohm), so X*P falls about 2 %; but -R*Q is POSITIVE here (Q into the plant is
% negative) and of comparable size, so the two nearly cancel. The residual
% movement is a few thousandths of a degree in either direction, which is why a
% monotonicity test on the angle was the wrong test to write.
angSpread = max([X.A230]) - min([X.A230]);
T = T.chk(angSpread < 0.01, sprintf( ...
    ['the angle across the equivalent is INVARIANT under X/R, not overstated: ' ...
     '%s deg, total spread %.4f deg (%.2f %% of the %+.4f deg shift itself) and ' ...
     'NOT monotonic. The assumption record''s "angle slightly overstated" claim ' ...
     'is contradicted: X is pinned by |Z|, so there is almost nothing left for ' ...
     'the R/X split to move'], ...
    strjoin(arrayfun(@(s) sprintf('%+.4f', s.A230), X, 'UniformOutput', false), ' -> '), ...
    angSpread, 100*angSpread/abs(X(1).A230), X(1).A230));

% MAGNITUDE: the boundary voltage RISES as R is introduced, so R = 0 OVERSTATES
% the sag. The model is PESSIMISTIC about boundary voltage, not optimistic. That
% is the safer direction for a plant study, but it is the opposite of what the
% record said, and a reader who believed the record would apply the correction the
% wrong way.
T = T.chk(all(diff([X.V230]) > 0), sprintf( ...
    ['and the boundary voltage RISES as X/R falls: %s pu. So R = 0 OVERSTATES ' ...
     'the boundary sag by %.2e pu at a realistic X/R = 10 - the model is ' ...
     'PESSIMISTIC about boundary voltage by %.4f %% of nominal, not optimistic ' ...
     'as the assumption record claimed'], ...
    strjoin(arrayfun(@(s) sprintf('%.6f', s.V230), X, 'UniformOutput', false), ' -> '), ...
    X(3).V230 - X(1).V230, 100*(X(3).V230 - X(1).V230)));

% The direction above is not just observed, it is PREDICTED, which is the
% difference between a measurement and a coincidence. V_bnd - V_swing ~
% (R*P + X*Q)/V, with P and Q taken in the direction of the drop - boundary
% towards swing - which is the direction the plant actually exports. At X/R = 10,
% R = X/10 on a 529 ohm base is 4.995e-4 pu and the export is 3.745 pu, so R*P
% alone is +1.871e-3 pu: POSITIVE, hence a rise. The measured rise is +1.618e-3
% pu; the balance is the X*Q term, which moves the other way as Q falls.
Zb230  = 230e3^2 / (D.base.Sbase_MVA*1e6);
RP_pu  = (X(3).R_ohm/Zb230) * (X(3).Pswing/D.base.Sbase_MVA);
T = T.chk(RP_pu > 0 && abs(RP_pu) > abs(X(3).V230 - X(1).V230), sprintf( ...
    ['and the rise is BOUNDED BY THE HAND CALCULATION that explains it: ' ...
     'R*P = (%.4f/%.1f)*(%+.3f) = %+.3e pu against a measured rise of %+.3e pu, ' ...
     'the balance being the smaller X*Q term moving the other way. Sign and ' ...
     'size both predicted, so the direction is mechanism and not coincidence'], ...
    X(3).R_ohm, Zb230, X(3).Pswing/D.base.Sbase_MVA, RP_pu, ...
    X(3).V230 - X(1).V230));

% Is that error big enough to matter? Judge it against the magnitude estimate
% swept in Part 1, which is the other grid unknown and the acknowledged weakest
% input. Comparing one unknown against the other is a measured statement; a
% chosen threshold would not be. THE ANSWER IS THE UNCOMFORTABLE ONE: the ASSUMED
% number moves the boundary voltage MORE than doubling the ESTIMATED one does.
dV_XR  = abs(X(3).V230 - X(1).V230);                  % X/R inf -> 10, |Z| fixed
dV_mag = abs(S(k1).V230 - S(find(sc == 2.0)).V230);   % |Z| x1 -> x2, R = 0
T = T.chk(dV_XR > dV_mag, sprintf( ...
    ['and it is LARGER than the uncertainty carried by the magnitude estimate: ' ...
     'X/R inf->10 moves the boundary voltage %.2e pu, while DOUBLING the ' ...
     'estimated |Z| moves it only %.2e pu (%.1fx less). The reason is that the ' ...
     'plant delivers %+.3f pu of P and only %+.3f pu of Q at the swing node, a ' ...
     'ratio of %.1f to 1, so R*P dominates X*Q and the term that was ASSUMED ' ...
     'away is the bigger one. Both grid numbers must therefore be flagged in ' ...
     'the report - it is NOT enough to flag the estimate alone, which is what ' ...
     'the earlier version of this test concluded from the opposite assertion'], ...
    dV_XR, dV_mag, dV_XR/dV_mag, ...
    X(1).Pswing/D.base.Sbase_MVA, X(1).Qswing/D.base.Sbase_MVA, ...
    abs(X(1).Pswing/X(1).Qswing)));

% ---- the generator reactive output claim is WRONG ----------------------
% The record claims R = 0 has "no effect on generator output". True of MW - the
% dispatch is a PV setpoint and cannot move - and false of MVAr. As R is
% introduced the boundary voltage rises past the swing voltage, so the reactive
% the machine must push into the grid to hold 22 kV at 1.00 pu falls, and it
% falls by a third. This is the one finding in Part 2 that changes a reported
% NUMBER rather than a caveat, so it gets its own check.
T = T.chk(all(diff([X.Qgen]) < 0), sprintf( ...
    ['generator REACTIVE output falls monotonically as R is introduced: %s MVAr ' ...
     '- %+.2f %% at a realistic X/R = 10 and %+.2f %% at X/R = 5. The ' ...
     'assumption record''s "no effect on generator output" is therefore WRONG ' ...
     'for MVAr: the reported Qgen of %.4f MVAr is a consequence of the R = 0 ' ...
     'assumption to within about a third of its own value'], ...
    strjoin(arrayfun(@(s) sprintf('%+.4f', s.Qgen), X, 'UniformOutput', false), ' -> '), ...
    100*(X(3).Qgen - X(1).Qgen)/X(1).Qgen, ...
    100*(X(4).Qgen - X(1).Qgen)/X(1).Qgen, X(1).Qgen));
T = T.near([X.Pgen], repmat(D.gen(1).Dispatch.Rated.P_MW, 1, numel(kXR)), 1e-3, ...
    sprintf(['while generator REAL output is untouched at %.2f MW in every ' ...
     'case (spread %.2e MW), because it is a dispatch setpoint and not a solved ' ...
     'quantity. So the record''s claim survives for MW and fails for MVAr - ' ...
     'exactly the distinction it failed to draw'], ...
    D.gen(1).Dispatch.Rated.P_MW, max([X.Pgen]) - min([X.Pgen])));

[np, nf] = T.done();
end

% =====================================================================
function v = getfielddef(s, f, d)
if isfield(s, f), v = s.(f); else, v = d; end
end
