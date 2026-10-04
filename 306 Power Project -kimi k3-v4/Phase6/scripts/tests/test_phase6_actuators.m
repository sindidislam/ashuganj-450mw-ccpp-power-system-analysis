function test_phase6_actuators()
P=init_phase6_parameters();S=phase6_normalize_scenario(P);
LF.sm=struct('Pmec',360e6,'Vf',2,'Vt',1);C=phase6_control_parameters(P,LF);
x=[];
for k=1:1000,[y,x]=phase6_control_step([1 1 0],x,C);end
assert(max(abs(y-[C.pm0 C.vf0]))<1e-12,'Steady initialization drift.');
[y1,~]=phase6_control_step([1.01 .98 0],x,C);
assert(y1(1)<C.pm0 && y1(2)>C.vf0,'Wrong governor or AVR response direction.');
for k=1:3000,[y,x]=phase6_control_step([1 1 1],x,C);end
assert(y(1)<.03 && abs(y(2))<1e-9,'Unit trip does not decay source inputs.');
x=[];
for k=1:100,[y,x]=phase6_breaker_step([1 1 0 0 0 1],false,k*.001,x,C,S);end
assert(all(y(1:4)==1)&&y(6)==0,'DC loss must inhibit actuation.');
for k=1:49,[y,x]=phase6_breaker_step([1 1 0 0 0 1],true,k*.001,x,C,S);end
assert(y(1)==1&&y(6)==1,'Mechanism delay or unit trip wrong.');
[y,x]=phase6_breaker_step([1 1 0 0 0 1],true,.05,x,C,S);
assert(all(y(1:2)==0),'Healthy trip failed.');
[y,~]=phase6_breaker_step(zeros(1,6),false,.1,x,C,S);
assert(all(y(1:2)==0),'Trip must latch.');
S.breakerFailed(1)=true;x=[];
for k=1:60,[y,x]=phase6_breaker_step([1 1 0 0 0 0],true,k*.001,x,C,S);end
assert(y(1)==1&&y(2)==0,'Breaker failure scenario must retain failed pole command.');
fprintf('PHASE6_ACTUATOR_TESTS_PASS\n');
end
