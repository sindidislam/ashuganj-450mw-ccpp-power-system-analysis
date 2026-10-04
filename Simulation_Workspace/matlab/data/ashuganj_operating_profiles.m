function P = ashuganj_operating_profiles(D)
%ASHUGANJ_OPERATING_PROFILES Authoritative operating cases for Phase 2.
%   P = ashuganj_operating_profiles(D) creates the 6 canonical profiles
%   and 4 historical aliases from master data or underlying providers.
%
%   CANONICAL PROFILES:
%   1. LF360_GAT_OUT : Primary 360 MW active-power capacity, GAT open
%   2. LF360_GAT_IN  : Primary 360 MW active-power capacity, GAT closed
%   3. LF342_GAT_OUT : Qualified owner questionnaire 342.01 MW, GAT open
%   4. LF342_GAT_IN  : Qualified owner questionnaire 342.01 MW, GAT closed
%   5. LF389P30_GAT_OUT : Historical OEM PF-reference 389.30 MW, GAT open (approved_exception)
%   6. LF389P30_GAT_IN  : Historical OEM PF-reference 389.30 MW, GAT closed (approved_exception)
%
%   HISTORICAL ALIASES (retained for backward compatibility):
%   - LF1 : Alias for LF389P30_GAT_OUT
%   - LF2 : Alias for LF389P30_GAT_IN
%   - LF3 : Alias for LF342_GAT_OUT
%   - LF4 : Alias for LF342_GAT_IN

if nargin < 1 || isempty(D)
    G = ashuganj_generators();
    grid = ashuganj_grid();
    loads = ashuganj_loads();
    base_S = 100;
    base_f = 50;
else
    G = D.gen;
    grid = D.grid;
    loads = D.loads;
    base_S = D.base.Sbase_MVA;
    base_f = D.base.f_Hz;
end

% 1. Canonical Operating Profiles (6 profiles)
c_defs = {
    'LF360_GAT_OUT',    'Primary capacity 360 MW GAT out',      360.00, false, 'radial', 'Primary',               'PRIMARY_VERIFIED',          false, 'Primary capacity case (GAT open)';
    'LF360_GAT_IN',     'Primary capacity 360 MW GAT in',       360.00, true,  'looped', 'Primary',               'PRIMARY_VERIFIED',          false, 'Primary capacity case (GAT in service)';
    'LF342_GAT_OUT',    'Qualified owner scenario 342.01 MW GAT out', 342.01, false, 'radial', 'Derated',         'PRIMARY_SOURCE_QUALIFIED',  false, 'Qualified owner site derated scenario (GAT open)';
    'LF342_GAT_IN',     'Qualified owner scenario 342.01 MW GAT in',  342.01, true,  'looped', 'Derated',         'PRIMARY_SOURCE_QUALIFIED',  false, 'Qualified owner site derated scenario (GAT in service)';
    'LF389P30_GAT_OUT', 'Historical reference 389.30 MW GAT out', 389.30, false, 'radial', 'Historical_Reference', 'HISTORICAL',               true,  'Historical OEM PF-reference case (GAT open)';
    'LF389P30_GAT_IN',  'Historical reference 389.30 MW GAT in',  389.30, true,  'looped', 'Historical_Reference', 'HISTORICAL',               true,  'Historical OEM PF-reference case (GAT in service)';
};

canonical = struct([]);
for k = 1:size(c_defs, 1)
    c = build_case_record(c_defs{k,1}, c_defs{k,2}, c_defs{k,3}, c_defs{k,4}, ...
        c_defs{k,5}, c_defs{k,6}, c_defs{k,7}, c_defs{k,8}, c_defs{k,9}, ...
        G, grid, loads, base_S, base_f);
    validate_operating_profile(c);
    canonical = [canonical, c]; %#ok<AGROW>
end

