function c = gui_uihtml(parent, html)
%GUI_UIHTML  A uihtml component fed from a file on disk, not from a string.
%
%   c = GUI_UIHTML(parent, html) creates a uihtml inside parent - a uifigure,
%   uipanel, uitab or uigridlayout - writes html to a uniquely named file under
%   tempdir, points the component at that file, and records the path in
%   c.UserData.file so the caller can refresh or copy assets beside it.
%
%   c = GUI_UIHTML(c, html) refreshes a component this function created: the new
%   markup goes to a NEW file, the component is re-pointed at it, the previous
%   file is deleted, and the SAME component handle comes back - so a tab that
%   parked it in a uigridlayout cell keeps its position and its layout row.
%
%   html may be a char array, a string scalar, a string array or a cellstr;
%   rows and elements are joined with newlines. A bare fragment - the <table>
%   that GUI_TABLE_TO_HTML returns - is wrapped in a minimal document; markup
%   that already contains <html is written through untouched.
%
%   WHY A FILE, WHEN HTMLSource ACCEPTS THE MARKUP DIRECTLY
%   ------------------------------------------------------
%   It does accept both. matlab.ui.control.HTML/set.HTMLSource in R2024a treats
%   a value ending in '.html' as a file that must open, and passes anything else
%   through as markup, so a string would draw correctly the first time. Three
%   things make the file the right choice anyway.
%
%   1. HTMLSource is declared AbortSet (HTML.m, the properties block that
%      declares it). An assignment whose value equals the current one is
%      discarded BEFORE the setter runs, so nothing reaches the view. A tab that
%      rebuilds its table after a re-solve and assigns markup that happens to be
%      byte-identical would keep showing the stale page and raise no error - the
%      worst possible failure for a results display. A new file path every time
%      is never equal to the old one, so a refresh always lands, whether or not
%      the content changed.
%   2. Supporting files must sit in the SAME folder as the HTML for uihtml to
%      reach them, and relative paths that climb out of that folder are not
%      reliable. With markup there is no folder to put a stylesheet or an
%      embedded PNG in; with a file, c.UserData.file names one - copy the asset
%      beside it and reference it by bare name.
%   3. The Export tab writes the same document a browser opens. Rendering from a
%      file keeps the in-window view and the exported file the same bytes
%      instead of two code paths that can silently drift apart.
%
%   WHY A PLAIN PATH AND NOT A file:/// URL
%   ---------------------------------------
%   The setter rejects any URL that is not the local connector, and it decides
%   what a URL is purely by prefix (www, http://, https://, ftp://, mailto:,
%   tel:). A bare Windows path is therefore safe even though the drive letter
%   carries a colon, while dressing it up as file:///... turns a working
%   assignment into an error. This project root also contains two spaces, so a
%   URL form would need percent-encoding on top. Pass the path as it comes out
%   of fullfile.
%
%   WHAT THE FILE DOES NOT BUY: THE CDN
%   -----------------------------------
%   uihtml cannot load third-party JavaScript over the network, and no MathJax
%   ships with R2024a in a usable form. The MathJax <script src="https://...">
%   that GUI_HTML_REPORT writes is therefore inert in this component, and any
%   equations in it show as literal \( ... \) - that report's own fallback
%   banner explains this to the reader. Equations meant for the window belong in
%   a uilabel with Interpreter 'latex', fed from gui_symbols(name).latex; the
%   MathJax route only pays off once the file is opened in a real browser with
%   winopen or web. Plain HTML and CSS, including every table this GUI builds,
%   render fine here because they need no JavaScript at all.
%
%   The temp folder is shared by every component and every concurrent MATLAB
%   session. Nothing here deletes a file it did not just replace, because a file
%   that looks stale may still be the live source of another session's
%   component, and uihtml exposes no deletion callback to hook. One orphan per
%   closed component is the deliberate price.
%
%   See also GUI_HTML_REPORT, GUI_TABLE_TO_HTML, GUI_SYMBOLS, UIHTML.

narginchk(2, 2);

