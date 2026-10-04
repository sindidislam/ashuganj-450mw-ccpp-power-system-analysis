function gui_tab_assumptions(tab, fig)
%GUI_TAB_ASSUMPTIONS  Assumptions tab: what was assumed, and why.
%
%   Left  a summary table, one row per assumption, with the parameter, the
%         value, the unit and whether the user approved it.
%   Right the full record of the selected assumption, including the Reason
%         prose at full length with its line breaks intact.
%
%   WHY THE REASON IS SHOWN IN FULL
%   -------------------------------
%   Each file in matlab/data/assumptions carries a paragraph explaining what
%   was missing from the source set, what was chosen instead, and which way the
%   result would move if the choice were different. That paragraph is the whole
%   value of the register - a table of numbers labelled 'assumption' with the
%   reasoning hidden is indistinguishable from a table of measurements. So the
%   detail pane uses a uitextarea, which honours newlines, and no truncation is
%   applied.
%
%   Approved_by_user = false is drawn in the table as DISCLOSED rather than
%   left as 0, because 0 in a column of numbers does not read as 'this number
%   was chosen by the analyst and never approved'.
%
%   See also ASHUGANJ_GUI, ASHUGANJ_MASTER_DATA.

app = fig.UserData;
D   = app.D;

if ~isfield(D, 'assumptions') || isempty(D.assumptions)
    g = uigridlayout(tab, [1 1]);
    lab = uilabel(g);
    lab.Text = 'The dataset declares no assumptions.';
    lab.HorizontalAlignment = 'center';
    return
end

A     = D.assumptions;
names = fieldnames(A);

g = uigridlayout(tab, [2 2]);
g.ColumnWidth = {'1.15x', '1x'};
g.RowHeight   = {'1x', 90};
g.Padding     = [8 8 8 8];

% ------------------------------------------------------- left: the summary
pl = uipanel(g, 'Title', sprintf('Assumption register (%d)', numel(names)));
pl.Layout.Row    = 1;
pl.Layout.Column = 1;
gl = uigridlayout(pl, [1 1]);

tbl = uitable(gl);
tbl.Data           = summary_table(A, names);
tbl.ColumnSortable = true;
tbl.SelectionType  = 'row';

% ------------------------------------------------------- right: the detail
pr = uipanel(g, 'Title', 'Full record - select a row on the left');
pr.Layout.Row    = 1;
pr.Layout.Column = 2;
gr = uigridlayout(pr, [1 1]);

ta = uitextarea(gr);
ta.Editable = 'off';
ta.FontName = 'Consolas';

tbl.SelectionChangedFcn = @(s,e) show_detail(ta, A, names, e.Selection);

% -------------------------------------------------------- bottom: the rule
pb = uipanel(g, 'Title', 'How to read this register');
pb.Layout.Row    = 2;
pb.Layout.Column = [1 2];
gb = uigridlayout(pb, [1 1]);

txt = [ "APPROVED  the user answered the question that settles this value; the number is theirs."
        "DISCLOSED the source set is silent, the choice could not be deferred, and it is recorded here rather than buried in the build code."
        ""
        "Every entry carries Status_assigned = ENGINEERING_ASSUMPTION and is asserted as such by ashuganj_master_data, so an assumption cannot be quietly reclassified as plant data." ];
lab = uilabel(gb);
lab.Text     = char(strjoin(txt, newline));
lab.WordWrap = 'on';

% Show the first record so the pane is never blank on open.
show_detail(ta, A, names, [1 1]);
tbl.Selection = 1;
end

% =====================================================================
function T = summary_table(A, names)
%SUMMARY_TABLE  One row per assumption: name, parameter, value, unit, status.
n = numel(names);
nm = strings(n,1); par = strings(n,1); val = strings(n,1);
un = strings(n,1); st  = strings(n,1);

for i = 1:n
    a     = A.(names{i});
    nm(i) = string(names{i});
    par(i) = field_or(a, 'Parameter', "");
    val(i) = field_or(a, 'Value',     "");
    un(i)  = field_or(a, 'Unit',      "");

    approved = isfield(a, 'Approved_by_user') && ...
               ~isempty(a.Approved_by_user) && logical(a.Approved_by_user(1));
    if approved
        st(i) = "APPROVED";
    else
        st(i) = "DISCLOSED";
    end
end

T = table(nm, par, val, un, st, 'VariableNames', ...
    {'Assumption','Parameter','Value','Unit','Status'});
end

% =====================================================================
function show_detail(ta, A, names, sel)
%SHOW_DETAIL  Print every field of the selected assumption, prose intact.
if isempty(sel)
    return
end
i = sel(1);
if i < 1 || i > numel(names)
    return
end

a = A.(names{i});
f = fieldnames(a);
out = string.empty(0,1);
out(end+1,1) = upper(string(names{i}));
out(end+1,1) = string(repmat('=', 1, max(8, strlength(names{i}))));
out(end+1,1) = "";
out(end+1,1) = "source: matlab/data/assumptions/" + string(names{i}) + ".m";
out(end+1,1) = "";

for k = 1:numel(f)
    v = a.(f{k});
    if ischar(v) || (isstring(v) && isscalar(v))
        % Prose keeps its own line breaks. wrap() would refold a paragraph the
        % author already formatted, so only the label is prepended.
        out(end+1,1) = string(f{k}) + ":";                    %#ok<AGROW>
        body = splitlines(string(v));
        out  = [out; "  " + body];                            %#ok<AGROW>
    else
        out(end+1,1) = string(f{k}) + ": " + gui_textify(v);   %#ok<AGROW>
    end
    out(end+1,1) = "";                                        %#ok<AGROW>
end

ta.Value = cellstr(out);
end

% =====================================================================
function s = field_or(S, name, dflt)
%FIELD_OR  gui_textify(S.name) if present, otherwise dflt.
if isfield(S, name)
    s = gui_textify(S.(name));
else
    s = dflt;
end
end
