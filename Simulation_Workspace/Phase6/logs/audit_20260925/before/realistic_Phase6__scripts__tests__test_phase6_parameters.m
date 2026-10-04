function test_phase6_parameters()
% Parameter-contract tests; expected defects include base drift or source promotion.
paths = setup_phase6_workspace();
assert(exist('init_phase6_parameters','file')==2, ...
    'Phase6:MissingParameterProvider','Central parameter provider is missing.');
protected = {fullfile(paths.project,'matlab','data','ashuganj_generators.m'), ...
    fullfile(paths.project,'matlab','data','ashuganj_transformers.m'), ...
    fullfile(paths.project,'matlab','data','ashuganj_lines.m'), ...
    fullfile(paths.project,'matlab','data','ashuganj_grid.m'), ...
    fullfile(paths.reference,'phase5_parameter_values.csv')};
before = cellfun(@phase5b_sha256,protected,'UniformOutput',false);
P = init_phase6_parameters();
assert(isscalar(P) && isstruct(P));
assert(isequaln(P.generator,ashuganj_generators()));
assert(isequaln(P.transformers,ashuganj_transformers()));
assert(isequaln(P.grid,ashuganj_grid()));
assert(isequaln(P.lines,ashuganj_lines()));
assert(isequaln(P.loads,ashuganj_loads()));
assert(isequaln(P.assumptions,engineering_assumptions()));
assert(isequaln(P.systems,ashuganj_phase2_systems()));
assert(abs(P.machine.Rs_pu-0.000842190082644628)<1e-14);
assert(P.machine.Sn_VA==458e6 && P.machine.Vn_V==22000);
assert(max(abs(P.machine.reactances_pu-[1.783 .3256 .2608 1.751 .5087 .2593 .2027]))<1e-12);
assert(max(abs(P.machine.timeConstants_s-[7.547 .045 .839 .07]))<1e-12);
assert(P.machine.polePairs==1 && P.machine.H_s==P.generator.H_s);
assert(P.machine.P_W==360e6 && P.machine.Vref_pu==1);
assert(P.machine.damping_pu==0 && ~isfield(P.machine,'Rf_pu'));
assert(height(P.reference.primary)==1);
assert(strcmp(string(P.reference.primary.Case_ID),'LF360_GAT_OUT'));
assert(P.reference.primary.Gen_P_MW==360);
assert(strcmp(P.scenario.networkProfile,'PHASE3_BASELINE'));
assert(P.grid.R_ohm==0 && P.grid.Isc_kA==50 && P.grid.Vnom_V==230000);
T = P.protection.parameters;
assert(T.value(strcmp(string(T.parameter),'GRID_Isc_kA'))==45.01);
assert(isequaln(T,readtable(fullfile(paths.reference,'phase5_parameter_values.csv'), ...
    'VariableNamingRule','preserve')));
assert(P.scenario.faultResistance_ohm==.01 && P.scenario.groundResistance_ohm==.01);
assert(~P.scenario.faultEnabled && strcmp(P.scenario.name,'normal'));
assert(P.scenario.protectionEnabled && P.scenario.batteryAvailable && P.scenario.chargerAvailable);
assert(isinf(P.scenario.dcLossTime_s) && isinf(P.scenario.dcRestoreTime_s));
assert(P.TsElectrical==50e-6 && P.TsControl==.001 && P.numericalShunt_W==10);
R = P.register;
required = {'Parameter','Value','Unit','Classification','Source','Notes'};
assert(all(ismember(required,R.Properties.VariableNames)));
assert(numel(unique(string(R.Parameter)))==height(R));
allowed = ["VERIFIED_SOURCE","DERIVED_FROM_VERIFIED_SOURCE","USER_ASSERTED", ...
    "ENGINEERING_ASSUMPTION","PLACEHOLDER_NOT_FOR_FINAL_RESULT"];
assert(all(ismember(string(R.Classification),allowed)));
assert(all(strlength(string(R.Source))>0) && all(strlength(string(R.Notes))>0));
rf = strcmp(string(R.Parameter),'generator.Rf_numeric');
assert(nnz(rf)==1 && strcmp(string(R.Classification(rf)),'PLACEHOLDER_NOT_FOR_FINAL_RESULT'));
assert(contains(string(R.Notes(rf)),'UNRESOLVED') && contains(string(R.Notes(rf)),'unused'));
assert(str2double(string(R.Value(rf)))==.10631);
for n = {'machine.damping_pu','scenario.faultResistance_ohm','scenario.groundResistance_ohm', ...
        'TsElectrical','TsControl','numericalShunt_W'}
    row = strcmp(string(R.Parameter),n{1});
    assert(nnz(row)==1 && strcmp(string(R.Classification(row)),'ENGINEERING_ASSUMPTION'));
end
keys = fieldnames(P.assumptions);
assert(all(ismember("assumptions."+string(keys),string(R.Parameter))));
assert(all(ismember("phase5."+string(T.parameter),string(R.Parameter))));
after = cellfun(@phase5b_sha256,protected,'UniformOutput',false);
assert(isequal(before,after),'Phase6:UpstreamMutation','Initializer changed a protected file.');
if ~isfolder(paths.results), mkdir(paths.results); end
out = [tempname(paths.results) '.csv'];
P.scenario.networkProfile='PHASE5_STUDY';
P.scenario.stopTime_s=3.25;
phase6_write_parameter_register(P,out);
cleanup=onCleanup(@() delete(out));
opts=detectImportOptions(out,'VariableNamingRule','preserve');
opts=setvartype(opts,{'Parameter','Value'},'string');
written=readtable(out,opts);
assert(height(written)==height(R));
assert(isequal(string(written.Parameter),string(R.Parameter)));
assert(written.Value(written.Parameter=="scenario.networkProfile")=="PHASE5_STUDY", ...
    'Phase6:StaleScenarioRegister','Export must capture selected scenario overrides.');
assert(str2double(written.Value(written.Parameter=="scenario.stopTime_s"))==3.25);
clear cleanup
fprintf('test_phase6_parameters PASS: canonical identity, machine mapping, profile separation, provenance, CSV export and protected hashes.\n');
end
