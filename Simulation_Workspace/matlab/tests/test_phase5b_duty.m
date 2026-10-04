function [np, nf] = test_phase5b_duty()
%TEST_PHASE5B_DUTY Conditional breaker screening on physical branch bases.
T = t_case('test_phase5b_duty');
Ti = phase5_import(ashuganj_root());
D = phase5b_duty(Ti);
old = {'location','breaker_ref','fault_type','caseID','I_sym_kA', ...
    'I_peak_kA','rating_kA','basis','verdict','note', ...
    'equipment_rating_kA','equipment_basis'};
T = T.chk(isequal(D.Properties.VariableNames(1:12), old), 'original columns retained first');
Q = D(strcmp(D.breaker_ref,'Q0') & ~strcmp(D.verdict,'NOTE'),:);
G = D(strcmp(D.breaker_ref,'52G'),:);
T = T.chk(height(Q)==40 && height(G)==40 && height(D)==81, '40 Q0, 40 52G, one reference row');
T = T.chk(all(Q.rating_kA==50), 'Q0 executes the conditional 50 kA interrupting comparison');
T = T.chk(all(strcmp(Q.verdict,'CONDITIONAL-PASS')), 'physical Q0 branch duties are conditional passes');
q = Q(strcmp(Q.location,'F1') & strcmp(Q.fault_type,'LLL') & strcmp(Q.caseID,'LF360_GAT_OUT'),:);
T = T.chk(abs(q.I_sym_kA-6.89701475447833)<1e-6, 'F1 Q0 current is referred from 22 kV to its 230 kV physical side');
g = G(strcmp(G.location,'F3') & strcmp(G.fault_type,'LLL') & strcmp(G.caseID,'LF360_GAT_OUT'),:);
T = T.chk(g.I_sym_kA>33 && g.I_sym_kA<34, 'F3 52G current is referred from 230 kV to its 22 kV physical side');
gll = G(strcmp(G.location,'F1') & strcmp(G.fault_type,'LL') & strcmp(G.caseID,'LF360_GAT_OUT'),:);
T = T.chk(gll.I_sym_kA>51.7 && gll.I_sym_kA<51.9, 'LL breaker duty uses worst B/C pole, not the 8.32 kA Ia');
T = T.chk(all(G.rating_kA==100), '52G retains the documentary 100 kA comparison');
required = {'duty_ratio','scope','current_basis','source_voltage_kV','breaker_voltage_kV', ...
    'continuous_rating_A','making_rating_kA','short_time_duration_s'};
has = all(ismember(required,D.Properties.VariableNames));
T = T.chk(has, 'duty includes ratios, scope and physical rating metadata');
if has
    T = T.chk(all(abs(Q.duty_ratio-Q.I_sym_kA/50)<1e-12), 'Q0 duty ratio equals physical branch current / 50 kA');
    T = T.chk(all(strcmp(Q.scope,'CONDITIONAL')), 'Q0 physical mapping remains conditional');
    T = T.chk(all(Q.continuous_rating_A==2000 & Q.making_rating_kA==125 & Q.short_time_duration_s==3), 'Q0 conditional 2000 A, 125 kA making, 3 s ratings retained');
    T = T.chk(all(contains(Q.current_basis,'Ikpp')) && all(contains(Q.note,'Ib')), 'Ikpp screening distinguished from breaking-time Ib');
    j = find(strcmp(Ti.fault_location,'F3') & strcmp(Ti.fault_type,'LLL') & strcmp(Ti.caseID,'LF360_GAT_OUT'),1);
    Ts = Ti(j,:); Bs = phase5b_branch_phasors(Ts);
    hit = strcmp(Bs.leg,'GSUT_HV');
    Bs{hit,{'Ia_A','Ib_A','Ic_A','Ibranch_faulted_A'}} = 55000*ones(1,4);
    Ds = phase5b_duty(Ts,[],Bs);
    qs = Ds(strcmp(Ds.breaker_ref,'Q0') & ~strcmp(Ds.verdict,'NOTE'),:);
    T = T.chk(strcmp(qs.verdict{1},'FAIL') && abs(qs.duty_ratio-1.1)<1e-12 && contains(qs.note{1},'exceeds'), '55 kA conditional branch honestly fails the 50 kA rating');
end
N = D(strcmp(D.verdict,'NOTE'),:);
T = T.chk(height(N)==1 && contains(N.note{1},'I_fault_system_reference'), 'system fault reference is retained separately');
try
    phase5b_duty(table()); T = T.chk(false,'empty input rejected');
catch ME
    T = T.chk(startsWith(ME.identifier,'phase5b_duty'),'empty input raises scoped error');
end
[np,nf] = T.done();
end
