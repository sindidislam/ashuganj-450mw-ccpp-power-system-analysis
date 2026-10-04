function test_phase6_measurement()
%TEST_PHASE6_MEASUREMENT Analytical DFT/RMS and live Level-2 block checks.
addpath(fileparts(fileparts(mfilename('fullpath'))));
assert(exist('phase6_measurement_step','file')==2, ...
    'phase6:measurementMissing','The fixed-frequency measurement helper must exist.');
assert(exist('phase6_measurement_sfun','file')==2, ...
    'phase6:measurementMissing','The Level-2 measurement S-function must exist.');
dt=.001; frequency=50; n=20; channels=114;
amplitude=(1:channels).';
angle=(-137+(1:channels).'*17)*pi/180;
expected=amplitude.*exp(1i*angle);

% Every channel has a different amplitude/angle: this exposes all packing
% permutations, a conjugate/sign error, peak/RMS errors, and sensor crossover.
state=[];
for k=0:79
    t=.1234+k*dt;
    instantaneous=sqrt(2)*real(expected*exp(1i*2*pi*frequency*t));
    [packed,rmsValue,valid,state]=phase6_measurement_step(instantaneous,t,state);
    assert(isnumeric(state)&&isreal(state)&&numel(state)==2322);
    if k<n-1
        assert(valid==0 && all(packed==0) && all(rmsValue==0), ...
            'Startup values must be zero until a complete cycle is acquired.');
    else
        assert(valid==1);
        checkClose(unpack(packed),expected,3e-10,'DFT amplitude, angle, order, or reference');
        checkClose(rmsValue,amplitude,3e-10,'Waveform RMS scaling or order');
    end
end

% Reconstruct independently with the Fortescue convention [zero; positive;
% negative]. A positive ABC sequence is [1; a^2; a]. Nonzero zero sequence
% checks the measured residual, 3*I0, including its angle and units.
a=exp(1i*2*pi/3);
fortescue=[1 1 1;1 a a^2;1 a^2 a]/3;
sequenceCases=[0 0 7*exp(-.4i);31*exp(.6i) 0 0;0 23*exp(-.8i) 0];
for c=1:3
    voltageSequence=sequenceCases(:,c);
    currentSequence=voltageSequence*(.13*exp(-.27i));
    abc=[1 1 1;1 a^2 a;1 a a^2]*voltageSequence;
    iabc=[1 1 1;1 a^2 a;1 a a^2]*currentSequence;
    desired=repmat([abc;iabc],19,1);
    state=[];
    for k=0:n-1
        t=.0073+k*dt;
        [packed,~,valid,state]=phase6_measurement_step( ...
            sqrt(2)*real(desired*exp(1i*2*pi*frequency*t)),t,state);
    end
    measured=reshape(unpack(packed),6,19);
    assert(valid==1);
    checkClose(fortescue*measured(1:3,1),voltageSequence,1e-11,'Voltage sequence');
    checkClose(fortescue*measured(4:6,19),currentSequence,1e-11,'Current sequence');
    checkClose(sum(measured(4:6,19)),3*currentSequence(1),1e-11,'Residual 3I0');
end

% Waveform RMS must retain DC and harmonics while the 50 Hz DFT rejects them.
fundamental=12*exp(.43i); harmonic=4*exp(-.7i); dc=3;
state=[];
for k=0:39
    t=.0047+k*dt;
    sample=dc+sqrt(2)*real(fundamental*exp(1i*2*pi*50*t) ...
        +harmonic*exp(1i*2*pi*150*t));
    [packed,rmsValue,valid,state]=phase6_measurement_step(repmat(sample,channels,1),t,state);
end
assert(valid==1);
checkClose(unpack(packed),repmat(fundamental,channels,1),1e-11,'Harmonic/DC rejection');
checkClose(rmsValue,repmat(sqrt(12^2+4^2+3^2),channels,1),1e-11,'Full waveform RMS');

% A completed cycle of zeros must flush the sliding window (not cumulative RMS).
for k=40:59
    [packed,rmsValue,valid,state]=phase6_measurement_step(zeros(channels,1),.0047+k*dt,state);
end
assert(valid==1 && all(packed==0) && all(rmsValue==0),'A zero cycle must flush prior data.');
[packed,rmsValue,valid,~]=phase6_measurement_step(zeros(channels,1),10,[]);
assert(valid==0 && all(packed==0) && all(rmsValue==0),'Explicit reinitialization must reset validity.');

testSimulink(expected,dt);
fprintf(['PHASE6_MEASUREMENT_TESTS_PASS: 114-channel phasor packing, cosine-reference angles, ' ...
    'RMS scaling, absolute-clock synchronization, positive/negative/zero sequence, ' ...
    '3I0 residual, DC/harmonics, sliding-window reset, and Simulink compile/repeat simulation.\n']);
end

function result=unpack(packed)
assert(isreal(packed)&&numel(packed)==228);
rows=reshape(packed,12,19);
result=reshape([complex(rows(1:3,:),rows(4:6,:)); ...
    complex(rows(7:9,:),rows(10:12,:))],114,1);
end

function checkClose(actual,expected,tolerance,label)
error=max(abs(actual(:)-expected(:)));
assert(error<tolerance,'phase6:measurementMismatch','%s: maximum error %.16g.',label,error);
end

function testSimulink(expected,dt)
% The signal generator computes the waveform directly from Simulink Clock.
% No workspace signal data, model file, or persistent function state is used.
model='P6_MEASUREMENT_UNIT_HARNESS';
if bdIsLoaded(model), close_system(model,0); end
load_system('simulink'); new_system(model);
cleanup=onCleanup(@()close_system(model,0)); %#ok<NASGU>
set_param(model,'Solver','FixedStepDiscrete','FixedStep',num2str(dt), ...
    'StopTime','.060','ReturnWorkspaceOutputs','on');
add_block('simulink/Sources/Clock',[model '/Clock']);
add_block('simulink/Math Operations/Gain',[model '/Radians'], ...
    'Gain','2*pi*50');
add_block('simulink/Math Operations/Trigonometric Function',[model '/Cos'], ...
    'Operator','cos');
add_block('simulink/Math Operations/Trigonometric Function',[model '/Sin'], ...
    'Operator','sin');
add_block('simulink/Math Operations/Gain',[model '/RealWave'], ...
    'Gain',mat2str(sqrt(2)*real(expected),17),'Multiplication','Matrix(K*u)');
add_block('simulink/Math Operations/Gain',[model '/ImagWave'], ...
    'Gain',mat2str(-sqrt(2)*imag(expected),17),'Multiplication','Matrix(K*u)');
add_block('simulink/Math Operations/Sum',[model '/Waveform'],'Inputs','++');
add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function', ...
    [model '/Measurement'],'FunctionName','phase6_measurement_sfun');
