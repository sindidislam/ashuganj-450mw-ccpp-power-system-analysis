function finish_layout_worker()
% Retain this MATLAB worker briefly after a failed audit for a file-triggered retry.
workerAudit=fileparts(mfilename('fullpath'));
retryFile=fullfile(workerAudit,'retry_layout.flag');
for attempt=1:4
 try
  run(fullfile(workerAudit,'finish_layout.m'));
  return;
 catch err
  fprintf('LAYOUT_WORKER_ATTEMPT_FAILED %d: %s\n',attempt,err.message);
 end
 retry=false;
 for tick=1:36
  pause(5);
  if isfile(retryFile),delete(retryFile);retry=true;break;end
 end
 if ~retry,return;end
end
end
