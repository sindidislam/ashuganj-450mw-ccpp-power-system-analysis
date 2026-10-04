function [np, nf] = test_transformer_phase_shift()
%TEST_TRANSFORMER_PHASE_SHIFT  Confirms the vector-group phase shifts empirically.
%
%   The transformer database says the GSUT is YNd1 (LV lagging the HV by 30 deg)
%   and the UAT is Dyn11 (LV leading by 30 deg), and it says so twice: on the
%   nameplate, and in the Specialized Power Systems winding-connection strings
%   chosen to represent it. The second of those is an INTERPRETATION of an SPS
%   convention, and interpretations of conventions are exactly the kind of thing
%   that is wrong 50 % of the time. The Conn_Note field on both transformers
%   promises this test by name; this is that test.
%
%   HOW IT DISCRIMINATES
%   --------------------
%   A phase shift cannot be read off a single bus angle, because the load angle
%   is mixed into it. But it can be caught by a power balance. The branch flows
%   are reconstructed from the solved bus voltages using an assumed shift; if the
%   assumed shift is wrong, the reconstructed currents are wrong, and the power
%   they imply at the 22 kV bus misses the generator's 389.3 MW by hundreds of
%   megawatts. So the test does the reconstruction twice, once with each sign,
%   and requires that exactly one of them closes.
%
%   THE LOOP CONSTRAINT
%   -------------------
%   Case LF2 closes a loop: 230 kV -> GSUT -> 22 kV -> UAT -> 6.6 kV -> GAT ->
%   230 kV. The vector-group shifts around that loop must sum to zero
%   (-30 + 30 + 0), or the loop is not physically closable at all. The GAT being
%   YNyn0 is what makes the loop legal, and the loop is the whole reason the GAT
%   mattered enough to be defect D6 of the prior model. That is checked too.
T = t_case('test_transformer_phase_shift');
mdlName = 'Ashuganj_South_Main';

% =====================================================================
% Part A - LF1: does the documented shift close the power balance?
% =====================================================================
[LF, D, C, info] = t_solve('LF1');
R   = ashuganj_branch_flows(LF, D, C, info.zones);
[~, res] = ashuganj_bus_results(LF, D, C, R, info.zones);

worst = max([res.Residual_MVA]);
T = T.chk(worst < 0.05, sprintf( ...
    ['power balance closes at every bus with the DOCUMENTED shifts: worst ' ...
     'residual %.2e MVA (branch flows from documented impedances vs solver ' ...
     'injections)'], worst));
for j = 1:numel(res)
    T = T.chk(res(j).Residual_MVA < 0.05, sprintf( ...
        '  %-9s residual %.3e MVA (dP %+.2e MW, dQ %+.2e MVAr)', ...
        res(j).Name, res(j).Residual_MVA, res(j).dP_MW, res(j).dQ_MVAr));
end

% =====================================================================
% Part B - the wrong sign must FAIL, and fail loudly
% =====================================================================
node = ashuganj_bus_map(LF, D, info.zones);
Sb   = D.base.Sbase_MVA;
X    = D.tx;
gsut = X(strcmp({X.Name}, 'GSUT'));
uat  = X(strcmp({X.Name}, 'UAT'));

% 22 kV bus balance: generator injection = GSUT export + UAT draw.
Pgen = real(LF.bus(node.B22).Sbus) * Sb;
for s = [+1, -1]
    Sg = xflow(gsut, LF, node, D, Sb, s*30);      % B22 -> B230_1
    Su = xflow(uat,  LF, node, D, Sb, s*(-30));   % B6_6 -> B22
    bal = real(Sg.Sf) - real(Su.St);              % net leaving the 22 kV bus
    err = abs(bal - Pgen);
    if s == +1
        T = T.chk(err < 0.02, sprintf( ...
            ['GSUT YNd1 (+30 deg) and UAT Dyn11 (-30 deg) reproduce the ' ...
             '22 kV bus balance: %.4f MW vs the generator''s %.4f MW'], bal, Pgen));
    else
        T = T.chk(err > 50, sprintf( ...
            ['the OPPOSITE shifts are decisively wrong: 22 kV balance becomes ' ...
             '%.1f MW against %.1f MW, an error of %.1f MW - so the ' ...
             'documented signs are confirmed by measurement, not by the block ' ...
             'name'], bal, Pgen, err));
    end
end

% =====================================================================
% Part C - angle direction must follow the power direction
% =====================================================================
% Across a mainly inductive series impedance the sending end leads. The GSUT
% exports from 22 kV up to 230 kV, so the 22 kV bus referred through the
% transformer must LEAD the 230 kV bus. The UAT feeds down, so its 22 kV side
% must lead its 6.6 kV side referred up.
Sg = xflow(gsut, LF, node, D, Sb, 30);
Su = xflow(uat,  LF, node, D, Sb, -30);

T = T.chk(real(Sg.Sf) > 0, sprintf( ...
    'GSUT carries power LV -> HV (export): %.4f MW leaves the 22 kV bus', real(Sg.Sf)));
T = T.chk(Sg.lead > 0, sprintf( ...
    ['GSUT: with the 30 deg group shift removed, the 22 kV side LEADS the ' ...
     '230 kV side by %.4f deg, which is the correct direction for export'], Sg.lead));
T = T.chk(real(Su.Sf) < 0, sprintf( ...
    'UAT carries power HV -> LV (auxiliary supply): %.4f MW at the 6.6 kV side', real(Su.Sf)));
