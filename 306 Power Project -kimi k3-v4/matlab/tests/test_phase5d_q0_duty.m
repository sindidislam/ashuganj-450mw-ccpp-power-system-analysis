function [np, nf] = test_phase5d_q0_duty()
%TEST_PHASE5D_Q0_DUTY  5 PGCB scenarios + margins.
T = t_case('test_phase5d_q0_duty');
out = fullfile(tempdir, ['ph5d_q0_' char(java.util.UUID.randomUUID())]);
mkdir(out); cleanup = onCleanup(@()rmdir(out, 's')); %#ok<NASGU>
R = phase5d_q0_breaker_duty(out, ashuganj_root());
T = T.chk(abs(R.rated_kA - 63.0) < 1e-12, 'Q0 rated 63 kA');
T = T.chk(abs(R.ip_kA - 160.65) < 1e-9, 'Q0 making 160.65 kA (2.55x)');
T = T.chk(abs(R.grid_max_allow_kA - 59.97) < 1e-9, 'max grid infeed 59.97 kA');
T = T.chk(abs(R.pgcb_total_kA - 53.03) < 1e-9, 'PGCB total 53.03 kA');
T = T.chk(abs(R.pgcb_duty_pct - 53.03/63*100) < 1e-9, 'PGCB duty 84.2%');
T = T.chk(abs(R.pgcb_margin_pct - 15.8) < 0.1, 'PGCB margin 15.8%');
D = readtable(R.csv, 'VariableNamingRule', 'preserve');
T = T.chk(height(D) == 5, '5 scenarios');
T = T.chk(abs(D.Igrid_kA(1) - 14.43) < 0.01, 'weak grid 14.43 kA');
T = T.chk(abs(D.Igrid_kA(2) - 28.87) < 0.01, 'moderate 28.87 kA');
T = T.chk(abs(D.Igrid_kA(3) - 43.30) < 0.01, 'strong 43.30 kA');
T = T.chk(all(strcmp(D.verdict, 'PASS')), 'all 5 PASS under 63 kA');
T = T.chk(isfile(R.png), 'duty curve written');
a = imfinfo(R.png); T = T.chk(a.Width > 800 && a.Height > 400, 'duty plot usable size');
try, phase5d_q0_breaker_duty(42); T = T.chk(false, 'invalid path rejected'); catch ME, T = T.chk(startsWith(ME.identifier, 'phase5d_q0'), 'invalid path rejected'); end
[np, nf] = T.done();
end
