function [np, nf] = test_magnetising_sensitivity()
%TEST_MAGNETISING_SENSITIVITY  Magnetising branch: now derived, still bounded.
%
%   THIS TEST USED TO GUARD AN ASSUMPTION. IT NOW GUARDS A DERIVATION.
%   ------------------------------------------------------------------
%   Its earlier version asserted Lm = 1e6 pu (numerically open) and stated the
%   reason as "every transformer nameplate in the source set gives the no-load
%   LOSS in kW and none of them gives the no-load CURRENT in per cent".
%
%   That was wrong. It was true of the rating PLATES and false of the DATA
%   SHEETS. The GSUT data sheet (S009-112070-00-ELC-HD-0001 Rev 00) publishes an
%   excitation current of 0.13 % at 100 % rated voltage, and the UAT/GAT data
%   sheet (S009-112070-00-ELC-HD-1001 Rev 00) publishes ~0.3 % and 0.3 %. The
%   assumption had been written before either document was read. Both are now
%   read, so both magnetising elements are DERIVED:
%
%     Rm(pu) = S_rated / P_no-load                     <- documented no-load LOSS
%     Lm(pu) = 1/sqrt(I0^2 - (1/Rm)^2)                 <- documented no-load CURRENT
%
%              GSUT      UAT      GAT
%     Rm      3239.0   1785.7   1087.0  pu
%     I0        0.13      0.3      0.3  %
%     Lm       791.9    339.3    350.2  pu
%
%   The subtraction in quadrature matters: I0 is the TOTAL excitation current,
%   and Rm already carries its loss component, so putting I0 straight into Lm
%   would double-count. For the UAT and GAT the loss component is a fifth of the
%   total current, which is not a rounding error.
%
%   WHY THE SWEEP SURVIVES
%   ----------------------
%   Two reasons, both about the quality of the new data rather than its absence.
%   The UAT figure is printed "~0.3", approximate in the source. The GSUT figure
%   carries the data sheet's own footnote that it "might be subject due change
%   after finalizing the transformer's detailed design". A derived value resting
%   on an approximate input still deserves a sensitivity band, so the sweep is
%   kept - and the retired Lm = 1e6 is kept in it as the first probe, which turns
%   "how wrong was the old assumption" into a measured number instead of a claim.
%
%   THE PROBE VALUES ARE NOT DATA
%   -----------------------------
%   Lm = 1e6, 500, 200 and 100 pu are probes. They appear in no data file and
%   nothing here is fed back into the model. Only the 'derived' row is the model
%   as actually built.
%
%   TWO QUANTITIES, NOT ONE
%   -----------------------
%   Kept apart deliberately, because conflating them is how the old bound came to
%   look 4x larger than it was:
%     Qm  - the magnetising reactive draw itself, sum(S_rating/Lm) ~ 0.795 MVAr.
%     dQg - the shift in the GENERATOR's reactive output. Smaller than Qm, because
%           the machine is a PV bus and the 230 kV swing supplies part of the rest.
%   The retired assumption record published +3.4406 MVAr as its worst case. That
%   was dQg at a 1 % magnetising current - 7.7x the GSUT's documented 0.13 % - so
%   it bounded the error safely but very loosely. Both are measured below.
%
%   Referenced by name from matlab/data/assumptions/transformer_magnetising_inductance.m,
%   which is retained as a SUPERSEDED record of the error rather than deleted.
T = t_case('test_magnetising_sensitivity');
mdlName = 'Ashuganj_South_Main';

D  = ashuganj_master_data();
Sb = D.base.Sbase_MVA;

