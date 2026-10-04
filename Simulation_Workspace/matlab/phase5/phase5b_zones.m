function Z = phase5b_zones(varargin)
%PHASE5B_ZONES Functional engineering trip matrix for Phase 5.
% Original inventory/zone fields are retained for struct2table export.
% The actions are ENGINEERING_ASSUMPTION, with sourced equipment identities
% kept separate from unverified station trip wiring and commissioning data.
if nargin~=0
    error('phase5b_zones:args','phase5b_zones takes no arguments.');
end
P=phase5b_parameters();
rows={ ...
 'G','GEN-87G','87G','PRIMARY','F1','Generator differential';
 'G','GEN-51-SIEMENS-BL','50/51-DT','BACKUP','','Reported 3 s baseline is a separate study comparator; manufacturer setting page absent';
 'G','GEN-51','51','BACKUP','','Selected generator inverse-time backup';
 'G','GEN-51N','51N','BACKUP','','Confirmed severe neutral overcurrent with dedicated study CT';
 'G','GEN-46','46','BACKUP','','Negative-sequence capability is sourced; trip stage not selected in this matrix';
 'G','GEN-59N','59N','PRESENCE','','Residual-voltage function retained; no unselected alarm-to-trip escalation';
 'G','GEN-64G','64G','PRESENCE','','Confirmed severe stator earth fault; 20 Hz arrangement sourced, defaults remain study values';
 'G','GEN-64R','64R','PRESENCE','','Rotor earth function inventory; alarm/severity stages require setting verification';
 'G','GEN-40','40','PRESENCE','','Loss-of-excitation function inventory';
 'G','GEN-32R','32R','PRESENCE','','Reverse-power function inventory';
 'G','GEN-21','21','PRESENCE','','Generator backup-distance function inventory';
 'G','GEN-78','78','PRESENCE','','Out-of-step function inventory';
 'G','GEN-59','59','PRESENCE','','Overvoltage function inventory';
 'G','GEN-81','81','PRESENCE','','Frequency function inventory';
 'G','GEN-24','24','PRESENCE','','Overflux function inventory';
 'G','GEN-50-27','50/27','PRESENCE','','Inadvertent-energization function inventory';
 'G','GEN-52G','52G','BREAKER','','10BAC10 generator breaker, 22 kV, 12.4 kA continuous and 100 kA sym r.m.s. documentary ratings';
 'T','GSUT-87T','87T','PRIMARY','F2','Transformer differential, 7UT6331 function presence sourced';
 'T','GSUT-HV-51','51','BACKUP','','Selected transformer HV inverse-time backup';
 'T','GSUT-87N','87N','PRESENCE','','Transformer restricted-earth-fault trip stage';
 'T','GSUT-63','63','PRESENCE','','Transformer mechanical severe trip stage; alarm stages excluded';
 'T','GSUT-49','49','PRESENCE','','Transformer thermal function inventory; no unselected alarm-to-trip escalation';
 'T','GSUT-86','86','PRESENCE','','Original 86/GSUT inventory retained; 86T is the study functional equivalent';
 'T','UAT-HV-51','51','PRESENCE','','UAT 1000/1 CT/function inventory; separate feeder scheme outside selected trip matrix';
 'T','GAT-HVN-51N','51N','PRESENCE','','GAT 250/1 neutral CT/function inventory; separate feeder scheme outside selected trip matrix';
 'B','GIS-87B','87B','PRIMARY','F3','Affected bus-section differential trip';
 'B','GIS-50BF','50BF','PRESENCE','','230 kV breaker failure with current-persistence supervision';
 'B','GIS-6MD66','6MD66','CONTROL-NOTE','','Bay control is not an independent fault detector';
 'B','GIS-Q0-51','51','BACKUP','','Selected GIS backup operates the qualified GSUT transformer-bay Q0';
 'L','LINE-7SD','7SD5221','PRIMARY','F4','Line differential local/remote ends; actual breaker identities require verification';
 'L','LINE-21-note','21','BACKUP','','Selected numerical distance backup; physical line-end breaker identity and actual relay implementation require verification'};
base=struct('zone','','device_id','','ansi','','role','','primary_for_fault','', ...
    'trip_52G','NO_AUTOMATIC_TRIP_ASSIGNED','trip_Q0','NO_AUTOMATIC_TRIP_ASSIGNED', ...
    'lockout_86','NONE','bf_path','NOT_APPLICABLE','note','', ...
    'status','ENGINEERING_ASSUMPTION','subtype','FUNCTIONAL_ENGINEERING_ASSUMPTION', ...
    'action_condition','FUNCTION_PRESENCE_ONLY','trip_other_breakers','NONE', ...
    'trip_excitation',false,'trip_turbine',false,'bf_timer_s',0, ...
    'source','docs/PHASE5_SOURCE_AUDIT.md; GENERATION AND TRANSFORMERS SYSTEM.pdf pp.2-3', ...
    'actual_trip_wiring_verified',false);
