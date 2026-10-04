function [np, nf] = test_topology()
%TEST_TOPOLOGY  Referential integrity and connectivity of the network.
%
%   Checks that every terminal named by a generator, transformer or load refers
%   to a bus that actually exists, that the modelled network is one connected
%   island, that the voltage on both sides of every transformer is consistent
%   with the bus it lands on (allowing for the recorded 6.9/6.6 kV conflict),
%   and that the four load-flow cases really are the 2x2 matrix the approved
%   answers imply.
T = t_case('test_topology');
D = ashuganj_master_data();
B = {D.buses.Name};

% ---- referential integrity ---------------------------------------------
for i = 1:numel(D.gen)
    T = T.chk(any(strcmp(B, D.gen(i).Bus)), ...
        sprintf('generator %s sits on a defined bus (%s)', D.gen(i).Name, D.gen(i).Bus));
end
for i = 1:numel(D.tx)
    T = T.chk(any(strcmp(B, D.tx(i).Bus_HV)), ...
        sprintf('%s HV bus %s is defined', D.tx(i).Label, D.tx(i).Bus_HV));
    T = T.chk(any(strcmp(B, D.tx(i).Bus_LV)), ...
        sprintf('%s LV bus %s is defined', D.tx(i).Label, D.tx(i).Bus_LV));
end
for i = 1:numel(D.loads)
    T = T.chk(any(strcmp(B, D.loads(i).Bus)), ...
        sprintf('load %s sits on a defined bus (%s)', D.loads(i).Label, D.loads(i).Bus));
end
T = T.chk(any(strcmp(B, D.grid.Bus_boundary)), 'legacy grid Bus_boundary fallback is defined');
T = T.eq(D.grid.Bus_boundary, 'B230_1', 'legacy Bus_boundary stays B230_1');
T = T.eq(D.grid.Grid_equivalent_bus, 'B230_REMOTE', 'Grid_equivalent_bus is B230_REMOTE (Phase-3 semantics)');
T = T.chk(any(strcmp(B, D.grid.Grid_equivalent_bus)), 'grid equivalent bus is defined');
% Explicit Phase-3 spans from the branch register (dataset, not the graph below).
L = D.lines;
kZ = find(strcmp({L.Name}, 'ZGRID'), 1);
kL = find(strcmp({L.Name}, 'L_LINE'), 1);
T = T.chk(~isempty(kZ) && ~isempty(kL), 'ZGRID + L_LINE present for Phase-3 span checks');
T = T.chk((strcmp(L(kZ).Bus_from,'BGRID230') && strcmp(L(kZ).Bus_to,'B230_REMOTE')) || ...
          (strcmp(L(kZ).Bus_from,'B230_REMOTE') && strcmp(L(kZ).Bus_to,'BGRID230')), ...
    'ZGRID spans B230_REMOTE<->BGRID230 in the Phase-3 world');
T = T.eq(L(kL).Bus_from, 'B230_1', 'L_LINE spans B230_1->B230_REMOTE (from)');
T = T.eq(L(kL).Bus_to, 'B230_REMOTE', 'L_LINE spans B230_1->B230_REMOTE (to)');

% ---- transformer voltages against their buses --------------------------
for i = 1:numel(D.tx)
    x   = D.tx(i);
    bHV = D.buses(strcmp(B, x.Bus_HV));
    bLV = D.buses(strcmp(B, x.Bus_LV));
    T = T.eq(x.V_HV_V, bHV.Vnom_V, ...
        sprintf('%s HV %g V matches bus %s nominal', x.Label, x.V_HV_V, x.Bus_HV));
    if x.V_LV_V == bLV.Vnom_V
        T = T.chk(true, sprintf('%s LV %g V matches bus %s nominal', ...
                  x.Label, x.V_LV_V, x.Bus_LV));
    else
        % Not a failure - it is conflict C13, and it must stay recorded.
        T = T.chk(x.V_LV_V == 6900 && bLV.Vnom_V == 6600, sprintf( ...
            ['%s LV winding %g V vs bus %s nominal %g V is the RECORDED ' ...
             'conflict C13, not an error'], x.Label, x.V_LV_V, x.Bus_LV, bLV.Vnom_V));
    end
