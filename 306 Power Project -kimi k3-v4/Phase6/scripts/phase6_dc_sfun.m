function phase6_dc_sfun(block)
%PHASE6_DC_SFUN Level-2 DC adapter, no persistent/shared runtime state.
% Dialog D,S. Inputs aux AC pu and aggregate raw trip request. Output 12.
% A stored-output interface introduces one 1 ms sample of coupling latency.
block.NumDialogPrms=2;
block.DialogPrmsTunable={'Nontunable','Nontunable'};
block.NumInputPorts=2; block.NumOutputPorts=1;
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;
for k=1:2
    block.InputPort(k).Dimensions=1;
    block.InputPort(k).DatatypeID=0;
    block.InputPort(k).Complexity='Real';
    block.InputPort(k).DirectFeedthrough=false;
end
block.OutputPort(1).Dimensions=12;
block.OutputPort(1).DatatypeID=0;
block.OutputPort(1).Complexity='Real';
block.SampleTimes=[.001 0];
block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('PostPropagationSetup',@allocate);
block.RegBlockMethod('InitializeConditions',@initialize);
block.RegBlockMethod('Outputs',@outputs);
block.RegBlockMethod('Update',@update);
end

function allocate(block)
block.NumDworks=2;
names={'DCState','Diagnostics'}; sizes=[8 12];
for k=1:2
    block.Dwork(k).Name=names{k}; block.Dwork(k).Dimensions=sizes(k);
    block.Dwork(k).DatatypeID=0; block.Dwork(k).Complexity='Real';
    block.Dwork(k).UsedAsDiscState=true;
end
end

function initialize(block)
D=block.DialogPrm(1).Data;
% The eighth state is initialized=false. The first Update initializes the
% physical engine from actual AC/availability inputs, without a duplicate step.
block.Dwork(1).Data=[D.dc_soc_initial;zeros(7,1)];
% Before the first measured update, supply availability is not yet established.
block.Dwork(2).Data=[0;0;0;0;D.dc_soc_initial;0;1;0;1;1;0;0];
end

function outputs(block)
block.OutputPort(1).Data=block.Dwork(2).Data;
end

function update(block)
D=block.DialogPrm(1).Data; S=block.DialogPrm(2).Data;
battery=logical(S.batteryAvailable); charger=logical(S.chargerAvailable);
loss=inf; restore=inf;
if isfield(S,'dcLossTime_s'), loss=S.dcLossTime_s; end
if isfield(S,'dcRestoreTime_s'), restore=S.dcRestoreTime_s; end
if block.CurrentTime>=loss && block.CurrentTime<restore
    battery=false; charger=false;
end
U=struct('auxVoltage_pu',block.InputPort(1).Data, ...
    'batteryAvailable',battery,'chargerAvailable',charger, ...
    'tripDemand',logical(block.InputPort(2).Data));
v=block.Dwork(1).Data;
if v(8)==0
    state=[];
else
    state=struct('SOC',v(1),'chargerCurrentCommand_A',v(2),'Vdc_V',v(3), ...
        'previousTrip',logical(v(4)),'previousClose',logical(v(5)), ...
        'tripRemaining_s',v(6),'closeRemaining_s',v(7));
end
[Y,state]=phase6_dc_step(U,state,.001,D);
block.Dwork(1).Data=[state.SOC;state.chargerCurrentCommand_A;state.Vdc_V; ...
    double(state.previousTrip);double(state.previousClose); ...
    state.tripRemaining_s;state.closeRemaining_s;1];
block.Dwork(2).Data=[Y.Vdc_V;Y.Ibattery_A;Y.Icharger_A;Y.Iload_A;Y.SOC; ...
    double(Y.dcHealthy);double(Y.lowVoltage);double(Y.batteryLow); ...
    double(Y.chargerFailure);double(Y.tripUnavailable); ...
    Y.chargerACPower_W;Y.tripCoilPower_W];
end
