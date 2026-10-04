function [np,nf]=test_phase5b_ledger()
T=t_case('test_phase5b_ledger'); L=phase5b_source_ledger();
T=T.chk(all(isfield(L,{'source_id','claim','value','locator','class'})),'source ledger compatibility schema');
ids={L.source_id};
k=strcmp(ids,'GSUT_CT');
T=T.chk(sum(k)==1&&strcmp(L(k).class,'ENGINEERING_ASSUMPTION'),'GSUT CT provenance reflects study assumption');
k=strcmp(ids,'CTI_s');
T=T.chk(sum(k)==1&&contains(L(k).class,'ENGINEERING'),'CTI is a study criterion not installed parameter');
T=T.chk(~any(strcmp({L.class},'SOURCE-BACKED')),'specific provenance replaces generic source-backed status');
T=T.chk(~phase5b_ct_scope('GEN-51N'),'legacy phase CT sensitivity cannot select dedicated neutral CT');
[np,nf]=T.done();
end
