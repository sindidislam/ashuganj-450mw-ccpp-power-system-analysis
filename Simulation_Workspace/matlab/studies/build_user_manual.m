function build_user_manual()
%BUILD_USER_MANUAL  Write docs/manual/USER_MANUAL.html - the operating manual.
%
%   This is the document the model itself points at: the powergui block in
%   simulink/main/Ashuganj_South_Main.slx carries the caption
%   "See docs/manual/USER_MANUAL.html", so whoever opens the diagram is told
%   where the instructions are.
%
%   WHAT IT IS FOR, AND HOW IT DIFFERS FROM THE PROJECT UPDATE
%   ----------------------------------------------------------
%   PROJECT_UPDATE.html answers "what did we find". This answers "how do I run
%   it". One command to type, one diagram to open, one button to press, what each
%   number on the screen means, what to do when it fails, and how to move the
%   whole project to a different computer.
%
%   Written for somebody who has never opened this project: a group member the
%   night before the presentation, or the next person to take the work on.
%
%   EVERY NUMBER IS READ, NOT REMEMBERED
%   ------------------------------------
%   The case figures come from results/load_flow/*.csv. The figures a presenter
%   will see on screen come from the powergui .rep files that the tool itself
%   wrote. The environment line is read from the running MATLAB. The file
%   inventory is counted off disk. Nothing in this page is retyped, so it cannot
%   drift from the model it describes.

root   = ashuganj_root();
lfDir  = fullfile(root, 'results', 'load_flow');
outDir = fullfile(root, 'docs', 'manual');
if ~exist(outDir, 'dir'), mkdir(outDir); end

sumFile = fullfile(lfDir, 'system_summary.csv');
if ~exist(sumFile, 'file')
    error('build_user_manual:noResults', ...
        ['results/load_flow/system_summary.csv does not exist, so there are no ' ...
         'measured numbers to write a manual around. Run RUN_ME (or ' ...
         'run_load_flow_study) first.']);
end

ctx = struct();
ctx.root   = root;
ctx.lfDir  = lfDir;
ctx.outDir = outDir;
ctx.SUM = readtable(sumFile);
ctx.TX  = readtable(fullfile(lfDir, 'transformer_results.csv'));
ctx.BUS = readtable(fullfile(lfDir, 'bus_results.csv'));
ctx.GEN = readtable(fullfile(lfDir, 'generator_results.csv'));
ctx.D   = ashuganj_master_data();

% ---- figures are copied beside the page, not linked across the tree ---------
% docs/manual/ is then a folder that can be zipped, emailed, or opened on a PC
% with no MATLAB and no project, and every image still resolves.
src = { fullfile(root,'results','diagrams','Load_Flow_LF1_Annotated.png')
        fullfile(root,'results','diagrams','Load_Flow_LF2_Annotated.png')
        fullfile(root,'results','plots','bus_voltage_profile.png')
        fullfile(root,'results','plots','transformer_loading.png') };
for k = 1:numel(src)
    if exist(src{k}, 'file')
        [~, nm, ex] = fileparts(src{k});
        copyfile(src{k}, fullfile(outDir, [nm ex]));
    end
end

out = fullfile(outDir, 'USER_MANUAL.html');
fid = fopen(out, 'w');
if fid < 0, error('build_user_manual:open', 'Cannot write %s', out); end
c = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, varargin{:});

% ===================================================================== head
w('<!DOCTYPE html>\n<html lang="en"><head>\n');
w('<meta charset="utf-8">\n');
w('<meta name="viewport" content="width=device-width, initial-scale=1">\n');
w('<title>Ashuganj South Load Flow - User Manual</title>\n');
w('<style>\n%s</style>\n', ashuganj_html_css());
w('</head>\n<body>\n');

w('<header>\n');
w(['<div class="course">EEE 306 &middot; Power System I Laboratory &middot; ' ...
   'January 2026 &middot; Group-03, Section C-1</div>\n']);
w('<h1>User manual &mdash; how to run and<br>demonstrate the load flow model</h1>\n');
w(['<div class="sub">Ashuganj 450 MW Combined Cycle Power Plant (South) &mdash; ' ...
   'balanced steady-state load flow</div>\n']);
w(['<div class="meta">Generated on this installation: MATLAB %s &middot; %s ' ...
   '&middot; %d cases on disk &middot; %g MVA base &middot; %g Hz</div>\n'], ...
   version, computer, height(ctx.SUM), ctx.D.base.Sbase_MVA, ctx.D.base.f_Hz);
w('</header>\n');

% ===================================================================== nav
w('<nav><b>Contents</b><ol>\n');
navs = { '1. Before you begin',                  'm1'
         '2. The one command',                   'm2'
         '3. The full rebuild, step by step',    'm3'
         '4. The live demonstration',            'm4'
         '5. Reading the tool''s own screen',    'm5'
         '6. The four cases',                    'm6'
         '7. Where the answers are',             'm7'
         '8. Changing something safely',         'm8'
         '9. When it goes wrong',                'm9'
         '10. Moving it to another PC',          'm10'
         '11. What this study does not do',      'm11' };
for k = 1:size(navs,1)
    w('<li><a href="#%s">%s</a></li>\n', navs{k,2}, navs{k,1});
end
w('</ol></nav>\n');

% ===================================================================== body
um_part_run(fid, ctx);
um_part_read(fid, ctx);
um_part_care(fid, ctx);

% ===================================================================== foot
w('<footer>\n');
w(['<p>Generated by <code>matlab/studies/build_user_manual.m</code>. The case ' ...
   'figures come from <code>results/load_flow/*.csv</code>, the on-screen ' ...
   'figures from the <code>.rep</code> reports powergui wrote itself, and the ' ...
   'file counts from the folders as they stand. Nothing on this page is ' ...
   'retyped.</p>\n']);
w(['<p>Companion documents: <a href="PROJECT_UPDATE.html">PROJECT_UPDATE.html</a> ' ...
   '&mdash; what the study found, and what is left to do; ' ...
   '<a href="LAB_REPORT.html">LAB_REPORT.html</a> &mdash; the same study written ' ...
   'up in the EEE 306 labsheet form.</p>\n']);
w('<p>Dept. of EEE, BUET &middot; EEE 306 Power System I Laboratory</p>\n');
w('</footer>\n</body></html>\n');

clear c
d = dir(out);
fprintf('  written: %s\n', out);
fprintf('  size   : %.0f kB\n', d.bytes/1024);

um_index(root, outDir);
end