if ~(isa(parent, 'handle') && isscalar(parent) && isvalid(parent))
    error('gui_uihtml:badTarget', ...
          ['First argument must be a live container (uifigure, uipanel, ' ...
           'uitab, uigridlayout) or a uihtml returned by an earlier ' ...
           'gui_uihtml call.']);
end

% Written before the component is touched: if the markup is malformed or the
% temp folder is unwritable, the caller keeps whatever was on screen.
file = write_temp(as_document(html));

if isa(parent, 'matlab.ui.control.HTML')
    c = parent;
else
    c = uihtml(parent);
end

% Read-modify-write of UserData, not a wholesale replacement: a caller may have
% stashed its own bookkeeping there and only .file belongs to this helper.
ud  = c.UserData;
old = '';
if isstruct(ud) && isscalar(ud)
    if isfield(ud, 'file')
        old = char(string(ud.file));
    end
else
    ud = struct();
end

c.HTMLSource = file;
ud.file      = file;
c.UserData   = ud;

if ~isempty(old) && ~strcmp(old, file) && isfile(old)
    try
        delete(old);
    catch
        % The embedded browser can still hold the previous file open for a
        % moment after being re-pointed. A leftover temp file is harmless;
        % failing the refresh over it would not be.
    end
end
end

% =====================================================================
function doc = as_document(html)
%AS_DOCUMENT  Join the input to one char array and guarantee a declared charset.
%
%   The wrapper exists for the charset, not for decoration. The dataset prose
%   carries en-dashes and degree signs; a file with no declared encoding is read
%   by the embedded browser in the platform default and those characters arrive
%   as mojibake. The few style rules stop an unstyled fragment from rendering in
%   the browser default serif, which looks nothing like the rest of the window.

if isempty(html)
    body = '';
elseif ischar(html)
    if size(html, 1) > 1
        body = char(strjoin(string(cellstr(html))', newline));
    else
        body = html;
    end
elseif isstring(html) || iscellstr(html)
    body = char(strjoin(string(html(:))', newline));
else
    error('gui_uihtml:badHTML', ...
          'Second argument must be char, string or cellstr, not %s.', ...
          class(html));
end

% A standalone document from gui_html_report is never rewritten: it owns its own
% <head>, its own CSS and its print rules.
if contains(lower(body), '<html')
    doc = body;
    return
end

shell = [ "<!DOCTYPE html>"
          "<html lang=""en""><head>"
          "<meta charset=""utf-8"">"
          "<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">"
          "<style>"
          "  body  { font-family: 'Segoe UI', Helvetica, Arial, sans-serif;"
          "          font-size: 12px; color: #202020; background: #ffffff;"
          "          margin: 8px; }"
          "  table { border-collapse: collapse; margin: 6px 0 12px 0; }"
          "  th, td { border: 1px solid #c8c8c8; padding: 3px 7px;"
          "           text-align: left; vertical-align: top; }"
          "  th    { background: #eef1f5; font-weight: 600; }"
          "  caption { text-align: left; font-weight: 600; padding: 4px 0; }"
          "</style>"
          "</head><body>"
          string(body)
          "</body></html>" ];

doc = char(strjoin(shell, newline));
end

% =====================================================================
function file = write_temp(doc)
%WRITE_TEMP  One uniquely named .html per call, in one shared temp folder.
%
%   The name must end in '.html' or set.HTMLSource treats the path as markup and
%   the component displays the path text itself. tempname supplies the unique
%   stem, so two components - or two MATLAB sessions - never collide.

folder = fullfile(tempdir, 'ashuganj_gui_html');
if ~isfolder(folder)
    [ok, msg] = mkdir(folder);
    if ~ok
        error('gui_uihtml:open', 'Cannot create %s: %s', folder, msg);
    end
end

[~, stem] = fileparts(tempname);
file = fullfile(folder, [stem '.html']);

fid = fopen(file, 'w', 'n', 'UTF-8');
if fid < 0
    error('gui_uihtml:open', 'Cannot write %s', file);
end
closer = onCleanup(@() fclose(fid));   %#ok<NASGU>

% doc is the ARGUMENT, never the format string: the markup is full of % and \
% characters that fprintf would otherwise read as conversion specifiers.
fprintf(fid, '%s', doc);
end
