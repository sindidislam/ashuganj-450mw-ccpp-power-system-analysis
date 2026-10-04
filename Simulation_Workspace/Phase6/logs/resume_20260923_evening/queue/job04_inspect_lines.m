mdl='PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL';
ls=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','line');
fprintf('LINE_COUNT %d\n',numel(ls));
disp(get_param(ls(1),'ObjectParameters'));
try,set_param(ls(1),'ForegroundColor','blue');fprintf('LINE_FOREGROUND_WORKS\n');catch e,disp(e.message);end
try,set_param(ls(1),'Color','blue');fprintf('LINE_COLOR_WORKS\n');catch e,disp(e.message);end
load(fullfile(paths.results,'final_normal.mat'),'out','info');
[comparison,settings]=phase6_compare_reference(out,info);
writetable(comparison,fullfile(paths.results,'operating_point_comparison.csv'));
writetable(settings,fullfile(paths.results,'setting_consistency.csv'));disp(comparison(:,[1 3 4 7 9]));
