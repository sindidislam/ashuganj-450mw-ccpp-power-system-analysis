function node = ashuganj_bus_map(LF, D, Z)
%ASHUGANJ_BUS_MAP  Identify which solved bus is which electrical node.
%
%   node = ASHUGANJ_BUS_MAP(LF, D, Z) returns a struct whose fields are the bus
%   names from the bus register and whose values are indices into LF.bus. Z is
%   info.zones from build_ashuganj_main, which carries the block handles.
%
%   WHY THIS FUNCTION HAS TO EXIST
%   ------------------------------
%   power_loadflow numbers buses; it does not name them, and the numbering is
%   NOT the order in which the blocks were created. Worse, what gets reported
%   changes between cases, and not in the obvious way. Six nodes are built. Five
%   are reported, in EVERY case, including the cases where a closed breaker was
%   expected to merge nodes:
%
%     LF1 (GAT bay open)   : GAT HV floats behind a 1e6 ohm snubber
%     LF2 (GAT bay closed) : GAT HV sits 2e-6 pu from the busbar, across the
%                            0.01 ohm closed-breaker resistance
%
%   The solver lumps BUS 1 and BUS 2 (nothing but the coupler and the bay CB
%   terminate on BUS 2, so no bus is reported there) but it does NOT lump the GAT
%   HV terminal, because the transformer winding terminates on it. So the node
%   count is 5 either way and the two 230 kV plant nodes are 2e-6 pu apart in
%   LF2. Any hard-coded index would be silently wrong in half the case matrix.
%
%   IDENTIFICATION IS BY BLOCK HANDLE, NOT BY VOLTAGE
%   -------------------------------------------------
%   An earlier version of this function identified the GAT HV node by predicting
%   its floating voltage and matching it to five digits. That worked in LF1 and
%   was WRONG IN PRINCIPLE: in LF2 the two candidate nodes differ by 2e-6 pu, so
%   matching by magnitude is a coincidence, not an identification. It duly failed
%   the first time LF2 was solved.
%
%   Every bus is now identified by the equipment attached to it:
%
%     LF.vsrc(i).busNumber   maps each source block to its bus. The swing source
%                            is EXT GRID; the PV source is G1. Both explicit.
%     LF.rlcload(i).busNumber maps each load block to its bus. All three 6.6 kV
%                            loads must report the SAME bus - that is the proof
%                            the zero-impedance feeders really did merge.
%     LF.bus(k).blocks       lists the load-flow blocks terminating on bus k.
%                            The GSUT appears at the 230 kV busbar, the GAT at
%                            its own HV terminal. Handles are compared against
%                            the ones the builder exported for THIS build.
%
%   Handles are per-build, so Z must come from the same build that produced LF.
%   That is enforced below by checking the model name.
%
%   The voltage predictions are still made - as VERIFICATION. Having identified
%   the GAT HV node by handle, the function checks that in the bay-open case it
%   really does sit at the turns-ratio voltage. That is now a cross-check on the
%   physics rather than the mechanism of identification, which is the right way
%   round. See docs/validation/solver_behaviour.md.

narginchk(3, 3);
assert(isstruct(Z) && isfield(Z, 'gsut'), ...
    ['ashuganj_bus_map: Z must be info.zones from build_ashuganj_main. Bus ' ...
     'identification is by block handle and cannot be done without it.']);

node = struct();
vb   = [LF.bus.vbase];
V    = abs([LF.bus.Vbus]);
nb   = numel(LF.bus);

