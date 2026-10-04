function Z = phase4_grounding(variant, ovr)
%PHASE4_GROUNDING  Grounding equivalents: NER plus UAT/GAT LV 5-A bounds.
%
%   Z = PHASE4_GROUNDING('primary') returns the primary additive HV-side
%   NER equivalent together with LV 5-A bounded equivalents. The primary
%   HV path adds the quoted 60-ohm HV resistor to the LV 2.62-ohm
%   resistor reflected through the distribution-transformer turns ratio.
%
%   Z = PHASE4_GROUNDING('quoted60') keeps the quoted 60-ohm HV resistor
%   visible as an alternative reading; the reflected LV term is still
%   reported in R_refl for traceability.
%
%   Z = PHASE4_GROUNDING(variant, ovr) applies the additive Task-12
%   override struct ovr (all fields optional; base defaults reproduce
%   current outputs EXACTLY):
%     Rloading_tolfrac in [-0.1,0.1], default 0: scales the LV 2.62-ohm
%       R_loading (ENGINEERING_ASSUMPTION band) before reflection.
%     ZN_UAT_scale in [0.2,3.0], default 1: multiplies the UAT LV 5-A
%       bounded equivalent (H1-base wording: E5 leg).
%     ZN_GATLV_scale in [0.2,3.0], default 1: multiplies the GAT LV 5-A
%       bounded equivalent (H1-base wording: H3 leg; GAT LV never solid).
%     ZN_GATHV_ohm in [0,5] ohm, default 0: HV neutral ohms carried for
%       the H3HV leg (engineering envelope, additive only; base 0 is
%       behaviour-identical).
%   ZN_UAT_ohm / ZN_GAT_LV_ohm are the PHYSICAL neutral impedances under
%   the IN-reading (neutral current IN = faulted-phase current for LG):
%   ZN = Vph/5 with Vph = 6900/sqrt(3) so that a bolted LV LG fault draws
%   Ia = Vph/ZN = 5 A (source: "impedance that limits the fault to 5 A").
%   The zero-sequence branch carries I0 = IN/3, hence the STAMPED branch
%   value is Z3N_*_equiv_ohm = 3*ZN (single counting, HERE, never
%   downstream): Ia = 3*Vf/(Z1+Z2+Z0) with Z0 ~ Z3N gives Ia = 5 A.
%   ADJUDICATION (correction record C7): stamping 796.743 directly (no x3)
%   would give Ia = 15 A, contradicting the 5-A source limit and the
%   generator-NER precedent (R_NER_HV physical + 3ZN stamped, F1 LG = 7.25 A
%   hand-check). The x3 below is therefore REQUIRED, applied exactly once.
%   ovr scales (ZN_UAT_scale etc.) act on the PHYSICAL value first.
%
%   Out-of-range or unknown ovr fields error with a 'phase4'-prefixed
%   identifier. No IEC 60909 compliance claim.
%
%   Any other variant string (including 'solid') is rejected with an
%   error: a zero-impedance NER path is forbidden by construction and has
%   no code path here.

if nargin < 1
    error('phase4_grounding:variant', 'Variant required: ''primary'' or ''quoted60''.');
end
if ~(ischar(variant) || (isstring(variant) && isscalar(variant)))
    error('phase4_grounding:variant', 'Variant must be ''primary'' or ''quoted60''.');
end
variant = char(variant);

% ---- Task-12 additive overrides (base defaults reproduce exactly) ----
Rloading_tolfrac = 0;
ZN_UAT_scale = 1;
ZN_GATLV_scale = 1;
ZN_GATHV_ohm = 0;
if nargin >= 2 && ~isempty(ovr)
    if ~isstruct(ovr) || ~isscalar(ovr)
        error('phase4_grounding:badOvr', 'ovr must be a scalar struct.');
    end
    fn = fieldnames(ovr);
    for i = 1:numel(fn)
        switch fn{i}
            case 'Rloading_tolfrac', Rloading_tolfrac = ovr.(fn{i});
            case 'ZN_UAT_scale', ZN_UAT_scale = ovr.(fn{i});
            case 'ZN_GATLV_scale', ZN_GATLV_scale = ovr.(fn{i});
            case 'ZN_GATHV_ohm', ZN_GATHV_ohm = ovr.(fn{i});
            otherwise
                error('phase4_grounding:badOvr', 'Unknown ovr field ''%s''.', fn{i});
        end
    end
end
if ~(isnumeric(Rloading_tolfrac) && isscalar(Rloading_tolfrac) && isfinite(Rloading_tolfrac) && Rloading_tolfrac >= -0.1 && Rloading_tolfrac <= 0.1)
    error('phase4_grounding:badOvr', 'ovr.Rloading_tolfrac must be finite in [-0.1,0.1].');
