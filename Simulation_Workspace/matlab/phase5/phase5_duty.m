function D = phase5_duty(Tthrough, ratings)
%PHASE5_DUTY  Breaker-duty engine, separate from coordination (Phase-5 Task 10).
%   D = PHASE5_DUTY(Tthrough, ratings) builds the breaker-duty table from
%   the phase5_import backbone table (2 cases x 5 locs x 4 types Ikpp rows
%   with through-current leg join). One duty row per input row plus exactly
%   one 50-kA estimated-reference NOTE row.
%
%   LEG-SEMANTICS DECISION (F4 investigation, binding; T8 carry-forward):
%   contributions legs are fault-point branch decompositions, ct_data
%   through_path rows are breaker-path currents. For F4 LLL OUT the
%   contributions leg_LINE_total_kA (51.058) is the FAULT-POINT SUM of both
%   circuits (B1 14.325 + B2 36.737 ~= 51.058) while ct_data LINE_Q9
%   (3.1721) is the BREAKER-PATH current (plant infeed, identical to
%   leg_GSUT_HV_kA). Duty uses the breaker-path branch, never the sum.
%   Decision table (Q0 = 52-1 plant outlet breaker at 230-kV GIS):
%     F1/F2 (B22 gen-bus fault) : leg_GRID_kA (grid infeed flowing through
%       Q0 toward the generator fault; e.g. F1 LLL OUT 72.105). The net
%       total (126.21) is a bus total, never duty.
%     F3 (GIS 230-kV line-bay fault, Q0 upstream of fault): leg_GSUT_HV_kA
%       (plant infeed through Q0; e.g. F3 LLL OUT 3.2184). ct_data LINE_Q9
%       at F3 equals GRID_Q (47.37, remote/line-side contribution) and is
%       NOT the Q0 plant-breaker path; the net total (50.53) is a bus
%       total, never duty.
%     F4 (mid-line m = 0.5 primary): leg_GSUT_HV_kA == ct_data LINE_Q9
%       (plant infeed through Q0; e.g. F4 LLL OUT 3.1721). leg_LINE_total
%       (51.058 = B1 + B2 fault-point sum) and leg_GRID (47.946 remote
%       infeed) are never through Q0, never duty. leg_LINE_B1/B2 are
%       per-circuit fault-point contributions, never breaker-path, never
%       substituted even when the plant leg is missing.
%     F5 (remote-bus fault): leg_GSUT_HV_kA == ct_data LINE_Q9 (plant
%       infeed through Q0 toward the remote fault; e.g. F5 LLL OUT 3.2076).
%       leg_GRID (49.941 remote infeed) and the net total (53.087) are
%       never through Q0, never duty.
%   Q0-BAY-POSITION ASSUMPTION (stamped, never silent): Q0 (52-1) is taken
%   as the plant outlet breaker at 230-kV GIS, so grid-zone (F3/F4/F5)
%   through-current is the plant infeed and generator-zone (F1/F2)
%   through-current is the grid infeed. T19 records the residual bay-position
%   ambiguity as a limitation. Q1/Q2/Q9 are disconnectors (no interrupting
%   rating, NEVER duty - a rating naming them is rejected with error);
%   Q51/Q52/Q8 are earthing (never duty).
%
%   Duty rule: symmetrical RMS THROUGH-current (branch I_sym_kA) versus a
%   DOCUMENTED rating. Rating MISSING (no ratings input, no Q0 row, NaN /
%   non-positive rating, or empty source) -> rating_kA NaN, basis carries a
%   MISSING tag, verdict 'NOT DETERMINABLE FROM AVAILABLE DATA' (never
%   PASS/FAIL invented). Documented rating (finite rating_kA > 0 plus
%   non-empty source for breaker_ref 'Q0') -> PASS iff I_sym <= rating else
%   honest FAIL. Missing/NaN through-current leg -> I_sym NaN, verdict
%   NOT DETERMINABLE with a MISSING-leg note (the net total is never
%   substituted). Peak I_peak_kA is borrowed-shape design-defined
%   informational only (Tthrough.r_kappa_ip or Tthrough.I_peak_kA when
%   present/finite, else NaN + MISSING-peak note) and never affects verdict.
%   50-kA row: informational comparison of the F3 LLL headline fault level
%   (joined total when the F3/LLL/LF360_GAT_OUT row is present, else the
%   frozen T1 identity 50.5308851865359 kA) against an ESTIMATED 50.00 kA
%   reference -> verdict NOTE (never PASS/FAIL); the row compares a
%   fault-point total for reference only, never a through-current duty
%   basis. Separate from coordination: no t_up/t_down/margin columns, no
%   operating-time calls. No '500-series standard' claim strings appear in
%   duty outputs (plain-study wording only).
%
%   D cols (locked, 10): location, breaker_ref, fault_type, caseID,
%     I_sym_kA, I_peak_kA, rating_kA, basis, verdict, note.
%   Verdict domain: PASS / FAIL / NOT DETERMINABLE FROM AVAILABLE DATA /
%     NOTE. All errors are 'phase5_duty'-prefixed.
if nargin < 1
    error('phase5_duty:args', 'usage: D = phase5_duty(Tthrough, ratings).');
