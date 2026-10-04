function [np,nf]=test_phase5b_writer()
% A small complete fixture tests CSV fidelity and required-value rejection.
T=t_case('test_phase5b_writer'); [tables,meta]=fixture();
out=fullfile(tempdir,['phase5b_writer_' char(java.util.UUID.randomUUID())]);
mkdir(out); cleanup=onCleanup(@()rmdir(out,'s')); %#ok<NASGU>
W=phase5b_writer(out,tables,meta);
expected={'phase5_device_registry.csv','phase5_relay_settings.csv','phase5_fault_inputs.csv', ...
 'phase5_relay_currents.csv','phase5_coordination_matrix.csv','phase5_coordination_margins.csv', ...
 'phase5_breaker_duty.csv','phase5_sensitivity.csv','phase5_validation.csv','phase5b_effectiveness.csv'};
T=T.chk(isequal(sort(W.files),sort(expected))&&numel(dir(fullfile(out,'*.csv')))==10,'writer emits exactly ten live table CSVs');
T=T.chk(~isfile(fullfile(out,'manifest.json'))&&~isfile(fullfile(out,'sha256.txt')),'manifest and hashes remain deferred until all outputs are finalized');
S=readtable(fullfile(out,'phase5_relay_settings.csv'),'Delimiter',',');
T=T.chk(abs(S.setting_A_primary-4)<1e-12&&abs(S.setting_A_secondary-.2)<1e-12&&S.ct_ratio==20,'numeric neutral setting survives CSV round trip');
D=readtable(fullfile(out,'phase5_breaker_duty.csv'),'Delimiter',',');
T=T.chk(D.I_sym_kA==6.9&&D.rating_kA==50&&abs(D.duty_ratio-.138)<1e-12&&strcmp(D.scope,'CONDITIONAL'),'conditional physical duty and ratio survive CSV round trip');
E=readtable(fullfile(out,'phase5b_effectiveness.csv'),'Delimiter',',');
T=T.chk(isinf(E.primary_time_s)&&E.backup_time_s==1.75,'Inf no-trip behavior is retained without inventing finite timing');
regText=fileread(fullfile(out,'phase5_device_registry.csv'));
T=T.chk(contains(regText,'INSTALLED_VALUE_NOT_VERIFIED')&&contains(regText,'NOT_APPLICABLE_TO_ROW')&&~contains(regText,'NaN'),'structural inapplicability and unverified installed CT are explicit text');
T=T.chk(W.rowCounts.phase5b_effectiveness_csv==height(tables.effectiveness)&&isequal(W.testCounts,meta.testCounts),'writer metadata matches actual rows and supplied test counts');
opts=detectImportOptions(fullfile(out,'phase5_coordination_matrix.csv'),'Delimiter',',');
opts=setvartype(opts,opts.VariableNames,'string');
M=readtable(fullfile(out,'phase5_coordination_matrix.csv'),opts);
G=readtable(fullfile(out,'phase5_coordination_margins.csv'),'Delimiter',',','TextType','string');
T=T.chk(height(M)==8 && height(G)==8 && string(M.t_down_s(4))=="Inf", ...
 'complete coordination schemas preserve explicit no-trip infinity');
T=T.chk(string(M.t_up_s(6))=="NOT_APPLICABLE_TO_ROW" && string(M.t_down_s(7))=="NOT_APPLICABLE_TO_ROW", ...
 'absent upstream and absent residual pair sides remain structural');
% Evaluable verdicts cannot hide missing currents, CTs, times or margins.
% Rows 1/2/3 are PASS/CONDITIONAL-PASS/FAIL; each carries a real pair.
for row=1:3
 for field={'I_down_A','I_up_A','ct_down','ct_up','t_down_s','t_up_s','margin_s'}
  for missing=[NaN Inf]
   bad=tables;bad.coordMatrix.(field{1})(row)=missing;
   label=sprintf('reject %s %s=%g',tables.coordMatrix.verdict{row},field{1},missing);
   T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical',label);
  end
 end
 for missing=[NaN Inf]
  bad=tables;bad.coordMargins.margin_s(row)=missing;
  T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical', ...
   sprintf('reject %s margin-table missing/nonfinite margin',tables.coordMargins.verdict{row}));
 end