% 2. Historical Aliases (4 profiles for backward compatibility)
a_defs = {
    'LF1', 'Rated dispatch GAT out',    389.30, false, 'radial', 'Rated',   'HISTORICAL',               true,  'Historical alias LF1';
    'LF2', 'Rated dispatch GAT in',     389.30, true,  'looped', 'Rated',   'HISTORICAL',               true,  'Historical alias LF2';
    'LF3', 'Derated dispatch GAT out',  342.01, false, 'radial', 'Derated', 'PRIMARY_SOURCE_QUALIFIED',  false, 'Historical alias LF3';
    'LF4', 'Derated dispatch GAT in',   342.01, true,  'looped', 'Derated', 'PRIMARY_SOURCE_QUALIFIED',  false, 'Historical alias LF4';
};

aliases = struct([]);
for k = 1:size(a_defs, 1)
    a = build_case_record(a_defs{k,1}, a_defs{k,2}, a_defs{k,3}, a_defs{k,4}, ...
        a_defs{k,5}, a_defs{k,6}, a_defs{k,7}, a_defs{k,8}, a_defs{k,9}, ...
        G, grid, loads, base_S, base_f);
    validate_operating_profile(a);
    aliases = [aliases, a]; %#ok<AGROW>
end

% 3. Package output
P = struct();
P.canonical = canonical;
P.aliases = aliases;
P.primary = canonical(1:2);
P.qualified = canonical(3:4);
P.historical = canonical(5:6);
P.builder_cases = [canonical, aliases];
end

function C = build_case_record(id, name, p, gat, topology, scenario, status, approved_exc, purpose, G, grid, loads, base_S, base_f)
C = struct();
C.ID = id;
C.case_id = id;
C.Name = name;
C.Gen_P_MW = p;
C.P_dispatch = p;
C.P_dispatch_MW = p;
C.P_capacity = G(1).P_capacity_MW;
C.P_capacity_MW = G(1).P_capacity_MW;
C.GAT_in = gat;
if gat
    C.GAT_status = 'IN';
else
    C.GAT_status = 'OUT';
end
C.UAT_status = 'IN';
C.coupler_status = 'CLOSED';
C.Coupler_closed = true;
C.Topology = topology;
C.topology = topology;
C.Gen_scenario = scenario;
C.status = status;
C.approved_exception = approved_exc;
C.Purpose = purpose;

% Finite physical limits from capability curve
[qmin, qmax] = generatorCapability(p, G(1).capabilityCurve);
C.Gen_Q_MVAr_limit = [qmin, qmax];
C.solver_Q_limits = [-inf, inf]; % Preserves unconstrained solver setting per freeze rule

C.Gen_Vset_pu = G(1).Vset_pu;
C.Grid_Vset_pu = grid.Vset_pu;
C.voltage_setpoints = struct('Gen_Vset_pu', G(1).Vset_pu, 'Grid_Vset_pu', grid.Vset_pu);

inc = [loads.Model_included];
p_aux = sum([loads(inc).P_MW]);
q_aux = sum([loads(inc).Q_MVAr]);
C.Load_P_MW = p_aux;
C.Load_Q_MVAr = q_aux;
C.auxiliary_load = struct('P_MW', p_aux, 'Q_MVAr', q_aux, 'allocation_status', 'ENGINEERING_ASSUMPTION');

C.grid_definition = struct('Vset_pu', grid.Vset_pu, ...
    'Isc_kA', grid.Isc_kA, ...
    'Ssc_MVA', grid.Ssc_MVA, ...
    'X_ohm', grid.X_ohm, ...
    'status', grid.X_Status);

C.Sbase_MVA = base_S;
C.f_Hz = base_f;
C.Snom_MVA = G(1).Snom_MVA;

if isfield(G(1), 'Name')
    C.generator_id = G(1).Name;
elseif isfield(G(1), 'Generator_ID')
    C.generator_id = G(1).Generator_ID;
else
    C.generator_id = 'G1';
end

if isfield(G(1), 'Dataset_ID')
    C.dataset_id = G(1).Dataset_ID;
else
    C.dataset_id = 'GEN-R31-WORKBOOK-ROW3';
end

C.assumptions = struct('auxiliary_allocation', 'ENGINEERING_ASSUMPTION', ...
    'grid_impedance', 'SOURCE_QUALIFIED_ESTIMATE', ...
    'voltage_setpoints', G(1).Vset_Status);
C.provenance = struct('source', G(1).P_capacity_Source, ...
    'status', status, ...
    'approved_exception', approved_exc);
end
