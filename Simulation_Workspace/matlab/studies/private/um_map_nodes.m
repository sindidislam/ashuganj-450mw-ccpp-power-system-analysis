function M = um_map_nodes(N, BUS, caseID)
%UM_MAP_NODES  Match the report's '*n*' labels to real bus names.
%
%   M = UM_MAP_NODES(N, BUS, CASEID) takes the parsed report nodes N from UM_REP
%   and the bus_results table BUS, and returns one row per report node with the
%   bus it can be identified as - or an explicit statement that it cannot.
%
%   HOW THE MATCH IS MADE
%   ---------------------
%   Three discriminators, all printed by the tool itself:
%     base voltage    230 kV / 22 kV / 6.6 kV
%     bus type        the report marks the swing bus; a bus with generation on it
%                     and no swing marker is the PV bus
%     solved voltage  to the three decimals the report prints
%
%   The mapping is DERIVED here, every time the page is generated, rather than
%   remembered. If the network changes the solver renumbers the nodes, and a
%   remembered table would then be quietly wrong - which is the one failure this
%   whole document exists to prevent.
%
%   WHEN IT CANNOT DECIDE
%   ---------------------
%   With the station auxiliary bay closed, the transformer's HV terminal and the
%   busbar sit a fraction of a volt apart, so at three decimals they print the
%   same number and the report cannot distinguish them. That is reported as
%   ambiguous, with the candidates named. It is not guessed.

M = struct('id', {}, 'V_pu_rep', {}, 'base_kV', {}, 'ang_deg', {}, ...
           'swing', {}, 'Pgen_MW', {}, 'Name', {}, 'Label', {}, 'V_pu_csv', {}, ...
           'Status', {}, 'Why', {});

keep = strcmp(BUS.Case, caseID) & cellfun(@(s) isempty(strtrim(s)), BUS.Merged_into);
rows = BUS(keep, :);

for k = 1:numel(N)
    n = N(k);
    ok = true(height(rows), 1);

    % base voltage, within 1 % of the printed value
    ok = ok & abs(rows.Vbase_V/1000 - n.base_kV) <= 0.01*n.base_kV;

    % bus type, from the markers the report itself prints
    isSwing = strcmpi(rows.Type, 'swing');
    isPV    = strcmpi(rows.Type, 'PV');
    if n.swing
        ok = ok & isSwing;
    else
        ok = ok & ~isSwing;
        if ~isnan(n.Pgen_MW) && abs(n.Pgen_MW) > 0.005
            ok = ok & isPV;            % generation, no swing marker -> PV bus
        else
            ok = ok & ~isPV;           % a PV bus always carries generation
        end
    end

    % solved voltage, to the three decimals the report prints
    ok = ok & abs(rows.V_pu - n.V_pu) <= 5.1e-4;

    j = numel(M) + 1;
    M(j).id       = n.id;
    M(j).V_pu_rep = n.V_pu;
    M(j).base_kV  = n.base_kV;
    M(j).ang_deg  = n.ang_deg;
    M(j).swing    = n.swing;
    M(j).Pgen_MW  = n.Pgen_MW;   % carried through: the caller labels the bus type
    M(j).Name     = '';
    M(j).Label    = '';
    M(j).V_pu_csv = NaN;

    hit = find(ok);
    if numel(hit) == 1
        M(j).Name     = rows.Bus{hit};
        M(j).Label    = rows.Label{hit};
        M(j).V_pu_csv = rows.V_pu(hit);
        M(j).Status   = 'matched';
        M(j).Why      = sprintf('%.0f kV, %s, %.3f pu', n.base_kV, rows.Type{hit}, n.V_pu);
    elseif isempty(hit)
        M(j).Status = 'none';
        M(j).Why    = sprintf(['no bus in bus_results.csv matches %.0f kV at ' ...
            '%.3f pu &mdash; the report and the tables are out of step, so ' ...
            'regenerate both'], n.base_kV, n.V_pu);
    else
        M(j).Status = 'ambiguous';
        M(j).Why    = sprintf(['%s all print %.3f pu on the same base, so the ' ...
            'report cannot separate them'], strjoin(rows.Bus(hit)', ' and '), n.V_pu);
    end
end
end
