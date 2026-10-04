# Phase 6 implementation and acceptance plan

## Source boundary

The original `simulink/` tree and Phase 1–5 results are immutable inputs. A byte-identical copy of all 40 original `.slx` files is kept in `Phase6/source_clone/simulink/`. Phase 6 writes only under `Phase6/`; its build reads the original MATLAB data providers and frozen copies of the final Phase 5 CSVs. Rebuilding never calls Phase 5 production writers.

The 2014 South one-line drawing `INEL-112070-00-ELC-DE-0001` and `Single Line Diagram_South.pdf` control topology and layout: generator 10MKA10 at the foot of the 22 kV unit column, GCB 10BAC10, GSUT 10BAT10 above it, 230 kV GIS at the top, UAT 10BBT10 and 6.6 kV auxiliaries branching right, and GAT 10BBT20 as the alternate auxiliary feed. The South model has no 400 kV bus. The previous `Ashuganj_South_Main.slx` opens in R2024a and is a flat balanced load-flow model with ideal three-phase G1 and grid source, GSUT/UAT/GAT, loads, ZGRID and powergui; it is a visual/electrical starting reference, not a completed dynamic model.

## Architecture decisions

1. A new SPS model is built by `scripts/build_phase6_model.m`; the original model is never resaved. The top level retains the drawing's vertical AC path, equipment tags and voltage colors. Detailed control, relay, battery and scenario logic live in named subsystems below/alongside the power path.
2. A single `init_phase6_parameters.m` returns the numerical parameter set and provenance metadata. The generator's 458 MVA, 22 kV machine data and combined inertia are from the project workbook; the primary dispatch is 360 MW. The 389.3 MW older LF1 model is preserved as a historical PF-derived reference only. The 0.7 km South line and the original estimated ZGRID remain separately identified. A Phase 5 grid screening alternative must not silently replace the Phase 3 load-flow network.
3. A synchronous machine with mechanical and field inputs replaces the ideal generator. Generic governor and AVR dynamics are marked academic assumptions, because the supplied SEMIPOL designation is not a verified controller transfer function. No numerical field-current claim is made from the unresolved `Rf` workbook field.
4. Fault blocks are wired to real AC nodes. Voltage/current measurements feed CT-scaled relay logic. Each relay's output passes through DC trip availability and a breaker command, and the breaker changes the AC network. Functions with missing installed settings remain study proxies or observation-only, never official relay claims.
5. The 110 V station battery/charger is the already documented Phase 2 academic model, with voltage sag, charger limits, SOC, DC loads and trip-coil availability. Storage means this station battery; no undocumented grid-scale storage is inferred.
6. Validation uses the frozen Phase 3 primary load-flow CSV and final corrected Phase 5 setting/fault CSVs. It records actual mismatch and explicit tolerances. Dynamic fault waveforms are Phase 6 model results; the Phase 4/5 initial symmetrical fault result is only a qualified comparison when circuit definitions agree.

## Execution sequence

- [ ] Verify source copy/hashes and MATLAB R2024a block paths.
- [ ] Build central parameter register with classifications and sentinels.
- [ ] Build and compile the dynamic AC network with machine, transformers, line, grid, breakers, sensors and selectable faults.
- [ ] Connect governor/AVR, CT/PT processing, relay timers, DC battery/charger and trip circuits.
- [ ] Initialize and run the primary normal operating point; compare Phase 3 reference values.
- [ ] Run 3PH, SLG, LL and LLG cases at documented network locations; log currents, relay pickups/trips, breaker status and DC state.
- [ ] Run DC-unavailable, charger-unavailable and recovery cases without attributing them to the installed plant.
- [ ] Export numerical tables and dynamic figures, visually inspect the top-level model, and document every failing or unverified acceptance item.

## Acceptance evidence

The model is ready only if a clean MATLAB session opens and compiles the saved `.slx`, normal simulation and load-flow initialization run, all four fault types perturb the electrical network, at least one relay drives a breaker through the functional DC path, DC loss inhibits that trip and raises alarms, and the top level passes visual inspection. Every numerical claim must be traceable to a source-backed datum, a stated derivation, or an explicit engineering-study assumption.
