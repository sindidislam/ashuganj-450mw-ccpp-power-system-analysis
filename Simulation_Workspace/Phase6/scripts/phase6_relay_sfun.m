function phase6_relay_sfun(block)
%PHASE6_RELAY_SFUN Level-2 adapter for real packed measured RMS phasors.
% Dialog R,S. Inputs: sensors 228, valid 1. Outputs: diagnostics 43, requests 6.
% DWork only; outputs hold the last 1 ms update, with no direct feedthrough.
block.NumDialogPrms=2;
block.DialogPrmsTunable={'Nontunable','Nontunable'};
block.NumInputPorts=2; block.NumOutputPorts=2;
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;
dimensions=[228 1];
for k=1:2
    block.InputPort(k).Dimensions=dimensions(k);
    block.InputPort(k).DatatypeID=0;
    block.InputPort(k).Complexity='Real';
    block.InputPort(k).DirectFeedthrough=false;
end
dimensions=[43 6];
for k=1:2
    block.OutputPort(k).Dimensions=dimensions(k);
    block.OutputPort(k).DatatypeID=0;
    block.OutputPort(k).Complexity='Real';
end
block.SampleTimes=[.001 0];
block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('PostPropagationSetup',@allocate);
block.RegBlockMethod('InitializeConditions',@initialize);
block.RegBlockMethod('Outputs',@outputs);
block.RegBlockMethod('Update',@update);
end

function allocate(block)
block.NumDworks=3;
names={'RelayState','Diagnostics','Requests'}; sizes=[29 43 6];
for k=1:3
    block.Dwork(k).Name=names{k}; block.Dwork(k).Dimensions=sizes(k);
    block.Dwork(k).DatatypeID=0; block.Dwork(k).Complexity='Real';
    block.Dwork(k).UsedAsDiscState=true;
end
end

function initialize(block)
M=measurements(zeros(19,3));
[Y,state]=phase6_relay_step(M,[],.001,block.DialogPrm(1).Data,false);
save_result(block,Y,state);
end

function outputs(block)
block.OutputPort(1).Data=block.Dwork(2).Data;
block.OutputPort(2).Data=block.Dwork(3).Data;
end

function update(block)
R=block.DialogPrm(1).Data; S=block.DialogPrm(2).Data;
valid=logical(block.InputPort(2).Data);
packed=reshape(block.InputPort(1).Data,12,19).';
I=complex(packed(:,7:9),packed(:,10:12));
if ~valid, I=complex(zeros(19,3)); end
M=measurements(I);
v=block.Dwork(1).Data;
state=struct('trip',logical(v(1:7).'),'timer_s',v(8:14).', ...
    'inverseDuty',v(15:17).','differentialTimer_s',reshape(v(18:29),4,3));
enabled=logical(S.protectionEnabled) && valid;
if isfield(S,'relayMask'), enabled=enabled & logical(reshape(S.relayMask,1,7)); end
[Y,state]=phase6_relay_step(M,state,.001,R,enabled);
save_result(block,Y,state);
end

function M=measurements(I)
names={'IgenInner','IgenTerminal','IgsutLV','IgsutHV','IbusIn', ...
    'IbusOut','IgatHV','IlineLocal','IlineRemote'};
M=struct();
for k=1:9, M.(names{k})=I(k,:); end
M.Ineutral_A=abs(I(12,1));
end

function save_result(block,Y,state)
block.Dwork(1).Data=[double(state.trip(:));state.timer_s(:);state.inverseDuty(:); ...
    state.differentialTimer_s(:)];
diag=[double(Y.pickup) double(Y.trip) Y.timer_s Y.operatingTime_s ...
    Y.currentSecondary_A Y.differential_A Y.restraint_A Y.threshold_A];
block.Dwork(2).Data=diag(:);
block.Dwork(3).Data=[double(Y.breakerRequest(:));double(Y.unitTrip)];
end