Z=repmat(base,size(rows,1),1);
for k=1:size(rows,1)
    Z(k).zone=rows{k,1}; Z(k).device_id=rows{k,2}; Z(k).ansi=rows{k,3};
    Z(k).role=rows{k,4}; Z(k).primary_for_fault=rows{k,5}; Z(k).note=rows{k,6};
    id=Z(k).device_id;
    if any(strcmp(id,{'GEN-87G','GEN-64G','GEN-51N'}))
        Z(k)=unit_trip(Z(k),'86G_FUNCTIONAL_EQUIVALENT',P);
        Z(k).action_condition='CONFIRMED_SEVERE_GENERATOR_FAULT_TRIP_STAGE';
    elseif any(strcmp(id,{'GEN-51','GEN-51-SIEMENS-BL'}))
        Z(k)=unit_trip(Z(k),'86G_FUNCTIONAL_EQUIVALENT',P);
        Z(k).action_condition='CONFIRMED_TIME_GRADED_BACKUP_OPERATION_REQUIRING_UNIT_ISOLATION';
    elseif any(strcmp(id,{'GSUT-87T','GSUT-HV-51','GSUT-87N','GSUT-63','GSUT-86'}))
        Z(k)=unit_trip(Z(k),'86T_FUNCTIONAL_EQUIVALENT_OF_86_GSUT',P);
        Z(k).action_condition='CONFIRMED_TRANSFORMER_TRIP_STAGE_OR_LOCKOUT_ASSERTION';
        Z(k).bf_timer_s=P.BF_230kV_s;
        Z(k).bf_path='IF_GSUT_Q0_FAILS: PERSISTENT_CURRENT_AFTER_TRIP_AND_0.15s -> ADJACENT_AFFECTED_SECTION_BREAKERS_EQUIVALENT_SET; 52G_BACKUP_REMOVES_GENERATOR_INFEED';
    elseif strcmp(id,'GEN-52G')
        Z(k).action_condition='BREAKER_TRIP_FROM_SELECTED_PROTECTION; BF_ON_PERSISTENT_CURRENT_AFTER_TRIP';
        Z(k).bf_timer_s=P.BF_22kV_s;
        Z(k).bf_path='IF_52G_FAILS: PERSISTENT_CURRENT_AFTER_TRIP_AND_0.12s -> TRIP_52-1(Q0)_GSUT_10ADA10/D07; REMOVE_UAT_BACKFEED; EXCITATION_AND_TURBINE_SHUTDOWN';
    elseif strcmp(id,'GIS-87B')
        Z(k).action_condition='CONFIRMED_87B_OPERATION_FOR_IDENTIFIED_AFFECTED_SECTION';
        Z(k).trip_52G='BACKUP_ONLY_IF_REQUIRED_TO_REMOVE_GENERATOR_INFEED';
        Z(k).trip_Q0='TRIP_IF_CONNECTED_TO_AFFECTED_SECTION: 52-1(Q0) GSUT 10ADA10/D07';
        Z(k).lockout_86='86B_AFFECTED_SECTION_FUNCTIONAL_EQUIVALENT';
        Z(k).trip_other_breakers='ALL_BREAKERS_CONNECTED_TO_AFFECTED_SECTION_EQUIVALENT_SET';
        Z(k).bf_path='START_50BF_FOR_COMMANDED_BREAKERS; FAILED_BREAKER -> ADJACENT_SOURCE_REMOVAL_EQUIVALENT_SET';
        Z(k).bf_timer_s=P.BF_230kV_s;
        Z(k).note=[Z(k).note '; section membership and additional breaker identities require verification; healthy section is not automatically tripped'];
    elseif strcmp(id,'GIS-50BF')
        Z(k).action_condition='PERSISTENT_CURRENT_AFTER_TRIP_AND_BF_TIMER_EXPIRED';
        Z(k).trip_52G='TRIP_IF_REQUIRED_TO_REMOVE_INFEED_THROUGH_FAILED_GSUT_Q0';
        Z(k).trip_Q0='TRIP_IF_ADJACENT_SOURCE_TO_FAILED_BREAKER: 52-1(Q0) GSUT 10ADA10/D07';
        Z(k).lockout_86='86B_AFFECTED_SECTION_FUNCTIONAL_EQUIVALENT';
        Z(k).trip_other_breakers='ADJACENT_AFFECTED_SECTION_BREAKERS_AND_REQUIRED_REMOTE_ENDS_EQUIVALENT_SET';
        Z(k).bf_path='TRIP_REQUEST + PERSISTENT_CURRENT + 0.15s -> ADJACENT_SOURCE_REMOVAL; ACTUAL_BI_AND_CONTACT_LOGIC_REQUIRE_VERIFICATION';
        Z(k).bf_timer_s=P.BF_230kV_s;
    elseif strcmp(id,'GIS-Q0-51')
        Z(k).action_condition='CONFIRMED_TIME_GRADED_GIS_BACKUP_OPERATION';
        Z(k).trip_52G='NO_DIRECT_TRIP';
        Z(k).trip_Q0='TRIP 52-1(Q0) GSUT BAY 10ADA10/D07';
        Z(k).bf_path='START_230kV_50BF; PERSISTENT_CURRENT_AFTER_TRIP_AND_0.15s -> ADJACENT_AFFECTED_SECTION_EQUIVALENT_SET';
        Z(k).bf_timer_s=P.BF_230kV_s;
    elseif strcmp(id,'LINE-7SD')
        Z(k).action_condition='CONFIRMED_LINE_DIFFERENTIAL_OPERATION_WITH_VALID_CHANNEL';
        Z(k).trip_52G='NO_DIRECT_TRIP'; Z(k).trip_Q0='NO_DIRECT_TRANSFORMER_BAY_TRIP';
        Z(k).trip_other_breakers='LOCAL_AND_REMOTE_LINE_END_BREAKERS_EQUIVALENT_SET';
        Z(k).bf_path='START_LOCAL_230kV_50BF; FAILED_LINE_END -> ADJACENT_AFFECTED_SECTION_AND_REMOTE_SOURCE_REMOVAL';
        Z(k).bf_timer_s=P.BF_230kV_s;
    elseif strcmp(id,'LINE-21-note')
        Z(k).action_condition='CONFIRMED_ZONE_OPERATION_AFTER_SELECTED_ZONE_TIMER_WITH_DIRECTION_SUPERVISION';
        Z(k).trip_52G='NO_DIRECT_TRIP'; Z(k).trip_Q0='NO_DIRECT_TRANSFORMER_BAY_TRIP';
        Z(k).trip_other_breakers='LOCAL_LINE_END_BREAKER_EQUIVALENT_SET; REMOTE_END_ONLY_IF_VERIFIED_INTERTRIP';
        Z(k).bf_path='START_LOCAL_230kV_50BF; FAILED_LINE_END -> ADJACENT_AFFECTED_SECTION_SOURCE_REMOVAL';
        Z(k).bf_timer_s=P.BF_230kV_s;
        Z(k).note=[Z(k).note sprintf('; Zone 1 %.4g+j%.4g ohm / %.2f s; Zone 2 %.4g+j%.4g ohm / %.2f s; Zone 3 %.4g+j%.4g ohm / %.2f s; reaches/timers are numerical backup proxies, not simulated impedance-estimator operation', ...
            P.DIST21_zone1_R_ohm,P.DIST21_zone1_X_ohm,P.DIST21_zone1_time_s, ...
            P.DIST21_zone2_R_ohm,P.DIST21_zone2_X_ohm,P.DIST21_zone2_time_s, ...
            P.DIST21_zone3_R_ohm,P.DIST21_zone3_X_ohm,P.DIST21_zone3_time_s)];
    end
end
end

function s=unit_trip(s,lockout,P)
s.trip_52G='TRIP 52G (10BAC10)';
s.trip_Q0='TRIP 52-1(Q0) GSUT BAY 10ADA10/D07';
s.lockout_86=lockout;
s.trip_other_breakers='52A-1 UAT INCOMER IF_REQUIRED_TO_REMOVE_BACKFEED';
s.trip_excitation=true; s.trip_turbine=true;
s.bf_timer_s=P.BF_22kV_s;
s.bf_path='IF_52G_FAILS: PERSISTENT_CURRENT_AFTER_TRIP_AND_0.12s -> GSUT_Q0_10ADA10/D07_AND_SOURCE_REMOVAL; IF_GSUT_Q0_FAILS: 230kV_50BF_0.15s';
s.note=[s.note '; functional source-isolation design; plant trip wiring, lockout implementation and interlocks require verification'];
end
