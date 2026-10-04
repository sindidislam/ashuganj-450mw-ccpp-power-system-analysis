function evening_worker()
% Single task-local MATLAB process for final sequential verification jobs.
wroot=fileparts(mfilename('fullpath'));wjobs=fullfile(wroot,'queue');
if ~isfolder(wjobs),mkdir(wjobs);end
wstart=tic;fprintf('EVENING_WORKER_READY\n');
while toc(wstart)<7200 && ~isfile(fullfile(wjobs,'STOP'))
 wfiles=dir(fullfile(wjobs,'*.m'));
 for wi=1:numel(wfiles)
  wfile=fullfile(wjobs,wfiles(wi).name);wmark=[wfile '.done'];
  if isfile(wmark)||~isfile([wfile '.ready']),continue;end
  fprintf('JOB_START %s\n',wfiles(wi).name);
  wresult=struct('job',wfiles(wi).name,'success',false,'error','');
  try,evalin('base',sprintf('run(''%s'')',strrep(wfile,'''','''''')));wresult.success=true;
  catch we,wresult.error=getReport(we,'extended','hyperlinks','off');fprintf(2,'%s\n',wresult.error);end
  wf=fopen(wmark,'w');fprintf(wf,'%s',jsonencode(wresult));fclose(wf);
  fprintf('JOB_DONE %s success=%d\n',wfiles(wi).name,wresult.success);
 end
 pause(.5);
end
fprintf('EVENING_WORKER_STOPPED\n');
end
