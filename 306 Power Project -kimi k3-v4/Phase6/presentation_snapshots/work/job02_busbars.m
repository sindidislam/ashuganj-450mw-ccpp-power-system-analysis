out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';modelFile=fullfile(p6,[mdl '.slx']);
clear phase6_presentation_busbars style_phase6_model phase6_color_wires;
phase6_presentation_busbars(mdl);
set_param(mdl,'SimulationCommand','update');
afterRun=sim(mdl,'StopTime','0.30','ReturnWorkspaceOutputs','on');
afterSummary=afterRun.get('phase6_summary');
load(fullfile(out,'work','baseline_summary.mat'),'baselineSummary');
assert(isequal(baselineSummary.Time,afterSummary.Time),'Phase6:BusTime','Time grids changed.');
delta=max(abs(baselineSummary.Data-afterSummary.Data),[],'all');
assert(delta<1e-7,'Phase6:BusBehavior','Busbar insertion changed measured output: %g',delta);
save_system(mdl,modelFile);
if ~isfolder(fullfile(out,'raw')),mkdir(fullfile(out,'raw'));end
phase6_color_wires(mdl);
print(['-s' mdl],'-dpng','-r120',fullfile(out,'raw','00_overview.png'));
for part={'Switchyard','Auxiliaries','Grid','DC Supply'}
 print(['-s' mdl '/' part{1}],'-dpng','-r140',fullfile(out,'raw',[strrep(part{1},' ','_') '_check.png']));
end
busbarVerification=struct('compiled',true,'baselineStopTime_s',.30,'maxSummaryDifference',delta, ...
 'phaseSeparation','Three separate ideal pass-through conductors per AC bus', ...
 'DCRepresentation','Existing signal-based DC model, labeled B06', 'savedModel',modelFile);
fid=fopen(fullfile(out,'verification.json'),'w');fprintf(fid,'%s',jsonencode(busbarVerification,'PrettyPrint',true));fclose(fid);
fprintf('BUSBAR_PASS delta=%g\n',delta);