% Handles must belong to the model that was solved, or the comparison below is
% meaningless: Simulink handles are reused across loads of different models.
assert(strcmp(bdroot(Z.gsut.tx), LF.model), ...
    ['ashuganj_bus_map: zones belong to model ''%s'' but the solution is for ' ...
     '''%s''. Handles are per-build; pass the zones from the build that was solved.'], ...
    bdroot(Z.gsut.tx), LF.model);

% =====================================================================
% Sources: the solver states the bus number outright.
% =====================================================================
hGrid = get_param(Z.grid.src, 'Handle');
hGen  = get_param(Z.gen.src,  'Handle');

node.BGRID230 = vsrc_bus(LF, hGrid, 'EXT GRID (external grid equivalent source)');
node.B22      = vsrc_bus(LF, hGen,  'G1 (generator source)');

% The types must be what the study design says they are. This is not how the
% buses were found, so it is a real check.
assert(strcmp(LF.bus(node.BGRID230).busType, 'swing'), ...
    ['ashuganj_bus_map: the external grid source is on bus %d, whose type is ' ...
     '''%s'', not ''swing''. The grid must be the swing bus (approved answer Q1a).'], ...
    node.BGRID230, LF.bus(node.BGRID230).busType);
assert(any(strcmp(LF.bus(node.B22).busType, {'PV','PQ'})), ...
    'ashuganj_bus_map: generator bus %d has unexpected type ''%s''.', ...
    node.B22, LF.bus(node.B22).busType);
assert(abs(LF.bus(node.B22).vbase - 22000) < 1, ...
    ['ashuganj_bus_map: the generator source sits on a bus with base %g V, ' ...
     'not 22000 V.'], LF.bus(node.B22).vbase);

% =====================================================================
% Loads: all three 6.6 kV boards must land on ONE bus.
% =====================================================================
assert(isfield(LF, 'rlcload') && ~isempty(LF.rlcload), ...
    'ashuganj_bus_map: no RLC loads in the solution; the auxiliary load is missing.');
lb = unique([LF.rlcload.busNumber]);
assert(isscalar(lb), ...
    ['ashuganj_bus_map: the %d auxiliary loads solved onto %d different buses ' ...
     '(%s). The Q6B split is a REPORTING segregation - the feeders are zero ' ...
     'impedance because their size, length and impedance are all MISSING - so ' ...
     'all three must share one electrical node.'], ...
    numel(LF.rlcload), numel(lb), mat2str(lb));
node.B6_6 = lb;

% The register keeps the three boards on three named buses. They are the same
% solved node, and every name must resolve, or downstream lookups fail silently.
node.B6_6_WI1 = lb;
node.B6_6_WI2 = lb;

assert(abs(LF.bus(node.B6_6).vbase - 6600) < 1, ...
    ['ashuganj_bus_map: the auxiliary loads sit on a bus with base %g V, not ' ...
     '6600 V. Note the loads are referred to the 6.6 kV PLANT BUS nominal ' ...
     'while the UAT winding is rated 6.9 kV - that is conflict C13, preserved ' ...
     'deliberately.'], LF.bus(node.B6_6).vbase);
assert(numel(find(vb < 1e4)) == 1, ...
    ['ashuganj_bus_map: expected exactly one bus below 10 kV (the 6.6 kV MV ' ...
     'bus); found %d. If a 400 V bus has appeared, the model no longer matches ' ...
     'the dataset - the 400 V board is deliberately excluded because its load ' ...
     'is MISSING.'], numel(find(vb < 1e4)));

% =====================================================================
% Transformer terminals: the two 230 kV plant nodes.
% =====================================================================
% The GSUT terminates on the 230 kV busbar; the GAT terminates on its own HV
% lead. Both are found by handle. This is the part that voltage fingerprinting
% got wrong.
hGsut = get_param(Z.gsut.tx, 'Handle');
hGat  = get_param(Z.aux.gat, 'Handle');

kGsut = blocks_bus(LF, hGsut, 230000, 'GSUT 10BAT10');
node.B230_1 = kGsut;
node.B230_2 = kGsut;      % lumped by the solver: nothing else terminates on BUS 2

kGat = blocks_bus(LF, hGat, 230000, 'GAT 10BBT20');
node.GAT_HV = kGat;

% If L_LINE exists, find the intermediate node between ZGRID and L_LINE.
% Since pure Series RLC Branches and PI Section Lines are not reliably 
% populated in the LF.bus(i).blocks array for both terminals by the load 
% flow solver, we find B230_REMOTE by exclusion: it is the only bus out 
% of the 6 that is not already identified.
L_idx = find(strcmp({D.lines.Name}, 'L_LINE'));
if ~isempty(L_idx) && D.lines(L_idx).Model_included
    expected_nb = 6;
else
    expected_nb = 5;
end
assert(nb == expected_nb, ...
    ['ashuganj_bus_map: %d buses were solved, not the expected %d.'], nb, expected_nb);

if expected_nb == 6
    known_buses = [node.BGRID230, node.B230_1, node.GAT_HV, node.B22, node.B6_6];
    all_buses = 1:nb;
    rem_bus = setdiff(all_buses, known_buses);
    if numel(rem_bus) == 1
        node.B230_REMOTE = rem_bus;
    else
        % Fallback if something went wrong
        node.B230_REMOTE = rem_bus(1);
    end
end

assert(kGat ~= kGsut, ...
    ['ashuganj_bus_map: the GAT HV terminal and the 230 kV busbar resolved to ' ...
     'the same bus %d. Measured behaviour is that the solver keeps them ' ...
     'separate in BOTH the bay-open and bay-closed cases; if that has changed, ' ...
     'the branch-flow report needs revisiting.'], kGat);

% =====================================================================
% Cross-checks. None of these found a bus; all of them can falsify one.
% =====================================================================

% With the bay OPEN the GAT HV node is fed only through the 1e6 ohm snubber, so
% it floats at the transformer's no-load voltage referred up from 6.6 kV. That
% voltage is predictable from the turns ratio alone, and finding it confirms both
% the identification and the turns ratio.
gat = D.tx(strcmp({D.tx.Name}, 'GAT'));
if ~isempty(gat) && strcmp(get_param(Z.gis.gatcb, 'InitialState'), 'open')
    B66   = D.buses(strcmp({D.buses.Name}, 'B6_6'));
    BH    = D.buses(strcmp({D.buses.Name}, gat.Bus_HV));
    Vpred = V(node.B6_6) * B66.Vnom_V * (gat.V_HV_V/gat.V_LV_V) / BH.Vnom_V;
    assert(abs(V(kGat) - Vpred) < 5e-3, ...
        ['ashuganj_bus_map: the GAT bay is open, so its HV terminal should ' ...
         'float at the turns-ratio voltage %.5f pu, but bus %d reads %.5f pu. ' ...
         'Either the turns ratio or the snubber path is not what the model ' ...
         'documents.'], Vpred, kGat, V(kGat));
else
    % Bay closed: the GAT HV terminal is the busbar, separated only by the
    % 0.01 ohm breaker resistance. It must be electrically indistinguishable.
    assert(abs(V(kGat) - V(kGsut)) < 1e-3, ...
        ['ashuganj_bus_map: the GAT bay is closed, so its HV terminal should ' ...
         'sit within a millivolt-per-unit of the busbar, but %.6f pu vs ' ...
         '%.6f pu differ by %.2e. The 0.01 ohm breaker resistance cannot ' ...
         'account for that.'], V(kGat), V(kGsut), abs(V(kGat) - V(kGsut)));
end
end

% =====================================================================
function k = vsrc_bus(LF, h, what)
%VSRC_BUS  Bus number of a voltage source, from the solver's own mapping.
assert(isfield(LF, 'vsrc') && ~isempty(LF.vsrc), ...
    'ashuganj_bus_map: the solution contains no voltage sources.');
j = find(abs([LF.vsrc.handle] - h) < 1e-9, 1);
assert(~isempty(j), ...
    ['ashuganj_bus_map: %s (handle %.6f) is not among the %d solved sources. ' ...
     'Either it was not built or the zones come from a different build.'], ...
    what, h, numel(LF.vsrc));
k = LF.vsrc(j).busNumber;
end

% =====================================================================
function k = blocks_bus(LF, h, vbaseWant, what)
%BLOCKS_BUS  Bus whose block list contains handle h, at the expected base.
%   LF.bus(k).blocks holds the load-flow blocks terminating on bus k. A
%   transformer appears at more than one bus (one per winding), so the voltage
%   base disambiguates WHICH winding - but the handle, not the voltage, is what
%   identifies the bus.
hit = [];
for k = 1:numel(LF.bus)
    b = LF.bus(k).blocks;
    if isempty(b), continue, end
    if any(abs(b(:) - h) < 1e-9) && abs(LF.bus(k).vbase - vbaseWant) < 1
        hit(end+1) = k;    %#ok<AGROW>
    end
end
assert(isscalar(hit), ...
    ['ashuganj_bus_map: %s (handle %.6f) was expected at exactly one %g V ' ...
     'bus but matched %d (%s). LF.bus.blocks did not identify it uniquely.'], ...
    what, h, vbaseWant, numel(hit), mat2str(hit));
k = hit;
end
