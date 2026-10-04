function [np, nf] = test_base_conversion()
%TEST_BASE_CONVERSION  Verifies convert_to_system_base and, just as important,
%   verifies that it is NOT applied to the Simulink block parameters.
%
%   Every transformer impedance in this project is quoted on its own rating:
%   16 % at 515 MVA, 10.5 % at 25 MVA, 12 % at 25 MVA. On the 100 MVA reporting
%   base those become 3.11 %, 42 % and 48 %. The Specialized Power Systems
%   transformer block wants per unit on its OWN nominal power, which is how the
%   nameplate quotes it, so the block gets the raw nameplate figure and the
%   converted figure is used only for reporting and for the independent
%   cross-check. Double-converting the UAT would turn 42 % into 168 % and the
%   solver would still converge, on nonsense. Both directions are tested.
T = t_case('test_base_conversion');

% ---- the identity and the algebra --------------------------------------
T = T.near(convert_to_system_base(0.1, 100, 100), 0.1, 1e-15, ...
    'same base is the identity');
T = T.near(convert_to_system_base(0.105, 25, 100), 0.42, 1e-15, ...
    '10.5 % at 25 MVA -> 42 % at 100 MVA (factor Snew/Sold)');
T = T.near(convert_to_system_base(0.16, 515, 100), 0.16*100/515, 1e-15, ...
    '16 % at 515 MVA -> 3.1068 % at 100 MVA');
T = T.near(convert_to_system_base(0.12, 25, 100), 0.48, 1e-15, ...
    '12 % at 25 MVA -> 48 % at 100 MVA');

% ---- round trip ---------------------------------------------------------
z0 = 0.16;
T = T.near(convert_to_system_base(convert_to_system_base(z0, 515, 100), 100, 515), ...
    z0, 1e-15, 'round trip 515 -> 100 -> 515 MVA returns the original');

% ---- the voltage-base form ---------------------------------------------
T = T.near(convert_to_system_base(0.1, 100, 100, 22, 22), 0.1, 1e-15, ...
    'same voltage base is the identity');
T = T.near(convert_to_system_base(0.1, 100, 100, 6.9, 6.6), 0.1*(6.9/6.6)^2, 1e-15, ...
    'voltage-base form scales by (Vold/Vnew)^2');
% This is conflict C13 expressed as a number: referring a 6.9 kV-based
% impedance to a 6.6 kV base inflates it by 9.2975 %. Stated to four decimals
% because this test exists to pin the constant, and an earlier draft of the
% project notes carried 9.32 %, which is wrong in the third figure.
T = T.near((6.9/6.6)^2 - 1, 0.092975, 1e-6, ...
    '6.9 kV -> 6.6 kV rebasing inflates an impedance by 9.2975 %');

% ---- generator reactances on the machine base --------------------------
G = ashuganj_generators();
T = T.near(convert_to_system_base(G.xdpp_pct/100, G.Snom_MVA, 100), ...
    0.2608*100/458, 1e-12, 'x_d'''' 26.08 % at 458 MVA -> 5.6943 % at 100 MVA');

T = T.chk(isfield(G,'Ra_pu_machine'),'explicit machine resistance exists');
if isfield(G,'Ra_pu_machine')
    T = T.near(G.Zbase_machine_ohm,22^2/458,1e-12,'machine Zbase');
    T = T.near(G.Zbase_100MVA_ohm,4.84,1e-12,'system Zbase');
    T = T.near(G.Ra_ohm,0.00089,1e-12,'raw ohm resistance');
    T = T.near(G.Ra_pu_machine,0.000842190082644628,1e-12,'machine pu resistance');
    T = T.near(G.Ra_pu_100MVA,0.000183884297520661,1e-12,'system pu resistance');
    T = T.near(G.Ra_pu_machine,G.Ra_ohm/G.Zbase_machine_ohm,1e-12,'ohm to machine pu');
    T = T.near(G.Ra_pu_100MVA,G.Ra_ohm/G.Zbase_100MVA_ohm,1e-12,'ohm to system pu');
    T = T.near(G.Ra_pu_machine*G.Zbase_machine_ohm,0.00089,1e-12,'machine inverse returns ohms');
    T = T.near(G.Ra_pu_100MVA*G.Zbase_100MVA_ohm,0.00089,1e-12,'system inverse returns ohms');
    T = T.near(convert_to_system_base(G.Ra_pu_machine,458,100,22,22),G.Ra_pu_100MVA,1e-12,'resistance single conversion');
    T = T.near(convert_to_system_base(G.Ra_pu_100MVA,100,458,22,22),G.Ra_pu_machine,1e-12,'resistance round trip');
    T = T.near(G.Xdpp_100MVA,0.0569432314410480,1e-12,'unqualified Xdpp system view');
    T = T.near(G.Xdpp_sat_100MVA,0.0490829694323144,1e-12,'saturated Xdpp system view');
    T = T.near(convert_to_system_base(G.Xdpp,458,100),G.Xdpp_100MVA,1e-12,'Xdpp single conversion');
    T = T.near(convert_to_system_base(G.Xdpp_sat,458,100),G.Xdpp_sat_100MVA,1e-12,'saturated Xdpp single conversion');
    T = T.near(convert_to_system_base(G.Xdpp_100MVA,100,458),G.Xdpp,1e-12,'Xdpp inverse');
    T = T.near(convert_to_system_base(G.Xdpp_sat_100MVA,100,458),G.Xdpp_sat,1e-12,'saturated Xdpp inverse');
    T = T.chk(G.Xdpp_100MVA ~= G.Xdpp_sat_100MVA,'distinct system reactances');
    T = T.chk(G.Ra_ohm ~= G.Ra_pu_machine && G.Ra_pu_machine ~= G.Ra_pu_100MVA,'distinct resistance quantities');
end

% ---- ohms to per unit, and the grid equivalent -------------------------
Zb230 = 230^2/100;                     % 529 ohm
T = T.near(Zb230, 529, 1e-9, 'Zbase at 230 kV, 100 MVA = 529 ohm');
Gr = ashuganj_grid();
T = T.near(Gr.Z_ohm/Zb230, 0.00502042, 1e-7, ...
    'grid 2.6558 ohm = 0.50204 % on the 100 MVA / 230 kV base');
T = T.near(Gr.X_ohm/(2*pi*50), Gr.L_H, 1e-15, ...
    'grid L is X/(2*pi*50) - the 50 Hz dependence is explicit');

% ---- the SPS blocks must hold the UNCONVERTED nameplate values --------
X  = ashuganj_transformers();
for i = 1:numel(X)
    x = X(i);
    T = T.near(x.X_pu, x.X_pct/100, 1e-12, sprintf( ...
        '%s block X_pu = %.6f is on its own %g MVA rating, NOT converted to 100 MVA', ...
        x.Label, x.X_pu, x.S_rating_MVA));
    onSb = convert_to_system_base(x.X_pu, x.S_rating_MVA, 100);
    if abs(onSb - x.X_pu) > 1e-9
        T = T.chk(abs(x.X_pu - onSb) > 1e-9, sprintf( ...
            '%s has NOT been double-converted (%.6f pu own base vs %.6f pu on 100 MVA)', ...
            x.Label, x.X_pu, onSb));
    end
end

% ---- input validation ---------------------------------------------------
ok = false;
try, convert_to_system_base(0.1, 0, 100); catch, ok = true; end
T = T.chk(ok, 'a zero source base is rejected rather than returning Inf');

[np, nf] = T.done();
end