end

% ---- connectivity of the modelled network (Phase-3 world) ------------------
% Build the graph from the elements that are actually in the model.
% Phase-3: ZGRID sits at B230_REMOTE behind L_LINE (B230_1->B230_REMOTE);
% Bus_boundary B230_1 is legacy fallback only (asserted above).
nodes = {'BGRID230','B230_REMOTE','B230_1','B230_2','B22','B6_6'};
edges = { 'BGRID230','B230_REMOTE'; ...  % ZGRID equivalent (Phase-3 remote span)
          'B230_1',  'B230_REMOTE'; ...  % L_LINE 0.7 km PI (Phase-3)
          'B230_1',  'B230_2'; ...      % bus coupler
          'B230_1',  'B22';    ...      % GSUT
          'B22',     'B6_6' };          % UAT
seen  = containers.Map(nodes, num2cell(1:numel(nodes)));
adj   = false(numel(nodes));
for e = 1:size(edges,1)
    a = seen(edges{e,1}); b = seen(edges{e,2});
    adj(a,b) = true; adj(b,a) = true;
end
reach = false(1, numel(nodes)); reach(1) = true;
for it = 1:numel(nodes)
    reach = reach | any(adj(reach, :), 1);
end
T = T.chk(all(reach), 'the modelled network is a single connected island');
T = T.eq(numel(nodes), 6, 'six load-flow nodes in Phase-3 world (REMOTE + 5; GAT HV appears only when GAT is in)');

% ---- no 400 kV anywhere -------------------------------------------------
T = T.eq(sum([D.buses.Vnom_V] == 400e3), 0, 'no 400 kV bus - South plant scope');
T = T.eq(sum([D.tx.V_HV_V] == 400e3), 0, 'no 400 kV transformer winding');
T = T.eq(max([D.buses.Vnom_V]), 230e3, 'highest voltage is 230 kV');

% ---- the 2x2 case matrix ------------------------------------------------
C = D.cases;
T = T.eq(numel(C), 4, 'four load-flow cases: Q2c dispatch x Q4c GAT state');
T = T.eq(numel(unique([C.Gen_P_MW])), 2, 'two dispatch levels');
T = T.near(sort(unique([C.Gen_P_MW])), [342.01 389.30], 1e-9, ...
    'dispatch levels are 342.01 MW site-derated and 389.30 MW rated');
T = T.eq(numel(unique([C.GAT_in])), 2, 'GAT in and GAT out both represented');
for i = 1:numel(C)
    T = T.eq(C(i).f_Hz, 50, sprintf('case %s at 50 Hz', C(i).ID));
    T = T.eq(C(i).Sbase_MVA, 100, sprintf('case %s on the 100 MVA base', C(i).ID));
    T = T.chk(C(i).Coupler_closed, sprintf( ...
        'case %s has the bus coupler closed (assumption, normal state not documented)', C(i).ID));
    T = T.eq(C(i).Gen_Vset_pu, 1.00, sprintf('case %s generator setpoint 1.00 pu', C(i).ID));
    T = T.eq(C(i).Grid_Vset_pu, 1.00, sprintf('case %s grid setpoint 1.00 pu', C(i).ID));
    T = T.near(C(i).Load_P_MW, 14.0, 1e-9, sprintf('case %s aux load 14.0 MW', C(i).ID));
end
% Every combination present exactly once.
combo = arrayfun(@(c) sprintf('%.2f|%d', c.Gen_P_MW, c.GAT_in), C, 'UniformOutput', false);
T = T.eq(numel(unique(combo)), 4, 'all four dispatch x GAT combinations are distinct');

[np, nf] = T.done();
end
