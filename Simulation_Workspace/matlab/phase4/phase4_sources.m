function S = phase4_sources(caseID, XdRole)
%PHASE4_SOURCES  Stage-source builder: subtransient/transient/steady sources per case.
%
%   S = PHASE4_SOURCES(caseID, XdRole) derives the generator internal sources
%   from the frozen per-case prefault state via PHASE4_PREFAULT(caseID).
%
%   XdRole selects the subtransient reactance (no averaging, no third value):
%     'sat'   -> Xdpp_used = 0.2248 (primary)
%     'unsat' -> Xdpp_used = 0.2608 (sensitivity)
%   Any other role errors with identifier starting 'phase4'.
%
%   Machine-base pu (Snom 458 MVA, Vnom 22 kV):
%     |Vt| = V_B22_kV/22; th = Angle_deg*pi/180
%     Vt = |Vt|*(cos(th)+j*sin(th)) (complex, angle retained)
%     St = (Pgen_MW+j*Qgen_MVAr)/458 (generator sign, leaving machine)
%     It = conj(St/Vt) (complex, leaving machine)
%     Ra_pu = 0.00089/(22^2/458); Zpp = Ra_pu+j*Xdpp_used
%     Epp = Vt+Zpp*It (complex phasor)
%
%   Park convention (declared in S.parkConvention, printed once, used
%   identically everywhere): q-axis leads d-axis by 90 deg; rotor angle
%   delta = arg(Vt+(Ra_pu+j*Xq)*It) with Xq = 1.7510; rotation
%   w = exp(j*(pi/2-delta)); Vd+jVq = Vt*w; Id+jIq = It*w with It
%   leaving-machine (generator sign); Vd = real(Vd+jVq), Vq = imag(...),
%   Id = real(Id+jIq), Iq = imag(...). Stator equations (generator sign,
%   leaving positive):
%     Edp = Vd+Ra_pu*Id-Xqp*Iq with Xqp = 0.5087;
%     Eqp = Vq+Ra_pu*Iq+Xdp*Id with Xdp = 0.3256;
%     steady d-axis identity Ed_steady = Vd+Ra_pu*Id-Xq*Iq = 0, i.e.
%     Vd = -Ra_pu*Id+Xq*Iq (holds by the delta definition);
%     Eq = Vq+Ra_pu*Iq+Xd*Id with Xd = 1.7830 constant field.
%   Closure (self-checked to 1e-9, errors starting 'phase4' on breach):
%   Vd_rec_t = Edp-Ra*Id+Xqp*Iq, Vq_rec_t = Eqp-Ra*Iq-Xdp*Id,
%   Vt_rec_t = (Vd_rec_t+j*Vq_rec_t)/w equals Vt; Vd_rec_s = -Ra*Id+Xq*Iq,
%   Vq_rec_s = Eq-Ra*Iq-Xd*Id, Vt_rec_s = (Vd_rec_s+j*Vq_rec_s)/w equals Vt.
%   Magnitude gates (recomputed from the same inputs, never hard-coded):
%   |E'_twoaxis| = sqrt(Edp^2+Eqp^2) vs |Vt+j*Xdp*It| within 15%;
%   |Eq| vs |Vt+j*Xd*It| within 20%; breach errors starting 'phase4'.
%   No magnitude-only path, no shared OUT/IN EMF (per-case prefault inside),
%   no sat/unsat averaging, Xdpp only from the XdRole switch (never X2/X0).
%
%   Output fields (exact): Vt_pu, It_pu, Epp, Edp, Eqp, Eq, delta_rad,
%   parkConvention, Xdpp_used.

if nargin < 2
    error('phase4_sources:badRole', 'XdRole required: ''sat'' (0.2248) or ''unsat'' (0.2608).');
end
RgSrc = phase4_registry();  % C8 canonical machine values (no local literals; defined before first use)
if isstring(XdRole) || ischar(XdRole)
    role = char(string(XdRole));
else
    error('phase4_sources:badRole', 'XdRole must be ''sat'' or ''unsat''.');
end
if strcmp(role, 'sat')
    Xdpp_used = RgSrc.machine.Xdpp_sat.value;
elseif strcmp(role, 'unsat')
    Xdpp_used = RgSrc.machine.Xdpp.value;
else
    error('phase4_sources:badRole', 'Unknown XdRole ''%s'': use ''sat'' or ''unsat''.', role);
end

F = phase4_prefault(caseID);

