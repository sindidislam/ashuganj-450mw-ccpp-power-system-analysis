function [np, nf] = test_phase4_sources()
T = t_case('test_phase4_sources');
S = phase4_sources('LF360_GAT_OUT', 'sat');
T = T.chk(isfield(S,'parkConvention') && ~isempty(S.parkConvention), 'Park convention declared');
T = T.eq(S.Xdpp_used, 0.2248, 'sat role uses 0.2248');
T = T.chk(abs(imag(S.Epp)) > 1e-6, 'Epp is complex phasor, angle carried');
U = phase4_sources('LF360_GAT_IN', 'sat');
T = T.chk(abs(U.Epp - S.Epp) > 1e-4, 'OUT/IN EMFs differ');
A = phase4_sources('LF360_GAT_OUT', 'unsat');
T = T.eq(A.Xdpp_used, 0.2608, 'unsat role uses 0.2608');
T = T.chk(isfield(S,'Edp') && isfield(S,'Eqp') && isfield(S,'Eq'), 'transient + steady sources present');
T = T.chk(S.Eq > 0, 'Eq positive field OUT-sat');
T = T.chk(magOK(S, 0.3256, 0.15, true), 'transient two-axis within 15pct OUT-sat');
T = T.chk(magOK(S, 1.7830, 0.20, false), 'steady Eq within 20pct OUT-sat');
T = T.chk(closureOK(S, 1e-9), 'closure transient+steady OUT-sat 1e-9');
T = T.chk(magOK(U, 0.3256, 0.15, true), 'transient two-axis within 15pct IN-sat');
T = T.chk(magOK(U, 1.7830, 0.20, false), 'steady Eq within 20pct IN-sat');
T = T.chk(closureOK(U, 1e-9), 'closure transient+steady IN-sat 1e-9');
T = T.chk(magOK(A, 0.3256, 0.15, true), 'transient two-axis within 15pct OUT-unsat');
T = T.chk(closureOK(A, 1e-9), 'closure transient+steady OUT-unsat 1e-9');
[np, nf] = T.done();
end

function ok = magOK(S, Xref, band, isTrans)
if isTrans
    ref = abs(S.Vt_pu + 1j*Xref*S.It_pu);
    Etwo = sqrt(S.Edp^2 + S.Eqp^2);
    ok = isscalar(Etwo) && isscalar(ref) && ref > 0 && abs(Etwo-ref)/ref < band;
else
    ref = abs(S.Vt_pu + 1j*Xref*S.It_pu);
    ok = isscalar(S.Eq) && isscalar(ref) && ref > 0 && abs(abs(S.Eq)-ref)/ref < band;
end
end

function ok = closureOK(S, tol)
Ra = 0.00089/(22^2/458);
Xq = 1.7510;
Xqp = 0.5087;
Xdp = 0.3256;
Xd = 1.7830;
dl = angle(S.Vt_pu + (Ra+1j*Xq)*S.It_pu);
w = exp(1j*(pi/2-dl));
Vd = real(S.Vt_pu*w);
Vq = imag(S.Vt_pu*w);
Id = real(S.It_pu*w);
Iq = imag(S.It_pu*w);
r1 = S.Edp - (Vd+Ra*Id-Xqp*Iq);
r2 = S.Eqp - (Vq+Ra*Iq+Xdp*Id);
r3 = S.Eq - (Vq+Ra*Iq+Xd*Id);
Vdrt = S.Edp-Ra*Id+Xqp*Iq;
Vqrt = S.Eqp-Ra*Iq-Xdp*Id;
Vdrs = -Ra*Id+Xq*Iq;
Vqrs = S.Eq-Ra*Iq-Xd*Id;
Vt_rt = (Vdrt+1j*Vqrt)/w;
Vt_rs = (Vdrs+1j*Vqrs)/w;
ok = abs(r1) <= tol && abs(r2) <= tol && abs(r3) <= tol ...
    && abs(Vt_rt-S.Vt_pu) <= tol && abs(Vt_rs-S.Vt_pu) <= tol && abs(Vdrs-Vd) <= tol;
end
