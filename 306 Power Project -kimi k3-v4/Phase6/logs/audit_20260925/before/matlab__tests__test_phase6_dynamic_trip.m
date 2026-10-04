function [np, nf] = test_phase6_dynamic_trip()
%TEST_PHASE6_DYNAMIC_TRIP  Closed-loop dynamic relay-trip evidence checks.
%   Runnable via:
%     matlab -batch "addpath(genpath('matlab')); test_phase6_dynamic_trip"
T = t_case('test_phase6_dynamic_trip');
out = fullfile(tempdir, ['phase6_trip_' char(java.util.UUID.randomUUID())]);
mkdir(out);
cleanup = onCleanup(@()rmdir(out, 's')); %#ok<NASGU>
root = ashuganj_root();

S = build_dynamic_protection_sim(out, root);
T = T.chk(isfile(S.params_csv) && isfile(S.meta_json), ...
    'trip params CSV + JSON meta are staged');
T = T.chk((S.model_copied && isfile(S.model_dst)) || ...
    (~S.model_copied && ~isempty(S.model_note)), ...
    'closed-loop model copied, or miss honestly flagged with a skip note');
T = T.chk(~isempty(S.insertion_status) && ...
    (startsWith(S.insertion_status, 'inserted') || startsWith(S.insertion_status, 'not-inserted')), ...
    'relay/breaker-hook insertion status recorded honestly');
P = readtable(S.params_csv);
T = T.chk(height(P) == 3, 'params CSV carries the 3 protection elements');
T = T.chk(abs(S.Iload_66_A - 14e6 / (sqrt(3) * 6600 * 0.85)) < 1e-6, ...
    '6.6 kV load derives from 14 MW @ 0.85 / 6.6 kV (~1441 A)');
T = T.chk(abs(S.Ipick_66_A - 1.2 * S.Iload_66_A) < 1e-9, ...
    '6.6 kV pickup is 1.20x load (~1729 A)');
T = T.chk(abs(S.Ipick_22_A - 17170.8) < 1e-9 && abs(S.TMS_22 - 0.20) < 1e-12, ...
    '22 kV backup keeps 17170.8 A pickup with Task-8 TMS 0.20');
T = T.chk(abs(S.t_inst_s - 0.040) < 1e-12, 'instant element is definite 40 ms');

R = run_dynamic_trip_simulation(out, root);
T = T.chk(isfile(R.times_csv) && isfile(R.png), ...
    'trip times CSV + validation PNG are written');
info = imfinfo(R.png);
T = T.chk(info.Width > 800, 'validation PNG is wider than 800 px');

% Trip times must reproduce the IEC SI calculator within one 50 us-class
% tolerance band (spec: +-15 ms).
want66 = phase5_time(R.Ifault_66_A, R.Ipick_66_A, R.TMS_66, 'SI');
T = T.chk(abs(R.t_op_66_s - want66) <= 0.015, ...
    '6.6 kV SI trip matches phase5_time within 15 ms');
want22 = phase5_time(R.Ifault_22_A, R.Ipick_22_A, R.TMS_22, 'SI');
T = T.chk(abs(R.t_op_22_s - want22) <= 0.015, ...
    '22 kV backup SI trip matches phase5_time within 15 ms');
T = T.chk(abs(R.t_trip_66_s - (R.fault_at_s + R.t_op_66_s)) < 1e-12, ...
    'absolute trip = fault at 0.50 s + operating time');

% Closed-loop waveform behaviour.
T = T.chk(abs(R.integrator_max - 1.0) < 1e-9, 'SI integrator reaches 1.0 at trip');
T = T.chk(R.i_post_max_A < 0.05 * R.i_fault_peak_A, ...
    'phase current truncates after trip (post < 5% of fault peak)');
T = T.chk(R.v_post_min_pu >= 0.95, 'voltage restores to >= 0.95 pu after trip');
T = T.chk(abs(R.dt_s - 50e-6) < 1e-12 && abs(R.fault_at_s - 0.50) < 1e-12, ...
    'synthesis uses 50 us step with fault at 0.50 s');
T = T.chk(ischar(R.sim_mode) && ~isempty(R.sim_mode) && ~isempty(R.sim_note), ...
    'sim-vs-analytical provenance is labelled honestly');

% CSV round-trip: persisted times agree with the calculator too.
TT = readtable(R.times_csv);
r66 = TT(strcmp(TT.device, 'FEEDER-6.6kV-51-SI'), :);
r22 = TT(strcmp(TT.device, 'GEN-51-SI-BACKUP'), :);
T = T.chk(height(r66) == 1 && abs(r66.t_op_s - want66) <= 0.015, ...
    'persisted feeder time matches phase5_time within 15 ms');
T = T.chk(height(r22) == 1 && abs(r22.t_op_s - want22) <= 0.015, ...
    'persisted backup time matches phase5_time within 15 ms');

% Invalid-argument error paths.
try, build_dynamic_protection_sim(42); T = T.chk(false, 'build rejects bad outDir'); ...
catch ME, T = T.chk(startsWith(ME.identifier, 'build_dynamic_protection_sim'), 'build rejects bad outDir'); end
try, build_dynamic_protection_sim(out, root, 'extra'); T = T.chk(false, 'build rejects arity 3'); ...
catch ME, T = T.chk(startsWith(ME.identifier, 'build_dynamic_protection_sim'), 'build rejects arity 3'); end
try, run_dynamic_trip_simulation(42); T = T.chk(false, 'run rejects bad outDir'); ...
catch ME, T = T.chk(startsWith(ME.identifier, 'run_dynamic_trip_simulation'), 'run rejects bad outDir'); end
try, run_dynamic_trip_simulation(out, root, 'extra'); T = T.chk(false, 'run rejects arity 3'); ...
catch ME, T = T.chk(startsWith(ME.identifier, 'run_dynamic_trip_simulation'), 'run rejects arity 3'); end

[np, nf] = T.done();
end
