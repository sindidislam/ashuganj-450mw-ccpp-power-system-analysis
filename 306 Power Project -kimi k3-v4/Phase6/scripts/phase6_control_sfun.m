function phase6_control_sfun(block)
% Level-2 discrete controller, with resettable model-owned states.
block.NumDialogPrms=1; block.DialogPrmsTunable={'Nontunable'};
block.NumInputPorts=1;block.NumOutputPorts=1;
block.SetPreCompInpPortInfoToDynamic;block.SetPreCompOutPortInfoToDynamic;
block.InputPort(1).Dimensions=3;block.InputPort(1).DirectFeedthrough=false;
block.OutputPort(1).Dimensions=2;
block.SampleTimes=[block.DialogPrm(1).Data.Ts 0];
block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('PostPropagationSetup',@allocate);
block.RegBlockMethod('InitializeConditions',@initialize);
block.RegBlockMethod('Outputs',@output);
block.RegBlockMethod('Update',@update);
end
function allocate(b)
b.NumDworks=1;b.Dwork(1).Name='GovernorTurbineField';b.Dwork(1).Dimensions=3;
b.Dwork(1).DatatypeID=0;b.Dwork(1).Complexity='Real';b.Dwork(1).UsedAsDiscState=true;
end
function initialize(b)
C=b.DialogPrm(1).Data;b.Dwork(1).Data=[C.pm0 C.pm0 C.vf0];
end
function output(b)
x=b.Dwork(1).Data;b.OutputPort(1).Data=x([2 3]);
end
function update(b)
[~,x]=phase6_control_step(b.InputPort(1).Data(:).',b.Dwork(1).Data(:).',b.DialogPrm(1).Data);
b.Dwork(1).Data=x;
end