end
if ~(isnumeric(ZN_UAT_scale) && isscalar(ZN_UAT_scale) && isfinite(ZN_UAT_scale) && ZN_UAT_scale >= 0.2 && ZN_UAT_scale <= 3.0)
    error('phase4_grounding:badOvr', 'ovr.ZN_UAT_scale must be finite in [0.2,3.0].');
end
if ~(isnumeric(ZN_GATLV_scale) && isscalar(ZN_GATLV_scale) && isfinite(ZN_GATLV_scale) && ZN_GATLV_scale >= 0.2 && ZN_GATLV_scale <= 3.0)
    error('phase4_grounding:badOvr', 'ovr.ZN_GATLV_scale must be finite in [0.2,3.0].');
end
if ~(isnumeric(ZN_GATHV_ohm) && isscalar(ZN_GATHV_ohm) && isfinite(ZN_GATHV_ohm) && ZN_GATHV_ohm >= 0 && ZN_GATHV_ohm <= 5)
    error('phase4_grounding:badOvr', 'ovr.ZN_GATHV_ohm must be finite in [0,5] ohm.');
end

% ---- distribution-transformer turns ratio (registry-style literals) ----
Vhv_V = 22000 / sqrt(3);   % HV phase voltage, V (22 kV machine terminal basis)
Vlv_V = 500;               % LV side reference voltage, V
n = Vhv_V / Vlv_V;         % turns ratio, dimensionless

% ---- HV-side NER path ---------------------------------------------------
R_LV_base_ohm = 2.62;        % LV-side NER resistor, ohm (source record)
R_LV_ohm = R_LV_base_ohm * (1 + Rloading_tolfrac);  % ENGINEERING_ASSUMPTION band
R_HV_quoted_ohm = 60;      % quoted HV-side NER resistor, ohm (source record)
R_refl = n^2 * R_LV_ohm;   % LV resistor reflected to HV side, ohm

switch variant
    case 'primary'
        % Primary reading: additive path, quoted HV plus reflected LV.
        R_NER_HV = R_HV_quoted_ohm + R_refl;
    case 'quoted60'
        % Alternative reading: quoted HV resistor kept visible on its own.
        R_NER_HV = R_HV_quoted_ohm;
    otherwise
        error('phase4_grounding:variant', 'Unknown grounding variant ''%s''; solid NER is forbidden.', variant);
end

ZN_ohm = R_NER_HV;         % HV-side neutral equivalent, ohm
Z3ZN_ohm = 3 * R_NER_HV;   % three-times neutral for sequence input, ohm

% ---- machine-base per-unit (22 kV / 458 MVA QUALIFIED basis) ------------
Zbase_machine_ohm = 22^2 / 458;   % machine Zbase, ohm (V_kV^2 / S_MVA)
Z3ZN_pu_machine = Z3ZN_ohm / Zbase_machine_ohm;

% ---- LV 5-A bounded equivalents (6.9 kV LV current-limit basis) ---------
Vph_LV_V = 6900 / sqrt(3);   % LV phase voltage, V (6.9 kV LV basis)
ZN_UAT_ohm = (Vph_LV_V / 5) * ZN_UAT_scale;       % UAT LV physical neutral, ohm (IN-reading)
ZN_GAT_LV_ohm = (Vph_LV_V / 5) * ZN_GATLV_scale;    % GAT LV physical neutral, ohm (NOT solid)
ZN_UAT_alt_ohm = Vph_LV_V / 15;  % alternative zero-sequence current reading, ohm
Z3N_UAT_equiv_ohm = 3 * ZN_UAT_ohm;      % STAMPED zero-branch value (single x3, here only)
Z3N_GAT_equiv_ohm = 3 * ZN_GAT_LV_ohm;   % STAMPED zero-branch value (single x3, here only)

Z = struct( ...
    'n', n, ...
    'R_refl', R_refl, ...
    'R_NER_HV', R_NER_HV, ...
    'ZN_ohm', ZN_ohm, ...
    'Z3ZN_ohm', Z3ZN_ohm, ...
    'Z3ZN_pu_machine', Z3ZN_pu_machine, ...
    'ZN_UAT_ohm', ZN_UAT_ohm, ...
    'ZN_GAT_LV_ohm', ZN_GAT_LV_ohm, ...
    'Z3N_UAT_equiv_ohm', Z3N_UAT_equiv_ohm, ...
    'Z3N_GAT_equiv_ohm', Z3N_GAT_equiv_ohm, ...
    'ZN_UAT_alt_ohm', ZN_UAT_alt_ohm, ...
    'NGT_mode', 'neglected', ...
    'Rloading_tolfrac', Rloading_tolfrac, ...
    'ZN_UAT_scale', ZN_UAT_scale, ...
    'ZN_GATLV_scale', ZN_GATLV_scale, ...
    'ZN_GATHV_ohm', ZN_GATHV_ohm, ...
    'R_LV_ohm', R_LV_ohm);
end
