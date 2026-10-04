function M = phase5b_mindetect(T40, devices)
%PHASE5B_MINDETECT  Per-CT min-detect over zone-relevant branch currents (Phase-5b Task C6).
%   M = PHASE5B_MINDETECT(T40, devices) replaces the V9 totals-based
%   min-detect with one struct row per (device, element in
%   phase/residual/negseq). Each row carries the minimum BRANCH current
%   over zone-relevant faults, the C4 study pickup (via phase5b_pickup),
%   the margin (min_branch_A / pickup_A) and a verdict:
%     margin >= 1               -> 'DETECT'
%     margin <  1 (determinable) -> 'BLIND-SPOT-HONEST' (non-PASS, never tuned)
%     not determinable           -> 'NOT-DETERMINABLE' (honest, never invented)
%
%   Row fields (locked): device_id, element, zone_locs, branch_tag,
%   n_zone, n_used, min_branch_A, min_loc, min_type, min_case, pickup_A,
%   pickup_src, margin, verdict, determinable, reason.
%
%   Zone relevance (locked): GEN devices <- F1/F2 rows (GEN_Q branch leg
%   for phase; 3I0 = 3x NER series leg for residual; negseq branch NOT
%   DETERMINABLE); GSUT-HV <- F1/F2/F3 rows (GSUT_HV leg); GIS-Q0 <-
%   F3/F4/F5 rows (LINE_Q9 through-convention magnitude: |leg_LINE_total|
%   for non-F4 rows; F4 rows use the same column with the documented
%   caveat that toward-fault B1+B2 sums both infeeds, so the F4 value
%   overstates the GIS outfeed — the GIS min binds at F5 regardless).
%
%   Branch-current doctrine (hardened): ONLY leg_* columns of the
%   phase5_import T40 join are read (C5-pinned branch-through-current
%   semantics). Fault totals are never a proxy for relay current: no
%   fault-point magnitude column is referenced anywhere below.
%
%   Stored production legs are |Ia| magnitudes only (phase4_handoff
%   legRow). Phase-element candidate types are therefore LLL (symmetric:
%   all phases equal |Ia|) and LG (A-phase faulted; B/C ~ 0 per the
%   phase4 LG_branch0 diagnostic): on LL/LLG rows the stored |Ia| is the
%   UNFAULTED-phase current and understates what B/C phase elements see,
%   so LL/LLG phase coverage is recorded NOT-DETERMINABLE-by-type
%   (counted in the reason string, never silently dropped). Residual
%   scope is the LG sensitivity-defining fault (C4 51N study basis
%   must-detect-F1-LG); LLG residual rows are observed-but-out-of-scope
%   and their observed 3I0 minimum is quoted in the reason string as a
%   flagged limitation, never as a verdict input. Negseq branch I2 is
%   unavailable in T40/production CSVs; fault-point sequence current is
%   a total and is never derived per the branch-current doctrine, so
%   every negseq row is NOT-DETERMINABLE.
%
%   Pickups come from the phase5b_pickup C4 rules (registry carries NaN +
%   rule tags; nothing hard-coded here). Load anchors passed to the
%   pickup engine are locked study constants: GEN devices Imax 14309 A
%   (ledger GEN-Imax-14309); GSUT-HV-51 GSUT_HV flow anchor 870.7726 A
%   (rule takes max with rated 1150 A, so 1380 A); GIS-Q0-51 LINE_Q9 flow
%   anchor 869.9567 A; GEN-51N study 0 A (fixed 5 A retained case). The
%   Imin argument is the computed branch minimum itself (settings are
%   load-based, so there is no circularity; validation margins stay
%   consistent). Devices whose pickup errors (DISABLED high-set, notes,
%   boundaries) yield NOT-DETERMINABLE rows quoting the engine reason.
%
%   All errors are 'phase5b'-prefixed.
if nargin ~= 2
    error('phase5b_mindetect:args', 'usage: M = phase5b_mindetect(T40, devices).');
end
if ~istable(T40) || height(T40) < 1
    error('phase5b_mindetect:schema', 'T40 must be a non-empty table (phase5_import backbone).');
end
need = {'fault_location', 'fault_type', 'caseID', 'leg_GEN_kA', ...
    'leg_GSUT_HV_kA', 'leg_LINE_total_kA', 'leg_NER_earth_kA'};
for k = 1:numel(need)
    if ~any(strcmp(T40.Properties.VariableNames, need{k}))
        error('phase5b_mindetect:schema', 'T40 missing required branch column %s.', need{k});
    end
end
if ~isstruct(devices) || isempty(devices) || ~isfield(devices, 'device_id')
    error('phase5b_mindetect:devices', 'devices must be a non-empty struct array with device_id (registry rows).');
end