T = T.chk(Su.lead < 0, sprintf( ...
    ['UAT: with the 30 deg group shift removed, the 6.6 kV side LAGS the ' ...
     '22 kV side by %.4f deg, correct for a downward feed'], -Su.lead));

% Raw reported angles, for the record: the group shift dominates and the load
% angle perturbs it. Both must land in the half-plane the group dictates.
aH = rad2deg(angle(LF.bus(node.B230_1).Vbus));
aM = rad2deg(angle(LF.bus(node.B22).Vbus));
aL = rad2deg(angle(LF.bus(node.B6_6).Vbus));
dG = wrap180(aM - aH);
dU = wrap180(aL - aM);
T = T.chk(dG < -10 && dG > -50, sprintf( ...
    'raw 230 kV -> 22 kV angle step %+.3f deg: a -30 deg group shift plus a %+.3f deg export angle', ...
    dG, dG + 30));
T = T.chk(dU > 10 && dU < 50, sprintf( ...
    'raw 22 kV -> 6.6 kV angle step %+.3f deg: a +30 deg group shift plus a %+.3f deg load angle', ...
    dU, dU - 30));

if bdIsLoaded(mdlName), bdclose(mdlName); end   % bdclose forces; close_system(...,0) warns on a dirty model

% =====================================================================
% Part D - LF2: the shifts around the GAT loop must sum to zero
% =====================================================================
[LF2, D2, C2, info2] = t_solve('LF2');
T = T.chk(C2.GAT_in, 'case LF2 has the GAT in service, closing the 230/22/6.6 kV loop');

shift = containers.Map({'YNd1','Dyn11','YNyn0','YNyn0+d11'}, {30, -30, 0, 0});
loop  = 0;
for nm = {'GSUT','UAT','GAT'}
    x = D2.tx(strcmp({D2.tx.Name}, nm{1}));
    loop = loop + shift(x.VectorGroup) * sign_in_loop(nm{1});
end
T = T.near(mod(loop, 360), 0, 1e-9, sprintf( ...
    ['vector-group shifts around the 230 kV -> GSUT -> 22 kV -> UAT -> 6.6 kV ' ...
     '-> GAT -> 230 kV loop sum to %g deg. A non-zero sum would make the loop ' ...
     'physically unclosable; the GAT being YNyn0 is what permits it'], loop));

R2  = ashuganj_branch_flows(LF2, D2, C2, info2.zones);
[~, res2] = ashuganj_bus_results(LF2, D2, C2, R2, info2.zones);
worst2 = max([res2.Residual_MVA]);
T = T.chk(worst2 < 0.05, sprintf( ...
    ['LF2 (loop closed) power balance also closes: worst residual %.2e MVA. ' ...
     'A wrong shift anywhere in a LOOPED network produces circulating power, ' ...
     'so this is the stronger of the two topologies to test'], worst2));

kg = find(strcmp({R2.Name}, 'GAT 10BBT20'), 1);
if ~isempty(kg)
    T = T.chk(abs(R2(kg).S_from_MVA) < 25, sprintf( ...
        ['GAT loop flow is %.4f MVA, within its 25 MVA rating - no circulating ' ...
         'power from a mismatched phase shift'], R2(kg).S_from_MVA));
end

if bdIsLoaded(mdlName), bdclose(mdlName); end   % bdclose forces; close_system(...,0) warns on a dirty model
[np, nf] = T.done();
end

% =====================================================================
function s = sign_in_loop(name)
%SIGN_IN_LOOP  Direction each transformer is traversed going round the loop.
%   The loop is walked 230 kV -> 22 kV -> 6.6 kV -> 230 kV. The GSUT and UAT are
%   traversed HV to LV, the GAT LV to HV, so the GAT's shift enters negated.
switch name
    case 'GAT', s = -1;
    otherwise,  s = +1;
end
end

% =====================================================================
function o = xflow(x, LF, node, D, Sb, th)
%XFLOW  Transformer flow with an EXPLICIT phase shift, so a wrong one can be
%   tried on purpose. Same algebra as ashuganj_branch_flows, shift not hidden.
BH = D.buses(strcmp({D.buses.Name}, x.Bus_HV));
BL = D.buses(strcmp({D.buses.Name}, x.Bus_LV));
k  = Sb / x.S_rating_MVA;
Z1 = (x.R1_pu + 1i*x.L1_pu) * k;
Z2 = (x.R2_pu + 1i*x.L2_pu) * k;
Ym = (1/x.Rm_pu + 1/(1i*x.Lm_pu)) / k;
ratio = (x.V_HV_V / x.V_LV_V) * (BL.Vnom_V / BH.Vnom_V);

VH = LF.bus(node.(x.Bus_HV)).Vbus;
VL = LF.bus(node.(x.Bus_LV)).Vbus;
VLref = VL * ratio * exp(1i*deg2rad(th));

VA = (VLref/Z2 + VH/Z1) / (1/Z1 + 1/Z2 + Ym);
I1 = (VA - VH)/Z1;
I2 = (VLref - VA)/Z2;

o.Sf   = VLref*conj(I2) * Sb;      % leaving the LV bus
o.St   = VH*conj(I1)    * Sb;      % arriving at the HV bus
o.lead = wrap180(rad2deg(angle(VLref) - angle(VH)));
end

% =====================================================================
function a = wrap180(a)
a = mod(a + 180, 360) - 180;
end
