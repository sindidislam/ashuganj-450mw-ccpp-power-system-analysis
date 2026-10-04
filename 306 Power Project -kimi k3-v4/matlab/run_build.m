% RUN_BUILD  Phase 10 driver: build the model and report compile status.
%   Run from the matlab/ directory:  matlab -batch "run_build"
addpath(pwd);
ashuganj_setup();

fprintf('MATLAB %s\n', version);
v = ver;
for i = 1:numel(v)
    if contains(v(i).Name, 'Simscape') || contains(v(i).Name, 'Power')
        fprintf('  %-40s %s\n', v(i).Name, v(i).Version);
    end
end

info = build_ashuganj_main('LF1');

% ---- Phase 11: compile check -----------------------------------------
fprintf('\n=== COMPILE CHECK ===\n');
mdl = info.model;
try
    set_param(mdl, 'SimulationCommand', 'update');
    fprintf('  update diagram : PASS\n');
catch ME
    fprintf('  update diagram : FAIL\n    %s\n', ME.message);
    for k = 1:numel(ME.cause)
        fprintf('    cause %d: %s\n', k, ME.cause{k}.message);
    end
end

% ---- report what was actually built ----------------------------------
fprintf('\n=== BLOCK INVENTORY ===\n');
bl = find_system(mdl, 'SearchDepth', 1, 'Type', 'Block');
for i = 1:numel(bl)
    [~, nm] = fileparts(bl{i});
    fprintf('  %-16s %s\n', get_param(bl{i}, 'BlockType'), strrep(get_param(bl{i},'Name'), char(10), ' '));
end

save_system(mdl, info.path);
fprintf('\nDONE. nBlocks=%d nLines=%d\n', info.nBlocks, info.nLines);
