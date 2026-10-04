function html = gui_table_to_html(T, varargin)
%GUI_TABLE_TO_HTML  One MATLAB table as a styled HTML fragment.
%
%   html = GUI_TABLE_TO_HTML(T) returns a char array holding a <table> fragment -
%   no <html>, no <body> - ready for GUI_UIHTML in the window, or for a 'table'
%   block of GUI_HTML_REPORT. Name-value options:
%
%     'Caption'    text placed in <caption> above the grid       (default '')
%     'MaxRows'    render only the first n rows, and say so      (default Inf)
%     'Precision'  decimals for non-integer numerics            (default 4)
%
%   WHY TWO HEADER ROWS
%   -------------------
%   Row one carries the quantity: the MathJax markup from GUI_SYMBOLS(name).html
%   beside the column name exactly as written in the CSV, so a symbol in the
%   report can be matched to a column in results/load_flow. Row two carries the
%   unit alone. The unit never shares a cell with the name because these names
%   already end in their unit, and 'P_loss_MW [MW]' reads as a mistake. A name
%   absent from the symbol map still gets a unit: the suffix of the name itself
%   is the fallback, which is why the _MW / _MVAr / _pu / _pct convention in the
%   dataset is worth relying on.
%
%   WHY NaN IS AN EM DASH, NOT A BLANK AND NEVER A ZERO
%   ---------------------------------------------------
%   NaN is load-bearing in these results, not missing data. B6_6_WI1, B6_6_WI2
%   and B230_2 are merged into their representative node, so no solver injection
%   exists for them at all; the closed bus coupler carries a flow no measurement
%   can separate; Alt_base_V exists only on B6_6. Printed as 0 those cells would
%   state a physical result that was never computed, and printed blank they would
%   look like a writer that failed. The em dash plus the footnote say which it
%   is. Empty TEXT, by contrast, really is an empty field (Merged_into on a
%   representative bus) and stays blank.
%
%   Numerics are right-aligned so decimal points line up. A column whose finite
%   values are all whole prints without decimals, so Vnom_V stays 230000 instead
%   of 230000.0000. Magnitudes below 1e-3, or at 1e6 and above, switch to
%   exponent form: the worst KCL residual (8.6e-08 MVA) is the number that proves
%   the solution, and %.4f would print it as 0.0000.
%
%   The fragment carries its own scoped CSS - zebra rows and a sticky header for
%   the 32-row bus table - because the report document supplies neither, and the
%   .gtbl prefix keeps these rules off every other table on the page. tbody is
%   marked mathjax_ignore so a Note containing $ or a backslash is never
%   mistaken for an equation.
%
%   See also GUI_SYMBOLS, GUI_HTML_REPORT, GUI_UIHTML, GUI_TEXTIFY.

