function Z = phase4_seqZ(opts)
%PHASE4_SEQZ  Zero-sequence builder M2-Z on 100 MVA / 230 kV.
%
%   Z = PHASE4_SEQZ(opts) returns zero-sequence impedances in pu on
%   100 MVA / 230 kV (ohms divided by 529) plus neutral equivalents.
%   opts is a struct with fields kR/kX/kB (line band multipliers),
%   k0g (grid magnitude multiplier, exactly 1.0/1.5/2.0), gatLeg
%   ('H0'/'H1'/'H2'), lambda_T (H1 loop scale in [0.5,2.0]), grid
%   ('P'/'S'), XoR_P (passed to seqPN for dataset P), ner
%   ('primary'/'quoted60', passed to grounding).
%   Additive Task-12 support (base-identical by default): opts.gatZ0sel
%   ('nominal' default = 10.8% / 'low' = 9.99% / 'high' = 11.61%,
%   SOURCE-stated tolerance, never relabelled ENGINEERING_ASSUMPTION)
%   selects the applied GAT HV-LV zero; opts.ovr (optional struct)
%   forwards to phase4_grounding (Rloading_tolfrac/ZN_UAT_scale/
%   ZN_GATLV_scale/ZN_GATHV_ohm; base defaults reproduce exactly).
%
%   Ratios come only from opts; there is no invented X0=3X1 / R0=R1 /
%   B0=B1 rule and no Z0m coupling-factor input. GAT LV neutral is the
%   5-A equivalent, never solid: no ZN=0 path exists for GAT LV.
%
%   GAT tertiary Z_PT/Z_ST are MISSING (NaN) and never enter arithmetic:
%   if the registry ever carries a non-NaN value, this function errors
%   prompting a spec update.
%
%   Values from phase4_registry; frozen Phase-3 totals R_eq 0.0277725 ohm,
%   X_eq 0.1425655 ohm, B_eq 3.937996 uS, Zbase 529 ohm; LV-zone base
%   R.lv.Zbase_ohm = 0.4356 ohm (6.6 kV) for ALL LV ohmic conversions
%   (aux/neutral pu); machine X0 0.128
%   on 458 MVA with Ra 0.00089 ohm stator; GSUT Z0 15.8% on 515 MVA; UAT
%   Z0 9.3% on 25 MVA; GAT Z0_PS 10.8% on 25 MVA (100-MVA loop = 4x).
%   LV neutral semantics (correction record C7): ZN_*_ohm are PHYSICAL
%   (IN-reading, Vph/5); Z3N_*_equiv_* are the STAMPED branch values
%   (single x3 applied in grounding, never downstream).

if nargin < 1 || ~isstruct(opts) || ~isscalar(opts)
    error('phase4_seqZ:badOpts', 'opts struct required with kR/kX/kB/k0g/gatLeg/lambda_T/grid/XoR_P/ner.');
end
req = {'kR','kX','kB','k0g','gatLeg','lambda_T','grid','ner'};
for i = 1:numel(req)
    if ~isfield(opts, req{i})
        error('phase4_seqZ:badOpts', 'Missing opts field ''%s''.', req{i});
    end
end

kR = opts.kR;
kX = opts.kX;
kB = opts.kB;
k0g = opts.k0g;
lambda_T = opts.lambda_T;

if ~(isscalar(kR) && isfinite(kR) && kR >= 2.0 && kR <= 5.0)
    error('phase4_seqZ:badKR', 'kR must be finite in [2.0,5.0].');
end
if ~(isscalar(kX) && isfinite(kX) && kX >= 2.0 && kX <= 3.5)
    error('phase4_seqZ:badKX', 'kX must be finite in [2.0,3.5].');
end
if ~(isscalar(kB) && isfinite(kB) && kB >= 0.60 && kB <= 0.85)
    error('phase4_seqZ:badKB', 'kB must be finite in [0.60,0.85].');
end
if ~(isscalar(k0g) && isfinite(k0g) && any(k0g == [1.0, 1.5, 2.0]))
    error('phase4_seqZ:badK0g', 'k0g must be exactly 1.0, 1.5, or 2.0.');
