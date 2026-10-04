function gui_tab_equipment(tab, fig)
%GUI_TAB_EQUIPMENT  Equipment tab: every register in the dataset, as a table.
%
%   A dropdown lists the registers found in D - buses, generators,
%   transformers, lines, loads, grid - and the selected one is drawn as a
%   sortable table with one row per element and one column per field.
%
%   THE REGISTER LIST IS DISCOVERED, NOT HARD-CODED
%   ----------------------------------------------
%   The dropdown is built by walking the top-level fields of D and keeping
%   those that are struct arrays or structs of plant data. Hard-coding the six
%   names would mean this tab silently omits any register added later, which is
%   the failure mode that matters: an omitted register looks like a register
%   that does not exist.
%
%   Columns are NOT reordered or renamed. What is shown is the field name the
%   dataset uses, so a value seen here can be traced straight back to
%   ashuganj_buses.m or ashuganj_transformers.m by name.
%
%   See also ASHUGANJ_GUI, GUI_STRUCT2TABLE, ASHUGANJ_MASTER_DATA.

app = fig.UserData;
D   = app.D;

% Fields that are metadata about the study rather than plant registers. These
% are shown on the Overview and Assumptions tabs instead.
skip = {'meta', 'base', 'assumptions', 'superseded', 'case_matrix_note', ...
        'status_vocabulary', 'structural', 'weakest_link', 'cases'};

f     = fieldnames(D);
names = {};
for i = 1:numel(f)
    if any(strcmp(f{i}, skip)), continue
    end
    if isstruct(D.(f{i}))
        names{end+1} = f{i};   %#ok<AGROW>
    end
end

if isempty(names)
    g = uigridlayout(tab, [1 1]);
    lab = uilabel(g);
    lab.Text = 'No plant registers found in the dataset.';
    lab.HorizontalAlignment = 'center';
    return
end

g = uigridlayout(tab, [3 1]);
g.RowHeight = {36, '1x', 26};
g.Padding   = [8 8 8 8];

% ------------------------------------------------------------------ picker
top = uigridlayout(g, [1 3]);
top.ColumnWidth = {90, 260, '1x'};
top.Padding     = [0 0 0 0];

lab = uilabel(top);
lab.Text = 'Register:';
lab.HorizontalAlignment = 'right';

dd = uidropdown(top);
dd.Items = cellfun(@(s) pretty(s, D), names, 'UniformOutput', false);
dd.ItemsData = names;

srcLab = uilabel(top);
srcLab.FontAngle = 'italic';

% ------------------------------------------------------------------- table
tbl = uitable(g);
tbl.ColumnSortable = true;

% -------------------------------------------------------------- row counter
cnt = uilabel(g);

dd.ValueChangedFcn = @(s,e) show(tbl, cnt, srcLab, D, s.Value);
show(tbl, cnt, srcLab, D, names{1});
end

% =====================================================================
function show(tbl, cnt, srcLab, D, name)
%SHOW  Draw one register into the table.
v = D.(name);
if isscalar(v)
    % A single-element register such as D.grid is still a register. It is drawn
    % as Field/Value rather than as a one-row table, because a one-row table of
    % thirty columns cannot be read without horizontal scrolling.
    tbl.Data           = gui_struct2list(v);
    tbl.ColumnWidth    = {230, 'auto'};
    tbl.ColumnSortable = false;
    cnt.Text = sprintf('%s: 1 entry, %d fields (shown as Field/Value)', ...
                       name, numel(fieldnames(v)));
else
    tbl.Data           = gui_struct2table(v);
    tbl.ColumnWidth    = 'auto';
    tbl.ColumnSortable = true;
    cnt.Text = sprintf('%s: %d entries, %d fields', ...
                       name, numel(v), numel(fieldnames(v)));
end
srcLab.Text = sprintf('source: matlab/data/ashuganj_%s.m', name);
end

% =====================================================================
function s = pretty(name, D)
%PRETTY  Dropdown label: the field name plus its entry count.
n = numel(D.(name));
if n == 1
    s = sprintf('%s (1)', name);
else
    s = sprintf('%s (%d)', name, n);
end
end
