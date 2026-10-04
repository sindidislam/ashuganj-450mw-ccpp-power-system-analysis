function [html, file] = gui_html_report(blocks, varargin)
%GUI_HTML_REPORT  Assemble one standalone HTML document from report blocks.
%
%   html = GUI_HTML_REPORT(blocks) builds a complete document (char) from a
%   struct array whose every element carries .Type and .Content:
%     'h1' 'h2' 'p' 'pre'  text        'math'   LaTeX, delimiters optional
%     'table'  a table                 'image'  a path to a PNG/JPEG/GIF/SVG
%     'html'   markup, passed verbatim - for a fragment a tab built itself
%   An optional .Caption is used by 'table' and 'image'. 'Title' and 'Subtitle'
%   set the heading; with 'File',p the document is also written there and the
%   second output is the absolute path written ('' when File is not given).
%   Nothing is rounded here: values arrive already carrying their symbol and
%   unit from GUI_TABLE_TO_HTML headers built by GUI_SYMBOLS.
%
%   'image' blocks are inlined as base64 data URIs so the report is ONE file: an
%   HTML mailed without its sibling folder shows broken icons instead.
%
%   MathJax v3 comes from a CDN: right for a file opened in a browser, useless
%   inside a uihtml component, which cannot reach one. The script tag's onerror
%   and a post-load check both set html.nomathjax, which reveals a banner saying
%   what happened and swaps every typeset equation for its raw LaTeX source, so
%   the mathematics degrades instead of vanishing. The print rules exist because
%   the submitted artefact is paper: A4, 15 mm margins, and no page break inside
%   a table, figure, equation or code block, so the browser's own Print to PDF
%   gives the report rather than a draft of it.
%
%   See also GUI_TABLE_TO_HTML, GUI_SYMBOLS, GUI_UIHTML, GUI_TEXTIFY.