% ---- the dataset must now say Lm is DERIVED, and from what ---------------
doc_I0 = struct('GSUT', 0.13, 'UAT', 0.3, 'GAT', 0.3);
for i = 1:numel(D.tx)
    x = D.tx(i);

    T = T.eq(x.I_noload_pct, doc_I0.(x.Name), sprintf( ...
        ['%s no-load current is %g %% FROM THE DATA SHEET - the quantity the ' ...
         'retired assumption claimed did not exist anywhere in the source set'], ...
        x.Name, doc_I0.(x.Name)));
    T = T.eq(x.I_noload_Status, 'VERIFIED_ENGINEERING_DOCUMENT', sprintf( ...
        '%s no-load current is sourced, not assumed', x.Name));

    T = T.eq(x.Rm_Status, 'DERIVED_FROM_VERIFIED_DATA', sprintf( ...
        '%s Rm IS derived from the documented %g kW no-load loss', x.Name, x.P_noload_kW));
    T = T.near(x.Rm_pu, x.S_rating_MVA*1000/x.P_noload_kW, 1e-9, sprintf( ...
        '%s Rm = %g MVA / %g kW = %.1f pu', x.Name, x.S_rating_MVA, x.P_noload_kW, x.Rm_pu));

    T = T.eq(x.Lm_Status, 'DERIVED_FROM_VERIFIED_DATA', sprintf( ...
        '%s Lm is now DERIVED, no longer an ENGINEERING_ASSUMPTION', x.Name));
    I0 = x.I_noload_pct/100;
    T = T.near(x.Lm_pu, 1/sqrt(I0^2 - (1/x.Rm_pu)^2), 1e-9, sprintf( ...
        '%s Lm = 1/sqrt(%.4g^2 - (1/%.1f)^2) = %.1f pu', ...
        x.Name, I0, x.Rm_pu, x.Lm_pu));
    T = T.chk(x.Lm_pu > 1/I0, sprintf( ...
        ['%s Lm (%.1f pu) is a LARGER reactance than the naive 1/I0 (%.1f pu), ' ...
         'i.e. draws LESS current, because the loss component Rm already ' ...
         'carries is removed in quadrature instead of being counted twice'], ...
        x.Name, x.Lm_pu, 1/I0));
    T = T.chk(x.Lm_pu ~= 1e6, sprintf( ...
        '%s Lm is no longer the retired open-circuit value', x.Name));
end

% ---- sweep Lm -----------------------------------------------------------
% Lm(pu) is roughly 1/I_magnetising(pu), so 100 pu is about 1 %, 200 pu about
% 0.5 % and 500 pu about 0.2 % magnetising current on each unit's own base.
% Ordered so Lm closes monotonically: the aggregate draw is dominated by the
% 515 MVA GSUT, whose derived 791.9 pu sits between open and the 500 pu probe.
probe = { 1e6,            'derived',            500,              200,              100             };
label = {'RETIRED: open', 'AS BUILT: derived', '~0.2 % Im probe', '~0.5 % Im probe', '~1.0 % Im probe'};
tname = {'GSUT', 'UAT', 'GAT'};
S = struct([]);

for i = 1:numel(probe)
    info = build_ashuganj_main('LF1', 'Quiet', true, 'Backup', false, 'Save', false);
    blks = {info.zones.gsut.tx, info.zones.aux.uat, info.zones.aux.gat};

    Qm = 0;
    for b = 1:numel(blks)
        x = D.tx(strcmp({D.tx.Name}, tname{b}));
        if ischar(probe{i})
            lm = x.Lm_pu;               % the model as actually built
        else
            lm = probe{i};              % a probe, applied to all three units
        end
        set_param(blks{b}, 'Lm', sprintf('%.10g', lm));
        Qm = Qm + x.S_rating_MVA/lm;    % nameplate-base magnetising draw at 1.0 pu
    end

    LF = power_loadflow(info.model, 'solve');

    C    = info.case;
    % Zones from THIS build: bus identification is by block handle and handles
    % are per-build, so a cached copy would resolve to the wrong model.
    node = ashuganj_bus_map(LF, D, info.zones);
    R    = ashuganj_branch_flows(LF, D, C, info.zones);

    S(i).label = label{i};
    S(i).Qm    = Qm;
    S(i).V230  = abs(LF.bus(node.B230_1).Vbus);
    S(i).V22   = abs(LF.bus(node.B22).Vbus);
    S(i).V66   = abs(LF.bus(node.B6_6).Vbus);
    S(i).Qgen  = imag(LF.bus(node.B22).Sbus)*Sb;
    S(i).Pgrid = real(LF.bus(node.BGRID230).Sbus)*Sb;
    S(i).Qgrid = imag(LF.bus(node.BGRID230).Sbus)*Sb;
    S(i).Ploss = C.Gen_P_MW + S(i).Pgrid - C.Load_P_MW;
    S(i).Qtx   = sum([R(strcmp({R.Type},'transformer')).Q_loss_MVAr]);
    S(i).Ptx   = sum([R(strcmp({R.Type},'transformer')).P_loss_MW]);

    T = T.chk(true, sprintf( ...
        '%-18s: Qm = %6.3f MVAr, Qgen = %+8.4f MVAr, P_loss = %.5f MW, V6.6 = %.7f pu, V230 = %.6f pu', ...
        label{i}, Qm, S(i).Qgen, S(i).Ploss, S(i).V66, S(i).V230));

    if bdIsLoaded(mdlName), bdclose(mdlName); end   % bdclose forces; close_system(...,0) warns on a dirty model
