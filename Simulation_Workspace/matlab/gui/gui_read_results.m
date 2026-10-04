function Res = gui_read_results(root, D)
%GUI_READ_RESULTS  Load every written load-flow table, tolerating absence.
%
%   Res = GUI_READ_RESULTS() reads the six CSVs in results/load_flow/ under the
%   root ASHUGANJ_ROOT returns; GUI_READ_RESULTS(root) uses an explicit root.
%   GUI_READ_RESULTS(root, D) also takes the dataset struct from
%   ASHUGANJ_MASTER_DATA, so the staleness verdict can quote D.meta.Dataset_date
%   and the .rep inventory can list every case in {D.cases.ID}. A missing or
%   unreadable file is reported, never fatal.
%
%   WHY THE GUI READS THE WRITTEN TABLES INSTEAD OF RE-SOLVING
%   ---------------------------------------------------------
%   Drawing a tab must be free; a solve is not. power_loadflow costs 12-28 s on
%   the first case of a session and 1-2 s warm, and needs Simulink, a model build
%   and the SPS library: a table that solved to fill itself freezes the window.
%
%   The deeper reason is that the numbers must not fork. RUN_LOAD_FLOW_STUDY
%   wrote these CSVs, MAKE_LOAD_FLOW_PLOTS renders the same CSVs, and the report
%   quotes them. A GUI that solved its own copy could show two different UAT
%   loading figures on one screen with no way to tell which one the report was
%   built from. One source of numbers, read by everyone. A re-solve stays
%   available behind the Load Flow tab's button, wrapped in GUI_RUN_CAPTURE,
%   where the user asked for it and can watch it run.
%
%   There is a hard reason too: ASHUGANJ_BUS_MAP identifies buses by Simulink
%   block handle and asserts against a loaded model, so the post-solve helpers
%   cannot be called by a file reader at all. These CSVs and the .rep reports
%   are the only form of the solution that exists without Simulink.
%
%   STALENESS IS REPORTED, NOT REPAIRED
%   -----------------------------------
%   Nothing here regenerates anything. The tables carry no record of which
%   dataset produced them, so their newest write time is judged twice: against
%   D.meta.Dataset_date, and against the newest edit to the registers in
%   matlab/data/ plus the study and build scripts. The second is the sharper
%   test, because the dataset date is hand-typed and does not move when a
%   register is edited - results can post-date the stated date and still predate
%   the numbers they were solved from.
%
%   Tables come back exactly as READTABLE produced them, because NaN is
%   load-bearing: the merged-bus rows of bus_results.csv and the coupler row of
%   line_results.csv are NaN because flow is not observable at a merged node,
%   and a zero there would assert that no power flows. Formatting, and the
%   symbol and unit of each quantity, belong to the tab via GUI_SYMBOLS.
%
%   RETURNS  .system .bus .gen .tx .line .residual  tables, empty if absent
%     .exists .rows .files  structs on those six keys: parsed-ok, height, path
%     .missing .errors .complete  absent paths, parse messages, all-six flag
%     .newest .newest_file .newest_str  newest present CSV (NaT / '' if none)
%     .reports  per case: Case File Exists Bytes Modified Lines Text
%     .staleness  Verdict (ABSENT|INCOMPLETE|STALE|CURRENT), Detail sentence,
%     Dataset_date, Source_newest, Source_file;  .stale mirrors the verdict
%
%   See also RUN_LOAD_FLOW_STUDY, MAKE_LOAD_FLOW_PLOTS, GUI_RUN_CAPTURE.

if nargin < 1 || isempty(root), root = ashuganj_root(); end
if nargin < 2, D = []; end

lfd = fullfile(root, 'results', 'load_flow');

% The short key each tab uses, then the name the writer used. Both live here so
% a renamed CSV is one edit instead of a search through every tab.
spec = { 'system',   'system_summary.csv'      ; ...
         'bus',      'bus_results.csv'         ; ...
         'gen',      'generator_results.csv'   ; ...
         'tx',       'transformer_results.csv' ; ...
         'line',     'line_results.csv'        ; ...
         'residual', 'residuals.csv'           };