p = inputParser;
p.FunctionName = 'gui_table_to_html';
p.addRequired('T', @(x) istable(x) || istimetable(x));
p.addParameter('Caption', '', @(x) ischar(x) || isstring(x));
p.addParameter('MaxRows', Inf, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('Precision', 4, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 15);
p.parse(T, varargin{:});
opt = p.Results;

if istimetable(T), T = timetable2table(T); end
names = string(T.Properties.VariableNames);
nv    = numel(names);
nr    = height(T);
cap   = strtrim(string(strjoin(cellstr(string(opt.Caption))', ' ')));

if nv == 0
    html = char("<p class=""gtbl-note"">This table has no columns - nothing to show.</p>");
    return
end

prec  = round(double(opt.Precision));
fmt   = struct('f', sprintf('%%.%df', prec), 'e', sprintf('%%.%de', prec));
shown = nr;
if isfinite(opt.MaxRows), shown = min(nr, floor(double(opt.MaxRows))); end

% Column metadata once, not per cell: gui_symbols may not be on the path yet
% (it is written in parallel), and one failed lookup per column is cheap.
sym = strings(1, nv); un = strings(1, nv); dsc = strings(1, nv);
for j = 1:nv
    [sym(j), un(j), dsc(j)] = symbol_for(names(j));
end

[rows, anyNaN] = body_rows(T, names, shown, fmt);

L = [ "<div class=""gtbl-wrap"">"; css_block(); "<table class=""gtbl"">" ];
L(end+1,1) = caption_html(cap, nr, shown, nv);
L(end+1,1) = "<thead><tr class=""gsym"">" + strjoin(head_cells(names, sym, dsc), "") + "</tr>";
L(end+1,1) = "<tr class=""gunit"">" + strjoin(unit_cells(un), "") + "</tr></thead>";
if shown == 0
    L(end+1,1) = "<tbody class=""mathjax_ignore""><tr><td class=""gtbl-empty"" colspan=""" + ...
                 nv + """>No rows. Run the study first, or widen the case filter.</td></tr></tbody>";
else
    L(end+1,1) = "<tbody class=""mathjax_ignore"">" + strjoin(rows, newline) + "</tbody>";
end
L(end+1,1) = "</table>";
if anyNaN
    L(end+1,1) = "<p class=""gtbl-foot mathjax_ignore""><span class=""nan"">&mdash;</span> is not zero and " + ...
        "not a gap in the data: the quantity does not exist for that row. A bus merged into its " + ...
        "representative node (B6_6_WI1, B6_6_WI2 into B6_6; B230_2 into B230_1) carries no solver " + ...
        "injection of its own, the flow through the closed bus coupler is not separately observable, " + ...
        "and a second voltage base or an allocated load is written only where one applies.</p>";
end
if shown < nr
    L(end+1,1) = "<p class=""gtbl-foot mathjax_ignore"">First " + shown + " of " + nr + ...
                 " rows shown; the remaining " + (nr - shown) + " are in the CSV.</p>";
end
L(end+1,1) = "</div>";
html = char(strjoin(L, newline));
end

% =====================================================================
function [s, u, d] = symbol_for(name)
%SYMBOL_FOR  MathJax markup, unit and description for one column name.
%   GUI_SYMBOLS owns all three. It is called in a try because a table can hold a
%   column the map does not know (Note, Checks, Q_limits) and because the map
%   must never be the reason a results table refuses to draw.
s = ""; u = ""; d = "";
try
    q = gui_symbols(char(name));
    if isstruct(q) && isscalar(q)
        if isfield(q, 'html') && ~isempty(q.html)
            s = strtrim(string(gui_textify(q.html)));
        elseif isfield(q, 'latex') && ~isempty(q.latex)
            s = "\(" + strtrim(erase(string(gui_textify(q.latex)), "$")) + "\)";
        end
        if isfield(q, 'units'), u = strtrim(string(gui_textify(q.units))); end
        if isfield(q, 'desc'),  d = strtrim(string(gui_textify(q.desc)));  end
    end
catch
    % Not in the map, or the map is not on the path: the fallbacks below stand.
end
if any(strcmpi(u, ["-", "1", "none", "dimensionless", "count", ""])), u = unit_from_name(name); end
end

% =====================================================================
function u = unit_from_name(name)
%UNIT_FROM_NAME  Read the unit off the column name's own suffix.
%   The dataset and every CSV name their columns <quantity>_<unit>, so a column
%   the symbol map has not been taught still shows its unit. Longest alternatives
%   come first: MATLAB's regexp takes the first that matches, so MVAr must be
%   tried before MVA, and kV before V, or MVAr_ columns would be labelled MVA.
u = "";
tok = regexp(char(name), '_(MVAr|MVA|MW|kVA|kV|kA|kW|barg|deg|ohm|pct|km|pu|Hz|MJ|kg|V|A|W|H|F|s)$', 'tokens', 'once');
if isempty(tok), return, end
u = string(tok{1});
if u == "pct", u = "%"; end
end

% =====================================================================
function c = head_cells(names, sym, dsc)
%HEAD_CELLS  Row one: the symbol, then the column name as the CSV spells it.
%   The name is kept even when a symbol exists, because the reader's other window
%   is the CSV. title= puts the description on hover, where it costs no width.
c = strings(1, numel(names));
for j = 1:numel(names)
    ttl = "";
    if strlength(dsc(j)) > 0, ttl = " title=""" + esc(dsc(j)) + """"; end
    inner = "";
    if strlength(sym(j)) > 0, inner = "<span class=""sy"">" + sym(j) + "</span>"; end
    c(j) = "<th" + ttl + ">" + inner + "<span class=""nm"">" + esc(names(j)) + "</span></th>";
end
end

% =====================================================================
function c = unit_cells(un)
%UNIT_CELLS  Row two: the unit alone, or an empty cell for a text column.
%   A dimensionless or textual column gets no em dash here - that glyph means
%   "no such value" in the body and must not be spent on "no unit" in the head.
c = strings(1, numel(un));
for j = 1:numel(un)
    if strlength(un(j)) > 0
        c(j) = "<th class=""u"">" + esc(un(j)) + "</th>";
    else
        c(j) = "<th class=""u""></th>";
    end
end
end

% =====================================================================
function [rows, anyNaN] = body_rows(T, names, shown, fmt)
%BODY_ROWS  Every data cell, typed per COLUMN and formatted per cell.
%   Deciding numeric-versus-text once per column is what makes 230000 print as an
%   integer while 389.3 keeps its decimals: wholeness is a property of the
%   column, not of the one value in front of you.
nv = numel(names);
kind = strings(1, nv); asInt = false(1, nv); col = cell(1, nv);
for j = 1:nv
    v = T.(names(j));
    col{j} = v;
    if isnumeric(v) && isreal(v) && size(v, 2) == 1
        kind(j) = "num";
        f = double(v(isfinite(v)));
        asInt(j) = ~isempty(f) && all(f == round(f)) && all(abs(f) < 1e9);
    elseif islogical(v) && size(v, 2) == 1
        kind(j) = "bool";
    else
        kind(j) = "txt";
    end
end

rows   = strings(1, shown);
anyNaN = false;
for i = 1:shown
    cells = strings(1, nv);
    for j = 1:nv
        v = col{j};
        switch kind(j)
            case "num"
                if isnan(v(i))
                    cells(j) = "<td class=""num nan"" title=""no value exists for this row"">&mdash;</td>";
                    anyNaN = true;
                else
                    cells(j) = "<td class=""num"">" + fmt_num(double(v(i)), fmt, asInt(j)) + "</td>";
                end
            case "bool"
                b = "false";
                if v(i), b = "true"; end
                cells(j) = "<td class=""bool"">" + b + "</td>";
            otherwise
                cells(j) = "<td>" + esc(text_cell(v, i)) + "</td>";
        end
    end
    rows(i) = "<tr>" + strjoin(cells, "") + "</tr>";
end
end

% =====================================================================
function s = fmt_num(v, fmt, asInt)
%FMT_NUM  One finite number at the requested precision.
%   Inf is a real entry in this dataset - Qmin/Qmax are -inf/+inf and the grid
%   X/R ratio is inf - so it is drawn as the symbol, not as the word or a NaN.
if isinf(v)
    s = "&infin;";
    if v < 0, s = "&minus;&infin;"; end
elseif asInt
    s = string(sprintf('%.0f', v));
elseif v == 0
    s = "0";
elseif abs(v) >= 1e-3 && abs(v) < 1e6
    s = string(sprintf(fmt.f, v));
else
    s = string(sprintf(fmt.e, v));
end
end

% =====================================================================
function t = text_cell(v, i)
%TEXT_CELL  One text-ish cell. A <missing> string or an empty char stays blank -
%   an unwritten text field is not the same claim as a NaN. Anything else,
%   including a vector variable such as a cooling-stage rating list, goes through
%   gui_textify, which is already the project's one-line renderer.
if isstring(v) && size(v, 2) == 1
    if ismissing(v(i)), t = ""; else, t = v(i); end
elseif iscategorical(v) && size(v, 2) == 1
    if ismissing(v(i)), t = ""; else, t = string(v(i)); end
elseif ischar(v)
    t = string(v(i, :));
elseif (isdatetime(v) || isduration(v)) && size(v, 2) == 1
    if ismissing(v(i)), t = ""; else, t = string(v(i)); end
elseif iscell(v) && size(v, 2) == 1
    t = gui_textify(v{i});
else
    t = gui_textify(v(i, :));
end
t = strtrim(string(t));
end

% =====================================================================
function s = caption_html(cap, nr, shown, nv)
%CAPTION_HTML  Caption plus the shape of what is actually on screen.
%   The dimensions are always stated, with or without a caption, so a truncated
%   view can never be mistaken for the whole table.
dim = shown + " of " + nr + " rows";
if shown == nr, dim = nr + " rows"; end
dim = dim + ", " + nv + " columns";
s = "<caption class=""mathjax_ignore"">";
if strlength(cap) > 0, s = s + esc(cap) + " "; end
s = s + "<span class=""dim"">(" + dim + ")</span></caption>";
end

% =====================================================================
function s = esc(v)
%ESC  HTML-escape one text value. Elementwise, missing treated as empty.
s = string(v);
if isempty(s), s = ""; end
s(ismissing(s)) = "";
s = replace(s, "&", "&amp;");  s = replace(s, "<", "&lt;");
s = replace(s, ">", "&gt;");   s = replace(s, """", "&quot;");
end

% =====================================================================
function L = css_block()
%CSS_BLOCK  Scoped rules, emitted with every fragment.
%   Repeating them costs a few hundred bytes when a tab shows several tables and
%   buys independence: a fragment must render the same inside uihtml, inside the
%   exported report, and on its own. The unit row's sticky offset is the symbol
%   row's own height; once MathJax typesets a symbol that row grows slightly, so
%   the seam can shift a pixel or two while scrolling - visible only there, and
%   the alternative is a header that scrolls away from a 32-row table.
%   max-height is lifted for print so the browser's Print to PDF shows every row.
L = [ "<style>"
      ".gtbl-wrap{max-height:70vh;overflow:auto;margin:8px 0 14px}"
      ".gtbl{border-collapse:separate;border-spacing:0;font:12px/1.45 ""Segoe UI"",Helvetica,Arial,sans-serif;color:#12161f}"
      ".gtbl caption{caption-side:top;text-align:left;font-weight:600;padding:2px 0 6px;color:#12161f}"
      ".gtbl caption .dim{font-weight:400;color:#5b6473}"
      ".gtbl th,.gtbl td{border-right:1px solid #d8dde5;border-bottom:1px solid #d8dde5;padding:3px 8px;text-align:left;white-space:nowrap}"
      ".gtbl th:first-child,.gtbl td:first-child{border-left:1px solid #d8dde5}"
      ".gtbl thead th{position:sticky;z-index:2;background:#eef1f5;border-top:1px solid #d8dde5;text-align:center;font-weight:600}"
      ".gtbl tr.gsym th{top:0}.gtbl tr.gunit th{top:1.95em;font-weight:400;color:#5b6473;border-bottom:2px solid #0b5c8a}"
      ".gtbl th .sy{margin-right:6px}.gtbl th .nm{font:11px/1.3 Consolas,""Courier New"",monospace;color:#5b6473}"
      ".gtbl td.num{text-align:right;font-variant-numeric:tabular-nums;font-family:Consolas,""Courier New"",monospace}"
      ".gtbl td.bool{text-align:center}.gtbl td.nan{color:#8a1c1c}.gtbl-foot .nan{color:#8a1c1c;font-weight:600}"
      ".gtbl tbody tr:nth-child(even){background:#f7f9fc}.gtbl tbody tr:hover{background:#eaf3fa}"
      ".gtbl td.gtbl-empty{text-align:center;color:#5b6473;padding:10px}"
      ".gtbl-foot{margin:0 0 10px;font-size:11px;line-height:1.5;color:#5b6473;max-width:60em}"
      ".gtbl-note{font-size:12px;color:#8a1c1c;font-weight:600}"
      "@media print{.gtbl-wrap{max-height:none;overflow:visible}.gtbl thead th{position:static}.gtbl{page-break-inside:avoid}}"
      "</style>" ];
end
