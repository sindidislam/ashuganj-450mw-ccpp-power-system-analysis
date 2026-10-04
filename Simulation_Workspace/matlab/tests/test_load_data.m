function [np, nf] = test_load_data()
%TEST_LOAD_DATA  Checks on the auxiliary load allocation.
%
%   The total auxiliary load, 14.0 MW at 0.85 lagging, is project data. Its
%   SPLIT across the three 6.6 kV boards is NOT: approved answer Q6B chose a
%   9050:2500:2500 allocation drawn from documented motor ratings, and the user
%   required in the same breath that "the allocation must be labelled an
%   assumption". This test checks the arithmetic of the split AND that the label
%   is still attached - specifically on P_MW, the apportioned megawatts, which is
%   the only quantity in the chain that is actually assumed rather than divided.
T = t_case('test_load_data');
Ld = ashuganj_loads();

inm = find([Ld.Model_included]);
T = T.eq(numel(inm), 3, 'three auxiliary loads are modelled (6.6 kV boards)');

% ---- totals, exactly ----------------------------------------------------
Ptot = sum([Ld(inm).P_MW]);
Qtot = sum([Ld(inm).Q_MVAr]);
T = T.near(Ptot, 14.0, 1e-9, sprintf('allocated P sums to %.6f MW = 14.0 MW', Ptot));
T = T.near(Qtot, 8.6764, 5e-4, sprintf('allocated Q sums to %.6f MVAr', Qtot));
T = T.near(sum([Ld(inm).Share]), 1.0, 1e-12, 'shares sum to exactly 1');

% ---- the 9050:2500:2500 split ------------------------------------------
alloc = [Ld(inm).Alloc_kW];
T = T.near(sort(alloc, 'descend'), [9050 2500 2500], 1e-9, ...
    'allocation ratio is the approved 9050 : 2500 : 2500 (Q6B)');
for k = inm
    T = T.near(Ld(k).Share, Ld(k).Alloc_kW/sum(alloc), 1e-12, ...
        sprintf('%s share = %g / %g', Ld(k).Label, Ld(k).Alloc_kW, sum(alloc)));
    T = T.near(Ld(k).P_MW, 14.0*Ld(k).Share, 1e-9, ...
        sprintf('%s P = 14.0 x share = %.4f MW', Ld(k).Label, Ld(k).P_MW));
end

% ---- power factor consistency ------------------------------------------
for k = inm
    pf = Ld(k).P_MW / hypot(Ld(k).P_MW, Ld(k).Q_MVAr);
    T = T.near(pf, 0.85, 1e-3, sprintf('%s power factor %.4f lagging', Ld(k).Label, pf));
    T = T.chk(Ld(k).Q_MVAr > 0, sprintf('%s Q is inductive (positive)', Ld(k).Label));
end
pfTot = Ptot / hypot(Ptot, Qtot);
T = T.near(pfTot, 0.85, 1e-3, sprintf('total auxiliary power factor %.4f lagging', pfTot));

% ---- the assumption label must still be attached ------------------------
% WHICH field carries the assumption matters, and the dataset draws the line in
% the right place:
%
%   Alloc_kW      VERIFIED_PROJECT_DATA        - documented motor ratings
%   Share         DERIVED_FROM_VERIFIED_DATA   - arithmetic on those ratings
%   P_MW          ENGINEERING_ASSUMPTION       <-- the apportioned megawatts
%
% The RATIO 9050:2500:2500 is not an assumption, it is division. What is assumed
% is that the 14 MW total distributes in proportion to installed motor rating -
% i.e. that every group runs at the same load factor - and that assumption lands
% on P_MW. This is where the user's Q6 requirement, "the allocation must be
% labelled an assumption", is satisfied.
T = T.chk(isfield(Ld, 'P_Status'), 'the apportioned load carries a Status field');
for k = inm
    T = T.eq(Ld(k).P_Status, 'ENGINEERING_ASSUMPTION', sprintf( ...
        ['%s apportioned P is labelled ENGINEERING_ASSUMPTION (Q6: "the ' ...
         'allocation must be labelled an assumption")'], Ld(k).Label));
    T = T.eq(Ld(k).Alloc_Status, 'VERIFIED_PROJECT_DATA', sprintf( ...
        '%s underlying motor rating is VERIFIED_PROJECT_DATA', Ld(k).Label));
    T = T.eq(Ld(k).Share_Status, 'DERIVED_FROM_VERIFIED_DATA', sprintf( ...
        ['%s share is DERIVED, not assumed - the ratio is arithmetic on ' ...
         'documented ratings; the assumption is in P_MW'], Ld(k).Label));
