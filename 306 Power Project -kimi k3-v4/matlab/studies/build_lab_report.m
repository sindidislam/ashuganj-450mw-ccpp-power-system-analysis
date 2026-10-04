function build_lab_report()
%BUILD_LAB_REPORT  Write docs/manual/LAB_REPORT.html in the EEE 306 labsheet form.
%
%   WHY A THIRD DOCUMENT
%   --------------------
%   PROJECT_UPDATE.html answers "what did we find". USER_MANUAL.html answers
%   "how do I run it". Neither is in the form the course marks work in. The
%   labsheets in Labsheets/ (Exp1.pdf to Exp5.pdf) all follow one structure -
%   Objectives, Introduction, Theory, Apparatus, Procedure, Connection Diagram,
%   numbered Data Tables, then Report Questions - and a term project handed in
%   against that structure is read as an experiment rather than as a pile of
%   output. This page is the study written up that way.
%
%   It is not a summary of the other two. The theory is set out from first
%   principles, the procedure is the sequence somebody else would repeat, the
%   tables are numbered Table 1 upward so they can be cited, one calculation is
%   worked by hand against the solver, and the report questions are answered from
%   this plant's own numbers instead of in general terms.
%
%   EVERY NUMBER IS READ FROM THE SOLVED RESULTS
%   --------------------------------------------
%   Same rule as the other two documents: the tables come from
%   results/load_flow/*.csv and the parameters from ashuganj_master_data, so the
%   page cannot state a figure the model does not produce. Run RUN_ME first.

root   = ashuganj_root();
lfDir  = fullfile(root, 'results', 'load_flow');
outDir = fullfile(root, 'docs', 'manual');
if ~exist(outDir, 'dir'), mkdir(outDir); end

sumFile = fullfile(lfDir, 'system_summary.csv');
if ~exist(sumFile, 'file')
    error('build_lab_report:noResults', ...
        ['results/load_flow/system_summary.csv does not exist, so there are no ' ...
         'measured numbers to tabulate. Run RUN_ME (or run_load_flow_study) ' ...
         'first.']);
end

ctx = struct();
ctx.root   = root;
ctx.lfDir  = lfDir;
ctx.outDir = outDir;
ctx.SUM = readtable(sumFile);
ctx.TX  = readtable(fullfile(lfDir, 'transformer_results.csv'));
ctx.BUS = readtable(fullfile(lfDir, 'bus_results.csv'));
ctx.GEN = readtable(fullfile(lfDir, 'generator_results.csv'));
ctx.LN  = readtable(fullfile(lfDir, 'line_results.csv'));
ctx.RES = readtable(fullfile(lfDir, 'residuals.csv'));
ctx.D   = ashuganj_master_data();

% Table numbers are allocated in one place and handed out in order, so a table
% inserted into a section later cannot leave two tables sharing a number.
ctx.tno = 0;

% ---- figures live beside the page ------------------------------------------
% Same reason as the other documents: docs/manual/ has to open on a machine with
% no MATLAB and no project folder, so nothing may point outside it.
src = { fullfile(root,'results','diagrams','Load_Flow_LF1_Annotated.png')
        fullfile(root,'results','diagrams','Load_Flow_LF2_Annotated.png')
        fullfile(root,'results','plots','bus_voltage_profile.png')
        fullfile(root,'results','plots','power_balance.png')
        fullfile(root,'results','plots','transformer_loading.png')
        fullfile(root,'results','plots','line_loading.png') };
for k = 1:numel(src)
    if exist(src{k}, 'file')
        [~, nm, ex] = fileparts(src{k});
        copyfile(src{k}, fullfile(outDir, [nm ex]));
    end
end

out = fullfile(outDir, 'LAB_REPORT.html');
fid = fopen(out, 'w');
if fid < 0, error('build_lab_report:open', 'Cannot write %s', out); end
c = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, varargin{:});

% ===================================================================== head
w('<!DOCTYPE html>\n<html lang="en"><head>\n');
w('<meta charset="utf-8">\n');
w('<meta name="viewport" content="width=device-width, initial-scale=1">\n');
w('<title>EEE 306 Term Project - Ashuganj South Load Flow</title>\n');
w('<style>\n%s</style>\n', ashuganj_html_css());
w('</head>\n<body>\n');

w('<header>\n');
w(['<div class="course">Department of Electrical and Electronic Engineering ' ...
   '&middot; BUET</div>\n']);
w('<h1>EEE 306 Power System I Laboratory<br>Term Project Report</h1>\n');
w(['<div class="sub"><b>Protection coordination and fault analysis of the ' ...
   'Ashuganj 450&nbsp;MW combined cycle power plant (South)</b><br>' ...
   'Stage 1 &mdash; balanced steady-state load flow</div>\n']);
w(['<div class="meta">January 2026 &middot; Group-03, Section C-1 &middot; ' ...
   'Solved on MATLAB %s &middot; %g&nbsp;MVA base &middot; %g&nbsp;Hz ' ...
   '&middot; %d operating cases</div>\n'], ...
   version, ctx.D.base.Sbase_MVA, ctx.D.base.f_Hz, height(ctx.SUM));
w('</header>\n');

% ===================================================================== nav
w('<nav><b>Contents</b><ol>\n');
navs = { '1. Objectives',                          'r1'
         '2. Introduction',                        'r2'
         '3. Theory',                              'r3'
         '4. Software and data used',              'r4'
         '5. Procedure',                           'r5'
         '6. Connection diagram',                  'r6'
         '7. Data tables',                         'r7'
         '8. Sample calculation',                   'r8'
         '9. What each result signifies',          'r9'
         '10. Report questions',                    'r10'
         '11. What to perform next',                'r11' };
for k = 1:size(navs,1)
    w('<li><a href="#%s">%s</a></li>\n', navs{k,2}, navs{k,1});
end
w('</ol></nav>\n');

% ===================================================================== body
ctx = lr_part_theory(fid, ctx);
ctx = lr_part_method(fid, ctx);
ctx = lr_part_data(fid, ctx);
ctx = lr_part_disc(fid, ctx);

% ===================================================================== foot
w('<footer>\n');
w(['<p>Generated by <code>matlab/studies/build_lab_report.m</code> from ' ...
   '<code>results/load_flow/*.csv</code> and ' ...
   '<code>matlab/data/ashuganj_master_data.m</code>. Every figure in every ' ...
   'table was read from the solved results at generation time; none was ' ...
   'retyped, so this report cannot disagree with the model it describes.</p>\n']);
w(['<p>Companion documents in this folder: ' ...
   '<a href="PROJECT_UPDATE.html">PROJECT_UPDATE.html</a> (findings, ' ...
   'assumptions, missing data) and ' ...
   '<a href="USER_MANUAL.html">USER_MANUAL.html</a> (how to run and ' ...
   'demonstrate it).</p>\n']);
w('<p>Dept. of EEE, BUET &middot; EEE 306 Power System I Laboratory</p>\n');
w('</footer>\n</body></html>\n');

clear c
d = dir(out);
fprintf('  written: %s\n', out);
fprintf('  size   : %.0f kB   tables: %d\n', d.bytes/1024, ctx.tno);
end
