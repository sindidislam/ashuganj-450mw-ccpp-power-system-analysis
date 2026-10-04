# Phase 6 study boundary and assumptions

The original South SLD and all Phase 1–5 outputs are read-only inputs. This is a university dynamic **study model**, not an as-built APSCL protection or station-battery design. The 450 MW project title is not a dispatch setpoint: the primary load-flow case is `LF360_GAT_OUT` at 360 MW. An older 389.3 MW case is a separate historical comparator.

The 22/230 kV, 515 MVA GSUT has a 16% study impedance and 0.21% resistive component in the source data. The short 0.7 km line is modeled separately from the estimated external grid impedance `ZGRID = j2.65581124 ohm`; the Phase 5 45.01 kA screening equivalent is a different scenario and must not be substituted silently. The 230 kV external grid is represented by an ideal voltage source behind that estimated impedance, so remote transient stability claims are limited.

Generator electrical ratings, reactances and combined inertia are sourced from project records. Generic excitation/AVR and turbine/governor gains, time constants, limits and initial field/mechanical drive that are needed for dynamic simulation remain **ENGINEERING_ASSUMPTION** values until plant controller data are supplied. They must be tuned and independently validated before inferring actual plant behavior.

Phase 5 relay CSV settings are numerical study settings. GEN-51 CT 15000/1 is source-backed; GEN-51N 20/1 is assumed; GSUT-HV 1600/1 has a documented conflict with a manufacturer 1500/1 figure. Differential thresholds, slopes and operating delays are study proxies, not installed settings. The model must not imply verified selectivity for an unmodeled zone.

The station storage subsystem is the Phase 2 academic **110 V, 55-cell, 200 Ah battery** with dual 20 kW duty/standby charger assumptions. It supports relay and breaker trip-coil availability in the study, and is not a grid-scale BESS. The original drawing carries other DC voltage labels; no assertion is made that this academic equivalent is the exact installed trip supply.

The parameter register and comparison reports distinguish `VERIFIED_SOURCE`, `DERIVED_FROM_VERIFIED_SOURCE`, `USER_ASSERTED`, `ENGINEERING_ASSUMPTION` and `PLACEHOLDER_NOT_FOR_FINAL_RESULT`. Dynamic waveforms without an independent plant record are Phase 6 simulation outputs, not validated plant measurements.
