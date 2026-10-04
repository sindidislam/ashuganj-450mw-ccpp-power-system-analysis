# Teacher demonstration: 8-10 minutes

Use MATLAB R2024a. Open this project's `Phase6/START_PHASE6.m` and click Run.
It opens the saved model and its study controls; a missing model is rebuilt.
The numerical examples below are supported by September 23-24 saved runs.
The saved model compiled and the actual GUI Run action passed on September 24.
Remaining exports and final persisted styling are tracked in
`PHASE6_VALIDATION_REPORT.md` before the finished deliverable is announced.

1. **Plant and operating point (2 minutes).** Identify Generator, Transformer,
   Switchyard, Transmission Line, Grid and Auxiliaries on the top-level SLD.
   Open the generator to show the synchronous machine and the turbine/AVR
   subsystem to show its real input path. In the control panel choose
   **Reset defaults**, then **Run simulation**. The normal study dispatch is
   360 MW with GAT out. Show the measured 22 kV line-to-line voltage and 50 Hz
   frequency. In **Measured voltages and currents**, Va/Vb/Vc are phase RMS
   voltages, so a healthy 22 kV bus is approximately 12.70 kV per phase. The
   table shows the latest completed run; Simulink meters update with simulation.

2. **Measured fault and protection (2 minutes).** In **Operating point and
   faults**, use a new scenario name, 3PH, GIS230, start 0.150 s, duration
   0.300 s and stop 0.600 s. Keep protection, battery and charger available.
   Click **Run simulation**. Select **Fault bus** on the measurements tab and
   **Plot selected V / I waveforms**. Open Protection and DC Supply to follow
   measured current, pickup/timing, trip demand, DC availability and breaker
   action. The saved default run has 87B pickup at 0.153 s, trip request at
   0.187 s, Q0/local-line open commands at 0.237 s and sustained current
   cessation by 0.2476 s. Click **Export results** to retain this run's tables,
   plots and exact settings under its scenario name.

3. **Change a real relay setting (1 minute).** In **Protection settings**,
   change Bus 87B **Delay (s)** from 0.035 to 0.070. Use another scenario name
   and run again. The saved check moved the request to 0.222 s and the open
   commands to 0.272 s. Explain that these are editable academic study settings;
   the frozen Phase 5 source table is preserved. Restore defaults before the
   next example, then re-enter the bus fault settings.

4. **DC-supported tripping and reset (2 minutes).** For the bus fault, set DC
   loss time to 0.080 s and restoration to Inf. Run with a distinct name.
   Show zero DC voltage, trip-unavailable alarm and a relay request while the
   breakers remain closed. Repeat the saved recovery case with restoration
   at 0.500 s, with fault duration 0.600 s and stop time 0.850 s: the pending
   initial trip waits for supply, coil power returns at 0.501 s and Q0/local
   line open at 0.551 s. The 2 kW pulse lasts until 0.701 s. This is the
   verified late-restoration case. The DC model represents an aggregate
   initial trip pulse; manual commands and later separate trips do not have
   independently modeled coil demands. Choose **Reset defaults**, run normal
   again and show that prior relay/breaker latches clear in the new simulation.

5. **Evidence and limits (1-2 minutes).** Show
   `results/operating_point_comparison.csv`: all 14 frozen baseline checks
   passed, with measured errors and tolerances visible. Show the reduced
   180 MW saved run if time permits. Use `FAULT_REFERENCE_COMPARISON.md` to
   explain why later dynamic fundamental currents differ from initial Ikpp.
   For generator-side faults, distinguish opening the external breaker branch
   from extinguishing the fault: stored machine energy continues feeding the
   internal branch after GCB opens. The 110 V battery, control tuning and some
   relay characteristics are declared study assumptions; the model does not
   establish installed-plant settings, complete internal-fault extinction or
   long-duration stability.

Leave the model at **Reset defaults**, followed by a normal run. Use distinct
scenario names when retaining demonstrations: exporting the same name replaces
that scenario's generated files. If a run or control fails, show the saved
verified evidence and record the failure instead of presenting it as a pass.
