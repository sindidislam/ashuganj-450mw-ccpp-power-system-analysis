function test_phase6_relays()
%TEST_PHASE6_RELAYS Independent primary-current fixtures; no fault flags.
% Run: addpath('Phase6/scripts/tests'); test_phase6_relays
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));
assert(exist('phase6_relay_step','file') == 2, ...
    'phase6:testMissingEngine','Measured relay engine must exist.');
R = phase6_relay_parameters();
dt = 0.001;
M = normal_currents();
[Y,~] = run_steps(M,[],dt,R,true,1000);
assert(~any(Y.trip) && ~any(Y.pickup),'Normal through-current must restrain.');
assert(all(Y.differential_A < 1e-9),'All normal zones must satisfy current balance.');
assert(isequal(size(Y.pickup),[1 7]) && isequal(size(Y.breakerRequest),[1 5]));
assert(max(abs(Y.currentSecondary_A-[0.6 0.538043478260870 0])) < 1e-10);

% Incorrect vector rotation or omitted HV zero-sequence rejection breaks this.
% LV line currents [18000,-9000,-9000], mapped independently on HV:
% [27000,-0,-27000]*(22/230)/sqrt(3), plus 600 A HV zero sequence.
M = empty_currents();
M.IgsutLV = [18000 -9000 -9000];
hv = (22/230)*27000/sqrt(3);
M.IgsutHV = [hv+600 600 -hv+600];
[Y,~] = run_steps(M,[],dt,R,true,100);
assert(~Y.pickup(5) && ~Y.trip(5),'External unbalanced transformer current must restrain.');
assert(Y.differential_A(2) < 1e-9,'HV zero-sequence must be removed.');

% Hand-computed two-slope 87T point: restraint=3000 A, spill=1000 A,
% threshold=.3*2585.6+.6*(3000-2585.6)=1024.32 A. Slope1 alone trips.
M = empty_currents();
lvA = 3500*(230/22)*sqrt(3)*2/3;
M.IgsutLV = [lvA -lvA/2 -lvA/2];
M.IgsutHV = [2500 0 -2500];
[Y,~] = run_steps(M,[],dt,R,true,50);
assert(~Y.pickup(5) && ~Y.trip(5),'Transformer high-restraint slope must restrain.');
assert(abs(Y.threshold_A(2)-1024.32) < 1e-8);

% A real generator-zone imbalance trips only 87G before backup timers.
M = normal_currents(); M.IgenInner = M.IgenInner + [10000 0 0];
[Y,state] = run_steps(M,[],dt,R,true,44);
assert(Y.pickup(4) && ~Y.trip(4),'87G must honor the 45 ms study delay.');
[Y,state] = phase6_relay_step(M,state,dt,R,true);
assert(isequal(Y.trip,logical([0 0 0 1 0 0 0])) && Y.unitTrip);
assert(isequal(Y.breakerRequest,logical([1 1 0 0 0])));
[Y,state] = phase6_relay_step(empty_currents(),state,dt,R,true);
assert(Y.trip(4),'Trip must latch after current disappears.');
[Y,~] = phase6_relay_step(empty_currents(),state,dt,R,false);
assert(~any(Y.breakerRequest) && ~Y.unitTrip,'Disabling must inhibit all requests.');
[Y,~] = phase6_relay_step(empty_currents(),[],dt,R,true);
assert(~any(Y.trip),'Empty state must reset trip latches.');

% Internal transformer imbalance; compensated phase magnitudes must operate.
M = empty_currents(); M.IgsutLV = [30000 -15000 -15000];
[Y,~] = run_steps(M,[],dt,R,true,45);
assert(isequal(Y.trip,logical([0 0 0 0 1 0 0])));
assert(isequal(Y.breakerRequest,logical([1 1 0 0 0])) && Y.unitTrip);

% A bus fault is KCL mismatch including the GAT branch, not line spill.
M = normal_currents(); M.IbusIn = M.IbusIn + [2000 0 0];
[Y,~] = run_steps(M,[],dt,R,true,35);
assert(isequal(Y.trip,logical([0 0 0 0 0 1 0])));
assert(isequal(Y.breakerRequest,logical([0 1 1 0 1])) && ~Y.unitTrip);
M = normal_currents(); M.IlineLocal = M.IlineLocal + [2000 0 0];
[Y,~] = run_steps(M,[],dt,R,true,35);
assert(isequal(Y.trip,logical([0 0 0 0 0 0 1])));
assert(isequal(Y.breakerRequest,logical([0 0 1 1 0])) && ~Y.unitTrip);

% Opposite-phase restraint levels expose incorrect cross-phase maxima.
M = empty_currents();
M.IlineLocal = [10000 1000 0]; M.IlineRemote = [10000 -1000 0];
[Y,~] = run_steps(M,[],dt,R,true,35);
assert(Y.trip(7),'Operate independently by phase; unrelated high restraint must not block.');
assert(abs(Y.differential_A(4)-2000) < 1e-9);
assert(abs(Y.restraint_A(4)-1000) < 1e-9);
M = empty_currents(); M.IlineLocal = [1000 0 0];
[~,state] = phase6_relay_step(M,[],0.020,R,true);
M.IlineLocal = [0 1000 0];
[Y,state] = phase6_relay_step(M,state,0.030,R,true);
assert(~Y.trip(7),'Differential timer must not stitch pickup from different phases.');
[Y,~] = phase6_relay_step(M,state,0.005,R,true);
assert(Y.trip(7),'Continuous pickup in one phase must satisfy its own timer.');

