function [np,nf]=test_phase5b_gate()
% Review readiness and engineering outcomes are distinct gate results.
T=t_case('test_phase5b_gate');G=phase5b_gate();
fields={'ready','status','validation_pass','validation_total','primary_pass','conditional_pass','fail','no_trip','no_pair'};
T=T.chk(all(isfield(G,fields)),'gate reports review readiness and separate engineering outcome counts');
T=T.chk(islogical(G.ready)&&G.ready&&strcmp(G.status,'READY_FOR_REVIEW'),'passing implementation checks produce review readiness');
V=phase5b_validate();
T=T.chk(G.validation_pass==sum([V.legs.pass])&&G.validation_total==numel(V.legs),'gate validation count matches the live engineering validator');
R=phase5b_registry();Ti=phase5_import(ashuganj_root());M=phase5b_coord(R.devices,Ti);
want=[sum(strcmp(M.scope,'PRIMARY')&strcmp(M.verdict,'PASS')),sum(strcmp(M.verdict,'CONDITIONAL-PASS')), ...
 sum(strcmp(M.verdict,'FAIL')),sum(strcmp(M.verdict,'NO-TRIP')),sum(strcmp(M.verdict,'NO-PAIR'))];
got=[G.primary_pass,G.conditional_pass,G.fail,G.no_trip,G.no_pair];
T=T.chk(isequal(got,want),'gate counts come from current physical-current coordination results');
T=T.chk(sum(got)==height(M)&&G.conditional_pass>0&&G.no_pair>0,'outcomes cover every pair while retaining conditional and absent pairs');
T=T.chk(G.primary_pass<height(M),'READY_FOR_REVIEW does not claim every engineering pair passed');
try,phase5b_gate(struct());T=T.chk(false,'obsolete table overrides rejected');catch ME,T=T.chk(strcmp(ME.identifier,'phase5b_gate:args'),'obsolete table overrides rejected');end
[np,nf]=T.done();
end