end
if nargin < 2 || isempty(ratings)
    ratings = [];
end
if ~istable(Tthrough) || height(Tthrough) < 1
    error('phase5_duty:args', 'Tthrough must be a non-empty table (phase5_import output).');
end
for k = 1:numel({'fault_location', 'fault_type', 'caseID'})
    need = {'fault_location', 'fault_type', 'caseID'};
    if ~any(strcmp(Tthrough.Properties.VariableNames, need{k}))
        error('phase5_duty:schema', 'Tthrough missing required column %s.', need{k});
    end
end
locs = tocelld(Tthrough.fault_location);
typs = tocelld(Tthrough.fault_type);
cases = tocelld(Tthrough.caseID);
n = height(Tthrough);
if any(~(strcmp(locs, 'F1') | strcmp(locs, 'F2') | strcmp(locs, 'F3') | strcmp(locs, 'F4') | strcmp(locs, 'F5')))
    bad = locs(~(strcmp(locs, 'F1') | strcmp(locs, 'F2') | strcmp(locs, 'F3') | strcmp(locs, 'F4') | strcmp(locs, 'F5')));
    error('phase5_duty:topology', 'unknown fault_location %s (need F1..F5).', bad{1});
end
if any(~(strcmp(typs, 'LLL') | strcmp(typs, 'LG') | strcmp(typs, 'LL') | strcmp(typs, 'LLG')))
    bad = typs(~(strcmp(typs, 'LLL') | strcmp(typs, 'LG') | strcmp(typs, 'LL') | strcmp(typs, 'LLG')));
    error('phase5_duty:faulttype', 'unsupported fault_type %s (need LLL/LG/LL/LLG).', bad{1});
end
legGRID = legcold(Tthrough, 'leg_GRID_kA', n);
legHV = legcold(Tthrough, 'leg_GSUT_HV_kA', n);
legTOT = legcold(Tthrough, 'leg_LINE_total_kA', n);
legB1 = legcold(Tthrough, 'leg_LINE_B1_kA', n);
legB2 = legcold(Tthrough, 'leg_LINE_B2_kA', n);
peak = legcold(Tthrough, 'r_kappa_ip', n);
peakA = legcold(Tthrough, 'I_peak_kA', n);
hasPeakCol = any(strcmp(Tthrough.Properties.VariableNames, 'r_kappa_ip')) || ...
    any(strcmp(Tthrough.Properties.VariableNames, 'I_peak_kA'));
