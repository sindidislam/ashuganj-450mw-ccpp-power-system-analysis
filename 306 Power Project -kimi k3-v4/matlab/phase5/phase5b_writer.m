function W=phase5b_writer(outDir,tables,meta)
% Write the live tables first. Final manifest is created only after plots/docs.
if nargin~=3||~isstruct(tables), error('phase5b_writer:args','outDir, tables, meta required'); end
names={'registry','settings','faultInputs','relayCurrents','coordMatrix','coordMargins','duty','sensitivity','validation','effectiveness'};
files={'phase5_device_registry.csv','phase5_relay_settings.csv','phase5_fault_inputs.csv','phase5_relay_currents.csv', ...
 'phase5_coordination_matrix.csv','phase5_coordination_margins.csv','phase5_breaker_duty.csv','phase5_sensitivity.csv','phase5_validation.csv','phase5b_effectiveness.csv'};
if ~isfolder(outDir), mkdir(outDir); end
rc=struct();
for i=1:numel(names)
 assert(isfield(tables,names{i})&&istable(tables.(names{i}))&&~isempty(tables.(names{i})), ...
  'phase5b_writer:schema','Missing nonempty table %s',names{i});
 T=tables.(names{i});
 % Required inputs are checked before rendering structural inapplicability.
 switch names{i}
  case 'settings', required={'setting_A_primary','setting_A_secondary','ct_ratio'};
  case 'faultInputs', required={'I_primary_A','I_primary_kA','m'};
  case 'relayCurrents', required={'I_primary_A','I_secondary_A','CT_ratio'};
  case 'sensitivity', required={'value','scenario_value'};
  case 'validation', required={'pass','residual'};
  otherwise, required={};
 end
 for f=required, assert(all(isfinite(T.(f{1}))),'phase5b_writer:numerical','Required numeric field %s.%s is not finite',names{i},f{1}); end
 if ismember(names{i},{'coordMatrix','coordMargins'})
  validate_coordination(T,names{i});
 end
 if strcmp(names{i},'duty')
  k=~strcmp(T.verdict,'NOTE');
  for f={'I_sym_kA','rating_kA','duty_ratio'}
   assert(all(isfinite(T.(f{1})(k))),'phase5b_writer:numerical','Required duty field %s is not finite',f{1});
  end
 end
 if strcmp(names{i},'effectiveness')
  for f={'primary_time_s','backup_time_s'}
   assert(all(~isnan(T.(f{1})))&&all(T.(f{1})>=0),'phase5b_writer:numerical','Required effectiveness time missing');
  end
 end
 if ismember('provenance',T.Properties.VariableNames)
  assert(all(strlength(strtrim(string(T.provenance)))>0),'phase5b_writer:provenance','Empty provenance');
 end
 if ismember('scope',T.Properties.VariableNames)
  assert(all(ismember(string(T.scope),["PRIMARY","CONDITIONAL","SENSITIVITY","REFERENCE-ONLY"])), ...
   'phase5b_writer:scope','Invalid output scope');
 end
 T=phase5b_export_applicability(T);
 writetable(T,fullfile(outDir,files{i}));
 rc.(matlab.lang.makeValidName(files{i}))=height(T);
end
W=struct('outDir',outDir,'files',{files},'rowCounts',rc,'testCounts',meta.testCounts);
end

function validate_coordination(T,name)
% A missing result is structural only for a genuinely absent pair side.
% The margins table has no current/time columns; validate its own schema.
required={'verdict','margin_s'};
if strcmp(name,'coordMatrix')
 required=[required,{'I_down_A','I_up_A','ct_down','ct_up','t_down_s','t_up_s'}];
end
assert(all(ismember(required,T.Properties.VariableNames)), ...
 'phase5b_writer:schema','Incomplete %s coordination schema',name);
for field=required(2:end)
 assert(isnumeric(T.(field{1}))&&isreal(T.(field{1}))&&size(T.(field{1}),2)==1, ...
  'phase5b_writer:numerical','%s.%s must be a real numerical column',name,field{1});
end
evaluated=ismember(string(T.verdict),["PASS","CONDITIONAL-PASS","FAIL"]);
assert(all(evaluated|ismember(string(T.verdict),["NO-TRIP","NO-PAIR"])), ...
 'phase5b_writer:numerical','Unknown %s coordination verdict',name);
assert(all(isfinite(T.margin_s(evaluated)))&&all(isnan(T.margin_s(~evaluated))), ...
 'phase5b_writer:numerical','%s requires finite evaluated margins and no margin for unresolved pairs/non-operation',name);
if ismember('pair_evaluable',T.Properties.VariableNames)
 assert(all(T.pair_evaluable==evaluated),'phase5b_writer:numerical', ...
  '%s pair_evaluable conflicts with coordination verdict',name);
end
if strcmp(name,'coordMargins'), return; end
for side={'down','up'}
 current=T.(['I_' side{1} '_A']); ct=T.(['ct_' side{1}]); seconds=T.(['t_' side{1} '_s']);
 absent=isnan(current)&isnan(ct)&isnan(seconds);
 present=~absent;
 assert(all(~absent(evaluated)), 'phase5b_writer:numerical', ...
  'Evaluated coordination row lacks its %s side',side{1});
 assert(all(isfinite(current(present))&current(present)>=0)& ...
  all(isfinite(ct(present))&ct(present)>0)& ...
  all(~isnan(seconds(present))&seconds(present)>=0), ...
  'phase5b_writer:numerical','Modeled %s side requires current, CT and finite/non-operation time',side{1});
 assert(all(isfinite(seconds(evaluated))), 'phase5b_writer:numerical', ...
  'Evaluated coordination row requires a finite %s operating time',side{1});
end
noTrip=strcmp(T.verdict,'NO-TRIP');
assert(all(T.t_down_s(noTrip)==Inf|T.t_up_s(noTrip)==Inf), ...
 'phase5b_writer:numerical','NO-TRIP requires explicit positive infinite operating time');
end
