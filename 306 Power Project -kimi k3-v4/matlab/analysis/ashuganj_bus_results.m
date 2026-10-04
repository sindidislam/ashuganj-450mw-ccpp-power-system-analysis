function [Bres, resid] = ashuganj_bus_results(LF, D, C, R, Z)
%ASHUGANJ_BUS_RESULTS  Bus table plus the KCL cross-check on the branch flows.
%
%   [Bres, resid] = ASHUGANJ_BUS_RESULTS(LF, D, C, R, Z) builds the reporting bus
%   table from the solution LF and, if the branch-flow struct R is supplied,
%   returns the per-bus power-balance residual in MVA. Z is info.zones from the
%   build that produced LF, needed to identify the buses by block handle.
%
%   THE RESIDUAL IS THE POINT
%   -------------------------
%   The branch flows in R are computed from the solved bus voltages and the
%   documented impedances, entirely outside the solver. At every bus the sum of
%   those branch flows must equal the injection the solver itself reports. If it
%   does, then two independent calculations agree on which network was solved -
%   the impedances that went in are the impedances that came out, the
%   vector-group phase shifts have the right sign, and the off-nominal 6.9/6.6 kV
%   ratio is being handled the same way in both places. If it does not, one of
%   those is wrong, and the residual says at which bus.
%
%   DUAL PER-UNIT REPORTING AT THE MV BUS
%   -------------------------------------
%   The 6.6 kV bus is reported twice: against the 6600 V system nominal and
%   against the 6900 V UAT/GAT secondary winding voltage. Conflict C13 is not
%   resolvable from the sources, so both denominators are quoted. Against 6600 V
%   the bus sits slightly ABOVE 1.0 pu; against 6900 V the same node is about
%   0.958 pu. Quoting only one of those would be a claim the sources do not
%   support.
%
%   MERGED NODES: EIGHT REGISTER BUSES, FIVE SOLVED NODES
%   -----------------------------------------------------
%   A zero-impedance connection is not a branch to the solver, it is an identity,
%   so several register buses share one solved node. Every register bus still gets
%   a row - omitting one would look like an oversight - but only the FIRST bus to
%   claim a node carries the solver's injection. The rest report NaN and name the
%   bus they merged into, in the Merged_into column.
%
%   That is not cosmetic. The three 6.6 kV nodes are one node, so the solver's
%   injection there is the WHOLE 14 MW auxiliary load. Copying it onto all three
%   rows would make the table total 42 MW of auxiliary load in a plant that has
%   14 - a wrong number that looks entirely plausible, which is the worst kind.
%
%   Each bus's own share is still reported, in the separate columns
%   P_load_alloc_MW and Q_load_alloc_MVAr. Those are DATASET INPUT (the Q6B
%   allocation, an ENGINEERING_ASSUMPTION), not solver output, and they are kept
%   in their own columns so the two can never be confused or added together.
%
%   SIGN CONVENTION
%   ---------------
%   Injections are generation-positive: P > 0 means power entering the network at
%   that bus. Branch Sf is the flow leaving the From bus into the branch; branch
%   St is the flow arriving at the To bus. So
%       injection(k) = sum(Sf | From == k) - sum(St | To == k).
%   P_load_alloc_MW uses the opposite, LOAD-positive convention, because it is a
%   demand and not an injection; the column name says which it is.

if nargin < 4, R = []; end
narginchk(5, 5);
Sb   = D.base.Sbase_MVA;
node = ashuganj_bus_map(LF, D, Z);

% ---- guard: is Sbus per unit, as this function assumes? ----------------
% If a release ever reports Sbus in MW instead, every number below would be off
% by a factor of 100 while still looking plausible. The generator injection is
% known exactly from the case definition, so it is used as the check.
kPV = node.B22;
if abs(real(LF.bus(kPV).Sbus)*Sb - C.Gen_P_MW) > 1e-3
    error('ashuganj_bus_results:sbusUnits', ...
        ['Generator bus injection is %.6g on the reported scale; case %s ' ...
         'dispatches %.2f MW. LF.bus.Sbus is not per unit on the %g MVA base ' ...
         'as assumed, so no result below can be trusted.'], ...
        real(LF.bus(kPV).Sbus), C.ID, C.Gen_P_MW, Sb);
