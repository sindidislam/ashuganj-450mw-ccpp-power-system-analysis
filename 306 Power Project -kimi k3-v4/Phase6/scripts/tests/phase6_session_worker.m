function phase6_session_worker()
% Task-local MATLAB test harness. Only jobs placed under Phase6/logs/jobs run.
phase6 = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(phase6,'scripts'));
setup_phase6_workspace();
jobs = fullfile(phase6,'logs','jobs');
if ~exist(jobs,'dir'), mkdir(jobs); end
fprintf('PHASE6_WORKER_READY MATLAB %s\n',version);
t0 = tic;
while toc(t0) < 3*3600 && ~isfile(fullfile(jobs,'STOP'))
    files = dir(fullfile(jobs,'*.m'));
    for k=1:numel(files)
        file = fullfile(jobs,files(k).name);
        marker = [file '.done'];
        if isfile(marker), continue; end
        started = datetime('now');
        fprintf('\nJOB_START %s\n',files(k).name);
        diary([file '.log']);
        result = struct('job',files(k).name,'success',false,'started',char(started),'error','');
        try
            evalin('base',sprintf('run(''%s'')',strrep(file,'''','''''')));
            result.success = true;
        catch err
            result.error = getReport(err,'extended','hyperlinks','off');
            fprintf(2,'%s\n',result.error);
        end
        result.finished = char(datetime('now'));
        diary off;
        fid = fopen(marker,'w'); fprintf(fid,'%s',jsonencode(result)); fclose(fid);
        fprintf('JOB_END %s success=%d\n',files(k).name,result.success);
    end
    pause(0.5);
end
fprintf('PHASE6_WORKER_STOPPED\n');
end