end
% Non-operation is a resolved +Inf time, including a neutral-only row whose
% nonexistent upstream residual element remains completely inapplicable.
for row=[4 5]
 for field={'I_down_A','ct_down','t_down_s'}
  bad=tables;bad.coordMatrix.(field{1})(row)=NaN;
  T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical', ...
   sprintf('NO-TRIP rejects missing active-side %s row %d',field{1},row));
 end
end
bad=tables;bad.coordMatrix.t_down_s(5)=1;
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical','NO-TRIP requires an explicit infinite operating time');
bad=tables;bad.coordMatrix.t_down_s(5)=-Inf;
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical','negative infinity is not a no-trip time');
bad=tables;bad.coordMatrix.t_down_s(6)=NaN;
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical','NO-PAIR cannot hide a missing modeled downstream time');
bad=tables;bad.coordMatrix.I_up_A(6)=0;
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical','an absent side must not contain a partial numerical result');
for name={'coordMatrix','coordMargins'}
 bad=tables;bad.(name{1}).margin_s(4)=0;
 T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical',[name{1} ' cannot invent a finite NO-TRIP margin']);
 bad=tables;bad.(name{1}).pair_evaluable(1)=false;
 T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical',[name{1} ' evaluability agrees with evaluated verdict']);
end
% All of these columns affect the final engineering conclusions. Missing
% values must fail before an exporter can disguise them as inapplicable.
cases={'settings','setting_A_primary';'settings','setting_A_secondary';'settings','ct_ratio'; ...
 'faultInputs','I_primary_A';'relayCurrents','I_secondary_A';'sensitivity','value'; ...
 'validation','residual';'duty','I_sym_kA';'duty','rating_kA';'duty','duty_ratio'; ...
 'effectiveness','primary_time_s';'effectiveness','backup_time_s'};
for k=1:size(cases,1)
 bad=tables;bad.(cases{k,1}).(cases{k,2})(1)=NaN;
 T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:numerical',['reject missing ' cases{k,1} '.' cases{k,2}]);
end
bad=tables;bad.faultInputs.provenance{1}='  ';
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:provenance','empty provenance cannot be exported');
bad=tables;bad.duty.scope{1}='INSTALLED-VERIFIED';
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:scope','invalid scope cannot turn a study into installed proof');
bad=rmfield(tables,'sensitivity');
T=expect_error(T,@()phase5b_writer(out,bad,meta),'phase5b_writer:schema','missing required table rejected');
% The informational NOTE is the sole duty exception to required branch data.
note=tables;note.duty.verdict={'NOTE'};note.duty.scope={'REFERENCE-ONLY'};
note.duty.I_sym_kA=NaN;note.duty.rating_kA=NaN;note.duty.duty_ratio=NaN;
try,phase5b_writer(out,note,meta);T=T.chk(true,'non-duty NOTE fields can be marked inapplicable');catch ME,T=T.chk(false,['NOTE export ' ME.identifier]);end
[np,nf]=T.done();
end
function T=expect_error(T,f,id,label)
try,f();T=T.chk(false,label);catch ME,T=T.chk(strcmp(ME.identifier,id),[label ' (' ME.identifier ')']);end
end
function [s,meta]=fixture()
prov={'ENGINEERING_ASSUMPTION:controlled numerical fixture'};primary={'PRIMARY'};
s.registry=table({'GEN-51N'},20,NaN,4,NaN,prov,primary, ...
 'VariableNames',{'device_id','ct_ratio','physical_CT_ratio','pickup_A','operate_proxy_s','provenance','scope'});