Res        = struct('root', root, 'dir', lfd);
Res.errors = strings(0, 1);
absent     = strings(0, 1);
newestNum  = 0;
newestName = '';

for i = 1:size(spec, 1)
    key = spec{i,1};  f = fullfile(lfd, spec{i,2});
    Res.(key)        = table();   Res.files.(key) = f;
    Res.exists.(key) = false;     Res.rows.(key)  = 0;

    dd = dir(f);
    if isempty(dd), absent(end+1,1) = string(f); continue, end          %#ok<AGROW>
    if dd(1).datenum > newestNum
        newestNum = dd(1).datenum;  newestName = spec{i,2};
    end
    [T, errMsg] = read_one(f);
    if strlength(errMsg) > 0
        % Present but unreadable is a different failure from never written.
        Res.errors(end+1,1) = errMsg;                                   %#ok<AGROW>
    else
        Res.(key) = T;  Res.exists.(key) = true;  Res.rows.(key) = height(T);
    end
end

Res.missing     = absent;
Res.complete    = isempty(absent) && isempty(Res.errors);
Res.newest      = NaT;   Res.newest_str = '';   Res.newest_file = newestName;
if newestNum > 0
    Res.newest     = datetime(newestNum, 'ConvertFrom', 'datenum');
    Res.newest_str = char(string(Res.newest, 'yyyy-MM-dd HH:mm'));
end

Res.reports   = find_reports(lfd, D);
Res.staleness = staleness_verdict(root, D, Res);
Res.stale     = strcmp(Res.staleness.Verdict, 'STALE');
end

% =====================================================================
function [T, errMsg] = read_one(f)
%READ_ONE  READTABLE with the options these particular CSVs need.
%   TextType string because Description, Note, Q_limits and Checks are prose
%   with commas inside quotes - the reason probe_csv_columns.m exists. Names are
%   preserved so each heading keeps the unit suffix a tab keys GUI_SYMBOLS off.
T = table();  errMsg = "";
try
    T = readtable(f, 'TextType', 'string', 'VariableNamingRule', 'preserve');
catch err
    errMsg = string(sprintf('%s: %s', f, err.message));
end
end

% =====================================================================
function R = find_reports(lfd, D)
%FIND_REPORTS  Inventory the per-case .rep reports power_loadflow wrote.
%   The study passes a stem with no extension and the solver appends .rep, so
%   the name is <CASE>_powergui_report.rep. Cases the dataset knows about are
%   listed even when absent, so a tab shows a case as not yet solved rather
%   than silently omitting it.
ids = strings(0, 1);
if ~isempty(D) && isfield(D, 'cases') && isfield(D.cases, 'ID')
    ids = string({D.cases.ID})';
end
dd = dir(fullfile(lfd, '*_powergui_report.rep'));
for k = 1:numel(dd)
    tok = regexp(dd(k).name, '^(.+)_powergui_report\.rep$', 'tokens', 'once');
    if ~isempty(tok), ids(end+1,1) = string(tok{1}); end                %#ok<AGROW>
end
ids = unique(ids, 'stable');

R = struct('Case', {}, 'File', {}, 'Exists', {}, 'Bytes', {}, 'Modified', {}, ...
           'Lines', {}, 'Text', {});
for k = 1:numel(ids)
    f = fullfile(lfd, char(ids(k) + "_powergui_report.rep"));
    e = dir(f);
    R(k).Case = char(ids(k));  R(k).File = f;  R(k).Exists = ~isempty(e);
    if isempty(e)
        R(k).Bytes = 0;  R(k).Modified = NaT;  R(k).Lines = 0;  R(k).Text = '';
        continue
    end
    R(k).Bytes    = e(1).bytes;
    R(k).Modified = datetime(e(1).datenum, 'ConvertFrom', 'datenum');
    % Kept verbatim and never parsed: the .rep SUMMARY totals only the
    % auxiliary subnetwork and labels its buses on the wrong base, so it is the
    % solver speaking - not a source for this project's own figures.
    R(k).Text  = fileread(f);
    R(k).Lines = numel(splitlines(string(R(k).Text)));
end
end