end
if ~(isscalar(lambda_T) && isfinite(lambda_T) && lambda_T >= 0.5 && lambda_T <= 2.0)
    error('phase4_seqZ:badLambda', 'lambda_T must be finite in [0.5,2.0].');
end

if isstring(opts.gatLeg)
    gatLeg = char(opts.gatLeg);
elseif ischar(opts.gatLeg)
    gatLeg = opts.gatLeg;
else
    error('phase4_seqZ:badLeg', 'gatLeg must be ''H0'', ''H1'', or ''H2''.');
end
if ~any(strcmp(gatLeg, {'H0','H1','H2'}))
    error('phase4_seqZ:badLeg', 'Unknown gatLeg ''%s'': use ''H0'', ''H1'', or ''H2''.', gatLeg);
end

if isstring(opts.grid)
    grid = char(opts.grid);
elseif ischar(opts.grid)
    grid = opts.grid;
else
    error('phase4_seqZ:badGrid', 'grid must be ''P'' or ''S''.');
end
if ~(numel(grid) == 1 && (grid == 'P' || grid == 'S'))
    error('phase4_seqZ:badGrid', 'grid must be ''P'' or ''S''.');
end

if isstring(opts.ner)
    ner = char(opts.ner);
elseif ischar(opts.ner)
    ner = opts.ner;
else
    error('phase4_seqZ:badNer', 'ner must be ''primary'' or ''quoted60''.');
end
if ~any(strcmp(ner, {'primary','quoted60'}))
    error('phase4_seqZ:badNer', 'Unknown ner ''%s'': use ''primary'' or ''quoted60''.', ner);
end

R = phase4_registry();

% ---- Task-12 additive: gatZ0sel (default nominal; SOURCE status kept) ----
gatZ0sel = 'nominal';
if isfield(opts, 'gatZ0sel') && ~isempty(opts.gatZ0sel)
    if isstring(opts.gatZ0sel), gatZ0sel = char(opts.gatZ0sel);
    elseif ischar(opts.gatZ0sel), gatZ0sel = opts.gatZ0sel;
    else
        error('phase4_seqZ:badGatZ0sel', 'gatZ0sel must be ''nominal''/''low''/''high''.');
    end
end
if ~any(strcmp(gatZ0sel, {'nominal','low','high'}))
    error('phase4_seqZ:badGatZ0sel', 'Unknown gatZ0sel ''%s'': use ''nominal''/''low''/''high''.', gatZ0sel);
end
switch gatZ0sel
    case 'nominal', Z0sel_pct = 10.8;
    case 'low', Z0sel_pct = 9.99;
    case 'high', Z0sel_pct = 11.61;
end

% ---- Task-12 additive: ovr forwarding to grounding (base defaults) ----
ovrFwd = struct();
if isfield(opts, 'ovr') && ~isempty(opts.ovr)
    if ~isstruct(opts.ovr) || ~isscalar(opts.ovr)
        error('phase4_seqZ:badOvr', 'opts.ovr must be a scalar struct.');
    end
    ovrFwd = opts.ovr;
else
    % direct ovr fields in opts (additive passthrough convenience)
    qflist = {'Rloading_tolfrac','ZN_UAT_scale','ZN_GATLV_scale','ZN_GATHV_ohm'};
    for qi = 1:numel(qflist)
        if isfield(opts, qflist{qi}), ovrFwd.(qflist{qi}) = opts.(qflist{qi}); end
    end
end

% ---- tertiary guard: MISSING must never enter arithmetic ----
if ~isnan(R.gat.Z_PT.value) || ~isnan(R.gat.Z_ST.value)
    error('phase4_seqZ:tertiaryFound', 'Registry Z_PT/Z_ST now non-NaN; spec update required before any tertiary arithmetic.');
end

Zbase = R.frozen.Zbase_ohm.value; % 529
R_eq = R.frozen.R_eq_ohm.value; % 0.0277725
X_eq = R.frozen.X_eq_ohm.value; % 0.1425655
B_eq_uS = R.frozen.B_eq_uS.value; % 3.937996

