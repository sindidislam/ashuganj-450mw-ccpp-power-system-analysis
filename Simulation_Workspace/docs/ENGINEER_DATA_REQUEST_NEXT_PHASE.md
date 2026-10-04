# Engineer Data Request and Next-Phase Plan

## 1. Direct answer about generator excitation, DC and batteries

The available South drawings confirm that the plant has **static excitation equipment** and both **110 Vdc** and **220 Vdc** systems. The protection one-line also shows 24 Vdc control circuits. This proves that DC control/protection systems exist, but it does **not** prove that the station battery continuously supplies the generator field.

For a large static-excited synchronous generator, the normal arrangement is usually:

1. AC power is taken from the generator terminals or auxiliary system through an excitation transformer.
2. A controlled rectifier converts that AC to DC.
3. The rectified DC feeds the generator rotor field.
4. A battery or dedicated field-flashing supply may provide initial excitation before generator terminal voltage exists.
5. Station batteries normally provide dependable tripping, closing, relay, emergency-control and field-flashing power—not bulk energy storage for exporting generator MW.

This is a **logical engineering interpretation**, not yet a verified Ashuganj operating fact. The current PDFs show static excitation and DC systems, but the following exact architecture is still unknown:

- Normal field source
- Field-flashing source
- Whether field flashing is from 110 Vdc, 220 Vdc, an AC rectifier or a dedicated battery
- Battery banks and chargers feeding the excitation controls
- Transfer logic following loss of normal AC
- Black-start capability

A station battery stores enough energy for controls, relay operation, breaker trip/close, emergency loads and possibly field flashing. It does **not** store meaningful quantities of the plant's 342–389 MW generation unless a separate utility-scale BESS exists. No such BESS is shown in the current South SLD.

## 2. Data already confirmed from current PDFs

- Static excitation equipment exists.
- Excitation transformer is connected to the 6.6 kV system.
- Generator rated field voltage/current: 406 V / 3088 A.
- Generator no-load excitation voltage: 122 V.
- SFC DC-link voltage: 2.28 kV.
- Maximum SFC starting current: 1876 A.
- 110 Vdc and 220 Vdc systems are shown.
- Protection one-line identifies excitation trips, field-flashing references, field circuit breaker and generator protection interfaces.

These facts must be retained, but they are insufficient to build a dynamic excitation or complete DC auxiliary model.

## 3. Immediate questions to ask APSCL electrical engineers

### A. Generator excitation and DC supply — critical

1. Is generator `10MKA10` excitation **static excitation**, brushless excitation, or a combination?
2. What is the manufacturer/model of the AVR and excitation system?
3. What normally supplies the excitation transformer primary?
4. What is the excitation transformer exact tag, ratio, kVA/MVA, vector group and impedance?
5. What is the normal rated field voltage/current and ceiling field voltage/current?
6. What is the normal AVR terminal-voltage setpoint at full load?
7. What is the source used for **field flashing** before generator voltage is established?
8. Is field flashing supplied from 110 Vdc, 220 Vdc, 24 Vdc, an AC rectifier or a dedicated battery?
9. What are the field-flashing resistor, contactor/breaker and timing settings?
10. What happens to excitation after loss of auxiliary AC or station DC?
11. Is there a redundant AVR channel and automatic transfer between channels?
12. Please provide the excitation-system block diagram, AVR setting sheet and commissioning test report.

### B. Battery and DC systems — critical for protection

For every DC bank:

1. Nominal voltage: 24, 48, 110 or 220 Vdc.
2. Battery-bank tag and physical location.
3. Battery chemistry: lead-acid, Ni-Cd or other.
4. Number of cells and cell voltage.
5. Capacity in Ah at the stated discharge rate.
6. Minimum and maximum bus voltage.
7. Number and rating of battery chargers.
8. Normal charger arrangement: main/standby, parallel or split bus.
9. DC-board single-line diagram.
10. Connected continuous loads and momentary loads.
11. Required autonomy time.
12. Breaker trip-coil and close-coil currents.
13. Largest simultaneous trip duty.
14. DC cable sizes, lengths and resistance.
15. DC earth-fault monitoring arrangement.
16. Low-voltage alarms and load-shedding logic.
17. Date and result of the latest battery capacity/discharge test.
18. Which battery feeds generator protection, GIS, MV switchgear, turbine trip and field flashing?

### C. Clarification on energy storage

Ask directly:

> Does Ashuganj South have any battery energy-storage system intended to absorb or export MW, or are all batteries station DC/control batteries only?

Expected plant arrangement is station DC only, but this must be confirmed rather than assumed.

## 4. Fixing the impractical `R = 0` grid assumption

Do not silently replace zero resistance with a guessed "typical" value in the final model. Use one of these tiers:

### Tier 1 — preferred verified model

Request from PGCB for the Ashuganj South 230 kV point of connection:

