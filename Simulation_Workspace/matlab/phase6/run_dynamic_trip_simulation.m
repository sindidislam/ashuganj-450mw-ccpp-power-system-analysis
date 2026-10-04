function R=run_dynamic_trip_simulation(outDir,root,scenario)
%RUN_DYNAMIC_TRIP_SIMULATION Run and export the actual v4 electrical model.
% R=run_dynamic_trip_simulation() or (outDir,root,scenario).
% Default: GIS230 3PH fault, start .15 s, duration .30 s, stop .60 s.
% Existing model relay edits are retained; scenario is normalized from source
% defaults plus supplied fields so earlier fault/DC overrides cannot leak.
% Use a distinct Phase6/results subfolder for each comparison. Simulation
% errors propagate; analytical trip traces are never substituted.
if nargin<1,outDir=[];end
if nargin<2,root=[];end
if nargin<3,scenario=struct();end
assert(isstruct(scenario)&&isscalar(scenario),'Phase6:Scenario','scenario must be a scalar struct.');
paths=phase6_trip_paths(outDir,root);
if ~isfile(paths.file),build_dynamic_protection_sim(paths.output,paths.project);end
load_system(paths.file);
actual=char(java.io.File(get_param(paths.model,'FileName')).getCanonicalPath());
assert(strcmpi(actual,char(java.io.File(paths.file).getCanonicalPath())), ...
    'Phase6:WrongProject','Close the same-name model from the other project before running v4.');
c=phase6_interactive_settings(paths.model,'get');
assert(strcmp(c.info.model,paths.model),'Phase6:RebuildRequired', ...
    'This model is the old renamed copy. Run build_dynamic_protection_sim once.');
request=struct('name','v4_bus_3ph','faultEnabled',true,'faultType','3PH', ...
    'faultLocation','GIS230','faultStart_s',.15,'faultDuration_s',.30,'stopTime_s',.60);
fields=fieldnames(scenario);for k=1:numel(fields),request.(fields{k})=scenario.(fields{k});end
request=phase6_normalize_scenario(c.P,request);
out=phase6_interactive_settings(paths.model,'run',struct('scenario',request));
c=phase6_interactive_settings(paths.model,'get');
result=export_phase6_results(out,c.info,paths.output);
R=struct('out',out,'info',c.info,'export',result,'sim_mode','measured-simulink', ...
    'times_csv',fullfile(result.outputDir,'relay_times.csv'), ...
    'png',fullfile(result.outputDir,'04_protection_breakers.png'));
fprintf('PHASE6_V4_SIMULATION_PASS %s\n',result.outputDir);
end
