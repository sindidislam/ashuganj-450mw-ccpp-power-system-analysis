function [ok, log, result] = gui_run_capture(fig, titleText, fcn, nOut)
%GUI_RUN_CAPTURE  Run one long job behind a progress dialog and keep its output.
%
%   [ok, log, result] = GUI_RUN_CAPTURE(fig, titleText, fcn, nOut) calls fcn(),
%   a handle taking no arguments, while an indeterminate uiprogressdlg titled
%   titleText stands in fig, and captures everything the job prints.
%
%   nOut asks fcn for that many outputs: 0 (the default) for side effects only,
%   with result = []; 1 for that single output; more than 1 for a 1-by-nOut
%   cell. run_load_flow_study wants nOut = 1, run_all_tests 2 ([np nf]), and
%   build_project_update 0 - it declares no outputs at all, so asking it for one
%   is an error rather than an empty. ok is true only if fcn returned without
%   error, result is [] whenever it did not, and log is char - header, output,
%   then the error report - ready for cellstr(splitlines(string(log))) in a
%   uitextarea or for a 'pre' block of gui_html_report.
%
%   WHY IT NEVER THROWS, AND WHY DIARY RATHER THAN EVALC
%   ----------------------------------------------------
%   The caller is a button, not a script. An uncaught error in a callback leaves
%   the dialog on screen for good, leaves diary pointing at a temp file, and
%   reports the failure only as red text in a command window a GUI user has no
%   reason to watch. Every failure - too few arguments, a non-handle, a case that
%   will not converge, a model not on the path - comes back as ok = false.
%
%   evalc hands its buffer over only on a clean return: if the job errors
%   halfway that buffer dies with the exception, taking the printing that led up
%   to the failure - exactly the diagnostic wanted - with it. diary writes to
%   disk as the job prints, so the file is complete at the moment of the error.
%   diary is global state, so the setting found on entry is put back on the way
%   out, Ctrl-C included: a user keeping their own transcript keeps it.
%
%   WHY THE WINDOW STILL FREEZES, AND WHAT TO EXPECT
%   ------------------------------------------------
%   The dialog is not a background task. MATLAB runs this callback on the one
%   thread that also draws the window, so while power_loadflow or the test suite
%   sits in its own loop nothing repaints: tabs do not respond, the animated bar
%   can stop animating, and Windows may grey the title bar and add "Not
%   Responding". None of that means the job died. Measured on this project, the
%   FIRST solve of a session costs 12-28 s (Simscape Electrical and powergui
%   load and JIT-compile on first use), later solves 1-2 s; run_load_flow_study
%   about 60 s for 4 builds, 4 solves, 6 CSVs and 6 deliverable .slx;
%   make_annotated_diagrams about 90 s because it solves everything again;
%   run_all_tests('model') and build_project_update('Solve',true) several
%   minutes. Wait, do not click, and do not press Ctrl-C in the command window -
%   that interrupt lands mid-build and leaves a half-wired model in Simulink.
%
%   The bar is Indeterminate because none of these jobs reports progress: a load
%   flow is two Newton iterations inside a MathWorks function that says nothing
%   until it returns, so a percentage could only be invented. It is not
%   Cancelable because CancelRequested can only be polled between statements of
%   code we control, and there are none left once the solver has been entered.
%
%   See also GUI_HTML_REPORT, GUI_READ_RESULTS, UIPROGRESSDLG, DIARY.

ok     = false;
result = [];

% narginchk would throw, and this function promises not to. A caller that got
% the argument list wrong gets the same treatment as a job that failed.
if nargin < 3
    log = banner('Working', ['NOT RUN. gui_run_capture needs three arguments: ' ...
          'the figure, a title, and a function handle taking no arguments.']);
    return
end

titleText = one_line(titleText);
if nargin < 4 || isempty(nOut), nOut = 0; end

% isfinite is not redundant below: Inf == fix(Inf) is true.
if ~isa(fcn, 'function_handle')
    log = banner(titleText, sprintf(['NOT RUN. The third argument must be a ' ...
          'function handle taking no arguments, not a %s.'], class(fcn)));
    return
end
if ~(isnumeric(nOut) && isscalar(nOut) && isfinite(nOut) && ...
        nOut >= 0 && nOut == fix(nOut))
    log = banner(titleText, 'NOT RUN. nOut must be a non-negative integer.');
    return
end

% The diary settings are read BEFORE anything redirects them, and one cleanup
% object owns both the redirect and the dialog. That pairing is deliberate: a
% Ctrl-C in the middle of a multi-minute solve unwinds this function without
% running the rest of it, and must not be able to leave a dead dialog on screen
% or the user's own transcript pointed at a file in tempdir. Diary comes back
% from get as an on/off switch value, not char, hence the string round trip.
prev.on   = strcmpi(char(string(get(0, 'Diary'))), 'on');
prev.file = char(string(get(0, 'DiaryFile')));

dlg   = open_dialog(fig, titleText);
guard = onCleanup(@() unwind(dlg, prev));   %#ok<NASGU>

