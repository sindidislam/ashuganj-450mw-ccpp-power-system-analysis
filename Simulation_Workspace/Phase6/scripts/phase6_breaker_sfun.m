function phase6_breaker_sfun(block)
block.NumDialogPrms=2;block.DialogPrmsTunable={'Nontunable','Nontunable'};
block.NumInputPorts=2;block.NumOutputPorts=1;
block.SetPreCompInpPortInfoToDynamic;block.SetPreCompOutPortInfoToDynamic;
block.InputPort(1).Dimensions=6;block.InputPort(2).Dimensions=1;
block.InputPort(1).DirectFeedthrough=false;block.InputPort(2).DirectFeedthrough=false;
block.OutputPort(1).Dimensions=6;
block.SampleTimes=[block.DialogPrm(1).Data.Ts 0];
block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('PostPropagationSetup',@allocate);
block.RegBlockMethod('InitializeConditions',@initialize);
block.RegBlockMethod('Outputs',@output);
block.RegBlockMethod('Update',@update);
end
function allocate(b)
b.NumDworks=1;b.Dwork(1).Name='TripMechanism';b.Dwork(1).Dimensions=11;
b.Dwork(1).DatatypeID=0;b.Dwork(1).Complexity='Real';b.Dwork(1).UsedAsDiscState=true;
end
function initialize(b)
S=b.DialogPrm(2).Data;b.Dwork(1).Data=[zeros(1,5) 1 1 1 1 double(S.GAT_in) 0];
end
function output(b)
x=b.Dwork(1).Data;b.OutputPort(1).Data=x(6:11);
end
function update(b)
[~,x]=phase6_breaker_step(b.InputPort(1).Data(:).',b.InputPort(2).Data,b.CurrentTime, ...
    b.Dwork(1).Data(:).',b.DialogPrm(1).Data,b.DialogPrm(2).Data);
b.Dwork(1).Data=x;
end