names={'Phasors','RMS','Valid'};
for k=1:3
    add_block('simulink/Sinks/To Workspace',[model '/' names{k}], ...
        'VariableName',['measurement' names{k}],'SaveFormat','Structure With Time');
    add_line(model,['Measurement/' num2str(k)],[names{k} '/1']);
end
add_line(model,'Clock/1','Radians/1');
add_line(model,'Radians/1','Cos/1'); add_line(model,'Radians/1','Sin/1');
add_line(model,'Cos/1','RealWave/1'); add_line(model,'Sin/1','ImagWave/1');
add_line(model,'RealWave/1','Waveform/1'); add_line(model,'ImagWave/1','Waveform/2');
add_line(model,'Waveform/1','Measurement/1');
set_param(model,'SimulationCommand','update');
for run=1:2
    output=sim(model);
    phasors=output.get('measurementPhasors');
    rmsValue=output.get('measurementRMS');
    valid=output.get('measurementValid');
    first=find(valid.signals.values==1,1);
    assert(abs(valid.time(first)-.020)<1e-12, ...
        'The first valid output must occur at 20 ms, after one Update-to-Outputs delay.');
    assert(all(valid.signals.values(1:first-1)==0));
    assert(all(phasors.signals.values(1:first-1,:)==0,'all'));
    assert(all(rmsValue.signals.values(1:first-1,:)==0,'all'));
    for row=first:numel(valid.time)
        checkClose(unpack(phasors.signals.values(row,:)),expected,3e-10,'Simulink phasor');
        checkClose(rmsValue.signals.values(row,:),abs(expected),3e-10,'Simulink waveform RMS');
    end
    assert(all(valid.signals.values(first:end)==1));
end
fprintf('PHASE6_MEASUREMENT_SIMULINK_PASS: update compile; two 61-sample runs; first valid at 0.020 s.\n');
end
