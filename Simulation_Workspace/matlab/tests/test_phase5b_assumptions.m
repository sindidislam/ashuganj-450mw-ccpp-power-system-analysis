function [np,nf]=test_phase5b_assumptions()
% Cross-layer assumptions have finite numbers, provenance and fenced scope.
T=t_case('test_phase5b_assumptions'); [P,A]=phase5b_parameters();R=phase5b_registry();
T=T.chk(all(isfinite(A.value))&&all(strlength(string(A.source_file))>0)&&all(strlength(string(A.derivation))>0),'every adopted parameter has a finite value, source and derivation');
T=T.chk(abs(P.GSUT_rated_A-1292.8)<1e-9&&abs(P.GSUT_maximum_load_anchor_A-458e6/(sqrt(3)*230e3))<1e-9,'GSUT nameplate and maximum through-load bases are separate');
T=T.chk(P.GSUT_51_pickup_A==1380&&P.GSUT_CT==1600&&P.GSUT_documentary_CT==1500,'GSUT central study and conflicting documentary CT remain explicit');
T=T.chk(P.Q0_interrupting_kA==50&&P.Q0_continuous_A==2000&&P.Q0_making_kA==125&&P.Q0_shortcircuit_s==3,'conditional transformer-bay breaker ratings are numerically closed');
k=strcmp(A.parameter,'Q0_interrupting_kA');
T=T.chk(sum(k)==1&&contains(string(A.status(k)),'CONDITIONAL')&&all(string(A.actual_installed_value_verified(k))=="NO"),'Q0 adopted rating does not imply verified physical mapping');
T=T.chk(P.GEN_51N_CT==20&&P.GEN_51N_pickup_A==4&&P.GEN_51N_secondary_A==.2,'primary neutral study uses its own 20/1 CT and 4 A pickup');
T=T.chk(abs(P.GEN_87G_pickup_A-2403.8)<1e-9&&abs(P.GSUT_87T_pickup_A-387.84)<1e-9&&P.BUS_87B_pickup_A==320&&P.LINE_87L_pickup_A==320,'differential study thresholds use their stated current bases');
T=T.chk(P.GEN_87G_highset_enabled==0,'generator differential high-set stays off');
Ti=phase5_import(ashuganj_root()); S=phase5b_sensitivity_v2(Ti,R.devices,R);
T=T.chk(all(strcmp(S.scope,'SENSITIVITY'))&&all(isfinite(S.value))&&all(isfinite(S.scenario_value)),'all executed sensitivity metrics stay finite and outside primary scope');
five=strcmp(S.family,'GEN_NEUTRAL_PICKUP')&S.scenario_value==5;
T=T.chk(any(five)&&all(strcmp(S.scope(five),'SENSITIVITY')),'5 A neutral case is executed only as sensitivity');
g=R.devices(strcmp({R.devices.device_id},'GEN-51N'));
T=T.chk(g.pickup_A==4&&g.ct_ratio==20&&strcmp(g.assumption_class,'PRIMARY'),'sensitivity execution preserves primary neutral registry settings');
T=T.chk(abs(P.GRID_Ssc_GVA-17.93)<.02&&P.GRID_Z0_Z1_ratio==3,'grid central values retain explicit secondary-data and zero-sequence screening assumptions');
[np,nf]=T.done();
end
