function out = make_annotated_diagrams(varargin)
%MAKE_ANNOTATED_DIAGRAMS  The presentation copy of the one-line, with the solved
%                         load flow written on it.
%
%   out = MAKE_ANNOTATED_DIAGRAMS                 all four cases
%   out = MAKE_ANNOTATED_DIAGRAMS('Cases', {'LF1'})       one case
%   out = MAKE_ANNOTATED_DIAGRAMS('Export', false)        build, do not print PNG
%
%   WHY THIS NEEDS TWO PASSES, AND CANNOT BE DONE IN ONE
%   ---------------------------------------------------
%   power_loadflow('solve') WRITES ITS SOLUTION BACK INTO THE BLOCKS - the source
%   Voltage and PhaseAngle and the load NominalVoltage all change (measured in
%   matlab/env/probe_mutation.m). So the model that has just been solved is no
%   longer the model that was specified, and saving it would ship a network with a
%   solution smeared into its parameters.
%
%   Hence: build clean -> solve -> CAPTURE the numbers -> throw that model away ->
%   build a SECOND, fresh network and write the captured numbers onto it as text.
%   What ships is the network as specified, annotated with what it does. The
%   numbers on the sheet are text; the blocks underneath them still hold the
%   nameplate data from the Phase 7 dataset.
%
%   WHAT IS PRODUCED
%   ----------------
%   simulink/studies/Load_Flow_<case>_Annotated.slx   the openable model
%   results/diagrams/Load_Flow_<case>_Annotated.png   the printable sheet
%
%   These are PRESENTATION artefacts. simulink/main/Ashuganj_South_Main.slx stays
%   un-annotated and is the model to run a fresh study from, because a sheet
%   carrying LF1's numbers would be misleading if the reader then solved LF3 on
%   it. That separation is deliberate.
%
%   The numbers are NOT recomputed here. run_load_flow_study does the solving and
%   the cross-checking; this function only re-renders. A case that failed to
%   converge is skipped with a message rather than drawn with blanks.
%
%   See also RUN_LOAD_FLOW_STUDY, BUILD_ASHUGANJ_MAIN.

p = inputParser;
p.addParameter('Cases', {}, @iscell);
p.addParameter('Export', true, @islogical);
p.parse(varargin{:});
opt = p.Results;

root = ashuganj_root();
D    = ashuganj_master_data();
if isempty(opt.Cases), opt.Cases = {D.cases.ID}; end

fprintf('\n%s\n', repmat('=', 1, 76));
fprintf('  ANNOTATED ONE-LINE DIAGRAMS - solved load flow written on the sheet\n');
fprintf('%s\n', repmat('=', 1, 76));

% ---- PASS 1: solve, and write nothing ---------------------------------
% Write false and SaveModels false: this pass exists only to obtain numbers, and
% must not touch the deliverable .slx files or overwrite the study CSVs that
% run_load_flow_study already wrote after its own cross-checks.
fprintf('\n  pass 1 - solving %s (no files written)\n', strjoin(opt.Cases, ', '));
S = run_load_flow_study('Cases', opt.Cases, 'Write', false, 'SaveModels', false);

outDir = fullfile(root, 'results', 'diagrams');
if opt.Export && ~exist(outDir, 'dir'), mkdir(outDir); end
studyDir = fullfile(root, 'simulink', 'studies');
if ~exist(studyDir, 'dir'), mkdir(studyDir); end

% ---- PASS 2: rebuild fresh, with the numbers as text ------------------
fprintf('\n  pass 2 - rebuilding each case with its numbers stamped on\n');
out = struct('ID', {}, 'model', {}, 'png', {}, 'skipped', {});
for i = 1:numel(S)
    cid = S(i).ID;
    if isempty(S(i).B)
        fprintf('  %-5s SKIPPED - did not converge, so there is nothing to stamp\n', cid);
        out(end+1) = struct('ID', cid, 'model', '', 'png', '', 'skipped', true);   %#ok<AGROW>
        continue
    end
    nm   = ['Load_Flow_' cid '_Annotated'];
    mdlP = fullfile(studyDir, [nm '.slx']);
    info = build_ashuganj_main(cid, 'ModelName', nm, 'Quiet', true, ...
        'Backup', false, 'Save', true, 'Close', false, ...
        'SavePath', mdlP, 'Results', S(i));

    png = '';
    if opt.Export
        png = fullfile(outDir, [nm '.png']);
        % -r100 was measured: it exports 1.3916 px per model unit, which keeps the
        % 8 pt footer text legible when the whole sheet is scaled to slide width.
        print(['-s' info.model], '-dpng', '-r100', png);
        d = dir(png);
        fprintf('  %-5s %s (%.0f kB)\n', cid, [nm '.png'], d.bytes/1024);
    else
        fprintf('  %-5s %s\n', cid, [nm '.slx']);
    end
    bdclose(info.model);
    out(end+1) = struct('ID', cid, 'model', mdlP, 'png', png, 'skipped', false);   %#ok<AGROW>
end

fprintf('\n  models : simulink/studies/Load_Flow_<case>_Annotated.slx\n');
if opt.Export
    fprintf('  sheets : results/diagrams/Load_Flow_<case>_Annotated.png\n');
end
fprintf(['  NOTE   : simulink/main/Ashuganj_South_Main.slx is deliberately NOT\n' ...
         '           annotated - it is the model to run a fresh study from.\n\n']);
end