end

% ---- which register bus maps to which solved node -----------------------
% Several register buses can map to the SAME solved node, because a
% zero-impedance connection is not a branch to the solver - it is an identity.
% Two of those happen here and both are documented consequences of missing data
% rather than modelling shortcuts:
%
%   B6_6, B6_6_WI1, B6_6_WI2   the 6.6 kV feeder impedances are MISSING, so the
%                              three load nodes are one electrical node
%   B230_1, B230_2             the bus coupler is CLOSED (assumption Q9a)
%
% Only the FIRST bus to claim a node carries the solver's injection. The others
% get NaN and a note saying which node they merged into. Repeating the merged
% node's injection on every member would be a serious misreport: the 6.6 kV
% group would then show three rows of -14 MW and total 42 MW of auxiliary load
% in a plant that has 14.
seen  = containers.Map('KeyType', 'double', 'ValueType', 'char');
names = fieldnames(node);
Bres  = struct([]);
for i = 1:numel(names)
    nm = names{i};
    k  = node.(nm);
    reg = D.buses(strcmp({D.buses.Name}, nm));
    if isempty(reg)
        reg = struct('Name', nm, 'Label', nm, 'Vnom_V', LF.bus(k).vbase, 'Zone', '');
    end
    merged = '';
    if isKey(seen, k), merged = seen(k); else, seen(k) = nm; end

    j = numel(Bres) + 1;
    Bres(j).Name      = nm;
    Bres(j).Label     = reg.Label;
    Bres(j).LF_index  = k;
    Bres(j).Merged_into = merged;
    Bres(j).Type      = LF.bus(k).busType;
    Bres(j).Vnom_V    = reg.Vnom_V;
    Bres(j).Vbase_V   = LF.bus(k).vbase;
    Bres(j).V_pu      = abs(LF.bus(k).Vbus);
    Bres(j).V_kV      = abs(LF.bus(k).Vbus) * LF.bus(k).vbase / 1000;
    Bres(j).V_pu_nom  = Bres(j).V_kV*1000 / reg.Vnom_V;
    Bres(j).Ang_deg   = rad2deg(angle(LF.bus(k).Vbus));
    % Solver output. NaN on a merged member, because the solver cannot attribute
    % an injection to one half of a single node - not because the value is
    % unknown, but because the question has no answer in this network.
    if isempty(merged)
        Bres(j).P_inj_MW   = real(LF.bus(k).Sbus) * Sb;
        Bres(j).Q_inj_MVAr = imag(LF.bus(k).Sbus) * Sb;
    else
        Bres(j).P_inj_MW   = NaN;
        Bres(j).Q_inj_MVAr = NaN;
    end
    % Dataset input, kept in separate columns so solver output and allocated
    % input can never be confused. Positive = load drawn at this bus.
    Bres(j).P_load_alloc_MW   = load_at(D, nm, 'P_MW');
    Bres(j).Q_load_alloc_MVAr = load_at(D, nm, 'Q_MVAr');
    Bres(j).Alt_base_V   = NaN;
    Bres(j).V_pu_alt     = NaN;
    Bres(j).Note         = '';

    if ~isempty(merged)
        Bres(j).Note = sprintf(['SAME ELECTRICAL NODE as %s - reported for ' ...
            'completeness, not solved separately. The solver sees only the ' ...
            'group, so P_inj/Q_inj are NaN rather than repeated: repeating ' ...
            'them would make the group total look like a per-bus figure.'], merged);
        if ~isnan(Bres(j).P_load_alloc_MW)
            Bres(j).Note = sprintf(['%s Its own allocated share is %.4f MW / ' ...
                '%.4f MVAr, in the P_load_alloc columns - an ' ...
                'ENGINEERING_ASSUMPTION (the split between the groups), not a ' ...
                'solved quantity.'], ...
                Bres(j).Note, Bres(j).P_load_alloc_MW, Bres(j).Q_load_alloc_MVAr);
        end
    end
    if strcmp(nm, 'B6_6')
        Bres(j).Alt_base_V = 6900;
        Bres(j).V_pu_alt   = Bres(j).V_kV*1000 / 6900;
        Bres(j).Note = sprintf(['CONFLICT C13: %.5f pu against the 6600 V system ' ...
            'nominal, %.5f pu against the 6900 V UAT secondary winding. Both ' ...
            'reported; the sources do not settle which is the intended base. ' ...
            'P_inj here is the injection at the MERGED 6.6 kV node, i.e. the ' ...
            'whole auxiliary load, not this bus''s %.4f MW allocated share.'], ...
            Bres(j).V_pu_nom, Bres(j).V_pu_alt, Bres(j).P_load_alloc_MW);
    end
    if strcmp(nm, 'B230_1') && isempty(merged) && node.B230_2 == node.B230_1
        % B230_1 precedes B230_2 in the register, so BUS 1 is the representative
        % of the merged pair and BUS 2 gets the merged-member row above.
        Bres(j).Label = '230 kV BUS 1 + BUS 2 (coupler closed)';
        Bres(j).Note  = ['Bus coupler CLOSED (assumption): the load flow merges ' ...
            '230 kV BUS 1 and BUS 2 into one node, so they cannot be reported ' ...
            'separately and the coupler flow is not observable.'];
    end
    if strcmp(nm, 'GAT_HV') && ~C.GAT_in
        Bres(j).Note = ['GAT HV terminal with bay 10BAY20 OPEN. Not a plant ' ...
            'busbar: it is the transformer terminal, back-energised through ' ...
            'the GAT from the 6.6 kV side. Its voltage is the turns ratio, ' ...
            'not a system voltage.'];
    end