end

% ---- the derived case, against the treatment it replaces ----------------
% This is the whole point of keeping the retired value as probe 1: the cost of
% the old assumption is now a measurement, not an estimate.
iOpen = 1;  iBuilt = 2;
dQg   = S(iBuilt).Qgen - S(iOpen).Qgen;
dV66  = S(iBuilt).V66  - S(iOpen).V66;

T = T.chk(dQg > 0, sprintf( ...
    ['the derivation ADDS reactive demand the open-circuit treatment omitted: ' ...
     'Qgen %+.4f -> %+.4f MVAr, dQg = %+.4f MVAr (%.2f %% of the generator''s ' ...
     '%.3f MVAr). Direction matches what the retired record claimed'], ...
    S(iOpen).Qgen, S(iBuilt).Qgen, dQg, 100*dQg/abs(S(iOpen).Qgen), abs(S(iOpen).Qgen)));

T = T.chk(dQg < 3.4406, sprintf( ...
    ['and it is SMALLER than the +3.4406 MVAr the retired assumption record ' ...
     'published as its worst case (%.1fx smaller). That bound was taken at a ' ...
     '1 %% magnetising current, 7.7x the GSUT''s documented 0.13 %%, so the old ' ...
     'assumption erred in the safe direction but overstated the band'], ...
    3.4406/dQg));

T = T.chk(abs(dV66) < 5e-3, sprintf( ...
    ['correcting Lm moves the 6.6 kV bus by %+.2e pu (%.4f %% of nominal), so ' ...
     'no previously reported voltage is invalidated by the correction - the ' ...
     'error was real but not load-flow-material'], dV66, 100*abs(dV66)));

% ---- the claimed direction, across the whole sweep ----------------------
T = T.chk(all(diff([S.Qgen]) > 0), sprintf( ...
    ['reactive demand rises monotonically as Lm closes: %s MVAr, tracking the ' ...
     'nameplate draw %s MVAr'], ...
    strjoin(arrayfun(@(s) sprintf('%+.3f', s.Qgen), S, 'UniformOutput', false), ' -> '), ...
    strjoin(arrayfun(@(s) sprintf('%.3f', s.Qm),   S, 'UniformOutput', false), ' -> ')));

worstQ = S(end).Qgen - S(1).Qgen;
T = T.chk(worstQ > 0 && worstQ < 8, sprintf( ...
    ['worst-case reactive spread across the whole sweep is %+.4f MVAr (%.2f %% ' ...
     'of the %.3f MVAr the generator supplies), at a 1 %% magnetising current ' ...
     'well above anything these units document. The AS-BUILT figure to quote is ' ...
     'the %+.4f MVAr derived case, not this bound'], ...
    worstQ, 100*worstQ/abs(S(1).Qgen), abs(S(1).Qgen), dQg));

% ---- the claimed harmlessness ------------------------------------------
T = T.near([S.V22], ones(1, numel(probe)), 1e-6, ...
    'the 22 kV bus is unaffected - the machine regulates it');

% How much does Lm move the MV bus? Answer it, then say whether that matters -
% and say it against a measured scale rather than a round number.
%
% The extreme of the sweep is a 1 % magnetising current, chosen deliberately
% ABOVE anything these units show. Even there the MV bus barely moves.
%
% The non-arbitrary comparison is conflict C7. The UAT and GAT secondaries are
% 6.9 kV while the bus they feed is nominally 6.6 kV, and the sources do not
% settle which base the reported MV voltage should use. That conflict - now
% CONFIRMED at source-hierarchy level 2, both windings read 6.9 kV on the
% manufacturer's own data sheet - is worth 6900/6600 - 1 = 4.55 % on the very
% same number. So Lm is not the limiting uncertainty on this bus, and the factor
% by which it is not is asserted below instead of being asserted by adjective.
dSweep = max(abs([S.V66] - S(1).V66));
c7     = 6900/6600 - 1;