% Ratings parse: documented Q0 rating needs finite rating_kA > 0 + non-empty source.
[hasRating, ratingQ0, ratingSrc] = parse_ratings(ratings);
oLoc = cell(n, 1); oBrk = cell(n, 1); oTyp = cell(n, 1); oCase = cell(n, 1);
oSym = NaN(n, 1); oPk = NaN(n, 1); oRate = NaN(n, 1);
oBasis = cell(n, 1); oVd = cell(n, 1); oNote = cell(n, 1);
for i = 1:n
    loc = locs{i}; typ = typs{i}; cs = cases{i};
    isGenZone = strcmp(loc, 'F1') || strcmp(loc, 'F2');
    if isGenZone
        sym = legGRID(i);
        legName = 'leg_GRID_kA';
        pathTxt = 'GRID_Q grid infeed through Q0 toward generator fault';
        rejTxt = sprintf('net-total/leg_LINE_total %.4g rejected (bus total, never duty)', legTOT(i));
    else
        sym = legHV(i);
        legName = 'leg_GSUT_HV_kA';
        if strcmp(loc, 'F3')
            pathTxt = 'GSUT_HV plant infeed through Q0 (LINE_Q9 at F3 is remote-side, not Q0 path)';
            rejTxt = sprintf(['net-total %.4g rejected (bus total, never duty); ' ...
                'LINE_Q9==GRID_Q %.4g remote-side rejected (not through Q0)'], legTOT(i), legGRID(i));
        elseif strcmp(loc, 'F4')
            pathTxt = 'GSUT_HV plant infeed through Q0 (== LINE_Q9 breaker-path)';
            rejTxt = sprintf(['fault-point sum leg_LINE_total %.4g (B1 %.4g + B2 %.4g) rejected, never duty; ' ...
                'remote infeed leg_GRID %.4g not through Q0, never duty'], legTOT(i), legB1(i), legB2(i), legGRID(i));
        else
            pathTxt = 'GSUT_HV plant infeed through Q0 toward remote fault (== LINE_Q9 breaker-path)';
            rejTxt = sprintf(['net-total %.4g rejected (bus total, never duty); ' ...
                'remote infeed leg_GRID %.4g not through Q0, never duty'], legTOT(i), legGRID(i));
        end
    end
    pkv = NaN;
    if isfinite(peak(i)), pkv = peak(i);
    elseif isfinite(peakA(i)), pkv = peakA(i);
    end
    oLoc{i} = loc; oBrk{i} = 'Q0'; oTyp{i} = typ; oCase{i} = cs;
    oSym(i) = sym; oPk(i) = pkv;
    if isfinite(sym) && hasRating
        oRate(i) = ratingQ0;
        if sym <= ratingQ0
            vd = 'PASS';
            vnote = sprintf('PASS: through-current %.4g kA <= documented Q0 rating %.4g kA', sym, ratingQ0);
        else
            vd = 'FAIL';
            vnote = sprintf(['FAIL: through-current %.4g kA > documented Q0 rating %.4g kA; ' ...
                'honest-shortfall-never-tuned'], sym, ratingQ0);
        end
        basis = sprintf(['SOURCE-BACKED:Phase-4-production-import through-current branch %s (%s); ' ...
            'Q0-bay-position-ENGINEERING_ASSUMPTION:52-1-plant-outlet-breaker (T19-limitation); ' ...
            'rating %.4g kA source %s'], legName, pathTxt, ratingQ0, ratingSrc);
        note = sprintf('branch %s %.4g kA; %s; peak %.4g kA borrowed-shape design-defined informational only (never duty input)', ...
            legName, sym, rejTxt, pkv);
    else
        if ~isfinite(sym)
            vd = 'NOT DETERMINABLE FROM AVAILABLE DATA';
            basis = sprintf(['MISSING:through-current-leg (%s NaN for %s %s %s; B1/B2 per-circuit contributions ' ...
                'never substituted); Q0-bay-position-ENGINEERING_ASSUMPTION:52-1-plant-outlet-breaker (T19-limitation); ' ...
                'rating %s'], legName, loc, typ, cs, rating_state(hasRating, ratingQ0, ratingSrc));
            note = sprintf(['MISSING-leg: branch %s unavailable for %s %s %s (net total never substituted); ' ...
                '%s; peak %.4g kA borrowed-shape design-defined informational only (never duty input)'], ...
                legName, loc, typ, cs, rejTxt, pkv);
        else
            vd = 'NOT DETERMINABLE FROM AVAILABLE DATA';
            basis = sprintf(['SOURCE-BACKED:Phase-4-production-import through-current branch %s (%s); ' ...
                'Q0-bay-position-ENGINEERING_ASSUMPTION:52-1-plant-outlet-breaker (T19-limitation); ' ...
                'MISSING:Q0-interrupting-rating (no source proves a rating; never invented)'], legName, pathTxt);
            note = sprintf('branch %s %.4g kA; %s; peak %.4g kA borrowed-shape design-defined informational only (never duty input)', ...
                legName, sym, rejTxt, pkv);
        end
    end
    if ~isfinite(pkv) && ~hasPeakCol
        note = [note ';MISSING-peak-informational-only (never duty input)'];
    elseif ~isfinite(pkv)
        note = [note ';MISSING-peak (row peak unavailable, never duty input)'];
    end
    oVd{i} = vd; oBasis{i} = basis; oNote{i} = note;
