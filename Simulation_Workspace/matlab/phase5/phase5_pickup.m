function P = phase5_pickup(device, Iload_A, Imin_fault_A)
%PHASE5_PICKUP  Pickup-setting methodology engine (Phase-5 Task 6).
%   P = PHASE5_PICKUP(device, Iload_A, Imin_fault_A) returns struct P with
%   fields setting/unit/basis/source/validation (+ device_id,
%   assumption_class) for one registry device row.
%
%   Inputs:
%     device       registry struct scalar (must carry device_id char; GEN-51
%                  additionally needs finite rated_A; no registry edit).
%     Iload_A      normal-load / frozen-flow anchor in PRIMARY A (scalar,
%                  finite, >= 0). For GIS-Q0-51 this IS the FL_anchor from
%                  phase4_ct_data.csv FL_anchor_kA column x1000.
%     Imin_fault_A minimum fault current for must-detect in PRIMARY A
%                  (scalar, finite, > 0). Phase OC uses min phase fault
%                  (LLL/LL/LLG bus, never LG earth); EF uses F1 LG 7.27 A.
%
%   Study settings (documented basis, never tuned-to-pass; honest CONFLICT
%   note in validation instead of retuning or erroring on shortfall):
%     GEN-51   setting = 1.25 x rated_A (registry 12019 A -> 15023.75 A
%              primary). BASIS above-rated-below-min-phase-fault. SOURCE
%              DERIVED-study-setting. VALIDATION min-phase-fault F-sweep
%              check in T16; no-trip-on-load vs Iload; T7 converts via CT.
%     GEN-51N  (or any ansi 51N / device_type ef) setting = 5 A primary
%              fixed study setting. Must-detect F1 LG 7.27200442799167 A
%              with margin 7.272/5 = 1.454 (~1.45). 5 A via 15000/1 =
%              0.33 mA secondary. Flagged SENSITIVE with limitation
%              (susceptible to noise). SOURCE ENGINEERING_ASSUMPTION,
%              scope SENSITIVITY.
%     GIS-Q0-51 setting = 1.2 x Iload_A (Iload = frozen-flow FL_anchor,
%              PRIMARY A). Anchors from
%              results/phase4_fault/production/phase4_ct_data.csv
%              FL_anchor_kA column (frozen Phase-3 flows, Task-13
%              derivation from phase3_system_summary.csv LF360_GAT_OUT):
%              LINE_Q9 0.869956651959241 kA (GIS-to-remote export through
%              Q0 convention), GRID_Q 0.870067239184327 kA, GSUT_HV
%              0.870772573866956 kA. SOURCE DERIVED-study-setting.
%     other OC setting = 1.2 x max(rated_A, Iload_A) (or 1.2 x Iload_A
%              when no finite rated_A). BASIS above-full-load-below-min-
%              fault. SOURCE DERIVED-study-setting.
%     LINE-21-note / REMOTE-GRID-boundary -> error (no settings invented,
%              NOT DETERMINABLE FROM AVAILABLE DATA). GIS-Q0-50 high-set ->
%              error DISABLED-unless-justified (no high-set invented).
%
%   Output setting is in PRIMARY amperes; T7 (phase5_time) converts via CT
%   (phase5_ct) to secondary before curve evaluation. BASIS strings are
%   verbatim-stable for phase5_relay_settings.csv (Task 17).
%   All errors are 'phase5'-prefixed.
if nargin ~= 3
    error('phase5_pickup:args', 'usage: P = phase5_pickup(device, Iload_A, Imin_fault_A).');
end
if ~isstruct(device) || ~isscalar(device) || ~isfield(device, 'device_id')
    error('phase5_pickup:device', 'device must be a scalar struct with device_id (registry row).');
end
idraw = device.device_id;
if isstring(idraw) && isscalar(idraw)
    idraw = char(idraw);
end
if ~ischar(idraw) || isempty(strtrim(idraw))
    error('phase5_pickup:device', 'device.device_id must be non-empty char (registry row).');
