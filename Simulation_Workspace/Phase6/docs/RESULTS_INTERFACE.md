# Phase 6 results interface

`export_phase6_results(out, info, outputDir)` exports a completed `Simulink.SimulationOutput`; it does not build or simulate the model. `info` is the return value from `build_phase6_model`. The destination must resolve canonically within this project's `Phase6/results` directory. The default is `Phase6/results/<scenario.name>`.

```matlab
paths = setup_phase6_workspace();
result = export_phase6_results(out, info, ...
    fullfile(paths.results, info.scenario.name));
```

Use absolute paths in worker jobs: MATLAB `run` temporarily enters the job script's directory. Output filenames are fixed within each scenario directory; exporting into the same directory updates that scenario's artifacts.

## Required logged signals

Every input is a real `timeseries` with strictly increasing simulation timestamps. Nonfinite measured values reject the export; positive infinity is allowed only for the relay's calculated operating-time channels, where it means no finite operating time at the present current. Each CSV preserves its own recorded timebase; signals are not interpolated onto a fabricated common grid.

| Signal | Width | Channel order and units |
|---|---:|---|
| `phase6_raw` | 114 | 19 sensors × `[Va Vb Vc Ia Ib Ic]`, instantaneous V and A; typically 0.2 ms logging |
| `phase6_phasors` | 228 | Per sensor `[Re(Vabc) Im(Vabc) Re(Iabc) Im(Iabc)]`, RMS V/A; 1 ms |
| `phase6_rms` | 114 | Per sensor `[Vabc Iabc]`, full-waveform sliding RMS V/A; 1 ms |
| `phase6_relay` | 43 | Pickup 7, trip request 7, accumulated timer 7 (s), calculated operating time 7 (s), secondary current 3 (A), differential 4 (A primary), restraint 4 (A primary), threshold 4 (A primary) |
| `phase6_dc` | 12 | DC bus V; battery, charger and load A; SOC pu; healthy, low voltage, battery low, charger failure, trip unavailable; charger AC W; trip-coil W |
| `phase6_breakers` | 6 | GCB, Q0, local line, remote line, GAT **closed commands**; unit trip |
| `phase6_machine` | 4 | Rotor speed pu, machine delta (native logged quantity), mechanical input pu, field voltage pu |
| `phase6_summary` | 24 | Labels supplied by `info.controls.summaryNames` |

Sensor order comes from `info.controls.sensorNames` and matches the model: `genInner`, `genTerminal`, `gsutLV`, `gsutHV`, `busIn`, `busOut`, `gatHV`, `lineLocal`, `lineRemote`, `aux`, `grid`, `neutral`, `faultGEN`, `faultLV`, `faultHV`, `faultGIS`, `faultLINE`, `faultGRID`, `faultAUX`.

Relay order is GEN51, GSUT51, GEN51N, 87G, 87T, 87B, 87L. Differential quantities are primary operating quantities for their compensated zones; they must not be confused with the first three secondary-current diagnostics.

## Files produced

Eight `*_timeseries.csv` files contain all original recorded samples with units in channel labels. Startup samples remain in these files and in `simulation_data.mat`. Summaries, event extraction and plots exclude timestamps before 0.020 s, when the measurement chain has not yet acquired a full cycle.

Additional CSVs are:

- `signal_inventory.csv`: sample counts, widths, first/last timestamps and median recorded interval.
- `load_point.csv`: mean, minimum, maximum and standard deviation of each plant summary quantity over up to 100 ms before the first scheduled disturbance in the record. With no scheduled disturbance, it uses the final 100 ms. The interval is explicit and cannot include the measurement warmup.
- `fault_summary.csv`: measured A/B/C fault-branch current, voltage, peak and full-window fundamental metrics, with explicit measurement windows and statuses.
- `relay_times.csv`: first logged pickup and trip-request times, elapsed times relative to scheduled fault initiation, the logged timer at trip, and the calculated operating time at pickup. A trip request precedes DC gating and breaker operation.
- `phase_pickup.csv`: independently reconstructed per-phase threshold crossings for the exact run's relay settings. It reports 3 phases for each of the six phase relays and one physical neutral channel for GEN51N. These are measured operating-quantity crossings, not invented phase-specific trip times.
- `breaker_times.csv`: per-phase open-command and sustained measured current-cessation times, associated current sensor, threshold, hold interval and status.
- `dc_statistics.csv`: post-warmup min/max/mean/first/last values and time spent asserted for boolean DC indications.
- `events.csv`: actual logged pickup, trip, breaker command and DC transitions. Scheduled fault application/removal is included with source `scenario_setting_not_measured_switch_state`, distinguishing the schedule from measured transitions.