% =====================================================================
function St = staleness_verdict(root, D, Res)
%STALENESS_VERDICT  Judge the tables against the dataset that produced them.
St = struct('Dataset_date', NaT, 'Source_newest', NaT, 'Source_file', '');

if ~isempty(D) && isfield(D, 'meta') && isfield(D.meta, 'Dataset_date')
    dstr = D.meta.Dataset_date;
else
    % D is cached in fig.UserData because every register self-validates on load;
    % re-running master data here for one date string would pay that cost on
    % every redraw, so scrape the literal out of the source file instead.
    dstr = '';  src = fullfile(root, 'matlab', 'data', 'ashuganj_master_data.m');
    if isfile(src)
        tok = regexp(fileread(src), 'Dataset_date\s*=\s*''([^'']*)''', 'tokens', 'once');
        if ~isempty(tok), dstr = tok{1}; end
    end
end
if ~isempty(dstr)
    try
        St.Dataset_date = datetime(dstr, 'InputFormat', 'yyyy-MM-dd');
    catch
        St.Dataset_date = NaT;      % a date hand-typed in some other format
    end
end
dtxt = dstr;  if isempty(dtxt), dtxt = '(not stated)'; end
[St.Source_newest, St.Source_file] = newest_source(root);

nBad = numel(Res.missing) + numel(Res.errors);
if isnat(Res.newest)
    St.Verdict = 'ABSENT';
    St.Detail  = sprintf(['No load-flow tables in %s. Solve on the Load Flow ' ...
        'tab, or run run_load_flow_study.'], Res.dir);
elseif nBad > 0
    St.Verdict = 'INCOMPLETE';
    St.Detail  = sprintf(['%d of the 6 tables are absent or unreadable. Newest ' ...
        'file present: %s, written %s.'], nBad, Res.newest_file, Res.newest_str);
elseif ~isnat(St.Dataset_date) && Res.newest < St.Dataset_date
    St.Verdict = 'STALE';
    St.Detail  = sprintf(['All 6 tables present, but the newest (%s, %s) is ' ...
        '%.1f days OLDER than the dataset date %s. Re-solve.'], Res.newest_file, ...
        Res.newest_str, days(St.Dataset_date - Res.newest), dtxt);
elseif ~isnat(St.Source_newest) && St.Source_newest > Res.newest
    St.Verdict = 'STALE';
    St.Detail  = sprintf(['All 6 tables present, written %s, but %s was edited ' ...
        '%.1f h later - the tables predate the numbers they came from. ' ...
        'Re-solve.'], Res.newest_str, St.Source_file, ...
        hours(St.Source_newest - Res.newest));
else
    St.Verdict = 'CURRENT';
    St.Detail  = sprintf(['All 6 tables present, newest written %s, after both ' ...
        'the dataset date %s and the last edit to any register or study ' ...
        'source.'], Res.newest_str, dtxt);
end

nRep = sum(~[Res.reports.Exists]);
if nRep > 0
    St.Detail = sprintf('%s  %d case report(s) (.rep) are absent.', St.Detail, nRep);
end
end

% =====================================================================
function [dn, nm] = newest_source(root)
%NEWEST_SOURCE  Newest edit among the files that decide the numbers.
%   Editing a register or the study script invalidates the CSVs without
%   changing anything about them, so these timestamps are the honest reference.
pats = { fullfile(root, 'matlab', 'data', '*.m'), ...
         fullfile(root, 'matlab', 'data', 'assumptions', '*.m'), ...
         fullfile(root, 'matlab', 'analysis', '*.m'), ...
         fullfile(root, 'matlab', 'studies', 'run_load_flow_study.m'), ...
         fullfile(root, 'matlab', 'build', 'build_ashuganj_main.m') };
best = 0;  dn = NaT;  nm = '';
for i = 1:numel(pats)
    dd = dir(pats{i});
    for k = 1:numel(dd)
        if ~dd(k).isdir && dd(k).datenum > best
            best = dd(k).datenum;  nm = dd(k).name;
        end
    end
end
if best > 0, dn = datetime(best, 'ConvertFrom', 'datenum'); end
end
