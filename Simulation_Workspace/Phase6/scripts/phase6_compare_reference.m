function [comparison,settings]=phase6_compare_reference(out,info)
% Measured operating quantities versus the frozen primary reference.
% Grid source V/P/Q are reconstructed across the selected series impedance;
% the grid-terminal Q is a different measurement location.
P=init_phase6_parameters();ref=P.reference.primary;S=info.scenario;
q=out.phase6_summary;t=q.Time;
finish=t(end);if S.faultEnabled,finish=min(finish,S.faultStart_s-.001);end
ix=t>=max(.04,finish-.1)&t<=finish;assert(any(ix));m=mean(q.Data(ix,:),1);
ph=out.phase6_phasors;ip=ph.Time>=max(.04,finish-.1)&ph.Time<=finish;
a=mean(ph.Data(ip,:),1);a=reshape(a,12,19).';
V=complex(a(:,1:3),a(:,4:6));I=complex(a(:,7:9),a(:,10:12));
E=info.network.profile;Vs=V(11,:)-(E.Rgrid+1i*E.Xgrid)*I(11,:);
Ssource=sum(Vs.*conj(I(11,:)))/1e6;
genA=angle(V(1,1)/Vs(1))*180/pi;auxA=angle(V(10,1)/Vs(1))*180/pi;busA=angle(V(5,1)/Vs(1))*180/pi;
B=P.reference.buses;B=B(string(B.Case_ID)=="LF360_GAT_OUT",:);
getAngle=@(name)B.Angle_deg(string(B.Bus_Name)==name);
rows={ ...
 'Generator active power','MW',ref.Gen_P_MW,m(1),1,'Measured generator terminal'; ...
 'Generator reactive power','MVAr',ref.Gen_Q_MVAr,m(2),.5,'Measured generator terminal'; ...
 'Generator voltage','kV',ref.Gen_V_kV,m(3),.1,'Line-to-line RMS'; ...
 'Generator current','kA',ref.Gen_S_MVA/(sqrt(3)*ref.Gen_V_kV),m(4),.05,'Reference current derived from frozen P/Q/V'; ...
 '230 kV bus voltage','kV',ref.V230_1_kV,m(9),.25,'Line-to-line RMS'; ...
 'Auxiliary bus voltage','kV',ref.V6_6_kV,m(21),.02,'Line-to-line RMS'; ...
 'Remote grid terminal voltage','kV',ref.V_REMOTE_kV,sqrt(mean(abs(V(11,:)).^2))*sqrt(3)/1000,.25,'Before grid impedance'; ...
 'Grid source active power','MW',ref.Export_P_MW,real(Ssource),1,'Derived from measured V/I and selected grid impedance'; ...
 'Grid source reactive power','MVAr',ref.Export_Q_MVAr,imag(Ssource),.5,'Derived at ideal source; excludes series grid impedance consumption'; ...
 'Grid current','kA',hypot(ref.Export_P_MW,ref.Export_Q_MVAr)/(sqrt(3)*230),m(10),.01,'Reference derived at 230 kV source'; ...
 'Generator angle','deg',getAngle('B22'),genA,.2,'Relative to reconstructed grid source phase A'; ...
 '230 kV bus angle','deg',getAngle('B230_1'),busA,.2,'Relative to reconstructed grid source phase A'; ...
 'Auxiliary angle','deg',getAngle('B6_6'),auxA,.2,'Relative to reconstructed grid source phase A'; ...
 'Frequency','Hz',50,m(5),.02,'Rotor electrical frequency'};
comparison=cell2table(rows,'VariableNames',{'Quantity','Unit','Reference','Measured','Absolute_tolerance','Basis'});
comparison.Absolute_error=abs(comparison.Measured-comparison.Reference);
comparison.Relative_error= comparison.Absolute_error./max(abs(comparison.Reference),1e-9);
comparison.Status=repmat("PASS",height(comparison),1);
comparison.Status(comparison.Absolute_error>comparison.Absolute_tolerance)="MISMATCH";
invalid=~isfinite(comparison.Measured)|~isfinite(comparison.Reference) ...
    |~isfinite(comparison.Absolute_tolerance)|~isfinite(comparison.Absolute_error);
comparison.Status(invalid)="INVALID_NONFINITE";
if ~strcmpi(S.networkProfile,'PHASE3_BASELINE')||S.dispatch_MW~=360||S.GAT_in
 comparison.Status(~invalid)="QUALIFIED_DIFFERENT_OPERATING_POINT_OR_PROFILE";
end
comparison.Window_start_s=repmat(min(t(ix)),height(comparison),1);
comparison.Window_end_s=repmat(max(t(ix)),height(comparison),1);
R=info.controls.relayParameters;frozen=phase6_relay_parameters(P);
names=["GEN51","GSUT51","GEN51N","87G","87T","87B","87L"];
settings=table(names.',R.pickup_A.',frozen.pickup_A.',R.ctRatio.',frozen.ctRatio.', ...
 R.pickupSecondary_A.',(R.pickup_A./R.ctRatio).', ...
 'VariableNames',{'Relay','Active_pickup_A','Frozen_pickup_A','Active_CT_ratio','Frozen_CT_ratio','Active_secondary_A','Expected_secondary_A'});
settings.Active_TMS=[R.tms nan(1,4)].';settings.Frozen_TMS=[frozen.tms nan(1,4)].';
settings.Active_delay_s=[nan(1,3) R.delay_s].';settings.Frozen_delay_s=[nan(1,3) frozen.delay_s].';
settings.Enabled=logical(S.relayMask(:)&S.protectionEnabled);
settings.Status=repmat("MATCHES_FROZEN_STUDY",7,1);
for k=1:7
 if settings.Active_pickup_A(k)~=settings.Frozen_pickup_A(k)||settings.Active_CT_ratio(k)~=settings.Frozen_CT_ratio(k) ...
  ||~isequaln(settings.Active_TMS(k),settings.Frozen_TMS(k))||~isequaln(settings.Active_delay_s(k),settings.Frozen_delay_s(k))
  settings.Status(k)="USER_EDITED_STUDY_SETTING";
 end
end
assert(all(abs(settings.Active_secondary_A-settings.Expected_secondary_A)<1e-9),'Phase6:CTConsistency','Active primary/secondary settings disagree.');
end
