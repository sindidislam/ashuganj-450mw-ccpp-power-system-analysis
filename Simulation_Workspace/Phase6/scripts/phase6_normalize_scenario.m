function S = phase6_normalize_scenario(P,override)
%PHASE6_NORMALIZE_SCENARIO One validated configuration for build and studies.
if nargin<2, override=struct(); end
assert(isstruct(override)&&isscalar(override),'Phase6:ScenarioType', ...
    'Scenario overrides must be a scalar structure.');
S=P.scenario;
S.dispatch_MW=P.reference.primary.Gen_P_MW;
S.relayMask=true(1,7);
S.breakerFailed=false(1,5);
S.manualOpen=false(1,5);
S.manualOpenTime_s=Inf;
S.generatorTripTime_s=Inf;
S.measurementScale=ones(1,19);
names=fieldnames(override);
for k=1:numel(names)
    assert(isfield(S,names{k}),'Phase6:ScenarioField','Unknown scenario field: %s',names{k});
    S.(names{k})=override.(names{k});
end
S.name=textValue(S.name,'name');
S.networkProfile=upper(textValue(S.networkProfile,'networkProfile'));
S.faultType=upper(textValue(S.faultType,'faultType'));
S.faultLocation=upper(textValue(S.faultLocation,'faultLocation'));
assert(ismember(string(S.networkProfile),["PHASE3_BASELINE","PHASE5_STUDY"]), ...
    'Phase6:NetworkProfile','Unknown network profile.');
assert(ismember(string(S.faultType),["3PH","SLG","LL","LLG"]), ...
    'Phase6:FaultType','Fault type must be 3PH, SLG, LL or LLG.');
assert(ismember(string(S.faultLocation),["GEN","GSUT_LV","GSUT_HV","GIS230","LINE230","GRID230","AUX66"]), ...
    'Phase6:FaultLocation','Unknown fault location.');
finiteScalar(S.dispatch_MW,'dispatch_MW');
assert(S.dispatch_MW>=0&&S.dispatch_MW<=450,'Phase6:Dispatch','Dispatch must be between 0 and 450 MW.');
positive={'stopTime_s','faultStart_s','faultDuration_s','faultResistance_ohm','groundResistance_ohm'};
for k=1:numel(positive)
    n=positive{k};finiteScalar(S.(n),n);
    assert(S.(n)>0,'Phase6:ScenarioPositive','%s must be positive.',n);
end
assert(S.faultStart_s>2/P.f_Hz,'Phase6:FaultWarmup', ...
    'Fault start must be later than the two-cycle measurement warmup.');
flags={'faultEnabled','protectionEnabled','batteryAvailable','chargerAvailable','GAT_in'};
for k=1:numel(flags),n=flags{k};S.(n)=booleanValue(S.(n),n,[1 1]);end
S.relayMask=booleanValue(S.relayMask,'relayMask',[1 7]);
S.breakerFailed=booleanValue(S.breakerFailed,'breakerFailed',[1 5]);
S.manualOpen=booleanValue(S.manualOpen,'manualOpen',[1 5]);
events={'manualOpenTime_s','generatorTripTime_s','dcLossTime_s','dcRestoreTime_s'};
for k=1:numel(events)
    n=events{k};v=S.(n);
    assert(isnumeric(v)&&isreal(v)&&isscalar(v)&&~isnan(v)&&v>=0, ...
        'Phase6:EventTime','%s must be nonnegative finite seconds, or +Inf to disable the event.',n);
end
assert(S.dcRestoreTime_s>=S.dcLossTime_s,'Phase6:DCSchedule', ...
    'DC restore time must not precede DC loss time.');
assert(isnumeric(S.measurementScale)&&isreal(S.measurementScale) ...
    &&isequal(size(S.measurementScale),[1 19]) ...
    &&all(isfinite(S.measurementScale))&&all(S.measurementScale>=0), ...
    'Phase6:MeasurementScale','measurementScale must be 19 finite nonnegative real values.');
assert(~S.faultEnabled||S.faultStart_s<S.stopTime_s,'Phase6:FaultTime', ...
    'Enabled fault start must be before stop time.');
end

function finiteScalar(v,n)
assert(isnumeric(v)&&isreal(v)&&isscalar(v)&&isfinite(v), ...
    'Phase6:ScenarioNumber','%s must be a finite real numeric scalar.',n);
end

function v=booleanValue(v,n,shape)
assert((isnumeric(v)||islogical(v))&&isreal(v)&&isequal(size(v),shape) ...
    &&all(isfinite(v(:)))&&all(v(:)==0|v(:)==1), ...
    'Phase6:ScenarioBoolean','%s must contain only logical values or numeric 0/1 with size %s.',n,mat2str(shape));
v=logical(v);
end

function value=textValue(value,n)
assert((ischar(value)&&isrow(value))||(isstring(value)&&isscalar(value)&&~ismissing(value)), ...
    'Phase6:ScenarioText','%s must be a text scalar.',n);
value=strtrim(char(value));
assert(~isempty(value),'Phase6:ScenarioText','%s must not be empty.',n);
end
