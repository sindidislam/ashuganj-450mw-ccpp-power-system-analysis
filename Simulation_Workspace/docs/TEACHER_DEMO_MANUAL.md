# Ashuganj South Load-Flow - Teacher Demonstration Manual

## Purpose

This project is a **balanced, steady-state load-flow** study of the Ashuganj 450 MW Combined Cycle Power Plant (South). It calculates normal operating voltages, real/reactive power flow, transformer loading and losses at 50 Hz.

It does **not** yet perform short-circuit faults, breaker-duty calculations, relay coordination, TMS/plug settings, differential protection or transient-stability simulation.

## What you need

- MATLAB R2024a
- Simulink
- Simscape Electrical / Specialized Power Systems
- The project folder intact; no internet connection is required

## The safe one-command workflow

Open MATLAB. In the Command Window, enter:

```matlab
cd 'F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project\matlab'
ashuganj_setup
run_all_tests
run_load_flow_study
make_load_flow_plots
```

What each command does:

| Command | Purpose | Typical duration |
|---|---|---|
| `ashuganj_setup` | Adds the project folders to the MATLAB path. Always run this first. | A few seconds |
| `run_all_tests` | Checks data, bases, topology, transformer phase shifts and sensitivity. | About 5-6 minutes |
| `run_load_flow_study` | Builds and solves LF1-LF4, writes CSV reports and clean `.slx` files. | Under a minute |
| `make_load_flow_plots` | Writes the four presentation figures. | About a minute |

Expected success messages:

```text
ALL CHECKS PASSED.
All 4 cases converged and passed every cross-check.
```

## The short live Simulink demonstration

Use this for a presentation rather than re-running the whole study.

1. Start MATLAB.
2. Run the following two lines:

   ```matlab
   cd 'F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project\matlab'
   ashuganj_setup
   ```

3. Open the readable base-case diagram:

   ```matlab
   open('../simulink/main/Ashuganj_South_Main.slx')
   ```

4. Point out the electrical route from left to right:

   ```text
   G1 (22 kV generator) -> GSUT (22/230 kV) -> 230 kV bus -> EXT GRID
                              |
                              +-> UAT -> 6.6 kV auxiliary loads
   ```

5. Explain that `GAT 10BBT20` is the optional 230 kV-to-6.6 kV auxiliary route. In the displayed base case (LF1), its bay is open.
6. Double-click the `powergui` block in the upper-left portion of the model.
7. Confirm that the system frequency is **50 Hz**.
8. Open the Load Flow Analyzer from `powergui`, or type this exactly in the Command Window:

   ```matlab
   powerLoadFlow
   ```

   Do not pass a model name to this command.

9. In the Load Flow Analyzer, select the balanced table and press **Compute**.
10. Press **Report**. The base case should solve in **2 iterations**.

### Important live-demo rules

- Do **not** click `Add bus blocks`; it modifies the model and is unnecessary for the demonstration.
- Do **not** save the model after manually pressing Compute. MATLAB writes solved values into blocks. Close it without saving when finished.
- Do not mistake the `fundamental = 60` FFT-tool field for the system frequency. The actual `powergui` network frequency is 50 Hz.

## The four load-flow cases

| Case | Generator dispatch | GAT bay | Topology | Purpose |
|---|---:|---|---|---|
| LF1 | 389.30 MW | Open | Radial | Base case |
| LF2 | 389.30 MW | Closed | Looped | Shows effect of GAT connection |
| LF3 | 342.01 MW | Open | Radial | Shows effect of reduced generation |
| LF4 | 342.01 MW | Closed | Looped | Combined reduced-generation/GAT case |

## Fresh verified results - 20 August 2026

The latest full run completed with **447 passed checks and 0 failed checks**. Every load-flow case converged in two iterations and passed its power-balance and KCL checks.

| Case | Export MW | Generator MVAr | Loss MW | 6.6 kV bus, pu | UAT MVA | Result |
|---|---:|---:|---:|---:|---:|---|
| LF1 | 374.484 | 31.676 | 0.816 | 1.0009 | 16.520 | OK |
| LF2 | 374.467 | 27.461 | 0.833 | 1.0203 | 20.293 | OK |
| LF3 | 327.330 | 26.174 | 0.680 | 1.0009 | 16.520 | OK |
| LF4 | 327.320 | 22.007 | 0.690 | 1.0208 | 18.799 | OK |

## What to say about the main finding

When the GAT is closed (LF2 and LF4), the GSUT, UAT and GAT form a closed electrical loop. About 5.9 MW circulates through the auxiliary path. It is not additional auxiliary demand. This raises UAT loading to 20.293 MVA in LF2, which is **109.5% of its 19 MVA ONAN rating** but below its 25 MVA ONAF rating.

The GAT-in cases should be presented as a topology comparison. The original document set does not contain the plant interlock/transfer schedule needed to prove that this is a permitted continuous operating state.

## What is supported by the original electrical documentation

- One 458 MVA, 22 kV, 50 Hz generator
- GSUT 10BAT10: 230/22 kV, 16% impedance on 515 MVA
- UAT 10BBT10: 22/6.9 kV, 10.5% impedance on 25 MVA
- GAT 10BBT20: 230/6.9/3.32 kV, 12% primary-secondary impedance on 25 MVA
- 14 MW auxiliary demand at 0.85 lagging power factor
- South-plant maximum voltage: 230 kV, not 400 kV

## Limitations to state honestly

- The external-grid impedance is estimated; a verified PGCB grid equivalent was not available.
- Grid resistance is assumed to be zero because a verified X/R ratio was not available.
- The 6.6 kV plant bus versus 6.9 kV transformer LV-winding discrepancy is retained and reported, not hidden.
- Individual motor operation, 400 V board loads and feeder voltage drops are not modelled; the auxiliary demand is aggregated at 6.6 kV.
- The GAT tertiary is omitted because its two missing impedances are not available. That is acceptable for balanced load flow but not for later earth-fault studies.

## Files to show if asked

| File | What it proves |
|---|---|
| `simulink/main/Ashuganj_South_Main.slx` | Readable LF1 electrical diagram |
| `results/load_flow/system_summary.csv` | One-line numerical summary of the four cases |
| `results/load_flow/transformer_results.csv` | Transformer flows and loading |
| `results/plots/transformer_loading.png` | Shows UAT loading clearly |
| `results/plots/bus_voltage_profile.png` | Shows bus voltages across cases |
| `results/reports/load_flow_report.md` | Detailed written engineering results |

## If you change data

Do not manually edit a Simulink transformer or load block. Change the relevant file under `matlab/data/`, then run:

```matlab
ashuganj_setup
run_all_tests
run_load_flow_study
make_load_flow_plots
```

The study runner rebuilds the models from the data and writes a backup before replacing the main diagram.
