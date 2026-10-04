function um_index(root, outDir)
%UM_INDEX  Write docs/manual/index.html, the front door to the three documents.
%
%   Deliberately short. Its whole job is that somebody who opens the folder
%   without being told anything ends up on the right page, and that the folder
%   still makes sense to a reader with no MATLAB installed.
%
%   Everything it states about the documents - that they exist, how big they
%   are, when they were written - is read off disk here, so it cannot claim a
%   page that is not there. It is written last of the three for that reason.

f = fullfile(outDir, 'index.html');
fid = fopen(f, 'w');
if fid < 0
    error('um_index:cannotWrite', 'Cannot write %s', f);
end
c = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, varargin{:});

docs = { 'USER_MANUAL.html',   'How to run it', ...
            ['Setting up, the one command, the click-by-click live ' ...
             'demonstration, the three things on the tool''s screen that look ' ...
             'wrong and are not, what each output file holds, what to do when ' ...
             'something fails, and how to move the project to another PC.']
         'PROJECT_UPDATE.html', 'What it found', ...
            ['The model, the four operating cases, the results and what they ' ...
             'mean, every assumption and what it is worth, the data still ' ...
             'missing, and the next stage of the study. This is the document to ' ...
             'present.']
         'LAB_REPORT.html',    'The written report', ...
            ['The same study in the EEE 306 labsheet form: objectives, theory, ' ...
             'the impedance and per-unit calculations worked through by hand, ' ...
             'the result tables, what each number signifies, report questions, ' ...
             'and what to perform next. This is the document to submit.'] };

w('<!DOCTYPE html>\n<html lang="en"><head>\n');
w('<meta charset="utf-8">\n');
w('<meta name="viewport" content="width=device-width, initial-scale=1">\n');
w('<title>Ashuganj South Load Flow - Documentation</title>\n');
w('<style>\n%s</style>\n', ashuganj_html_css());
w('</head>\n<body>\n');

w('<header>\n');
w(['<div class="course">EEE 306 &middot; Power System I Laboratory &middot; ' ...
   'January 2026 &middot; Group-03, Section C-1</div>\n']);
w('<h1>Ashuganj 450 MW Combined Cycle<br>Power Plant (South)</h1>\n');
w(['<div class="sub">Balanced steady-state load flow study &mdash; MATLAB, ' ...
   'Simulink and Simscape Electrical</div>\n']);
w('</header>\n');

% ===================================================================== the two
w('<section>\n');
w('<h2>Start here</h2>\n');
w(['<p>Three documents, all generated from the same solved results. Read the ' ...
   'first to <b>run</b> the study, the second to <b>present</b> it, the third to ' ...
   '<b>submit</b> it.</p>\n']);
w('<div class="cards2">\n');
for k = 1:size(docs,1)
    d = dir(fullfile(outDir, docs{k,1}));
    w('<div class="box">\n');
    if isempty(d)
        w('<h4>%s</h4>\n', docs{k,2});
        w(['<p class="warn"><code>%s</code> has not been generated yet. In ' ...
           'MATLAB, from the project root, type <code>RUN_ME docs</code>.</p>\n'], ...
           docs{k,1});
    else
        w('<h4><a href="%s">%s</a></h4>\n', docs{k,1}, docs{k,2});
        w('<p>%s</p>\n', docs{k,3});
        w('<p class="sl"><code>%s</code> &middot; %.0f kB &middot; written %s</p>\n', ...
          docs{k,1}, d.bytes/1024, datestr(d.datenum, 'dd mmm yyyy HH:MM'));
    end
    w('</div>\n');
end
w('</div>\n');
w('</section>\n');

% ===================================================================== figures
pngs = dir(fullfile(outDir, '*.png'));
if ~isempty(pngs)
    w('<section>\n');
    w('<h2>Figures</h2>\n');
    w(['<p>The figures the documents embed, as standalone images. They open ' ...
       'on any machine, with or without MATLAB, and they are the safest thing to ' ...
       'put on a projector.</p>\n']);
    w('<table class="files"><tbody>\n');
    for k = 1:numel(pngs)
        w('<tr><td><a href="%s">%s</a></td><td class="sl">%s</td></tr>\n', ...
          pngs(k).name, pngs(k).name, figure_caption(pngs(k).name));
    end
    w('</tbody></table>\n');
    w('</section>\n');
end

% ===================================================================== how to
w('<section>\n');
w('<h2>Running it yourself</h2>\n');
w(['<p>Open MATLAB, make the <b>project root</b> the current folder &mdash; two ' ...
   'levels above this one, the folder holding <code>RUN_ME.m</code> &mdash; and ' ...
   'type <code>RUN_ME check</code> first, then <code>RUN_ME</code>. Sections 1 ' ...
   'and 2 of the user manual explain what each one does; section 10 covers ' ...
   'moving the project to a different computer.</p>\n']);
w(['<p>Simulink and Simscape Electrical are the only requirements, and nothing ' ...
   'needs an internet connection.</p>\n']);
w('<h3>With no MATLAB at all</h3>\n');
w(['<p>This folder is self-contained: every page and every figure reference ' ...
   'nothing outside it, so it can be copied, zipped or emailed on its own and it ' ...
   'still reads. Everything in it was generated from the solved results &mdash; ' ...
   'no figure and no number in any of the three documents was typed by ' ...
   'hand.</p>\n']);
w('</section>\n');

% ===================================================================== footer
w('<footer>\n');
w(['<p>Generated %s by <code>matlab/studies/build_user_manual.m</code> from the ' ...
   'results in <code>results/load_flow/</code>. Regenerate with ' ...
   '<code>RUN_ME docs</code>.</p>\n'], datestr(now, 'dd mmm yyyy, HH:MM'));
w('<p class="sl">Project root: <code>%s</code></p>\n', um_esc(root));
w('<p>Dept. of EEE, BUET &middot; EEE 306 Power System I Laboratory</p>\n');
w('</footer>\n</body></html>\n');

clear c
d = dir(f);
fprintf('  written: %s\n', f);
fprintf('  size   : %.0f kB\n', d.bytes/1024);
end

% =====================================================================
function s = figure_caption(name)
%FIGURE_CAPTION  A one-line description for a figure file name.
%   An unrecognised name gets no caption rather than a wrong one, so a figure
%   added later is listed honestly instead of being described as something it is
%   not.
switch lower(name)
    case 'bus_voltage_profile.png'
        s = 'Solved voltage at every bus, all four cases, against the limits.';
    case 'power_balance.png'
        s = 'Generation, auxiliary demand, export and losses, all four cases.';
    case 'transformer_loading.png'
        s = 'Loading of each transformer against every cooling stage.';
    case 'line_loading.png'
        s = 'Loading of each branch against its documented rating.';
    case 'sld_reference.png'
        s = 'The Simulink diagram, laid out to match the original single-line drawing.';
    otherwise
        if startsWith(lower(name), 'load_flow_') && contains(lower(name), 'annotated')
            s = ['The single-line diagram with that case''s solved numbers ' ...
                 'written onto it.'];
        else
            s = '';
        end
end
end