end

% ---- KCL residual -------------------------------------------------------
resid = [];
if ~isempty(R)
    resid = struct([]);
    for j = 1:numel(Bres)
        % Merged members are skipped, not given a NaN residual. They would each
        % reproduce the representative node's residual exactly, and a NaN would
        % pass silently through any max() based check downstream.
        if ~isempty(Bres(j).Merged_into), continue, end
        k  = Bres(j).LF_index;
        Sn = 0;
        for b = 1:numel(R)
            if isnan(R(b).P_from_MW), continue, end     % unobservable branch
            if isfield(node, R(b).From) && node.(R(b).From) == k
                Sn = Sn + (R(b).P_from_MW + 1i*R(b).Q_from_MVAr);
            end
            if isfield(node, R(b).To) && node.(R(b).To) == k
                Sn = Sn - (R(b).P_to_MW + 1i*R(b).Q_to_MVAr);
            end
        end
        inj = Bres(j).P_inj_MW + 1i*Bres(j).Q_inj_MVAr;
        n = numel(resid) + 1;
        resid(n).Name        = Bres(j).Name;
        resid(n).Inj_MVA     = inj;
        resid(n).Branches_MVA= Sn;
        resid(n).dP_MW       = real(inj - Sn);
        resid(n).dQ_MVAr     = imag(inj - Sn);
        resid(n).Residual_MVA= abs(inj - Sn);
    end
end
end

% =====================================================================
function v = load_at(D, busName, field)
%LOAD_AT  Allocated load at one bus from the dataset, or NaN if none.
%   Dataset input, never solver output. Loads excluded from the model (the
%   400 V board, whose demand is MISSING) are not counted.
v = NaN;
if ~isfield(D, 'loads') || isempty(D.loads), return, end
m = strcmp({D.loads.Bus}, busName) & [D.loads.Model_included];
if ~any(m), return, end
v = sum([D.loads(m).(field)]);
end