Snom = RgSrc.machine.Snom_MVA.value;
Vnom = RgSrc.machine.Vnom_kV.value;
Ra_ohm = RgSrc.machine.Ra_ohm.value;
Xd = RgSrc.machine.Xd.value;
Xdp = RgSrc.machine.Xdp.value;
Xq = RgSrc.machine.Xq.value;
Xqp = RgSrc.machine.Xqp.value;

Vmag = F.Vt_B22_kV / Vnom;
th = F.Ang_B22_deg * pi / 180;
Vt_pu = Vmag * (cos(th) + 1j * sin(th));
St_pu = (F.Pgen_MW + 1j * F.Qgen_MVAr) / Snom;
It_pu = conj(St_pu / Vt_pu);

Ra_pu = Ra_ohm / (Vnom^2 / Snom);
Zpp = Ra_pu + 1j * Xdpp_used;
Epp = Vt_pu + Zpp * It_pu;

delta_rad = angle(Vt_pu + (Ra_pu + 1j * Xq) * It_pu);

w = exp(1j * (pi/2 - delta_rad));
Vdq = Vt_pu * w;
Idq = It_pu * w;
Vd = real(Vdq);
Vq = imag(Vdq);
Id = real(Idq);
Iq = imag(Idq);

Edp = Vd + Ra_pu * Id - Xqp * Iq;
Eqp = Vq + Ra_pu * Iq + Xdp * Id;
Eq = Vq + Ra_pu * Iq + Xd * Id;

% ---- initialization closure (algebraic identity, tol 1e-9) ----
Vd_rec_t = Edp - Ra_pu * Id + Xqp * Iq;
Vq_rec_t = Eqp - Ra_pu * Iq - Xdp * Id;
Vt_rec_t = (Vd_rec_t + 1j * Vq_rec_t) / w;
Vd_rec_s = -Ra_pu * Id + Xq * Iq;
Vq_rec_s = Eq - Ra_pu * Iq - Xd * Id;
Vt_rec_s = (Vd_rec_s + 1j * Vq_rec_s) / w;
res_t = abs(Vt_rec_t - Vt_pu);
res_s = abs(Vt_rec_s - Vt_pu);
res_d = abs(Vd_rec_s - Vd);
if ~(res_t <= 1e-9)
    error('phase4_sources:closure', 'Transient closure breach: |Vt_rec-Vt|=%g (tol 1e-9).', res_t);
end
if ~((res_s <= 1e-9) && (res_d <= 1e-9))
    error('phase4_sources:closure', 'Steady closure breach: |Vt_rec-Vt|=%g d-res=%g (tol 1e-9).', res_s, res_d);
end

% ---- magnitude plausibility gates (recomputed, never hard-coded) ----
ref_trans = abs(Vt_pu + 1j * Xdp * It_pu);
Etwo = sqrt(Edp^2 + Eqp^2);
rel_t = abs(Etwo - ref_trans) / ref_trans;
ref_steady = abs(Vt_pu + 1j * Xd * It_pu);
rel_s = abs(abs(Eq) - ref_steady) / ref_steady;
fprintf('phase4_sources %s %s: |Etwo|=%.6f ref=%.6f rel=%.4f; |Eq|=%.6f ref=%.6f rel=%.4f; res_t=%.3g res_s=%.3g\n', ...
    char(string(caseID)), role, Etwo, ref_trans, rel_t, abs(Eq), ref_steady, rel_s, res_t, res_s);
if ~(rel_t < 0.15)
    error('phase4_sources:magnitude', 'Transient magnitude breach: rel=%.4f (band 15%%).', rel_t);
end
if ~(rel_s < 0.20)
    error('phase4_sources:magnitude', 'Steady magnitude breach: rel=%.4f (band 20%%).', rel_s);
end

parkConvention = ['q-leads-d by 90deg; delta=arg(Vt+(Ra+jXq)It), Xq=1.7510; ' ...
    'Vd+jVq=Vt*exp(j*(pi/2-delta)), Id+jIq=It*exp(j*(pi/2-delta)) leaving-machine; ' ...
    'Edp=Vd+Ra*Id-Xqp*Iq, Eqp=Vq+Ra*Iq+Xdp*Id, Eq=Vq+Ra*Iq+Xd*Id constant-field'];

persistent announced;
if isempty(announced)
    fprintf('%s\n', parkConvention);
    announced = true;
end

S = struct('Vt_pu', Vt_pu, 'It_pu', It_pu, 'Epp', Epp, ...
    'Edp', Edp, 'Eqp', Eqp, 'Eq', Eq, ...
    'delta_rad', delta_rad, 'parkConvention', parkConvention, ...
    'Xdpp_used', Xdpp_used);
end
