# Independent Phase6 logic audit — 2026-09-25

Scope: read-only inspection of original v4 scripts and ZIP/XML model contents, followed by delegated focused code/test corrections. No MATLAB session was started by this agent. Root agent owns run evidence.

## Critical findings in the received files

1. `matlab/phase6/build_dynamic_protection_sim.m` copied the prior dynamic model, inserted an unconnected `CL_TripRelayHook` subsystem containing Constant -> Gain -> Terminator, and called this a closed-loop artifact. The SLX ZIP confirmed this description. `run_dynamic_trip_simulation.m` manufactured sine-wave current, integrator, breaker state and restored voltage; its only actual sim probe stopped at 0.02 s, long before the claimed 0.50 s fault. Existing `test_phase6_dynamic_trip` verified those manufactured arrays and allowed the model to be missing. Root is replacing both entry points with actual measured simulation.
2. `START_PHASE6.m` opened the older DYNAMIC_MODEL. Its builder accepted only that basename. A copied renamed model retained old model names and block paths in `Phase6BuildInfo`; interactive structural changes (dispatch/profile/GAT) called the fixed-name builder. Root owns canonical model rebuild/startup; this agent supplies propagation of ModelName in the UI.
3. The UI accepted any returned sim output as complete, including a user-stopped record, and enabled export. No end-time gate existed. A shared completion check is being added before caching/exporting interactive runs.
4. `phase6_normalize_scenario` accepted infinite fault resistance/duration, malformed Boolean values and negative scheduled events. It accepted lowercase category values but left them lowercase, while the UI popup looked up case-sensitive names. Focused validation and category normalization tests were added.
5. `phase6_compare_reference` initialized status to PASS then checked only error > tolerance. NaN error therefore remained PASS; different-profile qualification could also conceal invalid values. Focused regression added.

## Engineering/model qualifications to state explicitly

- The real Phase6 relay engine implements GEN51, GSUT51, GEN51N, 87G, 87T, 87B and 87L. Its differential delays, biases and thresholds are frozen study proxies. It does not implement the newer standalone Phase5c harmonic or high-set screening behavior. Existing relay tests intentionally confirm no instantaneous high-set operation.
- 87T vector compensation is a cyclic delta matrix with HV zero-sequence subtraction. The pure tests cover positive/negative/zero-sequence behavior, a hand-computed two-slope point, per-phase timer continuity, IEC inverse-duty accumulation and trip/reset mapping. No evident equation defect was found in this review.
- The DC path has one aggregate initial trip pulse and healthy-bus gating; it does not represent individual trip-coil energy for manual commands or later independent trips. `phase6_dc_step` now preserves a pending trip until supply is healthy, but `DC_TASK_REPORT.md:51` still described expired unpowered pulses requiring a new edge.
- Breaker histories are latched open commands. Exported current cessation is a separate measured 20 ms low-current criterion. Generator internal-equivalent faults can remain energized by stored machine energy after external breaker opening; do not call this complete internal-fault extinction.
- Two transmission circuits share modeled local/remote breaker sets. The auxiliary bus has no dedicated new 6.6 kV feeder OC/breaker path corresponding to the synthetic Task-8 plot.
- `measurementScale` scales all six V/I channels of each sensor, although its block label says CT test factors. Changing auxiliary sensor scale also changes the charger AC-voltage indication. Treat this as a measurement-channel test factor, not a physical CT-only saturation model.
- Default PHASE3_BASELINE retains grid R=0 by design; default numerical damping and missing/unused source fields also remain. New hardware prose asserting nothing is ideal zero and no unresolved entries remain contradicts the actual numerical/provenance model.
- Hardware prose used total bus fault current to infer CT saturation, asserted 50 kA covers 53 kA, and presented harmonic restraint as a CT-saturation guarantee. These were routed to the documentation agent.

## Files changed by this agent

- `matlab/tests/test_phase6_dynamic_trip.m`: replaced manufactured-waveform assertions with real normal/fault/protection-disabled integration checks and persisted evidence. Throws on nonzero failure count so a batch cannot return success despite failed checks.
- `Phase6/scripts/tests/test_phase6_input_and_evidence.m`: focused invalid-scenario, partial-run and NaN-comparison regressions.
- Pending coordinated changes: UI structural rebuild/completion gate, scenario validation, comparison invalid statuses, shared completion helper. Root records red/green execution.

## Recommended existing checks

Run in the root-owned MATLAB session after adding `Phase6/scripts` and `Phase6/scripts/tests`: `test_phase6_parameters`, `test_phase6_measurement`, `test_phase6_relays`, `test_phase6_dc`, `test_phase6_dc_recovery`, `test_phase6_actuators`, `test_phase6_protection_sfunctions`. `test_phase6_build` rebuilds the historical dynamic model and is not a substitute for the new canonical closed-loop integration test.

The new `test_phase6_dynamic_trip` retains `Phase6/results/regression_<uuid>` and requires actual SimulationOutput, no hook, correct saved model metadata, normal generation within 1 percent of 360 MW with no trip, 87B trip before fault-off, Q0/LineLocal opening after 50 ms within sample latency, sustained current cessation while fault remains applied, and continued fault current with protection disabled. No synthetic fallback can satisfy its contract.
## Coordinated correction status

The root session recorded the expected first failure in `input_red.log` (accepted lowercase categorical settings were not normalized). This agent then applied the following fixes without running MATLAB:

- `phase6_normalize_scenario`: scalar/type/finite/range validation; strict 0/1 logical flags and masks; normalized uppercase category values; only documented scheduled events accept +Inf; nonnegative event times; restore-after-loss and enabled-fault-before-stop checks.
- `phase6_assert_complete_run`: rejects a SimulationOutput containing ErrorMessage, missing/nonfinite time records, or a final saved tout different from the requested stop time (numerical tolerance only).
- `phase6_interactive_settings`: completion gate before caching a run and exporting it; structural rebuild forwards the current ModelName; relay edits require real numeric values.
- `export_phase6_results`: direct export also calls the completion gate.
- `phase6_compare_reference`: nonfinite values are INVALID_NONFINITE, including when a different-profile qualification applies.

The new physical wrappers and `phase6_trip_paths` were reviewed after the root rewrite; their returned R.out/info/export and S.info/params/meta interfaces match the integration test. The real builder retains `TimeSaveName=tout` and controller metadata contains `controls.parameters.Ts`. Root owns the pending green MATLAB evidence.
