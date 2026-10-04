# Phase 6 validation evidence

Evidence review: 2026-09-24, using saved MATLAB R2024a runs from September 23-24
in the kimi k3 project. Numerical checks, the visible GUI normal Run action,
late DC restoration and the latest normal reference comparison passed. Remaining
delivery work is completion of saved-run presentation exports and the final
persisted styling hooks/check. This report does not yet declare Phase 6 complete.

## Verified runs

The six component suites and integrated normal build/run passed in
`logs/resume_20260923_normal.log`. The eleven-case batch passed 11/11 measured
assertions in `results/scenario_validation.csv` and
`logs/resume_20260923_evening/validate_scenarios.log`. Supplemental and interface
results are in `logs/resume_20260923_evening/worker.log`.

The September 24 saved-model continuation compiled successfully. Four regression
suites (DC recovery, DC supply, actuators and protection S-functions), a normal
run started by the actual GUI Run button, integrated late DC restoration and
the final normal run passed in `logs/resume_20260924/final_checks.log`.
The new test first reproduced the pending-trip defect in `desktop.log`, then
passed after the DC pulse was changed to wait for supplied power.

| Saved scenario | Observed result |
|---|---|
| normal / final_normal.mat | No nuisance trips; initialized 360 MW operating point; later interface run returned to normal settings |
| bus_3ph | 87B request 0.187 s; Q0/local line open commands 0.237 s; all commanded phases show sustained branch-current cessation by 0.2476 s |
| generator_3ph | 87G request 0.197 s; GCB/Q0 open 0.247 s; measured cessation in both breaker branches |
| transformer_lv_ll | 87T request 0.198 s; GCB/Q0 open; measured branch-current cessation |
| transformer_hv_llg | 87T request 0.197 s; GCB/Q0 open; measured branch-current cessation |
| line_slg | 87L request 0.188 s; both line-end commands open 0.238 s; measured branch-current cessation |
| grid_external_ll | Actual external-fault current; no generator/transformer/bus/line differential trip |
| generator_slg | Physical neutral current picks up GEN51N; 7.256670 A initial-window fundamental; short fault ends before inverse trip |
| generator_slg_timed | GEN51N pickup 0.166 s, request 1.921 s; GCB/Q0 open 1.971 s; all commanded phases show branch-current cessation |
| dc_loss_bus_3ph | 87B request with DC at zero and trip-unavailable alarm; breakers remain closed |
| dc_recovery_bus_3ph | No opening before 0.300 s restoration; DC healthy/coil power 0.301 s; Q0/local line open 0.351 s |
| dc_late_recovery_bus_3ph | September 24 run: restore at 0.500 s; DC healthy and 2 kW coil power at 0.501 s; Q0/local line open 0.551 s; coil power ends 0.701 s |
| protection_disabled | Actual bus-fault current; no relay trip or breaker opening |
| charger_unavailable | Charger current zero/alarm active; battery discharges and retains healthy trip supply |
| reset_normal | New simulation resets prior relay/breaker states; no nuisance trips; normal voltage/frequency |
| reduced_180MW | Fresh load-flow initialization; 179.943861 MW, 21.999987 kV and 50.000027 Hz mean in 0.300-0.400 s; no nuisance trip |
| interactive_bus_trip | Editable 87B delay changed from 0.035 to 0.070 s; request moved to 0.222 s and open commands to 0.272 s; exact settings retained in export |

All fault scenarios above start at 0.150 s. The timed neutral test lasts 2.5 s;
other checks are short runs. The 11/11 batch count does not include the bus,
timed-neutral, reduced-load or interactive supplemental runs. Earlier worker
errors were followed by successful corrected jobs; they are retained in the log.

## Operating point and reference checks

`results/operating_point_comparison.csv` contains 14/14 PASS rows against the
frozen Phase 3 LF360_GAT_OUT reference using the September 24 final normal run.
Selected measurements over 0.500-0.600 s are 360.005275 MW, 27.616864 MVAr,
21.999958 kV and 50.000029 Hz.
Tolerances are explicit in every row. Grid source P/Q are reconstructed across
the selected series impedance, because the remote-terminal measurement has a
different reactive-power boundary. `results/setting_consistency.csv` records
seven pickup/CT/TMS/delay rows matching the frozen study settings. This table
does not validate every differential characteristic or installed relay function.