end
id = strtrim(idraw);
if ~isnumeric(Iload_A) || ~isscalar(Iload_A) || ~isreal(Iload_A) ...
        || ~isfinite(Iload_A) || Iload_A < 0
    error('phase5_pickup:load', 'Iload_A must be a real finite scalar >= 0 (PRIMARY A anchor).');
end
if ~isnumeric(Imin_fault_A) || ~isscalar(Imin_fault_A) || ~isreal(Imin_fault_A) ...
        || ~isfinite(Imin_fault_A) || Imin_fault_A <= 0
    error('phase5_pickup:fault', 'Imin_fault_A must be a real finite scalar > 0 (PRIMARY A).');
end
Iload_A = double(Iload_A);
Imin_fault_A = double(Imin_fault_A);
if strcmp(id, 'LINE-21-note') || strcmp(id, 'REMOTE-GRID-boundary')
    error('phase5_pickup:unsupported', 'phase5_pickup: %s has no settings (NOT DETERMINABLE FROM AVAILABLE DATA; NOTE/boundary only).', id);
end
if strcmp(id, 'GIS-Q0-50')
    error('phase5_pickup:disabled', 'phase5_pickup: GIS-Q0-50 high-set DISABLED-unless-justified (NOT DETERMINABLE FROM AVAILABLE DATA; no high-set invented).');
end
isEF = strcmp(id, 'GEN-51N');
if ~isEF
    if isfield(device, 'ansi')
        a = device.ansi;
        if isstring(a) && isscalar(a), a = char(a); end
        if ischar(a) && strcmp(strtrim(a), '51N'), isEF = true; end
    end
end
if ~isEF
    if isfield(device, 'device_type')
        dt = device.device_type;
        if isstring(dt) && isscalar(dt), dt = char(dt); end
        if ischar(dt) && strcmp(strtrim(dt), 'ef'), isEF = true; end
    end
end
if strcmp(id, 'GEN-51')
    if ~isfield(device, 'rated_A') || ~isnumeric(device.rated_A) ...
            || ~isscalar(device.rated_A) || ~isreal(device.rated_A) ...
            || ~isfinite(device.rated_A) || device.rated_A <= 0
        error('phase5_pickup:rated', 'phase5_pickup: GEN-51 needs finite rated_A (registry 12019 A).');
    end
    rated = double(device.rated_A);
    setting = 1.25 * rated;
    unit = 'A-primary';
    basis = sprintf('above-rated-below-min-phase-fault:1.25xrated-%.0fA=%.2fA-primary', rated, setting);
    source = 'DERIVED-study-setting:1.25xrated-from-phase5_registry-gen-12019A';
    if Iload_A > 0
        mLoad = setting / Iload_A;
    else
        mLoad = Inf;
    end
    mFault = Imin_fault_A / setting;
    validation = sprintf(['no-trip-on-load-vs-Iload-%.3fA(margin-%.3f);' ...
        'must-detect-vs-Imin-%.3fA(margin-%.3f);' ...
        'min-phase-fault-F-sweep-check-in-T16;T7-converts-via-CT'], ...
        Iload_A, mLoad, Imin_fault_A, mFault);
    if ~(setting > Iload_A)
        validation = [validation ';CONFLICT:pickup-below-Iload-risks-trip-on-load-honest-FAIL-not-retuned'];
    end
    if ~(setting < Imin_fault_A)
        validation = [validation ';CONFLICT:pickup-above-Imin-fails-must-detect-honest-FAIL-not-retuned'];
    end
    assumption_class = 'PRIMARY';
elseif isEF
    setting = 5;
    unit = 'A-primary';
    basis = 'must-detect-F1-LG-7.27A-primary:5A-with-margin-1.45';
    source = 'ENGINEERING_ASSUMPTION-study-setting-SENSITIVE:5A-primary-via-15000/1-0.33mA-secondary';
    mFault = Imin_fault_A / setting;
    validation = sprintf(['detects-F1-LG-%.5fA-with-margin-%.3f;' ...
        'SENSITIVE-susceptible-to-noise-reported-as-limitation;' ...
        'T7-converts-via-CT-15000/1'], Imin_fault_A, mFault);
    if ~(setting > Iload_A)
        validation = [validation ';CONFLICT:pickup-below-Iload-risks-trip-on-load-honest-FAIL-not-retuned'];
    end
    if ~(setting < Imin_fault_A)
        validation = [validation ';CONFLICT:pickup-above-Imin-fails-must-detect-honest-FAIL-not-retuned'];
    end
    assumption_class = 'SENSITIVITY';
