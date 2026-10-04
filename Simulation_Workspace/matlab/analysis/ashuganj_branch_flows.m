function R = ashuganj_branch_flows(LF, D, C, Z)
%ASHUGANJ_BRANCH_FLOWS  Branch flows reconstructed from the solved bus phasors.
%
%   R = ASHUGANJ_BRANCH_FLOWS(LF, D, C, Z) takes a power_loadflow solution LF,
%   the Phase 7 dataset D, the case record C and the builder's zone handles
%   Z = info.zones, and returns a struct array with one element per branch:
%   current, sending and receiving power, losses and loading.
%
%   WHY NOT MEASUREMENT BLOCKS
%   --------------------------
%   No V-I measurement blocks were put in the model. Every branch flow here is
%   reconstructed from the solved bus voltages and the DOCUMENTED impedances.
%   That is not a shortcut, it is the cross-check: these flows are computed
%   independently of the solver's internal branch bookkeeping, so the fact that
%   they close KCL at every bus against the solver's own reported bus injections
%   confirms that this post-processing and the solver agree about which network
%   was solved. A measurement block would only echo what the solver believes.
%
%   PER-UNIT CONVENTION
%   -------------------
%   100 MVA reporting base (approved answer Q11a), each bus at its DOCUMENTED
%   nominal voltage from the bus register - not the solver's derived vbase.
%   Impedances quoted on a transformer rating are converted here, once.
%
%   OFF-NOMINAL TURNS RATIOS
%   ------------------------
%   The UAT and GAT LV windings are 6.9 kV while the bus they feed is nominally
%   6.6 kV (conflict C13). That is a real off-nominal ratio of 6600/6900 =
%   0.956522 and it is carried explicitly. Treating it as 1.0 would put the MV
%   bus 4.5 % high - a modelling error dressed as a result.
%
%   VECTOR GROUPS
%   -------------
%   YNd1  : LV lags HV by 30 deg  ->  V_HV_equivalent = V_LV * ratio * e^(+j30)
%   Dyn11 : LV leads HV by 30 deg ->  V_HV_equivalent = V_LV * ratio * e^(-j30)
%   YNyn0 : no shift.
%   The sign is not taken on trust: test_transformer_phase_shift.m shows that
%   flipping it breaks the power balance by hundreds of MVA.
%
%   TRANSFORMER TOPOLOGY USED
%   -------------------------
%       HV bus --[Z1]-- node A --[ideal ratio, shift]--[Z2]-- LV bus
%                          |
%                         Ym  (Rm from documented no-load loss, Lm open)
%   This mirrors the SPS per-unit model, where the magnetising branch hangs off
%   the internal node behind winding 1, not off the HV terminal.
%
%   See also ASHUGANJ_MASTER_DATA, ASHUGANJ_BUS_RESULTS.

Sb   = D.base.Sbase_MVA;
node = ashuganj_bus_map(LF, D, Z);
Zb230 = (230e3)^2 / (Sb*1e6);

R = empty_branch();

% ===================================================== grid equivalent
G  = D.grid;
Zg = (G.R_ohm + 1i*G.X_ohm) / Zb230;
% Phase-3 reporting alignment (Task 9): the SOLVED ZGRID span is
% BGRID230->B230_REMOTE, behind the L_LINE PI section (builder
% build_external_grid.m:121-129; dataset ashuganj_lines.m:29-32). The
% Phase-2 span BGRID230->B230_1 (G.Bus_boundary) is kept only for models
% built without L_LINE. Data untouched: only which solved phasors are
% differenced across the unchanged Zg changes.
zg_to = G.Bus_boundary;
kLL = find(strcmp({D.lines.Name}, 'L_LINE'), 1);
has_LL = ~isempty(kLL) && D.lines(kLL).Model_included && isfield(node, 'B230_REMOTE');
if has_LL
    zg_to = 'B230_REMOTE';
end
R(end+1) = series_branch('ZGRID (grid equivalent)', G.Bus_internal, zg_to, ...
    'equivalent', Zg, node, LF, Sb, 230e3, NaN, ...
    'ESTIMATED Siemens §2.4 source-quantity impedance - weakest number in the model');

% ===================================================== Phase-3 0.7 km line (PI)
% Reporting-only nominal-PI reconstruction of the locked lumped
% dual-circuit L_LINE from the documented R/X/C (read, never modified).
% Skipped entirely when L_LINE is not modelled, so Phase-2 reporting is
% byte-for-byte unaffected. Named exactly 'L_LINE' for the validator lookup.
if has_LL
    LL = D.lines(kLL);
    R(end+1) = pi_line_branch('L_LINE', LL.Bus_from, LL.Bus_to, ...
        LL.R_ohm, LL.X_ohm, LL.C_F, D.grid.f_Hz, node, LF, Sb, 230e3, NaN, ...
        'Locked Phase-3 EA 0.7 km lumped dual-circuit Mallard PI; thermal rating MISSING so loading is NaN.');
