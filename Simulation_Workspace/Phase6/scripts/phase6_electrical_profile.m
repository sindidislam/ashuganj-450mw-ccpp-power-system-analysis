function E = phase6_electrical_profile(P,S)
%PHASE6_ELECTRICAL_PROFILE Keep frozen LF and revised screening networks distinct.
R=phase6_relay_parameters(P); Q=R.phase5;
E.transformers=P.transformers;
% Excluded LV demand is already represented in the canonical 14 MW total.
% Do not invent a 400 V feeder or pass its unresolved NaN demand to SPS.
included=[P.loads.Model_included];
assert(all(isfinite(included)),'Phase6:LoadSelection','Load inclusion flags must be finite.');
E.loads=P.loads(logical(included));
E.excludedLoads=P.loads(~logical(included));
for k=1:numel(E.loads)
    d=E.loads(k);
    assert(all(isfinite([d.P_MW d.Q_MVAr d.Vnom_V])) && d.P_MW>=0 && d.Q_MVAr>=0, ...
        'Phase6:LoadData','Included load %s requires finite nonnegative P/Q and voltage.',d.Name);
    assert(d.Vnom_V==6600 && any(strcmp(d.Bus,{'B6_6','B6_6_WI1','B6_6_WI2'})), ...
        'Phase6:LoadBoundary','Load %s requires its own voltage conversion/topology; cannot attach it to the 6.6 kV equivalent.',d.Name);
end
E.auxLoadConfiguration='Y (floating)';
E.auxLoadNote=['Three-wire auxiliary load equivalent preserves canonical balanced P/Q; ' ...
    'floating star is a Phase6 zero-sequence assumption. Excluded 400 V demand is already inside the 14 MW MV equivalent; no LV voltage claim.'];
L=P.lines(strcmp({P.lines.Name},'L_LINE'));
E.name=upper(char(S.networkProfile));
switch E.name
    case 'PHASE3_BASELINE'
        E.Rgrid=P.grid.R_ohm; E.Xgrid=P.grid.X_ohm;
        E.R0grid=E.Rgrid; E.X0grid=1.5*E.Xgrid;
        % Two explicit circuits replace the frozen lumped dual-circuit PI.
        E.Rline=2*L.R_ohm; E.Xline=2*L.X_ohm; E.Cline=L.C_F/2;
        % Phase3 had no zero-sequence data. These are Phase6 study assumptions.
        E.R0line=Q.SOUTH_R0_total_ohm; E.X0line=Q.SOUTH_X0_total_ohm;
        E.C0line=Q.SOUTH_B0_total_uS*1e-6/(2*pi*P.f_Hz);
        E.note='Frozen Phase3 positive sequence; separate assumed zero sequence. Rgrid=0 limits EMT DC-offset interpretation.';
    case 'PHASE5_STUDY'
        E.Rgrid=Q.GRID_Rth_ohm; E.Xgrid=Q.GRID_Xth_ohm;
        E.R0grid=Q.GRID_R0_ohm; E.X0grid=Q.GRID_X0_ohm;
        E.Rline=Q.SOUTH_R1_total_ohm; E.Xline=Q.SOUTH_X1_total_ohm;
        E.Cline=Q.SOUTH_B1_total_uS*1e-6/(2*pi*P.f_Hz);
        E.R0line=Q.SOUTH_R0_total_ohm; E.X0line=Q.SOUTH_X0_total_ohm;
        E.C0line=Q.SOUTH_B0_total_uS*1e-6/(2*pi*P.f_Hz);
        k=find(strcmp({E.transformers.Name},'GSUT'));
        E.transformers(k).R1_pu=Q.GSUT_R1_pu/2;
        E.transformers(k).R2_pu=Q.GSUT_R1_pu/2;
        E.transformers(k).L1_pu=Q.GSUT_X1_pu/2;
        E.transformers(k).L2_pu=Q.GSUT_X1_pu/2;
        E.note='Revised Phase5 study GSUT, two-circuit line and finite-R grid; frozen Phase5 fault CSV retains older Phase4 backbone.';
    otherwise
        error('Phase6:Profile','Unknown electrical profile: %s',E.name);
end
E.length_km=L.Length_km;
E.Rneutral=Q.NER_effective_HV_ohm;
E.generatorZ0=[Q.GEN_R0_pu Q.GEN_X0_pu];
E.auxNeutral_ohm=(6900/sqrt(3))/5;
E.breakerRon_ohm=1e-4; E.breakerSnubber_ohm=1e6;
E.faultSnubber_ohm=1e9;
E.faultSnubberNote=['Numerical parallel resistance for discrete SPS fault-switch/inductor topology; ' ...
    'not a plant insulation value. At 230kV nominal a grounded three-phase bank draws 52.9W total.'];
E.machineDiscreteSolver='Trapezoidal robust';
E.machineDiscreteSolverNote=['R2024a supported robust machine discretization; ' ...
    'non-iterative trapezoidal diverged in the normal 50us test. Physical machine data are unchanged.'];
E.groundMagnetization_pu=[1e7 1e7];
end