`results/fault_reference_comparison.csv` and `FAULT_REFERENCE_COMPARISON.md`
compare seven selected faults with the frozen Phase 4/5 initial Ikpp backbone.
The governing quantities are reconstructed from saved complex phasors and all
21 phase means are independently checked against the exported fault summaries.
Every comparison is qualified: the 0.171-0.210 s DFT window, machine dynamics,
grid resistance and sequence assumptions differ from the initial reference.
The generator 3PH difference is -12.273% and the transformer LV LL difference
is -9.411%; these are disclosed without forcing agreement or assigning an
accuracy PASS. Phase 3 baseline and revised Phase 5 screening profiles remain
distinct.

## What interruption and recovery mean

Every observed open command in the saved scenarios has a per-phase sustained
current-cessation record. The criterion uses raw current below the larger of
1 A and 0.1% of pre-command peak for 20 ms. This measures breaker-branch
interruption, not physical contact feedback or complete internal-fault extinction.

After GCB opening, the generator 3PH fault branch still carries approximately
27.1-27.5 kA waveform RMS at 0.400 s. The timed SLG fault branch still carries
6.863 A at 2.200 s. Scheduled removal occurs at 0.450 and 2.300 s respectively.
Unit protection commands field and prime-mover shutdown, but stored machine
energy remains. Long-duration stability and full internal-fault extinction
times have not been established by these records.

The September 24 DC correction preserves a pending initial trip pulse while
power is unavailable. The integrated late-restoration case restores at 0.500 s,
after the old unpowered pulse would have expired. The recorded coil receives
2 kW from 0.501 to 0.701 s and the two bus breaker commands open at 0.551 s.
This closes the demonstrated pending-initial-trip recovery defect.

The interface still represents one aggregate trip pulse and gates breaker
mechanisms by healthy bus service. It does not independently wire or meter
each physical coil. Manual commands bypass that aggregate demand, and another
individual trip while aggregate demand stays high does not create a separate
coil pulse. The verified initial protection trip/recovery must not be extended
to independent multi-coil or manual-trip energy claims. The DC supply input
uses aggregate phase waveform RMS; the older DC task report's positive-sequence
wording is not its exact integrated implementation.

## Artifact and preservation status

CSV time histories, fault/relay/breaker/DC summaries and original simulation
MAT data exist for all listed scenario directories. Normal, bus_3ph,
reduced_180MW, interactive_bus_trip and dc_late_recovery_bus_3ph contain full
figure/JSON exports. `logs/resume_20260924/export_remaining.m` completes missing
outputs from saved MAT data without rerunning simulations. Completion requires
its `export_remaining.done.json` success marker and nonempty required outputs;
preparing the script alone is not evidence that those exports exist.

The persistent source/assumption register is
`results/phase6_parameter_register.csv`. The fresh SHA-256 check covered 490
upstream files with zero changes at 2026-09-24 18:14:01 +06:00, recorded in
`logs/resume_20260924/upstream_hash_check.json`.

## Remaining final gates

- Complete the remaining saved-run exports and verify the success marker and
  required JSON/figure files.
- Finish the persisted styling hooks and final presentation check so the saved
  model retains the intended readable colored view after reopening.

The saved presentation evidence is `logs/resume_20260924/final_model.png`,
`final_phase_meters.png` and `final_panel.png`. Actual GUI Run was exercised;
scripted setting/reset/export calls and screenshots document the other tested
paths without implying an exhaustive test of every possible control sequence.

Unsupported installed functions, controller tuning, CT saturation, communications
latency and detailed winding physics remain the explicit study limits in
`PHASE6_ARCHITECTURE.md`, `PHASE6_ASSUMPTIONS.md` and `GROUNDING_REVIEW.md`.
