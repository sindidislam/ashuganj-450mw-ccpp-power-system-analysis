# Measured protection engine

Status: both relay functions implemented; current-only regression suite passed in MATLAB R2024a on 2026-09-22 at 08:32:09 Asia/Dhaka. This verifies the pure relay engine; physical model/DC/breaker integration is separately required.

The engine is an academic protection study, not a commissioned relay emulator. It takes actual primary complex RMS current phasors and a physical neutral-resistor RMS current. It does not accept fault locations, scenario flags or Boolean fault detection as relay inputs. The external model owns phasor estimation, CT transfer errors, DC trip availability, breaker movement and source de-excitation.

## Interface contract

`R = phase6_relay_parameters(P)` reads `P.protection.settings` (the relay-setting table) and `P.protection.parameters` (parameter table or numeric scalar struct). Missing tables default independently to the frozen CSVs returned by `setup_phase6_workspace().reference`. `P` may be omitted. Settings passed explicitly are authoritative. R contains numeric data only so a simulation wrapper can keep runtime state independent of MATLAB tables. Its provenance codes are described below.

`[Y,state] = phase6_relay_step(M,state,dt,R,enabled)` evaluates one elapsed sample interval `dt` in seconds. Pass `state=[]` for a new study or explicit reset. `enabled` is a scalar logical or seven-element logical row in relay order. A disabled relay clears unlatched timing, preserves any previous trip latch for diagnostics, and cannot request a breaker or unit trip. DC gating occurs after the engine and must not be confused with disabling the protection algorithm.

| Input | Positive direction / reference |
|---|---|
| `IgenInner`, `IgenTerminal` | Outward from generator; CTs bracket the internal-equivalent shunt-fault zone |
| `IgsutLV` | Unit bus into GSUT |
| `IgsutHV` | GSUT out toward GIS |
| `IbusIn` | Q0 into GIS bus |
| `IbusOut` | GIS bus toward local line breaker |
| `IgatHV` | GIS bus into GAT |
| `IlineLocal` | Plant into line, after local breaker |
| `IlineRemote` | Line into grid, before remote breaker |
| `Ineutral_A` | Real, nonnegative RMS current in the physical neutral-resistor branch |

All phasors are one-by-three `[Ia Ib Ic]` complex RMS primary amperes in the same time reference and phase order. The neutral input is a scalar primary RMS current; it must not be substituted with generator residual current without showing the actual grounding branch equivalence.

Relay order is GEN51, GSUT51, GEN51N, 87G, 87T, 87B, 87L. `pickup`, `trip`, `timer_s` and `operatingTime_s` are one-by-seven. `currentSecondary_A` is one-by-three for GEN51, GSUT51, GEN51N, using the maximum measured phase magnitude for phase overcurrent. `differential_A`, `restraint_A` and `threshold_A` are one-by-four in 87G, 87T, 87B, 87L order. They report the phase with the greatest differential-minus-threshold margin, consistently across all three outputs; each phase is tested independently. `breakerRequest` is one-by-five in GCB, Q0, LineLocal, LineRemote, GAT order. `unitTrip` requests source de-excitation/turbine trip for generator or transformer functions. It is not itself a DC-qualified physical actuator.

## Measurement equations and behavior

GEN51 uses `max(abs(IgenTerminal))/15000`, GSUT51 uses `max(abs(IgsutHV))/1600`, and GEN51N uses `Ineutral_A/20`. Pickup and timing use the frozen primary settings, equivalent to CT secondary comparison. Above pickup, IEC Standard Inverse operating time is `0.14*TMS/(multiple^0.02-1)`. A normalized duty accumulator integrates `dt/operatingTime` and trips at one; varying current therefore contributes its correct partial duty. Pickup duration is separately reported as `timer_s`. Current at or below pickup resets unlatched duty and time. No instantaneous overcurrent or differential high-set is enabled.