Five publication-style figures are written as both 220 dpi PNG and vector PDF: voltage/frequency, speed/P/Q, selected fault-branch waveforms, protection/breaker commands, and station DC response. Plots use actual logged values and units. A disabled fault produces a clearly labeled inactive-branch figure.

`simulation_data.mat` preserves the original `out`, build `info` including solved load flow and scenario, labeled numeric `signals`, derived `tables`, and `metadata`. `scenario_metadata.json` documents scenario settings, sensor/channel labels, measurement windows, sampling, and reporting conventions. JSON encodes NaN/Inf as null; MAT retains exact numerical values, and the CSV status columns explain absent events. The load-flow initialization is preserved as `info.loadflow`, independently of the measured dynamic load point.

## Fault and timing conventions

Fault current uses the branch corresponding to the configured fault location: GEN→faultGEN, GSUT_LV→faultLV, GSUT_HV→faultHV, GIS230→faultGIS, LINE230→faultLINE, GRID230→faultGRID, AUX66→faultAUX. It is never taken from the maximum of unrelated branch currents.

The initial waveform window begins at the scheduled fault time and ends at the earliest of 20 ms later, scheduled fault removal, the first observed breaker open command, or record end. The opening sample is excluded. RMS over a shortened window is retained and labeled `partial_initial_cycle_before_open_or_end`; it is not presented as a full-cycle value. Peak current comes from these same actual raw samples.

The 50 Hz measurement has a 20-sample window and one 1 ms Update-to-Outputs delay. Fundamental fault-current metrics therefore start no earlier than fault start +21 ms, and use only fully post-fault phasor windows before an open command or scheduled fault removal. The fundamental measurement interval is bounded at fault start +60 ms. If no qualifying window exists, its result is NaN with an explanatory status. Waveform RMS includes harmonics and DC; the fundamental phasor does not.

GEN51 and GSUT51 phase threshold crossings use the magnitude of their respective measured phase phasors divided by the exact CT ratio. GEN51N uses sensor `neutral` phase A, the model's single physical neutral-current measurement; it does not substitute the generator phase-current sum. Differential phase crossings repeat the model's compensation and restraint equations from the full logged phasors, since its scalar diagnostics retain only the phase with the largest operating margin. The transformer compensation includes negative and zero-sequence treatment. `info.controls.relayParameters` is the exact parameter source (alternatively `info.relayParameters`); settings are never silently rebuilt from defaults. Missing settings produce unavailable statuses. Disabled relay threshold crossings are labeled as disabled rather than reported as enabled pickup. Measurement scaling is already present in the phasor log and is not applied again.

The logged relay pickup normally follows the corresponding measured threshold crossing by the relay wrapper's 1 ms stored-output delay. The CSVs retain both timebases. Overcurrent timing uses the model's single max-phase relay accumulator; there are no separately simulated phase trip times. Pickup that already exists at reporting start is explicitly marked and is not hidden by fault-window filtering.

`phase6_breakers` reports commands, not contact feedback. Current cessation is a separate observation from the **unscaled raw** phase current at the associated breaker sensor. It requires `abs(I) <= max(1 A, 0.001 × the preceding 20 ms peak abs(I))` continuously for at least 20 ms after the open command. The reported cessation time is the beginning of that verified low-current interval. An AC zero crossing alone cannot satisfy it. Snubber leakage, charging current or another feed may prevent the criterion from being met. This is an explicit numerical observation criterion, not an installed breaker contact measurement or a claim of validated physical clearing accuracy. An initially open GAT is not counted as an opening event.

Absent pickup/trip/open/current-cessation events remain NaN with statuses such as `not_observed`, `relay_disabled`, `initially_open_no_open_transition` or `no_sustained_current_cessation_in_record`; zero is never substituted for an absent event.

## Test boundary

`phase6_result_tables(out, info)` contains the calculation layer and can accept a struct of explicitly labeled unit-test timeseries fixtures. Its metadata then identifies the data as a unit-test fixture. The production exporter rejects such structs and accepts a `Simulink.SimulationOutput` only. Fixture checks exercise branch selection, RMS/DFT windows, missing-event NaNs, asymmetric phase crossings, startup exclusion, command/current timing, and path/data guards. Production plot validation is performed using an actual completed simulation output.