ELS = {'phase', 'residual', 'negseq'};
M = repmat(emptyRow(), 0, 1);
for d = 1:numel(devices)
    dev = devices(d);
    idraw = dev.device_id;
    if isstring(idraw) && isscalar(idraw)
        idraw = char(idraw);
    end
    if ~ischar(idraw) || isempty(strtrim(idraw))
        error('phase5b_mindetect:devices', 'devices(%d).device_id must be non-empty char.', d);
    end
    id = strtrim(idraw);
    [zone, legCol, zoneTag] = zoneOf(id);
    kind = kindOf(dev, id);
    for e = 1:numel(ELS)
        M(end + 1, 1) = buildRow(T40, dev, id, ELS{e}, zone, legCol, zoneTag, kind); %#ok<AGROW>
    end
end
end

function r = emptyRow()
r = struct('device_id', '', 'element', '', 'zone_locs', '', ...
    'branch_tag', '', 'n_zone', NaN, 'n_used', NaN, 'min_branch_A', NaN, ...
    'min_loc', '', 'min_type', '', 'min_case', '', 'pickup_A', NaN, ...
    'pickup_src', '', 'margin', NaN, 'verdict', 'NOT-DETERMINABLE', ...
    'determinable', false, 'reason', '');
end

function [zone, legCol, zoneTag] = zoneOf(id)
%ZONEOF  Locked zone relevance per device family.
if strncmp(id, 'GEN-', 4)
    zone = {'F1', 'F2'};
    legCol = 'leg_GEN_kA';
    zoneTag = 'F1+F2';
elseif strncmp(id, 'GSUT-HV', 7)
    zone = {'F1', 'F2', 'F3'};
    legCol = 'leg_GSUT_HV_kA';
    zoneTag = 'F1+F2+F3';
elseif strncmp(id, 'GIS-Q0', 6)
    zone = {'F3', 'F4', 'F5'};
    legCol = 'leg_LINE_total_kA';
    zoneTag = 'F3+F4+F5';
else
    zone = {};
    legCol = '';
    zoneTag = '';
end
end

function kind = kindOf(dev, id)
%KINDOF  Phase-OC vs earth-fault device kind (registry device_type wins; id fallback).
if isfield(dev, 'device_type')
    dt = dev.device_type;
    if isstring(dt) && isscalar(dt)
        dt = char(dt);
    end
    if ischar(dt) && strcmp(strtrim(dt), 'ef')
        kind = 'EF';
        return;
    end
    if ischar(dt) && (strcmp(strtrim(dt), 'oc') || strcmp(strtrim(dt), 'oc-instantaneous'))
        kind = 'OC';
        return;
    end
end
if ~isempty(strfind(id, '51N'))
    kind = 'EF';
else
    kind = 'OC';
end
end

function r = buildRow(T40, dev, id, el, zone, legCol, zoneTag, kind)
r = emptyRow();
r.device_id = id;
r.element = el;
r.zone_locs = zoneTag;
if isempty(zone)
    r.branch_tag = 'NOT-APPLICABLE-no-zone-mapping-for-device';
    r.n_zone = 0;
    r.n_used = 0;
    r.reason = sprintf(['zone-not-mapped:%s-has-no-zone-relevant-faults;' ...
        'no-pickup-no-margin-no-verdict-beyond-NOT-DETERMINABLE'], id);
    return;
end
zhit = ismember(T40.fault_location, zone);
r.n_zone = sum(zhit);
if strcmp(el, 'negseq')
    r.branch_tag = 'NOT-APPLICABLE-branch-I2-unavailable-in-T40';
    r.n_used = 0;
    r.reason = sprintf(['negseq-branch-NOT-DETERMINABLE:branch-I2-unavailable-in-T40-' ...
        'production-CSVs;fault-point-sequence-current-is-a-total-never-derived-' ...
        'per-branch-current-doctrine;zone-%s-rows-%d-untouched'], zoneTag, r.n_zone);
    return;
end
if strcmp(el, 'phase') && ~strcmp(kind, 'OC')
    r.branch_tag = 'NOT-APPLICABLE-phase-element-on-EF-device';
    r.n_used = 0;
    r.reason = sprintf(['phase-element-not-applicable:%s-is-earth-fault-device;' ...
        'phase-coverage-NOT-DETERMINABLE;zone-%s-rows-%d-untouched'], id, zoneTag, r.n_zone);
    return;
end
if strcmp(el, 'residual') && ~(strcmp(kind, 'EF') && strcmp(zoneTag, 'F1+F2'))
    r.branch_tag = 'NOT-APPLICABLE-branch-residual-unavailable-in-T40';
    r.n_used = 0;
    if strcmp(kind, 'EF')
        why = 'residual-branch-only-via-NER-series-leg-valid-in-GEN-zone-F1F2';
    else
        why = 'residual-element-not-applicable-to-phase-device';
    end
    r.reason = sprintf(['residual-NOT-DETERMINABLE:%s:%s;' ...
        'zone-%s-rows-%d-untouched'], id, why, zoneTag, r.n_zone);
    return;