% IEC 60255 SI: t=0.14*TMS/(multiple^0.02-1), checked independently.
pickup = [17170.8 1380 4]; tms = [0.10 0.55 0.15];
for relay = 1:3
    for multiple = [2 5 10]
        M = empty_currents();
        if relay == 1
            M.IgenTerminal = balanced(pickup(relay)*multiple);
            M.IgenInner = M.IgenTerminal;
        elseif relay == 2
            M.IgsutHV = balanced(pickup(relay)*multiple);
        else
            M.Ineutral_A = pickup(relay)*multiple;
        end
        enabled = false(1,7); enabled(relay) = true;
        expected = 0.14*tms(relay)/(multiple^0.02-1);
        [Y,state] = run_steps(M,[],dt,R,enabled,floor(expected/dt));
        assert(~Y.trip(relay),'IEC must not trip before calculated time.');
        assert(abs(Y.operatingTime_s(relay)-expected) < 1e-10);
        [Y,~] = phase6_relay_step(M,state,dt,R,enabled);
        assert(Y.trip(relay),'IEC trip must occur within one step of calculated time.');
        assert(isequal(Y.breakerRequest,logical([1 1 0 0 0])) && Y.unitTrip);
    end
end

% Integrate changing current, not a timer compared to the latest time alone.
M = empty_currents(); M.Ineutral_A = 8;
T2 = 0.14*0.15/(2^0.02-1); T5 = 0.14*0.15/(5^0.02-1);
[~,state] = phase6_relay_step(M,[],0.4*T2,R,true);
M.Ineutral_A = 20;
[Y,state] = phase6_relay_step(M,state,0.59*T5,R,true);
assert(~Y.trip(3),'IEC accumulator must retain the correct fractional duty.');
[Y,~] = phase6_relay_step(M,state,0.02*T5,R,true);
assert(Y.trip(3),'IEC duty must integrate across current changes.');
[~,state] = phase6_relay_step(M,[],0.8*T5,R,true);
M.Ineutral_A = 4; [Y,state] = phase6_relay_step(M,state,dt,R,true);
assert(Y.timer_s(3)==0 && ~Y.pickup(3),'At pickup must reset unlatched timer.');
M.Ineutral_A = 20; [Y,~] = phase6_relay_step(M,state,0.3*T5,R,true);
assert(~Y.trip(3),'Below-pickup interruption must reset integrated duty.');

% No selected instantaneous high-set: large 87G current still waits 45 ms.
M = empty_currents(); M.IgenInner = [1e6 0 0];
[Y,~] = phase6_relay_step(M,[],dt,R,true);
assert(Y.pickup(4) && ~Y.trip(4));
[Y,~] = run_steps(M,[],dt,R,false,100);
assert(~any(Y.trip) && ~any(Y.breakerRequest));

% The public parameter API must consume explicit caller tables, not ignore them.
paths = setup_phase6_workspace();
P.protection.settings = readtable(fullfile(paths.reference,'phase5_relay_settings.csv'), ...
    'TextType','string');
P.protection.parameters = readtable(fullfile(paths.reference,'phase5_parameter_values.csv'), ...
    'TextType','string');
i = P.protection.settings.device_id == "GEN-51N";
P.protection.settings.setting_A_primary(i) = 8;
P.protection.settings.setting_A_secondary(i) = 0.4;
R2 = phase6_relay_parameters(P);
M = empty_currents(); M.Ineutral_A = 6;
[Y,~] = phase6_relay_step(M,[],dt,R2,true);
assert(~Y.pickup(3),'Caller setting table must control the relay pickup.');
fprintf('PHASE6_RELAY_TESTS_PASS: balance, vector compensation, four zones, IEC timing, reset, gating.\n');
end

function M = empty_currents()
fields = {'IgenInner','IgenTerminal','IgsutLV','IgsutHV','IbusIn', ...
    'IbusOut','IgatHV','IlineLocal','IlineRemote'};
M = struct();
for k=1:numel(fields), M.(fields{k}) = complex(zeros(1,3)); end
M.Ineutral_A = 0;
end

function M = normal_currents()
M = empty_currents();
M.IgenInner = balanced(9000); M.IgenTerminal = M.IgenInner;
M.IgsutLV = M.IgenTerminal;
% YNd1 LV lags HV by 30 deg for positive phase sequence.
M.IgsutHV = balanced(9000*22/230)*exp(1i*pi/6);
M.IbusIn = M.IgsutHV;
M.IgatHV = balanced(40)*exp(1i*pi/6);
M.IbusOut = M.IbusIn-M.IgatHV;
M.IlineLocal = M.IbusOut; M.IlineRemote = M.IlineLocal;
end

function I = balanced(amplitude)
I = amplitude*[1 exp(-1i*2*pi/3) exp(1i*2*pi/3)];
end

function [Y,state] = run_steps(M,state,dt,R,enabled,n)
for k=1:n, [Y,state] = phase6_relay_step(M,state,dt,R,enabled); end
end
