function [np, nf] = test_phase4_review_gate()
T = t_case('test_phase4_review_gate');
G = phase4_review_gate();
T = T.chk(G.phase3Untouched && G.rev2Untouched, 'freeze intact');
T = T.eq(numel(G.q), 23, '23 questions answered');
T = T.chk(all([G.q.confirmed]), 'all confirmed against code behavior');
[np, nf] = T.done();
end