- Three-phase short-circuit current or short-circuit MVA
- Single-line-to-ground short-circuit current
- Positive-sequence Thevenin `R1 + jX1`
- Negative-sequence `R2 + jX2`
- Zero-sequence `R0 + jX0`
- X/R ratio at the fault location
- Minimum and maximum grid-strength cases
- Network operating configurations used for those values

Then calculate:

`|Z1| = V_LL^2 / S_sc`

and, from X/R = `k`:

`R1 = |Z1| / sqrt(1 + k^2)`

`X1 = k R1`

### Tier 2 — engineering study assumption

If PGCB cannot provide R/X, use a **declared X/R sensitivity matrix**, not one hidden number. Suggested provisional cases:

- X/R = 5
- X/R = 10
- X/R = 20
- X/R = infinity only as the historical comparison

Keep `|Z|` fixed to the chosen short-circuit-strength case and report grid-equivalent losses separately from plant losses.

Do not label X/R = 10 as an Ashuganj fact unless an engineer or cited project criterion approves it.

### Tier 3 — line-derived estimate

If the actual 230 kV line conductor/cable data arrive, build the plant-to-grid branch from documented length and sequence constants, and place the PGCB Thevenin source at the remote grid bus. This is better than folding line and grid into one guessed reactance.

## 5. Remaining data needed to finalize balanced load flow

### Critical

1. Actual generator terminal-voltage/AVR setpoint.
2. Actual gross MW/MVAr operating snapshot and timestamp.
3. Actual auxiliary MW/MVAr at the same timestamp.
4. GSUT, UAT and GAT tap positions in service.
5. Normal GAT state.
6. Whether UAT and GAT are mechanically/electrically interlocked against sustained parallel operation.
7. Normal GIS bus-coupler state.
8. Normal Q1/Q2 busbar selections for each bay.
9. PGCB positive-sequence Thevenin R/X or short-circuit MVA plus X/R.
10. 230 kV line/cable identity, exact endpoints, number of circuits, length and R1/X1/B1.

### Important

11. Actual motor running/standby schedule.
12. Individual motor electrical input kW, PF and efficiency.
13. 6.6 kV feeder cable lengths, conductor sizes and impedances.
14. 400 V transformer/load-board breakdown.
15. Transformer operating cooling stages.
16. Generator capability-curve digital points or complete source PDF for independent transcription.

## 6. Data needed for fault analysis

### A. External grid and line

- Maximum and minimum PGCB short-circuit cases
- R1/X1, R2/X2 and R0/X0
- X/R ratio and DC offset basis
- Line length, conductor/cable type, number of circuits
- Positive-, negative- and zero-sequence R/X/B
- Tower geometry or cable construction and sheath/earthing arrangement
- Remote-end source contribution
- Mutual zero-sequence impedance where parallel circuits exist

### B. Generator

Already available: `xd`, `xd'`, `xd''`, rated MVA/kV, negative-sequence continuous capability and K factor.

Still needed:

- `xq`, `xq'`, `xq''`
- `x2` and `x0`
- Stator resistance `Ra`
- Saturated versus unsaturated values for each study method
- Subtransient/transient time constants
- Generator neutral grounding transformer/resistor exact zero-sequence equivalent
- Grounding capacitance if stator earth-fault distribution is studied
- Generator contribution decrement model

### C. Transformers

- Factory as-tested impedance and winding resistance
- Positive-sequence impedance at actual tap
- Complete GAT three-winding pair impedances `ZPS`, `ZPT`, `ZST`
- Zero-sequence impedance and zero-sequence connection model
- Neutral grounding impedances on UAT/GAT LV sides
- Inrush and saturation data if differential protection is studied
- Transformer X/R for asymmetrical current
- Tap position and earthing configuration for each operating case

### D. Motors

For each significant 6.6 kV motor:

- Rated voltage and electrical input kW/MVA
- PF and efficiency
- `xd''`, `xd'`, `x2`, `x0`, stator resistance
- Locked-rotor current and code letter
- Starting method and starting time
- Running/standby status
- Motor grounding arrangement
- Contribution decay constants

Without these, motor fault contribution can only be a declared sensitivity/bounding case.

### E. MV/LV network

- Cable lengths, sizes, material and installation
- R1/X1 and R0/X0 or enough geometry to calculate them
- Switchgear/busbar impedance where material
- LV-transformer impedances and vector groups
- Earthing transformers, NGR/NER values and earthing conductor impedance
- Normal/open tie-breaker states

### F. Fault-study outputs required

For each important bus and operating topology:

- Three-phase fault
- Single-line-to-ground fault
- Line-to-line fault
- Double-line-to-ground fault
- Initial symmetrical RMS current
- Peak making current
- Breaking current at breaker opening time
- Thermal equivalent current for 1 s and 3 s
- Contributions by generator, grid and motors
- Bus voltage during fault
- X/R and DC offset

## 7. Data needed for protection coordination

### A. Complete protection documentation

