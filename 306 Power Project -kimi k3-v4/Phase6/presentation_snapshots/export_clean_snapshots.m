function export_clean_snapshots()
% Re-export fresh high-resolution PNGs of the whole SLD and all subsystems
% from the renamed Simulink model.
snapDir = fileparts(mfilename('fullpath'));
phase6Dir = fileparts(snapDir);
addpath(phase6Dir);
addpath(fullfile(phase6Dir, 'scripts'));

mdl = 'PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
load_system(mdl);
cleanup = onCleanup(@() close_system(mdl, 0));

manifestFile = fullfile(snapDir, 'manifest.json');
rawDir = fullfile(snapDir, 'raw');
if ~exist(rawDir, 'dir')
    mkdir(rawDir);
end

recordsText = fileread(manifestFile);
records = jsondecode(recordsText);

fprintf('Exporting %d system-level snapshots from %s...\n', numel(records), mdl);
for k = 1:numel(records)
    r = records(k);
    outPng = fullfile(snapDir, strrep(r.image, '/', filesep));
    sysPath = r.system;
    fprintf('[%02d/%02d] Exporting: %s -> %s\n', k, numel(records), sysPath, r.image);
    try
        % Ensure system window is open/sized for clean capture
        open_system(sysPath, 'window');
        set_param(sysPath, 'ZoomFactor', 'FitSystem');
        drawnow;
        print(['-s' sysPath], '-dpng', '-r160', outPng);
    catch err
        fprintf(2, 'Failed to print %s: %s\n', sysPath, err.message);
    end
end
fprintf('EXPORT_COMPLETE: %d snapshots exported.\n', numel(records));
end
