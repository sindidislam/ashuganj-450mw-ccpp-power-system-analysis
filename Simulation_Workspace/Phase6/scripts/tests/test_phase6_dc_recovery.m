function test_phase6_dc_recovery()
%TEST_PHASE6_DC_RECOVERY A trip pending through DC loss must energize on return.
addpath(fileparts(fileparts(mfilename('fullpath'))));
P=init_phase6_parameters(); S=phase6_normalize_scenario(P);
LF.sm=struct('Pmec',360e6,'Vf',2,'Vt',1);
C=phase6_control_parameters(P,LF); D=phase6_dc_parameters(P);
dt=.001; request=[1 1 0 0 0 1];
U=struct('auxVoltage_pu',1,'batteryAvailable',false, ...
    'chargerAvailable',false,'tripDemand',true);
dcState=[]; breakerState=[];

% Hold a request without supply for longer than the nominal 200 ms pulse.
for k=1:500
    [dc,dcState]=phase6_dc_step(U,dcState,dt,D);
    [breaker,breakerState]=phase6_breaker_step(request,dc.dcHealthy, ...
        k*dt,breakerState,C,S);
    assert(dc.tripCoilPower_W==0 && all(breaker(1:2)==1), ...
        'A trip without DC power must not energize coils or open breakers.');
end

% Battery restoration must power the still-latched request before motion.
U.batteryAvailable=true; energy=0;
for k=1:500
    [dc,dcState]=phase6_dc_step(U,dcState,dt,D);
    [breaker,breakerState]=phase6_breaker_step(request,dc.dcHealthy, ...
        .5+k*dt,breakerState,C,S);
    energy=energy+dc.tripCoilPower_W*dt;
    if k==1
        assert(dc.tripCoilPower_W==2000, ...
            'phase6:pendingTripLost', ...
            'DC restoration must energize the trip pulse for the pending request.');
    elseif k==49
        assert(all(breaker(1:2)==1),'Trip must respect the 50 ms mechanism delay.');
    elseif k==50
        assert(all(breaker(1:2)==0),'Powered pending trip must open the breakers.');
    end
end
assert(abs(energy-400)<1e-7, ...
    'The restored trip must deliver one nominal 400 J coil pulse.');
assert(dc.tripCoilPower_W==0 && all(breaker(1:2)==0), ...
    'The pulse must finish while breaker indications stay latched open.');
fprintf('PHASE6_DC_RECOVERY_TESTS_PASS: delayed restoration powers the pending trip.\n');
end
