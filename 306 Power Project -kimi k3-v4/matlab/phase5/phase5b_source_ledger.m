function L=phase5b_source_ledger(varargin)
% Compatibility view of the authoritative numerical provenance ledger.
if nargin~=0, error('phase5b_source_ledger:args','No arguments accepted.'); end
[~,A]=phase5b_parameters();
L=struct('source_id',{},'claim',{},'value',{},'locator',{},'class',{});
for i=1:height(A)
 L(i)=struct('source_id',A.parameter{i},'claim',A.basis{i}, ...
  'value',sprintf('%.15g %s',A.value(i),A.unit{i}), ...
  'locator',[A.source_file{i} ':' A.source_section{i}],'class',A.status{i});
end
end