end
% 50-kA estimated-reference NOTE row (exactly one; never PASS/FAIL).
[refSym, refPk, refSrc] = ref50(Tthrough);
pct = (refSym - 50.0) / 50.0 * 100;
oLoc = [oLoc; {'F3'}]; oBrk = [oBrk; {'Q0'}]; oTyp = [oTyp; {'LLL'}]; oCase = [oCase; {'LF360_GAT_OUT'}];
oSym = [oSym; refSym]; oPk = [oPk; refPk]; oRate = [oRate; 50.0];
oBasis = [oBasis; {sprintf(['ESTIMATED:50.00-kA-station-reference (estimated, never a rating); ' ...
    'headline F3 LLL fault level %.4g kA %s (fault-point total for reference only, never a through-current duty basis)'], ...
    refSym, refSrc)}];
oVd = [oVd; {'NOTE'}];
oNote = [oNote; {sprintf(['%+.2f%% vs estimated 50 kA reference (%.4g vs 50.00); ' ...
    'informational comparison only, never PASS/FAIL; peak %.4g kA borrowed-shape design-defined informational only'], ...
    pct, refSym, refPk)}];
D = table(oLoc, oBrk, oTyp, oCase, oSym, oPk, oRate, oBasis, oVd, oNote, ...
    'VariableNames', {'location', 'breaker_ref', 'fault_type', 'caseID', ...
    'I_sym_kA', 'I_peak_kA', 'rating_kA', 'basis', 'verdict', 'note'});
end

function [hasRating, ratingQ0, ratingSrc] = parse_ratings(ratings)
%PARSE_RATINGS  Documented Q0 rating needs finite rating > 0 + non-empty source.
hasRating = false; ratingQ0 = NaN; ratingSrc = '';
if isempty(ratings)
    return;
end
if istable(ratings)
    vn = ratings.Properties.VariableNames;
    if ~all(ismember({'breaker_ref', 'rating_kA', 'source'}, vn))
        error('phase5_duty:ratings', 'ratings table needs columns breaker_ref, rating_kA, source.');
    end
    refs = tocelld(ratings.breaker_ref);
    vals = double(ratings.rating_kA);
    srcs = tocelld(ratings.source);
elseif isstruct(ratings)
    if ~all(isfield(ratings, {'breaker_ref', 'rating_kA', 'source'}))
        error('phase5_duty:ratings', 'ratings struct needs fields breaker_ref, rating_kA, source.');
    end
    refs = cell(numel(ratings), 1); vals = NaN(numel(ratings), 1); srcs = cell(numel(ratings), 1);
    for k = 1:numel(ratings)
        refs{k} = char(ratings(k).breaker_ref);
        vals(k) = double(ratings(k).rating_kA);
        srcs{k} = char(ratings(k).source);
    end