% ---- grounding (3ZN pu machine basis + LV 5-A equivalents) ----
if isempty(fieldnames(ovrFwd))
    G = phase4_grounding(ner);
else
    G = phase4_grounding(ner, ovrFwd);
end

% ---- positive-sequence grid for the k0g product (SAME dataset) ----
if grid == 'P'
    if ~isfield(opts, 'XoR_P')
        error('phase4_seqZ:badXoR', 'XoR_P required for dataset P.');
    end
    N = phase4_seqPN('P', opts.XoR_P);
else
    if isfield(opts, 'XoR_P')
        N = phase4_seqPN('S', opts.XoR_P);
    else
        N = phase4_seqPN('S', NaN);
    end
end

% ---- machine zero: Ra_pu + j*X0 transferred 100/458 ----
Snom_m = R.machine.Snom_MVA.value; % 458
Vnom_m = R.machine.Vnom_kV.value; % 22
Ra_ohm = R.machine.Ra_ohm.value; % 0.00089
X0_m = R.machine.X0.value; % 0.128
kM = 100 / Snom_m;
Ra_pu = (Ra_ohm / (Vnom_m^2 / Snom_m)) * kM;
Z0gen_pu = Ra_pu + 1j * (X0_m * kM);

% ---- NER 3ZN transferred to study base ----
Z3ZN_pu = G.Z3ZN_pu_machine * (100 / Snom_m);

% ---- GSUT zero 15.8% on 515 MVA ----
Z0g_pct = R.gsut.Z0_pct.value; % 15.8
Rg_pct = R.gsut.R_pct.value; % 0.21
X0g_pct = sqrt(Z0g_pct^2 - Rg_pct^2);
kG0 = 100 / 515;
Z0gsut_pu = (Rg_pct / 100) * kG0 + 1j * (X0g_pct / 100) * kG0;
ZN_GSUT_ohm = 0; % ENGINEERING_ASSUMPTION: GSUT neutral solid position, no measured record

% ---- UAT zero 9.3% on 25 MVA ----
Z0u_pct = R.uat.Z0_pct.value; % 9.3
Ru_pct = R.uat.R_pct.value; % 0.4
X0u_pct = sqrt(Z0u_pct^2 - Ru_pct^2);
kU0 = 100 / 25;
Z0uat_pu = (Ru_pct / 100) * kU0 + 1j * (X0u_pct / 100) * kU0;
ZN_UAT_ohm = G.ZN_UAT_ohm;
ZLVB = R.lv.Zbase_ohm.value; % 0.4356 ohm LV-zone base (correction record C1/C2)
Z3N_UAT_equiv_pu = G.Z3N_UAT_equiv_ohm / ZLVB;  % stamped branch value, single x3 upstream

% ---- GAT HV-LV zero on 25 MVA (selected tolerance applied; nominal = registry 10.8%) ----
Z0a_pct = Z0sel_pct;  % SOURCE-stated tolerance selection (never ENGINEERING_ASSUMPTION)
Ra_pct = R.gat.R_PS_pct.value; % 0.5
X0a_pct = sqrt(Z0a_pct^2 - Ra_pct^2);
kA0 = 100 / 25;
Z0gat_HVLV_pu = (Ra_pct / 100) * kA0 + 1j * (X0a_pct / 100) * kA0;

% ---- GAT T12 loop by leg (dual base identities; 100-MVA value stamped) ----
Z_H2_SHORT_pu = 1e-6;  % explicit short-limit on 100-MVA base (NOT zero: 6 orders
% below loop values ~0.4, far above solve floor; near-ideal short without 1/0)
switch gatLeg
    case 'H0'
        % approximation, open branch: tertiary open, no loop path
        Z_T0_loop_25MVA = NaN; Z_T0_loop_100MVA = NaN; Z_T0_loop_pu = NaN;
        tertiaryOpen = true;
    case 'H1'
        Z_T0_loop_25MVA = lambda_T * 0.108;
        Z_T0_loop_100MVA = Z_T0_loop_25MVA * 4;  % 25-MVA -> 100-MVA transfer
        Z_T0_loop_pu = Z_T0_loop_100MVA;  % stamped value (correction record C4)
        tertiaryOpen = false;
    case 'H2'
        % limiting sensitivity / stress case: explicit short-limit branch.
        % NOT a bracket proof, Z_PT/Z_ST MISSING.
        Z_T0_loop_25MVA = NaN; Z_T0_loop_100MVA = NaN;
        Z_T0_loop_pu = Z_H2_SHORT_pu;
        tertiaryOpen = false;