T = T.chk(dSweep < 5e-3, sprintf( ...
    ['the 6.6 kV bus moves by at most %.2e pu (%.3f %% of nominal) across the ' ...
     'whole sweep, and only %.4f %% between the open-circuit treatment and the ' ...
     'derived one, so Lm does not corrupt any reported voltage'], ...
    dSweep, 100*dSweep, 100*abs(dV66)));
T = T.chk(dSweep < c7/10, sprintf( ...
    ['and it is %.0fx smaller than conflict C7, which moves the SAME bus ' ...
     'voltage by %.2f %% depending on whether 6600 V or the 6.9 kV winding is ' ...
     'taken as the base. An unresolved source conflict dominates the ' ...
     'magnetising branch by more than an order of magnitude - that, not a ' ...
     'chosen threshold, is why Lm is not the limiting uncertainty at the MV bus'], ...
    c7/dSweep, 100*c7));
T = T.chk(max(abs([S.V230] - S(1).V230)) < 2e-3, sprintf( ...
    'the 230 kV boundary moves by at most %.2e pu across the whole sweep', ...
    max(abs([S.V230] - S(1).V230))));

% ---- the real part was already verified, so real loss must barely move ---
% Rm comes from documented no-load loss, so iron loss was right before this
% correction and is unchanged by it. Lm is purely reactive and can only touch
% real power through the extra current it draws through the windings - second
% order. This check is what proves the correction did not disturb P.
T = T.chk(max(abs([S.Ploss] - S(1).Ploss)) < 0.02, sprintf( ...
    ['total real loss moves by at most %.5f MW across the sweep, and %.5f MW ' ...
     'between open-circuit and derived: correcting the no-load CURRENT does ' ...
     'not disturb the no-load LOSS, which was documented and already right'], ...
    max(abs([S.Ploss] - S(1).Ploss)), abs(S(iBuilt).Ploss - S(iOpen).Ploss)));

% ---- loss decomposition, as an independent check on Rm -----------------
% Reconstruct the total real loss from documented nameplate data alone and
% compare it with the solved figure. Copper loss scales as the square of
% loading; iron loss as the square of voltage.
info = build_ashuganj_main('LF1', 'Quiet', true, 'Backup', false, 'Save', false);
LF   = power_loadflow(info.model, 'solve');
C    = info.case;
node = ashuganj_bus_map(LF, D, info.zones);
R    = ashuganj_branch_flows(LF, D, C, info.zones);

iron = 0; copper = 0;
for i = 1:numel(D.tx)
    x  = D.tx(i);
    kb = find(strcmp({R.Name}, x.Label), 1);
    if isempty(kb), continue, end
    Vw1    = R(kb).V_to_pu;                                  % winding 1 = HV side
    iron   = iron   + x.P_noload_kW/1000 * Vw1^2;
    loadpu = R(kb).S_from_MVA / x.S_rating_MVA;
    copper = copper + loadpu^2 * x.R_pu * x.S_rating_MVA;
end
Psolved = C.Gen_P_MW + real(LF.bus(node.BGRID230).Sbus)*Sb - C.Load_P_MW;
% Phase-3 AUTHORIZED: 8-branch world adds L_LINE I2R to solved loss; hand sum is iron+copper+L_LINE (tolerance 2% untouched)
kLL = find(strcmp({R.Name}, 'L_LINE'), 1);
Pline = 0; if ~isempty(kLL), Pline = R(kLL).P_loss_MW; end
Phand   = iron + copper + Pline;
T = T.chk(abs(Psolved - Phand)/Psolved < 0.02, sprintf( ...
    ['solved total loss %.4f MW is reproduced to %.2f %% by the nameplate ' ...
     'decomposition %.4f MW = %.4f MW iron (documented no-load losses at the ' ...
     'solved voltages) + %.4f MW copper (nameplate R at the solved loadings) + %.4f MW L_LINE. ' ...
     'Independent confirmation that Rm and R entered the model correctly'], ...
    Psolved, 100*abs(Psolved - Phand)/Psolved, Phand, iron, copper, Pline));
T = T.chk(abs(iron - 0.196) < 0.01, sprintf( ...
    ['iron loss %.4f MW is within 10 kW of the documented 159 + 14 + 23 = ' ...
     '196 kW sum, so all three no-load losses are being honoured - including ' ...
     'the GAT''s, which is energised from the 6.6 kV side with its bay open'], iron));

if bdIsLoaded(mdlName), bdclose(mdlName); end   % bdclose forces; close_system(...,0) warns on a dirty model
[np, nf] = T.done();
end
