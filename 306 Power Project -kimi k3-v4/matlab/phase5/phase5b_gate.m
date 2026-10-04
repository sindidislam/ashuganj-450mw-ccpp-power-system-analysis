function G=phase5b_gate(varargin)
% Review readiness is numerical completeness, not commissioned protection proof.
if nargin~=0, error('phase5b_gate:args','No arguments accepted.'); end
V=phase5b_validate(); R=phase5b_registry(); Ti=phase5_import(ashuganj_root());
[M,~]=phase5b_coord(R.devices,Ti);
ready=all([V.legs.pass]);
if ready, status='READY_FOR_REVIEW'; else, status='BLOCKED'; end
G=struct('ready',ready,'status',status,'validation_pass',sum([V.legs.pass]), ...
 'validation_total',numel(V.legs),'primary_pass',sum(strcmp(M.scope,'PRIMARY')&strcmp(M.verdict,'PASS')), ...
 'conditional_pass',sum(strcmp(M.verdict,'CONDITIONAL-PASS')),'fail',sum(strcmp(M.verdict,'FAIL')), ...
 'no_trip',sum(strcmp(M.verdict,'NO-TRIP')),'no_pair',sum(strcmp(M.verdict,'NO-PAIR')));
end