87G uses the measured inner minus terminal current. 87T maps the delta-side line currents onto the HV reference with `(22/230)*[Ia-Ib, Ib-Ic, Ic-Ia]/sqrt(3)` and subtracts the HV positive-plus-negative-sequence current `IgsutHV-mean(IgsutHV)`. The cyclic delta matrix produces +30 degrees for positive sequence and -30 degrees for negative sequence. A single fixed phasor rotation is insufficient for unbalanced through-faults. 87B uses `IbusIn-IbusOut-IgatHV`. 87L uses `IlineLocal-IlineRemote`.

Two-terminal restraint is one half of the sum of terminal current magnitudes, independently by phase, after transformer compensation where applicable. Bus restraint is one half of the sum of the magnitudes of all three measured branch currents. Threshold is `max(start, slope1*min(restraint,knee)+slope2*max(restraint-knee,0))`, continuous across the knee. Operation requires differential current strictly above threshold for the prescribed detection delay in one phase. Each phase has a separate timer; switching pickup to another phase cannot satisfy a continuous-delay requirement. Differential `timer_s` reports the longest phase timer. Differential pickup resets on restraint; a completed trip latches until an explicit state reset.

| Relay | Pickup primary A | TMS / delay s | Breaker request |
|---|---:|---:|---|
| GEN51 | 17170.8 | TMS 0.10 | GCB, Q0 |
| GSUT51 | 1380 | TMS 0.55 | GCB, Q0 |
| GEN51N | 4 | TMS 0.15 | GCB, Q0 |
| 87G | 2403.8 | 0.045 | GCB, Q0 |
| 87T | 387.84 HV-referred | 0.045 | GCB, Q0 |
| 87B | 320 | 0.035 | Q0, LineLocal, GAT |
| 87L | 320 | 0.035 | LineLocal, LineRemote |

The Phase 5 line scheme clearing proxy of 0.050 s is retained as source data and is not added to the 0.035 s detection timer. Actual breaker and communication delays belong to the external model. GIS-Q0-51 and the historical GEN-51-SIEMENS-BL comparator are retained in the imported setting rows but are not active functions in this seven-relay interface.

## Provenance and explicit additions

Frozen sources: `Phase6/data/phase5_reference/phase5_relay_settings.csv`, `phase5_parameter_values.csv`, inspected against the read-only source `matlab/phase5/phase5b_parameters.m`. All pickups and study operating delays come from the frozen settings. The transformer 30%/60% slopes and bus 30% slope come from the frozen parameter table. The study GSUT CT is 1600/1; the documentary 1500/1 conflict remains preserved in the imported numeric parameter data.

Added Phase 6 academic assumptions: generator bias 30%; line bias 30%; transformer two-slope knee at twice the rounded HV rated current, `2*1292.8 = 2585.6 A`; continuous two-slope characteristic with an independent minimum start; one-half-sum restraint; zero intentional high-set operation; ideal synchronized phasors and no communication latency within this pure function. These are not official or installed settings. Generator, bus and line use equal first/second slopes, so their knee value has no effect. The transformer knee is a relay characteristic breakpoint, not a CT excitation knee.

Numeric provenance codes: 1 means frozen Phase 5 CSV; 2 means explicitly supplied caller data; 3 means added Phase 6 academic assumption. `R.provenance` identifies each runtime source; `R.phase5` preserves every numeric source parameter, and `R.settingValues` preserves all nine source setting rows. Setting-row order is GEN-51, GEN-51N, GSUT-HV-51, GIS-Q0-51, GEN-51-SIEMENS-BL, GEN-87G, GSUT-87T, GIS-87B, LINE-7SD; columns are primary A, secondary A, CT ratio, TMS, definite delay s, operation proxy s. Inapplicable source cells remain NaN; active runtime values are finite.

## Electrical limits and integration checks

Check CT polarity and phase order with a healthy load-flow operating point before any fault validation. For the selected YNd1 convention, positive-sequence HV current leads LV current by 30 degrees when both are referenced in the stated through-power direction. If the SPS transformer winding configuration uses another convention, correct the physical connection/measurement mapping before changing compensation.

The generator internal-fault study requires a real shunt fault physically between the two CT measurements. A terminal fault outside both CTs correctly produces through-current and is not an 87G internal fault. A GSUT fault must lie between its two CTs; a terminal label alone does not establish differential-zone membership. Include every energized GIS branch in KCL or the omitted load will appear as false differential current.

