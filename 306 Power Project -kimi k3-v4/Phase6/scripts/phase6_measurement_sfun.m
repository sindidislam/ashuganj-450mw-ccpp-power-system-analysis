function phase6_measurement_sfun(block)
%PHASE6_MEASUREMENT_SFUN Synchronized fixed-50 Hz DFT and waveform RMS.
% No dialog parameters. One double, real, 114-vector input contains sensor
% groups [Va Vb Vc Ia Ib Ic] in this fixed sensor order:
% genInner, genTerminal, gsutLV, gsutHV, busIn, busOut, gatHV, lineLocal,
% lineRemote, aux, grid, neutral, faultGEN, faultLV, faultHV, faultGIS,
% faultLINE, faultGRID, faultAUX.
% Output 1: double, real, 228-vector; each sensor contributes
% [Re(Vabc) Im(Vabc) Re(Iabc) Im(Iabc)] of complex RMS, cosine-reference DFT.
% Output 2: double, real, 114-vector; full-waveform sliding RMS in input order.
% Output 3: double validity flag, 0 until a complete 20-sample cycle is stored.
% Sample time is 1 ms; nominal frequency is 50 Hz. Numeric Dwork resets every
% simulation. Outputs expose the previous Update result (1 ms delay). With
% the first input at t=0, the first valid output is t=0.020 s and contains
% samples t=0 through 0.019 s. Phases reference the absolute simulation clock.

block.NumDialogPrms=0;
block.NumInputPorts=1;
block.NumOutputPorts=3;
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;
block.InputPort(1).Dimensions=114;
block.InputPort(1).DatatypeID=0;
block.InputPort(1).Complexity='Real';
block.InputPort(1).SamplingMode='Sample';
block.InputPort(1).DirectFeedthrough=false;
dimensions=[228 114 1];
for k=1:3
    block.OutputPort(k).Dimensions=dimensions(k);
    block.OutputPort(k).DatatypeID=0;
    block.OutputPort(k).Complexity='Real';
    block.OutputPort(k).SamplingMode='Sample';
end
block.SampleTimes=[.001 0];
block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('PostPropagationSetup',@allocate);
block.RegBlockMethod('InitializeConditions',@initialize);
block.RegBlockMethod('Outputs',@output);
block.RegBlockMethod('Update',@update);
end

function allocate(block)
block.NumDworks=4;
names={'MeasurementHistory','PackedPhasors','WaveformRMS','MeasurementValid'};
dimensions=[2322 228 114 1];
for k=1:4
    block.Dwork(k).Name=names{k};
    block.Dwork(k).Dimensions=dimensions(k);
    block.Dwork(k).DatatypeID=0;
    block.Dwork(k).Complexity='Real';
    block.Dwork(k).UsedAsDiscState=true;
end
end

function initialize(block)
for k=1:4
    block.Dwork(k).Data=zeros(block.Dwork(k).Dimensions,1);
end
end

function output(block)
block.OutputPort(1).Data=block.Dwork(2).Data;
block.OutputPort(2).Data=block.Dwork(3).Data;
block.OutputPort(3).Data=block.Dwork(4).Data;
end

function update(block)
[phasors,rmsValue,valid,state]=phase6_measurement_step( ...
    block.InputPort(1).Data,block.CurrentTime,block.Dwork(1).Data);
block.Dwork(1).Data=state;
block.Dwork(2).Data=phasors;
block.Dwork(3).Data=rmsValue;
block.Dwork(4).Data=valid;
end
