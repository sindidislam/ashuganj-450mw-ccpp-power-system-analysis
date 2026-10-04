# Phase 6 acceptance contract

The user's full master prompt and 2026-09-22 visual correction govern this resumed build. The original work plan remains useful but does not override these requirements.

- Preserve original Simulink models and all Phase 1–5 data/results. Inventory source material, inspect original electrical structure, and record hashes.
- Deliver one runnable, reproducible hierarchical model in this folder. The master screen is a complete SLD with generator, transformer, switchyard, line/grid, auxiliaries, protection, DC supply, fault controls and monitoring.
- Use plain equipment names on the canvas: Generator, Transformer, Switchyard, Line, Grid, Auxiliaries, Protection, DC Supply, Faults, Measurements and Scenario. No task/phase numbering in subsystem labels. Opening each subsystem must show its real implementation and readable detail.
- Use an actual synchronous machine with inertia, excitation and governor; initialize the electrical and controller states from load flow.
- Keep Phase 3 baseline and revised Phase 5 study profiles explicitly distinct. The frozen Phase 5 coordination currents were not regenerated with every later screening assumption. Report differences; never force agreement.
- Fault types: none, 3PH, SLG, LL, LLG. Locations: generator terminals, unit/GSUT connection, transformer HV, 230 kV bus, line and remote grid. Times and impedances are centrally selected.
- Protection must use measured currents/voltages through CT/PT processing, pickup, timing, DC supply and physical breaker action. Differential functions must use measured differential/restraint current and transformer vector compensation, not scenario flags. Unsupported installed functions must be identified as unimplemented or study equivalents.
- Functional battery/charger/DC bus with SOC/current/voltage, charger failure, battery/undervoltage alarms and trip availability. Charger AC availability derives from the auxiliary bus. Healthy DC enables trips; DC loss inhibits them and is visible.
- Exports: operating-point comparison, source/setting consistency table, fault currents, relay times, breaker times, DC status and labeled dynamic plots.
- Validate normal/reduced operating points, four fault types, internal versus external differential behavior, breaker/DC response, DC loss, charger loss and stable reset/recovery. Log every failed or qualified acceptance item.
- Verify a saved model in a clean R2024a session and visually inspect the complete top level and detailed subsystems. Connections, readable labels and physical functionality are acceptance conditions, not cosmetic extras.
- Deliver a concise architecture document, source/assumption register, validation report and 5–10 minute teacher guide. Do not claim completion until every required acceptance test has evidence.
