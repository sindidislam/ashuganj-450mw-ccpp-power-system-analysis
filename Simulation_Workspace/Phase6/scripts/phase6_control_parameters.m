function C=phase6_control_parameters(P,LF)
%PHASE6_CONTROL_PARAMETERS Generic controls, initialized at the solved point.
A=P.assumptions;
C.Ts=P.TsControl;
C.droop=A.gov_droop_pu.value;
C.governorTime_s=A.gov_response_s.value;
C.turbineTime_s=A.gov_turbine_time_s.value;
C.avrGain=A.exc_avr_gain.value;
C.avrTime_s=A.exc_avr_time_s.value;
C.fieldMin_pu=A.exc_command_min_pu.value;
C.fieldMax_pu=A.exc_command_max_pu.value;
C.powerMin_pu=A.gov_min_power_MW.value*1e6/P.machine.Sn_VA;
C.powerMax_pu=450e6/P.machine.Sn_VA;
C.pm0=LF.sm(1).Pmec/P.machine.Sn_VA;
C.vf0=LF.sm(1).Vf;
C.vref=abs(LF.sm(1).Vt);
C.breakerDelay_s=.05*ones(1,5);
C.source='Phase2 canonical academic governor/AVR assumptions; LF initial state; Phase6 assumed 50 ms breaker mechanism';
% The machine already has field electrical dynamics. The older abstract
% Phase2 field-response lag is deliberately not applied a second time.
end