end
T = T.chk(exist('aux_load_allocation_split', 'file') == 2, ...
    'and the assumption has its own record in matlab/data/assumptions/');

% ---- modelling settings -------------------------------------------------
for k = inm
    T = T.eq(Ld(k).Vnom_V, 6600, ...
        sprintf('%s referenced to the 6.6 kV PLANT BUS nominal', Ld(k).Label));
    T = T.eq(Ld(k).f_Hz, 50, sprintf('%s at 50 Hz', Ld(k).Label));
    T = T.eq(Ld(k).LoadType, 'constant PQ', ...
        sprintf('%s modelled constant PQ - no invented voltage dependence', Ld(k).Label));
    T = T.eq(Ld(k).C_MVAr, 0, sprintf('%s no power-factor correction invented', Ld(k).Label));
end

% ---- the three loads sit on three REGISTER buses, one ELECTRICAL node ----
% The Q6B split segregates the load for reporting. It does not make it
% electrically remote: the feeder cable size, length and impedance are all
% MISSING (see test_line_data), so the feeders are zero impedance and all three
% nodes solve to the same voltage. Both halves of that must be true - three
% distinct bus names in the register, and nothing pretending they are apart.
busNames = {Ld(inm).Bus};
T = T.eq(numel(unique(busNames)), 3, ...
    'the three loads sit on three DISTINCT register buses, so the split is reportable');
for want = {'B6_6', 'B6_6_WI1', 'B6_6_WI2'}
    T = T.chk(any(strcmp(busNames, want{1})), sprintf( ...
        'one modelled load sits on %s', want{1}));
end
B = ashuganj_buses();
for k = inm
    b = B(strcmp({B.Name}, Ld(k).Bus));
    T = T.eq(numel(b), 1, sprintf('%s bus %s exists in the bus register', Ld(k).Label, Ld(k).Bus));
    T = T.eq(b.Vnom_V, 6600, sprintf( ...
        '%s bus %s is a 6.6 kV node', Ld(k).Label, Ld(k).Bus));
end
L = ashuganj_lines();
for nm = {'FDR_WI1', 'FDR_WI2'}
    j = find(strcmp({L.Name}, nm{1}), 1);
    T = T.chk(~L(j).Model_included, sprintf( ...
        ['%s is zero impedance, so its node is NOT electrically separate - the ' ...
         'split is honest about motor grouping, not about feeder voltage drop'], nm{1}));
end

% ---- the 400 V board is excluded, not guessed ---------------------------
k04 = find(strcmp({Ld.Bus}, 'B0_4'));
T = T.chk(~isempty(k04), 'the 400 V board appears in the register');
if ~isempty(k04)
    T = T.isnan(Ld(k04(1)).P_MW,   '400 V board P stays MISSING (NaN), not invented');
    T = T.isnan(Ld(k04(1)).Q_MVAr, '400 V board Q stays MISSING (NaN), not invented');
    T = T.chk(~Ld(k04(1)).Model_included, '400 V board excluded from the load flow');
    T = T.eq(Ld(k04(1)).Vnom_V, 400, '400 V board is FOUR HUNDRED VOLTS');
end

[np, nf] = T.done();
end
