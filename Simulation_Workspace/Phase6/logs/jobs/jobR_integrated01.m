setup_phase6_workspace();clear build_phase6_model phase6_add_controls phase6_control_sfun phase6_breaker_sfun phase6_monitor_sfun;rehash;
info=build_phase6_model('Scenario',struct('stopTime_s',.1));
fprintf('INTEGRATED_MODEL_BUILD_PASS\n');
save('Phase6/logs/integrated_build.mat','info');
