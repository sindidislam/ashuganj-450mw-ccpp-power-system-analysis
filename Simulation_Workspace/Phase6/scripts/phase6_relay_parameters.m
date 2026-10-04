function R = phase6_relay_parameters(P)
%PHASE6_RELAY_PARAMETERS Numeric, source-traceable measured-relay study data.
% P.protection.settings is a table; P.protection.parameters is a table or
% scalar numeric-field struct. Omitted sources use frozen Phase-5 CSVs.
% Provenance codes: 1=frozen Phase5, 2=caller, 3=Phase6 academic assumption.
% No values in this function imply commissioned or official plant settings.
if nargin < 1, P = struct(); end
paths = setup_phase6_workspace();
settingSource = 1; parameterSource = 1;
if isfield(P,'protection') && isfield(P.protection,'settings') ...
        && ~isempty(P.protection.settings)
    S = P.protection.settings; settingSource = 2;
else
    S = readtable(fullfile(paths.reference,'phase5_relay_settings.csv'), ...
        'TextType','string');
end
if isfield(P,'protection') && isfield(P.protection,'parameters') ...
        && ~isempty(P.protection.parameters)
    A = P.protection.parameters; parameterSource = 2;
else
    A = readtable(fullfile(paths.reference,'phase5_parameter_values.csv'), ...
        'TextType','string');
end
assert(istable(S),'phase6:settingsType','Protection settings must be a table.');
Q = numeric_parameters(A);
ids = ["GEN-51","GEN-51N","GSUT-HV-51","GIS-Q0-51", ...
    "GEN-51-SIEMENS-BL","GEN-87G","GSUT-87T","GIS-87B","LINE-7SD"];
columns = {'setting_A_primary','setting_A_secondary','ct_ratio','tms', ...
    'tdef_s','operate_proxy_s'};
R.settingValues = nan(numel(ids),numel(columns));
R.settingSourceRows = zeros(1,numel(ids));
for k = 1:numel(ids)
    row = find(string(S.device_id) == ids(k));
    assert(isscalar(row),'phase6:settingRow', ...
        'Expected exactly one setting row for %s.',ids(k));
    R.settingSourceRows(k) = row;
    for j = 1:numel(columns)
        R.settingValues(k,j) = numeric_value(S.(columns{j})(row));
    end
end
order = [1 3 2 6 7 8 9];
active = R.settingValues(order,:);
assert(all(string(S.curve(R.settingSourceRows(order(1:3)))) == "SI"), ...
    'phase6:curve','Only selected IEC Standard Inverse curves are implemented.');
R.pickup_A = active(:,1).';
R.pickupSecondary_A = active(:,2).';
R.ctRatio = active(:,3).';
R.tms = active(1:3,4).';
R.delay_s = active(4:7,6).';
R.communicationDelay_s = .005;
assert(all(isfinite([R.pickup_A R.ctRatio R.tms R.delay_s])) ...
    && all([R.pickup_A R.ctRatio R.tms R.delay_s] > 0), ...
    'phase6:settingNumeric','Selected pickups, CTs, TMS and delays must be positive finite values.');
assert(all(abs(R.pickupSecondary_A-R.pickup_A./R.ctRatio) < 1e-9), ...
    'phase6:ctConsistency','Primary and secondary settings disagree with CT ratios.');
assert(Q.GSUT_vector_clock == 1,'phase6:vectorGroup', ...
    'The implemented cyclic delta compensation requires the YNd1 convention.');
assert(Q.GEN_87G_highset_enabled == 0,'phase6:unsupportedHighset', ...
    'The frozen study has high-set OFF; high-set emulation is not implemented.');
R.lvToHv = Q.GSUT_LV_kV/Q.GSUT_HV_kV;
R.iecK = 0.14; R.iecAlpha = 0.02;
R.highsetEnabled = zeros(1,7);
% Missing generator/line biases and transformer breakpoint are explicit
% academic additions, never inferred installed relay settings or CT knees.
R.slope1 = [0.30 Q.GSUT_87T_slope1_percent/100 ...
    Q.BUS_87B_slope_percent/100 0.30];
R.slope2 = R.slope1;
R.slope2(2) = Q.GSUT_87T_slope2_percent/100;
% Equal slopes make the generator, bus and line breakpoints immaterial.
R.knee_A = [Q.GEN_rated_A 2*Q.GSUT_rated_A ...
    Q.BUS_87B_base_A Q.LINE_87L_base_A];
R.restraintFactor = 0.5;
R.lineSchemeClearingProxy_s = Q.LINE_87L_clearing_s;
R.phase5 = Q;
R.provenance = struct('settings',settingSource,'parameters',parameterSource, ...
    'pickup',settingSource*ones(1,7),'tms',settingSource*ones(1,3), ...
    'delay',settingSource*ones(1,4),'lvToHv',parameterSource, ...
    'slope1',[3 parameterSource parameterSource 3], ...
    'slope2',[3 parameterSource parameterSource 3], ...
    'knee',3*ones(1,4),'restraintFactor',3,'characteristic',3);
R.assumptions = struct('generatorBias_percent',30,'lineBias_percent',30, ...
    'transformerKneeRatedMultiple',2,'halfSumRestraint',1, ...
    'synchronizedPhasors',1,'communicationDelay_s',R.communicationDelay_s, ...
    'harmonicBlockingImplemented',0,'ctSaturationImplemented',0);
end

function Q = numeric_parameters(A)
if istable(A)
    Q = struct();
    for k = 1:height(A)
        name = char(string(A.parameter(k)));
        value = numeric_value(A.value(k));
        assert(isvarname(name) && ~isfield(Q,name),'phase6:parameterName', ...
            'Parameter names must be unique valid MATLAB fields.');
        assert(isscalar(value) && isfinite(value),'phase6:parameterValue', ...
            'Parameter %s must be a finite scalar.',name);
        Q.(name) = value;
    end
else
    assert(isstruct(A) && isscalar(A),'phase6:parameterType', ...
        'Protection parameters must be a table or numeric scalar struct.');
    Q = A;
    names = fieldnames(Q);
    for k = 1:numel(names)
        v = Q.(names{k});
        assert(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v), ...
            'phase6:parameterValue','Parameter %s must be a finite scalar.',names{k});
        Q.(names{k}) = double(v);
    end
end
end

function value = numeric_value(raw)
% string(double) rounds to display precision in MATLAB; preserve source
% doubles exactly and parse text only for mixed numeric/inapplicable columns.
if isnumeric(raw)
    value = double(raw);
else
    value = str2double(string(raw));
end
end