end
if strcmp(el, 'phase')
    % |Ia|-representative types only (LL/LLG stored |Ia| is unfaulted-phase).
    typeOK = ismember(T40.fault_type, {'LLL', 'LG'});
    vals = abs(double(T40.(legCol))) * 1000;
    r.branch_tag = sprintf('%s-magnitude-via-%s-SOURCE-BACKED', shortTag(legCol), legCol);
    scopeNote = 'LL-LLG-excluded-unfaulted-phase-Ia-only-in-production-data';
elseif strcmp(el, 'residual')
    % GEN-zone 3I0 from the NER series leg (LG sensitivity scope; LLG observed-only).
    typeOK = strcmp(T40.fault_type, 'LG');
    vals = 3 * abs(double(T40.leg_NER_earth_kA)) * 1000;
    r.branch_tag = '3I0-from-leg_NER_earth_kA-x3-series-SOURCE-BACKED';
    scopeNote = 'LLG-observed-only-out-of-LG-sensitivity-scope';
else
    error('phase5b_mindetect:internal', 'unknown element %s.', el);
end
cand = zhit & typeOK & isfinite(vals);
r.n_used = sum(cand);
if r.n_used < 1
    r.reason = sprintf(['no-finite-branch-current:%s-%s-zone-%s-candidate-rows-0;' ...
        'scope-%s;NOT-DETERMINABLE'], id, el, zoneTag, scopeNote);
    return;
end
[mn, ix] = min(vals(cand));
rows = find(cand);
r.min_branch_A = mn;
r.min_loc = char(T40.fault_location(rows(ix)));
r.min_type = char(T40.fault_type(rows(ix)));
r.min_case = char(T40.caseID(rows(ix)));
nDrop = r.n_zone - r.n_used;
% Observed-but-out-of-scope LLG residual (transparency, never a verdict input).
extra = '';
if strcmp(el, 'residual')
    llg = zhit & strcmp(T40.fault_type, 'LLG') & isfinite(vals);
    if any(llg)
        extra = sprintf(';LLG-observed-3I0-min-%.3fA-out-of-scope-flagged-limitation', ...
            min(vals(llg)));
    end
end
% C4 pickup for the computed branch minimum (settings are load-based).
Iload = loadAnchor(id);
try
    P = phase5b_pickup(dev, Iload, mn);
catch ME
    r.pickup_A = NaN;
    r.pickup_src = 'NOT-DETERMINABLE-pickup-engine-refused';
    r.margin = NaN;
    r.reason = sprintf(['pickup-refused:%s-%s-min-%.3fA-at-%s-%s-%s;' ...
        'engine-%s;NOT-DETERMINABLE'], id, el, mn, r.min_loc, r.min_type, ...
        r.min_case, ME.identifier);
    return;
end
r.pickup_A = P.setting;
r.pickup_src = P.source;
r.margin = mn / P.setting;
r.determinable = true;
if r.margin >= 1
    r.verdict = 'DETECT';
else
    r.verdict = 'BLIND-SPOT-HONEST';
end
r.reason = sprintf(['min-over-%d-of-%d-zone-rows(scope-%s%s);' ...
    'branch-%s=%.3fA-at-%s-%s-%s-vs-pickup-%.3fA(margin-%.4f);verdict-%s'], ...
    r.n_used, r.n_zone, scopeNote, extra, r.branch_tag, mn, ...
    r.min_loc, r.min_type, r.min_case, P.setting, r.margin, r.verdict);
end

function t = shortTag(legCol)
%SHORTTAG  Through-current tag label for a T40 branch column (rename contract: branch-through-current).
switch legCol
    case 'leg_GEN_kA'
        t = 'GEN_Q-branch-through-current';
    case 'leg_GSUT_HV_kA'
        t = 'GSUT_HV-branch-through-current';
    case 'leg_LINE_total_kA'
        t = 'LINE_Q9-through-convention-branch-through-current';
    otherwise
        t = 'branch-through-current';
end
end

function a = loadAnchor(id)
%LOADANCHOR  Locked study load anchors (PRIMARY A) for the C4 pickup rules.
if strncmp(id, 'GEN-51N', 7)
    a = 0;  % fixed 5 A retained sensitive case (load-independent)
elseif strncmp(id, 'GEN-', 4)
    a = 14309;  % generator max operating current (ledger GEN-Imax-14309)
elseif strncmp(id, 'GSUT-HV', 7)
    a = 870.772573866956;  % GSUT_HV flow anchor (rule takes max with rated 1150 A)
elseif strncmp(id, 'GIS-Q0', 6)
    a = 869.956651959241;  % LINE_Q9 flow anchor from ct_data FL_anchor
else
    a = 0;
end
end
