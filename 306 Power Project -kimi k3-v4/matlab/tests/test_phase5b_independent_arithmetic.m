function [np,nf]=test_phase5b_independent_arithmetic()
T=t_case('test_phase5b_independent_arithmetic');
try
 A=phase5b_independent_arithmetic();
 T=T.chk(height(A)>=25,'all required engineering arithmetic and relay time checks present');
 T=T.chk(all(strcmp(A.verdict,'PASS')),'independent arithmetic matches runtime');
 T=T.chk(any(strcmp(A.parameter,'GEN_R1_pu')),'exact resistance conversion audited');
 T=T.chk(sum(contains(string(A.parameter),'SI_TIME'))==12,'four SI relays at three fault multiples independently checked');
 M=table({'GEN-51'}, {'REMOTE-GRID-boundary'},2*17170.8/15000,NaN, ...
  0.14*0.10/(2^0.02-1),NaN,15000,NaN,'VariableNames', ...
  {'downstream','upstream','I_down_A','I_up_A','t_down_s','t_up_s','ct_down','ct_up'});
 B=phase5b_independent_arithmetic(M);
 T=T.chk(all(strcmp(B.verdict,'PASS')),'finite matrix-side time checked with explicit absent upstream side');
catch ME
 T=T.chk(false,['independent arithmetic audit: ' ME.message]);
end
[np,nf]=T.done();
end