end

% ---- GAT LV neutral: 5-A equivalent, NOT solid (no ZN=0 path) ----
% Stamped branch is the Z3N equivalent (single x3 in grounding, never here).
ZN_GAT_LV_ohm = G.ZN_GAT_LV_ohm; % 5-A physical IN-reading, NOT solid
Z3N_GAT_equiv_pu = G.Z3N_GAT_equiv_ohm / ZLVB;

% ---- line zero from band multipliers ----
Z0line_R_pu = kR * R_eq / Zbase;
Z0line_X_pu = kX * X_eq / Zbase;
Z0line_B_pu = kB * B_eq_uS * 1e-6 * Zbase;

% ---- grid zero magnitude from SAME-dataset positive sequence ----
Z1grid_pu = N.Z1grid_R + 1j * N.Z1grid_X;
Z0grid_mag_pu = k0g * abs(Z1grid_pu);

auxShuntOpen = true;

% SOURCE-stated tolerance, NOT engineering assumption: provided as data
% for the T12 leg; implementation applies the gatZ0sel selection above.
% Nominal selection reproduces the registry 10.8% path EXACTLY.
gatZ0_tol = struct('nominal', 10.8, 'low', 9.99, 'high', 11.61, ...
    'status', 'SOURCE-stated tolerance');

% HV neutral ohms (additive H3HV envelope; base 0 is behaviour-identical)
ZN_GATHV_ohm = G.ZN_GATHV_ohm;
ZN_GATHV_pu = ZN_GATHV_ohm / Zbase;

Z = struct('Z0gen_pu', Z0gen_pu, 'Z3ZN_pu', Z3ZN_pu, ...
    'Z0gsut_pu', Z0gsut_pu, 'ZN_GSUT_ohm', ZN_GSUT_ohm, ...
    'Z0uat_pu', Z0uat_pu, 'ZN_UAT_ohm', ZN_UAT_ohm, 'Z3N_UAT_equiv_pu', Z3N_UAT_equiv_pu, ...
    'Z0gat_HVLV_pu', Z0gat_HVLV_pu, 'Z_T0_loop_pu', Z_T0_loop_pu, ...
    'Z_T0_loop_25MVA', Z_T0_loop_25MVA, 'Z_T0_loop_100MVA', Z_T0_loop_100MVA, ...
    'Z_H2_SHORT_pu', Z_H2_SHORT_pu, ...
    'tertiaryOpen', tertiaryOpen, 'ZN_GAT_LV_ohm', ZN_GAT_LV_ohm, ...
    'Z3N_GAT_equiv_pu', Z3N_GAT_equiv_pu, ...
    'ZN_GATHV_ohm', ZN_GATHV_ohm, 'ZN_GATHV_pu', ZN_GATHV_pu, ...
    'gatZ0sel', gatZ0sel, 'Z0gat_applied_pct', Z0sel_pct, ...
    'Z0line_R_pu', Z0line_R_pu, 'Z0line_X_pu', Z0line_X_pu, ...
    'Z0line_R', Z0line_R_pu, 'Z0line_X', Z0line_X_pu, ...
    'Z0line_B_pu', Z0line_B_pu, 'Z0line_B', Z0line_B_pu, ...
    'Z1grid_pu', Z1grid_pu, 'Z0grid_mag_pu', Z0grid_mag_pu, ...
    'auxShuntOpen', auxShuntOpen, 'gatZ0_tol', gatZ0_tol, ...
    'kR', kR, 'kX', kX, 'kB', kB, 'k0g', k0g, ...
    'gatLeg', gatLeg, 'lambda_T', lambda_T, 'grid', grid, 'ner', ner);
end