else
    error('phase5_duty:ratings', 'ratings must be [] or a struct/table with breaker_ref, rating_kA, source.');
end
for k = 1:numel(refs)
    r = strtrim(refs{k});
    if any(strcmp(r, {'Q1', 'Q2', 'Q9', 'Q51', 'Q52', 'Q8'}))
        error('phase5_duty:rating', ['breaker_ref %s is a disconnector/earthing device, ' ...
            'never duty (only Q0 52-1 is duty-eligible).'], r);
    end
    if ~strcmp(r, 'Q0')
        error('phase5_duty:rating', 'unknown breaker_ref %s (need Q0).', r);
    end
end
hit = find(strcmp(strtrim(refs), 'Q0'), 1, 'first');
if isempty(hit)
    return;
end
if isfinite(vals(hit)) && vals(hit) > 0 && ~isempty(strtrim(srcs{hit}))
    hasRating = true; ratingQ0 = vals(hit); ratingSrc = strtrim(srcs{hit});
end
end

function s = rating_state(hasRating, ratingQ0, ratingSrc)
%RATING_STATE  Short rating-provenance tag for MISSING-leg basis strings.
if hasRating
    s = sprintf('documented %.4g kA (%s)', ratingQ0, ratingSrc);
else
    s = 'MISSING (no source proves a Q0 rating; never invented)';
end
end

function [refSym, refPk, refSrc] = ref50(Tthrough)
%REF50  Headline F3 LLL OUT fault level for the estimated-reference NOTE row.
FROZEN = 50.5308851865359;  % T1 regression identity (SOURCE-BACKED constant)
refSym = FROZEN; refPk = NaN;
refSrc = 'frozen-T1-identity-SOURCE-BACKED-constant';
vn = Tthrough.Properties.VariableNames;
if any(strcmp(vn, 'I_primary_kA')), tot = double(Tthrough.I_primary_kA(:));
elseif any(strcmp(vn, 'I_primary_A')), tot = double(Tthrough.I_primary_A(:)) / 1000;
else, tot = NaN(height(Tthrough), 1);
end
locs = tocelld(Tthrough.fault_location);
typs = tocelld(Tthrough.fault_type);
cases = tocelld(Tthrough.caseID);
hit = find(strcmp(locs, 'F3') & strcmp(typs, 'LLL') & strcmp(cases, 'LF360_GAT_OUT') & isfinite(tot), 1, 'first');
if ~isempty(hit)
    refSym = tot(hit);
    refSrc = 'SOURCE-BACKED:Phase-4-production-import joined F3-LLL-OUT total';
end
if any(strcmp(vn, 'r_kappa_ip'))
    pk = double(Tthrough.r_kappa_ip(:));
    if ~isempty(hit) && isfinite(pk(hit)), refPk = pk(hit); end
elseif any(strcmp(vn, 'I_peak_kA'))
    pk = double(Tthrough.I_peak_kA(:));
    if ~isempty(hit) && isfinite(pk(hit)), refPk = pk(hit); end
end
end

function v = legcold(Tsec, name, n)
%LEGCOLD  Optional leg column (kA) or NaN vector when absent.
if any(strcmp(Tsec.Properties.VariableNames, name))
    v = double(Tsec.(name)(:));
    if numel(v) ~= n, v = NaN(n, 1); end
    v(~isfinite(v)) = NaN;
else
    v = NaN(n, 1);
end
end

function c = tocelld(v)
%TOCELLD  Normalize table text column (cellstr/string/char) to cellstr.
if iscell(v)
    c = v(:);
    for k = 1:numel(c)
        if isstring(c{k}) && isscalar(c{k}), c{k} = char(c{k}); end
    end
elseif isstring(v)
    c = cellstr(v(:));
elseif ischar(v)
    c = cellstr(v);
else
    error('phase5_duty:schema', 'text column must be cell/string/char.');
end
end