end

% ===================================================== bus coupler 10BAY12
% A Three-Phase Breaker with BreakerResistance 0.01 ohm and a 1e6 ohm snubber.
% Closed, the load flow treats it as a short and merges BUS 1 with BUS 2, so
% there is no distinct branch and the flow through it is not observable from bus
% voltages. Recorded explicitly rather than dropped silently.
if C.Coupler_closed
    R(end+1) = note_branch('BUS COUPLER 10BAY12', 'B230_1', 'B230_2', 'breaker', ...
        'CLOSED (ASSUMPTION - normal state not in the document set). Solver merges BUS 1 and BUS 2; flow not observable from bus voltages.');
else
    R(end+1) = series_branch('BUS COUPLER 10BAY12 (open, snubber path)', ...
        'B230_1', 'B230_2', 'breaker', 1e6/Zb230, node, LF, Sb, 230e3, NaN, ...
        'OPEN: the 1e6 ohm SPS snubber is the only path. Numerical artefact of the block, not plant equipment.');
end

% ===================================================== GAT bay 10BAY20
if ~C.GAT_in
    R(end+1) = series_branch('GAT BAY CB 10BAY20 (open, snubber path)', ...
        'B230_2', 'GAT_HV', 'breaker', 1e6/Zb230, node, LF, Sb, 230e3, NaN, ...
        'OPEN: the 1e6 ohm SPS snubber is what gives the GAT HV terminal a defined voltage instead of a floating node. Numerical artefact of the block, not plant equipment.');
end

% ===================================================== transformers
for i = 1:numel(D.tx)
    x = D.tx(i);
    isGATout = strcmp(x.Name, 'GAT') && ~C.GAT_in;
    if isGATout
        hvKey = 'GAT_HV';
        nt = 'GAT bay 10BAY20 OPEN: the GAT stays connected to the 6.6 kV bus and is BACK-ENERGISED from the LV side, so it carries magnetising current only and its HV terminal floats at the turns-ratio voltage.';
    else
        hvKey = x.Bus_HV;
        nt = '';
    end
    R(end+1) = transformer_branch(x, hvKey, node, LF, D, Sb, nt);
end
end

% =====================================================================
function b = series_branch(name, from, to, type, Zpu, node, LF, Sb, Vb, rating, note)
if ~isfield(node, from) || ~isfield(node, to) || node.(from) == node.(to)
    b = note_branch(name, from, to, type, ...
        [note ' | terminals are the same solved node, so no flow is observable']);
    return
end
% Per-bus pu bases: LF.bus.Vbus is per-unit on that bus's own vbase (the
% Phase-3 PI section leaves B230_REMOTE at a 100 kV block-default base while
% every other 230 kV bus is on 230 kV). Renormalise both ends to the
% reporting Vb before differencing. When both ends already share Vb the
% factor is exactly 1.0, so Phase-2 reporting is bit-identical.
Vf = LF.bus(node.(from)).Vbus * (LF.bus(node.(from)).vbase / Vb);
Vt = LF.bus(node.(to)).Vbus * (LF.bus(node.(to)).vbase / Vb);
I  = (Vf - Vt) / Zpu;
b  = pack(name, from, to, type, Vf, Vt, I, Vf*conj(I), Vt*conj(I), Sb, Vb, rating, note);
end

% =====================================================================
function b = pi_line_branch(name, from, to, R_ohm, X_ohm, C_F, f_Hz, node, LF, Sb, Vb, rating, note)
%PI_LINE_BRANCH  Nominal-PI flow from solved phasors + documented R/X/C.
%   Series current From->To plus half the shunt charging at each end. Sf
%   leaves From; St arrives at To in the same reference direction, so
%   pack()'s loss and the bus_results KCL convention are preserved.
if ~isfield(node, from) || ~isfield(node, to) || node.(from) == node.(to)
    b = note_branch(name, from, to, 'line', ...
        [note ' | terminals are the same solved node, so no flow is observable']);
    return
end
Zb  = (Vb^2) / (Sb*1e6);
Yse = 1 / ((R_ohm + 1i*X_ohm) / Zb);
Ysh = 1i * (2*pi*f_Hz*C_F) / 2 * Zb;
% Same per-bus-base renormalisation as series_branch above: the L_LINE ends
% sit on different solver vbase values (230 kV vs the PI block default).
Vf  = LF.bus(node.(from)).Vbus * (LF.bus(node.(from)).vbase / Vb);
Vt  = LF.bus(node.(to)).Vbus * (LF.bus(node.(to)).vbase / Vb);
Ise = (Vf - Vt) * Yse;
Sf  = Vf * conj(Ise + Vf*Ysh);
St  = Vt * conj(Ise - Vt*Ysh);
b   = pack(name, from, to, 'line', Vf, Vt, Ise + Vf*Ysh, Sf, St, Sb, Vb, rating, note);
end