elseif strcmp(id, 'GIS-Q0-51')
    if ~(Iload_A > 0)
        error('phase5_pickup:load', 'phase5_pickup: GIS-Q0-51 needs FL_anchor Iload_A > 0 (from phase4_ct_data.csv FL_anchor_kA x1000).');
    end
    setting = 1.2 * Iload_A;
    unit = 'A-primary';
    basis = 'above-full-load-below-min-fault:1.2xFL_anchor-from-phase4_ct_data.csv-FL_anchor_kA-column';
    source = ['DERIVED-study-setting:1.2xFL_anchor-LINE_Q9-0.869956651959241kA-' ...
        'GRID_Q-0.870067239184327kA-GSUT_HV-0.870772573866956kA-' ...
        'from-phase4_ct_data.csv-frozen-flow-anchor-see-task-13-FL-derivation'];
    mLoad = setting / Iload_A;
    mFault = Imin_fault_A / setting;
    validation = sprintf(['no-trip-on-load-vs-FL_anchor-%.6fA(margin-%.3f);' ...
        'must-detect-vs-Imin-%.3fA(margin-%.3f);' ...
        'min-fault-F-sweep-check-in-T16;T7-converts-via-CT'], ...
        Iload_A, mLoad, Imin_fault_A, mFault);
    if ~(setting > Iload_A)
        validation = [validation ';CONFLICT:pickup-below-Iload-risks-trip-on-load-honest-FAIL-not-retuned'];
    end
    if ~(setting < Imin_fault_A)
        validation = [validation ';CONFLICT:pickup-above-Imin-fails-must-detect-honest-FAIL-not-retuned'];
    end
    assumption_class = 'PRIMARY';
else
    hasRated = isfield(device, 'rated_A') && isnumeric(device.rated_A) ...
        && isscalar(device.rated_A) && isreal(device.rated_A) ...
        && isfinite(device.rated_A) && device.rated_A > 0;
    if hasRated
        rated = double(device.rated_A);
        refA = max(rated, Iload_A);
        setting = 1.2 * refA;
        unit = 'A-primary';
        basis = sprintf('above-full-load-below-min-fault:1.2xmax(rated-%.3fA,Iload-%.3fA)', rated, Iload_A);
    else
        if ~(Iload_A > 0)
            error('phase5_pickup:load', 'phase5_pickup: %s needs finite rated_A or Iload_A > 0 (NOT DETERMINABLE FROM AVAILABLE DATA).', id);
        end
        setting = 1.2 * Iload_A;
        unit = 'A-primary';
        basis = 'above-full-load-below-min-fault:1.2xIload-no-rated-available';
    end
    source = 'DERIVED-study-setting:1.2x-load-anchor';
    if Iload_A > 0
        mLoad = setting / Iload_A;
    else
        mLoad = Inf;
    end
    mFault = Imin_fault_A / setting;
    validation = sprintf(['no-trip-on-load-vs-Iload-%.3fA(margin-%.3f);' ...
        'must-detect-vs-Imin-%.3fA(margin-%.3f);' ...
        'min-fault-F-sweep-check-in-T16;T7-converts-via-CT'], ...
        Iload_A, mLoad, Imin_fault_A, mFault);
    if ~(setting > Iload_A)
        validation = [validation ';CONFLICT:pickup-below-Iload-risks-trip-on-load-honest-FAIL-not-retuned'];
    end
    if ~(setting < Imin_fault_A)
        validation = [validation ';CONFLICT:pickup-above-Imin-fails-must-detect-honest-FAIL-not-retuned'];
    end
    assumption_class = 'PRIMARY';
end
P = struct('setting', setting, 'unit', unit, 'basis', basis, ...
    'source', source, 'validation', validation, ...
    'device_id', id, 'assumption_class', assumption_class);
end
