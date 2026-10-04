root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode/rev2';
cd(root);
addpath('data'); addpath('tests'); addpath('simulink'); addpath('gui');
try
  fig=ashuganj_rev2_gui('Visible','off');
  tg=findobj(fig,'Type','uitabgroup');
  tabs=tg.Children;
  fprintf('GUI built: %d tabs\n',numel(tabs));
  for k=1:numel(tabs), fprintf('  tab: %s (%d children)\n',tabs(k).Title,numel(tabs(k).Children)); end
  fprintf('lfRefresh: '); fig.UserData.lfRefresh(); fprintf('ok\n');
  close(fig);
  fprintf('GUI headless check PASSED\n');
catch ME
  fprintf('GUI FAIL: %s\n',ME.message);
  for k=1:numel(ME.stack), fprintf('  %s line %d\n',ME.stack(k).name,ME.stack(k).line); end
end
