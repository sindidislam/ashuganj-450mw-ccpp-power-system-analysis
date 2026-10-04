# Ashuganj South dynamic study model

The runnable model is `model/PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx`.
`scripts/build_phase6_model.m` reconstructs it from the canonical project data
and frozen Phase 3/5 reference tables. All generated work belongs to this
folder; the original Simulink and Phase 1–5 source/results remain unchanged.

## Electrical network

The 458 MVA, 22 kV synchronous machine has mechanical-power and field-voltage
inputs, inertia and electrical transient states. Its generator breaker feeds
the 515 MVA, 22/230 kV YNd1 generator transformer and the unit auxiliary
transformer branch. The switchyard connects the GSUT bay, two 0.7 km line
circuits, the remote grid equivalent and the alternate GAT auxiliary feed.
The primary operating point is 360 MW with GAT out of service. Loads total
14 MW at the modeled auxiliary bus; undocumented 400 V load detail is not
invented. The selected profile distinguishes the Phase 3 load-flow network
from the later Phase 5 screening assumptions.

The electrical solver uses Specialized Power Systems in MATLAB R2024a,
50 microsecond discrete steps and the robust trapezoidal synchronous-machine
method. Initialization solves the physical network load flow and then sets
the governor/turbine and AVR states from the solved mechanical and field inputs.

## Measurements and protection

Nineteen three-phase voltage/current locations feed one synchronized 50 Hz
measurement chain. Each location records instantaneous waveforms, waveform
RMS and complex fundamental phasors. Relays update every 1 ms after a complete
20 ms acquisition window. Logged results retain the acquisition delays.

GEN51, GSUT51 and GEN51N use primary measurements, their configured CT ratios
and an accumulated IEC Standard Inverse operating duty. Generator, transformer,
bus and line differential functions use measured differential/restraint
currents. The transformer function compensates the YNd1 ratio, phase shift and
zero-sequence behavior. The ground-current measurement is taken from the
physical generator neutral resistor, whose terminal equivalent is documented
in `GROUNDING_REVIEW.md`.

Relay trip requests feed the station DC/trip-coil calculation and a 50 ms
breaker mechanism. Breaker commands operate actual three-phase electrical
breakers. Reports distinguish the command time from sustained measured current
cessation; no contact feedback is fabricated. Unit protection also commands
the assumed turbine/field shutdown. A generator-side fault may remain fed by
stored magnetic/mechanical energy after the external breaker opens.

## Station DC and controls

The assumed 110 V, 55-cell, 200 Ah station battery supplies the relay/control
and trip-coil load. The charger takes its availability from measured auxiliary
AC voltage and its scenario availability setting. The calculation includes
battery resistance, charger limits, SOC and low-voltage/trip-availability
alarms. Complete DC loss inhibits breaker action; restoration can execute an
already latched relay request. A new simulation resets the relay/breaker states.

## Scope

This is a reproducible academic study model. Its controller tuning, several
relay characteristics, breaker delay and DC bank are explicit engineering
assumptions. It is not a commissioned protection-setting tool. CT saturation,
communications delay, detailed winding faults and all installed plant backup
functions are outside the implemented boundary. The short dynamic acceptance
runs establish the demonstrated functions, not long-duration plant stability.
See the source register, assumption file and generated comparison/validation
tables for evidence and qualifications.
