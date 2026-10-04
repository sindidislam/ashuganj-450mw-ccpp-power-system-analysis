function outputPath = phase6_write_parameter_register(P,outputPath)
%PHASE6_WRITE_PARAMETER_REGISTER Explicit export; initializer stays read-only.
if nargin<1 || ~isstruct(P) || ~isfield(P,'register') || ~istable(P.register)
    error('Phase6:ParameterRegister','P must contain a parameter register table.');
end
if nargin<2 || isempty(outputPath)
    paths=setup_phase6_workspace();
    outputPath=fullfile(paths.results,'phase6_parameter_register.csv');
end
outputPath=char(outputPath);
parent=fileparts(outputPath);
if ~isempty(parent)&&~isfolder(parent), mkdir(parent); end
R=P.register;
% The scenario runner can change the defaults after initialization. Export
% current selections without mutating the caller's canonical/reference data.
if isfield(P,'scenario')
    names=R.Properties.VariableNames;
    for k=1:numel(names), R.(names{k})=string(R.(names{k})); end
    keys=fieldnames(P.scenario);
    for k=1:numel(keys)
        key=keys{k}; parameter="scenario."+string(key);
        value=P.scenario.(key);
        if isnumeric(value)||islogical(value), value=string(mat2str(value,17));
        else, value=strjoin(string(value),'; '); end
        row=R.Parameter==parameter;
        if any(row)
            if any(R.Value(row)~=value)
                R.Notes(row)=R.Notes(row)+" Selected scenario overrides the initializer default.";
            end
            R.Value(row)=value;
        else
            R(end+1,:)={parameter,value,"as selected","ENGINEERING_ASSUMPTION", ...
                "Phase 6 scenario runner","Additional explicitly selected simulation scenario setting."};
        end
    end
end
writetable(R,outputPath);
end
