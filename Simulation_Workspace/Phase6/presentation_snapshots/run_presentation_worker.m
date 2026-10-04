function run_presentation_worker()
% Task-local batch worker; all actions are confined to this presentation job.
out=fileparts(mfilename('fullpath'));p6=fileparts(out);
addpath(fullfile(p6,'scripts'));setup_phase6_workspace();
opengl software;set(0,'DefaultFigureRenderer','painters');
queue=fullfile(out,'work');if ~isfolder(queue),mkdir(queue);end
fprintf('PRESENTATION_WORKER_READY %s\n',version);
t=tic;
while toc(t)<3600 && ~isfile(fullfile(queue,'STOP'))
 jobs=dir(fullfile(queue,'job*.m'));
 for k=1:numel(jobs)
  path=fullfile(queue,jobs(k).name);done=[path '.done'];
  if isfile(done),continue;end
  status=struct('success',false,'job',jobs(k).name,'error','');
  try,evalin('base',sprintf('run(''%s'')',strrep(path,'''','''''')));status.success=true;
  catch err,status.error=getReport(err,'extended','hyperlinks','off');fprintf(2,'%s\n',status.error);end
  fid=fopen(done,'w');fprintf(fid,'%s',jsonencode(status,'PrettyPrint',true));fclose(fid);
  fprintf('PRESENTATION_JOB_FINISHED %s success=%d\n',jobs(k).name,status.success);
 end
 pause(.5);
end
end