% =====================================================================
function b = transformer_branch(x, hvKey, node, LF, D, Sb, note)
BH = D.buses(strcmp({D.buses.Name}, x.Bus_HV));
BL = D.buses(strcmp({D.buses.Name}, x.Bus_LV));

% Impedances on the transformer's own rating -> reporting base. The HV winding
% voltage equals the HV bus nominal for all three units, so only the MVA base
% changes; a pu impedance is the same referred to either winding.
k  = Sb / x.S_rating_MVA;
Z1 = (x.R1_pu + 1i*x.L1_pu) * k;
Z2 = (x.R2_pu + 1i*x.L2_pu) * k;

% Admittance rebases the OTHER way: Y_new = Y_old * (S_old/S_new).
Ym = (1/x.Rm_pu + 1/(1i*x.Lm_pu)) / k;

% Off-nominal ratio and vector-group shift.
ratio = (x.V_HV_V / x.V_LV_V) * (BL.Vnom_V / BH.Vnom_V);
switch x.VectorGroup
    case 'YNd1',                th =  30;    % LV lags HV
    case 'Dyn11',               th = -30;    % LV leads HV
    case {'YNyn0','YNyn0+d11'}, th =   0;
    otherwise
        th   = 0;
        note = strtrim([note ' | UNRECOGNISED vector group ' x.VectorGroup ...
                        ': no phase shift applied, angles are not trustworthy']);
end

VH = LF.bus(node.(hvKey)).Vbus;
VL = LF.bus(node.(x.Bus_LV)).Vbus;
VLref = VL * ratio * exp(1i*deg2rad(th));       % LV referred to the HV side

% Internal node behind winding 1.
VA = (VLref/Z2 + VH/Z1) / (1/Z1 + 1/Z2 + Ym);
I1 = (VA - VH) / Z1;                            % node A -> HV bus
I2 = (VLref - VA) / Z2;                         % LV bus -> node A

b = pack(x.Label, x.Bus_LV, hvKey, 'transformer', VL, VH, I1, ...
         VLref*conj(I2), VH*conj(I1), Sb, BH.Vnom_V, x.S_rating_MVA, note);
b.Note = strtrim(sprintf('%s | ratio %.6f, shift %+d deg, Z %.4f %% on %g MVA', ...
         note, ratio, th, abs(Z1+Z2)*100/(Sb/x.S_rating_MVA), x.S_rating_MVA));
b.Rating_all_MVA = x.S_MVA;                     % every cooling stage
end

% =====================================================================
function b = pack(name, from, to, type, Vf, Vt, I, Sf, St, Sb, Vb, rating, note)
b = empty_branch();
b(1).Name     = name;
b.From        = from;
b.To          = to;
b.Type        = type;
b.V_from_pu   = abs(Vf);
b.V_to_pu     = abs(Vt);
b.Ang_from_deg= rad2deg(angle(Vf));
b.Ang_to_deg  = rad2deg(angle(Vt));
b.I_pu        = abs(I);
b.I_A         = abs(I) * (Sb*1e6) / (sqrt(3)*Vb);
b.P_from_MW   = real(Sf) * Sb;
b.Q_from_MVAr = imag(Sf) * Sb;
b.S_from_MVA  = abs(Sf)  * Sb;
b.P_to_MW     = real(St) * Sb;
b.Q_to_MVAr   = imag(St) * Sb;
b.S_to_MVA    = abs(St)  * Sb;
b.P_loss_MW   = (real(Sf) - real(St)) * Sb;
b.Q_loss_MVAr = (imag(Sf) - imag(St)) * Sb;
b.Rating_MVA  = rating;
if isfinite(rating) && rating > 0
    b.Loading_pct = 100 * max(abs(Sf), abs(St)) * Sb / rating;
else
    b.Loading_pct = NaN;
end
b.Rating_all_MVA = rating;
b.Note = note;
end

% =====================================================================
function b = note_branch(name, from, to, type, note)
%NOTE_BRANCH  A branch that exists in the plant but carries no observable flow.
%   Its numbers are NaN, not zero. Zero would be a measurement; NaN is the
%   truthful statement that bus voltages cannot reveal this flow.
b = pack(name, from, to, type, NaN, NaN, NaN, NaN, NaN, 1, 1, NaN, note);
end

% =====================================================================
function b = empty_branch()
f = {'Name','From','To','Type','V_from_pu','V_to_pu','Ang_from_deg','Ang_to_deg', ...
     'I_pu','I_A','P_from_MW','Q_from_MVAr','S_from_MVA','P_to_MW','Q_to_MVAr', ...
     'S_to_MVA','P_loss_MW','Q_loss_MVAr','Rating_MVA','Rating_all_MVA', ...
     'Loading_pct','Note'};
args = [f; repmat({{}}, 1, numel(f))];
b = struct(args{:});
end