p = inputParser;
p.FunctionName = 'gui_html_report';
p.addRequired('blocks', @(x) isempty(x) || isstruct(x));
p.addParameter('Title', 'Ashuganj 450 MW CCPP (South) - Load Flow Study', @(x) ischar(x) || isstring(x));
p.addParameter('Subtitle', '', @(x) ischar(x) || isstring(x));
p.addParameter('File', '', @(x) ischar(x) || isstring(x));
p.parse(blocks, varargin{:});
opt = p.Results;
if ~isempty(blocks) && ~all(isfield(blocks, {'Type', 'Content'}))
    error('gui_html_report:badBlocks', ...
          'Every block needs a Type and a Content field. Fields present: %s', strjoin(fieldnames(blocks)', ', '));
end
stamp = sprintf('generated %s by gui_html_report, MATLAB R%s', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')), version('-release'));

L = [ "<!DOCTYPE html><html lang=""en""><head><meta charset=""utf-8"">"
      "<meta name=""viewport"" content=""width=device-width, initial-scale=1"">"
      "<title>" + esc(opt.Title) + "</title><style>"
      css()
      "</style>"
      head_scripts()
      "</head><body><div class=""page""><header><h1 class=""doctitle"">" + esc(opt.Title) + "</h1>" ];
if strlength(string(opt.Subtitle)) > 0, L(end+1,1) = "<p class=""subtitle"">" + esc(opt.Subtitle) + "</p>"; end
L = [L; "<p class=""stamp"">" + esc(stamp) + "</p></header>"; cdn_notice()];

for i = 1:numel(blocks)
    L(end+1,1) = block_html(blocks(i), i);   %#ok<AGROW>
end

L(end+1,1) = "<footer>Ashuganj 450 MW CCPP (South), load flow study. Every value here is read from the " + ...
    "project dataset or from results/load_flow/; nothing is recomputed in this document. Print this " + ...
    "page from a browser for a PDF copy.</footer></div></body></html>";
html = char(strjoin(L, newline));
file = '';
if strlength(string(opt.File)) > 0, file = write_file(html, char(opt.File)); end
end

% =====================================================================
function out = block_html(b, idx)
%BLOCK_HTML  Render one block. An unknown Type warns and falls back to prose:
%   a bad block must not cost the reader the other forty, so anything
%   unrecognised is drawn as a flagged paragraph with its content intact.
cap = "";
if isfield(b, 'Caption'), cap = textof(b.Caption); end
kind = lower(strtrim(char(string(b.Type))));
switch kind
    case 'h1',    out = "<h1>" + esc(textof(b.Content)) + "</h1>";
    case 'h2',    out = "<h2>" + esc(textof(b.Content)) + "</h2>";
    case 'p',     out = "<p>" + replace(esc(textof(b.Content)), newline, "<br>") + "</p>";
    case 'pre',   out = "<pre class=""code"">" + esc(textof(b.Content)) + "</pre>";
    case 'math',  out = math_html(textof(b.Content));
    case 'table', out = table_html(b.Content, cap);
    case 'image', out = image_html(textof(b.Content), cap);
    case {'html', 'raw'},  out = textof(b.Content);   % verbatim, already markup
    otherwise
        warning('gui_html_report:unknownType', ...
                'Block %d has Type ''%s''; rendered as a flagged paragraph.', idx, kind);
        out = "<p class=""missing"">[block " + idx + ", unknown type " + esc(kind) + ...
              "]</p><p>" + esc(textof(b.Content)) + "</p>";
end
end

% =====================================================================
function out = math_html(tex)
%MATH_HTML  Display equation, plus the same source as a hidden raw block.
%   Delimiters are added only when the caller did not supply them, so a symbol
%   from gui_symbols ('$V$') and a hand-written align environment both arrive
%   unaltered. The raw copy sits in a <pre>, which MathJax is told to skip.
t    = strtrim(tex);
body = "\[" + t + "\]";
if startsWith(t, "$") || startsWith(t, "\[") || startsWith(t, "\begin"), body = t; end
out = "<div class=""math"">" + body + "</div>" + newline + "<pre class=""mathraw"">" + esc(t) + "</pre>";
end

% =====================================================================
function out = table_html(T, cap)
%TABLE_HTML  Hand a table to gui_table_to_html, or render a plain one. That helper
%   owns the MathJax column headers, so it is preferred, and it is called inside a try
%   because the report must still assemble when it is off the path. Cells go through
%   gui_textify, so the NaN that is load-bearing in these CSVs (merged buses, the
%   coupler row) prints as NaN and not as a blank.
if ischar(T) || isstring(T)
    out = textof(T);   % already a markup fragment
    return
elseif ~istable(T)
    out = "<p class=""missing"">Table content is a " + class(T) + ", not a table.</p>";
    return
end
args = {};
if strlength(cap) > 0, args = {'Caption', char(cap)}; end
try
    out = textof(gui_table_to_html(T, args{:}));   % textof, not string: guarantees one scalar
    return
catch err
    warning('gui_html_report:tableFallback', ...
            'gui_table_to_html failed (%s); using the plain renderer.', err.message);
end
capTag = "";
if strlength(cap) > 0, capTag = "<caption>" + esc(cap) + "</caption>"; end
rows = strings(1, height(T));
for i = 1:height(T)
    c = arrayfun(@(j) esc(gui_textify(T{i, j})), 1:width(T));
    rows(i) = "<tr><td>" + strjoin(c, "</td><td>") + "</td></tr>";
end
out = "<table>" + capTag + "<thead><tr><th>" + strjoin(esc(string(T.Properties.VariableNames)), "</th><th>") + ...
      "</th></tr></thead><tbody>" + strjoin(rows, "") + "</tbody></table>";
end

% =====================================================================
function out = image_html(pathIn, cap)
%IMAGE_HTML  Inline one PNG/JPEG/GIF/SVG as a base64 data URI.
f = char(pathIn);
if isempty(f) || exist(f, 'file') ~= 2
    out = "<p class=""missing"">Image not found: " + esc(f) + " - run make_load_flow_plots or make_annotated_diagrams first.</p>";
    return
end
fid = fopen(f, 'r');
if fid < 0
    out = "<p class=""missing"">Image could not be opened: " + esc(f) + "</p>";
    return
end
raw = fread(fid, Inf, '*uint8'); fclose(fid);
if isempty(raw), out = "<p class=""missing"">Image file is empty (0 bytes): " + esc(f) + "</p>"; return; end
[~, base, ext] = fileparts(f);
types = struct('png', "image/png", 'jpg', "image/jpeg", 'jpeg', "image/jpeg", 'gif', "image/gif", 'svg', "image/svg+xml");
key = char(erase(lower(string(ext)), "."));
if ~isfield(types, key), key = 'png'; end
alt = cap;
if strlength(alt) == 0, alt = string([base ext]); end
out = "<figure><img alt=""" + esc(alt) + """ src=""data:" + types.(key) + ";base64," + ...
      string(matlab.net.base64encode(raw)) + """>";
if strlength(cap) > 0, out = out + "<figcaption>" + esc(cap) + "</figcaption>"; end
out = out + "</figure>";
end

% =====================================================================
function outPath = write_file(html, target)
%WRITE_FILE  Write the document as UTF-8 and return the absolute path that dir()
%   supplies whatever the caller passed, so the Export tab can hand the result
%   straight to a winopen button.
d = fileparts(target);
if ~isempty(d) && exist(d, 'dir') ~= 7, mkdir(d); end
fid = fopen(target, 'w', 'n', 'UTF-8');
if fid < 0, error('gui_html_report:open', 'Cannot write %s', target); end
fprintf(fid, '%s', html);   % html is the ARGUMENT: the markup is full of % and \
fclose(fid);
info    = dir(target);
outPath = fullfile(info(1).folder, info(1).name);
end

% =====================================================================
function t = textof(v)
%TEXTOF  Any content as one string, keeping the line breaks a caller wrote.
%   gui_textify collapses whitespace runs - right for a uitable cell, wrong for
%   a 'pre' block - so text input is joined here, not flattened.
if ischar(v) || isstring(v)
    t = string(strjoin(cellstr(string(v))', sprintf('\n')));
elseif iscell(v) && all(cellfun(@(x) ischar(x) || isstring(x), v(:)))
    t = string(strjoin(cellstr(string(v(:)))', sprintf('\n')));
else
    t = gui_textify(v);
end
end

% =====================================================================
function s = esc(v)
%ESC  HTML-escape prose, headings, captions, alt text and raw TeX. Elementwise.
s = string(v);
if isempty(s), s = ""; end
s(ismissing(s)) = "";
s = replace(s, "&", "&amp;");   s = replace(s, "<", "&lt;");   s = replace(s, ">", "&gt;");
s = replace(s, """", "&quot;");
end

% =====================================================================
function L = head_scripts()
%HEAD_SCRIPTS  MathJax v3 config, the CDN tag, and two failure detectors.
%   Backslashes are literal in a MATLAB double-quoted string, so '\\(' reaches the
%   browser as the two characters JavaScript needs for one backslash. The 1.5 s
%   timeout catches a request that neither succeeds nor fires onerror.
L = [ "<script>window.MathJax={tex:{inlineMath:[['\\(','\\)'],['$','$']],displayMath:[['$$','$$'],['\\[','\\]']],processEscapes:true},options:{skipHtmlTags:['script','noscript','style','textarea','pre','code']}};"
      "function mjFailed(){document.documentElement.classList.add('nomathjax');}</script>"
      "<script id=""mjsrc"" async onerror=""mjFailed()"" src=""https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js""></script>"
      "<script>window.addEventListener('load',function(){setTimeout(function(){if(!(window.MathJax&&window.MathJax.startup)){mjFailed();}},1500);});</script>" ];
end

% =====================================================================
function s = cdn_notice()
%CDN_NOTICE  Hidden unless html.nomathjax is set by one of the two detectors.
s = "<div class=""cdn""><b>Equations are shown as raw LaTeX source.</b> MathJax could not be loaded " + ...
    "from its CDN - either this machine is offline, or the document is inside a MATLAB uihtml " + ...
    "component, which cannot reach a content delivery network. Open this file in a browser with internet access to see them typeset.</div>";
end

% =====================================================================
function L = css()
%CSS  Screen styling, the MathJax fallback switch, and the print rules.
L = [ ":root{--ink:#12161f;--mut:#5b6473;--rule:#d8dde5;--accent:#0b5c8a;--panel:#f6f8fb}*{box-sizing:border-box}"
      "body{margin:0;background:#eef1f5;color:var(--ink);font:15px/1.55 ""Segoe UI"",Helvetica,Arial,sans-serif}"
      ".page{max-width:1000px;margin:24px auto;padding:32px 42px;background:#fff;border:1px solid var(--rule)}"
      "header{border-bottom:2px solid var(--accent);padding-bottom:12px;margin-bottom:20px}h1.doctitle{font-size:26px;margin:0 0 4px}"
      "p{margin:8px 0}p.subtitle{margin:0;color:var(--mut)}p.stamp{margin:6px 0 0;color:var(--mut);font-size:12px}"
      "h1{font-size:22px;margin:26px 0 8px;border-bottom:1px solid var(--rule);padding-bottom:4px}h2{font-size:17px;margin:20px 0 6px;color:var(--accent)}"
      "table{border-collapse:collapse;margin:12px 0;font-size:13px;width:100%}th,td{border:1px solid var(--rule);padding:4px 8px;text-align:right}"
      "th{background:var(--panel);text-align:center;font-weight:600}td:first-child,th:first-child{text-align:left}caption{caption-side:top;text-align:left;font-weight:600;padding:0 0 4px}"
      "pre.code{background:var(--panel);border:1px solid var(--rule);padding:10px;overflow-x:auto;font:12px/1.4 Consolas,""Courier New"",monospace}"
      "figure{margin:16px 0;text-align:center}figure img{max-width:100%;height:auto;border:1px solid var(--rule)}figcaption{color:var(--mut);font-size:12px;padding-top:6px}"
      ".math{margin:14px 0;text-align:center;overflow-x:auto}pre.mathraw{display:none;background:var(--panel);border-left:3px solid var(--accent);padding:8px 10px;font:12px/1.4 Consolas,monospace}"
      "footer{margin-top:28px;border-top:1px solid var(--rule);padding-top:10px;color:var(--mut);font-size:12px}@page{size:A4;margin:15mm}"
      ".missing{color:#8a1c1c;font-weight:600}.cdn{display:none;border-left:4px solid #b8860b;background:#fdf6e3;padding:8px 12px;margin:0 0 18px;font-size:13px}"
      "html.nomathjax .cdn{display:block}html.nomathjax .math{display:none}html.nomathjax pre.mathraw{display:block}"
      "@media print{body{background:#fff}.page{max-width:none;margin:0;padding:0;border:0}table,figure,pre,.math{page-break-inside:avoid}h1,h2{page-break-after:avoid}}" ];
end