- Generator protection setting report, all attachments
- GIS control/protection multi-line package
- Relay setting files or exported parameter reports
- MV and LV protection one-lines
- Protection philosophy/selectivity report
- Trip matrix and cause/effect diagram
- Interlocking logic diagrams
- Commissioning test reports

### B. Relay inventory

For every relay:

- KKS/tag and protected equipment
- Manufacturer, model and firmware
- Active ANSI functions
- CT and VT input assignment
- Pickup/current setting
- Time multiplier/TMS
- Curve family: IEC SI/VI/EI, IEEE MI/VI/EI or definite time
- Instantaneous/high-set pickup and delay
- Directional polarizing method
- Negative-sequence, thermal, voltage, frequency and power settings
- Logic equations and blocking/interlocking inputs

### C. CT/VT data

- Ratio and tapping in use
- Number of cores and each core allocation
- Accuracy class
- Burden VA
- ALF for protection CTs
- Knee-point voltage, excitation curve and secondary winding resistance for PX/PS CTs
- Lead resistance and total connected burden
- VT ratio, winding connection, class, burden and fuse/MCB details

### D. Circuit breakers

- Continuous rating
- Rated symmetrical interrupting current
- Peak making current
- Short-time withstand current and duration
- Minimum and maximum opening time
- Relay operate time
- Trip-coil voltage/current
- Breaker-failure timer
- Reclosing duty where applicable

### E. Equipment damage/withstand curves

- Transformer through-fault withstand curve
- Generator stator/rotor thermal limits
- Negative-sequence capability curve
- Over/under-excitation curves
- Motor thermal/locked-rotor curves
- Cable thermal withstand
- Busbar and switchgear short-time withstand

### F. Coordination criteria

Ask the engineer/supervisor to approve:

- Minimum grading margin between relays
- Breaker interrupting-time allowance
- CT saturation allowance
- Fuse-relay grading rule
- Primary/backup philosophy
- Whether settings are for maximum fault, minimum fault or both
- Required sensitivity for remote-end and earth faults
- Maximum acceptable clearing times

## 8. Data priority list to send first

### Priority 1 — obtain before final load flow or fault work

1. PGCB short-circuit MVA/current and X/R, maximum/minimum cases.
2. Actual AVR setpoint and operating MW/MVAr snapshot.
3. Actual transformer taps and normal GAT/UAT/coupler topology.
4. UAT/GAT transfer interlock logic.
5. Complete 230 kV line constants and exact route/length.

### Priority 2 — obtain before unbalanced fault study

6. Generator `x2`, `x0`, `Ra`, q-axis values and time constants.
7. Complete GAT `ZPT` and `ZST`.
8. Transformer neutral grounding data.
9. Motor subtransient and sequence data.
10. MV cable positive/zero-sequence data.

### Priority 3 — obtain before protection coordination

11. Complete relay setting reports/files.
12. CT excitation/knee-point and burden data.
13. Breaker opening times and trip-coil DC data.
14. Battery/charger/DC distribution and autonomy.
15. Protection trip matrix, interlocks and commissioning reports.

## 9. Recommended execution plan

1. Send the Priority-1 request to APSCL and PGCB.
2. Replace the zero-R grid with verified R/X; until then retain explicit X/R sensitivities.
3. Confirm normal topology and define one verified normal case plus transfer/emergency cases.
4. Update and rerun the balanced load flow.
5. Freeze the corrected pre-fault model and results.
6. Add sequence networks and motor contributions.
7. Run maximum/minimum IEC 60909-style fault cases or the method approved by the supervisor.
8. Validate fault currents against hand calculations.
9. Enter relay/CT/VT/breaker data.
10. Produce time-current curves and differential/REF checks.
11. Verify primary/backup margins for all operating configurations.
12. Document every remaining estimate as a sensitivity case rather than a plant fact.

## 10. Ready-to-send concise engineer request

> Please provide the following for Ashuganj 450 MW CCPP South, project 112070: (1) excitation/AVR block diagram, model, settings, excitation-transformer data and field-flashing DC source; (2) 110/220 Vdc battery and charger single-lines, Ah capacities, autonomy, trip/close duties and latest discharge-test results; (3) actual generator AVR setpoint, MW/MVAr operating snapshot, transformer taps, GAT/UAT normal state and transfer interlock; (4) normal 230 kV GIS coupler and bus-selector positions; (5) PGCB maximum/minimum 230 kV fault level and X/R or Thevenin sequence impedances; (6) 230 kV line exact endpoints, circuits, length and R1/X1/B1/R0/X0/B0; (7) generator xq/x2/x0/Ra/time constants; (8) complete GAT ZPS/ZPT/ZST and neutral grounding; (9) motor sequence/subtransient and starting data; and (10) complete relay setting files, CT/VT details, breaker times, trip matrix and protection coordination philosophy.
[text](<c:/Users/Sindid/Downloads/Ashuganj_South_Master_Data_Request (1).xlsx>)