This model does not emulate CT saturation, harmonic/inrush restraint, overexcitation blocking, generator stator-winding distributed faults, manufacturer adaptive restraint, communication channel supervision, 50BF, 21, 64G injection protection or full installed relay firmware. Those are unimplemented functions, not implied by numeric source rows. Stable phasor estimation and synchronized local/remote data are required upstream. Healthy-DC and failed-DC breaker tests, load-flow checks and dynamic operating evidence remain integration responsibilities.

## Verification command

Run in MATLAB R2024a from the project root:

```matlab
addpath('Phase6/scripts/tests');
clear phase6_relay_parameters phase6_relay_step test_phase6_relays
rehash
test_phase6_relays;
```

The tests cover balanced through-flow, an external transformer fault with negative/zero-sequence components, internal current imbalances in each zone, phase-specific restraint and continuous timing, the hand-calculated 87T knee point (3000 A restraint, 1000 A spill, 1024.32 A threshold), IEC multiples 2/5/10 for all three inverse elements, variable-current duty integration, pickup reset, trip latching, disable gating and caller-table consumption.

Evidence: `Phase6/logs/jobs/job006_relay_red.m.done` records the expected missing-engine failure before implementation. `job010_relay_green.m.log` exposed numeric precision loss when converting an already numeric MATLAB table column through `string`; `job011_relay_numeric_probe.m.log` demonstrated the rounding (1.14472 became 1.1447). The import now preserves native doubles and parses only textual columns. `job012_relay_green.m` still loaded the old cached worker function; `job013_relay_green_refresh.m` explicitly cleared the three task functions, then ran the complete suite successfully. Its `.done` file has `success: true`, and its log contains `PHASE6_RELAY_TESTS_PASS`. No source tolerance was weakened. Clearing these task-local functions is useful when rerunning an edited implementation in a long-lived worker.

## Simulink adapter

`phase6_relay_sfun` is a Level-2 MATLAB S-function with dialog parameters `R,S`. Both inputs are real double: port 1 is the 228-element packed sensor vector, port 2 is scalar measurement validity. Each of 19 sensors occupies 12 elements `[Re(Vabc), Im(Vabc), Re(Iabc), Im(Iabc)]`. Sensors 1–9 supply the nine current inputs in the table above. Sensor 12 is the neutral branch, whose phase-A phasor magnitude becomes `Ineutral_A`. The complete sensor order is genInner, genTerminal, gsutLV, gsutHV, busIn, busOut, gatHV, lineLocal, lineRemote, aux, grid, neutral, faultGEN, faultLV, faultHV, faultGIS, faultLINE, faultGRID, faultAUX. Fault-location sensor entries are not used by the protection decision.

`S.protectionEnabled && valid` enables the relay set, further gated by optional `S.relayMask` in seven-relay order. Invalid measurements contribute zero diagnostic current and cannot request a breaker; any existing trip latch remains diagnostic state. Output port 1 contains 43 values: pickup 1–7, trip 8–14, timer 15–21, operating time 22–28, secondary current 29–31, differential 32–35, restraint 36–39 and threshold 40–43. Output port 2 contains the five breaker requests followed by unit trip.

Sample time is 1 ms. Inputs have no direct feedthrough; `Outputs` returns data from the previous `Update`. Its 29-state relay data plus stored outputs live exclusively in real DWork and reset every simulation. No persistent/global MATLAB runtime data is used. Treat the stored interface as one sample of coupling latency when interpreting breaker timing.

`test_phase6_protection_sfunctions` compiled and simulated both adapters in MATLAB/Simulink R2024a, checked normal packed-current restraint, a measured 87G internal imbalance and correct request mapping, then verified a second run with the mask disabled did not inherit the previous trip. Evidence is `job029_protection_wrappers_green.m.done` (`success: true`, 08:55:23 Asia/Dhaka) and its `PHASE6_PROTECTION_SFUNCTIONS_PASS` log. Its initial missing-wrapper failure is recorded by job028.