s.settings=table({'GEN-51N'},4,.2,20,prov,primary, ...
 'VariableNames',{'device_id','setting_A_primary','setting_A_secondary','ct_ratio','provenance','scope'});
s.faultInputs=table(7.272,.007272,.5,prov,primary,'VariableNames',{'I_primary_A','I_primary_kA','m','provenance','scope'});
s.relayCurrents=table(7.272,.3636,20,prov,primary,'VariableNames',{'I_primary_A','I_secondary_A','CT_ratio','provenance','scope'});
s.coordMatrix=coord_fixture();
m=s.coordMatrix;
s.coordMargins=table(strcat(m.downstream,'>',m.upstream),m.fault_location,m.fault_type,m.caseID, ...
 m.margin_s,m.verdict,m.reason,m.provenance,m.scope,m.pair_evaluable, ...
 'VariableNames',{'pair','fault_location','fault_type','caseID','margin_s','verdict','reason','provenance','scope','pair_evaluable'});
s.duty=table({'Q0'},6.9,50,.138,{'CONDITIONAL-PASS'},prov,{'CONDITIONAL'}, ...
 'VariableNames',{'breaker_ref','I_sym_kA','rating_kA','duty_ratio','verdict','provenance','scope'});
s.sensitivity=table(5,2.2,prov,{'SENSITIVITY'},'VariableNames',{'scenario_value','value','provenance','scope'});
s.validation=table(true,0,prov,primary,'VariableNames',{'pass','residual','provenance','scope'});
s.effectiveness=table(Inf,1.75,{'NO-TRIP'},prov,{'CONDITIONAL'},'VariableNames',{'primary_time_s','backup_time_s','detection','provenance','scope'});
meta=struct('testCounts',struct('passed',7,'failed',0));
end

function M=coord_fixture()
% Actual Phase-5b matrix schema, with hand-selected representative row types.
down={'GEN-51';'GSUT-HV-51';'GEN-51';'GEN-51';'GEN-51N';'GIS-Q0-51';'GSUT-HV-51';'GEN-51N'};
up={'GSUT-HV-51';'GIS-Q0-51';'GSUT-HV-51';'GSUT-HV-51';'GSUT-HV-51';'REMOTE-GRID-boundary';'GIS-Q0-51';'GSUT-HV-51'};
loc={'F1';'F1';'F2';'F1';'F3';'F3';'F3';'F1'};
typ={'LLL';'LL';'LLL';'LG';'LG';'LLL';'LG';'LG'};
verdict={'PASS';'CONDITIONAL-PASS';'FAIL';'NO-TRIP';'NO-TRIP';'NO-PAIR';'NO-PAIR';'NO-PAIR'};
scope={'PRIMARY';'CONDITIONAL';'PRIMARY';'PRIMARY';'PRIMARY';'CONDITIONAL';'CONDITIONAL';'PRIMARY'};
M=table(down,up,loc,typ,repmat({'SYN'},8,1),[60;50;60;.00727;35;50;35;.00727], ...
 [4;4;4;.5;0;4;NaN;.36],[4;4;4;.4;NaN;NaN;NaN;NaN], ...
 [1;1.5;1;Inf;Inf;2;NaN;1.75],[1.5;2;1.2;Inf;NaN;NaN;NaN;NaN], ...
 [15000;1600;15000;15000;20;1600;NaN;20],[1600;1600;1600;1600;NaN;NaN;NaN;NaN], ...
 [.5;.5;.2;NaN;NaN;NaN;NaN;NaN],verdict,repmat({'Controlled pair fixture'},8,1),scope, ...
 repmat({'ENGINEERING_ASSUMPTION:controlled numerical fixture'},8,1),[true(3,1);false(5,1)], ...
 'VariableNames',{'downstream','upstream','fault_location','fault_type','caseID','I_fault_kA', ...
 'I_down_A','I_up_A','t_down_s','t_up_s','ct_down','ct_up','margin_s','verdict','reason','scope','provenance','pair_evaluable'});
end