file = [tempname '.log'];
try
    diary('off');       % close any diary already running before re-pointing it
    diary(file);
catch
    file = '';          % capture unavailable; the job itself must still run
end

stamp = char(string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
err   = [];
t0    = tic;
try
    if nOut == 0
        fcn();
    else
        out = cell(1, nOut);
        [out{1:nOut}] = fcn();
        result = out;
        if nOut == 1, result = out{1}; end
    end
    ok = true;
catch err
    % ok stays false and result stays []; err is reported in the log below.
end
secs = toc(t0);

% Stop the capture before reading it - the file must not still be open for
% writing. unwind is idempotent, so the guard repeating it at exit is safe.
unwind([], prev);

log = assemble(titleText, stamp, secs, ok, read_and_delete(file), err);
end

% =====================================================================
function dlg = open_dialog(fig, titleText)
%OPEN_DIALOG  Indeterminate progress dialog, or [] if one cannot be made.
%
%   ancestor() lets a caller hand over the tab or the grid layout instead of the
%   uifigure uiprogressdlg needs. A plain figure(), a deleted handle or a
%   non-graphics value ends up as [], and the job then runs with no dialog
%   rather than not running at all.
dlg = [];
try
    f = ancestor(fig, 'figure');
    if isempty(f) || ~isvalid(f), return, end
    dlg = uiprogressdlg(f, 'Title', titleText, 'Indeterminate', 'on', ...
        'Cancelable', 'off', ...
        'Message', { 'Working. The window cannot repaint until this returns.'
                     'A first solve in a fresh session takes 12-28 s, a full'
                     'study about 60 s, the test suite minutes. A frozen bar or'
                     'a "Not Responding" title bar is expected.'
                     'Do not click, and do not press Ctrl-C.' });
    drawnow;            % paint the dialog before the thread is taken away
catch
    dlg = [];
end
end

% =====================================================================
function unwind(dlg, prev)
%UNWIND  Put the diary state back, then close the dialog. Safe to repeat.
try
    diary('off');
    if prev.on && ~isempty(prev.file)
        diary(prev.file);           % diary(name) also switches it back on
    elseif ~isempty(prev.file)
        set(0, 'DiaryFile', prev.file);
    end
catch
    % Restoring someone else's transcript is best effort. Failing here would
    % throw away a job that has already finished.
end

% close(dlg) would also do, but delete cannot leave a stale handle behind if the
% figure itself died while the job was running.
if ~isempty(dlg) && isvalid(dlg)
    try, delete(dlg); catch, end
end
end

% =====================================================================
function txt = read_and_delete(file)
%READ_AND_DELETE  Diary contents, newlines normalised, then the file binned.
%
%   A job that printed nothing never makes diary create the file, so a missing
%   file is a normal outcome and not an error; and an orphan left in tempdir
%   because the delete failed is cheaper than losing the log over it.
txt = '';
if isempty(file) || ~isfile(file), return, end
try, txt = fileread(file); catch, txt = ''; end
try, delete(file); catch, end

txt = strrep(strrep(txt, char([13 10]), newline), char(13), newline);
if ~isempty(txt) && txt(end) ~= newline, txt = [txt newline]; end
end

% =====================================================================
function log = assemble(titleText, stamp, secs, ok, body, err)
%ASSEMBLE  Header, captured output, then the error report if there was one.
verdict = 'FAILED';
if ok, verdict = 'FINISHED'; end
log = sprintf('%s\n%s\nstarted %s   elapsed %.1f s   outcome %s\n\n', ...
              titleText, rule(titleText), stamp, secs, verdict);

if isempty(strtrim(body))
    log = [log '(the job printed nothing to the command window)' newline];
else
    log = [log body];   % concatenated, never a format string: it is full of %
end

if ~ok && ~isempty(err)
    % 'hyperlinks','off' matters: the default report embeds <a href="matlab:...">
    % tags that read as noise in a uitextarea and as markup in an HTML report.
    try
        rep = getReport(err, 'extended', 'hyperlinks', 'off');
    catch
        rep = err.message;
    end
    if ~isempty(err.identifier)
        rep = sprintf('identifier: %s\n%s', err.identifier, rep);
    end
    log = [log sprintf('\n--- ERROR %s\n%s\n', repmat('-', 1, 48), rep)];
end
end

% =====================================================================
function s = one_line(v)
%ONE_LINE  A one-line char title from whatever the caller passed, never empty.
s = 'Working';
try
    t = strtrim(char(gui_textify(v)));
    if ~isempty(t), s = t; end
catch
    % Keep the default. A dialog title is not worth failing a run over.
end
end

% =====================================================================
function s = banner(titleText, msg)
%BANNER  The log for a run that never started.
s = sprintf('%s\n%s\n\n%s\n', titleText, rule(titleText), msg);
end

% =====================================================================
function s = rule(titleText)
%RULE  Underline for a header line, never shorter than a dozen characters.
s = repmat('=', 1, max(12, numel(titleText)));
end
